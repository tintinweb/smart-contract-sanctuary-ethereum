// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "./ERC721Metadata.sol";
import "./SafeMath.sol";

contract Road2Web3 is ERC721Metadata{

    uint public MAX_SUPPLY = 1000;

    using SafeMath for uint256;

    uint private index = 1;

    constructor(string memory _name, string memory _symbol) ERC721Metadata(_name, _symbol) {
        
    }

    //设置ipfs
     function _baseURI() internal pure override returns (string memory){
        return "ipfs://QmeDEvsWpBk429UJj9JTrgtHZpNJksvPVK4GfQv439UpXW/";
    }

    function mint() external{
        require(index <= MAX_SUPPLY, "All items have been minted");
        _mint(msg.sender, index);
    }
}