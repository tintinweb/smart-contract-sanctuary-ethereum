/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {

    uint256 public totalSupply; 
    uint256 public maxTotalSupply = 4523000000000000000000000;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external pure returns (string memory) {
        return "CHANCO";
    }

    function symbol() external pure returns (string memory) {
        return "CHANCO";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function _mint(address to_, uint256 _amount) internal {
        uint256 _totalAfterAmount = totalSupply + _amount;
        require(_totalAfterAmount <= maxTotalSupply, "More than supply");
        totalSupply += _amount;
        balanceOf[to_] += _amount;
        emit Transfer(address(0x0), to_, _amount);
    }

    function _burn(address from_, uint256 _amount) internal {
        balanceOf[from_] -= _amount;
        totalSupply -= _amount;
        emit Transfer(from_, address(0x0), _amount);
    }
    
    function _approve(address owner_, address _spender, uint256 _amount) internal {
        allowance[owner_][_spender] = _amount;
        emit Approval(owner_, _spender, _amount);
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address to_, uint256 _amount) public returns (bool) {
        balanceOf[msg.sender] -= _amount;
        balanceOf[to_] += _amount;
        emit Transfer(msg.sender, to_, _amount);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 _amount) public returns (bool) {
        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= _amount; }
        balanceOf[from_] -= _amount;
        balanceOf[to_] += _amount;
        emit Transfer(from_, to_, _amount);
        return true;
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
    
    function burnFrom(address from_, uint256 _amount) public {
        uint256 _currentAllowance = allowance[from_][msg.sender];
        require(_currentAllowance >= _amount, "Exceeds allowance");

        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= _amount; }

        _burn(from_, _amount);
    }
}

abstract contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

abstract contract Minter is Ownable {
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    function setMinter(address address_, bool bool_) external onlyOwner {
        minters[address_] = bool_;
    }
}

abstract contract Burner is Ownable {
    mapping(address => bool) public burners;
    modifier onlyBurner { require(burners[msg.sender], "Not Burner!"); _; }
    function setBurner(address address_, bool bool_) external onlyOwner {
        burners[address_] = bool_;
    }
}

contract CHANCO is ERC20, Ownable, Minter, Burner {

    ERC20 public immutable oldToken;

    bool public paused;

    constructor (address _oldToken) { 
        oldToken = ERC20(_oldToken); 
    }
    
    function mintToken(address to_, uint256 _amount) external onlyMinter {
        _mint(to_, _amount);
    }

    function burnToken(address from_, uint256 _amount) external onlyBurner {
        _burn(from_, _amount);
    }

    function ownerMint() external onlyOwner {
        _mint(msg.sender, 100);
    }

    function setPause() external onlyOwner {
        paused = !paused;
    }

    function migrate() external {
        require(paused, "Migration paused");
        uint balance = oldToken.balanceOf(msg.sender);
        oldToken.burnFrom(msg.sender, balance);
        _mint(msg.sender, balance);
    }
}