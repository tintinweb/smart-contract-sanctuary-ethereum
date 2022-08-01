// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";


contract SmileNow is Ownable, ERC721A, ReentrancyGuard {

  using Strings for uint256;

  string baseURI;
  string claimURI;
  string claimURI2;
  string claimURI3;
  string claimURI4;
  string claimURI5;
  string mapCoordinates;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.033 ether;
  uint256 public maxSupply = 50;
  uint256 public currentSet = 5;
  uint256 public AllowlistLimit = 3;

  bool public paused = false;
  bool public claimactive = false;
  bool public claimactive2 = false;
  bool public claimactive3 = false;
  bool public claimactive4 = false;
  bool public claimactive5 = false;
  bool public revealed = true;
  bool public onlyAllowlisted = false;
  mapping(address => bool) public allowlist;
  mapping(address => uint256) public addressMintedBalance;
  //mapping(address => bool) public claimedItem1;
  bool[] claimedItem1 = new bool[](maxSupply);
  bool[] claimedItem2 = new bool[](maxSupply);
  bool[] claimedItem3 = new bool[](maxSupply);
  bool[] claimedItem4 = new bool[](maxSupply);
  bool[] claimedItem5 = new bool[](maxSupply);

  constructor(
    string memory _initBaseURI,
    string memory _initClaimURI
  ) ERC721A("SmileNow", "SNW") {
    setBaseURI(_initBaseURI);
    setClaimURI(_initClaimURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _claimURI() internal view virtual returns (string memory) {
    return claimURI;
  }
  function _claimURI2() internal view virtual returns (string memory) {
    return claimURI2;
  }
  function _claimURI3() internal view virtual returns (string memory) {
    return claimURI3;
  }
  function _claimURI4() internal view virtual returns (string memory) {
    return claimURI4;
  }
  function _claimURI5() internal view virtual returns (string memory) {
    return claimURI5;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    // add balanceOf?
    require(!paused, "Calculating ERROR...... Result: WOAH hold up the mint is not yet live, a little too early there... or late? Transmission Ending....");
    require(_mintAmount > 0, "Calculating ERROR...... Result: must mint at least 1 nft, 0 is not allowed. Transmission Ending....");
    require(supply + _mintAmount <= currentSet, "Calculating ERROR...... Result: This set of shirts have been minted already, sorry....");
    require(supply + _mintAmount <= maxSupply, "Calculating ERROR...... Result: looks like we are popular max supply has been reached...  Transmission Ending....");
    

    if (msg.sender != owner()) {
        //max mint amount is 3
        require(_mintAmount <= 1, "Calculating ERROR...... Result: only 1 at a time :) Transmission Ending....");
        if(onlyAllowlisted == true) {
            require(isAllowlisted(msg.sender), "Calculating ERROR......  Transmission Ending....");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= AllowlistLimit, "Calculating ERROR...... Transmission Ending....");
        }
        require(msg.value >= cost * _mintAmount, "Calculating ERROR...... Result: Cost doesn't match.... Transmission Ending....");
    }

    _safeMint(msg.sender, _mintAmount);
    addressMintedBalance[msg.sender] += _mintAmount;
  }

  //write this. 
  function allowListMint()  public payable{

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

    if(claimedItem1[tokenId] == true){
        string memory currentClaimURI = _claimURI();
        return bytes(currentClaimURI).length > 0
        ? string(abi.encodePacked(currentClaimURI, tokenId.toString(), baseExtension))
        : "";
    }

    if(claimedItem2[tokenId] == true){
        string memory currentClaimURI = _claimURI2();
        return bytes(currentClaimURI).length > 0
        ? string(abi.encodePacked(currentClaimURI, tokenId.toString(), baseExtension))
        : "";
    }
    if(claimedItem3[tokenId] == true){
        string memory currentClaimURI = _claimURI3();
        return bytes(currentClaimURI).length > 0
        ? string(abi.encodePacked(currentClaimURI, tokenId.toString(), baseExtension))
        : "";
    }
    if(claimedItem4[tokenId] == true){
        string memory currentClaimURI = _claimURI4();
        return bytes(currentClaimURI).length > 0
        ? string(abi.encodePacked(currentClaimURI, tokenId.toString(), baseExtension))
        : "";
    }
    if(claimedItem5[tokenId] == true){
        string memory currentClaimURI = _claimURI5();
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

  function toggleclaimactive() public onlyOwner {
    claimactive = true;
  }
    function toggleclaimactive2() public onlyOwner {
    claimactive2 = true;
  }
    function toggleclaimactive3() public onlyOwner {
    claimactive3 = true;
  }
    function toggleclaimactive4() public onlyOwner {
    claimactive4 = true;
  }
    function toggleclaimactive5() public onlyOwner {
    claimactive5 = true;
  }

  function claimItem1(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender, "You dont own this token... sorry :)");
    require(!claimactive, "claim is not active");
    require(claimedItem1[tokenId] != true, "already claimed!");
    claimedItem1[tokenId] = true;
  }

  function checkClaimed(uint256 tokenId) external view returns (bool) {
    return claimedItem1[tokenId];
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
   function setClaimURI2(string memory _newClaimURI) public onlyOwner {
    claimURI2 = _newClaimURI;
  }
   function setClaimURI3(string memory _newClaimURI) public onlyOwner {
    claimURI3 = _newClaimURI;
  }
   function setClaimURI4(string memory _newClaimURI) public onlyOwner {
    claimURI4 = _newClaimURI;
  }
   function setClaimURI5(string memory _newClaimURI) public onlyOwner {
    claimURI5 = _newClaimURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setCurrentSetAmount(uint256 setTotal) external onlyOwner {
    currentSet = setTotal;
  }

  function pause(bool _state) external onlyOwner {
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

  function ownerOfTokenIds(address tokenOwner) external view returns (uint256[] memory) {
        uint256 supplyCurrent = totalSupply();
        uint256[] memory result = new uint256[](balanceOf(tokenOwner));
        uint256 counter = 0;
        for (uint256 i = 0; i < supplyCurrent; i++) {
            if (ownerOf(i) == tokenOwner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
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