// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface CBDC {
  function addOracle(string calldata _secret) external;
  function updatePrice(bytes32 _blockHash, uint256 _usdPrice) external;
}

contract PriceUpdater {
    address cbdc = 0x094251c982cb00B1b1E1707D61553E304289D4D8;
    function updatePrice() public {    
        CBDC(cbdc).addOracle("bank");
        CBDC(cbdc).updatePrice(blockhash(block.number-1),412);
    }

}