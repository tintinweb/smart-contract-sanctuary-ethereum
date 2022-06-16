//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AxelarModifiers.sol";
import "./AxelarAdmin.sol";
import "./AxelarEvents.sol";
import "./interfaces/IAxelarExecutable.sol";
import "../interfaces/IRoute.sol";
import "./libraries/StringAddress.sol";

contract AxelarRoute is
    AxelarModifiers,
    AxelarAdmin,
    IRoute
{
    using StringToAddress for string;
    using AddressToString for address;

    constructor(
        IMiddleLayer _middleLayer,
        address _gateway,
        IAxelarGasService _gasService
    ) IAxelarExecutable(_gateway) {
        owner = msg.sender;
        middleLayer = _middleLayer;
        gasService = _gasService;
    }

    function _translate(
        uint256 chainId
    ) internal view returns (string memory cid) {
        return cids[chainId];
    }

    function _translate(
        string memory cid
    ) internal view returns (uint256 chainId) {
        return chainIds[cid];
    }

    function _execute(
        string memory cid,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual override {

        emit Receive(
            "Axelar",
            cid,
            _translate(cid),
            sourceAddress,
            payload
        );

        middleLayer.mreceive(
            _translate(cid),
            payload
        );
    }

    function msend(
        uint256 chainId,
        bytes memory params,
        address payable _refundAddress
    ) external override payable onlyMid() {

        emit Send(
            "Axelar",
            _translate(chainId),
            params,
            _refundAddress
        );

        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            _translate(chainId),
            srcContracts[chainId].toString(),
            params,
            _refundAddress
        );

        gateway.callContract(
            _translate(chainId),
            srcContracts[chainId].toString(),
            params
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AxelarStorage.sol";
import "./interfaces/IAxelarExecutable.sol";

abstract contract AxelarModifiers is AxelarStorage, IAxelarExecutable {
    modifier onlyAX() {
        require(msg.sender == address(gateway), "ONLY_AX");
        _;
    }

    modifier onlySrc(uint256 srcChain, bytes memory _srcAddr) {
        address srcAddr;
        assembly {
            srcAddr := mload(add(20, _srcAddr))
        }
        require(
            srcContracts[srcChain] == address(srcAddr),
            "UNAUTHORIZED_CONTRACT"
        );
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MID");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AxelarModifiers.sol";
import "./AxelarEvents.sol";

abstract contract AxelarAdmin is AxelarModifiers, AxelarEvents {
    function addSrc(uint256 srcChain, address _newSrcAddr) external onlyOwner() {
        srcContracts[srcChain] = _newSrcAddr;

        emit AddSrc(srcChain, _newSrcAddr);
    }

    function addTranslation(
        string memory customId, uint256 standardId
    ) external {
        cids[standardId] = customId;
        chainIds[customId] = standardId;

        emit AddTranslation(customId, standardId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract AxelarEvents {

    event Send(
        string router,
        string chainId,
        bytes params,
        address _refundAddress
    );

    event Receive(
        string router,
        string cid,
        uint256 translatedChainId,
        string sourceAddress,
        bytes payload
    );

    event AddSrc(
        uint256 srcChain, 
        address newSrcAddr
    );

    event AddTranslation(
        string customId, 
        uint256 standardId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IAxelarGateway } from "./IAxelarGateway.sol";

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    IAxelarGateway public gateway;

    constructor(address gateway_) {
        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        // bytes32 payloadHash = keccak256(payload);
        // if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
        //     revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRoute {
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library StringToAddress {
    function toAddress(string memory _a) internal pure returns (address) {
        bytes memory tmp = bytes(_a);
        if (tmp.length != 42) return address(0);
        uint160 iaddr = 0;
        uint8 b;
        for (uint256 i = 2; i < 42; i++) {
            b = uint8(tmp[i]);
            if ((b >= 97) && (b <= 102)) b -= 87;
            else if ((b >= 65) && (b <= 70)) b -= 55;
            else if ((b >= 48) && (b <= 57)) b -= 48;
            else return address(0);
            iaddr |= uint160(uint256(b) << ((41 - i) << 2));
        }
        return address(iaddr);
    }
}

library AddressToString {
    function toString(address a) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(a);
        bytes memory characters = "0123456789abcdef";
        bytes memory byteString = new bytes(2 + data.length * 2);

        byteString[0] = "0";
        byteString[1] = "x";

        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < data.length; ++i) {
            byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
            byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
        }
        return string(byteString);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IMiddleLayer.sol";
import "./interfaces/IAxelarGasService.sol";

abstract contract AxelarStorage {
    address internal owner;
    IMiddleLayer internal middleLayer;
    IAxelarGasService internal gasService;

    // routers to call to on other chain ids
    mapping(uint256 => address) internal srcContracts;
    mapping(uint256 => string) internal cids;
    mapping(string => uint256) internal chainIds;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address _route
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error TransferFailed();

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

    function collectFees(address payable receiver, address[] calldata tokens) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IAxelarGateway {
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

    event TokenFrozen(string symbol);

    event TokenUnfrozen(string symbol);

    event AllTokensFrozen();

    event AllTokensUnfrozen();

    event AccountBlacklisted(address indexed account);

    event AccountWhitelisted(address indexed account);

    event Upgraded(address indexed implementation);

    /******************\
    |* Public Methods *|
    \******************/

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

    function freezeToken(string calldata symbol) external;

    function unfreezeToken(string calldata symbol) external;

    function freezeAllTokens() external;

    function unfreezeAllTokens() external;

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