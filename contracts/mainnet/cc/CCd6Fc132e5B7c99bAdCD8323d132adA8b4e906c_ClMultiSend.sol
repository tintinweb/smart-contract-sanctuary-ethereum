/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Includes openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/) code with MIT license

pragma solidity ^0.8.7;

interface ERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ClMultiSend
{
    event MultiTransfer
    (
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount
    );

    event MultiERC20Transfer
    (
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount,
        ERC20 _token
    );

    function multiTransfer(address[] memory _addresses, uint[] memory _amounts) payable public returns(bool)
    {
        uint toReturn = msg.value;

        for (uint i = 0; i < _addresses.length; i++) 
        {
            _safeTransfer(_addresses[i], _amounts[i]);
            toReturn = SafeMath.sub(toReturn, _amounts[i]);

            emit MultiTransfer(msg.sender, msg.value, _addresses[i], _amounts[i]);
        }

        _safeTransfer(msg.sender, toReturn);

        return true;
    }

    function multiERC20Transfer(ERC20 _token, address[] memory _addresses, uint[] memory _amounts) public payable
    {
        for (uint i = 0; i < _addresses.length; i++) 
        {
            _safeERC20Transfer(_token, _addresses[i], _amounts[i]);

            emit MultiERC20Transfer(msg.sender,msg.value,_addresses[i],_amounts[i],_token);
        }
    }

    function _safeTransfer(address _to, uint _amount) internal 
    {
        require(_to != address(0));
        payable(_to).transfer(_amount);
    }

    function _safeERC20Transfer(ERC20 _token, address _to, uint _amount) internal 
    {
        require(_to != address(0));
        require(_token.transferFrom(msg.sender, _to, _amount));
    }
}