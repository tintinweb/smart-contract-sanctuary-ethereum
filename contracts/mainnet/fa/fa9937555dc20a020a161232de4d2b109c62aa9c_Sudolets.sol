// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Sudolets is ERC721A, Ownable {
    bool minted;
    string baseURI;

    constructor() ERC721A("Sudolets", "LETS") {
        baseURI = "ipfs://bafybeie7bv4teyp4zmfbgpehd2cjx7lnc6gndo3bcr52xthlpbdnxdjx7u/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function mint() external payable {
        require(!minted, "Mint already completed");
        _mint(msg.sender, 1000);
        minted = true;
    }
}