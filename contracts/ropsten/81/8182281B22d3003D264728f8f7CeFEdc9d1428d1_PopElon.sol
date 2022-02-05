// SDPX-License-Identifier: MIT

/**


// SPDX-License-Identifier: GPL-3.0


/*

 

 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .-----------------.
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |   ______     | || |     ____     | || |   ______     | || |  _________   | || |   _____      | || |     ____     | || | ____  _____  | |
| |  |_   __ \   | || |   .'    `.   | || |  |_   __ \   | || | |_   ___  |  | || |  |_   _|     | || |   .'    `.   | || ||_   \|_   _| | |
| |    | |__) |  | || |  /  .--.  \  | || |    | |__) |  | || |   | |_  \_|  | || |    | |       | || |  /  .--.  \  | || |  |   \ | |   | |
| |    |  ___/   | || |  | |    | |  | || |    |  ___/   | || |   |  _|  _   | || |    | |   _   | || |  | |    | |  | || |  | |\ \| |   | |
| |   _| |_      | || |  \  `--'  /  | || |   _| |_      | || |  _| |___/ |  | || |   _| |__/ |  | || |  \  `--'  /  | || | _| |_\   |_  | |
| |  |_____|     | || |   `.____.'   | || |  |_____|     | || | |_________|  | || |  |________|  | || |   `.____.'   | || ||_____|\____| | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

PopElon
WWW..POPELON.COM
www.discord.gg/popelon
www.twitter.com/popelon


*/










// File: contracts/BabyX.sol


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";

import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */


contract PopElon is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 1000;
//   uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 1;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  mapping(address => bool) public whitelistedAddresses;
  mapping (address => bool) public freeDone;
  
  mapping(address => uint256) public addressMintedBalance;
  mapping (uint256 => string) private _tokenURISuffixes;

  address public popelon_0x_address = 0x91fe3594920F0a00F880791Db8fDAA95e2E060a3;
  IERC20 public token;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {
    
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function msgsender() public view returns (address) {
      return msg.sender;
  }

  function getBalanceOfPopelon() public view returns (uint256) {
    // address test = msg.sender; // use this if you want to get the sender
    // address test = 0xe780e329d218a1f849f1cab777217a2cfbb410f2; // hardcode the sender
    return IERC20(popelon_0x_address).balanceOf(msg.sender);
    // return uint256(1);
  }
  // public
  function mint(string memory _hashUrl, bool forFree) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    // require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply++ <= maxSupply, "max NFT limit exceeded");
    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            // require(isWhitelisted(msg.sender), "user is not whitelisted");
            if(isWhitelisted(msg.sender) && forFree && !freeDone[msg.sender]) {
                cost = 0 ether;
                freeDone[msg.sender] = true;
            } else {
                if(getBalanceOfPopelon()>=1000000) {
                    cost = 0.05 ether;
                } else {
                    cost = 0.1 ether;
                }
            }
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost , "insufficient funds");
    }
    uint256 newTokenId = totalSupply();
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, newTokenId);
      _setTokenURISuffix(newTokenId, _hashUrl);
  }
  
  function _setTokenURISuffix(uint256 tokenId, string memory _tokenURISuffix) internal virtual {
    require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    _tokenURISuffixes[tokenId] = _tokenURISuffix;
  }


  function isWhitelisted(address _user) public view returns (bool) {
    return  whitelistedAddresses[_user];
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

//   function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
//     maxMintAmount = _newmaxMintAmount;
//   }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    for(uint i=0;i<_users.length;i++){
        whitelistedAddresses[_users[i]]=true;
    }
  }
 function whitelistUser(address _user) public onlyOwner {
        whitelistedAddresses[_user]=true;    
  }
  function withdraw() public payable onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);

  }
}