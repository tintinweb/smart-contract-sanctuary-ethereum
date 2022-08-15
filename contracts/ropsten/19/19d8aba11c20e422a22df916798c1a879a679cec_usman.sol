// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
contract usman is ERC721URIStorage{
        using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address payable owner = payable(0xB1D0e833b42BbDF2B874E86959e68f071d8c535F);
    address minter;
    string name__ ;
    string symbol__;
    string uri__;
    uint256 mintingfees = 0.001 ether;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _creators;
    
    constructor (string memory _name, string memory _symbol, string memory _uri)ERC721(_name,_symbol) payable {
        minter = payable(msg.sender);
        name__ = _name ;
        symbol__ =  _symbol;
        uri__ =_uri;
        uint amount = 1 ;
        _balances[msg.sender] = amount;
        owner.transfer(mintingfees);
    }
    
    function mintToken(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _creators[newItemId] = msg.sender;
        _setTokenURI(newItemId, tokenURI);
        owner.transfer(mintingfees);
        return newItemId;
    }
        function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[_owner];
        }

    }