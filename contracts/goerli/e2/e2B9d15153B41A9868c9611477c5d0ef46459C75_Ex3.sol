// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IStarknetCore.sol";

contract Ex3{
    IStarknetCore starknetCore;

    constructor(
        address starknetCore_
    ) {
        starknetCore = IStarknetCore(starknetCore_);

    }

    function consumeMessage(uint256 l2ContractAddress, uint256 l2User) public returns(bool){
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
        return true;
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