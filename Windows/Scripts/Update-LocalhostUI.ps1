Param(
      [Switch]$Build,
      [Switch]$Prompt
     );

If ($Prompt) {
   $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Y`bBuild", 'Build Customer Solutions in Web/UI directory';
   $no  = New-Object System.Management.Automation.Host.ChoiceDescription '&No Build', 'No Building of Web/UI Solutions';
   $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no);
   $result = $host.ui.PromptForChoice('Build Web/UI Solutions?', 'Would you like to build Web/UI Solutions?', $options, 1);

   Switch ($result) {
      0 {
         $Build = $True;
      }
   }
}

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
