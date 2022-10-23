// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/INiftyLaunchComics.sol";
import "./interfaces/INiftyEquipment.sol";

contract NiftyBurningComicsL2 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  event ComicsBurned(address indexed by, uint256[] tokenIds, uint256[] values);
  event KeyMinted(address indexed by, uint256 tokenId, uint256 value, uint256 startIdForIMX);
  event ItemMinted(address indexed by, uint256[] tokenIds, uint256[] values, uint256[] startIdForIMX);

  /// @dev NiftyLaunchComics address
  address public comics;

  /// @dev NiftyKeys address
  address public keys;

  /// @dev NiftyItems address
  address public items;

  /// @dev NiftyLaunchComics burning start time
  uint256 public comicsBurningStartAt;

  /// @dev NiftyKeys mint start time
  uint256 public mintNiftyKeysStartAt;

  /// @dev NiftyLaunchComics burning end time
  uint256 public comicsBurningEndAt;

  /// @dev Key start Id for IMX
  /// @dev start from 1
  uint256 public keyStartIdForIMX;

  /// @dev Item start Id for IMX
  /// @dev start from 1
  uint256[] public itemStartIdForIMX;

  function initialize(
    address _comics,
    address _keys,
    address _items,
    uint256 _comicsBurningStartAt
  ) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    comics = _comics;
    keys = _keys;
    items = _items;
    comicsBurningStartAt = _comicsBurningStartAt;
    mintNiftyKeysStartAt = _comicsBurningStartAt + 3600 * 24 * 15; // 15 days period
    comicsBurningEndAt = _comicsBurningStartAt + 3600 * 24 * 30; // 30 days period

    // set the start Id of the key and items
    keyStartIdForIMX = 1;
    for (uint256 i; i < 6; i++) {
      itemStartIdForIMX.push(1);
    }
  }

  /**
   * @notice Burn comics and returns the items associated with its page
   * @dev User can burn all 6 comics at once to receive a key to the citadel
   * @dev Burning comics are available only for 30 days
   * @dev Key should be minted only for the last 15 days out of 30 days
   * @param _values Number of comics to burn, nth value means the number of nth comics(tokenId = n) to burn
   */
  function burnComics(uint256[] calldata _values) external nonReentrant whenNotPaused {
    // check if burning comics is valid
    require(
      comicsBurningStartAt <= block.timestamp && block.timestamp <= comicsBurningEndAt,
      "Burning comics is not valid"
    );

    // check _values param
    require(_values.length == 6, "Invalid length");

    // tokenIds and values to be minted
    uint256[] memory tokenIds = new uint256[](6);
    uint256[] memory tokenNumbersForItems = new uint256[](6);

    bool isForKeys = mintNiftyKeysStartAt < block.timestamp;

    // get tokenIds and the number of keys to mint
    uint256 valueForKeys = isForKeys ? type(uint256).max : 0;
    for (uint256 i; i < _values.length; i++) {
      if (isForKeys) {
        // burning comics for keys
        // get the min value in _values
        if (_values[i] < valueForKeys) valueForKeys = _values[i];
      }
    }

    // in case of the keys should be minted, set the number of items to be minted
    if (valueForKeys != 0) {
      for (uint256 i; i < _values.length; i++) {
        tokenNumbersForItems[i] = _values[i] - valueForKeys;
      }
    }

    // burn comics
    // INiftyLaunchComics(comics).burnBatch(msg.sender, tokenIds, _values);
    emit ComicsBurned(msg.sender, tokenIds, _values);

    // mint the keys and items
    if (valueForKeys != 0) {
      // mint the key and items
      // INiftyEquipment(keys).mint(msg.sender, 1, valueForKeys, "");
      // INiftyEquipment(items).mintBatch(msg.sender, tokenIds, tokenNumbersForItems, "");

      emit KeyMinted(msg.sender, 1, valueForKeys, keyStartIdForIMX);
      emit ItemMinted(msg.sender, tokenIds, tokenNumbersForItems, itemStartIdForIMX);

      keyStartIdForIMX += valueForKeys;
      for (uint256 i; i < 6; i++) {
        itemStartIdForIMX[i] += tokenNumbersForItems[i];
      }
    } else {
      // mint items
      // INiftyEquipment(items).mintBatch(msg.sender, tokenIds, _values, "");

      emit ItemMinted(msg.sender, tokenIds, _values, itemStartIdForIMX);

      for (uint256 i; i < 6; i++) {
        itemStartIdForIMX[i] += tokenNumbersForItems[i];
      }
    }
  }

  /**
   * @notice Pause comics burning
   * @dev Only owner
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause comics burning
   * @dev Only owner
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INiftyEquipment {
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INiftyLaunchComics {
  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) external;
}