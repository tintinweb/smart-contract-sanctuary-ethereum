// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "ERC721Enumerable.sol";
import "Ownable.sol";

contract DBAGNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  address[] private temp_address;
  uint256 private temp_tokenId;
  string public baseURI;
  bool public paused = false;
  address public DBAGAllAccessPassAddress = 0x0000000000000000000000000000000000000000;
  // uint256[] public availablePass;

  constructor(string memory _name, string memory _symbol, string memory _ipfsURI) 
  ERC721(_name, _symbol) {
    setBaseURI(_ipfsURI);
  }


  // function populateAvailablePass() public onlyOwner{
  //   uint256 currentArrySize = availablePass.length;
  //   for(uint256 i = 0; i < 1000; i++) {
  //     availablePass.push(currentArrySize + i + 1);
  //   }
  // }

  // function showAvailablePass() public view returns (uint256[] memory) {
  //   uint256[] memory tokenIds = new uint256[](availablePass.length);
  //   for (uint256 i; i < availablePass.length; i++) {
  //     tokenIds[i] = availablePass[i];
  //   }
  //   return tokenIds;
  // }

//=================================INTERNAL FUNCTIONS================================//
  function _baseURI() internal view virtual override returns (string memory) {return baseURI;}

//=================================TEST FUNCTIONS================================//
  // function Kek() public pure returns (string memory) {
  //   return Strings.toHexString(uint256(keccak256("1")), 32);
  // }

  //   function redeemNFT2() public{
  //     _safeMint(msg.sender, 1);
  // }

//=================================PUBLIC FUNCTIONS================================//
    function redeemNFT(address[] calldata _address, uint256 _tokenId) public{
      require(!paused, "The contract is paused");
      require(_tokenId > 0 && _tokenId <= 20000, "Invalid tokenId");
      require(msg.sender == DBAGAllAccessPassAddress, "Cannot access this function from this address");
      temp_address = _address;
      temp_tokenId = _tokenId;
      // TO_DO = RAMDOM 
      _safeMint(temp_address[0], temp_tokenId);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {tokenIds[i] = tokenOfOwnerByIndex(_owner, i);}
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    string memory tokenHash = Strings.toHexString(uint256(keccak256(bytes(tokenId.toString()))), 32);
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenHash, ".json")) : "";
    //return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

//=================================ONLY OWNER FUNCTIONS================================//
  function setBaseURI(string memory _newBaseURI) public onlyOwner {baseURI = _newBaseURI;}
  function pause(bool _state) public onlyOwner {paused = _state;}
  function setDBAGAllAccessPassAddress(address _DBAGAllAccessPassAddress) public onlyOwner {DBAGAllAccessPassAddress = _DBAGAllAccessPassAddress;}
}