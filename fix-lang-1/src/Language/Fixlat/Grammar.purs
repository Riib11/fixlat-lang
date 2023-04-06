-- | Syntax types for language.
-- |
-- | Limitations:
-- | - no user-defined data; everything is primitive
module Language.Fixlat.Grammar where

import Container
import Data.Array
import Data.Generic.Rep
import Data.Lattice
import Data.Maybe
import Data.Newtype
import Data.Show.Generic
import Prelude
import Pretty
import Utility
import Data.Enum (enumFromTo)
import Data.Eq.Generic (genericEq)
import Data.Ord.Generic (genericCompare)
import Partial.Unsafe (unsafeCrashWith)

newtype Module ann
  = Module
  { label :: Label
  , statements :: Array (Statement ann)
  }

derive instance genericModule :: Generic (Module ann) _

instance showModule :: Show ann => Show (Module ann) where
  show x = genericShow x

instance prettyModule :: Pretty (Module ann) where
  pretty (Module mdl) =
    vcat
      [ "module" ~ mdl.label ~ ":"
      , vcat $ ("" \~ _) <<< pretty <$> mdl.statements
      ]

-- | A top-level __statement__.
data Statement ann
  = PredicateStatement Predicate
  | RuleStatement (Rule ann)
  | QueryStatement (Query ann)

derive instance genericStatement :: Generic (Statement ann) _

instance showStatement :: Show ann => Show (Statement ann) where
  show x = genericShow x

instance prettyStatement :: Pretty (Statement ann) where
  pretty (PredicateStatement pred) = pretty pred
  pretty (RuleStatement rule) = pretty rule
  pretty (QueryStatement query) = pretty query

-- | A top-level __predicate__ declaration.
newtype Predicate
  = Predicate
  { label :: String
  , name :: Name
  , param :: { name :: Name, sort :: Sort }
  }

derive instance genericPredicate :: Generic Predicate _

instance showPredicate :: Show Predicate where
  show x = genericShow x

instance prettyPredicate :: Pretty Predicate where
  pretty (Predicate pred) =
    "predicate" ~ pred.label ~ ":"
      ~ pred.name
      ~ braces (pred.param.name ~ "," ~ pred.param.sort)

-- | An top-level inference __rule__ declaration.
newtype Rule ann
  = Rule
  { label :: Label
  , params :: Array Name -- parameters (universally quantified)
  , hyps :: Array (Term ann) -- hypotheses
  , con :: Term ann -- conclusion
  }

derive instance genericRule :: Generic (Rule ann) _

instance showRule :: Show ann => Show (Rule ann) where
  show x = genericShow x

instance prettyRule :: Pretty (Rule ann) where
  pretty (Rule rule) =
    vcat
      [ "rule" ~ rule.label ~ ":"
          ~ (if null rule.params then mempty else "∀" ~ rule.params ~ ".")
      , indent <<< vcat
          $ [ vcat $ rule.hyps
            , pretty "----------------"
            , pretty rule.con
            ]
      ]

-- | A top-level __query__.
newtype Query ann
  = Query
  { params :: Array Name -- parameters (universally quantified)
  , hyps :: Array (Term ann) --hypotheses
  , con :: Term ann -- conclusion
  }

derive instance genericQuery :: Generic (Query ann) _

instance showQuery :: Show ann => Show (Query ann) where
  show x = genericShow x

instance prettyQuery :: Pretty (Query ann) where
  pretty (Query query) =
    vcat
      [ "query"
          ~ ":"
          ~ (if null query.params then mempty else "∀" ~ query.params ~ ".")
      , indent <<< vcat
          $ [ vcat $ query.hyps
            , pretty "----------------"
            , pretty query.con
            ]
      ]

-- | A __sort__. Every sort has a lattice structure defined over its terms.
data Sort
  = UnitPrimSort
  | BoolPrimSort
  | PredSort Name

derive instance genericSort :: Generic Sort _

instance eqSort :: Eq Sort where
  eq x = genericEq x

instance showSort :: Show Sort where
  show x = genericShow x

instance prettySort :: Pretty Sort where
  pretty UnitPrimSort = pretty "Unit"
  pretty BoolPrimSort = pretty "Bool"
  pretty (PredSort x) = pretty x

-- | A __qualified proposition__.
data QualProp ann
  = UnqualProp (Prop ann)
  | ForallProp { name :: Name, prop :: Prop ann }
  | ExistsProp { name :: Name, prop :: Prop ann }

derive instance genericQualProp :: Generic (QualProp ann) _

instance showQualProp :: Show ann => Show (QualProp ann) where
  show x = genericShow x

instance prettyQualProp :: Pretty (QualProp ann) where
  pretty (UnqualProp prop) = pretty prop
  pretty (ForallProp all) = "∀" ~ all.name ~ "." ~ all.prop
  pretty (ExistsProp exi) = "∃" ~ exi.name ~ "." ~ exi.prop

-- | An unqualified __proposition__.
data Prop ann
  = Prop { name :: Name, arg :: Term ann }

derive instance genericProp :: Generic (Prop ann) _

instance showProp :: Show ann => Show (Prop ann) where
  show x = genericShow x

instance prettyProp :: Pretty (Prop ann) where
  pretty (Prop prop) = prop.name ~ braces prop.arg

-- | A __term__ corresponds to an instance of data. _Cannot_ have
-- | quantifications.
data Term ann
  = UnitTerm { ann :: ann }
  | BoolTerm { b :: Boolean, ann :: ann }
  | VarTerm { name :: Name, ann :: ann }

derive instance genericTerm :: Generic (Term ann) _

instance containerTerm :: Container Term where
  open _ = unsafeCrashWith "TODO"
  mapContainer f _ = unsafeCrashWith "TODO"

instance showTerm :: Show ann => Show (Term ann) where
  show _ = unsafeCrashWith "TODO"

instance prettyTerm :: Pretty (Term ann) where
  pretty _ = unsafeCrashWith "TODO"

-- | A __name__.
newtype Name
  = Name String

derive instance genericName :: Generic Name _

derive instance newtypeName :: Newtype Name _

instance eqName :: Eq Name where
  eq x = genericEq x

instance ordName :: Ord Name where
  compare x = genericCompare x

instance showName :: Show Name where
  show x = genericShow x

instance prettyName :: Pretty Name where
  pretty (Name str) = pretty str

-- | A __label__.
newtype Label
  = Label String

derive instance genericLabel :: Generic Label _

derive instance newtypeLabel :: Newtype Label _

instance showLabel :: Show Label where
  show x = genericShow x

instance prettyLabel :: Pretty Label where
  pretty (Label str) = pretty str

-- | Lattice over well-sorted terms
instance eqTermSort :: Eq (Term Sort) where
  eq = unsafeCrashWith "TODO"

instance partialOrdTermSort :: PartialOrd (Term Sort) where
  comparePartial _ _ = unsafeCrashWith "TODO"
  comparePartial tm1 tm2 = unsafeCrashWith $ "comparePartial: terms have different sorts" <> "\n  tm1 = " <> show tm1 <> "\n  tm2 = " <> show tm2

instance latticeTermSort :: Lattice (Term Sort) where
  join = unsafeCrashWith "TODO" -- :: Term Sort -> Term Sort -> Term Sort
  meet = unsafeCrashWith "TODO" -- :: Term Sort -> Term Sort -> Term Sort
