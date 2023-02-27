// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";

contract JoypolisOneYearPass is  ERC721Enumerable {

    address public owner;
    uint256 public nftid = 1;
    string currentURI = "https://arweave.net/e7wMIBwRr3yvZB0IjUoqJvqWorhXFiAlpm_3NDpsisQ";
    bool revealed = false;
    string [5] revealdURI = ["","","","",""];

    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == owner  );
        currentURI = _uri;
    }

    function setRevealdURI( string memory _uri , uint revealdArrayId) public {
        require( _msgSender() == owner  );
        revealdURI[revealdArrayId] = _uri;
    }

    function toggleRevealed( ) public {
        require( _msgSender() == owner  );
        revealed = !revealed;
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
        if (!revealed){
        return currentURI;
        } else {
        return revealdURI[tokenId % 5];
        }
    }

    function mint() public payable {
        require( msg.value == 0.2 ether);
        payable(owner).transfer(msg.value);
        _safeMint( _msgSender() , nftid);
        nftid++;        
    }



    constructor() ERC721("JOYPOLIS Yearly Pass NFT" , "CASJ" ) {
        owner = _msgSender();
    } 
}