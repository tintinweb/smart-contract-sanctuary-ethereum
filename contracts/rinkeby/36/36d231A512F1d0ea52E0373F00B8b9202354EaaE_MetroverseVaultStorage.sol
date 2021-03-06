// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../../lib/Controllable.sol";
import "./structs/MetroVaultStructs.sol";
import "./interfaces/IMetroVaultStorage.sol";
import "../../nfts/interfaces/IMetroNFTRouter.sol";

contract MetroverseVaultStorage is Controllable, IERC721Receiver {

    uint256 public totalStaked;

    address nftRouterAddress;
    
    mapping(uint256 => Stake) vault;

    event BlockStaked(address owner, uint256 tokenId, uint256 timestamp, uint16 cityId, uint32 extra);

    event BlockRestaked(address owner, uint256 tokenId, uint256 timestamp, uint16 cityId, uint32 extra);

    event BlockUnstaked(address owner, uint256 tokenId, uint256 timestamp, uint16 cityId, uint32 extra);

    constructor(address _nftRouterAddress) {
      nftRouterAddress = _nftRouterAddress;
    }

    function getStake(uint256 tokenId) external view returns (Stake memory) {
        return vault[tokenId];
    }

    function setStake(uint256 tokenId, Stake calldata newStake) external onlyController {
        require(newStake.owner != address(0), "Owner cannot be nil");
        vault[tokenId] = newStake;
        emit BlockRestaked(newStake.owner, tokenId, newStake.timestamp, newStake.cityId, newStake.extra);
    }

    function deleteStake(uint256 tokenId) external onlyController {
        Stake memory staked = vault[tokenId];
        delete vault[tokenId];
        emit BlockUnstaked(staked.owner, tokenId, staked.timestamp, staked.cityId, staked.extra);
    }

    function setNFTRouter(address _nftRouterAddress) external onlyController {
        nftRouterAddress = _nftRouterAddress;
    }

    function getNFTContractAddress(uint256 tokenId) public view returns (address) {
        return IMetroNFTRouter(nftRouterAddress).getNFTContractAddress(tokenId);
    }

    function stakeUnsafe(address owner, uint256[] calldata tokenIds, uint16 cityId, uint32 extra) external onlyController {
        totalStaked += tokenIds.length;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(vault[tokenId].owner == address(0), "Token is already staked");

            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            if (nft.ownerOf(tokenId) != address(this)) {
                require(nft.ownerOf(tokenId) == owner, "not your token");
                nft.transferFrom(owner, address(this), tokenId);
            }

            vault[tokenId] = Stake({
                owner: owner,
                timestamp: uint48(block.timestamp),
                cityId: cityId,
                extra: extra
            });

            emit BlockStaked(owner, tokenId, block.timestamp, cityId, extra);
        }
    }

    function unstakeUnsafe(address owner, uint256[] calldata tokenIds) external onlyController {
        totalStaked -= tokenIds.length;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];      
            Stake memory staked = vault[tokenId];
            require(owner == staked.owner, "Not an owner");

            delete vault[tokenId];
            IERC721 nft = IERC721(getNFTContractAddress(tokenId));
            nft.transferFrom(address(this), staked.owner, tokenId);
            emit BlockUnstaked(staked.owner, tokenId, block.timestamp, staked.cityId, staked.extra);
        }
    }

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Controllable is Ownable {

    mapping(address => bool) private controllers;

    function addController(address controller) external onlyOwner {
      controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
      controllers[controller] = false;
    }

    function isController(address account) public view returns (bool) {
        return controllers[account];
    }

    modifier onlyController() {
        require(controllers[_msgSender()], "Controllable: caller is not the controller");
        _;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

struct City {
    uint16 id;
    uint16 totalScore;
    uint8 totalBlocks;
    uint8 totalCitizens;
    string name;
    uint32 flags;
    // uint128 checksum; // Hash of all block ids sorted in ascending order
}

struct Citizen {
    uint16 totalScore;
    uint8 totalBlocks;
    // uint128 checksum; // Hash of all block ids sorted in ascending order
}

struct Player {
    uint16 totalOwned;
    uint16 totalStaked;
    uint16 totalCities;
    mapping(uint16 => Citizen) citizenships;
}

struct Stake {
    address owner;
    uint48 timestamp;
    uint16 cityId;
    uint32 extra;
}

// SPDX-License-Identifier: MIT LICENSE

import "../structs/MetroVaultStructs.sol";
import "../../../nfts/interfaces/IMetroNFTRouter.sol";


pragma solidity 0.8.12;


interface IMetroVaultStorage is IMetroNFTRouter {

    function getStake(uint256 tokenId) external view returns (Stake memory);
    function setStake(uint256 tokenId, Stake calldata newStake) external;
    function deleteStake(uint256 tokenId)external;
    
    function stakeUnsafe(address owner, uint256[] calldata tokenIds, uint16 cityId, uint32 extra) external;
    function unstakeUnsafe(address owner, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

interface IMetroNFTRouter {

    function getNFTContractAddress(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}