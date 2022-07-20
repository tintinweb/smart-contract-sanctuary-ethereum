// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract SmileNow is Ownable, ERC721A, ReentrancyGuard {

  using Strings for uint256;

  string baseURI;
  string claimURI;
  string mapCoordinates;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.033 ether;
  uint256 public maxSupply = 50;
  uint256 public AllowlistLimit = 3;

  bool public paused = true;
  bool public claimactive = false;
  bool public revealed = false;
  bool public onlyAllowlisted = true;
  mapping(address => bool) public allowlist;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => bool) public claimedItem1;

  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    string memory _initClaimURI
  ) ERC721A("SmileNow", "SNW") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    setClaimURI(_initClaimURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _claimURI() internal view virtual returns (string memory) {
    return claimURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "Calculating ERROR...... Result: WOAH hold up the mint is not yet live, a little too early there or late? Transmission Ending....");
    require(_mintAmount > 0, "Calculating ERROR...... Result: must mint at least 1 mft, 0 is not allowed. Transmission Ending....");
    require(supply + _mintAmount <= maxSupply, "Calculating ERROR...... Result: looks like we are popular... please lower your mint amount to not exceed the max mint amount to proceed. Transmission Ending....");

    if (msg.sender != owner()) {
        //max mint amount is 3
        require(_mintAmount <= 3, "Calculating ERROR...... Result: only 3 at a time :) Transmission Ending....");
        if(onlyAllowlisted == true) {
            require(isAllowlisted(msg.sender), "Calculating ERROR...... Result: only 3 at a time :) Transmission Ending....");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= AllowlistLimit, "Calculating ERROR...... Result: only 3 at a time :) Transmission Ending....");
        }
        require(msg.value >= cost * _mintAmount, "Calculating ERROR...... Result: Cost doesn't match.... Transmission Ending....");
    }

    _safeMint(msg.sender, _mintAmount);
    addressMintedBalance[msg.sender] += _mintAmount;
  }

  function isAllowlisted(address _user) public view returns (bool) {
    return allowlist[_user];
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    if(claimedItem1[ownerOf(tokenId)] == true){
        string memory currentClaimURI = _claimURI();
        return bytes(currentClaimURI).length > 0
        ? string(abi.encodePacked(currentClaimURI, tokenId.toString(), baseExtension))
        : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function setclaimactive() public onlyOwner {
    claimactive = true;
  }

  function claimItem1(uint256 tokenId) public {
    require(!claimactive, "claim is not active");
    require(claimedItem1[msg.sender] != true);
    require(ownerOf(tokenId) == msg.sender);
    claimedItem1[msg.sender] = true;
  }

  function checkClaimed(uint256 tokenId) public view returns (bool) {
    return claimedItem1[ownerOf(tokenId)];
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

   function setClaimURI(string memory _newClaimURI) public onlyOwner {
    claimURI = _newClaimURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }


  function setOnlyAllowlisted(bool _state) public onlyOwner {
    onlyAllowlisted = _state;
  }

  function allowlistUsers(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = true;
    }
  }

  function removeUsersFromAllowlist(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = false;
    }
  }

  function setMapCoordinates(string memory newCoordinates) public onlyOwner{
    mapCoordinates = newCoordinates;
  }

  function getMapCoordinates()  public view returns(string memory){
    return mapCoordinates;
  }
 
  function withdraw() public payable onlyOwner {
    //uint256 balance = address(this).balance;
    //uint256 forward_funding = (balance)/ 3;
    //payable("").transfer(forward_funding);
    //uint256 dev_artist_pay = (balance)/ 5;
    //payable(artist).transfer(dev_artist_pay);
    //payable(dev).transfer(dev_artist_pay);
    payable(owner()).transfer(address(this).balance);
  }
}