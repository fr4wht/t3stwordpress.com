La soluzione pensata e' basata su un infrastruttura composta da:

- MIG 
- Certificato SSL Google managed  
- Load balancer
- Firewall
- Health check
- Cloud Armor

Come IaC verra' utilizzato Terraform.

La parte di compute viene gestita tramite una MIG con bilanciatore che scalara' e farà il deploy automatico di una nuova istanza quando necessario.

La MIG creera' una istanza in 3 differenti regioni per evitare il single point of failure.
L'istanza una volta deployata, al boot lancera' l'installazione di Wordpress e Apache con le relative configurazioni.

Per garantire una veloce fruizione dei servizi, a livello di velocità di interconnessione, la rete di 'default' utilizza il tier Premium che offre prestazioni elevate oltre a maggiore compatibilità per eventuali servizi futuri.

Lato VM invece ogni singola istanza della MIG avrà 4 vCPU, 32 GB memory e 100GB di disco.

Verranno creati un certificato SSL e un indirizzo IP pubblico per consentire di accedere all'istanza di Wordpress via browser. 

Viene quindi creato un load balancer che utilizza il certificato SSL e inoltrera' il traffico verso le istanze di Wordpress. 

Per garantire che le istanze di Wordpress continuino a funzionare, viene implementato un health check che si occupera' di monitorare i servizi. 

Infine, viene creato un firewall HTTP per consentire il traffico sulla porta 80. 

Come stack di security applicativo, verra' utilizizzato il servizio Cloud Armor e Recaptcha. Cloud Armor fornira' la protezione contro gli attacchi DDoS e Recaptcha assicurando che gli utenti malevoli non interagiscano con l'applicativo.

_________________________________________________________________________________________________________________________________________________________

Per implementare questa infrastruttura seguire i seguenti passaggi:

- All'interno della cloud shell, apri l'editor
- Copia il contenuto della cartella all'interno
- Torna nella shell ed esegui i seguenti comandi in successione, soffermandoti sul comando plan per vedere le effettive modifiche che verranno fatte nella tua infrastruttura:
	
	terraform init 
	
	terraform validate
	
	terraform plan
	
	terraform apply

- Verifica il corretto funzionamento in console.
