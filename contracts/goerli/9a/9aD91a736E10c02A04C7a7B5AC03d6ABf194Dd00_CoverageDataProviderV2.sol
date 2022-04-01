// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/risk/ICoverageDataProviderV2.sol";
import "../interfaces/utils/IRegistry.sol";
import "../interfaces/ISOLACE.sol";
import "../utils/Governable.sol";

/**
 * @title  CoverageDataProviderV2
 * @author solace.fi
 * @notice Holds underwriting pool amounts in `USD`. Provides information to the [**Risk Manager**](./RiskManager.sol) that is the maximum amount of cover that `Solace` protocol can sell as a coverage.
*/
contract CoverageDataProviderV2 is ICoverageDataProviderV2, Governable, ReentrancyGuard {

    /***************************************
     STATE VARIABLES
    ***************************************/

    /// @notice The balance of underwriting pool in usd.
    mapping(string => uint256) private _uwpBalanceOf;

    /// @notice The index to underwriting pool.
    mapping(uint256 => string) private _indexToUwp;

    /// @notice The underwriting pool to index.
    mapping(string => uint256) private _uwpToIndex;

    /// @notice The underwriting pool updaters.
    mapping(address => bool) public updaters;

    /// @notice The underwriting pool count
    uint256 public numOfPools;


    /***************************************
     MODIFIERS FUNCTIONS
    ***************************************/
    
    modifier canUpdate() {
      require(msg.sender == super.governance() || updaters[msg.sender], "!governance");
      _;
    }

    /**
     * @notice Constructs the `CoverageDataProviderV2` contract.
     * @param _governance The address of the [governor](/docs/protocol/governance).
    */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _governance) Governable(_governance) {}

    /***************************************
     MUTUATOR FUNCTIONS
    ***************************************/
   
    /**
      * @notice Resets the underwriting pool balances.
      * @param _uwpNames The underwriting pool values to set.
      * @param _amounts The underwriting pool balances in `USD`.
    */
    function set(string[] calldata _uwpNames, uint256[] calldata _amounts) external override nonReentrant canUpdate {
      require(_uwpNames.length == _amounts.length, "length mismatch");
      _set(_uwpNames, _amounts);
    }

    /**
     * @notice Removes the given underwriting pool.
     * @param uwpNames The underwriting pool names to remove.
    */
    function remove(string[] calldata uwpNames) external override canUpdate {
      _remove(uwpNames);
    }

    /***************************************
     VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the maximum amount of cover in `USD` that Solace as a whole can sell.
     * @return cover The max amount of cover in `USD`.
    */
    function maxCover() external view override returns (uint256 cover) {
      // get pool balance
      uint256 pools = numOfPools;
      for (uint256 i = pools; i > 0; i--) {
        cover += balanceOf(_indexToUwp[i]);
      }
    }
   
    /**
     * @notice Returns the balance of the underwriting pool in `USD`.
     * @param uwpName The underwriting pool name to get balance.
     * @return amount The balance of the underwriting pool in `USD`.
    */
    function balanceOf(string memory uwpName) public view override returns (uint256 amount) {
      return _uwpBalanceOf[uwpName];
    }

    /**
     * @notice Returns underwriting pool name for given index.
     * @param index The underwriting pool index to get.
     * @return uwpName The underwriting pool name.
    */
    function poolOf(uint256 index) external view override returns (string memory uwpName) {
      return _indexToUwp[index];
    }

    /***************************************
     INTERNAL FUNCTIONS
    ***************************************/

    /**
      * @notice Resets the underwriting pool balances.
      * @param uwpNames The underwriting pool values to set.
      * @param amounts The underwriting pool balances in `USD`.
    */
    function _set(string[] memory uwpNames, uint256[] memory amounts) internal {
      // delete current underwriting pools
      uint256 poolCount = numOfPools;
      string memory uwpName;

      for (uint256 i = poolCount; i > 0; i--) {
        uwpName = _indexToUwp[i];
        delete _uwpToIndex[uwpName];
        delete _indexToUwp[i];
        delete _uwpBalanceOf[uwpName];
        emit UnderwritingPoolRemoved(uwpName);
      }

      // set new underwriting pools
      numOfPools = 0;
      uint256 amount;
      for (uint256 i = 0; i < uwpNames.length; i++) {
        uwpName = uwpNames[i];
        amount = amounts[i];
        require(bytes(uwpName).length > 0, "empty underwriting pool name");
        
        _uwpBalanceOf[uwpName] = amount;
        if (_uwpToIndex[uwpName] == 0) {
          uint256 index = numOfPools;
          _uwpToIndex[uwpName] = ++index;
          _indexToUwp[index] = uwpName;
          numOfPools = index;
        }
        emit UnderwritingPoolSet(uwpName, amount);
      }
    }

    /**
     * @notice Removes the given underwriting pool.
     * @param uwpNames The underwriting pool names to remove.
    */
    function _remove(string[] memory uwpNames) internal {
      string memory uwpName;

      for (uint256 i = 0; i < uwpNames.length; i++) {
        uwpName = uwpNames[i];
        uint256 index = _uwpToIndex[uwpName];
        if (index == 0) return;

        uint256 poolCount = numOfPools;
        if (poolCount == 0) return;

        if (index != poolCount) {
          string memory lastPool = _indexToUwp[poolCount];
          _uwpToIndex[lastPool] = index;
          _indexToUwp[index] = lastPool;
        }

        delete _uwpToIndex[uwpName];
        delete _indexToUwp[poolCount];
        delete _uwpBalanceOf[uwpName];
        numOfPools -= 1;
        emit UnderwritingPoolRemoved(uwpName);
      }
    }
  

    /***************************************
     GOVERNANCE FUNCTIONS
    ***************************************/
    
    /**
     * @notice Sets the underwriting pool bot updater.
     * @param updater The bot address to set.
    */
    function addUpdater(address updater) external override onlyGovernance {
      require(updater != address(0x0), "zero address uwp updater");
      updaters[updater] = true;
      emit UwpUpdaterSet(updater);
    }

    /**
     * @notice Sets the underwriting pool bot updater.
     * @param updater The bot address to set.
    */
    function removeUpdater(address updater) external override onlyGovernance {
      updaters[updater] = false;
      emit UwpUpdaterRemoved(updater);
    }
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title ICoverageDataProviderV2
 * @author solace.fi
 * @notice Holds underwriting pool amounts in `USD`. Provides information to the [**Risk Manager**](./RiskManager.sol) that is the maximum amount of cover that `Solace` protocol can sell as a coverage.
*/
interface ICoverageDataProviderV2 {
  
    /***************************************
     EVENTS
    ***************************************/

    /// @notice Emitted when the underwriting pool is set.
    event UnderwritingPoolSet(string uwpName, uint256 amount);

    /// @notice Emitted when underwriting pool is removed.
    event UnderwritingPoolRemoved(string uwpName);

    /// @notice Emitted when underwriting pool updater is set.
    event UwpUpdaterSet(address uwpUpdater);

    /// @notice Emitted when underwriting pool updater is removed.
    event UwpUpdaterRemoved(address uwpUpdater);

    /***************************************
     MUTUATOR FUNCTIONS
    ***************************************/

    /**
      * @notice Resets the underwriting pool balances.
      * @param uwpNames The underwriting pool values to set.
      * @param amounts The underwriting pool balances.
    */
    function set(string[] calldata uwpNames, uint256[] calldata amounts) external;

    /**
     * @notice Removes the given underwriting pool.
     * @param uwpNames The underwriting pool names to remove.
    */
    function remove(string[] calldata uwpNames) external;

    /***************************************
     VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The maximum amount of cover in `USD` that Solace as a whole can sell.
     * @return cover The max amount of cover in `USD`.
    */
    function maxCover() external view returns (uint256 cover);

    /**
     * @notice Returns the balance of the underwriting pool in `USD`.
     * @param uwpName The underwriting pool name to get balance.
     * @return amount The balance of the underwriting pool in `USD`.
    */
    function balanceOf(string memory uwpName) external view returns (uint256 amount); 

    /**
     * @notice Returns underwriting pool name for given index.
     * @param index The underwriting pool index to get.
     * @return uwpName The underwriting pool name.
    */
    function poolOf(uint256 index) external view returns (string memory uwpName);

    /***************************************
     GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the underwriting pool bot updater.
     * @param updater The bot address to set.
    */
    function addUpdater(address updater) external;

    /**
     * @notice Sets the underwriting pool bot updater.
     * @param updater The bot address to set.
    */
    function removeUpdater(address updater) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * A key is a unique identifier for each contract. Use [`get(key)`](#get) or [`tryGet(key)`](#tryget) to get the address of the contract. Enumerate the keys with [`length()`](#length) and [`getKey(index)`](#getkey).
 */
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a record is set.
    event RecordSet(string indexed key, address indexed value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice The number of unique keys.
    function length() external view returns (uint256);

    /**
     * @notice Gets the `value` of a given `key`.
     * Reverts if the key is not in the mapping.
     * @param key The key to query.
     * @param value The value of the key.
     */
    function get(string calldata key) external view returns (address value);

    /**
     * @notice Gets the `value` of a given `key`.
     * Fails gracefully if the key is not in the mapping.
     * @param key The key to query.
     * @param success True if the key was found, false otherwise.
     * @param value The value of the key or zero if it was not found.
     */
    function tryGet(string calldata key) external view returns (bool success, address value);

    /**
     * @notice Gets the `key` of a given `index`.
     * @dev Iterable [1,length].
     * @param index The index to query.
     * @return key The key at that index.
     */
    function getKey(uint256 index) external view returns (string memory key);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets keys and values.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param keys The keys to set.
     * @param values The values to set.
     */
    function set(string[] calldata keys, address[] calldata values) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Solace Token (SOLACE)
 * @author solace.fi
 * @notice The native governance token of the Solace Coverage Protocol.
 */
interface ISOLACE is IERC20Metadata {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a minter is added.
    event MinterAdded(address indexed minter);
    /// @notice Emitted when a minter is removed.
    event MinterRemoved(address indexed minter);

    /***************************************
    MINT FUNCTIONS
    ***************************************/

    /**
     * @notice Returns true if `account` is authorized to mint [**SOLACE**](../SOLACE).
     * @param account Account to query.
     * @return status True if `account` can mint, false otherwise.
     */
    function isMinter(address account) external view returns (bool status);

    /**
     * @notice Mints new [**SOLACE**](../SOLACE) to the receiver account.
     * Can only be called by authorized minters.
     * @param account The receiver of new tokens.
     * @param amount The number of new tokens.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Burns [**SOLACE**](../SOLACE) from msg.sender.
     * @param amount Amount to burn.
     */
    function burn(uint256 amount) external;

    /**
     * @notice Adds a new minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The new minter.
     */
    function addMinter(address minter) external;

    /**
     * @notice Removes a minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The minter to remove.
     */
    function removeMinter(address minter) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../interfaces/utils/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./../interfaces/utils/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() public view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}