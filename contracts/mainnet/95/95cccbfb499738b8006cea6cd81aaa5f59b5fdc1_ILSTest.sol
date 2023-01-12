// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "ERC721A.sol";
import "Ownable.sol";

contract ILSTest is ERC721A, Ownable {
    uint256 private _maxSupply = 50;

    address private _hotWallet;

    string private baseURI;

    mapping(address => bool) private _blacklist;

    constructor(address hot_wallet, string memory base_uri) ERC721A("i.ls test", "TEST") {
        _hotWallet = hot_wallet;
        baseURI = base_uri;
    }

    function offchainMint(uint256 limit) public onlyOwner {
        uint256 minted = _totalMinted();
        require(minted + limit <= _maxSupply, "Max supply exceeded");
        if (limit >= _maxSupply - minted) {
            _mint(_hotWallet, _maxSupply - minted);
        } else {
            _mint(_hotWallet, limit);
        }
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers() internal view virtual {
        require(_blacklist[msg.sender] == false, "Blacklisted");
    }

    function setBlacklist(address wallet, bool status) public onlyOwner {
        _blacklist[wallet] = status;
    }

    function isBlacklisted(address wallet) public view returns (bool) {
        return _blacklist[wallet];
    }

}