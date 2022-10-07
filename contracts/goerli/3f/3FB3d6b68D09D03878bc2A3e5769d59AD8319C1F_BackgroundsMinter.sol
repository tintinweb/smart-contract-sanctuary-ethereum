// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBackgrounds.sol";
import "../interfaces/ICurrency.sol";
import "../Error.sol";

contract BackgroundsMinter is Ownable, Pausable {
  struct Background {
    uint256 id;
    uint256 price;
  }

  IBackgrounds public backgroundsContract;
  ICurrency public currency;
  Background[] public backgrounds;
  uint256 public backgroundsAmount = 10; // Initial amount of backgrounds
  mapping(uint256 => uint256) public supplies;

  constructor(
    address _backgroundsAddress,
    address _currencyAddress,
    uint256[] memory _prices,
    uint256[] memory _maxSupplies
  ) {
    if (_prices.length != backgroundsAmount) revert InvalidArrayLength();
    if (_maxSupplies.length != backgroundsAmount) revert InvalidArrayLength();

    backgroundsContract = IBackgrounds(_backgroundsAddress);
    currency = ICurrency(_currencyAddress);

    // Prices are in Currency token
    for (uint256 i = 0; i < backgroundsAmount; i++) {
      backgrounds.push(Background(i, _prices[i]));
      supplies[i] = _maxSupplies[i];
    }

    super._pause();
  }

  /**
   * @dev Purchases a Background id with Currency tokens
   * @param _to account to which the tokens are minted
   * @param _id token identifier
   * @param _amount amount of tokens to mint
   * @notice Initially the caller should give allowance to this
   * contract to transfer the tokens.
   */
  function purchase(
    address _to,
    uint256 _id,
    uint256 _amount
  ) external whenNotPaused {
    if (_amount == 0) revert InvalidAmount();
    if (_id >= backgroundsAmount) revert InvalidID();
    if (_to == address(0)) revert InvalidAddress();
    if (supplies[_id] - _amount <= 0) revert NotEnoughSupplies();
    currency.burnFrom(msg.sender, backgrounds[_id].price * _amount);

    backgroundsContract.mint(_to, _id, _amount);

    supplies[_id] -= _amount;
  }

  /**
   * @dev Withdraw an amount of the Currency balance on this contract
   * @param _to account to which the tokens are minted
   * @param _amount amount of tokens to mint
   */
  function withdraw(address _to, uint256 _amount) external onlyOwner {
    if (_amount == 0) revert InvalidAmount();
    if (_to == address(0)) revert InvalidAddress();

    currency.transfer(_to, _amount);
  }

  /**
   * @dev Sets the price of a particular token
   * @param _id token identifier
   * @param _price price to set
   */
  function setPrice(uint256 _id, uint256 _price) external onlyOwner {
    backgrounds[_id].price = _price;
  }

  /**
   * @dev Sets the prices of some tokens
   * @param _ids token identifiers
   * @param _prices prices of each identifier
   * @notice The `_ids` and `_prices` should have the same length
   */
  function setPriceBatch(uint256[] calldata _ids, uint256[] calldata _prices)
    external
    onlyOwner
  {
    if (_ids.length != _prices.length) revert InvalidArrayLength();

    for (uint256 i = 0; i < _ids.length; i++) {
      backgrounds[_ids[i]].price = _prices[i];
    }
  }

  /**
   * @dev Increases the total of backgrounds by _addNewBackgrounds
   * @param _addNewBackgrounds the amount of background types to add
   * @param _maxSupplies the maximum ammount of each new type of backgrounds
   */
  function increaseBackgroundsAmount(
    uint256 _addNewBackgrounds,
    uint256[] calldata _newPrices,
    uint256[] calldata _maxSupplies
  ) external onlyOwner {
    if (_maxSupplies.length != _addNewBackgrounds) revert InvalidArrayLength();

    for (uint256 i = 0; i < _addNewBackgrounds; i++) {
      backgrounds.push(Background(i + backgroundsAmount, _newPrices[i]));
      supplies[i + backgroundsAmount] = _maxSupplies[i];
    }

    backgroundsContract.increaseBackgroundsAmount(_addNewBackgrounds);

    backgroundsAmount += _addNewBackgrounds;
  }

  /**
   * @dev Increases the remaining supply of a type of background
   * @param _id the background to add supply to
   * @param _extraSupply the amount of extra supply to add
   */
  function addBackgroundSupply(uint256 _id, uint256 _extraSupply)
    external
    onlyOwner
  {
    supplies[_id] += _extraSupply;
  }

  /**
   * @dev Increases the remaining supply of a bunch of backgrounds
   * @param _id the backgrounds to add supplies to
   * @param _extraSupply the amount of extra supplies to add to each background
   */
  function addBackgroundSupplyBatch(
    uint256[] calldata _id,
    uint256[] calldata _extraSupply
  ) external onlyOwner {
    if (_id.length != _extraSupply.length) revert InvalidArrayLength();

    for (uint256 i = 0; i < _id.length; i++) {
      supplies[_id[i]] += _extraSupply[i];
    }
  }

  /**
   * @dev pause some contract function with `whenNotPaused` modifier
   */
  function pause() external onlyOwner {
    super._pause();
  }

  /**
   * @dev unpause some contract function with `whenNotPaused` modifier
   */
  function unpause() external onlyOwner {
    super._unpause();
  }

  /**
   * @dev Sets the backgrounds contract address
   * @param _backgroundsAddress the address of the background contract
   */
  function setBackgrounds(address _backgroundsAddress) external onlyOwner {
    backgroundsContract = IBackgrounds(_backgroundsAddress);
  }

  /**
   * @dev Sets the currency contract address
   * @param _currencyAddress the address of the currency contract
   */
  function setCurrency(address _currencyAddress) external onlyOwner {
    currency = ICurrency(_currencyAddress);
  }

  /**
   * @dev Gets the backgrounds ids and prices
   */
  function getBackgrounds() external view returns (Background[] memory) {
    return backgrounds;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBackgrounds is IERC1155 {
  function mint(
    address _to,
    uint256 _id,
    uint256 _amount
  ) external;

  function increaseBackgroundsAmount(uint256 _addNewBackgrounds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurrency is IERC20 {
  function mint(address _account, uint256 _amount) external;

  function burnFrom(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

error Unauthorized();

error InvalidAddress();

error InvalidAmount();

error InvalidID();

error InvalidArrayLength();

error NoMinterRole();

error NFTOwnerOnly();

error NFTNotExist();

error NothingToReward();

error NoChangeToTheState();

error NotEnoughETH();

error NotEnoughAllowance();

error InvalidSignature();

error ExpiredSignature();

error ReplayedSignature();

error FunctionDisabled();

error NotEnoughFunds();

error NotEnoughSupplies();

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}