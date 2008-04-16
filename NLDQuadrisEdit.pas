unit NLDQuadrisEdit;

interface

uses
  Classes, DesignEditors, DesignIntf;

type
  TThemeProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

procedure Register;

implementation

uses
  NLDQuadris;

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(TThemeName), TNLDQuadris, 'Theme',
    TThemeProperty);
end;

{ TThemeProperty }

function TThemeProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paMultiSelect, paRevertable];
end;

procedure TThemeProperty.GetValues(Proc: TGetStrProc);
var
  i: Integer;
  ThemeNames: TStrings;
begin
  inherited;
  ThemeNames := TNLDQuadris.GetThemeNames;
  for i := 0 to ThemeNames.Count - 1 do
    Proc(ThemeNames[i]);
end;

end.
