// SPDX-License-Identifier: MIT 
pragma solidity 0.8.15;
import "./ERC165.sol";
import "./ERC721Upgradeable.sol";
import "./TreasuryNode.sol";
import "./AdminRole.sol";
import "./OperatorRole.sol";
import "./HasSecondarySaleFees.sol";
import "./NFT721Core.sol";
import "./NFT721Market.sol";
import "./NFT721Creator.sol";
import "./NFT721Metadata.sol";
import "./NFT721Mint.sol";
import "./AccountMigration.sol";
import "./NFT721ProxyCall.sol";
import "./ERC165UpgradeableGap.sol";
contract SSSNFT721 is
  TreasuryNode,
  AdminRole,
  OperatorRole,
  AccountMigration,
  ERC165UpgradeableGap,
  ERC165,
  HasSecondarySaleFees,
  ERC721Upgradeable,
  NFT721Core,
  NFT721ProxyCall,
  NFT721Creator,
  NFT721Market,
  NFT721Metadata,
  NFT721Mint
{
  function initialize(address payable treasury) public initializer {
    TreasuryNode._initializeTreasuryNode(treasury);
    ERC721Upgradeable.__ERC721_init();
    NFT721Mint._initializeNFT721Mint();
  }
  function adminUpdateConfig(
    address _nftMarket,
    string memory baseURI,
    address proxyCallContract
  ) public onlyAdmin {
    _updateNFTMarket(_nftMarket);
    _updateBaseURI(baseURI);
    _updateProxyCall(proxyCallContract);
  }
  function _burn(uint256 tokenId) internal override(ERC721Upgradeable, NFT721Creator, NFT721Metadata, NFT721Mint) {
    super._burn(tokenId);
  }
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, HasSecondarySaleFees, NFT721Mint, ERC721Upgradeable, NFT721Creator, NFT721Market)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}