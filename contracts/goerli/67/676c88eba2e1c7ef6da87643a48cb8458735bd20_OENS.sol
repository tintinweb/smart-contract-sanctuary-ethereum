/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Ownable {
    address public Registrar;
    
    constructor() {
        Registrar = msg.sender;
    }

    modifier ownerOnly() {
        require(Registrar == msg.sender);
        _;
    }
}

contract OENS is Ownable {
    string public name;
    string public symbol;

    event Write (
        address _owner,

        string _domain,
        address _eth,
        string _btc,
        string _ltc,
        string _xmr,

        string _content,

        string _url,
        string _twitter,
        string _github,

        uint256 _time
    );

    event Transfer (address _from, address _to, string _domain);

    event Reddem (string _domain);

    /**
     * Data structure
     */
    struct data_struct {
        address owner;

        address eth;
        string btc;
        string ltc;
        string xmr;

        string content;

        string url;
        string twitter;
        string github;

        uint256 time;
    }

    mapping(string => data_struct) public domains;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function write(
        address _owner,

        string memory _domain,
        address _eth,
        string memory _btc,
        string memory _ltc,
        string memory _xmr,

        string memory _content,

        string memory _url,
        string memory _twitter,
        string memory _github,
        uint8 _days
    ) public returns (bool success) {
        require(domains[_domain].owner == msg.sender || msg.sender == Registrar);

        domains[_domain].owner = _owner;

        domains[_domain].eth = _eth;
        domains[_domain].btc = _btc;
        domains[_domain].ltc = _ltc;
        domains[_domain].xmr = _xmr;
        
        domains[_domain].content = _content;
        
        domains[_domain].url = _url;
        domains[_domain].twitter = _twitter;
        domains[_domain].github = _github;

        uint256 _time = block.timestamp + (_days * 1 days);

        domains[_domain].time = _time;

        emit Write (_owner, _domain, _eth, _btc, _ltc, _xmr, _content, _url, _twitter, _github, _time);

        return true;
    }

    function get(string memory _domain) public view returns (data_struct memory result) {
        return domains[_domain];
    }

    function transfer(string memory _domain, address _owner) public returns (bool success) {
        require(domains[_domain].owner == msg.sender && msg.sender != _owner);

        domains[_domain].owner = _owner;

        domains[_domain].eth = _owner;
        domains[_domain].btc = "";
        domains[_domain].ltc = "";
        domains[_domain].xmr = "";
        
        domains[_domain].content = "";
        
        domains[_domain].url = "";
        domains[_domain].twitter = "";
        domains[_domain].github = "";

        emit Transfer (msg.sender, _owner, _domain);

        return true;
    }

    function available(string memory _domain) public view returns (bool availability) {
        return domains[_domain].owner == address(0x0) ||
               domains[_domain].owner == Registrar ||
               domains[_domain].time <= block.timestamp;
    }

    function expires(string memory _domain) public view returns (uint256 time) {
        if (domains[_domain].time > block.timestamp) return domains[_domain].time - block.timestamp;
        else return 0;
    }

    function redeem(string memory _domain) public ownerOnly returns (bool success) {
        domains[_domain].owner = Registrar;

        domains[_domain].eth = address(0x0);
        domains[_domain].btc = "";
        domains[_domain].ltc = "";
        domains[_domain].xmr = "";
        
        domains[_domain].content = "";
        
        domains[_domain].url = "";
        domains[_domain].twitter = "";
        domains[_domain].github = "";

        emit Reddem (_domain);

        return true;
    }
}