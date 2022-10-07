// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {

    /**
 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;

}

contract DemonsPortal is Ownable {
    event SendThroughPortalEvent(address from, uint demonId, uint buernedHellId, uint keyId);


    // Contracts
    IERC721 private hell;
    IERC721 private keys;

    // Hells ducks that were turned into demons
    mapping(uint256 => bool) private _demonIds;


    // Burner address
    address private _burnerAddress = 0x000000000000000000000000000000000000dEaD;

    bool private _isPortalActive = false;


    constructor(address hellAddress, address keyAddress) {
        hell = IERC721(hellAddress);
        keys = IERC721(keyAddress);
    }

    function sendThroughPortal(uint256 demonId, uint256 hellId, uint256 keyId) public {
        require(_isPortalActive, "Portal is not active.");

        require(demonId != hellId, "The tokens must be different");
        require(hell.ownerOf(demonId) == msg.sender, "You must own the requested Demon token.");
        require(hell.ownerOf(hellId) == msg.sender, "You must own the requested Hell token.");
        require(keys.ownerOf(keyId) == msg.sender, "You must own the requested Key token.");

        require(!_demonIds[demonId], "Hell duck was already transformed into a demon");

        // Burn Tokens
        hell.safeTransferFrom(msg.sender, _burnerAddress, hellId);
        keys.burn(keyId);

        // Mark the 2 Gen as used
        _demonIds[demonId] = true;

        emit SendThroughPortalEvent(msg.sender, demonId, hellId, keyId);
    }

    function flipPortalState() public onlyOwner {
        _isPortalActive = !_isPortalActive;
    }

    function setBurnerAddress(address newBurnerAddress) public onlyOwner {
        _burnerAddress = newBurnerAddress;
    }

    function burnerAddress() public view returns (address) {
        return _burnerAddress;
    }

    function isDemon(uint256 demonId) public view returns (bool) {
        return _demonIds[demonId];
    }

    function isPortalActive() public view returns (bool) {
        return _isPortalActive;
    }

    function setDemonIds(uint256[] memory demonIds) onlyOwner public {
        for(uint256 i = 0; i< demonIds.length; i++) {
            _demonIds[demonIds[i]] = true;
        }
    }

    function removeDemonIds(uint256[] memory demonIds) onlyOwner public {
        for(uint256 i = 0; i<demonIds.length; i++) {
            _demonIds[demonIds[i]] = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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