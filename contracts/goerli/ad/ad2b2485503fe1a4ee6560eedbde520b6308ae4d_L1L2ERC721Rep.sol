/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

pragma solidity ^0.8.7;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

/**
  Demo contract for L1 <-> L2 interaction between an L2 StarkNet contract and this L1 solidity
  contract.
*/
contract L1L2ERC721Rep {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    mapping(uint256 => uint256) public nftIdReputationPoints;

    uint256 constant MESSAGE_REP_DOWN = 0;

    // The selector of the "repUp" l1_handler.
    uint256 constant REPUP_SELECTOR =
        481301234104709516967081079511443560691305293629011359495317790738588668414;

    /**
      Initializes the contract state.
    */
    constructor(IStarknetCore starknetCore_) {
        starknetCore = starknetCore_;
    }

    function rep_down(
        uint256 l2ContractAddress,
        uint256 nftId,
        uint256 amount
    ) external {
        // Construct the rep down message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = MESSAGE_REP_DOWN;
        payload[1] = nftId;
        payload[2] = amount;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 reputation points of the NFT.
        nftIdReputationPoints[nftId] += amount;
    }

    function repUp(
        uint256 l2ContractAddress,
        uint256 nftId,
        uint256 amount
    ) external {
        require(amount < 2**64, "Invalid amount.");
        require(amount <= nftIdReputationPoints[nftId], "Insufficient nftId's reputation points.");

        // Update the L1 reputation points of the NFT.
        nftIdReputationPoints[nftId] -= amount;

        // Construct the repUp message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = nftId;
        payload[1] = amount;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, REPUP_SELECTOR, payload);
    }
}