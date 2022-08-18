// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../interfaces/ILaserModuleSSR.sol";
import "../interfaces/ILaserState.sol";

///@title LaserHelper - Helper contract that outputs multiple results in a single call.
contract LaserHelper {
    ///@dev Returns the wallet state + SSR module.
    function getWalletState(address wallet, address SSRModule)
        external
        view
        returns (
            address owner,
            address singleton,
            bool isLocked,
            address[] memory guardians,
            address[] memory recoveryOwners,
            uint256 nonce,
            uint256 balance,
            uint256 timeLock
        )
    {
        ILaserState laser = ILaserState(wallet);
        ILaserModuleSSR ssr = ILaserModuleSSR(SSRModule);
        owner = laser.owner();
        singleton = laser.singleton();
        isLocked = laser.isLocked();
        guardians = ssr.getGuardians(wallet);
        recoveryOwners = ssr.getRecoveryOwners(wallet);
        nonce = laser.nonce();
        balance = address(wallet).balance;
        timeLock = ssr.getWalletTimeLock(wallet);
    }
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