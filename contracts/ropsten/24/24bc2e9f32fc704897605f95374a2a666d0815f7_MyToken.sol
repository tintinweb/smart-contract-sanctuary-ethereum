// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC1155.sol";
import "./Ownable.sol";

contract MyToken is ERC1155, Ownable {
     uint256[] supplies = [50,100,50];
    uint256[] minted =  [0,0,0];
    uint256[] rates = [0.05 ether, 0.01 ether,  0.025 ether];
    mapping(address => uint256) private _balances;
    constructor() ERC1155("") {}
   
    function setURI( string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
function mint(uint256 id,uint256 amount)
        public
        payable
    {

        require(id <= supplies.length, "Token doesn't exist");
        require(id !=0, "Token Doen't exist");
        uint256 index = id - 1;
        require(minted[index] + amount <=supplies[index],"Not enough supply");
        require(msg.value >= amount* rates[index],"Not enough ether sent");
      _mint(msg.sender, id, amount,"");
      minted[index] +=amount;
               _balances[msg.sender] = amount;
    }
 function withdraw() public onlyOwner{
     require(address(this).balance > 0 ,"Balance is Zero");
     payable(owner()).transfer(address(this).balance);
 }
}