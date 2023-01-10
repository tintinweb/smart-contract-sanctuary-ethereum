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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title IERC1644 Controller Token Operation (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/ethereum/EIPs/issues/1644
/// @notice data and operatorData parameters were removed from `controllerTransfer`
/// and `controllerRedeem`
interface IERC1644 {
    // Controller Operation
    function isControllable() external view returns (bool);

    function controllerTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function controllerRedeem(address account, uint256 amount) external;

    // Controller Events
    event ControllerTransfer(
        address controller,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    event ControllerRedemption(
        address controller,
        address indexed account,
        uint256 amount
    );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC1644} from "./IERC1644.sol";
import {ITokenEnforceable} from "../TokenEnforceable/ITokenEnforceable.sol";

// IERC1644 Adds controller mechanisms for the owner to burn and transfer without allowances
interface IERC20Club is IERC1644 {
    event ControlDisabled(address indexed controller);
    event MemberJoined(address indexed member);
    event MemberExited(address indexed member);
    event TokenRecovered(
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    // solhint-disable-next-line func-name-mixedcase
    function __ERC20Club_init(
        string memory name_,
        string memory symbol_,
        address mintPolicy_,
        address burnPolicy_,
        address transferPolicy_
    ) external;

    function memberCount() external view returns (uint256);

    function disableControl() external;

    function mintTo(address account, uint256 amount) external returns (bool);

    function redeem(uint256 amount) external returns (bool);

    function redeemFrom(address account, uint256 amount)
        external
        returns (bool);

    function recoverERC20(
        address recipient,
        address token,
        uint256 amount
    ) external;
}

interface IERC20ClubFull is
    IERC20,
    IERC20Metadata,
    ITokenEnforceable,
    IERC20Club
{
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ITokenEnforceable} from "../TokenEnforceable/ITokenEnforceable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Membership {
    event RendererUpdated(address indexed implementation);

    // solhint-disable-next-line func-name-mixedcase
    function __ERC721Membership_init(
        string memory name_,
        string memory symbol_,
        address mintPolicy_,
        address burnPolicy_,
        address transferPolicy_,
        address renderer_
    ) external;

    function mintTo(address account) external returns (bool);

    function currentSupply() external view returns (uint256);
}

interface IERC721MembershipFull is
    IERC721,
    IERC721Metadata,
    ITokenEnforceable,
    IERC721Membership
{
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IMembershipRenderer {
    // to be called by frontend to render for a provided membership contract
    function tokenURIOf(address membership, uint256 tokenId)
        external
        view
        returns (string memory);

    // to be called by a ERC721Membership contract
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IMembershipRenderer} from "./Renderer/IMembershipRenderer.sol";

/// Custom contract for RugRadio utility NFTsproperties
contract RugUtilityProperties is Ownable, IMembershipRenderer {
    using Strings for uint256;

    uint256 public seed;
    string public baseURI; // https://pinata.cloud/<location>/

    // tokenId => custom combination ID
    mapping(uint256 => uint256) public oneOfOneCombination;
    // tokenId => custom token production
    mapping(uint256 => uint256) public oneOfOneProduction;

    event SeedGenerated(string phrase, uint256 seed);
    event UpdateBaseURI(string baseURI);
    event UpdateCombination(
        uint256 indexed tokenId,
        uint256 indexed combinationId
    );
    event UpdateProduction(uint256 indexed tokenId, uint256 indexed production);

    modifier onlyAfterReveal() {
        require(
            seed > 0 && bytes(baseURI).length > 0,
            "Reveal not released yet"
        );
        _;
    }

    function generateSeed(string memory phrase)
        external
        onlyOwner
        returns (uint256)
    {
        require(seed == 0, "Seed already set");
        seed = uint256(keccak256(abi.encode(phrase)));
        emit SeedGenerated(phrase, seed);
    }

    function updateBaseURI(string memory uri)
        external
        onlyOwner
        returns (string memory)
    {
        baseURI = uri;
        emit UpdateBaseURI(baseURI);
    }

    function updateOneOfOneCombination(uint256 tokenId, uint256 combination)
        external
        onlyOwner
    {
        // max combination Id = 4 * 100 + 16 = 416 -> use 500 for clean separation
        // additionally let people set to 0 in case an error occured and need a reset
        require(
            combination >= 500 || combination == 0,
            "One-of-One combination id invalid"
        );
        oneOfOneCombination[tokenId] = combination;
        emit UpdateCombination(tokenId, combination);
    }

    function updateOneOfOneProduction(uint256 tokenId, uint256 production)
        external
        onlyOwner
    {
        oneOfOneProduction[tokenId] = production;
        emit UpdateProduction(tokenId, production);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (seed == 0) {
            // fixed URL for utility NFT pre-reveal, allows us to switch renderer before reveal easily
            return "ipfs://QmPLizWkV3zmDybjXZnr7AALNLjab67QsmfrzHC8bhUm4S";
        }
        return
            string(
                abi.encodePacked(
                    baseURI,
                    getCombinationId(tokenId).toString(),
                    ".json"
                )
            );
    }

    function tokenURIOf(address, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return tokenURI(tokenId);
    }

    function getSlot(uint256 tokenId)
        internal
        view
        onlyAfterReveal
        returns (uint256)
    {
        // randomly distributee tokenId's across slots by re-hashing with seed
        uint256 slotSeed = uint256(keccak256(abi.encode(seed, tokenId)));
        return slotSeed % 19989;
    }

    function getCombinationId(uint256 tokenId) internal view returns (uint256) {
        if (oneOfOneCombination[tokenId] == 0) {
            return uint256(getRole(tokenId)) * 100 + getMeme(tokenId);
        } else {
            return oneOfOneCombination[tokenId];
        }
    }

    function getRole(uint256 tokenId) public view returns (uint8) {
        if (oneOfOneCombination[tokenId] == 0) {
            uint256 slot = getSlot(tokenId);

            if (slot < 112) {
                // 7 * 16 rows = 112 "Rare 2" roles
                return 1;
            } else if (slot < 112 + 1104) {
                // 69 * 16 rows = 1104 "Scarce 1" roles
                return 2;
            } else if (slot < 112 + 1104 + 7648) {
                // 478 * 16 rows = 7648 "Scarce 2" roles
                return 3;
            } else {
                // rest of roles are "Standard"
                return 4;
            }
        } else {
            // custom additions of "Rare 1" roles
            return 0;
        }
    }

    function getMeme(uint256 tokenId) public view returns (uint8) {
        if (oneOfOneCombination[tokenId] == 0) {
            // all rows share uniform distribution of different meme values
            return uint8((getSlot(tokenId) % 16) + 1);
        } else {
            // "One-of-One" for special tokens with override
            return 0;
        }
    }

    function getProduction(uint256 tokenId) external view returns (uint256) {
        if (oneOfOneProduction[tokenId] > 0) {
            // "Rare 1" roles with additional custom production rate
            return oneOfOneProduction[tokenId];
        }
        uint8 role = getRole(tokenId);
        if (role <= 1) {
            // "Rare X" roles
            return 11;
        } else if (role <= 3) {
            // "Scarce X" roles
            return 7;
        } else {
            // "Standard" roles
            return 5;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20ClubFull} from "../ERC20Club/IERC20Club.sol";
import {IERC721MembershipFull} from "../ERC721Membership/IERC721Membership.sol";
import {RugUtilityProperties} from "../ERC721Membership/RugUtilityProperties.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// This module contract allows users to claim available tokens for a given Gensis NFT
/// The caller of the claim function does not have to be the owner of the NFT
contract RugERC20ClaimModule is Ownable, ReentrancyGuard {
    uint256 public constant RUG_TOKEN_DECIMALS_MULTIPLIER = 10**18;

    IERC20ClubFull public rugToken;
    IERC721MembershipFull public genesisNFT;
    RugUtilityProperties public properties;

    // Mapping of TokenIds => time of last claim
    mapping(uint256 => uint256) public lastClaim;
    uint256 public startTime;

    event StartTimeSet(uint256 startTime);
    event RugTokensClaimed(uint256 indexed tokenId, uint256 amount);

    constructor(
        address rugToken_,
        address genesisNFT_,
        address properties_,
        uint256 startTime_
    ) Ownable() ReentrancyGuard() {
        rugToken = IERC20ClubFull(rugToken_);
        genesisNFT = IERC721MembershipFull(genesisNFT_);
        properties = RugUtilityProperties(properties_);
        setStartTime(startTime_);
    }

    modifier onlyAfterStart() {
        require(block.timestamp > startTime, "Token claiming is not active");
        _;
    }

    /// Function to set the start time of the claiming period
    /// Can only be called by the owner of the contract
    /// @param start Start time of claim
    function setStartTime(uint256 start) public onlyOwner {
        require(start != 0, "Start time must not be 0");
        startTime = start;
        emit StartTimeSet(startTime);
    }

    /// Function that returns initial bonus amount of tokens
    /// @param production Get the initial bonus for a given role
    /// @return The amount bonus tokens for a given production amount
    function getStartingBalance(uint256 production)
        internal
        pure
        returns (uint256)
    {
        if (production == 5) {
            return 555;
        } else if (production == 7) {
            return 888;
        } else if (production == 11) {
            return 1111;
        }

        return 0;
    }

    /// Function that calculates the amount of tokens a tokenId has available to claim
    /// IMPORTANT: This returns the number of tokens NOT scaled up with decimals
    /// @param tokenId Gensis NFT ID
    /// @return The amount tokens to mint
    function getClaimAmount(uint256 tokenId)
        public
        view
        onlyAfterStart
        returns (uint256)
    {
        uint256 production = properties.getProduction(tokenId);
        if (lastClaim[tokenId] == 0) {
            return
                (((block.timestamp - startTime) / 1 days) * production) +
                getStartingBalance(production);
        } else {
            return
                ((block.timestamp - lastClaim[tokenId]) / 1 days) * production;
        }
    }

    /// Function that mints/claims the available amount of tokens for a given RR Genesis NFT
    /// @param tokenId Gensis NFT ID
    /// @return The amount tokens claimed
    function claimTokens(uint256 tokenId)
        external
        onlyAfterStart
        nonReentrant
        returns (uint256)
    {
        uint256 amount = getClaimAmount(tokenId) *
            RUG_TOKEN_DECIMALS_MULTIPLIER;
        if (amount == 0) {
            return 0;
        }
        lastClaim[tokenId] = block.timestamp;

        address owner = genesisNFT.ownerOf(tokenId);
        rugToken.mintTo(owner, amount);

        emit RugTokensClaimed(tokenId, amount);
        return amount;
    }

    /// Function that bulk mints/claims for an array of Genesis token Ids
    /// @param tokenIds Array of Gensis NFT IDs
    /// @return True if successful
    function bulkClaimTokens(uint256[] calldata tokenIds)
        external
        onlyAfterStart
        nonReentrant
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            uint256 amount = getClaimAmount(tokenId) *
                RUG_TOKEN_DECIMALS_MULTIPLIER;
            if (amount != 0) {
                lastClaim[tokenId] = block.timestamp;

                address owner = genesisNFT.ownerOf(tokenId);
                rugToken.mintTo(owner, amount);

                emit RugTokensClaimed(tokenId, amount);
            }
        }

        return true;
    }

    /// This function is called for all messages sent to this contract (there
    /// are no other functions). Sending Ether to this contract will cause an
    /// exception, because the fallback function does not have the `payable`
    /// modifier.
    /// Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
    fallback() external {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ITokenEnforceable {
    event PolicyUpdated(
        PolicyType indexed policy,
        address indexed implementation
    );

    function updateMintPolicy(address implementation) external;

    function updateBurnPolicy(address implementation) external;

    function updateTransferPolicy(address implementation) external;

    function isAllowed(
        address operator,
        address sender,
        address recipient,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);
}

enum PolicyType {
    Mint,
    Burn,
    Transfer
}