// SPDX-License-Identifier: MIT
  
pragma solidity 0.8.7;

import "./types/SafeERC20.sol";
import "./types/SpaceAccessControlled.sol";

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IPricingCalculator.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IERC1543.sol";

import "./utils/Checkpoints.sol";

contract SpaceTreasury is SpaceAccessControlled, ITreasury {
    using SafeERC20 for IERC20;
	using Checkpoints for Checkpoints.History;

	uint256 public minimalPayment;
	address private initializer;
	IERC1543 public  alpAddress;
	IUniswapV2Router public override dexRouter;
	mapping(uint256 => int256) private lastDelta;

    mapping(STATUS => address[]) public registry;
    mapping(STATUS => mapping(address => bool)) public permissions;
    mapping(address => address) public bondCalculator;
    
    mapping(uint256 => uint256) public override ownerReserves;
	mapping(uint256 => uint256) public ownerPricingReserves;
	Checkpoints.History private _totalOwnerReserves;

    mapping(uint256 => uint256) public override userReserves;
	mapping(uint256 => uint256) public userPricingReserves;
	Checkpoints.History private _totalUserReserves;

	mapping(uint256 => uint256) public override initialDeposits;
	mapping(uint256 => uint256) public allocatedDeposits;

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";
	string internal invalidAddress = "Treasury: zero address";
    string internal insufficientReserves = "Treasury: insufficient reserves";

	uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "Treasury: swap is locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(
        address authority_,
		address dexRouter_,
		uint256 minimalPayment_
    ) SpaceAccessControlled(ISpaceAuthority(authority_)) {
        require(dexRouter_ != address(0), "Zero address: DEX");
		dexRouter = IUniswapV2Router(dexRouter_);
		initializer = msg.sender;
		minimalPayment = minimalPayment_;
    }

	function initialize(address alpAddress_) external override {
		require(msg.sender == initializer && alpAddress_ != address(0), invalidAddress);
		
		initializer = address(0);
		alpAddress = IERC1543(alpAddress_);
	}

	function getPastTotalOwnerReserves(uint256 blockNumber) public view override returns (uint256) {
		return _totalOwnerReserves.getAtBlock(blockNumber);
	}

	function totalOwnerReserves() public view override returns (uint256) {
		return _totalOwnerReserves.latest();
	}

	function getPastTotalUserReserves(uint256 blockNumber) public view override returns (uint256) {
		return _totalUserReserves.getAtBlock(blockNumber);
	}

	function totalUserReserves() public view override returns (uint256) {
		return _totalUserReserves.latest();
	}

	function changeDexAddress(address newDexRouter) external onlyGuardian {
		require(newDexRouter != address(0), invalidAddress);
		dexRouter = IUniswapV2Router(newDexRouter);
	}

	function changeMinimalPayment(uint256 newMinimalPayment) external onlyGuardian {
		minimalPayment = newMinimalPayment;
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
	) external override returns (uint256) {
        require(permissions[STATUS.RESERVETOKEN][token_], invalidToken);
		require(amount_ > amountToDex_, insufficientReserves);
		require(
			amount_ / (10**IERC20Metadata(token_).decimals()) >= minimalPayment, 
			insufficientReserves
		);

		amount_ -= amountToDex_;
        
		IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
		uint256 tokenId = alpAddress.createPair(msg.sender, paymentDelay_, name_, symbol_, metadata_);
		uint256 value = tokenValue(token_, amount_, tokenId, true);
		
		initialDeposits[tokenId] = value;
		ownerPricingReserves[tokenId] = value;
		userPricingReserves[tokenId] = value;
		lastDelta[tokenId] = int256(value);
	
		_dexDeploy(
			token_,
			alpAddress.assetPair(tokenId).tokenAddress,
			amountToDex_,
			tokensToDex_,
			deadline_
		);

		return tokenId;
	}

	function manage(address token_, uint256 amount_, uint256 tokenId_) external override {
		if (permissions[STATUS.LIQUIDITYTOKEN][token_]) {
            require(permissions[STATUS.LIQUIDITYMANAGER][msg.sender], notApproved);
        } else {
            require(permissions[STATUS.RESERVEMANAGER][msg.sender], notApproved);
        }

		if (permissions[STATUS.RESERVETOKEN][token_] || permissions[STATUS.LIQUIDITYTOKEN][token_]) {
            uint256 value = tokenValue(token_, amount_, tokenId_, true);
            allocatedDeposits[tokenId_] += value;
			require(
				allocatedDeposits[tokenId_] <= initialDeposits[tokenId_], 
				"Treasury: nothing to manage"
			);

			uint256 ownerReserve = ownerPricingReserves[tokenId_];
			uint256 userReserve = userPricingReserves[tokenId_];
			uint256 toAdd = getAmountIn(value, userReserve, ownerReserve);

			_rebase(tokenId_, ownerReserve + toAdd, userReserve - value);
        
			emit Managed(token_, tokenId_, amount_, value);
        }
        IERC20(token_).safeTransfer(msg.sender, amount_);
	}

    function deposit(
        uint256 amount_,
        address token_,
		uint256 id_,
		uint256 delay_,
		bool repay
    ) external override lock {
        if (
			!permissions[STATUS.RESERVETOKEN][token_] && 
			!permissions[STATUS.LIQUIDITYTOKEN][token_]
		) {
            revert(invalidToken);
        }
        
		IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);

        uint256 value = tokenValue(token_, amount_, id_, true);
		if (repay) {
			if (allocatedDeposits[id_] < value) {
				initialDeposits[id_] += value;
				allocatedDeposits[id_] = 0;
			} else {
				allocatedDeposits[id_] -= value;
			}
		} else {
			ownerReserves[id_] += value;
			_totalOwnerReserves.push(_add, value);
			alpAddress.changeAssetInfo(id_, delay_, value, msg.sender);
		}
		
		uint256 ownerReserve = ownerPricingReserves[id_];
		uint256 userReserve = userPricingReserves[id_];

		value = futurePayments(id_);
		uint256 toRemove = getAmountOut(value, ownerReserve, userReserve);

		_rebase(id_, ownerReserve - toRemove, userReserve + value);

        emit Deposit(token_, id_, amount_, value);
    }

    function withdraw(
		address token_,
		uint256 tokenId_
	) external override lock {
        require(!permissions[STATUS.RESERVETOKEN][token_], invalidToken);
		require(allocatedDeposits[tokenId_] == 0, "Treasury: funds in Extender");

		uint256 value = ownerReserves[tokenId_] + initialDeposits[tokenId_];
        uint256 amount = tokenValue(token_, value, tokenId_, false);

		_totalOwnerReserves.push(_subtract, ownerReserves[tokenId_]);
		_totalUserReserves.push(_subtract, userReserves[tokenId_]);

        IERC20(token_).safeTransfer(msg.sender, amount);
		alpAddress.burnAsset(tokenId_, msg.sender);

		delete ownerReserves[tokenId_];
		delete ownerPricingReserves[tokenId_];
		delete initialDeposits[tokenId_];
		delete userReserves[tokenId_];
		delete userPricingReserves[tokenId_];

        emit Withdrawal(token_, tokenId_, amount, value);
    }

	function buy(
		address token_, 
		address to_,
		uint256 amount_,
		uint256 tokenId_
	) external override lock {
        if (
			!permissions[STATUS.RESERVETOKEN][token_] && 
			!permissions[STATUS.LIQUIDITYTOKEN][token_]
		) {
            revert(invalidToken);
        }

        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);

		uint256 value = tokenValue(token_, amount_, tokenId_, true);
		userReserves[tokenId_] += value;
		_totalUserReserves.push(_add, value);

		uint256 ownerReserve = ownerPricingReserves[tokenId_];
		uint256 userReserve = userPricingReserves[tokenId_];
		uint256 toSend = getAmountOut(value, ownerReserve, userReserve);

		uint256 x = ownerReserve + value;
		uint256 y = userReserve - toSend;
		_rebase(tokenId_, x, y);

		IERC20(alpAddress.assetPair(tokenId_).tokenAddress).safeTransfer(to_, toSend);

		emit Bought(token_, tokenId_, amount_, value, to_);
	}

	function sell(
		address token_,
		uint256 value_,
		uint256 tokenId_
	) external override lock {
        require(!permissions[STATUS.RESERVETOKEN][token_], invalidToken);

		ownerReserves[tokenId_] -= value_;
		_totalUserReserves.push(_subtract, value_);

		uint256 ownerReserve = ownerPricingReserves[tokenId_];
		uint256 userReserve = userPricingReserves[tokenId_];
		uint256 amount = getAmountIn(value_, userReserve, ownerReserve);
		uint256 toSend = tokenValue(token_, amount, tokenId_, false);

        IERC20(token_).safeTransfer(msg.sender, toSend);

		IERC20(
			alpAddress.assetPair(tokenId_).tokenAddress
		).safeTransferFrom(msg.sender, address(this), value_);

		_rebase(tokenId_, ownerReserve + amount, userReserve - toSend);

		emit Sold(token_, tokenId_, amount, value_, msg.sender);
	}

    function incurDebt(
		address token_,
		uint256 amount_, 
		uint256 tokenId_
	) external override lock {
		require(permissions[STATUS.RESERVETOKEN][token_], notAccepted);
		
		uint256 value = tokenValue(token_, amount_, tokenId_, true);

        alpAddress.changeDebt(msg.sender, value, tokenId_, true);
		userReserves[tokenId_] -= value;
		_totalUserReserves.push(_subtract, value);
		
		IERC20(token_).safeTransfer(msg.sender, amount_);

		uint256 ownerReserve = ownerPricingReserves[tokenId_];
		uint256 userReserve = userPricingReserves[tokenId_];
		uint256 debt = getAmountIn(value, ownerReserve, userReserve);

		_rebase(tokenId_, ownerReserve - value, userReserve + debt);

        emit CreateDebt(msg.sender, tokenId_, token_, amount_, value);
    }

    function repayDebt(
		address token_,
		uint256 amount_, 
		uint256 tokenId_
	) external override lock {
        if (
			!permissions[STATUS.RESERVETOKEN][token_] && 
			!permissions[STATUS.LIQUIDITYTOKEN][token_]
		) {
            revert(invalidToken);
        }
		
		uint256 value = tokenValue(token_, amount_, tokenId_, true);

        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        alpAddress.changeDebt(msg.sender, value, tokenId_, false);
        
        userReserves[tokenId_] += value;
		_totalUserReserves.push(_add, value);

		uint256 ownerReserve = ownerPricingReserves[tokenId_];
		uint256 userReserve = userPricingReserves[tokenId_];
		uint256 refund = getAmountOut(value, userReserve, ownerReserve);

		_rebase(tokenId_, ownerReserve + value, userReserve - refund);

        emit RepayDebt(msg.sender, tokenId_, token_, amount_, value);
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function enable(
        STATUS _status,
        address _address,
        address _calculator
    ) external override onlyGuardian {
        if (_status == STATUS.SPACE) {
            alpAddress = IERC1543(_address);
        } else {
            permissions[_status][_address] = true;

            if (_status == STATUS.LIQUIDITYTOKEN) {
                bondCalculator[_address] = _calculator;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                registry[_status].push(_address);

                if (_status == STATUS.LIQUIDITYTOKEN || _status == STATUS.RESERVETOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(_address, _status);
                    if (reg) {
                        delete registry[_status][index];
                    }
                }
            }
        }
        emit Permissioned(_address, _status, true);
    }

    function disable(STATUS _status, address _toDisable) external override {
        require(
			msg.sender == authority.governor() || msg.sender == authority.guardian(), 
			"Only governor or guardian"
		);
        permissions[_status][_toDisable] = false;
        emit Permissioned(_toDisable, _status, false);
    }

    function indexInRegistry(
		address _address, 
		STATUS _status
	) public view override returns (bool, uint256) {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function tokenValue(
		address token_, 
		uint256 amount_, 
		uint256 tokenId_,
		bool wrap
	) public view override returns (uint256 value_) {
		if (wrap) {
			uint256 tokenDecimals = 
				10**IERC20Metadata(address(alpAddress.assetPair(tokenId_).tokenAddress)).decimals();
			value_ = amount_ * tokenDecimals / 10**IERC20Metadata(token_).decimals(); 

			if (permissions[STATUS.LIQUIDITYTOKEN][token_]) {
				value_ = IPricingCalculator(bondCalculator[token_]).valuation(token_, amount_); 
			}
		} else {
			uint256 tokenDecimals = 
				10**IERC20Metadata(address(alpAddress.assetPair(tokenId_).tokenAddress)).decimals();
			value_ = amount_ * 10**IERC20Metadata(token_).decimals() / tokenDecimals;
		}
    }

	function calculateDelta(uint256 tokenId) public view override returns (int256) {
		return int256(ownerReserves[tokenId]) - int256(userReserves[tokenId]);
	}

	function futurePayments(uint256 tokenId) public view override returns (uint256) {
		uint256 time  = alpAddress.assetPair(tokenId).paymentTime;
		uint256 delay = alpAddress.assetPair(tokenId).paymentDelay;
		uint256 amount = alpAddress.assetPair(tokenId).paymentAmount;
			
		uint256 deviation = time + delay;
		uint256 timestamp = block.timestamp;
		uint256 year = (365 days) + delay;
		uint256 lostTime = 0;

		if (timestamp < deviation) {
			lostTime = deviation - timestamp;
			lostTime = year > lostTime ? lostTime : year;
		}

		return delay == 0 ? 0 : (amount * (year - lostTime) / delay);
	}

	function fullDelta(uint256 id) public view override returns (int256) {
		return calculateDelta(id) + int256(futurePayments(id)) + int256(initialDeposits[id]);
	}

	function getAmountOut(
		uint256 amountIn, 
		uint256 reserveIn, 
		uint256 reserveOut
	) public pure returns (uint256) {
        if (reserveIn == 0 && amountIn == 0) {
            return 0;
        }

        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;

        return numerator / denominator;
    }

	function getAmountIn(
		uint256 amountOut, 
		uint256 reserveIn, 
		uint256 reserveOut
	) public pure returns (uint256) {
		if (reserveOut <= amountOut) {
			return 0;
		}

		uint256 numerator = reserveIn * amountOut;
		uint256 denominator = reserveOut - amountOut;

		return numerator / denominator;
	}

	function _setInitialReserves(uint256 value, uint256 tokenId) internal {
		initialDeposits[tokenId] = value;
		ownerPricingReserves[tokenId] = value;
		userPricingReserves[tokenId] = value;
	}

	function _dexDeploy(
		address token, 
		address alp, 
		uint256 tokenAmount, 
		uint256 alpAmount,
		uint256 deadline
	) internal {
		if (tokenAmount > 0) {
			IERC20(token).approve(address(dexRouter), tokenAmount);
			IERC20(alp).approve(address(dexRouter), alpAmount);
			
			dexRouter.addLiquidity(
				token,
				alp,
				tokenAmount,
				alpAmount,
				tokenAmount,
				alpAmount,
				address(this),
				deadline
			);
		}
		
	}

	function _rebase(uint256 tokenId, uint256 amount0Out, uint256 amount1Out) internal {
		int256 delta = fullDelta(tokenId) - lastDelta[tokenId];
		lastDelta[tokenId] = fullDelta(tokenId);
		
		alpAddress.rebase(tokenId, delta);
		_update(amount0Out, amount1Out, tokenId);
	}

	function _update(uint256 balance0, uint256 balance1, uint256 tokenId) internal {
		require(balance0 != 0 && balance1 != 0, "Treasury: ZERO PRICING RESERVES");

        ownerPricingReserves[tokenId] = balance0;
        userPricingReserves[tokenId] = balance1;
        
		emit Sync(tokenId, balance0, balance1);
    }

	function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
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

interface IPricingCalculator {
	// liquidity price
    function markdown(address _LP, uint256 tokenId) external view returns (uint256);
    function valuation(address pair_, uint256 amount_) external view returns (uint256 _value);

	// internal price
}

// SPDX-License-Identifier: MIT
  
pragma solidity 0.8.7;

interface IERC20Metadata {
	function decimals() external view returns (uint8);
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
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

interface IERC1543 {
	struct AssetPair {
        bool initialized;
        uint256 epoch;
        address tokenAddress;
        bool checked;
		uint256 debt;
		uint256 paymentAmount;
		uint256 paymentTime;
		uint256 paymentDelay;
    }
	
	event PairCreated(uint256 indexed tokenId, address indexed alp);
	event DebtChanged(uint256 indexed tokenId, uint256 indexed amount, bool add);
	event AssetChanged(
		uint256 indexed tokenId, 
		address indexed owner, 
		uint256 delay, 
		uint256 amount
	);

	function allPairsLength() external view returns (uint256);
	function checkedPairsLength() external view returns (uint256);
	function assetPair(uint256 tokenId) external view returns (AssetPair memory);

	function createPair(
		address to,
		uint256 paymentDelay,
		string memory name, 
		string memory symbol,
		string memory metadataURI
	) external returns (uint256);
	
	function changeDebt(
		address owner,
		uint256 amount,
		uint256 tokenId,
		bool add
	) external;

	function changeAssetInfo(
		uint256 tokenId,
		uint256 delay,
		uint256 amount,
		address owner
	) external;

	function checkAssetPair(uint256 tokenId) external;
	function rebase(uint256 tokenId, int256 supplyDelta) external;
	function burnAsset(uint256 tokenId, address owner) external;
}