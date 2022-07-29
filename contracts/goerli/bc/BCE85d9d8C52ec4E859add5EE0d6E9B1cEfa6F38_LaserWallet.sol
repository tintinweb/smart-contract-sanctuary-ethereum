// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "./handlers/Handler.sol";
import "./interfaces/ILaserWallet.sol";
import "./state/LaserState.sol";

interface ILaserGuard {
    function checkTransaction(address to) external;
}

///@title LaserWallet - Modular EVM based smart contract wallet.
///@author Rodrigo Herrera I.
contract LaserWallet is ILaserWallet, LaserState, Handler {
    string public constant VERSION = "1.0.0";

    bytes4 private constant EIP1271_MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 private constant LASER_TYPE_STRUCTURE =
        keccak256(
            "LaserOperation(address to,uint256 value,bytes callData,uint256 nonce,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 gasLimit)"
        );

    constructor() {
        owner = address(this);
    }

    receive() external payable {}

    ///@dev Setup function, sets initial storage of the wallet.
    ///@notice It can't be called after initialization.
    function init(
        address _owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address laserModule,
        bytes calldata laserModuleData,
        bytes calldata ownerSignature
    ) external {
        activateWallet(_owner, laserModule, laserModuleData);

        bytes32 signedHash = keccak256(abi.encodePacked(maxFeePerGas, maxPriorityFeePerGas, gasLimit, block.chainid));

        address signer = Utils.returnSigner(signedHash, ownerSignature, 0);

        if (signer != _owner) revert LW__init__notOwner();

        if (gasLimit > 0) {
            // Using infura relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;

            gasLimit = (gasLimit * 3150) / 3200;
            uint256 gasUsed = gasLimit - gasleft() + 8000;

            uint256 refundAmount = gasUsed * gasPrice;

            bool success = Utils.call(
                relayer == address(0) ? tx.origin : relayer,
                refundAmount,
                new bytes(0),
                gasleft()
            );

            if (!success) revert LW__init__refundFailure();
        }
        // emit Setup(_owner, laserModule);
    }

    /**
     * @dev Executes a generic transaction. It does not support 'delegatecall' for security reasons.
     * @param to Destination address.
     * @param value Amount to send.
     * @param callData Data payload for the transaction.
     * @param ownerSignature The signatures of the transaction.
     * @notice If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     * It is the relayer's responsability to make sure that they are the same, the user does not get affected if a mistake is made.
     * We prefer to prioritize the user's safety (not overpay) over the relayer.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata ownerSignature
    ) external {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__exec__invalidNonce();
        }

        if (isLocked) revert LW__exec__walletLocked();

        bytes32 signedHash = keccak256(
            encodeOperation(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit)
        );

        address signer = Utils.returnSigner(signedHash, ownerSignature, 0);

        if (signer != owner) revert LW__exec__notOwner();

        bool success = Utils.call(to, value, callData, gasleft() - 10000);

        // We do not revert the call if it fails, because the wallet needs to pay the relayer even in case of failure.
        if (success) emit ExecSuccess(to, value, nonce);
        else emit ExecFailure(to, value, nonce);

        if (laserGuard != address(0)) {
            ILaserGuard(laserGuard).checkTransaction(to);
        }

        // Using infura relayer for now ...
        uint256 fee = (tx.gasprice / 100) * 6;
        uint256 gasPrice = tx.gasprice + fee;
        uint256 gasUsed = gasLimit - gasleft() + 7000;
        uint256 refundAmount = gasUsed * gasPrice;

        success = Utils.call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());

        if (!success) revert LW__exec__refundFailure();
    }

    ///@dev Allows to execute a transaction from an authorized module.
    function execFromModule(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer
    ) external {
        unchecked {
            nonce++;
        }
        ///@todo custom errors instead of require statement.
        require(laserModules[msg.sender] != address(0), "nop module");

        bool success = Utils.call(to, value, callData, gasleft() - 10000);

        require(success, "main call failed");

        if (gasLimit > 0) {
            // Using infura relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;
            gasLimit = (gasLimit * 63) / 64;
            uint256 gasUsed = gasLimit - gasleft() + 7000;
            uint256 refundAmount = gasUsed * gasPrice;

            success = Utils.call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());

            require(success, "refund failed");
        }
    }

    ///@dev Locks the wallet. Once locked, only the SSR module can unlock it or recover it.
    function lock() external access {
        isLocked = true;
    }

    ///@dev Unlocks the wallet. Can only be unlocked or recovered from the SSR module.
    function unlock() external access {
        isLocked = false;
    }

    ///@dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
    ///@return Magic value  or reverts with an error message.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        address recovered = Utils.returnSigner(hash, signature, 0);

        // The guardians and recovery owners should not be able to sign transactions that are out of scope from this wallet.
        // Only the owner should be able to sign external data.
        if (recovered != owner || isLocked) revert LaserWallet__invalidSignature();
        return EIP1271_MAGIC_VALUE;
    }

    function getChainId() public view returns (uint256 chainId) {
        return block.chainid;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    function encodeOperation(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) internal view returns (bytes memory) {
        bytes32 opHash = keccak256(
            abi.encode(
                LASER_TYPE_STRUCTURE,
                to,
                value,
                keccak256(callData),
                _nonce,
                maxFeePerGas,
                maxPriorityFeePerGas,
                gasLimit
            )
        );

        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), opHash);
    }

    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32) {
        return keccak256(encodeOperation(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "../interfaces/IHandler.sol";
import "../interfaces/IERC165.sol";

/**
 * @title Handler - Supports token callbacks.
 */
contract Handler is IHandler, IERC165 {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 result) {
        return 0xbc197c81;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure {}

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165
            _interfaceId == 0x1626ba7e || // EIP 1271
            _interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155
            _interfaceId == 0x4e2312e0 || // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
            _interfaceId == 0xae029e0b || // Laser Wallet contract: bytes4(keccak256("I_AM_LASER"))
            _interfaceId == 0x150b7a02; // ERC721 onErc721Received
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title ILaserWallet
 * @author Rodrigo Herrera I.
 * @notice Has all the external functions, structs, events and errors for LaserWallet.sol.
 */
interface ILaserWallet {
    event Received(address indexed sender, uint256 amount);
    event Setup(address owner, address laserModule);
    event ExecSuccess(address to, uint256 value, uint256 nonce);
    event ExecFailure(address to, uint256 value, uint256 nonce);

    ///@dev init() custom error.
    error LW__init__notOwner();
    error LW__init__refundFailure();

    ///@dev exec() custom errors.
    error LW__exec__invalidNonce();
    error LW__exec__walletLocked();
    error LW__exec__notOwner();
    error LW__exec__refundFailure();

    ///@dev isValidSignature() Laser custom error.
    error LaserWallet__invalidSignature();

    /**
     * @dev Setup function, sets initial storage of the wallet.
     * @param _owner The owner of the wallet.
     * @param maxFeePerGas The maximum amount of WEI the user is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas Miner's tip.
     * @param gasLimit Maximum units of gas the user is willing to use for the transaction.
     * @param relayer Address of the relayer to pay back for the transaction inclusion.
     * @param laserModule Authorized Laser module that can execute transactions for this wallet.
     * @param ownerSignature The signature of the owner to make sure that it approved the transaction.
     * @notice It can't be called after initialization.
     */
    function init(
        address _owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address laserModule,
        bytes calldata laserGuardData,
        bytes calldata ownerSignature
    ) external;

    /**
     * @dev Executes a generic transaction. It does not support 'delegatecall' for security reasons.
     * @param to Destination address.
     * @param value Amount to send.
     * @param callData Data payload for the transaction.
     * @param _nonce Unsigned integer to avoid replay attacks. It needs to match the current wallet's nonce.
     * @param maxFeePerGas Maximum amount that the user is willing to pay for a unit of gas.
     * @param maxPriorityFeePerGas Miner's tip.
     * @param gasLimit The transaction's gas limit. It needs to be the same as the actual transaction gas limit.
     * @param ownerSignature The signatures of the transaction.
     * @notice If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     * It is the relayer's responsability to make sure that they are the same, the user does not get affected if a mistake is made.
     * We prefer to prioritize the user's safety (not overpay) over the relayer.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata ownerSignature
    ) external;

    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../access/Access.sol";
import "../common/Utils.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ILaserState.sol";

contract LaserState is ILaserState, Access {
    address internal constant pointer = address(0x1);

    address public singleton;

    address public owner;

    address public laserGuard;

    bool public isLocked;

    uint256 public nonce;

    mapping(address => address) internal laserModules;

    function changeOwner(address newOwner) external access {
        owner = newOwner;
    }

    function addLaserModule(address newModule) external access {
        laserModules[newModule] = laserModules[pointer];
        laserModules[pointer] = newModule;
    }

    function changeLaserGuard(address newLaserGuard) external access {
        laserGuard = newLaserGuard;
    }

    function upgradeSingleton(address _singleton) external access {
        // if (_singleton == address(this)) revert Singleton__upgradeSingleton__incorrectAddress();

        if (!IERC165(_singleton).supportsInterface(0xae029e0b)) {
            //bytes4(keccak256("I_AM_LASER")))
            revert LaserState__upgradeSingleton__notLaser();
        }

        singleton = _singleton;
    }

    function activateWallet(
        address _owner,
        address laserModule,
        bytes calldata laserModuleData
    ) internal {
        // If owner is not address 0, the wallet was already initialized ...
        if (owner != address(0)) revert LaserState__initOwner__walletInitialized();

        if (_owner.code.length != 0 || _owner == address(0)) revert LaserState__initOwner__addressWithCode();
        owner = _owner;

        if (laserModule != address(0)) {
            bool success = Utils.call(laserModule, 0, laserModuleData, gasleft());
            require(success);
            laserModules[laserModule] = pointer;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IHandler
 * @notice Has all the external functions for Handler.sol.
 */
interface IHandler {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 result);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 result);

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title IERC165
 * @notice Support of ERC165.
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     * interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

contract Access {
    error Access__notAllowed();

    modifier access() {
        if (msg.sender != address(this)) revert Access__notAllowed();

        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../interfaces/IEIP1271.sol";

/**
 * @title Utils - Helper functions for Laser wallet and modules.
 */
library Utils {
    error Utils__returnSigner__invalidSignature();
    error Utils__returnSigner__invalidContractSignature();

    ///@dev Returns the signer of the hash.
    ///@param signedHash The hash that was signed.
    function returnSigner(
        bytes32 signedHash,
        bytes memory signatures,
        uint256 pos
    ) internal view returns (address signer) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v) = splitSigs(signatures, pos);

        if (v == 0) {
            // If v is 0, then it is a contract signature.
            // The address of the contract is encoded into r.
            signer = address(uint160(uint256(r)));

            // The signature(s) of the EOA's that control the target contract.
            bytes memory contractSignature;

            assembly {
                contractSignature := add(add(signatures, s), 0x20)
            }

            if (IEIP1271(signer).isValidSignature(signedHash, contractSignature) != 0x1626ba7e) {
                revert Utils__returnSigner__invalidContractSignature();
            }
        } else if (v > 30) {
            signer = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedHash)),
                v - 4,
                r,
                s
            );
        } else {
            signer = ecrecover(signedHash, v, r, s);
        }

        if (signer == address(0)) revert Utils__returnSigner__invalidSignature();
    }

    ///@dev Returns the r, s and v values of the signature.
    ///@param pos Which signature to read.
    function splitSigs(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            let sigPos := mul(0x41, pos)
            r := mload(add(signatures, add(sigPos, 0x20)))
            s := mload(add(signatures, add(sigPos, 0x40)))
            v := byte(0, mload(add(signatures, add(sigPos, 0x60))))
        }
    }

    ///@dev Calls a target address, sends value and / or data payload.
    function call(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    ///@dev Calculates the gas price for the transaction.
    function calculateGasPrice(uint256 maxFeePerGas, uint256 maxPriorityFeePerGas) internal view returns (uint256) {
        if (maxFeePerGas == maxPriorityFeePerGas) {
            // Legacy mode (pre-EIP1559)
            return min(maxFeePerGas, tx.gasprice);
        }

        // EIP-1559
        // priority_fee_per_gas = min(transaction.max_priority_fee_per_gas, transaction.max_fee_per_gas - block.base_fee_per_gas)
        // effective_gas_price = priority_fee_per_gas + block.base_fee_per_gas
        uint256 priorityFeePerGas = min(maxPriorityFeePerGas, maxFeePerGas - block.basefee);

        // effective_gas_price
        return priorityFeePerGas + block.basefee;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaserState {
    ///@dev upgradeSingleton() custom error.
    error LaserState__upgradeSingleton__notLaser();

    ///@dev initOwner() custom error.
    error LaserState__initOwner__walletInitialized();
    error LaserState__initOwner__addressWithCode();

    function changeOwner(address newOwner) external;

    function addLaserModule(address newModule) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IEIP1271
 * @notice Interface to call external contracts to validate signature.
 */
interface IEIP1271 {
    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);
}