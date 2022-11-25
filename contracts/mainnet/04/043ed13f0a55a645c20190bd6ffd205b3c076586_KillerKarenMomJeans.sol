// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './ECDSA.sol';

error IncorrectSignature();
error SoldOut();
error WhitelistSoldOut();
error MaxMintTokensExceeded();
error AddressCantBeBurner();
error InvalidMaxSupply();
error HigherMaxSupplyNotAllowed();
error CantReduceCurrentSupply();
error CantWithdrawFunds();

// @author web_n3rdz (n3rdz.xyz)
contract KillerKarenMomJeans is ERC721A, Ownable {
    using ECDSA for bytes32;

    address private _signerAddress;

    string public baseURI;
    uint256 public maxSupply;
    uint256 public whitelistMaxSupply;

    constructor( uint256 newMaxSupply, uint256 newWhitelistMaxSupply, address newSignerAddress, string memory newBaseURI ) ERC721A("Killer Karen: Mom Jeans", "KKMJ") {
        maxSupply = newMaxSupply;
        whitelistMaxSupply = newWhitelistMaxSupply;
        baseURI = newBaseURI;
        _signerAddress = newSignerAddress;
    }

    // public functions

    /**
     * @dev Important: You will need a valid signature to mint. The signature will only be generated on the official website.
     */
    function mint(bytes calldata signature, uint256 quantity, uint256 maxMintable, bool isWhitelistClaim) external payable {
        if( !_verifySig(msg.sender, msg.value, maxMintable, isWhitelistClaim, signature) ) revert IncorrectSignature();
        if( _numberMinted(msg.sender) + quantity > maxMintable ) revert MaxMintTokensExceeded();

        if( isWhitelistClaim ) {
            if( totalSupply() + quantity > whitelistMaxSupply ) revert WhitelistSoldOut();
            maxSupply += quantity;
        } else {
            if( totalSupply() + quantity > maxSupply ) revert SoldOut();
        }

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Check how many tokens the given address minted
     */
    function numberMinted(address minter) external view returns(uint256) {
        return _numberMinted(minter);
    }

    // internal functions

    function _verifySig(address sender, uint256 valueSent, uint256 maxMintable, bool isWhitelistClaim, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, valueSent, maxMintable, isWhitelistClaim));
        return _signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // owner functions

    /**
     * @dev Aidrop tokens to given addresses (onlyOwner)
     */
    function airdrop(address[] calldata receivers, uint256[] calldata quantities, bool isWhitelistClaim ) external onlyOwner {

        uint256 totalQuantity = 0;

        for( uint256 i = 0; i < quantities.length; i++ ) {
            totalQuantity += quantities[i];
        }

        if( isWhitelistClaim ) {
            if( totalSupply() + totalQuantity > whitelistMaxSupply ) revert WhitelistSoldOut();
            maxSupply += totalQuantity;
        } else {
            if( totalSupply() + totalQuantity > maxSupply ) revert SoldOut();
        }

        for( uint256 i = 0; i < receivers.length; i++ ) {
            _mint(receivers[i], quantities[i]);
        }
    }

    /**
     * @dev Set the signer address to verify signatures (onlyOwner)
     */
    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if( newSignerAddress == address(0) ) revert AddressCantBeBurner();
        _signerAddress = newSignerAddress;
    }

    /**
     * @dev Set base uri for token metadata (onlyOwner)
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @dev Burn/reduce the max whitelist supply (onlyOwner)
     */
    function burnWhitelistSupply(uint256 newWhitelistMaxSupply) external onlyOwner {
        if( newWhitelistMaxSupply <= 0 ) revert InvalidMaxSupply();
        if( newWhitelistMaxSupply >= whitelistMaxSupply ) revert HigherMaxSupplyNotAllowed();
        if( newWhitelistMaxSupply < totalSupply() ) revert CantReduceCurrentSupply();
        
        whitelistMaxSupply = newWhitelistMaxSupply;
    }

    /**
     * @dev Burn/reduce the max supply (onlyOwner)
     */
    function burnSupply(uint256 newMaxSupply) external onlyOwner {
        if( newMaxSupply <= 0 ) revert InvalidMaxSupply();
        if( newMaxSupply >= maxSupply ) revert HigherMaxSupplyNotAllowed();
        if( newMaxSupply < totalSupply() ) revert CantReduceCurrentSupply();
        
        maxSupply = newMaxSupply;
    }

    /**
     * @dev Withdraw all funds (onlyOwner)
     */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if( !success ) revert CantWithdrawFunds();
    }



}