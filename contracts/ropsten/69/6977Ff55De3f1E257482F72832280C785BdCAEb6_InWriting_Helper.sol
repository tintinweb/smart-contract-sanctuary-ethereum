// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface InWriting {
    function mint_NFT(string memory str) external payable returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function get_minting_cost() external view returns (uint256);
    function buy(uint256 tokenId) external payable returns (bool);
    function mint_unlocked_NFT(string memory str) external payable returns (uint256);
    function get_price(uint256 tokenId) external view returns (uint256);
}

contract InWriting_Helper{
    address InWriting_address = 0x20111434640CDeD801f3C170FDe4a4934DEFb41a;
    InWriting write = InWriting(InWriting_address);

    constructor(){}

    function mint_and_send(string memory str, address addr) public payable returns (uint256) {
        uint256 tokenId = write.mint_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), addr, tokenId);
        return tokenId;
    }

    function mint_unlocked_and_send(string memory str, address addr) public payable returns (uint256) {
        uint256 tokenId = write.mint_unlocked_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), addr, tokenId);
        return tokenId;
    }

    function buy_and_send(uint256 tokenId, address addr) public payable returns (bool) {
        write.buy{value: write.get_price(tokenId)}(tokenId);
        write.transferFrom(address(this), addr, tokenId);
        return true;
    }

}