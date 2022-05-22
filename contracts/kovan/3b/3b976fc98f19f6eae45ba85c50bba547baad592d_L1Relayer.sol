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
    string message;

    constructor(string memory _message) {
        message = _message;
    }

    event DestinationTransferConfirmationReceived(
        address _bonder, 
        address _user,
        string _message,
        uint256 _amount,
        uint256 _transferId
    );

    function updateRelayInformation(
        address _bonder, 
        address _user,
        string memory _message,
        uint256 _amount,
        uint256 _transferId
    ) 
    public
    {
    message = _message;
    

    emit DestinationTransferConfirmationReceived(
        _bonder,
        _user,
        _message,
        _amount,
        _transferId
    );
    }
    
}