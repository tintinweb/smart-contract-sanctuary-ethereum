// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../ZetaConnector.base.sol";
import "../ZetaInterfaces.sol";

interface ZetaToken is IERC20 {
    function burnFrom(address account, uint256 amount) external;

    function mint(
        address mintee,
        uint256 value,
        bytes32 internalSendHash
    ) external;
}

contract ZetaConnectorNonEth is ZetaConnectorBase {
    constructor(
        address _zetaTokenAddress,
        address _tssAddress,
        address _tssAddressUpdater
    ) ZetaConnectorBase(_zetaTokenAddress, _tssAddress, _tssAddressUpdater) {}

    function getLockedAmount() public view returns (uint256) {
        return ZetaToken(zetaToken).balanceOf(address(this));
    }

    function send(ZetaInterfaces.SendInput calldata input) external override whenNotPaused {
        ZetaToken(zetaToken).burnFrom(msg.sender, input.zetaAmount);

        emit ZetaSent(
            msg.sender,
            input.destinationChainId,
            input.destinationAddress,
            input.zetaAmount,
            input.gasLimit,
            input.message,
            input.zetaParams
        );
    }

    function onReceive(
        bytes calldata originSenderAddress,
        uint256 originChainId,
        address destinationAddress,
        uint256 zetaAmount,
        bytes calldata message,
        bytes32 internalSendHash
    ) external override whenNotPaused onlyTssAddress {
        ZetaToken(zetaToken).mint(destinationAddress, zetaAmount, internalSendHash);

        if (message.length > 0) {
            ZetaReceiver(destinationAddress).onZetaMessage(
                ZetaInterfaces.ZetaMessage(originSenderAddress, originChainId, destinationAddress, zetaAmount, message)
            );
        }

        emit ZetaReceived(
            originSenderAddress,
            originChainId,
            destinationAddress,
            zetaAmount,
            message,
            internalSendHash
        );
    }

    function onRevert(
        address originSenderAddress,
        uint256 originChainId,
        bytes calldata destinationAddress,
        uint256 destinationChainId,
        uint256 zetaAmount,
        bytes calldata message,
        bytes32 internalSendHash
    ) external override whenNotPaused onlyTssAddress {
        ZetaToken(zetaToken).mint(originSenderAddress, zetaAmount, internalSendHash);

        if (message.length > 0) {
            ZetaReceiver(originSenderAddress).onZetaRevert(
                ZetaInterfaces.ZetaRevert(
                    originSenderAddress,
                    originChainId,
                    destinationAddress,
                    destinationChainId,
                    zetaAmount,
                    message
                )
            );
        }

        emit ZetaReverted(
            originSenderAddress,
            originChainId,
            destinationChainId,
            destinationAddress,
            zetaAmount,
            message,
            internalSendHash
        );
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./ZetaReceiver.sol";
import "./ZetaInterfaces.sol";

contract ZetaConnectorBase is Pausable {
    address public zetaToken;

    /**
     * @dev Collectively hold by Zeta blockchain validators.
     */
    address public tssAddress;
    address public tssAddressUpdater;

    event ZetaSent(
        address indexed originSenderAddress,
        uint256 destinationChainId,
        bytes destinationAddress,
        uint256 zetaAmount,
        uint256 gasLimit,
        bytes message,
        bytes zetaParams
    );
    event ZetaReceived(
        bytes originSenderAddress,
        uint256 indexed originChainId,
        address indexed destinationAddress,
        uint256 zetaAmount,
        bytes message,
        bytes32 indexed internalSendHash
    );
    event ZetaReverted(
        address originSenderAddress,
        uint256 originChainId,
        uint256 indexed destinationChainId,
        bytes indexed destinationAddress,
        uint256 zetaAmount,
        bytes message,
        bytes32 indexed internalSendHash
    );

    constructor(
        address _zetaTokenAddress,
        address _tssAddress,
        address _tssAddressUpdater
    ) {
        zetaToken = _zetaTokenAddress;
        tssAddress = _tssAddress;
        tssAddressUpdater = _tssAddressUpdater;
    }

    modifier onlyTssAddress() {
        require(msg.sender == tssAddress, "ZetaConnector: only TSS address can call this function");
        _;
    }

    modifier onlyTssUpdater() {
        require(msg.sender == tssAddressUpdater, "ZetaConnector: only TSS updater can call this function");
        _;
    }

    // update the TSS Address in case of Zeta blockchain validator nodes churn
    function updateTssAddress(address _tssAddress) external onlyTssUpdater {
        require(_tssAddress != address(0), "ZetaConnector: invalid tssAddress");

        tssAddress = _tssAddress;
    }

    // Change the ownership of tssAddressUpdater to the Zeta blockchain TSS nodes.
    // Effectively, only Zeta blockchain validators collectively can update TSS Address afterwards.
    function renounceTssAddressUpdater() external onlyTssUpdater {
        require(tssAddress != address(0), "ZetaConnector: invalid tssAddress");

        tssAddressUpdater = tssAddress;
    }

    function pause() external onlyTssUpdater {
        _pause();
    }

    function unpause() external onlyTssUpdater {
        _unpause();
    }

    function send(ZetaInterfaces.SendInput calldata input) external virtual {}

    function onReceive(
        bytes calldata originSenderAddress,
        uint256 originChainId,
        address destinationAddress,
        uint256 zetaAmount,
        bytes calldata message,
        bytes32 internalSendHash
    ) external virtual {}

    function onRevert(
        address originSenderAddress,
        uint256 originChainId,
        bytes calldata destinationAddress,
        uint256 destinationChainId,
        uint256 zetaAmount,
        bytes calldata message,
        bytes32 internalSendHash
    ) external virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ZetaInterfaces {
    /**
     * @dev Use SendInput to interact with our Connector: connector.send(SendInput)
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
     * @dev Our Connector will call your contract's onZetaMessage using this interface
     */
    struct ZetaMessage {
        bytes originSenderAddress;
        uint256 originChainId;
        address destinationAddress;
        uint256 zetaAmount;
        bytes message;
    }

    /**
     * @dev Our Connector will call your contract's onZetaRevert using this interface
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
pragma solidity ^0.8.12;

import "./ZetaInterfaces.sol";

interface ZetaReceiver {
    /**
     * @dev onZetaMessage will be called when a cross-chain message is delivered to your contract
     */
    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage) external;

    /**
     * @dev onZetaRevert will be called when a cross-chain message reverts
     * It's useful to rollback your contract's state
     */
    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert) external;
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