// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol';

import './IMintable.sol';
import './IERC1155Burnable.sol';

contract BurnMinter is Ownable, ERC1155Receiver {
  IMintable _token;
  IERC1155Burnable _paymentToken;

  struct PaymentInfo {
    bool enabled;
    uint8 count;
    uint64[8] tokenIds;
    uint16[8] amounts;
  }

  mapping(uint256 => PaymentInfo) _mintPayments;

  constructor(address tokenAddress, address paymentTokenAddress) {
    _token = IMintable(tokenAddress);
    _paymentToken = IERC1155Burnable(paymentTokenAddress);
  }

  function getMintPayments(uint256 tokenId) external view returns (PaymentInfo memory) {
    return _mintPayments[tokenId];
  }

  function setMintPayment(
    uint256 tokenId,
    uint64[] calldata paymentTokenIds,
    uint16[] calldata paymentAmounts
  ) external onlyOwner {
    _setMintPayment(tokenId, paymentTokenIds, paymentAmounts);
  }

  function batchSetMintPayment(
    uint256[] calldata tokenIds,
    uint64[][] calldata paymentTokenIds,
    uint16[][] calldata paymentAmounts
  ) external onlyOwner {
    require(
      tokenIds.length == paymentTokenIds.length && tokenIds.length == paymentAmounts.length,
      'Tokens and payments length mismatch'
    );
    for (uint256 i; i < tokenIds.length; i++) {
      _setMintPayment(tokenIds[i], paymentTokenIds[i], paymentAmounts[i]);
    }
  }

  function setMintStatus(uint256 tokenId, bool enabled) external onlyOwner {
    _setMintStatus(tokenId, enabled);
  }

  function batchSetMintStatus(uint256[] calldata tokenIds, bool enabled) external onlyOwner {
    for (uint256 i; i < tokenIds.length; i++) {
      _setMintStatus(tokenIds[i], enabled);
    }
  }

  function mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external {
    require(amount > 0, 'Invalid amount');

    PaymentInfo storage paymentInfo = _mintPayments[tokenId];
    require(paymentInfo.enabled, 'Mint not enabled');

    uint256 count = paymentInfo.count;
    for (uint256 i; i < count; ++i) {
      _paymentToken.burn(msg.sender, paymentInfo.tokenIds[i], paymentInfo.amounts[i] * amount);
    }

    _token.mint(to, tokenId, amount);
  }

  function burnPayment(uint256[] calldata tokenIds) external onlyOwner {
    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      uint256 balance = _paymentToken.balanceOf(address(this), tokenId);
      _paymentToken.burn(address(this), tokenId, balance);
    }
  }

  function onERC1155Received(
    address, /* operator */
    address from,
    uint256 id,
    uint256 value,
    bytes memory data
  ) public virtual override returns (bytes4) {
    require(msg.sender == address(_paymentToken), 'Invalid caller'); // only accept payment token

    (uint256 tokenId, uint256 amount) = abi.decode(data, (uint256, uint256));
    require(amount > 0, 'Invalid amount');

    _validatePayment(tokenId, amount, _asSingletonArray(id), _asSingletonArray(value));

    // _paymentToken.burn(address(this), id, value);

    _token.mint(from, tokenId, amount);

    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address, /* operator */
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) public virtual override returns (bytes4) {
    require(msg.sender == address(_paymentToken), 'Invalid caller'); // only accept payment token

    (uint256 tokenId, uint256 amount) = abi.decode(data, (uint256, uint256));
    require(amount > 0, 'Invalid amount');

    _validatePayment(tokenId, amount, ids, values);

    // for (uint256 i; i < ids.length; ++i) {
    //   _paymentToken.burn(address(this), ids[i], values[i]);
    // }

    _token.mint(from, tokenId, amount);

    return this.onERC1155BatchReceived.selector;
  }

  function _setMintPayment(
    uint256 tokenId,
    uint64[] calldata paymentTokenIds,
    uint16[] calldata amounts
  ) internal {
    require(paymentTokenIds.length > 0 && paymentTokenIds.length <= 8, 'Invalid number of tokens');
    require(paymentTokenIds.length == amounts.length, 'Ids and amounts length mismatch');

    uint64[8] memory paymentTokens;
    uint16[8] memory paymentAmounts;

    uint64 prevTokenId;
    for (uint256 i; i < paymentTokenIds.length; ++i) {
      require(i == 0 || paymentTokenIds[i] > prevTokenId, 'Incorrect token order'); // specify tokens in ascending order
      require(amounts[i] > 0, 'Invalid payment amount');

      paymentTokens[i] = paymentTokenIds[i];
      paymentAmounts[i] = amounts[i];

      prevTokenId = paymentTokenIds[i];
    }

    PaymentInfo storage paymentInfo = _mintPayments[tokenId];
    paymentInfo.count = uint8(paymentTokenIds.length);
    paymentInfo.tokenIds = paymentTokens;
    paymentInfo.amounts = paymentAmounts;
  }

  function _setMintStatus(uint256 tokenId, bool enabled) internal {
    PaymentInfo storage paymentInfo = _mintPayments[tokenId];
    require(paymentInfo.count > 0, 'Payment tokens not set');

    paymentInfo.enabled = enabled;
  }

  function _validatePayment(
    uint256 tokenId,
    uint256 amount,
    uint256[] memory paymentIds,
    uint256[] memory paymentValues
  ) internal view {
    PaymentInfo storage paymentInfo = _mintPayments[tokenId];
    require(paymentInfo.enabled, 'Mint not enabled');
    require(paymentInfo.count == paymentIds.length, 'Incorrect payment');

    uint256 count = paymentInfo.count;
    for (uint256 i; i < count; ++i) {
      require(
        paymentIds[i] == paymentInfo.tokenIds[i] &&
          paymentValues[i] == paymentInfo.amounts[i] * amount,
        'Incorrect payment'
      );
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IBurnable {
  function burn(
    address from,
    uint256 tokenId,
    uint256 amount
  ) external;
}

interface IERC1155Burnable is IERC1155, IBurnable {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintable {
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  function mintBatch(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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