// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IERC20 } from '../interfaces/IERC20.sol';
import { IExpressExecutable } from '../interfaces/IExpressExecutable.sol';

abstract contract ExpressExecutable is IExpressExecutable {
    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function enableExpressCallWithToken() external virtual returns (bool) {
        return true;
    }

    /// @notice this function is shadowed by the proxy and can be called only internally
    function execute(
        bytes32,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        _execute(sourceChain, sourceAddress, payload);
    }

    /// @notice this function is shadowed by the proxy and can be called only internally
    function executeWithToken(
        bytes32,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function addExpressGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

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

import { IAxelarExecutable } from './IAxelarExecutable.sol';

interface IExpressExecutable is IAxelarExecutable {
    function enableExpressCallWithToken() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IOwnable {
    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferStarted(address indexed newOwner);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    // Get pending ownership transfer
    function pendingOwner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';

// General interface for upgradable contracts
interface IUpgradable is IOwnable {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;

    function contractId() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradable } from '../interfaces/IUpgradable.sol';
import { Ownable } from '../utils/Ownable.sol';

abstract contract Upgradable is Ownable, IUpgradable {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    modifier onlyProxy() {
        // Prevent setup from being called on the implementation
        if (implementation() == address(0)) revert NotProxy();

        _;
    }

    function implementation() public view returns (address implementation_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external override onlyOwner {
        if (IUpgradable(newImplementation).contractId() != IUpgradable(this).contractId())
            revert InvalidImplementation();
        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        if (params.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

            if (!success) revert SetupFailed();
        }

        emit Upgraded(newImplementation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function setup(bytes calldata data) external override onlyProxy {
        _setup(data);
    }

    // solhint-disable-next-line no-empty-blocks
    function _setup(bytes calldata data) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }
        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        uint256 length = addressBytes.length;
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(2 + addressBytes.length * 2);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < length; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }
        return string(stringBytes);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../interfaces/IUpgradable.sol';

abstract contract Ownable is IOwnable {
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    // keccak256('ownership-transfer')
    bytes32 internal constant _OWNERSHIP_TRANSFER_SLOT =
        0x9855384122b55936fbfb8ca5120e63c6537a1ac40caf6ae33502b3c5da8c87d1;

    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner();

        _;
    }

    function owner() public view returns (address owner_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner_ := sload(_OWNER_SLOT)
        }
    }

    function pendingOwner() public view returns (address owner_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner_ := sload(_OWNERSHIP_TRANSFER_SLOT)
        }
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        emit OwnershipTransferStarted(newOwner);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, newOwner)
        }
    }

    function acceptOwnership() external virtual {
        address newOwner = pendingOwner();
        if (newOwner != msg.sender) revert InvalidOwner();

        emit OwnershipTransferred(newOwner);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
            sstore(_OWNER_SLOT, newOwner)
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPermit2 {
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    function transferFrom(address from, address to, uint160 amount, address token) external;

    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRoledPausable {
    event PauserProposed(address indexed currentPauser, address indexed pendingPauser);
    event PauserUpdated(address indexed pendingPauser);
    event Paused();
    event Unpaused();

    error ContractIsPaused();
    error NotPauser();
    error NotPendingPauser();
    error ZeroAddressProvided();

    function updatePauser(address _newPauser) external;

    function acceptPauser() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool value);

    function pauser() external view returns (address value);

    function pendingPauser() external view returns (address value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISquidMulticall {
    enum CallType {
        Default,
        FullTokenBalance,
        FullNativeBalance,
        CollectTokenBalance
    }

    struct Call {
        CallType callType;
        address target;
        uint256 value;
        bytes callData;
        bytes payload;
    }

    error AlreadyRunning();
    error CallFailed(uint256 callPosition, bytes reason);

    function run(Call[] calldata calls) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISquidMulticall} from "./ISquidMulticall.sol";

interface ISquidRouter {
    event CrossMulticallExecuted(bytes32 indexed payloadHash);
    event CrossMulticallFailed(bytes32 indexed payloadHash, bytes reason, address indexed refundRecipient);

    function bridgeCall(
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        address refundRecipient,
        bool forecallEnabled
    ) external payable;

    function callBridge(
        address token,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata calls
    ) external payable;

    function callBridgeCall(
        address token,
        uint256 amount,
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata sourceCalls,
        ISquidMulticall.Call[] calldata destinationCalls,
        address refundRecipient,
        bool forecallEnabled
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeCast160 {
    /// @notice Thrown when a valude greater than type(uint160).max is cast to uint160
    error UnsafeCast();

    /// @notice Safely casts uint256 to uint160
    /// @param value The uint256 to be cast
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) revert UnsafeCast();
        return uint160(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageSlot {
    function setUint256(bytes32 slot, uint256 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getAddress(bytes32 slot) internal view returns (address value) {
        assembly {
            value := sload(slot)
        }
    }

    function setBool(bytes32 slot, bool value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getBool(bytes32 slot) internal view returns (bool value) {
        assembly {
            value := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRoledPausable} from "./interfaces/IRoledPausable.sol";
import {StorageSlot} from "./libraries/StorageSlot.sol";

abstract contract RoledPausable is IRoledPausable {
    using StorageSlot for bytes32;

    bytes32 internal constant PAUSED_SLOT = keccak256("RoledPausable.paused");
    bytes32 internal constant PAUSER_SLOT = keccak256("RoledPausable.pauser");
    bytes32 internal constant PENDING_PAUSER_SLOT = keccak256("RoledPausable.pendingPauser");

    modifier whenNotPaused() {
        if (paused()) revert ContractIsPaused();
        _;
    }

    modifier onlyPauser() {
        if (msg.sender != pauser()) revert NotPauser();
        _;
    }

    constructor() {
        _setPauser(msg.sender);
    }

    function updatePauser(address newPauser) external onlyPauser {
        PENDING_PAUSER_SLOT.setAddress(newPauser);
        emit PauserProposed(msg.sender, newPauser);
    }

    function acceptPauser() external {
        if (msg.sender != pendingPauser()) revert NotPendingPauser();
        _setPauser(msg.sender);
        PENDING_PAUSER_SLOT.setAddress(address(0));
    }

    function pause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(true);
        emit Paused();
    }

    function unpause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(false);
        emit Unpaused();
    }

    function pauser() public view returns (address value) {
        value = PAUSER_SLOT.getAddress();
    }

    function paused() public view returns (bool value) {
        value = PAUSED_SLOT.getBool();
    }

    function pendingPauser() public view returns (address value) {
        value = PENDING_PAUSER_SLOT.getAddress();
    }

    function _setPauser(address _pauser) internal {
        if (_pauser == address(0)) revert ZeroAddressProvided();
        PAUSER_SLOT.setAddress(_pauser);
        emit PauserUpdated(_pauser);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISquidRouter} from "./interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "./interfaces/ISquidMulticall.sol";
import {IPermit2} from "./interfaces/IPermit2.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol";
import {ExpressExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/express/ExpressExecutable.sol";
import {RoledPausable} from "./RoledPausable.sol";
import {AddressToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";
import {StorageSlot} from "./libraries/StorageSlot.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast160} from "./libraries/SafeCast160.sol";

contract SquidRouter is ISquidRouter, ExpressExecutable, Upgradable, RoledPausable {
    using StorageSlot for bytes32;
    using AddressToString for address;
    using SafeERC20 for IERC20;
    using SafeCast160 for uint256;

    IAxelarGasService public immutable gasService;
    ISquidMulticall public immutable squidMulticall;
    IPermit2 public immutable permit2;

    error TransferFailed();
    error Permit2Unavailable();

    modifier onlyIfPermit2() {
        if (address(permit2) == address(0)) revert Permit2Unavailable();
        _;
    }

    constructor(
        address _gateway,
        address _gasService,
        address _multicall,
        address _permit2
    ) ExpressExecutable(_gateway) {
        if (_gateway == address(0) || _gasService == address(0) || _multicall == address(0)) {
            revert ZeroAddressProvided();
        }
        gasService = IAxelarGasService(_gasService);
        squidMulticall = ISquidMulticall(_multicall);
        permit2 = IPermit2(_permit2);
        // Implementation paused by default
        PAUSED_SLOT.setBool(true);
    }

    function bridgeCall(
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        address refundRecipient,
        bool express
    ) external payable whenNotPaused {
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        _transferFrom2(bridgedTokenAddress, msg.sender, address(this), amount);
        _bridgeCall(destinationChain, bridgedTokenSymbol, bridgedTokenAddress, calls, refundRecipient, express);
    }

    function permitBridgeCall(
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature,
        ISquidMulticall.Call[] calldata calls,
        address refundRecipient,
        bool express
    ) external payable whenNotPaused onlyIfPermit2 {
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        _permitTransferFrom(amount, msg.sender, address(this), permit, signature);
        _bridgeCall(destinationChain, bridgedTokenSymbol, bridgedTokenAddress, calls, refundRecipient, express);
    }

    function callBridge(
        address token,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata calls
    ) external payable {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 bridgedTokenAmount = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenAmount);
        gateway.sendToken(destinationChain, destinationAddress, bridgedTokenSymbol, bridgedTokenAmount);
    }

    function permitCallBridge(
        address token,
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata calls
    ) external payable {
        permitFundAndRunMulticall(token, amount, permit, signature, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 bridgedTokenAmount = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenAmount);
        gateway.sendToken(destinationChain, destinationAddress, bridgedTokenSymbol, bridgedTokenAmount);
    }

    function callBridgeCall(
        address token,
        uint256 amount,
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata sourceCalls,
        ISquidMulticall.Call[] calldata destinationCalls,
        address refundRecipient,
        bool express
    ) external payable {
        fundAndRunMulticall(token, amount, sourceCalls);
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        _bridgeCall(
            destinationChain,
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationCalls,
            refundRecipient,
            express
        );
    }

    function permitCallBridgeCall(
        address token,
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature,
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        ISquidMulticall.Call[] calldata sourceCalls,
        ISquidMulticall.Call[] calldata destinationCalls,
        address refundRecipient,
        bool express
    ) external payable {
        permitFundAndRunMulticall(token, amount, permit, signature, sourceCalls);
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        _bridgeCall(
            destinationChain,
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationCalls,
            refundRecipient,
            express
        );
    }

    function fundAndRunMulticall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] memory calls
    ) public payable whenNotPaused {
        uint256 valueToSend;
        if (token == address(0)) {
            valueToSend = amount;
        } else {
            _transferFrom2(token, msg.sender, address(squidMulticall), amount);
        }
        squidMulticall.run{value: valueToSend}(calls);
    }

    function permitFundAndRunMulticall(
        address token,
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature,
        ISquidMulticall.Call[] memory calls
    ) public payable whenNotPaused onlyIfPermit2 {
        uint256 valueToSend;
        if (token == address(0)) {
            valueToSend = amount;
        } else {
            _permitTransferFrom(amount, msg.sender, address(squidMulticall), permit, signature);
        }
        squidMulticall.run{value: valueToSend}(calls);
    }

    function contractId() external pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }

    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata bridgedTokenSymbol,
        uint256
    ) internal override {
        (ISquidMulticall.Call[] memory calls, address refundRecipient) = abi.decode(
            payload,
            (ISquidMulticall.Call[], address)
        );
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 contractBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(squidMulticall), contractBalance);

        try squidMulticall.run(calls) {
            emit CrossMulticallExecuted(keccak256(payload));
        } catch (bytes memory reason) {
            // Refund tokens to refund recepient if swap fails
            IERC20(bridgedTokenAddress).safeTransfer(refundRecipient, contractBalance);
            emit CrossMulticallFailed(keccak256(payload), reason, refundRecipient);
        }
    }

    function _bridgeCall(
        string calldata destinationChain,
        string calldata bridgedTokenSymbol,
        address bridgedTokenAddress,
        ISquidMulticall.Call[] calldata calls,
        address refundRecipient,
        bool express
    ) private {
        if (refundRecipient == address(0)) revert ZeroAddressProvided();

        bytes memory payload = abi.encode(calls, refundRecipient);
        // Only works if destination router has same address
        string memory destinationContractAddress = address(this).toString();
        uint256 bridgedTokenBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        if (address(this).balance > 0) {
            if (express) {
                gasService.payNativeGasForExpressCallWithToken{value: address(this).balance}(
                    address(this),
                    destinationChain,
                    destinationContractAddress,
                    payload,
                    bridgedTokenSymbol,
                    bridgedTokenBalance,
                    refundRecipient
                );
            } else {
                gasService.payNativeGasForContractCallWithToken{value: address(this).balance}(
                    address(this),
                    destinationChain,
                    destinationContractAddress,
                    payload,
                    bridgedTokenSymbol,
                    bridgedTokenBalance,
                    refundRecipient
                );
            }
        }
        _approve(bridgedTokenAddress, address(gateway), bridgedTokenBalance);
        gateway.callContractWithToken(
            destinationChain,
            destinationContractAddress,
            payload,
            bridgedTokenSymbol,
            bridgedTokenBalance
        );
    }

    function _approve(address tokenAddress, address spender, uint256 amount) private {
        if (IERC20(tokenAddress).allowance(address(this), spender) < amount) {
            // Not a security issue since the contract doesn't store tokens
            IERC20(tokenAddress).approve(spender, type(uint256).max);
        }
    }

    function _transferFrom2(address token, address from, address to, uint256 amount) private {
        // Generate calldata for a standard transferFrom call.
        bytes memory inputData = abi.encodeCall(IERC20.transferFrom, (from, to, amount));

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        assembly {
            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(eq(mload(0), 1), iszero(returndatasize())),
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                // We use 0 and 32 to copy up to 32 bytes of return data into the first slot of scratch space.
                call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 32)
            )
        }

        // We'll fall back to using Permit2 if calling transferFrom on the token directly reverted.
        if (!success) {
            // Revert transfer if Permit2 is not available.
            if (address(permit2) == address(0)) revert TransferFailed();
            permit2.transferFrom(from, to, amount.toUint160(), address(token));
        }
    }

    function _permitTransferFrom(
        uint256 amount,
        address from,
        address to,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature
    ) private {
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: to,
            requestedAmount: amount
        });
        permit2.permitTransferFrom(permit, transferDetails, from, signature);
    }

    function _setup(bytes calldata data) internal override {
        address _pauser = abi.decode(data, (address));
        _setPauser(_pauser);
    }
}