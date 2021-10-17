// TEST ESTIMATE
// 06-28-2021
///////////////////////////////////////////////////////////////////////////////////
// VARIABLES
const
  COLUMNS = 100;       // # of Columns in Report Summary 
  FIELDS = 21;        // # of Fields(Rows) in Report Summary
  SPACE = 20;

var
  // ESTIMATE ACCUMULATION VARIABLES
  AddMaterial, AddLabor, AddEquipment, AddTax, AddTotal, AddGrandTotal, AddSQFT,
  AddDuration, AddMarkup, AddSubTotal, AddPerDiem, AddFuel, AddCertifiedPayRoll,
  AddBondFee, AddC3Cert, AddMisc: single;

  // Variables To Handle Height in Report Summary  
  First_Height, New_Height: single;
  Group_Total, Group_Value, Group_ValueHolder: single;

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
  TOTAL, MARKUPTOTAL, SUBTOTAL, GROUPTOTAL, GRANDTOTAL: single;

  // INDIRECT COST VARIABLES
  PERDIEM, FUEL, CERTIFIEDPAYROLL, BONDFEE, C3CERTIFICATE, MISCELLANEOUS: single;

  // REPORT SUMMARY VARIALBES
  ReportFields:array [1..FIELDS] of string;     // Summary Fields
  MemoLocation:array [0..20] of single;         // Top Position
  Summary: TfrxReportSummary;                   // Summary Band
  Memo: TfrxMemoView;                           // Memo Variable

  LocationValue, PreviousLocationValue: string;
  SubLocationValue, PreviousSubLocationValue: string;

  DivisionBreakout, LocationBreakout, SubLocationBreakout: boolean;
  DisplayGroupName, DisplayGroupTotal, DisplayBudget, DisplayTerms: boolean; 

  // COUNTER VARIABLES
  text: string;
  i: single;
  j, k, d, GroupCounter: integer;
  
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
  divisionUseGroupName:array [0..COLUMNS] of boolean;         // 
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
// Page1OnBeforePrint (SET VARIALBES FUNCTION)
procedure Page1OnBeforePrint(Sender: TfrxComponent);
  begin
    // Set Report Breakout
    DivisionBreakout := false;
    LocationBreakout := true;
    SubLocationBreakout := false;

    // Job Properties
    //DisplayGroupName := ResultAsBoolean('Job', 'DISPLAY');
    DisplayGroupTotal := ResultAsBoolean('Job', 'Display Group Total');
    DisplayBudget := ResultAsBoolean('Job', 'Display Budget');
    DisplayTerms := ResultAsBoolean('Job', 'Display Terms and Conditions');
    

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
    GROUPTOTAL := 0;                  // Set GROUPTOTAL to 0
    end;
    DataSet := DetailData1.DataSet;   // Initialize DataSet
    
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
      CalculateScopeValues();           // Call CalculateScopeValues()
      IndirectCost();                   // Call IndirectCost()
      AccumulateEstimateValues();       // AccumulateEstimateValues()
    end;
  end;
/////////////////////////

/////////////////////////
// SecondPass - Calls second pass functions & procedures (2.4)
procedure AltSecondPass();
  begin     
    if (Engine.FinalPass) then begin    // If Engine Final Pass then
      ResetCounter();
      AltIndirectCost();                // Call IndirectCost()
    end;
  end;
/////////////////////////

/////////////////////////
// DirectCost (1.3)
procedure DirectCost();
  begin
    // Set Name, Location, SubLocation, GroupName, Qualifications, Exclusions, Markup %
    divisionName[j] := Copy(<EstData."Division">,5,(Length(<EstData."Division">) + 1)); 
    divisionLocation[j] := (<EstData."Location">);
    divisionSubLocation[j] := (<EstData."SubLocation">);
    divisionGroupName[j] := (<EstData."Group Name">);
    divisionUseGroupName[j] := (<EstData."Use Group Name">);
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
    divisionName[j] := Copy(<EstData."Division">,5,(Length(<EstData."Division">) + 1)); 
    divisionLocation[j] := (<EstData."Location">);
    divisionSubLocation[j] := (<EstData."SubLocation">);
    divisionGroupName[j] := (<EstData."Group Name">);
    divisionUseGroupName[j] := (<EstData."Use Group Name">);
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

    ScopeName.Memo.Text := '[Copy(<EstData."Division">,5,(Length(<EstData."Division">) + 1))]'; 
    ScopeNotes.Memo.Text := '[EstData."Qualifications"] <b>[EstData."Exclusions"]</b></font>';                                                                                                              
    ScopeGT.Memo.Text := FormatFloat('$#,###,##0.00', RoundUp(divisionGrandTotal[j]));
    // DisplayBudget := true; ////
    if (DisplayBudget) then begin
      ScopeNotes.Memo.Text := '[EstData."Qualifications"] <b>[EstData."Exclusions"]</b></font>' + ' Price based on ' + '<b>[divisionSQFT[j]] SQ FT.</b>';
    end;  
    Memo1.Memo.Text := '';
    Memo2.Memo.Text := '';
  end;
/////////////////////////

/////////////////////////
// AltIndirectCost (2.6)
procedure AltIndirectCost();
  var 
  tempValue, tempRound: single;
  altGrandTotal: single;
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
    
    //altGrandTotal := 
    altGrandTotal := divisionGrandTotal[j];
    ScopeName.Memo.Text := '[Copy(<EstData."Division">,5,(Length(<EstData."Division">) + 1))]';                                                                                                            
    Memo1.Memo.Text := '<b>[EstData."Name"]</b> [EstData."Qualifications"] <b>[EstData."Exclusions"]</b>';
    Memo2.Memo.Text := FormatFloat('$#,###,##0.00', RoundUp(altGrandTotal));  
    ScopeNotes.Memo.Text := ''; 
    ScopeGT.Memo.Text := '';
    if (divisionUseGroupName[j]) then begin
      Memo1.Memo.Text := '<b>[divisionGroupName[j]]</b> [EstData."Qualifications"] <b>[EstData."Exclusions"]</b>';   
    end;
    if (DisplayBudget) then begin
      Memo1.Memo.Text := '<b>[EstData."Name"]</b> [EstData."Qualifications"] <b>[EstData."Exclusions"]</b> Price based on <b>[divisionSQFT[j]] SQ FT.</b>';
    end; 
    if (divisionUseGroupName[j]) and (DisplayBudget) then begin
      Memo1.Memo.Text := '<b>[EstData."Group Name"]</b> [EstData."Qualifications"] <b>[EstData."Exclusions"]</b> Price based on <b>[divisionSQFT[j]] SQ FT.</b>';
    end;
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

///////////////////////////////////////////////////////////////////////////////////
// Procedure Name: SpeciCalculateGroupValuealScopes
procedure CalculateGroupValue();
  begin
      if (Group_Total > Group_Value) then begin
        Group_ValueHolder := Group_Value;
        Group_Value := Group_Total
      end;
      GroupGT.Memo.Text := FormatFloat('$#,###,##0.00', Group_Total - Group_ValueHolder);
  end;
///////////////////////////////////////////////////////////////////////////////////

// ///////////////////////////////////////////////////////////////////////////////////
// // Procedure Name: ManageHeight1
// procedure ManageHeight1();
//   begin
//     First_Height := AQ_Text.Height;  
//   end;
// ///////////////////////////////////////////////////////////////////////////////////
// 
// ///////////////////////////////////////////////////////////////////////////////////
// // Procedure Name: ManageHeight2
// procedure ManageHeight2();
//   begin
//   New_Height := AQ_Text.Height;                                  
//   AQ_Memo.Height := AQ_Text.Height;
//   EX_Memo.Top := EX_Memo.Top + (New_Height - First_Height);
//   //////
//   EX_Text.Top := EX_Memo.Top; 
//   end;
// ///////////////////////////////////////////////////////////////////////////////////
// 
// // RoundValues()
// procedure RoundValues();
//   var
//   tempValue, tempRound: single;
// 
//   begin
//   if (DataSet.Eof and Engine.FinalPass) then begin
//     for j := 1 to k do begin
//       ShowMessage(divisionGrandTotal[j]);
//       tempValue := divisionGrandTotal[j];
//       tempRound := RoundUp(tempValue);
//       divisionGrandTotal[j] := tempRound;
//       if (divisionIsScope[j]) then begin
//         GRANDTOTAL := GRANDTOTAL + divisionGrandTotal[j];
//         ShowMessage(GRANDTOTAL);
//         GT.Memo.Text := FormatFloat('$#,###,##0.00', GRANDTOTAL);
//       end;
//     end;
//   end;
//   end;
// 

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

procedure GroupGTOnBeforePrint(Sender: TfrxComponent);
  var
  tempValue, tempRound: single;
  Count, Element: integer;
  isNew: boolean;
  begin
    if not (isNew) then begin
      Element := 1;
      isNew := true;
    end;
    GROUPTOTAL := 0;
    for GroupCounter := Element to k do begin
    tempValue := divisionGrandTotal[GroupCounter];
    tempRound := RoundUp(tempValue);
    divisionGrandTotal[GroupCounter] := tempRound;
      if (divisionIsScope[GroupCounter]) then begin
        GROUPTOTAL := GROUPTOTAL + divisionGrandTotal[GroupCounter];
        GRANDTOTAL := GRANDTOTAL + divisionGrandTotal[GroupCounter];
        GroupGT.Memo.Text := FormatFloat('$#,###,##0.00', GROUPTOTAL);
        GT.Memo.Text := FormatFloat('$#,###,##0.00', GRANDTOTAL);
      end;
    end;

    Element := GroupCounter + 1;
  end;

procedure GTOnBeforePrint(Sender: TfrxComponent);
  var
  tempValue, tempRound: single;
  Count, Element: integer;
  isNew: boolean;
  begin
    if not (isNew) then begin
      Element := 1;
      isNew := true;
    end;
    GROUPTOTAL := 0;
    for GroupCounter := Element to k do begin
    tempValue := divisionGrandTotal[GroupCounter];
    tempRound := RoundUp(tempValue);
    divisionGrandTotal[GroupCounter] := tempRound;
      if (divisionIsScope[GroupCounter]) then begin
        //GROUPTOTAL := GROUPTOTAL + divisionGrandTotal[GroupCounter];
        //GRANDTOTAL := GRANDTOTAL + divisionGrandTotal[GroupCounter];
        GroupGT.Memo.Text := FormatFloat('$#,###,##0.00', GROUPTOTAL);
        GT.Memo.Text := FormatFloat('$#,###,##0.00', GRANDTOTAL);
      end;
    end;

    Element := GroupCounter + 1;
  end;

///////////////////////////////////////////////////////////////////////////////////
procedure ReportSummary1OnBeforePrint(Sender: TfrxComponent);                                                                                                                    
begin 
  //RoundValues();                                              
  //ManageHeight1();                                                           
end;
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
procedure ReportSummary1OnAfterCalcHeight(Sender: TfrxComponent);
begin
  //ManageHeight2();   
end;
///////////////////////////////////////////////////////////////////////////////////

begin                                                                                                                                                                                             
        
end.