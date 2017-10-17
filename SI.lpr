program SI;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, AddAutoActionForm, MainUnit, PopupUnit, SettingsFormUnit;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TAddAutoActionForm, Nibba);
  Application.CreateForm(TPopupForm, PopupForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.Run;
end.

