// SPDX-License-Identifier: MIT

/*
 ___  ___  ________  ________  ___       ___  ___  ________      
|\  \|\  \|\   __  \|\   ___ \|\  \     |\  \|\  \|\   __  \     
\ \  \\\  \ \  \|\  \ \  \_|\ \ \  \    \ \  \\\  \ \  \|\  \    
 \ \   __  \ \  \\\  \ \  \ \\ \ \  \    \ \   __  \ \  \\\  \   
  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \____\ \  \ \  \ \  \\\  \  
   \ \__\ \__\ \_______\ \_______\ \_______\ \__\ \__\ \_____  \ 
    \|__|\|__|\|_______|\|_______|\|_______|\|__|\|__|\|___| \__\
                                                            \|__|
*/

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract KingOfCoolXClones is ERC1155, Ownable {
    
  string public name;
  string public symbol;
  mapping(uint => string) public tokenURI;
  uint256 internal supply = 1;

  constructor() ERC1155("") {
    name = "King of Cool x Clones";
    symbol = "KOCXC";
    setURI(1, "ipfs://Qmc3eEbsBDsGtW7TcYpNgNLM3SvUSu6KiSUwxGny1ZCH68/1.json");
  }

  function freeMint(address _to) external {
    if(msg.sender != owner()) {
      require(msg.sender == _to, "KOCXC: Must mint to own wallet");
      require(balanceOf(_to, 1) < 1);
    }
    _mint(_to, 1, 1, "");
  }

  function honoraryMint(address _to, string memory _uri) public onlyOwner {
    _mint(_to, supply + 1, 1, "");
    setURI(supply + 1, _uri);
    supply++;
  }

  function setURI(uint _id, string memory _uri) public onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
}