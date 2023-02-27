// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";

contract JoypolisOneDayPass is  ERC721Enumerable {

    address public owner;
    uint256 public nftid = 1;
    string currentURI = "https://arweave.net/kFI-HsOZFnfogNVVbJoc8xBvm4GMx5ifwrw1_pZe-sQ";


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

    function mint() public payable {
        require( msg.value == 0.02 ether);
        require( nftid < 500);
        payable(owner).transfer(msg.value);
        _safeMint( _msgSender() , nftid);
        nftid++;        
    }



    constructor() ERC721("Entrance Pass for Web3 Night in JOYPOLIS" , "CASJ" ) {
        owner = _msgSender();
    } 
}