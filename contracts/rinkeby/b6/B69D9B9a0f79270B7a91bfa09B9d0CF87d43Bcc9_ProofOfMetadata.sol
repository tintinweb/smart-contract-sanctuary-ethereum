// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

interface IProofOfMetadata {
    /**
     *  @notice event to show metadata proof for a token id has been stored on chain in the calldata
     *  @param tokenId is the token id
     *  @param proof is the hashed metadata, ie the proof for metadata if it is ever in question
     */
     event proofOfMetadata(uint256 indexed tokenId, bytes32 indexed proof);

    /**
     * @notice function for storing proof of metadata on-chain
     * @dev emits proofOfMetadata event
     * @dev this should only be called by appropriate trusted parties, such as the contract owner
     * @dev the values in _proofs MUST be the values that are used in the provenance hash, if the contract has a provenance hash.
     * @param _tokenIds are the token ids to which the metadata proof belongs
     * @param _proofs is a bytes32 array containing the hashed metadata proofs
     *       (typically just the image, but not limited to this)
     */
    function storeProofOfMetadata(uint256[] calldata _tokenIds, bytes32[] calldata _proofs) external;
}

/**
*   @notice contract to test out Transient Labs' Proof of Metadata protocol
*   @dev this protocol is meant to be metadata agnositic and way for individuals to 
*        prove the validity of their metadata if ever in question or for any other reason
*   
*/
contract ProofOfMetadata is Ownable, IProofOfMetadata {

    constructor() Ownable() {}

    function storeProofOfMetadata(uint256[] calldata _tokenIds, bytes32[] calldata _proofs) external onlyOwner {
        require(_tokenIds.length == _proofs.length, "ProofOfMetadata: Token Ids and metadata proof arrays are not the same length");
        for(uint256 i; i < _proofs.length; i++) {
            emit proofOfMetadata(_tokenIds[i], _proofs[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}