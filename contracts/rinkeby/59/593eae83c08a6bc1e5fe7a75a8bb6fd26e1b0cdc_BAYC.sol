// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";


contract BAYC is Context, Ownable, ERC721, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public constant CAP = 10000;

    Counters.Counter private _currentId;

    event Mint(address indexed to, uint256 indexed mintIndex);


    constructor() ERC721("BAYC EXAMPLE", "BAYC") public {

    }

    function remaining() public view returns (uint256) {
        return CAP.sub(totalSupply());
    }

    // start from tokenId = 1
    function mint(uint256 amounts) public nonReentrant{
        require(totalSupply().add(amounts) <= CAP, "can not exceed max cap");

        for(uint256 i = 0; i < amounts; ++i) {
            _currentId.increment();
            uint256 mintIndex = _currentId.current();
            _safeMint(_msgSender(), mintIndex);

            emit Mint(_msgSender(), mintIndex);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

}