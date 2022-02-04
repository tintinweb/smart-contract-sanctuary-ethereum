//SPDX-License-Identifier: GPL-3.0
/*
                
                            __,__
                   .--.  .-"     "-.  .--.
                  / .. \/  .-. .-.  \/ .. \
                 | |  '|  /   Y   \  |'  | |
                 | \   \  \ 0 | 0 /  /   / |
                  \ '- ,\.-"`` ``"-./, -' /
                   `'-' /_   ^ ^   _\ '-'`
                       |  \._   _./  |
                       \   \ `~` /   /
                        '._ '-=-' _.'
                           '~---~'
                
                            
                    https://arcticapes.club
*/

pragma solidity^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";
contract ArcticApesNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Strings for uint256;
    
    string ticketName = "Arctic Apes";
    string ticketSymbol = "AP";
    string private unrevealedBaseURI;
    string private revealedBaseURI;
    bool private paused = true;
    bool private presalePaused = true;
    uint256 maxSupply = 10000;
    uint256 maxPerTX = 30;
    uint256 cost = 0.1 ether;
    mapping(address => bool) wl;
    Counters.Counter private _tokenTracker;
    
    event pauseChanged(bool paused);
    event newMint(address minter, uint256 tokenID);
    event saleConfigChanged(uint32 _newStart, uint32 _newEnd, uint32 _newTimeToUnlock, uint32 _newUnlockedMax, uint32 _newInitialMintMax, uint32 _maxPerWallet);

    constructor (string memory baseURI) ERC721(ticketName, ticketSymbol) {
        setUnrevealedBaseURI(baseURI);
    }
    
    struct saleConf {
        uint32 startTime;
        uint32 endTime;
        uint32 timeToUnlock;
        uint32 unlockedMax;
        uint32 initialMintMax;
        uint32 maxPerWallet;
        bool presaleAvailable;
        uint32 presaleStartTime;
        uint32 presaleEndTime;
        uint32 presaleMax;
    }
    
    saleConf private saleConfig;
    // modifiers 
    
    modifier saleLive {
        require(paused == false, "Sale is not yet live");
        _;
    }
    
    modifier checkSetup{

        require(saleConfig.startTime !=0, "Sale start time not set yet");
        require(saleConfig.endTime != 0, "Sale end time not set yet");
        require(maxPerTX > 0, "Max per transaction not yet set");
        _;
    }
    
    modifier checkPresale{
        require(saleConfig.presaleAvailable == true, "Presale is not enabled");
        require(saleConfig.presaleStartTime != 0, "Presale start time not set");
        require(saleConfig.presaleMax != 0, "Max in presale not set");
        _;
    }
    
    
    function unpauseMint() public onlyOwner checkSetup {
        paused = false;
    }
    
    function pauseMint() public onlyOwner {
        paused = true;
    }
    
    function unpausePresale() public onlyOwner checkPresale {
        presalePaused = false;
    }
    
    function pausePresale() public onlyOwner {
        presalePaused = true;
    }
    
    function addSingleWl(address toAdd) public onlyOwner {
        wl[toAdd] = true;

    }
    
    function rmvWl(address toRmv) public onlyOwner {
        wl[toRmv] = false;
    }    
    
    function massAddWl(address[] memory addressesToAdd) public onlyOwner {
        for (uint256 i=0; i < addressesToAdd.length; i++) {
            wl[addressesToAdd[i]] = true;
        }
    }
    
    function massRmvWl(address[] memory addressesToRmv) public onlyOwner {
        for (uint256 i=0; i < addressesToRmv.length; i++) {
            wl[addressesToRmv[i]] = false;
        }
    }
    
    function changeCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }
    
    function changeSupply(uint256 _amnt) public onlyOwner {
        maxSupply = _amnt;
    }
    

    // viewers
    function currentToken() public view returns(uint256) { 
        return _tokenTracker.current();
        
    }
    
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function getRevealedBaseURI() internal view returns(string memory) {
        return revealedBaseURI;
    }
    
    function _baseURI() internal override view returns(string memory) {
        return compareStrings(revealedBaseURI, "") ? unrevealedBaseURI: revealedBaseURI;
    }
    
    // setters
    
    function setUnrevealedBaseURI(string memory _givenBaseURI) public onlyOwner {
        unrevealedBaseURI = _givenBaseURI;
    }
    
    function setRevealedBaseURI(string memory _givenBaseURI) public onlyOwner {
        revealedBaseURI = _givenBaseURI;
    }
    
    // important functions
    
    function _fullMint(address _to, uint256 _tokenID) internal {
        _tokenTracker.increment();
        _safeMint(_to, _tokenID);
        emit newMint(_to, _tokenID);
    }
    
    
    function mint(uint256 _amnt) public payable{
        // by using currentToken we can reduce gas as a pose to the ERC721 built in func
        require(currentToken() + _amnt <= maxSupply, "We do not have the supply for this");
        require(_amnt > 0, "You must mint at least one");
        require(paused == false, "Mint is not live");
        require(block.timestamp >= saleConfig.startTime && saleConfig.endTime >= block.timestamp, "The mint period is not active");
        require(msg.value >= cost * _amnt, "User did not send enough ether for this");
        require(balanceOf(msg.sender) + _amnt <= saleConfig.maxPerWallet, "You are not allowed this many in 1 wallet");
        require(_amnt <= saleConfig.initialMintMax, "You cannot mint this many in 1 tx");
        for (uint256 i=0; i < _amnt; i++) {
            _fullMint(msg.sender, currentToken());
        }
    }
    
    function presaleMint(uint256 _amnt) public payable{
        require(currentToken() + _amnt <= maxSupply, "We do not have the supply for this");
        require(_amnt > 0, "You must mint at least one");
        require(presalePaused == false, "Presale not live or not enabled");
        require(block.timestamp >= saleConfig.presaleStartTime && saleConfig.presaleEndTime >= block.timestamp, "The mint period is not active");
        require(msg.value >= cost * _amnt, "User did not send enough ether for this.");
        require(balanceOf(msg.sender) + _amnt <= saleConfig.presaleMax, "You have reached the max amount minted for this wallet!");
        require(_amnt <= saleConfig.presaleMax, "You cannot mint this many in 1 transaction.");
        require(wl[msg.sender] == true, "You are not on the whitelist.");
        for (uint256 i=0; i < _amnt; i++) {
            _fullMint(msg.sender, currentToken());
        }
    }

    function setupSale(uint256 _startTime, 
    uint256 _endTime, 
    uint256 _timeToUnlock, 
    uint256 _unlockedMax,
    uint256 _initialMintMax,
    uint256 _maxPerWallet,
    bool _presaleAvailable,
    uint256 _presaleStart,
    uint256 _presaleEnd,
    uint256 _presaleMax) public onlyOwner {
        uint32 _uint32Start = _startTime.toUint32();
        uint32 _uint32End = _endTime.toUint32();
        uint32 _uint32Unlock = _timeToUnlock.toUint32();
        uint32 _uint32UnlockedMax = _unlockedMax.toUint32();
        uint32 _uint32InitialMintMax = _initialMintMax.toUint32();
        uint32 _uint32MaxPerWallet = _maxPerWallet.toUint32();
        uint32 _uint32presaleStart = _presaleStart.toUint32();
        uint32 _uint32presaleEnd = _presaleEnd.toUint32();
        uint32 _uint32presaleMax = _presaleMax.toUint32();
        saleConfig = saleConf({
            startTime: _uint32Start,
            endTime: _uint32End,
            timeToUnlock: _uint32Unlock,
            unlockedMax: _uint32UnlockedMax,
            initialMintMax: _uint32InitialMintMax,
            maxPerWallet: _uint32MaxPerWallet,
            presaleAvailable: _presaleAvailable,
            presaleStartTime: _uint32presaleStart,
            presaleEndTime: _uint32presaleEnd,
            presaleMax: _uint32presaleMax
        });
        emit saleConfigChanged(saleConfig.startTime, saleConfig.endTime, saleConfig.timeToUnlock, saleConfig.unlockedMax, saleConfig.initialMintMax, saleConfig.maxPerWallet);
    }

    function _widthdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _widthdraw(msg.sender, address(this).balance); // remaining
    }

    function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
        require(_exists(tokenID), "This token does not exist");
        string memory currBaseURI = _baseURI();
        return bytes(currBaseURI).length > 0 ? string(abi.encodePacked(currBaseURI, tokenID.toString(), ".json")):""; // for opensea and other places to find the data of our nft
    }
    
    
}