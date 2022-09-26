/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

pragma solidity 0.8.17;

contract CallTest {
    function decimals() external view returns (uint) {
        return msg.data.length;
    }

    function data() external view returns (bytes calldata) {
        return msg.data;
    }
}