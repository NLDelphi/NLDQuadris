{ *************************************************************************** }
{                                                                             }
{ NLDQuadris  -  www.nldelphi.com Open Source Delphi designtime component     }
{                                                                             }
{ aka "NLDEasterEgg"                                                          }
{                                                                             }
{ Initiator: Albert de Weerd (aka NGLN)                                       }
{ License: Free to use, free to modify                                        }
{ Website: http://www.nldelphi.com/forum/showthread.php?t=31097               }
{ SVN path: http://svn.nldelphi.com/nldelphi/opensource/ngln/NLDQuadris       }
{                                                                             }
{ *************************************************************************** }
{                                                                             }
{ Date: March 22, 2009                                                        }
{ Version: 1.0.0.2                                                            }
{                                                                             }
{ *************************************************************************** }

unit NLDQuadris;

{$BOOLEVAL OFF}

interface

uses
  Windows, Classes, Contnrs, ImgList, Controls, Graphics, Messages, ExtCtrls,
  NLDJoystick;

const
  ColCount = 6;
  RowCount = 10;

type
  EQuadrisError = class(EComponentError);

  TAnimKind = (akCycle, akPendulum);
  TAnimOrder = (aoUp, aoDown);
  TColRange = 0..ColCount - 1;
  TRowRange = 0..RowCount - 1;
  TColHeight = 0..RowCount;
  TItemID = type Integer;
  TQuadrisOption = (qoAutoIncLevel, qoRandomColumn, qoRandomDirection,
    qoShowNext, qoStartOnFocus, qoPauseOnUnfocus, qoWithHandicap);
  TQuadrisOptions = set of TQuadrisOption;
  TThemeName = type String;
  TQuadrisLevel = 1..9;
  TWind = (North, East, South, West);

const
  DefGameOptions = [qoAutoIncLevel, qoShowNext, qoStartOnFocus,
    qoPauseOnUnfocus, qoWithHandicap];
  DefLevel = 1;
  DefScore = 0;

type
  TCustomQuadris = class;
  TQuadrisItems = class;

  TGameOverEvent = procedure(Sender: TCustomQuadris;
    var StartAgain: Boolean) of object;
  TPointsEvent = procedure(Sender: TCustomQuadris; Points,
    Multiplier: Word) of object;
  TQuadrisEvent = procedure(Sender: TCustomQuadris) of object;
  TMoveEvent = procedure(Sender: TCustomQuadris; Succeeded: Boolean) of object;

  TQuadrisColors = record
    Light: TColor;
    Lighter: TColor;
    Dark: TColor;
    Darker: TColor;
  end;

  TItemMotion = record
    Speed: Double; {PixelsPerSecond}
    StartTick: Cardinal;
    StartTop: Integer;
    FinishTop: Integer;
  end;

  TItemImageLists = class(TObjectList)
  private
    function GetItem(Index: TItemID): TCustomImageList;
    procedure SetItem(Index: TItemID; Value: TCustomImageList);
    function GetDefImageIndex(Index: Integer): Integer;
    procedure SetDefImageIndex(Index: Integer; Value: Integer);
  public
    property Items[Index: TItemID]: TCustomImageList read GetItem
      write SetItem; default;
    property DefImageIndexes[Index: Integer]: Integer read GetDefImageIndex
      write SetDefImageIndex;
  end;

  TItem = class(TGraphicControl)
  private
    FAnimIndex: Integer;
    FAnimOrder: TAnimOrder;
    FAutoFinished: Boolean;
    FBackground: TCanvas;
    FCol: TColRange;
    FDropping: Boolean;
    FFadeImages: TCustomImageList;
    FFadeIndex: Integer;
    FID: TItemID;
    FImages: TCustomImageList;
    FItems: TQuadrisItems;
    FMotion: TItemMotion;
    FQuadris: TCustomQuadris;
    FRow: TColHeight;
    procedure Animate;
    procedure Fade;
    function Fading: Boolean;
    function GetCol: TColRange;
    function GetRow: TColHeight;
  protected
    constructor CreateLinked(AQuadris: TCustomQuadris; AID: TItemID);
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure MoveTo(ACol: TColRange; ARow: TColHeight; NewFinish: TRowRange);
    procedure DropTo(ARow: TRowRange);
    procedure Repaint; override;
    procedure Update; override;
    property Col: TColRange read GetCol;
    property ID: TItemID read FID;
    property Row: TColHeight read GetRow;
  end;

  TPairData = record
    ID1: TItemID;
    ID2: TItemID;
    Col: TColRange;
    Row: TRowRange;
    Dir: TWind;
  end;

  TPair = record
    Item1: TItem;
    Item2: TItem;
    Dir: TWind;
  end;

  TGridCoord = record
    Col: TColRange;
    Row: TRowRange;
  end;

  TItems = class(TObjectList)
  private
    function GetItem(Index: Integer): TItem;
  public
    property Items[Index: Integer]: TItem read GetItem; default;
  end;

  TQuadrisItems = class(TItems)
  private
    FBombing: Boolean;
    FBombItemID: TItemID;
    FDeleting: LongBool;
    FDropping: LongBool;
    FFadeItemID: TItemID;
    FGrid: array[TColRange, TRowRange] of TItem;
    FMaxItemID: TItemID;
    FNextPairData: TPairData;
    FCurrentPair: TPair;
    FQuadris: TCustomQuadris;
    FToTrace: array of TGridCoord;
    FTraceCycle: Integer;
    procedure BeginDelete;
    procedure BeginDrop;
    function ColHeight(ACol: TColRange): TColHeight;
    function DropSpeed: Double;
    procedure EndDelete;
    procedure EndDrop;
    function FallSpeed: Double;
    procedure GridNeeded(InclCurrentPair: Boolean);
    procedure MoveCurrentPair(ACol: TColRange; ARow: TRowRange; ADir: TWind);
    function RandomNextPairData: TPairData;
    procedure Squeeze;
    procedure ThrowBombs;
    procedure Trace;
    function ValidateMovement(Direction: TWind): Boolean;
  public
    procedure Clear; override;
    constructor Create(AQuadris: TCustomQuadris);
    procedure Animate;
    procedure Drop;
    function Empty: Boolean;
    function MoveLeft: Boolean;
    function MoveRight: Boolean;
    function Rotate: Boolean;
    procedure SetDelay(ADelay: Cardinal);
    procedure ThrowNextPair;
    procedure Update;
  end;

  TItemsView = class(TCustomControl)
  private
    FQuadris: TCustomQuadris;
    procedure WMLButtonDown(var Message: TWMLButtonDown);
      message WM_LBUTTONDOWN;
  protected
    procedure Paint; override;
  public
    function CanFocus: Boolean; override;
    constructor Create(AOwner: TComponent); override;
    procedure SetFocus; override;
  end;

  TFadeLabel = class(TGraphicControl)
  private
    FCaption: String;
    FStartTick: Cardinal;
    procedure SetCaption(const Value: String);
  protected
    procedure Paint; override;
  public
    procedure Animate;
    constructor Create(AOwner: TComponent); override;
    property Caption: String write SetCaption;
  end;

  TFixedSizeControl = class(TCustomControl)
  private
    function GetAnchors: TAnchors;
    function GetHeight: Integer;
    function GetWidth: Integer;
    procedure SetAnchors(Value: TAnchors);
  protected
    function CanAutoSize(var NewWidth: Integer;
      var NewHeight: Integer): Boolean; override;
    function CanResize(var NewWidth: Integer;
      var NewHeight: Integer): Boolean; override;
    property Anchors: TAnchors read GetAnchors write SetAnchors
      default [akLeft, akTop];
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property Height: Integer read GetHeight stored False;
    property Width: Integer read GetWidth stored False;
  end;

  TCustomQuadris = class(TFixedSizeControl)
  private
    FAnimInterval: Cardinal;
    FAnimKind: TAnimKind;
    FAnimTimer: TTimer;
    FBackground: TBitmap;
    FColors: TQuadrisColors;
    FItemImageLists: TItemImageLists;
    FItems: TQuadrisItems;
    FLevel: TQuadrisLevel;
    FOnBonus: TPointsEvent;
    FOnDrop: TQuadrisEvent;
    FOnGameOver: TGameOverEvent;
    FOnLevel: TQuadrisEvent;
    FOnMove: TMoveEvent;
    FOnPoints: TPointsEvent;
    FOnRotate: TMoveEvent;
    FOptions: TQuadrisOptions;
    FPaused: Boolean;
    FPauseTick: Cardinal;
    FPointsLabel: TFadeLabel;
    FScore: Cardinal;
    FStartLevel: TQuadrisLevel;
    FStreamedRunning: Boolean;
    FTheme: TThemeName;
    FThemeColor: TColor;
    FUpdateTimer: TTimer;
    FView: TItemsView;
    procedure GameOver;
    function GetColor: TColor;
    function GetRunning: Boolean;
    procedure InitJoystick;
    function IsColorStored: Boolean;
    procedure PaintView;
    procedure Points(TracedCount, TraceCycle: Word);
    procedure JoystickButtonDown(Sender: TNLDJoystick; Buttons: TJoyButtons);
    procedure JoystickMove(Sender: TNLDJoystick; const JoyPos: TJoyRelPos;
      Buttons: TJoyButtons);
    procedure LoadTheme(const ATheme: TThemeName);
    function MaxLevelScore(ALevel: TQuadrisLevel): Cardinal;
    procedure OnAnimTimer(Sender: TObject);
    procedure OnUpdateTimer(Sender: TObject);
    procedure SetColor(Value: TColor);
    procedure SetLevel(Value: TQuadrisLevel);
    procedure SetOptions(Value: TQuadrisOptions);
    procedure SetRunning(Value: Boolean);
    procedure SetTheme(const Value: TThemeName);
    procedure UpdateLevel;
    procedure WMGetDlgCode(var Message: TMessage); message WM_GETDLGCODE;
    procedure WMKeyDown(var Message: TWMKeyDown); message WM_KEYDOWN;
    procedure WMKillFocus(var Message: TWMSetFocus); message WM_KILLFOCUS;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var Message: TMessage); message CM_VISIBLECHANGED;
  protected
    procedure DoBonus(Points, Multiplier: Word); virtual;
    procedure DoDrop; virtual;
    procedure DoGameOver(var StartAgain: Boolean); virtual;
    procedure DoLevel; virtual;
    procedure DoMove(Succeeded: Boolean); virtual;
    procedure DoPoints(Points, Multiplier: Word); virtual;
    procedure DoRotate(Succeeded: Boolean); virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,
      Y: Integer); override;
    procedure Paint; override;
    property Color: TColor read GetColor write SetColor stored IsColorStored;
    property Level: TQuadrisLevel read FLevel write SetLevel default DefLevel;
    property OnBonus: TPointsEvent read FOnBonus write FOnBonus;
    property OnDrop: TQuadrisEvent read FOnDrop write FOnDrop;
    property OnGameOver: TGameOverEvent read FOnGameOver write FOnGameOver;
    property OnLevel: TQuadrisEvent read FOnLevel write FOnLevel;
    property OnMove: TMoveEvent read FOnMove write FOnMove;
    property OnPoints: TPointsEvent read FOnPoints write FOnPoints;
    property OnRotate: TMoveEvent read FOnRotate write FOnRotate;
    property Options: TQuadrisOptions read FOptions write SetOptions
      default DefGameOptions;
    property ParentColor default False;
    property Running: Boolean read GetRunning write SetRunning default False;
    property Score: Cardinal read FScore default DefScore;
    property Theme: TThemeName read FTheme write SetTheme;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function GetThemeNames: TStrings;
    procedure Pause;
    procedure Start;
    procedure Stop;
    property TabStop default True;
  published
    property Height stored False;
    property Width stored False;
  end;

  TNLDQuadris = class(TCustomQuadris)
  published
    property Anchors;
    property Color;
    property Ctl3D;
    property DragKind;
    property DragCursor;
    property DragMode;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnStartDock;
    property OnStartDrag;
    property ParentColor;
    property ParentCtl3D;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabStop;
    property Visible;
  published
    property Level;
    property OnBonus;
    property OnDrop;
    property OnGameOver;
    property OnLevel;
    property OnMove;
    property OnPoints;
    property OnRotate;
    property Options;
    property Running;
    property Score;
    property Theme;
  end;

procedure Register;

implementation

{$R Items.RES}

uses
  SysUtils, CommCtrl, Forms, Math;

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDQuadris]);
end;

resourcestring
  RsErrInvalidCreationF = 'Invalid creation of a %s control.';

type
  TRGB = record
    R: Byte;
    G: Byte;
    B: Byte;
  end;

function GetRGB(AColor: TColor): TRGB;
begin
  AColor := ColorToRGB(AColor);
  Result.R := GetRValue(AColor);
  Result.G := GetGValue(AColor);
  Result.B := GetBValue(AColor);
end;

function MixColor(Base, MixWith: TColor; const Factor: Double): TColor;
var
  FBase, FMixWith: TRGB;
begin
  if (Factor < 0) or (Factor > 1) then
    Result := Base
  else
  begin
    FBase := GetRGB(Base);
    FMixWith := GetRGB(MixWith);
    with FBase do
    begin
      R := R + Round((FMixWith.R - R) * Factor);
      G := G + Round((FMixWith.G - G) * Factor);
      B := B + Round((FMixWith.B - B) * Factor);
      Result := RGB(R, G, B);
    end;
  end;
end;

procedure NotifyKeyboardActivity;
begin
  SystemParametersInfo(SPI_SETSCREENSAVEACTIVE, 1, nil, 0);
end;

function StrToAnimKind(const S: String): TAnimKind;
begin
  Result := TAnimKind(StrToInt(S));
end;

{ TItemImagesLists }

function TItemImageLists.GetDefImageIndex(Index: Integer): Integer;
begin
  Result := Items[Index].Tag;
end;

function TItemImageLists.GetItem(Index: TItemID): TCustomImageList;
begin
  Result := TCustomImageList(inherited Items[Index]);
end;

procedure TItemImageLists.SetDefImageIndex(Index: Integer; Value: Integer);
begin
  Items[Index].Tag := Value;
end;

procedure TItemImageLists.SetItem(Index: TItemID; Value: TCustomImageList);
begin
  inherited Items[Index] := Value;
end;

{ TItem }

const
  DefItemSize = 26;

procedure TItem.Animate;
begin
  case FQuadris.FAnimKind of
    akCycle:
      if FAnimIndex = FImages.Count - 1 then
        FAnimIndex := 0
      else
        Inc(FAnimIndex);
    akPendulum:
      begin
        if FAnimIndex = FImages.Count - 1 then
          FAnimOrder := aoDown
        else if FAnimIndex = 0 then
          FAnimOrder := aoUp;
        if FAnimOrder = aoUp then
          Inc(FAnimIndex)
        else
          Dec(FAnimIndex);
      end;
  end;
  if Fading then
    Fade;
end;

constructor TItem.Create(AOwner: TComponent);
begin
  raise EQuadrisError.CreateFmt(rsErrInvalidCreationF, [ClassName]);
end;

constructor TItem.CreateLinked(AQuadris: TCustomQuadris; AID: TItemID);
begin
  inherited Create(nil);
  ControlStyle := [csOpaque, csFixedWidth, csFixedHeight, csDisplayDragImage,
    csNoStdEvents];
  FID := AID;
  FQuadris := AQuadris;
  FItems := FQuadris.FItems;
  Width := DefItemSize;
  Height := DefItemSize;
  Top := -Height + 1;
  FBackground := FQuadris.FBackground.Canvas;
  FFadeIndex := -1;
  FFadeImages := FQuadris.FItemImageLists[FItems.FFadeItemID];
  FImages := FQuadris.FItemImageLists[FID];
  FMotion.Speed := FItems.FallSpeed;
  FMotion.StartTick := GetTickCount;
  FMotion.StartTop := Top;
  Parent := FQuadris.FView;
end;

procedure TItem.DropTo(ARow: TRowRange);
begin
  FDropping := True;
  FMotion.Speed := FItems.DropSpeed;
  FMotion.StartTop := Top;
  FMotion.StartTick := GetTickCount;
  FMotion.FinishTop := (RowCount - ARow - 1) * Height;
  FItems.BeginDrop;
  Update;
end;

procedure TItem.Fade;
begin
  if FFadeIndex = -1 then
  begin
    SendToBack;
    FItems.BeginDelete;
  end;
  if FFadeIndex < FFadeImages.Count - 1 then
    Inc(FFadeIndex)
  else
  begin
    FItems.EndDelete;
    FItems.Remove(Self);
  end;
end;

function TItem.Fading: Boolean;
begin
  Result := FFadeIndex > -1;
end;

function TItem.GetCol: TColRange;
begin
  Result := Left div Width;
end;

function TItem.GetRow: TColHeight;
begin
  Result := RowCount - 1 - Ceil(Top / Height);
end;

procedure TItem.MoveTo(ACol: TColRange; ARow: TColHeight; NewFinish: TRowRange);
begin
  FCol := ACol;
  FRow := ARow;
  FMotion.FinishTop := (RowCount - NewFinish - 1) * Height;
  Update;
end;

procedure TItem.Paint;
var
  DC1: HDC;
  DC2: HDC;
  BITMAP1: HBITMAP;
  BITMAP2: HBITMAP;
begin
  DC1 := CreateCompatibleDC(Canvas.Handle);
  BITMAP1 := CreateCompatibleBitmap(Canvas.Handle, Width, Height);
  SelectObject(DC1, BITMAP1);
  if Fading then
  begin
    DC2 := CreateCompatibleDC(Canvas.Handle);
    BITMAP2 := CreateCompatibleBitmap(Canvas.Handle, Width, Height);
    SelectObject(DC2, BITMAP2);
    ImageList_Draw(FFadeImages.Handle, FFadeIndex, DC1, 0, 0, ILD_NORMAL);
    ImageList_Draw(FImages.Handle, FAnimIndex, DC2, 0, 0, ILD_MASK);
    BitBlt(DC1, 0, 0, Width, Height, DC2, 0, 0, NOTSRCERASE);
    BitBlt(DC2, 0, 0, Width, Height, FBackground.Handle, Left, Top, SRCCOPY);
    BitBlt(DC2, 0, 0, Width, Height, DC1, 0, 0, SRCINVERT);
    BitBlt(Canvas.Handle, 0, 0, Width, Height, DC2, 0, 0, SRCCOPY);
    ImageList_Draw(FImages.Handle, FAnimIndex, DC2, 0, 0, ILD_NORMAL);
    BitBlt(DC2, 0, 0, Width, Height, DC1, 0, 0, SRCAND);
    BitBlt(Canvas.Handle, 0, 0, Width, Height, DC2, 0, 0, SRCPAINT);
    DeleteObject(BITMAP2);
    DeleteDC(DC2);
  end
  else
  begin
    ImageList_Draw(FImages.Handle, FAnimIndex, DC1, 0, 0, ILD_MASK);
    BitBlt(DC1, 0, 0, Width, Height, FBackground.Handle, Left, Top, SRCAND);
    ImageList_Draw(FImages.Handle, FAnimIndex, DC1, 0, 0, ILD_TRANSPARENT);
    BitBlt(Canvas.Handle, 0, 0, Width, Height, DC1, 0, 0, SRCCOPY);
  end;
  DeleteObject(BITMAP1);
  DeleteDC(DC1);
end;

procedure TItem.Repaint;
begin
  if HasParent then
    Paint; {Faster then Invalidate}
end;

procedure TItem.Update;
var
  NewLeft: Integer;
  NewTop: Integer;
  NewBoundsRect: TRect;
  UpdateRect: TRect;
begin
  if FMotion.Speed > 0 then
  begin
    NewLeft := FCol * Width;
    if FRow <> Row then
      Inc(FMotion.StartTop, (Row - FRow) * Height);
    with FMotion do
      NewTop := StartTop + Round(Speed * (GetTickCount - StartTick) * 0.001);
    if NewTop >= FMotion.FinishTop then
    begin
      NewTop := FMotion.FinishTop;
      if FDropping then
      begin
        FItems.EndDrop;
        FDropping := False;
      end else
        FAutoFinished := True;
      FMotion.StartTop := NewTop;
      FMotion.Speed := 0;
    end;
    NewBoundsRect := Rect(NewLeft, NewTop, Newleft + Width, NewTop + Height);
    SubTractRect(UpdateRect, BoundsRect, NewBoundsRect);
    if HasParent then
      InvalidateRect(Parent.Handle, @UpdateRect, False);
    UpdateBoundsRect(NewBoundsRect);
    FCol := Col;
    FRow := Row;
  end;
  Repaint;
end;

{ TItems }

function TItems.GetItem(Index: Integer): TItem;
begin
  Result := TItem(inherited Items[Index]);
end;

{ TQuadrisItems }
{                                 Start
                                    |
                                 NextPair <------------.
                                    |                  |
               Stop <-- Yes <-- GameOver?              |
                                    |                  |
                          ,-------> No                 |
                          |         |                  |
                          No   Move&Rotate             |
                          |         |                  |
                          `---- Finished?              |
                                    |                  |
                                   Yes                 |
                                    |                  |
                                  Drop                 |
                                    |                  |
               Stop <-- Yes <-- GameOver?              |
                                    |                  |
                                    No                 |<------.
                                    |                  |       |
                          ,---> Dropping            Dropping   |
                          |         |                  |       |
                          |       Trace               Yes      No
                          |         |                  |       |
                          |      Delete? --> No --> Bombs? ----'
                          |         |
                          |        Yes
                          |         |
                          |      Points
                          |         |
                          |      Deleting
                          |         |
                          `----- Squeeze                                     }
type
  TDirDelta = packed record
    X: -1..1;
    Y: -1..1;
  end;

const
  Delta: array[TWind] of TDirDelta =
    ((X:0; Y:1), (X:1; Y:0), (X:0; Y:-1), (X:-1; Y:0));
  DefDropSpeed = 200;
  DefMaxFallSpeed = 90;
  DefMinFallSpeed = 10;
  LeftCol: TColRange = Low(TColRange);
  RightCol: TColRange = High(TColRange);
  BottomRow: TRowRange = Low(TRowRange);
  TopRow: TRowRange = High(TRowRange);
  WindCount = 4;

procedure TQuadrisItems.Animate;
var
  i: Integer;
begin
  i := 0;
  while i < Count do
  begin
    Items[i].Animate;
    Inc(i);
  end;
end;

procedure TQuadrisItems.BeginDelete;
begin
  Inc(FDeleting);
end;

procedure TQuadrisItems.BeginDrop;
begin
  Inc(FDropping);
end;

procedure TQuadrisItems.Clear;
begin
  inherited Clear;
  FNextPairData := RandomNextPairData;
  FDeleting := False;
  FDropping := False;
  FBombing := False;
  SetLength(FToTrace, 0);
  FTraceCycle := 0;
end;

function TQuadrisItems.ColHeight(ACol: TColRange): TColHeight;
begin
  for Result := BottomRow to TopRow do
    if FGrid[ACol, Result] = nil then
      Exit;
  Result := High(TColHeight);
end;

constructor TQuadrisItems.Create(AQuadris: TCustomQuadris);
begin
  inherited Create(True);
  FQuadris := AQuadris;
  Clear;
end;

procedure TQuadrisItems.Drop;
var
  Coord1: TGridCoord;
  Coord2: TGridCoord;
begin
  if FDropping or FDeleting then
    Exit;
  GridNeeded(False);
  Coord1.Col := FCurrentPair.Item1.Col;
  Coord2.Col := FCurrentPair.Item2.Col;
  case FCurrentPair.Dir of
    North:
      begin
        Coord1.Row := ColHeight(Coord1.Col);
        Coord2.Row := Coord1.Row + 1;
        if Coord1.Row = TopRow then
        begin
          FQuadris.GameOver;
          Exit;
        end;
      end;
    East, West:
      begin
        Coord1.Row := ColHeight(Coord1.Col);
        Coord2.Row := ColHeight(Coord2.Col);
      end;
    South:
      begin
        Coord2.Row := ColHeight(Coord1.Col);
        Coord1.Row := Coord2.Row + 1;
      end;
  end;
  SetLength(FToTrace, 2);
  FToTrace[0] := Coord1;
  FToTrace[1] := Coord2;
  BeginDrop;
  FCurrentPair.Item1.DropTo(Coord1.Row);
  FCurrentPair.Item2.DropTo(Coord2.Row);
  EndDrop;
  FQuadris.DoDrop;
end;

function TQuadrisItems.DropSpeed: Double;
begin
  Result := DefDropSpeed;
end;

function TQuadrisItems.Empty: Boolean;
begin
  Result := Count - Integer(FDeleting) = 0;
end;

procedure TQuadrisItems.EndDelete;
begin
  Dec(FDeleting);
  if not FDeleting then
    Squeeze;
end;

procedure TQuadrisItems.EndDrop;
begin
  Dec(FDropping);
  if not FDropping then
    if FBombing then
    begin
      FBombing := False;
      ThrowNextPair;
    end else
      Trace;
end;

function TQuadrisItems.FallSpeed: Double;
begin
  Result := DefMinFallSpeed +
    (FQuadris.FLevel / High(TQuadrisLevel)) *
    (DefMaxFallSpeed - DefMinFallSpeed);
end;

procedure TQuadrisItems.GridNeeded(InclCurrentPair: Boolean);
const
  Subtract: array[Boolean] of Integer = (3, 1);
var
  i: Integer;
begin
  FillChar(FGrid, SizeOf(FGrid), 0);
  for i := 0 to Count - Subtract[InclCurrentPair] do
    with Items[i] do
      if not Fading then
        FGrid[Col, Row] := Items[i];
end;

function TQuadrisItems.MoveLeft: Boolean;
begin
  if FDropping or FDeleting then
    Result := False
  else
  begin
    GridNeeded(False);
    Result := ValidateMovement(West);
    if Result then
      with FCurrentPair, Item1 do
        MoveCurrentPair(Col - 1, Row, Dir);
  end;
end;

procedure TQuadrisItems.MoveCurrentPair(ACol: TColRange; ARow: TRowRange;
  ADir: TWind);
begin
  FCurrentPair.Dir := ADir;
  case ADir of
    North, East, West:
      FCurrentPair.Item1.MoveTo(ACol, ARow, ColHeight(ACol));
    South:
      FCurrentPair.Item1.MoveTo(ACol, ARow, ColHeight(ACol) + 1);
  end;
  case ADir of
    North:
      FCurrentPair.Item2.MoveTo(ACol, ARow + 1, ColHeight(ACol) + 1);
    East:
      FCurrentPair.Item2.MoveTo(ACol + 1, ARow, ColHeight(ACol + 1));
    South:
      FCurrentPair.Item2.MoveTo(ACol, ARow - 1, ColHeight(ACol));
    West:
      FCurrentPair.Item2.MoveTo(ACol - 1, ARow, ColHeight(ACol - 1));
  end;
end;

function TQuadrisItems.MoveRight: Boolean;
begin
  if FDropping or FDeleting then
    Result := False
  else
  begin
    GridNeeded(False);
    Result := ValidateMovement(East);
    if Result then
      with FCurrentPair, Item1 do
        MoveCurrentPair(Col + 1, Row, Dir);
  end;
end;

function TQuadrisItems.RandomNextPairData: TPairData;
begin
  with Result do
  begin
    ID1 := Random(FMaxItemID);
    ID2 := Random(FMaxItemID);
    if qoRandomDirection in FQuadris.Options then
      Dir := TWind(Random(WindCount))
    else
      Dir := East;
    if qoRandomColumn in FQuadris.Options then
    begin
      Col := Random(ColCount - 1);
      if Dir = West then
        Inc(Col);
    end else
      Col := (ColCount - 1) div 2;
    Row := TopRow;
    if Dir = North then
      Dec(Row);
  end;
end;

function TQuadrisItems.Rotate: Boolean;
var
  Col: TColRange;
  Row: TColHeight;
  Dir: TWind;

  procedure IncDir;
  begin
    if Dir = High(TWind) then
      Dir := Low(TWind)
    else
      Inc(Dir);
  end;

begin
  if FDropping or FDeleting then
    Result := False
  else
  begin
    GridNeeded(False);
    Result := True;
    Col := FCurrentPair.Item1.Col;
    Row := FCurrentPair.Item1.Row;
    Dir := FCurrentPair.Dir;
    case Dir of
      North:
        if ValidateMovement(East) then
          IncDir
        else if ValidateMovement(West) then
        begin
          IncDir;
          Dec(Col);
        end
        else
        begin
          IncDir;
          IncDir;
          Inc(Row);
        end;
      East:
        if ValidateMovement(South) then
          IncDir
        else
          Result := False;
      South:
        if ValidateMovement(West) then
          IncDir
        else if FGrid[Col + 1, Row] = nil then
        begin
          IncDir;
          Inc(Col);
        end
        else
        begin
          IncDir;
          IncDir;
          Dec(Row);
        end;
      West:
        IncDir;
    end;
    if Result then
      MoveCurrentPair(Col, Row, Dir);
  end;
end;

procedure TQuadrisItems.SetDelay(ADelay: Cardinal);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    with Items[i].FMotion do
      StartTick := StartTick + ADelay;
end;

procedure TQuadrisItems.Squeeze;
var
  Col: TColRange;
  Row: TRowRange;
  FromCoord: TGridCoord;
  ToCoord: TGridCoord;
begin
  BeginDrop;
  GridNeeded(True);
  for Col := LeftCol to RightCol do
    for Row := BottomRow to TopRow do
      if FGrid[Col, Row] = nil then
      begin
        ToCoord.Col := Col;
        ToCoord.Row := Row;
        FromCoord := ToCoord;
        while FromCoord.Row < TopRow do
        begin
          Inc(FromCoord.Row);
          if FGrid[FromCoord.Col, FromCoord.Row] <> nil then
          begin
            FGrid[ToCoord.Col, ToCoord.Row] :=
              FGrid[FromCoord.Col, FromCoord.Row];
            FGrid[FromCoord.Col, FromCoord.Row] := nil;
            FGrid[ToCoord.Col, ToCoord.Row].DropTo(ToCoord.Row);
            SetLength(FToTrace, Length(FToTrace) + 1);
            FToTrace[Length(FToTrace) - 1] := ToCoord;
            Break;
          end;
        end;
      end;
  EndDrop;
end;

procedure TQuadrisItems.ThrowBombs;
var
  iBomb: Integer;
  Col: TColRange;
  Row: TColHeight;
  Item: TItem;
begin
  FBombing := True;
  BeginDrop;
  if FQuadris.FLevel > 2 then
  begin
    GridNeeded(True);
    for iBomb := 1 to Random(FQuadris.FLevel div 2) do
      if Random(5) = 0 then
      begin
        Col := Random(ColCount);
        Row := ColHeight(Col);
        if Row < RowCount then
        begin
          Item := TItem.CreateLinked(FQuadris, FBombItemID);
          Add(Item);
          Item.MoveTo(Col, TopRow, Row);
          Item.DropTo(Row);
        end;
      end;
  end;
  EndDrop;
end;

procedure TQuadrisItems.ThrowNextPair;
begin
  if (not FDropping) and (not FDeleting) then
    with FNextPairData do
    begin
      GridNeeded(True);
      if (FGrid[Col, Row] = nil) and
        (FGrid[Col + Delta[Dir].X, Row + Delta[Dir].Y] = nil) then
      begin
        FCurrentPair.Item1 := TItem.CreateLinked(FQuadris, ID1);
        FCurrentPair.Item2 := TItem.CreateLinked(FQuadris, ID2);
        Add(FCurrentPair.Item1);
        Add(FCurrentPair.Item2);
        MoveCurrentPair(Col, Row, Dir);
        FNextPairData := RandomNextPairData;
        FQuadris.PaintView;
      end
      else
        FQuadris.GameOver;
    end;
end;

procedure TQuadrisItems.Trace;
var
  TracedItems: array of TGridCoord;
  TracedBombs: array of TGridCoord;
  Checked: array[TColRange, TRowRange] of Boolean;

  procedure InitTrace;
  begin
    SetLength(TracedItems, 0);
    SetLength(TracedBombs, 0);
    FillChar(Checked, SizeOf(Checked), 0);
  end;

  procedure TraceQuadris(ACol: TColRange; ARow: TRowRange; TraceID: TItemID);
  var
    IsBomb: Boolean;
  begin
    Checked[ACol, ARow] := True;
    IsBomb := FGrid[ACol, ARow].ID = FBombItemID;
    if (FGrid[ACol, ARow].ID = TraceID) or IsBomb then
    begin
      if IsBomb then
      begin
        SetLength(TracedBombs, Length(TracedBombs) + 1);
        TracedBombs[Length(TracedBombs) - 1].Col := ACol;
        TracedBombs[Length(TracedBombs) - 1].Row := ARow;
      end
      else
      begin
        SetLength(TracedItems, Length(TracedItems) + 1);
        TracedItems[Length(TracedItems) - 1].Col := ACol;
        TracedItems[Length(TracedItems) - 1].Row := ARow;
      end;
      if (ARow < TopRow) and (not Checked[ACol, ARow + 1]) and
          (FGrid[ACol, ARow + 1] <> nil) and
          (not (IsBomb and (FGrid[ACol, ARow + 1].ID = TraceID))) then
        TraceQuadris(ACol, ARow + 1, TraceID);
      if (ACol < RightCol) and (not Checked[ACol + 1, ARow]) and
          (FGrid[ACol + 1, ARow] <> nil) and
          (not (IsBomb and (FGrid[ACol + 1, ARow].ID = TraceID))) then
        TraceQuadris(ACol + 1, ARow, TraceID);
      if (ARow > BottomRow) and (not Checked[ACol, ARow - 1]) and
          (FGrid[ACol, ARow - 1] <> nil) and
          (not (IsBomb and (FGrid[ACol, ARow - 1].ID = TraceID))) then
        TraceQuadris(ACol, ARow - 1, TraceID);
      if (ACol > LeftCol) and (not Checked[ACol - 1, ARow]) and
          (FGrid[ACol - 1, ARow] <> nil) and
          (not (IsBomb and (FGrid[ACol - 1, ARow].ID = TraceID))) then
        TraceQuadris(ACol - 1, ARow, TraceID);
    end;
  end;

var
  Deleted: Boolean;
  iTrace: Integer;
  TracedCount: Integer;
  iTraced: Integer;
begin
  Deleted := False;
  if Length(FToTrace) > 0 then
  begin
    GridNeeded(True);
    Inc(FTraceCycle);
    for iTrace := 0 to Length(FToTrace) - 1 do
    begin
      InitTrace;
      with FToTrace[iTrace] do
        TraceQuadris(Col, Row, FGrid[Col, Row].ID);
      TracedCount := Length(TracedItems);
      if TracedCount >= 4 then
      begin
        for iTraced := 0 to TracedCount - 1 do
          with TracedItems[iTraced] do
            FGrid[Col, Row].Fade;
        for iTraced := 0 to Length(TracedBombs) - 1 do
          with TracedBombs[iTraced] do
            FGrid[Col, Row].Fade;
        Deleted := True;
        FQuadris.Points(TracedCount, FTraceCycle);
      end;
    end;
    SetLength(FToTrace, 0);
  end;
  if not Deleted then
  begin
    FTraceCycle := 0;
    if qoWithHandicap in FQuadris.Options then
      ThrowBombs
    else
      ThrowNextPair;
  end;
end;

procedure TQuadrisItems.Update;
var
  i: Integer;
begin
  i := 0;
  while i < Count do
  begin
    Items[i].Update;
    Inc(i);
  end;
  if Count > 1 then
    if FCurrentPair.Item1.FAutoFinished or FCurrentPair.Item2.FAutoFinished then
      Drop;
end;

function TQuadrisItems.ValidateMovement(Direction: TWind): Boolean;
var
  Col: TColRange;
  Row: TRowRange;
begin
  Col := FCurrentPair.Item1.Col;
  Row := FCurrentPair.Item1.Row;
  case Direction of
    East:
      case FCurrentPair.Dir of
        North, West:
          Result := (Col < RightCol) and (FGrid[Col + 1, Row] = nil);
        East:
          Result := (Col < RightCol - 1) and (FGrid[Col + 2, Row] = nil);
        else {South:}
          Result := (Col < RightCol) and (FGrid[Col + 1, Row - 1] = nil);
      end;
    West:
      case FCurrentPair.Dir of
        North, East:
          Result := (Col > LeftCol) and (FGrid[Col - 1, Row] = nil);
        South:
          Result := (Col > LeftCol) and (FGrid[Col - 1, Row - 1] = nil);
        else {West:}
          Result :=
            (Col > LeftCol + 1) and (FGrid[Col - 2, Row] = nil);
      end;
    South:
      case FCurrentPair.Dir of
        North:
          Result := Row > ColHeight(Col);
        East:
          Result := (Row > ColHeight(Col)) and (Row > ColHeight(Col + 1));
        South:
          Result := Row > ColHeight(Col) + 1;
        else {West:}
          Result := (Row > ColHeight(Col)) and (Row > ColHeight(Col - 1));
      end;
    else {North:}
      Result := False;
  end;
end;

{ TItemsView }

function TItemsView.CanFocus: Boolean;
begin
  Result := False;
end;

constructor TItemsView.Create(AOwner: TComponent);
begin
  if not (AOwner is TCustomQuadris) then
    raise EQuadrisError.CreateFmt(rsErrInvalidCreationF, [ClassName]);
  inherited Create(AOwner);
  ControlStyle := [csOpaque, csFixedWidth, csFixedHeight, csDisplayDragImage,
    csNoStdEvents];
  FQuadris := TCustomQuadris(AOwner);
end;

procedure TItemsView.Paint;
begin
  with Canvas, ClipRect do
    BitBlt(Handle, Left, Top, Right - Left, Bottom - Top,
      FQuadris.FBackground.Canvas.Handle, Left, Top, SRCCOPY);
end;

procedure TItemsView.SetFocus;
begin
  FQuadris.SetFocus;
end;

procedure TItemsView.WMLButtonDown(var Message: TWMLButtonDown);
begin
  FQuadris.SetFocus;
  inherited;
end;

{ TFadeLabel }

const
  DefLabelAnimDuration = 1500;
  DefFontName = 'Arial';
  DefFontSize = 8;

procedure TFadeLabel.Animate;
var
  Duration: Cardinal;
begin
  if FCaption <> '' then
  begin
    Duration := GetTickCount - FStartTick;
    if Duration < DefLabelAnimDuration then
      Canvas.Font.Color :=
        MixColor(clBlack, clWhite, Duration/DefLabelAnimDuration)
    else
      FCaption := '';
    Invalidate;
  end;
end;

constructor TFadeLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csFixedWidth, csFixedHeight, csNoStdEvents,
    csDisplayDragImage];
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := DefFontName;
  Canvas.Font.Size := DefFontSize;
end;

procedure TFadeLabel.Paint;
var
  R: TRect;
begin
  R := ClientRect;
  DrawText(Canvas.Handle, PChar(FCaption), -1, R,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

procedure TFadeLabel.SetCaption(const Value: String);
begin
  FStartTick := GetTickCount;
  FCaption := Value;
end;

{ TFixedSizeControl }

const
  DefViewWidth = ColCount * DefItemSize;
  DefViewHeight = RowCount * DefItemSize;
  DefMargin = 12;
  DefWidth = DefViewWidth + 3 * DefMargin + 2 * DefItemSize;
  DefHeight = DefViewHeight + 2 * DefMargin;

function TFixedSizeControl.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
begin
  Result := False;
end;

function TFixedSizeControl.CanResize(var NewWidth,
  NewHeight: Integer): Boolean;
begin
  Result := False;
end;

constructor TFixedSizeControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csFixedWidth, csFixedHeight];
end;

function TFixedSizeControl.GetAnchors: TAnchors;
begin
  Result := inherited Anchors;
end;

function TFixedSizeControl.GetHeight: Integer;
begin
  Result := inherited Height;
end;

function TFixedSizeControl.GetWidth: Integer;
begin
  Result := inherited Width;
end;

procedure TFixedSizeControl.SetAnchors(Value: TAnchors);
begin
  if Value <> Anchors then
  begin
    if [akLeft, akRight] * Value = [akLeft, akRight] then
      if akLeft in Anchors then
        Exclude(Value, akLeft)
      else
        Exclude(Value, akRight);
    if [akTop, akBottom] * Value = [akTop, akBottom] then
      if akTop in Anchors then
        Exclude(Value, akTop)
      else
        Exclude(Value, akBottom);
    inherited Anchors := Value;
  end;
end;

procedure TFixedSizeControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, DefWidth, DefHeight);
end;

{ TCustomQuadris }

resourcestring
  RsErrThemesMissing = 'Unable to create Quadris control:' +
    #10#13#10#13'There are no theme resources found.';
  RsErrResCorruptF = 'Unable to load Quadris theme %s due to ' +
    'corrupt resource data.';

const
  DefResourceThemeType = 'QTHEME';
  DefResourceBmpPrefix = 'Q';
  DefUpdateTimerInterval = 40;
  DefFadeAnimInterval = 60;

var
  InternalThemeNames: TStrings;
  GlobalThemeNames: TStrings;

procedure TCustomQuadris.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if not Enabled then
    Pause;
end;

procedure TCustomQuadris.CMVisibleChanged(var Message: TMessage);
begin
  inherited;
  if not Visible then
    Pause;
end;

constructor TCustomQuadris.Create(AOwner: TComponent);
begin
  if GetThemeNames.Count <= 0 then
    raise EQuadrisError.Create(RsErrThemesMissing);
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents,
    csDoubleClicks, csOpaque, csDisplayDragImage];
  Canvas.Font.Name := DefFontName;
  Canvas.Font.Size := DefFontSize;
  TabStop := True;
  ParentColor := False;
  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Enabled := False;
  FAnimTimer.OnTimer := OnAnimTimer;
  FBackground := TBitmap.Create;
  FUpdateTimer := TTimer.Create(Self);
  FUpdateTimer.Enabled := False;
  FUpdateTimer.Interval := DefUpdateTimerInterval;
  FUpdateTimer.OnTimer := OnUpdateTimer;
  FItemImageLists := TItemImageLists.Create(True);
  FLevel := DefLevel;
  FStartLevel := FLevel;
  FScore := DefScore;
  FItems := TQuadrisItems.Create(Self);
  FOptions := DefGameOptions;
  FView := TItemsView.Create(Self);
  FView.SetBounds(DefMargin, DefMargin, DefViewWidth, DefViewHeight);
  FView.Parent := Self;
  FPointsLabel := TFadeLabel.Create(Self);
  FPointsLabel.SetBounds(0, 2 * DefMargin, DefViewWidth, DefMargin);
  FPointsLabel.Parent := FView;
  InitJoystick;
  SetTheme(GetThemeNames[0]);
end;

destructor TCustomQuadris.Destroy;
begin
  Stop;
  FItems.Free;
  FItemImageLists.Free;
  FBackground.Free;
  inherited Destroy;
end;

procedure TCustomQuadris.DoBonus(Points, Multiplier: Word);
begin
  if Assigned(FOnBonus) then
    FOnBonus(Self, Points, Multiplier);
end;

procedure TCustomQuadris.DoDrop;
begin
  if Assigned(FOnDrop) then
    FOnDrop(Self);
end;

procedure TCustomQuadris.DoGameOver(var StartAgain: Boolean);
begin
  if Assigned(FOnGameOver) then
    FOnGameOver(Self, StartAgain);
end;

procedure TCustomQuadris.DoLevel;
begin
  if Assigned(FOnLevel) then
    FOnLevel(Self);
end;

procedure TCustomQuadris.DoMove(Succeeded: Boolean);
begin
  if Assigned(FOnMove) then
    FOnMove(Self, Succeeded);
end;

procedure TCustomQuadris.DoPoints(Points, Multiplier: Word);
begin
  if Assigned(FOnPoints) then
    FOnPoints(Self, Points, Multiplier);
end;

procedure TCustomQuadris.DoRotate(Succeeded: Boolean);
begin
  if Assigned(FOnRotate) then
    FOnRotate(Self, Succeeded);
end;

procedure TCustomQuadris.GameOver;
var
  StartAgain: Boolean;
begin
  Stop;
  StartAgain := False;
  DoGameOver(StartAgain);
  if StartAgain then
    Start;
end;

function TCustomQuadris.GetColor: TColor;
begin
  Result := inherited Color;
end;

function TCustomQuadris.GetRunning: Boolean;
begin
  if csDesigning in ComponentState then
    Result := FStreamedRunning
  else
    Result := FUpdateTimer.Enabled;
end;

class function TCustomQuadris.GetThemeNames: TStrings;

  function EnumResNamesProc(hModule: Cardinal; lpszType, lpszName: PChar;
    LParam: Integer): BOOL; stdcall;
  begin
    TStrings(InternalThemeNames).Add(lpszName);
    Result := True;
  end;

begin
  if InternalThemeNames = nil then
  begin
    InternalThemeNames := TStringList.Create;
    GlobalThemeNames := TStringList.Create;
    EnumResourceNames(HInstance, DefResourceThemeType, @EnumResNamesProc, 0);
  end;
  TStrings(GlobalThemeNames).Assign(InternalThemeNames);
  Result := GlobalThemeNames;
end;

procedure TCustomQuadris.InitJoystick;
begin
  Joystick.Advanced := True;
  Joystick.Active := True;
  if Joystick.Active then
  begin
    Joystick.OnButtonDown := JoystickButtonDown;
    Joystick.OnMove := JoystickMove;
    Joystick.RepeatButtonDelay := 350;
    Joystick.RepeatMoveDelay := 350;
  end;
end;

function TCustomQuadris.IsColorStored: Boolean;
begin
  Result := Color <> FThemeColor;
end;

procedure TCustomQuadris.JoystickButtonDown(Sender: TNLDJoystick;
  Buttons: TJoyButtons);
begin
  if JoyBtn1 in Buttons then
    PostMessage(Handle, WM_KEYDOWN, VK_DOWN, 0);
  NotifyKeyboardActivity;
end;

procedure TCustomQuadris.JoystickMove(Sender: TNLDJoystick;
  const JoyPos: TJoyRelPos; Buttons: TJoyButtons);
begin
  if JoyPos.X < 0 then
    PostMessage(Handle, WM_KEYDOWN, VK_LEFT, 0)
  else if JoyPos.X > 0 then
    PostMessage(Handle, WM_KEYDOWN, VK_RIGHT, 0)
  else if JoyPos.Y < 0 then
    PostMessage(Handle, WM_KEYDOWN, VK_UP, 0)
  else if JoyPos.Y > 0 then
    PostMessage(Handle, WM_KEYDOWN, VK_DOWN, 0);
  NotifyKeyboardActivity;
end;

procedure TCustomQuadris.LoadTheme(const ATheme: TThemeName);
var
  Stream: TStream;
  Strings: TStrings;
  Bitmap: TBitmap;
  ThemeID: Integer;
  ItemCount: Integer;
  FrameCount: Integer;
  iItem: Integer;
  ImageList: TCustomImageList;
  iFrame: Integer;
  ItemName: String;
begin
  FItems.Clear;
  FItemImageLists.Clear;
  try
    Stream := TResourceStream.Create(HInstance, ATheme, DefResourceThemeType);
    Strings := TStringList.Create;
    Bitmap := TBitmap.Create;
    try
      Strings.LoadFromStream(Stream);
      ThemeID := StrToInt(Strings.Values['ThemeID']);
      ItemCount := StrToInt(Strings.Values['ItemCount']);
      FrameCount := StrToInt(Strings.Values['FrameCount']);
      FAnimInterval := StrToInt(Strings.Values['Interval']);
      FAnimTimer.Interval := FAnimInterval;
      FThemeColor := StrToInt(Strings.Values['Color']);
      Color := FThemeColor;
      FAnimKind := StrToAnimKind(Strings.Values['AnimKind']);
      FBackground.LoadFromResourceName(HInstance, ATheme);
      for iItem := 0 to ItemCount - 1 do
      begin
        ImageList := TCustomImageList.Create(nil);
        ImageList.Width := DefItemSize;
        ImageList.Height := DefItemSize;
        ImageList.BkColor := clBlack;
        FItemImageLists.Add(ImageList);
        FItemImageLists.DefImageIndexes[iItem] :=
          StrToInt(Strings.Values[IntToStr(iItem)]);
        for iFrame := 0 to FrameCount - 1 do
        begin
          ItemName := Format('%s%d_%d_%d', [DefResourceBmpPrefix,
            ThemeID, iItem, iFrame]);
          Bitmap.LoadFromResourceName(HInstance, ItemName);
          if iItem = ItemCount - 1 then
            ImageList.AddMasked(Bitmap, clNone)
          else
            ImageList.AddMasked(Bitmap, clDefault);
        end;
      end;
      FItems.FFadeItemID := ItemCount - 1;
      FItems.FBombItemID := ItemCount - 2;
      FItems.FMaxItemID := ItemCount - 2;
      FTheme := ATheme;
      Invalidate;
    finally
      Bitmap.Free;
      Strings.Free;
      Stream.Free;
    end;
  except
    on EOutOfMemory do
      raise;
    else
      raise EQuadrisError.CreateFmt(rsErrResCorruptF, [ATheme]);
  end;
end;

function TCustomQuadris.MaxLevelScore(ALevel: TQuadrisLevel): Cardinal;
begin
  Result := (ALevel + 1) * 50 * ALevel;
end;

procedure TCustomQuadris.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  SetFocus;
end;

procedure TCustomQuadris.OnAnimTimer(Sender: TObject);
begin
  FItems.Animate;
  FPointsLabel.Animate;
end;

procedure TCustomQuadris.OnUpdateTimer(Sender: TObject);
begin
  if FItems.FDeleting then
    FAnimTimer.Interval := DefFadeAnimInterval
  else
    FAnimTimer.Interval := FAnimInterval;
  FItems.Update;
end;

procedure TCustomQuadris.Paint;
var
  R: TRect;
begin
  Canvas.Brush.Color := Color;
  R := ClientRect;
  if Ctl3D then
    Frame3D(Canvas, R, FColors.Darker, FColors.Lighter, 1);
  Canvas.FillRect(R);
  R := FView.BoundsRect;
  InflateRect(R, 1, 1);
  Frame3D(Canvas, R, FColors.Dark, FColors.Light, 1);
  PaintView;
end;

procedure TCustomQuadris.PaintView;
var
  R: TRect;
begin
  R.Left := DefMargin * 2 + FView.Width;
  if qoShowNext in Options then
  begin
    R.Top := DefMargin - 4;
    R.Right := Width - DefMargin;
    R.Bottom := R.Top + 2 * Canvas.Font.Size;
    DrawText(Canvas.Handle, PChar('Next:'), -1, R, 0);
    OffsetRect(R, 0, 2 * Canvas.Font.Size);
    R.Right := R.Left + 2 * DefItemSize;
    R.Bottom := R.Top + 2 * DefItemSize;
    with R do
      BitBlt(Canvas.Handle, Left, Top, Right - Left, Bottom - Top,
        FBackground.Canvas.Handle, 0, 0, SRCCOPY);
    InflateRect(R, 1, 1);
    Frame3D(Canvas, R, FColors.Dark, FColors.Light, 1);
    with FItems.FNextPairData, FItemImageLists do
    begin
      case Dir of
        North:
          begin
            Items[ID1].Draw(Canvas, R.Left + DefItemSize div 2, R.Top + DefItemSize,
              DefImageIndexes[ID1], dsTransparent, itImage);
            Items[ID2].Draw(Canvas, R.Left + DefItemSize div 2, R.Top,
              DefImageIndexes[ID2], dsTransparent, itImage);
          end;
        East:
          begin
            Items[ID1].Draw(Canvas, R.Left, R.Top + DefItemSize div 2,
              DefImageIndexes[ID1], dsTransparent, itImage);
            Items[ID2].Draw(Canvas, R.Left + DefItemSize, R.Top + DefItemSize div 2,
              DefImageIndexes[ID2], dsTransparent, itImage);
          end;
        South:
          begin
            Items[ID1].Draw(Canvas, R.Left + DefItemSize div 2, R.Top,
              DefImageIndexes[ID1], dsTransparent, itImage);
            Items[ID2].Draw(Canvas, R.Left + DefItemSize div 2, R.Top + DefItemSize,
              DefImageIndexes[ID2], dsTransparent, itImage);
          end;
        West:
          begin
            Items[ID1].Draw(Canvas, R.Left + DefItemSize, R.Top + DefItemSize div 2,
              DefImageIndexes[ID1], dsTransparent, itImage);
            Items[ID2].Draw(Canvas, R.Left, R.Top + DefItemSize div 2,
              DefImageIndexes[ID2], dsTransparent, itImage);
          end
      end;
    end;
    R.Top := R.Bottom + 2 * Canvas.Font.Size;
    R.Right := Width - Defmargin;
    R.Bottom := R.Top + 2 * Canvas.Font.Size;
  end else
  begin
    R.Top := DefMargin - 4;
    R.Right := Width - DefMargin;
    R.Bottom := R.Top + 2 * Canvas.Font.Size;
  end;
  DrawText(Canvas.Handle, PChar('Score:'), -1, R, 0);
  OffsetRect(R, 0, 2 * Canvas.Font.Size);
  Frame3D(Canvas, R, FColors.Dark, FColors.Light, 1);
  Canvas.FillRect(R);
  DrawText(Canvas.Handle, PChar(IntToStr(FScore)), -1, R, DT_CENTER);
  InflateRect(R, 1, 1);
  OffsetRect(R, 0, 3 * Canvas.Font.Size);
  DrawText(Canvas.Handle, PChar('Level:'), -1, R, 0);
  OffsetRect(R, 0, 2 * Canvas.Font.Size);
  Frame3D(Canvas, R, FColors.Dark, FColors.Light, 1);
  Canvas.FillRect(R);
  DrawText(Canvas.Handle, PChar(IntToStr(FLevel)), -1, R, DT_CENTER);
end;

procedure TCustomQuadris.Pause;
begin
  if Running then
  begin
    Stop;
    FPauseTick := GetTickCount;
    FPaused := True;
  end;
end;

procedure TCustomQuadris.Points(TracedCount, TraceCycle: Word);
begin
  Inc(FScore, FLevel * TracedCount * TraceCycle);
  PaintView;
  DoPoints(FLevel * TracedCount, TraceCycle);
  if TraceCycle = 1 then
    FPointsLabel.Caption := Format('%d', [FLevel * TracedCount])
  else
    FPointsLabel.Caption := Format('%d x %d', [TraceCycle, FLevel * TracedCount]);
  if FItems.Empty then
  begin
    Inc(FScore, ColCount * RowCount * FLevel);
    PaintView;
    DoBonus(ColCount * RowCount, FLevel);
  end;
  UpdateLevel;
end;

procedure TCustomQuadris.SetColor(Value: TColor);
begin
  if Color <> Value then
  begin
    if Value = clDefault then
      inherited Color := FThemeColor
    else
      inherited Color := Value;
    FColors.Light := MixColor(Color, clWhite, 0.25);
    FColors.Lighter := MixColor(Color, clWhite, 0.5);
    FColors.Dark := MixColor(Color, clBlack, 0.25);
    FColors.Darker := MixColor(Color, clBlack, 0.5);
    Invalidate;
  end;
end;

procedure TCustomQuadris.SetLevel(Value: TQuadrisLevel);
begin
  if FLevel <> Value then
  begin
    FLevel := Value;
    if not Running then
      FStartLevel := FLevel;
    Invalidate;
  end;
end;

procedure TCustomQuadris.SetOptions(Value: TQuadrisOptions);
begin
  if FOptions <> Value then
  begin
    if (qoShowNext in (FOptions - Value)) or
        (qoShowNext in (Value - FOptions)) then
      Invalidate;
    if Focused and (qoStartOnFocus in (Value - FOptions)) then
      Start;
    if (not Focused) and (qoPauseOnUnfocus in (Value - FOptions)) then
      Pause;
    FOptions := Value;
  end;
end;

procedure TCustomQuadris.SetRunning(Value: Boolean);
begin
  if csDesigning in ComponentState then
    FStreamedRunning := Value
  else
    if Running <> Value then
    begin
      if Value then
        Start
      else
        Pause;
    end;
end;

procedure TCustomQuadris.SetTheme(const Value: TThemeName);
begin
  if FTheme <> Value then
  begin
    if Running then
      Stop;
    LoadTheme(Value);
  end;
end;

procedure TCustomQuadris.Start;
begin
  if not Running then
  begin
    if FPaused then
    begin
      FItems.SetDelay(GetTickCount - FPauseTick);
      FPaused := False;
    end else
    begin
      FItems.Clear;
      FScore := DefScore;
      FLevel := FStartLevel;
      FItems.ThrowNextPair;
    end;
    FAnimTimer.Enabled := True;
    FUpdateTimer.Enabled := True;
  end;
end;

procedure TCustomQuadris.Stop;
begin
  FUpdateTimer.Enabled := False;
  FAnimTimer.Enabled := False;
end;

procedure TCustomQuadris.UpdateLevel;
begin
  if qoAutoIncLevel in Options then
    if FLevel < High(TQuadrisLevel) then
      if FScore > MaxLevelScore(FLevel) then
      begin
        Inc(FLevel);
        DoLevel;
      end;
end;

procedure TCustomQuadris.WMGetDlgCode(var Message: TMessage);
begin
  if TabStop then
    Message.Result := DLGC_WANTARROWS
  else
    Message.Result := DLGC_WANTARROWS or DLGC_WANTTAB;
end;

procedure TCustomQuadris.WMKeyDown(var Message: TWMKeyDown);
begin
  if Running then
    case Message.CharCode of
      VK_LEFT:
        DoMove(FItems.MoveLeft);
      VK_UP:
        DoRotate(FItems.Rotate);
      VK_RIGHT:
        DoMove(FItems.MoveRight);
      VK_DOWN, VK_SPACE:
        FItems.Drop;
    end;
  inherited;
end;

procedure TCustomQuadris.WMKillFocus(var Message: TWMSetFocus);
begin
  inherited;
  if qoPauseOnUnfocus in Options then
    Pause;
end;

procedure TCustomQuadris.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  if qoStartOnFocus in Options then
    Start;
end;

initialization
  Randomize;

finalization
  if InternalThemeNames <> nil then
    InternalThemeNames.Free;
  if GlobalThemeNames <> nil then
    GlobalThemeNames.Free;

end.
