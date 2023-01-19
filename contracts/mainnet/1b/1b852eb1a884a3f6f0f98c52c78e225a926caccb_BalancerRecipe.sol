/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity ^0.8.1;

interface IBalancer{
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    //Balancer params
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}


// File contracts/Recipes/Interfaces/IERC20.sol

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


// File contracts/Recipes/Interfaces/IERC20Metadata.sol

pragma solidity ^0.8.0;
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


// File contracts/Recipes/Interfaces/ILendingLogic.sol

pragma solidity ^0.8.1;

interface ILendingLogic {
    /**
        @notice Get the APR based on underlying token.
        @param _token Address of the underlying token
        @return Interest with 18 decimals
    */
    function getAPRFromUnderlying(address _token) external view returns(uint256);

    /**
        @notice Get the APR based on wrapped token.
        @param _token Address of the wrapped token
        @return Interest with 18 decimals
    */
    function getAPRFromWrapped(address _token) external view returns(uint256);

    /**
        @notice Get the calls needed to lend.
        @param _underlying Address of the underlying token
        @param _amount Amount of the underlying token
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function lend(address _underlying, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the calls needed to unlend
        @param _wrapped Address of the wrapped token
        @param _amount Amount of the underlying tokens
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function unlend(address _wrapped, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the underlying wrapped exchange rate
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRate(address _wrapped) external returns(uint256);

    /**
        @notice Get the underlying wrapped exchange rate in a view (non state changing) way
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRateView(address _wrapped) external view returns(uint256);
}


// File contracts/Recipes/Interfaces/ILendingRegistry.sol

pragma solidity ^0.8.1;

interface ILendingRegistry {
    // Maps wrapped token to protocol
    function wrappedToProtocol(address _wrapped) external view returns(bytes32);
    // Maps wrapped token to underlying
    function wrappedToUnderlying(address _wrapped) external view returns(address);
    function underlyingToProtocolWrapped(address _underlying, bytes32 protocol) external view returns (address);
    function protocolToLogic(bytes32 _protocol) external view returns (address);

    /**
        @notice Set which protocl a wrapped token belongs to
        @param _wrapped Address of the wrapped token
        @param _protocol Bytes32 key of the protocol
    */
    function setWrappedToProtocol(address _wrapped, bytes32 _protocol) external;

    /**
        @notice Set what is the underlying for a wrapped token
        @param _wrapped Address of the wrapped token
        @param _underlying Address of the underlying token
    */
    function setWrappedToUnderlying(address _wrapped, address _underlying) external;

    /**
        @notice Set the logic contract for the protocol
        @param _protocol Bytes32 key of the procol
        @param _logic Address of the lending logic contract for that protocol
    */
    function setProtocolToLogic(bytes32 _protocol, address _logic) external;
    /**
        @notice Set the wrapped token for the underlying deposited in this protocol
        @param _underlying Address of the unerlying token
        @param _protocol Bytes32 key of the protocol
        @param _wrapped Address of the wrapped token
    */
    function setUnderlyingToProtocolWrapped(address _underlying, bytes32 _protocol, address _wrapped) external;

    /**
        @notice Get tx data to lend the underlying amount in a specific protocol
        @param _underlying Address of the underlying token
        @param _amount Amount to lend
        @param _protocol Bytes32 key of the protocol
        @return targets Addresses of the contracts to call
        @return data Calldata for the calls
    */
    function getLendTXData(address _underlying, uint256 _amount, bytes32 _protocol) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the tx data to unlend the wrapped amount
        @param _wrapped Address of the wrapped token
        @param _amount Amount of wrapped token to unlend
        @return targets Addresses of the contracts to call
        @return data Calldata for the calls
    */
    function getUnlendTXData(address _wrapped, uint256 _amount) external view returns(address[] memory targets, bytes[] memory data);   
}


// File contracts/Recipes/Interfaces/IPie.sol

pragma solidity ^0.8.1;
interface IPie is IERC20 {
    function joinPool(uint256 _amount) external;
    function exitPool(uint256 _amount) external;
    function calcTokensForAmount(uint256 _amount) external view  returns(address[] memory tokens, uint256[] memory amounts);
}


// File contracts/Recipes/Interfaces/IPieRegistry.sol

pragma solidity ^0.8.1;
interface IPieRegistry {
    function inRegistry(address _pool) external view returns(bool);
    function entries(uint256 _index) external view returns(address);
    function addSmartPool(address _smartPool) external;
    function removeSmartPool(uint256 _index) external;
}


// File contracts/Recipes/Interfaces/IWETH.sol

pragma solidity ^0.8.1;
interface IWETH is IERC20 {
    function withdraw(uint wad) external;
}


// File contracts/Recipes/OpenZeppelin/Context.sol

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


// File contracts/Recipes/OpenZeppelin/Ownable.sol

pragma solidity ^0.8.0;
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
        _transferOwnership(_msgSender());
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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


// File contracts/Recipes/OpenZeppelin/Address.sol

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


// File contracts/Recipes/OpenZeppelin/SafeERC20.sol

pragma solidity ^0.8.0;
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


// File contracts/Recipes/BalancerRecipeV1.sol

pragma solidity ^0.8.7;
contract BalancerRecipe is Ownable {
    using SafeERC20 for IERC20;

    IWETH immutable WETH;
    ILendingRegistry immutable lendingRegistry;
    IPieRegistry immutable pieRegistry;
    IBalancer balancer = IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    //Failing to query a price is expensive,
    //so we save info about the DEX state to prevent querying the price if it is not viable
    mapping(address => bytes32) balancerViable;

    struct BestPrice{
        uint price;
    }

    error invalidDexIndex(uint16 index);

    constructor(
        address _weth,
        address _lendingRegistry,
        address _pieRegistry
    ) {
        require(_weth != address(0), "WETH_ZERO");
        require(_lendingRegistry != address(0), "LENDING_MANAGER_ZERO");
        require(_pieRegistry != address(0), "PIE_REGISTRY_ZERO");

        WETH = IWETH(_weth);
        lendingRegistry = ILendingRegistry(_lendingRegistry);
        pieRegistry = IPieRegistry(_pieRegistry);

        // Approve max WETH spending on Balancer
        WETH.approve(address(balancer), type(uint256).max);

    }

    function toPie(address _pie, uint256 _outputAmount) external payable {

        // convert to WETH
        address(WETH).call{value: msg.value}("");

        // bake pie
        uint256 outputAmount = _bake(address(WETH), _pie, msg.value, _outputAmount);

        // transfer output
        IERC20(_pie).safeTransfer(_msgSender(), outputAmount);

        // if any WETH left convert it into ETH and send it back
        uint256 wethBalance = WETH.balanceOf(address(this));
        if(wethBalance != 0) {
            // console.log("returning WETH");
            // console.log(wethBalance);
            WETH.withdraw(wethBalance);
            payable(msg.sender).transfer(wethBalance);
        }
    }

    function bake(
        address _outputToken,
        uint256 _maxInput,
        uint256 _mintAmount
    ) external returns(uint256 inputAmountUsed, uint256 outputAmount) {
        IERC20 outputToken = IERC20(_outputToken);

        IERC20(address(WETH)).safeTransferFrom(_msgSender(), address(this), _maxInput);

        outputAmount = _bake(address(WETH), _outputToken, _maxInput, _mintAmount);

        uint256 remainingInputBalance = WETH.balanceOf(address(this));

        if(remainingInputBalance > 0) {
            WETH.transfer(_msgSender(), WETH.balanceOf(address(this)));
        }

        outputToken.safeTransfer(_msgSender(), outputAmount);

        return(inputAmountUsed, outputAmount);
    }

    function _bake(address _inputToken, address _outputToken, uint256 _maxInput, uint256 _mintAmount) internal returns(uint256 outputAmount) {
        require(_inputToken == address(WETH));
        require(pieRegistry.inRegistry(_outputToken));

        swapPie(_outputToken, _mintAmount);

        outputAmount = IERC20(_outputToken).balanceOf(address(this));

        return(outputAmount);
    }

    function swap(address _inputToken, address _outputToken, uint256 _outputAmount) internal {
        if(_inputToken == _outputToken) {
            return;
        }

        address underlying = lendingRegistry.wrappedToUnderlying(_outputToken);
        if(underlying != address(0)) {
            // calc amount according to exchange rate
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_outputToken);
            uint256 exchangeRate = lendingLogic.exchangeRate(_outputToken); // wrapped to underlying
            uint256 underlyingAmount = _outputAmount * exchangeRate / (1e18) + 1;

            swap(_inputToken, underlying, underlyingAmount);
            (address[] memory targets, bytes[] memory data) = lendingLogic.lend(underlying, underlyingAmount, address(this));

            //execute lending transactions
            for(uint256 i = 0; i < targets.length; i ++) {
                (bool success, ) = targets[i].call{ value: 0 }(data[i]);
                require(success, "CALL_FAILED");
            }
            return;
        }
    }

    function swapPie(address _pie, uint256 _outputAmount) internal {
        IPie pie = IPie(_pie);
        (address[] memory tokens, uint256[] memory amounts) = pie.calcTokensForAmount(_outputAmount);

        for(uint256 i = 0; i < tokens.length; i ++) {
            swap(address(WETH), tokens[i], amounts[i]);
            IERC20 token = IERC20(tokens[i]);
            token.approve(_pie, 0);
            token.approve(_pie, amounts[i]);
            require(amounts[i] <= token.balanceOf(address(this)), "We are trying to deposit more then we have");
        }

        pie.joinPool(_outputAmount);
    }

    function getPrice(address _inputToken, address _outputToken, uint256 _outputAmount) public returns(uint256)  {
        if(_inputToken == _outputToken) {
            return _outputAmount;
        }

        address underlying = lendingRegistry.wrappedToUnderlying(_outputToken);
        if(underlying != address(0)) {
            // calc amount according to exchange rate
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_outputToken);
            uint256 exchangeRate = lendingLogic.exchangeRate(_outputToken); // wrapped to underlying
            uint256 underlyingAmount = _outputAmount * exchangeRate / (10**18) + 1;

            return getPrice(_inputToken, underlying, underlyingAmount);
        }

        //At this point we only want price queries from WETH to other token
        require(_inputToken == address(WETH));

        //Input amount from single swap
        BestPrice memory bestPrice = getBestPrice(_inputToken, _outputToken, _outputAmount);

        return bestPrice.price;
    }

    //High gas cost, only queried off-chain
    function getBestPrice(address _assetIn, address _assetOut, uint _amountOut) public returns (BestPrice memory bestPrice){
        uint balancerAmount;

        //GET BALANCER PRICE
        if(balancerViable[_assetOut]!= ""){
            //Get Balancer price
            IBalancer.SwapKind kind = IBalancer.SwapKind.GIVEN_OUT;

            address[] memory assets = new address[](2);
            assets[0] = _assetIn;
            assets[1] = _assetOut;

            IBalancer.BatchSwapStep[] memory swapStep = new IBalancer.BatchSwapStep[](1);
            swapStep[0] = IBalancer.BatchSwapStep(balancerViable[_assetOut], 0, 1, _amountOut, "");

            IBalancer.FundManagement memory funds = IBalancer.FundManagement(payable(msg.sender),false,payable(msg.sender),false);      

            try balancer.queryBatchSwap(kind,swapStep,assets,funds) returns(int[] memory amounts) {
                balancerAmount = uint(amounts[0]);
            } catch {
                balancerAmount = type(uint256).max;
            }
        }
        return bestPrice;
    }

    // NOTE input token must be WETH
    function getPricePie(address _pie, uint256 _pieAmount) public returns(uint256) {
        require(pieRegistry.inRegistry(_pie));

        (address[] memory tokens, uint256[] memory amounts) = IPie(_pie).calcTokensForAmount(_pieAmount);

        uint256 inputAmount = 0;

        for(uint256 i = 0; i < tokens.length; i ++) {
            inputAmount += getBestPrice(address(WETH), tokens[i], amounts[i]).price;
        }

        return inputAmount;
    }

    function getLendingLogicFromWrapped(address _wrapped) internal view returns(ILendingLogic) {
        return ILendingLogic(
                lendingRegistry.protocolToLogic(
                    lendingRegistry.wrappedToProtocol(
                        _wrapped
                    )
                )
        );
    }

    //////////////////////////
    ///Admin Functions ///////
    //////////////////////////

    function setBalancerPoolMapping(address _inputAsset, bytes32 _pool) external onlyOwner {
        balancerViable[_inputAsset] = _pool;
    }

    function saveToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    function saveEth(address payable _to, uint256 _amount) external onlyOwner {
        _to.call{value: _amount}("");
    }
}


// File contracts/Recipes/Interfaces/IBasketFacet.sol

pragma solidity ^0.8.1;

interface IBasketFacet {

    event TokenAdded(address indexed _token);
    event TokenRemoved(address indexed _token);
    event EntryFeeSet(uint256 fee);
    event ExitFeeSet(uint256 fee);
    event AnnualizedFeeSet(uint256 fee);
    event FeeBeneficiarySet(address indexed beneficiary);
    event EntryFeeBeneficiaryShareSet(uint256 share);
    event ExitFeeBeneficiaryShareSet(uint256 share);

    event PoolJoined(address indexed who, uint256 amount);
    event PoolExited(address indexed who, uint256 amount);
    event FeeCharged(uint256 amount);
    event LockSet(uint256 lockBlock);
    event CapSet(uint256 cap);

    /**
        @notice Sets entry fee paid when minting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setEntryFee(uint256 _fee) external;

    /**
        @notice Get the entry fee
        @return Current entry fee
    */
    function getEntryFee() external view returns(uint256);

    /**
        @notice Set the exit fee paid when exiting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setExitFee(uint256 _fee) external;

    /**
        @notice Get the exit fee
        @return Current exit fee
    */
    function getExitFee() external view returns(uint256);

    /**
        @notice Set the annualized fee. Often referred to as streaming fee
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setAnnualizedFee(uint256 _fee) external;

    /**
        @notice Get the annualized fee.
        @return Current annualized fee.
    */
    function getAnnualizedFee() external view returns(uint256);

    /**
        @notice Set the address receiving the fees.
    */
    function setFeeBeneficiary(address _beneficiary) external;

    /**
        @notice Get the fee benificiary
        @return The current fee beneficiary
    */
    function getFeeBeneficiary() external view returns(address);

    /**
        @notice Set the fee beneficiaries share of the entry fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100%
    */
    function setEntryFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the entry fee beneficiary share
        @return Feeshare amount
    */
    function getEntryFeeBeneficiaryShare() external view returns(uint256);

    /**
        @notice Set the fee beneficiaries share of the exit fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100%
    */
    function setExitFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the exit fee beneficiary share
        @return Feeshare amount
    */
    function getExitFeeBeneficiaryShare() external view returns(uint256);

    /**
        @notice Calculate the oustanding annualized fee
        @return Amount of pool tokens to be minted to charge the annualized fee
    */
    function calcOutStandingAnnualizedFee() external view returns(uint256);

    /**
        @notice Charges the annualized fee
    */
    function chargeOutstandingAnnualizedFee() external;

    /**
        @notice Pulls underlying from caller and mints the pool token
        @param _amount Amount of pool tokens to mint
    */
    function joinPool(uint256 _amount) external;

    /**
        @notice Burns pool tokens from the caller and returns underlying assets
    */
    function exitPool(uint256 _amount) external;

    /**
        @notice Get if the pool is locked or not. (not accepting exit and entry)
        @return Boolean indicating if the pool is locked
    */
    function getLock() external view returns (bool);

    /**
        @notice Get the block until which the pool is locked
        @return The lock block
    */
    function getLockBlock() external view returns (uint256);

    /**
        @notice Set the lock block
        @param _lock Block height of the lock
    */
    function setLock(uint256 _lock) external;

    /**
        @notice Get the maximum of pool tokens that can be minted
        @return Cap
    */
    function getCap() external view returns (uint256);

    /**
        @notice Set the maximum of pool tokens that can be minted
        @param _maxCap Max cap
    */
    function setCap(uint256 _maxCap) external;

    /**
        @notice Get the amount of tokens owned by the pool
        @param _token Addres of the token
        @return Amount owned by the contract
    */
    function balance(address _token) external view returns (uint256);

    /**
        @notice Get the tokens in the pool
        @return Array of tokens in the pool
    */
    function getTokens() external view returns (address[] memory);

    /**
        @notice Add a token to the pool. Should have at least a balance of 10**6
        @param _token Address of the token to add
    */
    function addToken(address _token) external;

    /**
        @notice Removes a token from the pool
        @param _token Address of the token to remove
    */
    function removeToken(address _token) external;

    /**
        @notice Checks if a token was added to the pool
        @param _token address of the token
        @return If token is in the pool or not
    */
    function getTokenInPool(address _token) external view returns (bool);

    /**
        @notice Calculate the amounts of underlying needed to mint that pool amount.
        @param _amount Amount of pool tokens to mint
        @return tokens Tokens needed
        @return amounts Amounts of underlying needed
    */
    function calcTokensForAmount(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
        @notice Calculate the amounts of underlying to receive when burning that pool amount
        @param _amount Amount of pool tokens to burn
        @return tokens Tokens returned
        @return amounts Amounts of underlying returned
    */
    function calcTokensForAmountExit(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);
}


// File contracts/Recipes/Interfaces/ICallFacet.sol


pragma solidity ^0.8.1;

interface ICallFacet {

    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event Call(address indexed caller, address indexed target, bytes data, uint256 value);

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool. Reverts if one of the calls fails
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
        @param _values Array of amounts of ETH to send with the call
    */
    function call(
        address[] memory _targets,
        bytes[] memory _calldata,
        uint256[] memory _values
    ) external;

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool without sending any Ether. Reverts if one of the calls fail
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
    */
    function callNoValue(
        address[] memory _targets,
        bytes[] memory _calldata
    ) external;

    /**
        @notice Lets whitelisted callers execute a single arbitrary call from the pool. Reverts if the call fails
        @param _target Address of the target to call
        @param _calldata Calldata of the call
        @param _value Amount of ETH to send with the call
    */
    function singleCall(
        address _target,
        bytes calldata _calldata,
        uint256 _value
    ) external;

    /**
        @notice Add a whitelisted caller. Can only be called by the contract owner
        @param _caller Caller to add
    */
    function addCaller(address _caller) external;

    /**
        @notice Remove a whitelisted caller. Can only be called by the contract owner
    */
    function removeCaller(address _caller) external;

    /**
        @notice Checks if an address is a whitelisted caller
        @param _caller Address to check
        @return If the address is whitelisted
    */
    function canCall(address _caller) external view returns (bool);

    /**
        @notice Get all whitelisted callers
        @return Array of whitelisted callers
    */
    function getCallers() external view returns (address[] memory);
}


// File contracts/Recipes/Interfaces/IERC173.sol


pragma solidity ^0.8.1;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}


// File contracts/Recipes/Interfaces/IERC20Facet.sol


pragma solidity ^0.8.1;

interface IERC20Facet {

    /**
        @notice Get the token name
        @return The token name
    */
    function name() external view returns (string memory);

    /**
        @notice Get the token symbol
        @return The token symbol
    */
    function symbol() external view returns (string memory);

    /**
        @notice Get the amount of decimals
        @return Amount of decimals
    */
    function decimals() external view returns (uint8);

    /**
        @notice Mints tokens. Can only be called by the contract owner or the contract itself
        @param _receiver Address receiving the tokens
        @param _amount Amount to mint
    */
    function mint(address _receiver, uint256 _amount) external;

    /**
        @notice Burns tokens. Can only be called by the contract owner or the contract itself
        @param _from Address to burn from
        @param _amount Amount to burn
    */
    function burn(address _from, uint256 _amount) external;

    /**
        @notice Sets up the metadata and initial supply. Can be called by the contract owner
        @param _initialSupply Initial supply of the token
        @param _name Name of the token
        @param _symbol Symbol of the token
    */
    function initialize(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) external;

    /**
        @notice Set the token name of the contract. Can only be called by the contract owner or the contract itself
        @param _name New token name
    */
    function setName(string calldata _name) external;

    /**
        @notice Set the token symbol of the contract. Can only be called by the contract owner or the contract itself
        @param _symbol New token symbol
    */
    function setSymbol(string calldata _symbol) external;

    /**
        @notice Increase the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to increase by
    */
    function increaseApproval(address _spender, uint256 _amount) external returns (bool);

    /**
        @notice Decrease the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to decrease by
    */
    function decreaseApproval(address _spender, uint256 _amount) external returns (bool);

}


// File contracts/Recipes/Interfaces/IExperiPie.sol


pragma solidity ^0.8.1;
/**
    @title ExperiPie Interface
    @dev Combines all ExperiPie facet interfaces into one
*/
interface IExperiPie is IERC20, IBasketFacet, IERC20Facet, IERC173, ICallFacet {
}


// File contracts/Recipes/OpenZeppelin/ERC20.sol



pragma solidity ^0.8.0;
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}