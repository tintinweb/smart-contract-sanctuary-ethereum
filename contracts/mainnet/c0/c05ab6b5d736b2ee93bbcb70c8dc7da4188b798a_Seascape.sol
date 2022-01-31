// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Seascape is
    ERC721Enumerable,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    using SafeMath for uint256;

    address proxyRegistryAddress;

    uint256 private _mintingFees = 1e17;
    mapping(uint256 => string) private _aprovedTokenIdToURI;
    mapping(uint256 => string) private _mintedTokenIdToURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to, uint256 _tokenId) public payable {
        require(msg.value == _mintingFees, "Incorrect value sent");
        require(
            bytes(_aprovedTokenIdToURI[_tokenId]).length > 0,
            "TokenId not approved for minting"
        );
        require(
            bytes(_mintedTokenIdToURI[_tokenId]).length == 0,
            "Token already minted"
        );
        _mint(_to, _tokenId);
        _mintedTokenIdToURI[_tokenId] = _aprovedTokenIdToURI[_tokenId];
        _aprovedTokenIdToURI[_tokenId] = "";
    }

    function isMinted(uint256 _tokenId) public view returns (bool) {
        return bytes(_mintedTokenIdToURI[_tokenId]).length > 0;
    }

    function setMintingFees(uint256 fees) public onlyOwner {
        _mintingFees = fees;
    }

    function withdraw(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    function approveForMint(
        uint256[] calldata _tokenIds,
        string[] calldata _uris
    ) public onlyOwner {
        require(_tokenIds.length == _uris.length, "Incorrect data provided");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                bytes(_mintedTokenIdToURI[_tokenIds[i]]).length == 0,
                "Token already minted"
            );
            _aprovedTokenIdToURI[_tokenIds[i]] = _uris[i];
        }
    }

    function isApprovedForMint(uint256 _tokenId) public view returns (bool) {
        return bytes(_aprovedTokenIdToURI[_tokenId]).length > 0;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _mintedTokenIdToURI[_tokenId];
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://7ovpie3wzm4kyrpjxzrb5xgn3wqpaxiszuysxom5bdmxeurhoiwq.arweave.net/-6r0E3bLOKxF6b5iHtzN3aDwXRLNMSu5nQjZclInci0";
    }
}