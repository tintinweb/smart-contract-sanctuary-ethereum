// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

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
pragma solidity 0.8.16;

import "./IERC165.sol";

interface ILaserModuleSSR {
    error SSR__onlyWallet__notWallet();

    error SSR__initGuardians__underflow();

    error SSR__initRecoveryOwners__underflow();

    error SSR__verifyNewRecoveryOwnerOrGuardian__invalidAddress();

    ///@dev removeGuardian() custom errors.
    error SSR__removeGuardian__underflow();
    error SSR__removeGuardian__invalidAddress();
    error SSR__removeGuardian__incorrectPreviousGuardian();

    ///@dev removeRecoveryOwner() custom errors.
    error SSR__removeRecoveryOwner__underflow();
    error SSR__removeRecoveryOwner__invalidAddress();
    error SSR__removeRecoveryOwner__incorrectPreviousRecoveryOwner();

    ///@dev swapGuardian() custom errors.
    error SSR__swapGuardian__invalidPrevGuardian();
    error SSR__swapGuardian__invalidOldGuardian();

    ///@dev swapRecoveryOwner() custom errors.
    error SSR__swapRecoveryOwner__invalidPrevRecoveryOwner();
    error SSR__swapRecoveryOwner__invalidOldRecoveryOwner();

    ///@dev Inits the module.
    ///@notice The target wallet is the 'msg.sender'.
    function initSSR(address[] calldata _guardians, address[] calldata _recoveryOwners) external;

    function lock(
        address wallet,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes memory signatures
    ) external;

    /**
     * @dev Unlocks the target wallet.
     * @notice Can only be called with the signature of the wallet's owner + recovery owner or  owner + guardian.
     */
    function unlock(
        address wallet,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes memory signatures
    ) external;

    function recover(
        address wallet,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes memory signatures
    ) external;

    ///@dev Returns the chain id of this.
    function getChainId() external view returns (uint256 chainId);

    function getGuardians(address wallet) external view returns (address[] memory);

    function getRecoveryOwners(address wallet) external view returns (address[] memory);

    function getWalletTimeLock(address wallet) external view returns (uint256);

    function isGuardian(address wallet, address guardian) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

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
pragma solidity 0.8.16;

import "../../common/Utils.sol";
import "../../interfaces/ILaserModuleSSR.sol";
import "../../interfaces/ILaserState.sol";
import "../../interfaces/ILaserWallet.sol";

////////////
///// TODO: Adding and removing a guardian or recovery owner should
// only be allowed when the wallet is unlocked.
contract LaserModuleSSR is ILaserModuleSSR {
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 private constant LASER_MODULE_SSR_TYPE_STRUCTURE =
        keccak256(
            "LaserModuleSSR(address wallet,bytes callData,uint256 walletNonce,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 gasLimit"
        );

    ///@dev POINTER to create a mapping link list.
    address internal constant POINTER = address(0x1);

    ///@dev timeLock keeps track of the recovery time delay. It gets set to 'block.timestamp' when 'lock' is triggered.
    mapping(address => uint256) internal timeLock;

    mapping(address => uint256) internal recoveryOwnerCount;

    mapping(address => uint256) internal guardianCount;

    mapping(address => mapping(address => address)) internal recoveryOwners;

    mapping(address => mapping(address => address)) internal guardians;

    modifier onlyWallet(address wallet) {
        if (msg.sender != wallet) revert SSR__onlyWallet__notWallet();

        _;
    }

    ///@dev Inits the module.
    ///@notice The target wallet is the 'msg.sender'.
    function initSSR(address[] calldata _guardians, address[] calldata _recoveryOwners) external {
        address wallet = msg.sender;

        initGuardians(wallet, _guardians);
        initRecoveryOwners(wallet, _recoveryOwners);
    }

    ///@dev Locks the target wallet.
    ///Can only be called by the recovery owner + guardian.
    function lock(
        address wallet,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes memory signatures
    ) external {
        uint256 walletNonce = ILaserState(wallet).nonce();

        bytes32 signedHash = keccak256(
            encodeOperation(wallet, callData, walletNonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit)
        );

        require(bytes4(callData) == bytes4(keccak256("lock()")), "should be the same!");

        address signer1 = Utils.returnSigner(signedHash, signatures, 0);
        require(recoveryOwners[wallet][signer1] != address(0));

        address signer2 = Utils.returnSigner(signedHash, signatures, 1);
        require(guardians[wallet][signer2] != address(0));

        timeLock[wallet] = block.timestamp;

        ILaserWallet(wallet).execFromModule(wallet, 0, callData, maxFeePerGas, maxPriorityFeePerGas, gasLimit, relayer);
    }

    /**
     * @dev Unlocks the target wallet.
     * @notice Can only be called with the signature of the wallet's owner + recovery owner or  owner + guardian.
     */
    function unlock(
        address wallet,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes memory signatures
    ) external {
        uint256 walletNonce = ILaserState(wallet).nonce();

        bytes32 signedHash = keccak256(
            encodeOperation(wallet, callData, walletNonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit)
        );

        require(bytes4(callData) == bytes4(keccak256("unlock()")), "should be the same!");

        address walletOwner = ILaserState(wallet).owner();
        require(walletOwner != address(0));

        address signer1 = Utils.returnSigner(signedHash, signatures, 0);
        require(signer1 == walletOwner);

        address signer2 = Utils.returnSigner(signedHash, signatures, 1);
        require(
            guardians[wallet][signer2] != address(0) || recoveryOwners[wallet][signer2] != address(0),
            "nop signer2"
        );

        timeLock[wallet] = 0;
        ILaserWallet(wallet).execFromModule(wallet, 0, callData, maxFeePerGas, maxPriorityFeePerGas, gasLimit, relayer);
    }

    function recover(
        address wallet,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes memory signatures
    ) external {
        uint256 walletNonce = ILaserState(wallet).nonce();

        bytes32 signedHash = keccak256(
            encodeOperation(wallet, callData, walletNonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit)
        );

        require(bytes4(callData) == bytes4(keccak256("changeOwner(address)")), "should be change owner.");

        address signer1 = Utils.returnSigner(signedHash, signatures, 0);
        require(recoveryOwners[wallet][signer1] != address(0));

        address signer2 = Utils.returnSigner(signedHash, signatures, 1);
        require(guardians[wallet][signer2] != address(0), "nop signer2");

        require(timeLock[wallet] + 1 weeks < block.timestamp, "incorrect time");
        timeLock[wallet] = 0;
        ILaserWallet(wallet).execFromModule(wallet, 0, callData, maxFeePerGas, maxPriorityFeePerGas, gasLimit, relayer);
    }

    function addGuardian(address wallet, address newGuardian) external onlyWallet(wallet) {
        verifyNewRecoveryOwnerOrGuardian(wallet, newGuardian);
        guardians[wallet][newGuardian] = guardians[wallet][POINTER];
        guardians[wallet][POINTER] = newGuardian;

        unchecked {
            guardianCount[wallet]++;
        }
    }

    function removeGuardian(
        address wallet,
        address prevGuardian,
        address guardianToRemove
    ) external onlyWallet(wallet) {
        // There needs to be at least 1 guardian.
        if (guardianCount[wallet] < 2) revert SSR__removeGuardian__underflow();

        if (guardianToRemove == POINTER) revert SSR__removeGuardian__invalidAddress();

        if (guardians[wallet][prevGuardian] != guardianToRemove)
            revert SSR__removeGuardian__incorrectPreviousGuardian();

        guardians[wallet][prevGuardian] = guardians[wallet][guardianToRemove];
        guardians[wallet][guardianToRemove] = address(0);

        unchecked {
            // Can't underflow, there needs to be more than 2 guardians to reach here.
            guardianCount[wallet]--;
        }
    }

    function swapGuardian(
        address wallet,
        address prevGuardian,
        address newGuardian,
        address oldGuardian
    ) external onlyWallet(wallet) {
        verifyNewRecoveryOwnerOrGuardian(wallet, newGuardian);

        if (guardians[wallet][prevGuardian] != oldGuardian) revert SSR__swapGuardian__invalidPrevGuardian();

        if (oldGuardian == POINTER) revert SSR__swapGuardian__invalidOldGuardian();

        guardians[wallet][newGuardian] = guardians[wallet][oldGuardian];
        guardians[wallet][prevGuardian] = newGuardian;
        guardians[wallet][oldGuardian] = address(0);
    }

    function addRecoveryOwner(address wallet, address newRecoveryOwner) external onlyWallet(wallet) {
        verifyNewRecoveryOwnerOrGuardian(wallet, newRecoveryOwner);
        recoveryOwners[wallet][newRecoveryOwner] = recoveryOwners[wallet][POINTER];
        recoveryOwners[wallet][POINTER] = newRecoveryOwner;

        unchecked {
            recoveryOwnerCount[wallet]++;
        }
    }

    function removeRecoveryOwner(
        address wallet,
        address prevRecoveryOwner,
        address recoveryOwnerToRemove
    ) external onlyWallet(wallet) {
        // There needs to be at least 1 recovery owner.
        if (recoveryOwnerCount[wallet] < 2) revert SSR__removeRecoveryOwner__underflow();

        if (recoveryOwnerToRemove == POINTER) revert SSR__removeRecoveryOwner__invalidAddress();

        if (recoveryOwners[wallet][prevRecoveryOwner] != recoveryOwnerToRemove) {
            revert SSR__removeRecoveryOwner__incorrectPreviousRecoveryOwner();
        }

        recoveryOwners[wallet][prevRecoveryOwner] = recoveryOwners[wallet][recoveryOwnerToRemove];
        recoveryOwners[wallet][recoveryOwnerToRemove] = address(0);

        unchecked {
            // Can't underflow, there needs to be more than 2 guardians to reach here.
            recoveryOwnerCount[wallet]--;
        }
    }

    function swapRecoveryOwner(
        address wallet,
        address prevRecoveryOwner,
        address newRecoveryOwner,
        address oldRecoveryOwner
    ) external onlyWallet(wallet) {
        verifyNewRecoveryOwnerOrGuardian(wallet, newRecoveryOwner);
        if (recoveryOwners[wallet][prevRecoveryOwner] != oldRecoveryOwner) {
            revert SSR__swapRecoveryOwner__invalidPrevRecoveryOwner();
        }

        if (oldRecoveryOwner == POINTER) revert SSR__swapRecoveryOwner__invalidOldRecoveryOwner();

        recoveryOwners[wallet][newRecoveryOwner] = recoveryOwners[wallet][oldRecoveryOwner];
        recoveryOwners[wallet][prevRecoveryOwner] = newRecoveryOwner;
        recoveryOwners[wallet][oldRecoveryOwner] = address(0);
    }

    function getGuardians(address wallet) external view returns (address[] memory) {
        address[] memory guardiansArray = new address[](guardianCount[wallet]);
        address currentGuardian = guardians[wallet][POINTER];

        uint256 index;
        while (currentGuardian != POINTER) {
            guardiansArray[index] = currentGuardian;
            currentGuardian = guardians[wallet][currentGuardian];
            unchecked {
                ++index;
            }
        }
        return guardiansArray;
    }

    function getRecoveryOwners(address wallet) external view returns (address[] memory) {
        address[] memory recoveryOwnersArray = new address[](recoveryOwnerCount[wallet]);
        address currentRecoveryOwner = recoveryOwners[wallet][POINTER];

        uint256 index;
        while (currentRecoveryOwner != POINTER) {
            recoveryOwnersArray[index] = currentRecoveryOwner;
            currentRecoveryOwner = recoveryOwners[wallet][currentRecoveryOwner];
            unchecked {
                ++index;
            }
        }
        return recoveryOwnersArray;
    }

    function getWalletTimeLock(address wallet) external view returns (uint256) {
        return timeLock[wallet];
    }

    function isGuardian(address wallet, address guardian) external view returns (bool) {
        return guardians[wallet][guardian] != address(0) && guardian != POINTER;
    }

    function initGuardians(address wallet, address[] calldata _guardians) internal {
        uint256 guardiansLength = _guardians.length;

        if (guardiansLength < 1) revert SSR__initGuardians__underflow();

        address currentGuardian = POINTER;
        address guardian;

        for (uint256 i = 0; i < guardiansLength; ) {
            guardian = _guardians[i];

            guardians[wallet][currentGuardian] = guardian;
            currentGuardian = guardian;

            verifyNewRecoveryOwnerOrGuardian(wallet, guardian);

            unchecked {
                ++i;
            }
        }

        guardians[wallet][currentGuardian] = POINTER;
        guardianCount[wallet] = guardiansLength;
    }

    ///@dev Inits the recovery owners for the target wallet.
    ///@param wallet The target wallet address.
    ///@param _recoveryOwners Array of the recovery owners addresses.
    function initRecoveryOwners(address wallet, address[] calldata _recoveryOwners) internal {
        uint256 recoveryOwnersLength = _recoveryOwners.length;

        if (recoveryOwnersLength < 1) revert SSR__initRecoveryOwners__underflow();

        address currentRecoveryOwner = POINTER;
        address recoveryOwner;

        for (uint256 i = 0; i < recoveryOwnersLength; ) {
            recoveryOwner = _recoveryOwners[i];

            recoveryOwners[wallet][currentRecoveryOwner] = recoveryOwner;
            currentRecoveryOwner = recoveryOwner;

            verifyNewRecoveryOwnerOrGuardian(wallet, recoveryOwner);

            unchecked {
                ++i;
            }
        }

        recoveryOwners[wallet][currentRecoveryOwner] = POINTER;
        recoveryOwnerCount[wallet] = recoveryOwnersLength;
    }

    function verifyNewRecoveryOwnerOrGuardian(address wallet, address toVerify) internal view {
        address owner = ILaserState(wallet).owner();

        if (toVerify.code.length > 0) {
            // If the recovery owner is a smart contract wallet, it needs to support EIP1271.
            if (!IERC165(toVerify).supportsInterface(0x1626ba7e)) {
                revert SSR__verifyNewRecoveryOwnerOrGuardian__invalidAddress();
            }
        }
        if (
            toVerify == address(0) ||
            toVerify == owner ||
            guardians[wallet][toVerify] != address(0) ||
            recoveryOwners[wallet][toVerify] != address(0)
        ) revert SSR__verifyNewRecoveryOwnerOrGuardian__invalidAddress();
    }

    ///@dev Returns the chain id of this.
    function getChainId() public view returns (uint256 chainId) {
        return block.chainid;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    function encodeOperation(
        address wallet,
        bytes calldata callData,
        uint256 walletNonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) internal view returns (bytes memory) {
        bytes32 opHash = keccak256(
            abi.encode(
                LASER_MODULE_SSR_TYPE_STRUCTURE,
                wallet,
                keccak256(callData),
                walletNonce,
                maxFeePerGas,
                maxPriorityFeePerGas,
                gasLimit
            )
        );

        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), opHash);
    }

    function operationHash(
        address wallet,
        bytes calldata callData,
        uint256 walletNonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32) {
        return keccak256(encodeOperation(wallet, callData, walletNonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit));
    }
}