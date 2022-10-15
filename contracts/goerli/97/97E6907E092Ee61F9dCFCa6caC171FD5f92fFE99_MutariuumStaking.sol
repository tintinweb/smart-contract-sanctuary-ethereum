// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "./interfaces/IMuutariumStaking.sol";

contract MutariuumStaking is IMuutariumStaking, Ownable {

    uint256 private constant _BITMASK_NUMBER_STAKED = (1 << 64) - 1;
    uint256 private constant _BITPOS_CAN_STAKE = 1 << 64;
    uint256 private constant _BITPOS_CAN_UNSTAKE = 1 << 65;
    uint256 private constant _BITMASK_STAKING_STATUS = 3 << 64;

    /**
     * @dev Mapping from nft address to
     *      - mapping from tokenId to packed staking infos
     * packed staking info
     * Bits Layout:
     * - [0..159]     Address of the original owner of the NFT
     * - [160..255]   Timestamp of the staking
     */
    mapping(address => mapping(uint256 => uint256)) _packedStakingInfos;

    /**
     * @dev Mapping from nft address to packed contract infos
     * Bits Layout:
     * - [0..63]    Number of NFTs currently staked
     * - [64..65]   Staking status (INACTIVE, ACTIVE, PAUSED, LOCKED)
     */
    mapping(address => uint256) _packedContractInfos;

    /** Public Views */

    /**
     * @notice get the current owner and time when the stake started of an NFT
     * @return StakingInfos
     */
    function stakingInfos(address nft, uint256 tokenId) external view returns(StakingInfos memory) {
        (address owner, uint256 stakedAt) = _unpackStakingInfos(_packedStakingInfos[nft][tokenId]);
        return StakingInfos({
            owner: owner,
            stakedAt: stakedAt
        });
    }

    /**
     * @notice Get the number of NFTs currently staked and the current staking status of an NFT collection
     * @param nft The address of the collection
     * @return CollectionInfos
     */
    function collectionInfos(address nft) external view returns(CollectionInfos memory) {
        (StakingStatus status, uint256 numberStaked) = _unpackContractInfos(_packedContractInfos[nft]);
        return CollectionInfos({
            numberStaked: numberStaked,
            status: status
        });
    }

    /** Public function calls */

    /**
     * @notice Stake a list of nfts from a specific collection
     * @param nft The address of the collection
     * @param tokenIds the list of nfts from that collection
     *
     * - The status of the collection needs to be ACTIVE
     * - The staking contract must be approved on that collection for this sender
     */
    function stake(address nft, uint256[] calldata tokenIds) external {
        require(
            _canStake(nft),
            "Staking is not active on this collection"
        );
        require(
            IERC721(nft).isApprovedForAll(msg.sender, address(this)),
            "Missing approval for this collection"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(nft).ownerOf(tokenIds[i]) == msg.sender,
                string(abi.encodePacked(
                    "You don't own token #",
                    Strings.toString(tokenIds[i]),
                    " from the contract ",
                    Strings.toHexString(uint256(uint160(nft)), 20)
                ))
            );
            IERC721(nft).transferFrom(msg.sender, address(this), tokenIds[i]);
            _packedStakingInfos[nft][tokenIds[i]] = _packStakingInfos(msg.sender, block.timestamp);
            _packedContractInfos[nft]++;
            emit Stake(nft, msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice Unstake a list of nfts from a specific collection
     *
     * @param nft The address of the collection
     * @param tokenIds the list of nfts from that collection
     *
     * - The nft must have been been staked by the caller
     */
    function unstake(address nft, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (address owner, ) = _unpackStakingInfos(_packedStakingInfos[nft][tokenIds[i]]);
            require(owner == msg.sender, "You didn't stake this token");
            _packedContractInfos[nft]--;
            IERC721(nft).transferFrom(address(this), owner, tokenIds[i]);
            delete _packedStakingInfos[nft][tokenIds[i]];
            emit Unstake(nft, msg.sender, tokenIds[i]);
        }
    }

    /** Admin functions calls */

    /**
     * @notice Enable or disable staking or unstaking for a specific collection
     *
     * @param nft The address of the collection
     * @param canStake If staking should be enabled or disabled
     * @param canUnstake If ustaking should be enabled or disabled
     */
    function setStakingStatus(address nft, bool canStake, bool canUnstake) external onlyOwner {
        uint256 status = 0;
        if (canStake) {
            status = status | _BITPOS_CAN_STAKE;
        }
        if (canUnstake) {
            status = status | _BITPOS_CAN_UNSTAKE;
        }
        _packedContractInfos[nft] = _packedContractInfos[nft] & _BITMASK_NUMBER_STAKED | status;
    }

    /** Internal functions */

    function _packStakingInfos(address staker, uint256 timestamp) private pure returns(uint256) {
        return (timestamp << 160) | uint160(staker);
    }

    function _unpackStakingInfos(uint256 pack) private pure returns(address, uint256) {
        return (
            address(uint160(pack)),
            pack >> 160
        );
    }

    function _packContractInfos(StakingStatus status, uint256 numberStaked) private pure returns(uint256) {
        return (uint8(status) << 64) | numberStaked;
    }

    function _unpackContractInfos(uint256 pack) private pure returns(StakingStatus, uint256) {
        return (
            StakingStatus((pack >> 64) & 3),
            uint256(uint64(pack))
        );
    }

    function _canStake(address nft) private view returns(bool) {
        return (_packedContractInfos[nft] & _BITPOS_CAN_STAKE) > 0;
    }

    function _canUnstake(address nft) private view returns(bool) {
        return (_packedContractInfos[nft] & _BITPOS_CAN_UNSTAKE) > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMuutariumStaking {
  event Stake(
    address indexed contractAddress,
    address indexed staker,
    uint256 indexed tokenId
  );

  event Unstake(
    address indexed contractAddress,
    address indexed staker,
    uint256 indexed tokenId
  );

  enum StakingStatus {
    NONE,
    STAKE,
    UNSTAKE,
    ALL
  }

  struct StakingInfos {
    address owner;
    uint256 stakedAt;
  }

  struct CollectionInfos {
    uint256 numberStaked;
    StakingStatus status;
  }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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