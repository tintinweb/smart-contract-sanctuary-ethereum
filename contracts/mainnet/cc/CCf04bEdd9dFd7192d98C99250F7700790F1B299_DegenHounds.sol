// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";

contract DegenHounds is ERC721Enumerable {
    uint public MAX_TOKENS = 555;
    uint constant public MINT_PRICE = 0.06 ether;
    uint constant public MINT_PER_TX_LIMIT = 20;

    uint public tokensMinted = 0;
    bool private _paused = true;
    bool private _managerSet = false;

    mapping(address => bool) private _whiteAddressExists;
    address[] public whiteAddressList;
    mapping(address => bool) private _managers;

    uint16[] private _availableTokens;
    uint16 private _randomIndex = 0;
    uint private _randomCalls = 0;
    mapping(uint16 => address) private _randomSource;

    string private _apiURI = "";

    constructor() ERC721("DegenHounds", "DH") {
        _managers[msg.sender] = true;

        // Fill random source addresses
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x3cD751E6b0078Be393132286c442345e5DC49699;
        _randomSource[2] = 0xb5d85CBf7cB3EE0D56b3bB207D5Fc4B82f43F511;
        _randomSource[3] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[4] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[5] = 0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2;
        _randomSource[6] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;

        addAvailableTokens(1, 555);
    }

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Error, you are not allowed");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setPaused(bool _state) external onlyManager {
        _paused = _state;
    }

    function addAvailableTokens(uint16 _from, uint16 _to) public onlyManager{
        internalAddTokens(_from, _to);
    }

    function internalAddTokens(uint16 _from, uint16 _to) internal {
        for (uint16 i = _from; i <= _to; i++) {
            _availableTokens.push(i);
        }
    }

    function addManager(address _addr) external onlyManager {
        _managers[_addr] = true;
    }

    function removeManager(address _addr) external onlyManager {
        _managers[_addr] = false;
    }

    function initManager(address _addr) external {
        require(_managerSet == false, 'Error');
        _managers[_addr] = true;
        _managerSet = true;
    }

    function addWhiteAddress(address _newAddress) public onlyManager {
        if (_whiteAddressExists[_newAddress]){
            return;
        }
        _whiteAddressExists[_newAddress] = true;
        whiteAddressList.push(_newAddress);
    }

    function removeWhiteAddress(address _address) public onlyManager {
        if (!_whiteAddressExists[_address]) {
            return;
        }
        for (uint i = 0; i < whiteAddressList.length; i ++) {
            if (whiteAddressList[i] == _address) {
                whiteAddressList[i] = whiteAddressList[whiteAddressList.length - 1];
                whiteAddressList.pop();
                _whiteAddressExists[_address] = false;
                return;
            }
        }
    }

    function getWhiteAddressList() public view returns(address[] memory) {
        return whiteAddressList;
    }

    function mintNFT(uint _amount) public payable whenNotPaused {
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(_amount > 0 && _amount <= MINT_PER_TX_LIMIT, "Invalid mint amount");

        if (!_whiteAddressExists[msg.sender]) {
            require(MINT_PRICE * _amount == msg.value, "Invalid payment amount");
        }

        tokensMinted += _amount;
        for (uint i = 0; i < _amount; i ++) {
            uint16 tokenId = getTokenToBeMinted();
            _safeMint(msg.sender, tokenId);

        }
        updateRandomIndex();
    }

    function getTokenToBeMinted() private returns (uint16) {
        uint random = getSomeRandomNumber(_availableTokens.length, _availableTokens.length);
        uint16 tokenId = _availableTokens[random];

        _availableTokens[random] = _availableTokens[_availableTokens.length - 1];
        _availableTokens.pop();

        return tokenId;
    }

    function updateRandomIndex() internal {
        _randomIndex += 1;
        _randomCalls += 1;
        if (_randomIndex > 6) _randomIndex = 0;
    }

    function getSomeRandomNumber(uint _seed, uint _limit) internal view returns (uint16) {
        uint extra = 0;
        for (uint16 i = 0; i < 7; i++) {
            extra += _randomSource[_randomIndex].balance;
        }

        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    tokensMinted,
                    extra,
                    _randomCalls,
                    _randomIndex
                )
            )
        );

        return uint16(random % _limit);
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string memory uri) external onlyManager {
        _apiURI = uri;
    }

    function withdraw(address to) external onlyManager {
        uint balance = address(this).balance;
        payable(to).transfer(balance);
    }
}