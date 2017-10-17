unit PopupUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Windows, SettingsFormUnit;

type

  { TPopupForm }

  TPopupForm = class(TForm)
    Image1: TImage;
    CloseButton: TLabel;
    NotificationCaptionShadowTop: TLabel;
    NotificationCaptionShadow: TLabel;
    NotificationTextShadow: TLabel;
    NotificationTextShadowTop: TLabel;
    OuterAndInnerRect: TShape;
    ShowTimer: TTimer;
    FadeInTimer: TTimer;
    FadeOutTimer: TTimer;
    procedure CloseButtonClick(Sender: TObject);
    procedure FadeInTimerTimer(Sender: TObject);
    procedure FadeOutTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure ShowTimerTimer(Sender: TObject);
    procedure StayOnTopTimerTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure ShowPopup(howLong: longInt);
    procedure ChangeCaptionText(newText: string);
    procedure ChangeNotificationText(newText: string);
    procedure UnShowPopup();
  end;

var
  PopupForm: TPopupForm;

  isBeingShown: boolean;
  popUpPosX, popUpPosY: longInt;

implementation

{$R *.lfm}

{ TPopupForm }


procedure TPopupForm.FormCreate(Sender: TObject);
begin
  isBeingShown := false;

  popUpPosY := Screen.WorkAreaHeight-8-PopupForm.Height;
  popUpPosX := Screen.WorkAreaWidth-8-PopupForm.Width;

  PopupForm.Top:=popUpPosY;
  PopupForm.Left:=popUpPosX;

  //ShowMessage(IntToStr(Screen.WorkAreaWidth));
end;

procedure TPopupForm.FormDeactivate(Sender: TObject);
begin
end;

procedure TPopupForm.FadeInTimerTimer(Sender: TObject);
begin
  FadeOutTimer.Enabled:=false;
  PopupForm.Visible:=true;
  if (PopupForm.AlphaBlendValue = 255) then
  begin
    FadeInTimer.Enabled:=false; // fade in completed
    isBeingShown := true;
  end
  else
  begin
    PopupForm.AlphaBlendValue:=PopupForm.AlphaBlendValue+5;
  end;
end;

procedure TPopupForm.CloseButtonClick(Sender: TObject);
begin
  UnShowPopup;
end;

procedure TPopupForm.FadeOutTimerTimer(Sender: TObject);
begin
  FadeInTimer.Enabled:=false;
  if (PopupForm.AlphaBlendValue = 0) then
  begin
    FadeOutTimer.Enabled:=false; // fade out completed
    isBeingShown := false;
    PopupForm.Visible:=false;
  end
  else
  begin
    PopupForm.AlphaBlendValue:=PopupForm.AlphaBlendValue-5;
  end;
end;

procedure TPopupForm.ShowTimerTimer(Sender: TObject);
begin
  UnShowPopup;
end;

procedure TPopupForm.StayOnTopTimerTimer(Sender: TObject);
begin
  if (Visible) then
  begin
    SetWindowPos(Self.Handle, HWND_TOPMOST, popUpPosX, popUpPosY, 0, 0, SWP_NOSIZE);
  end;
end;

procedure TPopupForm.ShowPopup(howLong: longInt);
begin
  if not(SettingsForm.notificationsEnabled) then
  begin
    exit;
  end;

  if (isBeingShown) then
  begin
    // We're already showing some notification, just reset the timer
    if (PopupForm.AlphaBlendValue <> 255) then
    begin
      FadeOutTimer.Enabled:=false;
      PopupForm.AlphaBlendValue:=255;
    end;
  end
  else
  begin
    //
    FadeInTimer.Enabled := true;
  end;

  showTimer.Enabled:=false;
  showTimer.Interval:=howLong;
  showTimer.Enabled:=true;
end;

procedure TPopupForm.UnShowPopup();
begin
  FadeOutTimer.Enabled:=true;
end;

procedure TPopupForm.ChangeCaptionText(newText: string);
begin
  NotificationCaptionShadow.Caption:=newText;
  NotificationCaptionShadowTop.Caption:=newText;
end;

procedure TPopupForm.ChangeNotificationText(newText: string);
begin
  NotificationTextShadow.Caption:=newText;
  NotificationTextShadowTop.Caption:=newText;
end;

end.

