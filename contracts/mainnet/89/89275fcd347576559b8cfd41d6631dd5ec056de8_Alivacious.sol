// SPDX-License-Identifier: MIT
// Contract written by bcBread.
// !vibe
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "Counters.sol";
contract Alivacious is ERC721, Ownable{
  using Strings for uint;
  using Counters for Counters.Counter;

  Counters.Counter public _supply;
  string public constant NR = "ipfs://QmajiMumwDCrxBLbHfFuTt2tY5Tv7qzt3r1uRfQbyJAyok/rose.json";
  string baseURI = "ipfs://QmfWCLGA46opuCsuA8NTEMMNw2bTDfe8qWyybPofewMbE1/";//initialize "hidden" URI here
  string constant baseExtension = ".json";
  uint public cost = 25000000000000000;
  uint public constant maxSupply = 5000;
  uint private  maxMint= 11;
  uint private maxPerWallet = 11;//
  bool public paused = true;
  bool public presaleOnly = true;
  bool public revealed = false;
  mapping(address => bool) whitelistedAddresses;
  
  constructor () ERC721("Alivacious", "RUDY")payable{}
  

  // public
  function presaleMint(uint qty) external payable {
        
        uint _maxPerWallet = maxPerWallet;
        require(whitelistedAddresses[msg.sender], "WL Only");
        require(balanceOf(msg.sender) + qty < _maxPerWallet, "Wallet Max");//balance in wallet + amount minting
        require(msg.value >= 25000000000000000 * qty, "Amount of Ether sent too small");
        require(qty < maxMint, "Greedy"); //Less than 10.
        require((_supply.current() + qty) < 5001, "SoldOut");
        
        for (uint i = 0; i < qty; i++) {
      _supply.increment();
      _mint(msg.sender, _supply.current());
    }
        
    (bool success, ) = payable(0x07709a9E3B157FA33f51Ad627Fa6931c87f9F575).call{value: msg.value * 25 / 100}("");
        require(success);
   
    }


  function mint(uint qty) external payable {
        uint _cost = cost;
        uint _maxPerWallet = maxPerWallet;
        require(presaleOnly == false);
        require(balanceOf(msg.sender) + qty < _maxPerWallet, "Wallet Max");//balance in wallet + amount minting
        require(msg.value >= _cost * qty, "Amount of Ether sent too small");
        require(qty < 11, "Greedy");//Less than 10.
        require((_supply.current() + qty) < 5001, "SoldOut");
        
        for (uint i = 0; i < qty; i++) 
    {
      _supply.increment();
      _mint(msg.sender, _supply.current());
    }
        
    (bool success, ) = payable(0x07709a9E3B157FA33f51Ad627Fa6931c87f9F575).call{value: msg.value * 25 / 100}("");
        require(success);
   
    }

    function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory) 
  {
     if(revealed == false) {
        return NR;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }
  
    


    // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //only owner
  function addUser(address  _addressToWhitelist) public onlyOwner {
    whitelistedAddresses[_addressToWhitelist] = true;
}

  function batchAddUsers(address[] memory _users) external onlyOwner{
      uint size = _users.length;
      for(uint i=0; i < size; i++){
          address user = _users[i];
          whitelistedAddresses[user] = true;
      }
  } 

  function setCost(uint _newCost) external onlyOwner {
    cost = _newCost;//change price must be in gwei
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;//unhide by entering NEW baseURI
  }

  function pause(bool _state) external onlyOwner {
    paused = _state;//set to false to "unpause"
  }

  function setPresaleOnly(bool _state) external onlyOwner {
    presaleOnly = _state;//set to false for main mint
  }

  function setMax(uint _newMax) external onlyOwner {
    maxPerWallet = _newMax;//increase amount per wallet after launch
  }

  function setMaxMint(uint _newMaxMint) external onlyOwner {
    maxMint = _newMaxMint;//increase amount per wallet after launch
  }

  function reveal(bool _state) external onlyOwner {
    revealed = _state;//increase amount per wallet after launch
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}