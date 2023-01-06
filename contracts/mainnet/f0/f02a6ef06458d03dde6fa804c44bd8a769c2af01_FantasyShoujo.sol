// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "ERC721A.sol";
import "Ownable.sol";

contract FantasyShoujo is ERC721A, Ownable {
    uint256 private _maxSupply = 2222;
    uint256 private _maxOnChainMint = 666;
    uint256 private _maxOffChainMint = _maxSupply - _maxOnChainMint;

    bool private _onChainMintEnabled = false;
    uint256 private _onChainMintCount = 0;
    uint256 private _mintPrice = 0.008 ether;
    uint256 private _mintQuotaPerAddress = 1;

    address private _hotWallet;

    mapping(address => bool) private _minted;

    string private baseURI;

    mapping(address => bool) private _blacklist;

    constructor(address hot_wallet, string memory base_uri) ERC721A("Fantasy Shoujo by i.ls", "SHOUJO") {
        _hotWallet = hot_wallet;
        baseURI = base_uri;
    }

    function offchainMint(uint256 limit) public onlyOwner {
        uint256 minted = _totalMinted();
        require(minted + limit <= _maxOffChainMint, "Max supply exceeded");
        if (limit >= _maxSupply - minted) {
            _mint(_hotWallet, _maxSupply - minted);
        } else {
            _mint(_hotWallet, limit);
        }
    }

    function setMintStatus(bool enabled) public onlyOwner {
        _onChainMintEnabled = enabled;
    }

    function mint() public payable {
        require(_onChainMintEnabled, "Minting not started");
        require(_onChainMintCount < _maxOnChainMint, "Max supply exceeded");
        require(msg.value >= _mintPrice, "Insufficient funds");
        require(checkQuota(msg.sender), "Exceed quota");

        // mint
        _mint(msg.sender, 1);
        _minted[msg.sender] = true;
        _onChainMintCount++;

        // refund if overpaid
        if (msg.value > _mintPrice) {
            payable(msg.sender).transfer(msg.value - _mintPrice);
        }

        // send ethers to owner
        payable(owner()).transfer(_mintPrice);
    }

    function getMintedCount() public view returns (uint256) {
        return _onChainMintCount;
    }

    function getTotalOnChainSupply() public view returns (uint256) {
        return _maxOnChainMint;
    }

    function checkQuota(address wallet) internal view returns (bool) {
        if (_minted[wallet]) {
            return false;
        }

        if (this.balanceOf(wallet) >= _mintQuotaPerAddress) {
            return false;
        }

        return true;
    }

    function setPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function isMintable() public view returns (uint8) {
        if (!_onChainMintEnabled) {
            return 1;
        }

        if (_onChainMintCount >= _maxOnChainMint) {
            return 2;
        }

        if (!checkQuota(msg.sender)) {
            return 3;
        }

        return 0;
    }

    function setQuota(uint256 quota) public onlyOwner {
        _mintQuotaPerAddress = quota;
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