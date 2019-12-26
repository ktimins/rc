& iisreset;

New-WebServiceProxy -Uri 'http://localhost/pdservices/wsservice.asmx?wsdl' -UseDefaultCredential;

Return;
