// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC1155.sol";
import "./Ownable.sol";

contract MyToken is ERC1155, Ownable {
        uint256[] supplies =[50,100,150];
          uint256[] minted =[0,0,0];
            uint256[] rates =[0.05 ether,0.1 ether ,0.025 ether];
    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(uint256 id, uint256 amount)
        public
        payable
    {
       
       require(id <= supplies.length, "token not exits");
       require(id >0 ," token not exits");
       uint256 index = id-1;

       require(minted[index] + amount <= supplies[index]," not enough supply");
       require( msg.value >= amount * rates[index]," not enough ether sent");       
        _mint(msg.sender, id, amount, "");
        minted[index] += amount;
    }
    function withdraw()public onlyOwner
    {
         require(address(this).balance >0 ," zero balance");
         payable(owner()).transfer(address(this).balance);
    }

    
}