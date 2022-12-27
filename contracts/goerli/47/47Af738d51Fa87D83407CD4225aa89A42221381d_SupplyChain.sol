// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


contract SupplyChain{

    //Strutture User

    enum Ruolo{
        disabilitato,       //0
        produttoreTappi,    //1
        trasporto,          //2
        produttoreBevande,  //3
        enteVerifica,       //4
        eliminato           //5
    }

    struct User {
        Ruolo role;  
    }

    address admin;
    mapping (address => User) users;                       //associa un address a un user
    address[] utentiAttivi;


    //Strutture LottoTappi

    enum StatoTappi{
        disabilitato,
        prodotto,
        qualita
    }

    enum Qualita{
        none,
        approvato,
        respinto
    }

    struct LottoTappi{
        uint id_lotto;
        uint lotto_materiale;
        uint pezzi_prodotti;
        uint quantita_disponibile;
        uint timestamp_produzione;
        uint timestamp_qualita;
        address produttore;
        Qualita controllo_qualita;
        StatoTappi stato; 
    }

    mapping(bytes32 => LottoTappi) lottiTappi;              //associa un id (stringa id-lotto_id-produttore) a un lotto

    mapping(address => bytes32[]) lottiTappiForUser;      //associa un address a un vettore di identificatori per lotti tappi 


    //Strutture Ordini

    enum StatoOrdine{
        disabilitato,
        inoltrato,
        spedito,
        consegnato,
        ricevuto,
        terminato
    }

    enum TipoOrdine{
        tappi,
        bevande
    }

    struct LottiOrdine{
        uint lotto;
        uint quantita;
    }

    struct Ordine{
        uint id_ordine;
        uint timestamp_inoltro;
        uint timestamp_partenza;
        uint timestamp_consegna;
        address mittente;
        address trasporto;
        address destinatario;
        TipoOrdine tipo;
        LottiOrdine[] lotti;
        StatoOrdine stato;
    }

    mapping(bytes32 => Ordine) ordini;               //associa un id (stringa id-ordine_id-mittente) a un ordine

    mapping (address => bytes32[]) ordiniForUser;    //associa un address a un vettore di identificatori per ordine 

    mapping(bytes32 => bytes32[]) ordiniForLotto;    //Associa un id lotto a un elenco di ordini che lo riguardano 


    //Strutture LottoBevande

    enum StatoBevande{
        disabilitato,
        prodotto
    }

    struct LottoBevande{
        uint id_lotto;
        uint lotto_bottiglie;
        uint pezzi_prodotti;
        uint quantita_disponibile;
        uint timestamp_produzione;
        bytes32 lotto_tappi;        
        address produttore;
        StatoBevande stato; 
    }

    mapping (bytes32 => LottoBevande) lottiBevande;               //associa un id (stringa id-lotto_id-produttore) a un lotto

    bytes32[] allLottiBevande;

    mapping (address => bytes32[]) lottiBevandeForUser;          //associa un address a un vettore di identificatori per lotti bevande

    mapping (address => mapping(bytes32 => uint)) quantitaLottoForUser;   //accesso alla disponibilità di pezzi disponibile dei lotti di tappi a disposizione di ogni utente


    //Eventi

    event LottoTappiCreato(bytes32 identificatore, address produttore);
    event LottoTappiQualita(bytes32 identificatore, address produttore, Qualita qualita);
    event LottoBevandeCreato(bytes32 identificatore, address produttore);
    event OrdineTappiCreato(bytes32 identificatore, address mittente, address trasporto, address destinatario);
    event OrdineBevandeCreato(bytes32 identificatore, address mittente, address trasporto, address destinatario);
    event OrdineSpedito(bytes32 identificatore, address mittente, address trasporto, address destinatario);
    event OrdineConsegnatoRicevuto(bytes32 identificatore, address mittente, address trasporto, address destinatario);


    //Modifier

    //Il mittente del messagio deve essere l'admin
    modifier isAdmin{
        require( msg.sender == admin, "L'operazione deve essere eseguita dall'amministratore"); 
        _;
    }

    //Il mittente del messaggio deve avere ruolo produttoreTappi
    modifier soloProduttoreTappi{
        require( users[msg.sender].role == Ruolo.produttoreTappi, "L'operazione deve essere eseguita da un produttore di tappi");
        _;
    }

    //Il messaggio deve rifersi a un lotto tappi esistente
    modifier lottoTappiEsistente (bytes32 id){
        require( lottiTappi[id].stato != StatoTappi.disabilitato, "Lotto non esistente");
        _;
    }

    modifier soloTrasporto{
        require( users[msg.sender].role == Ruolo.trasporto, "L'operazione deve essere eseguita da un trasportatore");
        _;
    }

    modifier soloProduttoreBevande{
        require( users[msg.sender].role == Ruolo.produttoreBevande, "L'operazione deve essere eseguita da un produttore bevande");
        _;
    }

    //Il messaggio deve rifersi a un lotto tappi esistente
    modifier lottoBevandeEsistente (bytes32 identificatore){
        require( lottiBevande[identificatore].stato != StatoBevande.disabilitato, "Lotto non esistente");
        _;
    }


    //Funzioni generali

    constructor(){
        admin = msg.sender;
        users[admin].role = Ruolo.enteVerifica;
    }
   

    //Funzioni User

    function createUser(address _add, Ruolo role) public isAdmin {
        require( users[_add].role == Ruolo.disabilitato, "Utente gia' presente");
        require( role > Ruolo.disabilitato, "Ruolo non valido");
        require( role <= Ruolo.enteVerifica, "Ruolo non valido");
        users[_add].role = role;
        utentiAttivi.push(_add);
    }

    function disableUser(address _add) public isAdmin {
        require( users[_add].role != Ruolo.disabilitato, "Utente non presente");
        require( _add != admin, "L'amministratore non puo' essere eliminato");
        users[_add].role = Ruolo.eliminato;
    }

    function fetchRuolo(address _add) public view returns (
        Ruolo role,
        bool check_admin
    )
    {
        require( users[_add].role != Ruolo.disabilitato, "L'utente deve essere attivato dall'amministratore");
        require( (msg.sender == admin) || (msg.sender == _add), "Solo l'amministratore puo' leggere informazioni di altri utenti");
        role = users[_add].role;
        check_admin = admin == _add;
    }

    function fetchUsers() public isAdmin view returns (
        address[] memory utenti
    )
    {
        utenti = new address[](utentiAttivi.length);
        utenti = utentiAttivi;
    }



    //Funzioni LottoTappi

    //Registra un lotto prodotto dall'utente chiamante
    function produciTappo(uint id, uint lotto_materiale, uint pezzi_prodotti) public soloProduttoreTappi {
        
        bytes32 identificatore = keccak256(abi.encodePacked(id,msg.sender));

        require(lottiTappi[identificatore].stato == StatoTappi.disabilitato, "Lotto gia esistente");
        require(pezzi_prodotti > 0);

        lottiTappi[identificatore].id_lotto = id;
        lottiTappi[identificatore].lotto_materiale = lotto_materiale;
        lottiTappi[identificatore].pezzi_prodotti = pezzi_prodotti;
        lottiTappi[identificatore].quantita_disponibile = pezzi_prodotti;
        lottiTappi[identificatore].produttore = msg.sender;
        lottiTappi[identificatore].timestamp_produzione = block.timestamp;
        lottiTappi[identificatore].stato = StatoTappi.prodotto;
        lottiTappi[identificatore].controllo_qualita = Qualita.none;

        lottiTappiForUser[msg.sender].push(identificatore);

        emit LottoTappiCreato(identificatore, msg.sender);

    } 

    //Registra un lotto prodotto dall'utente chiamante
    function registraQualita(uint id, Qualita qualita) public soloProduttoreTappi{
        
        bytes32 identificatore = keccak256(abi.encodePacked(id,msg.sender));

        require( qualita <= Qualita.respinto, "Valore qualita non valido");
        require( lottiTappi[identificatore].stato == StatoTappi.prodotto, "Lotto non esistente o qualita' gia' inserita");
        lottiTappi[identificatore].controllo_qualita = qualita;
        lottiTappi[identificatore].timestamp_qualita = block.timestamp;
        lottiTappi[identificatore].stato = StatoTappi.qualita;

        emit LottoTappiQualita(identificatore, msg.sender, lottiTappi[identificatore].controllo_qualita);
    } 

    //Recupera un lotto dato il suo identificatore
    function fetchLottoTappi(bytes32 identificatore) public lottoTappiEsistente(identificatore) view returns (
        uint id_lotto,
        uint lotto_materiale,
        uint pezzi_prodotti,
        uint quantita_disponibile,
        uint timestamp_produzione,
        uint timestamp_qualita,
        address produttore,
        Qualita controllo_qualita,
        StatoTappi stato
    )

    {
        LottoTappi memory lotto = lottiTappi[identificatore];
        id_lotto = lotto.id_lotto;
        lotto_materiale = lotto.lotto_materiale;
        pezzi_prodotti = lotto.pezzi_prodotti;
        quantita_disponibile = lotto.quantita_disponibile;
        produttore = lotto.produttore;
        controllo_qualita = lotto.controllo_qualita;
        timestamp_produzione = lotto.timestamp_produzione;
        timestamp_qualita = lotto.timestamp_qualita;
        stato = lotto.stato;
    }

    //Recupera i lotti dell'utente chiamante
    function fetchTappiByAddress() public soloProduttoreTappi view returns(
        bytes32[] memory lotti
    )
    {
        bytes32[] memory identificatori;
        identificatori = lottiTappiForUser[msg.sender];
        lotti = new bytes32[](identificatori.length);
        lotti = identificatori;
    }


    //Funzioni Ordine

    //Registra un ordine di tappi inoltrato dall'utente chiamante
    function registraOrdineTappi(uint id, address trasporto, address destinatario, LottiOrdine[] memory lotti) public soloProduttoreTappi {

        bytes32 identificatore = keccak256(abi.encodePacked(id,msg.sender));
        bytes32 identificatore_lotto;

        require( ordini[identificatore].stato == StatoOrdine.disabilitato, "Ordine con id gia' esistente");

        require( users[trasporto].role == Ruolo.trasporto, "Utente di trasporto non valido" );
        require( users[destinatario].role == Ruolo.produttoreBevande, "Utente destinatario non valido" );


        uint quantitaRichiesta;
        uint quantitaDisponibile;

        for(uint i=0; i<lotti.length; i++){

            identificatore_lotto = keccak256(abi.encodePacked(lotti[i].lotto,msg.sender));

            require(lottiTappi[identificatore_lotto].controllo_qualita == Qualita.approvato, "Il lotto non ha superato il controllo qualita'");

            quantitaRichiesta = lotti[i].quantita;
            quantitaDisponibile = lottiTappi[identificatore_lotto].quantita_disponibile;
            require(quantitaRichiesta <= quantitaDisponibile, "Disponibilita' insufficiente nei lotti selezionati");
            lottiTappi[identificatore_lotto].quantita_disponibile = lottiTappi[identificatore_lotto].quantita_disponibile - quantitaRichiesta;
            ordini[identificatore].lotti.push(lotti[i]);

            ordiniForLotto[identificatore_lotto].push(identificatore);

        }

        ordini[identificatore].id_ordine = id;
        ordini[identificatore].mittente = msg.sender;
        ordini[identificatore].trasporto = trasporto;
        ordini[identificatore].destinatario = destinatario;
        ordini[identificatore].tipo = TipoOrdine.tappi;
        ordini[identificatore].timestamp_inoltro = block.timestamp;
        ordini[identificatore].stato = StatoOrdine.inoltrato;

        ordiniForUser[msg.sender].push(identificatore);
        ordiniForUser[trasporto].push(identificatore);
        ordiniForUser[destinatario].push(identificatore);

        emit OrdineTappiCreato(identificatore, msg.sender, trasporto, destinatario);

    } 

    //Registra un ordine di bevande inoltrato dall'utente chiamante
    function registraOrdineBevande(uint id, address trasporto, address destinatario, LottiOrdine[] memory lotti) public soloProduttoreBevande {

        bytes32 identificatore = keccak256(abi.encodePacked(id,msg.sender));
        bytes32 identificatore_lotto;

        require( ordini[identificatore].stato == StatoOrdine.disabilitato, "Ordine con id gia' esistente");

        require( users[trasporto].role == Ruolo.trasporto, "Utente di trasporto non valido" );


        uint quantitaRichiesta;
        uint quantitaDisponibile;

        for(uint i=0; i<lotti.length; i++){

            identificatore_lotto = keccak256(abi.encodePacked(lotti[i].lotto,msg.sender));

            quantitaRichiesta = lotti[i].quantita;
            quantitaDisponibile = lottiBevande[identificatore_lotto].quantita_disponibile;
            require(quantitaRichiesta <= quantitaDisponibile, "Disponibilita' insufficiente nei lotti selezionati");
            lottiBevande[identificatore_lotto].quantita_disponibile = lottiBevande[identificatore_lotto].quantita_disponibile - quantitaRichiesta;
            ordini[identificatore].lotti.push(lotti[i]);

            ordiniForLotto[identificatore_lotto].push(identificatore);

        }

        ordini[identificatore].id_ordine = id;
        ordini[identificatore].mittente = msg.sender;
        ordini[identificatore].trasporto = trasporto;
        ordini[identificatore].destinatario = destinatario;
        ordini[identificatore].tipo = TipoOrdine.bevande;
        ordini[identificatore].timestamp_inoltro = block.timestamp;
        ordini[identificatore].stato = StatoOrdine.inoltrato;

        ordiniForUser[msg.sender].push(identificatore);
        ordiniForUser[trasporto].push(identificatore);
        ordiniForUser[destinatario].push(identificatore);

        emit OrdineBevandeCreato(identificatore, msg.sender, trasporto, destinatario);

    } 

    //Registra la partenza di un ordine
    function spedisciOrdine(bytes32 identificatore) public soloTrasporto{
        

        require(ordini[identificatore].stato == StatoOrdine.inoltrato, "L'ordine deve essere inoltrato e non spedito");

        ordini[identificatore].timestamp_partenza = block.timestamp;
        ordini[identificatore].stato = StatoOrdine.spedito;

        emit OrdineSpedito(identificatore, ordini[identificatore].mittente, msg.sender, ordini[identificatore].destinatario);

    } 

    function aggiornaQuantitaLottiTappi(LottiOrdine[] memory lotti, address mittente, address destinatario) internal{

        bytes32 identificatore_lotto;

        for(uint i=0; i<lotti.length; i++){

            identificatore_lotto = keccak256(abi.encodePacked(lotti[i].lotto,mittente)); 

            //quantitaLottoForUser[destinatario][identificatore_lotto] = quantitaLottoForUser[destinatario][identificatore_lotto] + lotti[i].quantita;
            quantitaLottoForUser[destinatario][identificatore_lotto] = lotti[i].quantita;
        }

    }

    //Registra la consegna di un ordine
    function consegnaOrdine(bytes32 identificatore) public soloTrasporto{

        require((ordini[identificatore].stato == StatoOrdine.spedito) || (ordini[identificatore].stato == StatoOrdine.ricevuto), "L'ordine non e' in consegna");

        if(ordini[identificatore].stato == StatoOrdine.spedito){
            ordini[identificatore].stato = StatoOrdine.consegnato;
        }
        else if(ordini[identificatore].stato == StatoOrdine.ricevuto){
            ordini[identificatore].stato = StatoOrdine.terminato;

            if(ordini[identificatore].tipo == TipoOrdine.tappi ){
                aggiornaQuantitaLottiTappi(ordini[identificatore].lotti, ordini[identificatore].mittente, ordini[identificatore].destinatario);
            }

            emit OrdineConsegnatoRicevuto(identificatore, ordini[identificatore].mittente, msg.sender, ordini[identificatore].destinatario);
                        
        }

        ordini[identificatore].timestamp_consegna = block.timestamp;

    } 

    //Registra la ricezione di un ordine
    function ricezioneOrdine(bytes32 identificatore) public{

        require(ordini[identificatore].destinatario == msg.sender, "Solo il destinatario dell'ordine puo' confermare la ricezione");

        require((ordini[identificatore].stato == StatoOrdine.spedito) || (ordini[identificatore].stato == StatoOrdine.consegnato), "L'ordine non e' in consegna");

        if(ordini[identificatore].stato == StatoOrdine.spedito){
            ordini[identificatore].stato = StatoOrdine.ricevuto;
        }
        else if(ordini[identificatore].stato == StatoOrdine.consegnato){
            ordini[identificatore].stato = StatoOrdine.terminato;

            if(ordini[identificatore].tipo == TipoOrdine.tappi ){
                aggiornaQuantitaLottiTappi(ordini[identificatore].lotti, ordini[identificatore].mittente, ordini[identificatore].destinatario);
            }

            emit OrdineConsegnatoRicevuto(identificatore, ordini[identificatore].mittente, msg.sender, ordini[identificatore].destinatario);
        }

    } 

    //Recupera un ordine dato il suo identificatore
    function fetchOrdine(bytes32 identificatore) public view returns (
        uint id_ordine,
        uint timestamp_inoltro,
        uint timestamp_partenza,
        uint timestamp_consegna,
        address mittente,
        address trasporto,
        address destinatario,
        TipoOrdine tipo,
        LottiOrdine[] memory lotti,
        StatoOrdine stato
    )

    {
        require(ordini[identificatore].stato != StatoOrdine.disabilitato, "Ordine non presente");

        Ordine memory ordine = ordini[identificatore];
        id_ordine = ordine.id_ordine;
        mittente = ordine.mittente;
        trasporto = ordine.trasporto;
        destinatario = ordine.destinatario;
        tipo = ordine.tipo;
        lotti = ordine.lotti;
        timestamp_inoltro = ordine.timestamp_inoltro;
        timestamp_partenza = ordine.timestamp_partenza;
        timestamp_consegna = ordine.timestamp_consegna;
        stato = ordine.stato;
    }

    //Recupera gli ordini dell'utente chiamante
    function fetchOrdiniByAddress() public view returns(
        bytes32[] memory lista_ordini
    )
    {
        bytes32[] memory identificatori;
        identificatori = ordiniForUser[msg.sender];
        lista_ordini = new bytes32[](identificatori.length);
        lista_ordini = identificatori;
    }

    //Recupera gli ordini dato un lotto
    function fetchOrdiniByLotto(bytes32 identificatore) public view returns(
        bytes32[] memory lista_ordini
    )
    {
        bytes32[] memory identificatori;
        identificatori = ordiniForLotto[identificatore];
        lista_ordini = new bytes32[](identificatori.length);
        lista_ordini = identificatori;
    }


    //Funzioni LottoBevande

    //Registra un lotto prodotto dall'utente chiamante
    function produciBevanda(uint id, uint lotto_bottiglie, bytes32 lotto_tappi, uint pezzi_prodotti) public soloProduttoreBevande {

        bytes32 identificatore = keccak256(abi.encodePacked(id,msg.sender));

        require(lottiBevande[identificatore].stato == StatoBevande.disabilitato, "Lotto gia esistente");

        require(pezzi_prodotti > 0);

        uint quantitaRichiesta = pezzi_prodotti * 1;

        require(quantitaLottoForUser[msg.sender][lotto_tappi] >= quantitaRichiesta, "Disponibilita' insufficiente nei lotti selezionati");

        quantitaLottoForUser[msg.sender][lotto_tappi] = quantitaLottoForUser[msg.sender][lotto_tappi] - quantitaRichiesta;

        lottiBevande[identificatore].id_lotto = id;
        lottiBevande[identificatore].lotto_bottiglie = lotto_bottiglie;
        lottiBevande[identificatore].lotto_tappi = lotto_tappi;
        lottiBevande[identificatore].pezzi_prodotti = pezzi_prodotti;
        lottiBevande[identificatore].quantita_disponibile = pezzi_prodotti;
        lottiBevande[identificatore].produttore = msg.sender;
        lottiBevande[identificatore].timestamp_produzione = block.timestamp;
        lottiBevande[identificatore].stato = StatoBevande.prodotto;

        lottiBevandeForUser[msg.sender].push(identificatore);
        allLottiBevande.push(identificatore);

        emit LottoBevandeCreato(identificatore, msg.sender);

    } 

    //Recupera un lotto dato il suo identificatore
    function fetchLottoBevande(bytes32 identificatore) public lottoBevandeEsistente(identificatore) view returns (
        uint id_lotto,
        uint lotto_bottiglie,
        uint pezzi_prodotti,
        uint quantita_disponibile,
        uint timestamp_produzione,
        bytes32 lotto_tappi,
        address produttore,
        StatoBevande stato
    )

    {
        LottoBevande memory lotto = lottiBevande[identificatore];
        id_lotto = lotto.id_lotto;
        lotto_bottiglie = lotto.lotto_bottiglie;
        lotto_tappi = lotto.lotto_tappi;
        pezzi_prodotti = lotto.pezzi_prodotti;
        quantita_disponibile = lotto.quantita_disponibile;
        produttore = lotto.produttore;
        timestamp_produzione = lotto.timestamp_produzione;
        stato = lotto.stato;
    }

    //Recupera i lotti dell'utente chiamante
    function fetchBevandeByAddress() public soloProduttoreBevande view returns(
        bytes32[] memory lotti
    )
    {
        bytes32[] memory identificatori;
        identificatori = lottiBevandeForUser[msg.sender];
        lotti = new bytes32[](identificatori.length);
        lotti = identificatori;
    }

    //Recupera tutti i lotti bevande (ente verifica)
    function fetchBevande() public view returns(
        bytes32[] memory lotti
    )
    {
        require( users[msg.sender].role == Ruolo.enteVerifica, "L'operazione deve essere eseguita da un ente di verifica");
        lotti = new bytes32[](allLottiBevande.length);
        lotti = allLottiBevande;
    }

    function fetchDisponibilitaLottiTappiByAddressBevande(bytes32 lotto) public soloProduttoreBevande view returns(
        uint disponibilita
    )
    {
        disponibilita = quantitaLottoForUser[msg.sender][lotto];
    }

}