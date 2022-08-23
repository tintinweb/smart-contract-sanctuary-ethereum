// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";


contract imiltest4 is Ownable, ERC721A, ReentrancyGuard {

  using Strings for uint256;

  string baseURI;
  string claimURI;
  string claimURI2;
  string claimURI3;
  string claimURI4;
  string claimURI5;
  string public baseExtension = ".json";

  uint256 public cost = 0.033 ether;
  uint256 public maxSupply = 70;
  uint256 public currentSet = 9;
  uint256 public AllowlistLimit = 5;

  bool public paused = false;
  bool public claimactive = false;
  bool public claimactive2 = false;
  bool public claimactive3 = false;
  bool public claimactive4 = false;
  bool public claimactive5 = false;
  bool public onlyAllowlisted = false;
  mapping(address => bool) public allowlist;
  mapping(address => uint256) public addressMintedBalance;

  bool[] claimedItem1 = new bool[](maxSupply);
  bool[] claimedItem2 = new bool[](maxSupply);
  bool[] claimedItem3 = new bool[](maxSupply);
  bool[] claimedItem4 = new bool[](maxSupply);
  bool[] claimedItem5 = new bool[](maxSupply);

  constructor(
    string memory _initBaseURI,
    string memory _initClaimURI
  ) ERC721A("imitest", "IMI") {
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
    require(!paused, "WOAH hold up the mint is not yet live, a little too early there... or late? Transmission Ending");
    require(_mintAmount > 0, "must mint at least 1 nft, 0 is not allowed. Transmission Ending");
    require(supply + _mintAmount <= currentSet, "This set of shirts have been minted already, sorry.");
    require(supply + _mintAmount <= maxSupply, "looks like we are popular max supply has been reached");
    

    if (msg.sender != owner()) {
        //max mint amount is 3
        require(_mintAmount <= 1, "only 1 at a time :) ");
        if(onlyAllowlisted == true) {
            require(isAllowlisted(msg.sender), "Not Allowlisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= AllowlistLimit, "Already minted");
        }
        require(msg.value >= cost * _mintAmount, "Cost doesn't match");
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

  function toggleclaimactive(bool _state) public onlyOwner {
    claimactive = _state;
  }
    function toggleclaimactive2(bool _state) public onlyOwner {
    claimactive2 = _state;
  }
    function toggleclaimactive3(bool _state) public onlyOwner {
    claimactive3 = _state;
  }
    function toggleclaimactive4(bool _state) public onlyOwner {
    claimactive4 = _state;
  }
    function toggleclaimactive5(bool _state) public onlyOwner {
    claimactive5 = _state;
  }

  function claimItem1(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender, "sorry you are not the owner");
    require(!claimactive, "claim is not active yet");
    require(claimedItem1[tokenId] != true, "already claimed!");
    claimedItem1[tokenId] = true;
  }

  function claimItem2(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender);
    require(!claimactive);
    require(claimedItem2[tokenId] != true, "already claimed!");
    claimedItem2[tokenId] = true;
  }

  function claimItem3(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender);
    require(!claimactive);
    require(claimedItem3[tokenId] != true, "already claimed!");
    claimedItem3[tokenId] = true;
  }

  function claimItem4(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender);
    require(!claimactive);
    require(claimedItem4[tokenId] != true, "already claimed!");
    claimedItem4[tokenId] = true;
  }

  function claimItem5(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender);
    require(!claimactive);
    require(claimedItem5[tokenId] != true, "already claimed!");
    claimedItem5[tokenId] = true;
  }




  function checkClaimed(uint256 tokenId) external view returns (bool) {
    return claimedItem1[tokenId];
  }

    function checkClaimed2(uint256 tokenId) external view returns (bool) {
    return claimedItem2[tokenId];
  }
    function checkClaimed3(uint256 tokenId) external view returns (bool) {
    return claimedItem3[tokenId];
  }
    function checkClaimed4(uint256 tokenId) external view returns (bool) {
    return claimedItem4[tokenId];
  }
    function checkClaimed5(uint256 tokenId) external view returns (bool) {
    return claimedItem5[tokenId];
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
    payable(owner()).transfer(address(this).balance);
  }


}