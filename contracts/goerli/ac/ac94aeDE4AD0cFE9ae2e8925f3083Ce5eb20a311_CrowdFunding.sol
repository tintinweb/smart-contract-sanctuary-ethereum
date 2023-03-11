// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract CrowdFunding{

    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public crowdFundingCampaigns;

    uint256 public numberOfCampaigns = 0;

    /** 
        si usa memory per le variabili che devono essere salvate non permanentemente sulla memoria ma per quelle che devono essere svuotate

        La memoria è un'area di memoria volatile (cioè viene svuotata quando la funzione che l'ha utilizzata termina la sua esecuzione) e
        viene utilizzata per la gestione di variabili di tipo array, stringa e struct.
    
    */
    function createCampaing(address _owner, string memory _title, string memory _description, uint256 _target,
     uint256 _deadline, string memory _image) public returns (uint256){
        Campaign storage campaign = crowdFundingCampaigns[numberOfCampaigns];

        // require() verifica che, se una condizione è valida, ritorna un messaggio personalizzato di errore
        require(campaign.deadline < block.timestamp , "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    /** 
        si usa il modificatore 'payable' per specificare che con quella funzione avverrà uno scambio di cryptovalute
    */
    /** 
        Il codice in Solidity definisce una funzione chiamata "donateToCampaign" che consente ai partecipanti di donare denaro ad una
        campagna di crowdfunding specifica.
        La funzione richiede un parametro di input "_id", che rappresenta l'ID della campagna di crowdfunding a cui si desidera effettuare una donazione.
        La funzione utilizza il modificatore "payable" per consentire ai partecipanti di inviare ETH con la loro transazione.
        Il codice inizia impostando la variabile "amount" con il valore dell'ETH inviato con la transazione.
        Successivamente, viene ottenuto un riferimento alla campagna di crowdfunding specifica corrispondente all'ID fornito dall'utente, memorizzando 
        l'oggetto Campaign associato all'ID nella variabile "campaign".
        La funzione quindi aggiunge l'indirizzo del donatore e l'importo della donazione alle matrici "donators" e "donations" dell'oggetto Campaign corrispondente.
        Successivamente, la funzione tenta di trasferire l'importo della donazione all'indirizzo del proprietario della campagna di crowdfunding. Questo viene fatto 
        utilizzando la funzione "call" di Solidity, con il valore dell'importo come parametro. Se il trasferimento ha successo, viene aggiornato l'importo totale
        raccolto dalla campagna di crowdfunding.
        Infine, se il trasferimento ha avuto successo, la funzione restituisce un valore booleano "true" per indicare che la donazione è stata effettuata correttamente.
    */
    function donateToCampaign(uint256 _id) public payable{
        uint256 amount = msg.value;

        Campaign storage campaign = crowdFundingCampaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    /**
        La parola chiave "view" nell'intestazione della funzione "getDonators" indica che la funzione non modificherà lo stato del contratto. Questa parola chiave viene 
        utilizzata per indicare che la funzione può essere chiamata solo per leggere i dati dal contratto, ma non per modificare i dati.
        In altre parole, la funzione non effettuerà alcuna modifica alle variabili di stato del contratto e non creerà alcuna transazione sulla blockchain Ethereum. Ciò 
        significa che chiamare questa funzione non richiederà il pagamento di alcuna commissione di gas e non produrrà alcun impatto sullo stato del contratto.
        La parola chiave "view" viene spesso utilizzata per le funzioni di lettura dei dati, in quanto consente di accedere ai dati memorizzati nel contratto senza modificarli.
        Ciò significa che le funzioni "view" possono essere chiamate in modo sicuro da qualsiasi parte del codice, senza il rischio di effettuare modifiche accidentali ai dati
        del contratto.
    */
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory){
        return (crowdFundingCampaigns[_id].donators, crowdFundingCampaigns[_id].donations);
    }

    /** 
        Quella che fa questa funzione è, innanzitutto, creare un nuovo array di struct Compaign con all'interno tante struct vuote quanti sono le attuali Campagn e successivamente
        popolare ogni struct con la corrispondente Campaign
    */
    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaings = new Campaign[](numberOfCampaigns);

        for(uint256 i = 0; i < numberOfCampaigns; i++){
            Campaign storage item = crowdFundingCampaigns[i];

            allCampaings[i] = item;
        }

        return allCampaings;
    }

}