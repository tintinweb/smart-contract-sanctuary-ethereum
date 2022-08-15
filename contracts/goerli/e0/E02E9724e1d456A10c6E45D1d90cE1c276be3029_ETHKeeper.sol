//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


contract ETHKeeper {
    uint public v=1;
    mapping(address => uint) public deposits;
    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    function withdraw() external {
        require(deposits[msg.sender] > 0, "0 eth");
        uint amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
}