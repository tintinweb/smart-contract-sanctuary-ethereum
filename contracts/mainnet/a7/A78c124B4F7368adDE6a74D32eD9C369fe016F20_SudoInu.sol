// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract SudoInu is ERC721A {
    bool minted;

    constructor() ERC721A("Sudo Inu", "XMINU") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmUL5WAgCYMZZ714mi6LayiWiEA8dCAWD5o4Sm2gpJx6cj";
    }

    function mint() external payable {
        require(!minted, "Mint already completed");

        _mint(msg.sender, 1000);
        minted = true;
    }
}