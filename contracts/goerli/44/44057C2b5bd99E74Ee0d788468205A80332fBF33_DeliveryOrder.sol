// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract DeliveryOrder {
    /** Requirements
    - Only Cargo owner can create a new request DO
    - Multiple request DO can be created by single cargo owner.
    - 
     */
    address payable public owner; //owner of this contract
    uint256 totalRequestDO;//no. of delivery order
    struct Container{
        string containerNumber;
        string sealNumber;
        string sizeType;
        uint256 grossWeight;
        string depoName;
        string phoneNumber;
    }
    struct RequestDO {
        address cargoOwner;
        string DONumber;
        string shippingAgency;
        address SL;
        string notifyParty;
        string consignee;
        string shipper;
        string portOfLoading;
        string portOfDischarge;
        string portOfDelivery;
        Container[] containers;
        string status;
        uint256 containersSize;
        string expiredDate;
    }
    mapping(uint256 => RequestDO) public requests;
    modifier onlyOwner {
        require(msg.sender == owner,"Only owner can call this function.");
        _;
    }
    modifier onlySL(uint256 _id) {
        require(msg.sender == requests[_id].SL,"Only SL can call this function.");
        _;
    }
    constructor() payable {
        owner = payable(msg.sender);
    }
    // OLEH CARGO OWNER
    //Creation of a campaign
    function createRequestDO (
        string memory _DONumber, 
        string memory _shippingAgency, 
        address _SL, 
        string memory _notifyParty, 
        string memory _consignee, 
        string memory _shipper, 
        string memory _portOfLoading, 
        string memory _portOfDischarge, 
        string memory _portOfDelivery,
        string memory _expiredDate,
        Container[] memory _containers
    ) public returns (uint256) {
        // verifikasi dan validasi data
        require(
            bytes(_DONumber).length !=0 && 
            bytes(_shippingAgency).length !=0 && 
            bytes(_notifyParty).length !=0 && 
            bytes(_consignee).length !=0 && 
            bytes(_shipper).length !=0 && 
            bytes(_portOfLoading).length !=0 && 
            bytes(_portOfDischarge).length !=0 && 
            bytes(_portOfDelivery).length !=0, 
            'Incomplete data, all field must be filled in!');
        require(_containers.length > 0, 'Container must be more than zero!');
        
        RequestDO storage aRequestDO = requests[totalRequestDO];
        for (uint i=0; i < _containers.length; i++) {
            Container memory aContainer = Container(_containers[i].containerNumber,_containers[i].sealNumber,_containers[i].sizeType,_containers[i].grossWeight,_containers[i].depoName,_containers[i].phoneNumber);
            aRequestDO.containers.push(aContainer);
        }
        aRequestDO.cargoOwner = msg.sender;
        aRequestDO.DONumber = _DONumber;
        aRequestDO.shippingAgency = _shippingAgency;
        aRequestDO.SL = _SL;
        aRequestDO.notifyParty = _notifyParty;
        aRequestDO.consignee = _consignee;
        aRequestDO.shipper = _shipper;
        aRequestDO.portOfLoading = _portOfLoading;
        aRequestDO.portOfDischarge = _portOfDischarge;
        aRequestDO.portOfDelivery = _portOfDelivery;
        aRequestDO.status = "ON PROCESS";
        aRequestDO.expiredDate = _expiredDate;
        totalRequestDO++;
        return totalRequestDO - 1;
    }
    function getAllCORequestsDO () public view returns (RequestDO[] memory) {
        RequestDO[] memory allRequestDOs = new RequestDO[](totalRequestDO);
        for (uint i = 0; i < totalRequestDO; i++){
            RequestDO storage item = requests[i];
            if(item.cargoOwner != msg.sender) {
                continue;
            }
            allRequestDOs[i] = item;
        }
        return allRequestDOs;
    }
    function getCORequestDO (uint256 _id) public view returns(RequestDO memory) {
        RequestDO storage request = requests[_id];
        return request;
    }
    
    
    
    // OLEH SHIPPING LINE
    function getAllRequestsDO () public view returns (RequestDO[] memory) {
        RequestDO[] memory allRequestDOs = new RequestDO[](totalRequestDO);
        for (uint i = 0; i < totalRequestDO; i++){
            RequestDO storage item = requests[i];
            allRequestDOs[i] = item;
        }
        return allRequestDOs;
    }
    function approveRequest(uint256 _id) public onlySL(_id) {
        RequestDO storage request = requests[_id];
        request.status = "APPROVED";
    }
    function rejectRequest(uint256 _id) public onlySL(_id) {
        RequestDO storage request = requests[_id];
        request.status = "REJECTED";
    }
}