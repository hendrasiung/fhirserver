unit NewResourceForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  nppforms,
  FHIRResources, FHIRTypes, FHIRPluginValidator, FHIRProfileUtilities, FHIRParserBase, FHIRParser;

type
  TResourceNewForm = class(TNppForm)
    PageControl1: TPageControl;
    Panel1: TPanel;
    tbResources: TTabSheet;
    tbProfiles: TTabSheet;
    lbResources: TListBox;
    lbProfiles: TListBox;
    Label1: TLabel;
    edtFilter: TEdit;
    btnCreate: TButton;
    Button2: TButton;
    Panel2: TPanel;
    Label2: TLabel;
    rbJson: TRadioButton;
    rbXml: TRadioButton;
    procedure FormShow(Sender: TObject);
    procedure edtFilterChange(Sender: TObject);
    procedure lbResourcesClick(Sender: TObject);
    procedure btnCreateClick(Sender: TObject);
    procedure lbProfilesClick(Sender: TObject);
  private
    { Private declarations }
    FValidator : TFHIRValidator;
    procedure loadLists;
    procedure SetValidator(const Value: TFHIRValidator);
  public
    { Public declarations }
    destructor Destroy; override;

    property Validator : TFHIRValidator read FValidator write SetValidator;
  end;

var
  ResourceNewForm: TResourceNewForm;

implementation

{$R *.dfm}

Uses
  FhirPlugin;

procedure TResourceNewForm.btnCreateClick(Sender: TObject);
var
  sd : TFhirStructureDefinition;
  pu : TProfileUtilities;
  res : TFhirResource;
  comp : TFHIRComposer;
  s : TStringStream;
begin
  if PageControl1.ActivePageIndex = 0 then
    sd := lbResources.items.objects[lbResources.ItemIndex] as TFhirStructureDefinition
  else
    sd := lbProfiles.items.objects[lbProfiles.ItemIndex] as TFhirStructureDefinition;
  pu := TProfileUtilities.create(FValidator, nil);
  try
    res := pu.populateByProfile(sd);
    try
      if rbJson.Checked then
        comp := TFHIRJsonComposer.Create('en')
      else
        comp := TFHIRXmlComposer.Create('en');
      try
        s := TStringStream.Create;
        try
          comp.Compose(s, res, true);
          Npp.NewFile(s.DataString);
        finally
          s.Free;
        end;
      finally
        comp.Free;
      end;
    finally
      res.Free;
    end;
  finally
    pu.Free;
  end;
  ModalResult := mrOK;
end;

destructor TResourceNewForm.Destroy;
begin
  FValidator.Free;
  inherited;
end;

procedure TResourceNewForm.SetValidator(const Value: TFHIRValidator);
begin
  FValidator.Free;
  FValidator := Value;
end;

procedure TResourceNewForm.edtFilterChange(Sender: TObject);
begin
  loadLists;
end;

procedure TResourceNewForm.FormShow(Sender: TObject);
begin
  LoadLists;
end;

procedure TResourceNewForm.lbProfilesClick(Sender: TObject);
begin
  btnCreate.Enabled := lbProfiles.ItemIndex > -1;
end;

procedure TResourceNewForm.lbResourcesClick(Sender: TObject);
begin
  btnCreate.Enabled := lbResources.ItemIndex > -1;
end;

procedure TResourceNewForm.loadLists;
var
  sd : TFhirStructureDefinition;
  s : String;
begin
  lbResources.Clear;
  lbProfiles.Clear;
  s := edtFilter.Text;
  s := s.toLower;
  for sd in FValidator.Profiles.ProfilesByURL.Values do
    if (sd.kind = StructureDefinitionKindResource) and ((edtFilter.Text = '') or sd.name.ToLower.Contains(s)) then
      if sd.constrainedType = '' then
        lbResources.Items.AddObject(sd.name, sd)
      else
        lbProfiles.Items.AddObject(sd.name, sd)
end;

end.
