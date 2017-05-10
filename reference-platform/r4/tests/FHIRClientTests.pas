unit FHIRClientTests;

{
Copyright (c) 2011+, HL7 and Health Intersections Pty Ltd (http://www.healthintersections.com.au)
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

{$IFNDEF FHIR3}
// This is the dstu3 version of the FHIR code
{$ENDIF}


interface

uses
//  SysUtils, Classes, Math, RegExpr, Generics.Collections, Character,
//  StringSupport, TextUtilities, SystemSupport, MathSupport,
//  AdvObjects, AdvGenerics, DecimalSupport, DateAndTime,
//  XmlBuilder,
//
//  FHIRBase, FHIRTypes, FHIRResources, FHIRUtilities, FHIRProfileUtilities, FHIRConstants,
//  FHIRParser;
  SysUtils, Classes,
  StringSupport,
  FHIRBase, FHIRTypes, FHIRResources, FHIRConstants, FHIRParser,
  FHIRContext,
  FHIRPath, FHIRTestWorker,
  DUnitX.TestFramework;


Type
  [TextFixture]
  TFHIRClientTests = class (TObject)
  private
    FWorker : TWorkerContext;

  public
    [SetupFixture] procedure setup;
    [TearDownFixture] procedure teardown;

  end;

implementation


{ TFHIRClientTests }
(*
class function TFHIRClientTests.LoadResource(filename: String): TFHIRResource;
var
  f : TFileStream;
  prsr : TFHIRJsonParser;
begin
  f := TFileStream.Create(filename, fmOpenRead + fmShareDenyWrite);
  try
    prsr := TFHIRJsonParser.Create(nil, 'en');
    try
      prsr.source := f;
      prsr.parse;
      result := prsr.resource.Link;
    finally
      prsr.Free;
    end;
  finally
    f.Free;
  end;
end;

class procedure TFHIRClientTests.testClient(client: TFhirClient);
var
  conf : TFHIRConformance;
  patient : TFhirPatient;
  id : string;
  ok : boolean;
begin
  client.conformance(true).Free;
  client.conformance(false).Free;
  patient := LoadResource('C:\work\org.hl7.fhir.old\org.hl7.fhir.dstu2\build\publish\patient-example.json') as TFHIRPatient;
  try
    client.createResource(patient, id);
  finally
    patient.free
  end;
  patient := client.readResource(frtPatient, id) as TFHIRPatient;
  try
    patient.deceased := TFHIRDate.Create(NowUTC);
    client.updateResource(patient);
  finally
    patient.free;
  end;
  ok := false;
  client.deleteResource(frtPatient, id);
  try
    client.readResource(frtPatient, id).Free;
  except
    ok := true;
  end;
  if not ok then
    raise Exception.Create('test failed');
end;

class procedure TFHIRClientTests.tests(url: String);
var
  client : TFhirClient;
begin
  client := TFhirClient.Create(nil, url, true);
  try
    client.UseIndy := true;
    testClient(client);
  finally
    client.free;
  end;
  client := TFhirClient.Create(nil, url, false);
  try
    client.UseIndy := true;
    testClient(client);
  finally
    client.free;
  end;
  client := TFhirClient.Create(nil, url, true);
  try
    client.UseIndy := false;
    testClient(client);
  finally
    client.free;
  end;
  client := TFhirClient.Create(nil, url, false);
  try
    client.UseIndy := false;
    testClient(client);
  finally
    client.free;
  end;
end;

 *)

{ TFHIRClientTests }

procedure TFHIRClientTests.setup;
begin
  FWorker := TTestingWorkerContext.Use;
end;

procedure TFHIRClientTests.teardown;
begin
  FWorker.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TFHIRClientTests);
end.
