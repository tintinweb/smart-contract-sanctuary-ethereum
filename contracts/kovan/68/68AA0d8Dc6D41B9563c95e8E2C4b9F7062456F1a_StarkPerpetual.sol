// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract StarkPerpetual {

    // Monitored events.
    event LogDeposit(
        address depositorEthKey,
        uint256 starkKey,
        uint256 vaultId,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount
    );
    event LogWithdrawalPerformed(
        uint256 ownerKey,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount,
        address recipient
    );
    event LogMintWithdrawalPerformed(
        uint256 ownerKey,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount,
        uint256 assetId
    );

    
    function emitLogDeposit(
        address depositorEthKey,
        uint256 starkKey,
        uint256 vaultId,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount
    ) external {
        emit LogDeposit(depositorEthKey, starkKey, vaultId, assetType, nonQuantizedAmount, quantizedAmount);
    }

    function emitLogWithdrawalPerformed(
        uint256 ownerKey,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount,
        address recipient
    ) external {
        emit LogWithdrawalPerformed(ownerKey, assetType, nonQuantizedAmount, quantizedAmount, recipient);
    }

    function emitLogMintWithdrawalPerformed(
        uint256 ownerKey,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount,
        uint256 assetId
    ) external {
        emit LogMintWithdrawalPerformed(ownerKey, assetType, nonQuantizedAmount, quantizedAmount, assetId);
    }

}