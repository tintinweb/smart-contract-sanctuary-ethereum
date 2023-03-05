/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

pragma solidity 0.8.17;

contract IVS {
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
        return bytes4(0x1626ba7e);
    }
}