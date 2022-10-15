/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

contract ERC721 {
    mapping (uint => address) tokens;

    function mint(address tokenOwner, uint tokenId) public {
        tokens[tokenId] = tokenOwner;
    }

    function transferFrom(address from, address to, uint tokenId) public {
        require(tokens[tokenId] == from, "insufficient balance");

        tokens[tokenId] = to;
    }
}