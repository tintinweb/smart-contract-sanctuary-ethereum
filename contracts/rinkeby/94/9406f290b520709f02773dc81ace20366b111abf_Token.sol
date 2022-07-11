/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Ownable {
    address _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner, "Hindi ka may-ari ng contract na ito");
        _;
    }
    constructor(){
        _owner = msg.sender;
    }
}

contract Token is Ownable{

    // My Variables
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    // Keep track balances and allowances approved
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events - fire events on state changes etc
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SpecialMint(address indexed to, uint256 value, uint256 balanceBefore, uint256 balanceAfter, uint256 supplyBefore, uint256 supplyAfter);
    event SpecialBurn(address indexed from, uint256 value, uint256 balanceBefore, uint256 balanceAfter, uint256 supplyBefore, uint256 supplyAfter);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
    }

    /// @notice transfer amount of tokens to an address
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @return success as true, for transfer 
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev internal helper transfer function with required safety checks
    /// @param _from, where funds coming the sender
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    // Internal function transfer can only be called by this contract
    //  Emit Transfer Event event 
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    /// @notice Approve other to spend on your behalf eg an exchange 
    /// @param _spender allowed to spend and a max amount allowed to spend
    /// @param _value amount value of token to send
    /// @return true, success once address approved
    //  Emit the Approval event  
    // Allow _spender to spend up to _value on your behalf
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice transfer by approved person from original address of an amount within approved limit 
    /// @param _from, address sending to and the amount to send
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @dev internal helper transfer function with required safety checks
    /// @return true, success once transfered from original account    
    // Allow _spender to spend up to _value on your behalf
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            balanceOf[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )internal virtual{}

     function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    )internal virtual{}


    function specialMint(uint256 _value) external onlyOwner returns (bool success){
        _specialMint(msg.sender, _value);
        return true;
    }

    function _specialMint(address _to, uint256 _value) internal{
        require(_to != address(0));
        uint256 supplyBefore = totalSupply;
        uint256 balanceBefore = balanceOf[_to];

        totalSupply += _value;
        balanceOf[_to] += _value;

        uint256 supplyAfter = totalSupply;
        uint256 balanceAfter = balanceOf[_to];

        emit Transfer(address(0), _to, _value);
        emit SpecialMint(_to, _value, balanceBefore, balanceAfter, supplyBefore, supplyAfter);
    }




    function specialBurn(uint256 _value) external returns (bool success){
        _specialBurn(msg.sender, _value);
        return true;
    }

    function _specialBurn(address _from, uint256 _value) internal{
        require(_from != address(0));
        require(_value <= balanceOf[_from]);

        uint256 supplyBefore = totalSupply;
        uint256 balanceBefore = balanceOf[_from];

        totalSupply -= _value;
        balanceOf[_from] -= _value;

        uint256 supplyAfter = totalSupply;
        uint256 balanceAfter = balanceOf[_from];

        emit Transfer(_from, address(0), _value);
        emit SpecialBurn(_from, _value, balanceBefore, balanceAfter, supplyBefore, supplyAfter);
    }

}