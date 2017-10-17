unit MainUnit;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  LCL, Windows, Variants, StdCtrls, jwawinuser, Menus, LCLType, Buttons, Grids,
  Arrow, PopupNotifier, ComCtrls, DbCtrls, SettingsFormUnit, PopupUnit;

type

  { TMainForm }

  TMainForm = class(TForm)
    ArrowDown: TArrow;
    ArrowUp: TArrow;
    AutoPress: TTimer;
    ExitItem: TMenuItem;
    DragDropArrow1: TLabel;
    DragDropArrow2: TLabel;
    DragDropBG: TShape;
    CurrExecActionShape: TShape;
    TrayPopup: TPopupMenu;
    AddButton: TSpeedButton;
    DeleteButton: TSpeedButton;
    SettingsButton: TSpeedButton;
    StringGrid1: TStringGrid;
    DelayExecTimer: TTimer;
    TrayIcon: TTrayIcon;
    WaitTimer: TTimer;

    GrayedIcon: TIcon;
    NormalIcon: TIcon;

    procedure ArrowDownClick(Sender: TObject);
    procedure ArrowUpClick(Sender: TObject);
    procedure AutoPressTimer(Sender: TObject);
    procedure DelayExecTimerTimer(Sender: TObject);
    procedure ExitItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure AddButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure SettingsButtonClick(Sender: TObject);
    procedure StringGrid1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure StringGrid1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure WaitTimerTimer(Sender: TObject);

    procedure ChangeIntervalInList(indexToChange: longInt; newVal: longInt);

    procedure ExecToggleOn();
    procedure ExecToggleOff();
  private
    { private declarations }
  public
    { public declarations }
  end;

type
  TAutoAction = class (TObject)
    // basically an input and a timer (to wait after executing an INPUT)
    public
    waitTimerInterval: longInt;
    inputAction: jwawinuser.INPUT;
    constructor Create(newInput: jwawinuser.INPUT; newWaitInterval: LongInt);
  end;

  PAutoAction = ^TAutoAction;

const
  NoSelection: TGridRect = (Left: 0; Top: -1; Right: 0; Bottom: -1);

var
  MainForm: TMainForm;
  KeyboardHook: HHook;
  lastIntervalSpellSteal: longInt;

  autoActions: TList;
  currWaitTimerPtr: ^TTimer;
  waitTimerIsOn: boolean;

  keyNameBuffer: array [0..24] of char;
  tempInputArrayBuffer: array of INPUT;

  lastStoppedAutoActionIndex: longInt;
  toggleON: boolean;
  SourceCol, SourceRow: integer;

  popupDuration: longInt;

  doneAllAutoActions: boolean;
implementation

uses AddAutoActionForm;

{$R *.lfm}

procedure TMainForm.ExecToggleOn();
var
  secondsLeft: double;
begin
  secondsLeft := (MainForm.DelayExecTimer.Interval / 1000);

  PopupForm.ChangeCaptionText('SI status update');
  PopupForm.ChangeNotificationText('SI will be turned on in ' + FloatToStr(secondsLeft) + ' second(s)!');
  PopupForm.ShowPopup(popupDuration);

  MainForm.DelayExecTimer.Enabled:=true;
end;

procedure TMainForm.ExecToggleOff();
begin
  MainForm.DelayExecTimer.Enabled := false;
  toggleON := false;
  MainForm.AutoPress.Enabled := false;
  MainForm.WaitTimer.Enabled := false;
  lastStoppedAutoActionIndex := 0;

  PopupForm.ChangeCaptionText('SI status update');
  PopupForm.ChangeNotificationText('SI has been turned off!');
  PopupForm.ShowPopup(popupDuration);

  MainForm.TrayIcon.Icon := MainForm.GrayedIcon;
  MainForm.TrayIcon.Hint := 'SI is off';

  MainForm.CurrExecActionShape.Visible := false;
end;

procedure TMainForm.ChangeIntervalInList(indexToChange: longInt; newVal: longInt);
var
  count: longInt;
  tempActionChange: TAutoAction;
  tempAction: TAutoAction;
begin
  tempActionChange := autoActions.Items[indexToChange];
  if (indexToChange >= 0) and (indexToChange <= autoActions.Count-1) then
  begin
    tempAction := tempActionChange;
    tempAction.waitTimerInterval:=newVal;
    autoActions.Add(tempAction);
    autoActions.Exchange(indexToChange, autoActions.Count-1);
    autoActions.Delete(autoActions.Count-1);
  end;
end;

procedure TMainForm.AddButtonClick(Sender: TObject);
begin
  Nibba.Show;
end;

procedure TMainForm.DeleteButtonClick(Sender: TObject);
begin
  if (StringGrid1.Row <> StringGrid1.RowCount-1) then
  begin
    autoActions.Delete(StringGrid1.Row-1);
    StringGrid1.DeleteRow(StringGrid1.Row);
  end;
end;

procedure TMainForm.SettingsButtonClick(Sender: TObject);
begin
  SettingsForm.Show;
end;

procedure TMainForm.StringGrid1DragDrop(Sender, Source: TObject; X, Y: Integer);
var
  DestCol, DestRow: Integer;

begin
  StringGrid1.MouseToCell(X, Y, DestCol, DestRow); // convert mouse coord.
{ Move contents from source to destination }
  if (SourceRow <> DestRow) and (SourceRow <> StringGrid1.RowCount-1) and (DestRow <> 0) and (DestCol <> 0) and (DestRow <> StringGrid1.RowCount-1) then
  begin
    StringGrid1.ExchangeColRow(false, DestRow, SourceRow);
    autoActions.Exchange(DestRow-1, SourceRow-1);
  end;
  //StringGrid1.BorderSpacing.Left:=5;
end;

procedure TMainForm.StringGrid1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  //showMessage('Over drag');
  //StringGrid1.BorderSpacing.Left:=20;
end;

procedure TMainForm.StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  { Convert mouse coordinates X, Y to
    to StringGrid related col and row numbers }
  StringGrid1.MouseToCell(X, Y, SourceCol, SourceRow);
  { Allow dragging only if an acceptable cell was clicked
    (cell beyond the fixed column and row) }
  if (SourceCol > 0) and (SourceRow > 0) and (SourceCol <> 0) and (SourceRow <> 0) and (SourceCol <> StringGrid1.ColCount-1) and (SourceRow <> StringGrid1.RowCount-1) and (Button = mbLeft) then
    { Begin dragging after mouse has moved 4 pixels }
  begin
    StringGrid1.BeginDrag(False, 4);
    DragDropArrow1.Visible := true;
    DragDropArrow2.Visible := true;
    DragDropArrow1.Top:=StringGrid1.Top+3+(SourceRow*StringGrid1.RowHeights[SourceRow-1]);
  end;
end;

procedure TMainForm.StringGrid1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  DestCol, DestRow: Integer;
begin
  StringGrid1.MouseToCell(X, Y, DestCol, DestRow);

  if (SourceRow <> StringGrid1.RowCount-1) and (DestRow <> 0) and (DestRow <> StringGrid1.RowCount-1) then
    DragDropArrow2.Top:=StringGrid1.Top+3+(DestRow*StringGrid1.RowHeights[DestRow-1]);
end;

procedure TMainForm.StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  DragDropArrow1.Visible := false;
  DragDropArrow2.Visible := false;
end;

procedure TMainForm.WaitTimerTimer(Sender: TObject);
begin
  //showMessage(IntToStr(WaitTimer.Interval));
  WaitTimer.Enabled := false;
  waitTimerIsOn := false;
  AutoPress.Enabled := true;


  if (doneAllAutoActions) then
  begin
    if (SettingsForm.execType) then
    begin
      // repeat
    end
    else
    begin
      // once
      // turn off
      ExecToggleOff;
    end;
  end;

end;

constructor TAutoAction.Create(newInput: jwawinuser.INPUT; newWaitInterval: LongInt);
begin
  inputAction := newInput;
  waitTimerInterval := newWaitInterval;
end;

{ TMainForm }
function isBitSet(const AValueToCheck, ABitIndex: LongInt): Boolean;
begin
  Result := AValueToCheck and (1 shl ABitIndex) <> 0;
end;

function ArrayToString(const a: array of Char): string;
begin
  if Length(a)>0 then
    SetString(Result, PChar(@a[0]), Length(a))
  else
    Result := '';
end;

function keyboardHookProc(nCode: longInt; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  KBInfoStruct: ^KBDLLHOOKSTRUCT;
  vKeyCode: LONG;
  isCtrlDown: boolean;
  isAltDown: boolean;
  isShiftDown: boolean;
begin
  if (nCode < 0) or (wParam <> WM_KEYDOWN) then // if the nCode<0 or the key is now pressed down
  begin
    result := CallNextHookEx(0, nCode, wParam, lParam);
  end;



  KBInfoStruct := PKBDLLHOOKSTRUCT(lParam);
  vKeyCode := KBInfoStruct^.vkCode;

  // Debug
  if (vKeyCode = VK_ESCAPE) then
  begin
    Application.Terminate;
  end;



  isCtrlDown := isBitSet(GetKeyState(VK_LCONTROL), 15);
  isAltDown := isBitSet(GetKeyState(VK_MENU), 15);
  isShiftDown := isBitSet(GetKeyState(VK_SHIFT), 15);


  if (Nibba.isKeyBeingDetected) then
  begin
    Nibba.DetectKeyButton.Enabled:=true;
    Nibba.DetectKeyButton.Caption:='Detect button';
    Nibba.isKeyBeingDetected:=false;
    GetKeyNameText(MapVirtualKey(vKeyCode,0) shl 16, @keyNameBuffer, 25);
    Nibba.KeyDetectedEdit.Caption:=ArrayToString(keyNameBuffer);
    Nibba.VKDetectedEdit.Caption:=IntToStr(vKeyCode);
    Nibba.ScanCodeDetectedEdit.Caption:=IntToStr(MapVirtualKey(vKeyCode, 0));
  end;

  if (wParam = WM_KEYDOWN) and (SettingsForm.isKeyBeingDetectedSettingsOn) and (vKeyCode <> VK_LCONTROL) and (vKeyCode <> VK_LSHIFT) and (vKeyCode <> VK_MENU) then
  begin
    SettingsForm.DetectKeyOn.Enabled:=true;
    SettingsForm.DetectKeyOn.Caption:='Detect key';
    SettingsForm.isKeyBeingDetectedSettingsOn:=false;
    GetKeyNameText(MapVirtualKey(vKeyCode,0) shl 16, @keyNameBuffer, 25);
    SettingsForm.KeyEditOn.Caption:=ArrayToString(keyNameBuffer);
    SettingsForm.onVKCode:=vKeyCode;
  end;

  if (wParam = WM_KEYDOWN) and (SettingsForm.isKeyBeingDetectedSettingsOff) and (vKeyCode <> VK_LCONTROL) and (vKeyCode <> VK_LSHIFT) and (vKeyCode <> VK_MENU) then
  begin
    SettingsForm.DetectKeyOff.Enabled:=true;
    SettingsForm.DetectKeyOff.Caption:='Detect key';
    SettingsForm.isKeyBeingDetectedSettingsOff:=false;
    GetKeyNameText(MapVirtualKey(vKeyCode,0) shl 16, @keyNameBuffer, 25);
    SettingsForm.KeyEditOff.Caption:=ArrayToString(keyNameBuffer);
    SettingsForm.offVKCode:=vKeyCode;
  end;




  if (vKeyCode = SettingsForm.onVKCode)
     and (isCtrlDown = SettingsForm.onNeedsCtrl)
     and (isAltDown = SettingsForm.onNeedsAlt)
     and (isShiftDown = SettingsForm.onNeedsShift)
     and (not(toggleON)) and (wParam = WM_KEYDOWN)
     then
  begin
    // Toggle ON
    MainForm.ExecToggleOn;
  end
  else if (vKeyCode = SettingsForm.offVKCode)
     and (isCtrlDown = SettingsForm.offNeedsCtrl)
     and (isAltDown = SettingsForm.offNeedsAlt)
     and (isShiftDown = SettingsForm.offNeedsShift)
     and (toggleOn) and (wParam = WM_KEYDOWN)
     then
  begin
    // Toggle OFF
    MainForm.ExecToggleOff;
  end;



  result := CallNextHookEx(0, nCode, wParam, lParam);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  doneAllAutoActions:=false;
  popupDuration := 5000;
  StringGrid1.Selection:= NoSelection;
  StringGrid1.SelectedColor:=clBlue;
  toggleON:=false;
  lastStoppedAutoActionIndex := 0;
  ZeroMemory(@keyNameBuffer, 25);
  KeyboardHook := SetWindowsHookEx(WH_KEYBOARD_LL, @keyboardHookProc, HInstance, 0);
  waitTimerIsOn := false;
  MainForm.StringGrid1.InsertRowWithValues(MainForm.StringGrid1.RowCount-1, ['', '', '', '', '', '', '', '']);
  autoActions := TList.Create;
  StringGrid1.AutoSizeColumns;

  CurrExecActionShape.Height := StringGrid1.RowHeights[0];

  NormalIcon := TIcon.Create;
  try
    NormalIcon.LoadFromFile('tray_icons/normal.ico');
  except
    ShowMessage('Could not load normal icon!');
    Application.Terminate;
  end;

  GrayedIcon := TIcon.Create;
  try
    GrayedIcon.LoadFromFile('tray_icons/gray.ico');
  except
    ShowMessage('Could not load gray icon!');
    Application.Terminate;
  end;

end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnhookWindowsHookEx(KeyboardHook);

  TrayIcon.Hide;

  autoActions.Free;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: longInt;
  amountDeleted: longInt;
begin
  if (Key = VK_DELETE) then
  begin
    amountDeleted:=0;

    // Delete selected rows
    for i:=StringGrid1.Selection.Top to StringGrid1.Selection.Bottom do
    begin
      if (i <> StringGrid1.RowCount-1) then
      begin
        StringGrid1.DeleteRow(i-amountDeleted);
        autoActions.Delete(i-1-amountDeleted);
        Inc(amountDeleted);
      end;
    end;
  end;
end;


procedure TMainForm.AutoPressTimer(Sender: TObject);
var
  action: TAutoAction;
  tempInput: INPUT;
  i,j,k: longInt;
  amountOfNoDelayInputs: longInt;
begin
  //
  if (waitTimerIsOn) or (autoActions.Count = 0) then
  begin
    exit;
  end;

  doneAllAutoActions := false;
  amountOfNoDelayInputs := 0;

  for i:=lastStoppedAutoActionIndex to autoActions.Count-1 do
  begin
    //;
    action := autoActions.Items[i];

    if (action.waitTimerInterval <> 2) then // execute from lastStoppedActionIndex to this index and
    begin
      if(lastStoppedAutoActionIndex <> 0) then
      begin
        Inc(amountOfNoDelayInputs);
      end;

      AutoPress.Enabled := false;
      WaitTimer.Interval := action.waitTimerInterval;

      SetLength(tempInputArrayBuffer, 1);
      ZeroMemory(tempInputArrayBuffer, Length(tempInputArrayBuffer));
      for j:=0 to amountOfNoDelayInputs do
      begin
        // copy all inputs with no delays into temp buffer to execute them (including this one)
        if (lastStoppedAutoActionIndex <> 0) then
        begin
          k := (lastStoppedAutoActionIndex-1)+j;
        end
        else
        begin
          k := (lastStoppedAutoActionIndex)+j;
        end;
        action := autoActions.Items[k];
        tempInput := action.inputAction;
        tempInputArrayBuffer[0] := tempInput;

        CurrExecActionShape.Top := StringGrid1.Top + (StringGrid1.RowHeights[0] * (k+1));
        CurrExecActionShape.Repaint;
        (SendInput(Length(tempInputArrayBuffer), @tempInputArrayBuffer[0], sizeof(tempInputArrayBuffer[0])));
      end;

      if (i <> autoActions.Count-1) then
      begin
        doneAllAutoActions := false;
        lastStoppedAutoActionIndex := i+1;
      end
      else
      begin
        lastStoppedAutoActionIndex := 0;
        doneAllAutoActions := true;
      end;

      WaitTimer.Enabled := true;
      exit;
    end
    else
    begin
      Inc(amountOfNoDelayInputs);
    end;
  end;

  //showMessage(IntToStr(AmountOfNoDelayInputs));
  SetLength(tempInputArrayBuffer, 1);
  ZeroMemory(tempInputArrayBuffer, Length(tempInputArrayBuffer));
  j:=0;
  if (lastStoppedAutoActionIndex = 0) then
  begin
    i:=lastStoppedAutoActionIndex;
  end
  else
  begin
    i:=lastStoppedAutoActionIndex-1;
  end;
  while (i < lastStoppedAutoActionIndex+AmountOfNoDelayInputs) do
  begin
    action := autoActions.Items[i];
    tempInput := action.inputAction;
    tempInputArrayBuffer[0] := tempInput;
    CurrExecActionShape.Top := StringGrid1.Top + (StringGrid1.RowHeights[0] * (i+1));
    CurrExecActionShape.Repaint;
    SendInput(Length(tempInputArrayBuffer), @tempInputArrayBuffer[0], sizeof(tempInputArrayBuffer[0]));
    Inc(j);
    Inc(i);
  end;
  lastStoppedAutoActionIndex := 0;
  doneAllAutoActions := true;

  if (SettingsForm.execType) then
  begin
    // repeat
    CurrExecActionShape.Top := StringGrid1.Top + (StringGrid1.RowHeights[0]);
  end
  else
  begin
    // once
    // turn off
    ExecToggleOff;
  end;

end;

procedure TMainForm.DelayExecTimerTimer(Sender: TObject);
begin
  // Start executing
  doneAllAutoActions := false;
  toggleON := true;
  MainForm.AutoPress.Enabled := true;
  MainForm.WaitTimer.Enabled := true;
  lastStoppedAutoActionIndex := 0;

  DelayExecTimer.Enabled:=false;

  PopupForm.ChangeCaptionText('SI status update');
  PopupForm.ChangeNotificationText('SI has been turned on!');
  PopupForm.ShowPopup(popupDuration);

  if (autoActions.Count > 0) then
  begin
    CurrExecActionShape.Visible := true;
    CurrExecActionShape.Top := StringGrid1.Top + StringGrid1.RowHeights[0];
  end;
  MainForm.TrayIcon.Icon := MainForm.NormalIcon;
  MainForm.TrayIcon.Hint := 'SI is on';
end;

procedure TMainForm.ExitItemClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.ArrowUpClick(Sender: TObject);
var
  indexToSwap, indexToSwapFor: longInt;
begin
  if (autoActions.Count < 2) then
  begin
    exit;
  end;

  indexToSwap := StringGrid1.Row-1;
  indexToSwapFor := indexToSwap - 1;

  if (indexToSwapFor < 0) or (indexToSwapFor > autoActions.Count-1) then
  begin
    exit;
  end;

  autoActions.Exchange(indexToSwap, indexToSwapFor);
  StringGrid1.ExchangeColRow(false, indexToSwap+1, indexToSwapFor+1);
end;

procedure TMainForm.ArrowDownClick(Sender: TObject);
var
  indexToSwap, indexToSwapFor: longInt;
begin
  if (autoActions.Count < 2) then
  begin
    exit;
  end;

  indexToSwap := StringGrid1.Row-1;
  indexToSwapFor := indexToSwap + 1;

  if (indexToSwapFor < 0) or (indexToSwapFor > autoActions.Count-1) then
  begin
    exit;
  end;

  autoActions.Exchange(indexToSwap, indexToSwapFor);
  StringGrid1.ExchangeColRow(false, indexToSwap+1, indexToSwapFor+1);
end;

end.

