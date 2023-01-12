// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Casino {

    uint256 private immutable number;
    constructor (uint256 _number) payable {
        number = _number;
    }

    function guess(uint my_number) public payable {
        require(msg.value >= 0.001 ether, "you need to pay 0.1 eth to guess");

        if (number % 100 == my_number % 100) {
            uint256 balance = address(this).balance;
            address payable caller_address = payable(address(msg.sender));
            caller_address.transfer(balance);
        }
    }
}