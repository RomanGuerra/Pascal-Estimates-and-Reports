// 06-28-2021
///////////////////////////////////////////////////////////////////////////////////
// Name: Report Source Code
// Date Created: 07/01/2021
// Date Revised: 07/01/2021
// Date Distributed: 07/01/2021 5:00 PM
// Created By: Roman Guerra
// Description: This code provides the necessary elements for the reports produced in
// ------------ PlanSwift Takeoff Software. The main purpose of this code is to sum
// ------------ the project's subtotal in 'procedure Memo34OnBeforePrint', and then re-used that total to calculate 
// ------------ indirect cost of the scopes. The scopes are then rounded, and values are
// ------------ displayed in the Report Summary.

// VARIABLES
const
  BandWidth = 100;    // Band Width Constant

  // STRING CONSTANTS
  NAME = 'NAME';
  LOCATION = 'LOCATION';
  SUBLOCATION = 'SUBLOCATION';
  SQFT = 'SQFT';
  SQFT_COST = 'SQFT COST';
  COST = 'COST';
  GREEN_COST = 'GREEN COST';
  PERCENT = 'PERCENT';
  DURATION = 'DURATION';

  // Report Memo Constants 
  REPORT_MEMO_LEFT = 0;
  REPORT_MEMO_WIDTH = 75;                               //
  REPORT_MEMO_HEIGHT = 20;                              // Band Height Constant
  REPORT_HIGHLIGHT_COLOR = $009E6231;                   //
  REPORT_FONT_COLOR = clWhite;                          //
  REPORT_HALIGN = haCenter;                             // 
  REPORT_VALIGN = vaCenter;                             // V Alignment
  REPORT_STYLE = fsBold;                                // Style
  REPORT_FRAME = ftTop + ftLeft + ftRight + ftBottom;   // Frame
  REPORT_FONT_SIZE = 7;                                 // Font Size
  REPORT_TOP_SPACING = 20;

  // REPORT CONSTANTS

  // MEMO CONSTANTS
  MemoHighlight = $00F2F2F2;
  MemoHighlightSecond = clWhite;
  MemoHAlign = haRight;
  MemoNameColor = clInfoBk;

  // ESTIMATE CONSTANTS
  EstimateHighlight = clNone;
  EstimateColor = clGreen;
  EstimateStyle = fsBold;
  EstimateFrame = ftTop + ftLeft + ftRight + ftBottom;



  COLUMNS = 100;       // # of Columns in Report Summary 
  FIELDS = 21;        // # of Fields(Rows) in Report Summary
  SPACE = 20;

var
  // ESTIMATE ACCUMULATION VARIABLES
  AddMaterial, AddLabor, AddEquipment, AddTax, AddTotal, AddGrandTotal, AddSQFT,
  AddDuration, AddMarkup, AddSubTotal, AddPerDiem, AddFuel, AddCertifiedPayRoll,
  AddBondFee, AddC3Cert, AddMisc: single;

  // SCOPE CACULATION VARIABLES
  ScopeTotal, ScopeMarkup, ScopeSubTotal, ScopeIndirectCost, ScopeGrandTotal, ScopePerDiem,
  ScopeFuel, ScopeCertifiedPayroll, ScopeBondFee, ScopeC3Certificate, ScopeMiscellaneous,
  ScopeSQFT, ScopeDuration, ScopeMaterial, ScopeLabor, ScopeEquipment, ScopeTax: single;

  // CONDITION BOOLEAN VARIABLES
  ConditionMaterial, ConditionLabor, ConditionEquipment, ConditionTax, ConditionTotal,
  ConditionMarkupPerc, ConditionMarkup, ConditionSubTotal, ConditionPerDiem, ConditionFuel,
  ConditionCertifiedPayRoll, ConditionBondFee, ConditionC3Cert, ConditionMisc, ConditionSQFT, 
  ConditionSQFTCost, ConditionDuration, ConditionGrandTotal,
  ConditionName, ConditionLocation, ConditionSubLocation: boolean;

  // ESTIMATE JOB VARIABLES       
  TOTAL, MARKUPTOTAL, SUBTOTAL, GRANDTOTAL: single;

  // INDIRECT COST VARIABLES
  PERDIEM, FUEL, CERTIFIEDPAYROLL, BONDFEE, C3CERTIFICATE, MISCELLANEOUS: single;

  // REPORT SUMMARY VARIALBES
  ReportFields:array [1..FIELDS] of string;     // Summary Fields
  MemoLocation:array [0..20] of single;         // Top Position
  Summary: TfrxReportSummary;                   // Summary Band
  Memo: TfrxMemoView;                           // Memo Variable

  BandLeft, BandTop: single;                    // Summary Band Variables
  BandLeftLocation, BandTopNextLocation: single;    // Last Memo Location
  LocationValue, PreviousLocationValue: string;
  SubLocationValue, PreviousSubLocationValue: string;
  BandStartLeftLocation, BandStartTopLocation: single;

  DivisionBreakout, LocationBreakout, SubLocationBreakout: boolean;

  // COUNTER VARIABLES
  text: string;
  i: single;
  j, k, d: integer;
  
  ReportIncrement, ArrayElement, RowCounter, MemoLocationElement: integer;

  // DATASET VARIABLES 
  DataSet: TfrxDataSet;
  // DIVISION VARIABLES
  divisionName:array [0..COLUMNS] of string;             // Scope Name
  divisionGroupName:array [0..COLUMNS] of string;        // Group Name
  divisionLocation:array [0..COLUMNS] of string;         // Location
  divisionSubLocation:array [0..COLUMNS] of string;      // SubLocation
  divisionQualifications:array [0..COLUMNS] of string;   // Qualifications
  divisionExclusions:array [0..COLUMNS] of string;       // Exclusions
  divisionMaterial:array [0..COLUMNS] of single;         // Material
  divisionLabor:array [0..COLUMNS] of single;            // Labor
  divisionEquipment:array [0..COLUMNS] of single;        // Equipment
  divisionTax:array [0..COLUMNS] of single;              // Tax
  divisionTotal:array [0..COLUMNS] of single;            // Total
  divisionMarkupPerc:array [0..COLUMNS] of single;       // Markup %
  divisionMarkup:array [0..COLUMNS] of single;           // Markup
  divisionSubTotal:array [0..COLUMNS] of single;         // SubTotal
  divisionSQFT:array [0..COLUMNS] of single;             // SQ FT
  divisionDuration:array [0..COLUMNS] of single;         // Duration
  divisionPerDiem:array [0..COLUMNS] of single;          // Per Diem
  divisionFuel:array [0..COLUMNS] of single;             // Fuel
  divisionCertifiedPayroll:array [0..COLUMNS] of single; // Certified Payroll
  divisionBondFee:array [0..COLUMNS] of single;          // Bond Fee
  divisionC3Certificate:array [0..COLUMNS] of single;    // C3 Certificate
  divisionMiscellaneous:array [0..COLUMNS] of single;    // Miscellaneous
  divisionAddedCost:array [0..COLUMNS] of single;        // Added Cost
  divisionGrandTotal:array [0..COLUMNS] of single;       // Grand Total
  divisionSQCost:array [0..COLUMNS] of single;           // Cost per SQ FT
  divisionIsScope:array [0..COLUMNS] of boolean;         // Is scope or not
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// Page1OnBeforePrint (SET VARIALBES FUNCTION)
procedure Page1OnBeforePrint(Sender: TfrxComponent);
  begin
    // Set Report Breakout
    DivisionBreakout := false;
    LocationBreakout := true;
    SubLocationBreakout := false;
    
    // Set MemoLocation Array
    MemoLocation[0] := 0;     // PG 1
    MemoLocation[1] := 780;   // PG 2
    MemoLocation[2] := 1560;  // PG 3
    MemoLocation[3] := 2340;  // PG 4
    MemoLocation[4] := 3120;  // PG 5
    MemoLocation[5] := 3900;  // PG 6
    MemoLocation[6] := 4680;  // PG 7
    MemoLocation[7] := 5460;  // PG 8
    MemoLocation[8] := 6270;  // PG 9
    MemoLocation[9] := 7020;  // PG 10
    MemoLocation[10] := 7800; // PG 11

    // Set ReportFields Array
    ReportFields[1] := 'SCOPE';
    ReportFields[2] := 'LOCATION';
    ReportFields[3] := 'SUBLOCATION';
    ReportFields[4] := 'MATERIAL'; 
    ReportFields[5] := 'LABOR'; 
    ReportFields[6] := 'EQUIPMENT'; 
    ReportFields[7] := 'TAX'; 
    ReportFields[8] := 'TOTAL'; 
    ReportFields[9] := 'MARKUP %';
    ReportFields[10] := 'MARKUP'; 
    ReportFields[11] := 'SUBTOTAL';
    ReportFields[12] := 'PER DIEM';    
    ReportFields[13] := 'FUEL';   
    ReportFields[14] := 'C PAYROLL';
    ReportFields[15] := 'BOND FEE'; 
    ReportFields[16] := 'C3 CERT'; 
    ReportFields[17] := 'MISC'; 
    ReportFields[18] := 'SCOPE TOTAL';
    ReportFields[19] := 'SQ FT'; 
    ReportFields[20] := 'COST / SQFT'; 
    ReportFields[21] := 'DURATION';

    // On Final Pass Set Indirect Cost Variables
    if (Engine.FinalPass) then begin
    PERDIEM := PerToDec(ResultAsFloat('Job', 'Per Diem')) * SUBTOTAL;
    FUEL := ResultAsFloat('Job', 'Fuel');
    CERTIFIEDPAYROLL := ResultAsFloat('Job', 'Certified Payroll');
    BONDFEE := ResultAsFloat('Job', 'Bond Fee');
    C3CERTIFICATE := ResultAsFloat('Job', 'C3 Certificate');
    MISCELLANEOUS := ResultAsFloat('Job', 'Miscellaneous');
    end;
    
    // Before Final Pass
    if not (Engine.FinalPass) then begin
    SUBTOTAL := 0;                    // Set SUBTOTAL to 0
    GRANDTOTAL := 0;                  // Set GRANDTOTAL to 0
    DataSet := DetailData1.DataSet;   // Initialize DataSet

    BandTop := 0;                     // Set BandTop to 0
    BandTopNextLocation := 0;         // Set BandTopNextLocation to 0
    end;
    
  end;
///////////////////////////////////////////////////////////////////////////////////

/////////////////////////
// RoundUp - Returns the next rounded whole number. (FUNCTION 1)
function RoundUp(Cost: single):single;
  var
  Value, DecimalValue, RoundedValue: single;
  const
  HALF = 1/2;
  begin
  Value := Cost;
  DecimalValue := Frac(Cost);
  if (DecimalValue <= HALF) then begin             
    Value := Value + HALF;    
    RoundedValue := Round(Value);                                                           
  end;                  
  if (DecimalValue > HALF) then begin                                          
    RoundedValue := Round(Value);                                                        
  end;          
  Result := RoundedValue;
  end;
/////////////////////////

/////////////////////////
// PerToDec - Returns the converted decimal value of a percentage.(FUNCTION 2)
function PerToDec(Percent: single):single;
  const
    HUNDRED = 100;
  begin       
    Result := Percent / HUNDRED;
  end;
/////////////////////////

/////////////////////////
// DirectCost (1.3)
procedure DirectCost();
  begin
    // Set Name, Location, SubLocation, GroupName, Qualifications, Exclusions, Markup %
    divisionName[j] := Copy(<EstData."Division">,6,(Length(<EstData."Division">))); 
    divisionLocation[j] := (<EstData."Location">);
    divisionSubLocation[j] := (<EstData."SubLocation">);
    divisionGroupName[j] := (<EstData."Group Name">);
    divisionQualifications[j] := (<EstData."Qualifications">);
    divisionExclusions[j] := (<EstData."Exclusions">);
    divisionMarkupPerc[j] := (<EstData."Markup %">);
    divisionIsScope[j] := true;

    // Accumulate Direct Cost, Markup, SubTotal, Duration, SQFT, SUBTOTAL
    divisionMaterial[j] := divisionMaterial[j] + (<EstData."Material Total">);
    divisionLabor[j] := divisionLabor[j] + (<EstData."Labor Total">);
    divisionEquipment[j] := divisionEquipment[j] + (<EstData."Equipment Total">);
    divisionTax[j] := divisionTax[j] + (<EstData."Tax">);
    divisionTotal[j] := divisionTotal[j] + (<EstData."Total">);
    divisionMarkup[j] := divisionMarkup[j] + ((<EstData."Total">) * PerToDec((<EstData."Markup %">))); 
    divisionSubTotal[j] := divisionSubTotal[j] + ((<EstData."Total">) + ((<EstData."Total">) * PerToDec((<EstData."Markup %">))));
    divisionDuration[j] := divisionDuration[j] + (<EstData."Duration">);
    divisionSQFT[j] := divisionSQFT[j] + (<EstData."SQ FT">);
    SUBTOTAL := SUBTOTAL + ((<EstData."Total">) + ((<EstData."Total">) * PerToDec((<EstData."Markup %">))));
  end;
/////////////////////////

/////////////////////////
// AltDirectCost (2.3)
procedure AltDirectCost();
  begin
    // Set Name, Location, SubLocation, GroupName, Qualifications, Exclusions, Markup %
    divisionName[j] := Copy(<EstData."Division">,6,(Length(<EstData."Division">))); 
    divisionLocation[j] := (<EstData."Location">);
    divisionSubLocation[j] := (<EstData."SubLocation">);
    divisionGroupName[j] := (<EstData."Group Name">);
    divisionQualifications[j] := (<EstData."Qualifications">);
    divisionExclusions[j] := (<EstData."Exclusions">);
    divisionMarkupPerc[j] := (<EstData."Markup %">);
    divisionIsScope[j] := false;

    // Accumulate Direct Cost, Markup, SubTotal, Duration, SQFT
    divisionMaterial[j] := divisionMaterial[j] + (<EstData."Material Total">);
    divisionLabor[j] := divisionLabor[j] + (<EstData."Labor Total">);
    divisionEquipment[j] := divisionEquipment[j] + (<EstData."Equipment Total">);
    divisionTax[j] := divisionTax[j] + (<EstData."Tax">);
    divisionTotal[j] := divisionTotal[j] + (<EstData."Total">);
    divisionMarkup[j] := divisionMarkup[j] + ((<EstData."Total">) * PerToDec((<EstData."Markup %">))); 
    divisionSubTotal[j] := divisionSubTotal[j] + ((<EstData."Total">) + ((<EstData."Total">) * PerToDec((<EstData."Markup %">))));
    divisionDuration[j] := divisionDuration[j] + (<EstData."Duration">);
    divisionSQFT[j] := divisionSQFT[j] + (<EstData."SQ FT">);
  end;
/////////////////////////

/////////////////////////
// IndirectCost (1.9)
procedure IndirectCost();
  begin
    // Indirect Cost Calculations
    divisionPerDiem[j] := divisionPerDiem[j] + ScopePerDiem;
    divisionFuel[j] := divisionFuel[j] + ScopeFuel;
    divisionCertifiedPayroll[j] := divisionCertifiedPayroll[j] + ScopeCertifiedPayroll;
    divisionBondFee[j] := divisionBondFee[j] + ScopeBondFee;
    divisionC3Certificate[j] := divisionC3Certificate[j] + ScopeC3Certificate;
    divisionMiscellaneous[j] := divisionMiscellaneous[j] + ScopeMiscellaneous;  
    divisionAddedCost[j] := divisionAddedCost[j] + ScopeIndirectCost;
    divisionGrandTotal[j] := divisionSubTotal[j] + divisionAddedCost[j];
    divisionSQCost[j] := divisionGrandTotal[j] / divisionSQFT[j];  
  end;
/////////////////////////

/////////////////////////
// AltIndirectCost (2.6)
procedure AltIndirectCost();
  var 
  tempValue, tempRound: single;
  begin
    // Indirect Cost Set to 0
    divisionPerDiem[j] := 0;
    divisionFuel[j] := 0;
    divisionCertifiedPayroll[j] := 0;
    divisionBondFee[j] := 0;
    divisionC3Certificate[j] := 0;
    divisionMiscellaneous[j] := 0;  
    divisionAddedCost[j] := 0;

    // Set GrandTotal
    divisionGrandTotal[j] := divisionSubTotal[j]; 
  end;
/////////////////////////

/////////////////////////
// CalculateScopeValues - Calculates cost for scope variables. (2.1)
procedure CalculateScopeValues();
  begin
    // Scope Direct Cost 
    ScopeMaterial := (<EstData."Material Total">);
    ScopeEquipment := (<EstData."Equipment Total">);
    ScopeLabor := (<EstData."Labor Total">);
    ScopeTax := (<EstData."Tax">);
    ScopeTotal := (<EstData."Total">); 
    ScopeMarkup := (<EstData."Total">) * PerToDec((<EstData."Markup %">));
    ScopeSubTotal := ScopeTotal + ScopeMarkup; 
    ScopeSQFT := (<EstData."SQ FT">);
    ScopeDuration := (<EstData."Duration">);   
    ScopePerDiem := (ScopeSubTotal / SUBTOTAL) * PERDIEM;
    ScopeFuel := (ScopeSubTotal / SUBTOTAL) * FUEL;
    ScopeCertifiedPayroll := (ScopeSubTotal / SUBTOTAL) * CERTIFIEDPAYROLL;
    ScopeBondFee := (ScopeSubTotal / SUBTOTAL) * BONDFEE;
    ScopeC3Certificate := (ScopeSubTotal / SUBTOTAL) * C3CERTIFICATE;
    ScopeMiscellaneous := (ScopeSubTotal / SUBTOTAL) * MISCELLANEOUS;
    ScopeIndirectCost := ScopePerDiem + ScopeFuel + ScopeCertifiedPayroll + ScopeBondFee + ScopeC3Certificate + ScopeMiscellaneous;
    ScopeGrandTotal := ScopeSubTotal + ScopeIndirectCost;
  end;
/////////////////////////

/////////////////////////
// AccumulateEstimateValues - Accumulates all estimate variables.(2.2)
procedure AccumulateEstimateValues();
  begin
    // Accumulate Estimate Values                
    AddMaterial := AddMaterial + ScopeMaterial;
    AddLabor := AddLabor + ScopeLabor;
    AddEquipment := AddEquipment + ScopeEquipment;
    AddTax := AddTax + ScopeTax;
    AddTotal := AddTotal + ScopeTotal;
    AddMarkup := AddMarkup + ScopeMarkup;
    AddSubTotal := AddSubTotal + ScopeSubTotal; 
    AddPerDiem := AddPerDiem + ScopePerDiem;
    AddFuel := AddFuel + ScopeFuel;
    AddCertifiedPayRoll := AddCertifiedPayRoll + ScopeCertifiedPayroll;
    AddBondFee := AddBondFee + ScopeBondFee;
    AddC3Cert := AddC3Cert + ScopeC3Certificate;
    AddMisc := AddMisc + ScopeMiscellaneous;
    AddSQFT := AddSQFT + ScopeSQFT;
    AddDuration := AddDuration + ScopeDuration;
    AddGrandTotal := AddGrandTotal + divisionGrandTotal[j]; 
  end;
/////////////////////////

/////////////////////////
// EstimateBooleanValues (2.2)
procedure EstimateBooleanValues();
  begin
    // Check if Estimate boolean values are true or false.
    ConditionName := True;
    ConditionLocation := True;
    ConditionSubLocation := True;
    ConditionMaterial := CheckBooleanValues(AddMaterial);
    ConditionLabor := CheckBooleanValues(AddLabor);
    ConditionEquipment := CheckBooleanValues(AddEquipment);
    ConditionTax := CheckBooleanValues(AddTax);
    ConditionTotal := CheckBooleanValues(AddTotal);
    ConditionMarkupPerc := CheckBooleanValues(AddMarkup);
    ConditionMarkup := CheckBooleanValues(AddMarkup);
    ConditionSubTotal := CheckBooleanValues(AddSubTotal); 
    ConditionPerDiem := CheckBooleanValues(AddPerDiem);
    ConditionFuel := CheckBooleanValues(AddFuel);
    ConditionCertifiedPayRoll := CheckBooleanValues(AddCertifiedPayRoll);
    ConditionBondFee := CheckBooleanValues(AddBondFee);
    ConditionC3Cert := CheckBooleanValues(AddC3Cert);
    ConditionMisc := CheckBooleanValues(AddMisc);
    ConditionSQFT := CheckBooleanValues(AddSQFT);
    ConditionSQFTCost := CheckBooleanValues(AddSQFT);
    ConditionDuration := CheckBooleanValues(AddDuration);
    ConditionGrandTotal := CheckBooleanValues(AddGrandTotal); 
  end;
/////////////////////////

/////////////////////////
// CheckBooleanValues
function CheckBooleanValues(value: single):boolean;
  var
  condition: boolean;             // Variable
  begin
    condition := false;           // Set condition to false
    if not (value = 0) then begin // If value is not equal to zero.
      condition := true;          // Set condition to true
    end;
    Result := condition;          // Return condition
  end;
/////////////////////////

/////////////////////////
// FirstPass - Calls first pass functions & procedures (1.1)
procedure FirstPass();
  begin      
    if not (Engine.FinalPass) then begin    // If not engine final pass then
      CounterFirstPass();                   // Call CounterFirstPass()
      DirectCost();                         // Call DirectCost()
    end;  
  end;
/////////////////////////

/////////////////////////
// AltFirstPass - Calls first pass functions & procedures (2.1)
procedure AltFirstPass();
  begin      
    if not (Engine.FinalPass) then begin    // If not engine final pass then
      CounterFirstPass();                   // Call CounterFirstPass()
      AltDirectCost();                      // Call DirectCost()
    end;  
  end;
/////////////////////////

/////////////////////////
// SecondPass - Calls second pass functions & procedures (2.4)
procedure SecondPass();
  begin     
    if (Engine.FinalPass) then begin    // If Engine Final Pass then
      ResetCounter();
      CalculateScopeValues();                          // Call CalculateScopeValues()
      IndirectCost();                                  // Call IndirectCost()
      AccumulateEstimateValues();                      // AccumulateEstimateValues()
    end;
  end;
/////////////////////////

/////////////////////////
// SecondPass - Calls second pass functions & procedures (2.4)
procedure AltSecondPass();
  begin     
    if (Engine.FinalPass) then begin    // If Engine Final Pass then
      ResetCounter();
      AltIndirectCost();                               // Call IndirectCost()
    end;
  end;
/////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// CreateFieldSummary (FIELD SUMMARY)
// Description: Function handles first pass calculations.
///////////////////////////////////////////////////////////////////////////////////
procedure CreateSummaryColumn();
  var
  FirstField, SecondField: boolean;
  SetToZero: boolean;
  Count: integer;
  TempVal: single;

  begin         

    // Create Report Summary Band
    Summary := TfrxReportSummary.Create(Page2);
    Summary.Height := 20; 
    
    // Set Summary Band Field Variables
    BandLeft := 0;

    if (FirstField) then begin
      BandTop := BandTopNextLocation;
    end;

    if (SecondField) then begin
      BandTop := MemoLocation[MemoLocationElement];
    end;

    if not (SetToZero) then begin
      MemoLocationElement := 0;
      SetToZero := true;
    end;
    if (FirstField = true) and (SecondField = true) then begin
      FirstField := false;
      SecondField := false;
    end;

    if (RowCounter > 18) then begin
      BandTop := BandTopNextLocation;
    end;

    RowCounter := 0;
    ArrayElement := 1;


    CreateColumnConditionMemo(ConditionName);              // SCOPE
    CreateColumnConditionMemo(ConditionLocation);          // LOCATION
    CreateColumnConditionMemo(ConditionSubLocation);       // SUBLOCATION
    CreateColumnConditionMemo(ConditionMaterial);          // MATERIAL
    CreateColumnConditionMemo(ConditionLabor);             // LABOR
    CreateColumnConditionMemo(ConditionEquipment);         // EQUIPMENT
    CreateColumnConditionMemo(ConditionTax);               // TAX
    CreateColumnConditionMemo(ConditionTotal);             // TOTAL
    CreateColumnConditionMemo(ConditionMarkupPerc);        // MARKUP %
    CreateColumnConditionMemo(ConditionMarkup);            // MARKUP
    CreateColumnConditionMemo(ConditionSubTotal);          // SUBTOTAL
    CreateColumnConditionMemo(ConditionPerDiem);           // PERDIEM
    CreateColumnConditionMemo(ConditionFuel);              // FUEL
    CreateColumnConditionMemo(ConditionCertifiedPayRoll);  // CERTIFIEDPAYROLL
    CreateColumnConditionMemo(ConditionBondFee);           // BONDFEE
    CreateColumnConditionMemo(ConditionC3Cert);            // C3CERTIFICATE
    CreateColumnConditionMemo(ConditionMisc);              // MISCELLANEOUS
    CreateColumnConditionMemo(ConditionGrandTotal);        // SCOPE
    CreateColumnConditionMemo(ConditionSQFT);              // SQFT TOTAL
    CreateColumnConditionMemo(ConditionSQFTCost);          // COST PER SQFT
    CreateColumnConditionMemo(ConditionDuration);          // DURATION

    // Field Count Less than or equal to 18
    if (RowCounter <= 18) then begin

      if (FirstField) then begin
        SecondField := true; //
        Inc(MemoLocationElement); //
        BandStartTopLocation := BandTopNextLocation; //
        BandLeft := -25; //
      end;

      if not (FirstField) then begin
        FirstField := true; //
        BandTop := BandTop + SPACE; //
        BandTopNextLocation := BandTop; //
        BandLeft := -25; //
        BandStartTopLocation := MemoLocation[MemoLocationElement]; //
      end;
    end;

    // Field Count Greater than 18
    if (RowCounter > 18) then begin
      BandStartTopLocation := MemoLocation[MemoLocationElement];
      Inc(MemoLocationElement);
      BandTopNextLocation := MemoLocation[MemoLocationElement];
      BandTop := BandTopNextLocation;
      BandLeft := -25;
    end;        

                            
  end;
///////////////////////////////////////////////////////////////////////////////////

/////////////////////////
// CreateColumnConditionMemo
procedure CreateColumnConditionMemo(ConditionValue: boolean);
  begin
    if (ConditionValue) then begin
      Memo := TfrxMemoView.Create(ReportSummary);
      Memo.SetBounds(REPORT_MEMO_LEFT, BandTop, REPORT_MEMO_WIDTH, REPORT_MEMO_HEIGHT);
      Memo.Text := ReportFields[ArrayElement];
      Memo.Color := REPORT_HIGHLIGHT_COLOR;
      Memo.Font.Color := REPORT_FONT_COLOR;
      Memo.HAlign := REPORT_HALIGN;
      Memo.VAlign := REPORT_VALIGN;
      Memo.Font.Style := REPORT_STYLE;
      Memo.Frame.Typ := REPORT_FRAME;
      Memo.Font.Size := REPORT_FONT_SIZE;     
      BandTop := BandTop + REPORT_TOP_SPACING;
      Inc(RowCounter);  
    end;
      Inc(ArrayElement);                      
  end;
/////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// CreateField - Calls other procedures to create a cost summary in the Report Summary
procedure CreateField();
  begin                 
    // Memo Fields
    BandLeft := BandLeft + 100;
    BandTop := BandStartTopLocation;

    // Procedures
    CreateTitleMemo(divisionName, ConditionName, Name);
    CreateTitleMemo(divisionLocation, ConditionLocation, LOCATION);
    CreateTitleMemo(divisionSubLocation, ConditionSubLocation, SUBLOCATION);

    iValueReset();

    CreateMemo(divisionMaterial, ConditionMaterial, COST);
    CreateMemo(divisionLabor, ConditionLabor, COST);
    CreateMemo(divisionEquipment, ConditionEquipment, COST);
    CreateMemo(divisionTax, ConditionTax, COST);
    CreateMemo(divisionTotal, ConditionTotal, COST);
    CreateMemo(divisionMarkupPerc, ConditionMarkupPerc, PERCENT);
    CreateMemo(divisionMarkup, ConditionMarkup, COST);  
    CreateMemo(divisionSubTotal, ConditionSubTotal, COST);

    CreateMemo(divisionPerDiem, ConditionPerDiem, COST);
    CreateMemo(divisionFuel, ConditionFuel, COST); 
    CreateMemo(divisionCertifiedPayroll, ConditionCertifiedPayRoll, COST); 
    CreateMemo(divisionBondFee, ConditionBondFee, COST); 
    CreateMemo(divisionC3Certificate, ConditionC3Cert, COST);
    CreateMemo(divisionMiscellaneous, ConditionMisc, COST);

    CreateMemo(divisionGrandTotal, ConditionGrandTotal, GREEN_COST);
    CreateMemo(divisionSQFT, ConditionSQFT, SQFT);
    CreateMemo(divisionSQCost, ConditionSQFT, SQFT_COST);
    CreateMemo(divisionDuration, ConditionDuration, DURATION);
  end;
///////////////////////////////////////////////////////////////////////////////////

// CreateTitleMemo()
procedure CreateTitleMemo(value: array of string; boolValue: boolean; text: string);
  begin
    if (boolValue) then begin
      Memo := TfrxMemoView.Create(ReportSummary);
      Memo.SetBounds(BandLeft, BandTop, BandWidth, REPORT_MEMO_HEIGHT);
      Memo.Text := value[j];
      Memo.Color := clInfoBk;

      Memo.HAlign := MemoHAlign;
      Memo.Font.Style := fsBold;
      Memo.Font.Size := 6;
      BandTop := BandTop + 20; 

      //if (text = 'SQFT') then begin
      //end else if (text = 'SQFT COST') then begin
      //end;
      
      EstimateMemo();
    end;
  end;

// CreateMemo()
procedure CreateMemo(ArrayValue: array of single; boolValue: boolean; text: string);
  begin
    if (boolValue) then begin
      Memo := TfrxMemoView.Create(ReportSummary);
      Memo.SetBounds(BandLeft, BandTop, BandWidth, REPORT_MEMO_HEIGHT);
      Memo.HAlign := haRight;
      Memo.Frame.Typ := ftTop;        
      BandTop := BandTop + 20; 
      HighlightMemo();
      

      if (text = 'SQFT') then begin
        Memo.Text := FormatFloat('#,###,##0. SQFT', ArrayValue[j]);

      end else if (text = 'SQFT COST') then begin
        Memo.Text := FormatFloat('$#,###,##0.00 / SQFT', ArrayValue[j]);

      end else if (text = 'DURATION') then begin
        Memo.Text := FormatFloat('#,###,##0.00 WK', ArrayValue[j]);

      end else if (text = 'COST') then begin
        Memo.Text := FormatFloat('$#,###,##0.00', ArrayValue[j]);
        if (ArrayValue[j] < 0) then begin
          Memo.Font.Color := clRed;
        end; 

      end else if (text = 'GREEN COST') then begin
        Memo.Text := FormatFloat('$#,###,##0.00', ArrayValue[j]);
        Memo.Font.Style := fsBold;
        Memo.Font.Color := clGreen;
        if (ArrayValue[j] < 0) then begin
          Memo.Font.Color := clRed;
        end; 

      end else if (text = 'PERCENT') then begin
        Memo.Text := FormatFloat('#0.## %', ArrayValue[j]);
        Memo.Font.Color := clRed;
        Memo.Font.Style := fsBold;
      end;
      
      EstimateMemo();
    end;
  end;

// HighlightMemo
procedure HighlightMemo();
  begin
    i := i + 0.5;
    if (round(i) = i) then
      Memo.Color := $00F2F2F2            
    else
      Memo.Color := clWhite;
  end;

// EstimateMemo
procedure EstimateMemo();
  begin
    if (j = 0) then begin
      Memo.Color := EstimateHighlight;
      Memo.Font.Color := EstimateColor;
      Memo.Font.Style := EstimateStyle;
      Memo.Frame.Typ := EstimateFrame;
    end;     
  end;

/////////////////////////
// CounterFirstPass - Sets & increments j variable on FirstPass (1.2) (2.2)
procedure CounterFirstPass();
  var
  SetCounter: boolean;
  SecondPassDivValue, SecondPassPreviousDivValue: string;
  SecondPassDivNumValue, SecondPassPreviousDivNumValue: string;
  SecondPassLocValue, SecondPassPreviousLocValue: string;
  SecondPassSubValue, SecondPassPreviousSubValue: string;
  StringValueChanged: boolean;
  begin
    if (SetCounter) then begin
      SecondPassDivValue := (<EstData."Division">);
      SecondPassDivNumValue := (<EstData."Division #">);
      SecondPassLocValue := (<EstData."Location">);
      SecondPassSubValue := (<EstData."SubLocation">);

      if (DivisionBreakout) then begin
        if not (SecondPassDivValue = SecondPassPreviousDivValue) or not (SecondPassDivNumValue = SecondPassPreviousDivNumValue) then begin
          Inc(j);
          SecondPassPreviousDivValue := (<EstData."Division">);
          SecondPassPreviousDivNumValue := (<EstData."Division #">);
          SecondPassPreviousLocValue := (<EstData."Location">);
          SecondPassPreviousSubValue := (<EstData."SubLocation">);
        end;
      end;
      if (LocationBreakout) then begin
        if not (SecondPassDivValue = SecondPassPreviousDivValue) or not (SecondPassDivNumValue = SecondPassPreviousDivNumValue) or not (SecondPassLocValue = SecondPassPreviousLocValue) then begin
          Inc(j);
          SecondPassPreviousDivValue := (<EstData."Division">);
          SecondPassPreviousDivNumValue := (<EstData."Division #">);
          SecondPassPreviousLocValue := (<EstData."Location">);
          SecondPassPreviousSubValue := (<EstData."SubLocation">);
        end;
      end;
      if (SubLocationBreakout) then begin
        if not (SecondPassDivValue = SecondPassPreviousDivValue) or not (SecondPassDivNumValue = SecondPassPreviousDivNumValue) or not (SecondPassLocValue = SecondPassPreviousLocValue) or not (SecondPassSubValue = SecondPassPreviousSubValue)  then begin
          Inc(j);
          SecondPassPreviousDivValue := (<EstData."Division">);
          SecondPassPreviousDivNumValue := (<EstData."Division #">);
          SecondPassPreviousLocValue := (<EstData."Location">);
          SecondPassPreviousSubValue := (<EstData."SubLocation">);
        end;
      end;
        
    end;  

    while not (SetCounter) do begin            
      j := 1;
      SecondPassPreviousDivValue := (<EstData."Division">);
      SecondPassPreviousDivNumValue := (<EstData."Division #">);
      SecondPassPreviousLocValue := (<EstData."Location">);
      SecondPassPreviousSubValue := (<EstData."SubLocation">);
      SetCounter := true;
    end;                                            
  end;
/////////////////////////

/////////////////////////
// ResetCounter - Resets j variable on SecondPass (2.5)
procedure ResetCounter();
  var
  ResetCounter: boolean;
  SecondPassDivValue, SecondPassPreviousDivValue: string;
  SecondPassDivNumValue, SecondPassPreviousDivNumValue: string;
  SecondPassLocValue, SecondPassPreviousLocValue: string;
  SecondPassSubValue, SecondPassPreviousSubValue: string;
  SecondPassStringValueChanged: boolean;
  begin

  if (ResetCounter) then begin
    SecondPassDivValue := (<EstData."Division">);
    SecondPassDivNumValue := (<EstData."Division #">);
    SecondPassLocValue := (<EstData."Location">);
    SecondPassSubValue := (<EstData."SubLocation">);

      if (DivisionBreakout) then begin
        if not (SecondPassDivValue = SecondPassPreviousDivValue) or not (SecondPassDivNumValue = SecondPassPreviousDivNumValue) then begin
          Inc(j);
          Inc(k);
          SecondPassPreviousDivValue := (<EstData."Division">);
          SecondPassPreviousDivNumValue := (<EstData."Division #">);
          SecondPassPreviousLocValue := (<EstData."Location">);
          SecondPassPreviousSubValue := (<EstData."SubLocation">);
        end;
      end;
      if (LocationBreakout) then begin
        if not (SecondPassDivValue = SecondPassPreviousDivValue) or not (SecondPassDivNumValue = SecondPassPreviousDivNumValue) or not (SecondPassLocValue = SecondPassPreviousLocValue) then begin
          Inc(j);
          Inc(k);
          SecondPassPreviousDivValue := (<EstData."Division">);
          SecondPassPreviousDivNumValue := (<EstData."Division #">);
          SecondPassPreviousLocValue := (<EstData."Location">);
          SecondPassPreviousSubValue := (<EstData."SubLocation">);
        end;
      end;
      if (SubLocationBreakout) then begin
        if not (SecondPassDivValue = SecondPassPreviousDivValue) or not (SecondPassDivNumValue = SecondPassPreviousDivNumValue) or not (SecondPassLocValue = SecondPassPreviousLocValue) or not (SecondPassSubValue = SecondPassPreviousSubValue)  then begin
          Inc(j);
          Inc(k);
          SecondPassPreviousDivValue := (<EstData."Division">);
          SecondPassPreviousDivNumValue := (<EstData."Division #">);
          SecondPassPreviousLocValue := (<EstData."Location">);
          SecondPassPreviousSubValue := (<EstData."SubLocation">);
        end;
      end;
  end;  

  while not (ResetCounter) do begin            
    j := 1;
    k := 1;
    SecondPassPreviousDivValue := (<EstData."Division">);
    SecondPassPreviousDivNumValue := (<EstData."Division #">);
    SecondPassPreviousLocValue := (<EstData."Location">);
    SecondPassPreviousSubValue := (<EstData."SubLocation">);
    ResetCounter := true;
  end;   
                                        
  end;
/////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// iValueReset - Resets integer value to 0
procedure iValueReset();
  begin
    i := 0;                               
  end;
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// Memo34OnBeforePrint
procedure Memo34OnBeforePrint(Sender: TfrxComponent);
  begin
    // Estimate Cost                                   
    //GRANDTOTAL := 0;                                                                                                                  
  end;
///////////////////////////////////////////////////////////////////////////////////

/////////////////////////
// ScopeFunctions - Estimate Scope Calls (1.0)
procedure ScopeFunctions();
  begin
    FirstPass();
    SecondPass();                               
  end;
/////////////////////////

/////////////////////////
// AltFunctions - Estimate Scope Calls (2.0)
procedure AltFunctions();
  begin
    AltFirstPass();
    AltSecondPass();                               
  end;
/////////////////////////

/////////////////////////
// DetailData1OnBeforePrint - Process Report
procedure DetailData1OnBeforePrint(Sender: TfrxComponent);
  begin       
    if (Copy(<EstData."Division">,1,2) = '01') then begin           // STONE
      ScopeFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '02') then begin  // BRICK
      ScopeFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '03') then begin  // CMU
      ScopeFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '04') then begin  // CAST STONE
      ScopeFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '05') then begin  // STUCCO
      ScopeFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '06') then begin  // EIFS
      ScopeFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '07') then begin  // NICHIHA
      ScopeFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '08') then begin  // Alternates
      AltFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '09') then begin  // Alternates
      AltFunctions()
    end else if (Copy(<EstData."Division">,1,2) = '10') then begin  // Alternates
      AltFunctions()
    end;
  end;
/////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// Estimate
procedure Estimate();
  begin
    j := 0;
    divisionName[0] := 'ESTIMATE';
    divisionLocation[0] := ResultAsString('Job', 'Project');
    divisionSubLocation[0] := ResultAsString('Job', 'Project Location');
    divisionMaterial[0] := AddMaterial;
    divisionLabor[0] := AddLabor;
    divisionEquipment[0] := AddEquipment;
    divisionTax[0] := AddTax;
    divisionTotal[0] := AddTotal;
    divisionMarkup[0] := AddMarkup;
    divisionSubTotal[0] := SUBTOTAL;
    divisionSQFT[0] := AddSQFT;
    divisionDuration[0] := AddDuration;
    divisionPerDiem[0] := AddPerDiem;
    divisionFuel[0] := AddFuel;
    divisionCertifiedPayroll[0] := AddCertifiedPayRoll;
    divisionBondFee[0] := AddBondFee;
    divisionC3Certificate[0] := AddC3Cert;
    divisionMiscellaneous[0] := AddMisc;
    divisionGrandTotal[0] := GRANDTOTAL;
    divisionMarkupPerc[0] := (AddMarkup /AddTotal) * 100;
    divisionSQCost[0] := GRANDTOTAL / AddSQFT;
    

    CreateField();  
  end;
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// Estimate
procedure QE_Memo();
  begin
    BandTop := BandStartTopLocation;
    Memo := TfrxMemoView.Create(ReportSummary);
    Memo.SetBounds(200, (BandTop), 750, 100);
    Memo.Font.Size := 8;
    Memo.StretchMode := smMaxHeight;
    Memo.AllowHTMLTags := true;
    for j := 1 to k do begin  
      text := '<b><font color=blue>' + divisionName[j] + '</font><font color=green> ' + divisionLocation[j] + ' ' + divisionSubLocation[j] + '</b></font>';
      Memo.Memo.Add(text);
      text := '<b>Qualifications: </b>' + divisionQualifications[j];
      Memo.Memo.Add(text);
      text := '<b>Exclusions: </b>' + divisionExclusions[j];
      Memo.Memo.Add(text);
      text := '';
      Memo.Memo.Add(text);
    end;
  end;
///////////////////////////////////////////////////////////////////////////////////

// RoundValues()
procedure RoundValues();
  var
  tempValue, tempRound: single;

  begin
    for j := 1 to k do begin
      tempValue := divisionGrandTotal[j];
      tempRound := RoundUp(tempValue);
      divisionGrandTotal[j] := tempRound;
      if (divisionIsScope[j]) then begin
        GRANDTOTAL := GRANDTOTAL + divisionGrandTotal[j];
      end;
    end;
  end;
// 
procedure ReportSummaryOnBeforePrint(Sender: TfrxComponent);
  var
  ReportSummaryCreated: boolean;
  //tempValue, tempRound: single;
begin

  RoundValues();

  if (DataSet.Eof and Engine.FinalPass) and not (ReportSummaryCreated) then begin
    
    // Check Conditions
    EstimateBooleanValues();

    // Set R to 1
    ReportIncrement := 0;
    // Create Report Summary Fields
    CreateSummaryColumn();
    // For Loop
    for j := 1 to k do begin       
      // Create New Column
      if (ReportIncrement = 9) then begin
        CreateSummaryColumn();
        ReportIncrement := 0;
      end; 

      // Create Field & Increment R
      Inc(ReportIncrement);    
      CreateField();                    
    end;

    // Create Estimate
    ReportFields[18] := 'GRANDTOTAL';
    CreateSummaryColumn();
    Estimate();

    // Set Variable to True
    ReportSummaryCreated := true;

    // Q & E
    QE_Memo();

  end;
end;
///////////////////////////////////////////////////////////////////////////////////



begin
end.