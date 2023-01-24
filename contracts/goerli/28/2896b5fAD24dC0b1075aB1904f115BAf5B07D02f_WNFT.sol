// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IWNFT.sol";
import "./ERC20.sol";
import "./IERC721.sol";

import "./IERC721Receiver.sol";

contract WNFT is IWNFT, ERC20, IERC721Receiver {
    bytes4 private constant _SELECTOR =
        bytes4(keccak256("onERC721Received(address,uint256,bytes)"));

    address public nonFungibleToken;

    mapping(uint256 => uint256) public tokenRates;

    constructor(
        address nonFungibleToken_,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        nonFungibleToken = nonFungibleToken_;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function deposit(uint256[] calldata tokensId, address contributor)
        public
        returns (uint256 minted)
    {
        for (uint256 i = 0; i < tokensId.length; i++) {
            minted += _deposit(tokensId[i]);
        }
        _mint(contributor, minted);
    }

    function _deposit(uint256 tokenId) internal returns (uint256 rate) {
        require(
            IERC721(nonFungibleToken).ownerOf(tokenId) == address(this),
            "No input NFT"
        );
        require(tokenRates[tokenId] == 0, "The NFT has already been paid");
        rate = 1;
        tokenRates[tokenId] = rate;
    }

    function windrawal(uint256[] calldata tokensId, address contributor)
        public
        returns (uint256 burned)
    {
        for (uint256 i = 0; i < tokensId.length; i++) {
            burned += _windrawal(tokensId[i], contributor);
        }
        _burn(address(this), burned);
    }

    function getAmountToWindrawal(uint256[] calldata tokensId)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < tokensId.length; i++) {
            amount += tokenRates[tokensId[i]];
        }
    }

    function _windrawal(uint256 tokenId, address contributor)
        internal
        returns (uint256 rate)
    {
        require(tokenRates[tokenId] != 0, "This NFT is not in the vault");
        rate = tokenRates[tokenId];
        tokenRates[tokenId] = 0;
        IERC721(nonFungibleToken).transferFrom(
            address(this),
            contributor,
            tokenId
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        _mint(operator, _deposit(tokenId));
        return _SELECTOR;
    }
}