/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Factory Smart Contract - kontraktas, kuris kuria kitus kontraktus (aukcionus)

contract AuctionCreator {
    // visų sukurtų aukcionų masyvas
    Auction[] public auctions;

    // funkcija sukurianti aukcioną (aukcionų kontraktus)
    function CreateAuction(
        uint256 duration,
        uint256 finalPrice,
        uint256 minPrice,
        uint256 qnty
    ) public {
        require(minPrice <= finalPrice);
        require(qnty > 0);
        Auction newAuction = new Auction(
            duration,
            finalPrice,
            minPrice,
            qnty,
            msg.sender
        );
        auctions.push(newAuction);
    }

    // --- Duomenų nuskaitymas iš kontraktų masyvo

    // Grąžina masyvo ilgį (sukurtų aukcionų skaičių)
    function getAuctionCount() public view returns (uint256) {
        return auctions.length;
    }

    // Grąžina visą aukcionų masyvą ([address1, address2, address3, ...])
    function getAuctions() public view returns (Auction[] memory) {
        return auctions;
    }

    // --- Duomenų nuskaitymas iš jau sukurtų aukcionų, kreipiantis į kontraktą, pagal indeks'ą masyve.

    // Grąžinamas aukciono kūrėjo piniginės adresas (auctionOwner)
    function getAuctionOwner(uint256 _auctionIndex)
        public
        view
        returns (address)
    {
        return Auction(address(auctions[_auctionIndex])).auctionOwner();
    }

    // Grąžinamas didžiausią statymą atlikęs adresas (highestBidder)
    function getHighestBidder(uint256 _auctionIndex)
        public
        view
        returns (address)
    {
        return Auction(address(auctions[_auctionIndex])).highestBidder();
    }

    // Grąžinamas didžiausias statymas (highestBindingBid)
    function getHighestBindingBid(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        return Auction(address(auctions[_auctionIndex])).highestBindingBid();
    }

    // Grąžinamas aukciono kontrakto balansas (visų pervedimų laikomų kontrakte suma)
    function getBalance(uint256 _auctionIndex) public view returns (uint256) {
        return Auction(address(auctions[_auctionIndex])).balance();
    }

    // Grąžinamas aukcionos kontrakto parametras - minimali kaina (minPrice)
    function getAuctionMinPrice(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        return Auction(address(auctions[_auctionIndex])).minPrice();
    }

    // Grąžinamas aukcionos kontrakto parametras - maksimali kaina (finalPrice)
    function getAuctionFinalPrice(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        return Auction(address(auctions[_auctionIndex])).finalPrice();
    }

    // Grąžinamas aukcionos kontrakto parametras - trukmė blokais (auctionDuration)
    function getAuctionDuration(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        return Auction(address(auctions[_auctionIndex])).auctionDuration();
    }

    // Grąžinama aukciono stadija (returnState)
    function getAuctionState(uint256 _auctionIndex)
        public
        view
        returns (string memory)
    {
        return Auction(address(auctions[_auctionIndex])).returnState();
    }

    // Grąžinamas dabartinio iškasto bloko numeris (currentBlockNumber)
    function getCurrentBlock(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        return Auction(address(auctions[_auctionIndex])).currentBlockNumber();
    }

    // Grąžinama aukciono trukmė blokais, tai yra kiek liko blokų (blocksLeft)
    function getBlocksLeft(uint _auctionIndex)
        public
        view
        returns (uint)
    {
        return Auction(address(auctions[_auctionIndex])).blocksLeft();
    }

    // Grąžinama paskutinis blokas (currentBlock + auctionDuration)
    function getEndBlock(uint256 _auctionIndex) public view returns (uint256) {
        return Auction(address(auctions[_auctionIndex])).endBlock();
    }

    // Grąžinamas nurodytas aukcione kiekis (qnty)
    function getQnty(uint256 _auctionIndex) public view returns (uint256) {
        return Auction(address(auctions[_auctionIndex])).qnty();
    }

    // Grąžinami visi atlikti statymai pagal pinginės adresą (bids(msg.sender))
    function getUserBids(uint256 _auctionIndex) public view returns (uint256) {
        return Auction(address(auctions[_auctionIndex])).bids(msg.sender);
    }

    // --- Payable funkcijos kurios keičia blokų grandinės kintamųjų reikšmes

    // Pagrindinė aukciono funkcija, atlikti statymui, laiminčių statymų nustatymas
    function placeBid(uint256 _auctionIndex) public payable {
        uint256 bid = msg.value;
        Auction(address(auctions[_auctionIndex])).placeBid{value: bid}(
            msg.sender
        );
    }

    // Sukurto aukciono atšaukimas (pakeičia aukciono būseną auctionState)
    function cancelAuction(uint256 _auctionIndex) public {
        Auction(address(auctions[_auctionIndex])).cancelAuction(msg.sender);
    }

    // Aukciono užbaigimo funkcija. Inicijuoja pervedimus iš laikomo balanso, pagal apibrėžtas sąlygas
    function finishAuction(uint256 _auctionIndex) public {
        Auction(address(auctions[_auctionIndex])).finishAuction(msg.sender);
    }
}

// Aukciono kontraktas, kuriame apibrėžiamos aukciono kintamieji, funkcijos ir logika

contract Auction {
    // kintamieji
    address payable public auctionOwner; // aukciono savininko adresas
    uint256 public finalPrice; // savininko nustatyta didžiausia kaina
    uint256 public minPrice; // savininko nustatyta minimali kaina
    uint256 public auctionDuration; // savininko nurodytas blokų skaičius (aukciono trukmė)
    uint256 public qnty; // savininko nurodytas aukcionuojamas kiekis
    uint256 public startBlock; // bloko numeris, kai sukuriamas aukcionas
    uint256 public endBlock; // paskutinis bloko numeris, iki kurio truks aukcionas (startBlock + auctionDuration)

    // state kintamasis aukciono būsenos sekimui, patys save paaiškina
    enum State {
        Ongoing,
        Ended,
        UserCancelled,
        Failed
    }

    State public auctionState;

    uint256 public highestBindingBid; // didžiausias aukciono statymas
    address payable public highestBidder; // didžiausią statymą atlikęs adresas

    // visi statymai talpinami į bids masyvą - {adresas: statymas}
    mapping(address => uint256) public bids;

    uint256 bidIncrement; // automatizuojant aukcioną, žingsnis, kuriuo bus aplenkiamas didžiausias statymas

    // konstruktorius, tai yra kintamieji, kurie įgija reikšmes iškart sukūrus kontraktą. Dalis reikšmių turi būti perduodama funckijos parametrais, kita dalis nustatoma.
    constructor(
        uint256 _duration,
        uint256 _finalPrice,
        uint256 _minPrice,
        uint256 _qnty,
        address eoa
    ) {
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

    modifier notOwner() {
        require(msg.sender != auctionOwner, "Auction owner, cannot bid");
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock, "Auction has not started");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "Auction has ended");
        _;
    }

    // Pagrindinė aukciono funkcija
    function placeBid(address _sender) public payable {
        require(msg.sender != auctionOwner, "Auction owner, cannot bid");
        require(block.number >= startBlock, "Auction has not started");
        require(msg.sender != auctionOwner, "Auction owner, cannot bid");
        require(msg.value >= bidIncrement, "Bid should be atleast 100 wei");
        require(
            auctionState == State.Ongoing,
            "Auction has ended or cancelled"
        );

        address sender = _sender; // siuntėjo adresas

        uint256 currentBid = bids[sender] + msg.value; // esamas statymas yra anksčiau buvę adreso statymai + dabar siunčiama suma msg.value

        require(currentBid > highestBindingBid);
        require(
            currentBid <= finalPrice,
            "Bid should be not more than max Price"
        );
        require(highestBindingBid <= finalPrice);

        bids[sender] = currentBid; // adreso statymai priskiriami key: value mapping'ui {sender address: currentBid}

        // Tikrina ar dabartinis bloko nr. yra didsnis už aukciono skelbėjo nurodytą paskutinį bloko numerį (trukmė) ir ar aukcionas pasiekė minimalią kainą
        if (block.number >= endBlock && highestBindingBid < minPrice) {
            // Jeigu bloko nr. didesnis už nurodyto bloko numerį - reiškia aukcionas baigėsi. Jeigu didžiausias statymas nepasiekė minimalios kainos - aukcionas laikomas neįvykusiu. (State.Failed)
            auctionState = State.Failed;
        } else {
            // Toliau tikrinam ar dabartinis bloko nr. yra mažesnis už nurodyto bloko numerį.
            if (block.number < endBlock) {
                // Jeigu numeris mažesnis, reiškiasi aukcionas yra aktyvus. Pirmiausia tikriname, ar aukščiausią statymą turintis adresas yra lygus adresui kuris dabar atlieka kreipimąsi į kontraktą.
                if (sender != highestBidder) {
                    // Tikriname ar vartotojo atlikti Bid'ai yra mažesni/lygūs esamam didžiausiam bidui.
                    if (currentBid <= bids[highestBidder]) {
                        // jeigu taip, reiškiasi vartotojas nėra pastatęs pakankamai, ir didžiausiu bid'u lieka buvęs bidas.
                        highestBindingBid = min(
                            currentBid + bidIncrement,
                            bids[highestBidder]
                        );
                    } else {
                        // Jeigu ne, reiškiasi vartotojas pastatė daugiau, nei iki šiol buvęs bidas. Tikriname ar jo bidas siekia aukciono kūrėjo nustatytą maks kainą.
                        if (currentBid >= finalPrice) {
                            // Jeigu bidas siekia max kainą, tuomet jo bidas prilyginimas max kainai, jis (jo adresas) nustatomas kaip didžiausias bideris. Aukcionas baigiamas. (State.Ended)
                            currentBid = finalPrice;
                            highestBidder = payable(sender);
                            auctionState = State.Ended;
                        } else {
                            // Jeigu bidas nesiekia max kainos, tuomet nustatomas naujas didžiausias bidas, ir atnaujinamas didžiausiass bidersi (adresas).
                            highestBindingBid = min(
                                currentBid,
                                bids[highestBidder] + bidIncrement
                            );
                            highestBidder = payable(sender);
                        }
                    }
                } else {
                    // Jeigu bidą atlieka tas pats adresas, kuris ir dabar yra didžiausias bideris, didžiausio bido suma nepasikeičia, ir jis išlieka didžiausiu bideriu.
                    highestBindingBid = highestBindingBid;
                    highestBidder = payable(sender);
                }
            } else {
                // Jeigu dabartinis blokas aplenkia nurodytą bloką, aukcionas laikomas pasibaigusiu. (State.Ended)
                auctionState = State.Ended;
            }
        }
    }

    // funkcija inicijuojama, kai baigiasi aukciono laikas, atliekami pervedimai bideriams priklausomai nuo aukciono rezultatų. Funckija nėra automatinė, tai reiškia, kad kiekvienas aukciono dalyvis turi paprašyti pervedimo.
    function finishAuction(address _sender) public {
        address sender = _sender; // priskiriamas siuntėjo adresas
        require(
            auctionState == State.UserCancelled ||
                block.number > endBlock ||
                auctionState == State.Ended ||
                auctionState == State.Failed
        );
        require(sender == auctionOwner || bids[sender] > 0);

        address payable recipient; // sukuriamas recipient kintamasis (adresas), į kurį funkcija atliks pervedimus
        uint256 value; // pervedimo sumos kintamasis

        // Jeigu pasibaigus aukcionui didžiausias statymas nesiekia minimalios nustatytos kainos, aukcionas neįvykę, ir visi atlikę statymus, juos susigrąžina
        if (highestBindingBid < minPrice) {
            recipient = payable(sender);
            value = bids[sender];
        } else {
            // Tikrina, ar siuntėjas yra aukciono savininkas. Jeigu taip, gavėjas nustatomas savininkas, o pervedama suma yra didžiausias statymas
            if (sender == auctionOwner) {
                recipient = auctionOwner;
                value = highestBindingBid;
                // Jeigu siuntėjas nėra savininkas
            } else {
                // Tikriname ar siuntėjas yra didžiausią statymą atlikęs aukciono dalyvis. Jeigu taip jam grąžinamas skirtumas, tarp jo atliktų statymų ir laimėjusio statymo dydžio
                if (sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                    // Jeigu siuntėjas nėra aukciono laimėtojas, jam grąžinami visi jo atlikti statymai
                } else {
                    recipient = payable(sender);
                    value = bids[sender];
                }
            }
        }
        // Atlikto adreso statymai nustatomi 0, taip apsisaugoma, kad tas pats adresas, negalėtų pakartotinai prašyti pervedimų į savo piniginę
        bids[recipient] = 0;
        // Gavėjui pervedama jam priklausanti suma
        recipient.transfer(value);
        //Atnaujinama aukciono stadiją į Ended.
        auctionState = State.Ended;
    }

    // Solidity neturi math funkcijų, todėl pasidarom MIN funkciją patys, kuri pritraukta prie aukciono logikos.
    // Pirmesnis bidas bus grąžinamas, net ir jei antras lygus jam. Tai yra pirmesnis bidas laimi.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    // Funkcija aukciono savininkui atšaukti aukciono kontraktą. Pats kontraktas liekas, tiesiog pakeičiama jo būsena į UserCancelled
    function cancelAuction(address _sender) public {
        address sender = _sender;
        require(sender == auctionOwner);
        auctionState = State.UserCancelled;
    }

    // Funkcija grąžina aukciono stadiją, kaip stringą. Įprastai grąžintų indeksą (0, 1, 2, 3). Toks formatas lengviau interpretuojamas Front-end aplikacijoje.
    function returnState() external view returns (string memory) {
        State temp = auctionState;
        if (temp == State.Ongoing) return "Ongoing";
        if (temp == State.Ended) return "Ended";
        if (temp == State.UserCancelled) return "UserCancelled";
        if (temp == State.Failed) return "Failed";
        return "";
    }

    // Grąžina dabartinį grandinės bloko numerį
    function currentBlockNumber() public view returns (uint256) {
        uint256 currentBlock = block.number;
        return currentBlock;
    }

    // Grąžina blokų skaičių iki aukciono pabaigos. Jeigu aukcionas baigėsi, grąžina 0.
    function blocksLeft() public view returns (uint) {
        uint currentBlock = block.number;
        if (endBlock - currentBlock >= 0) {
            return endBlock - currentBlock;
        } else {
            return 0;
        }
    }

    // Grąžina į kontrakto balansą. Tai yra visi bidai, kurie yra atlikti į kontraktą.
    function balance() public view returns (uint256) {
        return payable(address(this)).balance;
    }
}