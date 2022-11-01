/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// File: contracts/Land.sol


pragma solidity 0.8.17;

contract Land {
    address SDM;

    constructor(){
        SDM = msg.sender;
    }

    struct Landreg {
        uint id;
        uint area;
        string landAddress;
        uint landPrice;
        string allLatitudeLongitude;
        uint propertyPID;
        string physicalSurveyNumber;
        string document;
        bool isforSell;
        address ownerAddress;
        bool isLandVerified;
        address[] pastOwners;
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

    struct Lekhpal {
        address _addr;
        string name;
        uint age;
        string designation;
        string city;
    }

    struct Tehsildar {
        address _addr;
        string name;
        uint age;
        string tehsil;
    }

    uint public userCount;
    uint public landsCount;

    mapping(address => Lekhpal) public lekhpalMapping;
    mapping(uint => address[]) lekhpalList;
    mapping(address => bool)  registeredLekhpalMapping;

    mapping(address => User) public UserMapping;
    mapping(uint => address)  AllUsers;
    mapping(uint => address[])  allUsersList;
    mapping(address => bool)  RegisteredUserMapping;

    mapping(address => uint[])  MyLands;
    mapping(uint => Landreg) public lands;
    mapping(uint => uint[])  allLandList;

    mapping(address => Tehsildar) public tehsildarMapping;
    mapping(uint => address[]) tehsildarList;
    mapping(address => bool)  registeredTehsildarMapping;

    //-----------------------------------------------SDM-----------------------------------------------

    function isSDM(address _addr) public view returns(bool){
        if(_addr==SDM) return true;
        else return false;
    }

    function changeSDM(address _addr)public {
        require(msg.sender==SDM,"you are not SDM");
        SDM=_addr;
    }

    //-----------------------------------------------Tehsildar-----------------------------------------------

    function addTehsildar(address _addr,string memory _name, uint _age, string memory _tehsil) public returns(bool) {
        require(SDM==msg.sender,"function caller is not SDM");
        registeredTehsildarMapping[_addr]=true;
        tehsildarList[1].push(_addr);
        tehsildarMapping[_addr] = Tehsildar(_addr,_name,_age,_tehsil);
        return true;
    }

    function removeTehsildar(address _addr) public{
        require(msg.sender==SDM,"You are not SDM");
        require(registeredTehsildarMapping[_addr],"Tehsiladar not found");
        registeredTehsildarMapping[_addr]=false;
        uint len=tehsildarList[1].length;
        for(uint i=0;i<len;i++)
        {
            if(tehsildarList[1][i]==_addr)
            {
                tehsildarList[1][i]=tehsildarList[1][len-1];
                tehsildarList[1].pop();
                break;
            }
        }
    }

    function isTehsildar(address _addr) public view returns (bool) {
        if(registeredTehsildarMapping[_addr]) return true;
        else return false;
    }

    //-----------------------------------------------Lekhpal-----------------------------------------------

    function addLekhpal(address _addr,string memory _name, uint _age, string memory _designation,string memory _city) public returns(bool){
        require(isTehsildar(msg.sender) == true,"function caller is not Tehsildar");
        registeredLekhpalMapping[_addr]=true;
        lekhpalList[1].push(_addr);
        lekhpalMapping[_addr] = Lekhpal(_addr,_name, _age, _designation,_city);
        return true;
    }

    function removeLekhpal(address _addr) public{
        require(isTehsildar(msg.sender) == true,"function caller is not Tehsildar");
        require(registeredLekhpalMapping[_addr],"Lekhpal not found");
        registeredLekhpalMapping[_addr]=false;
        uint len=lekhpalList[1].length;
        for(uint i=0;i<len;i++)
        {
            if(lekhpalList[1][i]==_addr)
            {
                lekhpalList[1][i]=lekhpalList[1][len-1];
                lekhpalList[1].pop();
                break;
            }
        }
    }

    function isLekhpal(address _addr) public view returns (bool) {
        if(registeredLekhpalMapping[_addr]) return true;
        else return false;
    }

    //-----------------------------------------------User-----------------------------------------------

    function isUserRegistered(address _addr) public view returns(bool)
    {
        if(RegisteredUserMapping[_addr]) return true;
        else return false;

    }

    function registerUser(string memory _name, uint _age, string memory _city,string memory _aadharNumber, string memory _panNumber, string memory _document, string memory _email
    ) public {

        require(!RegisteredUserMapping[msg.sender]);

        RegisteredUserMapping[msg.sender] = true;
        userCount++;
        allUsersList[1].push(msg.sender);
        AllUsers[userCount]=msg.sender;
        UserMapping[msg.sender] = User(msg.sender, _name, _age, _city,_aadharNumber,_panNumber, _document,_email,false);
    }

    function verifyUser(address _userId) public{
        require(isLekhpal(msg.sender));
        UserMapping[_userId].isUserVerified=true;
    }

    function isUserVerified(address id) public view returns(bool){
        return UserMapping[id].isUserVerified;
    }



    //-----------------------------------------------Land-----------------------------------------------
    function addLand(uint _area, string memory _address, uint landPrice,string memory _allLatiLongi, uint _propertyPID,string memory _surveyNum, string memory _document) public {
        require(isUserVerified(msg.sender));
        landsCount++;
        lands[landsCount] = Landreg(landsCount, _area, _address, landPrice,_allLatiLongi,_propertyPID, _surveyNum , _document,false,payable(msg.sender),false,new address[](0));
        MyLands[msg.sender].push(landsCount);
        allLandList[1].push(landsCount);
    }

    function verifyLand(uint _id) public{
        require(isLekhpal(msg.sender),"you should be lekhpal to call this function");
        require(lands[_id].area != 0, "Land doesn't exist");
        lands[_id].isLandVerified=true;
    }

    function isLandVerified(uint id) public view returns(bool){
        return lands[id].isLandVerified;
    }


    function transferOwnership(address _from, address _to, uint _id) public returns(bool){
        require(isTehsildar(msg.sender),"you should be tehsildar to call this function");
        require(isUserVerified(_from));
        require(isUserVerified(_to));
        require(isLandVerified(_id));
        require(lands[_id].ownerAddress == _from);

        lands[_id].ownerAddress = _to;
        lands[_id].pastOwners.push(_from);
        return true;
    }

    function checkPastOwner (uint _id, uint _ownerNum) public view returns(address) {
        return lands[_id].pastOwners[_ownerNum];
    }

    function getPastOwners (uint _id) public view returns(address  [] memory) {
        return lands[_id].pastOwners;
    }
}