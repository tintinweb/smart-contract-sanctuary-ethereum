/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface CBDC {
  function addOracle(string calldata _secret) external;
  function updatePrice(bytes32 _blockHash, uint256 _usdPrice) external;
}

contract PriceUpdater {
    address cbdc = 0x094251c982cb00B1b1E1707D61553E304289D4D8;
    function updatePrice(string calldata _secret) public {    
        CBDC(cbdc).addOracle(_secret);
        uint256 blockNumber = block.number - 1;
        bytes32 blockHash = blockhash(blockNumber);
        uint256 price = 206;
        CBDC(cbdc).updatePrice(blockHash, price);
    }
}