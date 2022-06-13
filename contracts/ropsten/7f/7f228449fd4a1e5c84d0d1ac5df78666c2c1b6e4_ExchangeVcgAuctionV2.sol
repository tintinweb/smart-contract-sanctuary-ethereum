// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;


import "./VcgBase.sol";


contract ExchangeVcgAuctionV2 is Ownable,Commission,ReentrancyGuardUpgradeable {
    using Strings for string;
    using Address for address;    
    using SafeMath for uint256;
    enum State {Pending, Started, Ended, Cancelled}

    struct auctionInfo {
        address  _nftContractAddress;
        uint256  _nftId;
        address  _beneficiaryAddress;
        uint256  _initialPrice;
        uint256  _bidIncrement;
        //uint256  _startTime;
        uint256  _duration;
        uint256  _stopTime;
        address  highestBidder;
        mapping(address => uint256) fundsByBidder;   
        State  _state;
        uint256 _totalBalance;
        //bool isUsed;
    }

    mapping(uint256 => auctionInfo) private _auctionInfos;

    // Interface to halt all auctions.
    bool public IsHalted;

    /// @notice How long an auction lasts for once the first bid has been received.
    uint256 private constant DEFAULT_DURATION = 5 minutes;
    /// @notice How long an auction lasts for once the first bid has been received.
    uint256 private constant EXTENSION_DURATION = 15 minutes;
    /// @notice Caps the max duration that may be configured so that overflows will not occur.
    //uint256 private constant MAX_MAX_DURATION = 1000 days;
    uint256 private constant MAX_DURATION = 100 days;

    // Admin withdrawal
    event WithDrawal(uint256 auctionid,address bidder,uint256 amount);
    // Pause and resume
    event Pause();
    event Resume();
    // New Bidding Event
    event NewBid(uint256 auctionid, uint256 price, address bidder);
    // Auction Finish Event
    event AuctionMade(uint256 auctionid, address oper ,State s);
    event AuctionAmountDetail(uint256 indexed auctionId,
            uint256 indexed beneficiaryReceived,
            uint256 indexed creatorReceived,
            uint256  platformReceived);

    // Halt transactions
    function halt() public onlyOwner {
        //require(_privilleged_operators[msg.sender] == true, "Operator only");
        IsHalted = true;
        emit Pause();
    }
    
    // Resume transactions
    function resume() public onlyOwner {
        IsHalted = false;
        emit Resume();
    }

    modifier onlyAuctionExist(uint256 auctionID) {
        require(_auctionInfos[auctionID]._nftId != 0,"auctionID not existed...");
        _;
    }

    modifier onlyOwnerOrBeneficiary(uint256 auctionID) {
        require(msg.sender == owner() ||
           msg.sender == _auctionInfos[auctionID]._beneficiaryAddress,
           "only Owner Or Beneficiary allow to do this.");
        _;
    }

    modifier notBeneficiary(uint256 auctionID, address bider) {
        //if (bider == _auctionInfos[auctionid].beneficiaryAddress) throw;
        require(bider != _auctionInfos[auctionID]._beneficiaryAddress, "Bider Must not the beneficiary");
        _;
    }

    modifier onlyAfterStart(uint256 auctionID) {
        //require(block.timestamp > _auctionInfos[auctionID]._startTime, "only After Start");
        require(_auctionInfos[auctionID]._stopTime > 0, "only After Start");
        _;
    }

    modifier onlyBeforeEnd(uint256 auctionID) {
        if ( _auctionInfos[auctionID]._stopTime > 0 )
        {
            require(block.timestamp < _auctionInfos[auctionID]._stopTime, "only Before End");
        }
        _;
    }

    modifier onlyEndedOrCanceled(uint256 auctionID) {
        require(_auctionInfos[auctionID]._state == State.Ended || 
            _auctionInfos[auctionID]._state == State.Cancelled, 
            "The nft is still on auction, pls claim it or wait for finish");
        _;
    }

    function hasRightToAuction(address nftContractaddr,uint256 tokenId) public view returns(bool) {
        return (IERC721(nftContractaddr).getApproved(tokenId) == address(this));
    }

    function isTokenOwner(address nftContractaddr,address targetAddr, uint256 tokenId) internal view returns(bool) {  
        return (targetAddr == IERC721(nftContractaddr).ownerOf(tokenId) );   
    }

    function isOnAuction(uint256 auctionID) public view returns(bool) {
        require(_auctionInfos[auctionID]._nftId != 0,"auctionID not existed...");
        //return (block.timestamp > _auctionInfos[auctionID]._startTime
        //    && block.timestamp < _auctionInfos[auctionID]._stopTime);
        return ( block.timestamp < _auctionInfos[auctionID]._stopTime );
    }   

    function createAuction(uint256 auctionID, 
        address  nftContractAddress,
        uint256  nftId,
        uint256  initialPrice,
        uint256  bidIncrement,
        uint256  duration) public {
        require(_auctionInfos[auctionID]._nftId == 0,"auctionID existed...");

        require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");

        require(duration * 1 minutes >= DEFAULT_DURATION && duration * 1 minutes < MAX_DURATION , "duration must greater than 5 min");
        //require(stopTime > block.timestamp + 600 , "stopTime must greater than current Time after 10 min");

        require(isTokenOwner(nftContractAddress, msg.sender, nftId),
        "the sender isn't the owner of the token id nft!");

        require(hasRightToAuction(nftContractAddress,nftId),
            "the exchange contracct is not the approved of the token.");
        
        require(initialPrice > 0 && initialPrice >= bidIncrement ,"need a vaild initial price");

        auctionInfo storage ainfo = _auctionInfos[auctionID];
        ainfo._nftContractAddress=nftContractAddress;
        ainfo._nftId=nftId;
        ainfo._beneficiaryAddress=msg.sender;
        ainfo._initialPrice=initialPrice;
        ainfo._bidIncrement=bidIncrement;
        ainfo._totalBalance = 0;
        ainfo._duration = duration ;
        ainfo._stopTime = 0;  
        ainfo._state=State.Pending;
        //ainfo.isUsed=true;

        emit AuctionMade(auctionID, address(this) ,State.Pending);
    }

    function getAuctionInfo(uint256 auctionID) external 
        view
        returns (address,uint256,address,uint256,uint256,
        uint256,uint256,address,uint256,State,uint256){
        auctionInfo storage info = _auctionInfos[auctionID];
        return (
            info._nftContractAddress,
            info._nftId,
            info._beneficiaryAddress,
            info._initialPrice,
            info._bidIncrement,
            info._duration,
            info._stopTime,
            info.highestBidder,
            info.fundsByBidder[info.highestBidder],
            info._state,
            info._totalBalance
        );
    }

    function clearAuctionInfo(uint256 auctionID) internal
        onlyAuctionExist(auctionID) {
        require(_auctionInfos[auctionID]._totalBalance == 0 ,
            "only zero balance to be claered.");
        /*
        auctionInfo storage ainfo = _auctionInfos[auctionID];
        
        ainfo._nftContractAddress=address(0);
        ainfo._nftId=0;
        ainfo._beneficiaryAddress=address(0);
        ainfo._initialPrice=0;
        ainfo._bidIncrement=0;
        ainfo._totalBalance = 0;
        ainfo._startTime=0;
        ainfo._stopTime=0;  
        ainfo._state=State.Pending;
        ainfo.highestBidder=address(0);
        ainfo.isUsed=false;
        */
        delete _auctionInfos[auctionID];
    }

    function cancelAuction(uint256 auctionID) public 
        onlyAuctionExist(auctionID) onlyOwnerOrBeneficiary(auctionID){
        _auctionInfos[auctionID]._state = State.Cancelled;
    }
    
    function getHighestBid(uint256 auctionID) public
        view
        returns (address,uint256)
    {
        require(_auctionInfos[auctionID]._nftId != 0,"auctionID not existed...");
        if(_auctionInfos[auctionID].highestBidder == address(0))
        {
            return (address(0),0);
        }
        return (_auctionInfos[auctionID].highestBidder,
            _auctionInfos[auctionID].fundsByBidder[
                _auctionInfos[auctionID].highestBidder]);
    }
    
    //onlyAfterStart(auctionID)
    function placeBid(uint256 auctionID) public payable 
            onlyAuctionExist(auctionID)
            notBeneficiary(auctionID,msg.sender) onlyBeforeEnd(auctionID) {
        // to place a bid auction should be running
        require(_auctionInfos[auctionID]._state == State.Pending ||
            _auctionInfos[auctionID]._state == State.Started,"Invaild Auction State");
        // minimum value allowed to be sent
        require(msg.value >= _auctionInfos[auctionID]._bidIncrement || _auctionInfos[auctionID]._bidIncrement == 0,
        "bid should be greater bid Increment");
        
        uint256 currentBid = _auctionInfos[auctionID].fundsByBidder[msg.sender] + msg.value;
        
        // the currentBid should be greater than the highestBid. 
        // Otherwise there's nothing to do.
        require((address(0) == _auctionInfos[auctionID].highestBidder &&
               currentBid >= _auctionInfos[auctionID]._initialPrice)//first bid
            || 
            (currentBid > _auctionInfos[auctionID].fundsByBidder[
            _auctionInfos[auctionID].highestBidder]),
            "the currentBid should be greater than the highestBid.");
        
        //set state to started,when first vaild bid
        if (_auctionInfos[auctionID]._state == State.Pending)
        {
            _auctionInfos[auctionID]._state = State.Started;
            emit AuctionMade(auctionID, msg.sender ,State.Started);

            // On the first bid, set the endTime to now + duration.
            unchecked {
                _auctionInfos[auctionID]._stopTime = block.timestamp + ( _auctionInfos[auctionID]._duration * 1 minutes );
            }
        }

        // updating the mapping variable
        _auctionInfos[auctionID].fundsByBidder[msg.sender] = currentBid;
        _auctionInfos[auctionID]._totalBalance = 
        _auctionInfos[auctionID]._totalBalance.add(msg.value);

        if (_auctionInfos[auctionID].highestBidder != msg.sender){ // highestBidder is another bidder
             _auctionInfos[auctionID].highestBidder = payable(msg.sender);
        }
        emit NewBid(auctionID, currentBid, msg.sender);
    }  
    
    function finalizeAuction(uint256 auctionID) public
        // onlyAuctionExist(auctionID) 
        onlyOwner nonReentrant {
        // support multi finalizeAuction call--2021.12.29
        if (_auctionInfos[auctionID]._nftId == 0 || 
        _auctionInfos[auctionID]._state == State.Ended)
        {
            return;
        }
       // the auction has been Cancelled or Ended
       require((_auctionInfos[auctionID]._state == State.Cancelled 
        || _auctionInfos[auctionID]._state == State.Started
        || _auctionInfos[auctionID]._state == State.Pending)
        &&
        block.timestamp > _auctionInfos[auctionID]._stopTime,
        "the auction may be Cancelled or Ended"); 
       
       if(_auctionInfos[auctionID]._state == State.Started)
       {
            address payable recipient;
            uint256 value;
            recipient = payable(_auctionInfos[auctionID]._beneficiaryAddress);
            value = _auctionInfos[auctionID].fundsByBidder[
            _auctionInfos[auctionID].highestBidder];
            
            // resetting the bids of the recipient to avoid multiple transfers to the same recipient
            _auctionInfos[auctionID].fundsByBidder[
            _auctionInfos[auctionID].highestBidder] = 0;
            _auctionInfos[auctionID]._totalBalance = 
                _auctionInfos[auctionID]._totalBalance.sub(value);
            //
            IERC721(_auctionInfos[auctionID]._nftContractAddress).safeTransferFrom(
                _auctionInfos[auctionID]._beneficiaryAddress,
                _auctionInfos[auctionID].highestBidder,
                _auctionInfos[auctionID]._nftId
            );
            (address creator,uint256 royalty) = IVcgERC721TokenWithRoyalty(_auctionInfos[auctionID]._nftContractAddress).royaltyInfo(_auctionInfos[auctionID]._nftId,value);
            (address platform,uint256 fee) = calculateFee(value);
            require(value > royalty + fee,"No enough Amount to pay except royalty and platform service fee");
            if(creator != address(0) && royalty >0 && royalty < value)
            {
                //payable(creator).transfer(royalty);
                Address.sendValue(payable(creator),royalty);
                value = value.sub(royalty);
            } 
            if(fee > 0 && fee < value)
            {
                //payable(platform).transfer(fee);
                //(bool sent, bytes memory data) = platform.call{value: fee}("");
                //require(sent, "Failed to send Ether to platform");
                Address.sendValue(payable(platform),fee);
                value = value.sub(fee);
            }
            //sends value to the recipient
            //recipient.transfer(value);
            Address.sendValue(payable(recipient),value);
            emit AuctionAmountDetail(auctionID,value,royalty,fee);
        }
        _auctionInfos[auctionID]._state = State.Ended;
        emit AuctionMade(auctionID, msg.sender ,State.Ended);
        if(_auctionInfos[auctionID]._totalBalance == 0){
            clearAuctionInfo(auctionID);
        }
    }

    function withdraw(uint256 auctionID) public
        onlyAuctionExist(auctionID) onlyEndedOrCanceled(auctionID)
        returns (bool success)
    {
        address payable withdrawalAccount;
        uint withdrawalAmount;

        if (_auctionInfos[auctionID]._state == State.Cancelled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = payable(msg.sender);
            withdrawalAmount = _auctionInfos[auctionID].fundsByBidder[withdrawalAccount];

        } else {
            require(msg.sender != _auctionInfos[auctionID].highestBidder ,
                "highestBidder does not allow to withdraw.");
            // anyone who participated but did not win the auction should be allowed to withdraw
            // the full amount of their funds
            withdrawalAccount = payable(msg.sender);
            withdrawalAmount = _auctionInfos[auctionID].fundsByBidder[withdrawalAccount];
        }

        if (withdrawalAmount == 0) {
            revert();
        }
        delete _auctionInfos[auctionID].fundsByBidder[withdrawalAccount];
        /*
        _auctionInfos[auctionID].fundsByBidder[withdrawalAccount] = 
        _auctionInfos[auctionID].fundsByBidder[withdrawalAccount].sub(withdrawalAmount);
        */
        // send the funds
        if (!withdrawalAccount.send(withdrawalAmount)){
            revert();
        }
        
        _auctionInfos[auctionID]._totalBalance = 
                _auctionInfos[auctionID]._totalBalance.sub(withdrawalAmount);
        if(_auctionInfos[auctionID]._totalBalance == 0){
            clearAuctionInfo(auctionID);
        }

        emit WithDrawal(auctionID,withdrawalAccount,withdrawalAmount);
        return true;
    }

    function getBalance(uint256 auctionID,address target) public
        view
        onlyAuctionExist(auctionID)
        returns (uint256)
    {
        if(address(0) == target){
            return _auctionInfos[auctionID].fundsByBidder[msg.sender];
        }
        return _auctionInfos[auctionID].fundsByBidder[target];
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
    } 
}