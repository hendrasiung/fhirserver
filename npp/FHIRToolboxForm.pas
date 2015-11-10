unit FHIRToolboxForm;

interface

{
On the toolbox:
  ----
  Change Server
  <server>
  Open by Client
  Put / Post / Transaction (if bundle)
  Validate on Server
  ----
  New from Template
  JSON <-> XML
  Validation/Intellisense on/off
  ----
  <path>
  EvaluatePath
  ----
  Settings
  Close


icons
  0  server
  1  client open
  2  post
  3  put
  4  transaction
  5  validate
  6  new
  7  format change
  8  evaluate path
  9  settings
  10 close

}

uses
  Windows, Messages, SysUtils, Variants, Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, NppDockingForms, Vcl.StdCtrls, NppPlugin, Vcl.ToolWin,
  Vcl.ComCtrls, System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Styles, Vcl.Themes,
  FHIRPathDocumentation;

type
  TFHIRToolbox = class(TNppDockingForm)
    mPath: TMemo;
    ImageList1: TImageList;
    ToolBar1: TToolBar;
    tbConnect: TToolButton;
    ToolButton3: TToolButton;
    tbOpen: TToolButton;
    tbPut: TToolButton;
    tbTransaction: TToolButton;
    tbServerValidate: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    tbPost: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    cbxServers: TComboBox;
    Panel1: TPanel;
    ToolButton16: TToolButton;
    ToolButton17: TToolButton;
    ToolButton18: TToolButton;
    ToolButton19: TToolButton;
    ToolButton20: TToolButton;
    ToolButton21: TToolButton;
    pnlMessage: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormHide(Sender: TObject);
    procedure FormFloat(Sender: TObject);
    procedure FormDock(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ToolButton11Click(Sender: TObject);
    procedure ToolButton14Click(Sender: TObject);
    procedure ToolButton18Click(Sender: TObject);
    procedure ToolButton10Click(Sender: TObject);
    procedure ToolButton15Click(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure tbConnectClick(Sender: TObject);
    procedure ToolButton9Click(Sender: TObject);
    procedure tbOpenClick(Sender: TObject);
    procedure tbPutClick(Sender: TObject);
    procedure tbPostClick(Sender: TObject);
    procedure tbTransactionClick(Sender: TObject);
    procedure tbServerValidateClick(Sender: TObject);
    procedure ToolButton16Click(Sender: TObject);
    procedure ToolButton17Click(Sender: TObject);
    procedure ToolButton21Click(Sender: TObject);
    procedure cbxServersChange(Sender: TObject);
    procedure mPathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mPathEnter(Sender: TObject);
    procedure mPathChange(Sender: TObject);
  private
    { Private declarations }
    FMessageShort, FMessageLong : String;
    FFirstPathEdit : boolean;
  public
    { Public declarations }
    procedure connected(name, url, user, scopes : String);
    procedure disconnected;
    procedure loadServers;
  end;

var
  FHIRToolbox: TFHIRToolbox;

procedure OpMessage(msgShort, msgLong : String);

implementation

{$R *.dfm}

Uses
  FHIRPluginSettings,
  NewServerForm,
  FHIRPlugin;

procedure OpMessage(msgShort, msgLong : String);
begin
  if (assigned(FHIRToolbox)) then
  begin
    if msgShort = '' then
      msgShort := FHIRToolbox.FMessageShort;
    if msgLong = '' then
      msgLong := FHIRToolbox.FMessageLong;
    FHIRToolbox.pnlMessage.Caption := '  '+msgShort;
    FHIRToolbox.pnlMessage.Hint := msgLong;
    FHIRToolbox.Update;
  end;
end;

procedure TFHIRToolbox.FormCreate(Sender: TObject);
begin
  self.NppDefaultDockingMask := DWS_DF_FLOATING; // whats the default docking position
  self.KeyPreview := true; // special hack for input forms
  self.OnFloat := self.FormFloat;
  self.OnDock := self.FormDock;
  if mPath.Text = Settings.Path then
  begin
    mPath.Text := 'Path...';
    FFirstPathEdit := true;
  end
  else
    mPath.Text := Settings.Path;
  inherited;
end;

procedure TFHIRToolbox.Button1Click(Sender: TObject);
begin
  inherited;
  self.UpdateDisplayInfo('test');
end;

procedure TFHIRToolbox.Button2Click(Sender: TObject);
begin
  inherited;
  self.Hide;
end;

procedure TFHIRToolbox.cbxServersChange(Sender: TObject);
begin
  inherited;
  _FuncDisconnect;
  if cbxServers.ItemIndex = cbxServers.Items.Count - 1 then
  begin
    RegisterServerForm := TRegisterServerForm.create(npp);
    try
      if RegisterServerForm.ShowModal = mrOk then
      begin
        cbxServers.items.Insert(cbxServers.ItemIndex, RegisterServerForm.edtName.Text+' ('+RegisterServerForm.edtServer.Text+')');
        cbxServers.ItemIndex := cbxServers.Items.Count - 2;
      end
      else
        cbxServers.ItemIndex := 0;
    finally
      RegisterServerForm.Free;
    end;
  end;
end;

procedure TFHIRToolbox.connected(name, url, user, scopes : String);
begin
  tbConnect.ImageIndex := 15;
  tbConnect.Hint := 'Disconnect from '+name;
  if (scopes = '') then
  begin
    FMessageShort := 'Connected';
    FMessageLong := 'Connected to '+name+' ('+url+', no security)'
  end
  else
  begin
    FMessageShort := 'Connected as '+user;
    FMessageLong := 'Connected to '+name+' ('+url+', user = '+user+', scopes = "'+scopes+'")';
  end;
  OpMessage('', '');
  tbOpen.Enabled := true;
  tbPut.Enabled := true;
  tbPost.Enabled := true;
  tbTransaction.Enabled := true;
  tbServerValidate.Enabled := true;
end;

procedure TFHIRToolbox.disconnected;
begin
  tbConnect.ImageIndex := 0;
  ToolBar1.Color := clBtnFace;
  FMessageShort := '';
  FMessageLong := '';
  OpMessage('', '');
  tbOpen.Enabled := false;
  tbPut.Enabled := false;
  tbPost.Enabled := false;
  tbTransaction.Enabled := false;
  tbServerValidate.Enabled := false;
end;

// special hack for input forms
// This is the best possible hack I could came up for
// memo boxes that don't process enter keys for reasons
// too complicated... Has something to do with Dialog Messages
// I sends a Ctrl+Enter in place of Enter
procedure TFHIRToolbox.FormKeyPress(Sender: TObject;
  var Key: Char);
begin
  inherited;
  if (Key = #13) and (self.mPath.Focused) then self.mPath.Perform(WM_CHAR, 10, 0);
end;

// Docking code calls this when the form is hidden by either "x" or self.Hide
procedure TFHIRToolbox.FormHide(Sender: TObject);
begin
  inherited;
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 0);
  Settings.ToolboxVisible := false;
end;

procedure TFHIRToolbox.FormDock(Sender: TObject);
begin
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 1);
end;

procedure TFHIRToolbox.FormFloat(Sender: TObject);
begin
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 1);
end;

procedure TFHIRToolbox.FormShow(Sender: TObject);
begin
  inherited;
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 1);
  Settings.ToolboxVisible := true;
  loadServers;
end;

procedure TFHIRToolbox.loadServers;
begin
  cbxServers.Items.Clear;
  Settings.listServers(cbxServers.Items);
  cbxServers.Items.Add('Register...');
  cbxServers.ItemIndex := 0;
  SendMessage(cbxServers.Handle, CB_SETDROPPEDWIDTH, 300, 0);
end;

procedure TFHIRToolbox.mPathChange(Sender: TObject);
begin
  Settings.Path := mPath.Text;
end;

procedure TFHIRToolbox.mPathEnter(Sender: TObject);
begin
  inherited;
  if FFirstPathEdit then
    mPath.Clear;
  FFirstPathEdit := false;
end;

procedure TFHIRToolbox.mPathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  inherited;
  if key = VK_F1 then
  begin
    FHIRPathDocumentationForm := TFHIRPathDocumentationForm.Create(self);
    try
      FHIRPathDocumentationForm.ShowModal;
    finally
      FHIRPathDocumentationForm.Free;
    end;
  end;
end;

procedure TFHIRToolbox.ToolButton10Click(Sender: TObject);
begin
  _FuncFormat;
end;

procedure TFHIRToolbox.ToolButton11Click(Sender: TObject);
begin
  _FuncValidate;
end;

procedure TFHIRToolbox.tbPostClick(Sender: TObject);
begin
  _FuncPOST;
end;

procedure TFHIRToolbox.ToolButton14Click(Sender: TObject);
begin
  _FuncValidateClear;
end;

procedure TFHIRToolbox.ToolButton15Click(Sender: TObject);
begin
  FNpp.FuncPath;
end;

procedure TFHIRToolbox.ToolButton16Click(Sender: TObject);
begin
  _FuncSettings;
end;

procedure TFHIRToolbox.ToolButton17Click(Sender: TObject);
begin
  _FuncToolbox;
end;

procedure TFHIRToolbox.ToolButton18Click(Sender: TObject);
begin
  _FuncAbout;
end;

procedure TFHIRToolbox.ToolButton1Click(Sender: TObject);
begin
  _FuncServers;
end;

procedure TFHIRToolbox.ToolButton21Click(Sender: TObject);
begin
  _FuncNarrative;
end;

procedure TFHIRToolbox.tbConnectClick(Sender: TObject);
begin
  if FNpp.connected then
    _FuncDisconnect
  else
    _FuncConnect;
end;

procedure TFHIRToolbox.tbOpenClick(Sender: TObject);
begin
  _FuncOpen;
end;

procedure TFHIRToolbox.tbPutClick(Sender: TObject);
begin
  _FuncPUT;
end;

procedure TFHIRToolbox.tbTransactionClick(Sender: TObject);
begin
  _FuncTransaction;
end;

procedure TFHIRToolbox.tbServerValidateClick(Sender: TObject);
begin
  _FuncServerValidate;
end;

procedure TFHIRToolbox.ToolButton9Click(Sender: TObject);
begin
  _FuncNewResource;
end;


end.
