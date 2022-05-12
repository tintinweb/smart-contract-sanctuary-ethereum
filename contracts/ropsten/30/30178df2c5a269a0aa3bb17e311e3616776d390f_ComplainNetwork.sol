/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

pragma solidity 0.5.16;

contract ComplainNetwork{
    // let us start with creating the contract in solidity 0.5.0 
    // we need some changes for view and taking action 
    
    enum Status {Pending,Proposed,Resolved }
    struct Citizen{
        uint _citId;
        string _name;
        string _email;
        string _password;
        uint _phone;
        address _accAddress;
        // should you store the address or not that is the quest
    }
    
    struct Complaint{
        // for storing the location
        uint _lat;
        uint _long;
        // category
        uint _category;
        string _data;
        string _proposedSolution;
        address _personId;
        Status _status;
        uint _reward;
        address _policeAssigned;
        address payable[] _contributors;
        uint[] _contAmount;
    }
    
    uint public complainCounter;
    uint private citizenCount;
    mapping(uint =>Complaint) private complainMap; 
    mapping(uint =>Citizen) private loginData;
    mapping(address =>bool) private policeAccounts;
    mapping(uint => address payable) complainSolver;
    address private superUser;

    constructor() public {
        superUser = msg.sender;
        complainCounter = 0;
        citizenCount = 1;
    }

    modifier complainOwnerAccess(uint cid){
        // check if user is the one who register the complaint
        require(complainMap[cid]._personId== msg.sender);
        _;
    }
    modifier superUserAccess(){
        require(msg.sender ==superUser);
        _;
    }
    modifier complainOwnOrPoliceAccess(uint cid) {
        require(policeAccounts[msg.sender] == true || msg.sender == complainMap[cid]._personId);
        _;
    }
    function viewCitizen(uint cid) public view returns(string memory,string memory,uint,address){
        return(loginData[cid]._name,loginData[cid]._email,loginData[cid]._phone,loginData[cid]._accAddress);
    }
    function registerCitizen(string memory name,string memory email ,string memory password ,uint phone ) public {
        loginData[citizenCount]._name = name;
        loginData[citizenCount]._email = email;
        loginData[citizenCount]._password = password;
        loginData[citizenCount]._phone = phone ;
        loginData[citizenCount]._accAddress = msg.sender;
        // should you store the address of the curr user 
        // create a mapping for address to password
        citizenCount++;
        loginData[citizenCount]._citId = citizenCount;
        //increment the citizencount then the value 

    }
    function LoginCitizen(string memory email,string memory password) public view returns(uint){
        // start with checking if email exists in logindata 
        // check for authentication 
        uint i ;
        for( i = 0;i<citizenCount;i++){
            if((keccak256(bytes(loginData[i]._email)) == keccak256(bytes(email))) && (keccak256(bytes(loginData[i]._password)) == keccak256(bytes(password)))){
                // if email and password matches the user then return true or else false;
                return loginData[i]._citId;
            }     
        }
        if(i==citizenCount){
            return 0;
        }
    }
    // let us write a function to register a complaint
    function registerComplain(string memory data,uint lat,uint long,uint cat) public payable returns(uint){
        complainMap[complainCounter]._lat = lat;
        complainMap[complainCounter]._long = long;
        complainMap[complainCounter]._category = cat;
        complainMap[complainCounter]._data = data;
        complainMap[complainCounter]._personId = msg.sender;
        complainMap[complainCounter]._status = Status.Pending;
        complainMap[complainCounter]._reward = msg.value;
        
        if(msg.value >0){
            // if the person who has registered complain has put some reward add his name to the contributors
            complainMap[complainCounter]._contributors.push(msg.sender);
            complainMap[complainCounter]._contAmount.push(msg.value);
        }

        complainCounter++;
        return complainCounter-1;

        // done with the register function ;
        //[0xD2Af2CbF3D3B93A61BdC41d0Def688d68CE94Fd0,0xEEF9904227552c98CEB16cc835182538352c5C6a]
    }  
    
    function viewSolution(uint cid) public view returns(string memory){
        return (complainMap[cid]._proposedSolution);
    }
    function viewComplain(uint cid) public view returns(uint ,uint ,uint,uint,address,string memory,Status ){
        // we can now atleast register the complain and then view it 
        return (cid,complainMap[cid]._reward,complainMap[cid]._long,complainMap[cid]._lat,complainMap[cid]._personId,complainMap[cid]._data,complainMap[cid]._status);   
    }

    function resolve(uint cid) public complainOwnerAccess(cid){
        // only the owner of complain can resolve the complaint
        complainMap[cid]._status = Status.Resolved;
        // if resolved call the transferFunds function
        complainMap[cid]._reward = 0;
        complainMap[cid]._proposedSolution = "";
        // transferFunds(cid);
    }

    function transferFunds(uint cid) private{
        if(complainMap[cid]._reward > 0){
            complainSolver[cid].transfer(complainMap[cid]._reward);
        }
        // transfer funds not working so what to do 

    } 
    function getComplainSolver(uint cid) public view returns(address payable){
        return complainSolver[cid];
    }
    
    function declineProposal(uint cid) public complainOwnerAccess(cid) {
        require( complainMap[cid]._status == Status.Proposed );
        complainMap[cid]._status = Status.Pending;
        complainMap[cid]._proposedSolution = "";
        complainSolver[cid] = address(uint160(0));
    }
    
    function fundComplain(uint cid) public payable{
        require((complainMap[cid]._status == Status.Pending) || (complainMap[cid]._status == Status.Proposed));
        complainMap[cid]._reward += msg.value;
        complainMap[cid]._contributors.push(msg.sender);
        complainMap[cid]._contAmount.push(msg.value);
    }
    function claimSolution(uint cid,string memory solution) public   {
        require(complainMap[cid]._status == Status.Pending);
        complainMap[cid]._status = Status.Proposed;
        complainMap[cid]._proposedSolution = solution;
        complainSolver[cid] = msg.sender;
    }
    
    function checkFund() public view returns(uint){
        return address(this).balance;
    }
}