/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

pragma solidity 0.7.6;


contract Test {

    fallback() external payable {
        revert("revert at fallback()");
    }
}