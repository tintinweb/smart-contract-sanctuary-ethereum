// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract ERC20Contract {
    string public name = "Fungible-Token";
    string public symbol = "FGT";
    uint256 public totalSupply = 1000;
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    mapping(address => user) public users;
    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct user {
        address MetamaskAddress;
        string name;
        string email;
        uint256 phoneNumber;
        string permanentAddress;
        string country;
        string city;
        bool isExist;
    }

    function userInfo(
        address MetamaskAddress,
        string memory name,
        string memory email,
        uint256 phoneNumber,
        string memory permanentAddress,
        string memory country,
        string memory city
    ) public onlyOwner {
        require(
            users[MetamaskAddress].isExist == false,
            "This customer address already exists......"
        );

        users[MetamaskAddress] = user(
            MetamaskAddress,
            name,
            email,
            phoneNumber,
            permanentAddress,
            country,
            city,
            true
        );
    }

    //function to transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    //function to transfer Tokens
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not Enough Tokens");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    //function to check balance of any account
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // Function to update Users basic information
    function updateuser(
        address MetamaskAddress,
        string memory _newName,
        string memory _newEmail,
        uint256 _newPhoneNumber,
        string memory _newPermanentAddress,
        string memory _newCity
        
    ) public returns (string memory, string memory,uint256,string memory, string memory) {
        user memory updateUser = users[MetamaskAddress];
        updateUser.name = _newName;
        updateUser.email = _newEmail;
        updateUser.phoneNumber = _newPhoneNumber;
        updateUser.permanentAddress = _newPermanentAddress;
        updateUser.city = _newCity;
        users[MetamaskAddress] = updateUser;
        return (updateUser.name, updateUser.email,updateUser.phoneNumber,updateUser.permanentAddress,updateUser.city);
    }


    

}

//0xb309dEf37017F55856eD07Aba09C1f4C637f6810 Owner address
//0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 gaurav address
//0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 manoj address