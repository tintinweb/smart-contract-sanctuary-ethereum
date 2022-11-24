// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../ERC721.sol";
import "../ERC721Enumerable.sol";
import "../Pausable.sol";
import "../Ownable.sol";
import "../Counters.sol";

/// @custom:security-contact [email protected]
contract MEGALODON is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.15 ether;
    uint256 public maxSupply = 500;
    uint256 public maxMintAmount = 5;
    bool public revealed = false;
    string public notRevealedUri;
    uint256 private _totalReleased = 0;

    uint256 public revealDelay = block.timestamp + (0);
    uint256 public claimsOpen = block.timestamp + (0);

    mapping(uint256 => address) private _claimed;
    mapping(uint256 => bytes4) private _hash;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        _pause();
    }

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused(), "the contract is paused");
        require(_mintAmount > 0);
        require(
            _mintAmount <= maxMintAmount,
            "exceeds max allowed mint in one action"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "exceeds max allowed token supply"
        );

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        if (totalSupply() >= maxSupply) {
            //            claimsOpen = block.timestamp + 9 days;
            reveal();
        }
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function balance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function totalReleased() public view onlyOwner returns (uint256) {
        return _totalReleased;
    }

    function totalIncome() public view onlyOwner returns (uint256) {
        uint256 _totalIncome = address(this).balance + _totalReleased;
        return (_totalIncome);
    }

    function withdraw() public payable onlyOwner {
        uint256 withdrawalAmount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
        _totalReleased += withdrawalAmount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
        //        whitelistEnd = block.timestamp + 6 hours;
    }

    function setClaimsOpen(uint256 _date) public onlyOwner {
        claimsOpen = _date;
    }

    function setRevealDelay(uint256 _date) public onlyOwner {
        revealDelay = _date;
    }

    function claimed(uint256 _id) public view virtual returns (address) {
        return _claimed[_id];
    }

    function hashClaim(uint256 _id) public view virtual returns (bytes4) {
        require(
            (msg.sender == ownerOf(_id)) || (msg.sender == owner()),
            "You are not the owner of this token."
        );
        return _hash[_id];
    }

    function hash(address _addr, uint256 _id) private view returns (bytes4) {
        bytes32 result = keccak256(
            abi.encodePacked(_addr, _id, block.timestamp)
        );
        return bytes4(result);
    }

    function claim(uint256 _id) public {
        require(
            (block.timestamp > claimsOpen),
            "Tooth claiming has not yet been opened."
        );
        require(
            (_claimed[_id] == address(0)),
            "This tooth has already been claimed."
        );
        require(
            (msg.sender == ownerOf(_id)),
            "You are not the owner of this token."
        );
        _claimed[_id] = msg.sender;
        _hash[_id] = hash(msg.sender, _id);
    }

    function approve(address to, uint256 tokenId) public override {
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return super.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        return super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchsize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchsize);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        if (revealDelay >= block.timestamp) {
            return notRevealedUri;
        }

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function reveal() public onlyOwner {
        //        revealDelay = block.timestamp + 2 days;
        revealed = true;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}