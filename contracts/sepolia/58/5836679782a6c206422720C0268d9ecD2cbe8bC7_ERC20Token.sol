/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public paused;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    address private owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier isContract(address _addr) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        require(codeSize > 0, "Address must be a contract");
        _;
    }
    
    constructor() {
        name = "Stoken";
        symbol = "XST";
        decimals = 8;
        maxSupply = 2000000 * (10 ** uint256(decimals));
        
        totalSupply = 0; // Update the initial supply according to your needs
        balanceOf[msg.sender] = totalSupply;
        
        owner = msg.sender;
        paused = false;
    }
    

    
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(!paused, "Contract is paused");
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(!paused, "Contract is paused");
        require(_spender != address(0), "Invalid spender address");
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(!paused, "Contract is paused");
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function pauseContract() external onlyOwner {
        paused = !paused;
    }
    
    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(_newMaxSupply >= totalSupply, "New max supply must be greater than or equal to the current total supply");
        maxSupply = _newMaxSupply * (10 ** uint256(decimals));
    }
}