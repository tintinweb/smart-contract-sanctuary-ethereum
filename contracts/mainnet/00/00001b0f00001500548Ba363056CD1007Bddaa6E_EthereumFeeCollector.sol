// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { BaseFeeCollector } from "./base/BaseFeeCollector.sol";

import {
    EthereumFeeCollectorInterface,
    WETHInterface
} from "./interfaces/EthereumFeeCollectorInterface.sol";

/**
 * @title   EthereumFeeCollector
 * @author  OpenSea Protocol Team
 * @notice  EthereumFeeCollector is a contract that is used as an
 *          implementation for a beacon proxy. It inherits the
 *          BaseFeeCollector allowing for native token and ERC20
 *          token withdrawals. In addition, allowing for unwrapping
 *          and transferring WETH.
 */
contract EthereumFeeCollector is
    BaseFeeCollector,
    EthereumFeeCollectorInterface
{
    constructor() BaseFeeCollector() {}

    /**
     * @notice Unwraps and withdraws the given amount of WETH tokens from the
     *         provided contract address. Requires the caller to have the
     *         operator role, and the withdrawal wallet to be in the
     *         allowlisted wallets.
     *
     * @param withdrawalWallet      The wallet to be used for withdrawal.
     * @param wrappedTokenContract  The token address to be unwrapped.
     * @param amount                The amount of tokens to be withdrawn.
     */
    function unwrapAndWithdraw(
        address withdrawalWallet,
        address wrappedTokenContract,
        uint256 amount
    ) external override isOperator {
        // Ensure the withdrawal wallet is in the withdrawal wallet mapping.
        if (_withdrawalWallets[withdrawalWallet] != true) {
            revert InvalidWithdrawalWallet(withdrawalWallet);
        }

        // Make the withdraw call on the provided wrapped token.
        (bool result, bytes memory data) = wrappedTokenContract.call(
            abi.encodeWithSelector(WETHInterface.withdraw.selector, amount)
        );

        // Revert if we have a false result.
        if (!result) {
            revert TokenTransferGenericFailure(
                wrappedTokenContract,
                withdrawalWallet,
                0,
                amount
            );
        }

        // Revert if we have a bad return value.
        if (data.length != 0 && data.length >= 32) {
            if (!abi.decode(data, (bool))) {
                revert BadReturnValueFromERC20OnTransfer(
                    wrappedTokenContract,
                    withdrawalWallet,
                    amount
                );
            }
        }

        // Transfer the now unwrapped tokens to the withdrawal address.
        payable(withdrawalWallet).transfer(amount);
    }

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return The name of this contract.
     */
    function name() external pure override returns (string memory) {
        // Return the name of the contract.
        return "ethereum-fee-collector";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { TwoStepOwnable } from "../access/TwoStepOwnable.sol";

import {
    ERC20Interface,
    BaseFeeCollectorInterface
} from "../interfaces/BaseFeeCollectorInterface.sol";

import {
    BaseFeeCollectorEventsAndErrors
} from "../interfaces/BaseFeeCollectorEventsAndErrors.sol";

/**
 * @title   BaseFeeCollector
 * @author  OpenSea Protocol Team
 * @notice  BaseFeeCollector is a contract that is used as an implementation
 *          for a beacon proxy. Allows for withdrawal of the native token
 *          and all ERC20 standard tokens from the proxy. The contract
 *          inherits TwoStepOwnable to allow for ownership modifiers.
 */
contract BaseFeeCollector is
    TwoStepOwnable,
    BaseFeeCollectorInterface,
    BaseFeeCollectorEventsAndErrors
{
    // The operator address.
    address internal _operator;

    // Mapping of valid withdrawal wallets.
    mapping(address => bool) internal _withdrawalWallets;

    /**
     * @dev Throws if called by any account other than the owner or
     *      operator.
     */
    modifier isOperator() {
        if (msg.sender != _operator && msg.sender != owner()) {
            revert InvalidOperator();
        }
        _;
    }

    /**
     * @notice Creates the implementation.
     */
    constructor() {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Deployment must originate from an approved deployer."
        );
    }

    /**
     * @notice External initialization called by the proxy to set the
     *         owner. During upgrading, do not modify the original
     *         variables that were set in previous implementations.
     *
     * @param ownerToSet The address to be set as the owner.
     */
    function initialize(address ownerToSet) external {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)) &&
                owner() == address(0),
            "Initialize must originate from an approved deployer, and the owner must not be set."
        );

        // Call initialize.
        _initialize(ownerToSet);
    }

    /**
     * @notice Internal initialization function to set the owner. During
     *         upgrading, do not modify the original variables that were set
     *         in the previous implementations. Requires this call to be inside
     *         the constructor.
     *
     * @param ownerToSet The address to be set as the owner.
     */
    function _initialize(address ownerToSet) internal {
        // Set the owner of the FeeCollector.
        _setInitialOwner(ownerToSet);
    }

    /**
     * @notice Withdrawals the given amount of ERC20 tokens from the provided
     *         contract address. Requires the caller to have the operator role,
     *         and the withdrawal wallet to be in the allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param tokenContract    The ERC20 token address to be withdrawn.
     * @param amount           The amount of ERC20 tokens to be withdrawn.
     */
    function withdrawERC20Tokens(
        address withdrawalWallet,
        address tokenContract,
        uint256 amount
    ) external override isOperator {
        // Ensure the withdrawal wallet is in the withdrawal wallet mapping.
        if (_withdrawalWallets[withdrawalWallet] != true) {
            revert InvalidWithdrawalWallet(withdrawalWallet);
        }

        // Make the transfer call on the provided ERC20 token.
        (bool result, bytes memory data) = tokenContract.call(
            abi.encodeWithSelector(
                ERC20Interface.transfer.selector,
                withdrawalWallet,
                amount
            )
        );

        // Revert if we have a false result.
        if (!result) {
            revert TokenTransferGenericFailure(
                tokenContract,
                withdrawalWallet,
                0,
                amount
            );
        }

        // Revert if we have a bad return value.
        if (data.length != 0 && data.length >= 32) {
            if (!abi.decode(data, (bool))) {
                revert BadReturnValueFromERC20OnTransfer(
                    tokenContract,
                    withdrawalWallet,
                    amount
                );
            }
        }
    }

    /**
     * @notice Withdrawals the given amount of the native token from this
     *         contract to the withdrawal address. Requires the caller to
     *         have the operator role, and the withdrawal wallet to be in
     *         the allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param amount           The amount of the native token to be withdrawn.
     */
    function withdraw(address withdrawalWallet, uint256 amount)
        external
        override
        isOperator
    {
        // Ensure the withdrawal wallet is in the withdrawal wallet mapping.
        if (_withdrawalWallets[withdrawalWallet] != true) {
            revert InvalidWithdrawalWallet(withdrawalWallet);
        }

        // Ensure the amount to withdraw is valid.
        if (amount > address(this).balance) {
            revert InvalidNativeTokenAmount(amount);
        }

        // Transfer the amount of the native token to the withdrawal address.
        payable(withdrawalWallet).transfer(amount);
    }

    /**
     * @notice Adds a new withdrawal address to the mapping. Requires
     *         the caller to be the owner and the withdrawal
     *         wallet to not be the null address.
     *
     * @param newWithdrawalWallet  The new withdrawal address.
     */
    function addWithdrawAddress(address newWithdrawalWallet)
        external
        override
        onlyOwner
    {
        // Ensure the new owner is not an invalid address.
        if (newWithdrawalWallet == address(0)) {
            revert NewWithdrawalWalletIsNullAddress();
        }

        // Set the new wallet address mapping.
        _setWithdrawalWallet(newWithdrawalWallet, true);
    }

    /**
     * @notice Removes the withdrawal address from the mapping. Requires
     *         the caller to be the owner.
     *
     * @param withdrawalWallet  The withdrawal address to
     *                             remove.
     */
    function removeWithdrawAddress(address withdrawalWallet)
        external
        override
        onlyOwner
    {
        // Set the withdrawal wallet to false.
        _setWithdrawalWallet(withdrawalWallet, false);
    }

    /**
     * @notice Assign the given address with the ability to operate the wallet.
     *         Requires caller to be the owner.
     *
     * @param operatorToAssign The address to assign the operator role.
     */
    function assignOperator(address operatorToAssign)
        external
        override
        onlyOwner
    {
        // Ensure the operator to assign is not an invalid address.
        if (operatorToAssign == address(0)) {
            revert OperatorIsNullAddress();
        }

        // Set the given account as the operator.
        _operator = operatorToAssign;

        // Emit an event indicating the operator has been assigned.
        emit OperatorUpdated(_operator);
    }

    /**
     * @notice An external view function that returns a boolean.
     *
     * @return A boolean that determines if the provided address is
     *         a valid withdrawal wallet.
     */
    function isWithdrawalWallet(address withdrawalWallet)
        external
        view
        override
        returns (bool)
    {
        // Return if the wallet is in the allow list.
        return _withdrawalWallets[withdrawalWallet];
    }

    /**
     * @notice Internal function to set the withdrawal wallet mapping.
     *
     * @param withdrawalAddress The address to be set as the withdrawal
     *                          wallet.
     * @param valueToSet        The boolean to set for the mapping.
     */
    function _setWithdrawalWallet(address withdrawalAddress, bool valueToSet)
        internal
    {
        // Set the withdrawal address mapping.
        _withdrawalWallets[withdrawalAddress] = valueToSet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface WETHInterface {
    function withdraw(uint256 wad) external;
}

/**
 * @title   EthereumFeeCollectorInterface
 * @author  OpenSea Protocol Team
 * @notice  EthereumFeeCollectorInterface contains all external function
 *          interfaces for the fee collector implementation.
 */
interface EthereumFeeCollectorInterface {
    /**
     * @notice Unwraps and withdraws the given amount of WETH tokens from the
     *         provided contract address. Requires the caller to have the
     *         operator role, and the withdrawal wallet to be in the
     *         allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param tokenContract    The WETH token address to be unwrapped.
     * @param amount           The amount of tokens to be withdrawn.
     */
    function unwrapAndWithdraw(
        address withdrawalWallet,
        address tokenContract,
        uint256 amount
    ) external;

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return The name of this contract.
     */
    function name() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/TwoStepOwnableInterface.sol";

/**
 * @title   TwoStepOwnable
 * @author  OpenSea Protocol Team
 * @notice  TwoStepOwnable is a module which provides access control
 *          where the ownership of a contract can be exchanged via a
 *          two step process. A potential owner is set by the current
 *          owner using transferOwnership, then accepted by the new
 *          potential owner using acceptOwnership.
 */
contract TwoStepOwnable is TwoStepOwnableInterface {
    // The address of the owner.
    address private _owner;

    // The address of the new potential owner.
    address private _potentialOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }
        // Continue with function execution.
        _;
    }

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner)
        external
        override
        onlyOwner
    {
        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsNullAddress();
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
        _potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override onlyOwner {
        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {
        // Ensure the caller is the potential owner.
        if (msg.sender != _potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;

        // Emit an event indicating ownership has been transferred.
        emit OwnershipTransferred(_owner, msg.sender);

        // Set the caller as the owner of this contract.
        _owner = msg.sender;
    }

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice A public view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @notice Internal function that sets the inital owner of the
     *         base contract. The initial owner must not be set
     *         previously.
     *
     * @param initialOwner The address to set for initial ownership.
     */
    function _setInitialOwner(address initialOwner) internal {
        // Ensure the initial owner is not an invalid address.
        if (initialOwner == address(0)) {
            revert InitialOwnerIsNullAddress();
        }

        // Ensure the owner has not already been set.
        if (_owner != address(0)) {
            revert OwnerAlreadySet(_owner);
        }

        // Emit an event indicating ownership has been set.
        emit OwnershipTransferred(address(0), initialOwner);

        // Set the initial owner.
        _owner = initialOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ERC20Interface {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

/**
 * @title   BaseFeeCollectorInterface
 * @author  OpenSea Protocol Team
 * @notice  BaseFeeCollectorInterface contains all external function interfaces
 *          for the fee collector implementation.
 */
interface BaseFeeCollectorInterface {
    /**
     * @notice Withdrawals the given amount of ERC20 tokens from the provided
     *         contract address
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param tokenContract    The ERC20 token address to be withdrawn.
     * @param amount           The amount of ERC20 tokens to be withdrawn.
     */
    function withdrawERC20Tokens(
        address withdrawalWallet,
        address tokenContract,
        uint256 amount
    ) external;

    /**
     * @notice Withdrawals the given amount of the native token from this
     *         contract to the withdrawal address. Requires the caller to
     *         have the operator role, and the withdrawal wallet to be in
     *         the allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param amount           The amount of the native token to be withdrawn.
     */
    function withdraw(address withdrawalWallet, uint256 amount) external;

    /**
     * @notice Adds a new withdrawal address to the mapping. Requires
     *         the caller to be the owner and the withdrawal
     *         wallet to not be the null address.
     *
     * @param newWithdrawalWallet  The new withdrawal address.
     */
    function addWithdrawAddress(address newWithdrawalWallet) external;

    /**
     * @notice Removes the withdrawal address from the mapping. Requires
     *         the caller to be the owner.
     *
     * @param withdrawalWallet  The withdrawal address to
     *                             remove.
     */
    function removeWithdrawAddress(address withdrawalWallet) external;

    /**
     * @notice Assign the given address with the ability to operate the wallet.
     *
     * @param operatorToAssign The address to assign the operator role.
     */
    function assignOperator(address operatorToAssign) external;

    /**
     * @notice An external view function that returns a boolean.
     *
     * @return A boolean that determines if the provided address is
     *         a valid withdrawal wallet.
     */
    function isWithdrawalWallet(address withdrawalWallet)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice BaseFeeCollectorEventsAndErrors contains errors and events
 *         related to fee collector interaction.
 */
interface BaseFeeCollectorEventsAndErrors {
    /**
     * @dev Emit an event whenever the contract owner registers a
     *      new operator.
     *
     * @param newOperator The new operator of the contract.
     */
    event OperatorUpdated(address newOperator);

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token,
        address to,
        uint256 amount
    );

    /**
     * @dev Revert with an error when attempting to withdrawal
     *      an amount greater than the current balance.
     */
    error InvalidNativeTokenAmount(uint256 amount);

    /**
     * @dev Revert with an error when attempting to initialize
     *      outside the constructor.
     */
    error InvalidInitialization();

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner of the wallet.
     */
    error InvalidOperator();

    /**
     * @dev Revert with an error when attempting to call a withdrawal
     *      operation with an incorrect withdrawal wallet.
     */
    error InvalidWithdrawalWallet(address withdrawalWallet);

    /**
     * @dev Revert with an error when attempting to set a
     *      new withdrawal wallet and supplying the null address.
     */
    error NewWithdrawalWalletIsNullAddress();

    /**
     * @dev Revert with an error when attempting to set the
     *      new operator and supplying the null address.
     */
    error OperatorIsNullAddress();

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token,
        address to,
        uint256 identifier,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title   TwoStepOwnableInterface
 * @author  OpenSea Protocol Team
 * @notice  TwoStepOwnableInterface contains all external function interfaces,
 *          events and errors for the two step ownable access control module.
 */
interface TwoStepOwnableInterface {
    /**
     * @dev Emit an event whenever the contract owner registers a
     *      new potential owner.
     *
     * @param newPotentialOwner The new potential owner of the contract.
     */
    event PotentialOwnerUpdated(address newPotentialOwner);

    /**
     * @dev Emit an event whenever contract ownership is transferred.
     *
     * @param previousOwner The previous owner of the contract.
     * @param newOwner      The new owner of the contract.
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Revert with an error when attempting to set an owner
     *      that is already set.
     */
    error OwnerAlreadySet(address currentOwner);

    /**
     * @dev Revert with an error when attempting to set the initial
     *      owner and supplying the null address.
     */
    error InitialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner.
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to claim ownership of the
     *      contract with a caller that is not the current potential owner.
     */
    error CallerIsNotNewPotentialOwner();

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);
}