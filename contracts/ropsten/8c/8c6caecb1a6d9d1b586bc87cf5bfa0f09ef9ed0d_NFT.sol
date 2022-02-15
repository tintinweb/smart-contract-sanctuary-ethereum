//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// we will bring in the  openzeppelin ERC721 NFt functionality

import './ERC721.sol';
import './ERC721URIStorage.sol';
import './Counters.sol';



contract NFT is  ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    // counters allow us to keep track of tokenids

    // address of marketplace for nfts to interact

    address contractAddress;
    //address payable owner;

  
  
 
     

    // OBJ: give the nft market the ability to transact with token or change ownership
    // srtApprovalForAll allows us to do that with  contract address

    //construct set up our address
    constructor(address markplaceAddress) ERC721('ezdraa','EZD'){
            contractAddress = markplaceAddress;
             //owner = payable(msg.sender);        
    }



    function mintToken(string memory tokenURI, uint256  price, uint256 _Adminfee) public payable returns(uint256, uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        // set the token uri: id and url
        _setTokenURI(newItemId, tokenURI);

        // give the marketplace the approval to transact between users
        setApprovalForAll(contractAddress, true);

       //owner address for minting royalty
       
       _Adminfee = price * _Adminfee/100;
        payable(0x2AA5322e399E049900B7C80dA5fCfE7efDB6d42b).transfer(_Adminfee);
       

        //mint the token and set it  for sale - return the id to do so
        return (newItemId, _Adminfee);
        
    }

    
}