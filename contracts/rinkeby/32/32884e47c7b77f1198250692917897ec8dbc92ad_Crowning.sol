/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Crowning {
    
    // The only address that can use functions with modifier _onlyBoss()
    address public boss;

    // Total supply of credits
    uint256 public totalSupply;

    // Price of single credit 
    uint256 public price;

    // List of CA users (user ID) and credit (int) which belongs to user
    mapping(string => uint256) public owners; 

    // Modifier - only 'boss' address can trigger functions marked with this modifier
    modifier onlyBoss() {
		require(boss == msg.sender, "Not a Boss");
		_;
	}

    struct User {
        string id;
        uint credits;
        bool verified;
    }

    User[] public users;

    event BossAddressAdded(
        address bossAddress,
        uint256 timestamp
    );

    event TotalSupplyCreated(
        uint256 supply,
        uint256 timestamp
    );

    event InitialPriceCreated(
        uint256 price,
        uint256 timestamp
    );

    event SupplyIncreased(
        uint256 increasedBy,
        uint256 totalSupply,
        uint256 timestamp
    );

    event SupplyDecreased(
        uint256 increasedBy,
        uint256 totalSupply,
        uint256 timestamp
    );

    event PriceChanged(
        uint256 newPrice,
        uint256 timestamp
    );

    event CreditIncreased(
        string user,
        uint256 amount,
        uint256 timestamp
    );

    event CreditDecreased(
        string user,
        uint256 amount,
        uint256 timestamp
    );

    // Constructor - only used on contract creation
    constructor(uint256 _totalSupply, uint256 _price){
        boss = msg.sender;
        totalSupply = _totalSupply;
        price = _price;
        emit BossAddressAdded(msg.sender, block.timestamp);
        emit TotalSupplyCreated(_totalSupply, block.timestamp);
        emit InitialPriceCreated(_price, block.timestamp);
    }

    // Supply and price changes
    function addSupply(uint256 _changeBy) public onlyBoss() {
     totalSupply += _changeBy;
     emit SupplyIncreased(_changeBy, totalSupply, block.timestamp);
    }

    function reduceSupply(uint256 _changeBy) public onlyBoss() {
     totalSupply -= _changeBy;
     emit SupplyDecreased(_changeBy, totalSupply, block.timestamp);
    }

    function changePrice(uint256 _newPrice) public onlyBoss() {
        price = _newPrice;
        emit PriceChanged(_newPrice, block.timestamp);
    }

    // Credit transfers
    function increaseUserCredit(string memory _user, uint256 _amount) public onlyBoss() {
       owners[_user] += _amount;
       emit CreditIncreased(_user, _amount, block.timestamp);
    }

    function descreaseUserCredit(string memory _user, uint256 _amount) public onlyBoss() {
       owners[_user] -= _amount;
       emit CreditDecreased(_user, _amount, block.timestamp);
    }

    function createUser(string memory _id, uint _credits, bool _verified) public onlyBoss() {
        User memory newUser = User({
            id: _id,
            credits: _credits,
            verified: _verified
        });
        users.push(newUser);
    }

    /*
        Possibly there could be more functions regarding gaining credit like - GIFTING CREDIT/REWARDS/EARNINGS etc.
    */   
}