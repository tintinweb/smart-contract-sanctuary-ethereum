// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IHopscotch} from "./IHopscotch.sol";
import {IWrappedNativeToken} from "./IWrappedNativeToken.sol";

contract Hopscotch is IHopscotch, Ownable {
    ////
    // Public structs 
    ////

    struct Request {
        address payable recipient;
        address recipientToken;
        uint256 recipientTokenAmount;
        bool paid;
    }

    ////
    // Storage 
    ////

    Request[] requests;
    address public immutable wrappedNativeToken;

    ////
    // Constructor 
    ////

    /// @param _wrappedNativeToken wrapped native token address for the chain
    constructor(address _wrappedNativeToken) {
        wrappedNativeToken = _wrappedNativeToken;
    }

    ////
    // Private functions 
    ////

    /// @notice Pay a native request directly with the native tokens held in this contract
    /// @param requestId id of the request to be paid
    /// @dev The call will revert if:
    ///         * request for requestId does not exist 
    ///         * request is not for the native tokens
    ///         * contract does not hold enough native tokens to fulfil the request 
    function payNativeRequestDirect(uint256 requestId) internal 
    {
        Request storage request = requests[requestId];

        require(request.recipientToken == address(0), "payNativeRequest/requestNotNative");
        require(address(this).balance >= request.recipientTokenAmount, "payNativeRequest/notEnoughNativeTokens");

        (bool success, ) = request.recipient.call{
            value: request.recipientTokenAmount
        }("");
        require(success, "payNativeRequest/nativeTokenSendFailure");
    }

    /// @notice Pay an erc20 request directly with the erc20 tokens held by this contract 
    /// @param requestId id of the request to be paid
    /// @dev The call will revert if:
    ///         * request for requestId does not exist 
    ///         * request is for the native tokens
    ///         * contract does not hold enough requestTokens to pay the request 
    function payErc20RequestDirect(uint256 requestId) internal
    {
        Request storage request = requests[requestId];

        require(request.recipientToken != address(0), "payErc20RequestDirect/requestIsNative");
        require(IERC20(request.recipientToken).balanceOf(address(this)) >= request.recipientTokenAmount, "payErc20RequestDirect/insufficientFunds");

        require(
            IERC20(request.recipientToken).transfer(request.recipient, request.recipientTokenAmount), "payErc20RequestDirect/transferFailed"
        );
    }

    /// @notice Perform a swap from inputToken to outputToken using the swapContractAddress with swapContractCallData  
    /// @param inputToken input token to swap
    /// @param outputToken output token to swap to
    /// @param inputTokenAmountAllowance allowance of inputTokens given to swapContractAddress to perform the swap
    /// @param minimumOutputTokenAmountReceived minumum output token amount recieved from the swap
    /// @param swapContractAddress address of the contract that will perform the swap
    ///                            if no swap is needed due to input and recipient tokens being the same this will not be called 
    /// @param swapContractCallData call data to pass into the swap contract that will perform the swap
    /// @dev The call will revert if
    ///         * inputToken is the same as outputToken
    ///         * inputToken balance of this contract is not at least inputTokenAmountAllowance
    ///         * outputToken balance of this contract is not increaced by at least minimumOutputTokenAmountReceived after the swap 
    ///         * swapContract call reverts
    /// @return inputTokenAmountPaid amount of input tokens paid for the swap
    /// @return outputTokenAmountReceived amount of output tokens recieved from the swap
    function performSwap(address inputToken, address outputToken, uint256 inputTokenAmountAllowance, uint256 minimumOutputTokenAmountReceived, address swapContractAddress, bytes calldata swapContractCallData) internal returns (uint256 inputTokenAmountPaid, uint256 outputTokenAmountReceived)
    {
        // Grab balances before swap to compare with after
        uint256 inputTokenBalanceBeforeSwap = IERC20(inputToken).balanceOf(address(this));
        uint256 outputTokenBalanceBeforeSwap = IERC20(outputToken).balanceOf(address(this));

        // Allow swap contract to spend this amount of swap input tokens
        IERC20(inputToken).approve(swapContractAddress, inputTokenAmountAllowance);

        // Execute swap
        (bool swapSuccess,) = swapContractAddress.call(swapContractCallData);
        require(swapSuccess, "performSwap/swap");

        // Check output balance increaced by at least request amount
        inputTokenAmountPaid = inputTokenBalanceBeforeSwap - IERC20(inputToken).balanceOf(address(this));
        outputTokenAmountReceived = IERC20(outputToken).balanceOf(address(this)) - outputTokenBalanceBeforeSwap;

        require(
            outputTokenAmountReceived >= minimumOutputTokenAmountReceived, "performSwap/notEnoughOutputTokensFromSwap"
        );

        // Revoke input token approval
        IERC20(inputToken).approve(swapContractAddress, 0);
    }

    ////
    // Public functions 
    ////

    function createRequest(address recipientToken, uint256 recipientTokenAmount) external returns (uint256 id) {
        require(recipientTokenAmount > 0, "createRequest/recipientTokenAmountZero");

        id = requests.length;
        requests.push(Request(payable(msg.sender), recipientToken, recipientTokenAmount, false));
        emit RequestCreated(id, msg.sender, recipientToken, recipientTokenAmount);
    }

    function payRequest(
        PayRequestInputParams calldata params
    )
        external
        payable
        returns (uint256 excessNativeTokenBalance, uint256 excessErc20InputTokenBalance, uint256 excessErc20OutputTokenBalance)
    {
        Request storage request = requests[params.requestId];

        require(params.inputTokenAmount > 0, "payRequest/inputTokenAmountZero");
        require(!request.paid, "already paid");
        request.paid = true;

        bool inputIsNative = (params.inputToken == address(0));
        bool outputIsNative = (request.recipientToken == address(0));

        if (inputIsNative) {
            require(address(this).balance >= params.inputTokenAmount, "payRequest/nativeTokenAmountLessThanInputTokenAmount");

            if(!outputIsNative) {
                // Wrap native token
                IWrappedNativeToken(wrappedNativeToken).deposit{value: params.inputTokenAmount}();
            }
        } else {
            // Transfer tokens in
            require(
                IERC20(params.inputToken).transferFrom(msg.sender, address(this), params.inputTokenAmount),
                "payRequest/inputTokenTransferFailed"
            );
        }

        address erc20InputToken = inputIsNative ? wrappedNativeToken : params.inputToken;
        address erc20OutputToken = outputIsNative ? wrappedNativeToken : request.recipientToken;

        // Stright transfer if not overridden by swap below
        uint256 inputTokenAmountPaid = request.recipientTokenAmount; 
        if(erc20InputToken != erc20OutputToken)
        {
            (inputTokenAmountPaid,) = performSwap(erc20InputToken, erc20OutputToken, params.inputTokenAmount, request.recipientTokenAmount, params.swapContractAddress, params.swapContractCallData);
        }

        if(outputIsNative) {
            if(!inputIsNative) {
                // Unwrap
                IWrappedNativeToken(wrappedNativeToken).withdraw(IWrappedNativeToken(wrappedNativeToken).balanceOf(address(this)));
            }

            // Direct send
            payNativeRequestDirect(params.requestId);
        } else {
            // Direct transfer
            payErc20RequestDirect(params.requestId);
        }

        uint256 nativeTokenBalance = address(this).balance;
        uint256 erc20InputTokenBalance = IERC20(erc20InputToken).balanceOf(address(this));
        uint256 erc20OutputTokenBalance = IERC20(erc20OutputToken).balanceOf(address(this));

        emit RequestPaid(params.requestId, msg.sender, params.inputToken, inputTokenAmountPaid);
        return (nativeTokenBalance, erc20InputTokenBalance, erc20OutputTokenBalance);
    }

    function withdraw() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    function withdrawToken(IERC20 token) public onlyOwner {
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "transfer failed");
    }

    function getRequest(uint256 requestId)
        external
        view
        returns (address recipient, address recipientToken, uint256 recipientTokenAmount, bool paid)
    {
        Request storage request = requests[requestId];
        return (request.recipient, request.recipientToken, request.recipientTokenAmount, request.paid);
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IWrappedNativeToken} from "./IWrappedNativeToken.sol";

interface IHopscotch {
    ////
    // Events
    ////

    /// @notice Emitted when a request is created
    /// @param requestId id of the created request
    /// @param recipient recipient of the request
    /// @param recipientToken requested token, zero if it is the native asset
    /// @param recipientTokenAmount requested token amount
    event RequestCreated(
        uint256 indexed requestId,
        address indexed recipient,
        address indexed recipientToken,
        uint256 recipientTokenAmount
    );

    /// @notice Emitted when a request is paid
    /// @param requestId id of the paid request
    /// @param sender sender of the request
    /// @param senderToken sender token, zero address if it was the native asset
    /// @param senderTokenAmount sender token amount used to pay the request
    event RequestPaid(
        uint256 indexed requestId, address indexed sender, address senderToken, uint256 senderTokenAmount
    );

    /// @notice Emitted when tokens are withdraw from this contract
    /// @param token token being withdrawn, zero address for native asset
    /// @param to where is the withdraw is going to
    /// @param amount amount being withdrawn
    event Withdraw(IERC20 indexed token, address indexed to, uint256 amount);

    ////
    // Public structs 
    ////

    /// @param requestId id of the request to be paid
    /// @param inputToken input token the request is being paid with, use zero address for native token 
    /// @param inputTokenAmount amount of input token to pay the request, this should be the quoted amount for the swap data
    /// @param swapContractAddress address of the contract that will perform the swap
    ///                            if no swap is needed due to input and recipient tokens being the same this will not be called 
    /// @param swapContractCallData call data to pass into the swap contract that will perform the swap
    struct PayRequestInputParams {
        uint256 requestId;
        address inputToken;
        uint256 inputTokenAmount;
        address swapContractAddress;
        bytes swapContractCallData;
    }

    ////
    // Public function declarations 
    ////

    /// @notice Create a request for a given token and token amount to be paid to msg.sender
    /// @param recipientToken token being requested, use zero address for native token 
    /// @param recipientTokenAmount the amount of the request token being requested
    /// @dev The call will revert if:
    ///         * recipient token amount is 0
    ///       emits RequestCreated
    /// @return id request id that was created
    function createRequest(address recipientToken, uint256 recipientTokenAmount) external returns (uint256 id);

    /// @notice Pay the request at requestId using the swapContractAddress
    /// @param params params 
    /// @dev The call will revert if:
    ///         * request for requestId does not exist 
    ///         * request has already been paid
    ///         * inputToken is the zero address
    ///         * inputTokenAmount is 0
    ///         * input token approval for this contract from msg.sender is less than inputTokenAmount 
    ///         * swapContractAddress called with swapContractCallData did not output at least the requests recipientTokenAmount of recipientToken
    ///      Excess input or output tokens will be returned to msg.sender
    ///      This will automatically wrap ETH asset if the inputTokenAddress is WETH9 and at least the inputTokenAmount of ETH was sent in
    ///      emits RequestPaid
    /// @return excessNativeTokenBalance amount of left over native tokens after the request was paid 
    /// @return excessErc20InputTokenBalance amount of left input erc20 tokens after the request was paid (wrapped native if the input was native token) 
    /// @return excessErc20OutputTokenBalance amout of left over output erc20 tokens after the request was paid (wrapped native if the output was native token) 
    function payRequest(
        PayRequestInputParams calldata params
    )
        external
        payable
        returns (uint256 excessNativeTokenBalance, uint256 excessErc20InputTokenBalance, uint256 excessErc20OutputTokenBalance);

    /// @notice Withdraw contract balance to the owner
    /// @dev The call will revert if:
    ///         * not called from the contract owner
    ///      emits Withdraw
    function withdraw() external;

    /// @notice Withdraw erc20 token balance to the owner
    /// @param token token to withdraw
    /// @dev The call will revert if:
    ///         * not called from the contract owner
    ///      emits Withdraw
    function withdrawToken(IERC20 token) external;

    /// @notice Get the request for the id
    /// @param requestId request id
    function getRequest(uint256 requestId)
        external
        view
        returns (address recipient, address recipientToken, uint256 recipientTokenAmount, bool paid);

    fallback() external payable;

    receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IWrappedNativeToken is IERC20 {
    /// @notice Deposit native asset to get wrapped native token
    function deposit() external payable;

    /// @notice Withdraw wrapped native asset to get native asset
    function withdraw(uint256) external;
}