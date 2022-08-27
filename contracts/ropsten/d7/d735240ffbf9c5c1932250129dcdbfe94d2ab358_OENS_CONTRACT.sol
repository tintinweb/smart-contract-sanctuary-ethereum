/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Ownable {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }
}

contract OENS_CONTRACT is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    struct data_struct {
        address eth;
        string btc;
        string ltc;
        string xmr;

        string content;

        string url;
        string twitter;
        string github;
    }

    mapping(string => data_struct) public OENS;
    mapping(address => uint256) public balanceOf;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[owner] = totalSupply;
    }

    function writeOENS(
        string memory _domain,
        address _eth,
        string memory _btc,
        string memory _ltc,
        string memory _xmr,

        string memory _content,

        string memory _url,
        string memory _twitter,
        string memory _github
    ) public ownerOnly returns (bool success) {
        OENS[_domain].eth = _eth;
        OENS[_domain].btc = _btc;
        OENS[_domain].ltc = _ltc;
        OENS[_domain].xmr = _xmr;
        
        OENS[_domain].content = _content;
        
        OENS[_domain].url = _url;
        OENS[_domain].twitter = _twitter;
        OENS[_domain].github = _github;

        return true;
    }

    function getOENS(string memory _domain) public view returns (data_struct memory result) {
        return OENS[_domain];
    }
}