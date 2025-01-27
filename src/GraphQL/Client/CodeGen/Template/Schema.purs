module GraphQL.Client.CodeGen.Template.Schema where

import Prelude

import Data.Foldable (intercalate)
import Data.Maybe (Maybe, maybe)
import Data.Monoid (guard)
import Data.String (Pattern(..), contains)

template ::
  { name :: String
  , enums :: Array String
  , mainSchemaCode :: String
  , modulePrefix :: String 
  , idImport :: Maybe { moduleName :: String, typeName :: String}
  } ->
  String
template { name, enums, idImport, mainSchemaCode, modulePrefix } =
    """module """ <> modulePrefix <> """Schema.""" <> name <> """ where

import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import GraphQL.Client.Args (class ArgGql, class RecordArg, NotNull)
""" <> guard (contains (Pattern "GqlUnion") mainSchemaCode) "import GraphQL.Client.Union (GqlUnion)" <> """
import """ <> maybe defaultIdImport getImport idImport <> """
""" <> enumImports <> """

""" <> mainSchemaCode <> """
"""
  where
  enumImports =
    enums 
      <#> (\v -> "import " <> modulePrefix <> """Schema.""" <> name <> ".Enum."<> v <> " ("<> v <> ")")
      # intercalate "\n"

  getImport {moduleName, typeName} = 
    moduleName <> " (" <> typeName <> ")"

  defaultIdImport = "GraphQL.Client.ID (ID)"
