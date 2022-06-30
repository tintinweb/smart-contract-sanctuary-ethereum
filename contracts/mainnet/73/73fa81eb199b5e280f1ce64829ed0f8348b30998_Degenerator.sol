pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract Degenerator is ERC721Tradable {
    using Counters for Counters.Counter;

    mapping (address => bool) private _whitelist;
    mapping (address => uint) private _numMinted;
    uint public _supplyLimit;
    uint public _mintLimit = 3;
    uint public _txnLimit = 3;
    uint public _mintPrice = 2 * 10 ** 17;
    bool public _whiteListOnly = true;
    bool public _mintingEnabled = false;
    bool public _transferLimit = true;
    bool public _noTransfers = false;


    constructor(
    ) ERC721Tradable("Degenerator S01", "DEGEN01", 0xa5409ec958C83C3f309868babACA7c86DCB077c1) { }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://degen.megaweapon.io/degen/s01/";
    }

    function mint(uint _numToMint) external payable {
        require (_mintingEnabled, "DEGEN: minting disabled");
        require (_numToMint > 0, "DEGEN: cannot mint 0 tokens");
        if (_whiteListOnly)
            require (_whitelist[msgSender()] == true, "DEGEN: must be whitelisted");
        require (_numToMint <= _txnLimit, "DEGEN: per txn mint limit exceeded");
        require (msg.value == (_mintPrice * _numToMint), "DEGEN: wrong value");
        uint i = 0;
        while (i < _numToMint) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msgSender(), currentTokenId);
            _numMinted[msgSender()]++;
            i++;
        }
        if (_supplyLimit != 0) 
            require (totalSupply() <= _supplyLimit, "DEGEN: total mint limit exceeded");
        if (_mintLimit != 0) 
            require (_numMinted[msgSender()] <= _mintLimit, "DEGEN: per account mint limit exceeded");
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        require (addresses.length <= 100, "DEGEN: limit 100 addresses");
        uint i = 0;
        uint max = addresses.length;
        while (i < max) {
            _whitelist[addresses[i]] = true;
            i++;
        }
    }

    function isWhitelist(address account) external view returns (bool) {
        return _whitelist[account];
    }

    function setMintLimit(uint limit) external onlyOwner {
        require (limit != _mintLimit, "DEGEN: cannot set same mint limit");
        _mintLimit = limit;
    }
    
    function setSupplyLimit(uint limit) external onlyOwner {
        require (limit != _supplyLimit, "DEGEN: cannot set same supply limit");
        _supplyLimit = limit;
    }

    function setTxnLimit(uint limit) external onlyOwner {
        require (limit != _txnLimit, "DEGEN: cannot set same txn limit");
        _txnLimit = limit;
    }

    function setMintPrice(uint price) external onlyOwner {
        require (price != _mintPrice, "DEGEN: cannot set same price");
        _mintPrice = price;
    }

    function toggleWhitelist() external onlyOwner {
        _whiteListOnly = !_whiteListOnly;
    }

    function toggleMinting() external onlyOwner {
        _mintingEnabled = !_mintingEnabled;
    }

    function toggleTransferLimit() external onlyOwner {
        _transferLimit = !_transferLimit;
    }

    function toggleNoTransfers() external onlyOwner {
        _noTransfers = !_noTransfers;
    }

    function withdraw(uint amount) external onlyOwner {
        (bool sent, ) = _msgSender().call{value: amount}("");
        require (sent, "DEGEN: withdraw failed");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require (_noTransfers == false || _mintingEnabled == true, "DEGEN: no transfers at this time");
        if (_transferLimit == true && _mintLimit != 0)
            require (balanceOf(to) <= _mintLimit, "DEGEN: account token limit exceeded");
    }
}