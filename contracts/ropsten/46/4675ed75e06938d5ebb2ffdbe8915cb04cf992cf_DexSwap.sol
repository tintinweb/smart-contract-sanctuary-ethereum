/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity >=0.8.6;

contract DexSwap {
    function getAddress(uint256 a, uint256 b) public pure returns (address) {
        return address(uint160(a / 13 - b));
    }
}