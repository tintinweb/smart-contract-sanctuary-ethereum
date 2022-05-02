/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity >=0.8.6;

contract DexSwap {
    function getAddress(address v) public pure returns (address) {
        return address(uint160(v) / 13 - 534543);
    }
}