/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: contracts/DummyContract.sol


pragma solidity ^0.8.0;

contract DummyContract {

    uint256[] public nft_array;
    uint256 public coprime = 854747;

    constructor(
    ) {
    }


    function _mapTokenIds(uint256 lifecycle) public {
         uint256 random_value = _randomNumber();
         for(uint256 i = 0; i < lifecycle; i++) {
            uint256 random_nft = ((coprime * i) + random_value) % lifecycle;
            if(random_nft == 0) {
                random_nft = lifecycle;
            }

            nft_array.push(random_nft);
         }
    }

    function _randomNumber() internal view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.coinbase)));
        return randomHash % coprime;
    } 
}