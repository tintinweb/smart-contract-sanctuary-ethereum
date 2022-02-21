// SPDX-License-Identifier: MIT

// Contract by TOKS

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract toksalpha is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
  using Strings for uint256;

  string public _baseTokenURI;

  bool public _active = false;
  bool public _presaleActive = false;

  bytes32 public _merkleRoot = 0x3454ba2028cca49223166a1b2b5f75c59cfeaa353eced6a39bd596a31a5fe29e;

  uint256 public _gifts = 300;
  uint256 public _price = 0.065 ether;
  uint256 public _presaleMintLimit = 2;
  uint256 public constant _MINT_LIMIT = 10;
  uint256 public constant _SUPPLY = 10000;
  uint256 public _SALE_SUPPLY = 3200;
  uint256 public _PRESALE_SUPPLY = 6500;

  mapping(address => uint256) private _claimed;

  address public _v1 = 0xB72b8e32860fEB870553D00F421311008a93236C;
  address public _v2 = 0x0d35F889C276b8566DB407fB6BD240388Fb3EdeB;
  address public _v3 = 0x0dB9a71032A1573a0C8ecfC18E99333Bc2e8503E;
  address public _v4 = 0xa28A7bBa6d373805C0E7afC9044F17EAbF3C066E;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor() ERC721("TOKS ALPHA", "TOKSA") {}

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setActive(bool active) public onlyOwner {
    _active = active;
  }

  function setPresaleActive(bool presaleActive) public onlyOwner {
    _presaleActive = presaleActive;
  }

  function setSaleSupply(uint256 saleSupply) public onlyOwner {
    _SALE_SUPPLY= saleSupply;
  }

  function setPresaleSupply(uint256 presaleSupply) public onlyOwner {
    _PRESALE_SUPPLY= presaleSupply;
  }

  function setPresaleMintLimit(uint256 presaleMintLimit) public onlyOwner {
    _presaleMintLimit = presaleMintLimit;
  }

  function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
    _merkleRoot = merkleRoot;
  }

  function setPrice(uint256 price) public onlyOwner {
    _price = price;
  }

  function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
   }

  function royaltyInfo(uint256 _tokenId, uint256 _secndprice) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0) {
            return (_royalties[0].account, (_secndprice * _royalties[0].value)/7500);
        }
        return (address(0), 0);
   }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
  } 

  function getTokensByWallet(address _owner) public view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for(uint256 i; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function getPresaleMints(address owner) public view returns (uint256){    
    return _claimed[owner];    
  }    
    
  function gift(address _to, uint256 _amount) public onlyOwner {    
    uint256 supply = totalSupply();    
    require(_amount <= _gifts, "Gift reserve exceeded with provided amount.");    
    
    for(uint256 i; i < _amount; i++){    
      _safeMint( _to, supply + i );    
    }    
    _gifts -= _amount;    
  } 

  function mint(uint256 _amount) public payable {
    uint256 supply = totalSupply();

    require( _active, "Not active");
    require( _amount <= _MINT_LIMIT, "Amount denied");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= _SALE_SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }
  }

  function presale(bytes32[] calldata _merkleProof, uint256 _amount) public payable {
    uint256 supply = totalSupply();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require( _presaleActive, "Not active");
    require( _amount + _claimed[msg.sender] <= _presaleMintLimit, "Amount denied");
    require( MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "Invalid Address");
    require( msg.value >= _price * _amount, "Insufficient ether");
    require( supply + _amount <= _PRESALE_SUPPLY, "Supply denied");

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
      _claimed[msg.sender] += 1;
    }
  }

  function withdraw() public payable onlyOwner {
    uint256 _p1 = address(this).balance * 2 / 5;
    uint256 _p2 = address(this).balance * 2 / 10;
    uint256 _p3 = address(this).balance * 2 / 10;
    uint256 _p4 = address(this).balance * 2 / 10;

    require(payable(_v1).send(_p1));
    require(payable(_v2).send(_p2));
    require(payable(_v3).send(_p3));
    require(payable(_v4).send(_p4));
  }
}