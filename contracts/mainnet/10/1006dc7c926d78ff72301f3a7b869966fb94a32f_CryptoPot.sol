/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CryptoPot {

    address public _creator;
    address public _owner;
    uint256 public _maxPlayers = 100;
    uint256 public _price = 0.05 ether;
    uint256 public _winnerPrice = 4.95 ether;
    uint256 public _contestId = 1;
    uint256 public _winnerBlock = 0;
    uint256 public _coolPeriod = 1000;  //1000 blocks 
    bool    public _coolPeriodStarted = false;

    mapping (uint256 => address) private _tokenId2address;
    mapping (uint256 => uint256) private _tokenId2block;
    mapping (uint256 => uint256) private _tokenId2time;
    mapping (uint256 => bool)    private _tokenId2taken; 

    event Winner(uint256 contestId, uint256 tokenId);

    constructor() {
        _owner = msg.sender;
        _creator = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }
    function joinContest(uint256 tokenId) external payable {
        require(msg.value >= _price, "Ether sent is not correct");
        require(tokenId > 0 && tokenId <= _maxPlayers, "token not valid");
        require(_tokenId2taken[tokenId] == false, "token not available");

        if(_coolPeriodStarted) {  //new contest
            require(block.number - _winnerBlock > _coolPeriod, "cool period activated");
            _coolPeriodStarted = false;
        }

        _tokenId2address[tokenId] = msg.sender;
        _tokenId2block[tokenId] = block.number;
        _tokenId2time[tokenId] = block.timestamp;
        _tokenId2taken[tokenId] = true;
        
        if(availableTokensCount() == 0) {
            selectWinner();
        }
    } 
    function selectWinner() internal {
        uint256 tempVal = 0;
        for(uint256 i = 1; i <= _maxPlayers; ++i) {
            tempVal += _tokenId2block[i];
            tempVal += _tokenId2time[i];
            _tokenId2taken[i] = false;   //reset
        }
        
        uint256 winnerTokenId = 1 + (tempVal % _maxPlayers);
        payable(_tokenId2address[winnerTokenId]).transfer(_winnerPrice);
        emit Winner(_contestId, winnerTokenId);
        _coolPeriodStarted = true;
        _winnerBlock = block.number;
        _contestId++;
    }
    function availableTokensCount() public view returns (uint256) {
        uint256 count = 0;
        for(uint256 i = 1; i <= _maxPlayers; ++i) {
            if(_tokenId2taken[i] == false) {
                ++count;
            }
        }
        return count;
    }
    function availableTokens() external view returns (string memory) {
        string memory str;
        for(uint256 i = 1; i <= _maxPlayers; ++i) {
            if(_tokenId2taken[i] == false) {
                str = string(abi.encodePacked(str, (bytes(str).length > 0 ? "," : ""), toString(i))); 
            }
            if(bytes(str).length > 100) {
                break;
            }
        }
        return str;
    }
    function setCoolPeriod(uint256 _newVal) external onlyOwner {
        _coolPeriod = _newVal;
    }
    function setMaxPlayers(uint256 _newVal) external onlyOwner {
        _maxPlayers = _newVal;
    }
    function setPrice(uint256 _newVal) external onlyOwner {
        _price = _newVal;
    }
    function setWinnerPrice(uint256 _newVal) external onlyOwner {
        _winnerPrice = _newVal;
    }
    function withdraw() external payable {
        require(_coolPeriodStarted == true, "game in progress");
        payable(_creator).transfer(address(this).balance);
    }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}