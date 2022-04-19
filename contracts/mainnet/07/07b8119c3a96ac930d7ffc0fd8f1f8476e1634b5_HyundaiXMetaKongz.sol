// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract HyundaiXMetaKongz is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 internal maxToken = 30;
    uint256 internal currentSupply;
    string internal baseURI;
    bool internal freeze;

    constructor(string memory baseURI_) ERC721("Hyundai X Meta Kongz", "HXMK") {
        baseURI = baseURI_;

        for (uint i=0; i < maxToken; i++) {
            _safeMint(msg.sender, currentSupply + 1);
            currentSupply++;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _freeze() internal view virtual override returns (bool) {
        return freeze;
    }

    function setFreeze() external onlyOwner {
        freeze = true;
    }


}