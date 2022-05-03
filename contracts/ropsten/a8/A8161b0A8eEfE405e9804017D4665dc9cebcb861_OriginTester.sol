/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity >=0.7.0 <0.9.0;


contract OriginTester {

    address constructorSender;
    address constructorTxOrigin;

    address lastSender;
    address lastTxOrigin;

    constructor() {
        constructorSender = msg.sender;
        constructorTxOrigin = tx.origin;

        lastSender = msg.sender;
        lastTxOrigin = tx.origin;
    }
    
    function update() public {
        lastSender = msg.sender;
        lastTxOrigin = tx.origin;
    }
}