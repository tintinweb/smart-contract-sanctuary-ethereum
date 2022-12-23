// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

struct Content {
    uint256 contentId;
    string ipfsHash;
    address notary;
}

contract Notarizer is Ownable {
    // State Variables
    mapping(address => bool) public whitelistedNotaries;
    mapping(uint256 => Content) public contents;
    mapping(string => bool) public notarizedHashes;
    uint public batchId = 0;
    // Events
    event WhitelistedNotary(address indexed _notary);

    event Notarize(
        address indexed _notary,
        string indexed _ipfsHash,
        string indexed _tag
    );

    event e_notarizeBatch(
        address indexed _notary,
        uint indexed _batchHashId,
        string indexed _tag
    );

    // Modifiers
    modifier onlyWhitelistedNotaries() {
        require(whitelistedNotaries[msg.sender], "Unauthorized");
        _;
    }
    modifier onlyValidHashed(string memory s) {
        bytes memory b = bytes(s);
        require(b.length == 46, "This is not an accepted IpfsHash");
        require(
            (b[0] == "Q" && b[1] == "m"),
            "Invalid IpfsHash, must be a CIDv0"
        );
        _;
    }

    // Functions
    function whitelistNotary(address _appAddress) external onlyOwner {
        whitelistedNotaries[_appAddress] = true;
        emit WhitelistedNotary(_appAddress);
    }

    function notarizeCID(
        uint _contentId,
        string memory _ipfsHash,
        string memory _tag
    ) public onlyWhitelistedNotaries onlyValidHashed(_ipfsHash) {
        // Notarization logic
        require(notarizedHashes[_ipfsHash] == false, "Already notarized");
        Content memory content;
        content.contentId = _contentId;
        content.ipfsHash = _ipfsHash;
        content.notary = msg.sender;

        contents[_contentId] = content;
        notarizedHashes[_ipfsHash] = true;

        emit Notarize(msg.sender, _ipfsHash, _tag);
    }

    function notarizeBatch(
        string[] memory hashBatch,
        uint[] memory contentIds,
        string memory _tag
    ) public onlyWhitelistedNotaries {
        for (uint8 i = 0; i < (hashBatch.length); i++) {
            notarizeCID(contentIds[i], hashBatch[i], _tag);
        }
        batchId++;
        emit e_notarizeBatch(msg.sender, batchId, _tag);
    }

    function getIpfsHash(uint _contentId) public view returns (string memory) {
        Content memory content;
        content = contents[_contentId];
        string memory ipfsHash = content.ipfsHash;
        return ipfsHash;
    }

    function isHashNotarized(
        string memory _ipfsHash
    ) public view onlyValidHashed(_ipfsHash) returns (bool) {
        return notarizedHashes[_ipfsHash];
    }
}