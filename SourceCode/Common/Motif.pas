unit Motif;

interface

uses
  System.Classes, System.SysUtils, System.Rtti;

type
  TPatternItem = class
  private
    fResponse: string;
    fValue: TValue;
  public
    constructor Create;

    property Response: string read fResponse write fResponse;
    property Value: TValue read fValue write fValue;
  end;

  TMotif = class
  private
    fList: TStringList;
    procedure addFuncValue(const aPattern: string; const aValue: TValue);
    function prepareTag(const aPattern: string): string;
    function getPatternItem (const aPattern: string; const aExact: Boolean): TPatternItem;
    function getPatternItemResponse(const index: integer): string;
    function getPatternItemFunc(const index: integer): Pointer;
  public
    function add(const aPattern: string; const aReturn: string = ''): TMotif; overload;
    function add<T>(const aPattern: string; const aFunc: TFunc<T>):TMotif; overload;
    function find (const aPattern: string; const aExact: Boolean = False): string; overload;
    function find<T>(const aPattern: string; const aExact: Boolean = False): T;
        overload;
    procedure remove (const aPattern: string);
    procedure clear;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  ArrayHelper, System.Generics.Collections, System.TypInfo;

function TMotif.prepareTag(const aPattern: string): string;
var
  strArray: TArrayRecord<string>;
  arrList: TList<string>;
begin
  strArray:=TArrayRecord<string>.Create(aPattern.Split([',']));
  strArray.ForEach(procedure(var Value: string; Index: integer)
                   begin
                     Value:=Value.Trim.ToUpper;
                   end);

  arrList:=TList<string>.Create;
  strArray.List(arrList);
  result:=string.Join(',', arrList.ToArray);
  arrList.Free;
end;

function TMotif.getPatternItem(const aPattern: string; const aExact: Boolean):
    TPatternItem;
var
  arrList: TList<string>;
  arrStr: TArrayRecord<string>;
  index: integer;
  tag: string;
  item: TPatternItem;
begin
  result:=nil;
  tag:=prepareTag(aPattern);
  if fList.Find(tag, index) then
  begin
    item:=fList.Objects[index] as TPatternItem;
    if Assigned(item) then
      Result:=item;
  end;
  if aExact or Assigned(Result) then
    Exit;
  arrStr:=TArrayRecord<string>.Create(tag.Split([',']));
  while arrStr.Count > 0 do
  begin
    arrStr.Delete(arrStr.Count - 1);

    arrList:=TList<string>.Create;
    arrStr.List(arrList);
    tag:=string.Join(',', arrList.ToArray);
    arrList.Free;

    if fList.Find(tag,index) then
    begin
      item:=fList.Objects[index] as TPatternItem;
      if Assigned(item) then
        Result:=item;
      Break;
    end;
  end;
end;

function TMotif.getPatternItemFunc(const index: integer): Pointer;
begin

end;

function TMotif.getPatternItemResponse(const index: integer): string;
var
  obj: TPatternItem;
begin
  Result:='';
  if (index>=0) and (index<=fList.Count - 1) then
  begin
    obj:=fList.Objects[index] as TPatternItem;
    if Assigned(obj) then
      if obj.Response<>'' then
        Result := obj.Response;
  end;
end;

{ TMotif }

function TMotif.add(const aPattern: string; const aReturn: string = ''): TMotif;
var
  tag: string;
  index: Integer;
  patItem: TPatternItem;
begin
  tag:=prepareTag(aPattern);
  if not fList.Find(tag, index) then
  begin
    patItem:=TPatternItem.Create;
    patItem.Response:=aReturn;
    fList.AddObject(tag, patItem);
  end;
  Result:=Self;
end;

function TMotif.add<T>(const aPattern: string; const aFunc: TFunc<T>): TMotif;
var
  tag: string;
  index: Integer;
  funRec: T;
begin
  Result:=nil;
  if not Assigned(aFunc) then
    Exit;
  tag:=prepareTag(aPattern);
  if not fList.Find(tag, index) then
  begin
    funRec:=aFunc();
    addFuncValue(tag, TValue.From<T>(funRec));
  end;
  Result:=Self;
end;

function TMotif.find(const aPattern: string; const aExact: Boolean): string;
var
  item: TPatternItem;
begin
  Result:='';
  item:=getPatternItem(aPattern, aExact);
  if Assigned(item) then
    result:=item.Response;
end;

function TMotif.find<T>(const aPattern: string; const aExact: Boolean = False):
    T;
var
  item: TPatternItem;
begin
  item:=getPatternItem(aPattern, aExact);
  if Assigned(item) then
    result:=item.Value.AsType<T>;
end;

procedure TMotif.remove(const aPattern: string);
var
  index: integer;
begin
  if fList.Find(prepareTag(aPattern), index) then
    fList.Delete(index);
end;

procedure TMotif.clear;
begin
  fList.Clear;
end;

constructor TMotif.Create;
begin
  inherited;
  fList:=TStringList.Create;
  fList.Sorted:=True;
  fList.OwnsObjects:=True;
end;

destructor TMotif.Destroy;
begin
  fList.Free;
  inherited;
end;

// Workaround to bypass compiler error when TPatternItem is called in add<T>
// Delphi dcc32 error E2506 Method of parameterized type declared in
// interface section must not use local symbol
procedure TMotif.addFuncValue(const aPattern: string; const aValue: TValue);
var
  patItem: TPatternItem;
begin
  patItem:=TPatternItem.Create;
  patItem.Value:=aValue;
  fList.AddObject(aPattern, patItem);
end;

constructor TPatternItem.Create;
begin
  inherited;
  fResponse:='';
  fValue:=TValue.Empty;
end;

end.
