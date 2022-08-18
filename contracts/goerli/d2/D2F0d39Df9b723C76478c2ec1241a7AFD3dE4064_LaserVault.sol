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

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title  ILaserVault
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser guard module that locks assets of a Laser wallet for extra security.
 *         It acts as a vault in the sense that the locked assets cannot be use unless the wallet's
 *         owner (or authorized module) orders otherwise.
 *
 * @dev    This interface has all events, errors, and external function for LaserMasterGuard.
 */
interface ILaserVault {
    event TokensAdded(address indexed, uint256 indexed);
    event TokensRemoved(address indexed, uint256 indexed);

    // verifyEth() custom error.
    error LaserVault__verifyEth__ethInVault();

    // verifyERC20Transfer() custom error.
    error LaserVault__verifyERC20Transfer__erc20InVault();

    // verifyCommonApprove() custom error.
    error LaserVault__verifyCommonApprove__erc20InVault();

    /**
     * @notice Verifies that the transaction doesn't spend assets from the vault.
     *
     * @param  wallet   The address of the wallet.
     * @param  to       Destination address.
     * @param  value    Amount in WEI to transfer.
     * @param callData  Data payload for the transaction.
     */
    function verifyTransaction(
        address wallet,
        address to,
        uint256 value,
        bytes calldata callData,
        uint256,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external view;

    /**
     * @notice Adds tokens to vault.
     *
     * @param  token  The address of the token.
     * @param  amount Amount of tokens to add to the vault.
     */
    function addTokensToVault(address token, uint256 amount) external;

    /**
     * @notice Removes tokens from vault.
     *
     * @param  token             The address of the token.
     * @param  amount            Amount of tokens to remove to the vault.
     * @param guardianSignature  Signature of one of the wallet's guardians.
     *                           In order to take tokens out of the vault, it needs to be
     *                           signed by the owner + a guardian.
     */
    function removeTokensFromVault(
        address token,
        uint256 amount,
        bytes calldata guardianSignature
    ) external;

    /**
     * @param wallet The address of the wallet.
     * @param token  The address of the token.
     *
     * @return The amount of tokens that are in the vault from the provided token and wallet.
     */
    function getTokensInVault(address wallet, address token) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../../common/Utils.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/ILaserModuleSSR.sol";
import "../../interfaces/ILaserState.sol";
import "../../interfaces/ILaserVault.sol";

/**
 * @title  LaserVault
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser guard module that locks assets of a Laser wallet for extra security.
 *         It acts as a vault in the sense that the locked assets cannot be use unless the wallet's
 *         owner (or authorized module) orders otherwise.
 */
contract LaserVault is ILaserVault {
    /*//////////////////////////////////////////////////////////////
                          Init module 
    //////////////////////////////////////////////////////////////*/

    address public immutable LASER_SMART_SOCIAL_RECOVERY;

    /*//////////////////////////////////////////////////////////////
                         ERC-20 function selectors
    //////////////////////////////////////////////////////////////*/

    bytes4 private constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));

    bytes4 private constant ERC20_INCREASE_ALLOWANCE = bytes4(keccak256("increaseAllowance(address,uint256)"));

    /*//////////////////////////////////////////////////////////////
                         ERC-721 function selectors
    //////////////////////////////////////////////////////////////*/

    bytes4 private constant ERC721_SAFE_TRANSFER_FROM =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));

    bytes4 private constant ERC721_SAFE_TRANSFER_FROM2 = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));

    /*//////////////////////////////////////////////////////////////
                         ERC-1155 function selectors
    //////////////////////////////////////////////////////////////*/

    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

    bytes4 private constant ERC1155_SAFE_BATCH_TRANSFER_FROM =
        bytes4(keccak256(("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")));

    /*//////////////////////////////////////////////////////////////
                         Shared function selectors
    //////////////////////////////////////////////////////////////*/

    bytes4 private constant COMMON_APPROVE = bytes4(keccak256("approve(address,uint256)"));

    bytes4 private constant COMMON_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));

    bytes4 private constant COMMON_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"));

    /*//////////////////////////////////////////////////////////////
                          ETH encoded address
    //////////////////////////////////////////////////////////////*/

    address private constant ETH = address(bytes20(bytes32(keccak256("ETH.ENCODED.LASER"))));

    /*//////////////////////////////////////////////////////////////
                          Vault's storage
    //////////////////////////////////////////////////////////////*/

    // walletAddress => tokenAddress => amount.
    mapping(address => mapping(address => uint256)) private tokensInVault;

    // walletAddress => nftAddress => tokenId => boolean.
    mapping(address => mapping(address => mapping(uint256 => bool))) private nftsInVault;

    constructor(address smartSocialRecovery) {
        //@todo Check that the smart social recovery is registred in LaserRegistry.
        LASER_SMART_SOCIAL_RECOVERY = smartSocialRecovery;
    }

    /**
     * @notice Verifies that the transaction doesn't spend assets from the vault.
     *
     * @param  wallet   The address of the wallet.
     * @param  to       Destination address.
     * @param  value    Amount in WEI to transfer.
     * @param callData  Data payload for the transaction.
     */
    function verifyTransaction(
        address wallet,
        address to,
        uint256 value,
        bytes calldata callData,
        uint256,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external view {
        bytes4 funcSelector = bytes4(callData);

        // If value is greater than 0, then it is an ETH transfer.
        if (value > 0) {
            verifyEth(wallet, value);
        }

        if (funcSelector == ERC20_TRANSFER) {
            verifyERC20Transfer(wallet, to, callData);
        }

        if (funcSelector == COMMON_APPROVE) {
            verifyCommonApprove(wallet, to, callData);
        }

        if (funcSelector == ERC20_INCREASE_ALLOWANCE) {
            verifyERC20IncreaseAllowance(wallet, to, callData);
        }
    }

    /**
     * @notice Adds tokens to vault.
     *
     * @param  token  The address of the token.
     * @param  amount Amount of tokens to add to the vault.
     */
    function addTokensToVault(address token, uint256 amount) external {
        address wallet = msg.sender;

        tokensInVault[wallet][token] += amount;

        emit TokensAdded(token, amount);
    }

    /**
     * @notice Removes tokens from vault.
     *
     * @param  token             The address of the token.
     * @param  amount            Amount of tokens to remove to the vault.
     * @param guardianSignature  Signature of one of the wallet's guardians.
     *                           In order to take tokens out of the vault, it needs to be
     *                           signed by the owner + a guardian.
     */
    function removeTokensFromVault(
        address token,
        uint256 amount,
        bytes calldata guardianSignature
    ) external {
        address wallet = msg.sender;

        // We subtract 1 from the nonce because the nonce was incremented at the
        // beginning of the transaction.
        uint256 walletNonce = ILaserState(wallet).nonce() - 1;

        bytes32 signedHash = keccak256(abi.encodePacked(token, amount, block.chainid, wallet, walletNonce));

        address signer = Utils.returnSigner(signedHash, guardianSignature, 0);

        require(ILaserModuleSSR(LASER_SMART_SOCIAL_RECOVERY).isGuardian(wallet, signer), "Invalid guardian signature");

        tokensInVault[wallet][token] -= amount;

        emit TokensRemoved(token, amount);
    }

    /**
     * @param wallet The address of the wallet.
     * @param token  The address of the token.
     *
     * @return The amount of tokens that are in the vault from the provided token and wallet.
     */
    function getTokensInVault(address wallet, address token) external view returns (uint256) {
        return tokensInVault[wallet][token];
    }

    /**
     * @notice Verifies that the transfer amount is in bounds.
     *
     * @param wallet   The wallet address.
     * @param value    Amount in 'WEI' to transfer.
     */
    function verifyEth(address wallet, uint256 value) internal view {
        // If value is greater than 0, then  it is ETH transfer.
        uint256 walletBalance = address(wallet).balance;

        uint256 ethInVault = tokensInVault[wallet][ETH];

        if (walletBalance - value < ethInVault) revert LaserVault__verifyEth__ethInVault();
    }

    /**
     * @notice Verifies that the transfer amount is in bounds.
     *
     * @param wallet    The wallet address.
     * @param to        The address to transfer the tokens to.
     * @param callData  The calldata of the function.
     */
    function verifyERC20Transfer(
        address wallet,
        address to,
        bytes calldata callData
    ) internal view {
        (, uint256 transferAmount) = abi.decode(callData[4:], (address, uint256));

        uint256 _tokensInVault = tokensInVault[wallet][to];

        uint256 walletTokenBalance = IERC20(to).balanceOf(wallet);

        if (walletTokenBalance - transferAmount < _tokensInVault) {
            revert LaserVault__verifyERC20Transfer__erc20InVault();
        }
    }

    /**
     * @notice Verifies that the spender's allowance is in bounds with the tokens in vault.
     *
     * @param wallet   The wallet address.
     * @param to       The address to transfer the tokens to.
     * @param callData The calldata of the function.
     */
    function verifyCommonApprove(
        address wallet,
        address to,
        bytes calldata callData
    ) internal view {
        (address spender, uint256 amount) = abi.decode(callData[4:], (address, uint256));

        // First we will check if it is ERC20.
        uint256 _tokensInVault = tokensInVault[wallet][to];

        if (_tokensInVault > 0) {
            // Then it is definitely an ERC20.
            uint256 walletTokenBalance = IERC20(to).balanceOf(wallet);

            uint256 spenderAllowance = IERC20(to).allowance(wallet, spender);

            if (walletTokenBalance - (amount + spenderAllowance) < _tokensInVault) {
                revert LaserVault__verifyCommonApprove__erc20InVault();
            }
        }
    }

    /**
     * @notice Verifies that the wallet has enough allowance to transfer the amount of tokens.
     *
     * @param wallet   The wallet address.
     * @param to       The address to transfer the tokens to.
     * @param callData The calldata of the function.
     */
    function verifyERC20IncreaseAllowance(
        address wallet,
        address to,
        bytes calldata callData
    ) internal view {
        (address spender, uint256 addedValue) = abi.decode(callData[4:], (address, uint256));

        uint256 _tokensInVault = tokensInVault[wallet][to];

        uint256 walletTokenBalance = IERC20(to).balanceOf(wallet);

        uint256 spenderCurrentAllowance = IERC20(to).allowance(spender, wallet);
        uint256 spenderNewAllowance = spenderCurrentAllowance + addedValue;

        require(walletTokenBalance - spenderNewAllowance > _tokensInVault, "Allowance exceeds vault.");
    }
}