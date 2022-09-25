//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Auth {
    struct UserDetail {
        address addr;
        string name;
        string password;
        string CNIC;
        string ipfsImageHash;
        bool isUserLoggedIn;
    }

    mapping(address => UserDetail) user;

    // user registration function
    function registerUser(
        address _address,
        string memory _name,
        string memory _password,
        string memory _cnic,
        string memory _ipfsImageHash
    ) public notAdmin returns (bool) {
        require(user[_address].addr != msg.sender);
        user[_address].addr = _address;
        user[_address].name = _name;
        user[_address].password = _password;
        user[_address].CNIC = _cnic;
        user[_address].ipfsImageHash = _ipfsImageHash;
        user[_address].isUserLoggedIn = false;
        return true;
    }

    // user login function
    function loginUser(address _address, string memory _password)
        public
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked(user[_address].password)) ==
            keccak256(abi.encodePacked(_password))
        ) {
            user[_address].isUserLoggedIn = true;
            return user[_address].isUserLoggedIn;
        } else {
            return false;
        }
    }

    // check the user logged In or not
    function checkIsUserLogged(address _address)
        public
        view
        returns (bool, string memory)
    {
        return (user[_address].isUserLoggedIn, user[_address].ipfsImageHash);
    }

    // logout the user
    function logoutUser(address _address) public {
        user[_address].isUserLoggedIn = false;
    }

    struct AdminDetail {
        address adminAddress;
        string name;
        string password;
        string ipfsImageHash;
        bool isAdminLoggedIn;
    }
    mapping(address => AdminDetail) admin;
    // admin registration function

    address adminAddress;

    constructor() public {
        adminAddress = 0x08d963D9c8bdAA8493D17c38A15d31b53f9e71dA;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    modifier notAdmin() {
        require(msg.sender != adminAddress);
        _;
    }

    function registerAdmin(
        address _address,
        string memory _name,
        string memory _password,
        string memory _ipfsImageHash
    ) public onlyAdmin returns (bool) {
        require(admin[_address].adminAddress != msg.sender);
        admin[_address].adminAddress = _address;
        admin[_address].name = _name;
        admin[_address].password = _password;
        admin[_address].ipfsImageHash = _ipfsImageHash;
        admin[_address].isAdminLoggedIn = false;
        return true;
    }

    // admin login function
    function loginAdmin(address _address, string memory _password)
        public
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked(admin[_address].password)) ==
            keccak256(abi.encodePacked(_password))
        ) {
            admin[_address].isAdminLoggedIn = true;
            return admin[_address].isAdminLoggedIn;
        } else {
            return false;
        }
    }

    // check the admin logged In or not
    function checkIsAdminLogged(address _address)
        public
        view
        returns (bool, string memory)
    {
        return (admin[_address].isAdminLoggedIn, admin[_address].ipfsImageHash);
    }

    // logout the admin
    function logoutAdmin(address _address) public {
        admin[_address].isAdminLoggedIn = false;
    }

    function getAdminBalance(address _address) public view returns (uint256) {
        return (admin[_address].adminAddress.balance);
    }
}