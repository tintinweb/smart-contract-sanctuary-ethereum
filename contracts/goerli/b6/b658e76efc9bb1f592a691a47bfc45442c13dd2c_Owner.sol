/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address public community = address(uint160(uint256(
            keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked("did-dao-community"))))
        )));

    address public infrastructure = address(uint160(uint256(
            keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked("did-dao-infrastructure"))))
        )));
    
    bytes32 c_node = keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked("did-dao-community"))));

    bytes32 i_node = keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked("did-dao-infrastructure"))));

    // Left Part staked for a duration, Right Part locked forever.
    function nodeToAddress(bytes32 node) public pure returns (address, address) {
        return (nodeLeftToAddress(node), nodeRightToAddress(node));
    }

    function nodeRightToAddress(bytes32 node) public pure returns (address) {
        address account = address(uint160(uint256(node)));
        return account;
    }

    function nodeLeftToAddress(bytes32 node) public pure returns (address) { 
        address account = address(uint160(uint256(node) >> 96));
        return account;
    }

}