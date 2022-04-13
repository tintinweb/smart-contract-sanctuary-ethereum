pragma solidity ^0.8.4;

import "../registration/IMX.sol";

contract BatchWithdrawal {
    IMX public imx;
    
    constructor(IMX _imx) {
        imx = _imx;
    }
    struct Withdrawal {
        uint256 assetType;
        bytes mintingBlob;
    }


    function withdrawBatch(uint256 starkKey, Withdrawal[] calldata withdrawals) external {
        for (uint i = 0; i < withdrawals.length; i++) {
            Withdrawal memory w = withdrawals[i];
            imx.withdrawAndMint(starkKey, w.assetType, w.mintingBlob);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMX {
    function getEthKey(uint256 starkKey) external view returns (address);

    function registerUser(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature
    ) external;

    function deposit(
        uint256 starkKey,
        uint256 assetType,
        uint256 vaultId
    ) external payable;

    function deposit(
        uint256 starkKey,
        uint256 assetType,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    function depositNft(
        uint256 starkKey,
        uint256 assetType,
        uint256 vaultId,
        uint256 tokenId
    ) external;

    function withdraw(uint256 starkKey, uint256 assetType) external;

    function withdrawTo(
        uint256 starkKey,
        uint256 assetType,
        address recipient
    ) external;

    function withdrawNft(
        uint256 starkKey,
        uint256 assetType,
        uint256 tokenId
    ) external;

    function withdrawNftTo(
        uint256 starkKey,
        uint256 assetType,
        uint256 tokenId,
        address recipient
    ) external;

    function withdrawAndMint(
        uint256 starkKey,
        uint256 assetType,
        bytes calldata mintingBlob
    ) external;
}