// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract WiseOldGAN is ERC721A, Ownable {
    bool minted;
    string baseURI;

    constructor() ERC721A("Wise Old GAN", "WOG") {
        baseURI = "ipfs://Qmda1JrwdV4Vvef9GBSHbfkjPZPNFZBs57gcfVLLChFtR2/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function mint() external payable {
        require(!minted, "Mint already completed");
        _mint(msg.sender, 500);
        minted = true;
    }
}