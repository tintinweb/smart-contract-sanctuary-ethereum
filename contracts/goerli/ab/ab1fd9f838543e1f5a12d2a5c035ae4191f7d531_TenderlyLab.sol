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
        require(memberedToken[msg.sender].length > 0, "Not owned tokens");
        uint256 to = from + count;
        uint256 renCount = to > memberedToken[msg.sender].length ? memberedToken[msg.sender].length - from : count;
        uint256[] memory ren = new uint256[](renCount);
        
        for (uint256 i = 0; i < ren.length; i++) 
        {
            ren[i] = memberedToken[msg.sender][from+i];
        }

        return ren;
    }

    function getAll() public view returns(uint256[] memory) {
        require(memberedToken[msg.sender].length > 0, "Not owned tokens");
        uint256[] memory ren = new uint256[](memberedToken[msg.sender].length );

        for (uint256 i = 0; i < memberedToken[msg.sender].length; i++) 
        {
            ren[i] = memberedToken[msg.sender][i];
        }

        return ren;
    }
}