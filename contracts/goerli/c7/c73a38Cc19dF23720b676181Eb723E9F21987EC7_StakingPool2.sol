// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool2.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract StakingPool2 is IStakingPool2, Ownable, Initializable {
    struct RewardState {
        uint256 index;
        uint256 timestamp;
    }

    struct FixedDeposit {
        uint256 amount;
        uint256 shares;
    }

    uint256 public constant ONE_YEAR = 365 * 24 * 3600;
    uint256 public constant INDEX_SCALE = 1e36;
    uint256 public constant EXPIRE_MAPPING_HEAD = uint256(1);

    uint256 public override rewardsPerSecond;
    uint256 public override endTime;
    uint256 public override minPeriod;
    uint256 public override totalShares;

    address public override stakeToken;
    address public override rewardToken;

    RewardState public override poolRewardState;

    mapping(address => uint256) public override getUserShares;
    mapping(address => uint256) public override getUserIndex;
    mapping(address => uint256) public override getUserCurrentDeposit;
    mapping(address => uint256) public override getUserRewardAccrued;

    mapping(address => mapping(uint256 => uint256)) public getUserNextExpireAt;
    mapping(address => mapping(uint256 => FixedDeposit)) public getUserFixedDeposit;

    function initialize(
        address _owner,
        address _stakeToken,
        address _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _endTime,
        uint256 _minPeriod
    ) external initializer {
        owner = _owner;
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        rewardsPerSecond = _rewardPerSecond;
        endTime = _endTime;
        minPeriod = _minPeriod;
        poolRewardState = RewardState(INDEX_SCALE, block.timestamp);
    }

    function updateRewardsPerSecond(uint256 newRewardsPerSecond) external onlyOwner {
        emit RewardsPerSecondUpdated(rewardsPerSecond, newRewardsPerSecond);
        rewardsPerSecond = newRewardsPerSecond;
    }

    function updateEndTime(uint256 newEndTime) external onlyOwner {
        emit EndTimeUpdated(endTime, newEndTime);
        endTime = newEndTime;
    }

    function updateMinPeriod(uint256 newMinPeriod) external onlyOwner {
        emit MinPeriodUpdated(minPeriod, newMinPeriod);
        minPeriod = newMinPeriod;
    }

    function rewardClaimable(address user) public view override returns (uint256) {
        uint256 poolIndex;
        uint256 deltaTime = block.timestamp - poolRewardState.timestamp;
        if (deltaTime > 0 && rewardsPerSecond > 0) {
            uint256 rewardsAccrued = deltaTime * rewardsPerSecond;
            uint256 ratio = totalShares > 0 ? (rewardsAccrued * INDEX_SCALE) / totalShares : 0;
            poolIndex = poolRewardState.index + ratio;
        }

        uint256 userIndex = getUserIndex[user];
        if (userIndex == 0 && poolIndex >= INDEX_SCALE) {
            userIndex = INDEX_SCALE;
        }

        uint256 deltaIndex = poolIndex - userIndex;
        uint256 userShares = getUserShares[user];
        uint256 userRewardDelta = (deltaIndex * userShares) / INDEX_SCALE;
        return getUserRewardAccrued[user] + userRewardDelta;
    }

    function withdrawable(address user) public view override returns (uint256) {
        uint256 _addToCurrent;
        uint256 currentTime = block.timestamp;
        uint256 next = getUserNextExpireAt[msg.sender][EXPIRE_MAPPING_HEAD];
        while (next < currentTime && next > 0) {
            _addToCurrent += getUserFixedDeposit[user][next].amount;
            next = getUserNextExpireAt[msg.sender][next];
        }

        return getUserCurrentDeposit[user] + _addToCurrent;
    }

    function currentDeposit(uint256 amount) external override {
        require(amount > 0, "zero amount");

        _updatePoolRewardIndex();
        _distributeUserReward(msg.sender);
        _updateExpiredFixedsToCurrent(msg.sender);

        TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), amount);
        _mintShares(msg.sender, amount);
        getUserCurrentDeposit[msg.sender] += amount;
        emit Deposited(msg.sender, amount, amount, 0, 0);
    }

    function fixedDeposit(uint256 amount, uint256 period, uint256 preExpireAt) external override {
        require(amount > 0, "zero amount");
        require(period >= minPeriod, "period less than min period");
        require(preExpireAt > 0, "zero preExpireAt");

        uint256 expireAt = block.timestamp + period;
        require(expireAt <= endTime, "expireAt over endTime");
        require(expireAt > preExpireAt, "expireAt not after preExpireAt");

        _updatePoolRewardIndex();
        _distributeUserReward(msg.sender);
        _updateExpiredFixedsToCurrent(msg.sender);

        TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), amount);
        uint256 shares = amount + (amount * 3 * period) / ONE_YEAR;
        _mintShares(msg.sender, shares);

        getUserFixedDeposit[msg.sender][expireAt] = FixedDeposit(amount, shares);
        uint256 first = getUserNextExpireAt[msg.sender][EXPIRE_MAPPING_HEAD];
        if (first == 0) {
            getUserNextExpireAt[msg.sender][EXPIRE_MAPPING_HEAD] = expireAt;
        } else {
            if (preExpireAt == EXPIRE_MAPPING_HEAD) {
                require(expireAt < first, "expireAt not before first");
                getUserNextExpireAt[msg.sender][EXPIRE_MAPPING_HEAD] = expireAt;
                getUserNextExpireAt[msg.sender][expireAt] = first;
            } else {
                require(getUserFixedDeposit[msg.sender][preExpireAt].amount > 0, "invalid preExpireAt");
                uint256 next = getUserNextExpireAt[msg.sender][preExpireAt];
                if (next > 0) require(expireAt < next, "expireAt not before next");
                getUserNextExpireAt[msg.sender][preExpireAt] = expireAt;
                if (next > 0) getUserNextExpireAt[msg.sender][expireAt] = next;
            }
        }

        emit Deposited(msg.sender, amount, shares, period, expireAt);
    }

    function withdraw(address to, uint256 amount) external override {
        _updatePoolRewardIndex();
        _distributeUserReward(msg.sender);
        _updateExpiredFixedsToCurrent(msg.sender);

        require(amount <= getUserCurrentDeposit[msg.sender], "over withdrawable");
        _burnShares(msg.sender, amount);
        getUserCurrentDeposit[msg.sender] -= amount;

        TransferHelper.safeTransfer(stakeToken, to, amount);
        emit Withdrawn(msg.sender, to, amount);
    }

    function claimReward(address to) external override returns (uint256 claimed) {
        _updatePoolRewardIndex();
        _distributeUserReward(msg.sender);
        _updateExpiredFixedsToCurrent(msg.sender);

        claimed = getUserRewardAccrued[msg.sender];
        getUserRewardAccrued[msg.sender] = 0;

        TransferHelper.safeTransfer(rewardToken, to, claimed);
        emit RewardClaimed(msg.sender, to, claimed);
    }

    function _updatePoolRewardIndex() internal {
        uint256 deltaTime = block.timestamp - poolRewardState.timestamp;
        if (deltaTime > 0 && rewardsPerSecond > 0) {
            uint256 rewardsAccrued = deltaTime * rewardsPerSecond;
            uint256 ratio = totalShares > 0 ? (rewardsAccrued * INDEX_SCALE) / totalShares : 0;
            poolRewardState.index = poolRewardState.index + ratio;
            poolRewardState.timestamp = block.timestamp;
        } else if (deltaTime > 0) {
            poolRewardState.timestamp = block.timestamp;
        }
    }

    function _distributeUserReward(address user) internal {
        uint256 poolIndex = poolRewardState.index;
        uint256 userIndex = getUserIndex[user];
        // Update user's index to the current pool index
        getUserIndex[user] = poolIndex;

        if (userIndex == 0 && poolIndex >= INDEX_SCALE) {
            userIndex = INDEX_SCALE;
        }

        uint256 deltaIndex = poolIndex - userIndex;
        uint256 userShares = getUserShares[user];
        uint256 userRewardDelta = (deltaIndex * userShares) / INDEX_SCALE;
        getUserRewardAccrued[user] += userRewardDelta;

        emit DistributedUserReward(user, userRewardDelta, poolIndex);
    }

    function _updateExpiredFixedsToCurrent(address user) internal {
        FixedDeposit memory _fixed;
        uint256 _addToCurrent;
        uint256 _sharesToBurn;
        uint256 currentTime = block.timestamp;
        uint256 next = getUserNextExpireAt[user][EXPIRE_MAPPING_HEAD];
        uint256 _temp;
        while (next < currentTime && next > 0) {
            _fixed = getUserFixedDeposit[user][next];
            _addToCurrent += _fixed.amount;
            _sharesToBurn += _fixed.shares - _fixed.amount;
            delete getUserFixedDeposit[user][next];

            _temp = next;
            next = getUserNextExpireAt[user][next];
            delete getUserNextExpireAt[user][_temp];
        }

        if (getUserNextExpireAt[user][EXPIRE_MAPPING_HEAD] != next)
            getUserNextExpireAt[user][EXPIRE_MAPPING_HEAD] = next;
        if (_addToCurrent > 0) getUserCurrentDeposit[user] += _addToCurrent;
        if (_sharesToBurn > 0) _burnShares(user, _sharesToBurn);
    }

    function _mintShares(address user, uint256 shares) internal {
        totalShares += shares;
        getUserShares[user] += shares;
        emit SharesTransferred(address(0), user, shares);
    }

    function _burnShares(address user, uint256 shares) internal {
        require(getUserShares[user] >= shares, "not enough shares to be burnt");
        totalShares -= shares;
        getUserShares[user] -= shares;
        emit SharesTransferred(user, address(0), shares);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPool2 {
    event Deposited(address indexed user, uint256 amount, uint256 shares, uint256 period, uint256 expireAt);
    event Withdrawn(address indexed user, address indexed to, uint256 amount);
    event RewardClaimed(address indexed user, address indexed to, uint256 claimed);
    event SharesTransferred(address indexed from, address indexed to, uint256 amount);
    event RewardsPerSecondUpdated(uint256 oldRewards, uint256 newRewards);
    event EndTimeUpdated(uint256 oldEndTime, uint256 newEndTime);
    event MinPeriodUpdated(uint256 oldMinPeriod, uint256 newMinPeriod);
    event DistributedUserReward(address indexed user, uint256 userRewardDelta, uint256 poolRewardIndex);

    function stakeToken() external view returns (address);

    function rewardToken() external view returns (address);

    function rewardsPerSecond() external view returns (uint256);

    function endTime() external view returns (uint256);

    function minPeriod() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function poolRewardState() external view returns (uint256 index, uint256 timestamp);

    function getUserIndex(address user) external view returns (uint256);

    function getUserShares(address user) external view returns (uint256);

    function getUserCurrentDeposit(address user) external view returns (uint256);

    function getUserRewardAccrued(address user) external view returns (uint256);

    function rewardClaimable(address user) external view returns (uint256);

    function withdrawable(address user) external view returns (uint256);

    function currentDeposit(uint256 amount) external;

    function fixedDeposit(uint256 amount, uint256 period, uint256 preExpireAt) external;

    function withdraw(address to, uint256 amount) external;

    function claimReward(address to) external returns (uint256 claimed);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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