/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

contract AcuityAccount {

    /**
     * @dev Mapping of account to ACU account.
     */
    mapping (address => bytes32) accountAcuAccount;

    /**
     * @dev ACU account has been set for an account.
     * @param account Account that has set its ACU account.
     * @param acuAccount ACU account that has been set for account.
     */
    event AcuAccountSet(address indexed account, bytes32 indexed acuAccount);

    /**
     * @dev Set Acu account for sender.
     * @param acuAccount ACU account to set for sender.
     */
    function setAcuAccount(bytes32 acuAccount)
        external
    {
        accountAcuAccount[msg.sender] = acuAccount;
        emit AcuAccountSet(msg.sender, acuAccount);
    }

    /**
     * @dev Get ACU account for account.
     * @param account Account to get ACU account for.
     * @return acuAccount ACU account for account.
     */
    function getAcuAccount(address account)
        external
        view
        returns (bytes32 acuAccount)
    {
        acuAccount = accountAcuAccount[account];
    }

}