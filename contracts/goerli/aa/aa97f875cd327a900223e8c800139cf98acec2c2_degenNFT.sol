// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ | 

import "./interface.sol";
import "./contract.sol";
import "./abstract.sol";
import "./library.sol";

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

contract degenNFT is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public costWhitelist = 0.001 ether;
    uint256 public costPublicSale = 0.002 ether;
    uint256 public NFTminted;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    mapping (address => bool) public whitelisted;
    mapping(address => uint) public minted;

    string public tokenName = "DEGEN NFT COLLECTION";
    string public tokenSymbol = "DNC";
    uint256 public maxSupply = 10420;
    uint256 public mintableSupply = 10000;
    uint256 public maxMintAmountPerTx = 5;
    string public hiddenMetadataUri = "ipfs://QmRp5WBQuC56cVJJ5qnXkprtNT64ofdfa8nADfhVEWPhe9";
    
    constructor() ERC721A(tokenName, tokenSymbol) {
            maxSupply = maxSupply;
            setMaxMintAmountPerTx(maxMintAmountPerTx);
            setHiddenMetadataUri(hiddenMetadataUri);}

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= mintableSupply, "Mintable supply exceeded!");
        _;}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if(whitelistMintEnabled == true && paused == true){
            require(msg.value >= costWhitelist * _mintAmount, "Insufficient funds!");}
        if(paused == false){
            require(msg.value >= costPublicSale * _mintAmount, "Insufficient funds!");}
        _;}

    function setCostWhitelist(uint256 _cost) public onlyOwner {
        costWhitelist = _cost;}

    function setCostPublicSale(uint256 _cost) public onlyOwner {
        costPublicSale = _cost;}

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, 'The contract is paused!');
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        NFTminted += _mintAmount;
            _safeMint(_msgSender(), _mintAmount);}

    function burn(uint256 tokenId) public {
        _burn(tokenId, true); }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        //Minted by Owner without any cost, doesn't count on minted quantity
        NFTminted += _mintAmount;
        _safeMint(_receiver, _mintAmount);}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;}

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function setPaused(bool _state) public onlyOwner {
        paused = _state;}

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;}

    function whitelistAddress (address[] memory _addr) public onlyOwner() {
        for (uint i = 0; i < _addr.length; i++) {
            if(whitelisted[_addr[i]] == false){
                whitelisted[_addr[i]] = true;}}}

    function blacklistWhitelisted(address _addr) public onlyOwner() {
        require(whitelisted[_addr], "Account is already Blacklisted");
        whitelisted[_addr] = false;}

    function whitelistMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(whitelisted[_msgSender()], "Account is not in whitelist");
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        NFTminted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);}

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);}
        
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}}