/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

contract TestStruct {
    
    struct AuctionInfo {
        uint256 startTime;
        uint256 tokenId;
        address erc20;
        uint256 value;
        address winner;
        bool isClinch;
    }
    
    AuctionInfo[] public auctions;
    
    function add(uint256 count) public returns (uint256 length){
        
        for(uint256 i = 0; i < count; i++){
            auctions.push(AuctionInfo({
                startTime: block.timestamp,
                tokenId: i,
                erc20: msg.sender,
                winner: msg.sender,
                value: auctions.length,
                isClinch: false
            }));
        }
        return auctions.length;
    }
    
    function getLength() public view returns (uint256) {
        return auctions.length;
    }
    
    function getAll() public view returns (AuctionInfo[] memory) {
        return auctions;
    }
    
}