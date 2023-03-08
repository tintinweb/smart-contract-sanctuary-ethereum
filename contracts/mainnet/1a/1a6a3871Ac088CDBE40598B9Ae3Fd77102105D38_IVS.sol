/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

pragma solidity 0.8.17;

contract IVS {
    mapping(bytes32 => bool) public validSignatures;
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
        return bytes4(validSignatures[_hash] ? 0x1626ba7e : 0xffffffff);
    }

    function setValidSignature(bytes32 _hash) external {
        validSignatures[_hash] = true;
    }
}