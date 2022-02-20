/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

pragma solidity >=0.7.0 <0.9.0;

contract test {


    function timestampAfter(uint expiryBlockNumber) public returns (bool) {
        // return block.number;
        return bool(expiryBlockNumber < block.number);
    }
}