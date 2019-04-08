# Instalação Visual Studio

## Install

* Visual Studio Community
* Oracle 10.0.5 (\\s-sa-sao02fs03\comum$\Comum_NovaPlataformaTC\util\Oracle\SEQUENCIA)
* Pulse Secure (\\s-sa-sao02fs03\comum$\Comum_NovaPlataformaTC\util\Pulse)
* PLSQL Developer (\\s-sa-sao02fs03\comum$\Comum_NovaPlataformaTC\util\PLSQL Developer10)
* MRemote (\\s-sa-sao02fs03\comum$\Comum_NovaPlataformaTC\util\mRemote)
* KeePass (\\s-sa-sao02fs03\comum$\Comum_NovaPlataformaTC\util\KeePass)
* WCFStorm (\\s-sa-sao02fs03\comum$\Comum_NovaPlataformaTC\util\WCFStorm Enterprise)
* Araxis (\\s-sa-sao02fs03\comum$\Comum_NovaPlataformaTC\util\Araxis Merge Professional)
* Windows Features (Turn Windows features on and off):
  * Enable all .Net Framework 3.5
  * Enable all IIS features

## Configuration

### IIS

* create Application Pool with:
  * Name: Developer
  * Identity: STEFANINI-DOM\<stefanini user>
* Add on the file applicationHost (C:\Windows\System32\inetsrv\Config) under tag <sites> (you'll find a partial the applicationHost.config [here](applicationHost.config))
* If Oracle couldn't connection, change in Advanced Settings: Enable 32-bit Application to True
* Include two lines in the Aspnet.config (C:\Windows\Microsoft.NET\Framework\v4.0.30319):

```xml
<NetFx40_LegacySecurityPolicy enabled="true"/>
<legacyCasPolicy enabled="true" />
```

### Oracle

* Copy [sqlnet](sqlnet.ora) and [tnsname](tnsname.ora) to C:\oracle\product\10.2.0(instaled version)\client_1\network\ADMIN

### Visual Studio

* Git repository: satktsao02app06
* Create a default directory in your machine: C:\Git\EW<Project Caractere(s)>
* Install NUnit Adapter Plugin

### Enviroment Variables

* CURRENT_WATTSCOUNTRY: MX (or CL, AR, BR...)
* CURRENT_WATTSCOUNTRY_ENV: DES (QA, HOM...)
* CURRENT_WATTSPATH: C:\GIT\EWTC
* TNS_ADMIN: C:\oracle\product\10.2.0(instaled version)\client_1\network\ADMIN