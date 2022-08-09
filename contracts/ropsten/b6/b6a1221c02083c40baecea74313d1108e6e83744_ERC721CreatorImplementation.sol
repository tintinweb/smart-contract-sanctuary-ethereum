// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC721CreatorImplementation {

    string private _baseUri = "";
    bool public isBase;
    address public owner;
    /**
     * Initializer
     */
    function initialize(address _owner) external {
        require(isBase == false, "ERROR: cannot initialize");
        require(owner == address(0), "ERROR: initialized");
        owner = _owner;
    }

    function baseURI() view public virtual returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory baseURI) internal {
        _baseUri = baseURI;
    }
}