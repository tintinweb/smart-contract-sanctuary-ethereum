// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "./handlers/Handler.sol";
import "./interfaces/ILaserGuard.sol";
import "./interfaces/ILaserWallet.sol";
import "./state/LaserState.sol";

/**
 * @title  LaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a modular smart contract wallet made for the Ethereum Virtual Machine.
 *         It has modularity (programmability) and security at its core.
 */
contract LaserWallet is ILaserWallet, LaserState, Handler {
    /*//////////////////////////////////////////////////////////////
                            Laser metadata
    //////////////////////////////////////////////////////////////*/

    string public constant VERSION = "1.0.0";

    string public constant NAME = "Laser Wallet";

    /*//////////////////////////////////////////////////////////////
                        Signature constant helpers
    //////////////////////////////////////////////////////////////*/

    bytes4 private constant EIP1271_MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 private constant LASER_TYPE_STRUCTURE =
        keccak256(
            "LaserOperation(address to,uint256 value,bytes callData,uint256 nonce,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 gasLimit)"
        );

    /**
     * @dev Sets the owner of the implementation address (singleton) to 'this'.
     *      This will make the base contract unusable, even though it does not have 'delegatecall'.
     */
    constructor() {
        owner = address(this);
    }

    receive() external payable {}

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner                        The owner of the wallet.
     * @param maxFeePerGas                  Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas          Miner's tip.
     * @param gasLimit                      Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer                       Address to refund for the inclusion of this transaction.
     * @param smartSocialRecoveryModule     Address of the initial module to setup -> Smart Social Recovery.
     * @param _laserMasterGuard             Address of the parent guard module 'LaserMasterGuard'.
     * @param laserVault                    Address of the guard sub-module 'LaserVault'.
     * @param _laserRegistry                Address of the Laser registry: module that keeps track of authorized modules.
     * @param smartSocialRecoveryInitData   Initialization data for the provided module.
     * @param ownerSignature                Signature of the owner that validates approval for initialization.
     */
    function init(
        address _owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address smartSocialRecoveryModule,
        address _laserMasterGuard,
        address laserVault,
        address _laserRegistry,
        bytes calldata smartSocialRecoveryInitData,
        bytes memory ownerSignature
    ) external {
        // activateWallet verifies that the current owner is address 0, reverts otherwise.
        // This is more than enough to avoid being called after initialization.
        activateWallet(
            _owner,
            smartSocialRecoveryModule,
            _laserMasterGuard,
            laserVault,
            _laserRegistry,
            smartSocialRecoveryInitData
        );

        // This is to ensure that the owner authorized the amount of gas.
        {
            bytes32 signedHash = keccak256(
                abi.encodePacked(maxFeePerGas, maxPriorityFeePerGas, gasLimit, block.chainid, address(this))
            );

            address signer = Utils.returnSigner(signedHash, ownerSignature, 0);
            if (signer != _owner) revert LW__init__notOwner();
        }

        if (gasLimit > 0) {
            // Using Infura's relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;

            // 2 call depths.
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
     * @notice Executes a generic transaction.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
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
        bytes memory signatures
    ) public returns (bool success) {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__exec__invalidNonce();
        }

        // If the wallet is locked, further transactions cannot be executed from 'exec'.
        if (isLocked) revert LW__exec__walletLocked();

        // We get the hash of this transaction.
        bytes32 signedHash = keccak256(
            encodeOperation(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit)
        );

        // We get the signer of the hash of this transaction.
        address signer = Utils.returnSigner(signedHash, signatures, 0);

        // The signer must be the owner.
        if (signer != owner) revert LW__exec__notOwner();
        // We call Laser master guard to verify the transaction (in bounds).
        ILaserGuard(laserMasterGuard).verifyTransaction(
            address(this),
            to,
            value,
            callData,
            _nonce,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasLimit,
            signatures
        );
        // We execute the main transaction but we keep 10_000 units of gas for the remaining operations.
        success = Utils.call(to, value, callData, gasleft() - 10000);

        // We do not revert the call if it fails, because the wallet needs to pay the relayer even in case of failure.
        if (success) emit ExecSuccess(to, value, nonce);
        else emit ExecFailure(to, value, nonce);

        if (gasLimit > 0) {
            // If gas limit is greater than 0, it means that the call was relayed.

            // We are using Infura's relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;
            gasLimit = (gasLimit * 63) / 64;
            uint256 gasUsed = gasLimit - gasleft() + 7000;
            uint256 refundAmount = gasUsed * gasPrice;
            success = Utils.call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());
            if (!success) revert LW__exec__refundFailure();
        }
    }

    /**
     * @notice Executes a batch of transactions.
     *
     * @param transactions An array of Laser transactions.
     */
    function multiCall(Transaction[] calldata transactions) external {
        uint256 transactionsLength = transactions.length;

        //@todo custom errors and optimization.
        for (uint256 i = 0; i < transactionsLength; ) {
            Transaction calldata transaction = transactions[i];

            exec(
                transaction.to,
                transaction.value,
                transaction.callData,
                transaction.nonce,
                transaction.maxFeePerGas,
                transaction.maxPriorityFeePerGas,
                transaction.gasLimit,
                transaction.relayer,
                transaction.signatures
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Executes a transaction from an authorized module.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     */
    function execFromModule(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer
    ) external {
        // We quiet compiler warnings FOR NOW.
        (maxFeePerGas, maxPriorityFeePerGas);
        unchecked {
            nonce++;
        }
        if (laserModules[msg.sender] == address(0)) revert LW__execFromModule__unauthorizedModule();

        bool success = Utils.call(to, value, callData, gasleft() - 10000);

        if (!success) revert LW__execFromModule__mainCallFailed();

        if (gasLimit > 0) {
            // Using infura relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;
            gasLimit = (gasLimit * 63) / 64;
            uint256 gasUsed = gasLimit - gasleft() + 7000;
            uint256 refundAmount = gasUsed * gasPrice;

            success = Utils.call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());

            if (!success) revert LW__execFromModule__refundFailure();
        }
    }

    /**
     * @notice Simulates a transaction.
     *         It needs to be called off-chain from address(0).
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
     *
     * @return gasUsed The gas used for this transaction.
     */
    function simulateTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes memory signatures
    ) external returns (uint256 gasUsed) {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__SIMULATION__invalidNonce();
        }

        // If the wallet is locked, further transactions cannot be executed from 'exec'.
        if (isLocked) revert LW__SIMULATION__walletLocked();

        // We get the hash of this transaction.
        bytes32 signedHash = keccak256(
            encodeOperation(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit)
        );

        // We get the signer of the hash of this transaction.
        address signer = Utils.returnSigner(signedHash, signatures, 0);

        // The signer must be the owner.
        if (signer != owner) revert LW__SIMULATION__notOwner();
        // We call Laser master guard to verify the transaction (in bounds).
        ILaserGuard(laserMasterGuard).verifyTransaction(
            address(this),
            to,
            value,
            callData,
            _nonce,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasLimit,
            signatures
        );
        // We execute the main transaction but we keep 10_000 units of gas for the remaining operations.
        bool success = Utils.call(to, value, callData, gasleft() - 10000);

        // We do not revert the call if it fails, because the wallet needs to pay the relayer even in case of failure.
        if (success) emit ExecSuccess(to, value, nonce);
        else emit ExecFailure(to, value, nonce);

        if (gasLimit > 0) {
            // If gas limit is greater than 0, it means that the call was relayed.

            // We are using Infura's relayer for now ...
            uint256 fee = (tx.gasprice / 100) * 6;
            uint256 gasPrice = tx.gasprice + fee;
            gasLimit = (gasLimit * 63) / 64;
            uint256 _gasUsed = gasLimit - gasleft() + 7000;
            uint256 refundAmount = _gasUsed * gasPrice;
            success = Utils.call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());
            if (!success) revert LW__SIMULATION__refundFailure();
        }

        gasUsed = gasLimit - gasleft();
        require(msg.sender == address(0), "Must be called off-chain from 0 addr");
    }

    /**
     * @notice Locks the wallet. Once locked, only the SSR module can unlock it or recover it.
     *
     * @dev Can only be called by address(this).
     */
    function lock() external access {
        isLocked = true;
    }

    /**
     * @notice Unlocks the wallet. Can only be unlocked or recovered from the SSR module.
     *
     * @dev Can only be called by address(this).
     */
    function unlock() external access {
        isLocked = false;
    }

    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value if signature matches the owner's address and the wallet is not locked.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        address recovered = Utils.returnSigner(hash, signature, 0);

        if (recovered != owner || isLocked) revert LaserWallet__invalidSignature();
        return EIP1271_MAGIC_VALUE;
    }

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
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

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() public view returns (uint256 chainId) {
        return block.chainid;
    }

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    /**
     * @notice Encodes the transaction data.
     */
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
            _interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            _interfaceId == 0x1626ba7e || // EIP 1271.
            _interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155.
            _interfaceId == 0x4e2312e0 || // ERC-1155 `ERC1155TokenReceiver` support.
            _interfaceId == 0xae029e0b || // Laser Wallet contract: bytes4(keccak256("I_AM_LASER")).
            _interfaceId == 0x150b7a02; // ERC721 onErc721Received.
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title  ILaserGuard
 *
 * @notice Common api interface for all Guard modules (parent and child).
 */
interface ILaserGuard {
    /**
     * @notice Verifies a Laser transaction.
     *         It calls all guard sub-modules with the 'verifyTransaction api'.
     *         Each sub-module implements its own logic. But the main purpose is to
     *         provide extra transaction security.
     *
     * @param wallet The address of the wallet: should be 'msg.sender'.
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param nonce                 Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
     */
    function verifyTransaction(
        address wallet,
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        bytes memory signatures
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title  ILaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a modular smart contract wallet made for the Ethereum Virtual Machine.
 *         It has modularity (programmability) and security at its core.
 *
 * @dev    This interface has all events, errors, and external function for LaserWallet.
 */
interface ILaserWallet {
    event Setup(address owner, address laserModule);
    event ExecSuccess(address to, uint256 value, uint256 nonce);
    event ExecFailure(address to, uint256 value, uint256 nonce);

    // init() custom errors.
    error LW__init__notOwner();
    error LW__init__refundFailure();

    // exec() custom errors.
    error LW__exec__invalidNonce();
    error LW__exec__walletLocked();
    error LW__exec__notOwner();
    error LW__exec__refundFailure();

    // execFromModule() custom errors.
    error LW__execFromModule__unauthorizedModule();
    error LW__execFromModule__mainCallFailed();
    error LW__execFromModule__refundFailure();

    // simulateTransaction() custom errors.
    error LW__SIMULATION__invalidNonce();
    error LW__SIMULATION__walletLocked();
    error LW__SIMULATION__notOwner();
    error LW__SIMULATION__refundFailure();

    // isValidSignature() Laser custom error.
    error LaserWallet__invalidSignature();

    struct Transaction {
        address to;
        uint256 value;
        bytes callData;
        uint256 nonce;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 gasLimit;
        address relayer;
        bytes signatures;
    }

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner                        The owner of the wallet.
     * @param maxFeePerGas                  Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas          Miner's tip.
     * @param gasLimit                      Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer                       Address to refund for the inclusion of this transaction.
     * @param smartSocialRecoveryModule     Address of the initial module to setup -> Smart Social Recovery.
     * @param _laserMasterGuard             Address of the parent guard module 'LaserMasterGuard'.
     * @param laserVault                    Address of the guard sub-module 'LaserVault'.
     * @param _laserRegistry                Address of the Laser registry: module that keeps track of authorized modules.
     * @param smartSocialRecoveryInitData   Initialization data for the provided module.
     * @param ownerSignature                Signature of the owner that validates approval for initialization.
     */
    function init(
        address _owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address smartSocialRecoveryModule,
        address _laserMasterGuard,
        address laserVault,
        address _laserRegistry,
        bytes calldata smartSocialRecoveryInitData,
        bytes memory ownerSignature
    ) external;

    /**
     * @notice Executes a generic transaction.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash for this transaction.
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
        bytes calldata signatures
    ) external returns (bool success);

    /**
     * @notice Executes a transaction from an authorized module.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     */
    function execFromModule(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer
    ) external;

    /**
     * @notice Simulates a transaction.
     *         It needs to be called off-chain from address(0).
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
     *
     * @return gasUsed The gas used for this transaction.
     */
    function simulateTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata signatures
    ) external returns (uint256 gasUsed);

    /**
     * @notice Locks the wallet. Once locked, only the SSR module can unlock it or recover it.
     *
     * @dev Can only be called by address(this).
     */
    function lock() external;

    /**
     * @notice Unlocks the wallet. Can only be unlocked or recovered from the SSR module.
     *
     * @dev Can only be called by address(this).
     */
    function unlock() external;

    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value if signature matches the owner's address and the wallet is not locked.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32);

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() external view returns (uint256 chainId);

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../access/Access.sol";
import "../common/Utils.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ILaserMasterGuard.sol";
import "../interfaces/ILaserState.sol";
import "../interfaces/ILaserRegistry.sol";

/////
///////// @todo Add 'removeModule', should be the signature of the owner + guardian
////////        or owner + recovery owner.
/////
contract LaserState is ILaserState, Access {
    address internal constant POINTER = address(0x1); // Pointer for the link list.

    /*//////////////////////////////////////////////////////////////
                         Laser Wallet storage
    //////////////////////////////////////////////////////////////*/

    address public singleton; // Base contract.

    address public owner; // Owner of the wallet.

    address public laserMasterGuard; // Parent module for guard sub modules.

    address public laserRegistry; // Registry that keeps track of authorized modules (Laser and Guards).

    bool public isLocked; // If the wallet is locked, only certain operations can unlock it.

    uint256 public nonce; // Anti-replay number for signed transactions.

    mapping(address => address) internal laserModules; // Mapping of authorized Laser modules.

    /**
     * @notice Restricted, can only be called by the wallet 'address(this)' or module.
     *
     * @param newOwner  Address of the new owner.
     */
    function changeOwner(address newOwner) external access {
        owner = newOwner;
    }

    /**
     * @notice Restricted, can only be called by the wallet 'address(this)' or module.
     *
     * @param newModule Address of a new authorized Laser module.
     */
    function addLaserModule(address newModule) external access {
        require(ILaserRegistry(laserRegistry).isModule(newModule), "Invalid new module");
        laserModules[newModule] = laserModules[POINTER];
        laserModules[POINTER] = newModule;
    }

    function upgradeSingleton(address _singleton) external access {
        //@todo Change require for custom errrors.
        require(_singleton != address(this), "Invalid singleton");
        require(ILaserRegistry(laserRegistry).isSingleton(_singleton), "Invalid master copy");
        singleton = _singleton;
    }

    function activateWallet(
        address _owner,
        address smartSocialRecoveryModule,
        address _laserMasterGuard,
        address laserVault,
        address _laserRegistry,
        bytes calldata smartSocialRecoveryInitData
    ) internal {
        // If owner is not address 0, the wallet was already initialized.
        if (owner != address(0)) revert LaserState__initOwner__walletInitialized();

        if (_owner.code.length != 0 || _owner == address(0)) revert LaserState__initOwner__invalidAddress();

        // We set the owner.
        owner = _owner;

        // check that the module is accepted.
        laserMasterGuard = _laserMasterGuard;
        laserRegistry = _laserRegistry;

        require(ILaserRegistry(laserRegistry).isModule(smartSocialRecoveryModule), "Module not authorized");
        bool success = Utils.call(smartSocialRecoveryModule, 0, smartSocialRecoveryInitData, gasleft());
        require(success);
        laserModules[smartSocialRecoveryModule] = POINTER;

        // We add the guard module.
        ILaserMasterGuard(_laserMasterGuard).addGuardModule(laserVault);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

///@title IHandler
///@notice Has all the external functions for Handler.sol.
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
    /*//////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

    error Utils__returnSigner__invalidSignature();

    error Utils__returnSigner__invalidContractSignature();

    /**
     * @param signedHash  The hash that was signed.
     * @param signatures  Result of signing the has.
     * @param pos         Position of the signer.
     *
     * @return signer      Address that signed the hash.
     */
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

    /**
     * @dev Returns the r, s and v values of the signature.
     *
     * @param pos Which signature to read.
     */
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

    /**
     * @dev Calls a target address, sends value and / or data payload.
     *
     * @param to     Destination address.
     * @param value  Amount in WEI to transfer.
     * @param callData   Data payload for the transaction.
     */
    function call(
        address to,
        uint256 value,
        bytes memory callData,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(callData, 0x20), mload(callData), 0, 0)
        }
    }

    /**
     * @dev Calculates the gas price for the transaction.
     */
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title  ILaserMasterGuard
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Parent guard module that calls child Laser guards.
 *
 * @dev    This interface has all events, errors, and external function for LaserMasterGuard.
 */
interface ILaserMasterGuard {
    // addGuardModule() custom errors.
    error LaserMasterGuard__addGuardModule__unauthorizedModule();
    error LaserMasterGuard__addGuardModule__overflow();

    // removeGuardModule custom errors.
    error LaserMasterGuard__removeGuardModule__incorrectModule();
    error LaserMasterGuard__removeGuardModule__incorrectPrevModule();

    /**
     * @notice Adds a new guard module.
     *         wallet is 'msg.sender'.
     *
     * @param module The address of the new module. It needs to be authorized in LaserRegistry.
     */
    function addGuardModule(address module) external;

    /**
     * @notice Removes a guard module.
     * wallet is 'msg.sender'.
     *
     * @param prevModule    The address of the previous module on the linked list.
     * @param module        The address of the module to remove.
     */
    function removeGuardModule(
        address prevModule,
        address module,
        bytes calldata guardianSignature
    ) external;

    /**
     * @notice Verifies a Laser transaction.
     *         It calls all guard sub-modules with the 'verifyTransaction api'.
     *         Each sub-module implements its own logic. But the main purpose is to
     *         provide extra transaction security.
     *
     * @param wallet                The address of the wallet: should be 'msg.sender'.
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param nonce                 Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
     */
    function verifyTransaction(
        address wallet,
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        bytes memory signatures
    ) external;

    /**
     * @param wallet The requested address.
     *
     * @return The guard modules that belong to the requested address.
     */
    function getGuardModules(address wallet) external view returns (address[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaserState {
    ///@dev upgradeSingleton() custom error.
    error LaserState__upgradeSingleton__notLaser();

    ///@dev initOwner() custom errors.
    error LaserState__initOwner__walletInitialized();
    error LaserState__initOwner__invalidAddress();

    function singleton() external view returns (address);

    function owner() external view returns (address);

    function laserMasterGuard() external view returns (address);

    function laserRegistry() external view returns (address);

    function isLocked() external view returns (bool);

    function nonce() external view returns (uint256);

    ///@notice Restricted, can only be called by the wallet or module.
    function changeOwner(address newOwner) external;

    ///@notice Restricted, can only be called by the wallet.
    function addLaserModule(address newModule) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaserRegistry {
    function isSingleton(address singleton) external view returns (bool);

    function isModule(address module) external view returns (bool);
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