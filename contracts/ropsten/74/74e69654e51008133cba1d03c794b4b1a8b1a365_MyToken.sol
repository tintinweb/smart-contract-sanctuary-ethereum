// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC1155.sol";
import "./Ownable.sol";

contract MyToken is ERC1155, Ownable {
    uint256[] supplies =[50,100,150];
    uint256[] minted =[0,0,0];
    uint256[] rates =[0.05 ether,0.01 ether,0.025 ether];

    constructor() ERC1155("") {}

    function setURI(string memory newurl) public onlyOwner{
        _setURI(newurl);
    }
    function mint( uint256 id, uint256 amount) 
        public
        payable 
    {
        require(id <= supplies.length, "token dosen't exist");
        require(id !=0, "token dosen't exist");
        uint256 index =id - 1;
        require(minted[index]+amount <= supplies[index], "Not enough supply");
        require(msg.value >= amount * rates[index], "Not enough ethers sent");
        _mint(msg.sender, id, amount,"");
        minted[index] +=amount;
    }
    function widthdraw() public onlyOwner{
       require(address(this).balance > 0 ,"Balance is zero");
       payable(owner()).transfer(address(this).balance);   
    }
   
}