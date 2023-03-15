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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import {IPFPBinding} from "./IPFPBinding.sol";
import {ICommunityVerification} from "./ICommunityVerification.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title
 * Forever by binding binding to an address like ENS reverse,
 * PFP by community verification.
 */
contract ForeverPFP is Ownable, IPFPBinding, ICommunityVerification {
    mapping(bytes32 => address) private bindingAddresses;
    mapping(address => IPFPBinding.PFP) private pfps;
    mapping(address => bool) private verifications;

    function bind(address contract_, uint256 tokenId) external override {
        _bind(contract_, tokenId, msg.sender);
        emit PFPBound(msg.sender, contract_, tokenId);
    }

    function bindDelegate(
        address contract_,
        uint256 tokenId,
        address delegate
    ) external override {
        _bind(contract_, tokenId, delegate);
        emit PFPBoundDelegate(msg.sender, delegate, contract_, tokenId);
    }

    function _bind(address contract_, uint256 tokenId, address addr) internal {
        address owner = IERC721(contract_).ownerOf(tokenId);
        require(owner == msg.sender, "msg.sender is not the owner");
        bytes32 pfpHash = _pfpKey(contract_, tokenId);
        address boundAddress = bindingAddresses[pfpHash];
        require(boundAddress != addr, "duplicated binding");
        bindingAddresses[pfpHash] = addr;
        pfps[addr] = IPFPBinding.PFP(contract_, tokenId);
        if (boundAddress == address(0)) {
            return;
        }
        emit PFPUnbound(boundAddress, contract_, tokenId);
        delete pfps[boundAddress];
        return;
    }

    function unbind(address contract_, uint256 tokenId) external override {
        address owner = IERC721(contract_).ownerOf(tokenId);
        require(owner == msg.sender, "msg.sender is not the owner");
        bytes32 pfpHash = _pfpKey(contract_, tokenId);
        address boundAddress = bindingAddresses[pfpHash];
        require(boundAddress != address(0), "PFP not bound");

        emit PFPUnbound(boundAddress, contract_, tokenId);

        delete bindingAddresses[pfpHash];
        delete pfps[boundAddress];
    }

    function getPFP(
        address addr
    ) external view override returns (address, uint256) {
        IPFPBinding.PFP memory pfp = pfps[addr];
        return (pfp.contract_, pfp.tokenId);
    }

    function getBindingAddress(
        address contract_,
        uint256 tokenId
    ) external view override returns (address) {
        return bindingAddresses[_pfpKey(contract_, tokenId)];
    }

    function addVerification(address contract_) external override onlyOwner {
        require(!verifications[contract_], "duplicated collection");
        verifications[contract_] = true;
        emit VerificationAdded(contract_);
    }

    function removeVerification(address contract_) external override onlyOwner {
        require(verifications[contract_], "collection not verified");
        verifications[contract_] = false;
        emit VerificationRemoved(contract_);
    }

    function isVerified(
        address contract_
    ) external view override returns (bool) {
        return verifications[contract_];
    }

    function _pfpKey(
        address collection,
        uint256 tokenId
    ) internal pure virtual returns (bytes32) {
        return keccak256(abi.encode(collection, tokenId));
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title Same image url will confuse people, so verify a collection list of unique PFPs is important by the community.
 *
 * @dev this verfication can be maintained by the community by voting on snapshot with future developed ERC721/ERC20 tokens.
 */
interface ICommunityVerification {
    // @notice Emitted when a PFP collection is verified.
    event VerificationAdded(address indexed contract_);

    // @notice Emitted when a PFP collection is removed.
    event VerificationRemoved(address indexed contract_);

    /**
     * @notice Owner only, multi-sig by community voted.
     *
     * @param contract_ The collection address of the PFP
     */
    function addVerification(address contract_) external;

    /**
     * @notice Owner only, multi-sig by community voted.
     * Just in case one collection change metadata image to confuse people.
     *
     * @param contract_ The collection address of the PFP
     */
    function removeVerification(address contract_) external;

    /**
     * @notice Returns whether a PFP collection is verified.
     *
     * @param contract_ The collection address of the PFP
     */
    function isVerified(address contract_) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title Bind address to PFP 1:1 mapping like ENS reverse record.
 * @dev Only owner of the token can bind or unbind the PFP.
 */
interface IPFPBinding {
    struct PFP {
        address contract_;
        uint256 tokenId;
    }

    // @notice Emitted when a PFP bound from the owner.
    event PFPBound(
        address indexed to,
        address indexed contract_,
        uint256 tokenId
    );

    // @notice Emitted when a PFP bound to a delegate.
    event PFPBoundDelegate(
        address indexed from,
        address indexed to,
        address indexed contract_,
        uint256 tokenId
    );

    // @notice Emitted when a PFP unbound from the owner.
    event PFPUnbound(
        address indexed from,
        address indexed contract_,
        uint256 tokenId
    );

    /**
     * @notice Bind PFP to the msg.sender.
     * Only the token owner can bind.
     *
     * @param contract_ The address of the PFP
     * @param tokenId The tokenId of the PFP
     */
    function bind(address contract_, uint256 tokenId) external;

    /**
     * @notice Bind PFP to the delegate.
     * Only the token owner can bind the delegate.
     *
     * @param contract_ The address of the PFP
     * @param tokenId The tokenId of the PFP
     * @param delegate The delegate/hotwallet address owner want to delegate to
     */
    function bindDelegate(
        address contract_,
        uint256 tokenId,
        address delegate
    ) external;

    /**
     * @notice Unbind PFP from bound address.
     * Only the token owner can unbind the binding.
     *
     * @param contract_ The address of the PFP
     * @param tokenId The tokenId of the PFP
     */
    function unbind(address contract_, uint256 tokenId) external;

    /**
     * @notice Get ERC721 collection address and tokenId as PFP for an address.
     * Returns address(0) & 0 if this addr has no PFP binding
     *
     * @param addr The address for querying PFP binding
     */
    function getPFP(address addr) external view returns (address, uint256);

    /**
     * @notice Get address mapping to one PFP.
     * Returns delegated address if this PFP is bind to delegate, returns address(0) if the PFP is not bound to any address.
     *
     * @param contract_ The address of the PFP
     * @param tokenId The tokenId of the PFP
     */
    function getBindingAddress(
        address contract_,
        uint256 tokenId
    ) external view returns (address);
}