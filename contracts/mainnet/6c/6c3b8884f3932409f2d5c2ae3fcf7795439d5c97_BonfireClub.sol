// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './ECDSA.sol';

error IncorrectSignature();
error SoldOut();
error MaxMintTokensExceeded();
error AddressCantBeBurner();
error InvalidMaxSupply();
error HigherMaxSupplyNotAllowed();
error CantReduceCurrentSupply();

// @author web_n3rdz (n3rdz.xyz)
contract BonfireClub is ERC721A, Ownable {
    using ECDSA for bytes32;

    address private _signerAddress;

    address payable private immutable _team1;
    address payable private immutable _team2;
    address payable private immutable _team3;
    address payable private immutable _team4;
    address payable private immutable _team5;

    string public baseURI;
    uint256 public maxSupply;

    constructor( uint256 newMaxSupply, address newSignerAddress, string memory newBaseURI, address[5] memory teamAddresses ) ERC721A("Bonfire Club", "BFC") {
        maxSupply = newMaxSupply;
        baseURI = newBaseURI;
        _signerAddress = newSignerAddress;

        _team1 = payable(teamAddresses[0]);
        _team2 = payable(teamAddresses[1]);
        _team3 = payable(teamAddresses[2]);
        _team4 = payable(teamAddresses[3]);
        _team5 = payable(teamAddresses[4]);
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
     * @dev Aidrop tokens to given addresses (onlyOwner)
     */
    function airdrop(address[] calldata receivers, uint256[] calldata quantities ) external onlyOwner {

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
        uint256 amount70 = address(this).balance / 100 * 70;
        uint256 amount8 = address(this).balance / 100 * 8;
        uint256 amount2 = address(this).balance / 100 * 2;
        uint256 amount10 = address(this).balance / 100 * 10;

        _team1.transfer(amount70);
        _team2.transfer(amount8);
        _team3.transfer(amount2);
        _team4.transfer(amount10);
        _team5.transfer(amount10);
    }

}