pragma solidity 0.8.9;

contract MonobundleDeposit {

    struct Account {
        string name;
        uint256 balance;
    }

    mapping(address => Account) public accounts;

    event AccountCreated(address userAddress, string name, uint256 balance);
    
    constructor() {}

    function openAccount(string calldata _newName) external payable {
        Account storage account = accounts[msg.sender];
        require(bytes(account.name).length == 0, "ACCOUNT EXISTS");

        account.name = _newName;
        account.balance = msg.value;

        emit AccountCreated(msg.sender, _newName, msg.value);
    }
}