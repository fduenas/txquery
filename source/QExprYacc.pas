{*****************************************************************************}
{   TxQuery DataSet                                                           }
{                                                                             }
{   The contents of this file are subject to the Mozilla Public License       }
{   Version 1.1 (the "License"); you may not use this file except in          }
{   compliance with the License. You may obtain a copy of the License at      }
{   http://www.mozilla.org/MPL/                                               }
{                                                                             }
{   Software distributed under the License is distributed on an "AS IS"       }
{   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the   }
{   License for the specific language governing rights and limitations        }
{   under the License.                                                        }
{                                                                             }
{   The Original Code is: QExprYacc.pas                                       }
{                                                                             }
{                                                                             }
{   The Initial Developer of the Original Code is Alfonso Moreno.             }
{   Portions created by Alfonso Moreno are Copyright (C) <1999-2003> of       }
{   Alfonso Moreno. All Rights Reserved.                                      }
{   Open Source patch reviews (2009-2012) with permission from Alfonso Moreno }
{                                                                             }
{   Alfonso Moreno (Hermosillo, Sonora, Mexico)                               }
{   email: luisarvayo@yahoo.com                                               }
{     url: http://www.ezsoft.com                                              }
{          http://www.sigmap.com/txquery.htm                                  }
{                                                                             }
{   Contributor(s): Chee-Yang, CHAU (Malaysia) <cychau@gmail.com>             }
{                   Sherlyn CHEW (Malaysia)                                   }
{                   Francisco Due�as Rodriguez (Mexico) <fduenas@gmail.com>   }
{                                                                             }
{              url: http://code.google.com/p/txquery/                         }
{                   http://groups.google.com/group/txquery                    }
{                                                                             }
{*****************************************************************************}

unit QExprYacc;

{$I xq_flag.INC}
{$R QExprYacc.res}
interface

uses
  SysUtils, Classes, Windows, Dialogs, QYaccLib, QBaseExpr, Db
(*$IFDEF LEVEL6*)
  , Variants
(*$ENDIF*)
  , XQTypes;

const
  MAX_INDEXED_FIELDS = 10;
type

  TReferencedDatasetList = Class;

  TReferencedDataSetItem = Class
  Private
    FReferencedDataSets: TReferencedDataSetList;
    FDataSet: TDataSet;
    FCount: Integer;
  Public
    Constructor Create( RefDataSetList: TReferencedDataSetList );
    Property DataSet: TDataSet Read fDataSet Write fDataSet;
    Property Count: Integer Read fCount Write fCount;
  End;

  TReferencedDataSetList = Class
    FItems: TList;
    Function GetCount: Integer;
    Function GetItem( Index: Integer ): TReferencedDataSetItem;
  Public
    Constructor Create;
    Destructor Destroy; Override;
    Function Add: TReferencedDataSetItem;
    Procedure Clear;
    Procedure Delete( Index: Integer );
    Function IndexOf( DataSet: TDataSet ): Integer;

    Property Count: Integer Read GetCount;
    Property Items[Index: Integer]: TReferencedDataSetItem Read GetItem; Default;
  End;

  TCheckData = Record
    Field: TField; // the field referenced
    RefCount: Integer; // No of references to a field
    FieldCount: Integer; // number of fields referenced in expression
    Fields: Array[1..MAX_INDEXED_FIELDS] Of TField; // the fields referenced (used for joining)
    HasMorefunctions: Boolean; // expression have more functions
  End;

  TExprParser = class(TCustomParser)
  private
    fDefaultDataSet: TDataSet;
    fAnalizer: TObject;
    fIdReferences: TStrings;
    fReferencedDataSets: TReferencedDataSetList;

    fExprList: TList;
    fTempParams: TParameterList;
    fGroupIdent: TxNativeString;
    fIdentifier: TxNativeString;
    fGroupIdentList: TStringList;
    fIdentifierList: TStringList;
    { is not this a simple expression ? like TABLE.FIELD
      this is used for detecting if giving the same data type to the
      result set as the original field }
    fIsComplex: Boolean;
    { used to obtain a pair of operators }
    Op1, Op2: TExpression;
    { a stacked list of params referencing to FExprList }
    fStackedParamCount: TList;
    { the number of parameters for the last function }
    fParamCount: Integer;
    { for the case..when..else..end }
    fWhenParamList: TParameterList;
    fThenParamList: TParameterList;
    fElseExpr: TExpression;
    { used in unknown identifiers }
    IDF: TExpression;
    Procedure IDFunc( Sender: TObject; Const Group, Identifier: TxNativeString;
      ParameterList: TParameterList; Var Expression: TExpression );
    Function GetExplicitParam( const ParamName: TxNativeString ): TxNativeString;
    function AddExpression(Expression: TExpression): TExpression;
    function GetParamList: TParameterList;
    function ForceParamList(Count: Integer): TParameterList;
    procedure GetTwoOperators;
    procedure GetOneOperator;
    procedure AddParam;
    function GetString( const s: TxNativeString ): TxNativeString;
  public
    SubqueryExpr: TExpression; // used for subqueries only (special case)
    CheckData: TCheckData; // used when checking expression
    Expression: TExpression; // the real expression to evaluate

    constructor Create(SqlAnalizer: TObject; DataSet: TDataSet); overload;
    constructor Create(SqlAnalizer: TObject;
     DataSet: TDataSet; aRuntimeSettings, aSystemSettings: TFormatSettings); overload;
    destructor Destroy; override;
    function yyparse : integer; override;
    function GetExpression: TExpression;
    Procedure ParseExpression( Const ExprStr: TxNativeString );
    Function CheckExpression( Const ExprStr: TxNativeString ): Boolean;

    Property ReferencedDataSets: TReferencedDataSetList Read fReferencedDataSets Write fReferencedDataSets;
    Property IdReferences: TStrings Read FIdReferences;

    property IsComplex: Boolean read FIsComplex write FIsComplex;
  end;

const _IDENTIFIER = 257;
const _UINTEGER = 258;
const _SINTEGER = 259;
const _NUMERIC = 260;
const _STRING = 261;
const _COMA = 262;
const _LPAREN = 263;
const _RPAREN = 264;
const _PERIOD = 265;
const _COLON = 266;
const RW_OR = 267;
const RW_XOR = 268;
const RW_AND = 269;
const _EQ = 270;
const _NEQ = 271;
const _GT = 272;
const _LT = 273;
const _GE = 274;
const _LE = 275;
const RW_BETWEEN = 276;
const RW_IN = 277;
const RW_LIKE = 278;
const _PLUS = 279;
const _SUB = 280;
const _DIV = 281;
const RW_DIV = 282;
const _MULT = 283;
const RW_MOD = 284;
const RW_SHL = 285;
const RW_SHR = 286;
const UMINUS = 287;
const _EXP = 288;
const RW_NOT = 289;
const _ILLEGAL = 290;
const _COMMENT = 291;
const _BLANK = 292;
const _TAB = 293;
const _NEWLINE = 294;
const RW_TRUE = 295;
const RW_FALSE = 296;
const RW_STRING = 297;
const RW_FLOAT = 298;
const RW_INTEGER = 299;
const RW_BOOLEAN = 300;
const RW_CASE = 301;
const RW_WHEN = 302;
const RW_THEN = 303;
const RW_ELSE = 304;
const RW_END = 305;
const RW_IF = 306;
const RW_CAST = 307;
const RW_AS = 308;
const RW_ESCAPE = 309;

{type YYSType = record
               yystring : string
               end(*YYSType*);
}(*moved to QlexLib.YYSType*) {modified by fduenas: make TP Yacc/Lex thread safe)}
// global definitions:

//var yylval : YYSType; {modified by fduenas: make TP Yacc/Lex thread safe)}

implementation

uses
  xquery, xqmiscel, Math, xqconsts, qlexlib, QExprLex, xqbase{$IFDEF LEVEL4}, WideStrUtils{$ENDIF};

Constructor TReferencedDataSetItem.Create( RefDataSetList:
  TReferencedDataSetList );
Begin
  Inherited Create;
  fReferencedDataSets := RefDataSetList;
End;

Constructor TReferencedDataSetList.Create;
Begin
  Inherited Create;
  fItems := TList.Create;
End;

Destructor TReferencedDataSetList.Destroy;
Begin
  Clear;
  fItems.Free;
  Inherited Destroy;
End;

Function TReferencedDataSetList.GetCount: Integer;
Begin
  Result := fItems.Count;
End;

Function TReferencedDataSetList.GetItem( Index: Integer ): TReferencedDataSetItem;
Begin
  Result := fItems[Index];
End;

Function TReferencedDataSetList.Add: TReferencedDataSetItem;
Begin
  Result := TReferencedDataSetItem.Create( Self );
  fItems.Add( Result );
End;

Procedure TReferencedDataSetList.Clear;
Var
  I: Integer;
Begin
  For I := 0 To fItems.Count - 1 Do
    TReferencedDataSetItem( fItems[I] ).Free;
  fItems.Clear;
End;

Procedure TReferencedDataSetList.Delete( Index: Integer );
Begin
  TReferencedDataSetItem( fItems[Index] ).Free;
  fItems.Delete( Index );
End;

Function TReferencedDataSetList.IndexOf( DataSet: TDataSet ): Integer;
Var
  I: Integer;
Begin
  result := -1;
  For I := 0 To fItems.Count - 1 Do
    If TReferencedDataSetItem( fItems[I] ).Dataset = Dataset Then
    Begin
      result := I;
      Exit;
    End;
End;

Type

  TExplicitParamExpr = Class( TExpression )
  Private
    fAnalizer: TSqlAnalizer;
    fParam: TParam;
  Protected
    Function GetAsString: String; Override;
   {$IFDEF LEVEL4}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
   {$ENDIF}
    Function GetAsFloat: Double; Override;
    Function GetAsInteger: Integer; Override;
    Function GetAsLargeInt: Int64; Override; {added by fduenas: added LargeInt (Int64) support}
    Function GetAsBoolean: Boolean; Override;
    Function GetExprType: TExprtype; Override;
    Function GetIsNull: boolean; Override;
  Public
    Constructor Create( Analizer: TSqlAnalizer; Param: TParam );
  End;

  TFieldExpr = Class( TFunctionExpr )
  Private
    FField: TField;
    FxQuery: TCustomxQuery;
    FParser: TExprParser;
  Protected
    Function GetMaxString: String; Override;
    Function GetAsString: String; Override;
   {$IFDEF LEVEL4}
    Function GetMaxWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
   {$ENDIF}
    Function GetAsFloat: Double; Override;
    Function GetAsInteger: Integer; Override;
    Function GetAsLargeInt: Int64; Override; {added by fduenas: added LargeInt (Int64) support}
    Function GetAsBoolean: Boolean; Override;
    Function GetExprType: TExprtype; Override;
    Function GetIsNull: boolean; Override;
    function StringCharSize: integer; override; { patched by ccy }
  Public
    Constructor Create( ParameterList: TParameterList;
      F: TField; xQuery: TCustomxQuery; Parser: TExprParser );
    Property Field: TField Read FField;
  End;

  TResultSetFieldExpr = Class( TFunctionExpr )
  Private
    fxqField: TxqField;
  Protected
    Function GetAsString: String; Override;
   {$IFDEF LEVEL4}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
   {$ENDIF}
    Function GetAsFloat: Double; Override;
    Function GetAsInteger: Integer; Override;
    Function GetAsLargeInt: Int64; Override; {added by fduenas: added LargeInt (Int64) support}
    Function GetAsBoolean: Boolean; Override;
    Function GetExprType: TExprtype; Override;
    Function GetIsNull: boolean; Override;
  Public
    Constructor Create( ParameterList: TParameterList; xqField: TxqField );
  End;

  TStrToDateExpr = Class( TFunctionExpr )
  Protected
    Function GetAsFloat: Double; Override;
    function GetExprType: TExprtype; override;
  End;

  TNowExpr = Class( TFunctionExpr )
  Protected
    Function GetAsFloat: Double; Override;
    function GetExprType: TExprtype; override;
  End;

  TSQLTrimExpr = Class( TFunctionExpr )
  Protected
    Function GetMaxString: String; Override;
    Function GetAsString: String; Override;
   {$IFDEF LEVEL4}
    Function GetMaxWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
   {$ENDIF}
    function GetExprType: TExprtype; override;
  End;

  TRoundDecExpr = Class( TFunctionExpr )
  Private
    FIsRound: Boolean;
  Protected
    function GetAsFloat: Double; Override;
    function GetExprType: TExprtype; override;
  Public
    Constructor Create(aName: string; ParameterList: TParameterList; IsRound: Boolean );
  End;

  TUDFExpr = Class( TFunctionExpr )
  Private
    FxQuery: TCustomXQuery;
    FResultType: TExprtype;
    FParams: TParameterList;
    FMaxLen: Integer;
  Protected
    Function GetMaxString: String; Override;
    Function GetAsString: String; Override;
   {$IFDEF LEVEL4}
    Function GetMaxWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
   {$ENDIF}
    Function GetAsFloat: Double; Override;
    Function GetAsInteger: Integer; Override;
    Function GetAsLargeInt: Int64; Override; {added by fduenas: added LargeInt (Int64) support}
    Function GetAsBoolean: Boolean; Override;
    function GetExprType: TExprtype; override;
  Public
    Constructor Create( ParameterList: TParameterList; xQuery: TCustomXQuery;
      Const Identifier: String; ResultType: TExprtype; MaxLen: Integer );
  End;

  { use IFNULL to get a default value if the field has a NULL value }
  TIFNULLExpr = Class( TFunctionExpr )
  Protected
    Function CheckParameters: Boolean; Override;
    Function GetMaxString: String; Override;
    Function GetAsString: String; Override;
   {$IFDEF LEVEL4}
    Function GetMaxWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
   {$ENDIF}
    Function GetAsFloat: Double; Override;
    Function GetAsInteger: Integer; Override;
    Function GetAsLargeInt: Int64; Override;
    Function GetAsBoolean: Boolean; Override;
    Function GetExprType: TExprtype; override;
  End;

  { use ISNULL to test only if a Field has a NULL value }
  TISNULLExpr = Class( TFunctionExpr )
  Protected
    Function CheckParameters: Boolean; Override;
    Function GetMaxString: String; Override;
    Function GetAsString: String; Override;
   {$IFDEF LEVEL4}
    Function GetMaxWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
   {$ENDIF}
    Function GetAsFloat: Double; Override;
    Function GetAsInteger: Integer; Override;
    Function GetAsLargeInt: Int64; Override;
    Function GetAsBoolean: Boolean; Override;
    Function GetExprType: TExprtype; override;
  End;

  TNULLValueExpr = Class( TFunctionExpr )
  Protected
    Function GetAsBoolean: Boolean; Override;
    function GetExprType: TExprtype; override;
  End;

  TFilterFieldExpr = Class( TFunctionExpr )
  Private
    fField: TField;
  Protected
    Function GetAsString: String; Override;
    {$IFDEF LEVEL4}
    Function GetAsWideString: WideString; Override; {added by fduenas: added WideString (Delphi4Up) support}
    {$ENDIF}
    Function GetAsFloat: Double; Override;
    Function GetAsInteger: Integer; Override;
    Function GetAsLargeInt: Int64; Override; {added by fduenas: added LargeInt (Int64) support}
    Function GetAsBoolean: Boolean; Override;
    function GetExprType: TExprtype; override;
  Public
    Constructor Create(aName: string; ParameterList: TParameterList; F: TField );
  End;

Constructor TFieldExpr.Create( ParameterList: TParameterList;
  F: TField; xQuery: TCustomxQuery; Parser: TExprParser );
Begin
  Inherited Create( ParameterList );
  fField := F;
  fxQuery := xQuery;
  fParser := Parser;
End;

Function TFieldExpr.GetExprType: TExprtype;
Begin
  If Not(fField.Datatype In [ftMemo, ftFmtMemo{$IFDEF Delphi2006Up}, ftWideMemo{$ENDIF}]) And (fField.Datatype In ftNonTexttypes) Then
    Result := ttInteger
  Else
  Begin
    Case fField.Datatype Of
      ftString, ftMemo, ftFmtMemo(*$IFDEF LEVEL4*), ftFixedChar(*$ENDIF*)(*$IFDEF LEVEL5*), ftGUID(*$ENDIF*):
        Result := ttString;
     {$IFDEF LEVEL4}
      ftWideString, ftFixedWideChar {$IFDEF Delphi2006Up}, ftWideMemo{$ENDIF}:
        Result := ttWideString;
     {$ENDIF}
      ftFloat, ftCurrency, ftBCD,{$IFDEF LEVEL6}ftFMTBcd, ftTimeStamp,{$ENDIF}ftDate,
        ftTime, ftDateTime:
        Result := ttFloat; { changed by fduenas: ftLargeInt moved below}
      ftAutoInc, ftSmallInt, {$IFDEF Delphi2009Up} ftShortInt, {$ENDIF} ftInteger, ftWord:
        Result := ttInteger;
     {$IFDEF LEVEL4}
      ftLargeInt:
        Result := ttLargeInt;
     {$ENDIF}
      ftBoolean:
        Result := ttBoolean;
    Else
      result := ttString;
    End;
  End;
End;

Function TFieldExpr.GetMaxString: String;
Begin
  If (Not( fField.Datatype In [ftMemo, ftFmtMemo{$IFDEF Delphi2006Up}, ftWideMemo {$ENDIF}] )) And
        ( fField.DataType In ftNonTextTypes ) Then
  begin
  end else
  Begin
    If ( fField.DataType In [ftString, ftMemo, ftFmtMemo (*$IFDEF LEVEL4*), ftFixedChar,
         ftWideString, ftFixedWideChar(*$ENDIF*){$IFDEF Delphi2006Up}, ftWideMemo{$ENDIF}
(*$IFDEF LEVEL5*), ftGUID(*$ENDIF*)] ) Then
    Begin
      if fField.DataType In [ftMemo, ftFmtMemo{$IFDEF Delphi2006Up}, ftWideMemo{$ENDIF}] then
      begin
        Result:= StringOfChar( 'X', 10 );
      end else
      begin
        Result:= StringOfChar( 'X', fField.Size );
      end;
    End
    else
    begin
      {patched by fduenas: non ttString Types used in String Functions like Upper(IntegerField)
      {without casting it to string first, causes to display wrong values because 'Result' was and empty string}
      {the correct way should be: Upper(FormatFloat('0', IntegerField))}
      {but now string functions can receive any other type of parameters}
      try
       if FField.DataSize > 0 then
          result := StringOfChar( 'X', FField.DataSize )
       else
          result := StringOfChar( 'X', Length(VarToStr( FField.Value )) );
      except

      end;
    end;
  End;
End;
{$IFDEF LEVEL4}
function TFieldExpr.GetMaxWideString: WideString;
Begin
  If (Not( fField.Datatype In [ftMemo, ftFmtMemo{$IFDEF Delphi2006Up}, ftWideMemo{$ENDIF}] )) And
        ( fField.DataType In ftNonTextTypes ) Then
  begin
  end else
  Begin
    If ( fField.DataType In [ftString, ftMemo, ftFmtMemo (*$IFDEF LEVEL4*), ftFixedChar,
      ftWideString, ftFixedWideChar(*$ENDIF*){$IFDEF Delphi2006Up}, ftWideMemo{$ENDIF}
(*$IFDEF LEVEL5*), ftGUID(*$ENDIF*)] ) Then
    Begin
      if fField.DataType In [ftMemo, ftFmtMemo{$IFDEF Delphi2006Up}, ftWideMemo{$ENDIF}] then
      begin
        Result:= StringOfChar('X', 10);
      end else
      begin
        Result:= StringOfChar('X', fField.Size);
      end;
    End
    else
    begin
      {patched by fduenas: non ttString Types used in String Functions like Upper(IntegerField)
      {without casting it to string first, causes to display wrong values because 'Result' was and empty string}
      {the correct way should be: Upper(FormatFloat('0', IntegerField))}
      {but now string functions can receive any other type of parameters}
      try
       if FField.DataSize > 0 then
          result := StringOfChar('X', FField.DataSize)
       else
          result := StringOfChar('X', Length(VarToStr( FField.Value )));
      except

      end;
    end;
  End;
End;
{$ENDIF}

function TFieldExpr.StringCharSize: integer; { patched by ccy }
begin
{$IFDEF LEVEL4}
  if Field.DataType in [ ftWideString, ftFixedWideChar{$IFDEF Delphi2006Up}, ftWideMemo {$ENDIF}] then
    Result := SizeOfFieldType(ftWideString)
  else
{$ENDIF}
    Result := SizeOfFieldType(ftString);
end;

Function TFieldExpr.GetAsString: String;
Begin
  Result := '';
  If FxQuery.IsDataSetDisabled( fField.DataSet ) Then Exit;

  If Not( fField.Datatype In [ftMemo, ftFmtMemo{$IFDEF Delphi2006Up}, ftWideMemo {$ENDIF}] ) And
        ( fField.DataType In ftNonTextTypes ) Then
  begin
  end else
  Begin
   {$IFDEF LEVEL4}
    if  FField.DataType in [ftWideString, ftFixedWideChar {$IFDEF Delphi2006Up}, ftWideMemo {$ENDIF}] then
        Result := FField.AsWideString
    else
  {$ENDIF}
        Result := fField.AsString;

  End;
End;
{$IFDEF LEVEL4}
function TFieldExpr.GetAsWideString: WideString;
Begin
  Result := '';
  If FxQuery.IsDataSetDisabled( fField.DataSet ) Then Exit;

  If Not( fField.Datatype In [ftMemo, ftFmtMemo{$IFDEF Delphi2006Up}, ftWideMemo {$ENDIF}] ) And
        ( fField.DataType In ftNonTextTypes ) Then
  begin
  end else
  Begin
    Result := fField.AsWideString;
  End;
End;
{$ENDIF}
Function TFieldExpr.GetAsFloat: Double;
Begin
  Result := 0;
  If FxQuery.IsDataSetDisabled( fField.DataSet ) Then Exit;
{$IFDEF LEVEL6}
  if fField.DataType = ftTimeStamp then
    // meantime ftTimeStamp is supported
    Result := fField.AsDateTime
  else
{$ENDIF}
    Result := fField.AsFloat;
End;

Function TFieldExpr.GetAsInteger: Integer;
Begin
  Result := 0;
  If FxQuery.IsDataSetDisabled( fField.DataSet ) Then
    Exit;
  Result := fField.AsInteger;
End;

function TFieldExpr.GetAsLargeInt: Int64;
Begin
  Result := 0;
  If FxQuery.IsDataSetDisabled( fField.DataSet ) Then
    Exit;
  Result := {$IFDEF Delphi2010Up}fField.AsLargeInt{$ELSE}fField.Value{$ENDIF};

End;

Function TFieldExpr.GetAsBoolean: Boolean;
Begin
  Result := False;
  If FxQuery.IsDataSetDisabled( fField.DataSet ) Then
    Exit;
  Result := fField.AsBoolean;
End;

//unley

Function TFieldExpr.GetIsNull: boolean;
Begin
  If FxQuery.IsDataSetDisabled( fField.DataSet ) Then
  Begin
    Result := True;
    Exit;
  End;
  Result := fField.IsNull;
End;

//
Constructor TResultSetFieldExpr.Create( ParameterList: TParameterList; xqField: TxqField );
Begin
  Inherited Create( ParameterList );
  fxqField := xqField;
End;

Function TResultSetFieldExpr.GetAsString: String;
Begin
  Result := fxqField.AsString;
End;
{$IFDEF LEVEL4}
function TResultSetFieldExpr.GetAsWideString: WideString;
begin
 Result := fxqField.AsWideString;
end;
{$ENDIF}
Function TResultSetFieldExpr.GetAsFloat: Double;
Begin
  Result := fxqField.AsFloat;
End;

Function TResultSetFieldExpr.GetAsInteger: Integer;
Begin
  Result := fxqField.AsInteger;
End;

function TResultSetFieldExpr.GetAsLargeInt: Int64;
begin
  Result := fxqField.AsLargeInt;
end;

Function TResultSetFieldExpr.GetAsBoolean: Boolean;
Begin
  Result := fxqField.AsBoolean;
End;

Function TResultSetFieldExpr.GetExprType: TExprtype;
Begin
  Result := fxqField.DataType;
End;

Function TResultSetFieldExpr.GetIsNull: boolean;
Begin
  Result := fxqField.IsNull;
End;

//TNowExpr

function TNowExpr.GetAsFloat: Double;
begin
  Result := Now;
end;

function TNowExpr.GetExprType: TExprtype;
begin
  Result:= ttFloat;
end;

//TStrToDate

Function TStrToDateExpr.GetAsFloat: Double;
Begin
  Try
    Result := StrToDate( Param[0].AsString{$IFDEF Delphi7Up}, fRuntimeFormatSettings{$ENDIF} );
  Except
    On E: Exception Do
    Begin
      MessageToUser( E.Message, mtError );
      Result := 0;
    End;
  End;
End;

function TStrToDateExpr.GetExprType: TExprtype;
Begin
  Result := ttFloat;
End;

//TSQLTrimExpr

Function SQLTrim( trimmed_char: char; Const S: String ): String;
Var
  I, L: Integer;
Begin
  L := Length( S );
  I := 1;
  While ( I <= L ) And ( S[I] = trimmed_char ) Do
    Inc( I );
  If I > L Then
    Result := ''
  Else
  Begin
    While S[L] = trimmed_char Do
      Dec( L );
    Result := Copy( S, I, L - I + 1 );
  End;
End;

Function SQLTrimLeft( trimmed_char: char; Const S: String ): String;
Var
  I, L: Integer;
Begin
  L := Length( S );
  I := 1;
  While ( I <= L ) And ( S[I] = trimmed_char ) Do
    Inc( I );
  Result := Copy( S, I, Maxint );
End;

Function SQLTrimRight( trimmed_char: char; Const S: String ): String;
Var
  I: Integer;
Begin
  I := Length( S );
  While ( I > 0 ) And ( S[I] = trimmed_char ) Do
    Dec( I );
  Result := Copy( S, 1, I );
End;
{$IFDEF LEVEL4}
Function SQLTrimW( trimmed_char: WideChar; Const S: WideString ): WideString;
Var
  I, L: Integer;
Begin
  L := Length( S );
  I := 1;
  While ( I <= L ) And ( S[I] = trimmed_char ) Do
    Inc( I );
  If I > L Then
    Result := ''
  Else
  Begin
    While S[L] = trimmed_char Do
      Dec( L );
    Result := Copy( S, I, L - I + 1 );
  End;
End;

Function SQLTrimLeftW( trimmed_char: WideChar; Const S: WideString ): WideString;
Var
  I, L: Integer;
Begin
  L := Length( S );
  I := 1;
  While ( I <= L ) And ( S[I] = trimmed_char ) Do
    Inc( I );
  Result :=  Copy( S, I, Maxint );
End;

Function SQLTrimRightW( trimmed_char: WideChar; Const S: WideString ): WideString;
Var
  I: Integer;
Begin
  I := Length( S );
  While ( I > 0 ) And ( S[I] = trimmed_char ) Do
    Dec( I );
  Result := Copy( S, 1, I );
End;
{$ENDIF}
Function TSQLTrimExpr.GetAsString: String;
Begin
  Case Param[2].AsInteger Of
    0: // leading
      Result := SQLTrimLeft( Param[0].AsString[1], Param[1].AsString );
    1: // trailing
      Result := SQLTrimRight( Param[0].AsString[1], Param[1].AsString );
    2: // both
      Result := SQLTrim( Param[0].AsString[1], Param[1].AsString );
  End;
End;

Function TSQLTrimExpr.GetMaxString: String;
Begin
  Case Param[2].AsInteger Of
    0: // leading
      Result := SQLTrimLeft( Param[0].AsString[1], Param[1].MaxString );
    1: // trailing
      Result := SQLTrimRight( Param[0].AsString[1], Param[1].MaxString );
    2: // both
      Result := SQLTrim( Param[0].AsString[1], Param[1].MaxString );
  End;
End;
{$IFDEF LEVEL4}
function TSQLTrimExpr.GetAsWideString: WideString;
Begin
  Case Param[2].AsInteger Of
    0: // leading
      Result := SQLTrimLeftW( Param[0].AsWideString[1], Param[1].AsWideString );
    1: // trailing
      Result := SQLTrimRightW( Param[0].AsWideString[1], Param[1].AsWideString );
    2: // both
      Result := SQLTrimW( Param[0].AsWideString[1], Param[1].AsWideString );
  End;
End;

function TSQLTrimExpr.GetMaxWideString: WideString;
Begin
  Case Param[2].AsInteger Of
    0: // leading
      Result := SQLTrimLeftW( Param[0].AsWideString[1], Param[1].MaxWideString );
    1: // trailing
      Result := SQLTrimRightW( Param[0].AsWideString[1], Param[1].MaxWideString );
    2: // both
      Result := SQLTrimW( Param[0].AsWideString[1], Param[1].MaxWideString );
  End;
End;
{$ENDIF}
function TSQLTrimExpr.GetExprType: TExprtype;
Begin
{$IFDEF LEVEL4}
 if Param[1].ExprType=ttWideString then
    Result := ttWideString
 else
{$ENDIF}
    Result := ttString;
End;

//TRoundDecExpr

Constructor TRoundDecExpr.Create(aName: string; ParameterList: TParameterList;
  IsRound: Boolean );
Begin
  Inherited Create(aName,  ParameterList );
  FIsRound := IsRound;
End;

Function TRoundDecExpr.GetAsFloat: Double;
Begin
  If Param[1].AsInteger = 0 Then
    Result := Param[0].AsFloat
  Else
    Result := Param[0].AsFloat * IntPower( 10, Param[1].AsInteger );
  If FIsRound Then
    Result := Result + 0.5;
  If Param[1].AsInteger > 0 Then
    Result := Int( Result ) / IntPower( 10, Param[1].AsInteger );
End;

function TRoundDecExpr.GetExprType: TExprtype;
Begin
  Result := ttFloat;
End;

{ TISNULLExpr }
{ use IFNULL to get a default value if the field has a NULL value }
function TIFNULLExpr.CheckParameters: Boolean;
var _errorMsg: string;
begin
 result := (ParameterCount >=1) and (ParameterCount <=2);
 If not Result then
    _errorMsg:= SEXPR_WRONGPARAMETERCOUNT
 else if (ParameterCount=2) then
 begin
  result := (Param[0].ExprType = Param[1].ExprType);
  if not result then
     _errorMsg:= SEXPR_PARAMETERSTYPEDIFFERENT
 end;

 If Not result Then
    raise EExpression.CreateFmt( _errorMsg,
      [GetExprName])
end;

Function TIFNULLExpr.GetAsBoolean: Boolean;
Begin
  CheckParameters;
  Result := Param[0].IsNull;
  if (ParameterCount=2) then
      if Result then
         Result := Param[1].AsBoolean
       else
         Result := Param[0].AsBoolean
End;

function TIFNULLExpr.GetAsFloat: Double;
begin
  CheckParameters;
  if (Param[0].IsNull) then
      if (ParameterCount=2) then
          Result := Param[1].AsFloat
      else
          Result := Param[0].AsFloat
  else
      if (ParameterCount=2) then
          Result := Param[0].AsFloat
      else
          if GetAsBoolean then
             Result := 1
          else
             Result := 0;
end;

function TIFNULLExpr.GetAsInteger: Integer;
begin
  CheckParameters;
  if (Param[0].IsNull) then
      if (ParameterCount=2) then
          Result := Param[1].AsInteger
      else
          Result := Param[0].AsInteger
  else
      if (ParameterCount=2) then
          Result := Param[0].AsInteger
      else
          if GetAsBoolean then
             result := 1
          else
             Result := 0;
end;

function TIFNULLExpr.GetAsLargeInt: Int64;
begin
  CheckParameters;
  if (Param[0].IsNull) then
      if (ParameterCount=2) then
          Result := Param[1].AsLargeInt
      else
          Result := Param[0].AsLargeInt
  else
      if (ParameterCount=2) then
          Result := Param[0].AsLargeInt
      else
          if GetAsBoolean then
             result := 1
          else
             Result := 0;
end;

function TIFNULLExpr.GetAsString: String;
begin
  CheckParameters;
    if (Param[0].IsNull) then
      if (ParameterCount=2) then
          Result := Param[1].AsString
      else
          Result := Param[0].AsString
    else
      if (ParameterCount=2) then
          Result := Param[0].AsString
      else
         Result := NBoolean[GetAsBoolean];
end;
{$IFDEF LEVEL4}
function TIFNULLExpr.GetAsWideString: WideString;
begin
  CheckParameters;
    if (Param[0].IsNull) then
      if (ParameterCount=2) then
          Result := Param[1].AsWideString
      else
          Result := Param[0].AsWideString
  else
      if (ParameterCount=2) then
          Result := Param[0].AsWideString
      else
         Result := NBoolean[GetAsBoolean];
end;
{$ENDIF}
function TIFNULLExpr.GetExprType: TExprtype;
Begin
 if (ParameterCount=2) then
     result := Param[1].ExprType
 else
     result := ttBoolean;
End;

function TIFNULLExpr.GetMaxString: String;
begin
  CheckParameters;
    if (Param[0].IsNull) then
      if (ParameterCount=2) then
          if Length(Param[0].MaxString) > length(Param[1].MaxString) then
             Result := Param[0].MaxString
          else
             Result := Param[1].MaxString
  else
      if (ParameterCount=2) then
          Result := Param[0].MaxString
      else
          Result := NBoolean[False];
end;
{$IFDEF LEVEL4}
function TIFNULLExpr.GetMaxWideString: WideString;
begin
  CheckParameters;
    if (Param[0].IsNull) then
      if (ParameterCount=2) then
          if Length(Param[0].MaxWideString) > Length(Param[1].MaxWideString) then
             Result := Param[0].MaxWideString
          else
             Result := Param[1].MaxWideString
  else
      if (ParameterCount=2) then
          Result := Param[0].MaxWideString
      else
          Result := NBoolean[False];
end;
{$ENDIF}
//TNULLValueExpr

Function TNULLValueExpr.GetAsBoolean: Boolean;
Begin
  Result := True;
End;

function TNULLValueExpr.GetExprType: TExprtype;
Begin
 Result := ttBoolean;
End;

//functions defined in Exfunctions property

Constructor TUDFExpr.Create( ParameterList: TParameterList; xQuery:
  TCustomXQuery; Const Identifier: String; ResultType: TExprtype;
  MaxLen: Integer );
Begin
  Inherited Create(Identifier, ParameterList );
  FxQuery := xQuery;
  FParams := ParameterList;
  FResultType := ResultType;
  FMaxLen := MaxLen;
End;

function TUDFExpr.GetExprType: TExprtype;
Begin
  Result := FResultType;
End;

Function TUDFExpr.GetMaxString: String;
Var
  MxL: Integer;
Begin
  Result:= '';
  if Not (FResultType in [ttString{$IFDEF LEVEL4}, ttWideString{$ENDIF}]) then Exit;
  MxL:= FMaxLen;
  if MxL = 0 then MxL := 1;
  Result:= StringOfChar( 'x', MxL );
End;
{$IFDEF LEVEL4}
function TUDFExpr.GetMaxWideString: WideString;
Var
  MxL: Integer;
Begin
  Result:= '';
  if Not (FResultType in [ttString, ttWideString]) then Exit;
  MxL:= FMaxLen;
  if MxL = 0 then MxL := 1;
  Result:= StringOfChar( 'x', MxL );
End;
{$ENDIF}
Function TUDFExpr.GetAsString: String;
Var
  Value: variant;
Begin
  Value := Null;
  Result := '';
  FxQuery.OnUDFSolve( FxQuery, fExprName, FParams, Value );
  If vartype( Value ) <> varNull Then
    Result := Value; // varAstype(Value, varString);
End;
{$IFDEF LEVEL4}
function TUDFExpr.GetAsWideString: WideString;
Var
  Value: variant;
Begin
  Value := Null;
  Result := '';
  FxQuery.OnUDFSolve( FxQuery, fExprName, FParams, Value );
  If VarType( Value ) <> varNull Then
    Result := Value; // varAstype(Value, varString);
End;
{$ENDIF}
Function TUDFExpr.GetAsFloat: Double;
Var
  Value: variant;
Begin
  Value := Null;
  Result := 0;
  FxQuery.OnUDFSolve( FxQuery, FExprName, FParams, Value );
  If vartype( Value ) <> varNull Then
    Result := Value; // varAstype(Value, varDouble);
End;

Function TUDFExpr.GetAsInteger: Integer;
Var
  Value: variant;
Begin
  Value := Null;
  Result := 0;
  FxQuery.OnUDFSolve( FxQuery, FExprName, FParams, Value );
  If vartype( Value ) <> varNull Then
    Result := Value; // varAstype(Value, varInteger);
End;

function TUDFExpr.GetAsLargeInt: Int64;
Var
  Value: variant;
Begin
  Value := Null;
  Result := 0;
  FxQuery.OnUDFSolve( FxQuery, FExprName, FParams, Value );
  If vartype( Value ) <> varNull Then
    Result := Value; // varAstype(Value, varInteger);
End;

Function TUDFExpr.GetAsBoolean: Boolean;
Var
  Value: variant;
Begin
  Value := Null;
  Result := False;
  FxQuery.OnUDFSolve( FxQuery, fExprName, FParams, Value );
  If vartype( Value ) <> varNull Then
    Result := Value; // varAstype(Value, varBoolean);
End;

// TFilterFieldExpr

Constructor TFilterFieldExpr.Create(aName: string; ParameterList: TParameterList; F: TField );
Begin
  Inherited Create(aName, ParameterList );
  fField := F;
End;

function TFilterFieldExpr.GetExprType: TExprtype;
Begin
  If fField.Datatype In ftNonTexttypes Then
    Result := ttInteger
  Else
    Case fField.Datatype Of
      ftString(*$IFDEF LEVEL4*), ftFixedChar(*$ENDIF*)(*$IFDEF LEVEL5*),
      ftGUID(*$ENDIF*): Result := ttString;
     (*$IFDEF LEVEL4*)
      ftWideString, ftFixedWideChar{$IFDEF Delphi2006Up}, ftWideMemo {$ENDIF}:
        Result := ttWideString;
     (*$ENDIF*)
      ftFloat, ftCurrency, ftBCD, {$IFDEF LEVEL6}ftFMTBcd, ftTimeStamp,{$ENDIF}
      ftDate, ftTime, ftDateTime: Result := ttFloat; {ftTimeStamp added 2013-04-25}
      ftAutoInc, ftSmallInt, {$IFDEF Delphi2009Up}ftShortInt,{$ENDIF} ftInteger, ftWord:
       Result := ttInteger;
(*$IFDEF LEVEL4*)
      ftLargeInt: Result := ttLargeInt;
(*$ENDIF*)
      ftBoolean: Result := ttBoolean;
    Else
      result := ttString;
    End;
End;

Function TFilterFieldExpr.GetAsString: String;
Begin
  Result := '';
  If Not ( fField.Datatype In ftNonTexttypes ) Then
    Result := fField.AsString;
End;
{$IFDEF LEVEL4}
function TFilterFieldExpr.GetAsWideString: WideString;
begin
  Result := '';
  If Not ( fField.Datatype In ftNonTexttypes ) Then
    Result := fField.AsWideString;
end;
{$ENDIF}
Function TFilterFieldExpr.GetAsFloat: Double;
Begin
  Result := fField.AsFloat;
End;

Function TFilterFieldExpr.GetAsInteger: Integer;
Begin
  Result := fField.AsInteger;
End;

function TFilterFieldExpr.GetAsLargeInt: Int64;
begin
  Result := fField.{$IFDEF Delphi2010}AsLargeInt{$ELSE}Value{$ENDIF};
end;

Function TFilterFieldExpr.GetAsBoolean: Boolean;
Begin
  Result := fField.AsBoolean;
End;

// TExplicitParamExpr
Constructor TExplicitParamExpr.Create( Analizer: TSqlAnalizer; Param: TParam );
Begin
  Inherited Create;
  fAnalizer:= Analizer;
  fParam:= Param;
  if fParam = Nil then
    Raise ExQueryError.Create( SParameterNotFound );
End;

Function TExplicitParamExpr.GetExprType: TExprtype;
var
  DataType: TFieldType;
  DataSet: TDataSet;
  fld: TField;
Begin
  Result:= ttString;
  if fAnalizer.xquery.DataSource <> Nil then
  begin
    DataSet := fanalizer.xquery.DataSource.DataSet;
    If DataSet = Nil Then exit;
    if DataSet.Active = False Then DataSet.Open;
    fld := DataSet.FindField(fParam.Name);
    if fld = nil then Exit;
    DataType:= fld.DataType
  end else
    DataType:= fParam.DataType;
  If Not(Datatype In [ftMemo, ftFmtMemo]) And (fParam.Datatype In ftNonTexttypes) Then
    Result := ttInteger
  Else
  Begin
    Case Datatype Of
      ftString, ftMemo, ftFmtMemo(*$IFDEF LEVEL4*), ftFixedChar(*$ENDIF*)
(*$IFDEF LEVEL5*), ftGUID(*$ENDIF*): Result := ttString;
      (*$IFDEF LEVEL4*)
      ftWideString, ftFixedWideChar{$IFDEF Delphi2006Up}, ftWideMemo  {$ENDIF}:
         Result := ttWideString;
      (*$ENDIF*)
      ftFloat, ftCurrency, ftBCD,{$IFDEF LEVEL6}ftFMTBcd, ftTimeStamp,{$ENDIF}
      ftDate, ftTime, ftDateTime: Result := ttFloat; {ftTimeStamp added 2013-04-25}
      ftAutoInc, ftSmallInt,{$IFDEF Delphi2009Up}ftShortint, {$ENDIF} ftInteger, ftWord:
        Result := ttInteger;
(*$IFDEF LEVEL4*)
      ftLargeInt: Result := ttLargeInt;
(*$ENDIF*)
      ftBoolean: Result := ttBoolean;
    Else
      result := ttString;
    End;
  End;
End;

Function TExplicitParamExpr.GetAsString: String;
var
  DataSet: TDataSet;
  fld: TField;
Begin
  Result:= '';
  if fAnalizer.xquery.DataSource <> Nil then
  begin
    DataSet := fanalizer.xquery.DataSource.DataSet;
    If DataSet = Nil Then exit;
    if DataSet.Active = False Then DataSet.Open;
    fld := DataSet.FindField(fParam.Name);
    if fld = nil then Exit;
    Result := fld.AsString;
  end else
    Result := fParam.AsString;
End;
{$IFDEF LEVEL4}
function TExplicitParamExpr.GetAsWideString: WideString;
var
  DataSet: TDataSet;
  fld: TField;
Begin
  Result:= '';
  if fAnalizer.xquery.DataSource <> Nil then
  begin
    DataSet := fanalizer.xquery.DataSource.DataSet;
    If DataSet = Nil Then exit;
    if DataSet.Active = False Then DataSet.Open;
    fld := DataSet.FindField(fParam.Name);
    if fld = nil then Exit;
    Result := fld.AsWideString;
  end else
    Result := fParam.AsWideString;
End;
{$ENDIF}
Function TExplicitParamExpr.GetAsFloat: Double;
var
  DataSet: TDataSet;
  fld: TField;
Begin
  Result:= 0;
  if fAnalizer.xquery.DataSource <> Nil then
  begin
    DataSet := fanalizer.xquery.DataSource.DataSet;
    If DataSet = Nil Then exit;
    if DataSet.Active = False Then DataSet.Open;
    fld := DataSet.FindField(fParam.Name);
    if fld = nil then Exit;
    Result := fld.AsFloat;
  end else
    Result := fParam.AsFloat;
End;

Function TExplicitParamExpr.GetAsInteger: Integer;
var
  DataSet: TDataSet;
  fld: TField;
Begin
  Result:= 0;
  if fAnalizer.xquery.DataSource <> Nil then
  begin
    DataSet := fanalizer.xquery.DataSource.DataSet;
    If DataSet = Nil Then exit;
    if DataSet.Active = False Then DataSet.Open;
    fld := DataSet.FindField(fParam.Name);
    if fld = nil then Exit;
    Result := fld.AsInteger;
  end else
    Result := fParam.AsInteger;
End;

function TExplicitParamExpr.GetAsLargeInt: Int64;
var
  DataSet: TDataSet;
  fld: TField;
Begin
  Result:= 0;
  if fAnalizer.xquery.DataSource <> Nil then
  begin
    DataSet := fanalizer.xquery.DataSource.DataSet;
    If DataSet = Nil Then exit;
    if DataSet.Active = False Then DataSet.Open;
    fld := DataSet.FindField(fParam.Name);
    if fld = nil then Exit;
    Result := fld.{$IFDEF Delphi2010Up}AsLargeInt{$ELSE}Value{$ENDIF};
  end else
    Result := fParam.{$IFDEF Delphi2009Up}AsLargeInt{$ELSE}Value{$ENDIF};
End;

Function TExplicitParamExpr.GetAsBoolean: Boolean;
var
  DataSet: TDataSet;
  fld: TField;
Begin
  Result:= false;
  if fAnalizer.xquery.DataSource <> Nil then
  begin
    DataSet := fanalizer.xquery.DataSource.DataSet;
    If DataSet = Nil Then exit;
    if DataSet.Active = False Then DataSet.Open;
    fld := DataSet.FindField(fParam.Name);
    if fld = nil then Exit;
    Result := fld.AsBoolean;
  end else
    Result := fParam.AsBoolean;
End;

//unley
Function TExplicitParamExpr.GetIsNull: boolean;
Begin
  Result := fParam.IsNull;
End;


//
constructor TExprParser.Create(SqlAnalizer: TObject; DataSet: TDataSet);
begin
  inherited Create;
  fDefaultDataSet := DataSet;
  fAnalizer := SqlAnalizer;
  fIdReferences := TStringList.Create;

  FExprList:= TList.Create;
  FStackedParamCount:= TList.Create;
  FGroupIdentList:= TStringList.create;
  FIdentifierList:= TStringList.create;
end;

constructor TExprParser.Create(SqlAnalizer: TObject;
 DataSet: TDataSet; aRuntimeSettings, aSystemSettings: TFormatSettings);
begin
 Create(SqlAnalizer, DataSet);
 yyRuntimeFormatSettings := aRuntimeSettings;
 yySystemFormatSettings := aSystemSettings;
end;

destructor TExprParser.Destroy;
var
  I: Integer;
begin
  Expression.Free;
  fIdReferences.Free;

  for I:= 0 to FExprList.Count-1 do
    TObject(FExprList[I]).Free;
  FExprList.Free;
  if FWhenParamList<>nil then
    FWhenParamList.Free;
  if FThenParamList<>nil then
    FThenParamList.Free;
  if FElseExpr<>nil then
    FElseExpr.Free;
  FStackedParamCount.Free;
  FGroupIdentList.free;
  FIdentifierList.free;
  inherited Destroy;
end;

Procedure TExprParser.IDFunc( Sender: TObject; Const Group, Identifier: TxNativeString;
  ParameterList: TParameterList; Var Expression: TExpression );
Var
  TmpDataSet: TDataSet;
  FieldName, TableName: String;
  Idx: Integer;
  F: TField;
  Accept: Boolean;
  _Params: TParameterList;
  xqField: TxqField;
  Datatype: TExprType;
  MaxLen: Integer;
Begin
  Expression := Nil;
  //NumError := 0;
  // The fields will be found in the result set
  If ( fAnalizer <> Nil ) And ( Length( Group ) > 0 ) And
     ( Length( Identifier ) > 0 ) And ( ParameterList = Nil ) Then
  Begin
    With TSqlAnalizer(fAnalizer) Do
    Begin
      If Not WhereContainsOnlyBasicFields And ( JoinList.Count > 0 ) Then
      Begin
        If (ResultSet <> Nil) Then
        Begin
          // received table.field notation
          FieldName := Group + '.' + Identifier;
          xqField := TSqlAnalizer(fAnalizer).ResultSet.FindField( FieldName );
          If (xqField <> Nil) Then
          begin
           if assigned(ParameterList) then
              _Params := ParameterList
           else
              _Params := TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings);
           Expression := TResultSetFieldExpr.Create( _Params, xqField );
          end;
        End;
      End;
    End;
    If Expression = Nil Then
    Begin
      // if was not found on the result set, search on table.field datasets
      TableName := Group;
      TmpDataSet := TSqlAnalizer(fAnalizer).FindDataSetByName( TableName );
      If Not Assigned( TmpDataSet ) Then
        Raise EExpression.Create( Format( SWrongDataSetname, [TableName] ) );
      FieldName := Identifier;
      If TmpDataSet = fDefaultDataSet Then
        Inc( CheckData.RefCount ); // number of primary dataset referenced
      (*else                                    // number of other datasets referenced in the expression
         Inc(CheckData.OtherRefCount);*)
      // create the list of datasets referenced in the expression
      If Assigned( fReferencedDataSets ) Then
      Begin
        Idx := fReferencedDataSets.IndexOf( TmpDataSet );
        If Idx >= 0 Then
          fReferencedDataSets[Idx].Count := fReferencedDataSets[Idx].Count + 1
        Else
          With fReferencedDataSets.Add Do
          Begin
            DataSet := TmpDataSet;
            Count := 1;
          End;
      End;
      // Create expression
      F := TmpDataSet.FindField( FieldName );
      If Assigned( F ) Then
      Begin
        _Params := TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings);
        _Params.Add( CreateStringLiteralObj( Group, yyRuntimeFormatSettings, yySystemFormatSettings ) );
        _Params.Add( CreateStringLiteralObj( Identifier, yyRuntimeFormatSettings, yySystemFormatSettings ) );
        Expression := TFieldExpr.Create( _Params, F, TSqlAnalizer(fAnalizer).xQuery, Self );
        If CheckData.RefCount = 1 Then
          CheckData.Field := F;
        Inc( CheckData.FieldCount );
        If CheckData.FieldCount <= MAX_INDEXED_FIELDS Then
          CheckData.Fields[CheckData.FieldCount] := F; // used in multi-key joining
      End
      Else
        Raise EExpression.CreateFmt( SWrongFieldName, [FieldName] );
    End;
  End;
  If Expression = Nil Then
  Begin
    If Identifier = 'NOW' Then
    begin
      CheckData.HasMorefunctions := True;
      If Not Assigned( ParameterList ) Then
        Expression := TNowExpr.Create(Identifier, TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings) );
      //else
        //NumError := 1;
    End
    Else If Identifier = 'SQLTRIM' Then // SQL TRIM function
    Begin
      CheckData.HasMorefunctions := True;
      If Assigned( ParameterList ) And ( ParameterList.Count = 3 ) Then
      Begin
        If Length( ParameterList.AsString[0] ) <> 1 Then
          Raise EExpression.Create( SWrongLengthInTrim );
        Expression := TSQLTrimExpr.Create(Identifier, ParameterList )
      End;
      //Else
      //  NumError := 1;
    End
    Else If ( Identifier = 'ROUNDDEC' ) Or ( Identifier = 'TRUNCDEC' ) Then
    Begin
      CheckData.HasMorefunctions := True;
      If Assigned( ParameterList ) And ( ParameterList.Count = 2 ) And
        ( ParameterList.Exprtype[0] In [ttFloat, ttInteger, ttLargeInt] ) And
        ( ParameterList.Exprtype[1] = ttInteger ) Then
      Begin
        Expression := TRoundDecExpr.Create(Identifier, ParameterList,
          ( AnsiCompareText( Identifier, 'ROUNDDEC' ) = 0 ) )
      End;
      //Else
      //  NumError := 1;
    End
    Else If (Identifier = 'IFNULL') Then // for use in sql select only
    Begin
      CheckData.HasMorefunctions := True;
      // not enough checking for now
      If Assigned( ParameterList ) And (ParameterList.Count > 0) Then
         Expression := TIFNULLExpr.Create(Identifier, ParameterList, yyRuntimeFormatSettings, yySystemFormatSettings );
      //Else
      //  NumError := 1;
    End
    Else If (Identifier = 'ISNULL') Then // for use in sql select only
    Begin
      CheckData.HasMorefunctions := True;
      // not enough checking for now
      If Assigned( ParameterList ) And (ParameterList.Count > 0) Then
         Expression := TISNULLExpr.Create(Identifier, ParameterList, yyRuntimeFormatSettings, yySystemFormatSettings );
      //Else
      //  NumError := 1;
    End Else if (fAnalizer = Nil) and (fDefaultDataSet <> Nil) then
    Begin
      // used in filter property in TxQuery
      // now look in the fDataSet fields
      F := fDefaultDataSet.FindField( Identifier );
      If Assigned( F ) Then
      Begin
        If Not Assigned( ParameterList ) Then
          Expression := TFilterFieldExpr.Create(Identifier, TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings), F );
        //Else
        //  NumError := 1;
      End;
    End;
  End;
  { RFC 1.80 }
  if (fAnalizer <> Nil) And (Expression = Nil) And
    Assigned(TSqlAnalizer(fAnalizer).xQuery.OnUDFCheck) And
    Assigned(TSqlAnalizer(fAnalizer).xQuery.OnUDFSolve) then
  Begin
    With TSqlAnalizer(fAnalizer) Do
    Begin // is this an UDF function ?
      Accept := False;
      Datatype:= ttString;
      MaxLen:= 0;
      if Assigned(ParameterList) then
         _Params := ParameterList
      else
         _Params := TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings); {To make sure an object is passed, 2012-04-24}
      xQuery.OnUDFCheck( xQuery, Identifier, _Params, Datatype, MaxLen, Accept );
      If Accept Then
      Begin
        if not assigned(_Params) then
           _Params := TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings);
        CheckData.HasMorefunctions := True;
        Expression := TUDFExpr.Create(_Params, xQuery, Identifier, DataType, MaxLen );
      End
      else if (_Params <> ParameterList) then
              FreeAndNil(_Params);
    End;
  End;

  //If NumError = 1 Then
    //Raise EExpression.CreateFmt( SWrongParameters, [Identifier] );
End;

Procedure TExprParser.ParseExpression( Const ExprStr: TxNativeString );
Var
  lexer: TCustomLexer;
  outputStream: TMemoryStream;
  errorStream: TMemoryStream;
  stream: TMemoryStream;
  ErrLine, ErrCol: Integer;
  ErrMsg, Errtxt: TxNativeString;
Begin
  If Length( ExprStr ) = 0 Then Exit;
  FillChar( CheckData, SizeOf( TCheckData ), #0 ); {must be #0 instead of 0}
  If Expression <> Nil Then
    FreeObject( Expression );
  Try
    If Length( ExprStr ) > 0 Then
    Begin
      stream := TMemoryStream.create;
      stream.write( ExprStr[1], Length( ExprStr ) * {$IFNDEF XQ_USE_SIZEOF_CONSTANTS}SizeOf(Char){$ELSE}XQ_SizeOf_Char{$ENDIF} ); { patched by ccy }
      stream.seek( 0, 0 );
      outputStream := TMemoryStream.create;
      errorStream := TMemoryStream.create;
      lexer := TExprLexer.Create;
      lexer.yyinput := Stream;
      lexer.yyoutput := outputStream;
      lexer.yyerrorfile := errorStream;
      lexer.yyRuntimeFormatSettings := self.yyRuntimeFormatSettings;
      lexer.yySystemFormatSettings := self.yySystemFormatSettings;

      // link to the identifier function
      yyLexer := lexer; // lexer and parser linked
      Try
        If yyparse = 1 Then
        Begin
          ErrLine := lexer.yylineno;
          ErrCol := lexer.yycolno - Lexer.yyTextLen - 1;
          ErrMsg := yyerrormsg;
          lexer.GetyyText (Errtxt);
          Raise EXQueryError.CreateFmt( SExprParserError, [ExprStr + ': ' + ErrMsg,
            ErrLine, ErrCol, ErrTxt] );
        End;
        Expression := GetExpression;
        CheckData.HasMorefunctions := CheckData.HasMorefunctions Or Self.IsComplex;
      Finally
        stream.free;
        lexer.free;
        outputstream.free;
        errorstream.free;
      End;
    End;
  Except
    On E: Exception Do
    Begin
      Expression := Nil;
      //MessageToUser(E.Message, smsgerror,MB_ICONERROR);
      Raise;
    End;
  End;
End;

Function TExprParser.CheckExpression( Const ExprStr: TxNativeString ): Boolean;
Var
  lexer: TCustomLexer;
  outputStream: TMemoryStream;
  errorStream: TMemoryStream;
  stream: TMemoryStream;
  ErrLine, ErrCol: Integer;
  ErrMsg, Errtxt: TxNativeString;
Begin
  FillChar( CheckData, SizeOf( TCheckData ), #0 ); {must be #0 instead of 0}
  Result := false;
  If Expression <> Nil Then
    FreeObject( Expression );
  Try
    If Length( ExprStr ) > 0 Then
    Begin
      stream := TMemoryStream.create;
      stream.write( ExprStr[1], Length( ExprStr ) * {$IFNDEF XQ_USE_SIZEOF_CONSTANTS}SizeOf(Char){$ELSE}XQ_SizeOf_Char{$ENDIF} ); { patched by ccy }
      stream.seek( 0, 0 );
      outputStream := TMemoryStream.create;
      errorStream := TMemoryStream.create;
      lexer := TExprLexer.Create;
      lexer.yyinput := Stream;
      lexer.yyoutput := outputStream;
      lexer.yyerrorfile := errorStream;
      lexer.yyRuntimeFormatSettings := self.yyRuntimeFormatSettings;
      lexer.yySystemFormatSettings := self.yySystemFormatSettings;
      // link to the identifier function
      yyLexer := lexer; // lexer and parser linked
      Try
        If yyparse = 1 Then
        Begin
          ErrLine := lexer.yylineno;
          ErrCol := lexer.yycolno - Lexer.yyTextLen - 1;
          ErrMsg := Self.yyerrormsg;
          lexer.GetyyText (Errtxt);
          Raise EXQueryError.CreateFmt( SExprParserError, [ErrMsg, ErrLine, ErrCol, ErrTxt] );
        End;
        Expression := Self.GetExpression;
        CheckData.HasMorefunctions := CheckData.HasMorefunctions Or IsComplex;
        Result := CheckData.RefCount > 0;
      Finally
        stream.free;
        lexer.free;
        outputstream.free;
        errorstream.free;
      End;
    End;
  Except
    On E: Exception Do
    Begin
      Expression := Nil;
      //MessageToUser(E.Message, smsgerror,MB_ICONERROR);
      Raise;
    End;
  End;
End;

Function TExprParser.GetString( const s: TxNativestring ): TxNativestring;
begin
  Result:= Copy( s, 2, Length(s) - 2);
end;

// this function returns the final expression obtained
function TExprParser.GetExpression: TExpression;
begin
  Result:= nil;
  if FExprList.Count<>1 then Exit;
  Result:= TExpression(FExprList[0]);
  FExprList.Delete(0);
end;

function TExprParser.GetParamList: TParameterList;
var
  I: Integer;
  NumParams: Integer;
begin
  Result:= nil;
  if FStackedParamCount.Count=0 then
    NumParams:= 0
  else
  begin
    NumParams:= TxNativeInt(FStackedParamCount[FStackedParamCount.Count-1]);
    FStackedParamCount.Delete(FStackedParamCount.Count-1);
  end;
  if (FExprList.Count=0) or (NumParams=0) or (NumParams>FExprList.Count) then Exit;
  Result:= TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings);
  for I:= 0 to NumParams - 1 do
      Result.Add(FExprList[FExprList.Count - NumParams + I]);
  while NumParams > 0 do
  begin
    FExprList.Delete(FExprList.Count-1);
    Dec(NumParams);
  end;
end;

function TExprParser.ForceParamList(Count: Integer): TParameterList;
var
  I: Integer;
  NumParams: Integer;
begin
  Result:= nil;
  NumParams:= Count;
  if (FExprList.Count=0) or (NumParams=0) or (NumParams>FExprList.Count) then Exit;
  Result:= TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings);
  for I:= 0 to NumParams - 1 do
    Result.Add(FExprList[FExprList.Count - NumParams + I]);
  while NumParams > 0 do
  begin
    FExprList.Delete(FExprList.Count-1);
    Dec(NumParams);
  end;
end;

procedure TExprParser.GetTwoOperators;
begin
  Op1:= TExpression(FExprList[FExprList.Count-2]);
  Op2:= TExpression(FExprList[FExprList.Count-1]);
  FExprList.Delete(FExprList.Count-1);
  FExprList.Delete(FExprList.Count-1);
end;

procedure TExprParser.GetOneOperator;
begin
  Op1:= TExpression(FExprList[FExprList.Count-1]);
  FExprList.Delete(FExprList.Count-1);
end;

procedure TExprParser.AddParam;
begin
  FParamCount:= TxNativeInt(FStackedParamCount[FStackedParamCount.Count-1]);
  Inc(FParamCount);
  FStackedParamCount[FStackedParamCount.Count-1]:= Pointer(FParamCount);
end;

function TExprParser.AddExpression(Expression: TExpression): TExpression;
begin
  FExprList.Add(Expression);
  FIsComplex:= True;
  Result:= Expression;
end;

Function TExprParser.GetExplicitParam( const ParamName: TxNativeString ): TxNativeString;
var
  pf: TParamsAsFieldsItem;
  Param: TParam;
begin
  Result:= '';
  if fAnalizer = Nil then Exit;
  // First a search on the ParamsAsFields property
  if TSqlAnalizer(fAnalizer).XQuery.ParamsAsFields.Count > 0 then
  begin
    pf := TSqlAnalizer(fAnalizer).XQuery.ParamsAsFields.ParamByName( ParamName );
    if pf <> Nil then
    begin
      Result:= TSqlAnalizer(fAnalizer).QualifiedField( '\f"' + pf.Value + '"', True );
      Exit;
    end;
  end;
  // if not found then replace with default params
  Param:= TSqlAnalizer(fAnalizer).xQuery.ParamByName( ParamName );
  if Param = Nil then
    raise ExQueryError(Format(SParameterNotFound,[ParamName]));
  // return param value
  Result:= Param.AsString;
  FExprList.Add(TExplicitParamExpr.Create( TSqlAnalizer(fAnalizer), Param ));
end;

// function yylex : Integer; forward;  // addition 1

function TExprParser.yyparse : Integer; // addition 2

var yystate, yysp, yyn : SmallInt;
    yys : array [1..yymaxdepth] of SmallInt;
    yyv : array [1..yymaxdepth] of YYSType;
    yyval : YYSType;

procedure yyaction ( yyruleno : Integer );
  (* local definitions: *)
var
  IntVal, Code: Integer;
begin
  (* actions: *)
  case yyruleno of
   1 : begin
         yyval := yyv[yysp-0];
       end;
   2 : begin
         FGroupIdent:= FGroupIdentList[FGroupIdentList.Count-1];
         FGroupIdentList.Delete(FGroupIdentList.Count-1);
         FIdentifier:= FIdentifierList[FIdentifierList.Count-1];
         FIdentifierList.Delete(FIdentifierList.Count-1);
         FTempParams:= GetParamList;

         IDF:=nil;
         IDFunc(Self, FGroupIdent, FIdentifier, FTempParams, IDF);
         if IDF <> nil then
         begin
          if Length(FGroupIdent)=0 then
             AddExpression(IDF)
          else
          begin
           FExprList.Add(IDF);
           if FTempParams=nil then
           begin
           if FIdReferences.IndexOf( FGroupIdent + '.' + FIdentifier ) < 0 then
              FIdReferences.Add(FGroupIdent + '.' + FIdentifier);
           end;
          end;
         end else
         begin
          if CompareText(FIdentifier,'NULL')=0 then
             IDF:= AddExpression(TNullValueExpr.Create(FIdentifier, FTempParams))
          else if (CompareText(FIdentifier,'TRIM')=0) or (CompareText(FIdentifier,'ALLTRIM')=0) then {added by fduenas: use ALLTRIM insted of TRIM}
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfTrim))
          else if CompareText(FIdentifier,'LTRIM')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfLTrim))
          else if CompareText(FIdentifier,'RTRIM')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfRTrim))
          else if CompareText(FIdentifier,'CHR')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfChr))
          else if CompareText(FIdentifier,'TRUNC')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfTrunc))
          else if CompareText(FIdentifier,'ROUND')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfRound))
          else if CompareText(FIdentifier,'ABS')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfAbs))
          else if CompareText(FIdentifier,'ARCTAN')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfArcTan))
          else if CompareText(FIdentifier,'COS')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfCos))
          else if CompareText(FIdentifier,'SIN')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfSin))
          else if CompareText(FIdentifier,'EXP')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfExp))
          else if CompareText(FIdentifier,'FRAC')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfFrac))
          else if CompareText(FIdentifier,'INT')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfInt))
          else if CompareText(FIdentifier,'LN')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfLn))
          else if CompareText(FIdentifier,'PI')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfPi))
          else if CompareText(FIdentifier,'SQR')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfSqr))
          else if CompareText(FIdentifier,'SQRT')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfSqrt))
          else if CompareText(FIdentifier,'POWER')=0 then
                  IDF:= AddExpression(TMathFunctionExprLib.Create(FIdentifier, FTempParams, mfPower))
          else if CompareText(FIdentifier,'UPPER')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfUpper))
          else if CompareText(FIdentifier,'LOWER')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfLower))
          else if CompareText(FIdentifier,'UCASE')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfUpper)) {patched by fduenas: added as UPPER alias}
          else if CompareText(FIdentifier,'LCASE')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfLower)) {patched by fduenas: added as LOWER alias}
          else if CompareText(FIdentifier,'COPY')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfCopy))
          else if CompareText(FIdentifier,'SUBSTRING')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfCopy))
          else if CompareText(FIdentifier,'SUBSTR')=0 then {patched by fduenas: added SubStr for compatibility }
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfCopy))
          else if CompareText(FIdentifier,'MIDSTR')=0 then {patched by fduenas: added MidStr for compatibility with LeftStr and RightStr}
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfCopy))
          else if CompareText(FIdentifier,'CONCAT')=0 then {added by fduenas: Concat and Concat_WS functions}
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfConcat))
          else if CompareText(FIdentifier,'CONCAT_WS')=0 then {added by fduenas: Concat and Concat_WS functions}
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfConcatWS))
          else if CompareText(FIdentifier,'POS')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfPos))
          else if CompareText(FIdentifier,'CHARINDEX')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfPos))
          else if CompareText(FIdentifier,'LENGTH')=0 then
                  IDF:= AddExpression(TStringFunctionExprLib.Create(FIdentifier, FTempParams, sfLength))
          else if CompareText(FIdentifier,'LEFT')=0 then
                  IDF:= AddExpression(TLeftExpr.Create(FIdentifier, FTempParams))
          else If CompareText(FIdentifier,'LEFTSTR')=0 then {patched by fduenas: added LeftStr as Function because LEFT can't be used in the Field List}
                  IDF:= AddExpression(TLeftExpr.Create(FIdentifier, FTempParams))
          else if CompareText(FIdentifier,'RIGHT')=0 then
                  IDF:= AddExpression(TRightExpr.Create(FIdentifier, FTempParams))
          else if CompareText(FIdentifier,'RIGHTSTR')=0 then
                  IDF:= AddExpression(TRightExpr.Create(fIdentifier, FTempParams)) {patched by fduenas: added RightStr as Function because RIGHT can't be used in the Field List}
          else if (CompareText(FIdentifier,'YEAR')=0) OR (CompareText(FIdentifier,'YEAROF')=0) then {modified by fduenas: added some alias}
                  IDF:= AddExpression(TDecodeDateTimeExpr.Create(FIdentifier, FTempParams, dkYear))
          else if (CompareText(FIdentifier,'MONTH')=0) OR  (CompareText(FIdentifier,'MONTHOF')=0) then {modified by fduenas: added some alias}
                  IDF:= AddExpression(TDecodeDateTimeExpr.Create(FIdentifier, FTempParams, dkMonth))
          else if (CompareText(FIdentifier,'DAY')=0) OR (CompareText(FIdentifier,'DAYOF')=0) then {modified by fduenas: added some alias}
                  IDF:= AddExpression(TDecodeDateTimeExpr.Create(FIdentifier, FTempParams, dkDay))
          else if (CompareText(FIdentifier,'HOUR')=0) OR  (CompareText(FIdentifier,'HOUROF')=0) then {modified by fduenas: added some alias}
                  IDF:= AddExpression(TDecodeDateTimeExpr.Create(FIdentifier, FTempParams, dkHour))
          else if (CompareText(FIdentifier,'MIN')=0)  OR (CompareText(FIdentifier,'MINUTE')=0) then {modified by fduenas: added some alias}
                  IDF:= AddExpression(TDecodeDateTimeExpr.Create(FIdentifier, FTempParams, dkMin))
          else if (CompareText(FIdentifier,'SEC')=0)  OR (CompareText(FIdentifier,'SECONDS')=0) then {modified by fduenas: added some alias}
                  IDF:= AddExpression(TDecodeDateTimeExpr.Create(FIdentifier, FTempParams, dkSec))
          else if (CompareText(FIdentifier,'MSEC')=0)  OR (CompareText(FIdentifier,'MICROSECOND')=0) then {modified by fduenas: added some alias}
                  IDF:= AddExpression(TDecodeDateTimeExpr.Create(FIdentifier, FTempParams, dkMSec))
          else if CompareText(FIdentifier,'FORMATDATETIME')=0 then
                  IDF:= AddExpression(TFormatDateTimeExpr.Create(FIdentifier, FTempParams))
          else if CompareText(FIdentifier,'FORMATFLOAT')=0 then
                  IDF:= AddExpression(TFormatFloatExpr.Create(FIdentifier, FTempParams))
          else if CompareText(FIdentifier,'FORMAT')=0 then
                  IDF:= AddExpression(TFormatExpr.Create(FIdentifier, FTempParams))
          else if CompareText(FIdentifier,'DECODE')=0 then
                  IDF:= AddExpression(TDecodeExpr.Create(FIdentifier, FTempParams))
          else if CompareText(FIdentifier,'MINOF')=0 then
                  IDF:= AddExpression(TMinMaxOfExpr.Create(FIdentifier, FTempParams, True))
          else if CompareText(FIdentifier,'MAXOF')=0 then
                  IDF:= AddExpression(TMinMaxOfExpr.Create(FIdentifier, FTempParams, False))
          else if CompareText(FIdentifier,'SQLLIKE')=0 then
                  IDF:= AddExpression({$IFNDEF XQ_USE_NEW_SQLLIKE_FUNCTION}TSQLLikeExpr{$ELSE}TSQLMatchLikeExpr{$ENDIF}.Create(fIdentifier, FTempParams, False))
          else if CompareText(FIdentifier,'SQLNOTLIKE')=0 then
                  IDF:= AddExpression({$IFNDEF XQ_USE_NEW_SQLLIKE_FUNCTION}TSQLLikeExpr{$ELSE}TSQLMatchLikeExpr{$ENDIF}.Create(fIdentifier, FTempParams, True))
          else if CompareText(FIdentifier,'MATCH')=0 then
                  IDF:= AddExpression(TSQLMatchLikeExpr.Create(fIdentifier, FTempParams, False))
          else if (CompareText(FIdentifier,'ASCII')=0) or (CompareText(FIdentifier,'ORD')=0) then
                  IDF:= AddExpression(TASCIIExpr.Create(FIdentifier, FTempParams));
         end;
         if IDF=nil then
         begin
          FTempParams.Free;
          yyerror(Format(SEXPR_UNKNOWNID, [yyv[yysp-1].yystring]{$IFDEF Delphi7Up}, yyRuntimeFormatSettings{$ENDIF}));
          yyabort;
          Exit;
         end;
       end;
   3 : begin
         AddExpression(TTypeCastExpr.Create(ForceParamList(1), ttString));
       end;
   4 : begin
         AddExpression(TTypeCastExpr.Create(GetParamList, ttFloat));
       end;
   5 : begin
         AddExpression(TTypeCastExpr.Create(ForceParamList(1), ttFloat));
       end;
   6 : begin
         AddExpression(TTypeCastExpr.Create(GetParamList, ttInteger));
       end;
   7 : begin
         AddExpression(TTypeCastExpr.Create(ForceParamList(1), ttInteger));
       end;
   8 : begin
         AddExpression(TTypeCastExpr.Create(GetParamList, ttBoolean));
       end;
   9 : begin
         AddExpression(TTypeCastExpr.Create(ForceParamList(1), ttBoolean));
       end;
  10 : begin
         AddExpression(TConditionalExpr.Create(GetParamList));
       end;
  11 : begin
         AddExpression(TCaseWhenElseExpr.Create(FWhenParamList, FThenParamList, FElseExpr));
         FWhenParamList:= nil;
         FThenParamList:= nil;
         FElseExpr:= nil;

       end;
  12 : begin
         AddExpression( TBetweenExpr.Create(ForceParamList(3), FALSE) );
       end;
  13 : begin
         AddExpression( TBetweenExpr.Create(ForceParamList(3), TRUE) );
       end;
  14 : begin
         AddExpression( TSQLInPredicateExpr.Create(ForceParamList(FParamCount + 1), FALSE) );
       end;
  15 : begin
         AddExpression( TSQLInPredicateExpr.Create(ForceParamList(FParamCount + 1), TRUE) );
       end;
  16 : begin
         AddExpression({$IFNDEF XQ_USE_NEW_SQLLIKE_FUNCTION}TSQLLikeExpr{$ELSE}TSQLMatchLikeExpr{$ENDIF}.Create(ForceParamList(3), FALSE));
       end;
  17 : begin
         AddExpression({$IFNDEF XQ_USE_NEW_SQLLIKE_FUNCTION}TSQLLikeExpr{$ELSE}TSQLMatchLikeExpr{$ENDIF}.Create(ForceParamList(3), TRUE));
       end;
  18 : begin
         GetOneOperator;
         AddExpression(TUnaryOp.Create(opMinus, Op1));
         FIsComplex:= True;
       end;
  19 : begin
         GetOneOperator;
         AddExpression(TUnaryOp.Create(opPlus, Op1));
         FIsComplex:= True;
       end;
  20 : begin
         GetOneOperator;
         AddExpression(TUnaryOp.Create(opNot, Op1));
         FIsComplex:= True;
       end;
  21 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opPlus, Op1, Op2));
         FIsComplex:= True;
       end;
  22 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opMinus, Op1, Op2));
         FIsComplex:= True;
       end;
  23 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opMult, Op1, Op2));
         FIsComplex:= True;
       end;
  24 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opDivide, Op1, Op2));
         FIsComplex:= True;
       end;
  25 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opDiv, Op1, Op2));
         FIsComplex:= True;
       end;
  26 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opExp, Op1, Op2));
         FIsComplex:= True;
       end;
  27 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opMod, Op1, Op2));
         FIsComplex:= True;
       end;
  28 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opShl, Op1, Op2));
         FIsComplex:= True;
       end;
  29 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opShr, Op1, Op2));
         FIsComplex:= True;
       end;
  30 : begin
         GetTwoOperators;
         AddExpression(TRelationalOp.Create(opGTE, Op1, Op2));
         FIsComplex:= True;
       end;
  31 : begin
         GetTwoOperators;
         AddExpression(TRelationalOp.Create(opLTE, Op1, Op2));
         FIsComplex:= True;
       end;
  32 : begin
         GetTwoOperators;
         AddExpression(TRelationalOp.Create(opGT, Op1, Op2));
         FIsComplex:= True;
       end;
  33 : begin
         GetTwoOperators;
         AddExpression(TRelationalOp.Create(opLT, Op1, Op2));
         FIsComplex:= True;
       end;
  34 : begin
         GetTwoOperators;
         AddExpression(TRelationalOp.Create(opEQ, Op1, Op2));
         FIsComplex:= True;
       end;
  35 : begin
         GetTwoOperators;
         AddExpression(TRelationalOp.Create(opNEQ, Op1, Op2));
         FIsComplex:= True;
       end;
  36 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opAnd, Op1, Op2));
         FIsComplex:= True;
       end;
  37 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opOr, Op1, Op2));
         FIsComplex:= True;
       end;
  38 : begin
         GetTwoOperators;
         AddExpression(TBinaryOp.Create(opXor, Op1, Op2));
         FIsComplex:= True;
       end;
  39 : begin
         FIsComplex:= True;
       end;
  40 : begin
         FStackedParamCount.Add(Pointer(0));
       end;
  41 : begin
         yyval := yyv[yysp-1];
       end;
  42 : begin
         yyval := yyv[yysp-2];
       end;
  43 : begin
         FStackedParamCount.Add(Pointer(0));
       end;
  44 : begin
         AddParam;
       end;
  45 : begin
         AddParam;
       end;
  46 : begin
         yyval := yyv[yysp-3];
       end;
  47 : begin
         yyval := yyv[yysp-0];
       end;
  48 : begin
         yyval := yyv[yysp-1];
       end;
  49 : begin
         if FWhenParamList=nil then
            FWhenParamList:= TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings);
         if FThenParamList=nil then
            FThenParamList:= TParameterList.Create(yyRuntimeFormatSettings, yySystemFormatSettings);
         FWhenParamList.Add(FExprList[FExprList.Count-2]);
         FThenParamList.Add(FExprList[FExprList.Count-1]);
         FExprList.Delete(FExprList.Count-1);
         FExprList.Delete(FExprList.Count-1);
       end;
  50 : begin
       end;
  51 : begin
         FElseExpr:= TExpression(FExprList[FExprList.Count-1]);
         FExprList.Delete(FExprList.Count-1);

       end;
  52 : begin
         FGroupIdentList.Add('');
         FIdentifierList.Add(UpperCase(yyv[yysp-0].yystring));

       end;
  53 : begin
         FGroupIdentList.Add(UpperCase(yyv[yysp-2].yystring));
         FIdentifierList.Add(UpperCase(yyv[yysp-0].yystring));

       end;
  54 : begin
         Val(yyv[yysp-0].yystring, IntVal, Code);
         if Code=0 then
            FExprList.Add(TIntegerLiteral.Create(StrToInt(yyv[yysp-0].yystring), yyRuntimeFormatSettings, yySystemFormatSettings))
         else
            FExprList.Add(TLargeIntLiteral.Create(StrToInt64(yyv[yysp-0].yystring), yyRuntimeFormatSettings, yySystemFormatSettings));
       end;
  55 : begin
         Val(yyv[yysp-0].yystring, IntVal, Code);
         if Code=0 then
            FExprList.Add(TIntegerLiteral.Create(StrToInt(yyv[yysp-0].yystring), yyRuntimeFormatSettings, yySystemFormatSettings))
         else
            FExprList.Add(TLargeIntLiteral.Create(StrToInt64(yyv[yysp-0].yystring), yyRuntimeFormatSettings, yySystemFormatSettings));
       end;
  56 : begin
         FExprList.Add(TFloatLiteral.Create(StrToFloat(yyv[yysp-0].yystring{$IFDEF Delphi7Up},yyRuntimeFormatSettings{$ENDIF}), yyRuntimeFormatSettings, yySystemFormatSettings));
       end;
  57 : begin
         FExprList.Add(CreateStringLiteralObj( GetString( yyv[yysp-0].yystring ), yyRuntimeFormatSettings, yySystemFormatSettings ))
       end;
  58 : begin
         FExprList.Add(TBooleanLiteral.Create(True, yyRuntimeFormatSettings, yySystemFormatSettings));
       end;
  59 : begin
         FExprList.Add(TBooleanLiteral.Create(False, yyRuntimeFormatSettings, yySystemFormatSettings));
       end;
  60 : begin
         yyval.yystring := GetExplicitParam( yyv[yysp-0].yystring );
       end;
  61 : begin
         FExprList.Add(CreateStringLiteralObj('', yyRuntimeFormatSettings, yySystemFormatSettings));
       end;
  62 : begin
         FExprList.Add(CreateStringLiteralObj(GetString( yyv[yysp-0].yystring ), yyRuntimeFormatSettings, yySystemFormatSettings));
       end;
  end;
end(*yyaction*);

(* parse table: *)

type YYARec = record
                sym, act : SmallInt;
              end;
     YYRRec = record
                len, sym : SmallInt;
              end;

const

yynacts   = 1688;
yyngotos  = 143;
yynstates = 123;
yynrules  = 62;

var

yya : array [1..yynacts    ] of YYARec;
yyg : array [1..yyngotos   ] of YYARec;
yyd : array [0..yynstates-1] of SmallInt;
yyal: array [0..yynstates-1] of SmallInt;
yyah: array [0..yynstates-1] of SmallInt;
yygl: array [0..yynstates-1] of SmallInt;
yygh: array [0..yynstates-1] of SmallInt;
yyr : array [1..yynrules   ] of YYRRec;

procedure LoadResArrays;

  procedure ResLoad(const resname: string; ResourceBuffer: Pointer);
  var
    ResourceSize: Integer;
    ResourcePtr: PChar;
    BinResource: THandle;
    ResInstance: Longint;
    H: THandle;
    Buf: array[0..255] of Char;
  begin
    H := System.FindResourceHInstance(HInstance);
    StrPLCopy(Buf, resname, SizeOf(Buf)-1);
    ResInstance := FindResource(H, Buf, RT_RCDATA);
    if ResInstance = 0 then begin
      H := HInstance;
      {try to find in main binary}
      ResInstance := FindResource(H, Buf, RT_RCDATA);
    end;
    ResourceSize := SizeofResource(H,ResInstance);
    BinResource := LoadResource(H,ResInstance);
    ResourcePtr := LockResource(BinResource);
    Move(ResourcePtr^, ResourceBuffer^, ResourceSize);
    UnlockResource(BinResource);
    FreeResource(BinResource);

  end;
var
  Section: TRTLCriticalSection;
begin

  InitializeCriticalSection(Section);
  EnterCriticalSection(Section);

  ResLoad('QExprYacc_YYA', @yya[1]);
  ResLoad('QExprYacc_YYG', @yyg[1]);

  ResLoad('QExprYacc_YYD', @yyd[0]);

  ResLoad('QExprYacc_YYAL', @yyal[0]);

  ResLoad('QExprYacc_YYAH', @yyah[0]);

  ResLoad('QExprYacc_YYGL', @yygl[0]);

  ResLoad('QExprYacc_YYGH', @yygh[0]);

  ResLoad('QExprYacc_YYR', @yyr[1]);

  LeaveCriticalSection(Section);
  DeleteCriticalSection(Section);

end;


const _error = 256; (* error token *)

function yyact(state, sym : Integer; var act : SmallInt) : Boolean;
  (* search action table *)
  var k : Integer;
  begin
    k := yyal[state];
    while (k<=yyah[state]) and (yya[k].sym<>sym) do inc(k);
    if k>yyah[state] then
      yyact := false
    else
      begin
        act := yya[k].act;
        yyact := true;
      end;
  end(*yyact*);

function yygoto(state, sym : Integer; var nstate : SmallInt) : Boolean;
  (* search goto table *)
  var k : Integer;
  begin
    k := yygl[state];
    while (k<=yygh[state]) and (yyg[k].sym<>sym) do inc(k);
    if k>yygh[state] then
      yygoto := false
    else
      begin
        nstate := yyg[k].act;
        yygoto := true;
      end;
  end(*yygoto*);

label parse, next, error, errlab, shift, reduce, accept, abort;

begin(*yyparse*)

  (* load arrays from resource *)
  LoadResArrays;

  yystate := 0; yychar := -1; yynerrs := 0; yyerrflag := 0; yysp := 0;

{$ifdef yydebug}
  yydebug := true;
{$else}
  yydebug := false;
{$endif}
 {$IFNDEF Delphi7Up}
  RestoreFormatSettings( yyRuntimeFormatSettings );
 {$ENDIF}
parse:

  (* push state and value: *)

  inc(yysp);
  if yysp>yymaxdepth then
    begin
      yyerror('yyparse stack overflow');
      goto abort;
    end;
  yys[yysp] := yystate; yyv[yysp] := yyval;

next:

  if (yyd[yystate]=0) and (yychar=-1) then
    (* get next symbol *)
    begin
      repeat
         yychar := yyLexer.yylex(yylval); if yychar<0 then yychar := 0; {modified by fduenas: make TP Yacc/Lex thread safe)}
         // ignore comments and blanks [ \n\t]
         if not( (yychar=_COMMENT) or (yychar=_BLANK) or
                 (yychar=_TAB) or (yychar=_NEWLINE) ) then break;
      until false;
      if yychar= _ILLEGAL then goto error;
    end;

  (*
  if yydebug then
    writeln( yyLexer.yyOutput, 'state '+intToStr( yystate)+ ', char '+
                               intToStr( yychar) + ' at line n�'+
                               intToStr(yyLexer.yylineno) + ', col n�' +
                               intToStr( yyLexer.yycolno));
  *)

  (* determine parse action: *)

  yyn := yyd[yystate];
  if yyn<>0 then goto reduce; (* simple state *)

  (* no default action; search parse table *)

  if not yyact(yystate, yychar, yyn) then goto error
  else if yyn>0 then                      goto shift
  else if yyn<0 then                      goto reduce
  else                                    goto accept;

error:

  (* error; start error recovery: *)

  if yyerrflag=0 then yyerror('syntax error');

errlab:

  if yyerrflag=0 then inc(yynerrs);     (* new error *)

  if yyerrflag<=2 then                  (* incomplete recovery; try again *)
    begin
      yyerrflag := 3;
      (* uncover a state with shift action on error token *)
      while (yysp>0) and not ( yyact(yys[yysp], _error, yyn) and
                               (yyn>0) ) do
        begin
          (*
          if yydebug then
            if yysp>1 then
              writeln( yyLexer.yyOutput, 'error recovery pops state ' +
                       intToStr(yys[yysp])+', uncovers '+ intToStr(yys[yysp-1]))
            else
              writeln( yyLexer.yyOutput, 'error recovery fails ... abort');
          *)
          dec(yysp);
        end;
      if yysp=0 then goto abort; (* parser has fallen from stack; abort *)
      yystate := yyn;            (* simulate shift on error *)
      goto parse;
    end
  else                                  (* no shift yet; discard symbol *)
    begin
      (*
      if yydebug then
        writeln( yyLexer.yyOutput, 'error recovery discards char '+
                 intToStr( yychar));
      *)
      if yychar=0 then goto abort; (* end of input; abort *)
      yychar := -1; goto next;     (* clear lookahead char and try again *)
    end;

shift:

  (* go to new state, clear lookahead character: *)

  yystate := yyn; yychar := -1; yyval := yylval;
  if yyerrflag>0 then dec(yyerrflag);

  goto parse;

reduce:

  (* execute action, pop rule from stack, and go to next state: *)

  //if yydebug then writeln( yyLexer.yyOutput, 'reduce '+ intToStr( -yyn));

  yyflag := yyfnone; yyaction(-yyn);
  dec(yysp, yyr[-yyn].len);
  if yygoto(yys[yysp], yyr[-yyn].sym, yyn) then yystate := yyn;

  (* handle action calls to yyaccept, yyabort and yyerror: *)

  case yyflag of
    yyfaccept : goto accept;
    yyfabort  : goto abort;
    yyferror  : goto errlab;
  end;

  goto parse;

accept:
 {$IFNDEF Delphi7Up}
  RestoreFormatSettings( yySystemFormatSettings );
 {$ENDIF}
  yyparse := 0; exit;

abort:
 {$IFNDEF Delphi7Up}
  RestoreFormatSettings( yySystemFormatSettings );
 {$ENDIF}
  yyparse := 1; exit;

end(*yyparse*);

{ TISNULLExpr }
{ use ISNULL to test only if a Field has a NULL value }
function TISNULLExpr.CheckParameters: Boolean;
var _errorMsg: string;
begin
 result := (ParameterCount >=1) and (ParameterCount <=2);
 If not Result then
    _errorMsg:= SEXPR_WRONGPARAMETERCOUNT
 else if (ParameterCount=2) then
 begin
  result := (Param[1].ExprType = ttBoolean) ;
  if not result then
     _errorMsg:= '%s: '+Format(SEXPR_INVALIDPARAMETERTYPEMUSTBE,[NExprType[Param[1].ExprType], NExprType[ttBoolean]]);
 end;

 If Not result Then
    raise EExpression.CreateFmt( _errorMsg,
      [GetExprName])
end;

Function TISNULLExpr.GetAsBoolean: Boolean;
Begin
  CheckParameters;
  Result := Param[0].IsNull;
  if (ParameterCount=2) and
     (Param[1].AsBoolean=false) then
      Result := Not Result;
End;

function TISNULLExpr.GetAsFloat: Double;
begin
  Result := GetAsInteger;
end;

function TISNULLExpr.GetAsInteger: Integer;
begin
  if GetAsBoolean then
     Result := 1
  else
     Result := 0;
end;

function TISNULLExpr.GetAsLargeInt: Int64;
begin
  CheckParameters;
  Result := GetAsInteger;
end;

function TISNULLExpr.GetAsString: String;
begin
 Result := NBoolean[GetAsBoolean];
end;
{$IFDEF LEVEL4}
function TISNULLExpr.GetAsWideString: WideString;
begin
 Result := NBoolean[GetAsBoolean];
end;
{$ENDIF}
function TISNULLExpr.GetExprType: TExprtype;
Begin
 result := ttBoolean;
End;

function TISNULLExpr.GetMaxString: String;
begin
  CheckParameters;
  Result := NBoolean[False];
end;
{$IFDEF LEVEL4}
function TISNULLExpr.GetMaxWideString: WideString;
begin
  CheckParameters;
  Result := NBoolean[False];
end;
{$ENDIF}

end.