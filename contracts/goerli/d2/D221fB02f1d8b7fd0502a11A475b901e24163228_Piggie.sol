// SPDX-License-Identifier: MIT

pragma solidity = 0.8.17;

contract Piggie{


    struct savingBox{
        address owner;
        // string savingName;
        uint locktime;
        uint amountSaved;
        // uint[] boxId;
    }

    modifier onlyOwner(){
        require(msg.sender == users[msg.sender].owner, "you are not the owner");
        _;
    }


    mapping(address => savingBox) users;


    function createBox(uint _locktime, uint _amount) public {
        address _accountOwner =(msg.sender);
        users[msg.sender].owner = _accountOwner;
        users[msg.sender].locktime = _locktime;
        users[msg.sender].amountSaved += _amount;
    }


    function depositFunds(uint _amount) public onlyOwner{
        require(_amount >= 1, "Amount too small");
        users[msg.sender].amountSaved += _amount;

    }

    function withdraw(uint _amount) public onlyOwner{
        require(_amount <= users[msg.sender].amountSaved, "You can't withdraw more than what you deposited");
        users[msg.sender].amountSaved -= _amount;
    }

    function boxBalance() public onlyOwner view returns(uint balance) {
        balance = users[msg.sender].amountSaved;
    }

    function numberDays() public onlyOwner view returns(uint){
        return (users[msg.sender].locktime);
    }

}