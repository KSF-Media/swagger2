-- |
-- Swagger™ is a project used to describe and document RESTful APIs.
--
-- The Swagger specification defines a set of files required to describe such an API.
-- These files can then be used by the Swagger-UI project to display the API
-- and Swagger-Codegen to generate clients in various languages.
-- Additional utilities can also take advantage of the resulting files, such as testing tools.
module Data.Swagger (
  -- * How to use this library
  -- $howto

  -- ** @'Monoid'@ instances
  -- $monoids

  -- ** Lenses and prisms
  -- $lens

  -- ** Schema specification
  -- $schema

  -- * Re-exports
  module Data.Swagger.Lens,
  module Data.Swagger.ParamSchema,
  module Data.Swagger.Schema,

  -- * Swagger specification
  Swagger(..),
  Host(..),
  Scheme(..),

  -- ** Info types
  Info(..),
  Contact(..),
  License(..),

  -- ** Paths
  Paths(..),
  PathItem(..),

  -- ** Operations
  Tag(..),
  Operation(..),

  -- ** Types and formats
  SwaggerType(..),
  Format,
  CollectionFormat(..),

  -- ** Parameters
  Param(..),
  ParamAnySchema(..),
  ParamOtherSchema(..),
  ParamLocation(..),
  ParamName,
  Items(..),
  Header(..),
  Example(..),

  -- ** Schemas
  ParamSchema(..),
  Schema(..),
  SwaggerItems(..),
  Xml(..),

  -- ** Responses
  Responses(..),
  Response(..),

  -- ** Security
  SecurityScheme(..),
  SecuritySchemeType(..),
  SecurityRequirement(..),

  -- *** API key
  ApiKeyParams(..),
  ApiKeyLocation(..),

  -- *** OAuth2
  OAuth2Params(..),
  OAuth2Flow(..),
  AuthorizationURL,
  TokenURL,

  -- ** External documentation
  ExternalDocs(..),

  -- ** References
  Reference(..),
  Referenced(..),

  -- ** Miscellaneous
  MimeList(..),
  URL(..),
) where

import Data.Swagger.Lens
import Data.Swagger.ParamSchema
import Data.Swagger.Schema

import Data.Swagger.Internal

-- $setup
-- >>> import Control.Lens
-- >>> import Data.Aeson
-- >>> import Data.Monoid
-- >>> import Data.Proxy
-- >>> import GHC.Generics
-- >>> :set -XDeriveGeneric
-- >>> :set -XOverloadedStrings
-- >>> :set -XOverloadedLists
-- >>> :set -fno-warn-missing-methods

-- $howto
--
-- This section explains how to use this library to work with Swagger specification.

-- $monoids
--
-- Virtually all types representing Swagger specification have @'Monoid'@ instances.
-- The @'Monoid'@ type class provides two methods — @'mempty'@ and @'mappend'@.
--
-- In this library you can use @'mempty'@ for a default/empty value. For instance:
--
-- >>> encode (mempty :: Swagger)
-- "{\"swagger\":\"2.0\",\"info\":{\"version\":\"\",\"title\":\"\"}}"
--
-- As you can see some spec properties (e.g. @"version"@) are there even when the spec is empty.
-- That is because these properties are actually required ones.
--
-- You /should/ always override the default (empty) value for these properties,
-- although it is not strictly necessary:
--
-- >>> encode mempty { _infoTitle = "Todo API", _infoVersion = "1.0" }
-- "{\"version\":\"1.0\",\"title\":\"Todo API\"}"
--
-- You can merge two values using @'mappend'@ or its infix version @('<>')@:
--
-- >>> encode $ mempty { _infoTitle = "Todo API" } <> mempty { _infoVersion = "1.0" }
-- "{\"version\":\"1.0\",\"title\":\"Todo API\"}"
--
-- This can be useful for combining specifications of endpoints into a whole API specification:
--
-- @
-- \-\- /account subAPI specification
-- accountAPI :: Swagger
--
-- \-\- /task subAPI specification
-- taskAPI :: Swagger
--
-- \-\- while API specification is just a combination
-- \-\- of subAPIs' specifications
-- api :: Swagger
-- api = accountAPI <> taskAPI
-- @

-- $lens
--
-- Since @'Swagger'@ has a fairly complex structure, lenses and prisms are used
-- to modify this structure. In combination with @'Monoid'@ instances, lenses
-- also make it fairly simple to construct/modify any part of the specification:
--
-- >>> :{
-- encode $ mempty & pathsMap .~
--   [ ("/user", mempty & pathItemGet ?~ (mempty
--       & operationProduces ?~ MimeList ["application/json"]
--       & operationResponses .~ (mempty
--         & responsesResponses . at 200 ?~ Inline (mempty & responseSchema ?~ Ref (Reference "#/definitions/User")))))]
-- :}
-- "{\"/user\":{\"get\":{\"responses\":{\"200\":{\"schema\":{\"$ref\":\"#/definitions/#/definitions/User\"},\"description\":\"\"}},\"produces\":[\"application/json\"]}}}"
--
-- Since @'ParamSchema'@ is basically the /base schema specification/, a special
-- @'HasParamSchema'@ class has been introduced to generalize @'ParamSchema'@ lenses
-- and allow them to be used by any type that has a @'ParamSchema'@:
--
-- >>> :{
-- encode $ mempty
--   & schemaTitle   ?~ "Email"
--   & schemaType    .~ SwaggerString
--   & schemaFormat  ?~ "email"
-- :}
-- "{\"format\":\"email\",\"title\":\"Email\",\"type\":\"string\"}"

-- $schema
--
-- This library provides two classes for schema encoding.
-- Both these classes provide means to encode _types_ as Swagger _schemas_.
--
-- @'ToParamSchema'@ is intended to be used for primitive API endpoint parameters,
-- such as query parameters, headers and URL path pieces.
-- Its corresponding value-encoding class is @'ToHttpApiData'@ (from @http-api-data@ package).
--
-- @'ToSchema'@ is used for request and response bodies and mostly differ from
-- primitive parameters by allowing objects/mappings in addition to primitive types and arrays.
-- Its corresponding value-encoding class is @'ToJSON'@ (from @aeson@ package).
--
-- While lenses and prisms make it easy to define schemas, it might be that you don't need to:
-- @'ToSchema'@ and @'ToParamSchema'@ classes both have default @'Generic'@-based implementations!
--
-- @'ToSchema'@ default implementation is also aligned with @'ToJSON'@ default implementation with
-- the only difference being for sum encoding. @'ToJSON'@ defaults sum encoding to @'defaultTaggedObject'@,
-- while @'ToSchema'@ defaults to something which corresponds to @'ObjectWithSingleField'@. This is due to
-- @'defaultTaggedObject'@ behavior being hard to specify in Swagger.
--
-- Here's an example showing @'ToJSON'@–@'ToSchema'@ correspondance:
--
-- >>> data Person = Person { name :: String, age :: Integer } deriving Generic
-- >>> instance ToJSON Person
-- >>> instance ToSchema Person
-- >>> encode (Person "David" 28)
-- "{\"age\":28,\"name\":\"David\"}"
-- >>> encode $ toSchema (Proxy :: Proxy Person)
-- "{\"required\":[\"name\",\"age\"],\"type\":\"object\",\"properties\":{\"age\":{\"type\":\"integer\"},\"name\":{\"type\":\"string\"}}}"
--

