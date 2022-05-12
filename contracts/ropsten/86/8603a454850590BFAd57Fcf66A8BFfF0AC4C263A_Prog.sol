/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


struct NFTinfo {
    address mainOwner;
    mapping(address => bool) isBenificialOwner;
    mapping(address => uint64) balances;
    mapping(address => mapping(address => bool)) approvals;
}


contract OwnerShip{
    address private contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "You are not the owner of the contract");
        _;
    }

    function getContractOwner() onlyOwner external view returns(address){
        return contractOwner;
    }

    function setContractOwner(address newContractOwner) onlyOwner external{
        contractOwner = newContractOwner;
    }
}

contract Prog is OwnerShip{
    uint64 public constant ONE_BILION = 1000000000; //1.000.000.000 1Bilion
    uint64 public constant ONE_QUARTER_OF_BILION = 250000000; //250.000.000 1/4 Bilion = 25%
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    mapping(uint256 => NFTinfo) private _nfts;
    string                      private _uri;

    constructor(string memory uri_) {
        _uri = uri_;
    }

    function getUri() external view returns (string memory) {
        return _uri;
    }

    function ownerOf(uint256 _tokenId) external view returns (address){
        return _nfts[_tokenId].mainOwner;
    }

    function balanceOf(address addr, uint256 _tokenId) external view returns (uint256) {
        return _nfts[_tokenId].balances[addr];
    }

    function mint(address to, uint256 _tokenId) onlyOwner external {
        require( _nfts[_tokenId].mainOwner == address(0), "NFT not avaiable to Mint");
        _nfts[_tokenId].mainOwner = to;
        _nfts[_tokenId].balances[to] = ONE_BILION;

        _nfts[_tokenId].isBenificialOwner[to] = true;

        emit Transfer(address(0), to, _tokenId);
    }

    function isBenificialOwner(address addr, uint256 _tokenId) external view returns (bool) {
        return _nfts[_tokenId].isBenificialOwner[addr];
    }

    function transfer(address from, address to, uint256 _tokenId, uint64 amount) onlyApproved(from, _tokenId) external {
        require( amount > 0, "Amount must be positive");
        require( _nfts[_tokenId].balances[from] >= amount, "You don't have enought funds");

        _nfts[_tokenId].balances[from] -= amount;
        _nfts[_tokenId].balances[to] += amount;

        address ownerAddress = _nfts[_tokenId].mainOwner;
        uint64 balanceOfTo = _nfts[_tokenId].balances[to];

        if( balanceOfTo > _nfts[_tokenId].balances[ownerAddress] )
            _nfts[_tokenId].mainOwner = to;

        if( balanceOfTo >= ONE_QUARTER_OF_BILION)
            _nfts[_tokenId].isBenificialOwner[to] = true;
        
        if( _nfts[_tokenId].balances[from] < ONE_QUARTER_OF_BILION)
            _nfts[_tokenId].isBenificialOwner[from] = false;

        emit Transfer(from, to, _tokenId);
    }

    function changeApprove(address to, uint256 _tokenId, bool val) external {
        _nfts[_tokenId].approvals[_msgSender()][to] = val;

        emit Approval(_msgSender(), to, _tokenId);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    modifier onlyApproved(address from, uint256 _tokenId) {
        require(msg.sender == from || _nfts[_tokenId].approvals[from][msg.sender], "You are not allowed");
        _;
    }
}