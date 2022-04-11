/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 < 0.9.0;

interface IERC721
{
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

  function setApprovalForAll(address operator, bool _approved) external;
}


interface IERC20
{
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Market
{
    enum listingStatus
    {
        Active,
        Sold,
        Cancelled
    }

    struct Listing
    {
        listingStatus status;
        address seller;
        address token;
        uint tokenId;
        uint price;
    }

    uint private _listingId=0;
    mapping(uint => Listing) private _listings;

    function getListing(uint listingId) public view returns(Listing memory)
    {
        return _listings[listingId];
    }

    function listToken(address token, uint tokenId, uint price) external
    {
        // IERC721(token)._setApprovalForAll(address(this), true);
         IERC721(token).transferFrom(msg.sender, address(this), tokenId);

         Listing memory listing = Listing(listingStatus.Active, msg.sender, token, tokenId, price);

         _listingId++;

         _listings[_listingId]=listing;
    }

    function buyToken(uint listingId, address token) external 
    {
        Listing storage listing = _listings[listingId];

        require(msg.sender!=listing.seller, 'Buyer cannot be a Seller');
        require(listing.status==listingStatus.Active, 'Listing is not Active');
        require(token==0x4BCdAC5AB3CCFCAb7d573CB655B3833443bfB467);
        require(IERC20(token).balanceOf(msg.sender)>=listing.price, 'Insufficient Payment');

        IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);
        IERC20(token).transferFrom(msg.sender, listing.seller, listing.price);
    }

      function cancel(uint listingId) external
      {
         Listing storage listing = _listings[listingId];

         require(listing.seller==msg.sender, 'Only Seller can cancel Listing');
         require(listing.status==listingStatus.Active, 'Listing is not Active');

         listing.status=listingStatus.Cancelled;

         IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);

      }
}