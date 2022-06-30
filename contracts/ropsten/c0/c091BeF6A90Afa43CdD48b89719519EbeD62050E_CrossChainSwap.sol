// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@zetachain/contracts/packages/protocol-contracts/contracts/ZetaInteractor.sol";
import "@zetachain/contracts/packages/protocol-contracts/contracts/interfaces/ZetaInterfaces.sol";

import "./CrossChainSwapErrors.sol";

/**
 * Cross-chain swap via 0x API
 */
contract CrossChainSwap is ZetaInteractor, ZetaReceiver, CrossChainSwapErrors {
    bytes32 public constant XC_SWAP_MESSAGE = keccak256("XC_SWAP");
    address public _zetaToken;

    uint256 public constant MASK = type(uint128).max;

    // Events
    event FirstLegSuccess(address sellToken, uint256 sellAmount, uint256 zetaAmount);
    event SecondLegSuccess(address buyToken, uint256 buyAmount, uint256 zetaAmount);
    event FirstLegReverted(address receiver, address buyToken, uint256 zetaAmount);

    struct XcSwapTokenArgs {
        uint256 zetaAmount;
        address payable firstLegSwapTarget;
        bytes firstLegSwapCallData;
        uint256 sellAmount;
        address payable secondLegSwapTarget;
        bytes secondLegSwapCallData;
        address payable allowanceTarget;
        address payable buyTokenAddress;
        address payable sellTokenAddress;
        uint256 destinationChainId;
    }

    constructor(
        address _zetaConnector,
        address _zetaTokenInput
    ) ZetaInteractor(_zetaConnector) {
        _zetaToken = _zetaTokenInput;
    }

    function swapTokensForTokens(XcSwapTokenArgs calldata args)
        external
        payable
    {
        // Validate destination `chainID`
        if (keccak256(interactorsByChainId[args.destinationChainId]) == keccak256(new bytes(0)))
            revert InvalidDestinationChainId();

        // Transfer `sellToken` to this contract from sender
        if (!IERC20(args.sellTokenAddress).transferFrom(msg.sender, address(this), args.sellAmount))
            revert ErrorTransferringTokens(args.sellTokenAddress);

        // Give `0xExchangeProxy` an infinite allowance to spend this contract's `sellToken`.
        if (!IERC20(args.sellTokenAddress).approve(args.allowanceTarget, MASK))
            revert ErrorApprovingTokens(args.sellTokenAddress);

        // Call 1st leg 0x Swap - should buy ZETA
        (bool success1, ) = args.firstLegSwapTarget.call(args.firstLegSwapCallData);
        if (!success1) revert BuyZetaFailed();

        // Approve ZETA
        if (!IERC20(_zetaToken).approve(address(connector), args.zetaAmount))
            revert ErrorApprovingTokens(_zetaToken);

        // Send message
        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: args.destinationChainId,
                destinationAddress: interactorsByChainId[args.destinationChainId],
                gasLimit: 2500000,
                // TODO Also pass revert leg params
                message: abi.encode(
                    XC_SWAP_MESSAGE,
                    msg.sender,
                    args.buyTokenAddress,
                    args.allowanceTarget,
                    args.secondLegSwapTarget,
                    args.secondLegSwapCallData
                ),
                zetaAmount: args.zetaAmount,
                zetaParams: abi.encode("")
            })
        );

        // Emit success event
        emit FirstLegSuccess(args.sellTokenAddress, args.sellAmount, args.zetaAmount);
    }

    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage)
        external
        override
        isValidMessageCall(zetaMessage)
    {
        // Decode incoming message
        (
            bytes32 messageType,
            address receiverAddress,
            address allowanceTarget,
            address payable buyTokenAddress,
            address payable secondLegSwapTarget,
            bytes memory secondLegSwapCallData
        ) = abi.decode(zetaMessage.message, (bytes32, address, address, address, address, bytes));

        // Validate message
        if (messageType != XC_SWAP_MESSAGE) revert InvalidMessageType();
        if (secondLegSwapTarget == address(0)) revert InvalidCallTarget();
        if (secondLegSwapCallData.length == 0) revert InvalidCallData();

        // Give `0xExchangeProxy` an allowance to spend tranferred ZETA.
        if (!IERC20(_zetaToken).approve(allowanceTarget, zetaMessage.zetaAmount))
            revert ErrorApprovingTokens(_zetaToken);

        // Call 2n leg 0x Swap - should sell ZETA
        (bool success1, ) = secondLegSwapTarget.call(secondLegSwapCallData);
        if (!success1) revert SellZetaFailed();

        // Transfer purchased tokens to original sender
        uint256 buyAmount = IERC20(buyTokenAddress).balanceOf(address(this));
        bool success2 = IERC20(buyTokenAddress).transfer(receiverAddress, buyAmount);
        if (!success2) revert ErrorTransferringTokens(buyTokenAddress);

        // Emit success event
        emit SecondLegSuccess(buyTokenAddress, buyAmount, zetaMessage.zetaAmount);
    }

    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert)
        external
        override
        isValidRevertCall(zetaRevert)
    {
        // Decode incoming message
        (
            bytes32 messageType,
            address receiverAddress,
            address payable buyTokenAddress,
            address payable secondLegSwapTarget,
            bytes memory secondLegSwapCallData
        ) = abi.decode(zetaRevert.message, (bytes32, address, address, address, bytes));

        // Validate message
        if (messageType != XC_SWAP_MESSAGE) revert InvalidMessageType();
        if (secondLegSwapTarget == address(0)) revert InvalidCallTarget();
        if (secondLegSwapCallData.length == 0) revert InvalidCallData();

        // Emit revert event
        emit FirstLegReverted(receiverAddress, buyTokenAddress, zetaRevert.zetaAmount);
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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ZetaInterfaces.sol";
import "./interfaces/ZetaInteractorErrors.sol";

abstract contract ZetaInteractor is Ownable, ZetaInteractorErrors {
    uint256 internal immutable currentChainId;
    ZetaConnector public connector;

    /**
     * @dev Maps a chain id to its corresponding address of the MultiChainSwap contract
     * The address is expressed in bytes to allow non-EVM chains
     * This mapping is useful, mainly, for two reasons:
     *  - Given a chain id, the contract is able to route a transaction to its corresponding address
     *  - To check that the messages (onZetaMessage, onZetaRevert) come from a trusted source
     */
    mapping(uint256 => bytes) public interactorsByChainId;

    modifier isValidMessageCall(ZetaInterfaces.ZetaMessage calldata zetaMessage) {
        _isValidCaller();
        if (keccak256(zetaMessage.originSenderAddress) != keccak256(interactorsByChainId[zetaMessage.originChainId]))
            revert InvalidZetaMessageCall();
        _;
    }

    modifier isValidRevertCall(ZetaInterfaces.ZetaRevert calldata zetaRevert) {
        _isValidCaller();
        if (zetaRevert.originSenderAddress != address(this)) revert InvalidZetaRevertCall();
        if (zetaRevert.originChainId != currentChainId) revert InvalidZetaRevertCall();
        _;
    }

    constructor(address zetaConnectorAddress) {
        currentChainId = block.chainid;
        connector = ZetaConnector(zetaConnectorAddress);
    }

    function _isValidCaller() private view {
        if (msg.sender != address(connector)) revert InvalidCaller(msg.sender);
    }

    /**
     * @dev Useful for contracts that inherit from this one
     */
    function isValidChainId(uint256 chainId) internal view returns (bool) {
        return (keccak256(interactorsByChainId[chainId]) != keccak256(new bytes(0)));
    }

    function setInteractorByChainId(uint256 destinationChainId, bytes calldata contractAddress) external onlyOwner {
        interactorsByChainId[destinationChainId] = contractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ZetaInterfaces {
    /**
     * @dev Use SendInput to interact with the Connector: connector.send(SendInput)
     */
    struct SendInput {
        /// @dev Chain id of the destination chain. More about chain ids https://docs.zetachain.com/learn/glossary#chain-id
        uint256 destinationChainId;
        /// @dev Address to send to on the destination chain (expressed in bytes since it can be non-EVM)
        bytes destinationAddress;
        /// @dev Gas amount limit for the destination chain's transaction
        uint256 gasLimit;
        /// @dev An encoded, arbitrary message to be parsed by the destination contract
        bytes message;
        /// @dev The amount of ZETA that you want to send cross-chain + the gas fees to be paid for the transaction
        uint256 zetaAmount;
        /// @dev Optional parameters for the ZetaChain protocol
        bytes zetaParams;
    }

    /**
     * @dev Our Connector calls onZetaMessage with this struct as argument
     */
    struct ZetaMessage {
        bytes originSenderAddress;
        uint256 originChainId;
        address destinationAddress;
        uint256 zetaAmount;
        bytes message;
    }

    /**
     * @dev Our Connector calls onZetaRevert with this struct as argument
     */
    struct ZetaRevert {
        address originSenderAddress;
        uint256 originChainId;
        bytes destinationAddress;
        uint256 destinationChainId;
        uint256 zetaAmount;
        bytes message;
    }
}

interface ZetaConnector {
    /**
     * @dev Sending value and data cross-chain is as easy as calling connector.send(SendInput)
     */
    function send(ZetaInterfaces.SendInput calldata input) external;
}

interface ZetaReceiver {
    /**
     * @dev onZetaMessage is called when a cross-chain message reaches a contract
     */
    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage) external;

    /**
     * @dev onZetaRevert is called when a cross-chain message reverts.
     * It's useful to rollback to the original state
     */
    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface CrossChainSwapErrors {
    error ErrorTransferringTokens(address token);

    error ErrorApprovingTokens(address token);

    error InvalidMessageType();

    error InvalidCallTarget();

    error InvalidCallData();

    error BuyZetaFailed();

    error SellZetaFailed();

    error NotImplemented();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ZetaInteractorErrors {
    error InvalidDestinationChainId();

    error InvalidCaller(address caller);

    error InvalidZetaMessageCall();

    error InvalidZetaRevertCall();
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