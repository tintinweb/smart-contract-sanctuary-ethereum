//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AdminModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Reentrancy gaurd.
     */
    modifier nonReentrant() {
        require(status != 2, "ReentrancyGuard: reentrant call");
        status = 2;
        _;
        status = 1;
    }

    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(auth == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Update auth.
     * @param auth_ address of new auth.
     */
    function updateAuth(address auth_) external onlyAuth {
        auth = auth_;
        emit updateAuthLog(auth_);
    }

    /**
     * @dev Update if vault or not.
     * @param vaultAddr_ address of vault.
     * @param isVault_ true for adding the vault, false for removing.
     */
    function updateVault(address vaultAddr_, bool isVault_) external onlyAuth {
        isVault[vaultAddr_] = isVault_;
        emit updateVaultLog(vaultAddr_, isVault_);
    }

    /**
     * @dev Update premium.
     * @param premium_ new premium.
     */
    function updatePremium(uint256 premium_) external onlyAuth {
        premium = premium_;
        emit updatePremiumLog(premium_);
    }

    /**
     * @dev Update premium.
     * @param premiumEth_ new premium.
     */
    function updatePremiumEth(uint256 premiumEth_) external onlyAuth {
        premiumEth = premiumEth_;
        emit updatePremiumEthLog(premiumEth_);
    }

    /**
     * @dev Function to withdraw premium collected.
     * @param tokens_ list of token addresses.
     * @param amounts_ list of corresponding amounts.
     * @param to_ address to transfer the funds to.
     */
    function withdrawPremium(
        address[] memory tokens_,
        uint256[] memory amounts_,
        address to_
    ) external onlyAuth {
        uint256 length_ = tokens_.length;
        require(amounts_.length == length_, "lengths not same");
        for (uint256 i = 0; i < length_; i++) {
            if (amounts_[i] == type(uint256).max)
                amounts_[i] = IERC20(tokens_[i]).balanceOf(address(this));
            IERC20(tokens_[i]).safeTransfer(to_, amounts_[i]);
        }
        emit withdrawPremiumLog(tokens_, amounts_, to_);
    }
}

contract InstaVaultWrapperImplementation is AdminModule {
    using SafeERC20 for IERC20;

    function deleverageAndWithdraw(
        address vaultAddr_,
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_,
        uint256 unitAmt_,
        bytes memory swapData_,
        uint256 route_,
        bytes memory instaData_
    ) external nonReentrant {
        require(unitAmt_ != 0, "unitAmt_ cannot be zero");
        require(isVault[vaultAddr_], "invalid vault");
        (uint256 exchangePrice_, ) = IVault(vaultAddr_)
            .getCurrentExchangePrice();
        uint256 itokenAmt_;
        if (withdrawAmount_ == type(uint256).max) {
            itokenAmt_ = IERC20(vaultAddr_).balanceOf(msg.sender);
            withdrawAmount_ = (itokenAmt_ * exchangePrice_) / 1e18;
        } else {
            itokenAmt_ = (withdrawAmount_ * 1e18) / exchangePrice_;
        }
        IERC20(vaultAddr_).safeTransferFrom(
            msg.sender,
            address(this),
            itokenAmt_
        );
        address[] memory wethList_ = new address[](1);
        wethList_[0] = address(wethContract);
        uint256[] memory wethAmtList_ = new uint256[](1);
        wethAmtList_[0] = deleverageAmt_;
        bytes memory data_ = abi.encode(
            vaultAddr_,
            withdrawAmount_,
            to_,
            unitAmt_,
            swapData_
        );
        fla.flashLoan(wethList_, wethAmtList_, route_, data_, instaData_);
    }

    struct InstaVars {
        address vaultAddr;
        uint256 withdrawAmt;
        uint256 withdrawAmtAfterFee;
        address to;
        uint256 unitAmt;
        bytes swapData;
        uint256 withdrawalFee;
        uint256 iniWethBal;
        uint256 iniStethBal;
        uint256 finWethBal;
        uint256 finStethBal;
        uint256 iniEthBal;
        uint256 finEthBal;
        uint256 ethReceived;
        uint256 stethReceived;
        uint256 iniTokenBal;
        uint256 finTokenBal;
        bool success;
        uint256 wethCut;
        uint256 wethAmtReceivedAfterSwap;
        address tokenAddr;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 tokenPriceInEth;
        uint256 tokenCut;
    }

    function executeOperation(
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256[] memory premiums_,
        address initiator_,
        bytes memory params_
    ) external returns (bool) {
        require(msg.sender == address(fla), "illegal-caller");
        require(initiator_ == address(this), "illegal-initiator");
        require(
            tokens_.length == 1 && tokens_[0] == address(wethContract),
            "invalid-params"
        );

        InstaVars memory v_;
        (v_.vaultAddr, v_.withdrawAmt, v_.to, v_.unitAmt, v_.swapData) = abi
            .decode(params_, (address, uint256, address, uint256, bytes));
        IVault vault_ = IVault(v_.vaultAddr);
        v_.withdrawalFee = vault_.withdrawalFee();
        v_.withdrawAmtAfterFee =
            v_.withdrawAmt -
            ((v_.withdrawAmt * v_.withdrawalFee) / 1e4);
        wethContract.safeApprove(v_.vaultAddr, amounts_[0]);
        if (v_.vaultAddr == ethVaultAddr) {
            v_.iniEthBal = address(this).balance;
            v_.iniStethBal = stethContract.balanceOf(address(this));
            vault_.deleverageAndWithdraw(
                amounts_[0],
                v_.withdrawAmt,
                address(this)
            );
            v_.finEthBal = address(this).balance;
            v_.finStethBal = stethContract.balanceOf(address(this));
            v_.ethReceived = v_.finEthBal - v_.iniEthBal;
            v_.stethReceived = v_.finStethBal - amounts_[0] - v_.iniStethBal;
            require(
                v_.ethReceived + v_.stethReceived + 1e9 >= v_.withdrawAmtAfterFee,  // Adding small margin for any potential decimal error
                "something-went-wrong"
            );

            v_.iniWethBal = wethContract.balanceOf(address(this));
            stethContract.safeApprove(oneInchAddr, amounts_[0]);
            Address.functionCall(oneInchAddr, v_.swapData, "1Inch-swap-failed");
            v_.finWethBal = wethContract.balanceOf(address(this));
            v_.wethAmtReceivedAfterSwap = v_.finWethBal - v_.iniWethBal;
            require(
                v_.wethAmtReceivedAfterSwap != 0,
                "wethAmtReceivedAfterSwap cannot be zero"
            );
            require(
                v_.wethAmtReceivedAfterSwap >=
                    (amounts_[0] * v_.unitAmt) / 1e18,
                "Too-much-slippage"
            );

            v_.wethCut =
                amounts_[0] +
                premiums_[0] -
                v_.wethAmtReceivedAfterSwap;
            v_.wethCut = v_.wethCut + ((v_.wethCut * premiumEth) / 10000);
            if (v_.wethCut < v_.ethReceived) {
                Address.sendValue(payable(v_.to), v_.ethReceived - v_.wethCut);
                stethContract.safeTransfer(v_.to, v_.stethReceived);
            } else {
                v_.wethCut -= v_.ethReceived;
                stethContract.safeTransfer(
                    v_.to,
                    v_.stethReceived - v_.wethCut
                );
            }
        } else {
            v_.tokenAddr = vault_.token();
            v_.tokenPriceInBaseCurrency = aaveOracle.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle.getAssetPrice(
                address(wethContract)
            );
            v_.tokenPriceInEth =
                (v_.tokenPriceInBaseCurrency * 1e18) /
                v_.ethPriceInBaseCurrency;

            v_.iniTokenBal = IERC20(v_.tokenAddr).balanceOf(address(this));
            v_.iniStethBal = stethContract.balanceOf(address(this));
            vault_.deleverageAndWithdraw(
                amounts_[0],
                v_.withdrawAmt,
                address(this)
            );
            v_.finTokenBal = IERC20(v_.tokenAddr).balanceOf(address(this));
            v_.finStethBal = stethContract.balanceOf(address(this));
            require(
                v_.finTokenBal - v_.iniTokenBal >= (v_.withdrawAmtAfterFee * 99999999 / 100000000), // Adding small margin for any potential decimal error
                "something-went-wrong"
            );
            require(
                v_.finStethBal - v_.iniStethBal + 1e9 >= amounts_[0], // Adding small margin for any potential decimal error
                "something-went-wrong"
            );

            v_.iniWethBal = wethContract.balanceOf(address(this));
            stethContract.safeApprove(oneInchAddr, amounts_[0]);
            Address.functionCall(oneInchAddr, v_.swapData, "1Inch-swap-failed");
            v_.finWethBal = wethContract.balanceOf(address(this));
            v_.wethAmtReceivedAfterSwap = v_.finWethBal - v_.iniWethBal;
            require(
                v_.wethAmtReceivedAfterSwap != 0,
                "wethAmtReceivedAfterSwap cannot be zero"
            );
            require(
                v_.wethAmtReceivedAfterSwap >=
                    (amounts_[0] * v_.unitAmt) / 1e18,
                "Too-much-slippage"
            );
            v_.wethCut =
                amounts_[0] +
                premiums_[0] -
                v_.wethAmtReceivedAfterSwap;
            v_.wethCut = v_.wethCut + ((v_.wethCut * premium) / 10000);
            v_.tokenCut = (v_.tokenPriceInEth * v_.wethCut) / 1e18;
            IERC20(v_.tokenAddr).safeTransfer(
                v_.to,
                v_.withdrawAmtAfterFee - v_.tokenCut
            );
        }
        wethContract.safeTransfer(address(fla), amounts_[0] + premiums_[0]);
        return true;
    }

    // function initialize(address auth_, uint256 premium_) external {
    //     require(status == 0, "only once");
    //     auth = auth_;
    //     premium = premium_;
    //     status = 1;
    // }

    receive() external payable {}
}

pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {
    event updateAuthLog(address auth_);

    event updateVaultLog(address vaultAddr_, bool isVault_);

    event updatePremiumLog(uint256 premium_);

    event updatePremiumEthLog(uint256 premiumEth_);

    event withdrawPremiumLog(
        address[] tokens_,
        uint256[] amounts_,
        address to_
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstantVariables {
    IFla internal constant fla =
        IFla(0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882);
    address internal constant oneInchAddr =
        0x1111111254fb6c44bAC0beD2854e76F90643097d;
    IERC20 internal constant wethContract =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant stethContract =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    address internal constant ethVaultAddr =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;
    IAavePriceOracle internal constant aaveOracle =
        IAavePriceOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);
}

contract Variables is ConstantVariables {
    uint256 internal status;

    address public auth;

    mapping(address => bool) public isVault;

    uint256 public premium; // premium for token vaults (in BPS)

    uint256 public premiumEth; // premium for eth vault (in BPS)
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFla {
    function flashLoan(
        address[] memory tokens_,
        uint256[] memory amts_,
        uint256 route,
        bytes calldata data_,
        bytes calldata instaData_
    ) external;
}

interface IVault {
    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function token() external view returns (address);

    function withdrawalFee() external view returns (uint256);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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