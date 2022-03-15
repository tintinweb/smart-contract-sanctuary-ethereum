// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "UserOperation.sol";
import "IAAWallet.sol";

contract EntryPoint {

    // custom error to catch validateUserOp error.
    error FailedOp(string reason);

    // core ERC 4337 entry point functions:
    function handleOps(UserOperation[] calldata userOps) external returns(bytes memory destination, uint amount){

        for (uint i = 0; i < userOps.length; i++) {
            UserOperation memory userOp = userOps[i];
            address sender = userOp.sender;
            bytes memory callData = userOp.callData;
            bool validationSuccess;

            // validation - call validateUserOp on the wallet passing in a UserOperation and catch errors.
            try IAAWallet(sender).validateUserOp(userOp, false) {
                validationSuccess = true;
            } catch Error(string memory revertReason) {
                revert FailedOp(revertReason);
            }

            // extra fail-safe to stop non-validating userOperations to squeeze through.
            require(validationSuccess == true, "Sorry! UserOperation is not succesfully validated");

            // execution - only run is validateUserOp succeeds.
            try IAAWallet(sender).executionFromEntryPoint(callData) returns(bytes memory _destination, uint _amount) {
                destination = bytes(_destination);
                amount = _amount;
                return (destination, amount);
            } catch Error(string memory revertReason) {
                revert FailedOp(revertReason);
            }
        }
    }
    

    // a way for a bundler to simulate that validateUserOp is successful so it's worth their while to bundle that UserOperation into their handleOps call. 
    function simulateValidation(UserOperation calldata userOp) external {
        address sender = userOp.sender;

        try IAAWallet(sender).validateUserOp(userOp, true) {
        } catch Error(string memory revertReason) {
            revert FailedOp(revertReason);
        }



    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;


struct UserOperation {
    address sender;
    uint256 nonce;
    bytes callData;
    bytes signature;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "UserOperation.sol";

interface IAAWallet {
    // an interface to allow the entry point contract to call the core ERC 4337 wallet functions.
    function validateUserOp(UserOperation calldata userOp, bool simulate) external;
    function executionFromEntryPoint(bytes memory callData) external returns(bytes memory destination, uint amount);

}