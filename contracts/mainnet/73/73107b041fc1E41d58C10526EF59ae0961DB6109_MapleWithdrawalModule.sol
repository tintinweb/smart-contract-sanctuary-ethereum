/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// Sources flattened with hardhat v2.10.0 https://hardhat.org

// File contracts/interfaces/Enum.sol

pragma solidity ^0.8.9;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
interface Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}


// File contracts/interfaces/GnosisSafe.sol

pragma solidity ^0.8.9;

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}


// File contracts/MapleWithdrawalModule.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract MapleWithdrawalModule {
    string public constant NAME = "Maple Withdrawal Module";
    string public constant VERSION = "0.1.0";

    address SNX_TREASURY_COUNCIL_MULTISIG_ADDRESS = 0x99F4176EE457afedFfCB1839c7aB7A030a5e4A92;
    address MAPLE_POOL_TOKEN_ADDRESS = 0xFeBd6F15Df3B73DC4307B1d7E65D46413e710C27;

    error InvalidAmount();
    error ExecutionFailed();

    function withdrawFromPool(uint256 usdcToWithdraw) external {
        if (usdcToWithdraw == 0) {
            revert InvalidAmount();
        }

        // Execute
        bool success = _executeSafeTransaction(usdcToWithdraw);
        if (!success) {
            revert ExecutionFailed();
        }
    }


    function _executeSafeTransaction(uint256 usdcToWithdraw) internal returns (bool success) {
        GnosisSafe safe = GnosisSafe(SNX_TREASURY_COUNCIL_MULTISIG_ADDRESS);

        bytes memory payload = abi.encodeWithSignature("withdraw(uint256)", usdcToWithdraw);

        success = safe.execTransactionFromModule(MAPLE_POOL_TOKEN_ADDRESS, 0, payload, Enum.Operation.Call);
    }
}