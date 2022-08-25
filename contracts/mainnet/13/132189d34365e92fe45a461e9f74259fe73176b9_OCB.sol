// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './ECDSA.sol';

    error IncorrectSignature();
    error SoldOut();
    error MaxMintTokensExceeded();
    error SignerCantBeBurner();
    error CantWithdrawFunds();

// @author web_n3rdz (n3rdz.xyz)
contract OCB is ERC721A, Ownable {
    using ECDSA for bytes32;

    address private _signerAddress;

    string public baseURI;
    uint256 public maxSupply;

    constructor( uint256 newMaxSupply, address newSignerAddress, string memory newBaseURI ) ERC721A("OnChain Buccaneers", "OCB") {
        maxSupply = newMaxSupply;
        _signerAddress = newSignerAddress;
        baseURI = newBaseURI;
    }

    // public functions

    /**
     * @dev Important: You will need a valid signature to mint. The signature will only be generated on the official website.
     */
    function mint(bytes calldata signature, uint256 quantity, uint256 maxMintable) external payable {
        if( !_verifySig(msg.sender, msg.value, maxMintable, signature) ) revert IncorrectSignature();
        if( totalSupply() + quantity > maxSupply ) revert SoldOut();
        if( _numberMinted(msg.sender) + quantity > maxMintable ) revert MaxMintTokensExceeded();

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Check how many tokens the given address minted
     */
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

    /**
     * @dev Aidrop tokens to given address (onlyOwner)
     */
    function airdop(address receiver, uint256 quantity ) external onlyOwner {
        if( totalSupply() + quantity > maxSupply ) revert SoldOut();
        _mint(receiver, quantity);
    }

    /**
     * @dev Set the signer address to verify signatures (onlyOwner)
     */
    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if( newSignerAddress == address(0) ) revert SignerCantBeBurner();
        _signerAddress = newSignerAddress;
    }

    /**
     * @dev Set base uri for token metadata (onlyOwner)
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @dev Withdraw all funds (onlyOwner)
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if( !success ) revert CantWithdrawFunds();
    }

}