//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Dependencies/CheckContract.sol";
import "./Dependencies/Initializable.sol";
import "./Interfaces/IDfrancParameters.sol";

contract DfrancParameters is IDfrancParameters, Ownable, CheckContract, Initializable {
	string public constant NAME = "DfrancParameters";

	uint256 public constant override DECIMAL_PRECISION = 1 ether;
	uint256 public constant override _100pct = 1 ether; // 1e18 == 100%

	uint256 public constant REDEMPTION_BLOCK_DAY = 14;

	uint256 public constant MCR_DEFAULT = 1100000000000000000; // 110%
	uint256 public constant CCR_DEFAULT = 1500000000000000000; // 150%
	uint256 public constant PERCENT_DIVISOR_DEFAULT = 100; // dividing by 100 yields 0.5%

	uint256 public constant BORROWING_FEE_FLOOR_DEFAULT = (DECIMAL_PRECISION / 1000) * 5; // 0.5%
	uint256 public constant MAX_BORROWING_FEE_DEFAULT = (DECIMAL_PRECISION / 100) * 5; // 5%

	uint256 public constant DCHF_GAS_COMPENSATION_DEFAULT = 200 ether;
	uint256 public constant MIN_NET_DEBT_DEFAULT = 2000 ether;
	uint256 public constant REDEMPTION_FEE_FLOOR_DEFAULT = (DECIMAL_PRECISION / 1000) * 5; // 0.5%

	// Minimum collateral ratio for individual troves
	mapping(address => uint256) public override MCR;
	// Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
	mapping(address => uint256) public override CCR;

	mapping(address => uint256) public override DCHF_GAS_COMPENSATION; // Amount of DCHF to be locked in gas pool on opening troves
	mapping(address => uint256) public override MIN_NET_DEBT; // Minimum amount of net DCHF debt a trove must have
	mapping(address => uint256) public override PERCENT_DIVISOR; // dividing by 200 yields 0.5%
	mapping(address => uint256) public override BORROWING_FEE_FLOOR;
	mapping(address => uint256) public override REDEMPTION_FEE_FLOOR;
	mapping(address => uint256) public override MAX_BORROWING_FEE;
	mapping(address => uint256) public override redemptionBlock;

	mapping(address => bool) internal hasCollateralConfigured;

	IActivePool public override activePool;
	IDefaultPool public override defaultPool;
	IPriceFeed public override priceFeed;
	address public adminContract;

	bool public isInitialized;

	modifier isController() {
		require(msg.sender == owner() || msg.sender == adminContract, "Invalid Permissions");
		_;
	}

	function setAddresses(
		address _activePool,
		address _defaultPool,
		address _priceFeed,
		address _adminContract
	) external override initializer onlyOwner {
		require(!isInitialized, "Already initalized");
		checkContract(_activePool);
		checkContract(_defaultPool);
		checkContract(_priceFeed);
		checkContract(_adminContract);
		isInitialized = true;

		adminContract = _adminContract;
		activePool = IActivePool(_activePool);
		defaultPool = IDefaultPool(_defaultPool);
		priceFeed = IPriceFeed(_priceFeed);
	}

	function setAdminContract(address _admin) external onlyOwner {
		require(_admin != address(0), "admin address is zero");
		checkContract(_admin);
		adminContract = _admin;
	}

	function setPriceFeed(address _priceFeed) external override onlyOwner {
		checkContract(_priceFeed);
		priceFeed = IPriceFeed(_priceFeed);

		emit PriceFeedChanged(_priceFeed);
	}

	function sanitizeParameters(address _asset) external {
		if (!hasCollateralConfigured[_asset]) {
			_setAsDefault(_asset);
		}
	}

	function setAsDefault(address _asset) external onlyOwner {
		_setAsDefault(_asset);
	}

	function setAsDefaultWithRemptionBlock(address _asset, uint256 blockInDays)
		external
		isController
	{
		if (blockInDays > 14) {
			blockInDays = REDEMPTION_BLOCK_DAY;
		}

		if (redemptionBlock[_asset] == 0) {
			redemptionBlock[_asset] = block.timestamp + (blockInDays * 1 days);
		}

		_setAsDefault(_asset);
	}

	function _setAsDefault(address _asset) private {
		hasCollateralConfigured[_asset] = true;

		MCR[_asset] = MCR_DEFAULT;
		CCR[_asset] = CCR_DEFAULT;
		DCHF_GAS_COMPENSATION[_asset] = DCHF_GAS_COMPENSATION_DEFAULT;
		MIN_NET_DEBT[_asset] = MIN_NET_DEBT_DEFAULT;
		PERCENT_DIVISOR[_asset] = PERCENT_DIVISOR_DEFAULT;
		BORROWING_FEE_FLOOR[_asset] = BORROWING_FEE_FLOOR_DEFAULT;
		MAX_BORROWING_FEE[_asset] = MAX_BORROWING_FEE_DEFAULT;
		REDEMPTION_FEE_FLOOR[_asset] = REDEMPTION_FEE_FLOOR_DEFAULT;
	}

	function setCollateralParameters(
		address _asset,
		uint256 newMCR,
		uint256 newCCR,
		uint256 gasCompensation,
		uint256 minNetDebt,
		uint256 precentDivisor,
		uint256 borrowingFeeFloor,
		uint256 maxBorrowingFee,
		uint256 redemptionFeeFloor
	) external onlyOwner {
		hasCollateralConfigured[_asset] = true;

		setMCR(_asset, newMCR);
		setCCR(_asset, newCCR);
		setDCHFGasCompensation(_asset, gasCompensation);
		setMinNetDebt(_asset, minNetDebt);
		setPercentDivisor(_asset, precentDivisor);
		setMaxBorrowingFee(_asset, maxBorrowingFee);
		setBorrowingFeeFloor(_asset, borrowingFeeFloor);
		setRedemptionFeeFloor(_asset, redemptionFeeFloor);
	}

	function setMCR(address _asset, uint256 newMCR)
		public
		override
		onlyOwner
		safeCheck("MCR", _asset, newMCR, 1010000000000000000, 10000000000000000000) /// 101% - 1000%
	{
		uint256 oldMCR = MCR[_asset];
		MCR[_asset] = newMCR;

		emit MCRChanged(oldMCR, newMCR);
	}

	function setCCR(address _asset, uint256 newCCR)
		public
		override
		onlyOwner
		safeCheck("CCR", _asset, newCCR, 1010000000000000000, 10000000000000000000) /// 101% - 1000%
	{
		uint256 oldCCR = CCR[_asset];
		CCR[_asset] = newCCR;

		emit CCRChanged(oldCCR, newCCR);
	}

	function setPercentDivisor(address _asset, uint256 precentDivisor)
		public
		override
		onlyOwner
		safeCheck("Percent Divisor", _asset, precentDivisor, 2, 200)
	{
		uint256 oldPercent = PERCENT_DIVISOR[_asset];
		PERCENT_DIVISOR[_asset] = precentDivisor;

		emit PercentDivisorChanged(oldPercent, precentDivisor);
	}

	function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor)
		public
		override
		onlyOwner
		safeCheck("Borrowing Fee Floor", _asset, borrowingFeeFloor, 0, 1000) /// 0% - 10%
	{
		uint256 oldBorrowing = BORROWING_FEE_FLOOR[_asset];
		uint256 newBorrowingFee = (DECIMAL_PRECISION / 10000) * borrowingFeeFloor;

		BORROWING_FEE_FLOOR[_asset] = newBorrowingFee;
		require(MAX_BORROWING_FEE[_asset] > BORROWING_FEE_FLOOR[_asset], "Wrong inputs");

		emit BorrowingFeeFloorChanged(oldBorrowing, newBorrowingFee);
	}

	function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee)
		public
		override
		onlyOwner
		safeCheck("Max Borrowing Fee", _asset, maxBorrowingFee, 0, 1000) /// 0% - 10%
	{
		uint256 oldMaxBorrowingFee = MAX_BORROWING_FEE[_asset];
		uint256 newMaxBorrowingFee = (DECIMAL_PRECISION / 10000) * maxBorrowingFee;

		MAX_BORROWING_FEE[_asset] = newMaxBorrowingFee;
		require(MAX_BORROWING_FEE[_asset] > BORROWING_FEE_FLOOR[_asset], "Wrong inputs");

		emit MaxBorrowingFeeChanged(oldMaxBorrowingFee, newMaxBorrowingFee);
	}

	function setDCHFGasCompensation(address _asset, uint256 gasCompensation)
		public
		override
		onlyOwner
		safeCheck("Gas Compensation", _asset, gasCompensation, 1 ether, 200 ether)
	{
		uint256 oldGasComp = DCHF_GAS_COMPENSATION[_asset];
		DCHF_GAS_COMPENSATION[_asset] = gasCompensation;

		emit GasCompensationChanged(oldGasComp, gasCompensation);
	}

	function setMinNetDebt(address _asset, uint256 minNetDebt)
		public
		override
		onlyOwner
		safeCheck("Min Net Debt", _asset, minNetDebt, 0, 10000 ether)
	{
		uint256 oldMinNet = MIN_NET_DEBT[_asset];
		MIN_NET_DEBT[_asset] = minNetDebt;

		emit MinNetDebtChanged(oldMinNet, minNetDebt);
	}

	function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor)
		public
		override
		onlyOwner
		safeCheck("Redemption Fee Floor", _asset, redemptionFeeFloor, 10, 1000) /// 0.10% - 10%
	{
		uint256 oldRedemptionFeeFloor = REDEMPTION_FEE_FLOOR[_asset];
		uint256 newRedemptionFeeFloor = (DECIMAL_PRECISION / 10000) * redemptionFeeFloor;

		REDEMPTION_FEE_FLOOR[_asset] = newRedemptionFeeFloor;
		emit RedemptionFeeFloorChanged(oldRedemptionFeeFloor, newRedemptionFeeFloor);
	}

	function removeRedemptionBlock(address _asset) external override onlyOwner {
		redemptionBlock[_asset] = block.timestamp;

		emit RedemptionBlockRemoved(_asset);
	}

	modifier safeCheck(
		string memory parameter,
		address _asset,
		uint256 enteredValue,
		uint256 min,
		uint256 max
	) {
		require(
			hasCollateralConfigured[_asset],
			"Collateral is not configured, use setAsDefault or setCollateralParameters"
		);

		if (enteredValue < min || enteredValue > max) {
			revert SafeCheckError(parameter, enteredValue, min, max);
		}
		_;
	}
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract CheckContract {
	function checkContract(address _account) internal view {
		require(_account != address(0), "Account cannot be zero address");

		uint256 size;
		assembly {
			size := extcodesize(_account)
		}
		require(size > 0, "Account code size cannot be zero");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";

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

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

pragma solidity ^0.8.14;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";
import "./IDfrancBase.sol";

interface IDfrancParameters {
	error SafeCheckError(
		string parameter,
		uint256 valueEntered,
		uint256 minValue,
		uint256 maxValue
	);

	event MCRChanged(uint256 oldMCR, uint256 newMCR);
	event CCRChanged(uint256 oldCCR, uint256 newCCR);
	event GasCompensationChanged(uint256 oldGasComp, uint256 newGasComp);
	event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
	event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
	event BorrowingFeeFloorChanged(uint256 oldBorrowingFloorFee, uint256 newBorrowingFloorFee);
	event MaxBorrowingFeeChanged(uint256 oldMaxBorrowingFee, uint256 newMaxBorrowingFee);
	event RedemptionFeeFloorChanged(
		uint256 oldRedemptionFeeFloor,
		uint256 newRedemptionFeeFloor
	);
	event RedemptionBlockRemoved(address _asset);
	event PriceFeedChanged(address indexed addr);

	function DECIMAL_PRECISION() external view returns (uint256);

	function _100pct() external view returns (uint256);

	// Minimum collateral ratio for individual troves
	function MCR(address _collateral) external view returns (uint256);

	// Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
	function CCR(address _collateral) external view returns (uint256);

	function DCHF_GAS_COMPENSATION(address _collateral) external view returns (uint256);

	function MIN_NET_DEBT(address _collateral) external view returns (uint256);

	function PERCENT_DIVISOR(address _collateral) external view returns (uint256);

	function BORROWING_FEE_FLOOR(address _collateral) external view returns (uint256);

	function REDEMPTION_FEE_FLOOR(address _collateral) external view returns (uint256);

	function MAX_BORROWING_FEE(address _collateral) external view returns (uint256);

	function redemptionBlock(address _collateral) external view returns (uint256);

	function activePool() external view returns (IActivePool);

	function defaultPool() external view returns (IDefaultPool);

	function priceFeed() external view returns (IPriceFeed);

	function setAddresses(
		address _activePool,
		address _defaultPool,
		address _priceFeed,
		address _adminContract
	) external;

	function setPriceFeed(address _priceFeed) external;

	function setMCR(address _asset, uint256 newMCR) external;

	function setCCR(address _asset, uint256 newCCR) external;

	function sanitizeParameters(address _asset) external;

	function setAsDefault(address _asset) external;

	function setAsDefaultWithRemptionBlock(address _asset, uint256 blockInDays) external;

	function setDCHFGasCompensation(address _asset, uint256 gasCompensation) external;

	function setMinNetDebt(address _asset, uint256 minNetDebt) external;

	function setPercentDivisor(address _asset, uint256 precentDivisor) external;

	function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor) external;

	function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee) external;

	function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor) external;

	function removeRedemptionBlock(address _asset) external;
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

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.14;
import "./IPool.sol";

interface IActivePool is IPool {
	// --- Events ---
	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event ActivePoolDCHFDebtUpdated(address _asset, uint256 _DCHFDebt);
	event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IPool.sol";

interface IDefaultPool is IPool {
	// --- Events ---
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event DefaultPoolDCHFDebtUpdated(address _asset, uint256 _DCHFDebt);
	event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.14;

interface IPriceFeed {
	struct ChainlinkResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	struct RegisterOracle {
		AggregatorV3Interface chainLinkOracle;
		AggregatorV3Interface chainLinkIndex;
		bool isRegistered;
	}

	enum Status {
		chainlinkWorking,
		chainlinkUntrusted
	}

	// --- Events ---
	event PriceFeedStatusChanged(Status newStatus);
	event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
	event LastGoodIndexUpdated(address indexed token, uint256 _lastGoodIndex);
	event RegisteredNewOracle(
		address token,
		address chainLinkAggregator,
		address chianLinkIndex
	);

	// --- Function ---
	function addOracle(
		address _token,
		address _chainlinkOracle,
		address _chainlinkIndexOracle
	) external;

	function fetchPrice(address _token) external returns (uint256);

	function getDirectPrice(address _asset) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IDfrancParameters.sol";

interface IDfrancBase {
	event VaultParametersBaseChanged(address indexed newAddress);

	function dfrancParams() external view returns (IDfrancParameters);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IDeposit.sol";

// Common interface for the Pools.
interface IPool is IDeposit {
	// --- Events ---

	event AssetBalanceUpdated(uint256 _newBalance);
	event DCHFBalanceUpdated(uint256 _newBalance);
	event ActivePoolAddressChanged(address _newActivePoolAddress);
	event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
	event AssetAddressChanged(address _assetAddress);
	event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
	event AssetSent(address _to, address indexed _asset, uint256 _amount);

	// --- Functions ---

	function getAssetBalance(address _asset) external view returns (uint256);

	function getDCHFDebt(address _asset) external view returns (uint256);

	function increaseDCHFDebt(address _asset, uint256 _amount) external;

	function decreaseDCHFDebt(address _asset, uint256 _amount) external;
}

pragma solidity ^0.8.14;

interface IDeposit {
	function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}