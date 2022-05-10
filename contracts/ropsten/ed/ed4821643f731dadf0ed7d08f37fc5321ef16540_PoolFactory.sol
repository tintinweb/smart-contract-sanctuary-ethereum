// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "./IPool.sol";
import "./Aware.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Pool Factory
 *
 * @notice MMC Pool Factory manages Metamars Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_MINTER permission on the MMC token to mint yield
 *      (see `mintYieldTo` function)
 */
contract PoolFactory is OwnableUpgradeable, Aware {
    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like MMC)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for MMC pools, 800 for MMC/ETH pools - set during deployment)
        uint32 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    /**
     * @dev MMC/block determines yield farming reward base
     *      used by the yield pools controlled by the factory
     */
    uint192 public mmcPerBlock;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion
     */
    uint32 public totalWeight;

    /**
     * @dev MMC/block decreases by 3% every blocks/update (set to 91252 blocks during deployment);
     *      an update is triggered by executing `updateMMCPerBlock` public function
     */
    uint32 public blocksPerUpdate;

    /**
     * @dev End block is the last block when MMC/block can be decreased;
     *      it is implied that yield farming stops after that block
     */
    uint32 public endBlock;

    /**
     * @dev Each time the MMC/block ratio gets updated, the block number
     *      when the operation has occurred gets recorded into `lastRatioUpdate`
     * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
     *      has passed when decreasing yield reward by 3%
     */
    uint32 public lastRatioUpdate;

    /// @dev Maps pool token address (like MMC) -> pool address (like core pool instance)
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
    mapping(address => bool) public poolExists;

    /**
     * @dev Fired in createPool() and registerPool()
     *
     * @param _by an address which executed an action
     * @param poolToken pool token address (like MMC)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event PoolRegistered(
        address indexed _by,
        address indexed poolToken,
        address indexed poolAddress,
        uint64 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in changePoolWeight()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event WeightUpdated(address indexed _by, address indexed poolAddress, uint32 weight);

    /**
     * @dev Fired in updateMMCPerBlock()
     *
     * @param _by an address which executed an action
     * @param newMtlPerBlock new MMC/block value
     */
    event MtlRatioUpdated(address indexed _by, uint256 newMtlPerBlock);

    function initialize(
        address _mmc,
        uint192 _mmcPerBlock,
        uint32 _blocksPerUpdate,
        uint32 _initBlock,
        uint32 _endBlock
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        Aware.__Aware_init(_mmc);

        // verify the inputs are set
        require(_mmcPerBlock > 0, "MMC/block not set");
        require(_blocksPerUpdate > 0, "blocks/update not set");
        require(_initBlock > 0, "init block not set");
        require(_endBlock > _initBlock, "invalid end block: must be greater than init block");

        // save the inputs into internal state variables
        mmcPerBlock = _mmcPerBlock;
        blocksPerUpdate = _blocksPerUpdate;
        lastRatioUpdate = _initBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address
     *
     * @dev A shortcut for `pools` mapping
     *
     * @param poolToken pool token address (like MMC) to query pool address for
     * @return pool address for the token specified
     */
    function getPoolAddress(address poolToken) external view returns (address) {
        // read the mapping and return
        return pools[poolToken];
    }

    /**
     * @notice Reads pool information for the pool defined by its pool token address,
     *      designed to simplify integration with the front ends
     *
     * @param _poolToken pool token address to query pool information for
     * @return pool information packed in a PoolData struct
     */
    function getPoolData(address _poolToken) public view returns (PoolData memory) {
        // get the pool address from the mapping
        address poolAddr = pools[_poolToken];

        // throw if there is no pool registered for the token specified
        require(poolAddr != address(0), "pool not found");

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint32 weight = IPool(poolAddr).weight();

        // create the in-memory structure and return it
        return PoolData({ poolToken: poolToken, poolAddress: poolAddr, weight: weight, isFlashPool: isFlashPool });
    }

    /**
     * @dev Verifies if `blocksPerUpdate` has passed since last MMC/block
     *      ratio update and if MMC/block reward can be decreased by 3%
     *
     * @return true if enough time has passed and `updateMMCPerBlock` can be executed
     */
    function shouldUpdateRatio() public view returns (bool) {
        // if yield farming period has ended
        if (block.number > endBlock) {
            // MMC/block reward cannot be updated anymore
            return false;
        }

        // check if blocks/update (91252 blocks) have passed since last update
        return block.number >= lastRatioUpdate + blocksPerUpdate;
    }

    /**
     * @dev Registers an already deployed pool instance within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolAddr address of the already deployed pool instance
     */
    function registerPool(address poolAddr) public onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint32 weight = IPool(poolAddr).weight();

        // ensure that the pool is not already registered within the factory
        require(pools[poolToken] == address(0), "this pool is already registered");

        // create pool structure, register it within the factory
        pools[poolToken] = poolAddr;
        poolExists[poolAddr] = true;
        // update total pool weight of the factory
        totalWeight += weight;

        // emit an event
        emit PoolRegistered(msg.sender, poolToken, poolAddr, weight, isFlashPool);
    }

    /**
     * @notice Decreases MMC/block reward by 3%, can be executed
     *      no more than once per `blocksPerUpdate` blocks
     */
    function updateMMCPerBlock() external {
        // checks if ratio can be updated i.e. if blocks/update (91252 blocks) have passed
        require(shouldUpdateRatio(), "too frequent");

        // decreases MMC/block reward by 3%
        mmcPerBlock = (mmcPerBlock * 97) / 100;

        // set current block as the last ratio update block
        lastRatioUpdate = uint32(block.number);

        // emit an event
        emit MtlRatioUpdated(msg.sender, mmcPerBlock);
    }

    /**
     * @dev Mints MMC tokens; executed by MMC Pool only
     *
     * @dev Requires factory to have ROLE_TOKEN_MINTER permission
     *      on the MMC ERC20 token instance
     *
     * @param _to an address to mint tokens to
     * @param _amount amount of MMC tokens to mint
     */
    function mintYieldTo(address _to, uint256 _amount) external {
        // verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "access denied");

        // mint MMC tokens as required
        mintMtc(_to, _amount);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner
     *
     * @param poolAddr address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address poolAddr, uint32 weight) external {
        // verify function is executed either by factory owner or by the pool itself
        require(msg.sender == owner() || poolExists[msg.sender]);

        // recalculate total weight
        totalWeight = totalWeight + weight - IPool(poolAddr).weight();

        // set the new pool weight
        IPool(poolAddr).setWeight(weight);

        // emit an event
        emit WeightUpdated(msg.sender, poolAddr, weight);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IMetamarsToken is IERC20Upgradeable {
    function mint(address _to, uint256 _value) external;
    function burn(uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

/**
 * @title Metamars Pool
 *
 * @notice An abstraction representing a pool, see MetamarsPoolBase for details
   */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
    }

    // for the rest of the functions see Soldoc in MetamarsPoolBase

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function pendingYieldRewards(address _user) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function stake(
        uint256 _amount,
        uint64 _lockedUntil
    ) external;

    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external;

    function sync() external;

    function processRewards() external;

    function setWeight(uint32 _weight) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../token/IMetamarsToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Metamars Aware
 *
 * @notice Helper smart contract to be inherited by other smart contracts requiring to
 *      be linked to verified Metamars Token instance and performing some basic tasks on it
 */
abstract contract Aware is Initializable  {
  /// @dev Link to MMC ERC20 Token Metamars Token instance
  address public mmc;

  function __Aware_init(address _mmc) internal onlyInitializing {
    // verify MMC address is set and is correct
    require(_mmc != address(0), "MMC address not set");

    // write MMC address
    mmc = _mmc;
  }

  /**
   * @dev Executes MetamarsToken.safeTransferFrom(address(this), _to, _value, "")
   *      on the bound Metamars Token instance
   *
   * @dev Reentrancy safe due to the Metamars Token design
   */
  function transferMtl(address _to, uint256 _value) internal {
    // just delegate call to the target
    transferMtlFrom(address(this), _to, _value);
  }

  /**
   * @dev Executes MetamarsToken.transferFrom(_from, _to, _value)
   *      on the bound MetamarsToken instance
   *
   * @dev Reentrancy safe due to the MetamarsToken design
   */
  function transferMtlFrom(address _from, address _to, uint256 _value) internal {
    // just delegate call to the target
    IMetamarsToken(mmc).transferFrom(_from, _to, _value);
  }

  /**
   * @dev Executes MetamarsToken.mint(_to, _values)
   *      on the bound MetamarsToken instance
   *
   * @dev Reentrancy safe due to the MetamarsToken design
   */
  function mintMtc(address _to, uint256 _value) internal {
    // just delegate call to the target
    IMetamarsToken(mmc).mint(_to, _value);
  }

  /**
   * @dev Executes MetamarsToken.burn(_values)
   *      on the bound MetamarsToken instance
   *
   * @dev Reentrancy safe due to the MetamarsToken design
   */
  function burnMtc(uint256 _value) internal {
    // just delegate call to the target
    IMetamarsToken(mmc).burn(_value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

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

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}