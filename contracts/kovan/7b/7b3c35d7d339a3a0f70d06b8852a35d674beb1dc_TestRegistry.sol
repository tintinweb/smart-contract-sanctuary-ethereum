/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

pragma solidity ^0.8.13;


interface IOwnable {
    function owner() external view returns (address);
}

contract TestRegistry  {
    mapping(bytes32 => address)         addresses;
    mapping(bytes32 => uint256)         uints;
    mapping(bytes32 => bool)            booleans;
    mapping(bytes32 => string)          strings;

    mapping(address => bool)    public  admins;

    mapping(address => mapping(address => bool)) public app_admins;


    event AdminUpdated(address user, bool isAdmin);
    event AppAdminChanged(address app,address user,bool state);
    //===
    event AddressChanged(string key, address value);
    event UintChanged(string key, uint256 value);
    event BooleanChanged(string key, bool value);
    event StringChanged(string key, string value);


   
    function setAdmin(address user,bool status ) external  {
        admins[user] = status;
        emit AdminUpdated(user,status);
    }

    function hash(string memory field) internal pure returns (bytes32) {
        return keccak256(abi.encode(field));
    }

    function setRegistryAddress(string memory fn, address value) external  {
        addresses[hash(fn)] = value;
        emit AddressChanged(fn,value);
    }

    function setRegistryBool(string memory fn, bool value) external  {
        booleans[hash(fn)] = value;
        emit BooleanChanged(fn,value);
    }

    function setRegistryString(string memory fn, string memory value) external  {
        strings[hash(fn)] = value;
        emit StringChanged(fn,value);
    }

    function setRegistryUINT(string memory fn, uint value) external  {
        uints[hash(fn)] = value;
        emit UintChanged(fn,value);
    }

    function setAppAdmin(address app, address user, bool state) external {
        require(
            msg.sender == IOwnable(app).owner() ||
            app_admins[app][msg.sender],
            "You do not have access permission"
        );
        app_admins[app][user] = state;
        emit AppAdminChanged(app,user,state);
    }

    function getRegistryAddress(string memory key) external view returns (address) {
        return addresses[hash(key)];
    }

    function getRegistryBool(string memory key) external view returns (bool) {
        return booleans[hash(key)];
    }

    function getRegistryUINT(string memory key) external view returns (uint256) {
        return uints[hash(key)];
    }

    function getRegistryString(string memory key) external view returns (string memory) {
        return strings[hash(key)];
    }

    function isAdmin(address user) external view returns (bool) {
        return  admins[user];
    }

    function isAppAdmin(address app, address user) external view returns (bool) {
        return 
            user == IOwnable(app).owner() ||
            app_admins[app][user];
    }
    
}