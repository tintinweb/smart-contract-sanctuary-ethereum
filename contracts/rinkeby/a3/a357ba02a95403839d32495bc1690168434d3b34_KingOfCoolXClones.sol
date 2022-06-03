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
  string public tokenURI;

  constructor() ERC1155("") {
    name = "King of Cool x Clones";
    symbol = "KOCXC";
    tokenURI = "ipfs://Qmc3eEbsBDsGtW7TcYpNgNLM3SvUSu6KiSUwxGny1ZCH68/1.json";
  }

  function mint(address _to) external {
    require(msg.sender == _to, "KOCXC: Must mint to own wallet");
    require(balanceOf(_to, 1) == 0);
    _mint(_to, 1, 1, "");
  }

  function uri(uint _id) public override view returns (string memory) {
    require(_id == 1, "KOCXC: Only ID 1 accepted");
    return tokenURI;
  }

}