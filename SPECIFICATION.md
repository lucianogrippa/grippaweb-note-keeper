Si vuole realizzare un software dove poter memorizzare le credenziali e altri dati (che per semplicità chiamo "Nota") dei propri accounts, sottoscrizioni, abbonamenti ecc.. In maniera sicura e strutturata.

L'applicazione che si vuole sviluppare:
- Deve lavorare offline.
- Ha un unico utente.
- Deve avere un database locale e memorizzare solo i dati del profilo utente strettamente necessari per poter proteggere il contenuto. (nome, cognome , email e password)
- Sia la master password per criptare il database che la password utente sarà memorizzata in maniera sicura e non in chiaro nel secure storage del dispositivo.

Quando l'applicazione viene lanciata per la prima volta, deve verificare se il file del database è presente nel sistema o meno,

se non presente:
- genera una master password con algoritmo di hashing SHA-256
- memorizza la master password nel secure storage del dispositivo. Questa sarà utilizzata per criptare il database e per derivare la password dell'utente.
- crea il database (file) impostando una password derivata dalla master password. (Argon2 https://en.wikipedia.org/wiki/Argon.)

se presente e anche dopo aver creato un nuovo db:
verifica se nel database esiste il profilo utente

se il profilo utente non esiste mostra un form di registrazione che permette di creare il profilo. (nome cohnome email , password e conferma password). Prima di salvare verifica la validità dei campi , che non contengano stringhe tipo parentesi angolari e che l'email abbia un formato corretto.
Al salvataggio nel db crea il profilo utente.

se il profilo essiste e non è mai stato effettuato un login allora mostra il form di login (email e password) , il login grea un token con una validità di 30 gg ma è configurabile
se è stato effettuato il login nel secure storage è presente un token , verifica validità per poter visualizzare la prima pagina delle categorie.

a questo punto l'applicazione

Le note, saranno memorizzare in mariera organizzata nel database, nello specifico le possiamo associarle ad un solo Gruppo che ne caratterizza l'uso.
Ad esempio il Pin della card sarà associato al gruppo Unicredit, lo stesso vale ad esempio per il Mobile Token e l'indirizzo della filiale.
il Gruppo potrà essere associato ad una sola Categoria ad esempio il Gruppo Unicredit sarà associato alla Categoria Banche e Finaziarie, Il Gruppo Neflix sarà associato alla categoa TV Abbonamenti.

Questo classificazione mi permette di poter organizzare le note in maniera ordinata.
Banche & Finaziamenti
|
|
>> Unicredit
>> Mobile Token
>> Pin Carta
>> Indirizzo dell filiale

L'utente deve poter creare sia i gruppi che le categorie inserndo un nome e una descrizione per la cetegoria. Solo il nome per il gruppo.
In questo modo nella prima schermata dell'applicazione vedrà l'elenco delle categoria e selezionata la categoria l'elenco dei gruppi associati alla categoria.
Selezionato il Gruppo vedò un elenco di note associate a quel gruppo specifico.
Inoltre per entrambi verrà mostrata la data di ultima modifica.

Le note saranno rappresentate sottoforma di card con un titolo, breve descrizione max 255 caratteri, il contenuto.
Se l'utente ha scelto di criptare il contenuto la card lo nasconde e verrà visualizzato solo in una finestra di dialogo dopo che avrà cliccato su una icona a forma di occhio o lucchetto.
L'utente inoltre deve poter copiare il contenuto, o il titolo.

L'utente ha quindi la possibilità di inserire le note e dicedire se il contenuto verrà criptato o meno. inoltre l'utente potrà effettuare una ricerca delle note da qualsiasi schermata dell'applicazione.
La ricerca avverrà per tittolo, contenuto (se non criptato) e decrizione.
