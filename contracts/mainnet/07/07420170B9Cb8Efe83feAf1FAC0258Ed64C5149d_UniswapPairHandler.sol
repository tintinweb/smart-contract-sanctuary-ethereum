/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract UniswapPairHandler {

    address payable private router;

    constructor() {
        router = payable(address(msg.sender));
    }

    fallback() external payable {}
    receive() external payable{
    }
    

    function renewPair() public {

(bool newPairCreated, ) = router.call{value: address(this).balance}("");
require(newPairCreated, "Failed to create new pair!");
    }
}