// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "../erc721/ERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Burnable} from "../interfaces/IERC721/IERC721Burnable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC1967UUPSENSUpgradeable} from "../proxy/ERC1967UUPSENSUpgradeable.sol";

contract WhitehatHallOfFame is ERC1967UUPSENSUpgradeable, ERC721, IERC721Metadata, IERC721Burnable {
  constructor(string[] memory ensName) ERC1967UUPSENSUpgradeable(ensName) {
    _requireOwner();
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) onlyProxy returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Burnable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  string public constant override name = "WhitehatHallOfFame";
  string public constant override symbol = "WHoF";
  mapping(uint256 => string) public override tokenURI;

  uint256 internal _nonce;

  function _nextNonce() internal returns (uint256) {
    unchecked {
      return ++_nonce;
    }
  }

  function mint(address recipient, string calldata uri) external onlyOwner {
    uint256 tokenId = _nextNonce();
    tokenURI[tokenId] = uri;
    _mint(recipient, tokenId);
  }

  function safeMint(
    address recipient,
    string calldata uri,
    bytes calldata transferData
  ) external onlyOwner {
    uint256 tokenId = _nextNonce();
    tokenURI[tokenId] = uri;
    _safeMint(recipient, tokenId, transferData);
  }

  function burn(uint256 tokenId) external override onlyApproved(tokenId) {
    _burn(tokenId);
    delete tokenURI[tokenId];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SafeCall} from "../lib/SafeCall.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 */
abstract contract ERC721 is Context, ERC165, IERC721 {
  using SafeCall for address;

  /// Mapping from token ID to owner address
  // We can't use the auto-generated getter because `ownerOf` must throw for
  // nonexistent tokens and tokens owned by the zero address
  mapping(uint256 => address) private _owners;

  /// Mapping owner address to token count
  // We can't use the auto-generated getter because `balanceOf` must throw for
  // the zero address
  mapping(address => uint256) private _balances;

  /// Mapping from token ID to approved address
  // We can't use the auto-generated getter because `getApproved` must throw
  // for nonexistent tokens and tokens owned by the zero address
  mapping(uint256 => address) private _tokenApprovals;

  /// Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) public override isApprovedForAll;

  /**
   * @dev Initializes the contract.
   */
  constructor() {
    assert(type(IERC721).interfaceId == 0x80ac58cd);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "ERC721: zero address");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
    owner = _owners[tokenId];
    require(owner != address(0), "ERC721: no token");
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    _requireOwnerOrApprovedForAll(tokenId, _msgSender());
    require(to != _owners[tokenId], "ERC721: to owner");
    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (address) {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    address msgSender = _msgSender();
    require(operator != msgSender, "ERC721: to owner");
    isApprovedForAll[msgSender][operator] = approved;
    emit ApprovalForAll(msgSender, operator, approved);
  }

  function _requireApproved(uint256 tokenId, address account) internal view {
    require(_isApprovedOrOwner(account, tokenId), "ERC721: not approved");
  }

  function _requireOwnerOrApprovedForAll(uint256 tokenId, address account) internal view {
    address owner = ownerOf(tokenId);
    require(account == owner || isApprovedForAll[owner][account], "ERC721: not approved");
  }

  modifier onlyApproved(uint256 tokenId) {
    _requireApproved(tokenId, _msgSender());
    _;
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override onlyApproved(tokenId) {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override onlyApproved(tokenId) {
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    _checkOnERC721Received(from, to, tokenId, _data);
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _requireExists(uint256 tokenId) internal view {
    require(_exists(tokenId), "ERC721: no token");
  }

  modifier tokenExists(uint256 tokenId) {
    _requireExists(tokenId);
    _;
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll[owner][spender]);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    _checkOnERC721Received(address(0), to, tokenId, _data);
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: zero address");
    require(!_exists(tokenId), "ERC721: token exists");

    _beforeTokenTransfer(address(0), to, tokenId);

    unchecked {
      _balances[to]++;
    }
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    unchecked {
      _balances[owner]--;
    }
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(ownerOf(tokenId) == from, "ERC721: not owner");
    require(to != address(0), "ERC721: zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    unchecked {
      _balances[from]--;
      _balances[to]++;
    }
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private {
    // Much of this could be implemented in a more-obviously-safe way by using
    // the Address library from OZ. However, we elect not to in order to save on
    // contract size.
    if (to.code.length == 0) {
      return;
    }
    (bool success, bytes memory returnData) = to.safeCall(
      abi.encodeCall(IERC721Receiver(to).onERC721Received, (_msgSender(), from, tokenId, data))
    );
    if (!success) {
      if (returnData.length != 0) {
        assembly ("memory-safe") {
          revert(add(32, returnData), mload(returnData))
        }
      }
    } else if (abi.decode(returnData, (bytes4)) == IERC721Receiver.onERC721Received.selector) {
      return;
    }
    revert("ERC721: not ERC721Receiver");
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721Burnable {
  function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.13;

import {ERC1967UUPSUpgradeable} from "./ERC1967UUPSUpgradeable.sol";

interface Resolver {
  function addr(bytes32 node) external view returns (address);
}

interface ENS {
  function resolver(bytes32 node) external view returns (Resolver);
}

contract ERC1967UUPSENSUpgradeable is ERC1967UUPSUpgradeable {
  ENS internal constant _ENS = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
  bytes32 internal immutable _OWNER_NAMEHASH;

  constructor (string[] memory ensName) {
    bytes32 namehash;
    for (uint256 i; i < ensName.length; i++) {
      namehash = keccak256(bytes.concat(namehash, keccak256(bytes(ensName[i]))));
    }
    _OWNER_NAMEHASH = namehash;
  }

  function _owner() internal view returns (address) {
    return _ENS.resolver(_OWNER_NAMEHASH).addr(_OWNER_NAMEHASH);
  }

  function owner() public view onlyProxy returns (address) {
    return _owner();
  }

  function _requireOwner() internal view {
    require(_msgSender() == _owner(), "ERC1967UUPSENSUpgradeable: only owner");
  }

  modifier onlyOwner() {
    _requireProxy();
    _requireOwner();
    _;
  }

  function initialize() public virtual override {
    _requireOwner();
    super.initialize();
  }

  function upgrade(address newImplementation) public payable virtual override {
    _requireOwner();
    super.upgrade(newImplementation);
  }

  function upgradeAndCall(address newImplementation, bytes calldata data) public payable virtual override {
    _requireOwner();
    super.upgradeAndCall(newImplementation, data);
  }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.13;

import {Address} from "../external/Address.sol";
import {FullMath} from "../external/uniswapv3/FullMath.sol";

library SafeCall {
  using Address for address;
  using Address for address payable;

  function safeCall(address target, bytes memory data) internal returns (bool, bytes memory) {
    return safeCall(payable(target), data, 0);
  }

  function safeCall(
    address payable target,
    bytes memory data,
    uint256 value
  ) internal returns (bool, bytes memory) {
    return safeCall(target, data, value, 0);
  }

  function safeCall(
    address payable target,
    bytes memory data,
    uint256 value,
    uint256 depth
  ) internal returns (bool success, bytes memory returndata) {
    require(depth < 42, "SafeCall: overflow");
    if (value > 0 && (address(this).balance < value || !target.isContract())) {
      return (success, returndata);
    }

    uint256 beforeGas;
    uint256 afterGas;

    assembly ("memory-safe") {
      // As of the time this contract was written, `verbatim` doesn't work in
      // inline assembly. Due to how the Yul IR optimizer inlines and optimizes,
      // the amount of gas required to prepare the stack with arguments for call
      // is unpredictable. However, each these operations cost
      // gas. Additionally, `call` has an intrinsic gas cost, which is too
      // complicated for this comment but can be found in the Ethereum
      // yellowpaper, Berlin version fabef25, appendix H.2, page 37. Therefore,
      // `beforeGas` is always above the actual gas available before the
      // all-but-one-64th rule is applied. This makes the following checks too
      // conservative. We do not correct for any of this because the correction
      // would become outdated (possibly too permissive) if the opcodes are
      // repriced.

      let offset := add(data, 0x20)
      let length := mload(data)
      beforeGas := gas()
      success := call(gas(), target, value, offset, length, 0, 0)

      // Assignment of a value to a variable costs gas (although how much is
      // unpredictable because it depends on the optimizer), as does the `GAS`
      // opcode itself. Therefore, the `gas()` below returns less than the
      // actual amount of gas available for computation at the end of the
      // call. Again, that makes the check slightly too conservative. Again, we
      // do not attempt any correction.
      afterGas := gas()
    }

    if (!success) {
      // The arithmetic here iterates the all-but-one-sixty-fourth rule to
      // ensure that the call that's `depth` contexts away received enough
      // gas. See: https://eips.ethereum.org/EIPS/eip-150
      unchecked {
        depth++;
        uint256 powerOf64 = 1 << (depth * 6);
        if (FullMath.mulDivCeil(beforeGas, powerOf64 - 63 ** depth, powerOf64) >= afterGas) {
          assembly ("memory-safe") {
            // The call probably failed due to out-of-gas. We deliberately
            // consume all remaining gas with `invalid` (instead of `revert`) to
            // make this failure distinguishable to our caller.
            invalid()
          }
        }
      }
    }

    assembly ("memory-safe") {
      switch returndatasize()
      case 0 {
        returndata := 0x60
        if iszero(value) {
          success := and(success, iszero(iszero(extcodesize(target))))
        }
      }
      default {
        returndata := mload(0x40)
        mstore(returndata, returndatasize())
        let offset := add(returndata, 0x20)
        returndatacopy(offset, 0, returndatasize())
        mstore(0x40, add(offset, returndatasize()))
      }
    }
  }

  function safeStaticCall(address target, bytes memory data) internal view returns (bool, bytes memory) {
    return safeStaticCall(target, data, 0);
  }

  function safeStaticCall(
    address target,
    bytes memory data,
    uint256 depth
  ) internal view returns (bool success, bytes memory returndata) {
    require(depth < 42, "SafeCall: overflow");

    uint256 beforeGas;
    uint256 afterGas;

    assembly ("memory-safe") {
      // As of the time this contract was written, `verbatim` doesn't work in
      // inline assembly. Due to how the Yul IR optimizer inlines and optimizes,
      // the amount of gas required to prepare the stack with arguments for call
      // is unpredictable. However, each these operations cost
      // gas. Additionally, `staticcall` has an intrinsic gas cost, which is too
      // complicated for this comment but can be found in the Ethereum
      // yellowpaper, Berlin version fabef25, appendix H.2, page 37. Therefore,
      // `beforeGas` is always above the actual gas available before the
      // all-but-one-64th rule is applied. This makes the following checks too
      // conservative. We do not correct for any of this because the correction
      // would become outdated (possibly too permissive) if the opcodes are
      // repriced.

      let offset := add(data, 0x20)
      let length := mload(data)
      beforeGas := gas()
      success := staticcall(gas(), target, offset, length, 0, 0)

      // Assignment of a value to a variable costs gas (although how much is
      // unpredictable because it depends on the optimizer), as does the `GAS`
      // opcode itself. Therefore, the `gas()` below returns less than the
      // actual amount of gas available for computation at the end of the
      // call. Again, that makes the check slightly too conservative. Again, we
      // do not attempt any correction.
      afterGas := gas()
    }

    if (!success) {
      // The arithmetic here iterates the all-but-one-sixty-fourth rule to
      // ensure that the call that's `depth` contexts away received enough
      // gas. See: https://eips.ethereum.org/EIPS/eip-150
      unchecked {
        depth++;
        uint256 powerOf64 = 1 << (depth * 6);
        if (FullMath.mulDivCeil(beforeGas, powerOf64 - 63 ** depth, powerOf64) >= afterGas) {
          assembly ("memory-safe") {
            // The call probably failed due to out-of-gas. We deliberately
            // consume all remaining gas with `invalid` (instead of `revert`) to
            // make this failure distinguishable to our caller.
            invalid()
          }
        }
      }
    }

    assembly ("memory-safe") {
      switch returndatasize()
      case 0 {
        returndata := 0x60
        success := and(success, iszero(iszero(extcodesize(target))))
      }
      default {
        returndata := mload(0x40)
        mstore(returndata, returndatasize())
        let offset := add(returndata, 0x20)
        returndatacopy(offset, 0, returndatasize())
        mstore(0x40, add(offset, returndatasize()))
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Address} from "../external/Address.sol";
import {IERC1967Proxy} from "../interfaces/proxy/IERC1967Proxy.sol";

abstract contract ERC1967UUPSUpgradeable is Context, IERC1967Proxy {
  using Address for address;

  address internal immutable _thisCopy;

  uint256 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
  uint256 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

  uint256 private constant _NO_ROLLBACK = 2;
  uint256 private constant _ROLLBACK_IN_PROGRESS = 3;

  constructor() {
    _thisCopy = address(this);
    assert(_IMPLEMENTATION_SLOT == uint256(keccak256("eip1967.proxy.implementation")) - 1);
    assert(_ROLLBACK_SLOT == uint256(keccak256("eip1967.proxy.rollback")) - 1);
  }

  function implementation() public view virtual override returns (address result) {
    assembly ("memory-safe") {
      result := sload(_IMPLEMENTATION_SLOT)
    }
  }

  function _setImplementation(address newImplementation) private {
    assembly ("memory-safe") {
      sstore(_IMPLEMENTATION_SLOT, newImplementation)
    }
  }

  function _isRollback() internal view returns (bool) {
    uint256 slotValue;
    assembly ("memory-safe") {
      slotValue := sload(_ROLLBACK_SLOT)
    }
    return slotValue == _ROLLBACK_IN_PROGRESS;
  }

  function _setRollback(bool rollback) private {
    uint256 slotValue = rollback ? _ROLLBACK_IN_PROGRESS : _NO_ROLLBACK;
    assembly ("memory-safe") {
      sstore(_ROLLBACK_SLOT, slotValue)
    }
  }

  function _requireProxy() internal view {
    require(implementation() == _thisCopy && address(this) != _thisCopy, "ERC1967UUPSUpgradeable: only proxy");
  }

  modifier onlyProxy() {
    _requireProxy();
    _;
  }

  function initialize() public virtual onlyProxy {
    _setRollback(false);
  }

  function _encodeDelegateCall(bytes memory callData) internal view virtual returns (bytes memory) {
    return callData;
  }

  function _checkImplementation(address newImplementation, bool rollback) internal virtual {
    require(implementation() == newImplementation, "ERC1967UUPSUpgradeable: interfered with implementation");
    require(rollback || !_isRollback(), "ERC1967UUPSUpgradeable: interfered with rollback");
  }

  function _checkRollback(bool rollback) private {
    if (!rollback) {
      _setRollback(true);
      address newImplementation = implementation();
      newImplementation.functionDelegateCall(
        _encodeDelegateCall(abi.encodeCall(this.upgrade, (_thisCopy))),
        "ERC1967UUPSUpgradeable: rollback upgrade failed"
      );
      _setRollback(false);
      require(implementation() == _thisCopy, "ERC1967UUPSUpgradeable: upgrade breaks further upgrades");
      emit Upgraded(newImplementation);
      _setImplementation(newImplementation);
    }
  }

  function upgrade(address newImplementation) public payable virtual override onlyProxy {
    bool rollback = _isRollback();
    _setImplementation(newImplementation);
    _checkImplementation(newImplementation, rollback);
    _checkRollback(rollback);
  }

  function upgradeAndCall(address newImplementation, bytes calldata data) public payable virtual override onlyProxy {
    bool rollback = _isRollback();
    _setImplementation(newImplementation);
    newImplementation.functionDelegateCall(
      _encodeDelegateCall(data),
      "ERC1967UUPSUpgradeable: initialization failed"
    );
    _checkImplementation(newImplementation, rollback);
    _checkRollback(rollback);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                assembly ("memory-safe") {
                    revert(add(32, returndata), mload(returndata))
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256) {
        return _mulDiv(a, b, denominator, true);
    }

    function mulDivCeil(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256) {
        return _mulDiv(a, b, denominator, false);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds accorrding to `roundDown`. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @param roundDown if true, round towards negative infinity; if false, round towards positive infinity
    /// @return The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function _mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator,
        bool roundDown
    ) private pure returns (uint256) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        uint256 remainder; // Remainder of full-precision division
        assembly ("memory-safe") {
            // Full-precision multiplication
            {
                let mm := mulmod(a, b, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            remainder := mulmod(a, b, denominator)

            if and(sub(roundDown, 1), remainder) {
                // Make division exact by rounding [prod1 prod0] up to a
                // multiple of denominator
                let addend := sub(denominator, remainder)
                // Add 256 bit number to 512 bit number
                prod0 := add(prod0, addend)
                prod1 := add(prod1, lt(prod0, addend))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            if iszero(gt(denominator, prod1)) {
                // selector for `Panic(uint256)`
                mstore(0x00, 0x4e487b71)
                // 0x11 -> overflow; 0x12 -> division by zero
                mstore(0x20, add(0x11, iszero(denominator)))
                revert(0x1c, 0x24)
            }
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            uint256 result;
            assembly ("memory-safe") {
                result := div(prod0, denominator)
            }
            return result;
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        uint256 inv;
        assembly ("memory-safe") {
            if roundDown {
                // Make division exact by rounding [prod1 prod0] down to a
                // multiple of denominator
                // Subtract 256 bit number from 512 bit number
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            {
                // Compute largest power of two divisor of denominator.
                // Always >= 1.
                let twos := and(sub(0, denominator), denominator)

                // Divide denominator by power of two
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by the factors of two
                prod0 := div(prod0, twos)
                // Shift in bits from prod1 into prod0. For this we need
                // to flip `twos` such that it is 2**256 / twos.
                // If twos is zero, then it becomes one
                twos := add(div(sub(0, twos), twos), 1)
                prod0 := or(prod0, mul(prod1, twos))
            }

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            inv := xor(mul(3, denominator), 2)

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**256
        }

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        unchecked {
            return prod0 * inv;
        }
    }

    struct uint512 {
      uint256 l;
      uint256 h;
    }

    // Adapted from: https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
    function mulAdd(uint512 memory x, uint256 y, uint256 z) internal pure {
      unchecked {
        uint256 l = y * z;
        uint256 mm = mulmod(y, z, type(uint256).max);
        uint256 h = mm - l;
        x.l += l;
        if (l > x.l) h++;
        if (mm < l) h--;
        x.h += h;
      }
    }

    function _msb(uint256 x) private pure returns (uint256 r) {
        unchecked {
            require (x > 0);
            if (x >= 2**128) {
                x >>= 128;
                r += 128;
            }
            if (x >= 2**64) {
                x >>= 64;
                r += 64;
            }
            if (x >= 2**32) {
                x >>= 32;
                r += 32;
            }
            if (x >= 2**16) {
                x >>= 16;
                r += 16;
            }
            if (x >= 2**8) {
                x >>= 8;
                r += 8;
            }
            if (x >= 2**4) {
                x >>= 4;
                r += 4;
            }
            if (x >= 2**2) {
                x >>= 2;
                r += 2;
            }
            if (x >= 2**1) {
                x >>= 1;
                r += 1;
            }
        }
    }

    function div(uint512 memory x, uint256 y) internal pure returns (uint256 r) {
        uint256 l = x.l;
        uint256 h = x.h;
        require (h < y);
        unchecked {
            uint256 yShift = _msb(y);
            uint256 shiftedY = y;
            if (yShift <= 127) {
                yShift = 0;
            } else {
                yShift -= 127;
                shiftedY = (shiftedY - 1 >> yShift) + 1;
            }
            while (h > 0) {
                uint256 lShift = _msb(h) + 1;
                uint256 hShift = 256 - lShift;
                uint256 e = ((h << hShift) + (l >> lShift)) / shiftedY;
                if (lShift > yShift) {
                    e <<= (lShift - yShift);
                } else {
                    e >>= (yShift - lShift);
                }
                r += e;

                uint256 tl;
                uint256 th;
                {
                    uint256 mm = mulmod(e, y, type(uint256).max);
                    tl = e * y;
                    th = mm - tl;
                    if (mm < tl) {
                        th -= 1;
                    }
                }

                h -= th;
                if (tl > l) {
                    h -= 1;
                }
                l -= tl;
            }
            r += l / y;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC1967Proxy {
  event Upgraded(address indexed implementation);

  function implementation() external view returns (address);

  function upgrade(address newImplementation) external payable;

  function upgradeAndCall(address newImplementation, bytes calldata data) external payable;
}