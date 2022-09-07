// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Admin__DoesNotExist();

/**
 * @title Admin
 * @notice This contract holds the information for admin wallets and Gnosis safe
 * @author Erly Stage Studios
 */
contract Admin {
    address[] private s_whiteListedWallets;

    address private s_gnosisWallet;

    /**
     * @notice Add a wallet to whitelist
     * @param walletAddress: the address of the wallet of the admin
     */
    function addWalletToWhiteList(address walletAddress) external {
        s_whiteListedWallets.push(walletAddress);
    }

    /**
     * @notice check if the given wallet is whitelisted
     * @param walletAddress: the address of the wallet
     * @return bool: the truth value if wallet exists or not
     */
    function checkWhitelisted(address walletAddress)
        external
        view
        returns (bool)
    {
        bool success = false;
        for (uint256 i = 0; i < s_whiteListedWallets.length; i++) {
            if (s_whiteListedWallets[i] == walletAddress) {
                success = true;
                break;
            }
        }
        return success;
    }

    /**
     * @notice remove the wallet address from whitelist
     * @param walletAddress: the address of the wallet
     */
    function removeWallet(address walletAddress) external {
        bool found = false;
        for (uint256 i = 0; i < s_whiteListedWallets.length; i++) {
            if (s_whiteListedWallets[i] == walletAddress) {
                found = true;
                delete s_whiteListedWallets[i];
                break;
            }
        }
        if (!found) {
            revert Admin__DoesNotExist();
        }
    }

    /**
     * @notice save the main Gnosis wallet address
     * @param walletAddress: the wallet Address of the genosis wallet
     */
    function connectGnosisWallet(address walletAddress) external {
        s_gnosisWallet = walletAddress;
    }

    /**
     * @notice getter for the Gnosis wallet address
     * @return address: the address of the Gnosis wallet
     */
    function getGnosisWalletAddress() external view returns (address) {
        return s_gnosisWallet;
    }
}