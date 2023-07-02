module Language.Fixlat.Core.Internal.Generate (generate) where

import Data.Tuple.Nested
import Prelude

import Control.Assert (assertI)
import Control.Assert.Assertions (keyOfMap)
import Control.Debug as Debug
import Control.Monad.State (execStateT, modify, modify_)
import Data.Array as Array
import Data.Either (Either(..), either)
import Data.List (List(..))
import Data.List as List
import Data.List.NonEmpty as NonEmptyList
import Data.List.NonEmpty as NonemptyList
import Data.Make (make)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Traversable (for, for_, traverse, traverse_)
import Effect.Class (class MonadEffect)
import Hole (hole)
import Language.Fixlat.Core.Grammar as G
import Language.Fixlat.Core.Internal.Base (Database(..), FixpointEnv, GenerateT, Patch(..), Queue(..), _gas, decrementGasNonpositive, emptyDatabase)
import Language.Fixlat.Core.Internal.Database as Database
import Language.Fixlat.Core.Internal.Queue as Queue
import Language.Fixlat.Core.Internal.RuleNormalization (normRule)
import Language.Fixlat.Core.ModuleT (ModuleT, getModuleCtx)
import Record as R

--------------------------------------------------------------------------------
-- Generate
--------------------------------------------------------------------------------

generate :: forall m. MonadEffect m => 
  Database -> 
  G.FixpointSpecName -> 
  ModuleT m Database
generate (Database initialProps) fixpointSpecName = do
  Debug.debugA $ "[generate] BEGIN"
  Debug.debugA $ "[generate] fixpoint: " <> show fixpointSpecName

  moduleCtx <- getModuleCtx
  let fixpointSpec = assertI keyOfMap $ fixpointSpecName /\ (unwrap moduleCtx.module_).fixpoints

  rules <- (unwrap moduleCtx.module_).rules #
    Map.filterWithKey (\ruleName _ -> ruleName `Array.elem` ((unwrap fixpointSpec).ruleNames)) >>>
    Map.values >>>
    map make >>>
    traverse normRule

  let queue = do
        let axioms = (unwrap moduleCtx.module_).axioms #
              Map.filterWithKey (\axiomName _ -> axiomName `Array.elem` ((unwrap fixpointSpec).axiomNames)) >>>
              Map.values >>>
              Array.fromFoldable
        let props = initialProps <> List.fromFoldable (axioms <#> \(G.Axiom prop) -> prop)
        Queue (NonEmptyList.singleton <$> (ConclusionPatch <$> props))

  let comparePatch = const <<< const $ GT

  let env =
        { gas: moduleCtx.initialGas 
        , database: emptyDatabase
        , rules
        , queue 
        , comparePatch }
        :: FixpointEnv

  env' <- execStateT loop env

  Debug.debugA $ "[generate] END"
  pure env'.database

--------------------------------------------------------------------------------
-- Loop
--------------------------------------------------------------------------------

loop :: forall m. MonadEffect m => GenerateT m Unit
loop = do
  Debug.debugA $ "[loop] BEGIN"
  -- • Decrement gas. If gas is 0, then done.
  -- • If no more patches in queue, then done, otherwise pop the next patch.
  -- • Learn the patch, yielding new patches.
  -- • Insert the new patches into the queue.
  decrementGasNonpositive >>= if _
    then do
      Debug.debugA "[loop] no more gas"
      end
    else do
      Queue.pop >>= case _ of
        Left _ -> do
          Debug.debugA "[loop] no more patches"
          end
        Right patches -> do
          Debug.debugA $ "[loop] new patches count: " <> show (NonemptyList.length patches)
          let merge = map (either (const Nil) identity) >>> NonemptyList.toList >>> List.concat
          patches #
            ( -- learn the new patches
              traverse Database.learnPatch >=>
              --- enqueue the new patches
              traverse_ Database.enqueuePatch <<< merge ) 
          loop
  where
  end = do
    Debug.debugA $ "[loop] END"
    pure unit