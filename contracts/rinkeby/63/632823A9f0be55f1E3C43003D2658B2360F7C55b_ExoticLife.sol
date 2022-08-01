// SPDX-License-Identifier: MIT

// Into the Metaverse NFTs are governed by the following terms and conditions: https://a.did.as/into_the_metaverse_tc

pragma solidity ^0.8.9;

import "./counters.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./strings.sol";
import "./AbstractERC1155Factory.sol";


/*
* @title ERC1155 ExoticLife
* @author Exotic Technology
*/
contract ExoticLife is AbstractERC1155Factory {
      
    
    struct cover {
        uint id;
        uint maxToken;
        
    }

    cover[] covers;

    mapping(address => bool) private senders;

    event minted(uint256 indexed index, address indexed account, uint256 amount);

    constructor(
      
         
    ) ERC1155("ipfs://QmdG5EiyNmE5qQBDyNoFvSWKpawHNLY5rthAfBRRmaKhEL/") {
        name_ = "EXX";
        symbol_ = "EXX";

        senders[msg.sender] = true; // add owner
    }

    function addSender(address _address) public onlyOwner  {
        
        require(_address != address(0));
        senders[_address] = true;
       
    }
    
    function removeSender(address _address) public onlyOwner {
        require(_address != address(0));
        senders[_address] = false;
        
    }

    

   function addToken(uint _max)external  {

       require(senders[_msgSender()]);

       require(_max >0,"cannot be 0");

       uint x = covers.length;
       covers.push(cover(x,_max));

   }

   function updateTokenSupply(uint _id, uint _supply)external {
       require(senders[_msgSender()]);

       require(covers.length > 0,"no tokens");
       require(_id <= covers.length,"out of bounds");
       uint x = totalSupply(_id);
       require(_supply >= x,"already passed");

       covers[_id].maxToken = _supply;
       

   }

    function auctionMint(address _to, uint _id, uint _amount) external  {

        require(senders[_msgSender()]);
        
        require(covers.length > 0,"no tokens");
        require(_id <= covers.length,"out of bounds");
        uint ts = totalSupply(_id);
        require(ts + _amount <= covers[_id].maxToken,"max");

        _mint(_to, _id, _amount, "");


    }



    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");

            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
}