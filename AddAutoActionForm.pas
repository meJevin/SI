unit AddAutoActionForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, Windows, Messages, Variants, jwawinuser;

type

  { TAddAutoActionForm }

  TAddAutoActionForm = class(TForm)
    AddActionButton: TButton;
    OKButton: TButton;
    DetectKeyButton: TButton;
    DelayEdit: TEdit;
    KeyDetectedEdit: TEdit;
    DelayLabel: TLabel;
    VKDetectedEdit: TEdit;
    ScanCodeDetectedEdit: TEdit;
    VKDetectedLabel: TLabel;
    KeyDetectionGroupBox: TGroupBox;
    InputButtonLabel1: TLabel;
    InputTypeCombo: TComboBox;
    InputButtonCombo: TComboBox;
    InputTypeCombo1: TComboBox;
    InputTypeLabel1: TLabel;
    KeyDetectedLabel: TLabel;
    MovementXEdit: TEdit;
    MovementYEdit: TEdit;
    InputTypeLabel: TLabel;
    MovementXLabel: TLabel;
    MovementYLabel: TLabel;
    InputButtonLabel: TLabel;
    MouseInputInfoBox: TGroupBox;
    InputSelectionBox: TComboBox;
    InputTypeSelection: TGroupBox;
    KeyboardInputInfoBox: TGroupBox;
    TypeOfInputLabel: TLabel;
    ScanCodeDetectedLabel: TLabel;
    procedure AddActionButtonClick(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure DelayEditEditingDone(Sender: TObject);
    procedure DetectKeyButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure InputSelectionBoxChange(Sender: TObject);
    procedure InputTypeComboChange(Sender: TObject);
    procedure KeyDetectionGroupBoxClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    isKeyBeingDetected: boolean;
  end;

var
  Nibba: TAddAutoActionForm;

implementation

uses MainUnit;

{$R *.lfm}

{ TAddAutoActionForm }


procedure TAddAutoActionForm.InputTypeComboChange(Sender: TObject);
begin
  if ((Sender as TComboBox).Items[(Sender as TComboBox).ItemIndex] = 'Move') then
  begin
    MovementXLabel.Enabled:=true;
    MovementXEdit.Enabled:=true;
    MovementYLabel.Enabled:=true;
    MovementYEdit.Enabled:=true;

    InputButtonLabel.Enabled:=false;
    InputButtonCombo.Enabled:=false;
  end
  else
  begin
    MovementXLabel.Enabled:=false;
    MovementXEdit.Enabled:=false;
    MovementYLabel.Enabled:=false;
    MovementYEdit.Enabled:=false;

    InputButtonLabel.Enabled:=true;
    InputButtonCombo.Enabled:=true;
  end;
end;

procedure TAddAutoActionForm.KeyDetectionGroupBoxClick(Sender: TObject);
begin

end;

procedure TAddAutoActionForm.InputSelectionBoxChange(Sender: TObject);
begin
  if ((Sender as TComboBox).Items[(Sender as TComboBox).ItemIndex] = 'Keyboard') then
  begin
    MouseInputInfoBox.Visible:=false;
    KeyboardInputInfoBox.Visible:=true;
  end
  else
  begin
    MouseInputInfoBox.Visible:=true;
    KeyboardInputInfoBox.Visible:=false;
  end;
end;

procedure TAddAutoActionForm.DetectKeyButtonClick(Sender: TObject);
begin
  isKeyBeingDetected := true;
  (Sender as TButton).Enabled:=false;
  (Sender as TButton).Caption:='Push some key!';
end;

procedure TAddAutoActionForm.FormCreate(Sender: TObject);
begin

end;

procedure TAddAutoActionForm.AddActionButtonClick(Sender: TObject);
var
  newInput: INPUT;
  newWaitInterval: LONG;
  newTempPtr: ^TAutoAction;
  temp: TAutoAction;
  inputTypeStr: string;
  pressReleaseStr: string;
  buttonStr: string;
  moveStr: string;
  XStr: string;
  YStr: string;
begin
  if (DelayEdit.Caption = '') then
  begin
    Application.MessageBox('Delay was not entered!', 'Error', MB_ICONWARNING or MB_OK);
    exit;
  end
  else if (KeyboardInputInfoBox.Visible) and ((KeyDetectedEdit.Caption = '') or (VKDetectedEdit.Caption = '') or (ScanCodeDetectedEdit.Caption = '')) then
  begin
    //
    Application.MessageBox('Key detection failed! Try again!', 'Error', MB_ICONWARNING or MB_OK);
    exit;
  end
  else if (InputSelectionBox.Items[InputSelectionBox.ItemIndex] = 'Mouse')
          and
          (InputTypeCombo.Items[InputTypeCombo.ItemIndex] = 'Move')
          and
          ((MovementXEdit.Caption = '') or (MovementYEdit.Caption = '')) then
  begin
    Application.MessageBox('X and Y movement was not entered!', 'Error', MB_ICONWARNING or MB_OK);
    exit;
  end;

  if (InputSelectionBox.Items[InputSelectionBox.ItemIndex] = 'Keyboard') then
  begin
    //
    inputTypeStr := 'Keyboard';
    newInput.type_ := INPUT_KEYBOARD;
    newInput.ki.dwFlags := KEYEVENTF_SCANCODE;
    pressReleaseStr := 'Press';
    if (InputTypeCombo1.Items[InputTypeCombo1.ItemIndex] = 'Release a button') then
    begin
      pressReleaseStr := 'Release';
      newInput.ki.dwFlags := KEYEVENTF_SCANCODE or KEYEVENTF_KEYUP;
    end;
    newInput.ki.wScan := StrToInt(ScanCodeDetectedEdit.Caption);
    newInput.ki.wVk := 0;
    buttonStr := KeyDetectedEdit.Caption;
    moveStr := 'No';
    XStr := '0';
    YStr := '0';
  end
  else
  begin
    inputTypeStr := 'Mouse';
    newInput.type_ := INPUT_MOUSE;
    newInput.mi.time:=0;
    newInput.mi.dwFlags:=0;
    if (InputTypeCombo.Items[InputTypeCombo.ItemIndex] = 'Release a button') then
    begin
      //
      pressReleaseStr := 'Release';
      newInput.mi.dx:=0;
      newInput.mi.dy:=0;

      if (InputButtonCombo.Items[InputButtonCombo.ItemIndex] = 'LMB') then
      begin
        buttonStr := 'LMB';
        newInput.mi.dwFlags:=MOUSEEVENTF_LEFTUP;
      end
      else if (InputButtonCombo.Items[InputButtonCombo.ItemIndex] = 'RMB') then
      begin
        buttonStr := 'RMB';
        newInput.mi.dwFlags:=MOUSEEVENTF_RIGHTUP;
      end
      else
      begin
        buttonStr := 'MMB';
        newInput.mi.dwFlags:=MOUSEEVENTF_MIDDLEUP;
      end;
      moveStr := 'No';
    end
    else if (InputTypeCombo.Items[InputTypeCombo.ItemIndex] = 'Press a button') then
    begin
      //
      pressReleaseStr := 'Press';
      newInput.mi.dx:=0;
      newInput.mi.dy:=0;

      if (InputButtonCombo.Items[InputButtonCombo.ItemIndex] = 'LMB') then
      begin
        buttonStr := 'LMB';
        newInput.mi.dwFlags:=MOUSEEVENTF_LEFTDOWN;
      end
      else if (InputButtonCombo.Items[InputButtonCombo.ItemIndex] = 'RMB') then
      begin
        buttonStr := 'RMB';
        newInput.mi.dwFlags:=MOUSEEVENTF_RIGHTDOWN;
      end
      else
      begin
        buttonStr := 'MMB';
        newInput.mi.dwFlags:=MOUSEEVENTF_MIDDLEDOWN;
      end;
      moveStr := 'No';
    end
    else
    begin
      // Move !
      pressReleaseStr := 'No';
      buttonStr := 'No';
      moveStr := 'Yes';
      newInput.mi.dx := StrToInt(MovementXEdit.Caption) * (65536 div GetSystemMetrics(SM_CXSCREEN)); //x being coord in pixels
      newInput.mi.dy :=  StrToInt(MovementYEdit.Caption) * (65536 div GetSystemMetrics(SM_CYSCREEN)); //y being coord in pixels
      XStr := MovementXEdit.Caption;
      YStr := MovementYEdit.Caption;
      newInput.mi.dwFlags := MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_MOVE;
    end;
  end;

  newWaitInterval := StrToInt(DelayEdit.Caption);

  if(newWaitInterval = 0) then
  begin
    newWaitInterval := 2;
  end;

  temp := TAutoAction.Create(newInput, newWaitInterval);
  autoActions.Add(temp);

  MainForm.StringGrid1.InsertRowWithValues(MainForm.StringGrid1.RowCount-1, ['',
                                                                            inputTypeStr,
                                                                            pressReleaseStr,
                                                                            buttonStr, moveStr,
                                                                            XStr, YStr,
                                                                            DelayEdit.Caption]);

end;

procedure TAddAutoActionForm.OKButtonClick(Sender: TObject);
begin
  Nibba.Visible := false;
end;

procedure TAddAutoActionForm.DelayEditEditingDone(Sender: TObject);
begin
  if (StrToInt(DelayEdit.Caption) < 2) then
  begin
    DelayEdit.Caption := '2';
  end;
end;

end.

