/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Etherum {
    //Variables
    string public name;
    string public symbol;
    uint256 public decimal;
    uint256 public totalSupply;

    //Keeping Track of balances and allowances approved
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    //Events
    event Transfer(address indexed sender, address indexed receiver, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimal, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    //@notice tranfer amount of tokens to an address
    //@param _receiver [receiver of the token]
    //@param _value [amount value of token to send]
    //@return success as true for transfer
    function transfer(address _receiver, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _receiver, _value);
        return true;
    }

    //@dev internal helper transfer function with safety checks
    //@param _sender [funds coming from the sender]
    //@param _receiver [receiver of the tokens]
    //@param _value [amount value of token to send]
    //Function called only once by this contract
    function _transfer(address _sender, address _receiver, uint _value) internal {
        require(_receiver != address(0));
        balanceOf[_sender] = balanceOf[_sender] - (_value);
        balanceOf[_receiver] = balanceOf[_receiver] + (_value);
        emit Transfer(_sender,_receiver,_value);
    }

    //@notice [Approve others to spend on an exchange]
    //@param _spender [allowed to spend and max amount to spend]
    //@param _value [amount value of token to send]
    //@return true [success once address approved]
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //@notice [transfer by approved person from original address within approved limits ]
    //@param _sender [address sending to and the amount to send]
    //@param _receiver [receiver of the token]
    //@param _value [amount value of token to send]
    //@return true [success once transfered from origin account]
    function transferFrom(address _sender, address _receiver, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_sender]);
        require(_value <= allowance[_sender][msg.sender]);
        allowance[_sender][msg.sender] = allowance[_sender][msg.sender] - (_value);
        _transfer(_sender,_receiver,_value);
        return true;
    }
}