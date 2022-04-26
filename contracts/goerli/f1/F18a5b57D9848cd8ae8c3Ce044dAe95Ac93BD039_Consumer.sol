//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IStarknetCore.sol";

contract Consumer {
    IStarknetCore starknetCore;
    uint public governor;
    uint public balance;

    constructor(uint _governor, address _starknetCore) {
        starknetCore = IStarknetCore(_starknetCore);
        governor = _governor;
    }

    function increase_balance(uint256 amount) public{
        uint256[] memory payload = new uint256[](1);
        payload[0] = amount;
        starknetCore.consumeMessageFromL2(governor, payload);
        balance += amount;
    }

  
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}