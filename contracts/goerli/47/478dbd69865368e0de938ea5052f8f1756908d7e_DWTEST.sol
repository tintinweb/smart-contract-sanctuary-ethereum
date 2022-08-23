// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './ECDSA.sol';

contract DWTEST is ERC721A, Ownable {
    using ECDSA for bytes32;

    address private _signerAddress;

    string public baseURI;
    uint256 public maxSupply;

    constructor( uint256 newMaxSupply, address newSignerAddress, string memory newBaseURI ) ERC721A("DWTEST", "DWTEST") {
        maxSupply = newMaxSupply;
        _signerAddress = newSignerAddress;
        baseURI = newBaseURI;
    }

    // public functions

    function mint(bytes calldata signature, uint256 quantity, uint256 maxMintable) external payable {
        require( _verifySig(msg.sender, msg.value, maxMintable, signature), "Incorrect signature" );
        require( totalSupply() + quantity <= maxSupply, "Sold out");
        require( _numberMinted(msg.sender) + quantity <= maxMintable, "Maximum mintable tokens exceeded");

        _mint(msg.sender, quantity);
    }

    function numberMinted(address minter) external view returns(uint256) {
        return _numberMinted(minter);
    }

    // internal functions

    function _verifySig(address sender, uint256 valueSent, uint256 maxMintable, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, valueSent, maxMintable));
        return _signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // owner functions

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        require( newSignerAddress != address(0), "Signer can't be 0");
        _signerAddress = newSignerAddress;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}