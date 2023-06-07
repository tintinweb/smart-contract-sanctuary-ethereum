// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title HeyMint ERC721A Function Reference
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This is a function reference contract for Etherscan reference purposes only.
 * This contract includes all the functions from multiple implementation contracts.
 */
contract HeyMintERC1155Reference {
    struct BaseConfig {
    uint24 projectId;
    string uriBase;
    bool enforceRoyalties;
    uint16 royaltyBps;
    bool heyMintFeeActive;
    address presaleSignerAddress;
  }

   struct TokenConfig {
    uint16 tokenId;
    uint16 maxSupply;
    bool publicSaleActive;
    uint32 publicPrice;
    uint8 publicMintsAllowedPerAddress;
    bool usePublicSaleTimes;
    uint32 publicSaleStartTime;
    uint32 publicSaleEndTime;
    bool presaleActive;
    uint32 presalePrice;
    uint16 presaleMaxSupply;
    uint8 presaleMintsAllowedPerAddress;
    uint32 presaleStartTime;
    uint32 presaleEndTime;
    string tokenUri;
  }

   function CORI_SUBSCRIPTION_ADDRESS() external view returns (address ) {}

   function DOMAIN_SEPARATOR() external view returns (bytes32 ) {}

   function EMPTY_SUBSCRIPTION_ADDRESS() external view returns (address ) {}

   function balanceOf(address  owner, uint256  id) external view returns (uint256 ) {}

   function balanceOfBatch(address[] memory owners, uint256[] memory ids) external view returns (uint256[] memory balances) {}

   function defaultHeymintFeePerToken() external view returns (uint256 ) {}

   function heymintFeePerToken() external view returns (uint256 ) {}

   function heymintPayoutAddress() external view returns (address ) {}

   function initialize(string memory _name, string memory _symbol, BaseConfig memory _config, TokenConfig[] memory _tokenConfig) external {}

   function isApprovedForAll(address  operator, address  owner) external view returns (bool ) {}

   function isOperatorFilterRegistryRevoked() external view returns (bool ) {}

   function name() external view returns (string memory) {}

   function nonces(address  owner) external view returns (uint256 ) {}

   function owner() external view returns (address ) {}

   function paused() external view returns (bool ) {}

   function permit(address  owner, address  operator, uint256  deadline, uint8  v, bytes32  r, bytes32  s_) external {}

   function renounceOwnership() external {}

   function revokeOperatorFilterRegistry() external {}

   function royaltyInfo(uint256 , uint256  _salePrice) external view returns (address , uint256 ) {}

   function safeBatchTransferFrom(address  from, address  to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external {}

   function safeTransferFrom(address  from, address  to, uint256  id, uint256  amount, bytes memory data) external {}

   function setApprovalForAll(address  operator, bool  approved) external {}

   function supportsInterface(bytes4  interfaceId) external view returns (bool ) {}

   function symbol() external view returns (string memory) {}

   function transferOwnership(address  newOwner) external {}

   function uri(uint256  id) external view returns (string memory) {}
}