/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
                                     

/*
    @author @sheeeev66 of @thecoredevs
*/

contract ERC20 {
    // Supply
    uint256 public totalSupply; 
    uint256 public maxTotalSupply = 10000000000000000000000000;
    // Mappings of Balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external pure returns (string memory) {
        return "Zen Token";
    }

    function symbol() external pure returns (string memory) {
        return "ZEN";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    // Internal Functions
    function _mint(address to_, uint256 _amount) internal {
        uint256 _totalAfterAmount = totalSupply + _amount;
        require(_totalAfterAmount <= maxTotalSupply, "You cannot mint more than Mox Total Supply!");
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

    // Public Functions
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

    function burn(uint256 _amount) external { // should you allow anyone to burn?
        _burn(msg.sender, _amount);
    }
    
    function burnFrom(address from_, uint256 _amount) public {
        uint256 _currentAllowance = allowance[from_][msg.sender];
        require(_currentAllowance >= _amount, "ERC20IBurnable: Burn amount requested exceeds allowance!");

        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= _amount; }

        _burn(from_, _amount);
    }
}

contract Control  {
    address public owner;
    mapping(address => bool) public controllers;

    constructor() { owner = msg.sender; }
    
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    modifier onlyController { require(controllers[msg.sender], "Not Controller!"); _; }

    function transferOwnership(address new_) external onlyOwner { owner = new_; }
    
    function setController(address address_, bool bool_) external onlyOwner {
        controllers[address_] = bool_;
    }
}

contract ZenTokenV2 is ERC20, Control {

    // bool disableYieldTokenMint; this is done by setting the address in the yield contract to 0

    ERC20 public immutable oldToken;

    constructor(address _oldToken) { oldToken = ERC20(_oldToken); }
    



    // functions for yield token
    function mintAsController(address to_, uint256 _amount) external onlyController {
        _mint(to_, _amount);
    }
    function burnAsController(address from_, uint256 _amount) external onlyController {
        _burn(from_, _amount);
    }

    // migration
        bool public migrationEnabled = false;
    function toggleMigration() external onlyOwner {
        migrationEnabled = !migrationEnabled;
    }

    function migrate() external {
        require(migrationEnabled, "Migration is not enabled!");
        uint userBal = oldToken.balanceOf(msg.sender);
        oldToken.burnFrom(msg.sender, userBal);
        _mint(msg.sender, userBal / 10);
    }
}