// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.17;

contract Account {

    struct usersAccounts{
        address owner;
        string Boxname;
        uint amountSaved;

    }

    mapping(address => usersAccounts) users;

    modifier onlyOwner(){
        require(msg.sender == users[msg.sender].owner, "you are not the owner");
        _;
    }


    function createBox(string memory _savingName) public {
        address _accountOwner = msg.sender;

        users[msg.sender].owner = _accountOwner;
        users[msg.sender].Boxname = _savingName;
    }

        function depostiFunds(uint _amount) public onlyOwner{
        require(_amount >= 1, "Amount too small"); // checks if value to save is upto 1 ether
        users[msg.sender].amountSaved += _amount;

    }

    function withdraw(uint _amount) external onlyOwner {
        require(_amount <= users[msg.sender].amountSaved, "You can't withdraw more than what you deposited");
        users[msg.sender].amountSaved -= _amount;
    }

    function boxBalance() external onlyOwner  view returns(uint) {
        return (users[msg.sender].amountSaved);
    }


}