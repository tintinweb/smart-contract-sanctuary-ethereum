/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IStarknetCore {
  /// @notice Sends a message to an L2 contract.
  /// @return the hash of the message.
  function sendMessageToL2(
    uint256 toAddress,
    uint256 selector,
    uint256[] calldata payload
  ) external returns (bytes32);

  /// @notice Consumes a message that was sent from an L2 contract.
  /// @return the hash of the message.
  function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
    external returns(bytes32);
}

interface IERC721Read {
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
}

/// @notice L1 counter-part of the Cairo contract that reads a token's data
contract NFTChecker {
  IStarknetCore starknetCore;
  // Function IDs (optional) used while receiving
  uint256 constant PROVE_NFT_OWNERSHIP = 0;
  // Selectors used while sending
  uint256 constant SET_OWNER_OF_SELECTOR = 
  1360114337191064846240331428331736981605565427608539543753235946271679306594;

  constructor() {
    starknetCore = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
  }

  function proveNFTOwnership(
    uint256 l2ContractAddress,
    address nftAddress,
    uint256 nftId,
    address ownerAddress
  ) external {
    uint256[] memory rcvPayload = new uint256[](4);
    rcvPayload[0] = PROVE_NFT_OWNERSHIP;
    rcvPayload[1] = uint256(uint160(nftAddress));
    rcvPayload[2] = nftId;
    rcvPayload[3] = uint256(uint160(ownerAddress));

    // Search for and consume the msg from L2
    starknetCore.consumeMessageFromL2(
      l2ContractAddress, 
      rcvPayload
    );

    // If above call didn't revert it means that there was a call with arguments
    // we've provided, now we can send a message to the L2

    bool isOwner = IERC721Read(nftAddress).ownerOf(nftId) == ownerAddress;

    uint256[] memory sendPayload = new uint256[](4);
    sendPayload[1] = uint256(uint160(nftAddress));
    sendPayload[2] = nftId;
    sendPayload[3] = uint256(uint160(ownerAddress));
    sendPayload[4] = isOwner ? 1 : 0;

    // Send msg to L2
    starknetCore.sendMessageToL2(
      l2ContractAddress, 
      SET_OWNER_OF_SELECTOR, 
      sendPayload
    );
  }
}

///            @author                                           
/// _____  __  _  _  _____ __  __
/// ` / /_|  \| || ||_   _|\ \/ /
///  /___/|_|\__||_|  |_|   |__|