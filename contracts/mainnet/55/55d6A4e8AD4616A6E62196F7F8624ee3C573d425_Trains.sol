/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

pragma solidity ^0.8.0;

interface nftToken {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Trains {
    uint256[] private personHistory;
    address market;
    address _owner;
    constructor () {
        _owner = msg.sender;
    }


    function doTransfer(address from, address to, uint256 tokenId) public {
        require(msg.sender ==market,"not allowed");
        nftToken nftT = nftToken(market);
        nftT.transferFrom(from, to, tokenId);
    }

    function setMarket(address addr) public {
        require(msg.sender == _owner,"not owner");
        market = addr;
    }

}