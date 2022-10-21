// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";


contract Wangen_collection is Ownable, ERC1155Supply {
    using Strings for uint256;



    string public name = "Test ";
    string public symbol = "TT";
    
    


    constructor()
    ERC1155("ipfs://QmSz6SriDmqUTN53h93ivuLAKCibPXbYEnVNq9yfdj22h3/")
        {
           
        }
 
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }

    function mint(uint256 bronzeCount, uint256 silverCount, uint256 goldCount, uint256 platiniumCount, uint256 blackCount) external payable {        
        if(bronzeCount>0){
            _mint(msg.sender, 1, bronzeCount, "");
        }
        if(silverCount>0){
            _mint(msg.sender, 2, silverCount, "");
        }
        if(silverCount>0){
            _mint(msg.sender, 3, goldCount, "");
        }
        if(silverCount>0){
            _mint(msg.sender, 4, platiniumCount, "");
        }
        if(silverCount>0){
            _mint(msg.sender, 5, blackCount, "");
        }
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require( _msgSender() == owner(), "caller is not approved");
        _burn(account, id, value);
    }


}