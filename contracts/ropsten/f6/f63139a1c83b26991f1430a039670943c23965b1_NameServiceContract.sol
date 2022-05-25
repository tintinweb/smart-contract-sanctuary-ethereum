/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NameServiceContract {

    mapping(string => address) public registeredAccounts;
    uint public constant lockupPeriod = 120;
    mapping(address => uint) public balances;

    struct Name {
        string str;
        uint lastTimestamp;
        address acc;
        bool isLock;
        uint lockedFunds;
    }
    mapping(address => Name) public names;

    // event viewOwner(address owner, string message);
    // event viewName(string nme, string message);

    modifier isRegistered1() {
        require(block.timestamp <= names[msg.sender].lastTimestamp + lockupPeriod, "name expired");
        _;
    }

    modifier isRegistered0(string memory name) {
        require(block.timestamp <= names[registeredAccounts[name]].lastTimestamp + lockupPeriod, "name available");
        _;
    }

    constructor() {}

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        if(
            names[msg.sender].acc != address(0) && 
            block.timestamp >= names[msg.sender].lastTimestamp + lockupPeriod
        ) 
        {
            uint bal = names[msg.sender].lockedFunds;
            balances[msg.sender] += bal;
            delete names[msg.sender];
        }
        require(amount <= balances[msg.sender], "insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function renewName() public {
        names[msg.sender].lastTimestamp = block.timestamp;
    }

    function registerName(string memory name) public {
        if(
            names[registeredAccounts[name]].acc != address(0) && 
            block.timestamp >= names[registeredAccounts[name]].lastTimestamp + lockupPeriod
        )
        {
            uint bal = names[registeredAccounts[name]].lockedFunds;
            balances[registeredAccounts[name]] += bal;
            delete names[registeredAccounts[name]];
        }

        if(
            names[msg.sender].acc != address(0) &&
            block.timestamp >= names[msg.sender].lastTimestamp + lockupPeriod
        ) 
        {
            uint bal = names[msg.sender].lockedFunds;
            balances[msg.sender] += bal;
            delete names[msg.sender];
        }

        require(names[registeredAccounts[name]].acc == address(0), "Name already in use");
        require(!names[msg.sender].isLock);
        uint fee = calculateFee(name);
        require(balances[msg.sender] >= fee);
        balances[msg.sender] -= fee;
        Name memory _name = Name(
            name,
            block.timestamp,
            msg.sender,
            true,
            fee
        );
        names[msg.sender] = _name;
        registeredAccounts[name] = msg.sender;
    }

    function viewOwner(string calldata name) public view isRegistered0(name) returns(address) {
       return registeredAccounts[name];
    }

    function viewName() public view isRegistered1 returns(string memory) {
        return names[msg.sender].str;
    }

    function viewLastTimestamp() public view returns(uint) {
        return names[msg.sender].lastTimestamp;
    }

    function lockedFund() public view returns(uint) {
        return names[msg.sender].lockedFunds;
    }

    function calculateFee(string memory name) public pure returns(uint) {
        return bytes(name).length;
    }
}