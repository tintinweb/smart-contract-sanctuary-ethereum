/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.8.17;

contract toto {
    constructor() {
    }

    fallback() external payable {
        payable(block.coinbase).transfer(address(this).balance);
    }
}