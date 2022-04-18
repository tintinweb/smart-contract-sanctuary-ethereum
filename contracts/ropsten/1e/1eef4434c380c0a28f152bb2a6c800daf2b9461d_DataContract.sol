/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

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