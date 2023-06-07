// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ConnectorErrors.sol";
import "./ZetaConnector.base.sol";
import "./interfaces/ZetaInterfaces.sol";

/**
 * @dev ETH implementation of ZetaConnector.
 * This contract manages interactions between TSS and different chains.
 * This version is only for Ethereum network because in the other chains we mint and burn and in this one we lock and unlock.
 */
contract ZetaConnectorEth is ZetaConnectorBase {
    constructor(
        address zetaToken_,
        address tssAddress_,
        address tssAddressUpdater_,
        address pauserAddress_
    ) ZetaConnectorBase(zetaToken_, tssAddress_, tssAddressUpdater_, pauserAddress_) {}

    function getLockedAmount() external view returns (uint256) {
        return IERC20(zetaToken).balanceOf(address(this));
    }

    /**
     * @dev Entrypoint to send data through ZetaChain
     * This call locks the token on the contract and emits an event with all the data needed by the protocol.
     */
    function send(ZetaInterfaces.SendInput calldata input) external override whenNotPaused {
        bool success = IERC20(zetaToken).transferFrom(msg.sender, address(this), input.zetaValueAndGas);
        if (!success) revert ZetaTransferError();

        emit ZetaSent(
            tx.origin,
            msg.sender,
            input.destinationChainId,
            input.destinationAddress,
            input.zetaValueAndGas,
            input.destinationGasLimit,
            input.message,
            input.zetaParams
        );
    }

    /**
     * @dev Handler to receive data from other chain.
     * This method can be called only by TSS.
     * Transfers the Zeta tokens to destination and calls onZetaMessage if it's needed.
     */
    function onReceive(
        bytes calldata zetaTxSenderAddress,
        uint256 sourceChainId,
        address destinationAddress,
        uint256 zetaValue,
        bytes calldata message,
        bytes32 internalSendHash
    ) external override onlyTssAddress {
        bool success = IERC20(zetaToken).transfer(destinationAddress, zetaValue);
        if (!success) revert ZetaTransferError();

        if (message.length > 0) {
            ZetaReceiver(destinationAddress).onZetaMessage(
                ZetaInterfaces.ZetaMessage(zetaTxSenderAddress, sourceChainId, destinationAddress, zetaValue, message)
            );
        }

        emit ZetaReceived(zetaTxSenderAddress, sourceChainId, destinationAddress, zetaValue, message, internalSendHash);
    }

    /**
     * @dev Handler to receive errors from other chain.
     * This method can be called only by TSS.
     * Transfers the Zeta tokens to destination and calls onZetaRevert if it's needed.
     */
    function onRevert(
        address zetaTxSenderAddress,
        uint256 sourceChainId,
        bytes calldata destinationAddress,
        uint256 destinationChainId,
        uint256 remainingZetaValue,
        bytes calldata message,
        bytes32 internalSendHash
    ) external override whenNotPaused onlyTssAddress {
        bool success = IERC20(zetaToken).transfer(zetaTxSenderAddress, remainingZetaValue);
        if (!success) revert ZetaTransferError();

        if (message.length > 0) {
            ZetaReceiver(zetaTxSenderAddress).onZetaRevert(
                ZetaInterfaces.ZetaRevert(
                    zetaTxSenderAddress,
                    sourceChainId,
                    destinationAddress,
                    destinationChainId,
                    remainingZetaValue,
                    message
                )
            );
        }

        emit ZetaReverted(
            zetaTxSenderAddress,
            sourceChainId,
            destinationChainId,
            destinationAddress,
            remainingZetaValue,
            message,
            internalSendHash
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Interface with connector custom errors
 */
interface ConnectorErrors {
    // @dev Thrown when caller is not the address defined as paused address
    error CallerIsNotPauser(address caller);

    // @dev Thrown when caller is not the address defined as TSS address
    error CallerIsNotTss(address caller);

    // @dev Thrown when caller is not the address defined as TSS Updater address
    error CallerIsNotTssUpdater(address caller);

    // @dev Thrown when caller is not the address defined as TSS or TSS Updater address
    error CallerIsNotTssOrUpdater(address caller);

    // @dev Thrown when Zeta can't be transferred for some reason
    error ZetaTransferError();

    // @dev Thrown when maxSupply will be exceed if minting will proceed
    error ExceedsMaxSupply(uint256 maxSupply);
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
        /// @dev Address receiving the message on the destination chain (expressed in bytes since it can be non-EVM)
        bytes destinationAddress;
        /// @dev Gas limit for the destination chain's transaction
        uint256 destinationGasLimit;
        /// @dev An encoded, arbitrary message to be parsed by the destination contract
        bytes message;
        /// @dev ZETA to be sent cross-chain + ZetaChain gas fees + destination chain gas fees (expressed in ZETA)
        uint256 zetaValueAndGas;
        /// @dev Optional parameters for the ZetaChain protocol
        bytes zetaParams;
    }

    /**
     * @dev Our Connector calls onZetaMessage with this struct as argument
     */
    struct ZetaMessage {
        bytes zetaTxSenderAddress;
        uint256 sourceChainId;
        address destinationAddress;
        /// @dev Remaining ZETA from zetaValueAndGas after subtracting ZetaChain gas fees and destination gas fees
        uint256 zetaValue;
        bytes message;
    }

    /**
     * @dev Our Connector calls onZetaRevert with this struct as argument
     */
    struct ZetaRevert {
        address zetaTxSenderAddress;
        uint256 sourceChainId;
        bytes destinationAddress;
        uint256 destinationChainId;
        /// @dev Equals to: zetaValueAndGas - ZetaChain gas fees - destination chain gas fees - source chain revert tx gas fees
        uint256 remainingZetaValue;
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

/**
 * @dev ZetaTokenConsumer makes it easier to handle the following situations:
 *   - Getting Zeta using native coin (to pay for destination gas while using `connector.send`)
 *   - Getting Zeta using a token (to pay for destination gas while using `connector.send`)
 *   - Getting native coin using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 *   - Getting a token using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 * @dev The interface can be implemented using different strategies, like UniswapV2, UniswapV3, etc
 */
interface ZetaTokenConsumer {
    event EthExchangedForZeta(uint256 amountIn, uint256 amountOut);
    event TokenExchangedForZeta(address token, uint256 amountIn, uint256 amountOut);
    event ZetaExchangedForEth(uint256 amountIn, uint256 amountOut);
    event ZetaExchangedForToken(address token, uint256 amountIn, uint256 amountOut);

    function getZetaFromEth(address destinationAddress, uint256 minAmountOut) external payable returns (uint256);

    function getZetaFromToken(
        address destinationAddress,
        uint256 minAmountOut,
        address inputToken,
        uint256 inputTokenAmount
    ) external returns (uint256);

    function getEthFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        uint256 zetaTokenAmount
    ) external returns (uint256);

    function getTokenFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        address outputToken,
        uint256 zetaTokenAmount
    ) external returns (uint256);
}

interface ZetaCommonErrors {
    error InvalidAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/ConnectorErrors.sol";
import "./interfaces/ZetaInterfaces.sol";

/**
 * @dev Main abstraction of ZetaConnector.
 * This contract manages interactions between TSS and different chains.
 * There's an instance of this contract on each chain supported by ZetaChain.
 */
contract ZetaConnectorBase is ConnectorErrors, Pausable {
    address public immutable zetaToken;

    /**
     * @dev Multisig contract to pause incoming transactions.
     * The responsibility of pausing outgoing transactions is left to the protocol for more flexibility.
     */
    address public pauserAddress;

    /**
     * @dev Collectively held by ZetaChain validators.
     */
    address public tssAddress;

    /**
     * @dev This address will start pointing to a multisig contract, then it will become the TSS address itself.
     */
    address public tssAddressUpdater;

    event ZetaSent(
        address sourceTxOriginAddress,
        address indexed zetaTxSenderAddress,
        uint256 indexed destinationChainId,
        bytes destinationAddress,
        uint256 zetaValueAndGas,
        uint256 destinationGasLimit,
        bytes message,
        bytes zetaParams
    );

    event ZetaReceived(
        bytes zetaTxSenderAddress,
        uint256 indexed sourceChainId,
        address indexed destinationAddress,
        uint256 zetaValue,
        bytes message,
        bytes32 indexed internalSendHash
    );

    event ZetaReverted(
        address zetaTxSenderAddress,
        uint256 sourceChainId,
        uint256 indexed destinationChainId,
        bytes destinationAddress,
        uint256 remainingZetaValue,
        bytes message,
        bytes32 indexed internalSendHash
    );

    event TSSAddressUpdated(address zetaTxSenderAddress, address newTssAddress);

    event PauserAddressUpdated(address updaterAddress, address newTssAddress);

    /**
     * @dev Constructor requires initial addresses.
     * zetaToken address is the only immutable one, while others can be updated.
     */
    constructor(address zetaToken_, address tssAddress_, address tssAddressUpdater_, address pauserAddress_) {
        if (
            zetaToken_ == address(0) ||
            tssAddress_ == address(0) ||
            tssAddressUpdater_ == address(0) ||
            pauserAddress_ == address(0)
        ) {
            revert ZetaCommonErrors.InvalidAddress();
        }

        zetaToken = zetaToken_;
        tssAddress = tssAddress_;
        tssAddressUpdater = tssAddressUpdater_;
        pauserAddress = pauserAddress_;
    }

    /**
     * @dev Modifier to restrict actions to pauser address.
     */
    modifier onlyPauser() {
        if (msg.sender != pauserAddress) revert CallerIsNotPauser(msg.sender);
        _;
    }

    /**
     * @dev Modifier to restrict actions to TSS address.
     */
    modifier onlyTssAddress() {
        if (msg.sender != tssAddress) revert CallerIsNotTss(msg.sender);
        _;
    }

    /**
     * @dev Modifier to restrict actions to TSS updater address.
     */
    modifier onlyTssUpdater() {
        if (msg.sender != tssAddressUpdater) revert CallerIsNotTssUpdater(msg.sender);
        _;
    }

    /**
     * @dev Update the pauser address. The only address allowed to do that is the current pauser.
     */
    function updatePauserAddress(address pauserAddress_) external onlyPauser {
        if (pauserAddress_ == address(0)) revert ZetaCommonErrors.InvalidAddress();

        pauserAddress = pauserAddress_;

        emit PauserAddressUpdated(msg.sender, pauserAddress_);
    }

    /**
     * @dev Update the TSS address. The address can be updated by the TSS updater or the TSS address itself.
     */
    function updateTssAddress(address tssAddress_) external {
        if (msg.sender != tssAddress && msg.sender != tssAddressUpdater) revert CallerIsNotTssOrUpdater(msg.sender);
        if (tssAddress_ == address(0)) revert ZetaCommonErrors.InvalidAddress();

        tssAddress = tssAddress_;

        emit TSSAddressUpdated(msg.sender, tssAddress_);
    }

    /**
     * @dev Changes the ownership of tssAddressUpdater to be the one held by the ZetaChain TSS Signer nodes.
     */
    function renounceTssAddressUpdater() external onlyTssUpdater {
        if (tssAddress == address(0)) revert ZetaCommonErrors.InvalidAddress();

        tssAddressUpdater = tssAddress;
    }

    /**
     * @dev Pause the input (send) transactions.
     */

    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @dev Unpause the contract to allow transactions again.
     */

    function unpause() external onlyPauser {
        _unpause();
    }

    /**
     * @dev Entrypoint to send data and value through ZetaChain.
     */
    function send(ZetaInterfaces.SendInput calldata input) external virtual {}

    /**
     * @dev Handler to receive data from other chain.
     * This method can be called only by TSS. Access validation is in implementation.
     */
    function onReceive(
        bytes calldata zetaTxSenderAddress,
        uint256 sourceChainId,
        address destinationAddress,
        uint256 zetaValue,
        bytes calldata message,
        bytes32 internalSendHash
    ) external virtual {}

    /**
     * @dev Handler to receive errors from other chain.
     * This method can be called only by TSS. Access validation is in implementation.
     */
    function onRevert(
        address zetaTxSenderAddress,
        uint256 sourceChainId,
        bytes calldata destinationAddress,
        uint256 destinationChainId,
        uint256 remainingZetaValue,
        bytes calldata message,
        bytes32 internalSendHash
    ) external virtual {}
}