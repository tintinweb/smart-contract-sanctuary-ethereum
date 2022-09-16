/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// AxelarDepositService

// File contracts/interfaces/IUpgradable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external pure returns (bytes32);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}


// File contracts/interfaces/IDepositServiceBase.sol

interface IDepositServiceBase {
    error InvalidAddress();
    error InvalidSymbol();
    error NothingDeposited();
    error WrapFailed();
    error UnwrapFailed();
    error TokenApproveFailed();
    error TokenTransferFailed();
    error NativeTransferFailed();

    function gateway() external returns (address);

    function wrappedSymbol() external returns (string memory);

    function wrappedToken() external returns (address);
}


// File contracts/interfaces/IAxelarDepositService.sol

// This should be owned by the microservice that is paying for gas.
interface IAxelarDepositService is IUpgradable, IDepositServiceBase {
    function sendNative(string calldata destinationChain, string calldata destinationAddress) external payable;

    function addressForTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external view returns (address);

    function addressForNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external view returns (address);

    function addressForNativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address recipient
    ) external view returns (address);

    function sendTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external;

    function refundTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol,
        address[] calldata refundTokens
    ) external;

    function sendNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external;

    function refundNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        address[] calldata refundTokens
    ) external;

    function nativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address payable recipient
    ) external;

    function refundNativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address payable recipient,
        address[] calldata refundTokens
    ) external;

    function receiverImplementation() external returns (address receiver);

    function refundToken() external returns (address);
}


// File contracts/interfaces/IAxelarGateway.sol

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

    event TokenSent(address indexed sender, string destinationChain, string destinationAddress, string symbol, uint256 amount);

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


// File contracts/interfaces/IERC20.sol

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


// File contracts/interfaces/IWETH9.sol

// WETH9 specific interface
interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}


// File contracts/util/Upgradable.sol

abstract contract Upgradable is IUpgradable {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;

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

    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) revert InvalidOwner();

        emit OwnershipTransferred(newOwner);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNER_SLOT, newOwner)
        }
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
        if (IUpgradable(newImplementation).contractId() != IUpgradable(this).contractId()) revert InvalidImplementation();
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

    function setup(bytes calldata data) external override {
        // Prevent setup from being called on the implementation
        if (implementation() == address(0)) revert NotProxy();

        _setup(data);
    }

    // solhint-disable-next-line no-empty-blocks
    function _setup(bytes calldata data) internal virtual {}
}


// File contracts/util/BytesStringUtil.sol

library StringToBytes32 {
    error InvalidStringLength();

    function toBytes32(string memory str) internal pure returns (bytes32) {
        // Converting a string to bytes32 for immutable storage
        bytes memory stringBytes = bytes(str);

        // We can store up to 31 bytes of data as 1 byte is for encoding length
        if (stringBytes.length == 0 || stringBytes.length > 31) revert InvalidStringLength();

        uint256 stringNumber = uint256(bytes32(stringBytes));

        // Storing string length as the last byte of the data
        stringNumber |= 0xff & stringBytes.length;
        return bytes32(abi.encodePacked(stringNumber));
    }
}

library Bytes32ToString {
    function toTrimmedString(bytes32 stringData) internal pure returns (string memory converted) {
        // recovering string length as the last byte of the data
        uint256 length = 0xff & uint256(stringData);

        // restoring the string with the correct length
        // solhint-disable-next-line no-inline-assembly
        assembly {
            converted := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(converted, 0x40))
            // store length in memory
            mstore(converted, length)
            // write actual data
            mstore(add(converted, 0x20), stringData)
        }
    }
}


// File contracts/deposit-service/DepositServiceBase.sol

// This should be owned by the microservice that is paying for gas.
contract DepositServiceBase is IDepositServiceBase {
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;

    // Using immutable storage to keep the constants in the bytecode
    address public immutable gateway;
    bytes32 internal immutable wrappedSymbolBytes;

    constructor(address gateway_, string memory wrappedSymbol_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = gateway_;

        // Checking if token symbol exists in the gateway
        if (IAxelarGateway(gateway_).tokenAddresses(wrappedSymbol_) == address(0)) revert InvalidSymbol();

        wrappedSymbolBytes = wrappedSymbol_.toBytes32();
    }

    function wrappedToken() public view returns (address) {
        return IAxelarGateway(gateway).tokenAddresses(wrappedSymbol());
    }

    // @dev Converts bytes32 from immutable storage into a string
    function wrappedSymbol() public view returns (string memory) {
        return wrappedSymbolBytes.toTrimmedString();
    }

    function _safeTransfer(
        address tokenAddress,
        address receiver,
        uint256 amount
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = tokenAddress.call(abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount));
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TokenTransferFailed();
    }
}


// File contracts/deposit-service/DepositReceiver.sol

contract DepositReceiver {
    constructor(bytes memory delegateData, address refundAddress) {
        // Reading the implementation of the AxelarDepositService
        // and delegating the call back to it
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = IAxelarDepositService(msg.sender).receiverImplementation().delegatecall(delegateData);

        // if not success revert with the original revert data
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        if (refundAddress == address(0)) refundAddress = msg.sender;

        selfdestruct(payable(refundAddress));
    }

    // @dev This function is for receiving Ether from unwrapping WETH9
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}


// File contracts/deposit-service/ReceiverImplementation.sol

// This should be owned by the microservice that is paying for gas.
contract ReceiverImplementation is DepositServiceBase {
    constructor(address gateway_, string memory wrappedSymbol_) DepositServiceBase(gateway_, wrappedSymbol_) {}

    // @dev This function is used for delegate call by DepositReceiver
    // Context: msg.sender == AxelarDepositService, this == DepositReceiver
    function receiveAndSendToken(
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol
    ) external {
        address tokenAddress = IAxelarGateway(gateway).tokenAddresses(symbol);
        // Checking with AxelarDepositService if need to refund a token
        address refund = IAxelarDepositService(msg.sender).refundToken();
        if (refund != address(0)) {
            if (refundAddress == address(0)) refundAddress = msg.sender;
            _safeTransfer(refund, refundAddress, IERC20(refund).balanceOf(address(this)));
            return;
        }

        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));

        if (amount == 0) revert NothingDeposited();

        // Not doing safe approval as gateway will revert anyway if approval fails
        // We expect allowance to always be 0 at this point
        IERC20(tokenAddress).approve(gateway, amount);
        // Sending the token trough the gateway
        IAxelarGateway(gateway).sendToken(destinationChain, destinationAddress, symbol, amount);
    }

    // @dev This function is used for delegate call by DepositReceiver
    // Context: msg.sender == AxelarDepositService, this == DepositReceiver
    function receiveAndSendNative(
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external {
        address refund = IAxelarDepositService(msg.sender).refundToken();
        if (refund != address(0)) {
            if (refundAddress == address(0)) refundAddress = msg.sender;
            _safeTransfer(refund, refundAddress, IERC20(refund).balanceOf(address(this)));
            return;
        }

        address wrappedTokenAddress = wrappedToken();
        uint256 amount = address(this).balance;

        if (amount == 0) revert NothingDeposited();

        // Wrapping the native currency and into WETH-like
        IWETH9(wrappedTokenAddress).deposit{ value: amount }();
        // Not doing safe approval as gateway will revert anyway if approval fails
        // We expect allowance to always be 0 at this point
        IWETH9(wrappedTokenAddress).approve(gateway, amount);
        // Sending the token trough the gateway
        IAxelarGateway(gateway).sendToken(destinationChain, destinationAddress, wrappedSymbol(), amount);
    }

    // @dev This function is used for delegate call by DepositReceiver
    // Context: msg.sender == AxelarDepositService, this == DepositReceiver
    function receiveAndUnwrapNative(address refundAddress, address recipient) external {
        address wrappedTokenAddress = wrappedToken();
        address refund = IAxelarDepositService(msg.sender).refundToken();
        if (refund != address(0)) {
            if (refundAddress == address(0)) refundAddress = msg.sender;
            _safeTransfer(refund, refundAddress, IERC20(refund).balanceOf(address(this)));
            return;
        }

        uint256 amount = IERC20(wrappedTokenAddress).balanceOf(address(this));

        if (amount == 0) revert NothingDeposited();

        // Unwrapping the token into native currency and sending it to the recipient
        IWETH9(wrappedTokenAddress).withdraw(amount);
        (bool sent, ) = recipient.call{ value: amount }('');

        if (!sent) revert NativeTransferFailed();
    }
}


// File contracts/deposit-service/AxelarDepositService.sol

// This should be owned by the microservice that is paying for gas.
contract AxelarDepositService is Upgradable, DepositServiceBase, IAxelarDepositService {
    // This public storage for ERC20 token intended to be refunded.
    // It triggers the DepositReceiver/ReceiverImplementation to switch into a refund mode.
    // Address is stored and deleted withing the same refund transaction.
    address public refundToken;

    address public immutable receiverImplementation;

    constructor(address gateway_, string memory wrappedSymbol_) DepositServiceBase(gateway_, wrappedSymbol_) {
        receiverImplementation = address(new ReceiverImplementation(gateway_, wrappedSymbol_));
    }

    // @dev This method is meant to be called directly by user to send native token cross-chain
    function sendNative(string calldata destinationChain, string calldata destinationAddress) external payable {
        address wrappedTokenAddress = wrappedToken();
        uint256 amount = msg.value;

        if (amount == 0) revert NothingDeposited();

        // Wrapping the native currency and into WETH-like token
        IWETH9(wrappedTokenAddress).deposit{ value: amount }();
        // Not doing safe approval as gateway will revert anyway if approval fails
        // We expect allowance to always be 0 at this point
        IWETH9(wrappedTokenAddress).approve(gateway, amount);
        // Sending the token trough the gateway
        IAxelarGateway(gateway).sendToken(destinationChain, destinationAddress, wrappedSymbol(), amount);
    }

    // @dev Generates a deposit address for sending an ERC20 token cross-chain
    function addressForTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendToken.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress,
                    tokenSymbol
                ),
                refundAddress
            );
    }

    // @dev Generates a deposit address for sending native currency cross-chain
    function addressForNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress
    ) public view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendNative.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress
                ),
                refundAddress
            );
    }

    // @dev Generates a deposit address for unwrapping WETH-like token into native currency
    function addressForNativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address recipient
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(ReceiverImplementation.receiveAndUnwrapNative.selector, refundAddress, recipient),
                refundAddress
            );
    }

    // @dev Receives ERC20 token from the deposit address and sends it cross-chain
    function sendTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{ salt: salt }(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndSendToken.selector,
                refundAddress,
                destinationChain,
                destinationAddress,
                tokenSymbol
            ),
            refundAddress
        );
    }

    // @dev Refunds ERC20 tokens from the deposit address if they don't match the intended token
    // Only refundAddress can refund the token that was intended to go cross-chain (if not sent yet)
    function refundTokenDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol,
        address[] calldata refundTokens
    ) external {
        address intendedToken = IAxelarGateway(gateway).tokenAddresses(tokenSymbol);

        uint256 tokensLength = refundTokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            // Allowing only the refundAddress to refund the intended token
            if (refundTokens[i] == intendedToken && msg.sender != refundAddress) continue;

            // Saving to public storage to be accessed by the DepositReceiver
            refundToken = refundTokens[i];
            // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
            new DepositReceiver{ salt: salt }(
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendToken.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress,
                    tokenSymbol
                ),
                refundAddress
            );
        }

        refundToken = address(0);
    }

    // @dev Receives native currency, wraps it into WETH-like token and sends cross-chain
    function sendNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{ salt: salt }(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndSendNative.selector,
                refundAddress,
                destinationChain,
                destinationAddress
            ),
            refundAddress
        );
    }

    // @dev Refunds ERC20 tokens from the deposit address after the native deposit was sent
    // Only refundAddress can refund the native currency intended to go cross-chain (if not sent yet)
    function refundNativeDeposit(
        bytes32 salt,
        address refundAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        address[] calldata refundTokens
    ) external {
        // Allowing only the refundAddress to refund the native currency
        if (addressForNativeDeposit(salt, refundAddress, destinationChain, destinationAddress).balance > 0 && msg.sender != refundAddress)
            return;

        uint256 tokensLength = refundTokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            refundToken = refundTokens[i];
            // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
            new DepositReceiver{ salt: salt }(
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndSendNative.selector,
                    refundAddress,
                    destinationChain,
                    destinationAddress
                ),
                refundAddress
            );
        }

        refundToken = address(0);
    }

    // @dev Receives WETH-like token, unwraps and send native currency to the recipient
    function nativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address payable recipient
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{ salt: salt }(
            abi.encodeWithSelector(ReceiverImplementation.receiveAndUnwrapNative.selector, refundAddress, recipient),
            refundAddress
        );
    }

    // @dev Refunds ERC20 tokens from the deposit address except WETH-like token
    // Only refundAddress can refund the WETH-like token intended to be unwrapped (if not yet)
    function refundNativeUnwrap(
        bytes32 salt,
        address refundAddress,
        address payable recipient,
        address[] calldata refundTokens
    ) external {
        address wrappedTokenAddress = wrappedToken();

        uint256 tokensLength = refundTokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            // Allowing only the refundAddress to refund the intended WETH-like token
            if (refundTokens[i] == wrappedTokenAddress && msg.sender != refundAddress) continue;

            refundToken = refundTokens[i];
            // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
            new DepositReceiver{ salt: salt }(
                abi.encodeWithSelector(ReceiverImplementation.receiveAndUnwrapNative.selector, refundAddress, recipient),
                refundAddress
            );
        }

        refundToken = address(0);
    }

    function _depositAddress(
        bytes32 salt,
        bytes memory delegateData,
        address refundAddress
    ) internal view returns (address) {
        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.9/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                // Encoding delegateData and refundAddress as constructor params
                                keccak256(abi.encodePacked(type(DepositReceiver).creationCode, abi.encode(delegateData, refundAddress)))
                            )
                        )
                    )
                )
            );
    }

    function contractId() external pure returns (bytes32) {
        return keccak256('axelar-deposit-service');
    }
}