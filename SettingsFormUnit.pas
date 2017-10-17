unit SettingsFormUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, EditBtn,
  StdCtrls, Types, LCLType;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    AltEditOff: TEdit;
    NotificationsCheckBox: TCheckBox;
    NotificationDurationEdit: TEdit;
    NotificationDurationLabel: TLabel;
    OkButton: TButton;
    CtrlEditOff: TEdit;
    DetectKeyOn: TButton;
    DetectKeyOff: TButton;
    EnableAltOff: TCheckBox;
    EnableCtrlOff: TCheckBox;
    EnableShiftOn: TCheckBox;
    EnableCtrlOn: TCheckBox;
    EnableAltOn: TCheckBox;
    EnableShiftOff: TCheckBox;
    ExecTypeCombo: TComboBox;
    ExecTypeLabel: TLabel;
    DelayBeforeExecEdit: TEdit;
    KeyEditOff: TEdit;
    Plus1Off: TLabel;
    Plus2Off: TLabel;
    Plus3Off: TLabel;
    ShiftEditOn: TEdit;
    CtrlEditOn: TEdit;
    AltEditOn: TEdit;
    KeyEditOn: TEdit;
    SettingsBox: TGroupBox;
    DelayBeforeExecLabel: TLabel;
    ShiftEditOff: TEdit;
    ToggleOnBox: TGroupBox;
    Plus1On: TLabel;
    Plus2On: TLabel;
    Plus3On: TLabel;
    ToggleOffBox: TGroupBox;
    procedure DelayBeforeExecEditEditingDone(Sender: TObject);
    procedure DetectKeyOffClick(Sender: TObject);
    procedure DetectKeyOnClick(Sender: TObject);
    procedure EnableAltOffClick(Sender: TObject);
    procedure EnableAltOnClick(Sender: TObject);
    procedure EnableCtrlOffClick(Sender: TObject);
    procedure EnableCtrlOnClick(Sender: TObject);
    procedure EnableShiftOffClick(Sender: TObject);
    procedure EnableShiftOnClick(Sender: TObject);
    procedure ExecTypeComboEditingDone(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure NotificationDurationEditEditingDone(Sender: TObject);
    procedure NotificationsCheckBoxClick(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    isKeyBeingDetectedSettingsOff: boolean;
    isKeyBeingDetectedSettingsOn: boolean;

    onNeedsShift: boolean;
    onNeedsCtrl: boolean;
    onNeedsAlt: boolean;
    onVKCode: longInt;

    offNeedsShift: boolean;
    offNeedsCtrl: boolean;
    offNeedsAlt: boolean;
    offVKCode: longInt;

    abortVKCode: longInt;

    execType: boolean; // true - repeat, false - once

    notificationsEnabled: boolean;
  end;

var
  SettingsForm: TSettingsForm;

implementation

uses MainUnit, PopupUnit;

{$R *.lfm}

{ TSettingsForm }

procedure TSettingsForm.DelayBeforeExecEditEditingDone(Sender: TObject);
begin
  if (StrToInt(DelayBeforeExecEdit.Text) < 1) then
  begin
    DelayBeforeExecEdit.Text := '1';
  end;

  MainForm.DelayExecTimer.Interval:=StrToInt(DelayBeforeExecEdit.Text);
end;

procedure TSettingsForm.DetectKeyOffClick(Sender: TObject);
begin
  DetectKeyOff.Enabled:=false;
  DetectKeyOff.Caption:='Push a button!';
  isKeyBeingDetectedSettingsOff := true;
end;

procedure TSettingsForm.DetectKeyOnClick(Sender: TObject);
begin
  DetectKeyOn.Enabled:=false;
  DetectKeyOn.Caption:='Push a button!';
  isKeyBeingDetectedSettingsOn := true;
end;

procedure TSettingsForm.EnableAltOffClick(Sender: TObject);
begin
  AltEditOff.Enabled := (Sender as TCheckBox).Checked;
  offNeedsAlt := (Sender as TCheckBox).Checked;
end;

procedure TSettingsForm.EnableAltOnClick(Sender: TObject);
begin
  AltEditOn.Enabled := (Sender as TCheckBox).Checked;
  onNeedsAlt := (Sender as TCheckBox).Checked;
end;

procedure TSettingsForm.EnableCtrlOffClick(Sender: TObject);
begin
  CtrlEditOff.Enabled := (Sender as TCheckBox).Checked;
  offNeedsCtrl := (Sender as TCheckBox).Checked;
end;

procedure TSettingsForm.EnableCtrlOnClick(Sender: TObject);
begin
  CtrlEditOn.Enabled := (Sender as TCheckBox).Checked;
  onNeedsCtrl := (Sender as TCheckBox).Checked;
end;

procedure TSettingsForm.EnableShiftOffClick(Sender: TObject);
begin
  ShiftEditOff.Enabled := (Sender as TCheckBox).Checked;
  offNeedsShift := (Sender as TCheckBox).Checked;
end;

procedure TSettingsForm.EnableShiftOnClick(Sender: TObject);
begin
  ShiftEditOn.Enabled := (Sender as TCheckBox).Checked;
  onNeedsShift := (Sender as TCheckBox).Checked;
end;

procedure TSettingsForm.ExecTypeComboEditingDone(Sender: TObject);
begin
  if (ExecTypeCombo.ItemIndex = 0) then
  begin
    execType := true;
  end
  else if (ExecTypeCombo.ItemIndex = 1) then
  begin
    execType := false;
  end;
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  execType := true;
  notificationsEnabled := true;

  onNeedsShift := false;
  onNeedsAlt := false;
  onNeedsCtrl := true;
  onVKCode := VK_1;

  offNeedsShift := false;
  offNeedsAlt := false;
  offNeedsCtrl := true;
  offVKCode := VK_1;
end;

procedure TSettingsForm.NotificationDurationEditEditingDone(Sender: TObject);
begin
  if (StrToInt(NotificationDurationEdit.Caption) < 1000) then
  begin
    NotificationDurationEdit.Caption := '1000';
  end;
  MainUnit.popupDuration := StrToInt(NotificationDurationEdit.Caption);
end;

procedure TSettingsForm.NotificationsCheckBoxClick(Sender: TObject);
begin
  notificationsEnabled := (Sender as TCheckBox).Checked;
  PopupForm.Visible := notificationsEnabled;
end;

procedure TSettingsForm.OkButtonClick(Sender: TObject);
begin
  SettingsForm.Close;
end;


end.

