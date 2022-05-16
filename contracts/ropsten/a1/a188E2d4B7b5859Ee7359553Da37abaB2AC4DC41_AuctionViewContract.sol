//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface UserContract {
    function isBuyer(address account) view external returns (bool);
    function isSeller(address account) view external returns (bool);
}

contract AuctionContract {
    address payable owner;
    UserContract userContract;
    constructor(address _userContractAddress) {
        // owner is the person deploying it
        owner = payable(msg.sender);
        userContract = UserContract(_userContractAddress);
    }

    // data structure
    uint public auctionId = 0;
    enum DataType { API, Dataset }
    enum DataField { FINANCE, MANAGEMENT, MARKETING, GEOGRAPHY, LIFE, OTHER}
    enum AuctionStatus { Initiated, Bidding_ended, Sale_created, Aborted, Deposit_refunded}
    struct AuctionMeta {
        string name;
        uint startPrice;
        DataType dataType;
        address payable buyer;
        uint deadline;
        uint dataNum;
        uint deposit;
    }
    struct Auction{
        uint id;
        AuctionMeta meta;
        uint curPrice;
        address payable curSeller;
        string url;
        DataField dataField;
        AuctionStatus status;
        uint bidCount;
        uint bidderCount;
    }
    // auction list
    mapping(uint => Auction) public idToAuction;
    // events
    event AuctionCreated(uint id, address payable buyer, uint deadline);
    event BidderCreated(uint id, address payable bidder);
    event Bid(uint id);
    event SaleCreated(uint auctionId, uint saleId);

    // bid list
    // auctionId => bidId => bidder
    mapping(uint => mapping(uint => address payable)) public idToBid;

    modifier validId(uint _auctionId){
        require(_auctionId > 0 && _auctionId <= auctionId, "Auction doesn't exist!");
        _;
    }

    function isAuctionIdValid(uint _auctionId) view external returns (bool){
        if(_auctionId > 0 && _auctionId <= auctionId){
            return true;
        }
        return false;
    }

    function getAuctionById(uint _auctionId) view external validId(_auctionId) returns (Auction memory){
        return idToAuction[_auctionId];
    }

    function hasSellerBid(uint _auctionId, address payable seller) view external validId(_auctionId) returns (bool){
        mapping(uint => address payable) storage bidders = idToBid[_auctionId];
        uint bidderCount = idToAuction[_auctionId].bidderCount;
        for(uint i = 1;i <= bidderCount;i++){
            if(bidders[i] == seller){
                return true;
            }
        }
        return false;
    }

    function createAuction(string memory _url, string memory _name, uint _curPrice, uint _dataNum, DataType _dataType, DataField _dataField, uint _deadline) public payable returns (uint){
        require(userContract.isBuyer(msg.sender), "Only valid buyers can create auction!");
        require(bytes(_url).length != 0 && bytes(_name).length != 0, "Parameters can't be empty!");
        uint deposit = _curPrice * _dataNum * 2 /10;
        require(msg.value == deposit, "Not enough money for deposit!");
        auctionId++;
        idToAuction[auctionId] = Auction(
            auctionId,
            AuctionMeta(_name, _curPrice, _dataType, payable(msg.sender), _deadline, _dataNum, deposit),
            _curPrice,
            payable(msg.sender),
            _url,
            _dataField,
            AuctionStatus.Initiated,
            0,
            0
        );

        emit AuctionCreated(auctionId, payable(msg.sender), _deadline);
        
        return auctionId;
    }

    function isFirstBid(uint _auctionId) view public validId(_auctionId)  returns (bool){
        uint bidderCount = idToAuction[_auctionId].bidderCount;
        bool isFirst = true;
        for(uint i = 1;i <= bidderCount;i++){
            if(idToBid[_auctionId][i] == payable(msg.sender)){
                isFirst =  false;
            }
        }
        return isFirst;
    }

    function createBidder(uint _auctionId) public payable validId(_auctionId) {
        require(userContract.isSeller(msg.sender), "Only a valid seller can become bidder!");
        Auction storage curItem = idToAuction[_auctionId];
        require(payable(msg.sender) != curItem.meta.buyer, "Buyers can't become a bidder themselves!");
        require(msg.value == curItem.meta.deposit, "Not enough money!");
        require(curItem.status == AuctionStatus.Initiated, "Can't update ended auctions!");
        uint bidderCount = idToAuction[_auctionId].bidderCount;
        bool isFirst = true;
        for(uint i = 1;i <= bidderCount;i++){
            if(idToBid[_auctionId][i] == payable(msg.sender)){
                isFirst =  false;
            }
        }
        require(isFirst == true, "Already a bidder!");
        bidderCount++;
        idToAuction[_auctionId].bidderCount = bidderCount;
        idToBid[_auctionId][bidderCount] = payable(msg.sender);
        emit BidderCreated(_auctionId, payable(msg.sender));
    }

    function bid(uint _auctionId, uint _curPrice) public validId(_auctionId) { 
        Auction storage curItem = idToAuction[_auctionId];
        require(curItem.curPrice > _curPrice && _curPrice > 0, "Bid must be smaller than current price!");
        require(curItem.status == AuctionStatus.Initiated, "Can't update ended auctions!");
        uint bidderCount = idToAuction[_auctionId].bidderCount;
        mapping(uint => address payable) storage curIdToBid = idToBid[_auctionId];
        bool isBidder = false;
        for(uint i = 1;i <= bidderCount;i++){
            if(curIdToBid[i] == payable(msg.sender)){
                isBidder = true;
            }
        }
        require(isBidder == true, "Please create a bidder first before bidding!");
        idToAuction[_auctionId].curPrice = _curPrice;
        idToAuction[_auctionId].curSeller = payable(msg.sender);
        idToAuction[_auctionId].bidCount++;
        emit Bid(_auctionId);
    }

    function getAuctionByIdList(uint[] memory _idList) public view returns (Auction[] memory){
        uint itemCount = _idList.length;
        require(itemCount <= auctionId, "Not enough auctions!");
        uint currentIndex = 0;
        Auction[] memory items = new Auction[](itemCount);
        for(uint i = 0;i < itemCount;i++){
            items[currentIndex] = idToAuction[_idList[i]];
            currentIndex++;
        }
        return items;
    }

    function endAuction(uint _auctionId) public validId(_auctionId) {
        require(payable(msg.sender) == owner, "Only owner could end the auction");
        require(idToAuction[_auctionId].status == AuctionStatus.Initiated, "Auction already ended!!");
        idToAuction[_auctionId].status = AuctionStatus.Bidding_ended;
        // refund failed bidder
        uint bidderCount = idToAuction[_auctionId].bidderCount;
        address payable winner = idToAuction[_auctionId].curSeller;
        mapping(uint => address payable) storage curIdToBid = idToBid[_auctionId];
        for(uint i = 1;i <= bidderCount;i++){
            if(curIdToBid[i] != winner){
                // failed to win the auction: refund
                curIdToBid[i].transfer(idToAuction[_auctionId].meta.deposit);
            }
        }
        if(bidderCount == 0){
            idToAuction[_auctionId].meta.buyer.transfer(idToAuction[_auctionId].meta.deposit);
        }
    }

    function createSale(uint _auctionId, uint _saleId) public validId(_auctionId){
        require(idToAuction[_auctionId].status == AuctionStatus.Bidding_ended, "Can only create an auction after the bidding ends!");
        require(msg.sender == owner, "Only buyer can create sale");
        require(idToAuction[_auctionId].bidderCount != 0, "No seller to create sale with");
        idToAuction[_auctionId].status = AuctionStatus.Sale_created;
        emit SaleCreated(_auctionId, _saleId);
    }

    function refundDeposit(uint _auctionId) public validId(_auctionId){
        require(idToAuction[_auctionId].status == AuctionStatus.Sale_created, "Can only refund after the sale is created");
        require(msg.sender == owner, "Can only be called by the owner!");
        idToAuction[_auctionId].status = AuctionStatus.Deposit_refunded;
        idToAuction[_auctionId].meta.buyer.transfer(idToAuction[_auctionId].meta.deposit);
        idToAuction[_auctionId].curSeller.transfer(idToAuction[_auctionId].meta.deposit);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface AuctionContract {
    enum DataType { API, Dataset }
    enum DataField { FINANCE, MANAGEMENT, MARKETING, GEOGRAPHY, LIFE, OTHER}
    enum AuctionStatus { Initiated, Bidding_ended, Sale_created, Aborted, Deposit_refunded}
    struct AuctionMeta {
        string name;
        uint startPrice;
        DataType dataType;
        address payable buyer;
        uint deadline;
        uint dataNum;
        uint deposit;
    }
    struct Auction{
        uint id;
        AuctionMeta meta;
        uint curPrice;
        address payable curSeller;
        string url;
        DataField dataField;
        AuctionStatus status;
        uint bidCount;
        uint bidderCount;
    }
    function auctionId() view external returns (uint);
    function getAuctionById(uint _auctionId) view external returns (Auction memory);
    function hasSellerBid(uint _auctionId, address payable seller) view external returns (bool);
}

contract AuctionViewContract {
    address payable owner;
    AuctionContract auctionContract;
    constructor(address _auctionContractAddress) {
        // owner is the person deploying it
        owner = payable(msg.sender);
        auctionContract = AuctionContract(_auctionContractAddress);
    }

    function getAllData() public view returns (AuctionContract.Auction[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        uint auctionId = auctionContract.auctionId();
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                itemCount += 1;
            }
        }
        AuctionContract.Auction[] memory items = new AuctionContract.Auction[](itemCount);
        for (uint i = 0; i < auctionId; i++) {
            uint currentId = i + 1;
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(currentId);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getDataListByType(AuctionContract.DataType _dataType) public view returns (AuctionContract.Auction[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        uint auctionId = auctionContract.auctionId();
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.meta.dataType == _dataType && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                itemCount += 1;
            }
        }
        AuctionContract.Auction[] memory items = new AuctionContract.Auction[](itemCount);
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.meta.dataType == _dataType && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getDataListByField(AuctionContract.DataField _dataField) public view returns (AuctionContract.Auction[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        uint auctionId = auctionContract.auctionId();
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.dataField == _dataField && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                itemCount += 1;
            }
        }
        AuctionContract.Auction[] memory items = new AuctionContract.Auction[](itemCount);
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.dataField == _dataField && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getSelectedDataList(AuctionContract.DataType _dataType, AuctionContract.DataField _dataField) public view returns (AuctionContract.Auction[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        uint auctionId = auctionContract.auctionId();
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.meta.dataType == _dataType && currentItem.dataField == _dataField && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                itemCount += 1;
            }
        }
        AuctionContract.Auction[] memory items = new AuctionContract.Auction[](itemCount);
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if (bytes(currentItem.meta.name).length != 0 && currentItem.meta.dataType == _dataType && currentItem.dataField == _dataField && currentItem.status == AuctionContract.AuctionStatus.Initiated) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getBuyerAuctions() public view returns (AuctionContract.Auction[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        uint auctionId = auctionContract.auctionId();
        address payable buyer = payable(msg.sender);
        for(uint i = 0;i < auctionId;i++){
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if(currentItem.meta.buyer == buyer){
                itemCount += 1;
            }
        }
        AuctionContract.Auction[] memory items = new AuctionContract.Auction[](itemCount);
        for (uint i = 0; i < auctionId; i++) {
            AuctionContract.Auction memory currentItem = auctionContract.getAuctionById(i + 1);
            if(currentItem.meta.buyer == buyer){
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getSellerAuctions() view public returns (AuctionContract.Auction[] memory) {
        address payable seller = payable(msg.sender);
        uint itemCount = 0;
        uint currentIndex = 0;
        uint auctionId = auctionContract.auctionId();
        for(uint i = 1;i <= auctionId; i++){
            if(auctionContract.hasSellerBid(i, seller)){
                itemCount += 1;
            }
        }
        AuctionContract.Auction[] memory items = new AuctionContract.Auction[](itemCount);
        for(uint i = 1;i <= auctionId;i++){
            if(auctionContract.hasSellerBid(i, seller)){
                items[currentIndex] = auctionContract.getAuctionById(i);
                currentIndex += 1;
            }
        }
        return items;        
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface AuctionContract {
    enum DataType { API, Dataset }
    enum DataField { FINANCE, MANAGEMENT, MARKETING, GEOGRAPHY, LIFE, OTHER}
}

interface UserContract {
    function isSeller(address account) view external returns (bool);
}

contract DataContract {
    address payable owner;
    AuctionContract auctionContract;
    UserContract userContract;
    constructor(address _auctionContractAddress, address _userContractAddress) {
        // owner is the person deploying it
        owner = payable(msg.sender);
        auctionContract = AuctionContract(_auctionContractAddress);
        userContract = UserContract(_userContractAddress);
    }

    // model data
    uint dataId = 0;
    struct Data{
        uint id;
        string name;
        uint price;
        AuctionContract.DataType dataType;
        address payable seller;
        string url;
        AuctionContract.DataField dataField;
        uint createdTime;
        bool deleted;
    }
    // data list
    mapping(uint => Data) public idToData;

    event DataCreated(
        uint id,
        string uuid
    );
    event DataDeleted(uint id);

    modifier validId(uint _dataId){
        require(_dataId > 0 && _dataId <= dataId, "Data doesn't exist!");
        _;
    }

    function isDataIdValid(uint _dataId) view external returns (bool){
        if(_dataId > 0 && _dataId <= dataId && idToData[_dataId].deleted == false){
            return true;
        }
        return false;
    }

    function getDataById(uint _dataId) view external validId(_dataId) returns (Data memory){
        return idToData[_dataId];
    }

    // release data: prevent a reentrant attack
    function createData(string memory _url, string memory _name, uint _price, AuctionContract.DataType _dataType, AuctionContract.DataField _dataField, uint _createdTime, string memory _uuid) public returns (uint){
        require(userContract.isSeller(msg.sender), "Only valid sellers can create data!");
        require(bytes(_url).length != 0 && bytes(_name).length != 0, "Parameters can't be empty!");
        dataId++;
        idToData[dataId] = Data(
            dataId,
            _name,
            _price,
            _dataType,
            payable(msg.sender),
            _url,
            _dataField,
            _createdTime,
            false
        );

        emit DataCreated(dataId, _uuid);
        
        return dataId;
    }

    function updateData(uint _dataId, string memory _url, string memory _name, uint _price, AuctionContract.DataField _dataField) public {
        require(_dataId > 0 && _dataId <= dataId, "Data doesn't exist!");
        require(idToData[_dataId].deleted == false, "Cannot update deleted data!");
        require(msg.sender == idToData[_dataId].seller, "Only seller can update data!");
        idToData[_dataId].url = _url;
        idToData[_dataId].name = _name;
        idToData[_dataId].price = _price;
        idToData[_dataId].dataField = _dataField;
    }

    function deleteData(uint _dataId) public{
        require(_dataId > 0 && _dataId <= dataId && idToData[_dataId].deleted == false, "Data doesn't exist!");
        require(msg.sender == idToData[_dataId].seller, "Only seller can delete data!");
        idToData[_dataId].deleted = true;
        emit DataDeleted(_dataId);
    }

    function getAllData() public view returns (Data[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false) {
                itemCount += 1;
            }
        }
        Data[] memory items = new Data[](itemCount);
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false) {
                uint currentId = i + 1;
                Data storage currentItem = idToData[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getDataBySeller() public view returns (Data[] memory){
        address payable seller = payable(msg.sender);
        uint itemCount = 0;
        for(uint i = 1;i <= dataId;i++){
            if(idToData[i].deleted == false && idToData[i].seller == seller){
                itemCount++;
            }
        }
        uint currentIndex = 0;
        Data[] memory items = new Data[](itemCount);
        for(uint i = 1;i <= dataId;i++){
            if(idToData[i].deleted == false && idToData[i].seller == seller){
                items[currentIndex] = idToData[i];
                currentIndex += 1;
            }
        }
        return items;
    }

    function getSelectedDataList(AuctionContract.DataType _dataType, AuctionContract.DataField _dataField) public view returns (Data[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false && idToData[i + 1].dataType == _dataType && idToData[i + 1].dataField == _dataField) {
                itemCount += 1;
            }
        }
        Data[] memory items = new Data[](itemCount);
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false && idToData[i + 1].dataType == _dataType && idToData[i + 1].dataField == _dataField) {
                uint currentId = i + 1;
                Data storage currentItem = idToData[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getDataListByType(AuctionContract.DataType _dataType) public view returns (Data[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false && idToData[i + 1].dataType == _dataType) {
                itemCount += 1;
            }
        }
        Data[] memory items = new Data[](itemCount);
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false && idToData[i + 1].dataType == _dataType) {
                uint currentId = i + 1;
                Data storage currentItem = idToData[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getDataListByField(AuctionContract.DataField _dataField) public view returns (Data[] memory){
        uint itemCount = 0;
        uint currentIndex = 0;
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false && idToData[i + 1].dataField == _dataField) {
                itemCount += 1;
            }
        }
        Data[] memory items = new Data[](itemCount);
        for (uint i = 0; i < dataId; i++) {
            if (idToData[i + 1].deleted == false && idToData[i + 1].dataField == _dataField) {
                uint currentId = i + 1;
                Data storage currentItem = idToData[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface AuctionContract {
    enum DataType { API, Dataset }
    enum DataField { FINANCE, MANAGEMENT, MARKETING, GEOGRAPHY, LIFE, OTHER}
    enum AuctionStatus { Initiated, Bidding_ended, Sale_created, Aborted, Deposit_refunded}
    struct AuctionMeta {
        string name;
        uint startPrice;
        DataType dataType;
        address payable buyer;
        uint deadline;
        uint dataNum;
        uint deposit;
    }
    struct Auction{
        uint id;
        AuctionMeta meta;
        uint curPrice;
        address payable curSeller;
        string url;
        DataField dataField;
        AuctionStatus status;
        uint bidCount;
        uint bidderCount;
    }
    function isAuctionIdValid(uint _auctionId) view external returns (bool);
    function getAuctionById(uint _auctionId) view external returns (Auction memory);
}

interface DataContract {
    struct Data{
        uint id;
        string name;
        uint price;
        AuctionContract.DataType dataType;
        address payable seller;
        string url;
        AuctionContract.DataField dataField;
        uint createdTime;
    }
    function isDataIdValid(uint _dataId) view external returns (bool);
    function getDataById(uint _dataId) view external returns (Data memory);
}

interface UserContract {
    function isBuyer(address account) view external returns (bool);
    function isSeller(address account) view external returns (bool);
}

contract Market is ReentrancyGuard {
    address payable owner;
    DataContract dataContract;
    AuctionContract auctionContract;
    UserContract userContract;

    // model sale
    enum SaleStatus { Initiated, DigestPut, Paid, ConfirmedSuccess, ConfirmedFraud}
    uint saleId = 0;
    struct Rated{
        bool sellerRated;
        bool buyerRated;
    }
    struct AuctionInfo { 
        uint auctionId;
        bool isAuction; 
    }
    struct Deposits {
        uint sellerDepositPrice;
        uint buyerDepositPrice;
    }

    struct Sale{
        uint id;
        address payable seller;
        address payable buyer;
        uint price;
        uint dataNum;
        uint createdTime;
        string digest;
        SaleStatus status;
        Rated rated;
        // data
        uint dataId;
        Deposits deposits;
        AuctionInfo auctionInfo;
    }
    mapping (uint => Sale) public idToSale;
    event SaleCreated(
        uint id,
        bool isAuction,
        uint createdTime,
        uint dataId,
        uint auctionId
    );

    event Rate (
        uint saleId,
        string rate,
        address payable rater
    );
    event StatusChanged(uint saleId);

    event RefundAuctionDeposit (uint saleId, uint auctionId);

    constructor(address _dataContractAddress, address _auctionContractAddress, address _userContractAddress) {
        // owner is the person deploying it
        owner = payable(msg.sender);
        dataContract = DataContract(_dataContractAddress);
        auctionContract = AuctionContract(_auctionContractAddress);
        userContract = UserContract(_userContractAddress);
    }

    // sale data: called by buyers 
    function createSale(uint _price, 
                        uint _dataNum, 
                        uint _createdTime, 
                        bool _isAuction, 
                        uint _dataId, 
                        uint _sellerDepositPrice, 
                        uint _buyerDepositPrice, 
                        uint _auctionId) public returns (uint){
        saleId++;
        address payable seller;
        address payable buyer;
        if(_isAuction){
            require(auctionContract.isAuctionIdValid(_auctionId), "Auction doesn't exist!");
            seller = auctionContract.getAuctionById(_auctionId).curSeller;
            buyer = payable(msg.sender);
        }else{
            require(dataContract.isDataIdValid(_dataId), "Data doesn't exist!");
            seller = dataContract.getDataById(_dataId).seller;
            require(msg.sender != seller, "Please don't buy your own data!");
            buyer = payable(msg.sender);
        }
        require(userContract.isBuyer(buyer), "Buyer is not a valid buyer!");
        require(userContract.isSeller(seller), "Seller is not a valid seller!");
        idToSale[saleId] = Sale(
                saleId,
                seller,
                buyer,
                _price,
                _dataNum,
                _createdTime,
                "",
                SaleStatus.Initiated,
                Rated(false, false),
                _dataId,
                Deposits(_sellerDepositPrice, _buyerDepositPrice),
                AuctionInfo(_auctionId, _isAuction)
            );
        emit SaleCreated(saleId, _isAuction, _createdTime, _dataId, _auctionId);
        return saleId;
    }

    // sellers put digest and deposit
    function putDigestAndDeposit(uint _saleId, string memory _digest) public payable {
        require(_saleId > 0 && _saleId <= saleId, "Sale doesn't exist!");
        Sale storage sale = idToSale[_saleId];
        require(msg.sender == sale.seller, "Only seller of the data can upload digest!");
        if(!sale.auctionInfo.isAuction){
            require(msg.value == sale.deposits.sellerDepositPrice, "Not enough money!");
        }
        require(sale.status == SaleStatus.Initiated, "Not the right status!");
        idToSale[_saleId].digest = _digest;
        idToSale[_saleId].status = SaleStatus.DigestPut;
        emit StatusChanged(_saleId);
    }

    // buyers put money and deposit
    function payPriceAndDeposit(uint _saleId) public payable{
        require(_saleId > 0 && _saleId <= saleId, "Sale doesn't exist!");
        Sale storage sale = idToSale[_saleId];
        require(msg.sender == sale.buyer, "Only buyer of the sale can pay for it!");
        if(sale.auctionInfo.isAuction){
            require(msg.value == sale.price * sale.dataNum, "Not enough money!");
        }else{
            require(msg.value == sale.deposits.buyerDepositPrice + sale.price * sale.dataNum, "Not enough money!");
        }
        require(sale.status == SaleStatus.DigestPut, "Not the right status!");
        idToSale[_saleId].status = SaleStatus.Paid;
        emit StatusChanged(_saleId);
    }

    // buyer confirm the sale
    function confirm(uint _saleId, bool succeeded) public nonReentrant{
        require(_saleId > 0 && _saleId <= saleId, "Sale doesn't exist!");
        Sale storage sale = idToSale[_saleId];
        require(msg.sender == sale.buyer, "Only buyer of the sale can confirm it!");
        require(sale.status == SaleStatus.Paid, "Not the right status!");
        if(succeeded){
            if(sale.auctionInfo.isAuction){
                emit RefundAuctionDeposit(_saleId, sale.auctionInfo.auctionId);
            }else{
                // return the deposit
                payable(msg.sender).transfer(sale.deposits.buyerDepositPrice);
                sale.seller.transfer(sale.deposits.sellerDepositPrice + sale.price * sale.dataNum * 9 / 10);
            }
            sale.status = SaleStatus.ConfirmedSuccess;
        }else{
            sale.status = SaleStatus.ConfirmedFraud;
        }
        owner.transfer(sale.price / 10);
        emit StatusChanged(_saleId);
    }

    // rate
    function BuyerRates(uint _saleId, string memory _rate) public{
        require(_saleId > 0 && _saleId <= saleId, "Sale doesn't exist!");
        Sale storage sale = idToSale[_saleId];
        require(msg.sender == sale.buyer, "Only buyer of the sale can rate it!");
        require(sale.status == SaleStatus.ConfirmedSuccess || sale.status == SaleStatus.ConfirmedFraud, "Not the right status!");
        require(sale.rated.buyerRated == false, "Buyer has already rated on this one!");
        emit Rate(_saleId, _rate, payable(msg.sender));
        sale.rated.buyerRated = true;
    }

    function SellerRates(uint _saleId, string memory _rate) public{
        require(_saleId > 0 && _saleId <= saleId, "Sale doesn't exist!");
        Sale storage sale = idToSale[_saleId];
        require(msg.sender == sale.seller, "Only seller of the sale can rate it!");
        require(sale.status == SaleStatus.ConfirmedSuccess || sale.status == SaleStatus.ConfirmedFraud, "Not the right status!");
        require(sale.rated.sellerRated == false, "Seller has already rated on this one!");
        emit Rate(_saleId, _rate, payable(msg.sender));
        sale.rated.sellerRated = true;
    }

    function getRelatedSales() public view returns (Sale[] memory, string[] memory, AuctionContract.DataType[] memory){
        address payable user = payable(msg.sender);
        uint itemCount = 0;
        uint currentIndex = 0;
        for(uint i = 1;i <= saleId;i++){
            Sale storage sale = idToSale[i];
            if(sale.seller == user || sale.buyer == user){
                itemCount += 1;
            }
        }
        Sale[] memory saleItems = new Sale[](itemCount);
        string[] memory dataNameItems = new string[](itemCount);
        AuctionContract.DataType[] memory dataTypeItems = new AuctionContract.DataType[](itemCount);
        for(uint i = 1;i <= saleId;i++){
            Sale storage sale = idToSale[i];
            if(sale.seller == user || sale.buyer == user){
                if(sale.auctionInfo.isAuction){
                    AuctionContract.Auction memory auction = auctionContract.getAuctionById(sale.auctionInfo.auctionId);
                    dataNameItems[currentIndex] = auction.meta.name;
                    dataTypeItems[currentIndex] = auction.meta.dataType;
                }else{
                    DataContract.Data memory data = dataContract.getDataById(sale.dataId);
                    dataNameItems[currentIndex] = data.name;
                    dataTypeItems[currentIndex] = data.dataType;
                }
                saleItems[currentIndex] = sale;
                currentIndex++;
            }
        }
        return (saleItems, dataNameItems, dataTypeItems);
    }

    function getSaleById(uint _saleId) public view returns (Sale memory){
        return idToSale[_saleId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract UserContract is AccessControl{
    // Create new role identifiers for buyer and seller role
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");

    constructor() {
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SELLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BUYER_ROLE, DEFAULT_ADMIN_ROLE);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    function isSeller(address account) view external returns (bool){
        return hasRole(SELLER_ROLE, account);
    }

    function isBuyer(address account) view external returns (bool){
        return hasRole(BUYER_ROLE, account);
    }

    function createSeller(address account) public onlyAdmin{
        grantRole(SELLER_ROLE, account);
    }

    function createBuyer(address account) public onlyAdmin{
        grantRole(BUYER_ROLE, account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}