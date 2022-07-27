// SPDX-License-Identifier: No License
/**
 * @title Vendor Utility Functions
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "../interfaces/ILendingPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IVendorOracle.sol";
import "../ERC20/SafeERC20.sol";

library VendorUtils{
    using SafeERC20 for IERC20;

    error NotAPool();

    error DifferentPoolOwner();

    error InvalidExpiry();

    error DifferentLendToken();

    error OracleNotSet();


    ///@notice Make sure new pool can be rolled into
    ///@param _pool the pool you are about rollover into
    function _validateNewPool(
        ILendingPool _pool,
        IPoolFactory factory,
        IERC20 lendToken,
        address owner,
        uint48 expiry
    ) external view {
        if (!factory.pools(address(_pool))) revert NotAPool();

        if (address(_pool.lendToken()) != address(lendToken))
            revert DifferentLendToken();

        if (_pool.owner() != owner) revert DifferentPoolOwner();

        if (_pool.expiry() <= expiry) revert InvalidExpiry();
    }

    /// @notice                     Compute the amount of lend tokens to send given collateral deposited
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _mintRatio           MintRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           lend token that is being paid out for collateral
    /// @return                     Lend token amount in lend decimals
    ///
    /// In this function we will need to compute the amount of lend token to send 
    /// based on collateral and mint ratio.
    /// Mint Ratio dictates how many lend tokens we send per unit of collateral. 
    /// MintRatio must always be passed as 18 decimals.
    /// So:
    ///    lentAmount = mintRatio * colAmount
    /// Given the above information, there are only 2 cases to consider when adjusting decimals:
    ///    lendDecimals > colDecimals + 18 OR lendDecimals <= colDecimals + 18
    /// Based on the situation we will either multiply or divide by 10**x where x is difference between desired decimals
    /// and the decimals we actually have. This way we minimize the number of divisions to at most one and 
    /// impact of such division is minimal as it is a division by 10**x and only acts as a mean of reducing decimals count.
    function _computePayoutAmount(uint256 _colDepositAmount, uint256 _mintRatio, IERC20 _colToken, IERC20 _lendToken)
        public
        view
        returns (uint256)
    {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals >= lendDecimals){
            return (_colDepositAmount * _mintRatio) / (10**(colDecimals + mintDecimals - lendDecimals));
        }else{
            return (_colDepositAmount * _mintRatio) * (10**(lendDecimals - colDecimals - mintDecimals));
        }
    }

    /// @notice                     Compute the amount of debt to assign to the user during the . 
    /// @dev                        Uses the estimate sent from previous pool if it is within 1% of computed value
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _mintRatio           MintRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @param _estimate            Amount of lend token that is suggested by the previous pool to avoid additional division
    /// @return                     Lend token amount in lend decimals
    ///
    /// This function is used exclusively on rollover.
    /// Rollover process entails that we pay off all our fees and send all of our 
    /// available or required (in case where MintRatio is higher in the second pool) 
    /// collateral to a borrow function of the new pool.
    /// Basically our goal is to make borrow amount (without fees) in the second pool the same as in the first pool.
    /// Since we are performing a regular borrow in the second pool we will end up computing the amount of debt again.
    /// This will potentially result in truncation errors and potentially bad debt.
    /// For this reason we should be able to pass the amount owed from the first pool directly to the second pool. 
    /// In order to prevent pools sending arbitrary debt amounts, we still perform the computation and check that the passed
    /// debt amount is within the allowed threshold from the computed amount. 
    function _computePayoutAmountWithEstimate(
        uint256 _colDepositAmount, 
        uint256 _mintRatio, 
        IERC20 _colToken, 
        IERC20 _lendToken,
        uint256 _estimate
    )
        external
        view
        returns (uint256)
    {
        uint256 compute = _computePayoutAmount(_colDepositAmount,  _mintRatio,  _colToken,  _lendToken);
        uint256 threshold = compute * 1_0000 / 100_0000; // Suggested debt should be within 1% of the computed debt
        if (compute + threshold <= _estimate || compute - threshold >= _estimate){
            return _estimate;
        }else{
            return compute;
        }
    }

    function _computeCollateralReturn(uint256 _repayAmount, uint256 _mintRatio, IERC20 colToken, IERC20 lendToken) 
        external 
        view 
        returns (uint256)
    {
        uint8 lendDecimals = lendToken.decimals();
        uint8 colDecimals = colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) {
            return _repayAmount / (_mintRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        }else{
            return _repayAmount * 10**(colDecimals + mintDecimals - lendDecimals) / _mintRatio;
        }
    }


    function _computeReimbursement(uint256 _colAmount, uint256 _mintRatio, uint256 _newMintRatio) 
        external 
        pure 
        returns (uint256)
    {
        return (_colAmount * (_newMintRatio - _mintRatio)) /
            _newMintRatio;
    }


    ///@notice Check if col price is below mint ratio
    function isValidPrice(
        IVendorOracle priceFeed,
        IERC20 colToken, 
        IERC20 lendToken,
        uint256 mintRatio
    ) external view returns (bool) {
        if (address(priceFeed) == address(0)) revert OracleNotSet();
        int256 priceLend = priceFeed.getPriceUSD(address(lendToken));
        int256 priceCol = priceFeed.getPriceUSD(address(colToken));
        if (priceLend != -1 && priceCol != -1) {
            return (priceCol > ((int256(mintRatio) * priceLend) / 1e18));
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../ERC20/IERC20.sol";
import "./IStructs.sol";

interface ILendingPool is IStructs {
    struct UserReport {
        uint256 borrowAmount; // total borrowed in lend token
        uint256 colAmount; // total collateral borrowed
        uint256 totalFees; // total fees owed at the moment
    }

    event Borrow(address borrower, uint256 colDepositAmount, uint256 borrowAmount);
    event Repay(address borrower, uint256 colReturned, uint256 repayAmount);
    event UpdateExpiry(uint48 newExpiry);
    event AddBorrower(address newBorrower);

    function initialize(Data calldata data) external;

    function undercollateralized() external view returns (uint256);

    function mintRatio() external view returns (uint256);

    function lendToken() external view returns (IERC20);

    function colToken() external view returns (IERC20);

    function expiry() external view returns (uint48);

    function borrowOnBehalfOf(address _borrower, uint256 _colDepositAmount, uint256 _rate, uint256 _estimate)
        external;

    function owner() external view returns (address);

    function isPrivate() external view returns (uint256);

    function borrowers(address borrower) external view returns (uint256);

    function disabledBorrow() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPoolFactory {
    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function poolImplementationAddress() external view returns (address);

    function rollBackImplementation() external view returns (address);

    function allowUpgrade() external view returns (bool);

    function isPaused(address _pool) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVendorOracle {
    function getPriceUSD(address base) external view returns (int256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
pragma solidity ^0.8.11;

import "../ERC20/IERC20.sol";

interface IStructs {
    struct Data {
        address deployer;
        uint256 mintRatio;
        address colToken;
        address lendToken;
        uint48 expiry;
        address[] borrowers;
        uint48 protocolFee;
        uint48 protocolColFee;
        address feesManager;
        address oracle;
        address factory;
        uint256 undercollateralized;
    }

    struct UserPoolData{
        uint256 _mintRatio;
        address _colToken;
        address _lendToken;
        uint48 _feeRate;
        uint256 _type;
        uint48 _expiry;
        address[] _borrowers;
        uint256 _undercollateralized;
        uint256 _licenseId;
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