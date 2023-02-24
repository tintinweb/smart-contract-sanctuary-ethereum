/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;
pragma experimental ABIEncoderV2;
contract Land {
    struct Landreg {
        uint id;
        uint area;
        string city;
        string state;
        uint landPrice;
        uint propertyPID;   
        uint physicalSurveyNumber;
        string ipfsHash;
        string document;
    }
    struct Buyer{
        address id;
        string name;
        uint age;
        string city;
        string aadharNumber;
        string panNumber;
        string document;
        string email;
    }
    struct Seller{
        address id;
        string name;
        uint age;
        string aadharNumber;
        string panNumber;
        string landsOwned;
        string document;
    }
    struct LandInspector {
        uint id;
        string name;
        uint age;
        string designation;
    }
    struct LandRequest{
        uint reqId;
        address sellerId;
        address buyerId;
        uint landId;
        // bool requestStatus;
        // bool requested;
    }

    //key value pairs
    mapping(uint => Landreg) public lands;
    mapping(uint => LandInspector) public InspectorMapping;
    mapping(address => Seller) public SellerMapping;
    mapping(address => Buyer) public BuyerMapping;
    mapping(uint => LandRequest) public RequestsMapping;

    mapping(address => bool) public RegisteredAddressMapping;
    mapping(address => bool) public RegisteredSellerMapping;
    mapping(address => bool) public RegisteredBuyerMapping;
    mapping(address => bool) public SellerVerification;
    mapping(address => bool) public SellerRejection;
    mapping(address => bool) public BuyerVerification;
    mapping(address => bool) public BuyerRejection;
    mapping(uint => bool) public LandVerification;
    mapping(uint => address) public LandOwner;
    mapping(uint => bool) public RequestStatus;
    mapping(uint => bool) public RequestedLands;
    mapping(uint => bool) public PaymentReceived;

    address public Land_Inspector;
    address[] public sellers;
    address[] public buyers;

    uint public landsCount;
    uint public inspectorsCount;
    uint public sellersCount;
    uint public buyersCount;
    uint public requestsCount;

    event Registration(address _registrationId);
    event AddingLand(uint indexed _landId);
    event Landrequested(address _sellerId);
    event requestApproved(address _buyerId);
    event Verified(address _id);
    event Rejected(address _id);

    constructor(){
        Land_Inspector = msg.sender ;
        addLandInspector("Inspector 1", 45, "Tehsil Manager");
    }

    function addLandInspector(string memory _name, uint _age, string memory _designation) private {
        inspectorsCount++;
        InspectorMapping[inspectorsCount] = LandInspector(inspectorsCount, _name, _age, _designation);
    }

    function getLandsCount() public view returns (uint) {
        return landsCount;
    }

    function getBuyersCount() public view returns (uint) {
        return buyersCount;
    }

    function getSellersCount() public view returns (uint) {
        return sellersCount;
    }

    function getRequestsCount() public view returns (uint) {
        return requestsCount;
    }
    function getArea(uint i) public view returns (uint) {
        return lands[i].area;
    }
    function getCity(uint i) public view returns (string memory) {
        return lands[i].city;
    }
     function getState(uint i) public view returns (string memory) {
        return lands[i].state;
    }
    // function getStatus(uint i) public view returns (bool) {
    //     return lands[i].verificationStatus;
    // }
    function getPrice(uint i) public view returns (uint) {
        return lands[i].landPrice;
    }
    function getPID(uint i) public view returns (uint) {
        return lands[i].propertyPID;
    }
    function getSurveyNumber(uint i) public view returns (uint) {
        return lands[i].physicalSurveyNumber;
    }
    function getImage(uint i) public view returns (string memory) {
        return lands[i].ipfsHash;
     }
    function getDocument(uint i) public view returns (string memory) {
        return lands[i].document;
    }
    
    function getLandOwner(uint id) public view returns (address) {
        return LandOwner[id];
    }

    function verifySeller(address _sellerId) public{
        require(isLandInspector(msg.sender));

        SellerVerification[_sellerId] = true;
        emit Verified(_sellerId);
    }

    function rejectSeller(address _sellerId) public{
        require(isLandInspector(msg.sender));

        SellerRejection[_sellerId] = true;
        emit Rejected(_sellerId);
    }

    function verifyBuyer(address _buyerId) public{
        require(isLandInspector(msg.sender));
        BuyerVerification[_buyerId] = true;
        emit Verified(_buyerId);
    }

    function rejectBuyer(address _buyerId) public{
        require(isLandInspector(msg.sender));
        BuyerRejection[_buyerId] = true;
        emit Rejected(_buyerId);
    }
    
    function verifyLand(uint _landId) public{
        require(lands[_landId].id==_landId);
        require(isLandInspector(msg.sender));

        LandVerification[_landId] = true;
        
       
    }
    function isLandVerified(uint _id) public view returns (bool result) {
        result=false;
        if(LandVerification[_id]){
            return result= true;
        }
    }

    function isVerified(address _id) public view returns (bool result) {
        result=false;
        if(SellerVerification[_id] || BuyerVerification[_id]){
            return result=true;
        }
    }

    function isRejected(address _id) public view returns (bool result) {
        result=false;
        if(SellerRejection[_id] || BuyerRejection[_id]){
            return result=true;
        }
    }

    function isSeller(address _id) public view returns (bool result) {
        result=false;
        if(RegisteredSellerMapping[_id]){
            return result=true;
        }
    }

    function isLandInspector(address _id) public view returns (bool ) {
        if(Land_Inspector == _id){
            return true;
        }else{
            return false;
        }
    }

    function isBuyer(address _id) public view returns (bool result) {
        result=false;
        if(RegisteredBuyerMapping[_id]){
             return result =true;
        }
    }
    function isRegistered(address _id) public view returns (bool result) {
        result=false;
        if(RegisteredAddressMapping[_id]){
            return result =true;
        }
    }

    function addLand(uint _area, string memory _city,string memory _state, uint landPrice, uint _propertyPID,uint _surveyNum,string memory _ipfsHash, string memory _document) public {
        require((isSeller(msg.sender)) && (isVerified(msg.sender)));
        landsCount++;
        lands[landsCount] = Landreg(landsCount, _area, _city, _state, landPrice,_propertyPID, _surveyNum, _ipfsHash, _document);
        LandOwner[landsCount] = msg.sender;
        // emit AddingLand(landsCount);
    }

    //registration of seller
    function registerSeller(string memory _name, uint _age, string memory _aadharNumber, string memory _panNumber, string memory _landsOwned, string memory _document) public {
        //require that Seller is not already registered
        require(!RegisteredAddressMapping[msg.sender]);

        RegisteredAddressMapping[msg.sender] = true;
        RegisteredSellerMapping[msg.sender] = true ;
         sellersCount++;
        SellerMapping[msg.sender] = Seller(msg.sender, _name, _age, _aadharNumber,_panNumber, _landsOwned, _document);
        sellers.push(msg.sender);
        emit Registration(msg.sender);
    }

    function updateSeller(string memory _name, uint _age, string memory _aadharNumber, string memory _panNumber, string memory _landsOwned) public {
        //require that Seller is already registered
        require(RegisteredAddressMapping[msg.sender] && (SellerMapping[msg.sender].id == msg.sender));

        SellerMapping[msg.sender].name = _name;
        SellerMapping[msg.sender].age = _age;
        SellerMapping[msg.sender].aadharNumber = _aadharNumber;
        SellerMapping[msg.sender].panNumber = _panNumber;
        SellerMapping[msg.sender].landsOwned = _landsOwned;

    }

    function getSeller() public view returns( address [] memory ){
        return(sellers);
    }

    function getSellerDetails(address i) public view returns (string memory, uint, string memory, string memory, string memory, string memory) {
        return (SellerMapping[i].name, SellerMapping[i].age, SellerMapping[i].aadharNumber, SellerMapping[i].panNumber, SellerMapping[i].landsOwned, SellerMapping[i].document);
    }

    function registerBuyer(string memory _name, uint _age, string memory _city, string memory _aadharNumber, string memory _panNumber, string memory _document, string memory _email) public {
        //require that Buyer is not already registered
        require(!RegisteredAddressMapping[msg.sender]);

        RegisteredAddressMapping[msg.sender] = true;
        RegisteredBuyerMapping[msg.sender] = true ;
        buyersCount++;
        BuyerMapping[msg.sender] = Buyer(msg.sender, _name, _age, _city, _aadharNumber, _panNumber, _document, _email);
        buyers.push(msg.sender);

        emit Registration(msg.sender);
    }

    function updateBuyer(string memory _name,uint _age, string memory _city,string memory _aadharNumber, string memory _email, string memory _panNumber) public {
        //require that Buyer is already registered
        require(RegisteredAddressMapping[msg.sender] && (BuyerMapping[msg.sender].id == msg.sender));

        BuyerMapping[msg.sender].name = _name;
        BuyerMapping[msg.sender].age = _age;
        BuyerMapping[msg.sender].city = _city;
        BuyerMapping[msg.sender].aadharNumber = _aadharNumber;
        BuyerMapping[msg.sender].email = _email;
        BuyerMapping[msg.sender].panNumber = _panNumber;
        
    }

    function getBuyer() public view returns( address [] memory ){
        return(buyers);
    }

    function getBuyerDetails(address i) public view returns ( string memory,string memory, string memory, string memory, string memory, uint, string memory) {
        return (BuyerMapping[i].name,BuyerMapping[i].city , BuyerMapping[i].panNumber, BuyerMapping[i].document, BuyerMapping[i].email, BuyerMapping[i].age, BuyerMapping[i].aadharNumber);
    }


    function requestLand(address _sellerId, uint _landId) public{
        require(isBuyer(msg.sender) && isVerified(msg.sender));
        
        requestsCount++;
        RequestsMapping[requestsCount] = LandRequest(requestsCount, _sellerId, msg.sender, _landId);
        RequestStatus[requestsCount] = false;
        RequestedLands[requestsCount] = true;

        emit Landrequested(_sellerId);
    }

    function getRequestDetails (uint i) public view returns (address, address, uint, bool) {
        return(RequestsMapping[i].sellerId, RequestsMapping[i].buyerId, RequestsMapping[i].landId, RequestStatus[i]);
    }

    function isRequested(uint _id) public view returns (bool result) {
        result=false;
        if(RequestedLands[_id]){
            return result=true;
        }
    }

    function isApproved(uint _id) public view returns (bool result) {
        result=false;
        if(RequestStatus[_id]){
            return result=true;
        }
    }

    function approveRequest(uint _reqId) public {
        require((isSeller(msg.sender)) && (isVerified(msg.sender)));
       
        RequestStatus[_reqId] = true;

    }

    function LandOwnershipTransfer(uint _landId, address _newOwner) public{
        require(isLandInspector(msg.sender));

        LandOwner[_landId] = _newOwner;
    }

    function isPaid(uint _landId) public view returns (bool result) {
        result=false;
        if(PaymentReceived[_landId]){
            return result=true;
        }
    }
    //0x80cDF19C6040F2Cc7D928c858eC4821c48d21534

    function payment(address payable _receiver, uint _landId) public payable {
        PaymentReceived[_landId] = true;
        _receiver.transfer(msg.value);
    }




}