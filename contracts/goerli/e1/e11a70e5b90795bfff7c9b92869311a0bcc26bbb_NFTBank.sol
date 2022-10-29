/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: nft_bank.sol


// Copyright (c) 2022 Keisuke OHNO

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;


//on chain metadata interface
interface iNFTCollection {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function safeTransferFrom(address from,address to,uint256 tokenId) external payable;
}

contract NFTBank is ERC721Holder{

    mapping(address => mapping(uint256 => address)) addressMapping;
    mapping(address => mapping(uint256 => bool)) isDeposit;

    constructor(){
    }

    function deposit(address _contractAddress , uint256 _tokenId )public{
        iNFTCollection NFTCollection;
        NFTCollection = iNFTCollection(_contractAddress);
        require( NFTCollection.ownerOf(_tokenId) == msg.sender , "You are not the owner of NFT.");
        NFTCollection.safeTransferFrom(msg.sender, address(this) , _tokenId);
        addressMapping[_contractAddress][_tokenId] = msg.sender;
        isDeposit[_contractAddress][_tokenId] = true;    
    }

    function thisaddress()public view returns(address){
        return address(this);
    }

    function withdraw(address _contractAddress , uint256 _tokenId )public{
        require( addressMapping[_contractAddress][_tokenId] == msg.sender , "You are not the owner of NFT." );
        require( isDeposit[_contractAddress][_tokenId] == true , "You are not the owner of NFT." );
        iNFTCollection NFTCollection;
        NFTCollection = iNFTCollection(_contractAddress);
        NFTCollection.safeTransferFrom( address(this) , msg.sender, _tokenId);
        isDeposit[_contractAddress][_tokenId] = false;        
    }

    function ownerOfNFT( address _contractAddress , uint256 _tokenId ) public view returns (address) {
        require( isDeposit[_contractAddress][_tokenId] == true , "You are not the owner of NFT." );
        return addressMapping[_contractAddress][_tokenId];
    }


}