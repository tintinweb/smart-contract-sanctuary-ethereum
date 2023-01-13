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

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';

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
    error TransferFailed();
    error InvalidAddress();

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

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

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

    function collectFees(address payable receiver, address[] calldata tokens) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
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
pragma solidity ^0.8.15;

interface INexus {
	event MessageSent(
		uint256 destinationChainId,
		uint256 fee,
		bytes _callData,
		uint8 _provider
	);
	event TokenWithMessageSent(
		uint256 destinationChainId,
		uint256 fee,
		bytes _callData,
		uint8 _provider,
		address _token,
		uint256 _amount
	);
	event TokenWithMessageReceived(
		uint256 sourceChainId,
		uint256 fee,
		bytes _callData,
		address _token,
		uint256 _amount
	);
	event MessageReceived(uint256 sourceChainId, uint256 fee, bytes _callData);

	function deposit() external payable;

	function sendMessage(
		uint256 destinationChainId,
		address targetContractAddress,
		uint256 fee,
		bytes memory _message,
		uint8 _provider,
		address _refundAddress
	) external payable;

	function sendTokenWithMessage(
		uint256 destinationChainId,
		address targetContractAddress,
		uint256 fee,
		bytes memory _message,
		uint8 _provider,
		address _refundAddress,
		address _token,
		uint256 _amount
	) external payable;

	// For NexusRelay
	function receiveCallback(
		uint256 _amount,
		address _asset,
		address _senderAddress,
		uint256 _senderChainId,
		bytes memory _message,
		uint8 _provider
	) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface INexusRelay {
	function transmit(
		uint256 destinationChainId,
		bytes memory message,
		address _token,
		uint256 amount,
		address _refundAddress
	) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { INexus } from "../interfaces/INexus.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INexusRelay } from "../interfaces/INexusRelay.sol";

abstract contract AbstractNexusRelay is Ownable, INexusRelay {
	mapping(uint256 => address) public externalNexusRelayPartners;
	address immutable _nexus;
	uint8 public immutable providerId;
	bool immutable supportsRefund;

	constructor(
		address _nexusAddress,
		uint8 _providerId,
		bool _supportsRefund
	) {
		_nexus = _nexusAddress;
		providerId = _providerId;
		supportsRefund = _supportsRefund;
	}

	function transmit(
		uint256 destinationChainId,
		bytes memory message,
		address _token,
		uint256 amount,
		address _refundAddress
	) external payable onlyNexus {
		require(
			supportsRefund || _refundAddress == address(0),
			"This provider does not support refunds"
		);
		address refund = _refundAddress;
		if (refund == address(0)) refund = address(nexus());

		_transmit(destinationChainId, message, _token, amount, refund);
	}

	function _transmit(
		uint256 destinationChainId,
		bytes memory message,
		address _token,
		uint256 amount,
		address _refundAddress
	) internal virtual;

	function nexus() public view returns (INexus) {
		return INexus(_nexus);
	}

	function _setExternalNexusRelayPartner(
		uint256 chainId,
		address relay
	) internal {
		externalNexusRelayPartners[chainId] = relay;
	}

	function setExternalNexusRelayPartner(
		uint256 chainId,
		address relay
	) external virtual onlyOwner {
		_setExternalNexusRelayPartner(chainId, relay);
	}

	function checkExternalNexusRelayPartner(
		uint256 chainId,
		address relay
	) external view returns (bool) {
		return (externalNexusRelayPartners[chainId] == relay);
	}

	modifier onlyNexus() {
		require(msg.sender == _nexus, "Only Nexus can call this function");
		_;
	}

	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function _forwardMessageToNexus(
		uint256 _amount,
		address _asset,
		address _senderAddress,
		uint256 _senderChainId,
		bytes memory _message
	) internal onlyGateway(_msgSender()) {
		nexus().receiveCallback(
			_amount,
			_asset,
			_senderAddress,
			_senderChainId,
			_message,
			providerId
		);
	}

	// Serves as a reminder to check origin of messages
	modifier onlyGateway(address) virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { AbstractNexusRelay } from "./AbstractNexusRelay.sol";
import { INexus } from "../interfaces/INexus.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { StringToAddress, AddressToString } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/StringAddressUtils.sol";

contract AxelarNexusRelay is IAxelarExecutable, AbstractNexusRelay {
	using AddressToString for address;
	using StringToAddress for string;

	IAxelarGateway public immutable _gateway;
	struct ChainData {
		string chainName;
		address _gateway;
		address gasService;
	}

	IAxelarGasService public immutable gasReceiver;
	mapping(string => uint256) public chainNametoId;
	mapping(uint256 => ChainData) public chainIdtoData;
	mapping(address => string) tokenAddressToSymbol;
	string[] public tokenSymbols = [
		"aUSDC",
		"wAXL",
		"WMATIC",
		"WFTM",
		"WETH",
		"WAVAX",
		"WDEV",
		"WBNB",
		"axlWETH"
	];

	constructor(
		address _owner,
		uint8 _providerId
	) AbstractNexusRelay(_owner, _providerId, true) {
		_fillChainDetails();
		gasReceiver = IAxelarGasService(
			chainIdtoData[block.chainid].gasService
		);
		_gateway = IAxelarGateway(chainIdtoData[block.chainid]._gateway);
		_fillTokenSymbols();
	}

	function _fillChainDetails() private {
		chainNametoId["ethereum-2"] = 5;
		chainNametoId["binance"] = 97;
		chainNametoId["Polygon"] = 80001;
		chainNametoId["arbitrum"] = 421613;

		chainIdtoData[5] = ChainData(
			"ethereum-2",
			0xe432150cce91c13a887f7D836923d5597adD8E31,
			0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
		);
		chainIdtoData[97] = ChainData(
			"binance",
			0x4D147dCb984e6affEEC47e44293DA442580A3Ec0,
			0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
		);
		chainIdtoData[80001] = ChainData(
			"Polygon",
			0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B,
			0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
		);
		chainIdtoData[421613] = ChainData(
			"arbitrum",
			0xe432150cce91c13a887f7D836923d5597adD8E31,
			0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
		);
	}

	function _fillTokenSymbols() private {
		for (uint256 i = 0; i < tokenSymbols.length; i++) {
			address _tokenAddress = _gateway.tokenAddresses(tokenSymbols[i]);
			if (_tokenAddress == address(0)) continue;
			tokenAddressToSymbol[_tokenAddress] = tokenSymbols[i];
		}
	}

	function _execute(
		string calldata sourceChain,
		string calldata sourceAddress,
		bytes calldata payload
	) internal {
		_forwardMessageToNexus(
			0,
			address(0),
			sourceAddress.toAddress(),
			chainNametoId[sourceChain],
			payload
		);
	}

	function _executeWithToken(
		string calldata sourceChain,
		string calldata sourceAddress,
		bytes calldata payload,
		string calldata tokenSymbol,
		uint256 amount
	) internal {
		address _tokenAddress = _gateway.tokenAddresses(tokenSymbol);
		IERC20(_tokenAddress).approve(owner(), amount);

		_forwardMessageToNexus(
			amount,
			_gateway.tokenAddresses(tokenSymbol),
			sourceAddress.toAddress(),
			chainNametoId[sourceChain],
			payload
		);
	}

	function _transmit(
		uint256 destinationChainId,
		bytes memory message,
		address _tokenAddress,
		uint256 amount,
		address _refundAddress
	) internal override {
		address targetContract = externalNexusRelayPartners[destinationChainId];
		string memory targetContractStr = targetContract.toString();
		if (amount > 0) {
			IERC20 token = IERC20(_tokenAddress);
			token.transferFrom(msg.sender, address(this), amount);
			token.approve(address(_gateway), amount);

			if (msg.value > 0)
				gasReceiver.payNativeGasForContractCallWithToken{
					value: msg.value
				}(
					address(this),
					chainIdtoData[destinationChainId].chainName,
					targetContractStr,
					message,
					tokenAddressToSymbol[_tokenAddress],
					amount,
					_refundAddress
				);
			_gateway.callContractWithToken(
				chainIdtoData[destinationChainId].chainName,
				targetContractStr,
				message,
				tokenAddressToSymbol[_tokenAddress],
				amount
			);
		} else {
			if (msg.value > 0)
				gasReceiver.payNativeGasForContractCall{ value: msg.value }(
					address(this),
					chainIdtoData[destinationChainId].chainName,
					targetContractStr,
					message,
					_refundAddress
				);
			_gateway.callContract(
				chainIdtoData[destinationChainId].chainName,
				targetContractStr,
				message
			);
		}
	}

	function execute(
		bytes32 commandId,
		string calldata sourceChain,
		string calldata sourceAddress,
		bytes calldata payload
	) external override {
		bytes32 payloadHash = keccak256(payload);
		if (
			!_gateway.validateContractCall(
				commandId,
				sourceChain,
				sourceAddress,
				payloadHash
			)
		) revert NotApprovedByGateway();
		_execute(sourceChain, sourceAddress, payload);
	}

	function executeWithToken(
		bytes32 commandId,
		string calldata sourceChain,
		string calldata sourceAddress,
		bytes calldata payload,
		string calldata tokenSymbol,
		uint256 amount
	) external override {
		bytes32 payloadHash = keccak256(payload);
		if (
			!_gateway.validateContractCallAndMint(
				commandId,
				sourceChain,
				sourceAddress,
				payloadHash,
				tokenSymbol,
				amount
			)
		) revert NotApprovedByGateway();

		_executeWithToken(
			sourceChain,
			sourceAddress,
			payload,
			tokenSymbol,
			amount
		);
	}

	function gateway() external view override returns (IAxelarGateway) {
		return _gateway;
	}

	modifier onlyGateway(address) override {
		// _gateway.validateContractCall() and _gateway.validateContractCallAndMint() check the origin of messages
		_;
	}
}