// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IStarknetCore.sol";

contract L2L1Message {
    IStarknetCore starkNetCore;
    uint256 constant MESSAGE_SELECTOR =
        897827374043036985111827446442422621836496526085876968148369565281492581228;
    uint256 private L2_NFT_ADDRESS =
        3299554814824158824218957723762657724237806158670943467750440497544585829143;

    constructor(address _starkNetCore) {
        require(_starkNetCore != address(0), "non-zero address only");
        starkNetCore = IStarknetCore(_starkNetCore);
    }

    function mintL2Nft(uint256 _user) external {
        require(_user != 0, "non-zero");
        uint256[] memory messagePayload = new uint256[](1);
        messagePayload[0] = _user;

        starkNetCore.sendMessageToL2(
            L2_NFT_ADDRESS,
            MESSAGE_SELECTOR,
            messagePayload
        );
    }

    function exercise3(uint256 _l2CallerAddress) external {
        require(_l2CallerAddress != 0, "non-zero only");
        uint256[] memory l2Payload = new uint256[](1);
        l2Payload[0] = _l2CallerAddress;
        starkNetCore.consumeMessageFromL2(L2_NFT_ADDRESS, l2Payload);
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