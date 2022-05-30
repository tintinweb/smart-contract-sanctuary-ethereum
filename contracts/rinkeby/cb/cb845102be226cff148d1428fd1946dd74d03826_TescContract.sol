// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TescContract is ERC721, Ownable {
    using SafeMath for uint256;

    string public baseURI;
    uint256 public currentSupply;

    constructor() ERC721("TestToken", "TT") {
        baseURI = "https://ipfs.io/ipfs/QmSdzLDB8wqMSqn76GYZ6DzduGB5PwSoC5YSBQZYqoNUeW/";
    }

    function mint(uint j) public onlyOwner {
        for(uint256 i; i < j; i++) {
            _safeMint(msg.sender, currentSupply + 1);
            currentSupply++;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setBaseURIBasic() external onlyOwner {
        baseURI = "https://ipfs.io/ipfs/QmSdzLDB8wqMSqn76GYZ6DzduGB5PwSoC5YSBQZYqoNUeW/";
    }
}