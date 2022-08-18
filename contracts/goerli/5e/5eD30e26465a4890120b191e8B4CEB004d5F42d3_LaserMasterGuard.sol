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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

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
pragma solidity 0.8.16;

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

interface ILaserRegistry {
    function isSingleton(address singleton) external view returns (bool);

    function isModule(address module) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../../common/Utils.sol";
import "../../interfaces/ILaserGuard.sol";
import "../../interfaces/ILaserMasterGuard.sol";
import "../../interfaces/ILaserModuleSSR.sol";
import "../../interfaces/ILaserRegistry.sol";

/**
 * @title LaserMasterGuard
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Parent guard module that calls child Laser guards.
 */
contract LaserMasterGuard is ILaserMasterGuard {
    /*//////////////////////////////////////////////////////////////
                            Constans
    //////////////////////////////////////////////////////////////*/

    address private constant POINTER = address(0x1);

    address public immutable LASER_REGISTRY;

    address public immutable LASER_SMART_SOCIAL_RECOVERY;

    /*//////////////////////////////////////////////////////////////
                        LaserMasterGuard's storage
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) internal guardModulesCount;

    mapping(address => mapping(address => address)) internal guardModules;

    /**
     * @param laserRegistry         Address of LaserRegistry: contract that contains the addresses
     *                              of authorized modules.
     * @param smartSocialRecovery   Address of Laser smart social recovery module.
     */
    constructor(address laserRegistry, address smartSocialRecovery) {
        LASER_REGISTRY = laserRegistry;
        //@todo Check that the smart social recovery is registred in LaserRegistry.
        LASER_SMART_SOCIAL_RECOVERY = smartSocialRecovery;
    }

    /**
     * @notice Adds a new guard module.
     *         wallet is 'msg.sender'.
     *
     * @param module The address of the new module. It needs to be authorized in LaserRegistry.
     */
    function addGuardModule(address module) external {
        address wallet = msg.sender;

        // @todo undo this (make the deployments - approvals automatic on deploy).
        // if (!ILaserRegistry(LASER_REGISTRY).isModule(module)) {
        //     revert LaserMasterGuard__addGuardModule__unauthorizedModule();
        // }

        if (guardModulesCount[wallet] == 0) {
            initGuardModule(wallet, module);
        } else {
            guardModules[wallet][module] = guardModules[wallet][POINTER];
            guardModules[wallet][POINTER] = module;
        }

        unchecked {
            ++guardModulesCount[wallet];
        }

        // We can only have a maximum amount of 3 guard modules with low amount of gas usage per transaction.
        // This rule is to avoid a self-inflicted DDoS attack.
        if (guardModulesCount[wallet] == 4) revert LaserMasterGuard__addGuardModule__overflow();
    }

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
    ) external {
        address wallet = msg.sender;

        bytes32 signedHash = keccak256(abi.encodePacked(module, block.chainid));

        address signer = Utils.returnSigner(signedHash, guardianSignature, 0);

        require(ILaserModuleSSR(LASER_SMART_SOCIAL_RECOVERY).isGuardian(wallet, signer), "Invalid guardian signature");

        if (guardModules[wallet][module] == address(0)) {
            revert LaserMasterGuard__removeGuardModule__incorrectModule();
        }

        if (module == POINTER) {
            revert LaserMasterGuard__removeGuardModule__incorrectModule();
        }

        if (guardModules[wallet][prevModule] != module) {
            revert LaserMasterGuard__removeGuardModule__incorrectPrevModule();
        }

        guardModules[wallet][prevModule] = guardModules[wallet][module];
        guardModules[wallet][module] = address(0);

        guardModulesCount[wallet]--;
    }

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
    ) external {
        uint256 nGuards = guardModulesCount[wallet];

        if (nGuards > 0) {
            address currentGuardModule = guardModules[wallet][POINTER];

            if (nGuards == 1) {
                // If there is only 1 guard module, there is no need to loop.
                ILaserGuard(currentGuardModule).verifyTransaction(
                    wallet,
                    to,
                    value,
                    callData,
                    nonce,
                    maxFeePerGas,
                    maxPriorityFeePerGas,
                    gasLimit,
                    signatures
                );
            } else {
                // Guard modules are capped at max 3, and each one is verified that the gas usage
                // is in bounds. Therefore there is no risk of DDoS (using so much gas that the transaction reverts).
                while (currentGuardModule != POINTER) {
                    ILaserGuard(currentGuardModule).verifyTransaction(
                        wallet,
                        to,
                        value,
                        callData,
                        nonce,
                        maxFeePerGas,
                        maxPriorityFeePerGas,
                        gasLimit,
                        signatures
                    );

                    currentGuardModule = guardModules[wallet][currentGuardModule];
                }
            }
        }
    }

    /**
     * @param wallet The requested address.
     *
     * @return The guard modules that belong to the requested address.
     */
    function getGuardModules(address wallet) public view returns (address[] memory) {
        address[] memory guardModulesArray = new address[](guardModulesCount[wallet]);
        address currentGuardModule = guardModules[wallet][POINTER];

        uint256 index;

        while (currentGuardModule != POINTER) {
            guardModulesArray[index] = currentGuardModule;
            currentGuardModule = guardModules[wallet][currentGuardModule];
            unchecked {
                ++index;
            }
        }
        return guardModulesArray;
    }

    /**
     * @notice Inits the guard modules for a specific wallet.
     *
     * @param  wallet  Address of the wallet to init the guard module.
     * @param  module  Address of the module to init.
     */
    function initGuardModule(address wallet, address module) internal {
        guardModules[wallet][POINTER] = module;
        guardModules[wallet][module] = POINTER;
    }
}