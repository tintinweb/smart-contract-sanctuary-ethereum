// SPDX-License-Identifier: MIT 
pragma solidity 0.8.14;
import "./ERC165.sol";
import "./ERC721Upgradeable.sol";
import "./FoundationTreasuryNode.sol";
import "./FoundationAdminRole.sol";
import "./FoundationOperatorRole.sol";
import "./HasSecondarySaleFees.sol";
import "./NFT721Core.sol";
import "./NFT721Market.sol";
import "./NFT721Creator.sol";
import "./NFT721Metadata.sol";
import "./NFT721Mint.sol";
import "./AccountMigration.sol";
import "./NFT721ProxyCall.sol";
import "./ERC165UpgradeableGap.sol";
contract FNDNFT721 is
  FoundationTreasuryNode,
  FoundationAdminRole,
  FoundationOperatorRole,
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
  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize(address payable treasury) public initializer {
    FoundationTreasuryNode._initializeFoundationTreasuryNode(treasury);
    ERC721Upgradeable.__ERC721_init();
    NFT721Mint._initializeNFT721Mint();
  }

  /**
   * @notice Allows a Foundation admin to update NFT config variables.
   * @dev This must be called right after the initial call to `initialize`.
   */
  function adminUpdateConfig(
    address _nftMarket,
    string memory baseURI,
    address proxyCallContract
  ) public onlyFoundationAdmin {
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