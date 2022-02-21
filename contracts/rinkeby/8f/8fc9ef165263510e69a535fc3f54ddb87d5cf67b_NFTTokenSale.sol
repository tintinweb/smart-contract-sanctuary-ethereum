// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZepplin.sol";

contract NFTTokenSale {
    address payable admin;
    IERC721 public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _tokenID);
    
    constructor (IERC721 _tokenContract, uint256 _tokenPrice ) {
        admin = payable(msg.sender);
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;        
    }

    function multiply(uint x, uint y) internal pure returns (uint z){
        require(y==0 || (z = x * y) / y == x);        
    }
    
    function buyNft(uint256 _tokenID) public payable {
        // Check this NFT is Owned by this contract, or is approved
        address _tokenOwner = tokenContract.ownerOf(_tokenID);
        require(_tokenOwner == address(this) || tokenContract.isApprovedForAll(_tokenOwner, address(this)));
                      
        // Check for Payment
        require(msg.value == tokenPrice);
                
        tokenContract.safeTransferFrom(_tokenOwner,msg.sender,_tokenID);
        
        tokensSold += 1;
        emit Sell(msg.sender, _tokenID);
    }

    function endSale() public {
        require(msg.sender == admin);

       // require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));      
        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        admin.transfer(address(this).balance);
    }

}