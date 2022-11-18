// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

// Linked Libraries
import { SavingLib } from "./lib/SavingLib.sol";
import { Utils } from "./lib/Utils.sol";

// External imports
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Interfaces imports
import { ICToken } from "./interfaces/ICToken.sol";
import { ICETH } from "./interfaces/ICETH.sol";
import { IGlobalConfig } from "./interfaces/IGlobalConfig.sol";
import { IPoolRegistry } from "../interfaces/IPoolRegistry.sol";
import { IBank } from "./interfaces/IBank.sol";

// Other imports
import { Constant, ActionType } from "./config/Constant.sol";
import { InitializableReentrancyGuard } from "./InitializableReentrancyGuard.sol";
import { InitializablePausable } from "./InitializablePausable.sol";

contract SavingAccount is Initializable, InitializableReentrancyGuard, Constant, InitializablePausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    IGlobalConfig public globalConfig;
    IPoolRegistry public poolRegistry;
    address public baseToken;
    IERC20 public miningToken;
    // UNIX timestamp, when it matures and enable withdrawal for the baseToken
    uint256 public maturesOn;
    uint256 public poolId;

    address public constant COMP_ADDR = address(0); // disabled

    event Transfer(address indexed token, address from, address to, uint256 amount);
    event Borrow(address indexed token, address from, uint256 amount);
    event Repay(address indexed token, address from, uint256 amount);
    event Deposit(address indexed token, address from, uint256 amount);
    event Withdraw(address indexed token, address from, uint256 amount);
    event WithdrawAll(address indexed token, address from, uint256 amount);
    event Liquidate(
        address liquidator,
        address borrower,
        address borrowedToken,
        uint256 repayAmount,
        address collateralToken,
        uint256 payAmount
    );
    event Claim(address from, uint256 amount);
    event WithdrawCOMP(address beneficiary, uint256 amount);

    modifier onlySupportedToken(address _token) {
        if (_token != ETH_ADDR) {
            require(globalConfig.tokenRegistry().isTokenExist(_token), "Unsupported token");
        }
        _;
    }

    modifier onlyEnabledToken(address _token) {
        require(globalConfig.tokenRegistry().isTokenEnabled(_token), "The token is not enabled");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(globalConfig.bank()), "Only authorized to call from DeFiner internal contracts.");
        _;
    }

    modifier onlyPoolRegistry() {
        require(msg.sender == address(poolRegistry), "not a poolRegistry");
        _;
    }

    modifier whenMatured(address _token) {
        if (_token == baseToken) {
            require(block.timestamp > maturesOn, "not matured");
        }
        _;
    }

    /**
     * @dev Check that this pool is in "Configured" state.
     * @notice check only in the "deposit()" as this is the very first operation in a pool.
     */
    modifier whenPoolConfigured() {
        require(poolRegistry.isPoolConfigured(poolId), "pool not Configured");
        _;
    }

    /**
     * Initialize function to be called by the Deployer for the first time
     * @param _tokenAddresses list of token addresses
     * @param _cTokenAddresses list of corresponding cToken addresses
     * @param _globalConfig global configuration contract
     */
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        IGlobalConfig _globalConfig,
        IPoolRegistry _poolRegistry,
        uint256 _poolId
    ) public initializer {
        // Initialize InitializableReentrancyGuard
        super._initialize();
        super._initialize(address(_globalConfig));

        globalConfig = _globalConfig;
        poolRegistry = _poolRegistry;
        poolId = _poolId;

        require(_tokenAddresses.length == _cTokenAddresses.length, "Token and cToken length don't match.");
        uint256 tokenNum = _tokenAddresses.length;
        for (uint256 i = 0; i < tokenNum; i++) {
            if (_cTokenAddresses[i] != address(0x0) && _tokenAddresses[i] != ETH_ADDR) {
                approveAll(_tokenAddresses[i]);
            }
        }
    }

    function configure(
        address _baseToken,
        IERC20 _miningToken,
        uint256 _maturesOn
    ) external onlyPoolRegistry {
        require(address(miningToken) == address(0), "miningToken already set");
        baseToken = _baseToken;
        miningToken = _miningToken;
        maturesOn = _maturesOn;
    }

    /**
     * Approve transfer of all available tokens
     * @param _token token address
     */
    function approveAll(address _token) public {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        require(cToken != address(0x0), "cToken address is zero");
        IERC20(_token).safeApprove(cToken, 0);
        IERC20(_token).safeApprove(cToken, type(uint256).max);
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * Transfer the token between users inside DeFiner
     * @param _to the address that the token be transfered to
     * @param _token token address
     * @param _amount amout of tokens transfer
     */
    function transfer(
        address _to,
        address _token,
        uint256 _amount
    ) external onlySupportedToken(_token) onlyEnabledToken(_token) whenNotPaused nonReentrant {
        globalConfig.bank().newRateIndexCheckpoint(_token);
        uint256 amount = globalConfig.accounts().withdraw(msg.sender, _token, _amount);
        globalConfig.accounts().deposit(_to, _token, amount);

        emit Transfer(_token, msg.sender, _to, amount);
    }

    /**
     * Borrow the amount of token from the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     */
    function borrow(address _token, uint256 _amount)
        external
        onlySupportedToken(_token)
        onlyEnabledToken(_token)
        whenNotPaused
        nonReentrant
    {
        require(_amount != 0, "Borrow zero amount of token is not allowed.");

        globalConfig.bank().borrow(msg.sender, _token, _amount);

        // Transfer the token on Ethereum
        SavingLib.sendAssets(_amount, _token);

        emit Borrow(_token, msg.sender, _amount);
    }

    /**
     * Repay the amount of token back to the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     * @dev If the repay amount is larger than the borrowed balance, the extra will be returned.
     */
    function repay(address _token, uint256 _amount) public payable onlySupportedToken(_token) nonReentrant {
        require(_amount != 0, "Amount is zero");
        SavingLib.collectAssets(_amount, _token);

        // Add a new checkpoint on the index curve.
        uint256 amount = globalConfig.bank().repay(msg.sender, _token, _amount);

        // Send the remain money back
        if (amount < _amount) {
            SavingLib.sendAssets(_amount.sub(amount), _token);
        }

        emit Repay(_token, msg.sender, amount);
    }

    /**
     * Deposit the amount of token to the saving pool.
     * @param _token the address of the deposited token
     * @param _amount the mount of the deposited token
     */
    function deposit(address _token, uint256 _amount)
        public
        payable
        onlySupportedToken(_token)
        onlyEnabledToken(_token)
        whenPoolConfigured
        nonReentrant
    {
        require(_amount != 0, "Amount is zero");
        SavingLib.collectAssets(_amount, _token);
        globalConfig.bank().deposit(msg.sender, _token, _amount);

        emit Deposit(_token, msg.sender, _amount);
    }

    /**
     * Withdraw a token from an address
     * @param _token token address
     * @param _amount amount to be withdrawn
     */
    function withdraw(address _token, uint256 _amount)
        external
        onlySupportedToken(_token)
        whenNotPaused
        whenMatured(_token)
        nonReentrant
    {
        require(_amount != 0, "Amount is zero");
        uint256 amount = globalConfig.bank().withdraw(msg.sender, _token, _amount);
        SavingLib.sendAssets(amount, _token);

        emit Withdraw(_token, msg.sender, amount);
    }

    /**
     * Withdraw all tokens from the saving pool.
     * @param _token the address of the withdrawn token
     */
    function withdrawAll(address _token)
        external
        onlySupportedToken(_token)
        whenNotPaused
        whenMatured(_token)
        nonReentrant
    {
        // Sanity check
        require(
            globalConfig.accounts().getDepositPrincipal(msg.sender, _token) > 0,
            "Token depositPrincipal must be greater than 0"
        );

        // Add a new checkpoint on the index curve.
        globalConfig.bank().newRateIndexCheckpoint(_token);

        // Get the total amount of token for the account
        uint256 amount = globalConfig.accounts().getDepositBalanceCurrent(_token, msg.sender);

        uint256 actualAmount = globalConfig.bank().withdraw(msg.sender, _token, amount);
        if (actualAmount != 0) {
            SavingLib.sendAssets(actualAmount, _token);
        }
        emit WithdrawAll(_token, msg.sender, actualAmount);
    }

    function liquidate(
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) public onlySupportedToken(_borrowedToken) onlySupportedToken(_collateralToken) whenNotPaused nonReentrant {
        IBank bank = IBank(address(globalConfig.bank()));
        bank.newRateIndexCheckpoint(_borrowedToken);
        bank.newRateIndexCheckpoint(_collateralToken);
        bank.updateDepositFINIndex(_borrowedToken);
        bank.updateDepositFINIndex(_collateralToken);
        bank.updateBorrowFINIndex(_borrowedToken);
        bank.updateBorrowFINIndex(_collateralToken);

        (uint256 repayAmount, uint256 payAmount) = globalConfig.accounts().liquidate(
            msg.sender,
            _borrower,
            _borrowedToken,
            _collateralToken
        );

        bank.update(_borrowedToken, repayAmount, ActionType.LiquidateRepayAction);

        emit Liquidate(msg.sender, _borrower, _borrowedToken, repayAmount, _collateralToken, payAmount);
    }

    /**
     * Withdraw token from Compound
     * @param _token token address
     * @param _amount amount of token
     */
    function fromCompound(address _token, uint256 _amount) external onlyAuthorized {
        require(
            ICToken(globalConfig.tokenRegistry().getCToken(_token)).redeemUnderlying(_amount) == 0,
            "redeemUnderlying failed"
        );
    }

    function toCompound(address _token, uint256 _amount) external onlyAuthorized {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        if (Utils._isETH(_token)) {
            ICETH(cToken).mint{ value: _amount }();
        } else {
            // uint256 success = ICToken(cToken).mint(_amount);
            require(ICToken(cToken).mint(_amount) == 0, "mint failed");
        }
    }

    /**
     * An account claim all mined FIN token
     */
    function claim() public nonReentrant returns (uint256) {
        uint256 finAmount = globalConfig.accounts().claim(msg.sender);
        miningToken.safeTransfer(msg.sender, finAmount);
        emit Claim(msg.sender, finAmount);
        return finAmount;
    }

    function claimForToken(address _token) public nonReentrant returns (uint256) {
        uint256 finAmount = globalConfig.accounts().claimForToken(msg.sender, _token);
        if (finAmount > 0) miningToken.safeTransfer(msg.sender, finAmount);
        emit Claim(msg.sender, finAmount);
        return finAmount;
    }

    // NOTICE: Withdraw COMP is disabled in Gemini
    /**
     * Withdraw COMP token to beneficiary
     */
    /*
    function withdrawCOMP(address _beneficiary) external onlyOwner {
        uint256 compBalance = IERC20(COMP_ADDR).balanceOf(address(this));
        IERC20(COMP_ADDR).safeTransfer(_beneficiary, compBalance);

        emit WithdrawCOMP(_beneficiary, compBalance);
    }
    */

    function version() public pure virtual returns (string memory) {
        return "v2.0.0";
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IGlobalConfig.sol";
import "./Utils.sol";

library SavingLib {
    using SafeERC20 for IERC20;

    /**
     * Receive the amount of token from msg.sender
     * @param _amount amount of token
     * @param _token token address
     */
    function collectAssets(uint256 _amount, address _token) public {
        if (Utils._isETH(_token)) {
            require(msg.value == _amount, "The amount is not sent from address.");
        } else {
            //When only tokens received, msg.value must be 0
            require(msg.value == 0, "msg.value must be 0 when receiving tokens");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /**
     * Send the amount of token to an address
     * @param _amount amount of token
     * @param _token token address
     */
    function sendAssets(uint256 _amount, address _token) public {
        if (Utils._isETH(_token)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "../interfaces/IGlobalConfig.sol";

library Utils {
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10**uint256(18);

    function _isETH(address _token) public pure returns (bool) {
        return ETH_ADDR == _token;
    }

    function getDivisor(IGlobalConfig globalConfig, address _token) public view returns (uint256) {
        if (_isETH(_token)) return INT_UNIT;
        return 10**uint256(globalConfig.tokenRegistry().getTokenDecimals(_token));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ICToken {
    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemAmount) external returns (uint256);

    function exchangeRateStore() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ICETH {
    function mint() external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./ITokenRegistry.sol";
import "./IBank.sol";
import "./ISavingAccount.sol";
import "./IAccounts.sol";
import "./IConstant.sol";

interface IGlobalConfig {
    function initialize(
        address _gemGlobalConfig,
        address _bank,
        address _savingAccount,
        address _tokenRegistry,
        address _accounts,
        address _poolRegistry
    ) external;

    function tokenRegistry() external view returns (ITokenRegistry);

    function chainLink() external view returns (address);

    function bank() external view returns (IBank);

    function savingAccount() external view returns (ISavingAccount);

    function accounts() external view returns (IAccounts);

    function maxReserveRatio() external view returns (uint256);

    function midReserveRatio() external view returns (uint256);

    function minReserveRatio() external view returns (uint256);

    function rateCurveConstant() external view returns (uint256);

    function compoundSupplyRateWeights() external view returns (uint256);

    function compoundBorrowRateWeights() external view returns (uint256);

    function deFinerRate() external view returns (uint256);

    function liquidationThreshold() external view returns (uint256);

    function liquidationDiscountRatio() external view returns (uint256);

    function governor() external view returns (address);

    function updateMinMaxBorrowAPR(uint256 _minBorrowAPRInPercent, uint256 _maxBorrowAPRInPercent) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./IGemGlobalConfig.sol";
import "./IPoolFactory.sol";
import "./IDefaultTokenRegistry.sol";

interface IPoolRegistry {
    function initializer(
        IGemGlobalConfig _gemGlobalConfig,
        IPoolFactory _poolFactory,
        IDefaultTokenRegistry _defaultTokenRegistry
    ) external;

    function nextPoolId() external view returns (uint256);

    function isPoolConfigured(uint256 _poolId) external view returns (bool);

    function getPoolStatus(uint256 _poolId) external view returns (uint8);

    function getPoolsByCreator(address _creator) external view returns (uint256[] memory);

    function calcBaseTokenAmountStep3(
        uint256 _maturesOn,
        uint256 _allMiningSpeed,
        uint256 _blocksPerYear
    ) external view returns (uint256);

    function pools(uint256 _poolId)
        external
        view
        returns (
            address poolCreator,
            address baseToken,
            address globalConfig,
            address savingAccount,
            address bank,
            address accounts,
            address tokenRegistry,
            address claim,
            address fixedPriceOracle,
            uint8 poolStatus,
            uint256 maturesOn
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { ActionType } from "../config/Constant.sol";

interface IBank {
    /* solhint-disable func-name-mixedcase */
    function BLOCKS_PER_YEAR() external view returns (uint256);

    function initialize(address _globalConfig, address _poolRegistry) external;

    function newRateIndexCheckpoint(address) external;

    function deposit(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function withdraw(
        address _from,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function borrow(
        address _from,
        address _token,
        uint256 _amount
    ) external;

    function repay(
        address _to,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function getDepositAccruedRate(address _token, uint256 _depositRateRecordStart) external view returns (uint256);

    function getBorrowAccruedRate(address _token, uint256 _borrowRateRecordStart) external view returns (uint256);

    function depositeRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function borrowRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function depositeRateIndexNow(address _token) external view returns (uint256);

    function borrowRateIndexNow(address _token) external view returns (uint256);

    function updateMining(address _token) external;

    function updateDepositFINIndex(address _token) external;

    function updateBorrowFINIndex(address _token) external;

    function update(
        address _token,
        uint256 _amount,
        ActionType _action
    ) external returns (uint256 compoundAmount);

    function depositFINRateIndex(address, uint256) external view returns (uint256);

    function borrowFINRateIndex(address, uint256) external view returns (uint256);

    function getTotalDepositStore(address _token) external view returns (uint256);

    function totalLoans(address _token) external view returns (uint256);

    function totalReserve(address _token) external view returns (uint256);

    function totalCompound(address _token) external view returns (uint256);

    function getBorrowRatePerBlock(address _token) external view returns (uint256);

    function getDepositRatePerBlock(address _token) external view returns (uint256);

    function getTokenState(address _token)
        external
        view
        returns (
            uint256 deposits,
            uint256 loans,
            uint256 reserveBalance,
            uint256 remainingAssets
        );

    function configureMaxUtilToCalcBorrowAPR(uint256 _maxBorrowAPR) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

enum ActionType {
    DepositAction,
    WithdrawAction,
    BorrowAction,
    RepayAction,
    LiquidateRepayAction
}

abstract contract Constant {
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10**uint256(18);
    uint256 public constant ACCURACY = 10**uint256(18);
}

/**
 * @dev Only some of the contracts uses BLOCKS_PER_YEAR in their code.
 * Hence, only those contracts would have to inherit from BPYConstant.
 * This is done to minimize the argument passing from other contracts.
 */
abstract contract BPYConstant is Constant {
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BLOCKS_PER_YEAR;

    constructor(uint256 _blocksPerYear) {
        BLOCKS_PER_YEAR = _blocksPerYear;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/**
 * @notice Code copied from OpenZeppelin, to make it an upgradable contract
 */
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract InitializableReentrancyGuard {
    bool private _notEntered;

    function _initialize() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./interfaces/IGlobalConfig.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract InitializablePausable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    address private globalConfig;
    bool private _paused;

    function _initialize(address _globalConfig) internal {
        globalConfig = _globalConfig;
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(IGlobalConfig(globalConfig).governor());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(IGlobalConfig(globalConfig).governor());
    }

    modifier onlyPauser() {
        require(
            msg.sender == IGlobalConfig(globalConfig).governor(),
            "PauserRole: caller does not have the Pauser role"
        );
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ITokenRegistry {
    function initialize(
        address _gemGlobalConfig,
        address _poolRegistry,
        address _globalConfig
    ) external;

    function tokenInfo(address _token)
        external
        view
        returns (
            uint8 index,
            uint8 decimals,
            bool enabled,
            bool _isSupportedOnCompound, // compiler warning
            address cToken,
            address chainLinkOracle,
            uint256 borrowLTV
        );

    function addTokenByPoolRegistry(
        address _token,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle,
        uint256 _borrowLTV
    ) external;

    function getTokenDecimals(address) external view returns (uint8);

    function getCToken(address) external view returns (address);

    function getCTokens() external view returns (address[] calldata);

    function depositeMiningSpeeds(address _token) external view returns (uint256);

    function borrowMiningSpeeds(address _token) external view returns (uint256);

    function isSupportedOnCompound(address) external view returns (bool);

    function getTokens() external view returns (address[] calldata);

    function getTokenInfoFromAddress(address _token)
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        );

    function getTokenInfoFromIndex(uint256 index)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function getTokenIndex(address _token) external view returns (uint8);

    function addressFromIndex(uint256 index) external view returns (address);

    function isTokenExist(address _token) external view returns (bool isExist);

    function isTokenEnabled(address _token) external view returns (bool);

    function priceFromAddress(address _token) external view returns (uint256);

    function updateMiningSpeed(
        address _token,
        uint256 _depositeMiningSpeed,
        uint256 _borrowMiningSpeed
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ISavingAccount {
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        address _globalConfig,
        address _poolRegistry,
        uint256 _poolId
    ) external;

    function configure(
        address _baseToken,
        address _miningToken,
        uint256 _maturesOn
    ) external;

    function toCompound(address, uint256) external;

    function fromCompound(address, uint256) external;

    function approveAll(address _token) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IAccounts {
    function initialize(address _globalConfig, address _gemGlobalConfig) external;

    function deposit(
        address,
        address,
        uint256
    ) external;

    function borrow(
        address,
        address,
        uint256
    ) external;

    function getBorrowPrincipal(address, address) external view returns (uint256);

    function withdraw(
        address,
        address,
        uint256
    ) external returns (uint256);

    function repay(
        address,
        address,
        uint256
    ) external returns (uint256);

    function getDepositPrincipal(address _accountAddr, address _token) external view returns (uint256);

    function getDepositBalanceCurrent(address _token, address _accountAddr) external view returns (uint256);

    function getDepositInterest(address _account, address _token) external view returns (uint256);

    function getBorrowInterest(address _accountAddr, address _token) external view returns (uint256);

    function getBorrowBalanceCurrent(address _token, address _accountAddr)
        external
        view
        returns (uint256 borrowBalance);

    function getBorrowETH(address _accountAddr) external view returns (uint256 borrowETH);

    function getDepositETH(address _accountAddr) external view returns (uint256 depositETH);

    function getBorrowPower(address _borrower) external view returns (uint256 power);

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) external returns (uint256, uint256);

    function claim(address _account) external returns (uint256);

    function claimForToken(address _account, address _token) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/* solhint-disable */
interface IConstant {
    function ETH_ADDR() external view returns (address);

    function INT_UNIT() external view returns (uint256);

    function ACCURACY() external view returns (uint256);

    function BLOCKS_PER_YEAR() external view returns (uint256);
}
/* solhint-enable */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

interface IGemGlobalConfig {
    function initialize(
        address _finToken,
        address _governor,
        address _definerAdmin,
        address payable _deFinerCommunityFund,
        uint256 _poolCreationFeeInUSD8,
        AggregatorInterface _nativeTokenOracleForPriceInUSD8
    ) external;

    function finToken() external view returns (address);

    function governor() external view returns (address);

    function definerAdmin() external view returns (address);

    function nativeTokenOracleForPriceInUSD8() external view returns (address);

    function deFinerCommunityFund() external view returns (address payable);

    function getPoolCreationFeeInNative() external view returns (uint256);

    function getNativeTokenPriceInUSD8() external view returns (int256);

    function nativeTokenPriceOracleInUSD8() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IPoolFactory {
    function poolRegistry() external view returns (address);

    function initialize(
        address _gemGlobalConfig,
        address _ubGlobalConfig,
        address _ubSavingAccount,
        address _ubBank,
        address _ubAccounts,
        address _ubTokenRegistry,
        address _ubClaim
    ) external;

    function createNewPool(uint256 _poolId)
        external
        returns (
            address globalConfig,
            address savingAccount,
            address bank,
            address accounts,
            address tokenRegistry,
            address claim
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IDefaultTokenRegistry {
    function initialize(address _owner) external;

    function tokenInfo(address _token)
        external
        view
        returns (
            uint8 index,
            uint8 decimals,
            bool isSupportedOnCompound,
            address cToken,
            address chainLinkOracle,
            uint256 borrowLTV
        );

    function tokens(uint256 _index) external view returns (address);

    function getTokensLength() external view returns (uint256 length);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}