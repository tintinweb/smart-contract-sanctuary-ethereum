// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IVendorOracle.sol";
import "./interfaces/ILendingPool.sol";
import "./utils/IOwnable.sol";
import "./utils/OwnableInit.sol";
import "./ERC20/SafeERC20.sol";
import "./interfaces/IPoolFactory.sol";

contract LendingPool is ILendingPool, Ownable {
    using SafeERC20 for IERC20;
    IVendorOracle public priceFeed;
    IERC20 public override colToken;
    IERC20 public override lendToken;
    IPoolFactory public factory;
    address public treasury;
    uint256 public mintRatio;
    uint256 public feeRate; //bpt
    uint256 private protocolFee; //bpt
    uint256 public totalFees;
    mapping(address => UserReport) public debt;
    uint48 public expiry;

    function initialize(
        address _owner,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken,
        address _oracle,
        uint256 _feeRate, //Goes to pool deployer
        uint256 _protocolFee,
        uint48 _expiry,
        address _treasury
    ) external initializer {
        require(_mintRatio > 0, "Mint ratio <= 0");
        mintRatio = _mintRatio;
        colToken = IERC20(_colToken);
        lendToken = IERC20(_lendToken);
        priceFeed = IVendorOracle(_oracle);
        feeRate = _feeRate;
        protocolFee = _protocolFee;
        expiry = _expiry;
        treasury = _treasury;
        factory = IPoolFactory(msg.sender);
        initializeOwner(_owner);
    }

    function lend(uint256 _lendAmount) external onlyOwner {
        _pullTokensFrom(msg.sender, lendToken, _lendAmount);
        emit Lend(_lendAmount);
    }

    function rollIn(
        address _borrower,
        uint256 _colDepositAmount,
        uint256 _debtAmount
    ) external {
        // _borrow(_borrower, _colDepositAmount, true);
        require(isValidPrice(), "LTV >= 100%");
        require(block.timestamp <= expiry, "Pool closed");
        UserReport memory userReport;
        if (debt[_borrower].exists != 0) {
            userReport = debt[_borrower];
        } else {
            userReport = UserReport({
                borrowAmount: 0,
                colAmount: 0,
                totalFees: 0,
                exists: 1
            });
        }

        userReport.borrowAmount += _debtAmount;
        userReport.totalFees += (_debtAmount * feeRate) / 10000;
        totalFees += userReport.totalFees;
        _pullTokensFrom(msg.sender, colToken, _colDepositAmount);
        userReport.colAmount += _colDepositAmount;
        debt[_borrower] = userReport;
        factory.addBorrowerRecord(_borrower);
        emit Borrow(_borrower, _colDepositAmount);
    }

    function borrow(uint256 _colDepositAmount) external {
        borrowOnBehalfOf(msg.sender, _colDepositAmount);
    }

    function borrowOnBehalfOf(address _borrower, uint256 _colDepositAmount)
        public
    {
        require(isValidPrice(), "LTV >= 100%");
        require(block.timestamp <= expiry, "Pool closed");

        UserReport memory userReport;
        if (debt[_borrower].exists != 0) {
            userReport = debt[_borrower];
        } else {
            userReport = UserReport({
                borrowAmount: 0,
                colAmount: 0,
                totalFees: 0,
                exists: 1
            });
        }

        uint256 rawPayoutAmount = computePayoutAmount(
            _colDepositAmount,
            mintRatio
        );
        require(
            lendToken.balanceOf(address(this)) >= rawPayoutAmount,
            "Not enough liquidity"
        );
        userReport.borrowAmount += rawPayoutAmount;
        userReport.totalFees += (rawPayoutAmount * feeRate) / 10000;
        totalFees += userReport.totalFees;
        _pullTokensFrom(msg.sender, colToken, _colDepositAmount);
        userReport.colAmount += _colDepositAmount;
        debt[_borrower] = userReport;
        _safeTransfer(lendToken, _borrower, rawPayoutAmount);
        factory.addBorrowerRecord(_borrower);
        emit Borrow(_borrower, _colDepositAmount);
    }

    function rollOver(address _newPool) external {
        require(block.timestamp <= expiry, "Pool closed");
        ILendingPool newPool = ILendingPool(_newPool);
        _validateNewPool(newPool);
        UserReport memory userReport = debt[msg.sender];

        colToken.approve(_newPool, userReport.colAmount);
        if (newPool.mintRatio() <= mintRatio) {
            uint256 diffToRepay = computePayoutAmount(
                userReport.colAmount,
                mintRatio - newPool.mintRatio()
            );
            _pullTokensFrom(
                msg.sender,
                lendToken,
                diffToRepay + userReport.totalFees
            );
            newPool.rollIn(
                msg.sender,
                userReport.colAmount,
                (userReport.borrowAmount - diffToRepay)
            );
        } else {
            uint256 diffToReimburse = (userReport.colAmount *
                ((newPool.mintRatio() - mintRatio) / 1e18)) /
                (newPool.mintRatio() / 1e18);
            _pullTokensFrom(msg.sender, lendToken, userReport.totalFees);
            _safeTransfer(colToken, msg.sender, diffToReimburse);
            newPool.rollIn(
                msg.sender,
                userReport.colAmount - diffToReimburse,
                userReport.borrowAmount
            );
        }
        userReport.colAmount = 0;
        userReport.borrowAmount = 0; //Clean users debdt in current pool
        userReport.totalFees = 0;
        debt[msg.sender] = userReport;
    }

    function _validateNewPool(ILendingPool pool) private view {
        require(
            address(pool.lendToken()) == address(lendToken),
            "Wrong lend token"
        );
        require(
            address(pool.colToken()) == address(colToken),
            "Wrong col token"
        );
        require(
            address(IOwnable(address(pool)).owner()) == address(owner()),
            "Different pool owner"
        );
        require(pool.expiry() > expiry, "Pool does not last long enough");
    }

    // //Function rollover lendingFunds

    function repay(uint256 _repayAmount) external {
        repayOnBehalfOf(msg.sender, _repayAmount);
    }

    function repayOnBehalfOf(address _borrower, uint256 _repayAmount) public {
        UserReport memory userReport = debt[_borrower];
        require(block.timestamp <= expiry, "Pool closed");
        require(
            _repayAmount <= (userReport.borrowAmount + userReport.totalFees),
            "Acount debt is less"
        );
        require(userReport.borrowAmount > 0, "No debt");
        uint256 repayRemainder = _repayAmount;

        //Repay the fee first.
        _pullTokensFrom(msg.sender, lendToken, _repayAmount);
        if (repayRemainder <= userReport.totalFees) {
            userReport.totalFees -= repayRemainder;
            repayRemainder = 0;
        } else {
            repayRemainder -= userReport.totalFees;
            userReport.totalFees = 0;
        }

        userReport.borrowAmount -= repayRemainder;
        uint256 colReturnAmount = computeReturnAmount(repayRemainder);

        userReport.colAmount -= colReturnAmount;
        debt[_borrower] = userReport;
        _safeTransfer(colToken, _borrower, colReturnAmount);
        emit Repay(_borrower, _repayAmount);
    }

    function collect() external onlyOwner {
        require(block.timestamp > expiry, "Early to collect");
        // Send the protocol fee to treasury
        _safeTransfer(lendToken, treasury, (totalFees * protocolFee) / 10000);
        _safeTransfer(
            colToken,
            treasury,
            (colToken.balanceOf(address(this)) * protocolFee) / 10000
        );

        // Send premium to lender
        _safeTransfer(
            lendToken,
            msg.sender,
            lendToken.balanceOf(address(this))
        );
        _safeTransfer(colToken, msg.sender, colToken.balanceOf(address(this)));
        emit Collect();
    }

    // How much lend token you get for supplied collateral
    function computePayoutAmount(uint256 _colDepositAmount, uint256 _mintRatio)
        public
        view
        returns (uint256)
    {
        uint8 colDecimals = colToken.decimals();
        uint8 lendDecimals = lendToken.decimals();
        return
            (_colDepositAmount * _mintRatio * (10**lendDecimals)) /
            (10**colDecimals) /
            1e18;
    }

    //How much collateral you get back given repay amount. No fee calculation
    function computeReturnAmount(uint256 _repayAmount)
        public
        view
        returns (uint256)
    {
        uint8 colDecimals = colToken.decimals();
        uint8 lendDecimals = lendToken.decimals();
        return
            (_repayAmount * 1e18 * (10**colDecimals)) /
            (10**lendDecimals) /
            mintRatio;
    }

    receive() external payable {}

    function version() external pure override returns (string memory) {
        return "0.0.1";
    }

    /******************
     * Utility funcitons
     *******************/

    function _pullTokensFrom(
        address sender,
        IERC20 token,
        uint256 amount
    ) private {
        uint256 initialBalance = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount);
        require(
            token.balanceOf(address(this)) == initialBalance + amount,
            "Transfer failed"
        );
    }

    // Returns wheather borrowing is allowed based on teh assets price
    function isValidPrice() public view returns (bool) {
        if (address(priceFeed) != address(0)) {
            int256 priceLend = priceFeed.getPriceUSD(address(lendToken));
            int256 priceCol = priceFeed.getPriceUSD(address(colToken));
            if (priceLend != -1 && priceCol != -1) {
                return (priceCol > ((int256(mintRatio) * priceLend) / 1e18));
            }
        }
        return true;
    }

    function _safeTransfer(
        IERC20 _token,
        address _account,
        uint256 _amount
    ) private {
        uint256 bal = _token.balanceOf(address(this));
        if (bal < _amount) {
            _token.safeTransfer(_account, bal);
        } else {
            _token.safeTransfer(_account, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVendorOracle {
    function getPriceUSD(address base) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../ERC20/IERC20.sol";

interface ILendingPool {
    struct UserReport {
        uint256 borrowAmount;
        uint256 colAmount;
        uint256 totalFees;
        uint8 exists;
    }

    event Borrow(address borrower, uint256 colDepositAmount);
    event Repay(address borrower, uint256 repayAmount);
    event Lend(uint256 lendAmount);
    event Collect();

    function initialize(
        address _owner,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken,
        address _oracle,
        uint256 _feeRate, //Goes to pool deployer
        uint256 _protocolFee,
        uint48 _expiry,
        address _treasury
    ) external;

    function version() external pure returns (string memory);

    function mintRatio() external view returns (uint256);

    function lendToken() external view returns (IERC20);

    function colToken() external view returns (IERC20);

    function expiry() external view returns (uint48);

    function rollIn(address _borrower, uint256 _colDepositAmount, uint256 _debtAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
interface IOwnable {
    /**
     * @dev Returns owner
     */
    function owner() external view returns (address ownerAddress);

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() external;

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Initializable.sol";

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
abstract contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function initializeOwner(address _ownerAddress) internal initializer {
        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _owner);
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPoolFactory {
    function addBorrowerRecord(address _borrower) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);
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

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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