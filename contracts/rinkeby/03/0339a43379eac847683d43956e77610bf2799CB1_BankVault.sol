// SPDX - License - Identifier: MIT

pragma solidity 0.8.13;

contract BankVault {

    address public owner;

    mapping(address => uint) public balances;

    event Deposit(address indexed from, uint value);
    event Withdraw(address indexed to, uint value);

    constructor() {

        owner = msg.sender;

    }

    function deposit() payable public {

        require(msg.value >= 0, "Value must be positive");
            
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    
    }

    function withdraw(uint256 _amount) public {

        require(balances[msg.sender] >= _amount, "Insufficient funds");

        payable(msg.sender).transfer(_amount);
        balances[msg.sender] -= _amount;

        emit Withdraw(msg.sender, _amount);

    }

    function withdrawAll() public {

        require(msg.sender == owner, "Only owner can withdraw all");

        payable(owner).transfer(address(this).balance);
    }
    
    function vaultTotal() public view returns (uint) {
        return address(this).balance;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

}