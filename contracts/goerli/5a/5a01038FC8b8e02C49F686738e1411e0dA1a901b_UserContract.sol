// // SPDX-License-Identifier: MIT
/*  
   _____ ____  __    ____  _____ ______________  ______  ______
  / ___// __ \/ /   / __ \/ ___// ____/ ____/ / / / __ \/ ____/
  \__ \/ / / / /   / / / /\__ \/ __/ / /   / / / / /_/ / __/   
 ___/ / /_/ / /___/ /_/ /___/ / /___/ /___/ /_/ / _, _/ /___   
/____/\____/_____/\____//____/_____/\____/\____/_/ |_/_____/   

*/

pragma solidity ^0.8.9;

contract UserContract{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error notAdmin();
    error addressAlreadyRegistered();
    error zeroAddressNotSupported();
    error adminAlreadyExist();
    error notAdminAddress();
    error invalidType();
    
    address[] private pushUsers;
    address[] private adminAddresses;
    address private owner;
    mapping(address => bool) private isUser;
    mapping(address => uint) private userTypeData;
    mapping(uint => string) public userTypes;
    mapping(address => bool) private adminAddress;

    /**
        * constructor
    */
    constructor(){
        owner = msg.sender;
        userTypes[1] = "admin";
        userTypes[2] = "corporateUser";
        userTypes[3] = "appUser"; 
    }

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the admin");
        _;
    }

    function whitelistAdmin(address _admin) external onlyOwner{
        if(_admin == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[_admin] == true){ revert adminAlreadyExist();}
        adminAddress[_admin] = true;
        adminAddresses.push(_admin);
    }

    struct userBulkData{
        address _ad;
        uint _type;
    }
    
    /**
        *  addUser
        * @param _ad - Admin has the access to enter the user address to the blockchain.
        * @param _type - Enter the type, whether admin, corporate user, app user. 
    */
    function addUser(address _ad, uint _type) external {
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        if(isUser[_ad] == true){ revert addressAlreadyRegistered();}
        if(bytes(userTypes[_type]).length == 0){ revert invalidType();}
        isUser[_ad] = true;
        userTypeData[_ad] = _type;
        pushUsers.push(_ad);
    }

    /**
        * addUserBulk
        * @param userData - Enter the user data (address and type) as array format.
    */
    function addUserBulk(userBulkData[] memory userData) external {
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        for(uint i = 0; i < userData.length; i++){
            if(isUser[userData[i]._ad] == true){ revert addressAlreadyRegistered();}
            if(bytes(userTypes[userData[i]._type]).length == 0){ revert invalidType();}
            isUser[userData[i]._ad] = true;
            userTypeData[userData[i]._ad] = userData[i]._type;
            pushUsers.push(userData[i]._ad);
        }
    }

    /**
        *  verifyUser
        * @param _ad - Enter the address, to know about the role
    */
    function verifyUser(address _ad) external view returns(bool, uint){
        if(isUser[_ad]){
            return (true, userTypeData[_ad]);
        }else{
            return (false, userTypeData[_ad]);
        }
    }

    /**
        *  getAllUserAddress
        *  outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }   

    function allAdmins() external view returns(address[] memory){
        return adminAddresses;
    } 
}