// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// interfaces
import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IAllocator.sol";
import "./interfaces/ITreasuryExtender.sol";

import "./types/SpaceAccessControlled.sol";
import "./types/SafeERC20.sol";

error TreasuryExtender_AllocatorOffline();
error TreasuryExtender_AllocatorNotActivated();
error TreasuryExtender_AllocatorNotOffline();
error TreasuryExtender_AllocatorRegistered(uint256 id);
error TreasuryExtender_OnlyAllocator(uint256 id, address sender);
error TreasuryExtender_MaxAllocation(uint256 allocated, uint256 limit);

contract TreasuryExtender is SpaceAccessControlled, ITreasuryExtender {
    using SafeERC20 for IERC20;

    ITreasury public immutable treasury;
    IAllocator[] public allocators;

    mapping(IAllocator => mapping(uint256 => AllocatorData)) public allocatorData;

    constructor(address treasuryAddress, address authorityAddress)
        SpaceAccessControlled(ISpaceAuthority(authorityAddress))
    {
		require(treasuryAddress != address(0), "TreasuryExtender: bad treasury");
        treasury = ITreasury(treasuryAddress);
        allocators.push(IAllocator(address(0)));
    }

    function _allocatorActivated(AllocatorStatus status) internal pure {
        if (AllocatorStatus.ACTIVATED != status) revert TreasuryExtender_AllocatorNotActivated();
    }

    function _allocatorOffline(AllocatorStatus status) internal pure {
        if (AllocatorStatus.OFFLINE != status) revert TreasuryExtender_AllocatorNotOffline();
    }

    function _onlyAllocator(
        IAllocator byStatedId,
        address sender,
        uint256 id
    ) internal pure {
        if (IAllocator(sender) != byStatedId) revert TreasuryExtender_OnlyAllocator(id, sender);
    }

    function registerDeposit(address newAllocator) external override onlyGovernor {
		require(newAllocator != address(0), "TreasuryExtender: zero address");
        IAllocator allocator = IAllocator(newAllocator);
        allocators.push(allocator);

        uint256 id = allocators.length - 1;

        allocator.addId(id);

        emit NewDepositRegistered(newAllocator, address(allocator.tokens()[allocator.tokenIds(id)]), id);
    }

    function setAllocatorLimits(
		uint256 id, 
		AllocatorLimits calldata limits
	) external override onlyGovernor {
        IAllocator allocator = allocators[id];
        _allocatorOffline(allocator.status());
        allocatorData[allocator][id].limits = limits;

        emit AllocatorLimitsChanged(id, limits.allocated, limits.loss);
    }

    function report(uint256 id, uint128 gain, uint128 loss) external override {
        IAllocator allocator = allocators[id];
        AllocatorData storage data = allocatorData[allocator][id];
        AllocatorPerformance memory perf = data.performance;
        AllocatorStatus status = allocator.status();

        _onlyAllocator(allocator, msg.sender, id);
        if (status == AllocatorStatus.OFFLINE) revert TreasuryExtender_AllocatorOffline();

        if (gain >= loss) {
            if (loss == type(uint128).max) {
                AllocatorData storage newAllocatorData =
					allocatorData[allocators[allocators.length - 1]][id];

                newAllocatorData.holdings.allocated = data.holdings.allocated;
                newAllocatorData.performance.gain = data.performance.gain;
                data.holdings.allocated = 0;

                perf.gain = 0;
                perf.loss = 0;

                emit AllocatorReportedMigration(id);
            
			} else {
                perf.gain += gain;

                emit AllocatorReportedGain(id, gain);
            }

        } else {
            data.holdings.allocated -= loss;
            perf.loss += loss;

            emit AllocatorReportedLoss(id, loss);
        }

        data.performance = perf;
    }

    function requestFundsFromTreasury(
		uint256 id, 
		uint256 amount, 
		uint256 tokenId
	) external override onlyGovernor {
        IAllocator allocator = allocators[id];
        AllocatorData memory data = allocatorData[allocator][id];
        address token = address(allocator.tokens()[allocator.tokenIds(id)]);

        _allocatorActivated(allocator.status());
        _allocatorBelowLimit(data, amount);

        treasury.manage(token, amount, tokenId);
        allocatorData[allocator][id].holdings.allocated += amount;
        IERC20(token).safeTransfer(address(allocator), amount);

        emit AllocatorFunded(id, amount);
    }

    function returnFundsToTreasury(
		uint256 id, 
		uint256 amount, 
		uint256 tokenId,
		uint256 delay
	) external override onlyGovernor {
        IAllocator allocator = allocators[id];
        uint256 allocated = allocatorData[allocator][id].holdings.allocated;
        uint128 gain = allocatorData[allocator][id].performance.gain;
        address token = address(allocator.tokens()[allocator.tokenIds(id)]);

        if (amount > allocated) {
            amount -= allocated;
            if (amount > gain) {
                amount = allocated + gain;
                gain = 0;
            } else {
                gain -= uint128(amount);
                amount += allocated;
            }
            allocated = 0;
        } else {
            allocated -= amount;
        }

        _allowTreasuryWithdrawal(IERC20(token));
        IERC20(token).safeTransferFrom(address(allocator), address(this), amount);

        allocatorData[allocator][id].holdings.allocated = allocated;
        if (allocated == 0) allocatorData[allocator][id].performance.gain = gain;

        treasury.deposit(amount, token, tokenId, delay, true);

        emit AllocatorWithdrawal(id, tokenId,  amount);
    }

    function returnRewardsToTreasury(
		uint256 id, 
		address token, 
		uint256 amount, 
		uint256 tokenId,
		uint256 delay
	) external override {
        _returnRewardsToTreasury(allocators[id], IERC20(token), amount, tokenId, delay);
    }

    function returnRewardsToTreasury(
		address allocatorAddress, 
		address token, 
		uint256 amount,
		uint256 tokenId,
		uint256 delay
	) external override {
        _returnRewardsToTreasury(IAllocator(allocatorAddress), IERC20(token), amount, tokenId, delay);
    }

    function getAllocatorByID(uint256 id) external view override returns (address allocatorAddress) {
        allocatorAddress = address(allocators[id]);
    }

    function getTotalAllocatorCount() external view override returns (uint256) {
        return allocators.length;
    }

    function getAllocatorLimits(uint256 id) external view override returns (AllocatorLimits memory) {
        return allocatorData[allocators[id]][id].limits;
    }

    function getAllocatorPerformance(
		uint256 id
	) external view override returns (AllocatorPerformance memory) {
        return allocatorData[allocators[id]][id].performance;
    }

    function getAllocatorAllocated(uint256 id) external view override returns (uint256) {
        return allocatorData[allocators[id]][id].holdings.allocated;
    }

    function _returnRewardsToTreasury(
        IAllocator allocator,
        IERC20 token,
        uint256 amount,
		uint256 tokenId,
		uint256 delay
    ) internal onlyGovernor {
        uint256 balance = token.balanceOf(address(allocator));
        amount = (balance < amount) ? balance : amount;

        _allowTreasuryWithdrawal(token);

        token.safeTransferFrom(address(allocator), address(this), amount);
        treasury.deposit(amount, address(token), tokenId, delay, true);

        emit AllocatorRewardsWithdrawal(address(allocator), amount);
    }

    function _allowTreasuryWithdrawal(IERC20 token) internal {
        if (token.allowance(address(this), address(treasury)) == 0) {
			token.approve(address(treasury), type(uint256).max);
		}
    }

    function _allocatorBelowLimit(AllocatorData memory data, uint256 amount) internal pure {
        uint256 newAllocated = data.holdings.allocated + amount;
        if (newAllocated > data.limits.allocated) {
			revert TreasuryExtender_MaxAllocation(newAllocated, data.limits.allocated);
		}
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../libraries/Math.sol";
import "../libraries/SafeCast.sol";

library Checkpoints {
    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    function latest(History storage self) internal view returns (uint256) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : self._checkpoints[pos - 1]._value;
    }

    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (self._checkpoints[mid]._blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : self._checkpoints[high - 1]._value;
    }

    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        uint256 pos = self._checkpoints.length;
        uint256 old = latest(self);
        if (pos > 0 && self._checkpoints[pos - 1]._blockNumber == block.number) {
            self._checkpoints[pos - 1]._value = SafeCast.toUint224(value);
        } else {
            self._checkpoints.push(
                Checkpoint({
					_blockNumber: SafeCast.toUint32(block.number), 
					_value: SafeCast.toUint224(value)
				})
            );
        }
        return (old, value);
    }

    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support 
	 * for smart wallets like Gnosis Safe, and does not provide security since it can be circumvented 
	 * by calling from a contract constructor.
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
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], 
	 * but with `errorMessage` as a fallback revert reason when `target` reverts.
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
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by 
	 * bubbling the revert reason using the provided one.
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

pragma solidity 0.8.7;

import "../interfaces/ISpaceAuthority.sol";

abstract contract SpaceAccessControlled {

    event AuthorityUpdated(ISpaceAuthority indexed authority);

    string constant UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    ISpaceAuthority public authority;

    constructor(ISpaceAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    modifier onlyGovernor() {
		require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    function setAuthority(ISpaceAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IERC20.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
			value >= type(int128).min && value <= type(int128).max, 
			"SafeCast: value doesn't fit in 128 bits"
		);
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
			value >= type(int64).min && value <= type(int64).max, 
			"SafeCast: value doesn't fit in 64 bits"
		);
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
			value >= type(int32).min && value <= type(int32).max, 
			"SafeCast: value doesn't fit in 32 bits"
		);
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
			value >= type(int16).min && value <= type(int16).max, 
			"SafeCast: value doesn't fit in 16 bits"
		);
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
			value >= type(int8).min && value <= type(int8).max, 
			"SafeCast: value doesn't fit in 8 bits"
		);
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
	function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
	function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    
	function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    
	function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
	function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
	function swapExactETHForTokens(
		uint amountOutMin, 
		address[] calldata path, 
		address to, 
		uint deadline
	) external payable returns (uint[] memory amounts);
    
	function swapTokensForExactETH(
		uint amountOut, 
		uint amountInMax, 
		address[] calldata path, 
		address to, 
		uint deadline
	) external returns (uint[] memory amounts);
    
	function swapExactTokensForETH(
		uint amountIn, 
		uint amountOutMin, 
		address[] calldata path, 
		address to, 
		uint deadline
	) external returns (uint[] memory amounts);
    
	function swapETHForExactTokens(
		uint amountOut, 
		address[] calldata path, 
		address to, 
		uint deadline
	) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(
		uint amountIn, 
		uint reserveIn, 
		uint reserveOut
	) external pure returns (uint amountOut);
    
	function getAmountIn(
		uint amountOut, 
		uint reserveIn, 
		uint reserveOut
	) external pure returns (uint amountIn);
    
	function getAmountsOut(
		uint amountIn, 
		address[] calldata path
	) external view returns (uint[] memory amounts);
    
	function getAmountsIn(
		uint amountOut, 
		address[] calldata path
	) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

struct AllocatorPerformance {
    uint128 gain;
    uint128 loss;
}

struct AllocatorLimits {
    uint128 allocated;
    uint128 loss;
}

struct AllocatorHoldings {
    uint256 allocated;
}

struct AllocatorData {
    AllocatorHoldings holdings;
    AllocatorLimits limits;
    AllocatorPerformance performance;
}

interface ITreasuryExtender {
    event NewDepositRegistered(address allocator, address token, uint256 id);
    event AllocatorFunded(uint256 id, uint256 amount);
    event AllocatorWithdrawal(uint256 id, uint256 tokenId, uint256 amount);
    event AllocatorRewardsWithdrawal(address allocator, uint256 amount);
    event AllocatorReportedGain(uint256 id, uint128 gain);
    event AllocatorReportedLoss(uint256 id, uint128 loss);
    event AllocatorReportedMigration(uint256 id);
    event AllocatorLimitsChanged(uint256 id, uint128 allocationLimit, uint128 lossLimit);

    function registerDeposit(address newAllocator) external;
    function setAllocatorLimits(uint256 id, AllocatorLimits memory limits) external;
    function report(uint256 id, uint128 gain, uint128 loss) external;
    function requestFundsFromTreasury(uint256 id, uint256 amount, uint256 tokenId) external;
	
	function returnRewardsToTreasury(
		address allocator, 
		address token, 
		uint256 amount, 
		uint256 tokenId, 
		uint256 delay
	) external;

    function returnFundsToTreasury(
		uint256 id, 
		uint256 amount, 
		uint256 tokenId, 
		uint256 delay
	) external;
    
	function returnRewardsToTreasury(
		uint256 id, 
		address token, 
		uint256 amount, 
		uint256 tokenId, 
		uint256 delay
	) external;
    
	function getTotalAllocatorCount() external view returns (uint256);
    function getAllocatorByID(uint256 id) external view returns (address);
    function getAllocatorAllocated(uint256 id) external view returns (uint256);
    function getAllocatorLimits(uint256 id) external view returns (AllocatorLimits memory);
    function getAllocatorPerformance(uint256 id) external view returns (AllocatorPerformance memory);
}

// SPDX-License-Identifier: MIT
  
pragma solidity 0.8.7;

import "../utils/Checkpoints.sol";
import "./IUniswapV2Router.sol";

interface ITreasury {
	event Deposit(address indexed token, uint256 indexed tokenId, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 indexed tokenId, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, uint256 indexed tokenId, address token,  uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, uint256 indexed tokenId, address token, uint256 amount, uint256 value);
    event Bought(address indexed token, uint256 tokenId, uint256 amount, uint256 value, address to);
    event Sold(address indexed token, uint256 tokenId, uint256 amount, uint256 value, address to);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);
	event Sync(uint256 indexed tokenId, uint256 ownerReserves, uint256 userReserves);
	event Managed(address indexed token, uint256 indexed tokenId, uint256 amount, uint256 value);

	enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        RESERVEDEBTOR,
        REWARDMANAGER,
        SPACE,
        NATIVEDEBTOR
    }

	function create(
		address token_,
		uint256 amount_,
		uint256 amountToDex_,
		uint256 tokensToDex_,
		uint256 paymentDelay_,
		uint256 deadline_,
		string memory name_,
		string memory symbol_,
		string memory metadata_
	) external returns (uint256);

	function deposit(
		uint256 amount_,
		address token_,
		uint256 id_,
		uint256 delay_,
		bool repay_
	) external;

	function manage(address token_, uint256 amount_, uint256 tokenId_) external;
	function withdraw(address token_, uint256 tokenId_) external;
	function buy(address token_, address to_, uint256 amount_, uint256 tokenId_) external;
	function sell(address token_, uint256 value_, uint256 tokenId_) external;
	function incurDebt(address token_, uint256 amount_, uint256 tokenId_) external;
	function repayDebt(address token_, uint256 amount_, uint256 tokenId_) external;
	function enable(STATUS status_, address address_, address calculator_) external;
	function disable(STATUS status_, address toDisable_) external;

	// view functions
	function dexRouter() external view returns (IUniswapV2Router);
	function indexInRegistry(address address_, STATUS status_) external view returns (bool, uint256);
	function tokenValue(
		address token, 
		uint256 amount, 
		uint256 tokenId, 
		bool wrap
	) external view returns (uint256);
	function calculateDelta(uint256 tokenId) external view returns (int256);
	function futurePayments(uint256 tokenId) external view returns (uint256);
	function fullDelta(uint256 tokenId) external view returns (int256);
	function ownerReserves(uint256 tokenId) external view returns (uint256);
	function userReserves(uint256 tokenId) external view returns (uint256);
	function initialDeposits(uint256 tokenId) external view returns (uint256);

	function getPastTotalOwnerReserves(uint256 blockNumber) external view returns (uint256);
	function getPastTotalUserReserves(uint256 blockNumber) external view returns (uint256);
	function totalOwnerReserves() external view returns (uint256);
	function totalUserReserves() external view returns (uint256);

	function initialize(address alpAddress_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ISpaceAuthority {
    
	event GovernorPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event GuardianPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event PolicyPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event VaultPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);

	function initialize(address treasuryAddress, address tokenAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC20 {
	function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IERC20.sol";
import "./ITreasuryExtender.sol";
import "./ISpaceAuthority.sol";

enum AllocatorStatus {
    OFFLINE,
    ACTIVATED,
    MIGRATING
}

struct AllocatorInitData {
    ISpaceAuthority authority;
    ITreasuryExtender extender;
    IERC20[] tokens;
}

interface IAllocator {
    event AllocatorDeployed(address authority, address extender);
    event AllocatorActivated();
    event AllocatorDeactivated(bool panic);
    event LossLimitViolated(uint128 lastLoss, uint128 dloss, uint256 estimatedTotalAllocated);
    event MigrationExecuted(address allocator);
    event EtherReceived(uint256 amount);

    function update(uint256 id) external;
    function deallocate(uint256[] memory amounts) external;
    function prepareMigration() external;
    function migrate() external;
    function activate() external;
    function deactivate(bool panic) external;
    function addId(uint256 id) external;
    
	function name() external view returns (string memory);
    function ids() external view returns (uint256[] memory);
    function tokenIds(uint256 id) external view returns (uint256);
    function version() external view returns (string memory);
    function status() external view returns (AllocatorStatus);
    function tokens() external view returns (IERC20[] memory);
    function utilityTokens() external view returns (IERC20[] memory);
    function rewardTokens() external view returns (IERC20[] memory);
    function amountAllocated(uint256 id) external view returns (uint256);
}