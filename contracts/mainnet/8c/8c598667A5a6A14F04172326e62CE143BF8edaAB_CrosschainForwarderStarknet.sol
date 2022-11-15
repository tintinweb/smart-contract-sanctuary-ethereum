// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface StarkNetLike {
    function sendMessageToL2(
        uint256 to,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    function consumeMessageFromL2(uint256 from, uint256[] calldata payload)
        external
        returns (bytes32);

    function startL1ToL2MessageCancellation(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;

    function cancelL1ToL2Message(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;
}

contract CrosschainForwarderStarknet {
    uint256 constant RELAY_SELECTOR =
        300224956480472355485152391090755024345070441743081995053718200325371913697;

    address public immutable starkNet;
    uint256 public immutable l2GovernanceRelay;

    constructor(address _starkNet, uint256 _l2GovernanceRelay) {
        starkNet = _starkNet;
        l2GovernanceRelay = _l2GovernanceRelay;
    }

    function execute(uint256 spell) public {
        uint256[] memory payload = new uint256[](1);
        payload[0] = spell;
        StarkNetLike(starkNet).sendMessageToL2(
            l2GovernanceRelay,
            RELAY_SELECTOR,
            payload
        );
    }
}