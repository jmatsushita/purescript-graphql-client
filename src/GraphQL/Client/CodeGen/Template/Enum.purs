module GraphQL.Client.CodeGen.Template.Enum where

import Prelude

import Data.CodePoint.Unicode (isAlpha)
import Data.Foldable (intercalate)
import Data.Maybe (Maybe, fromMaybe, maybe)
import Data.Monoid (guard)
import Data.String (codePointFromChar)
import Data.String as String
import Data.String.CodeUnits (charAt)
import Data.String.Unicode (toUpper)
import GraphQL.Client.CodeGen.Lines (docComment)

template ::
  String ->
  { name :: String
  , schemaName :: String
  , description :: Maybe String
  , values :: Array String
  , imports :: Array String
  , enumValueNameTransform :: Maybe (String -> String)
  , customCode :: { name :: String, values :: Array { gql :: String, transformed :: String} } -> String
  } ->
  String
template modulePrefix opts@{ name, schemaName, description, values, imports, customCode } =
  """module """ <> modulePrefix <> "Schema." <> schemaName <> """.Enum.""" <> name
    <> """ where

import Prelude

import Data.Argonaut.Decode (class DecodeJson, JsonDecodeError(..), decodeJson)
import Data.Argonaut.Encode (class EncodeJson, encodeJson)
import Data.Either (Either(..))
import Data.Function (on)
import GraphQL.Client.Args (class ArgGql)
import GraphQL.Client.ToGqlString (class GqlArgString)
import GraphQL.Hasura.Decode (class DecodeHasura)
import GraphQL.Hasura.Encode (class EncodeHasura)
import GraphQL.Client.Variables.TypeName (class VarTypeName)
"""
    <> intercalate "\n" imports
    <> """

"""
    <> docComment description
    <> """data """
    <> name
    <> """ 
  = """
    <> enumCtrs
    <> """
"""
    <> customCode { name, values: valuesAndTransforms }
    <> """

instance eq"""
    <> name
    <> """ :: Eq """
    <> name
    <> """ where 
  eq = eq `on` show

instance ord"""
    <> name
    <> """ :: Ord """
    <> name
    <> """ where
  compare = compare `on` show

instance argToGql"""
    <> name
    <> """ :: ArgGql """
    <> name
    <> """ """
    <> name
    <> """

instance gqlArgString"""
    <> name
    <> """ :: GqlArgString """
    <> name
    <> """ where
  toGqlArgStringImpl = show

instance decodeJson"""
    <> name
    <> """ :: DecodeJson """
    <> name
    <> """ where
  decodeJson = decodeJson >=> case _ of 
"""
    <> decodeMember
    <> """
    s -> Left $ TypeMismatch $ "Not a """
    <> name
    <> """: " <> s

instance encodeJson"""
    <> name
    <> """ :: EncodeJson """
    <> name
    <> """ where 
  encodeJson = show >>> encodeJson

instance decdoeHasura"""
    <> name
    <> """ :: DecodeHasura """
    <> name
    <> """ where 
  decodeHasura = decodeJson

instance encodeHasura"""
    <> name
    <> """ :: EncodeHasura """
    <> name
    <> """ where 
  encodeHasura = encodeJson

instance varTypeName"""
    <> name
    <> """ :: VarTypeName """
    <> name
    <> """ where 
  varTypeName _ = """
    <> show (name <> "!")
    <> """

instance show"""
    <> name
    <> """ :: Show """
    <> name
    <> """ where
  show a = case a of 
"""
    <> showMember
    <> """
"""
  where
  enumValueName = fromMaybe defaultEnumValueName opts.enumValueNameTransform

  enumCtrs = intercalate "\n  | " (map enumValueName values)

  decodeMember =
    values
      <#> (\v -> "    \"" <> v <> "\" -> pure " <> enumValueName v <> "")
      # intercalate "\n"

  showMember =
    values
      <#> (\v -> "    " <> enumValueName v <> " -> \"" <> v <> "\"")
      # intercalate "\n"

  valuesAndTransforms = values <#> (\v -> {gql: v, transformed: enumValueName v})

defaultEnumValueName :: String -> String
defaultEnumValueName s = alphaStart <> toUpper (String.take 1 s) <> String.drop 1 s
  where
  alphaStart =
    guard (maybe false (not isAlpha <<< codePointFromChar) $ charAt 0 s)
      "ENUM_"
