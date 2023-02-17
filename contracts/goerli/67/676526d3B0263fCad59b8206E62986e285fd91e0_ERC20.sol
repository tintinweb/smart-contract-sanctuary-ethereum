/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract ERC20 {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256 ) ) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor (string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function buy() external payable {
        _mint(msg.sender, msg.value);
    }

    function redeem(uint256 amount) external {
        _burn(msg.sender, amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require( success, "Failed to send ETH");
    }

    function transfer( address recipient, uint256 amount ) external returns(bool) {
        return _transfer( msg.sender, recipient, amount );
    }

    function transferFrom( address sender, address recipient, uint256 amount ) external returns(bool) {
        require( allowance[sender][recipient] >= amount, "ERC20: allowance exceded" );
        allowance[sender][recipient] -= amount;
        emit Approval(sender, recipient, amount);

        return _transfer(sender, recipient, amount);
    }    

    function approve( address spender, uint256 amount ) external returns(bool) {
        require( spender != address(0), "ERC20: setting allowances to the null address" );
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _transfer( address sender, address recipient, uint256 amount ) private returns(bool) {
        require( recipient != address(0), "ERC20: transfer the null address" );
        require( balanceOf[sender] >= amount, "ERC20: insuficient balance to transfer");

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _mint( address to, uint256 amount ) internal {
        require( to != address(0), "ERC20: mint to the null address" );
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn( address from, uint256 amount ) internal {
        require( balanceOf[from] >= amount, "ERC20: insuficient balance" );
        totalSupply -= amount;
        balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);
    }
}