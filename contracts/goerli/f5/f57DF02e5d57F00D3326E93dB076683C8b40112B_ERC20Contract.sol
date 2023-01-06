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
        string memory _newName
        
    ) public returns (string memory) {
        user memory updateUser = users[MetamaskAddress];
        updateUser.name = _newName;
        users[MetamaskAddress] = updateUser;
        return (updateUser.name);
    }
}