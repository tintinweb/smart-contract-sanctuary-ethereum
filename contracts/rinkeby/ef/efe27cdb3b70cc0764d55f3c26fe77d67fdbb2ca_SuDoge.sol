// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SuDoge is ERC721A, Ownable {
    bool minted;
    string baseURI;

    // Rinkeby
    address sudoswapRouter = 0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5;
    address sudoswapFactory = 0xcB1514FE29db064fa595628E0BFFD10cdf998F33;

    //Mainnet
    //address sudoswapRouter = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    //address sudoswapFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;

    constructor() ERC721A("Tester", "TEST") {
        baseURI = "ipfs://none/";
        _mint(msg.sender, 1000);
        minted = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if(minted)
        {
            require(msg.sender == sudoswapRouter || msg.sender == sudoswapFactory, 'Can only be swapped via SudoSwap');
        }
    }
}