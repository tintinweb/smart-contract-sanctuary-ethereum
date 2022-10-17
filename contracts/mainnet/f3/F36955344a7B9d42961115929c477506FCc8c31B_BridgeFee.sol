/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IAnyswapRouter.sol



pragma solidity 0.8.0;

interface IAnyswapRouter {
  function anySwapOutNative(address token, address to, uint toChainID) external payable;
  function anySwapOutUnderlying(address token, address to, uint256 amount, uint256 chainId) external;
  function anySwapOut(address token, address to, uint256 amount, uint256 chainId) external;
}

interface AnyswapERC20 {
  function underlying() external view returns (address);
  function Swapout(uint256 amount, address bindaddr) external;
}
// File: contracts/interfaces/IBridgeFee.sol



pragma solidity 0.8.0;

interface IBridgeFee {
    struct Fee {
        uint256 value;
        uint256 precisions;
    }

    function configure(
        address _feeAddress,
        Fee calldata _fee
    ) external;
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/utils/Address.sol



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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/proxy/utils/Initializable.sol



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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.0/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/BridgeFee.sol



pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;





/// @title Bridge Fee
/// @notice This contract is the middleware of MadWallet fee system and the AnySwap bridge contract
contract BridgeFee is Initializable, IBridgeFee {
    /// @notice the default fee percentage of bridging tokens
    Fee public defaultFee;

    address private _owner;

    /// @notice stores the address that will receive the fee
    address public feeAddress;

    /// @notice stores the fee per token
    mapping(address => Fee) public tokenFee;

    event OwnershipTransferred(address oldOwner, address newOwner);
    event BridgeDone(
        address indexed sender,
        address indexed dcrmAddress,
        address indexed tokenAddress,
        uint256 amount,
        uint256 feeAmount
    );

    modifier onlyOwner () {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function initialize() public initializer {
        _owner = msg.sender;
    }

    /// @notice A function to set the primary contract state variables
    /// @param _feeAddress the value for feeAddress
    /// @param _defaultFee the value for defaultFee
    function configure(
        address _feeAddress,
        Fee calldata _defaultFee
    ) external override onlyOwner {
        require(_feeAddress != address(0), "invalid fee address");

        defaultFee = _defaultFee;
        feeAddress = _feeAddress;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice A function to set the fee value for a token
    /// @param tokenAddress the token address
    /// @param fee the struct value of the token fee
    function setTokenFee(address tokenAddress, Fee calldata fee) external onlyOwner {
        tokenFee[tokenAddress] = fee;
    }

    /// @notice A function to set the defaultFee
    /// @param fee the struct value of the default fee
    function setDefaultFee(Fee calldata fee) external onlyOwner {
        defaultFee = fee;
    }

    /// @notice A function to transfer ERC20 tokens to AnySwap Bridge
    /// @param tokenAddress the token address to be bridged
    /// @param amount token amount to be bridged
    /// @param dcrmAddress AnySwap Bridge Address
    function transfer(
        address tokenAddress,
        uint256 amount,
        address dcrmAddress
    ) external {
        require(dcrmAddress != address(0), "invalid dcrm address");
        require(amount > 0, "invalid amount");

        IERC20 token = IERC20(tokenAddress);

        (uint256 feeAmount, uint256 bridgeAmount) = getFeeAmounts(
            amount,
            tokenAddress
        );
        require(token.transferFrom(msg.sender, dcrmAddress, bridgeAmount), "bridge failed");
        require(token.transferFrom(msg.sender, feeAddress, feeAmount), "fee transfer failed");
        emit BridgeDone(msg.sender, dcrmAddress, tokenAddress, bridgeAmount, feeAmount);
    }

    /// @notice A function to transfer native coin to AnySwap Bridge
    function anySwapOutNative(address routerAddress, address anyToken, address recipient, uint256 toChainID) external payable {
        require(routerAddress != address(0), "invalid router address");
        require(msg.value > 0, "invalid amount");

        (uint256 feeAmount, uint256 bridgeAmount) = getFeeAmounts(
            msg.value,
            address(0)
        );

        IAnyswapRouter(routerAddress).anySwapOutNative{value: bridgeAmount}(anyToken, recipient, toChainID);

        (bool feeAmountSent, ) = payable(feeAddress).call{value: feeAmount}("");
        require(feeAmountSent, "fee transfer failed");

        emit BridgeDone(msg.sender, routerAddress, address(0), bridgeAmount, feeAmount);
    }

    function swapOut(address tokenAddress, uint256 amount) external {
        require(amount > 0, "!zero");

        (uint256 feeAmount, uint256 bridgeAmount) = getFeeAmounts(amount, tokenAddress);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), bridgeAmount);
        IERC20(tokenAddress).transferFrom(msg.sender, feeAddress, feeAmount);

        AnyswapERC20(tokenAddress).Swapout(bridgeAmount, msg.sender);

        emit BridgeDone(msg.sender, tokenAddress, tokenAddress, bridgeAmount, feeAmount);
    }

    function anySwapOut(address routerAddress, address anyToken, uint256 amount, uint256 toChainId) external {
        require(amount > 0, "!zero");

        (uint256 feeAmount, uint256 bridgeAmount) = getFeeAmounts(amount, anyToken);
        IERC20(anyToken).transferFrom(msg.sender, address(this), bridgeAmount);
        IERC20(anyToken).transferFrom(msg.sender, feeAddress, feeAmount);

        IAnyswapRouter(routerAddress).anySwapOut(anyToken, msg.sender, bridgeAmount, toChainId);

        emit BridgeDone(msg.sender, routerAddress, anyToken, bridgeAmount, feeAmount);
    }

    function anySwapOutUnderlying(address routerAddress, address anyToken, uint256 amount, uint256 toChainId) external {
        require(amount > 0, "!zero");
        
        address tokenAddress = AnyswapERC20(anyToken).underlying();
        (uint256 feeAmount, uint256 bridgeAmount) = getFeeAmounts(amount, tokenAddress);
        
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), bridgeAmount);
        IERC20(tokenAddress).transferFrom(msg.sender, feeAddress, feeAmount);
        
        IERC20(tokenAddress).approve(routerAddress, bridgeAmount);
        IAnyswapRouter(routerAddress).anySwapOutUnderlying(anyToken, msg.sender, bridgeAmount, toChainId);

        emit BridgeDone(msg.sender, routerAddress, tokenAddress, bridgeAmount, feeAmount);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /// @param _totalAmount the amount has been transferred to this contract
    /// @param tokenAddress the address of the token
    function getFeeAmounts(
        uint256 _totalAmount,
        address tokenAddress
    ) internal view returns (uint256, uint256) {
        Fee memory fee = tokenFee[tokenAddress];

        if (fee.value == 0) {
            fee = defaultFee;
        }
        uint256 feeAmount = _totalAmount * fee.value / 100 / 10 ** fee.precisions;
        uint256 bridgeAmount = _totalAmount - feeAmount;

        return (feeAmount, bridgeAmount);
    }
}