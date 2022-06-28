// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Context.sol";
import "./Ownable.sol";
import "./Strings.sol";


import "./ERC721A.sol";

  // the rarible dependency files are needed to setup sales royalties on Rarible
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

/*

This contract allows for royalties and generational mints.

The Contract also supports pausable as well as the standard ERC721a
functionality (based on ERC721)

The royalty interfaces supported are:
  Rarible
  ERC2981 royalty protocol (mintable, etc)

Images are organized by batches of 500.  Thus the uri will change for every 500 images.

*/

contract MAYG_721a is ERC721A, Ownable, RoyaltiesV2Impl {

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  bool public paused = false;

    // set the cost to mint each NFT
  uint256 public cost = 0.00 ether;

  string public  constant _baseExtension = ".json";

    // maximum number of tokens that can mint in one batch
  uint256 private _maxFistGenMintBatchSize = 250;
  uint256 private _maxFirstGenTokens = 10000;

  string[20] private _imageRange;

  uint256 private constant _imageRangeBatchSize = 500;
  uint256 private constant _imageRangeBatches = 20;

  event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

  constructor(
    string memory _cid
  ) ERC721A(
     "MAYGNFT_10k",
     "MAYGNFT"
  ) {
    setCIDforRange(_cid, 0);
  }

  function mint(address _to, uint256 _quantity) public onlyOwner {
      require(!paused);

      require(_quantity > 0, "MAYG_721a: invalid quantity, 0");
      require(_quantity <= _maxFistGenMintBatchSize, "MAYG_721a: invalid quantity, too large");

      uint256 supply = totalSupply();
      require(supply + _quantity <= _maxFirstGenTokens, "MAYG_721a: invalid quantity, too many first gen tokens");

      _safeMint(_to, _quantity);
    }

  /*
  */
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory cid = getCIDForTokenInternal(_tokenId);
    string memory tokenIdStr = Strings.toString(_tokenId);

    bytes memory b = abi.encodePacked(cid, tokenIdStr, _baseExtension);
    return string(b);
  }

  function onERC721Received(
      address operator,
      address from,
      uint256 tokenId,
      bytes memory data
  ) public override returns (bytes4) {
  /*
        // for testing reverts with a message from the receiver contract
      if (bytes1(data) == 0x01) {
          revert('reverted in the receiver contract!');
      }

        // for testing with the returned wrong value from the receiver contract
      if (bytes1(data) == 0x02) {
          return 0x0;
      }

        // for testing the reentrancy protection
      if (bytes1(data) == 0x03) {
          IERC721AMock(_erc721aMock).safeMint(address(this), 1);
     }
  */
      emit Received(operator, from, tokenId, data, 20000);
      return this.onERC721Received.selector;
  }

  function withdraw() public payable onlyOwner {

    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

    // configure royalties for Rariable
    // note:  Royalty percentages are in basis points so a 10% sales royalty should be entered as 1000.
  function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesRecipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

    // configure royalties for Mintable using the ERC2981 standard
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      //use the same royalties that were saved for Rariable
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if(_royalties.length > 0) {
      return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
    }
    return (address(0), 0);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
      if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
          return true;
      }

      if(interfaceId == _INTERFACE_ID_ERC2981) {
        return true;
      }

      return super.supportsInterface(interfaceId);
  }


    //pause the contract and do not allow any more minting
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

    //set the cost of an NFT
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function burn(uint256 tokenId, bool approvalCheck) public onlyOwner {
    _burn( tokenId, approvalCheck);
  }

    // start on 1
  function _startTokenId() internal pure override returns (uint256) {
      return 1;
  }

    /*
    // token minting constraints

      _maxFistGenMintBatchSize : max number of tokens one can mint in a batch in a first gen mint.
      _maxFirstGenTokens : total number of first generation tokens
      */

  function setMintConstraints(uint256 maxFistGenMintBatchSize,
                              uint256 maxFirstGenTokens
                              ) public onlyOwner {
    _maxFistGenMintBatchSize = maxFistGenMintBatchSize;
    _maxFirstGenTokens = maxFirstGenTokens;
  }

    // strings are 128 bytes long
    // CIDs are 48 bytes
    // _imageRangeBatchSize = 500;
    // 20 ranges,  from 0 to 19

    // not ideal, but we are only storing 20 ranges.
    // uint256 => string ) private _imageRange;
    // const uint256 _imageRangeBatchSize = 500;

  function setCIDforRange(string memory _cid, uint256 _rangeNo ) public onlyOwner {
    _imageRange[_rangeNo] = _cid;
  }

  function getCIDForToken( uint256 tokenId ) public onlyOwner view returns (string memory) {
    return getCIDForTokenInternal(tokenId);
  }

  function getCIDForTokenInternal( uint256 tokenId ) internal view returns (string memory) {

    require(tokenId > 0 , "tokenId of zero is out of range" );

    uint256 cidIndex = (tokenId-1) / _imageRangeBatchSize;

    require (cidIndex < _imageRangeBatches, "missing CID value for token");

    return _imageRange[cidIndex];
  }
}