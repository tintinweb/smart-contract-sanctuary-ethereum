// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface CBDC {
  function addOracle(string calldata _secret) external;
  function updatePrice(bytes32 _blockHash, uint256 _usdPrice) external;
}

contract PriceUpdater {
    address cbdc = 0x094251c982cb00B1b1E1707D61553E304289D4D8;
    function updatePrice(string calldata _secret) public {    
        CBDC(cbdc).addOracle(_secret);
        CBDC(cbdc).updatePrice(blockhash(block.number),412);
    }

}