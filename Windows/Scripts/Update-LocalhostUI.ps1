Push-Location 'C:\Work\Products\DailyBuild\CommercialIntellisys\Web\UI';

.\_1_GetLatestSource.bat;
.\_2_BuildAllCustomerSolutions.ps1 -JustGo;
.\_3_PDPagesCustomCopy.bat;

Pop-Location;

Exit;
