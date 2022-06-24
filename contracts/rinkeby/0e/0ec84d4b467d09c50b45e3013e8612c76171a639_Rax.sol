// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import './RAX.flatten.sol';
// import './ERC721A.sol';

error CallerNotOwner();
error OwnerAlreadySet();
error MaxMintPerTx();
error MaxSupplyReached();
error TransferWhilePaused();

contract Rax is ERC721A {
    address private _owner;

    // baseURI with trailing slash.
    string public baseURI = 'http://ipfs.bducks.io/';

    // MAX NUMBER OF NFTs PER TRANSACTION
    uint8 MAX_MINT_PER_TRANSACTION = 100;

    // MAX NFTs available
    uint16 MAX_NFTs = 1000;

    // pauses transfers and minting
    bool private _paused;

    // royalty value
    uint256 CREATOR_ROYALTY = 1000 wei;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() ERC721A('Rax', 'RAX') {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert CallerNotOwner();
        _;
    }

    function batchMint(address[] memory receivers) external onlyOwner {
        if (totalSupply() + receivers.length > MAX_NFTs)
            revert MaxSupplyReached();
        if (receivers.length > MAX_MINT_PER_TRANSACTION) revert MaxMintPerTx();

        for (uint8 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function transferOwnership(address to) external onlyOwner {
        if (_owner == to) revert OwnerAlreadySet();
        address oldOwner = _owner;
        _owner = to;
        emit OwnershipTransferred(oldOwner, to);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function isPaused() public view virtual returns (bool) {
        return _paused;
    }

    function setPaused(bool paused) external onlyOwner {
        _paused = paused;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (_paused) revert TransferWhilePaused();
    }
}