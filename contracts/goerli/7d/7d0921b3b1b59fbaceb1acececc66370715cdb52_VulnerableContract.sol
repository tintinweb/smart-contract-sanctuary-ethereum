// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16;

contract VulnerableContract {
    mapping(address => uint256) public balances;
    uint256 public constant PRICE = 0.01 ether;

    function deposit() external payable {
        require(msg.value == PRICE, "wrong value");
        balances[msg.sender] = msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];

        if (amount > 0) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "not successful");
        }

        balances[msg.sender] = 0;
    }
}