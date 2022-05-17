/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract asset {
    address contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    struct assetreg {
        uint id;
        uint area;
        string assetAddress;
        uint assetPrice;
        string allLatitudeLongitude;
        //string allLongitude;
        uint propertyPID;
        string physicalSurveyNumber;
        string document;
        bool isforSell;
        address payable ownerAddress;
        bool isassetVerified;
    }

    struct User{
        address id;
        string name;
        uint age;
        string city;
        string aadharNumber;
        string panNumber;
        string document;
        string email;
        bool isUserVerified;
    }

    struct assetInspector {
        uint id;
        address _addr;
        string name;
        uint age;
        string designation;
        string city;
    }

    struct assetRequest{
        uint reqId;
        address payable sellerId;
        address payable buyerId;
        uint assetId;
        reqStatus requestStatus;
        bool isPaymentDone;
    }
    enum reqStatus {requested,accepted,rejected,paymentdone,commpleted}


    uint inspectorsCount;
    uint public userCount;
    uint public assetsCount;
    uint public documentId;
    uint requestCount;


    mapping(address => assetInspector) public InspectorMapping;
    mapping(uint => address[]) allassetInspectorList;
    mapping(address => bool)  RegisteredInspectorMapping;
    mapping(address => User) public UserMapping;
    mapping(uint => address)  AllUsers;
    mapping(uint => address[])  allUsersList;
    mapping(address => bool)  RegisteredUserMapping;
    mapping(address => uint[])  Myassets;
    mapping(uint => assetreg) public assets;
    mapping(uint => assetRequest) public assetRequestMapping;
    mapping(address => uint[])  MyReceivedassetRequest;
    mapping(address => uint[])  MySentassetRequest;
    mapping(uint => uint[])  allassetList;
    mapping(uint => uint[])  paymentDoneList;


    function isContractOwner(address _addr) public view returns(bool){
        if(_addr==contractOwner)
            return true;
        else
            return false;
    }

    function changeContractOwner(address _addr)public {
        require(msg.sender==contractOwner,"you are not contractOwner");

        contractOwner=_addr;
    }

    //-----------------------------------------------assetInspector-----------------------------------------------

    function addassetInspector(address _addr,string memory _name, uint _age, string memory _designation,string memory _city) public returns(bool){
        if(contractOwner!=msg.sender)
            return false;
        require(contractOwner==msg.sender);
        RegisteredInspectorMapping[_addr]=true;
        allassetInspectorList[1].push(_addr);
        InspectorMapping[_addr] = assetInspector(inspectorsCount,_addr,_name, _age, _designation,_city);
        return true;
    }

    function ReturnAllassetIncpectorList() public view returns(address[] memory)
    {
        return allassetInspectorList[1];
    }

    function removeassetInspector(address _addr) public{
        require(msg.sender==contractOwner,"You are not contractOwner");
        require(RegisteredInspectorMapping[_addr],"asset Inspector not found");
        RegisteredInspectorMapping[_addr]=false;


        uint len=allassetInspectorList[1].length;
        for(uint i=0;i<len;i++)
        {
            if(allassetInspectorList[1][i]==_addr)
            {
                allassetInspectorList[1][i]=allassetInspectorList[1][len-1];
                allassetInspectorList[1].pop();
                break;
            }
        }
    }

    function isassetInspector(address _id) public view returns (bool) {
        if(RegisteredInspectorMapping[_id]){
            return true;
        }else{
            return false;
        }
    }



    //-----------------------------------------------User-----------------------------------------------

    function isUserRegistered(address _addr) public view returns(bool)
    {
        if(RegisteredUserMapping[_addr]){
            return true;
        }else{
            return false;
        }
    }

    function registerUser(string memory _name, uint _age, string memory _city,string memory _aadharNumber, string memory _panNumber, string memory _document, string memory _email
    ) public {

        require(!RegisteredUserMapping[msg.sender]);

        RegisteredUserMapping[msg.sender] = true;
        userCount++;
        allUsersList[1].push(msg.sender);
        AllUsers[userCount]=msg.sender;
        UserMapping[msg.sender] = User(msg.sender, _name, _age, _city,_aadharNumber,_panNumber, _document,_email,false);
        //emit Registration(msg.sender);
    }

    function verifyUser(address _userId) public{
        require(isassetInspector(msg.sender));
        UserMapping[_userId].isUserVerified=true;
    }
    function isUserVerified(address id) public view returns(bool){
        return UserMapping[id].isUserVerified;
    }
    function ReturnAllUserList() public view returns(address[] memory)
    {
        return allUsersList[1];
    }


    //-----------------------------------------------asset-----------------------------------------------
    function addasset(uint _area, string memory _address, uint _assetPrice,string memory _allLatiLongi, uint _propertyPID,string memory _surveyNum, string memory _document) public {
        require(isUserVerified(msg.sender));
        assetsCount++;
        assets[assetsCount] = assetreg(assetsCount, _area, _address, _assetPrice,_allLatiLongi,_propertyPID, _surveyNum , _document,false,payable(msg.sender),false);
        Myassets[msg.sender].push(assetsCount);
        allassetList[1].push(assetsCount);
        // emit Addingasset(assetsCount);
    }

    function ReturnAllassetList() public view returns(uint[] memory)
    {
        return allassetList[1];
    }

    function verifyasset(uint _id) public{
        require(isassetInspector(msg.sender));
        assets[_id].isassetVerified=true;
    }
    function isassetVerified(uint id) public view returns(bool){
        return assets[id].isassetVerified;
    }

    function myAllassets(address id) public view returns( uint[] memory){
        return Myassets[id];
    }


    function makeItforSell(uint id) public{
        require(assets[id].ownerAddress==msg.sender);
        assets[id].isforSell=true;
    }

    function requestforBuy(uint _assetId) public
    {
        require(isUserVerified(msg.sender) && isassetVerified(_assetId));
        requestCount++;
        assetRequestMapping[requestCount]=assetRequest(requestCount,assets[_assetId].ownerAddress,payable(msg.sender),_assetId,reqStatus.requested,false);
        MyReceivedassetRequest[assets[_assetId].ownerAddress].push(requestCount);
        MySentassetRequest[msg.sender].push(requestCount);
    }

    function myReceivedassetRequests() public view returns(uint[] memory)
    {
        return MyReceivedassetRequest[msg.sender];
    }
    function mySentassetRequests() public view returns(uint[] memory)
    {
        return MySentassetRequest[msg.sender];
    }
    function acceptRequest(uint _requestId) public
    {
        require(assetRequestMapping[_requestId].sellerId==msg.sender);
        assetRequestMapping[_requestId].requestStatus=reqStatus.accepted;
    }
    function rejectRequest(uint _requestId) public
    {
        require(assetRequestMapping[_requestId].sellerId==msg.sender);
        assetRequestMapping[_requestId].requestStatus=reqStatus.rejected;
    }

    function requesteStatus(uint id) public view returns(bool)
    {
        return assetRequestMapping[id].isPaymentDone;
    }

    function assetPrice(uint id) public view returns(uint)
    {
        return assets[id].assetPrice;
    }
    function makePayment(uint _requestId) public payable
    {
        require(assetRequestMapping[_requestId].buyerId==msg.sender && assetRequestMapping[_requestId].requestStatus==reqStatus.accepted);

        assetRequestMapping[_requestId].requestStatus=reqStatus.paymentdone;
        //assetRequestMapping[_requestId].sellerId.transfer(assets[assetRequestMapping[_requestId].assetId].assetPrice);
        //assets[assetRequestMapping[_requestId].assetId].ownerAddress.transfer(assets[assetRequestMapping[_requestId].assetId].assetPrice);
        assets[assetRequestMapping[_requestId].assetId].ownerAddress.transfer(msg.value);
        assetRequestMapping[_requestId].isPaymentDone=true;
        paymentDoneList[1].push(_requestId);
    }

    function returnPaymentDoneList() public view returns(uint[] memory)
    {
        return paymentDoneList[1];
    }

    function transferOwnership(uint _requestId,string memory documentUrl) public returns(bool)
    {
        require(isassetInspector(msg.sender));
        if(assetRequestMapping[_requestId].isPaymentDone==false)
            return false;
        documentId++;
        assetRequestMapping[_requestId].requestStatus=reqStatus.commpleted;
        Myassets[assetRequestMapping[_requestId].buyerId].push(assetRequestMapping[_requestId].assetId);

        uint len=Myassets[assetRequestMapping[_requestId].sellerId].length;
        for(uint i=0;i<len;i++)
        {
            if(Myassets[assetRequestMapping[_requestId].sellerId][i]==assetRequestMapping[_requestId].assetId)
            {
                Myassets[assetRequestMapping[_requestId].sellerId][i]=Myassets[assetRequestMapping[_requestId].sellerId][len-1];
                //Myassets[assetRequestMapping[_requestId].sellerId].length--;
                Myassets[assetRequestMapping[_requestId].sellerId].pop();
                break;
            }
        }
        assets[assetRequestMapping[_requestId].assetId].document=documentUrl;
        assets[assetRequestMapping[_requestId].assetId].isforSell=false;
        assets[assetRequestMapping[_requestId].assetId].ownerAddress=assetRequestMapping[_requestId].buyerId;
        return true;
    }
    function makePaymentTestFun(address payable _reveiver) public payable
    {
        _reveiver.transfer(msg.value);
    }
}