/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// packages required
// "@eth-optimism/contracts: ^0.5.14";
// "@eth-optimism/sdk: ^1.0.1";

// import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

contract L1Relayer {
    event DestinationTransferConfirmationReceived(
        address _bonder, 
        address _user,
        uint256 _amount,
        uint256 _transferId
    );

    function updateRelayInformation(
        address _bonder, 
        address _user,
        uint256 _amount,
        uint256 _transferId
    ) 
    external
    {

    emit DestinationTransferConfirmationReceived(
        _bonder,
        _user,
        _amount,
        _transferId
    );
    }
    
}