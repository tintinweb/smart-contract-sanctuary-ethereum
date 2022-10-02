// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './ERC721A.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';

error SoldOut();
error MaxMintTokensExceeded();
error CantWithdrawFunds();
error TxOriginNotSender();
error NotEnoughFunds();
error MintIsPaused();

contract RengaGoblins is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;
    uint256 public maxSupply;
    uint256 public maxMintPerWallet;
    uint256 public price;
    bool public paused;

    constructor( uint256 _maxSupply, string memory _tokenURI, uint256 _maxMintPerWallet, uint256 _price, bool _paused ) ERC721A("rengagoblins", "RENGOB") {
        maxSupply = _maxSupply;
        baseURI = _tokenURI;
        maxMintPerWallet = _maxMintPerWallet;
        price = _price;
        paused = _paused;
    }

    // public functions

    /**
     * @dev Public mint
     */
    function mint(uint256 quantity) external payable nonReentrant {
        if( paused ) revert MintIsPaused();
        if( tx.origin != msg.sender ) revert TxOriginNotSender();
        if( msg.value < quantity * price ) revert NotEnoughFunds();
        if( totalSupply() + quantity > maxSupply ) revert SoldOut();
        if( _numberMinted(msg.sender) + quantity > maxMintPerWallet ) revert MaxMintTokensExceeded();

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Check how many tokens the given address minted
     */
    function numberMinted(address minter) external view returns(uint256) {
        return _numberMinted(minter);
    }

    // internal functions

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
     * @dev Set base uri for token metadata (onlyOwner)
     */
    function setBaseURI(string memory _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
    }

    /**
     * @dev Set pause status (onlyOwner)
     */
    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /**
     * @dev Set max mint per wallet (onlyOwner)
     */
    function setMaxMintPerWallet(uint256 _maxMint) external onlyOwner {
        maxMintPerWallet = _maxMint;
    }

    /**
     * @dev Set public price (onlyOwner)
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @dev Withdraw all funds (onlyOwner)
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if( !success ) revert CantWithdrawFunds();
    }

}