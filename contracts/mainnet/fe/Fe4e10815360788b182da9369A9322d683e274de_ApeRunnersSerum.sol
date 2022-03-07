// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./base/Controllable.sol";
import "sol-temple/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Ape Runners Serum
/// @author naomsa <https://twitter.com/naomsa666>
contract ApeRunnersSerum is Ownable, Pausable, Controllable, ERC1155 {
  using Strings for uint256;

  /* -------------------------------------------------------------------------- */
  /*                                Sale Details                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Utility token contract address.
  IRUN public utilityToken;

  /* -------------------------------------------------------------------------- */
  /*                              Metadata Details                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Base metadata uri.
  string public baseURI;

  /// @notice Base metadata uri extension.
  string public baseExtension;

  constructor(
    string memory newBaseURI,
    string memory newBaseExtension,
    address newUtilityToken
  ) {
    // Set variables
    baseURI = newBaseURI;
    baseExtension = newBaseExtension;
    utilityToken = IRUN(newUtilityToken);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Sale Logic                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice Buy one or more serums.
  /// @param serum Serum id to buy.
  /// @param amount Amount to buy.
  function buy(uint256 serum, uint256 amount) external {
    require(
      serum == 1 || serum == 2 || serum == 3,
      "Query for nonexisting serum"
    );

    require(
      totalSupply[serum] + amount <= maxSuppply(serum),
      "Serum max supply exceeded"
    );

    require(amount > 0, "Invalid buy amount");

    utilityToken.burn(msg.sender, price(serum) * amount);
    _mint(msg.sender, serum, amount, "");
  }

  /// @notice Retrieve serum cost.
  /// @param serum Serum 1, 2 or 3.
  function price(uint256 serum) public pure returns (uint256) {
    if (serum == 1) return 300 ether;
    else if (serum == 2) return 900 ether;
    else if (serum == 3) return 3000 ether;
    else revert("Query for nonexisting serum");
  }

  /// @notice Retrieve serum max supply.
  /// @param serum Serum 1, 2 or 3.
  function maxSuppply(uint256 serum) public pure returns (uint256) {
    if (serum == 1) return 4500;
    else if (serum == 2) return 490;
    else if (serum == 3) return 10;
    else revert("Query for nonexisting serum");
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set baseURI to `newBaseURI`.
  /// @param newBaseURI New base uri.
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /// @notice Set baseExtension to `newBaseExtension`.
  /// @param newBaseExtension New base uri.
  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  /// @notice Set utilityToken to `newUtilityToken`.
  /// @param newUtilityToken New utility token.
  function setUtilityToken(address newUtilityToken) external onlyOwner {
    utilityToken = IRUN(newUtilityToken);
  }

  /// @notice Toggle if the contract is paused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                               ERC-1155 Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Mint new tokens with `ids` at `amounts` to `to`.
  /// @param to Address of the recipient.
  /// @param ids Array of token ids.
  /// @param amounts Array of amounts.
  function mint(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external onlyController {
    _mintBatch(to, ids, amounts, "");
  }

  /// @notice Burn tokens with `ids` at `amounts` from `from`.
  /// @param from Address of the owner.
  /// @param ids Array of token ids.
  /// @param amounts Array of amounts.
  function burn(
    address from,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external onlyController {
    _burnBatch(from, ids, amounts);
  }

  /// @notice See {ERC1155-uri}.
  function uri(uint256 id) public view override returns (string memory) {
    require(super.exists(id), "Query for nonexisting serum");
    return string(abi.encodePacked(baseURI, id.toString(), baseExtension));
  }

  /// @notice See {ERC1155-_beforeTokenTransfer}.
  /// @dev Overriden to block transactions while the contract is paused (avoiding bugs).
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {
    require(!super.paused() || msg.sender == super.owner(), "Pausable: paused");
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}

interface IRUN {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Controllable
abstract contract Controllable {
  /// @notice address => is controller.
  mapping(address => bool) private _isController;

  /// @notice Require the caller to be a controller.
  modifier onlyController() {
    require(
      _isController[msg.sender],
      "Controllable: Caller is not a controller"
    );
    _;
  }

  /// @notice Check if `addr` is a controller.
  function isController(address addr) public view returns (bool) {
    return _isController[addr];
  }

  /// @notice Set the `addr` controller status to `status`.
  function _setController(address addr, bool status) internal {
    _isController[addr] = status;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ERC1155
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice A complete ERC1155 implementation including supply tracking and
 * enumerable functions. Completely gas optimized and extensible.
 */
abstract contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice See {ERC1155-balanceOf}.
  mapping(address => mapping(uint256 => uint256)) public balanceOf;

  /// @notice See {ERC1155-isApprovedForAll}.
  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /// @notice Tracker for tokens in circulation by Id.
  mapping(uint256 => uint256) public totalSupply;

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  /// @notice See {ERC1155Metadata_URI-uri}.
  function uri(uint256) public view virtual returns (string memory);

  /// @notice See {ERC1155-balanceOfBatch}.
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; i++) batchBalances[i] = balanceOf[accounts[i]][ids[i]];

    return batchBalances;
  }

  /// @notice See {ERC1155-setApprovalForAll}.
  function setApprovalForAll(address operator, bool approved) public virtual {
    _setApprovalForAll(msg.sender, operator, approved);
  }

  /// @notice See {ERC1155-safeTransferFrom}.
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    require(from == msg.sender || isApprovedForAll[from][msg.sender], "ERC1155: caller is not owner nor approved");
    _safeTransferFrom(from, to, id, amount, data);
  }

  /// @notice See {ERC1155-safeBatchTransferFrom}.
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    require(
      from == msg.sender || isApprovedForAll[from][msg.sender],
      "ERC1155: transfer caller is not owner nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /// @notice Indicates whether any token exist with a given id, or not./
  function exists(uint256 id) public view virtual returns (bool) {
    return totalSupply[id] > 0;
  }

  /*             _                               _    */
  /*   _        ( )_                            (_ )  */
  /*  (_)  ___  | ,_)   __   _ __   ___     _ _  | |  */
  /*  | |/' _ `\| |   /'__`\( '__)/' _ `\ /'_` ) | |  */
  /*  | || ( ) || |_ (  ___/| |   | ( ) |( (_| | | |  */
  /*  (_)(_) (_)`\__)`\____)(_)   (_) (_)`\__,_)(___) */

  /// @notice Transfers `amount` tokens of token type `id` from `from` to `to`.
  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: transfer to the zero address");

    _trackSupplyBeforeTransfer(from, to, _asSingletonArray(id), _asSingletonArray(amount));

    _beforeTokenTransfer(msg.sender, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    require(balanceOf[from][id] >= amount, "ERC1155: insufficient balance for transfer");
    unchecked {
      balanceOf[from][id] -= amount;
    }
    balanceOf[to][id] += amount;

    emit TransferSingle(msg.sender, from, to, id, amount);
    _checkOnERC1155Received(msg.sender, from, to, id, amount, data);
    _afterTokenTransfer(msg.sender, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
  }

  /// @notice Safe version of the batchTransferFrom function.
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");

    _trackSupplyBeforeTransfer(from, to, ids, amounts);

    _beforeTokenTransfer(msg.sender, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      require(balanceOf[from][ids[i]] >= amounts[i], "ERC1155: insufficient balance for transfer");
      unchecked {
        balanceOf[from][ids[i]] -= amounts[i];
        balanceOf[to][ids[i]] += amounts[i];
      }
    }

    emit TransferBatch(msg.sender, from, to, ids, amounts);
    _checkOnERC1155BatchReceived(msg.sender, from, to, ids, amounts, data);
    _afterTokenTransfer(msg.sender, from, to, ids, amounts, data);
  }

  /// @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");

    _trackSupplyBeforeTransfer(address(0), to, _asSingletonArray(id), _asSingletonArray(amount));

    _beforeTokenTransfer(msg.sender, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

    balanceOf[to][id] += amount;
    emit TransferSingle(msg.sender, address(0), to, id, amount);
    _checkOnERC1155Received(msg.sender, address(0), to, id, amount, data);
    _afterTokenTransfer(msg.sender, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);
  }

  /// @notice Batch version of {mint}.
  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    _trackSupplyBeforeTransfer(address(0), to, ids, amounts);

    _beforeTokenTransfer(msg.sender, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      balanceOf[to][ids[i]] += amounts[i];
    }

    emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    _checkOnERC1155BatchReceived(msg.sender, address(0), to, ids, amounts, data);
    _afterTokenTransfer(msg.sender, address(0), to, ids, amounts, data);
  }

  /// @notice Destroys `amount` tokens of token type `id` from `from`
  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual {
    _trackSupplyBeforeTransfer(from, address(0), _asSingletonArray(id), _asSingletonArray(amount));

    _beforeTokenTransfer(msg.sender, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

    require(balanceOf[from][id] >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      balanceOf[from][id] -= amount;
    }

    emit TransferSingle(msg.sender, from, address(0), id, amount);
    _afterTokenTransfer(msg.sender, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");
  }

  /// @notice Batch version of {burn}.
  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    _trackSupplyBeforeTransfer(from, address(0), ids, amounts);

    _beforeTokenTransfer(msg.sender, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      require(balanceOf[from][ids[i]] >= amounts[i], "ERC1155: burn amount exceeds balance");
      unchecked {
        balanceOf[from][ids[i]] -= amounts[i];
      }
    }

    emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    _afterTokenTransfer(msg.sender, from, address(0), ids, amounts, "");
  }

  /// @notice Approve `operator` to operate on all of `owner` tokens
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC1155: setting approval status for self");
    isApprovedForAll[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /// @notice Hook that is called before any token transfer.
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  /// @notice Hook that is called after any token transfer.
  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  /// @notice Internal helper for tracking token supply before transfers.
  function _trackSupplyBeforeTransfer(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) private {
    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; i++) {
        totalSupply[ids[i]] += amounts[i];
      }
    }

    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; i++) {
        totalSupply[ids[i]] -= amounts[i];
      }
    }
  }

  /// @notice ERC1155Receiver callback checking and calling helper for single transfers.
  function _checkOnERC1155Received(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 returnValue) {
        require(returnValue == 0xf23a6e61, "ERC1155: transfer to non ERC1155Receiver implementer");
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  /// @notice ERC1155Receiver callback checking and calling helper for batch transfers.
  function _checkOnERC1155BatchReceived(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 returnValue) {
        require(returnValue == 0xbc197c81, "ERC1155: transfer to non ERC1155Receiver implementer");
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  /// @notice Helper for single item arrays.
  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }

  /*    ___  _   _  _ _      __   _ __  */
  /*  /',__)( ) ( )( '_`\  /'__`\( '__) */
  /*  \__, \| (_) || (_) )(  ___/| |    */
  /*  (____/`\___/'| ,__/'`\____)(_)    */
  /*               | |                  */
  /*               (_)                  */

  /// @notice See {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId || // ERC1155
      interfaceId == type(IERC1155MetadataURI).interfaceId || // ERC1155MetadataURI
      interfaceId == type(IERC165).interfaceId; // ERC165
  }
}

interface IERC1155Receiver {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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