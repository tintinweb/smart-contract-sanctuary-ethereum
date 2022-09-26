/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

pragma solidity 0.8.17;

contract CallTest {
    function callArray(uint[] calldata args) external view returns (uint) {
        return msg.data.length;
    }

    function callBytes(bytes calldata args) external view returns (bytes calldata) {
        return msg.data;
    }
}