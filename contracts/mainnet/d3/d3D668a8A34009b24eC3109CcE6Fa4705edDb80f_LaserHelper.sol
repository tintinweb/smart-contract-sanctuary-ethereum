// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaser {
    function owner() external view returns (address);

    function singleton() external view returns (address);

    function timeLock() external view returns (uint256);

    function isLocked() external view returns (bool);

    function nonce() external view returns (uint256);

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
}

interface ILaserModuleSSR {
    function getRecoveryOwners(address wallet) external view returns (address[] memory);

    function getGuardians(address wallet) external view returns (address[] memory);
}

/**
 * @title LaserHelper - Helper contract that outputs multiple results in a single call.
 */
contract LaserHelper {
    /**
     * @dev Returns the wallet state + SSR module.
     */
    function getWalletState(address laserWallet, address SSRModule)
        external
        view
        returns (
            address owner,
            address singleton,
            bool isLocked,
            address[] memory guardians,
            address[] memory recoveryOwners,
            uint256 nonce,
            uint256 balance
        )
    {
        ILaser laser = ILaser(laserWallet);
        ILaserModuleSSR laserModule = ILaserModuleSSR(SSRModule);
        owner = laser.owner();
        singleton = laser.singleton();
        isLocked = laser.isLocked();
        guardians = laserModule.getGuardians(laserWallet);
        recoveryOwners = laserModule.getRecoveryOwners(laserWallet);
        nonce = laser.nonce();
        balance = address(laserWallet).balance;
    }

    function simulateTransaction(
        address to,
        bytes calldata callData,
        uint256 value,
        uint256 gasLimit
    ) external returns (uint256 totalGas) {
        totalGas = gasLimit - gasleft();

        (bool success, ) = payable(to).call{value: value}(callData);
        require(success, "main execution failed.");

        totalGas = totalGas - gasleft();
        require(msg.sender == address(0), "Must be called off-chain from address zero.");
    }
}