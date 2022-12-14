// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
// [Acknowledgement]
//     This contract was inspired by ethereum-optimism/optimism-tutorial `FromL1_ControlL2Greeter.sol`.
// [Usage]
//     This contract runs on L1 (Goerli) and controls a `Greeter.sol` on L2 (Optimism Goerli).
pragma solidity ^0.8.17;

import "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

contract FromL1_ControlL2Greeter {
    address constant L1CrossDomainMessenger = 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294; // [1]
    address immutable greeterOnL2;
    
    constructor(address _greeterOnL2) {
        greeterOnL2 = _greeterOnL2;
    }
    
    function setGreeting(string calldata _greeting) public {
        bytes memory message;
            
        message = abi.encodeWithSignature(
            "setGreeting(string)", 
            _greeting
        );
        
        ICrossDomainMessenger(L1CrossDomainMessenger).sendMessage(
            greeterOnL2,
            message,
            1000000 // [2]
        );
    }
}

// [1]: Some useful addresses can be found at:
//      https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts/deployments/goerli#layer-1-contracts
// [2]: The number of free gas quota can be found at:
//      https://community.optimism.io/docs/developers/bridge/messaging/#for-l1-%E2%87%92-l2-transactions