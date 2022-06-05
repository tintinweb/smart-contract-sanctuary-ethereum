/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity ^0.4.25;
contract Split {
    address public constant T1 = 0xdEdeB801186c27dBA36Ed389Bc7A940797c1cFf0; //MAIN
    address public constant T2 = 0xDe541f54334995f7178A5dFc21A34F2Ba8250ED8; //ACCOUNT 3
    address public constant T3 = 0x2C6bBA92df93F63077Ef71aa8b9d5AD6b0C13FF1; //ACCOUNT 5


    function () external payable {
        if (msg.value > 0) {
// msg.value - received ethers
            T1.transfer(msg.value * 50 / 100);
           
            T2.transfer(msg.value * 30 / 100);

            T3.transfer(msg.value * 20 / 100);
        }
    }
}