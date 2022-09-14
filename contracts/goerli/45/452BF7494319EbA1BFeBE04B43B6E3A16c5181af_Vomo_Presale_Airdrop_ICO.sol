/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract Vomo_Presale_Airdrop_ICO {
    string public constant name = "VomoVerse";
    string public constant symbol = "Vomo";
    uint256 constant decimals = 18;
    uint256 public Presale_Price = 70921; // per 1 Ether
    uint256 public Token_Soft_Cap = 105000000000000000000000000;
    uint256 public Softcap_Price = 35587;
    uint256 public Token_Hard_Cap = 105000000000000000000000000;
    uint256 public Hardcap_Price = 17793;
    uint256 public Listing_Price = 14416;
    address public owner;
    enum State {
        Init,
        Running
    }
    uint256 Trassaction_time;
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
    event Trassaction_timeEvent(
        uint256 Trassaction_time
    );

    /// Functions:
    constructor(
        address _escrow

    ) {
        require(_escrow != address(0));
        escrow = _escrow;
        presaleSupply_ = 3000000000000000000000000;
        balance[escrow] += DropTokens;
        balance[escrow] += presaleSupply_;
        balance[escrow] += Token_Soft_Cap;
        balance[escrow] += Token_Hard_Cap;
        owner=escrow;
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

    function IbuyTokens(address _buyer, address _referral, uint256 _amount, uint256 _numToken)
        public
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

        //Presale
        if (block.timestamp <= Presale_End_Countdown) {
            Trassaction_time = block.timestamp;
            uint256 PrebuyerTokens = _numToken;
            if (PrebuyerTokens > 38461538000000000000000) {
                uint256 presaleBuy_Transactionfee = 384615385000000000000;
                uint256 actual_PrebuyerTokens = PrebuyerTokens -
                    presaleBuy_Transactionfee;
                uint256 reftokensVal = _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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
                Presale_initialToken += _numToken;
                balance[escrow] = presaleSupply_ - Presale_initialToken;
                uint256 _presaleBalance = balance[escrow];
                presaleBalance = _presaleBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit presaleTransfer(escrow, _buyer, actual_PrebuyerTokens);
                emit PresaleEthToVomo(_amount, actual_PrebuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            } else {
                uint256 presaleBuy_Transactionfee = (_numToken / 100) * 1;
                uint256 actual_Presale_Price = _numToken -
                    presaleBuy_Transactionfee;
                uint256 actual_PrebuyerTokens = actual_Presale_Price;
                uint256 reftokensVal = _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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

                Presale_initialToken += _numToken;
                balance[escrow] = presaleSupply_ - Presale_initialToken;
                uint256 _presaleBalance = balance[escrow];
                presaleBalance = _presaleBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit presaleTransfer(escrow, _buyer, actual_PrebuyerTokens);
                emit PresaleEthToVomo(_amount, actual_PrebuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            }
        }
        //SoftCap
        else if (block.timestamp <= Softcap_End_Countdown) {
            Trassaction_time = block.timestamp;
            uint256 SoftbuyerTokens = _numToken;
            if (SoftbuyerTokens > 38461538000000000000000) {
                uint256 softcapBuy_Transactionfee = 384615385000000000000;
                uint256 actual_SoftbuyerTokens = SoftbuyerTokens -
                    softcapBuy_Transactionfee;
                uint256 reftokensVal = _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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

                Softcap_initialToken += _numToken;
                balance[escrow] = totalSoftcap - Softcap_initialToken;
                uint256 _softcapBalance = balance[escrow];
                softcapBalance = _softcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit softcapTransfer(escrow, _buyer, actual_SoftbuyerTokens);
                emit SoftcapEthToVomo(_amount, actual_SoftbuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            } else {
                uint256 softcapBuy_Transactionfee = (_numToken / 100) * 1;
                uint256 actual_Softcap_Price = _numToken -
                    softcapBuy_Transactionfee;
                uint256 actual_SoftbuyerTokens =
                    actual_Softcap_Price;
                uint256 reftokensVal = _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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

                Softcap_initialToken += _numToken;
                balance[escrow] = totalSoftcap - Softcap_initialToken;
                uint256 _softcapBalance = balance[escrow];
                softcapBalance = _softcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit softcapTransfer(escrow, _buyer, actual_SoftbuyerTokens);
                emit SoftcapEthToVomo(_amount, actual_SoftbuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            }
        }
        //HardCap
        else if (block.timestamp <= Hardcap_End_Countdown) {
            Trassaction_time = block.timestamp;
            uint256 hardbuyerTokens =  _numToken;
            if (hardbuyerTokens > 38461538000000000000000) {
                uint256 hardcapBuy_Transactionfee = 384615385000000000000;
                uint256 actual_hardbuyerTokens = hardbuyerTokens -
                    hardcapBuy_Transactionfee;
                uint256 reftokensVal = _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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

                Hardcap_initialToken += _numToken;
                balance[escrow] = totalhardcap - Hardcap_initialToken;
                uint256 _hardcapBalance = balance[escrow];
                hardcapBalance = _hardcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit hardcapTransfer(escrow, _buyer, actual_hardbuyerTokens);
                emit HardcapEthToVomo(_amount, actual_hardbuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            } else {
                uint256 hardcapBuy_Transactionfee = (_numToken / 100) * 1;
                uint256 actual_Hardcap_Price = _numToken -
                    hardcapBuy_Transactionfee;
                uint256 actual_hardbuyerTokens = 
                    actual_Hardcap_Price;
                uint256 reftokensVal =  _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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

                Hardcap_initialToken += _numToken;
                balance[escrow] = totalhardcap - Hardcap_initialToken;
                uint256 _hardcapBalance = balance[escrow];
                hardcapBalance = _hardcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit hardcapTransfer(escrow, _buyer, actual_hardbuyerTokens);
                emit HardcapEthToVomo(_amount, actual_hardbuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            }
        }
        //Listing Price
        else {
            uint256 listbuyerTokens = _numToken;
            Trassaction_time = block.timestamp;
            if (listbuyerTokens > 38461538000000000000000) {
                uint256 listingbuy_Transactionfee = 384615385000000000000;
                uint256 actual_listbuyerTokens = listbuyerTokens -
                    listingbuy_Transactionfee;
                uint256 reftokensVal = _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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

                Listing_initialToken += _numToken;
                balance[escrow] = totallisting - Listing_initialToken;
                uint256 _listingBalance = balance[escrow];
                listingBalance = _listingBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit listingTransfer(escrow, _buyer, actual_listbuyerTokens);
                emit ListingEthToVomo(_amount, actual_listbuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            } else {
                uint256 listingbuy_Transactionfee = (_numToken / 100) * 1;
                uint256 actual_Listing_Price = _numToken -
                    listingbuy_Transactionfee;
                uint256 actual_listbuyerTokens = 
                    actual_Listing_Price;
                uint256 reftokensVal = _amount * _numToken;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (_amount >= 20) {
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

                Listing_initialToken += _numToken;
                balance[escrow] = totallisting - Listing_initialToken;
                uint256 _listingBalance = balance[escrow];
                listingBalance = _listingBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit listingTransfer(escrow, _buyer, actual_listbuyerTokens);
                emit ListingEthToVomo(_amount, actual_listbuyerTokens);
                emit Trassaction_timeEvent(Trassaction_time);
            }
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
        uint256 _airdropBalance = DropTokens - Airdrop_initialToken;
        airdropBalance = _airdropBalance;
        if (!ownerAppended[to]) {
            ownerAppended[to] = true;
            owners.push(to);
        }
        emit AirdropTransfer(msg.sender, to, numDropTokens);
        return true;
    }

    /// @dev Returns number of tokens owned by given address.
    function balanceOf(address _owner) public view virtual returns (uint256) {
        return balance[_owner];
    }
    modifier onlyOwner() {
        require(msg.sender == owner,"You are not owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}