//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";

/**
 * @title OracleContract
 * @dev Store & retrieve merkle root hash in a variable
 */
contract OracleContract is OracleInterface {
    mapping(address => bytes32) public merkleRoots;

    /**
     * @dev Store merkle root hash of brand in variable
     * @param _brand address of brand
     * @param _merkleRoot root hash of all claimable amounts of the brands
     */
    function setMerkleroot(address _brand, bytes32 _merkleRoot)
        public
        override
        returns (bool)
    {
        merkleRoots[_brand] = _merkleRoot;
        emit SetMerkleroot(_brand, _merkleRoot);
        return true;
    }

    /**
     * @dev  merkle root hash of brand in variable
     * @param _brand address of brand
     * @return brand root hash
     */
    function getMerkleroot(address _brand)
        public
        view
        override
        returns (bytes32)
    {
        return merkleRoots[_brand];
    }
}