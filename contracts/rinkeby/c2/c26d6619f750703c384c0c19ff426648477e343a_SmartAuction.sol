/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Do a Smart Auction
 */
contract SmartAuction {
    address payable public beneficiary;
    uint public auctionEnd; //tempo di fine asta

    address public highestBidder;
    uint public highestBid;

    //uint private secondsInMinute = 60;

    //fare il map di una coppia chiave valore, gli passo i tipi su cui bisogna fare il map
    mapping(address => uint ) pendingReturns;

    bool ended;

    //quando si verifica una determinata condizione si chiama l'evento
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount );

    //il costruttore negli smart contract viene chiamato quando viene fatto il deploy la prima volta
    constructor(uint _biddingTime) {
        //imposto il beneficiario in base a chi fa il deploy del contratto
        beneficiary = payable(msg.sender); 
        auctionEnd = block.timestamp + (_biddingTime * 1 days);
    }

    //payable significa che è possibile inviare eth a questa funzione
    function bid() public payable {
        //require = condizioni che vogliamo siano sempre verificate quando si chiama questa funzione
        //voglio che il momento in cui viene fatta l'offerta sia antecedente alla fine dell'asta
        require(block.timestamp <= auctionEnd, "Auction already over.");
        //msg.value prende la quantità di moneta inviata da chi sta facendo l'offerta
        require(msg.value > highestBid, "There is already a higher bid.");

        //bisogna fare il rimborso all'address che ha fatto l'offerta precedente se viene superata quindi bisogna salvarlo
        if(highestBid != 0) {
            //faccio il map con la highestBid attuale
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = msg.value; 
        highestBidder = msg.sender;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    //bisogna stare attenti al problema della reentrancy, uno smart contract potrebbe interagire con il nostro in modo malevolo per rubare soldi, se non settiamo 
    //subito a zero il pendingReturns dell'indirizzo che ha chiesto il withdraw rischiamo che questo lo continui a fare finchè non ci svuota lo smart contract
    //quindi è meglio fare un'operazione in più nel caso non vada a buon fine e risettarla come prima della richiesta di withdraw
  
    function withdraw() public  payable returns (bool) {
        uint amount = pendingReturns[msg.sender]; 

        if(amount > 0) {
            pendingReturns[msg.sender] = 0;
            //trasferisco gli eth dal contratto all'indirizzo di chi chiede il withdraw, se non va a buon fine devo reincrementarlo nel contratto quindi nel mapping
            if(!(payable(msg.sender).send(amount))){
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true; 
    }

    function endAuction() public {
        require(block.timestamp >= auctionEnd, "Auction not yet ended");
        require(!ended, "endAuction was called");

        ended = true;
        //fare un ciclo for e trasferisci i soldi anche agli altri indirizzi che hanno partecipato salvando gli address su un array
        //stare attenti al pendingReturn all'address dell'highestBidder
        beneficiary.transfer(highestBid); 

        emit AuctionEnded(highestBidder, highestBid);
    }

    function auctionAlreadyEnded() public view returns (bool) {
        return ended;
    }

    function getTimeOfEnd() public view returns (uint) {
        return auctionEnd;
    }

}