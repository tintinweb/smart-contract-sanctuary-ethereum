// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";

contract MyToken is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    IERC20 private grom;

    constructor(IERC20 gromContract) ERC721("MyToken", "MTK") {
        grom = gromContract;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function multipleMint(uint256 _numOfTokens) external onlyOwner {
        for (uint256 i = 0; i < _numOfTokens; i++) {
            safeMint(msg.sender);
        }
    }

    function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        super._transfer(from, to, tokenId);
    }

    /**
    * @notice Allow contract owner to withdraw GR to its own account.
    */
    function withdrawGr() external onlyOwner {
        uint256 balance = grom.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        grom.transfer(owner(), balance);
    }
}