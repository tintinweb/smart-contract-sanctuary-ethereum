// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMX.sol";

contract Registration {
    IMX public imx;

    constructor(IMX _imx) {
        imx = _imx;
    }

    function registerAndDeposit(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        uint256 vaultId
    ) external payable {
        imx.registerUser(ethKey, starkKey, signature);
        // the standard way to write this is: imx.deposit.value(msg.value)(starkKey, assetType, vaultId);
        // but the Solidity compiler hates the overloading of deposit + the use of .value()
        (bool success, ) = address(imx).call{value: msg.value}(
            abi.encodeWithSignature(
                "deposit(uint256,uint256,uint256)",
                starkKey,
                assetType,
                vaultId
            )
        );
        require(success, "Deposit Failed");
    }

    function registerAndDeposit(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external {
        imx.registerUser(ethKey, starkKey, signature);
        imx.deposit(starkKey, assetType, vaultId, quantizedAmount);
    }

    function registerAndDepositNft(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        uint256 vaultId,
        uint256 tokenId
    ) external {
        imx.registerUser(ethKey, starkKey, signature);
        imx.depositNft(starkKey, assetType, vaultId, tokenId);
    }

    function registerAndWithdraw(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType
    ) external {
        imx.registerUser(ethKey, starkKey, signature);
        imx.withdraw(starkKey, assetType);
    }

    function registerAndWithdrawTo(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        address recipient
    ) external {
        imx.registerUser(ethKey, starkKey, signature);
        imx.withdrawTo(starkKey, assetType, recipient);
    }

    function registerAndWithdrawNft(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        uint256 tokenId
    ) external {
        imx.registerUser(ethKey, starkKey, signature);
        imx.withdrawNft(starkKey, assetType, tokenId);
    }

    function registerAndWithdrawNftTo(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        uint256 tokenId,
        address recipient
    ) external {
        imx.registerUser(ethKey, starkKey, signature);
        imx.withdrawNftTo(starkKey, assetType, tokenId, recipient);
    }

    function regsiterAndWithdrawAndMint(
        address ethKey,
        uint256 starkKey,
        bytes calldata signature,
        uint256 assetType,
        bytes calldata mintingBlob
    ) external {
        imx.registerUser(ethKey, starkKey, signature);
        imx.withdrawAndMint(starkKey, assetType, mintingBlob);
    }

    function isRegistered(uint256 starkKey) public view returns (bool) {
        return imx.getEthKey(starkKey) != address(0);
    }
}