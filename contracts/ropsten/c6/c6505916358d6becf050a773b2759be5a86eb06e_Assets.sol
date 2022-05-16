/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Assets {
    address contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    struct Assetsreg {
        uint id;

        string fileName;
        string fileType;
        string category;
        string description;
        uint assetsPrice;
        

        string document;
        
        bool isforSell;
        address payable ownerAddress;
        bool isAssetsVerified;
    }

    struct User{
        address id;
        string name;
        uint age;
        string location;
        string aadharNumber;
        string phoneNumber;
        string document;
        string email;
        bool isUserVerified;
    }

    struct AssetsInspector {
        uint id;
        address _addr;
        string name;
        uint age;
        string designation;
        string location;
    }

    struct AssetsRequest{
        uint reqId;
        address payable sellerId;
        address payable buyerId;
        uint assetsId;
        reqStatus requestStatus;
        bool isPaymentDone;
    }
    enum reqStatus {requested,accepted,rejected,paymentdone,commpleted}


    uint inspectorsCount;
    uint public userCount;
    uint public assetsCount;
    uint public documentId;
    uint requestCount;


    mapping(address => AssetsInspector) public InspectorMapping;
    mapping(uint => address[]) allAssetsInspectorList;
    mapping(address => bool)  RegisteredInspectorMapping;
    mapping(address => User) public UserMapping;
    mapping(uint => address)  AllUsers;
    mapping(uint => address[])  allUsersList;
    mapping(address => bool)  RegisteredUserMapping;
    mapping(address => uint[])  MyAssets;
    mapping(uint => Assetsreg) public assets;
    mapping(uint => AssetsRequest) public AssetsRequestMapping;
    mapping(address => uint[])  MyReceivedAssetsRequest;
    mapping(address => uint[])  MySentAssetsRequest;
    mapping(uint => uint[])  allAssetsList;
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

    //-----------------------------------------------AssetsInspector-----------------------------------------------

    function addAssetsInspector(address _addr,string memory _name, uint _age, string memory _designation,string memory _location) public returns(bool){
        if(contractOwner!=msg.sender)
            return false;
        require(contractOwner==msg.sender);
        RegisteredInspectorMapping[_addr]=true;
        allAssetsInspectorList[1].push(_addr);
        InspectorMapping[_addr] = AssetsInspector(inspectorsCount,_addr,_name, _age, _designation,_location);
        return true;
    }

    function ReturnAllAssetsIncpectorList() public view returns(address[] memory)
    {
        return allAssetsInspectorList[1];
    }

    function removeAssetsInspector(address _addr) public{
        require(msg.sender==contractOwner,"You are not contractOwner");
        require(RegisteredInspectorMapping[_addr],"Assets Inspector not found");
        RegisteredInspectorMapping[_addr]=false;


        uint len=allAssetsInspectorList[1].length;
        for(uint i=0;i<len;i++)
        {
            if(allAssetsInspectorList[1][i]==_addr)
            {
                allAssetsInspectorList[1][i]=allAssetsInspectorList[1][len-1];
                allAssetsInspectorList[1].pop();
                break;
            }
        }
    }

    function isAssetsInspector(address _id) public view returns (bool) {
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

    function registerUser(string memory _name, uint _age, string memory _location,string memory _aadharNumber, string memory _phoneNumber, string memory _document, string memory _email
    ) public {

        require(!RegisteredUserMapping[msg.sender]);

        RegisteredUserMapping[msg.sender] = true;
        userCount++;
        allUsersList[1].push(msg.sender);
        AllUsers[userCount]=msg.sender;
        UserMapping[msg.sender] = User(msg.sender, _name, _age, _location,_aadharNumber,_phoneNumber, _document,_email,false);
        //emit Registration(msg.sender);
    }

    function verifyUser(address _userId) public{
        require(isAssetsInspector(msg.sender));
        UserMapping[_userId].isUserVerified=true;
    }
    function isUserVerified(address id) public view returns(bool){
        return UserMapping[id].isUserVerified;
    }
    function ReturnAllUserList() public view returns(address[] memory)
    {
        return allUsersList[1];
    }


    //-----------------------------------------------Assets-----------------------------------------------
    function addAssets(string memory _fileName, string memory _fileType, uint _assetsPrice,string memory _category, string memory _description, string memory _document) public {
        require(isUserVerified(msg.sender));
        assetsCount++;
        assets[assetsCount] = Assetsreg(assetsCount, _fileName, _fileType, _category, _description, _assetsPrice, _document,false,payable(msg.sender),false);
        MyAssets[msg.sender].push(assetsCount);
        allAssetsList[1].push(assetsCount);
        // emit AddingAssets(assetsCount);
    }

    function ReturnAllAssetsList() public view returns(uint[] memory)
    {
        return allAssetsList[1];
    }

    function verifyAssets(uint _id) public{
        require(isAssetsInspector(msg.sender));
        assets[_id].isAssetsVerified=true;
    }
    function isAssetsVerified(uint id) public view returns(bool){
        return assets[id].isAssetsVerified;
    }

    function myAllAssetss(address id) public view returns( uint[] memory){
        return MyAssets[id];
    }


    function makeItforSell(uint id) public{
        require(assets[id].ownerAddress==msg.sender);
        assets[id].isforSell=true;
    }

    function requestforBuy(uint _assetsId) public
    {
        require(isUserVerified(msg.sender) && isAssetsVerified(_assetsId));
        requestCount++;
        AssetsRequestMapping[requestCount]=AssetsRequest(requestCount,assets[_assetsId].ownerAddress,payable(msg.sender),_assetsId,reqStatus.requested,false);
        MyReceivedAssetsRequest[assets[_assetsId].ownerAddress].push(requestCount);
        MySentAssetsRequest[msg.sender].push(requestCount);
    }

    function myReceivedAssetsRequests() public view returns(uint[] memory)
    {
        return MyReceivedAssetsRequest[msg.sender];
    }
    function mySentAssetsRequests() public view returns(uint[] memory)
    {
        return MySentAssetsRequest[msg.sender];
    }
    function acceptRequest(uint _requestId) public
    {
        require(AssetsRequestMapping[_requestId].sellerId==msg.sender);
        AssetsRequestMapping[_requestId].requestStatus=reqStatus.accepted;
    }
    function rejectRequest(uint _requestId) public
    {
        require(AssetsRequestMapping[_requestId].sellerId==msg.sender);
        AssetsRequestMapping[_requestId].requestStatus=reqStatus.rejected;
    }

    function requesteStatus(uint id) public view returns(bool)
    {
        return AssetsRequestMapping[id].isPaymentDone;
    }

    function assetsPrice(uint id) public view returns(uint)
    {
        return assets[id].assetsPrice;
    }
    function makePayment(uint _requestId) public payable
    {
        require(AssetsRequestMapping[_requestId].buyerId==msg.sender && AssetsRequestMapping[_requestId].requestStatus==reqStatus.accepted);

        AssetsRequestMapping[_requestId].requestStatus=reqStatus.paymentdone;
        //AssetsRequestMapping[_requestId].sellerId.transfer(assets[AssetsRequestMapping[_requestId].assetsId].assetsPrice);
        //assets[AssetsRequestMapping[_requestId].assetsId].ownerAddress.transfer(assets[AssetsRequestMapping[_requestId].assetsId].assetsPrice);
        assets[AssetsRequestMapping[_requestId].assetsId].ownerAddress.transfer(msg.value);
        AssetsRequestMapping[_requestId].isPaymentDone=true;
        paymentDoneList[1].push(_requestId);
    }

    function returnPaymentDoneList() public view returns(uint[] memory)
    {
        return paymentDoneList[1];
    }

    function transferOwnership(uint _requestId,string memory documentUrl) public returns(bool)
    {
        require(isAssetsInspector(msg.sender));
        if(AssetsRequestMapping[_requestId].isPaymentDone==false)
            return false;
        documentId++;
        AssetsRequestMapping[_requestId].requestStatus=reqStatus.commpleted;
        MyAssets[AssetsRequestMapping[_requestId].buyerId].push(AssetsRequestMapping[_requestId].assetsId);

        uint len=MyAssets[AssetsRequestMapping[_requestId].sellerId].length;
        for(uint i=0;i<len;i++)
        {
            if(MyAssets[AssetsRequestMapping[_requestId].sellerId][i]==AssetsRequestMapping[_requestId].assetsId)
            {
                MyAssets[AssetsRequestMapping[_requestId].sellerId][i]=MyAssets[AssetsRequestMapping[_requestId].sellerId][len-1];
                //MyAssetss[AssetsRequestMapping[_requestId].sellerId].length--;
                MyAssets[AssetsRequestMapping[_requestId].sellerId].pop();
                break;
            }
        }
        assets[AssetsRequestMapping[_requestId].assetsId].document=documentUrl;
        assets[AssetsRequestMapping[_requestId].assetsId].isforSell=false;
        assets[AssetsRequestMapping[_requestId].assetsId].ownerAddress=AssetsRequestMapping[_requestId].buyerId;
        return true;
    }
    function makePaymentTestFun(address payable _reveiver) public payable
    {
        _reveiver.transfer(msg.value);
    }
}