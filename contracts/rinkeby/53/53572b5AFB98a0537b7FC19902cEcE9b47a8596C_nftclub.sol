/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.9;

pragma solidity ^0.8.14;

contract nftclub {
    address private owner;
    uint256 public value;
    uint256 private ethers;

    enum status {
        sell,
        auction
    }

    struct NFT {
        address tokenId;
        address profile;
        string file_url;
        string redeemable;
        uint256 last_selling_price;
        status Status;
    }

    mapping(address => NFT) public TokenCollections;

    constructor() {
        owner = msg.sender;
    }

    function buy(
        address _token,
        address _profile,
        address _oldProfile,
        string calldata _file_url,
        string calldata _redeemable,
        status _status,
        uint256 price
    ) public payable returns (bool) {
        require(msg.value >= price, "Insufficient Balance");
        payable(_oldProfile).transfer(msg.value);
        TokenCollections[_token] = NFT(
            _token,
            _profile,
            _file_url,
            _redeemable,
            price,
            _status
        );

        return true;
    }

    function buyByAuction(
        address _token,
        address _profile,
        address _oldProfile,
        string calldata _file_url,
        string calldata _redeemable,
        status _status,
        uint256 price
    ) public payable returns (bool) {
        NFT memory Token = TokenCollections[_token];

        require(msg.value >= Token.last_selling_price, "Insufficient Balance");
        payable(_oldProfile).transfer(msg.value);
        TokenCollections[_token] = NFT(
            _token,
            _profile,
            _file_url,
            _redeemable,
            price,
            _status
        );
        return true;
    }

    function get(address _token) public view returns (NFT memory) {
        NFT memory Token = TokenCollections[_token];
        return Token;
    }

    function widthDraw() external payable {
        require(msg.sender == owner, "Sorry you're not owner");
        (bool sent, ) = owner.call{value: ethers}("");
        require(sent, "Failed to send Ether");
    }

    fallback() external payable {
        ethers += msg.value;
    }

    receive() external payable {
        ethers += msg.value;
    }
}