// SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.4;

contract LizardPrime is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;

    uint256 public maxSupply;
    uint256 public price;
    uint256 public maxMintPerTx;
    uint256 public maxWhitelistMint = 10;
    uint256 public maxMintSupply;

    mapping(address => uint256) whitelistMintAmount;

    string public baseURI;
    string public hiddenURI;

    bool public paused = false;
    bool public revealed = false;
    bool[2] public authorized = [false, false];
    bool public whitelistOpen = true;

    address[] public teamWallets;
    address[2] public auxWallets = [0xB10Dc722Dfa2eb434772014cd3c825feD63BE47C,0x90688b6dE0fC52dF2DEb00eb21dC94Dbb6080957];
    address[2] public pixWallets = [0x3BaB948516504e31209319C1456Db258EcB20573,0x0662E643bDadA9CB7F5a6AC2BA08BF7c62A2Db9a];
    uint[] public teamWalletsPm;


    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxMintPerTx,
        uint256 _maxMintSupply,
        address[] memory _teamWallets,
        uint[] memory _teamWalletsPm
    ) ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        maxMintSupply = _maxMintSupply;
        price = _price;
        maxMintPerTx = _maxMintPerTx;
        teamWallets = _teamWallets;
        teamWalletsPm = _teamWalletsPm;
    }

    modifier mintCompliance(uint256 _amount) {
        require(_amount <= maxMintPerTx, "Max mint amount per tx exceeded (10).");  
        require(totalSupply() + _amount <= maxSupply, "Max Supply reached.");
        require(totalSupply() + _amount <= maxMintSupply, "Max Mint amount for this phase reached.");
        require(!paused, "Paused.");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _amount) external payable mintCompliance(_amount) {

        require(msg.value >= price * _amount, "Insufficient funds.");
        require(!whitelistOpen);

        _safeMint(msg.sender, _amount);
    }

    function mintPix(uint256 _amount, address _to) external {

        require(_msgSender() == pixWallets[0] || _msgSender() == pixWallets[1] || _msgSender() == owner(), "Caller is not the owner.");
        _safeMint(_to, _amount);
    }

    function mintAirdrop(uint256[] calldata _amount, address[] calldata _to) external onlyOwner {

        require(_amount.length == _to.length, "Amount and Address arrays must have the same size.");

        for(uint i = 0; i< _amount.length; i++){
            _safeMint(_to[i], _amount[i]);
        }
    }

    function mintWhitelist(uint256 _amount) external payable mintCompliance(_amount) {

        require(whitelistOpen);
        require(msg.value >= price * _amount, "Insufficient funds.");
        require(balanceOf(_msgSender())+ _amount <= maxWhitelistMint, "Max mint amount per whitelist exceeded.");

        _safeMint(_msgSender(), _amount);
    }

    function closeWhitelist() external onlyOwner{
        whitelistOpen = !whitelistOpen;
    }

    function setMaxWhitelistMint(uint256 _amountMax) external onlyOwner {
        maxWhitelistMint = _amountMax;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {

        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed) {
            return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        }

        return hiddenURI;

    }

    function setPrice(uint256 _price) public onlyOwner {
        require(authorized[0] && authorized[1], "Price changes are not authorized.");
        price = _price;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function setHiddenUri(string memory _hiddenUri) public onlyOwner {
        hiddenURI = _hiddenUri;
    }

    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        revealed = _revealed;
        baseURI = _baseUri;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxMintAmountPerTx(uint256 _amount) public onlyOwner {
        require(authorized[0] && authorized[1], "Max Mint per Tx changes are not authorized.");
        maxMintPerTx = _amount;
    }

    function authorize() external{
        if (msg.sender == teamWallets[0] || msg.sender == auxWallets[0]){
            authorized[0] = !authorized[0];
            return;
        }
        if (msg.sender == teamWallets[1] || msg.sender == auxWallets[1]){
            authorized[1] = !authorized[1];
            return;
        }
        revert("Caller is not a team wallet.");
    }

    function setTeamWallet(uint _id, address _teamWallet, uint _teamWalletPm) public onlyOwner {
        require(authorized[0] && authorized[1], "Team Wallet changes are not authorized.");
        teamWallets[_id] = _teamWallet;
        teamWalletsPm[_id] = _teamWalletPm;
    }

    function setpixWallet(address[2] calldata _pixWallets) public onlyOwner {
        require(authorized[0] && authorized[1], "Pix Wallet changes are not authorized.");
        pixWallets[0] = _pixWallets[0];
        pixWallets[1] = _pixWallets[1];
    }

    function addTeamWallet(address _teamWallet, uint _teamWalletPm) public onlyOwner {
        require(authorized[0] && authorized[1], "Team Wallet changes are not authorized.");
        teamWallets.push(_teamWallet);
        teamWalletsPm.push(_teamWalletPm);
    }

    function emergencyWithdraw(address _wallet) external onlyOwner {
        require(authorized[0] && authorized[1], "Emergency Withdraw is not authorized.");
        
        (bool succ, ) = payable(_wallet).call{value: address(this).balance}("");
        require(succ, "Call transfer failed");
        
    }

    function withdraw() external nonReentrant{

        uint256 currentBalance = address(this).balance;

        for(uint i = 0; i< teamWallets.length; i++){
            (bool succ, ) = payable(teamWallets[i]).call{value: currentBalance*teamWalletsPm[i]/1000}("");
            require(succ, "Call transfer failed");
        }
    }

}