/-
Copyright (c) 2023 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import Lean.Data.Json

/-!
# OpenAI JSON messages.
-/

open Lean (ToJson FromJson Json fromJson?)

namespace Mathlib.Tactic.GPT

inductive Role
| system | assistant | user
deriving ToJson, FromJson, BEq

instance : ToString Role where
  toString r := match r with | .system => "system" | .assistant => "assistant" | .user => "user"

structure Message where
  role : Role
  content : String
deriving ToJson, FromJson

structure Request where
  model : String := "gpt-4"
  messages : List Message
  temperature : Float := 0.2
deriving ToJson, FromJson

structure Choice where
  message : Message
  finish_reason : String
  index : Nat
deriving ToJson, FromJson

structure Usage where
  prompt_tokens : Nat
  completion_tokens : Nat
  total_tokens : Nat
deriving ToJson, FromJson

structure Response where
  id : String
  object : String
  created : Nat
  model : String
  usage : Usage
  choices : List Choice
deriving ToJson, FromJson

structure ErrorMessage where
  message : String
  type : String
  param : Option Nat := none
  code : Option Nat := none
deriving ToJson, FromJson

structure Error where
  error : ErrorMessage
deriving ToJson, FromJson

/--
Extract the content of ChatGPT's reply.
This assumes that there is only one `choice`, discarding others.
-/
def Response.content (r : Response) : Option String :=
r.choices.head?.map (·.message.content)

/-- Parse a raw JSON string to a `Response` term. -/
def parseResponse (response : String) : Except String Response :=
match Json.parse response with
| .ok r => match fromJson? r with
  | .ok r => .ok r
  | .error e₁ => match (fromJson? r : Except String Error) with
    | .ok { error := e₂ } => .error (e₂.type ++ ": " ++ e₂.message)
    | .error e₂ => .error (e₁ ++ "\n" ++ e₂)
| .error e => .error e
