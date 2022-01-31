/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface FeedInterface {
    function transmitters() external view returns (address[] memory);

    function transferPayeeship(address _transmitter, address _proposed) external;

    function acceptPayeeship(address _transmitter) external;
}

contract PayeeshipTransferer {
    error DelegateCallFail(bytes data);

    /// @notice Check if the payee can change the payeeship of the target feeds.
    /// @param targets Target price feeds
    /// @param payee The payee requesting change of payeeship
    /// @return canRequest Boolean value indiciating whether the sender can change the payeeship of given targets
    /// @return wrongPermissions Array of targets that the sender does not have permission to request a change
    function canRequestChangeOfPayeeship(FeedInterface[] memory targets, address payee)
        external
        view
        returns (bool canRequest, FeedInterface[] memory wrongPermissions)
    {
        wrongPermissions = new FeedInterface[](targets.length);
        uint256 wrongPermissionsCounter = 0;
        for (uint256 i = 0; i < targets.length; i++) {
            FeedInterface targetContract = targets[i];
            address[] memory transmitters = targetContract.transmitters();

            for (uint256 j = 0; j < transmitters.length; j++) {
                if (transmitters[j] == payee) {
                    break;
                }
                if (j == transmitters.length - 1) {
                    wrongPermissions[wrongPermissionsCounter] = targetContract;
                    wrongPermissionsCounter++;
                }
            }

            if (transmitters.length == 0) {
                wrongPermissions[wrongPermissionsCounter] = targetContract;
                wrongPermissionsCounter++;
            }
        }

        if (wrongPermissionsCounter == 0) {
            canRequest = true;
        }
        // Set the length of wrongPermissions to the correct length
        assembly {
            mstore(wrongPermissions, wrongPermissionsCounter)
        }
    }

    /// @notice Request to change the payeeship of the target contracts from the message sender, to the newPayee
    /// @dev Call canRequestChangeOfPayeeship() first to esnure that the sender CAN call this without reverts
    /// @param targets Array of target contracts to change the payee
    /// @param newPayee Address of the new Payee
    function requestChangeOfPayeeship(address[] memory targets, address newPayee) external {
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory data) = targets[i].delegatecall(abi.encodeWithSelector(FeedInterface.transferPayeeship.selector, msg.sender, newPayee));
            if (!success) revert DelegateCallFail(data);
        }
    }

    /// @notice Accepts payeeship change for msg.sender on each of the targets. The oldPayee must request change before this step
    /// @dev Must be called by the account accepting the payeeship
    /// @param targets Array of target contracts to change the payee
    /// @param oldPayee The original payee that requested the change
    function acceptChangeOfPayeeship(address[] memory targets, address oldPayee) external {
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory data) = targets[i].delegatecall(abi.encodeWithSelector(FeedInterface.acceptPayeeship.selector, msg.sender, oldPayee));
            if (!success) revert DelegateCallFail(data);
        }
    }
}