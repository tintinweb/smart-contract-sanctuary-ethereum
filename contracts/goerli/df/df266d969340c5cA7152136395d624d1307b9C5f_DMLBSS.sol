// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Ownable.sol";
import "ERC1155.sol";
import "Strings.sol";

contract DMLBSS is ERC1155, Ownable {
    uint256 public constant ONE = 0;
    uint256 public constant TWO = 1;
    uint256 public constant THREE = 2;
    
    constructor()
    ERC1155("https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/{id}.json") {
        _mint(msg.sender, ONE,10 **18, "");
        _mint(msg.sender, TWO,10 **38, "");
        _mint(msg.sender, THREE, 1, "");
    }

   

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

     function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }


 function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/", Strings.toString(_tokenid),".json"
            )
        );
    }
}