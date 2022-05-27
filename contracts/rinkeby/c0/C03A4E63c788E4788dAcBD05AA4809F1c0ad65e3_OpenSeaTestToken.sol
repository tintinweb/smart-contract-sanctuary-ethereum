// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract OpenSeaTestToken  {

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

    constructor() {
        _name = "OS Test";
        _symbol = "OST";
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 _tokenId) public pure returns (string memory) {
        return string(abi.encodePacked("https://test/", _tokenId ));
    }

    // function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    //     address owner = _owners[tokenId];
    //     require(owner != address(0), "ERC721: owner query for nonexistent token");
    //     return owner;
    // }

}