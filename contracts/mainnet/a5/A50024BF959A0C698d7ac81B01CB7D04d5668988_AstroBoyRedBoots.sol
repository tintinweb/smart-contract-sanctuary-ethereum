// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './ERC721A.sol';
import './StartTokenIdHelper.sol';
import './MerkleProof.sol';


contract AstroBoyRedBoots is StartTokenIdHelper, ERC721A {

    struct Config {
        uint256 total;
        uint256 limit;
        uint256 count;
        uint256 starttime;
        uint256 endtime;
        bytes32 root; 
        mapping(address => uint256) records;
    }

    mapping(uint256 => Config) public configs;

    uint256 public index;
    address public owner;
    string public uri;
    bool public paused;


    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not owner");
        _;
    }
    

    constructor(string memory name, string memory symbol, string memory baseURI) StartTokenIdHelper(1) ERC721A(name, symbol) {
        owner = msg.sender;
        uri = baseURI;
    }


    function freeMint(bytes32[] memory proof) external {
        require(!paused, "paused");

        require(msg.sender.code.length == 0, "not allow");

        require(check(index, msg.sender, proof), "not eligible for mint");

        require(block.timestamp >= configs[index].starttime, "not start"); 
        require(block.timestamp < configs[index].endtime, "is over"); 
        
        require(configs[index].count < configs[index].total, "sold out");
        require(configs[index].records[msg.sender] + 1 <= configs[index].limit, "exceed the limit");

        configs[index].count += 1;
        configs[index].records[msg.sender] += 1;

        _safeMint(msg.sender, 1);

    }

    function safeMint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }


    function setConfig(uint256 idx, uint256 total, uint256 limit, uint256 starttime, uint256 endtime, bytes32 root) external onlyOwner {

        Config storage config = configs[idx];
        config.total = total;
        config.limit = limit;
        config.starttime = starttime;
        config.endtime = endtime;
        config.root = root;

        index = idx;
    }


    function setIndex(uint256 idx) external onlyOwner {
        index = idx;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function check(uint256 idx, address addr, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, 0))));
        return MerkleProof.verify(proof, configs[idx].root, leaf);
    }

    function queryRecords(uint256 idx, address addr) external view returns(uint256) {
        return configs[idx].records[addr];
    }

    function numberMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return startTokenId();
    }

}