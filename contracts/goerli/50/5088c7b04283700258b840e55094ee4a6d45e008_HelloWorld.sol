/*
Specifica la versione di Solidity
un source file con il comando scritto sopra non compila con un compiler che ha una versione 
precedente a 0.8.9 e non funziona neanche con un compiler che inizia con 0.9.0
Questo perché non ci saranno cambiamenti importanti fino alla versione 0.9.0

*/
pragma solidity ^0.8.9;

/*
"contract HelloWorld" definisce un contratto chiamato HelloWorld
Un contratto è una raccolta di funzioni (comportamento) e dati (stato).
Una volta distribuito, un contratto risiede in un indirizzo specifico della blockchain Ethereum.
*/
contract HelloWorld{

    /*
    Dichiara una variabile chiamata message di tipo string.
    Le variabili di stato sono variabili con valori memorizzati in modo permanente nello spazio di archiviazione (storage) del contratto.
    La parola public fa in modo che la variabile sia accessibile dall'esterno del contratto e crea una funzione che gli altri
    contratti possono chiamare per accedere alla variabile.
    */
    string public message;


    /*
    Il costruttore è una funzione speciale che viene eseguita alla creazione del contratto.
    I costruttori vengono usati per inizializzare i dati del contratto.
    Dopo l'esecuzione del costruttore, il codice finale del contratto è distribuito sulla blockchain.
    La distribuzione del contratto ha un costo aggiuntivo in base alla lunghezza del codice
    */
    constructor(string memory initMessage){
        /*
        Accetta una stringa initMessage e imposta il valore nella variabile message
        */
        message = initMessage;
    }

    /*
    Funzione pubblica che accetta una stringa e aggiorna la variabile message
    */
    function update(string memory newMessage) public{
        message = newMessage;
    }
}