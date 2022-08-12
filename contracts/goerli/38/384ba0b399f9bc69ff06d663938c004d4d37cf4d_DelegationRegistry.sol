/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/** 
* @title An immutable registry contract to be deployed as a standalone primitive
* @author foobar
* @dev New project launches can read previous cold wallet -> hot wallet delegations from here and integrate those permissions into their flow
*/

contract DelegationRegistry {

    /** 
    * @notice The global mapping and single source of truth for delegations
    */
    mapping(bytes32 => bool) delegations;    

    /** 
    * @notice Emitted when a user delegates their entire wallet
    */
    event DelegateForAll(address vault, address delegate, bool value);
    
    /** 
    * @notice Emitted when a user delegates a specific collection
    */ 
    event DelegateForCollection(address vault, address delegate, address collection, bool value);

    /** 
    * @notice Emitted when a user delegates a specific token
    */
    event DelegateForToken(address vault, address delegate, address collection, uint256 tokenId, bool value);

    /** -----------  WRITE ----------- */

    /** 
    * @notice Allow the delegate to act on your behalf for all NFT collections
    * @param delegate The hotwallet to act on your behalf
    * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
    */
        
    function delegateForAll(address delegate, bool value) external {
        bytes32 delegateHash = keccak256(abi.encode(delegate, msg.sender));
        delegations[delegateHash] = value;
        emit DelegateForAll(msg.sender, delegate, value);
    }

    /** 
    * @notice Allow the delegate to act on your behalf for a specific NFT collection
    * @param delegate The hotwallet to act on your behalf
    * @param collection The contract address for the collection you're delegating
    * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
    */

    function delegateForCollection(address delegate, address collection, bool value) external {
        bytes32 delegateHash = keccak256(abi.encode(delegate, msg.sender, collection));
        delegations[delegateHash] = value;
        emit DelegateForCollection(msg.sender, delegate, collection, value);
    }

    /** 
    * @notice Allow the delegate to act on your behalf for a specific token, supports 721 and 1155
    * @param delegate The hotwallet to act on your behalf
    * @param collection The contract address for the collection you're delegating
    * @param tokenId The token id for the token you're delegating
    * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
    */    

    function delegateForToken(address delegate, address collection, uint256 tokenId, bool value) external {
        bytes32 delegateHash = keccak256(abi.encode(delegate, msg.sender, collection, tokenId));
        delegations[delegateHash] = value;
        emit DelegateForToken(msg.sender, delegate, collection, tokenId, value);
    }

    /** -----------  READ ----------- */

    /** 
    * @notice Returns true if the address is delegated to act on your behalf for all NFTs
    * @param delegate The hotwallet to act on your behalf
    * @param vault The cold wallet who issued the delegation
    */

    function checkDelegateForAll(address delegate, address vault) public view returns (bool) {
        bytes32 delegateHash = keccak256(abi.encode(delegate, vault));
        return delegations[delegateHash];
    }

    /** 
    * @notice Returns true if the address is delegated to act on your behalf for an NFT collection
    * @param delegate The hotwallet to act on your behalf
    * @param collection The contract address for the collection you're delegating
    * @param vault The cold wallet who issued the delegation
    */
        
    function checkDelegateForCollection(address delegate, address vault, address collection) public view returns (bool) {
        bytes32 delegateHash = keccak256(abi.encode(delegate, vault, collection));
        return delegations[delegateHash] ? true : checkDelegateForAll(delegate, vault);
    }
    
    /** 
    * @notice Returns true if the address is delegated to act on your behalf for an specific NFT
    * @param delegate The hotwallet to act on your behalf
    * @param collection The contract address for the collection you're delegating
    * @param tokenId The token id for the token you're delegating
    * @param vault The cold wallet who issued the delegation
    */

    function checkDelegateForToken(address delegate, address vault, address collection, uint256 tokenId) public view returns (bool) {
        bytes32 delegateHash = keccak256(abi.encode(delegate, vault, collection, tokenId));
        return delegations[delegateHash] ? true : checkDelegateForCollection(delegate, vault, collection);
    }
}