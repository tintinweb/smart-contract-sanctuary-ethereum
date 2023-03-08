// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.8.5; 

import "./IGBM.sol";
import "./IGBMInitiator.sol";
import "../tokens/IERC20.sol";
import "../tokens/IERC721.sol";
import "../tokens/IERC721TokenReceiver.sol";
import "../tokens/IERC1155.sol";
import "../tokens/IERC1155TokenReceiver.sol";
import "../tokens/Ownable.sol";

/// @title GBM auction contract
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud and Javier Fraile
contract GBM is IGBM, IERC1155TokenReceiver, IERC721TokenReceiver {

    //Struct used to store the representation of an NFT being auctionned
    struct token_representation {
        address contractAddress; // The contract address
        uint256 tokenID; // The ID of the token on the contract
        bytes4 tokenKind; // The ERC name of the token implementation bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
        uint256 tokenAmount; // Amount of token units under auction
    }

    struct Auction {
        uint256 dueIncentives;         // _auctionID => dueIncentives
        uint256 debt;                  // _auctionID => unsettled debt
        address highestBidder;         // _auctionID => bidder
        uint256 highestBid;            // _auctionID => bid
        bool biddingAllowed;           // tokencontract => Allow to start/pause ongoing auctions

        uint256 startTime;             // _auctionID => timestamp
        uint256 endTime;               // _auctionID => timestamp
        uint256 hammerTimeDuration;    // _auctionID => duration in seconds
        uint256 bidDecimals;           // _auctionID => bidDecimals
        uint256 stepMin;               // _auctionID => stepMin
        uint256 incMin;                // _auctionID => minimal earned incentives
        uint256 incMax;                // _auctionID => maximal earned incentives
        uint256 bidMultiplier;         // _auctionID => bid incentive growth multiplier
    }

    struct Collection {
        uint256 startTime;
        uint256 endTime;
        uint256 hammerTimeDuration;
        uint256 bidDecimals;
        uint256 stepMin;
        uint256 incMin; // minimal earned incentives
        uint256 incMax; // maximal earned incentives
        uint256 bidMultiplier; // bid incentive growth multiplier
        bool biddingAllowed; // Allow to start/pause ongoing auctions
    }

    //The address of the auctionner to whom all profits will be sent
    address public override owner;

    //Contract address storing the ERC20 currency used in auctions

    mapping(uint256 => token_representation) internal tokenMapping; //_auctionID => token_primaryKey
    mapping(address => mapping(bytes4 => mapping(uint256 => mapping(uint256 => uint256)))) auctionMapping; // contractAddress => tokenKind => tokenID => TokenIndex => _auctionID
    mapping(address => mapping(bytes4 => mapping(uint256 => mapping(uint256 => uint256)))) previousAuctionData; // contractAddress => tokenKind => tokenID => TokenIndex => _auctionID
 
    mapping(address => Collection) collections;
    mapping(uint256 => bool) claimed; // _auctionID => claimed Boolean preventing multiple claim of a token

    mapping(uint256 => Auction) auctions;

    mapping(address => mapping(uint256 => uint256)) eRC1155_tokensIndex; //Contract => TokenID => Auction index being auctionned
    mapping(address => mapping(uint256 => uint256)) eRC721_tokensIndex; //Contract => TokenID =>  Auction index being auctionned
    mapping(address => mapping(uint256 => uint256)) eRC1155_tokensUnderAuction; //Contract => TokenID => Amount being auctionned
    
    address beneficiary;

    uint256 auctionTokenIDOneOffRangeStart;
    uint256 auctionTokenIDOneOffRangeEnd;
    

    modifier onlyTokenOwner(address _contract) {
        require(msg.sender == Ownable(_contract).owner(), "Only allowed to the owner of the token contract");
        _;
    }

     modifier onlyThisContractOwner() {
        require(msg.sender == owner, "Only allowed to the owner of this contract");
        _;
    }

    constructor()
    {
        owner = msg.sender;
    }

    function setBeneficiary(address _beneficiary) external {
        require(msg.sender == owner, "Not the owner of the contract");
        beneficiary = _beneficiary;
    }

    /// @notice Place a GBM bid for a GBM auction
    /// @param _auctionID The auction you want to bid on
    /// @param _bidAmount The amount of the ERC20 token the bid is made of. They should be withdrawable by this contract.
    /// @param _highestBid The current higest bid. Throw if incorrect.
    function bid(uint256 _auctionID, uint256 _bidAmount, uint256 _highestBid) external payable override {
        require(tokenMapping[0].contractAddress != address(0x0) && (_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "bid: auctionID does not exist"); //Modified for the one off registration
        require(collections[tokenMapping[0].contractAddress].biddingAllowed, "bid: bidding is currently not allowed");  //Modified for the one off registration
        require(!claimed[_auctionID], "claim: this auction has alredy been claimed");
        
        require(_bidAmount > 1, "bid: _bidAmount cannot be 0");
        require(_highestBid == auctions[_auctionID].highestBid, "bid: current highest bid do not match the submitted transaction _highestBid");

        //An auction start time of 0 also indicate the auction has not been created at all
        require(getAuctionStartTime(_auctionID) <= block.timestamp && getAuctionStartTime(_auctionID) != 0, "bid: Auction has not started yet"); 
        require(getAuctionEndTime(_auctionID) >= block.timestamp, "bid: Auction has already ended");

        require(_bidAmount > _highestBid, "bid: _bidAmount must be higher than _highestBid");
	    require((_highestBid * (getAuctionBidDecimals(_auctionID) + getAuctionStepMin(_auctionID))) <= (_bidAmount * getAuctionBidDecimals(_auctionID)),
            "bid: _bidAmount must meet the minimum bid"
        );
        
        //Transfer the money of the bidder to the GBM smart contract
        require(msg.value == _bidAmount, "The bid amount doesn't match the amount of currency sent");

        //Extend the duration time of the auction if we are close to the end
        if(getAuctionEndTime(_auctionID) < block.timestamp + getHammerTimeDuration(_auctionID)) {
            auctions[_auctionID].endTime = block.timestamp + getHammerTimeDuration(_auctionID);
            emit Auction_EndTimeUpdated(_auctionID, auctions[_auctionID].endTime);
        }

        // Saving incentives for later sending
        uint256 duePay = auctions[_auctionID].dueIncentives;
        address previousHighestBidder = auctions[_auctionID].highestBidder;
        uint256 previousHighestBid = auctions[_auctionID].highestBid;

        // Emitting the event sequence
        if(previousHighestBidder != address(0)) {
            emit Auction_BidRemoved(_auctionID, previousHighestBidder, previousHighestBid);
        }

        if(duePay != 0) {
            auctions[_auctionID].debt = auctions[_auctionID].debt + duePay;
            emit Auction_IncentivePaid(_auctionID, previousHighestBidder, duePay);
        }

        emit Auction_BidPlaced(_auctionID, msg.sender, _bidAmount);

        // Calculating incentives for the new bidder
        auctions[_auctionID].dueIncentives = calculateIncentives(_auctionID, _bidAmount);

        //Setting the new bid/bidder as the highest bid/bidder
        auctions[_auctionID].highestBidder = msg.sender;
        auctions[_auctionID].highestBid = _bidAmount;

        if((previousHighestBid + duePay) != 0) {
            //Refunding the previous bid as well as sending the incentives
            (bool sent, bytes memory data) = previousHighestBidder.call{value: previousHighestBid + duePay}("");
            //Not check to avoid a contract revert in the receive function that locks the auction
            // require(sent, "Failed to refund ETH");
        }
    }

    /// @notice Attribute a token to the winner of the auction and distribute the proceeds to the owner of this contract.
    /// throw if bidding is disabled or if the auction is not finished.
    /// @param _auctionID The auctionID of the auction to complete
    function claim(uint256 _auctionID) external override {
        address _ca = tokenMapping[0].contractAddress;         //Modified for one Off
        uint256 _tid = _auctionID;         //Modified for one Off
        bytes4 _tkd = tokenMapping[0].tokenKind; //Modified for one Off
        uint256 _tam = 1; //Modified for one Off

        require(_ca != address(0x0), "claim: auctionID does not exist");
        require(collections[_ca].biddingAllowed, "claim: Claiming is currently not allowed");
        require(getAuctionEndTime(_auctionID) < block.timestamp, "claim: Auction has not yet ended");

        require(!claimed[_auctionID], "claim: this auction has alredy been claimed");   
        claimed[_auctionID] = true;

        /* 
        //Do not use in current version. We assume approved tokens, not one transferred to the GBM contract.
        if (auctions[_auctionID].highestBid == 0) {
            auctions[_auctionID].highestBidder = Ownable(_ca).owner();
        }   
        */     

        //Transfer the proceeds to the beneficiary
        uint256 finalAmount = auctions[_auctionID].highestBid - auctions[_auctionID].debt;
        require(beneficiary != address(0), "Beneficiary address not set");
        (bool sent, bytes memory data) = beneficiary.call{value: finalAmount}("");
        // require(sent, "Failed to final amount");

        if (_tkd == bytes4(keccak256("ERC721"))) { //0x73ad2146
            IERC721(_ca).safeTransferFrom(owner, auctions[_auctionID].highestBidder, _tid);
            auctionMapping[_ca][_tkd][_tid][0] = 0;
        } else if (_tkd == bytes4(keccak256("ERC1155"))) { //0x973bb640
            IERC1155(_ca).safeTransferFrom(owner, auctions[_auctionID].highestBidder, _tid, _tam, "");
            // eRC1155_tokensUnderAuction[_ca][_tid] = eRC1155_tokensUnderAuction[_ca][_tid] - _tam;
        }

        emit Auction_Claimed(_auctionID);
    }

    /// @notice Register an auction contract default parameters for a GBM auction. To use to save gas
    /// @param _contract The token contract the auctionned token belong to
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract
    function registerAnAuctionContract(address _contract, address _initiator) public override onlyThisContractOwner() {
        collections[_contract].startTime = IGBMInitiator(_initiator).getStartTime(uint256(uint160(_contract)));
        collections[_contract].endTime = IGBMInitiator(_initiator).getEndTime(uint256(uint160(_contract)));
        collections[_contract].hammerTimeDuration = IGBMInitiator(_initiator).getHammerTimeDuration(uint256(uint160(_contract)));
        collections[_contract].bidDecimals = IGBMInitiator(_initiator).getBidDecimals(uint256(uint160(_contract)));
        collections[_contract].stepMin = IGBMInitiator(_initiator).getStepMin(uint256(uint160(_contract)));
        collections[_contract].incMin = IGBMInitiator(_initiator).getIncMin(uint256(uint160(_contract)));
        collections[_contract].incMax = IGBMInitiator(_initiator).getIncMax(uint256(uint160(_contract)));
        collections[_contract].bidMultiplier = IGBMInitiator(_initiator).getBidMultiplier(uint256(uint160(_contract)));
        require(collections[_contract].startTime > 0, "registerAnAuctionContract: Start time is not correct");
    }

    /// @notice Allow/disallow bidding and claiming for a whole token contract address.
    /// @param _contract The token contract the auctionned token belong to
    /// @param _value True if bidding/claiming should be allowed.
    function setBiddingAllowed(address _contract, bool _value) external override onlyThisContractOwner() {
        collections[_contract].biddingAllowed = _value;
    }

    /// @notice Modify the auction of a token
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _auctionID ID of the auction to modify
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract (if wanting to reset to default, 
    /// use an initiator sending back 0 on it's getters)
    function modifyAnAuctionToken(uint256 _auctionID, address _initiator) external override onlyThisContractOwner() {
        modifyAnAuctionToken(_auctionID, 0, _initiator);
    }

    /// @notice Modify the auction of a token
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _auctionID ID of the auction to modify
    /// @param _tokenAmount The amount of tokens being auctionned
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract (if wanting to reset to default, 
    /// use an initiator sending back 0 on it's getters)
    function modifyAnAuctionToken(uint256 _auctionID, uint256 _tokenAmount, address _initiator) public override onlyThisContractOwner() {
        address _ca = tokenMapping[_auctionID].contractAddress;
        bytes4 _tki = tokenMapping[_auctionID].tokenKind;
        uint256 _tid = tokenMapping[_auctionID].tokenID;
        uint256 _tam = tokenMapping[_auctionID].tokenAmount;
        
        require(msg.sender == Ownable(_ca).owner(), "modifyAnAuctionToken: Only the owner of a contract can modify an auction");
        require(_ca != address(0), "modifyAnAuctionToken: Auction ID is not correct");
        require(auctions[_auctionID].startTime > block.timestamp, "modifyAnAuctionToken: Auction has already started");
        require(_initiator != address(0), "modifyAnAuctionToken: Initiator address is not correct");
        
        if (_tam != _tokenAmount && _tokenAmount != 0) {
            require(_tki == bytes4(keccak256("ERC1155")), "modifyAnAuctionToken: Token amount for auction token kind not correct");
            require(_tokenAmount >= 1, "modifyAnAuctionToken: Token amount not correct");
            tokenMapping[_auctionID].tokenAmount = _tokenAmount;
            
            uint256 _tokenDiff;
            if (_tam < _tokenAmount) {
                _tokenDiff = _tokenAmount - _tam;
                require((eRC1155_tokensUnderAuction[_ca][_tid] + _tokenDiff) <= IERC1155(_ca).balanceOf(address(this), _tid), 
                    "modifyAnAuctionToken: Cannot set to auction that amount of tokens");
                eRC1155_tokensUnderAuction[_ca][_tid] = eRC1155_tokensUnderAuction[_ca][_tid] + _tokenDiff;
            } else {
                _tokenDiff = _tam - _tokenAmount;
                require((eRC1155_tokensUnderAuction[_ca][_tid] - _tokenDiff) <= IERC1155(_ca).balanceOf(address(this), _tid),
                    "modifyAnAuctionToken: Cannot set to auction that amount of tokens");
                eRC1155_tokensUnderAuction[_ca][_tid] = eRC1155_tokensUnderAuction[_ca][_tid] - _tokenDiff;
            }
        }
        
        auctions[_auctionID].startTime = IGBMInitiator(_initiator).getStartTime(_auctionID);
        auctions[_auctionID].endTime = IGBMInitiator(_initiator).getEndTime(_auctionID);
        auctions[_auctionID].hammerTimeDuration = IGBMInitiator(_initiator).getHammerTimeDuration(_auctionID);
        auctions[_auctionID].bidDecimals = IGBMInitiator(_initiator).getBidDecimals(_auctionID);
        auctions[_auctionID].stepMin = IGBMInitiator(_initiator).getStepMin(_auctionID);
        auctions[_auctionID].incMin = IGBMInitiator(_initiator).getIncMin(_auctionID);
        auctions[_auctionID].incMax = IGBMInitiator(_initiator).getIncMax(_auctionID);
        auctions[_auctionID].bidMultiplier = IGBMInitiator(_initiator).getBidMultiplier(_auctionID);

        require(auctions[_auctionID].startTime > 0, "modifyAnAuctionToken: Start time is not correct");
    }



    //This function will NOT transfer the tokens to the smart contract. Instead, it assume the seller have given approvedForAll 1155 to the GBM smart contract.
    function massRegistrerOneOff(address _initiator, address _ERC1155Contract, uint256 _tokenIDStart, uint256 _tokenIDEnd) external override onlyThisContractOwner() {

        //registering all auction Data with the ID 0. Lookup will be done on auctionID 0 if the data at the acutal auctionID is null
        if(_initiator != address(0x0)) {
            auctions[0].startTime = IGBMInitiator(_initiator).getStartTime(0);
            auctions[0].endTime = IGBMInitiator(_initiator).getEndTime(0);
            auctions[0].hammerTimeDuration = IGBMInitiator(_initiator).getHammerTimeDuration(0);
            auctions[0].bidDecimals = IGBMInitiator(_initiator).getBidDecimals(0);
            auctions[0].stepMin = IGBMInitiator(_initiator).getStepMin(0);
            auctions[0].incMin = IGBMInitiator(_initiator).getIncMin(0);
            auctions[0].incMax = IGBMInitiator(_initiator).getIncMax(0);
            auctions[0].bidMultiplier = IGBMInitiator(_initiator).getBidMultiplier(0);
            tokenMapping[0].tokenKind = bytes4(keccak256("ERC1155"));
            tokenMapping[0].contractAddress = _ERC1155Contract;
            require(auctions[0].startTime > 0, "registerAuctionData: Start time is not correct");
        }

        auctionTokenIDOneOffRangeStart = _tokenIDStart;
        auctionTokenIDOneOffRangeEnd = _tokenIDEnd;

        if(beneficiary == address(0)){
            beneficiary = msg.sender;
        }

        collections[_ERC1155Contract].biddingAllowed = true;

    }


    function getAuctionHighestBidder(uint256 _auctionID) external override view returns(address) {
        return auctions[_auctionID].highestBidder;
    }

    function getAuctionHighestBid(uint256 _auctionID) external override view returns(uint256) {
        return auctions[_auctionID].highestBid;
    }

    function getAuctionDebt(uint256 _auctionID) external override view returns(uint256) {
        return auctions[_auctionID].debt;
    }

    function getAuctionDueIncentives(uint256 _auctionID) external override view returns(uint256) {
        return auctions[_auctionID].dueIncentives;
    }
    
    function getAuctionID(address _contract, bytes4 _tokenKind, uint256 _tokenID, uint256 _index) external override view returns(uint256) {
        require( tokenMapping[0].contractAddress == _contract, "Contract not under auction");
        return _tokenID;  //Modified for one Off auctions
    }

    function getTokenKind(uint256 _auctionID) external override view returns(bytes4) {
        return tokenMapping[0].tokenKind; //Modified for one Off auctions
    }

    function getTokenId(uint256 _auctionID) external override view returns(uint256) {
        return _auctionID; //Modified for one Off auctions
    }

    function getTokenAmount(uint256 _auctionID) external override view returns(uint256){
        return 1; //Modified for one Off auctions
    }

    function getContractAddress(uint256 _auctionID) external override view returns(address) {
        return tokenMapping[0].contractAddress;
    }

    function getAuctionStartTime(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].startTime != 0) {
            return auctions[_auctionID].startTime;
        } else {
            return auctions[0].startTime;
        }
    }

    function getAuctionEndTime(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].endTime != 0) {
            return auctions[_auctionID].endTime;
        } else {
            return auctions[0].endTime;
        }
    }

    function getHammerTimeDuration(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].hammerTimeDuration != 0) {
            return auctions[_auctionID].hammerTimeDuration;
        } else {
            return auctions[0].hammerTimeDuration;
        }
    }


    function getAuctionBidDecimals(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].bidDecimals != 0) {
            return auctions[_auctionID].bidDecimals;
        } else {
            return auctions[0].bidDecimals;
        }
    }

    function getAuctionStepMin(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].stepMin != 0) {
            return auctions[_auctionID].stepMin;
        } else {
            return auctions[0].stepMin;
        }
    }

    function getAuctionIncMin(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].incMin != 0) {
            return auctions[_auctionID].incMin;
        } else {
            return auctions[0].incMin;
        }
    }

    function getAuctionIncMax(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].incMax != 0) {
            return auctions[_auctionID].incMax;
        } else {
            return auctions[0].incMax;
        }
    }

    function getAuctionBidMultiplier(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].bidMultiplier != 0) {
            return auctions[_auctionID].bidMultiplier;
        } else {
            return auctions[0].bidMultiplier;
        }
    }

    function onERC721Received(address /* _operator */, address /* _from */, uint256 /* _tokenID */, bytes calldata /* _data */) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address /* _operator */, address /* _from */, uint256 /* _id */, uint256 /* _value */, bytes calldata /* _data */) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

   
    function onERC1155BatchReceived(address /* _operator */, address /* _from */, uint256[] calldata /* _ids */, uint256[] calldata /* _values */, bytes calldata /* _data */) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }    


    /// @notice Calculating and setting how much payout a bidder will receive if outbid
    /// @dev Only callable internally
    function calculateIncentives(uint256 _auctionID, uint256 _newBidValue) internal view returns (uint256) {

        uint256 bidDecimals = getAuctionBidDecimals(_auctionID);
        uint256 bidIncMax = getAuctionIncMax(_auctionID);

        //Init the baseline bid we need to perform against
        uint256 baseBid = auctions[_auctionID].highestBid * (bidDecimals + getAuctionStepMin(_auctionID)) / bidDecimals;

        //If no bids are present, set a basebid value of 1 to prevent divide by 0 errors
        if(baseBid == 0) {
            baseBid = 1;
        }

        //Ratio of newBid compared to expected minBid
        uint256 decimaledRatio = ((bidDecimals * getAuctionBidMultiplier(_auctionID) * (_newBidValue - baseBid) ) / baseBid) + 
            getAuctionIncMin(_auctionID) * bidDecimals;

        if(decimaledRatio > (bidDecimals * bidIncMax)) {
            decimaledRatio = bidDecimals * bidIncMax;
        }

        return  (_newBidValue * decimaledRatio)/(bidDecimals*bidDecimals);
    }


    //Functions not usable in current implementation
        	
	function massRegistrerERC721Each(address _initiator, address _ERC721Contract, uint256 _tokenIDStart, uint256 _tokenIDEnd) external pure override {
        require(false, "This implementation only support one off registration");
    }

    function massRegistrerERC1155Each(address _initiator, address _ERC1155Contract, uint256 _tokenID, uint256 _indexStart, uint256 _indexEnd) external pure override {
        require(false, "This implementation only support one off registration");
    }


    function registerAnAuctionToken(address _contract, uint256 _tokenID, bytes4 _tokenKind, uint256 _tokenAmount, address _initiator) public pure override {
        require(false, "This implementation only support one off registration");
    }

      
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.8.5; 

/// @title IGBM GBM auction interface
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud and Javier Fraile
interface IGBM {
    
    //Event emitted when an auction is being setup
    event Auction_Initialized(uint256 indexed _auctionID, uint256 indexed _tokenID, address indexed _contractAddress, bytes4 _tokenKind);

    //Event emitted when the start time of an auction changes (due to admin interaction )
    event Auction_StartTimeUpdated(uint256 indexed _auctionID, uint256 _startTime);

    //Event emitted when the end time of an auction changes (be it due to admin interaction or bid at the end)
    event Auction_EndTimeUpdated(uint256 indexed _auctionID, uint256 _endTime);
    
    //Event emitted when a Bid is placed
    event Auction_BidPlaced(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when a bid is removed (due to a new bid displacing it)
    event Auction_BidRemoved(uint256 indexed _auctionID,  address indexed _bidder, uint256 _bidAmount);

    //Event emitted when incentives are paid (due to a new bid rewarding the _earner bid)
    event Auction_IncentivePaid(uint256 indexed _auctionID,  address indexed _earner, uint256 _incentiveAmount);

    //Event emitted when a token is claimed
    event Auction_Claimed(uint256 indexed _auctionID);


    function bid(uint256 _auctionID, uint256 _bidAmount, uint256 _highestBid) external payable;
    function claim(uint256 _auctionID) external;
    function registerAnAuctionContract(address _contract, address _initiator) external;
    function setBiddingAllowed(address _contract, bool _value) external;
    function registerAnAuctionToken(address _contract, uint256 _tokenId, bytes4 _tokenKind, uint256 _tokenAmount, address _initiator) external;
    function modifyAnAuctionToken(uint256 _auctionID, address _initiator) external;
    function modifyAnAuctionToken(uint256 _auctionID, uint256 _tokenAmount, address _initiator) external;
    function massRegistrerERC721Each(address _initiator, address _ERC721Contract, uint256 _tokenIDStart, uint256 _tokenIDEnd) external;
    function massRegistrerERC1155Each(address _initiator, address _ERC1155Contract, uint256 _tokenID, uint256 _indexStart, uint256 _indexEnd) external;

    function massRegistrerOneOff(address _initiator, address _ERC1155Contract, uint256 _tokenIDStart, uint256 _tokenIDEnd) external;

    function owner() external returns(address);
    
    function getAuctionID(address _contract, bytes4 _tokenKind, uint256 _tokenID, uint256 _tokenIndex) external view returns(uint256);
    function getTokenId(uint256 _auctionID) external view returns(uint256);
    function getContractAddress(uint256 _auctionID) external view returns(address);
    function getTokenKind(uint256 _auctionID) external view returns(bytes4);
    function getTokenAmount(uint256 _auctionID) external view returns(uint256);

    function getAuctionHighestBidder(uint256 _auctionID) external view returns(address);
    function getAuctionHighestBid(uint256 _auctionID) external view returns(uint256);
    function getAuctionDebt(uint256 _auctionID) external view returns(uint256);
    function getAuctionDueIncentives(uint256 _auctionID) external view returns(uint256);

    function getAuctionStartTime(uint256 _auctionID) external view returns(uint256);
    function getAuctionEndTime(uint256 _auctionID) external view returns(uint256);
    function getHammerTimeDuration(uint256 _auctionID) external view returns(uint256);
    function getAuctionBidDecimals(uint256 _auctionID) external view returns(uint256);
    function getAuctionStepMin(uint256 _auctionID) external view returns(uint256);
    function getAuctionIncMin(uint256 _auctionID) external view returns(uint256);
    function getAuctionIncMax(uint256 _auctionID) external view returns(uint256);
    function getAuctionBidMultiplier(uint256 _auctionID) external view returns(uint256);

}

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.8.5; 

/// @title IGBMInitiator: GBM Auction initiator interface.
/// @dev Will be called when initializing GBM auctions on the main GBM contract. 
/// @author Guillaume Gonnaud and Javier Fraile
interface IGBMInitiator {

    // Auction id either = the contract token address cast as uint256 or 
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind)));  <= ERC721
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind, _1155Index))); <= ERC1155

    function getStartTime(uint256 _auctionId) external view returns(uint256);

    function getEndTime(uint256 _auctionId) external view returns(uint256);

    function getHammerTimeDuration(uint256 _auctionId) external view returns(uint256);

    function getBidDecimals(uint256 _auctionId) external view returns(uint256);

    function getStepMin(uint256 _auctionId) external view returns(uint256);

    function getIncMin(uint256 _auctionId) external view returns(uint256);

    function getIncMax(uint256 _auctionId) external view returns(uint256);

    function getBidMultiplier(uint256 _auctionId) external view returns(uint256);
    

}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.5; 

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.5; 

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.5; 

/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.5; 

interface Ownable {
    function owner() external returns(address); 
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.5; 

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.5; 

/// @title ERC-1155 Multi Token Standard
/// @dev ee https://eips.ethereum.org/EIPS/eip-1155
///  The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}