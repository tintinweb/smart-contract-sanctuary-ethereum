// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {IPrimaryPFP} from "./IPrimaryPFP.sol";
import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/**
 * @title Set primary PFP by binding a PFP to an address like primary ENS.
 *
 */
interface WarmXyzInterface {
    function getHotWallet(address coldWallet) external view returns (address);
}

interface DelegateCashInterface {
    function checkDelegateForAll(
        address delegate,
        address vault
    ) external view returns (bool);

    function checkDelegateForContract(
        address delegate,
        address vault,
        address contract_
    ) external view returns (bool);

    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);

    function delegateForToken(
        address delegate,
        address contract_,
        uint256 tokenId,
        bool value
    ) external;
}

contract PrimaryPFP is IPrimaryPFP, ERC165 {
    // keccak256(abi.encode(collection, tokenId)) => ownerAddress
    mapping(bytes32 => address) private pfpOwners;
    // ownerAddress => PFPStruct
    mapping(address => PFP) private primaryPFPs;

    DelegateCashInterface private immutable dci;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IPrimaryPFP).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    constructor(address dciAddress) {
        dci = DelegateCashInterface(dciAddress);
    }

    function setPrimary(address contract_, uint256 tokenId) external override {
        address tokenOwner = IERC721(contract_).ownerOf(tokenId);
        require(tokenOwner == msg.sender, "msg.sender is not the owner");
        _set(contract_, tokenId);
        emit PrimarySet(msg.sender, contract_, tokenId);
    }

    function setPrimaryByDelegateCash(
        address contract_,
        uint256 tokenId
    ) external override {
        address tokenOwner = IERC721(contract_).ownerOf(tokenId);
        require(
            dci.checkDelegateForToken(
                msg.sender,
                tokenOwner,
                contract_,
                tokenId
            ) ||
                dci.checkDelegateForContract(
                    msg.sender,
                    tokenOwner,
                    contract_
                ) ||
                dci.checkDelegateForAll(msg.sender, tokenOwner),
            "msg.sender is not delegated"
        );
        _set(contract_, tokenId);
        emit PrimarySetByDelegateCash(msg.sender, contract_, tokenId);
    }

    function _set(address contract_, uint256 tokenId) internal {
        bytes32 pfpHash = _pfpKey(contract_, tokenId);
        address lastOwner = pfpOwners[pfpHash];
        require(lastOwner != msg.sender, "duplicated set");
        pfpOwners[pfpHash] = msg.sender;
        PFP memory pfp = primaryPFPs[msg.sender];
        // owner has PFP record
        if (pfp.contract_ != address(0)) {
            emit PrimaryRemoved(msg.sender, pfp.contract_, pfp.tokenId);
            delete pfpOwners[_pfpKey(pfp.contract_, pfp.tokenId)];
        }
        primaryPFPs[msg.sender] = PFP(contract_, tokenId);
        if (lastOwner == address(0)) {
            return;
        }
        emit PrimaryRemoved(lastOwner, contract_, tokenId);
        delete primaryPFPs[lastOwner];
    }

    function removePrimary(
        address contract_,
        uint256 tokenId
    ) external override {
        address owner = IERC721(contract_).ownerOf(tokenId);
        require(owner == msg.sender, "msg.sender is not the owner");
        bytes32 pfpHash = _pfpKey(contract_, tokenId);
        address boundAddress = pfpOwners[pfpHash];
        require(boundAddress != address(0), "primary PFP not set");

        emit PrimaryRemoved(boundAddress, contract_, tokenId);
        delete pfpOwners[pfpHash];
        delete primaryPFPs[boundAddress];
    }

    function getPrimary(
        address addr
    ) external view override returns (address, uint256) {
        PFP memory pfp = primaryPFPs[addr];
        return (pfp.contract_, pfp.tokenId);
    }

    function getPrimaries(
        address[] calldata addrs
    ) external view returns (PFP[] memory) {
        uint256 length = addrs.length;
        PFP[] memory result = new PFP[](length);
        for (uint256 i; i < length; ) {
            result[i] = primaryPFPs[addrs[i]];
            unchecked {
                ++i;
            }
        }
        return result;
    }

    function getPrimaryAddress(
        address contract_,
        uint256 tokenId
    ) external view override returns (address) {
        return pfpOwners[_pfpKey(contract_, tokenId)];
    }

    function _pfpKey(
        address collection,
        uint256 tokenId
    ) internal pure virtual returns (bytes32) {
        return keccak256(abi.encodePacked(collection, tokenId));
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity ^0.8.20;

/**
 * @title Set primary PFP for an address like primary ENS.
 * @dev owner or delegated/warmed address can set primary PFP, only owner can remove the primary PFP.
 */
interface IPrimaryPFP {
    struct PFP {
        address contract_;
        uint256 tokenId;
    }

    // @notice Emitted when a primary PFP set for the owner.
    event PrimarySet(
        address indexed to,
        address indexed contract_,
        uint256 tokenId
    );

    // @notice Emitted when a primary PFP set from delegate.cash.
    event PrimarySetByDelegateCash(
        address indexed to,
        address indexed contract_,
        uint256 tokenId
    );

    // @notice Emitted when a primary PFP removed.
    event PrimaryRemoved(
        address indexed from,
        address indexed contract_,
        uint256 tokenId
    );

    /**
     * @notice Set primary PFP for an address.
     * Only the PFP owner can set it.
     *
     * @param contract_ The collection address of the PFP
     * @param tokenId The tokenId of the PFP
     */
    function setPrimary(address contract_, uint256 tokenId) external;

    /**
     * @notice Set primary PFP for an address from a delegated address from delegate.cash.
     * Only the delegated address from delegate cash can set it.
     *
     * @param contract_ The collection address of the PFP
     * @param tokenId The tokenId of the PFP
     */
    function setPrimaryByDelegateCash(
        address contract_,
        uint256 tokenId
    ) external;

    /**
     * @notice Remove the primary PFP setting.
     * Only the PFP owner can remove it.
     *
     * @param contract_ The collection address of the PFP
     * @param tokenId The tokenId of the PFP
     */
    function removePrimary(address contract_, uint256 tokenId) external;

    /**
     * @notice Get primary PFP for an address.
     * Returns address(0) & 0 if this addr has no primary PFP.
     *
     * @param addr The address for querying primary PFP
     */
    function getPrimary(address addr) external view returns (address, uint256);

    /**
     * @notice Get primary PFPs for an array of addresses.
     * Returns a list of PFP struct for addrs.
     *
     * @param addrs The addresses for querying primary PFP
     */
    function getPrimaries(
        address[] calldata addrs
    ) external view returns (PFP[] memory);

    /**
     * @notice Get address of primary PFP for an address.
     * Returns delegated address if this PFP is bind to delegate, returns address(0) if the PFP is not bound to any address.
     *
     * @param contract_ The collection address of the PFP
     * @param tokenId The tokenId of the PFP
     */
    function getPrimaryAddress(
        address contract_,
        uint256 tokenId
    ) external view returns (address);
}