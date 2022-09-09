// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract imiltestTwo is Ownable, ERC721A, ReentrancyGuard {



  using Strings for uint256;



  string baseURI;

  mapping (uint => string) claimURI;

  string public baseExtension = ".json";



  uint256 public cost = 0.033 ether;

  uint256 public maxSupply = 69;

  uint256 public currentSet = 9;

  uint256 public AllowlistLimit = 5;



  bool public paused = false;



  mapping (uint =>  bool) public claimActiveByPhase;

  mapping (uint =>  mapping(uint => bool)) public claimedItemByPhase;

  mapping (uint256 =>  uint) public claimPhaseByToken;





  bool public onlyAllowlisted = false;

  mapping(address => bool) public allowlist;

  mapping(address => uint256) public addressMintedBalance;



  constructor(

    string memory _initBaseURI,

    string memory _initClaimURI

  ) ERC721A("imitest2", "IMI") {

    setBaseURI(_initBaseURI);

    setClaimURI(_initClaimURI,1);

  }



  // internal

  function _baseURI() internal view virtual override returns (string memory) {

    return baseURI;

  }



  function _claimURI(uint claim) internal view virtual returns (string memory) {

    return claimURI[claim];

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



    uint claimPhaseForToken = claimPhaseByToken[tokenId];



    if(claimPhaseForToken > 0){

        string memory currentClaimURI = _claimURI(claimPhaseForToken);

        return bytes(currentClaimURI).length > 0

        ? string(abi.encodePacked(currentClaimURI, tokenId.toString(), baseExtension))

        : "";

    }

    else{

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0

        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))

        : "";

    }

  }



  function toggleClaim(bool _state, uint claim) public onlyOwner {

    claimActiveByPhase[claim] = _state;

  }



  function claimItem(uint256 tokenId, uint claim) external {

    require(ownerOf(tokenId) == msg.sender, "sorry you are not the owner");

    require(claimActiveByPhase[claim], "claim is not active yet");

    require(!claimedItemByPhase[tokenId][claim], "already claimed!");

    claimedItemByPhase[tokenId][claim] = true;

    claimPhaseByToken[tokenId] = claim;

  }



  function checkClaimed(uint256 tokenId, uint claim) external view returns (bool) {

    return claimedItemByPhase[tokenId][claim];

  }



  function setBaseURI(string memory _newBaseURI) public onlyOwner {

    baseURI = _newBaseURI;

  }



   function setClaimURI(string memory _newClaimURI, uint claim) public onlyOwner {

    claimURI[claim] = _newClaimURI;

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