// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

 contract DeployFee is Context {
    // using SafeERC20 for IERC20Metadata;

    // //Chainlink Price Feed Oracle 
    // AggregatorV3Interface internal priceFeed;

    // //Payments Otions
    // bytes32 public constant FIXED_PAYMENT_OPTION =
    //     keccak256("FIXED_PAYMENT_OPTION");
    // bytes32 public constant PERCENTAGE_UPFRONT_PAYMENT_OPTION =
    //     keccak256("PERCENTAGE_UPFRONT_PAYMENT_OPTION");
    // bytes32 public constant COMBINED_PAYMENT_OPTION =
    //     keccak256("COMBINED_PAYMENT_OPTION");

    // //Selected Payment Option
    // bytes32 public deployFeePaymentOption;

    // //Payment Tokens
    // IERC20Metadata public deployFeeFirstToken;
    // IERC20Metadata public deployFeeSecondToken;

    // //Deploy Fee Percentage, 1e18 == 100%
    // uint256 public deployFeePercentageAmount;
    
    // //Deploy Fee Fixed Amount 1e18 == 1 USD
    // uint256 public deployFeeFixedAmount;

    // //Deploy Fee Beneficiary, this address will collect the Fee
    // address public deployFeeBeneficiary;

    // //Constant exponential value used to calculate the deploy fee
    // uint256 constant EXP_VALUE = 1e18;

    // mapping(uint256  => tokenProperties)  TokenProperties;
    // struct tokenProperties{
    //     address tokenAddress;
    //     uint256 amount;
    //     uint256 percentage;
    // }
    

    // function addPlatformToken(uint256 _index , address Address, uint256 _amount, uint256 _percentage ) external {
    //     // tokenProperties[Address].push(tokenProperties(_amount,_percentage));
    //     TokenProperties[Address]= tokenProperties(_amount, _percentage);
    // }
    //  function getPlatformTokens() external view returns (tokenProperties memory)
    //  {
    //      return TokenProperties[Address][tokenProperties];
         
    //  }


// Declare struct
    struct Player {
        address tokenAddress;
        uint256 amount;
        uint256 percentage;
    }
    
    // Declare array
    Player[] public players;
    
    function addPlayer(address _tokenAddress, uint256 _amount,uint256 _percentage) external {
    
       Player memory player = Player(_tokenAddress,_amount,_percentage); // This declaration shadows an existing declaration.
    
       players.push(player); // Member "push" not found or not visible after argument-dependent lookup in struct MyContract.Player memory.
    
    }

    // function getPlayer() external view returns(players){
    //     return players;
    // }



    // /**
    // * @notice Set up the DeployFee contract
    // * @param _deployFeeFixedAmount Deploy Fee Fixed Amount 1e18 == 1 USD
    // * @param _deployFeePercentageAmount Deploy Fee Percentage, 1e18 == 100%
    // * @param _deployFeeBeneficiary Deploy Fee Beneficiary
    // * @param _deployFeeFirstToken First Payment Token, it can be USDT, TUSD, USDC, etc.
    // * @param _deployFeeSecondToken Second Payment Token, it can be USDT, TUSD, USDC, etc.
    // * @param _priceFeed Chainlink Price Feed Oracle
    // * @param _deployFeePaymentOption Selected Payment Fee
    // */
    // function setupDeployFeeInternal(
    //     uint256 _deployFeeFixedAmount,
    //     uint256 _deployFeePercentageAmount,
    //     address _deployFeeBeneficiary,
    //     address _deployFeeFirstToken,
    //     address _deployFeeSecondToken,
    //     address _priceFeed,
    //     bytes32 _deployFeePaymentOption
    // ) internal {
    //     require(
    //         _deployFeePaymentOption == FIXED_PAYMENT_OPTION ||
    //             _deployFeePaymentOption == PERCENTAGE_UPFRONT_PAYMENT_OPTION ||
    //             _deployFeePaymentOption == COMBINED_PAYMENT_OPTION
    //     );
    //     require(
    //         _deployFeeFirstToken != address(0) &&
    //         _deployFeeSecondToken != address(0) &&
    //         _priceFeed != address(0)
    //     );
    //     deployFeeFirstToken = IERC20Metadata(_deployFeeFirstToken);

    //     deployFeeSecondToken = IERC20Metadata(_deployFeeSecondToken);

    //     priceFeed = AggregatorV3Interface(_priceFeed);

    //     deployFeeFixedAmount = _deployFeeFixedAmount;

    //     deployFeePercentageAmount = _deployFeePercentageAmount;

    //     deployFeePaymentOption = _deployFeePaymentOption;

    //     deployFeeBeneficiary = _deployFeeBeneficiary;
    // }

    // /**
    // * @notice Changes the active payment option
    // * @param _deployFeePaymentOption the new active payment option
    // */
    // function changeActivePaymentOptionInternal(bytes32 _deployFeePaymentOption)
    //     internal
    // {
    //     require(
    //         _deployFeePaymentOption == FIXED_PAYMENT_OPTION ||
    //             _deployFeePaymentOption == PERCENTAGE_UPFRONT_PAYMENT_OPTION ||
    //             _deployFeePaymentOption == COMBINED_PAYMENT_OPTION
    //     );
    //     deployFeePaymentOption = _deployFeePaymentOption;
    // }

    // /** 
    // * @notice called by LokrFactory, charge the deploy fee to the user
    // * @param tokenAddress selected token address to pay the fee, 
    // * if its != deployFirstToken || deployFeeSecondToken will charge with the blockchain token
    // * @param isPaid if is paid the fixed value previously, will only charge a small percentage of tokens
    // */
    // function chargeDeployFee(address tokenAddress, bool isPaid)
    //     internal
    // {
    //     if(tokenAddress == address(deployFeeFirstToken) || tokenAddress == address(deployFeeSecondToken)) {
    //         tokenChargeDeployFee(IERC20Metadata(tokenAddress), isPaid);
    //     }
    //     else{
    //         cryptoChargeDeployFee(isPaid);
    //     }
    // }

    // /** 
    // * @param paymentToken token to pay the deploy Fee
    // * @param isPaid if is paid the fixed value previously, will only charge a small percentage of tokens
    // */
    // function tokenChargeDeployFee(IERC20Metadata paymentToken, bool isPaid)
    //     internal
    // {
    //     if (!isPaid) {
    //         (uint256 requiredTokens, ) = calculateRequiredTokens(paymentToken);
    //         paymentToken.safeTransferFrom(
    //             _msgSender(),
    //             deployFeeBeneficiary,
    //             requiredTokens
    //         );
    //     } else {
    //         (, uint256 requiredTokens) = calculateRequiredTokens(paymentToken);
    //         paymentToken.safeTransferFrom(
    //             _msgSender(),
    //             deployFeeBeneficiary,
    //             requiredTokens
    //         );
    //     }
    // }

    // function calculateRequiredTokens(IERC20Metadata paymentToken) internal view returns(uint256 fixedTokenAmount, uint256 percentageTokenAmount) {
    //     uint256 tokenDecimals = 10 ** uint256(paymentToken.decimals());
    //     if(tokenDecimals >= EXP_VALUE) {
    //         fixedTokenAmount = deployFeeFixedAmount * ( tokenDecimals / EXP_VALUE );
    //         percentageTokenAmount = ((deployFeeFixedAmount * deployFeePercentageAmount) / EXP_VALUE) * ( tokenDecimals / EXP_VALUE );
    //     } else {
    //         fixedTokenAmount = deployFeeFixedAmount / ( EXP_VALUE / tokenDecimals );
    //         percentageTokenAmount = ((deployFeeFixedAmount * deployFeePercentageAmount) / EXP_VALUE) / ( EXP_VALUE / tokenDecimals );
    //     }
    // }

    // /** 
    // * @notice charge the deploy fee with the blockchain token
    // * @param isPaid if is paid the fixed value previously, will only charge a small percentage of tokens
    // */
    // function cryptoChargeDeployFee(bool isPaid) internal {
    //     uint256 requiredETH;
    //     if(!isPaid) {
    //         (requiredETH,) = calculateRequiredETH();
    //     } else {
    //         (,requiredETH) = calculateRequiredETH();
    //     }
    //     require(msg.value >= requiredETH, "ERROR: Msg.value is lower than expected");
    //     uint256 ethExceeded = msg.value - requiredETH;
    //     if(ethExceeded > 1 gwei) {
    //         bool sent = payable(_msgSender()).send(ethExceeded);
    //         require(sent, "ERROR: Failed to return exceeded value");
    //     }
    // }

    // function calculateRequiredETH() internal view returns(uint256 fixedRequiredETH, uint256 percentageRequiredETH) {
    //     uint256 priceFeedDecimals = 10 ** uint256(priceFeed.decimals());
    //     (, int ethUsdPrice, , , ) = priceFeed.latestRoundData();
    //     if(priceFeedDecimals >= EXP_VALUE) {
    //         fixedRequiredETH = deployFeeFixedAmount / (uint256(ethUsdPrice) / EXP_VALUE);
    //         percentageRequiredETH = deployFeeFixedAmount / (uint256(ethUsdPrice) / EXP_VALUE) * deployFeePercentageAmount / EXP_VALUE;
    //     } else {
    //         fixedRequiredETH = deployFeeFixedAmount * priceFeedDecimals / uint256(ethUsdPrice);
    //         percentageRequiredETH = deployFeeFixedAmount * priceFeedDecimals / uint256(ethUsdPrice) * deployFeePercentageAmount / EXP_VALUE;
    //     }
    // }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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