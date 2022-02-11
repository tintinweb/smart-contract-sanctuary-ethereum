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

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IExchangeAgent.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IPremiumPool.sol";

contract PremiumPool is IPremiumPool, ReentrancyGuard, Ownable {
    using Address for address;

    address public exchangeAgent;
    address public UNO_TOKEN;
    address public USDC_TOKEN;
    mapping(address => bool) public availableCurrencies;
    address[] public availableCurrencyList;
    mapping(address => bool) public whiteList;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) public SSRP_PREMIUM;
    mapping(address => uint256) public SSIP_PREMIUM;
    mapping(address => uint256) public BACK_BURN_UNO_PREMIUM;
    uint256 public SSRP_PREMIUM_ETH;
    uint256 public SSIP_PREMIUM_ETH;
    uint256 public BACK_BURN_PREMIUM_ETH;

    uint256 private MAX_INTEGER = type(uint256).max;

    event PremiumWithdraw(address indexed _currency, address indexed _to, uint256 _amount);
    event LogBuyBackAndBurn(address indexed _operator, address indexed _premiumPool, uint256 _unoAmount);
    event LogCollectPremium(address indexed _from, address _premiumCurrency, uint256 _premiumAmount);
    event LogDepositToSyntheticSSRPRewarder(address indexed _rewarder, uint256 _amountDeposited);
    event LogDepositToSyntheticSSIPRewarder(address indexed _rewarder, address indexed _currency, uint256 _amountDeposited);
    event LogAddCurrency(address indexed _premiumPool, address indexed _currency);
    event LogRemoveCurrency(address indexed _premiumPool, address indexed _currency);
    event LogMaxApproveCurrency(address indexed _premiumPool, address indexed _currency, address indexed _to);
    event LogMaxDestroyCurrencyAllowance(address indexed _premiumPool, address indexed _currency, address indexed _to);
    event LogAddWhiteList(address indexed _premiumPool, address indexed _whiteListAddress);
    event LogRemoveWhiteList(address indexed _premiumPool, address indexed _whiteListAddress);

    constructor(
        address _exchangeAgent,
        address _unoToken,
        address _usdcToken,
        address _multiSigWallet
    ) {
        require(_exchangeAgent != address(0), "UnoRe: zero exchangeAgent address");
        require(_unoToken != address(0), "UnoRe: zero UNO address");
        require(_usdcToken != address(0), "UnoRe: zero USDC address");
        require(_multiSigWallet != address(0), "UnoRe: zero multisigwallet address");
        exchangeAgent = _exchangeAgent;
        UNO_TOKEN = _unoToken;
        USDC_TOKEN = _usdcToken;
        whiteList[msg.sender] = true;
        transferOwnership(_multiSigWallet);
    }

    modifier onlyAvailableCurrency(address _currency) {
        require(availableCurrencies[_currency], "UnoRe: not allowed currency");
        _;
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "UnoRe: not white list address");
        _;
    }

    receive() external payable {}

    function collectPremiumInETH() external payable override nonReentrant onlyWhiteList {
        uint256 _premiumAmount = msg.value;
        uint256 _premium_SSRP = (_premiumAmount * 1000) / 10000;
        uint256 _premium_SSIP = (_premiumAmount * 7000) / 10000;
        SSRP_PREMIUM_ETH = SSRP_PREMIUM_ETH + _premium_SSRP;
        SSIP_PREMIUM_ETH = SSIP_PREMIUM_ETH + _premium_SSIP;
        BACK_BURN_PREMIUM_ETH = BACK_BURN_PREMIUM_ETH + (_premiumAmount - _premium_SSRP - _premium_SSIP);
        emit LogCollectPremium(msg.sender, address(0), _premiumAmount);
    }

    function collectPremium(address _premiumCurrency, uint256 _premiumAmount)
        external
        override
        nonReentrant
        onlyAvailableCurrency(_premiumCurrency)
        onlyWhiteList
    {
        require(IERC20(_premiumCurrency).balanceOf(msg.sender) >= _premiumAmount, "UnoRe: premium balance overflow");
        TransferHelper.safeTransferFrom(_premiumCurrency, msg.sender, address(this), _premiumAmount);
        uint256 _premium_SSRP = (_premiumAmount * 1000) / 10000;
        uint256 _premium_SSIP = (_premiumAmount * 7000) / 10000;
        SSRP_PREMIUM[_premiumCurrency] = SSRP_PREMIUM[_premiumCurrency] + _premium_SSRP;
        SSIP_PREMIUM[_premiumCurrency] = SSIP_PREMIUM[_premiumCurrency] + _premium_SSIP;
        BACK_BURN_UNO_PREMIUM[_premiumCurrency] =
            BACK_BURN_UNO_PREMIUM[_premiumCurrency] +
            (_premiumAmount - _premium_SSRP - _premium_SSIP);
        emit LogCollectPremium(msg.sender, _premiumCurrency, _premiumAmount);
    }

    function depositToSyntheticSSRPRewarder(address _rewarder) external onlyOwner nonReentrant {
        require(_rewarder != address(0), "UnoRe: zero address");
        require(_rewarder.isContract(), "UnoRe: no contract address");
        uint256 usdcAmountToDeposit = 0;
        if (SSRP_PREMIUM_ETH > 0) {
            TransferHelper.safeTransferETH(exchangeAgent, SSRP_PREMIUM_ETH);
            uint256 convertedAmount = IExchangeAgent(exchangeAgent).convertForToken(address(0), USDC_TOKEN, SSRP_PREMIUM_ETH);
            usdcAmountToDeposit += convertedAmount;
            SSRP_PREMIUM_ETH = 0;
        }
        for (uint256 ii = 0; ii < availableCurrencyList.length; ii++) {
            if (SSRP_PREMIUM[availableCurrencyList[ii]] > 0) {
                if (availableCurrencyList[ii] == USDC_TOKEN) {
                    usdcAmountToDeposit += SSRP_PREMIUM[availableCurrencyList[ii]];
                } else {
                    uint256 convertedUSDCAmount = IExchangeAgent(exchangeAgent).convertForToken(
                        availableCurrencyList[ii],
                        USDC_TOKEN,
                        SSRP_PREMIUM[availableCurrencyList[ii]]
                    );
                    usdcAmountToDeposit += convertedUSDCAmount;
                }
                SSRP_PREMIUM[availableCurrencyList[ii]] = 0;
            }
        }
        if (usdcAmountToDeposit > 0) {
            TransferHelper.safeTransfer(USDC_TOKEN, _rewarder, usdcAmountToDeposit);
            emit LogDepositToSyntheticSSRPRewarder(_rewarder, usdcAmountToDeposit);
        }
    }

    function depositToSyntheticSSIPRewarder(
        address _currency,
        address _rewarder,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_rewarder != address(0), "UnoRe: zero address");
        require(_rewarder.isContract(), "UnoRe: no contract address");
        if (_currency == address(0) && SSIP_PREMIUM_ETH > 0) {
            require(_amount <= SSIP_PREMIUM_ETH, "UnoRe: overflow premium balance");
            TransferHelper.safeTransferETH(_rewarder, _amount);
            SSIP_PREMIUM_ETH -= _amount;
            emit LogDepositToSyntheticSSIPRewarder(_rewarder, _currency, _amount);
        } else {
            if (availableCurrencies[_currency] && SSIP_PREMIUM[_currency] > 0) {
                require(_amount <= SSIP_PREMIUM[_currency], "UnoRe: overflow premium balance");
                TransferHelper.safeTransfer(_currency, _rewarder, _amount);
                SSIP_PREMIUM[_currency] -= _amount;
                emit LogDepositToSyntheticSSIPRewarder(_rewarder, _currency, _amount);
            }
        }
    }

    function buyBackAndBurn() external onlyOwner {
        uint256 unoAmount = 0;
        if (BACK_BURN_PREMIUM_ETH > 0) {
            TransferHelper.safeTransferETH(exchangeAgent, BACK_BURN_PREMIUM_ETH);
            unoAmount += IExchangeAgent(exchangeAgent).convertForToken(address(0), UNO_TOKEN, BACK_BURN_PREMIUM_ETH);
            BACK_BURN_PREMIUM_ETH = 0;
        }
        for (uint256 ii = 0; ii < availableCurrencyList.length; ii++) {
            if (BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]] > 0) {
                uint256 convertedAmount = IExchangeAgent(exchangeAgent).convertForToken(
                    availableCurrencyList[ii],
                    UNO_TOKEN,
                    BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]]
                );
                unoAmount += convertedAmount;
                BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]] = 0;
            }
        }
        if (unoAmount > 0) {
            TransferHelper.safeTransfer(UNO_TOKEN, burnAddress, unoAmount);
        }
        emit LogBuyBackAndBurn(msg.sender, address(this), unoAmount);
    }

    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(_to != address(0), "UnoRe: zero address");
        require(_amount > 0, "UnoRe: zero amount");
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "UnoRe: Insufficient Premium");
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            require(IERC20(_currency).balanceOf(address(this)) >= _amount, "UnoRe: Insufficient Premium");
            TransferHelper.safeTransfer(_currency, _to, _amount);
        }
        emit PremiumWithdraw(_currency, _to, _amount);
    }

    function addCurrency(address _currency) external onlyOwner {
        require(!availableCurrencies[_currency], "Already available");
        availableCurrencies[_currency] = true;
        availableCurrencyList.push(_currency);
        maxApproveCurrency(_currency, exchangeAgent);
        emit LogAddCurrency(address(this), _currency);
    }

    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency], "Not available yet");
        availableCurrencies[_currency] = false;
        uint256 len = availableCurrencyList.length;
        address lastCurrency = availableCurrencyList[len - 1];
        for (uint256 ii = 0; ii < len; ii++) {
            if (_currency == availableCurrencyList[ii]) {
                availableCurrencyList[ii] = lastCurrency;
                availableCurrencyList.pop();
                destroyCurrencyAllowance(_currency, exchangeAgent);
                return;
            }
        }
        emit LogRemoveCurrency(address(this), _currency);
    }

    function maxApproveCurrency(address _currency, address _to) public onlyOwner nonReentrant {
        if (IERC20(_currency).allowance(address(this), _to) < MAX_INTEGER) {
            TransferHelper.safeApprove(_currency, _to, MAX_INTEGER);
            emit LogMaxApproveCurrency(address(this), _currency, _to);
        }
    }

    function destroyCurrencyAllowance(address _currency, address _to) public onlyOwner nonReentrant {
        if (IERC20(_currency).allowance(address(this), _to) > 0) {
            TransferHelper.safeApprove(_currency, _to, 0);
            emit LogMaxDestroyCurrencyAllowance(address(this), _currency, _to);
        }
    }

    function addWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(!whiteList[_whiteListAddress], "UnoRe: white list already");
        whiteList[_whiteListAddress] = true;
        emit LogAddWhiteList(address(this), _whiteListAddress);
    }

    function removeWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(whiteList[_whiteListAddress], "UnoRe: white list removed or unadded already");
        whiteList[_whiteListAddress] = false;
        emit LogRemoveWhiteList(address(this), _whiteListAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchangeAgent {
    function USDC_TOKEN() external view returns (address);

    function getTokenAmountForUSDC(address _token, uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForUSDC(uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForToken(address _token, uint256 _tokenAmount) external view returns (uint256);

    function getTokenAmountForETH(address _token, uint256 _ethAmount) external view returns (uint256);

    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external view returns (uint256);

    function convertForToken(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external returns (uint256);

    function convertForETH(address _token, uint256 _convertAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPool {
    function collectPremium(address _premiumCurrency, uint256 _premiumAmount) external;

    function collectPremiumInETH() external payable;

    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}