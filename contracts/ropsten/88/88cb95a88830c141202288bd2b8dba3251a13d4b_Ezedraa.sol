// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

//this was created from https://github.com/0xcert/ethereum-erc721/blob/master/src/contracts/mocks/nf-token-metadata-enumerable-mock.sol
//and royalty was from here https://www.gemini.com/blog/exploring-the-nft-royalty-standard-eip-2981 and https://github.com/dievardump/EIP2981-implementation

import "./nf-token-metadata.sol";
import "./nf-token-enumerable.sol";
import "./ownable.sol";
import "./Strings.sol";

import './ERC2981PerTokenRoyalties.sol';

  //These are the most common errors I experienced as I set it up:
  //18001 Not current owner of contract
  //18002 can not transfer to zero address
  //string constant ZERO_ADDRESS = "003001";
  //string constant NOT_VALID_NFT = "003002";
  //string constant NOT_OWNER_OR_OPERATOR = "003003";
  //string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  //string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  //string constant NFT_ALREADY_EXISTS = "003006";
  //string constant NOT_OWNER = "003007";
  //string constant IS_OWNER = "003008";

/**
 * @dev This is an example contract implementation of NFToken with enumerable and metadata
 * extensions.
 */
contract Ezedraa is
  NFTokenEnumerable,
  NFTokenMetadata,
  Ownable,
  ERC2981PerTokenRoyalties
{

  /**
   * @dev Contract constructor.
   * @param _name A descriptive name for a collection of NFTs.
   * @param _symbol An abbreviated name for NFTokens.
   */
    constructor(
    string memory _name,
    string memory _symbol
  )
  {
    nftName = _name;
    nftSymbol = _symbol;
  }


  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */
  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri,
    address royaltyRecipient,
    uint256 royaltyValue
  )
    external
    onlyOwner
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    
    if (royaltyValue > 0) {
        _setTokenRoyalty(_tokenId, royaltyRecipient, royaltyValue);
    }
    
  }

  /**
   * @dev Removes a NFT from owner.
   * @param _tokenId Which NFT we want to remove.
   */
  function burn(
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._burn(_tokenId);
  }


  function setTokenUri(
    uint256 _tokenId,
    string calldata _uri
  )
    external
    onlyOwner
  {
    super._setTokenUri(_tokenId, _uri);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override(NFToken, NFTokenEnumerable)
    virtual
  {
    NFTokenEnumerable._mint(_to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override(NFTokenMetadata, NFTokenEnumerable)
    virtual
  {
    NFTokenEnumerable._burn(_tokenId);
    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._removeNFToken(_from, _tokenId);
  }

  /**
   * @dev Assignes a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._addNFToken(_to, _tokenId);
  }

   /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override(NFToken, NFTokenEnumerable)
    view
    returns (uint256)
  {
    return NFTokenEnumerable._getOwnerNFTCount(_owner);
  }

}