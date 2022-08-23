/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Vomo_Presale_Airdrop_ICO {
    // Fields:
    string public constant name = "VomoVerse";
    string public constant symbol = "Vomo";
    uint256 constant decimals = 18;
    uint256 public Presale_Price = 70921; // per 1 Ether
    uint256 public Token_Soft_Cap = 105000000000000000000000000;
    uint256 public Softcap_Price = 35587;
    uint256 public Token_Hard_Cap = 105000000000000000000000000;
    uint256 public Hardcap_Price = 17793;
    uint256 public Listing_Price = 14416;

    enum State {
        Init,
        Running
    }
    uint256 public presale_TransactionFee;
    uint256 public refBuy_Transactionfee;
    uint256 public softcap_TransactionFee;
    uint256 public hardcap_TransactionFee;
    uint256 public listing_Transactionfee;
    uint256 public presaleBalance;
    uint256 public softcapBalance;
    uint256 public hardcapBalance;
    uint256 public listingBalance;
    uint256 public airdropBalance;
    uint256 public Presale_Start_Countdown;
    uint256 public Presale_End_Countdown;
    uint256 public Softcap_End_Countdown;
    uint256 public Hardcap_End_Countdown;
    uint256 presaleSupply_;
    address funder1;
    address funder2;
    address funder3;
    address Development;
    address Marketing;
    address Community;
    address TokenStability;
    address Referral;
    State currentState = State.Running;
    uint256 public Presale_initialToken = 0; //inital presale sold
    uint256 public Softcap_initialToken = 0; //initial softcap sold
    uint256 public Hardcap_initialToken = 0; //intial hardcap sold
    uint256 public Listing_initialToken = 0; //inital listing
    uint256 public Airdrop_initialToken = 0; // initial airdrop
    uint256 DropTokens;
    // Gathered funds can be withdrawn only to escrow's address.
    address public escrow;
    mapping(address => uint256) private balance;
    mapping(address => bool) ownerAppended;
    address[]  owners;

    /// Modifiers:
    modifier onlyInState(State state) {
        require(state == currentState);
        _;
    }

    /// Events:

    event presaleTransfer(
        address indexed from,
        address indexed to,
        uint256 _value
    );
    event referalTransfer(
        address indexed from,
        address indexed to,
        uint256 _value
    );
    event AirdropTransfer(
        address indexed from,
        address indexed to,
        uint256 _value
    );
    event softcapTransfer(
        address indexed from, 
        address indexed to, 
        uint256 _value
        );
    event hardcapTransfer(
        address indexed from, 
        address indexed to, 
        uint256 _value
        );
    event listingTransfer(
        address indexed from, 
        address indexed to, 
        uint256 _value
        );
    event presaleStart(
        uint256 timestamp
        );
    event presaleEnd(
        uint256 timestamp
        );
    event softcapEnd(
        uint256 timestamp
        );
    event hardcapEnd(
        uint256 timestamp
        );
    event PresaleEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );
    event SoftcapEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );
    event HardcapEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );
     event ListingEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );

    /// Functions:
    constructor(
        address _escrow,
        address _funder1,
        address _funder2,
        address _funder3,
        address _Development,
        address _Marketing,
        address _Community,
        address _TokenStability
    ) {
        require(_escrow != address(0));
        escrow = _escrow;
        presaleSupply_ = 3000000000000000000000000;
        funder1 = _funder1;
        funder2 = _funder2;
        funder3 = _funder3;
        Development = _Development;
        Marketing = _Marketing;
        Community = _Community;
        TokenStability = _TokenStability;
        balance[escrow] += DropTokens;
        balance[escrow] += presaleSupply_;
        balance[escrow] += Token_Soft_Cap;
        balance[escrow] += Token_Hard_Cap;
    }

    function Timestamp(
        uint256 _Presale_Start_Countdown,
        uint256 _Presale_End_Countdown,
        uint256 _Softcap_End_Countdown,
        uint256 _Hardcap_End_Countdown
    ) public {
        require(msg.sender == owner, "Set Only Admin");
        Presale_Start_Countdown = _Presale_Start_Countdown;
        Presale_End_Countdown = _Presale_End_Countdown;
        Softcap_End_Countdown = _Softcap_End_Countdown;
        Hardcap_End_Countdown = _Hardcap_End_Countdown;
        emit presaleStart(Presale_Start_Countdown);
        emit presaleEnd(Presale_End_Countdown);
        emit softcapEnd(Softcap_End_Countdown);
        emit hardcapEnd(Hardcap_End_Countdown);
    }

    function setAirdrop(uint256 _DropTokens) public {
        require(msg.sender == owner, "Set Only Admin");
        DropTokens = _DropTokens;
    }

    function buyTokens(address _buyer, address _referral)
        public
        payable
        onlyInState(State.Running)
    {
        Referral = _referral;
        require(Presale_Start_Countdown != 0, "Set Presale Start Date....!");
        require(Presale_End_Countdown != 0, "Set Presale End Date....!");
        require(Softcap_End_Countdown != 0, "Set Softcap End Date....!");
        require(Hardcap_End_Countdown != 0, "Set Hardcap End Date....!");
        require(Referral != _buyer, "Buyer cannot self referal");
        require(
            block.timestamp >= Presale_Start_Countdown,
            "Presale will Start Soon.."
        );
        require(msg.value != 0);

        //Presale
        if (block.timestamp <= Presale_End_Countdown) {
            uint256 PrebuyerTokens = msg.value * Presale_Price;
            if (PrebuyerTokens > 38461538000000000000000) {
                uint256 presaleBuy_Transactionfee = 384615385000000000000;
                uint256 actual_PrebuyerTokens = PrebuyerTokens -
                    presaleBuy_Transactionfee;
                uint256 reftokensVal = msg.value * Presale_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                presale_TransactionFee =
                    presaleBuy_Transactionfee +
                    refBuy_Transactionfee;
                balance[escrow] += presale_TransactionFee;
                require(
                    Presale_initialToken + PrebuyerTokens <= presaleSupply_
                );
                balance[_buyer] += actual_PrebuyerTokens;
                Presale_initialToken += PrebuyerTokens;
                balance[escrow] = presaleSupply_ - Presale_initialToken;
                uint256 _presaleBalance = balance[escrow];
                presaleBalance = _presaleBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit presaleTransfer(escrow, _buyer, actual_PrebuyerTokens);
                emit PresaleEthToVomo(msg.value, actual_PrebuyerTokens);
            } else {
                uint256 presaleBuy_Transactionfee = (Presale_Price / 100) * 1;
                uint256 actual_Presale_Price = Presale_Price -
                    presaleBuy_Transactionfee;
                uint256 actual_PrebuyerTokens = msg.value *
                    actual_Presale_Price;
                uint256 reftokensVal = msg.value * Presale_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                presale_TransactionFee =
                    presaleBuy_Transactionfee +
                    refBuy_Transactionfee;
                balance[escrow] += presale_TransactionFee;

                require(
                    Presale_initialToken + PrebuyerTokens <= presaleSupply_
                );

                balance[_buyer] += actual_PrebuyerTokens;

                Presale_initialToken += PrebuyerTokens;
                balance[escrow] = presaleSupply_ - Presale_initialToken;
                uint256 _presaleBalance = balance[escrow];
                presaleBalance = _presaleBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit presaleTransfer(escrow, _buyer, actual_PrebuyerTokens);
                emit PresaleEthToVomo(msg.value, actual_PrebuyerTokens);
            }
        }
        //SoftCap
        else if (block.timestamp <= Softcap_End_Countdown) {
            uint256 SoftbuyerTokens = msg.value * Softcap_Price;
            if (SoftbuyerTokens > 38461538000000000000000) {
                uint256 softcapBuy_Transactionfee = 384615385000000000000;
                uint256 actual_SoftbuyerTokens = SoftbuyerTokens -
                    softcapBuy_Transactionfee;
                uint256 reftokensVal = msg.value * Softcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                softcap_TransactionFee =
                    softcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += softcap_TransactionFee;

                uint256 totalSoftcap = Token_Soft_Cap + presaleBalance;
                require(Softcap_initialToken + SoftbuyerTokens <= totalSoftcap);

                balance[_buyer] += actual_SoftbuyerTokens;

                Softcap_initialToken += SoftbuyerTokens;
                balance[escrow] = totalSoftcap - Softcap_initialToken;
                uint256 _softcapBalance = balance[escrow];
                softcapBalance = _softcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit softcapTransfer(escrow, _buyer, actual_SoftbuyerTokens);
                emit SoftcapEthToVomo(msg.value, actual_SoftbuyerTokens);
            } else {
                uint256 softcapBuy_Transactionfee = (Softcap_Price / 100) * 1;
                uint256 actual_Softcap_Price = Softcap_Price -
                    softcapBuy_Transactionfee;
                uint256 actual_SoftbuyerTokens = msg.value *
                    actual_Softcap_Price;
                uint256 reftokensVal = msg.value * Softcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                softcap_TransactionFee =
                    softcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += softcap_TransactionFee;

                uint256 totalSoftcap = Token_Soft_Cap + presaleBalance;
                require(Softcap_initialToken + SoftbuyerTokens <= totalSoftcap);

                balance[_buyer] += actual_SoftbuyerTokens;

                Softcap_initialToken += SoftbuyerTokens;
                balance[escrow] = totalSoftcap - Softcap_initialToken;
                uint256 _softcapBalance = balance[escrow];
                softcapBalance = _softcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit softcapTransfer(escrow, _buyer, actual_SoftbuyerTokens);
                emit SoftcapEthToVomo(msg.value, actual_SoftbuyerTokens);
            }
        }
        //HardCap
        else if (block.timestamp <= Hardcap_End_Countdown) {
            uint256 hardbuyerTokens = msg.value * Hardcap_Price;
            if (hardbuyerTokens > 38461538000000000000000) {
                uint256 hardcapBuy_Transactionfee = 384615385000000000000;
                uint256 actual_hardbuyerTokens = hardbuyerTokens -
                    hardcapBuy_Transactionfee;
                uint256 reftokensVal = msg.value * Hardcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                hardcap_TransactionFee =
                    hardcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += hardcap_TransactionFee;

                uint256 totalhardcap = Token_Hard_Cap + softcapBalance;
                require(Hardcap_initialToken + hardbuyerTokens <= totalhardcap);

                balance[_buyer] += actual_hardbuyerTokens;

                Hardcap_initialToken += hardbuyerTokens;
                balance[escrow] = totalhardcap - Hardcap_initialToken;
                uint256 _hardcapBalance = balance[escrow];
                hardcapBalance = _hardcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit hardcapTransfer(escrow, _buyer, actual_hardbuyerTokens);
                emit HardcapEthToVomo(msg.value, actual_hardbuyerTokens);
            } else {
                uint256 hardcapBuy_Transactionfee = (Hardcap_Price / 100) * 1;
                uint256 actual_Hardcap_Price = Hardcap_Price -
                    hardcapBuy_Transactionfee;
                uint256 actual_hardbuyerTokens = msg.value *
                    actual_Hardcap_Price;
                uint256 reftokensVal = msg.value * Hardcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                hardcap_TransactionFee =
                    hardcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += hardcap_TransactionFee;

                uint256 totalhardcap = Token_Hard_Cap + softcapBalance;
                require(Hardcap_initialToken + hardbuyerTokens <= totalhardcap);

                balance[_buyer] += actual_hardbuyerTokens;

                Hardcap_initialToken += hardbuyerTokens;
                balance[escrow] = totalhardcap - Hardcap_initialToken;
                uint256 _hardcapBalance = balance[escrow];
                hardcapBalance = _hardcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit hardcapTransfer(escrow, _buyer, actual_hardbuyerTokens);
                emit HardcapEthToVomo(msg.value, actual_hardbuyerTokens);
            }
        }
        //Listing Price
        else {
            uint256 listbuyerTokens = msg.value * Listing_Price;
            if (listbuyerTokens > 38461538000000000000000) {
                uint256 listingbuy_Transactionfee = 384615385000000000000;
                uint256 actual_listbuyerTokens = listbuyerTokens -
                    listingbuy_Transactionfee;
                uint256 reftokensVal = msg.value * Listing_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                listing_Transactionfee =
                    listingbuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += listing_Transactionfee;

                uint256 totallisting = hardcapBalance;
                require(Listing_initialToken + listbuyerTokens <= totallisting);

                balance[_buyer] += actual_listbuyerTokens;

                Listing_initialToken += listbuyerTokens;
                balance[escrow] = totallisting - Listing_initialToken;
                uint256 _listingBalance = balance[escrow];
                listingBalance = _listingBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit listingTransfer(escrow, _buyer, actual_listbuyerTokens);
                emit ListingEthToVomo(msg.value, actual_listbuyerTokens);
            } else {
                uint256 listingbuy_Transactionfee = (Listing_Price / 100) * 1;
                uint256 actual_Listing_Price = Listing_Price -
                    listingbuy_Transactionfee;
                uint256 actual_listbuyerTokens = msg.value *
                    actual_Listing_Price;
                uint256 reftokensVal = msg.value * Listing_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                listing_Transactionfee =
                    listingbuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += listing_Transactionfee;

                uint256 totallisting = hardcapBalance;
                require(Listing_initialToken + listbuyerTokens <= totallisting);

                balance[_buyer] += actual_listbuyerTokens;

                Listing_initialToken += listbuyerTokens;
                balance[escrow] = totallisting - Listing_initialToken;
                uint256 _listingBalance = balance[escrow];
                listingBalance = _listingBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit listingTransfer(escrow, _buyer, actual_listbuyerTokens);
                emit ListingEthToVomo(msg.value, actual_listbuyerTokens);
            }
        }
        //Distribution crypto into 7 wallets address
        uint256 Balance_funder1 = (msg.value / 100) * 15;
        uint256 Balance_funder2 = (msg.value / 100) * 5;
        uint256 Balance_funder3 = (msg.value / 100) * 5;
        uint256 Balance_Development = (msg.value / 100) * 35;
        uint256 Balance_Marketing = (msg.value / 100) * 25;
        uint256 Balance_Community = (msg.value / 100) * 5;
        uint256 Balance_TokenStability = (msg.value / 100) * 10;

        //Transfer crypto Eth to 7 wallets address
        if (address(this).balance > 0) {
            payable(funder1).transfer(Balance_funder1);
            payable(funder2).transfer(Balance_funder2);
            payable(funder3).transfer(Balance_funder3);
            payable(Development).transfer(Balance_Development);
            payable(Marketing).transfer(Balance_Marketing);
            payable(Community).transfer(Balance_Community);
            payable(TokenStability).transfer(Balance_TokenStability);
        }
    }

    //Airdop
    function AirDrop(address to, uint256 numDropTokens)
        public
        virtual
        returns (bool)
    {
        require(msg.sender == owner);
        require(numDropTokens <= DropTokens);
        require(Airdrop_initialToken + numDropTokens <= DropTokens);
        balance[to] += numDropTokens;
        Airdrop_initialToken += numDropTokens;
        balance[escrow] = DropTokens - Airdrop_initialToken;
        uint256 _airdropBalance = balance[escrow];
        airdropBalance = _airdropBalance;
        if (!ownerAppended[to]) {
            ownerAppended[to] = true;
            owners.push(to);
        }
        emit AirdropTransfer(msg.sender, to, numDropTokens);
        return true;
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) public view virtual returns (uint256) {
        return balance[_owner];
    }

    address public owner;

    // Transfer Ownership
    function Ownable() public {
        owner = escrow;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}