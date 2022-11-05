/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AuctionCreator{
    Auction[] public auctions;

    function CreateAuction(uint duration, uint finalPrice, uint minPrice, uint qnty) public{
        require(minPrice <= finalPrice);
        require(qnty>0);
        Auction newAuction = new Auction(duration, finalPrice, minPrice, qnty, msg.sender);
        auctions.push(newAuction);
    }
    
    // Duomenų nuskaitymas iš jau sukurto kontrakto - getters

    function getAuctionCount() public view returns (uint256) {
    return auctions.length;
    }

    function getAuctions() public view returns (Auction[] memory) {
    return auctions;
    }

    function getAuctionOwner(uint256 _auctionIndex) public view returns (address) {
    return Auction(address(auctions[_auctionIndex])).auctionOwner();
   }

    function getHighestBidder(uint256 _auctionIndex) public view returns (address) {
    return Auction(address(auctions[_auctionIndex])).highestBidder();
   }
       
    function getHighestBindingBid(uint256 _auctionIndex) public view returns (uint256) {
    return Auction(address(auctions[_auctionIndex])).highestBindingBid();
   }

    function getAuctionMinPrice(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).minPrice();
   }
    
    function getAuctionFinalPrice(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).finalPrice();
   }

    function getAuctionDuration(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).auctionDuration();
   }

    function getAuctionState(uint256 _auctionIndex) public view returns (string memory) {
    return Auction(address(auctions[_auctionIndex])).returnState();
   }

    function getCurrentBlock(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).currentBlockNumber();
   }

    function getBlocksLeft(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).blocksLeft();
   }

    function getEndBlock(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).endBlock();
   }

    function getQnty(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).qnty();
   }

    function getUserBids(uint256 _auctionIndex) public view returns (uint) {
    return Auction(address(auctions[_auctionIndex])).bids(msg.sender);
   }

     // Duomenų įrašymas į blokų grandinę (biddinimas, atšaukimas, auciono rezultatai) - setters

    function placeBid(uint256 _auctionIndex) public payable {
    uint bid = msg.value;
    Auction(address(auctions[_auctionIndex])).placeBid{value: bid}(msg.sender);
    }

    function cancelAuction(uint256 _auctionIndex) public {
    Auction(address(auctions[_auctionIndex])).cancelAuction(msg.sender);
    }

    function finishAuction(uint256 _auctionIndex) public {
    Auction(address(auctions[_auctionIndex])).finishAuction(msg.sender);
    }

}

contract Auction{
    address payable public auctionOwner;
    uint public finalPrice;
    uint public minPrice;
    uint public auctionDuration; // in block num
    uint public qnty;
    uint public startBlock;
    uint public endBlock;
    
    enum State {
        Ongoing,
        Ended,
        UserCancelled,
        Failed
        }

    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(uint _duration, uint _finalPrice, uint _minPrice, uint _qnty, address eoa){
        auctionOwner = payable(eoa);
        auctionState = State.Ongoing;
        auctionDuration = _duration;
        bidIncrement = 1;
        finalPrice = _finalPrice;
        minPrice = _minPrice;
        startBlock = block.number;
        endBlock = startBlock + auctionDuration; // 1 blokas 15 sec, 40 bloku = 10 min
        qnty = _qnty;
    }

    modifier notOwner(){
        require(msg.sender != auctionOwner, "Auction owner, cannot bid");
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock, "Auction has not started");
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock, "Auction has ended");
        _;
    }

    // bidinimo funkcija
    function placeBid(address _sender) public payable{
        require(msg.sender != auctionOwner, "Auction owner, cannot bid");
        require(block.number >= startBlock, "Auction has not started");
        require(msg.sender != auctionOwner, "Auction owner, cannot bid");
        require(msg.value >= bidIncrement, "Bid should be atleast 100 wei");
        require(auctionState == State.Ongoing, "Auction has ended or cancelled");
        
        address sender = _sender;
        
        uint currentBid = bids[sender] + msg.value;

        require(currentBid > highestBindingBid);
        require(currentBid <= finalPrice, "Bid should be not more than max Price");
        require(highestBindingBid <= finalPrice);

        bids[sender] = currentBid;
        

        // Tikrina ar dabartinis bloko nr. yra didsnis už aukciono skelbėjo nurodytą paskutinį bloko numerį (trukmė) ir ar aukcionas pasiekė minimalią kainą
        if(block.number >= endBlock && highestBindingBid < minPrice){
            // Jeigu bloko nr. didesnis už nurodyto bloko numerį - reiškia aukcionas baigėsi. Jeigu didžiausias statymas nepasiekė minimalios kainos - aukcionas laikomas neįvykusiu. (State.Failed)
            auctionState = State.Failed;
        }else{
            // Toliau tikrinam ar dabartinis bloko nr. yra mažesnis už nurodyto bloko numerį.
            if(block.number < endBlock){
                // Jeigu numeris mažesnis, reiškiasi aukcionas yra aktyvus. Pirmiausia tikriname, ar aukščiausią statymą turintis adresas yra lygus adresui kuris dabar atlieka kreipimąsi į kontraktą.
                if(sender != highestBidder){
                    // Tikriname ar vartotojo atlikti Bid'ai yra mažesni/lygūs esamam didžiausiam bidui.
                    if(currentBid <= bids[highestBidder]){
                        // jeigu taip, reiškiasi vartotojas nėra pastatęs pakankamai, ir didžiausiu bid'u lieka buvęs bidas.
                        highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
                    }else{
                        // Jeigu ne, reiškiasi vartotojas pastatė daugiau, nei iki šiol buvęs bidas. Tikriname ar jo bidas siekia aukciono kūrėjo nustatytą maks kainą.
                        if(currentBid >= finalPrice){
                            // Jeigu bidas siekia max kainą, tuomet jo bidas prilyginimas max kainai, jis (jo adresas) nustatomas kaip didžiausias bideris. Aukcionas baigiamas. (State.Ended)
                            currentBid = finalPrice;
                            highestBidder = payable(sender);
                            auctionState = State.Ended;
                        }else{
                            // Jeigu bidas nesiekia max kainos, tuomet nustatomas naujas didžiausias bidas, ir atnaujinamas didžiausiass bidersi (adresas).
                            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
                            highestBidder = payable(sender);
                        }
                    } 
                }else{
                    // Jeigu bidą atlieka tas pats adresas, kuris ir dabar yra didžiausias bideris, didžiausio bido suma nepasikeičia, ir jis išlieka didžiausiu bideriu.
                    highestBindingBid = highestBindingBid;
                    highestBidder = payable(sender);
                }
            }else{
                // Jeigu dabartinis blokas aplenkia nurodytą bloką, aukcionas laikomas pasibaigusiu. (State.Ended)
                auctionState = State.Ended;
            }
        }
    }


    // funkcija inicijuojama, kai baigiasi aukciono laikas, atliekami pervedimai bideriams priklausomai nuo aukciono rezultatų
    function finishAuction(address _sender) public{
        address sender = _sender;
        require(auctionState == State.UserCancelled || block.number > endBlock || auctionState == State.Ended || auctionState == State.Failed);
        require(sender == auctionOwner || bids[sender]>0);
        
        address payable recipient;
        uint value;

        if(highestBindingBid < minPrice){
            recipient = payable(sender);
            value = bids[sender];
        }else{
            if(sender == auctionOwner){
                recipient = auctionOwner;
                value = highestBindingBid;
            }else{
                if(sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{
                    recipient = payable(sender);
                    value = bids[sender];
                }
            }
        }
        bids[recipient] = 0;
        recipient.transfer(value);
        auctionState = State.Ended;
    }

    // solidity neturi math funkcijų, todėl pasidarom MIN funkciją patys, kuri pritraukta prie aukciono logikos.
    // pirmesnis bidas bus grąžinamas, net ir jei antras lygus jam. Tai yra pirmesnis bidas laimi.
    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }

    // funkcija owneriui atšaukti aukciono kontraktą
    function cancelAuction(address _sender) public{
        address sender = _sender;
        require(sender == auctionOwner);
        auctionState = State.UserCancelled;
    }

    function returnState() external view returns (string memory) {
        State temp = auctionState;
        if (temp == State.Ongoing) return "Ongoing";
        if (temp == State.Ended) return "Ended";
        if (temp == State.UserCancelled) return "UserCanceled";
        if (temp == State.Failed) return "Failed";
        return "";
    }

    function currentBlockNumber() public view returns(uint256){
        uint currentBlock = block.number;
        return currentBlock;
    }

    function blocksLeft() public view returns(uint){
        uint currentBlock = block.number;
        if(endBlock - currentBlock >= 0){
            return endBlock - currentBlock;
        }else{
            return 0;
        }
    }

}