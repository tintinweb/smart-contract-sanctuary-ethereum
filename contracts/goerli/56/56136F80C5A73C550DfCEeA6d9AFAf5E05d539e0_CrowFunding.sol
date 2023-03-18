// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowFunding {
    // struct == obj in js
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

    mapping(uint256 =>Campaign)public campaigns;

    // Inizializziamo il contatore delle campagne 
    uint256 public numberOfCampaigns = 0;

    //! creazione di una campagna 
    //? MEMORY -> parola chiave che specifica lo storage temporaneo di una stringa
    //? PUBLIC -> parola chiave che specifica la visibilità della funzione
    //? RETURNS -> parola chiave che specifica che la funzione ci ridarà un dato del quale bisgona specificare il tipo 
    function creaCampaign(
        //parametri in ingresso con la dichiarazione del tipo essendo solidity un linguaggio tipizzato
        address _owner,string memory _title,string memory _description,uint256 _target,uint256 _deadline,string memory _image)public returns(uint256){
        Campaign storage campaign = campaigns[numberOfCampaigns];

        //!Controllo della deadline della campagna se è inferiore alla data di oggi. Obbligatoria data nel futuro
        require(campaign.deadline < block.timestamp,"The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image=_image;

        numberOfCampaigns ++;

        return numberOfCampaigns-1;
    }

    //! donatione per una campagna
    //? PAYABLE ->
    function donateToCampaign(uint256 _id)public payable{
        uint256 amount  = msg.value;
        
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        //Payable restituisce due variabli la prima la specifichiamo, la secondo ci va bene qualsiasi sia il suo tipo
        (bool sent,) = payable(campaign.owner).call{value:amount}("");
        if(sent){
            campaign.amountCollected = campaign.amountCollected +amount;
        }
    }

    //! dammi tutti i donatori di una campagna
    //? VIEW -> parola chiave che specifica che la seguente funzione non modifica dati, ma le visualizza solo
    function getDonators(uint256 _id) view public 
    returns(address[] memory,uint256[] memory){
        return (campaigns[_id].donators,campaigns[_id].donations);
    }

    //! dammi tutte le campagne
    function getCampaigns() public view returns(Campaign[] memory){
        //Stiamo creando una nuova variabile di tipo array di oggetti
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i=0;i<numberOfCampaigns; i++){
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}