// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract basic {
    uint256 public num = 5;

    function setter(uint256 num1) public {
        num = num1;
    }

    function receive_money() public payable {}

    function send_money(uint256 money) public {
        payable(msg.sender).transfer(money);
    }

    function know_balance() public view returns (uint256 bal) {
        return address(this).balance;
    }
}