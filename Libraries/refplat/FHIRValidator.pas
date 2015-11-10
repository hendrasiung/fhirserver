Unit FHIRValidator;

{
  Copyright (c) 2001-2013, Health Intersections Pty Ltd (http://www.healthintersections.com.au)
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
  * Neither the name of HL7 nor the names of its contributors may be used to
  endorse or promote products derived from this software without specific
  prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
}

interface

Uses
  SysUtils, Classes, System.Character, RegExpr, ActiveX, ComObj,

  StringSupport, MathSupport,
  AdvObjects, AdvGenerics, AdvObjectLists, Advbuffers, AdvNameBuffers,
  AdvMemories, AdvFiles, AdvVclStreams, AdvZipReaders, AdvZipParts, AdvStringMatches,

  IdSoapXml, IdSoapMsXml, XmlBuilder, MsXmlParser, AltovaXMLLib_TLB, AdvXmlEntities, AdvJSON,

  FHIRBase, FHIRResources, FHIRTypes, FHIRParser, FHIRProfileUtilities, ProfileManager;

Type
  TWrapperElement = class(TAdvObject)
  private
    FOwned: TAdvObjectList;
    function own(obj: TWrapperElement): TWrapperElement;
  public
    Constructor Create; Override;
    Destructor Destroy; Override;
    function Link: TWrapperElement; overload;
    function getNamedChild(name: String): TWrapperElement; virtual; abstract;
    function getFirstChild(): TWrapperElement; virtual; abstract;
    function getNextSibling(): TWrapperElement; virtual; abstract;
    function getName(): String; virtual; abstract;
    function getResourceType(): String; virtual; abstract;
    function getNamedChildValue(name: String): String; virtual; abstract;
    procedure getNamedChildren(name: String; list: TAdvList<TWrapperElement>); virtual; abstract;
    function getAttribute(name: String): String; virtual; abstract;
    procedure getNamedChildrenWithWildcard(name: String; list: TAdvList<TWrapperElement>); virtual; abstract;
    function hasAttribute(name: String): boolean; virtual; abstract;
    function getNamespace(): String; virtual; abstract;
    function isXml(): boolean; virtual; abstract;
    function getText(): String; virtual; abstract;
    function hasNamespace(s: String): boolean; virtual; abstract;
    function hasProcessingInstruction(): boolean; virtual; abstract;
    function locStart: TSourceLocation; virtual; abstract;
    function locEnd: TSourceLocation; virtual; abstract;
  end;

  TNodeStack = class(TAdvObject)
  private
    xml: boolean;
    parent: TNodeStack;
    literalPath: String; // xpath format
    logicalPaths: TStringList; // dotted format, various entry points
    element: TWrapperElement;
    definition: TFHIRElementDefinition;
    type_: TFHIRElementDefinition;
    // extension : TFHIRElementDefinition;
    function push(element: TWrapperElement; count: integer; definition: TFHIRElementDefinition; type_: TFHIRElementDefinition): TNodeStack;
    function addToLiteralPath(path: Array of String): String;
  public
    Constructor Create(xml: boolean);
    Destructor Destroy; Override;
  end;

  TElementInfo = class(TAdvObject)
  private
    name: String;
    element: TWrapperElement;
    path: String;
    definition: TFHIRElementDefinition;
    count: integer;
    function locStart: TSourceLocation;
    function locEnd: TSourceLocation;
  public
    Constructor Create(name: String; element: TWrapperElement; path: String; count: integer);
  end;

  TChildIterator = class(TAdvObject)
  private
    parent: TWrapperElement;
    basePath: String;
    lastCount: integer;
    child: TWrapperElement;

  public
    constructor Create(path: String; element: TWrapperElement);
    function next: boolean;
    function name: String;
    function element: TWrapperElement;
    function path: String;
    function count: integer;
  end;

  TBestPracticeWarningLevel = (bpwlIgnore, bpwlHint, bpwlWarning, bpwlError);
  TCheckDisplayOption = (cdoIgnore, cdopCheck, cdoCheckCaseAndSpace, cdoCheckCase, cdoCheckSpace);

  TFHIRInstanceValidator = class(TAdvObject)
  private
    // configuration items
    FContext: TValidatorServiceProvider;
    Fowns: boolean;
    FCheckDisplay: TCheckDisplayOption;
    FBPWarnings: TBestPracticeWarningLevel;
    FSuppressLoincSnomedMessages: boolean;
    FRequireResourceId: boolean;
    FIsAnyExtensionsAllowed: boolean;
    FExtensionDomains: TStringList;

    function rule(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; path: String; thePass: boolean; msg: String): boolean; overload;
    function rule(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; path: String; thePass: boolean; msg: String): boolean; overload;
    function warning(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; path: String; thePass: boolean; msg: String): boolean;
    function hint(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; path: String; thePass: boolean; msg: String): boolean;
    procedure bpCheck(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; literalPath: String; test: boolean; message: String);

    // function isKnownType(code : String) : boolean;
    function genFullUrl(bundleBase, entryBase, ty, id: String): String;
    function empty(element: TWrapperElement): boolean;
    Function resolveInBundle(entries: TAdvList<TWrapperElement>; ref, fullUrl, type_, id: String): TWrapperElement;
    function getProfileForType(type_: String): TFHIRStructureDefinition;
    function sliceMatches(element: TWrapperElement; path: String; slice, ed: TFHIRElementDefinition; profile: TFHIRStructureDefinition): boolean;
    function resolveType(t: String): TFHIRElementDefinition;
    function getCriteriaForDiscriminator(path: String; ed: TFHIRElementDefinition; discriminator: String; profile: TFHIRStructureDefinition): TFHIRElementDefinition;
    function getValueForDiscriminator(element: TWrapperElement; discriminator: String; criteria: TFHIRElementDefinition): TFhirElement;
    function valueMatchesCriteria(value: TFhirElement; criteria: TFHIRElementDefinition): boolean;
    function resolve(ref: String; stack: TNodeStack): TWrapperElement;
    function tryParse(ref: String): String;
    function checkResourceType(ty: String): String;
    function getBaseType(profile: TFHIRStructureDefinition; pr: String): String;
    function getFromBundle(bundle: TWrapperElement; ref: String): TWrapperElement;
    function getContainedById(container: TWrapperElement; id: String): TWrapperElement;
    function resolveProfile(profile: TFHIRStructureDefinition; pr: String): TFHIRStructureDefinition;
    function checkExtensionContext(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; definition: TFHIRStructureDefinition; stack: TNodeStack;
      extensionParent: String): boolean;
    // function getElementByPath(definition : TFHIRStructureDefinition; path : String) : TFHIRElementDefinition;
    function findElement(profile: TFHIRStructureDefinition; name: String): TFHIRElementDefinition;
    // function getDefinitionByTailNameChoice(children : TFHIRElementDefinitionList; name : String) : TFHIRElementDefinition;
    function resolveBindingReference(reference: TFHIRType): TFHIRValueSet;
    function getExtensionByUrl(extensions: TAdvList<TWrapperElement>; url: String): TWrapperElement;

    procedure checkQuantityValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRQuantity);
    procedure checkAddressValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRAddress);
    procedure checkContactPointValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRContactPoint);
    procedure checkAttachmentValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRAttachment);
    procedure checkIdentifierValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRIdentifier);
    procedure checkCodingValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRCoding);
    procedure checkHumanNameValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRHumanName);
    procedure checkCodeableConceptValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRCodeableConcept);
    procedure checkTimingValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRTiming);
    procedure checkPeriodValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRPeriod);
    procedure checkRangeValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRRange);
    procedure checkRatioValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRRatio);
    procedure checkSampledDataValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRSampledData);

    procedure checkFixedValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFhirElement; propName: String);

    function checkCode(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; path: String; code, System, display: String): boolean;
    procedure checkQuantity(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; context: TFHIRElementDefinition; b: boolean);
    procedure checkPrimitiveBinding(errors: TFhirOperationOutcomeIssueList; path: String; ty: String; context: TFHIRElementDefinition; element: TWrapperElement);
    procedure checkPrimitive(errors: TFhirOperationOutcomeIssueList; path, ty: String; context: TFHIRElementDefinition; e: TWrapperElement);
    procedure checkIdentifier(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; context: TFHIRElementDefinition);
    procedure checkCoding(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; profile: TFHIRStructureDefinition; context: TFHIRElementDefinition; inCodeableConcept: boolean);
    procedure checkCodeableConcept(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; profile: TFHIRStructureDefinition; context: TFHIRElementDefinition);
    procedure checkReference(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; profile: TFHIRStructureDefinition; container: TFHIRElementDefinition; parentType: String; stack: TNodeStack);
    function checkExtension(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; def: TFHIRElementDefinition; profile: TFHIRStructureDefinition; stack: TNodeStack): TFHIRStructureDefinition;
    procedure validateContains(errors: TFhirOperationOutcomeIssueList; path: String; child: TFHIRElementDefinition; context: TFHIRElementDefinition; element: TWrapperElement; stack: TNodeStack; needsId: boolean);
    function allowUnknownExtension(url: String): boolean;

    procedure validateSections(errors: TFhirOperationOutcomeIssueList; entries: TAdvList<TWrapperElement>; focus: TWrapperElement; stack: TNodeStack; fullUrl, id: String);
    procedure validateBundleReference(errors: TFhirOperationOutcomeIssueList; entries: TAdvList<TWrapperElement>; ref: TWrapperElement; name: String; stack: TNodeStack; fullUrl, type_, id: String);
    procedure validateDocument(errors: TFhirOperationOutcomeIssueList; entries: TAdvList<TWrapperElement>; composition: TWrapperElement; stack: TNodeStack; fullUrl, id: String);
    procedure validateElement(errors: TFhirOperationOutcomeIssueList; profile: TFHIRStructureDefinition; definition: TFHIRElementDefinition; cprofile: TFHIRStructureDefinition; context: TFHIRElementDefinition; element: TWrapperElement; actualType: String; stack: TNodeStack; inCodeableConcept: boolean);
    procedure validateMessage(errors: TFhirOperationOutcomeIssueList; bundle: TWrapperElement);
    procedure validateBundle(errors: TFhirOperationOutcomeIssueList; bundle: TWrapperElement; stack: TNodeStack);
    procedure validateObservation(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; stack: TNodeStack);
    procedure checkDeclaredProfiles(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; stack: TNodeStack);
    procedure start(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; profile: TFHIRStructureDefinition; stack: TNodeStack);
    procedure validateResource(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; profile: TFHIRStructureDefinition; needsId: boolean; stack: TNodeStack);
  public
    Constructor Create(context: TValidatorServiceProvider; owns: boolean);
    Destructor Destroy; Override;
    Property CheckDisplay: TCheckDisplayOption read FCheckDisplay write FCheckDisplay;
    Property BPWarnings: TBestPracticeWarningLevel read FBPWarnings write FBPWarnings;
    Property SuppressLoincSnomedMessages: boolean read FSuppressLoincSnomedMessages write FSuppressLoincSnomedMessages;
    Property RequireResourceId: boolean read FRequireResourceId write FRequireResourceId;
    Property IsAnyExtensionsAllowed: boolean read FIsAnyExtensionsAllowed write FIsAnyExtensionsAllowed;

    procedure validate(errors: TFhirOperationOutcomeIssueList; element: TIdSoapXmlElement); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; obj: TJsonObject); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; element: TIdSoapXmlElement; profile: String); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; element: TIdSoapXmlElement; profile: TFHIRStructureDefinition); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; profile: TFHIRStructureDefinition); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; obj: TJsonObject; profile: TFHIRStructureDefinition); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; obj: TJsonObject; profile: String); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; document: TIdSoapXmlDom); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; document: TIdSoapXmlDom; profile: String); overload;
    procedure validate(errors: TFhirOperationOutcomeIssueList; document: TIdSoapXmlDom; profile: TFHIRStructureDefinition); overload;

  end;

  TFHIRValidatorContext = class (TAdvObject)
  private
    FxmlApp: AltovaXMLLib_TLB.Application;
  end;

  TFHIRBaseValidator = class (TValidatorServiceProvider)
  private
    FValidator : TFHIRInstanceValidator;
    FSchematronSource : String;
    FSources : TAdvNameBufferList;
    FCache : IXMLDOMSchemaCollection;
    FProfiles : TProfileManager;

    procedure Load(feed: TFHIRBundle);
    function LoadDoc(name : String; isFree : boolean = false) : IXMLDomDocument2;
    procedure processSchematron(op : TFhirOperationOutcome; source : String);
    procedure executeSchematron(context : TFHIRValidatorContext; op : TFhirOperationOutcome; source, name : String);
    procedure validateInstance(op : TFHIROperationOutcome; elem : TIdSoapXmlElement; specifiedprofile : TFHirStructureDefinition); overload;
    procedure SetProfiles(const Value: TProfileManager);

  protected
    procedure SeeResource(r : TFhirResource); virtual;
  public
    Constructor Create; Override;
    Destructor Destroy; Override;

    Function Link : TFHIRBaseValidator; overload;

    Property Validator : TFHIRInstanceValidator read FValidator;
    Property Profiles : TProfileManager read FProfiles write SetProfiles;

    procedure LoadFromDefinitions(filename : string);
    Property SchematronSource : String read FSchematronSource write FSchematronSource;

    function AcquireContext : TFHIRValidatorContext;
    procedure YieldContext(context : TFHIRValidatorContext);

    Function validateInstance(context : TFHIRValidatorContext; elem : TIdSoapXmlElement; opDesc : String; profile : TFHirStructureDefinition) : TFHIROperationOutcome; overload;
    Function validateInstance(context : TFHIRValidatorContext; resource : TFhirResource; opDesc : String; profile : TFHirStructureDefinition) : TFHIROperationOutcome; overload;
    Function validateInstance(context : TFHIRValidatorContext; source : TAdvBuffer; format : TFHIRFormat; opDesc : String; profile : TFHirStructureDefinition) : TFHIROperationOutcome; overload;

    function fetchResource(t : TFhirResourceType; url : String) : TFhirResource; override;
  end;


implementation

uses
  FHIRParserBase, FHIRUtilities;

function nameMatches(name, tail: String): boolean;
begin
  if (tail.endsWith('[x]')) then
    result := name.startsWith(tail.substring(0, tail.length - 3))
  else
    result := (name = tail);
end;

{ TElementInfo }

Constructor TElementInfo.Create(name: String; element: TWrapperElement; path: String; count: integer);
begin
  inherited Create;
  self.name := name;
  self.element := element;
  self.path := path;
  self.count := count;
end;

function TElementInfo.locStart: TSourceLocation;
begin
  result := element.locStart;
end;

function TElementInfo.locEnd: TSourceLocation;
begin
  result := element.locEnd;
end;

function codeInExpansion(cnt: TFhirValueSetExpansionContains; System, code: String): boolean; overload;
var
  c: TFhirValueSetExpansionContains;
begin
  for c in cnt.containsList do
  begin
    if (code = c.code) and ((System = '') or (System = c.System)) then
    begin
      result := true;
      exit;
    end;
    if (codeInExpansion(c, System, code)) then
    begin
      result := true;
      exit;
    end;
  end;
  result := false;
end;

function codeInExpansion(vs: TFHIRValueSet; System, code: String): boolean; overload;
var
  c: TFhirValueSetExpansionContains;
begin
  for c in vs.Expansion.containsList do
  begin
    if (code = c.code) and ((System = '') or (System = c.System)) then
    begin
      result := true;
      exit;
    end;
    if (codeInExpansion(c, System, code)) then
    begin
      result := true;
      exit;
    end;
  end;
  result := false;
end;

{ TWrapperElement }

Constructor TWrapperElement.Create;
begin
  inherited Create;
  FOwned := TAdvObjectList.Create;
end;

Destructor TWrapperElement.Destroy;
begin
  FOwned.Free;
  inherited Destroy;
end;

function TWrapperElement.Link: TWrapperElement;
begin
  result := TWrapperElement(inherited Link);
end;

function TWrapperElement.own(obj: TWrapperElement): TWrapperElement;
begin
  FOwned.Add(obj);
  result := obj;
end;

type
  TDOMWrapperElement = class(TWrapperElement)
  private
    FElement: TIdSoapXmlElement;
  public
    Constructor Create(element: TIdSoapXmlElement);
    function getNamedChild(name: String): TWrapperElement; override;
    function getFirstChild(): TWrapperElement; override;
    function getNextSibling(): TWrapperElement; override;
    function getName(): String; override;
    function getResourceType(): String; override;
    function getNamedChildValue(name: String): String; override;
    procedure getNamedChildren(name: String; list: TAdvList<TWrapperElement>); override;
    function getAttribute(name: String): String; override;
    procedure getNamedChildrenWithWildcard(name: String; list: TAdvList<TWrapperElement>); override;
    function hasAttribute(name: String): boolean; override;
    function getNamespace(): String; override;
    function isXml(): boolean; override;
    function getText(): String; override;
    function hasNamespace(s: String): boolean; override;
    function hasProcessingInstruction(): boolean; override;
    function locStart: TSourceLocation; override;
    function locEnd: TSourceLocation; override;
  end;

  { TDOMWrapperElement }

constructor TDOMWrapperElement.Create(element: TIdSoapXmlElement);
begin
  inherited Create;
  FElement := element;
end;

function TDOMWrapperElement.getAttribute(name: String): String;
begin
  result := FElement.getAttribute('', name);
end;

function TDOMWrapperElement.getFirstChild: TWrapperElement;
var
  res: TIdSoapXmlElement;
begin
  res := FElement.FirstChild;
  if res = nil then
    result := nil
  else
    result := own(TDOMWrapperElement.Create(res));
end;

function TDOMWrapperElement.getName: String;
begin
  result := FElement.name;
end;

function TDOMWrapperElement.getNamedChild(name: String): TWrapperElement;
var
  res: TIdSoapXmlElement;
begin
  res := FElement.FirstChild;
  while (res <> nil) and (res.name <> name) and (res.name <> name) do
    res := res.NextSibling;
  if res = nil then
    result := nil
  else
    result := own(TDOMWrapperElement.Create(res));
end;

procedure TDOMWrapperElement.getNamedChildren(name: String; list: TAdvList<TWrapperElement>);
var
  res: TIdSoapXmlElement;
begin
  res := FElement.FirstChild;
  while (res <> nil) do
  begin
    if (res.name = name) OR (res.name = name) then
      list.Add(own(TDOMWrapperElement.Create(res)));
    res := res.NextSibling;
  end;
end;

procedure TDOMWrapperElement.getNamedChildrenWithWildcard(name: String; list: TAdvList<TWrapperElement>);
var
  res: TIdSoapXmlElement;
  n: String;
begin
  res := FElement.FirstChild;
  while (res <> nil) do
  begin
    n := res.name; // OR res.tagName
    if (n = name) or ((name.endsWith('[x]') and (n.startsWith(name.substring(0, name.length - 3))))) then
      list.Add(own(TDOMWrapperElement.Create(res)));
    res := res.NextSibling;
  end;
end;

function TDOMWrapperElement.getNamedChildValue(name: String): String;
var
  res: TIdSoapXmlElement;
begin
  res := FElement.FirstChild;
  while (res <> nil) and (res.name <> name) and (res.name <> name) do
    res := res.NextSibling;
  if res = nil then
    result := ''
  else
    result := res.getAttribute('', 'value');
end;

function TDOMWrapperElement.getNamespace: String;
begin
  result := FElement.namespace;
end;

function TDOMWrapperElement.getNextSibling: TWrapperElement;
var
  res: TIdSoapXmlElement;
begin
  res := FElement.NextSibling;
  if res = nil then
    result := nil
  else
    result := own(TDOMWrapperElement.Create(res));
end;

function TDOMWrapperElement.getResourceType: String;
begin
  result := FElement.name;
end;

function TDOMWrapperElement.getText: String;
begin
  result := FElement.TextContentA;
end;

function TDOMWrapperElement.hasAttribute(name: String): boolean;
begin
  result := FElement.getAttribute('', name) <> '''';
end;

function TDOMWrapperElement.hasNamespace(s: String): boolean;
var
  i: integer;
  n, ns, t: String;
begin
  result := false;
  for i := 0 to FElement.AttributeCount - 1 do
  begin
    FElement.getAttributeName(i, ns, n);
    t := FElement.getAttribute(ns, n);
    if ((n = 'xmlns') or n.startsWith('xmlns:')) and (t = s) then
      result := true;
  end;
end;

function TDOMWrapperElement.hasProcessingInstruction: boolean;
// var
// node : IXMLDOMNode;
begin
  result := false;
  // node := FElement.FirstChild;
  // while (node <> nil) do
  // begin
  // if (node.NodeType = NODE_PROCESSING_INSTRUCTION) then
  // result := true;
  // node := node.NextSibling;
  // end;
end;

function TDOMWrapperElement.isXml: boolean;
begin
  result := true;
end;

function TDOMWrapperElement.locStart: TSourceLocation;
begin
  result.line := -1;
  result.col := -1;
end;

function TDOMWrapperElement.locEnd: TSourceLocation;
begin
  result.line := -1;
  result.col := -1;
end;

type
  TSAXWrapperElement = class(TWrapperElement)
  private
    FParent : TSAXWrapperElement; // not linked
    FNamespace : String;
    FName : String;
    FText : String;
    FAttributes : TAdvStringMatch;
    FChildren : TAdvList<TSAXWrapperElement>;
    FLocationStart : TSourceLocation;
    FLocationEnd : TSourceLocation;
  public
    Constructor Create; overload; override;
    Constructor Create(parent : TSAXWrapperElement; namespace, name : String); overload;
    Destructor Destroy; override;
    function link : TSAXWrapperElement; overload;
    function getNamedChild(name: String): TWrapperElement; override;
    function getFirstChild(): TWrapperElement; override;
    function getNextSibling(): TWrapperElement; override;
    function getName(): String; override;
    function getResourceType(): String; override;
    function getNamedChildValue(name: String): String; override;
    procedure getNamedChildren(name: String; list: TAdvList<TWrapperElement>); override;
    function getAttribute(name: String): String; override;
    procedure getNamedChildrenWithWildcard(name: String; list: TAdvList<TWrapperElement>); override;
    function hasAttribute(name: String): boolean; override;
    function getNamespace(): String; override;
    function isXml(): boolean; override;
    function getText(): String; override;
    function hasNamespace(s: String): boolean; override;
    function hasProcessingInstruction(): boolean; override;
    function locStart: TSourceLocation; override;
    function locEnd: TSourceLocation; override;
  end;

  TFHIRSaxParser = class (TMsXmlSaxHandler)
  private
    FStack : TAdvList<TSAXWrapperElement>;
    FRoot : TSAXWrapperElement;
    FLastStart : TSourceLocation;
  public
    constructor create;
    destructor destroy; override;
    procedure startElement(sourceLocation : TSourceLocation; uri, localname : string; attrs : IVBSAXAttributes); override;
    procedure endElement(sourceLocation : TSourceLocation); overload; override;
    procedure text(chars : String; sourceLocation : TSourceLocation); override;
  end;

  TJsonWrapperElement = class(TWrapperElement)
  private
    path: String;
    element: TJsonNode;
    _element: TJsonNode;
    name: String;
    resourceType: String;
    parent: TJsonWrapperElement; // not linked
    index: integer;
    children: TAdvList<TJsonWrapperElement>;
    procedure processChild(name: String; e: TJsonNode);
    procedure createChildren;
  public
    Constructor Create(element: TJsonObject); overload;
    Constructor Create(path, name: String; element, _element: TJsonNode; parent: TJsonWrapperElement; index: integer); overload;
    function getNamedChild(name: String): TWrapperElement; override;
    function getFirstChild(): TWrapperElement; override;
    function getNextSibling(): TWrapperElement; override;
    function getName(): String; override;
    function getResourceType(): String; override;
    function getNamedChildValue(name: String): String; override;
    procedure getNamedChildren(name: String; list: TAdvList<TWrapperElement>); override;
    function getAttribute(name: String): String; override;
    procedure getNamedChildrenWithWildcard(name: String; list: TAdvList<TWrapperElement>); override;
    function hasAttribute(name: String): boolean; override;
    function getNamespace(): String; override;
    function isXml(): boolean; override;
    function getText(): String; override;
    function hasNamespace(s: String): boolean; override;
    function hasProcessingInstruction(): boolean; override;
    function locStart: TSourceLocation; override;
    function locEnd: TSourceLocation; override;
  end;



{ TSAXWrapperElement }

constructor TSAXWrapperElement.Create(parent : TSAXWrapperElement; namespace, name: String);
begin
  Create;
  FNamespace := namespace;
  FName := name;
  FParent := parent;
end;

constructor TSAXWrapperElement.Create;
begin
  inherited;
  FAttributes := TAdvStringMatch.create;
  FChildren := TAdvList<TSAXWrapperElement>.create;
end;

destructor TSAXWrapperElement.Destroy;
begin
  FAttributes.Free;
  FChildren.Free;
  inherited;
end;

function TSAXWrapperElement.getAttribute(name: String): String;
begin
  result := FAttributes[name];
end;

function TSAXWrapperElement.getFirstChild: TWrapperElement;
begin
  if FChildren.Count = 0 then
    result := nil
  else
    result := FChildren[0];
end;

function TSAXWrapperElement.getName: String;
begin
  result := FName;
end;

function TSAXWrapperElement.getNamedChild(name: String): TWrapperElement;
var
  child : TSAXWrapperElement;
begin
  result := nil;
  for child in FChildren do
    if child.FName = name then
    begin
      result := child;
      exit;
    end;
end;

procedure TSAXWrapperElement.getNamedChildren(name: String; list: TAdvList<TWrapperElement>);
var
  child : TSAXWrapperElement;
begin
  for child in FChildren do
    if child.FName = name then
      list.Add(child.link)
end;

procedure TSAXWrapperElement.getNamedChildrenWithWildcard(name: String; list: TAdvList<TWrapperElement>);
var
  child : TSAXWrapperElement;
  n : String;
begin
  for child in FChildren do
  begin
    n := child.FName;
    if (n = name) or ((name.endsWith('[x]') and (n.startsWith(name.substring(0, name.length - 3))))) then
      list.Add(child.link)
  end;
end;

function TSAXWrapperElement.getNamedChildValue(name: String): String;
var
  child : TWrapperElement;
begin
  child := getNamedChild(name);
  if (child <> nil) then
    result := child.getAttribute('value')
  else
    result := '';
end;

function TSAXWrapperElement.getNamespace: String;
begin
  result := FNamespace;
end;

function TSAXWrapperElement.getNextSibling: TWrapperElement;
var
  index : Integer;
begin
  result := nil;
  if FParent <> nil then
  begin
    index := FParent.FChildren.IndexOf(self);
    if (index >= -1) and (index < FParent.FChildren.Count - 1) then
      result := FParent.FChildren[index + 1];
  end;
end;

function TSAXWrapperElement.getResourceType: String;
begin
  result := FName;
end;

function TSAXWrapperElement.getText: String;
begin
  result := FText;
end;

function TSAXWrapperElement.hasAttribute(name: String): boolean;
begin
  result := FAttributes.ExistsByKey(name);
end;

function TSAXWrapperElement.hasNamespace(s: String): boolean;
var
  i: integer;
  n, ns, t: String;
begin
  result := false;
  for i := 0 to FAttributes.Count - 1 do
  begin
    n := FAttributes.Keys[i];
    t := FAttributes.Values[i];
    if ((n = 'xmlns') or n.startsWith('xmlns:')) and (t = s) then
    begin
      result := true;
      exit;
    end;
  end;
end;

function TSAXWrapperElement.hasProcessingInstruction: boolean;
begin
  result := false;
end;

function TSAXWrapperElement.isXml: boolean;
begin
  result := true;
end;

function TSAXWrapperElement.link: TSAXWrapperElement;
begin
  result := TSAXWrapperElement(inherited Link);
end;

function TSAXWrapperElement.locEnd: TSourceLocation;
begin
  result := FLocationEnd;
end;

function TSAXWrapperElement.locStart: TSourceLocation;
begin
  result := FLocationStart;
end;

{ TJsonWrapperElement }

Constructor TJsonWrapperElement.Create(path, name: String; element, _element: TJsonNode; parent: TJsonWrapperElement; index: integer);
begin
  inherited Create;
  self.path := path + '/' + name;
  self.name := name;
  self.element := element;
  if (element is TJsonObject and TJsonObject(element).has('resourceType')) then
    self.resourceType := TJsonObject(element).str['resourceType'];
  self._element := _element;
  self.parent := parent;
  self.index := index;
  createChildren();
end;

Constructor TJsonWrapperElement.Create(element: TJsonObject);
begin
  inherited Create;
  self.name := '';
  self.resourceType := element.str['resourceType'];
  self.element := element;
  self.path := '';
  createChildren();
end;

procedure TJsonWrapperElement.createChildren;
var
  i: integer;
  obj: TJsonObject;
begin
  children := TAdvList<TJsonWrapperElement>.create;
  // we''re going to make this look like the XML
  if (element <> nil) then
  begin

    if (element is TJsonValue) or (element is TJsonBoolean) then
    begin
      // we may have an element_ too
      if (_element <> nil) and (_element is TJsonObject) then
      begin
        obj := TJsonObject(_element);
        for i := 0 to obj.properties.count - 1 do
          processChild(obj.properties.Keys[i], obj.properties[obj.properties.Keys[i]]);
      end;
    end
    else if (element is TJsonObject) then
    begin
      obj := TJsonObject(element);
      for i := 0 to obj.properties.count - 1 do
        if obj.properties.Keys[i] <> 'resourceType' then
          processChild(obj.properties.Keys[i], obj.properties[obj.properties.Keys[i]]);
    end
    else if (element is TJsonNull) then
    begin
      // nothing to do
    end
    else
      raise Exception.Create('unexpected condition: ' + element.ClassName);
  end;
end;

procedure TJsonWrapperElement.processChild(name: String; e: TJsonNode);
var
  _e: TJsonNode;
  arr, _arr: TJsonArray;
  a, _a: TJsonNode;
  max, i: integer;
begin
  _e := nil;
  if (name.startsWith('_')) then
  begin
    name := name.substring(1);
    if TJsonObject(element).has(name) then
      exit; // it will get processed anyway
    e := nil;
  end;

  if element is TJsonObject then
    _e := TJsonObject(element).obj['_' + name];

  if (((e is TJsonValue) or (e is TJsonBoolean)) or ((e = nil) and (_e <> nil) and not(_e is TJsonArray))) then
  begin
    children.Add(TJsonWrapperElement.Create(path, name, e, _e, self, children.count));
  end
  else if (e is TJsonArray) or ((e = nil) and (_e <> nil)) then
  begin
    arr := TJsonArray(e);
    _arr := TJsonArray(_e);
    if arr <> nil then
      max := arr.count
    else
      max := 0;
    if (_arr <> nil) and (_arr.count > max) then
      max := _arr.count;
    for i := 0 to max - 1 do
    begin
      a := nil;
      _a := nil;
      if not((arr = nil) or (arr.count < i)) then
        a := arr.Item[i];
      if not((_arr = nil) or (_arr.count < i)) then
        a := _arr.Item[i];
      children.Add(TJsonWrapperElement.Create(path, name, a, _a, self, children.count));
    end
  end
  else if (e is TJsonObject) then
  begin
    children.Add(TJsonWrapperElement.Create(path, name, e, nil, self, children.count));
  end
  else
    raise Exception.Create('not done yet (1): ' + e.ClassName);
end;

function TJsonWrapperElement.getNamedChild(name: String): TWrapperElement;
var
  j: TJsonWrapperElement;
begin
  result := nil;
  for j in children do
    if (j.name = name) then
      result := j;
end;

function TJsonWrapperElement.getFirstChild(): TWrapperElement;
begin
  if (children.count = 0) then
    result := nil
  else
    result := children[0];
end;

function TJsonWrapperElement.getNextSibling(): TWrapperElement;
begin
  if (parent = nil) then
    result := nil
  else if (index >= parent.children.count - 1) then
    result := nil
  else
    result := parent.children[index+1];
end;

function TJsonWrapperElement.getName(): String;
begin
  result := name;
end;

function TJsonWrapperElement.getNamedChildValue(name: String): String;
var
  c: TWrapperElement;
begin
  c := getNamedChild(name);
  if (c = nil) then
    result := ''
  else
    result := c.getAttribute('value');
end;

procedure TJsonWrapperElement.getNamedChildren(name: String; list: TAdvList<TWrapperElement>);
var
  j: TJsonWrapperElement;
begin
  for j in children do
    if (j.name = name) then
      list.Add(j.Link);
end;

function TJsonWrapperElement.getAttribute(name: String): String;
var
  c: TWrapperElement;
begin
  if (name = 'value') then
  begin
    if (element = nil) then
      result := ''
    else if (element is TJsonValue) then
      result := TJsonValue(element).value
    else
      result := ''
  end
  else if (name = 'xml:id') then
  begin
    c := getNamedChild('id');
    if (c = nil) then
      result := ''
    else
      result := c.getAttribute('value');
  end
  else if (name = 'url') then
  begin
    c := getNamedChild('url');
    if (c = nil) then
      result := ''
    else
      result := c.getAttribute('value');
  end
  else
    raise Exception.Create('not done yet (2): ' + name);
end;

procedure TJsonWrapperElement.getNamedChildrenWithWildcard(name: String; list: TAdvList<TWrapperElement>);
begin
  raise Exception.Create('not done yet');
end;

function TJsonWrapperElement.hasAttribute(name: String): boolean;
begin
  if (name = 'value') then
  begin
    if (element = nil) then
      result := false
    else if (element is TJsonValue) then
      result := true
    else
      result := false;
  end
  else if (name = 'id') then
  begin
    result := getNamedChild('id') <> nil;
  end
  else
    raise Exception.Create('not done yet (3): ' + name);
end;

function TJsonWrapperElement.getNamespace(): String;
begin
  raise Exception.Create('not done yet');
end;

function TJsonWrapperElement.isXml(): boolean;
begin
  result := false;
end;

function TJsonWrapperElement.getText(): String;
begin
  raise Exception.Create('not done yet');
end;

function TJsonWrapperElement.hasNamespace(s: String): boolean;
begin
  raise Exception.Create('not done');
end;

function TJsonWrapperElement.hasProcessingInstruction(): boolean;
begin
  result := false;
end;

function TJsonWrapperElement.getResourceType(): String;
begin
  result := resourceType;
end;

function TJsonWrapperElement.locStart: TSourceLocation;
begin
  if _element = nil then
    result := element.LocationStart
  else if element = nil then
    result := _element.LocationStart
  else
    result := minLoc(element.LocationStart, _element.LocationStart);
end;

function TJsonWrapperElement.locEnd: TSourceLocation;
begin
  if _element = nil then
    result := element.LocationEnd
  else if element = nil then
    result := _element.LocationEnd
  else
    result := maxLoc(element.LocationEnd, _element.LocationEnd);
end;

{ TNodeStack }

constructor TNodeStack.Create(xml: boolean);
begin
  inherited Create;
  self.xml := xml;
  logicalPaths := TStringList.Create;
end;

destructor TNodeStack.Destroy;
begin
  logicalPaths.Free;
  inherited;
end;

function tail(path: String): String;
begin
  result := path.substring(path.lastIndexOf('.') + 1);
end;

function TNodeStack.push(element: TWrapperElement; count: integer; definition: TFHIRElementDefinition; type_: TFHIRElementDefinition): TNodeStack;
var
  t, lp: String;
begin
  result := TNodeStack.Create(element.isXml());
  result.parent := self;
  result.element := element;
  result.definition := definition;
  if (element.isXml()) then
  begin
    if element.getNamespace() = XHTML_NS then
      result.literalPath := literalPath + '/h:' + element.getName()
    else
      result.literalPath := literalPath + '/f:' + element.getName();
    if (count > -1) then
      result.literalPath := result.literalPath + '[' + integer.toString(count) + ']';
  end
  else
  begin
    if (element.getName() = '') then
      result.literalPath := ''
    else
      result.literalPath := literalPath + '/' + element.getName();
    if (count > -1) then
      result.literalPath := result.literalPath + '/' + inttostr(count);
  end;
  result.logicalPaths := TStringList.Create;
  if (type_ <> nil) then
  begin
    // type will be bull if we on a stitching point of a contained resource, or if....
    result.type_ := type_;
    t := tail(definition.path);
    for lp in logicalPaths do
    begin
      result.logicalPaths.Add(lp + '.' + t);
      if (t.endsWith('[x]')) then
        result.logicalPaths.Add(lp + '.' + t.substring(0, t.length - 3) + type_.path);
    end;
    result.logicalPaths.Add(type_.path);
  end
  else if (definition <> nil) then
  begin
    for lp in logicalPaths do
      result.logicalPaths.Add(lp + '.' + element.getName());
  end
  else
    result.logicalPaths.AddStrings(logicalPaths);
end;

function TNodeStack.addToLiteralPath(path: Array of String): String;
var
  b: TStringBuilder;
  p: String;
begin
  b := TStringBuilder.Create;
  try
    b.append(literalPath);
    if (xml) then
    begin
      for p in path do
      begin
        if (p.startsWith(':')) then
        begin
          b.append('[');
          b.append(p.substring(1));
          b.append(']');
        end
        else
        begin
          b.append('/f:');
          b.append(p);
        end
      end
    end
    else
    begin
      for p in path do
      begin
        b.append('/');
        if p.startsWith(':') then
        begin
          b.append(p.substring(1));
        end
        else
        begin
          b.append(p);
        end
      end
    end;
    result := b.toString();
  finally
    b.Free;
  end;
end;

{ TFHIRInstanceValidator }

constructor TFHIRInstanceValidator.Create(context: TValidatorServiceProvider; owns: boolean);
begin
  inherited Create;
  FContext := context;
  Fowns := owns;
end;

destructor TFHIRInstanceValidator.Destroy;
begin
  if Fowns then
    FContext.Free;
  inherited;
end;

function TFHIRInstanceValidator.empty(element: TWrapperElement): boolean;
var
  child: TWrapperElement;
begin
  if (element.hasAttribute('value')) then
    result := false
  else if (element.hasAttribute('id')) then
    result := false
  else
  begin
    child := element.getFirstChild();
    while (child <> nil) do
    begin
      if (not child.isXml()) or (FHIR_NS = child.getNamespace()) then
      begin
        result := false;
        exit;
      end;
      child := child.getNextSibling();
    end;
    result := true;
  end;
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; element: TIdSoapXmlElement);
begin
  validate(errors, element, nil);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; obj: TJsonObject);
begin
  validate(errors, obj, nil);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; element: TIdSoapXmlElement; profile: String);
var
  p: TFHIRStructureDefinition;
begin
  p := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, profile));
  if (p = nil) then
    raise Exception.Create('StructureDefinition "' + profile + '" not found');
  validate(errors, element, p);
end;

function makeSAXWrapperElement(buffer : TAdvBuffer) : TWrapperElement;
var
  ms : TMsXmlParser;
  fs : TFHIRSaxParser;
begin
  ms := TMsXmlParser.Create;
  try
    fs := TFHIRSaxParser.create;
    result := fs.FRoot.Link;
    ms.Parse(buffer, fs);
  finally
    ms.Free;
  end;
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; element: TIdSoapXmlElement; profile: TFHIRStructureDefinition);
begin
  validateResource(errors, TDOMWrapperElement.create(element), profile, FRequireResourceId, nil);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; obj: TJsonObject; profile: TFHIRStructureDefinition);
begin
  validateResource(errors, TJsonWrapperElement.Create(obj), profile, FRequireResourceId, nil);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; obj: TJsonObject; profile: String);
var
  p: TFHIRStructureDefinition;
begin
  p := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, profile));
  if (p = nil) then
    raise Exception.Create('StructureDefinition "' + profile + '" not found');
  validate(errors, obj, p);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; document: TIdSoapXmlDom);
begin
  validate(errors, document, nil);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; document: TIdSoapXmlDom; profile: String);
var
  p: TFHIRStructureDefinition;
begin
  p := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, profile));
  if (p = nil) then
    raise Exception.Create('StructureDefinition "' + profile + '" not found');
  validate(errors, document, p);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; document: TIdSoapXmlDom; profile: TFHIRStructureDefinition);
begin
  validateResource(errors, TDOMWrapperElement.create(document.Root), profile, FRequireResourceId, nil);
end;

procedure TFHIRInstanceValidator.validate(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; profile: TFHIRStructureDefinition);
begin
  validateResource(errors, element, profile, FRequireResourceId, nil);
end;

function getFirstEntry(bundle: TWrapperElement): TWrapperElement;
var
  list: TAdvList<TWrapperElement>;
  resource: TWrapperElement;
begin
  list := TAdvList<TWrapperElement>.Create;
  try
    bundle.getNamedChildren('entry', list);
    if (list.count = 0) then
      result := nil
    else
    begin
      resource := list[0].getNamedChild('resource');
      if (resource = nil) then
        result := nil
      else
        result := resource.getFirstChild();
    end;
  finally
    list.Free;
  end;
end;

{
  * The actual base entry point
}
procedure TFHIRInstanceValidator.validateResource(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; profile: TFHIRStructureDefinition; needsId: boolean;
  stack: TNodeStack);
var
  ok: boolean;
  resourceName: String;
  type_: String;
  first: TWrapperElement;
begin
  if (stack = nil) then
    stack := TNodeStack.Create(element.isXml());

  // getting going - either we got a profile, or not.
  ok := true;
  if (element.isXml()) then
    ok := rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), '/', element.getNamespace().equals(FHIR_NS),
      'Namespace mismatch - expected "' + FHIR_NS + '", found "' + element.getNamespace() + '"');
  if (ok) then
  begin
    resourceName := element.getResourceType();
    if (profile = nil) then
    begin
      profile := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, 'http://hl7.org/fhir/StructureDefinition/' + resourceName));
      ok := rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.addToLiteralPath(resourceName), profile <> nil,
        'No profile found for resource type "' + resourceName + '"');
    end
    else
    begin
      if profile.ConstrainedType <> '' then
        type_ := profile.ConstrainedType
      else
        type_ := profile.name;

      // special case: we have a bundle, and the profile is not for a bundle. We'll try the first entry instead
      if (type_ = resourceName) and (resourceName = 'Bundle') then
      begin
        first := getFirstEntry(element);
        if (first <> nil) and (first.getResourceType() = type_) then
        begin
          element := first;
          resourceName := element.getResourceType();
          needsId := false;
        end;
      end;

      ok := rule(errors, IssueTypeINVALID, nullLoc, nullLoc, stack.addToLiteralPath(resourceName), type_ = resourceName, 'Specified profile type was "' + profile.ConstrainedType +
        '", but resource type was "' + resourceName + '"');
    end;
  end;

  if (ok) then
  begin
    stack := stack.push(element, -1, profile.Snapshot.ElementList[0], profile.Snapshot.ElementList[0]);
    if (needsId) and ((element.getNamedChild('id') = nil)) then
      rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, false, 'Resource has no id');
    start(errors, element, profile, stack); // root is both definition and type
  end;
end;

// we assume that the following things are true:
// the instance at root is valid against the schema and schematron
// the instance validator had no issues against the base resource profile
// profile is valid, and matches the resource name
procedure TFHIRInstanceValidator.start(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; profile: TFHIRStructureDefinition; stack: TNodeStack);
begin
  if (rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), stack.literalPath, profile.Snapshot <> nil,
    'StructureDefinition has no snapshot - validation is against the snapshot, so it must be provided')) then
  begin
    validateElement(errors, profile, profile.Snapshot.ElementList[0], nil, nil, element, element.getName(), stack, false);
    checkDeclaredProfiles(errors, element, stack);

    // specific known special validations
    if (element.getResourceType() = 'Bundle') then
      validateBundle(errors, element, stack);
    if (element.getResourceType() = 'Observation') then
      validateObservation(errors, element, stack);
  end;
end;

procedure TFHIRInstanceValidator.checkDeclaredProfiles(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; stack: TNodeStack);
var
  meta: TWrapperElement;
  profiles: TAdvList<TWrapperElement>;
  i: integer;
  profile: TWrapperElement;
  ref, p: String;
  pr: TFHIRStructureDefinition;
begin
  meta := element.getNamedChild('meta');
  if (meta <> nil) then
  begin
    profiles := TAdvList<TWrapperElement>.Create();
    meta.getNamedChildren('profile', profiles);
    i := 0;
    for profile in profiles do
    begin
      ref := profile.getAttribute('value');
      p := stack.addToLiteralPath(['meta', 'profile', ':' + inttostr(i)]);
      if (rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), p, ref <> '', 'StructureDefinition reference invalid')) then
      begin
        pr := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, ref));
        if (warning(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), p, pr <> nil, 'StructureDefinition reference could not be resolved')) then
        begin
          if (rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), p, pr.Snapshot <> nil,
            'StructureDefinition has no snapshot - validation is against the snapshot, so it must be provided')) then
          begin
            validateElement(errors, pr, pr.Snapshot.ElementList[0], nil, nil, element, element.getName, stack, false);
          end;
        end;
        inc(i);
      end;
    end;
  end;
end;

procedure TFHIRInstanceValidator.validateBundle(errors: TFhirOperationOutcomeIssueList; bundle: TWrapperElement; stack: TNodeStack);
var
  entries: TAdvList<TWrapperElement>;
  type_, id: String;
  firstEntry: TWrapperElement;
  firstStack: TNodeStack;
  fullUrl: String;
  resource, res: TWrapperElement;
  localStack: TNodeStack;
begin
  entries := TAdvList<TWrapperElement>.Create();
  bundle.getNamedChildren('entry', entries);
  type_ := bundle.getNamedChildValue('type');
  if (entries.count = 0) then
  begin
    rule(errors, IssueTypeINVALID, stack.literalPath, (type_ <> 'document') and (type_ <> 'message'), 'Documents or Messages must contain at least one entry');
  end
  else
  begin
    firstEntry := entries[0];
    firstStack := stack.push(firstEntry, 0, nil, nil);
    fullUrl := firstEntry.getNamedChildValue('fullUrl');

    if (type_ = 'document') then
    begin
      res := firstEntry.getNamedChild('resource');
      localStack := firstStack.push(res, -1, nil, nil);
      resource := res.getFirstChild();
      id := resource.getNamedChildValue('id');
      if (rule(errors, IssueTypeINVALID, firstEntry.locStart(), firstEntry.locEnd(), stack.addToLiteralPath(['entry', ':0']), res <> nil, 'No resource on first entry')) then
      begin
        if (bundle.isXml()) then
          validateDocument(errors, entries, resource, localStack.push(resource, -1, nil, nil), fullUrl, id)
        else
          validateDocument(errors, entries, res, localStack, fullUrl, id);
      end;
    end;
    if (type_ = 'message') then
      validateMessage(errors, bundle);
  end;
end;

procedure TFHIRInstanceValidator.validateMessage(errors: TFhirOperationOutcomeIssueList; bundle: TWrapperElement);
begin
end;

procedure TFHIRInstanceValidator.validateDocument(errors: TFhirOperationOutcomeIssueList; entries: TAdvList<TWrapperElement>; composition: TWrapperElement; stack: TNodeStack;
  fullUrl, id: String);
begin
  // first entry must be a composition
  if (rule(errors, IssueTypeINVALID, composition.locStart(), composition.locEnd(), stack.literalPath, composition.getResourceType() = 'Composition',
    'The first entry in a document must be a composition')) then
  begin
    // the composition subject and section references must resolve in the bundle
    validateBundleReference(errors, entries, composition.getNamedChild('subject'), 'Composition Subject', stack.push(composition.getNamedChild('subject'), -1, nil, nil), fullUrl,
      'Composition', id);
    validateSections(errors, entries, composition, stack, fullUrl, id);
  end;
end;
// rule(errors, IssueTypeINVALID, bundle.locStart(), bundle.locEnd(), 'Bundle', !'urn:guid:' = base), 'The base "urn:guid:" is not valid (use urn:uuid:)');
// rule(errors, IssueTypeINVALID, entry.locStart(), entry.locEnd(), localStack.literalPath, !'urn:guid:' = ebase), 'The base "urn:guid:" is not valid');
// rule(errors, IssueTypeINVALID, entry.locStart(), entry.locEnd(), localStack.literalPath, !Utilities.noString(base) ) or ( !Utilities.noString(ebase), 'entry does not have a base');
// String firstBase := nil;
// firstBase := ebase = nil ? base : ebase;

procedure TFHIRInstanceValidator.validateSections(errors: TFhirOperationOutcomeIssueList; entries: TAdvList<TWrapperElement>; focus: TWrapperElement; stack: TNodeStack;
  fullUrl, id: String);
var
  sections: TAdvList<TWrapperElement>;
  section: TWrapperElement;
  i: integer;
  localStack: TNodeStack;
begin
  sections := TAdvList<TWrapperElement>.Create();
  focus.getNamedChildren('entry', sections);
  i := 0;
  for section in sections do
  begin
    localStack := stack.push(section, 1, nil, nil);
    validateBundleReference(errors, entries, section.getNamedChild('content'), 'Section Content', localStack, fullUrl, 'Composition', id);
    validateSections(errors, entries, section, localStack, fullUrl, id);
    inc(i);
  end;
end;

procedure TFHIRInstanceValidator.validateBundleReference(errors: TFhirOperationOutcomeIssueList; entries: TAdvList<TWrapperElement>; ref: TWrapperElement; name: String;
  stack: TNodeStack; fullUrl, type_, id: String);
var
  target: TWrapperElement;
begin
  if (ref <> nil) and (ref.getNamedChildValue('reference') <> '') then
  begin
    target := resolveInBundle(entries, ref.getNamedChildValue('reference'), fullUrl, type_, id);
    rule(errors, IssueTypeINVALID, target.locStart(), target.locEnd(), stack.addToLiteralPath(['reference']), target <> nil,
      'Unable to resolve the target of the reference in the bundle (' + name + ')');
  end;
end;

function isAbsoluteUrl(s: String): boolean;
begin
  result := false;
end;

Function TFHIRInstanceValidator.resolveInBundle(entries: TAdvList<TWrapperElement>; ref, fullUrl, type_, id: String): TWrapperElement;
var
  entry, res, resource: TWrapperElement;
  fu, u, t, i, et, eid: String;
  parts: TArray<String>;
begin
  result := nil;
  if (isAbsoluteUrl(ref)) then
  begin
    // if the reference is absolute, then you resolve by fullUrl. No other thinking is required.
    for entry in entries do
    begin
      fu := entry.getNamedChildValue('fullUrl');
      if (ref = fu) then
      begin
        result := entry;
        exit;
      end;
    end;
  end
  else
  begin
    // split into base, type, and id
    u := '';
    if (fullUrl <> '') and (fullUrl.endsWith(type_ + '/' + id)) then
      // fullUrl := complex
      u := fullUrl.substring((type_ + '/' + id).length) + ref;
    parts := ref.split(['\\/']);
    if (length(parts) >= 2) then
    begin
      t := parts[0];
      i := parts[1];
      for entry in entries do
      begin
        fu := entry.getNamedChildValue('fullUrl');
        if (u <> '') and (fullUrl = u) then
        begin
          result := entry;
          exit;
        end;
        if (u = '') then
        begin
          res := entry.getNamedChild('resource');
          resource := res.getFirstChild();
          et := resource.getResourceType();
          eid := resource.getNamedChildValue('id');
          if (t = et) and (i = eid) then
            result := entry;
        end;
      end;
    end;
  end;
end;

function TFHIRInstanceValidator.getProfileForType(type_: String): TFHIRStructureDefinition;
begin
  result := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, 'http://hl7.org/fhir/StructureDefinition/' + type_));
end;

procedure TFHIRInstanceValidator.validateObservation(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; stack: TNodeStack);
begin
  // all observations should have a subject, a performer, and a time
  bpCheck(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, element.getNamedChild('subject') <> nil, 'All observations should have a subject');
  bpCheck(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, element.getNamedChild('performer') <> nil, 'All observations should have a performer');
  bpCheck(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, (element.getNamedChild('effectiveDateTime') <> nil) or
    (element.getNamedChild('effectivePeriod') <> nil), 'All observations should have an effectiveDateTime or an effectivePeriod');
end;

procedure TFHIRInstanceValidator.bpCheck(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; literalPath: String; test: boolean; message: String);
begin
  case BPWarnings of
    bpwlHint:
      hint(errors, t, locStart, locEnd, literalPath, test, message);
    bpwlWarning:
      warning(errors, t, locStart, locEnd, literalPath, test, message);
    bpwlError:
      rule(errors, t, locStart, locEnd, literalPath, test, message);
    bpwlIgnore:
      ; // do nothing
  end;
end;

function isPrimitiveType(t: String): boolean;
begin
  result := SameText(t, 'boolean') or SameText(t, 'integer') or SameText(t, 'string') or SameText(t, 'decimal') or SameText(t, 'uri') or SameText(t, 'base64Binary') or
    SameText(t, 'instant') or SameText(t, 'date') or SameText(t, 'uuid') or SameText(t, 'id') or SameText(t, 'xhtml') or SameText(t, 'markdown') or SameText(t, 'dateTime') or
    SameText(t, 'time') or SameText(t, 'code') or SameText(t, 'oid') or SameText(t, 'id');
end;

function describeTypes(types: TFhirElementDefinitionTypeList): String;
var
  tc: TFhirElementDefinitionType;
begin
  result := '';
  for tc in types do
    CommaAdd(result, tc.code);
end;

function resolveNameReference(Snapshot: TFhirStructureDefinitionSnapshot; name: String): TFHIRElementDefinition;
var
  ed: TFHIRElementDefinition;
begin
  result := nil;
  for ed in Snapshot.ElementList do
    if (name = ed.name) then
    begin
      result := ed;
      exit;
    end;
end;

function findElement(profile: TFHIRStructureDefinition; name: String): TFHIRElementDefinition;
var
  c: TFHIRElementDefinition;
begin
  result := nil;
  for c in profile.Snapshot.ElementList do
  begin
    if (c.path = name) then
    begin
      result := c;
      exit;
    end;
  end;
end;

function TFHIRInstanceValidator.resolveType(t: String): TFHIRElementDefinition;
var
  url: String;
  sd: TFHIRStructureDefinition;
begin
  url := 'http://hl7.org/fhir/StructureDefinition/' + t;
  sd := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, url));
  if (sd = nil) or (sd.Snapshot = nil) then
    result := nil
  else
    result := sd.Snapshot.ElementList[0];
end;

function TFHIRInstanceValidator.rule(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; path: String; thePass: boolean; msg: String): boolean;
var
  vm: TFhirOperationOutcomeIssue;
begin
  if not thePass then
  begin
    vm := TFhirOperationOutcomeIssue.Create;
    errors.Add(vm);
    vm.severity := IssueSeverityError;
    vm.locationList.append.value := path;
    vm.code := t;
    vm.details := TFHIRCodeableConcept.Create;
    vm.details.text := msg;
  end;
  result := thePass;
end;

function TFHIRInstanceValidator.rule(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; path: String; thePass: boolean; msg: String): boolean;
var
  vm: TFhirOperationOutcomeIssue;
begin
  if not thePass then
  begin
    vm := TFhirOperationOutcomeIssue.Create;
    errors.Add(vm);
    vm.Tags['s-l'] := inttostr(locStart.line);
    vm.Tags['s-c'] := inttostr(locStart.col);
    vm.Tags['e-l'] := inttostr(locEnd.line);
    vm.Tags['e-c'] := inttostr(locEnd.col);
    vm.severity := IssueSeverityError;
    vm.locationList.append.value := path + ' (@ line ' + inttostr(locStart.line) + '/ col ' + inttostr(locStart.col) + ')';
    vm.code := t;
    vm.details := TFHIRCodeableConcept.Create;
    vm.details.text := msg;
  end;
  result := thePass;
end;

function isBundleEntry(path: String): boolean;
var
  parts: TArray<String>;
begin
  parts := path.split(['/']);
  if (path.startsWith('/f:')) then
    result := (length(parts) > 2) and (parts[length(parts) - 1].startsWith('f:resource')) and ((parts[length(parts) - 2] = 'f:entry')) or
      (parts[length(parts) - 2].startsWith('f:entry['))
  else
    result := (length(parts) > 2) and (parts[length(parts) - 1] = 'resource') and (((length(parts) > 2) and (parts[length(parts) - 3] = 'entry'))) or
      (parts[length(parts) - 2] = 'entry');
end;

procedure TFHIRInstanceValidator.validateElement(errors: TFhirOperationOutcomeIssueList; profile: TFHIRStructureDefinition; definition: TFHIRElementDefinition;
  cprofile: TFHIRStructureDefinition; context: TFHIRElementDefinition; element: TWrapperElement; actualType: String; stack: TNodeStack; inCodeableConcept: boolean);
var
  childDefinitions: TFHIRElementDefinitionList;
  children: TAdvList<TElementInfo>;
  iter: TChildIterator;
  slice, ed, td: TFHIRElementDefinition;
  process, match: boolean;
  ei: TElementInfo;
  count: integer;
  t, prefix: String;
  tc, trc: TFhirElementDefinitionType;
  p: TFHIRStructureDefinition;
  localStack: TNodeStack;
  thisIsCodeableConcept: boolean;
begin
  // irrespective of what element it is, it cannot be empty
  if (element.isXml()) then
  begin
    rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, FHIR_NS = element.getNamespace(),
      'Namespace mismatch - expected "' + FHIR_NS + '", found "' + element.getNamespace() + '"');
    rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, not element.hasNamespace('http://www.w3.org/2001/XMLSchema-instance'),
      'Schema Instance Namespace is not allowed in instances');
    rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, not element.hasProcessingInstruction(), 'No Processing Instructions in resources');
  end;
  rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.literalPath, not empty(element),
    'Elements must have some content (@value, extensions, or children elements)');

  // get the list of direct defined children, including slices
  childDefinitions := getChildMap(profile, definition.name, definition.path, definition.NameReference);

  // 1. List the children, and remember their exact path (convenience)
  children := TAdvList<TElementInfo>.Create();
  iter := TChildIterator.Create(stack.literalPath, element);
  while (iter.next()) do
    children.Add(TElementInfo.Create(iter.name(), iter.element(), iter.path(), iter.count()));

  // 2. assign children to a definition
  // for each definition, for each child, check whether it belongs in the slice
  slice := nil;
  for ed in childDefinitions do
  begin
    process := true;
    // where are we with slicing
    if (ed.Slicing <> nil) then
    begin
      if (slice <> nil) and (slice.path = ed.path) then
        raise Exception.Create('Slice encountered midway through path on ' + slice.path);
      slice := ed;
      process := false;
    end
    else if (slice <> nil) and (slice.path <> ed.path) then
      slice := nil;

    if (process) then
    begin
      for ei in children do
      begin
        match := false;
        if (slice = nil) then
        begin
          match := nameMatches(ei.name, tail(ed.path));
        end
        else
        begin
          if nameMatches(ei.name, tail(ed.path)) then
            match := sliceMatches(ei.element, ei.path, slice, ed, profile);
        end;
        if (match) then
        begin
          if (rule(errors, IssueTypeINVALID, ei.locStart(), ei.locEnd(), ei.path, ei.definition = nil, 'Element matches more than one slice')) then
            ei.definition := ed;
        end;
      end;
    end;
  end;

  for ei in children do
    if (ei.path.endsWith('.extension')) then
      rule(errors, IssueTypeINVALID, ei.locStart(), ei.locEnd(), ei.path, ei.definition <> nil, 'Element is unknown or does not match any slice (url:="' +
        ei.element.getAttribute('url') + '")')
    else
      rule(errors, IssueTypeINVALID, ei.locStart(), ei.locEnd(), ei.path, (ei.definition <> nil) or (not ei.element.isXml() and (ei.element.getName() = 'fhir_comments')),
        'Element is unknown or does not match any slice');

  // 3. report any definitions that have a cardinality problem
  for ed in childDefinitions do
  begin
    if (ed.representation = []) then
    begin // ignore xml attributes
      count := 0;
      for ei in children do
        if (ei.definition = ed) then
          inc(count);
      if (ed.Min <> '0') then
        rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), stack.literalPath, count >= StrToInt(ed.Min), 'Element "' + stack.literalPath + '.' + tail(ed.path) +
          '": minimum required = ' + ed.Min + ', but only found ' + inttostr(count));
      if (ed.max <> '*') then
        rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), stack.literalPath, count <= StrToInt(ed.max), 'Element ' + tail(ed.path) + ' @ ' + stack.literalPath
          + ': max allowed = ' + ed.max + ', but found ' + inttostr(count));

    end;
  end;
  // 4. check order if any slices are orderd. (todo)

  // 5. inspect each child for validity
  for ei in children do
  begin
    if (ei.definition <> nil) then
    begin
      t := '';
      td := nil;
      if (ei.definition.Type_List.count = 1) and (ei.definition.Type_List[0].code <> '*') and (ei.definition.Type_List[0].code <> 'Element') and
        (ei.definition.Type_List[0].code <> 'BackboneElement') then
        t := ei.definition.Type_List[0].code
      else if (ei.definition.Type_List.count = 1) and (ei.definition.Type_List[0].code = '*') then
      begin
        prefix := tail(ei.definition.path);
        assert(prefix.endsWith('[x]'));
        t := ei.name.substring(prefix.length - 3);
        if (isPrimitiveType(t)) then
          t := uncapitalize(t);
      end
      else if (ei.definition.Type_List.count > 1) then
      begin
        prefix := tail(ei.definition.path);
        prefix := prefix.substring(0, prefix.length - 3);
        for tc in ei.definition.Type_List do
          if ((prefix + capitalize(tc.code)) = ei.name) then
            t := tc.code;
        if (t = '') then
        begin
          trc := ei.definition.Type_List[0];
          if (trc.code = 'Reference') then
            t := 'Reference'
          else
          begin
            assert(prefix.endsWith('[x]'));
            rule(errors, IssueTypeSTRUCTURE, ei.locStart(), ei.locEnd(), stack.literalPath, false, 'The element ' + ei.name + ' is illegal. Valid types at this point are ' +
              describeTypes(ei.definition.Type_List));
          end;
        end;
      end
      else if (ei.definition.NameReference <> '') then
        td := resolveNameReference(profile.Snapshot, ei.definition.NameReference);

      if (t <> '') then
      begin
        if (t.startsWith('@')) then
        begin
          ei.definition := findElement(profile, t.substring(1));
          t := '';
        end;
      end;
      if (t = '') then
        localStack := stack.push(ei.element, ei.count, ei.definition, td)
      else
        localStack := stack.push(ei.element, ei.count, ei.definition, resolveType(t));
      if ei.path <> localStack.literalPath then
        raise Exception.Create('paths differ: ' + ei.path + ' vs ' + localStack.literalPath);

      assert(ei.path = localStack.literalPath);
      thisIsCodeableConcept := false;

      if (t <> '') then
      begin
        if (isPrimitiveType(t)) then
          checkPrimitive(errors, ei.path, t, ei.definition, ei.element)
        else
        begin
          if (t = 'Identifier') then
            checkIdentifier(errors, ei.path, ei.element, ei.definition)
          else if (t = 'Coding') then
            checkCoding(errors, ei.path, ei.element, profile, ei.definition, inCodeableConcept)
          else if (t = 'CodeableConcept') then
          begin
            checkCodeableConcept(errors, ei.path, ei.element, profile, ei.definition);
            thisIsCodeableConcept := true;
          end
          else if (t = 'Reference') then
            checkReference(errors, ei.path, ei.element, profile, ei.definition, actualType, localStack);

          if (t = 'Extension') then
            checkExtension(errors, ei.path, ei.element, ei.definition, profile, localStack)
          else if (t = 'Resource') then
            validateContains(errors, ei.path, ei.definition, definition, ei.element, localStack, not isBundleEntry(ei.path))
          else
          begin
            p := getProfileForType(t);
            if (rule(errors, IssueTypeSTRUCTURE, ei.locStart(), ei.locEnd(), ei.path, p <> nil, 'Unknown type ' + t)) then
              validateElement(errors, p, p.Snapshot.ElementList[0], profile, ei.definition, ei.element, t, localStack, thisIsCodeableConcept);
          end;
        end;
      end
      else
      begin
        if (rule(errors, IssueTypeSTRUCTURE, ei.locStart(), ei.locEnd(), stack.literalPath, ei.definition <> nil, 'Unrecognised Content ' + ei.name)) then
          validateElement(errors, profile, ei.definition, nil, nil, ei.element, t, localStack, false);
      end;
    end;
  end;
end;

{ *
  *
  * @param element - the candidate that might be in the slice
  * @param path - for reporting any errors. the XPath for the element
  * @param slice - the definition of how slicing is determined
  * @param ed - the slice for which to test membership
  * @return
  * @;
}
function TFHIRInstanceValidator.sliceMatches(element: TWrapperElement; path: String; slice, ed: TFHIRElementDefinition; profile: TFHIRStructureDefinition): boolean;
var
  s: TFhirString;
  discriminator: String;
  criteria: TFHIRElementDefinition;
  value: TFhirElement;
begin
  result := true;
  if (slice.Slicing.DiscriminatorList.count = 0) then
    result := false // cannot validate in this case
  else
    for s in slice.Slicing.DiscriminatorList do
    begin
      discriminator := s.value;
      criteria := getCriteriaForDiscriminator(path, ed, discriminator, profile);
      if (discriminator = 'url') and (criteria.path = 'Extension.url') then
      begin
        if (element.getAttribute('url') <> TFHIRUri(criteria.fixed).value) then
        begin
          result := false;
          exit;
        end;
      end
      else
      begin
        value := getValueForDiscriminator(element, discriminator, criteria);
        if (not valueMatchesCriteria(value, criteria)) then
        begin
          result := false;
          exit;
        end;
      end;
    end;
end;

function TFHIRInstanceValidator.valueMatchesCriteria(value: TFhirElement; criteria: TFHIRElementDefinition): boolean;
begin
  result := false;
end;

function TFHIRInstanceValidator.warning(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; path: String; thePass: boolean; msg: String): boolean;
var
  vm: TFhirOperationOutcomeIssue;
begin
  if not thePass then
  begin
    vm := TFhirOperationOutcomeIssue.Create;
    errors.Add(vm);
    vm.Tags['s-l'] := inttostr(locStart.line);
    vm.Tags['s-c'] := inttostr(locStart.col);
    vm.Tags['e-l'] := inttostr(locEnd.line);
    vm.Tags['e-c'] := inttostr(locEnd.col);
    vm.severity := IssueSeverityWarning;
    vm.locationList.append.value := path + ' (@ line ' + inttostr(locStart.line) + '/ col ' + inttostr(locStart.col) + ')';
    vm.code := t;
    vm.details := TFHIRCodeableConcept.Create;
    vm.details.text := msg;
  end;
  result := thePass;
end;

function TFHIRInstanceValidator.getValueForDiscriminator(element: TWrapperElement; discriminator: String; criteria: TFHIRElementDefinition): TFhirElement;
begin
  result := nil;
end;

function TFHIRInstanceValidator.hint(errors: TFhirOperationOutcomeIssueList; t: TFhirIssueType; locStart, locEnd: TSourceLocation; path: String; thePass: boolean; msg: String): boolean;
var
  vm: TFhirOperationOutcomeIssue;
begin
  if not thePass then
  begin
    vm := TFhirOperationOutcomeIssue.Create;
    errors.Add(vm);
    vm.Tags['s-l'] := inttostr(locStart.line);
    vm.Tags['s-c'] := inttostr(locStart.col);
    vm.Tags['e-l'] := inttostr(locEnd.line);
    vm.Tags['e-c'] := inttostr(locEnd.col);
    vm.severity := IssueSeverityInformation;
    vm.locationList.append.value := path + ' (@ line ' + inttostr(locStart.line) + '/ col ' + inttostr(locStart.col) + ')';
    vm.code := t;
    vm.details := TFHIRCodeableConcept.Create;
    vm.details.text := msg;
  end;
  result := thePass;
end;

function TFHIRInstanceValidator.getCriteriaForDiscriminator(path: String; ed: TFHIRElementDefinition; discriminator: String; profile: TFHIRStructureDefinition)
  : TFHIRElementDefinition;
var
  childDefinitions, Snapshot: TFHIRElementDefinitionList;
  // t : TFHIRStructureDefinition;
  originalPath, goal: String;
  ty: TFHIRStructureDefinition;
  index: integer;
begin
  result := nil;
  childDefinitions := getChildMap(profile, ed.name, ed.path, '');

  Snapshot := nil;
  if (childDefinitions.count = 0) then
  begin
    // going to look at the type
    if (ed.Type_List.count = 0) then
      raise Exception.Create('Error in profile for ' + path + ' no children, no type');
    if (ed.Type_List.count > 1) then
      raise Exception.Create('Error in profile for ' + path + ' multiple types defined in slice discriminator');
    if (ed.Type_List[0].profileList.count > 0) then
    begin
      // need to do some special processing for reference here...
      if (ed.Type_List[0].code = 'Reference') then
        discriminator := discriminator.substring(discriminator.indexOf('.') + 1);
      ty := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, ed.Type_List[0].profileList[0].value));
    end
    else
      ty := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, 'http://hl7.org/fhir/StructureDefinition/' + ed.Type_List[0].code));
    Snapshot := ty.Snapshot.ElementList;
    ed := Snapshot[0];
  end
  else
  begin
    Snapshot := profile.Snapshot.ElementList;
  end;
  originalPath := ed.path;
  goal := originalPath + '.' + discriminator;

  index := Snapshot.indexOf(ed);
  assert(index > -1);
  inc(index);
  while (index < Snapshot.count) and (Snapshot[index].path <> originalPath) do
  begin
    if (Snapshot[index].path = goal) then
    begin
      result := Snapshot[index];
      exit;
    end;
    inc(index);
  end;
  raise Exception.Create('Unable to find discriminator definition for ' + goal + ' in ' + discriminator + ' at ' + path);
end;

// private String mergePath(String path1, String path2) begin
// // path1 is xpath path
// // path2 is dotted path
// TArray<String> parts := path2.split('\\.');
// StringBuilder b := new StringBuilder(path1);
// for (int i := 1; i < parts.length -1; i++)
// b.append('/f:'+parts[i]);
// return b.toString();
// end;

function TFHIRInstanceValidator.checkResourceType(ty: String): String;
begin
  if (TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, 'http://hl7.org/fhir/StructureDefinition/' + ty)) <> nil) then
    result := ty
  else
    result := '';
end;

function TFHIRInstanceValidator.tryParse(ref: String): String;
var
  parts: TArray<String>;
begin
  parts := ref.split(['/']);
  case (length(parts)) of
    1:
      result := '';
    2:
      result := checkResourceType(parts[0]);
  else
    if (parts[length(parts) - 2] = '_history') then
      result := checkResourceType(parts[length(parts) - 4])
    else
      result := checkResourceType(parts[length(parts) - 2]);
  end;
end;

procedure TFHIRInstanceValidator.checkReference(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; profile: TFHIRStructureDefinition;
  container: TFHIRElementDefinition; parentType: String; stack: TNodeStack);
var
  ref: String;
  we: TWrapperElement;
  ft, pr, bt: String;
  ok: boolean;
  b: String;
  ty: TFhirElementDefinitionType;
begin
  ref := element.getNamedChildValue('reference');
  if (ref = '') then
  begin
    // todo - what should we do in this case?
    hint(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path, element.getNamedChildValue('display') <> '',
      'A Reference without an actual reference should have a display');
    exit;
  end;

  we := resolve(ref, stack);
  if (we <> nil) then
    ft := we.getResourceType()
  else
    ft := tryParse(ref);
  if (hint(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path, ft <> '', 'Unable to determine type of target resource')) then
  begin
    ok := false;
    b := '';
    for ty in container.Type_List do
    begin
      if (not ok) and (ty.code = 'Reference') then
      begin
        // we validate as much as we can. First, can we infer a type from the profile?
        if (ty.profileList.count = 0) or (ty.profileList[0].value = 'http://hl7.org/fhir/StructureDefinition/Resource') then
          ok := true
        else
        begin
          pr := ty.profileList[0].value;
          bt := getBaseType(profile, pr);
          if (rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path, bt <> '', 'Unable to resolve the profile reference "' + pr + '"')) then
          begin
            if (b <> '') then
              b := b + ', ';
            b := b + bt;
            ok := bt = ft;
          end
          else
            ok := true; // suppress following check
        end;
      end;
      if (not ok) and (ty.code = '*') then
      begin
        ok := true; // can refer to anything
      end;
    end;
    rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path, ok, 'Invalid Resource target type. Found ' + ft + ', but expected one of (' + b + ')');
  end;
end;

function TFHIRInstanceValidator.resolve(ref: String; stack: TNodeStack): TWrapperElement;
var
  res: TWrapperElement;
begin
  if (ref.startsWith('#')) then
  begin
    // work back through the contained list.
    // really, there should only be one level for this (contained resources cannot contain
    // contained resources), but we"ll leave that to some other code to worry about
    while (stack <> nil) and (stack.element <> nil) do
    begin
      res := getContainedById(stack.element, ref.substring(1));
      if (res <> nil) then
      begin
        result := res;
        exit;
      end;
      stack := stack.parent;
    end;
    result := nil;
  end
  else
  begin
    // work back through the contained list - if any of them are bundles, try to resolve
    // the resource in the bundle
    while (stack <> nil) and (stack.element <> nil) do
    begin
      if ('Bundle' = stack.element.getResourceType()) then
      begin
        res := getFromBundle(stack.element, ref.substring(1));
        if (res <> nil) then
        begin
          result := res;
          exit;
        end;
      end;
      stack := stack.parent;
    end;
    // todo: consult the external host for resolution
    result := nil;
  end;
end;

function TFHIRInstanceValidator.getFromBundle(bundle: TWrapperElement; ref: String): TWrapperElement;
var
  entries: TAdvList<TWrapperElement>;
  we, res: TWrapperElement;
  url: String;
begin
  entries := TAdvList<TWrapperElement>.Create();
  bundle.getNamedChildren('entry', entries);
  for we in entries do
  begin
    res := we.getNamedChild('resource').getFirstChild();
    if (res <> nil) then
    begin
      url := genFullUrl(bundle.getNamedChildValue('base'), we.getNamedChildValue('base'), res.getName(), res.getNamedChildValue('id'));
      if (url.endsWith(ref)) then
      begin
        result := res;
        exit;
      end;
    end;
  end;
  result := nil;
end;

function TFHIRInstanceValidator.genFullUrl(bundleBase, entryBase, ty, id: String): String;
var
  base: String;
begin
  if entryBase = '' then
    base := bundleBase
  else
    base := entryBase;
  if (base = '') then
    result := ty + '/' + id
  else if ('urn:uuid' = base) or ('urn:oid' = base) then
    result := base + id
  else
    result := base + '/' + ty + '/' + id;
end;

function TFHIRInstanceValidator.getContainedById(container: TWrapperElement; id: String): TWrapperElement;
var
  contained: TAdvList<TWrapperElement>;
  we, res: TWrapperElement;
begin
  contained := TAdvList<TWrapperElement>.Create();
  container.getNamedChildren('contained', contained);
  for we in contained do
  begin
    if we.isXml() then
      res := we.getFirstChild()
    else
      res := we;
    if (id = res.getNamedChildValue('id')) then
    begin
      result := res;
      exit;
    end;
  end;
  result := nil;
end;

function TFHIRInstanceValidator.getBaseType(profile: TFHIRStructureDefinition; pr: String): String;
var
  p: TFHIRStructureDefinition;
begin
  // if (pr.startsWith('http://hl7.org/fhir/StructureDefinition/')) begin
  // // this just has to be a base type
  // return pr.substring(40);
  // end; else begin
  p := resolveProfile(profile, pr);
  if (p = nil) then
    result := ''
  else if (p.Kind = StructureDefinitionKindRESOURCE) then
    result := p.Snapshot.ElementList[0].path
  else
    result := p.Snapshot.ElementList[0].Type_List[0].code;
  // end;
end;

function TFHIRInstanceValidator.resolveProfile(profile: TFHIRStructureDefinition; pr: String): TFHIRStructureDefinition;
var
  r: TFHIRResource;
begin
  if (pr.startsWith('#')) then
  begin
    for r in profile.containedList do
    begin
      if (r.id = pr.substring(1)) and (r is TFHIRStructureDefinition) then
      begin
        result := r as TFHIRStructureDefinition;
      end;
    end;
    result := nil;
  end
  else
    result := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, pr));
end;

function TFHIRInstanceValidator.checkExtension(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; def: TFHIRElementDefinition;
  profile: TFHIRStructureDefinition; stack: TNodeStack): TFHIRStructureDefinition;
var
  url: String;
  isModifier: boolean;
  ex: TFHIRStructureDefinition;
begin
  url := element.getAttribute('url');
  isModifier := element.getName() = 'modifierExtension';

  ex := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, url));
  if (ex = nil) then
  begin
    if (not rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path, allowUnknownExtension(url), 'The extension ' + url + ' is unknown, and not allowed here'))
    then
      warning(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path, allowUnknownExtension(url), 'Unknown extension ' + url);
  end
  else
  begin
    if (def.isModifier) then
      rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path + '[url:="' + url + '"]', ex.Snapshot.ElementList[0].isModifier,
        'Extension modifier mismatch: the extension element is labelled as a modifier, but the underlying extension is not')
    else
      rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path + '[url:="' + url + '"]', not ex.Snapshot.ElementList[0].isModifier,
        'Extension modifier mismatch: the extension element is not labelled as a modifier, but the underlying extension is');

    // two questions
    // 1. can this extension be used here?
    checkExtensionContext(errors, element, { path+'[url:="'+url+'"]', } ex, stack, ex.url);

    if (isModifier) then
      rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path + '[url:="' + url + '"]', ex.Snapshot.ElementList[0].isModifier,
        'The Extension "' + url + '" must be used as a modifierExtension')
    else
      rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), path + '[url:="' + url + '"]', not ex.Snapshot.ElementList[0].isModifier,
        'The Extension "' + url + '" must not be used as an extension (it"s a modifierExtension)');

    // 2. is the content of the extension valid?

  end;
  result := ex;
end;

function TFHIRInstanceValidator.allowUnknownExtension(url: String): boolean;
var
  s: String;
begin
  result := FIsAnyExtensionsAllowed;
  if (url.contains('example.org')) or (url.contains('acme.com')) or (url.contains('nema.org')) then
    result := true
  else if FExtensionDomains <> nil then
    for s in FExtensionDomains do
      if (url.startsWith(s)) then
        result := true;
end;

// function TFHIRInstanceValidator.isKnownType(code : String) : boolean;
// begin
// result := TFHIRStructureDefinition(Fcontext.fetchResource(frtStructureDefinition, code.toLower)) <> nil;
// end;

// function TFHIRInstanceValidator.getElementByPath(definition : TFHIRStructureDefinition; path : String) : TFHIRElementDefinition;
// var
// e : TFHIRElementDefinition;
// begin
// for e in definition.SnapShot.ElementList do
// begin
// if (e.Path = path) then
// begin
// result := e;
// exit;
// end;
// end;
// result := nil;
// end;

function TFHIRInstanceValidator.checkExtensionContext(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; definition: TFHIRStructureDefinition; stack: TNodeStack;
  extensionParent: String): boolean;
var
  extUrl: String;
  b, c, p, lp: String;
  ct: TFhirString;
  ok: boolean;
begin
  extUrl := definition.url;
  p := '';
  for lp in stack.logicalPaths do
  begin
    if p <> '' then
      p := p + ', ';
    p := p + lp;
  end;
  if (definition.ContextType = ExtensionContextDATATYPE) then
  begin
    ok := false;
    b := '';
    for ct in definition.contextList do
    begin
      if b <> '' then
        b := b + ', ';
      b := b + ct.value;
      if (ct.value = '*') or (stack.logicalPaths.indexOf(ct.value + '.extension') > -1) then
        ok := true;
    end;
    result := rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), stack.literalPath, ok,
      'The extension ' + extUrl + ' is not allowed to be used on the logical path set [' + p + '] (allowed: datatype:=' + b + ')');
  end
  else if (definition.ContextType = ExtensionContextEXTENSION) then
  begin
    ok := false;
    for ct in definition.contextList do
      if (ct.value = '*') or (ct.value = extensionParent) then
        ok := true;
    result := rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), stack.literalPath, ok,
      'The extension ' + extUrl + ' is not allowed to be used with the extension "' + extensionParent + '"');
  end
  else if (definition.ContextType = ExtensionContextMAPPING) then
  begin
    raise Exception.Create('Not handled yet (extensionContext)');
  end
  else if (definition.ContextType = ExtensionContextRESOURCE) then
  begin
    ok := false;
    // String simplePath := container.Path;
    // System.out.println(simplePath);
    // if (effetive.endsWith('.extension') ) or ( simplePath.endsWith('.modifierExtension'))
    // simplePath := simplePath.substring(0, simplePath.lastIndexOf("."));
    b := '';
    for ct in definition.contextList do
    begin
      if b <> '' then
        b := b + ', ';
      b := b + ct.value;
      c := ct.value;
      if (c = '*') or (stack.logicalPaths.indexOf(c + '.extension') >= 0) or (c.startsWith('@') and (stack.logicalPaths.indexOf(c.substring(1) + '.extension') >= 0)) then
        ok := true;
    end;
    result := rule(errors, IssueTypeSTRUCTURE, element.locStart(), element.locEnd(), stack.literalPath, ok,
      'The extension ' + extUrl + ' is not allowed to be used on the logical path set ' + p + ' (allowed: resource:=' + b + ')');
  end
  else
    raise Exception.Create('Unknown context type');
end;

//
// private String simplifyPath(String path) begin
// String s := path.replace('/f:', '.');
// while (s.contains('['))
// s := s.substring(0, s.indexOf('['))+s.substring(s.indexOf(']')+1);
// TArray<String> parts := s.split('\\.');
// int i := 0;
// while (i < parts.length ) and ( !context.getProfiles().containsKey(parts[i].toLowerCase()))
// i++;
// if (i >= parts.length)
// raise Exception.create('Unable to process part '+path);
// int j := parts.length - 1;
// while (j > 0 ) and ( (parts[j] = 'extension') ) or ( parts[j] = 'modifierExtension')))
// j--;
// StringBuilder b := new StringBuilder();
// boolean first := true;
// for (int k := i; k <= j; k++) begin
// if (k = j ) or ( !parts[k] = parts[k+1])) begin
// if (first)
// first := false;
// else
// b.append('.');
// b.append(parts[k]);
// end;
// end;
// return b.toString();
// end;
//

function empty(element: TWrapperElement): boolean;
var
  child: TWrapperElement;
begin
  if (element.hasAttribute('value')) then
    result := false
  else if (element.hasAttribute('xml:id')) then
    result := false
  else
  begin
    child := element.getFirstChild();
    while (child <> nil) do
    begin
      if (not child.isXml()) or (FHIR_NS = child.getNamespace()) then
      begin
        result := false;
        exit;
      end;
      child := child.getNextSibling();
    end;
    result := true;
  end;
end;

function TFHIRInstanceValidator.findElement(profile: TFHIRStructureDefinition; name: String): TFHIRElementDefinition;
var
  c: TFHIRElementDefinition;
begin
  result := nil;
  for c in profile.Snapshot.ElementList do
  begin
    if (c.path = name) then
    begin
      result := c;
      exit;
    end;
  end;
end;

// function TFHIRInstanceValidator.getDefinitionByTailNameChoice(children : TFHIRElementDefinitionList; name : String) : TFHIRElementDefinition;
// var
// ed : TFHIRElementDefinition;
// n : string;
// begin
// result := nil;
// for ed in children do
// begin
// n := tail(ed.Path);
// if (n.endsWith('[x]') ) and ( name.startsWith(n.substring(0, n.length-3))) then
// begin
// result := ed;
// exit;
// end;
// end;
// end;

procedure TFHIRInstanceValidator.validateContains(errors: TFhirOperationOutcomeIssueList; path: String; child: TFHIRElementDefinition; context: TFHIRElementDefinition;
  element: TWrapperElement; stack: TNodeStack; needsId: boolean);
var
  e: TWrapperElement;
  resourceName: String;
  profile: TFHIRStructureDefinition;
begin
  if element.isXml() then
    e := element.getFirstChild()
  else
    e := element;
  resourceName := e.getResourceType();
  profile := TFHIRStructureDefinition(FContext.fetchResource(frtStructureDefinition, 'http://hl7.org/fhir/StructureDefinition/' + resourceName));
  if (rule(errors, IssueTypeINVALID, element.locStart(), element.locEnd(), stack.addToLiteralPath(resourceName), profile <> nil,
    'No profile found for contained resource of type "' + resourceName + '"')) then
    validateResource(errors, e, profile, needsId, stack);
end;

function passesCodeWhitespaceRules(v: String): boolean;
var
  lastWasSpace: boolean;
  c: char;
begin
  if (v.trim() <> v) then
    result := false
  else
  begin
    lastWasSpace := true;
    for c in v do
    begin
      if (c = ' ') then
      begin
        if (lastWasSpace) then
        begin
          result := false;
          exit;
        end
        else
          lastWasSpace := true;
      end
      else if c.isWhitespace then
      begin
        result := false;
        exit;
      end
      else
        lastWasSpace := false;
    end;
  end;
  result := true;
end;

function yearIsValid(v: String): boolean;
var
  i: integer;
begin
  if (v = '') then
    result := false
  else
  begin
    i := StrToIntDef(v.substring(0, Integermin(4, v.length)), 0);
    result := (i >= 1800) and (i <= 2100);
  end;
end;

function hasTimeZone(fmt: String): boolean;
begin
  result := (fmt.length > 10) and (fmt.substring(10).contains('-') or fmt.substring(10).contains('+') or fmt.substring(10).contains('Z'));
end;

function hasTime(fmt: String): boolean;
begin
  result := fmt.contains('T');
end;

procedure TFHIRInstanceValidator.checkPrimitive(errors: TFhirOperationOutcomeIssueList; path: String; ty: String; context: TFHIRElementDefinition; e: TWrapperElement);
var
  regex: TRegExpr;
begin
  if (ty = 'xhtml') then
    exit;

  if (ty = 'uri') then
  begin
    rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, not e.getAttribute('value').startsWith('oid:'), 'URI values cannot start with oid:');
    rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, not e.getAttribute('value').startsWith('uuid:'), 'URI values cannot start with uuid:');
    rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, e.getAttribute('value') = e.getAttribute('value').trim(), 'URI values cannot have leading or trailing whitespace');
  end;
  if (not SameText(ty, 'string')) and (e.hasAttribute('value')) then
  begin
    if (rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, e.getAttribute('value').length > 0, '@value cannot be empty')) then
      warning(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, e.getAttribute('value').trim() = e.getAttribute('value'), 'value should not start or finish with whitespace');
  end;
  if (ty = 'dateTime') then
  begin
    rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, yearIsValid(e.getAttribute('value')), 'The value "' + e.getAttribute('value') + '" does not have a valid year');
    regex := TRegExpr.Create;
    try
      regex.Expression :=
        '-?[0-9]{4}(-(0[1-9]|1[0-2])(-(0[0-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00))?)?)?)?';
      rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, regex.Exec(e.getAttribute('value')), 'Not a valid date time');
    finally
      regex.Free;
    end;
    rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, not hasTime(e.getAttribute('value')) or hasTimeZone(e.getAttribute('value')),
      'if a date has a time, it must have a timezone');
  end;
  if (ty = 'instant') then
  begin
    regex := TRegExpr.Create;
    try
      regex.Expression := '-?[0-9]{4}-(0[1-9]|1[0-2])-(0[0-9]|[1-2][0-9]|3[0-1])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00))';
      rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, regex.Exec(e.getAttribute('value')), 'The instant "' + e.getAttribute('value') + '" is not valid (by regex)');
    finally
      regex.Free;
    end;
    rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, yearIsValid(e.getAttribute('value')), 'The value "' + e.getAttribute('value') + '" does not have a valid year');
  end;

  if (ty = 'code') then
  begin
    // Technically, a code is restricted to string which has at least one character and no leading or trailing whitespace, and where there is no whitespace other than single spaces in the contents
    rule(errors, IssueTypeINVALID, e.locStart(), e.locEnd(), path, passesCodeWhitespaceRules(e.getAttribute('value')),
      'The code "' + e.getAttribute('value') + '" is not valid (whitespace rules)');
  end;

  if (context.Binding <> nil) then
  begin
    checkPrimitiveBinding(errors, path, ty, context, e);
  end;
  // for nothing to check
end;

function describeReference(reference: TFHIRType): String;
begin
  if (reference = nil) then
    result := 'nil'
  else if (reference is TFHIRUri) then
    result := TFHIRUri(reference).value
  else if (reference is TFHIRReference) then
    result := TFHIRReference(reference).reference
  else
    result := '??';
end;

// note that we don"t check the type here; it could be string, uri or code.
procedure TFHIRInstanceValidator.checkPrimitiveBinding(errors: TFhirOperationOutcomeIssueList; path: String; ty: String; context: TFHIRElementDefinition; element: TWrapperElement);
var
  value: String;
  Binding: TFhirElementDefinitionBinding;
  vs: TFHIRValueSet;
  ok: boolean;
  res: TValidationResult;
begin
  if (not element.hasAttribute('value')) then
    exit;
  value := element.getAttribute('value');

  // System.out.println('check '+value+' in '+path);

  // firstly, resolve the value set
  Binding := context.Binding;
  if (Binding.ValueSet <> nil) and (Binding.ValueSet is TFHIRReference) then
  begin
    vs := resolveBindingReference(Binding.ValueSet);
    if (warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, vs <> nil, 'ValueSet ' + describeReference(Binding.ValueSet) + ' not found')) then
    begin
      res := FContext.validateCode('', value, '', vs);
      if (not res.isOk()) then
      begin
        if (Binding.Strength = BindingStrengthREQUIRED) then
          warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'The value provided is not in the value set ' +
            describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code is required from this value set')
        else if (Binding.Strength = BindingStrengthEXTENSIBLE) then
          warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'The value provided is not in the value set ' +
            describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code should come from this value set unless it has no suitable code')
        else if (Binding.Strength = BindingStrengthPREFERRED) then
          hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'The value provided is not in the value set ' + describeReference(Binding.ValueSet)
            + ' (' + vs.url + ', and a code is recommended to come from this value set');
      end;
    end;
  end
  else
    hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'Binding has no source, so can''t be checked');
end;

function isValidFHIRUrn(uri: String): boolean;
begin
  result := (uri = 'urn:x-fhir:uk:id:nhs-number');
end;

function isAbsolute(uri: String): boolean;
begin
  result := (uri = '') or uri.startsWith('http:') or uri.startsWith('https:') or uri.startsWith('urn:uuid:') or uri.startsWith('urn:oid:') or uri.startsWith('urn:ietf:') or
    uri.startsWith('urn:iso:') or isValidFHIRUrn(uri);
end;

procedure TFHIRInstanceValidator.checkIdentifier(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; context: TFHIRElementDefinition);
var
  System: String;
begin
  System := element.getNamedChildValue('system');
  rule(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, isAbsolute(System), 'Identifier.system must be an absolute reference, not a local reference');
end;

procedure TFHIRInstanceValidator.checkQuantity(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; context: TFHIRElementDefinition; b: boolean);
var
  code: String;
  System: String;
  units: String;
begin
  code := element.getNamedChildValue('code');
  System := element.getNamedChildValue('system');
  units := element.getNamedChildValue('units');

  if (System <> '') and (code <> '') then
    checkCode(errors, element, path, code, System, units);
end;

function readAsCoding(item: TWrapperElement): TFHIRCoding;
var
  c: TFHIRCoding;
begin
  c := TFHIRCoding.Create;
  try
    c.System := item.getNamedChildValue('system');
    c.Version := item.getNamedChildValue('version');
    c.code := item.getNamedChildValue('code');
    c.display := item.getNamedChildValue('display');
    result := c.Link;
  finally
    c.Free;
  end;
end;

procedure TFHIRInstanceValidator.checkCoding(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; profile: TFHIRStructureDefinition;
  context: TFHIRElementDefinition; inCodeableConcept: boolean);
var
  code: String;
  System: String;
  display: String;
  Binding: TFhirElementDefinitionBinding;
  vs: TFHIRValueSet;
  c: TFHIRCoding;
  res: TValidationResult;
begin
  code := element.getNamedChildValue('code');
  System := element.getNamedChildValue('system');
  display := element.getNamedChildValue('display');

  rule(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, isAbsolute(System), 'Coding.system must be an absolute reference, not a local reference');

  if (System <> '') and (code <> '') then
  begin
    if (checkCode(errors, element, path, code, System, display)) then
      if (context <> nil) and (context.Binding <> nil) then
      begin
        Binding := context.Binding;
        if (warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, Binding <> nil, 'Binding for ' + path + ' missing')) then
        begin
          if (Binding.ValueSet <> nil) and (Binding.ValueSet is TFHIRReference) then
          begin
            vs := resolveBindingReference(Binding.ValueSet);
            if (warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, vs <> nil, 'ValueSet ' + describeReference(Binding.ValueSet) + ' not found')) then
            begin
              try
                c := readAsCoding(element);
                res := FContext.validateCode(c, vs);
                if (not res.isOk()) then
                  if (Binding.Strength = BindingStrengthREQUIRED) then
                    warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'The value provided is not in the value set ' +
                      describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code is required from this value set')
                  else if (Binding.Strength = BindingStrengthEXTENSIBLE) then
                    warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'The value provided is not in the value set ' +
                      describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code should come from this value set unless it has no suitable code')
                  else if (Binding.Strength = BindingStrengthPREFERRED) then
                    hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'The value provided is not in the value set ' +
                      describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code is recommended to come from this value set');
              except
                on e: Exception do
                  warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'Error ' + e.message + ' validating CodeableConcept');
              end;
            end
            else if (Binding.ValueSet <> nil) then
              hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'Binding by URI TFHIRReference cannot be checked')
            else if not inCodeableConcept then
              hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'Binding has no source, so can''t be checked');
          end;
        end;
      end;
  end;
end;

function TFHIRInstanceValidator.resolveBindingReference(reference: TFHIRType): TFHIRValueSet;
begin
  if (reference is TFHIRUri) then
    result := TFHIRValueSet(FContext.fetchResource(frtValueSet, TFHIRUri(reference).value))
  else if (reference is TFHIRReference) then
    result := TFHIRValueSet(FContext.fetchResource(frtValueSet, TFHIRReference(reference).reference))
  else
    result := nil;
end;

function readAsCodeableConcept(element: TWrapperElement): TFHIRCodeableConcept;
var
  cc: TFHIRCodeableConcept;
  list: TAdvList<TWrapperElement>;
  item: TWrapperElement;
begin
  cc := TFHIRCodeableConcept.Create;
  list := TAdvList<TWrapperElement>.Create;
  try
    element.getNamedChildren('coding', list);
    for item in list do
      cc.CodingList.Add(readAsCoding(item));
    cc.text := element.getNamedChildValue('text');
    result := cc.Link;
  finally
    cc.Free;
    list.Free;
  end;
End;

procedure TFHIRInstanceValidator.checkCodeableConcept(errors: TFhirOperationOutcomeIssueList; path: String; element: TWrapperElement; profile: TFHIRStructureDefinition;
  context: TFHIRElementDefinition);
var
  Binding: TFhirElementDefinitionBinding;
  vs: TFHIRValueSet;
  found, any: boolean;
  c: TWrapperElement;
  res: TValidationResult;
  code, System, Version: string;
  cc: TFHIRCodeableConcept;
begin
  if (context <> nil) and (context.Binding <> nil) then
  begin
    Binding := context.Binding;
    if (warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, Binding <> nil, 'Binding for ' + path + ' missing (cc)')) then
    begin
      if (Binding.ValueSet <> nil) and (Binding.ValueSet is TFHIRReference) then
      begin
        vs := resolveBindingReference(Binding.ValueSet);
        if (warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, vs <> nil, 'ValueSet ' + describeReference(Binding.ValueSet) + ' not found')) then
        begin
          try
            cc := readAsCodeableConcept(element);
            if (cc.CodingList.IsEmpty) then
            begin
              if (Binding.Strength = BindingStrengthREQUIRED) then
                rule(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'No code provided, and a code is required from the value set ' +
                  describeReference(Binding.ValueSet) + ' (' + vs.url)
              else if (Binding.Strength = BindingStrengthEXTENSIBLE) then
                warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'No code provided, and a code should be provided from the value set ' +
                  describeReference(Binding.ValueSet) + ' (' + vs.url);
            end
            else
            begin
              res := FContext.validateCode(cc, vs);
              if (not res.isOk) then
              begin
                if (Binding.Strength = BindingStrengthREQUIRED) then
                  rule(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'None of the codes provided are in the value set ' +
                    describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code from this value set is required')
                else if (Binding.Strength = BindingStrengthEXTENSIBLE) then
                  warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'None of the codes provided are in the value set ' +
                    describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code should come from this value set unless it has no suitable code')
                else if (Binding.Strength = BindingStrengthPREFERRED) then
                  hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'None of the codes provided are in the value set ' +
                    describeReference(Binding.ValueSet) + ' (' + vs.url + ', and a code is recommended to come from this value set');
              end;
            end;
          except
            on e: Exception do
              warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'Error ' + e.message + ' validating CodeableConcept');
          end;
        end;
      end;
    end;
  end
  else if (Binding.ValueSet <> nil) then
    hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'Binding by URI TFHIRReference cannot be checked')
  else
    hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, false, 'Binding has no source, so can''t be checked');
end;

function TFHIRInstanceValidator.checkCode(errors: TFhirOperationOutcomeIssueList; element: TWrapperElement; path: String; code, System, display: String): boolean;
var
  s: TValidationResult;
begin
  result := true;
  if (FContext.supportsSystem(System)) then
  begin
    s := FContext.validateCode(System, code, display);
    try
      if (s = nil) or (s.isOk()) then
        result := true
      else if (s.severity = IssueSeverityInformation) then
        hint(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, s = nil, s.message)
      else if (s.severity = IssueSeverityWarning) then
        warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, s = nil, s.message)
      else
        result := rule(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, s = nil, s.message);
    finally
      s.Free;
    end;
  end
  // else if (system.startsWith('http://hl7.org/fhir')) then
  // begin
  // if (system = 'http://hl7.org/fhir/sid/icd-10') then
  // result := true // else don"t check ICD-10 (for now)
  // else
  // begin
  // vs := FContext.fetchCodeSystem(system);
  // if (vs <> nil) then
  // check vlaue set uri hasn't been used directly
  // if (warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, vs <> nil, 'Unknown Code System '+system))
  // else begin
  // ConceptDefinitionComponent def := getCodeDefinition(vs, code);
  // if (warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, def <> nil, 'Unknown Code ('+system+'#'+code+')'))
  // return warning(errors, IssueTypeCODEINVALID, element.locStart(), element.locEnd(), path, display = nil ) or ( display = def.getDisplay()), 'Display should be "'+def.getDisplay()+'"');
  // end;
  // return false;
  // end;
  // end; else if (system.startsWith('http://loinc.org')) begin
  // return true;
  // end; else if (system.startsWith('http://unitsofmeasure.org')) begin
  // return true;
  // end;
  else
    result := true;
end;

// function getCodeDefinition(c TFHIRConceptDefinition; code : String ) : TFHIRConceptDefinition;
// begin
// if (code = c.Code))
// return c;
// for (ConceptDefinitionComponent g : c.getConcept()) begin
// ConceptDefinitionComponent r := getCodeDefinition(g, code);
// if (r <> nil)
// return r;
// end;
// return nil;
// end;
//
// private ConceptDefinitionComponent getCodeDefinition(vs : TFHIRValueSet, String code) begin
// for (ConceptDefinitionComponent c : vs.getCodeSystem().getConcept()) begin
// ConceptDefinitionComponent r := getCodeDefinition(c, code);
// if (r <> nil)
// return r;
// end;
// return nil;
// end;



// public class ProfileStructureIterator begin
//
// private profile : TFHIRStructureDefinition;
// private TFHIRElementDefinition elementDefn;
// private List<String> names := new ArrayList<String>();
// private Map<String, List<TFHIRElementDefinition>> children := new HashMap<String, List<TFHIRElementDefinition>>();
// private int cursor;
//
// public ProfileStructureIterator(profile : TFHIRStructureDefinition, TFHIRElementDefinition elementDefn) begin
// this.profile := profile;
// this.elementDefn := elementDefn;
// loadMap();
// cursor := -1;
// end;
//
// procedure TFHIRInstanceValidator.loadMap() begin
// int i := profile.SnapShot.getElement().indexOf(elementDefn) + 1;
// String lead := elementDefn.Path;
// while (i < profile.SnapShot.getElement().Count) begin
// String name := profile.Snapshot.ElementList[i).Path;
// if (name.length() <= lead.length())
// return; // cause we"ve got to the end of the possible matches
// String tail := name.substring(lead.length()+1);
// if (Utilities.isToken(tail) ) and ( name.substring(0, lead.length()) = lead)) begin
// List<TFHIRElementDefinition> list := children[tail);
// if (list = nil) begin
// list := new ArrayList<TFHIRElementDefinition>();
// names.add(tail);
// children.put(tail, list);
// end;
// list.add(profile.Snapshot.ElementList[i));
// end;
// i++;
// end;
// end;
//
// public boolean more() begin
// cursor++;
// return cursor < names.Count;
// end;
//
// public List<TFHIRElementDefinition> current() begin
// return children[name());
// end;
//
// public String name() begin
// return names[cursor);
// end;
//
// end;
//
// procedure TFHIRInstanceValidator.checkByProfile(errors : TFhirOperationOutcomeIssueList; path : String; focus : TWrapperElement, profile : TFHIRStructureDefinition, TFHIRElementDefinition elementDefn) ; begin
// // we have an element, and the structure that describes it.
// // we know that"s it"s valid against the underlying spec - is it valid against this one?
// // in the instance validator above, we assume that schema or schmeatron has taken care of cardinalities, but here, we have no such reliance.
// // so the walking algorithm is different: we"re going to walk the definitions
// String type;
// if (elementDefn.Path.endsWith('[x]')) begin
// String tail := elementDefn.Path.substring(elementDefn.Path.lastIndexOf('.')+1, elementDefn.Path.length()-3);
// type := focus.getName().substring(tail.length());
// rule(errors, IssueTypeSTRUCTURE, focus.locStart(), focus.locEnd(), path, typeAllowed(type, elementDefn.Type_List), 'The type "'+type+'" is not allowed at this point (must be one of "'+typeSummary(elementDefn)+')');
// end; else begin
// if (elementDefn.Type_List.Count = 1) begin
// type := elementDefn.Type_List.Count = 0 ? nil : elementDefn.Type_List[0].Code;
// end; else
// type := nil;
// end;
// // constraints:
// for (ElementDefinitionConstraintComponent c : elementDefn.getConstraint())
// checkConstraint(errors, path, focus, c);
// if (elementDefn.Binding <> nil ) and ( type <> nil)
// checkBinding(errors, path, focus, profile, elementDefn, type);
//
// // type specific checking:
// if (type <> nil ) and ( typeIsPrimitive(type)) begin
// checkPrimitiveByProfile(errors, path, focus, elementDefn);
// end; else begin
// if (elementDefn.hasFixed())
// checkFixedValue(errors, path, focus, elementDefn.getFixed(), '');
//
// ProfileStructureIterator walker := new ProfileStructureIterator(profile, elementDefn);
// while (walker.more()) begin
// // collect all the slices for the path
// List<TFHIRElementDefinition> childset := walker.current();
// // collect all the elements that match it by name
// TAdvList<TWrapperElement> children := TAdvList<TWrapperElement>.create();
// focus.getNamedChildrenWithWildcard(walker.name(), children);
//
// if (children.Count = 0) begin
// // well, there"s no children - should there be?
// for (TFHIRElementDefinition defn : childset) begin
// if (not rule(errors, IssueTypeREQUIRED, focus.locStart(), focus.locEnd(), path, defn.getMin() = 0, 'Required Element "'+walker.name()+'" missing'))
// break; // no point complaining about missing ones after the first one
// end;
// end; else if (childset.Count = 1) begin
// // simple case: one possible definition, and one or more children.
// rule(errors, IssueTypeSTRUCTURE, focus.locStart(), focus.locEnd(), path, childset[0).Max = '*') ) or ( StrToInt(childset[0).Max) >= children.Count,
// 'Too many elements for "'+walker.name()+'"'); // todo: sort out structure
// for (TWrapperElement child : children) begin
// checkByProfile(errors, childset[0).Path, child, profile, childset[0));
// end;
// end; else begin
// // ok, this is the full case - we have a list of definitions, and a list of candidates for meeting those definitions.
// // we need to decide *if* that match a given definition
// end;
// end;
// end;
// end;
// procedure TFHIRInstanceValidator.checkBinding(errors : TFhirOperationOutcomeIssueList; path : String; focus : TWrapperElement, profile : TFHIRStructureDefinition, TFHIRElementDefinition elementDefn, String type) throws EOperationOutcome, Exception begin
// ElementDefinitionBindingComponent bc := elementDefn.Binding;
//
// if (bc <> nil ) and ( bc.ValueSet() <> nil ) and ( bc.ValueSet is TFHIRReference) begin
// String url := ((TFHIRReference) bc.ValueSet).getReference();
// vs : TFHIRValueSet := resolveValueSetReference(profile, (TFHIRReference) bc.ValueSet);
// if (vs = nil) begin
// rule(errors, IssueTypeSTRUCTURE, focus.locStart(), focus.locEnd(), path, false, 'Cannot check binding on type "'+type+'" as the value set "'+url+'" could not be located');
// end; else if (ty = 'code'))
// checkBindingCode(errors, path, focus, vs);
// else if (ty = 'Coding'))
// checkBindingCoding(errors, path, focus, vs);
// else if (ty = 'CodeableConcept'))
// checkBindingCodeableConcept(errors, path, focus, vs);
// else
// rule(errors, IssueTypeSTRUCTURE, focus.locStart(), focus.locEnd(), path, false, 'Cannot check binding on type "'+type+'"');
// end;
// end;
//
// private ValueSet resolveValueSetReference(profile : TFHIRStructureDefinition, TFHIRReference TFHIRReference) throws EOperationOutcome, Exception begin
// if (TFHIRReference.getReference().startsWith('#')) begin
// for (Resource r : profile.getContained()) begin
// if (r is ValueSet ) and ( r.getId() = TFHIRReference.getReference().substring(1)))
// return (ValueSet) r;
// end;
// return nil;
// end; else
// return resolveBindingReference(TFHIRReference);
//
// end;

// procedure TFHIRInstanceValidator.checkBindingCode(errors : TFhirOperationOutcomeIssueList; path : String; focus : TWrapperElement, vs : TFHIRValueSet) begin
// // rule(errors, 'exception', path, false, 'checkBindingCode not done yet');
// end;
//
// procedure TFHIRInstanceValidator.checkBindingCoding(errors : TFhirOperationOutcomeIssueList; path : String; focus : TWrapperElement, vs : TFHIRValueSet) begin
// // rule(errors, 'exception', path, false, 'checkBindingCoding not done yet');
// end;
//
// procedure TFHIRInstanceValidator.checkBindingCodeableConcept(errors : TFhirOperationOutcomeIssueList; path : String; focus : TWrapperElement, vs : TFHIRValueSet) begin
// // rule(errors, 'exception', path, false, 'checkBindingCodeableConcept not done yet');
// end;
//
// private String typeSummary(TFHIRElementDefinition elementDefn) begin
// StringBuilder b := new StringBuilder();
// for (TypeRefComponent t : elementDefn.Type_List) begin
// b.append('"'+t.Code);
// end;
// return b.toString().substring(1);
// end;
//
// private boolean typeAllowed(String t, List<TypeRefComponent> types) begin
// for (TypeRefComponent type : types) begin
// if (t = Utilities.capitalize(ty.Code)))
// return true;
// if (t = 'Resource') ) and ( Utilities.capitalize(ty.Code) = 'TFHIRReference'))
// return true;
// end;
// return false;
// end;
//
// procedure TFHIRInstanceValidator.checkConstraint(errors : TFhirOperationOutcomeIssueList; path : String; focus : TWrapperElement, ElementDefinitionConstraintComponent c) ; begin

// try
// begin
// XPathFactory xpf := new net.sf.saxon.xpath.XPathFactoryImpl();
// NamespaceContext context := new NamespaceContextMap('f', 'http://hl7.org/fhir', 'h', 'http://www.w3.org/1999/xhtml');
//
// XPath xpath := xpf.newXPath();
// xpath.setNamespaceContext(context);
// ok : boolean := (Boolean) xpath.evaluate(c.getXpath(), focus, XPathConstants.BOOLEAN);
// if (ok = nil ) or ( not ok) begin
// if (c.getSeverity() = ConstraintSeverity.warning)
// warning(errors, 'invariant', path, false, c.getHuman());
// else
// rule(errors, 'invariant', path, false, c.getHuman());
// end;
// end;
// catch (XPathExpressionException e) begin
// rule(errors, 'invariant', path, false, 'error executing invariant: '+e.Message);
// end;
// end;
//
// procedure TFHIRInstanceValidator.checkPrimitiveByProfile(errors : TFhirOperationOutcomeIssueList; path : String; focus : TWrapperElement, TFHIRElementDefinition elementDefn) begin
// // two things to check - length, and fixed value
// String value := focus.getAttribute('value');
// if (elementDefn.hasMaxLengthElement()) begin
// rule(errors, IssueTypeTOOLONG, focus.locStart(), focus.locEnd(), path, value.length() <= elementDefn.getMaxLength(), 'The value "'+value+'" exceeds the allow length limit of '+inttostr(elementDefn.getMaxLength()));
// end;
// if (elementDefn.hasFixed()) begin
// checkFixedValue(errors, path, focus, elementDefn.getFixed(), '');
// end;
// end;
//

procedure TFHIRInstanceValidator.checkFixedValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFhirElement; propName: String);
var
  value: String;
  extensions: TAdvList<TWrapperElement>;
  e: TFhirExtension;
  ex: TWrapperElement;
begin
  if (fixed = nil) and (focus = nil) then
    exit; // this is all good

  if (fixed = nil) and (focus <> nil) then
    rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, false, 'Unexpected element ' + focus.getName())
  else if (fixed <> nil) and (focus = nil) then
    rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, false, 'Mising element ' + propName)
  else
  begin
    value := focus.getAttribute('value');
    if (fixed is TFHIRBoolean) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRBoolean(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRBoolean(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRInteger) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRInteger(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRInteger(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRDecimal) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRDecimal(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRDecimal(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRBase64Binary) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRBase64Binary(fixed).StringValue = value,
        'Value is "' + value + '" but must be "' + TFHIRBase64Binary(fixed).StringValue + '"')
    else if (fixed is TFHIRInstant) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRInstant(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRInstant(fixed)
        .StringValue + '"')
    else if (fixed is TFhirString) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFhirString(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFhirString(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRUri) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRUri(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRUri(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRDate) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRDate(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRDate(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRDateTime) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRDateTime(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRDateTime(fixed)
        .StringValue + '"')
    else if (fixed is TFHIROid) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIROid(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIROid(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRUuid) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRUuid(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRUuid(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRCode) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRCode(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRCode(fixed)
        .StringValue + '"')
    else if (fixed is TFHIRId) then
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, TFHIRId(fixed).StringValue = value, 'Value is "' + value + '" but must be "' + TFHIRId(fixed).StringValue + '"')
    else if (fixed is TFHIRQuantity) then
      checkQuantityValue(errors, path, focus, TFHIRQuantity(fixed))
    else if (fixed is TFHIRAddress) then
      checkAddressValue(errors, path, focus, TFHIRAddress(fixed))
    else if (fixed is TFHIRContactPoint) then
      checkContactPointValue(errors, path, focus, TFHIRContactPoint(fixed))
    else if (fixed is TFHIRAttachment) then
      checkAttachmentValue(errors, path, focus, TFHIRAttachment(fixed))
    else if (fixed is TFHIRIdentifier) then
      checkIdentifierValue(errors, path, focus, TFHIRIdentifier(fixed))
    else if (fixed is TFHIRCoding) then
      checkCodingValue(errors, path, focus, TFHIRCoding(fixed))
    else if (fixed is TFHIRHumanName) then
      checkHumanNameValue(errors, path, focus, TFHIRHumanName(fixed))
    else if (fixed is TFHIRCodeableConcept) then
      checkCodeableConceptValue(errors, path, focus, TFHIRCodeableConcept(fixed))
    else if (fixed is TFHIRTiming) then
      checkTimingValue(errors, path, focus, TFHIRTiming(fixed))
    else if (fixed is TFHIRPeriod) then
      checkPeriodValue(errors, path, focus, TFHIRPeriod(fixed))
    else if (fixed is TFHIRRange) then
      checkRangeValue(errors, path, focus, TFHIRRange(fixed))
    else if (fixed is TFHIRRatio) then
      checkRatioValue(errors, path, focus, TFHIRRatio(fixed))
    else if (fixed is TFHIRSampledData) then
      checkSampledDataValue(errors, path, focus, TFHIRSampledData(fixed))
    else
      rule(errors, IssueTypeException, focus.locStart(), focus.locEnd(), path, false, 'Unhandled fixed value type ' + fixed.ClassName);
    extensions := TAdvList<TWrapperElement>.Create();
    focus.getNamedChildren('extension', extensions);
    if (fixed.extensionList.count = 0) then
    begin
      rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, extensions.count = 0, 'No extensions allowed');
    end
    else if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, extensions.count = fixed.extensionList.count,
      'Extensions count mismatch: expected ' + inttostr(fixed.extensionList.count) + ' but found ' + inttostr(extensions.count))) then
    begin
      for e in fixed.extensionList do
      begin
        ex := getExtensionByUrl(extensions, e.url);
        if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, ex <> nil, 'Extension count mismatch: unable to find extension: ' + e.url)) then
          checkFixedValue(errors, path, ex.getFirstChild().getNextSibling(), e.value, 'extension.value');
      end;
    end;
  end;
end;

procedure TFHIRInstanceValidator.checkAddressValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRAddress);
var
  lines: TAdvList<TWrapperElement>;
  i: integer;
begin
  checkFixedValue(errors, path + '.use', focus.getNamedChild('use'), fixed.UseElement, 'use');
  checkFixedValue(errors, path + '.text', focus.getNamedChild('text'), fixed.TextElement, 'text');
  checkFixedValue(errors, path + '.city', focus.getNamedChild('city'), fixed.CityElement, 'city');
  checkFixedValue(errors, path + '.state', focus.getNamedChild('state'), fixed.StateElement, 'state');
  checkFixedValue(errors, path + '.country', focus.getNamedChild('country'), fixed.CountryElement, 'country');
  checkFixedValue(errors, path + '.zip', focus.getNamedChild('zip'), fixed.PostalCodeElement, 'postalCode');

  lines := TAdvList<TWrapperElement>.Create();
  focus.getNamedChildren('line', lines);
  if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, lines.count = fixed.lineList.count, 'Expected ' + inttostr(fixed.lineList.count) + ' but found ' +
    inttostr(lines.count) + ' line elements')) then
  begin
    for i := 0 to lines.count - 1 do
      checkFixedValue(errors, path + '.coding', lines[i], fixed.lineList[i], 'coding');
  end;
end;

procedure TFHIRInstanceValidator.checkContactPointValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRContactPoint);
begin
  checkFixedValue(errors, path + '.system', focus.getNamedChild('system'), fixed.SystemElement, 'system');
  checkFixedValue(errors, path + '.value', focus.getNamedChild('value'), fixed.ValueElement, 'value');
  checkFixedValue(errors, path + '.use', focus.getNamedChild('use'), fixed.UseElement, 'use');
  checkFixedValue(errors, path + '.period', focus.getNamedChild('period'), fixed.Period, 'period');
end;

procedure TFHIRInstanceValidator.checkAttachmentValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRAttachment);
begin
  checkFixedValue(errors, path + '.contentType', focus.getNamedChild('contentType'), fixed.ContentTypeElement, 'contentType');
  checkFixedValue(errors, path + '.language', focus.getNamedChild('language'), fixed.LanguageElement, 'language');
  checkFixedValue(errors, path + '.data', focus.getNamedChild('data'), fixed.DataElement, 'data');
  checkFixedValue(errors, path + '.url', focus.getNamedChild('url'), fixed.UrlElement, 'url');
  checkFixedValue(errors, path + '.size', focus.getNamedChild('size'), fixed.SizeElement, 'size');
  checkFixedValue(errors, path + '.hash', focus.getNamedChild('hash'), fixed.HashElement, 'hash');
  checkFixedValue(errors, path + '.title', focus.getNamedChild('title'), fixed.TitleElement, 'title');
end;

procedure TFHIRInstanceValidator.checkIdentifierValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRIdentifier);
begin
  checkFixedValue(errors, path + '.use', focus.getNamedChild('use'), fixed.UseElement, 'use');
  checkFixedValue(errors, path + '.label', focus.getNamedChild('type'), fixed.type_, 'type');
  checkFixedValue(errors, path + '.system', focus.getNamedChild('system'), fixed.SystemElement, 'system');
  checkFixedValue(errors, path + '.value', focus.getNamedChild('value'), fixed.ValueElement, 'value');
  checkFixedValue(errors, path + '.period', focus.getNamedChild('period'), fixed.Period, 'period');
  checkFixedValue(errors, path + '.assigner', focus.getNamedChild('assigner'), fixed.Assigner, 'assigner');
end;

procedure TFHIRInstanceValidator.checkCodingValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRCoding);
begin
  checkFixedValue(errors, path + '.system', focus.getNamedChild('system'), fixed.SystemElement, 'system');
  checkFixedValue(errors, path + '.code', focus.getNamedChild('code'), fixed.CodeElement, 'code');
  checkFixedValue(errors, path + '.display', focus.getNamedChild('display'), fixed.DisplayElement, 'display');
  checkFixedValue(errors, path + '.userSelected', focus.getNamedChild('userSelected'), fixed.UserSelectedElement, 'userSelected');
end;

procedure TFHIRInstanceValidator.checkHumanNameValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRHumanName);
var
  parts: TAdvList<TWrapperElement>;
  i: integer;
begin
  checkFixedValue(errors, path + '.use', focus.getNamedChild('use'), fixed.UseElement, 'use');
  checkFixedValue(errors, path + '.text', focus.getNamedChild('text'), fixed.TextElement, 'text');
  checkFixedValue(errors, path + '.period', focus.getNamedChild('period'), fixed.Period, 'period');

  parts := TAdvList<TWrapperElement>.Create();
  focus.getNamedChildren('family', parts);
  if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, parts.count = fixed.familyList.count, 'Expected ' + inttostr(fixed.familyList.count) + ' but found ' +
    inttostr(parts.count) + ' family elements')) then
  begin
    for i := 0 to parts.count - 1 do
      checkFixedValue(errors, path + '.family', parts[i], fixed.familyList[i], 'family');
  end;
  focus.getNamedChildren('given', parts);
  if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, parts.count = fixed.GivenList.count, 'Expected ' + inttostr(fixed.GivenList.count) + ' but found ' +
    inttostr(parts.count) + ' given elements')) then
  begin
    for i := 0 to parts.count - 1 do
      checkFixedValue(errors, path + '.given', parts[i], fixed.GivenList[i], 'given');
  end;
  focus.getNamedChildren('prefix', parts);
  if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, parts.count = fixed.prefixList.count, 'Expected ' + inttostr(fixed.prefixList.count) + ' but found ' +
    inttostr(parts.count) + ' prefix elements')) then
  begin
    for i := 0 to parts.count - 1 do
      checkFixedValue(errors, path + '.prefix', parts[i], fixed.prefixList[i], 'prefix');
  end;
  focus.getNamedChildren('suffix', parts);
  if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, parts.count = fixed.suffixList.count, 'Expected ' + inttostr(fixed.suffixList.count) + ' but found ' +
    inttostr(parts.count) + ' suffix elements')) then
  begin
    for i := 0 to parts.count - 1 do
      checkFixedValue(errors, path + '.suffix', parts[i], fixed.suffixList[i], 'suffix');
  end;
end;

procedure TFHIRInstanceValidator.checkCodeableConceptValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRCodeableConcept);
var
  codings: TAdvList<TWrapperElement>;
  i: integer;
begin
  checkFixedValue(errors, path + '.text', focus.getNamedChild('text'), fixed.TextElement, 'text');
  codings := TAdvList<TWrapperElement>.Create();
  focus.getNamedChildren('coding', codings);
  if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, codings.count = fixed.CodingList.count, 'Expected ' + inttostr(fixed.CodingList.count) + ' but found ' +
    inttostr(codings.count) + ' coding elements')) then
  begin
    for i := 0 to codings.count - 1 do
      checkFixedValue(errors, path + '.coding', codings[i], fixed.CodingList[i], 'coding');
  end;
end;

procedure TFHIRInstanceValidator.checkTimingValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRTiming);
var
  events: TAdvList<TWrapperElement>;
  i: integer;
begin
  checkFixedValue(errors, path + '.repeat', focus.getNamedChild('repeat'), fixed.repeat_, 'value');

  events := TAdvList<TWrapperElement>.Create();
  focus.getNamedChildren('event', events);
  if (rule(errors, IssueTypeVALUE, focus.locStart(), focus.locEnd(), path, events.count = fixed.eventList.count, 'Expected ' + inttostr(fixed.eventList.count) + ' but found ' +
    inttostr(events.count) + ' event elements')) then
  begin
    for i := 0 to events.count - 1 do
      checkFixedValue(errors, path + '.event', events[i], fixed.eventList[i], 'event');
  end;
end;

procedure TFHIRInstanceValidator.checkPeriodValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRPeriod);
begin
  checkFixedValue(errors, path + '.start', focus.getNamedChild('start'), fixed.StartElement, 'start');
  checkFixedValue(errors, path + '.end', focus.getNamedChild('end'), fixed.End_Element, 'end');
end;

procedure TFHIRInstanceValidator.checkRangeValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRRange);
begin
  checkFixedValue(errors, path + '.low', focus.getNamedChild('low'), fixed.Low, 'low');
  checkFixedValue(errors, path + '.high', focus.getNamedChild('high'), fixed.High, 'high');
end;

procedure TFHIRInstanceValidator.checkRatioValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRRatio);
begin
  checkFixedValue(errors, path + '.numerator', focus.getNamedChild('numerator'), fixed.Numerator, 'numerator');
  checkFixedValue(errors, path + '.denominator', focus.getNamedChild('denominator'), fixed.Denominator, 'denominator');
end;

procedure TFHIRInstanceValidator.checkSampledDataValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRSampledData);
begin
  checkFixedValue(errors, path + '.origin', focus.getNamedChild('origin'), fixed.Origin, 'origin');
  checkFixedValue(errors, path + '.period', focus.getNamedChild('period'), fixed.PeriodElement, 'period');
  checkFixedValue(errors, path + '.factor', focus.getNamedChild('factor'), fixed.FactorElement, 'factor');
  checkFixedValue(errors, path + '.lowerLimit', focus.getNamedChild('lowerLimit'), fixed.LowerLimitElement, 'lowerLimit');
  checkFixedValue(errors, path + '.upperLimit', focus.getNamedChild('upperLimit'), fixed.UpperLimitElement, 'upperLimit');
  checkFixedValue(errors, path + '.dimensions', focus.getNamedChild('dimensions'), fixed.DimensionsElement, 'dimensions');
  checkFixedValue(errors, path + '.data', focus.getNamedChild('data'), fixed.DataElement, 'data');
end;

procedure TFHIRInstanceValidator.checkQuantityValue(errors: TFhirOperationOutcomeIssueList; path: String; focus: TWrapperElement; fixed: TFHIRQuantity);
begin
  checkFixedValue(errors, path + '.value', focus.getNamedChild('value'), fixed.ValueElement, 'value');
  checkFixedValue(errors, path + '.comparator', focus.getNamedChild('comparator'), fixed.ComparatorElement, 'comparator');
  checkFixedValue(errors, path + '.units', focus.getNamedChild('unit'), fixed.Unit_Element, 'units');
  checkFixedValue(errors, path + '.system', focus.getNamedChild('system'), fixed.SystemElement, 'system');
  checkFixedValue(errors, path + '.code', focus.getNamedChild('code'), fixed.CodeElement, 'code');
end;

function TFHIRInstanceValidator.getExtensionByUrl(extensions: TAdvList<TWrapperElement>; url: String): TWrapperElement;
var
  e: TWrapperElement;
begin
  result := nil;
  for e in extensions do
  begin
    if (url = e.getNamedChildValue('url')) then
    begin
      result := e;
    end;
  end;
end;

{ TChildIterator }

constructor TChildIterator.Create(path: String; element: TWrapperElement);
begin
  inherited Create;
  parent := element;
  basePath := path;
end;

function TChildIterator.count: integer;
var
  n: TWrapperElement;
begin
  n := child.getNextSibling();
  if (n <> nil) and (n.getName() = child.getName()) then
    result := lastCount + 1
  else
    result := -1;
end;

function TChildIterator.element: TWrapperElement;
begin
  result := child;
end;

function TChildIterator.name: String;
begin
  result := child.getName();
end;

function TChildIterator.next: boolean;
var
  lastName: String;
begin
  if (child = nil) then
  begin
    child := parent.getFirstChild();
    lastCount := 0;
  end
  else
  begin
    lastName := child.getName();
    child := child.getNextSibling();
    if (child <> nil) and (child.getName() = lastName) then
      inc(lastCount)
    else
      lastCount := 0;
  end;
  result := child <> nil;
end;

function TChildIterator.path: String;
var
  n: TWrapperElement;
  sfx: String;
begin
  n := child.getNextSibling();
  if (parent.isXml()) then
  begin
    sfx := '';
    if (n <> nil) and (n.getName() = child.getName()) then
      sfx := '[' + inttostr(lastCount + 1) + ']';
    if (child.getNamespace = XHTML_NS) then
      result := basePath + '/h:' + name() + sfx
    else
      result := basePath + '/f:' + name() + sfx;
  end
  else
  begin
    sfx := '';
    if (n <> nil) and (n.getName() = child.getName()) then
      sfx := '/' + integer.toString(lastCount + 1);
    result := basePath + '/' + name() + sfx;
  end;
end;

{ TFHIRBaseValidator }

constructor TFHIRBaseValidator.Create;
begin
  inherited;
  FSources := TAdvNameBufferList.create;
  FValidator := TFHIRInstanceValidator.create(self, false);
  FValidator.IsAnyExtensionsAllowed := true;
  FProfiles := TProfileManager.Create;
end;

destructor TFHIRBaseValidator.Destroy;
begin
  FValidator.Free;
  FSources.Free;
  FProfiles.Free;
  inherited;
end;


procedure TFHIRBaseValidator.LoadFromDefinitions(filename: string);
var
  b : TAdvBuffer;
  m : TAdvMemoryStream;
  r : TAdvZipReader;
  i : integer;
  mem : TAdvMemoryStream;
  vcl : TVclStream;
  xml : TFHIRXmlParser;
  v : Variant;
begin

  // read the zip, loading the resources we need
  b := TAdvBuffer.create;
  try
    b.LoadFromFileName(filename);
    m := TAdvMemoryStream.create;
    try
      m.Buffer := b.Link;
      r := TAdvZipReader.create;
      try
        r.Stream := m.Link;
        r.ReadZip;
        for i := 0 to r.Parts.count - 1 do
        begin
          if StringArrayExists(['.xsd', '.xsl', '.xslt', '.sch'], ExtractFileExt(r.Parts[i].Name)) then
            FSources.add(r.Parts[i].Link)
          else if ExtractFileExt(r.Parts[i].Name) = '.xml' then
          begin
            mem := TAdvMemoryStream.create;
            try
              mem.Buffer := r.Parts[i].Link;
              vcl := TVCLStream.create;
              try
                vcl.Stream := mem.link;
                xml := TFHIRXmlParser.create('en');
                try
                  xml.source := vcl;
                  xml.Parse;
                  Load(xml.resource as TFhirBundle);
                finally
                  xml.free;
                end;
              finally
                vcl.free;
              end;
            finally
              mem.free;
            end;
          end;
        end;
      finally
        r.free;
      end;
    finally
      m.free;
    end;
  finally
    b.free;
  end;

  // prep the schemas
  v := CreateOLEObject(GMsXmlProgId_SCHEMA);
  FCache := IUnknown(TVarData(v).VDispatch) as IXMLDOMSchemaCollection;
  FCache.add('http://www.w3.org/XML/1998/namespace', loadDoc('xml.xsd'));
  FCache.add('http://www.w3.org/1999/xhtml', loadDoc('fhir-xhtml.xsd'));
  FCache.add('http://www.w3.org/2000/09/xmldsig#', loadDoc('xmldsig-core-schema.xsd'));
  FCache.add('http://hl7.org/fhir', loadDoc('fhir-single.xsd'));
end;

function TFHIRBaseValidator.Link: TFHIRBaseValidator;
begin
  result := TFHIRBaseValidator(inherited Link);
end;

procedure TFHIRBaseValidator.Load(feed: TFHIRBundle);
var
  i : integer;
  r : TFhirResource;
  p : TFHirStructureDefinition;
begin
  for i := 0 to feed.entryList.count - 1 do
  begin
    r := feed.entryList[i].resource;
    SeeResource(r);
  end;
end;

procedure TFHIRBaseValidator.SeeResource(r : TFHIRResource);
var
  p : TFhirStructureDefinition;
begin
  if r is TFHirStructureDefinition then
  begin
    p := r as TFHirStructureDefinition;
    if FProfiles <> nil then
      FProfiles.SeeProfile(0, p);
  end;
end;

function TrimBof(const s : String):String;
begin
  result := s;
  while (result[1] <> '<') do
    delete(result, 1, 1);
end;

function TFHIRBaseValidator.LoadDoc(name : String; isFree : boolean) : IXMLDomDocument2;
Var
  LVariant: Variant;
  buf : TAdvNameBuffer;
Begin
  buf := FSources.GetByName(name);
  LVariant := LoadMsXMLDomV(isfree);
  Result := IUnknown(TVarData(LVariant).VDispatch) as IXMLDomDocument2;
  result.async := false;
  if isFree then
    result.resolveExternals := true;
  if not result.loadXML(TrimBof(buf.AsUnicode)) then
    raise Exception.create('unable to parse XML because '+result.parseError.reason);
end;

function TFHIRBaseValidator.AcquireContext: TFHIRValidatorContext;
begin
  result := TFHIRValidatorContext.create;
  try
    result.FxmlApp := AltovaXMLLib_TLB.CoApplication.Create;
    result.link;
  finally
    result.free;
  end;
end;

procedure TFHIRBaseValidator.YieldContext(context: TFHIRValidatorContext);
begin
  try
    context.FxmlApp := nil;
  finally
    context.free;
  end;
end;

function TFHIRBaseValidator.validateInstance(context : TFHIRValidatorContext; source: TAdvBuffer; format : TFHIRFormat; opDesc : String; profile : TFHirStructureDefinition): TFHIROperationOutcome;
var
  dom : TIdSoapMSXmlDom;
  json : TJsonObject;
  wrapper : TWrapperElement;
  comp : TFHIRXmlComposer;
  mem : TAdvMemoryStream;
  procedure load;
  var
    mem : TAdvMemoryStream;
    vcl : TVCLStream;
  begin
    mem := TAdvMemoryStream.create;
    try
      mem.Buffer := source.Link;
      vcl := TVCLStream.create;
      try
        vcl.Stream := mem.Link;
        dom.Read(vcl);
      finally
        vcl.free;
      end;
    finally
      mem.free;
    end;
  end;
begin
  result := TFhirOperationOutcome.create;
  try
    if (format = ffXml) then
    begin
      dom := TIdSoapMSXmlDom.create;
      try
        dom.Schemas := FCache;
        load;
        if dom.Root = nil then
        begin
          result.error('Schema', IssueTypeInvalid, 'line '+inttostr(dom.ParseError.line)+', Col '+inttostr(dom.ParseError.linepos), false, dom.ParseError.reason);
          dom.schemas := nil;
          try
            load;
          except
            result.issueList[0].severity := IssueSeverityFatal;
          end;
        end;

        if dom.Root <> nil then
        begin
          // well, we can actually load XML. try the schematrons
//          executeSchematron(context, result, source.AsUnicode, lowercase(dom.Root.Name)+'.sch');
          wrapper := makeSAXWrapperElement(source);
          try
            FValidator.validate(result.issueList, wrapper, profile);
          finally
            wrapper.Free;
          end;
        end;
      finally
        dom.free;
      end
    end
    else if format = ffJson then
    begin
      json := TJSONParser.Parse(source.AsBytes);
      try
        FValidator.validate(result.issueList, json, profile);
      finally
        json.Free;
      end;
    end;
    BuildNarrative(result, opDesc);
    result.Link;
  finally
    result.free;
  end;
end;

procedure TFHIRBaseValidator.validateInstance(op: TFHIROperationOutcome; elem: TIdSoapXmlElement; specifiedprofile : TFHirStructureDefinition);
begin
  FValidator.validate(op.issueList, elem, specifiedprofile);
end;

Function TFHIRBaseValidator.validateInstance(context : TFHIRValidatorContext; elem : TIdSoapXmlElement; opDesc : String; profile : TFHirStructureDefinition) : TFHIROperationOutcome;
begin
  result := TFhirOperationOutcome.create;
  try
    validateInstance(result, elem, profile);
    BuildNarrative(result, opDesc);
    result.link;
  finally
    result.free;
  end;
end;

function TFHIRBaseValidator.validateInstance(context: TFHIRValidatorContext; resource: TFhirResource; opDesc: String; profile: TFHirStructureDefinition): TFHIROperationOutcome;
var
  stream : TBytesStream;
  xml : TFHIRXmlComposer;
  buf : TAdvBuffer;
begin
  stream := TBytesStream.Create(nil);
  try
    xml := TFHIRXmlComposer.Create('en');
    try
      xml.Compose(stream, resource, true, nil);
    finally
      xml.Free;
    end;
    buf := TAdvBuffer.Create;
    try
      buf.AsBytes := copy(stream.Bytes, 0, stream.Size);
      result := validateInstance(context, buf, ffXml, opDesc, profile);
    finally
      buf.Free;
    end;
  finally
    stream.Free;
  end;
end;


procedure TFHIRBaseValidator.processSchematron(op : TFhirOperationOutcome; source : String);
var
  e : IXMLDOMElement;
  issue : TFhirOperationOutcomeIssue;
  ex : TFhirExtension;
  v : Variant;
  doc : IXMLDOMDocument2;
Begin
  v := LoadMsXMLDomV(false);
  doc := IUnknown(TVarData(v).VDispatch) as IXMLDomDocument2;
  doc.async := false;
  if not doc.loadXML(source) then
    raise Exception.create('unable to parse schematron results because '+doc.parseError.reason);

  e := TMsXmlParser.FirstChild(doc.DocumentElement);
  while (e <> nil) do
  begin
    if e.baseName = 'failed-assert' then
    begin
      issue := TFhirOperationOutcomeIssue.create;
      try
        issue.severity := IssueSeverityError;
        issue.code := IssueTypeInvariant;
        issue.details := TFhirCodeableConcept.Create;
        issue.details.text := e.text;
        issue.locationList.Append.value := e.getAttribute('location');
        ex := issue.ExtensionList.Append;
        ex.url := 'http://hl7.org/fhir/tools#issue-source';
        ex.value := TFhirCode.create;
        TFhirCode(ex.value).value := 'Schematron';
        op.issueList.add(issue.link);
      finally
        issue.free;
      end;
    end;
    e := TMsXmlParser.NextSibling(e);
  end;
end;

procedure TFHIRBaseValidator.SetProfiles(const Value: TProfileManager);
begin
  FProfiles.Free;
  FProfiles := Value;
end;

procedure TFHIRBaseValidator.executeSchematron(context : TFHIRValidatorContext; op : TFhirOperationOutcome; source, name: String);
var
  xslt2: AltovaXMLLib_TLB.XSLT2;
  src : String;
  app : AltovaXMLLib_TLB.Application;
begin
  if context <> nil then
    app := context.FxmlApp
  else
    app := AltovaXMLLib_TLB.CoApplication.Create;

  xslt2 := App.XSLT2;
  src := FSources.GetByName(name).AsUnicode;
  xslt2.InputXMLFromText := src;
  xslt2.XSLFileName := IncludeTrailingPathDelimiter(FSchematronSource)+'iso_svrl_for_xslt2.xsl';
  src := xslt2.ExecuteAndGetResultAsString;
  xslt2 := App.XSLT2;
  xslt2.InputXMLFromText := source;
  xslt2.XSLFromText := src;
  processSchematron(op, xslt2.ExecuteAndGetResultAsString);
end;

function TFHIRBaseValidator.fetchResource(t : TFhirResourceType; url : String) : TFhirResource;
begin
  case t of
    frtStructureDefinition : result := FProfiles.ProfileByURL[url];
  else
    result := nil;
  end;
end;


{ TFHIRSaxParser }

constructor TFHIRSaxParser.create;
begin
  inherited;
  FStack := TAdvList<TSAXWrapperElement>.create;
  FRoot := TSAXWrapperElement.Create(nil, '', '');
end;

destructor TFHIRSaxParser.destroy;
begin
  FStack.Free;
  FRoot.Free;
  inherited;
end;

procedure TFHIRSaxParser.startElement(sourceLocation: TSourceLocation; uri, localname: string; attrs: IVBSAXAttributes);
var
  focus : TSAXWrapperElement;
  i : integer;
begin
  if FStack.Count = 0 then
  begin
    FRoot.FNamespace := uri;
    FRoot.FName := localname;
    focus := FRoot;
  end
  else
  begin
    focus := TSAXWrapperElement.Create(FStack[FStack.Count-1], uri, localname);
    FStack[FStack.Count-1].FChildren.add(focus);
  end;
  FStack.Add(focus.Link);

  // SAX reports that the element 'starts' at the end of the element.
  // which is where we want to end it. So we store the last location
  // we saw anything at, and use that instead
  if isNullLoc(FLastStart) then
    focus.FLocationStart := sourceLocation
  else
    focus.FLocationStart := FLastStart;
  focus.FLocationEnd := nullLoc;

  for i := 0 to attrs.length - 1 do
    focus.FAttributes.Add(attrs.getQName(i), attrs.getValue(i));
  FLastStart := nullLoc;
end;

procedure TFHIRSaxParser.endElement(sourceLocation: TSourceLocation);
begin
  // we consider that an element 'ends' where the text or next element
  // starts. That's not strictly true, but gives a better output
  if isNullLoc(FStack[FStack.Count-1].FLocationEnd) then
    FStack[FStack.Count-1].FLocationEnd := sourceLocation;
  FStack.Delete(FStack.Count-1);
  FLastStart := sourceLocation;
end;

procedure TFHIRSaxParser.text(chars: String; sourceLocation: TSourceLocation);
begin
  // we consider that an element 'ends' where the text or next element
  // starts. That's not strictly true, but gives a better output
  if FStack.Count > 0 then
  begin
    if isNullLoc(FStack[FStack.Count-1].FLocationEnd) then
      FStack[FStack.Count-1].FLocationEnd := sourceLocation;
    FStack[FStack.Count-1].FText := FStack[FStack.Count-1].FText + chars;
  end;
  FLastStart := sourceLocation;
end;

end.
