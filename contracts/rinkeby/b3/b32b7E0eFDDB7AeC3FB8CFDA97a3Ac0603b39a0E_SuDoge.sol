// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./LSSVMPairCloner.sol";

contract SuDoge is ERC721A, Ownable {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    bool _sudoswapOnly;
    string baseURI;

    // Rinkeby
    address constant sudoswapRouter = 0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5;
    address constant sudoswapFactory = 0xcB1514FE29db064fa595628E0BFFD10cdf998F33;
    address constant missingEnumerableETHTemplate = 0x4c306E8Ee7dc4c5dd13A262F2665A35dd50D3635;
    address constant missingEnumerableERC20Template = 0xE5369d08D7156B0544C62c4d14f5Bb6d3cB1124b;

    //Mainnet
    //address sudoswapRouter = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    //address sudoswapFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;

    constructor() ERC721A("Tester", "TEST") {
        baseURI = "ipfs://none/";
        _mint(msg.sender, 1000);
        _sudoswapOnly = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function setSudoswapOnly(bool value) external onlyOwner() {
        _sudoswapOnly = value;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if(_sudoswapOnly)
        {
            if(_msgSenderERC721A() != sudoswapRouter && _msgSenderERC721A() != sudoswapFactory)
            {
                // Should be a Sudoswap Pair.
                require(
                    isPair(_msgSenderERC721A(), PairVariant.MISSING_ENUMERABLE_ERC20) || isPair(_msgSenderERC721A(), PairVariant.MISSING_ENUMERABLE_ETH),
                    'Can only be swapped via SudoSwap');
            }
        }
    }

    function isPair(address potentialPair, PairVariant variant)
        private
        view
        returns (bool)
    {
        if (variant == PairVariant.MISSING_ENUMERABLE_ERC20) {
            return
                LSSVMPairCloner.isERC20PairClone(
                    sudoswapFactory,
                    missingEnumerableERC20Template,
                    potentialPair
                );
        } else if (variant == PairVariant.MISSING_ENUMERABLE_ETH) {
            return
                LSSVMPairCloner.isETHPairClone(
                    sudoswapFactory,
                    missingEnumerableETHTemplate,
                    potentialPair
                );
        } else {
            // invalid input
            return false;
        }
    }

}