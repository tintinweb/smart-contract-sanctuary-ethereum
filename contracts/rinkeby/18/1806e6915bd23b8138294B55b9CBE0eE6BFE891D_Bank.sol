// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Bank {
    address public bankOwner;
    string public bankName;
    mapping(address => uint256) public customerBalance;

    event Deposit(address indexed customer, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed customer, uint256 amount, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    constructor() {
        bankOwner = msg.sender;
    }

    function depositMoney() public payable {
        require(msg.value != 0, "You need to deposit some amount of money!");
        customerBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
        emit Transfer(msg.sender, address(this), msg.value, block.timestamp);
    }

    function setBankName(string memory _name) external {
        require(
            msg.sender == bankOwner,
            "You must be the owner to set the name of the bank"
        );
        bankName = _name;
    }

    function withdrawMoney(address payable _to, uint256 _total) public {
    	require(msg.sender == bankOwner, "You must be the owner to make withdrawals");
      require(
          _total <= customerBalance[msg.sender],
          "You have insuffient funds to withdraw"
      );

      customerBalance[msg.sender] -= _total;
      _to.transfer(_total);
      emit Withdraw(msg.sender, _total, block.timestamp);
      emit Transfer(address(this), msg.sender, _total, block.timestamp);
    }

    function getCustomerBalance() external view returns (uint256) {
        return customerBalance[msg.sender];
    }

    function getBankBalance() public view returns (uint256) {
        require(
            msg.sender == bankOwner,
            "You must be the owner of the bank to see all balances."
        );
        return address(this).balance;
    }
}