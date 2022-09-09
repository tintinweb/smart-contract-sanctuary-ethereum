// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";

contract HoneyPassGenesis is  ERC721Enumerable {

    address public owner;
    uint256 public nftid = 1;
    string currentURI = "https://arweave.net/TudOWhy7IN0JlxNy8ZQ0D80v-MZDrZfNoHv_S66GJeE";


    function mint33() public {
        require( _msgSender() == owner );
        for(uint i = 1; i <= 33; i++){
        _safeMint( owner , nftid);
        nftid++;
        }
    }

    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == owner  );
        currentURI = _uri;
    }

    function burn(uint256 _id) public {
        require( _msgSender() == ownerOf(_id));
        _burn(_id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        tokenId;
        return currentURI;
    }

    constructor() ERC721("Honey Pass Genesis" , "HPG" ) {
        owner = _msgSender();
        _safeMint( owner , nftid);
        nftid++;
    } 
}