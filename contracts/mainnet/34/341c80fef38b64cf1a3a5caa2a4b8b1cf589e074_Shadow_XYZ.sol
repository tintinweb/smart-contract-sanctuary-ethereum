// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './ECDSA.sol';

error IncorrectSignature();
error SoldOut();
error MaxMintTokensExceeded();
error AddressCantBeBurner();
error CantWithdrawFunds();

contract Shadow_XYZ is ERC721A, Ownable {
    using ECDSA for bytes32;

    address private _signerAddress;
    address private _authorWallet;

    uint256 private _authorMaxPayment;
    uint256 private _authorAlreadyPaid;

    string public baseURI;
    uint256 public maxSupply;

    constructor( uint256 newMaxSupply, address newSignerAddress, string memory newBaseURI, address newAuthorWallet, uint256 newAuthorMaxPayment ) ERC721A("Shadow_XYZ", "SHDW") {
        maxSupply = newMaxSupply;
        baseURI = newBaseURI;
        _signerAddress = newSignerAddress;
        _authorWallet = newAuthorWallet;
        _authorMaxPayment = newAuthorMaxPayment;
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
     * @dev Batch aidrop tokens to given addresses (onlyOwner)
     */
    function airdopBatch(address[] calldata receivers, uint256[] calldata quantities ) external onlyOwner {

        uint256 totalQuantity = 0;

        for( uint256 i = 0; i < quantities.length; i++ ) {
            totalQuantity += quantities[i];
        }

        if( totalSupply() + totalQuantity > maxSupply ) revert SoldOut();

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
     * @dev Withdraw all funds (onlyOwner)
     */
    function withdrawAll() external onlyOwner {

        uint256 balance = address(this).balance;

        if( _authorAlreadyPaid < _authorMaxPayment ) {
            if( balance < _authorMaxPayment - _authorAlreadyPaid ) {
                payable(_authorWallet).transfer(balance);
                _authorAlreadyPaid += balance;
            } else {
                uint256 lastAuthorPayment = _authorMaxPayment - _authorAlreadyPaid;
                uint256 leftover = balance - lastAuthorPayment;

                payable(_authorWallet).transfer(lastAuthorPayment);
                payable(msg.sender).transfer(leftover);

                _authorAlreadyPaid = _authorMaxPayment; 
            }

        } else {
            payable(msg.sender).transfer(balance);
        }
        
    }

}