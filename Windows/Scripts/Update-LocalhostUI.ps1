Param(
      [Switch]$Build
     )

Push-Location 'C:\Work\Products\DailyBuild\CommercialIntellisys\Web\UI';

## Get latest UI source.
.\_1_GetLatestSource.bat;

## NGA Builder can usually get the correct assemblies, so building isn't always needed.
If ($Build) {
   ## Build the customer solutioms in the UI dir of TFS
   .\_2_BuildAllCustomerSolutions.ps1 -JustGo;
}

## Copy the PDNPages to where they need to be.
.\_3_PDPagesCustomCopy.bat;

Pop-Location;

Exit;
