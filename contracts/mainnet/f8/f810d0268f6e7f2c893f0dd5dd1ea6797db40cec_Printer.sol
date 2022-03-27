/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.11;

interface ERC721{
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}


contract ERC20 {
    address immutable printer = msg.sender;
    string public constant name = "Print";
    string public constant symbol = "PRINT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _owner, address indexed _spender, uint256 _value);
    event Approval(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public {
        require(msg.sender == printer);
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
    }
}


contract Printer {
    struct Record {
        address owner;
        uint64 beginning;
        ERC20 erc20;
    }

    mapping(address => mapping(uint256 => Record)) public records;

    function onERC721Received(address, address _from, uint256 _tokenId, bytes calldata) public returns (bytes4) {
        Record storage record = records[msg.sender][_tokenId];
        if (address(record.erc20) == address(0)) {
            record.erc20 = new ERC20();
        }
        record.owner = _from;
        record.beginning = uint64(block.timestamp);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function print(address _collection, uint256 _tokenId) public {
        Record storage record = records[_collection][_tokenId];
        require(msg.sender == record.owner);
        uint256 value = (block.timestamp - record.beginning) * 10**18;
        record.beginning = uint64(block.timestamp);
        record.erc20.mint(msg.sender, value);
    }

    function withdraw(address _collection, uint256 _tokenId) public {
        Record storage record = records[_collection][_tokenId];
        require(msg.sender == record.owner);
        uint256 value = (block.timestamp - record.beginning) * 10**18;
        record.owner = address(0);
        record.beginning = 0;
        record.erc20.mint(msg.sender, value);
        ERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId);
    }
}