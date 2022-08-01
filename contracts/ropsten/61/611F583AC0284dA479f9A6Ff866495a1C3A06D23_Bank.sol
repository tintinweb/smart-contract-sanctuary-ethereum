// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


contract Bank{
    address private owner;
    uint8 private clientCount;
    bool private isClosed;
    mapping (address => uint) private balances;

    constructor () payable {
        require(msg.value == 5 ether, "5 ether initial funding required");
        owner = msg.sender;
        clientCount = 0;
        isClosed = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of this contract can call this function.");
        _;
    }

    modifier checkIfAccountExists(address sender){
        require(balances[sender] == 0, "Account already created");
        _;
    }

    function openAccount() public payable checkIfAccountExists(msg.sender) {
        require(isClosed != true, "bank is closed");
        require(msg.value != 0 ether, "ether initial amount required");
        if(clientCount < 6){
            clientCount++;
            balances[msg.sender] += 1 ether;
        }
        balances[msg.sender] += msg.value;
    }

    function getTotalClients() external view returns(uint){
        return clientCount;
    }

    function checkBalance() view  external onlyOwner() returns(uint){
        return address(this).balance;
    }

    function checkMyBalance() public view returns(uint){
        require(isClosed != true, "bank is closed");
        return balances[msg.sender];
    }


    function deposit(address _address) public payable checkIfAccountExists(_address){
        require(isClosed != true, "bank is closed");
        balances[_address] += msg.value;
    }

    function withdraw(uint withdrawAmount) public {
        require(isClosed != true, "bank is closed");
        // require(balances[msg.sender] == msg.sender, "Only account holder can withdraw from this account");
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            payable(msg.sender).transfer(withdrawAmount);
        }
    }

    function closeBank() public onlyOwner() returns(string memory message){
        if(isClosed == false){
            isClosed = true;
            message = "bank is closed";
            return message;
        }
    }

    function openBank() public onlyOwner() returns(string memory message){
        if(isClosed == true){
            isClosed = false;
            message = "bank is opened";
            return message;
        }
    }

    function closeMyAccount() public payable {
        require(isClosed != true, "bank is closed");
        if (balances[msg.sender] != 0) {
            payable(msg.sender).transfer(balances[msg.sender]);
            balances[msg.sender] -= balances[msg.sender];
        }
    }

    function demolishBank() public onlyOwner {
        selfdestruct(payable(owner));
    }

}