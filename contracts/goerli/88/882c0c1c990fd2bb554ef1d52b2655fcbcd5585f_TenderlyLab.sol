/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

pragma solidity 0.8.18;

contract TenderlyLab {

    mapping(address owner => uint256[] tokenIds) memberedToken;

    function add(uint256 tokenId) public {
        memberedToken[msg.sender].push(tokenId);
    }

    function addBatch(uint256[] memory tokenList) public {
        for (uint256 i = 0; i < tokenList.length; i++) 
        {
            memberedToken[msg.sender].push(tokenList[i]);
        }
    }

    function getFrom(uint256 from, uint256 count) public view returns(uint256[] memory) {
        require(memberedToken[msg.sender].length > 0, "Not exist");
        uint256 _count = memberedToken[msg.sender].length > count ? memberedToken[msg.sender].length : count;
        uint256[] memory ren = new uint256[](_count);
        uint256 to = from + count;

        for (uint256 i = from; i < to; i++) 
        {
            ren[i] = memberedToken[msg.sender][i];
        }

        return ren;
    }

    function getAll() public view returns(uint256[] memory) {
        require(memberedToken[msg.sender].length > 0, "Not exist");
        uint256[] memory ren = new uint256[](memberedToken[msg.sender].length );

        for (uint256 i = 0; i < memberedToken[msg.sender].length; i++) 
        {
            ren[i] = memberedToken[msg.sender][i];
        }

        return ren;
    }
}