/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity ^0.4.0;

interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract vault{
    address private administrator;		// 管理员钱包地址

    event Create_RedEnvelope(uint _amount, address _token);
    event Claim_RedEnvelope(address _participant, address[] _tokens, uint[] _rewards, uint cost);
    event WithDraw_RedEnvelope(address _owner, address[] _tokens, uint[] _rewards, uint cost);
    
    constructor(address _administrator) public {
        administrator = _administrator;		// 设置管理员账号
    }

    function () public payable {
    }
    
    function create_RedEnvelope(uint _amount, address _token) public payable {
        require(
            _token != address(0),
            "You need to fill token address!"
        );

        if(msg.value > 0 && _token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            emit Create_RedEnvelope(msg.value, _token);
        } else {
            Token t = Token(_token);
            t.transferFrom(msg.sender,this,_amount);
            emit Create_RedEnvelope(_amount, _token);
        }
    }
 
    function claim(address _participant, address[] _tokens, uint[] _rewards, uint cost) public {
        require(
            msg.sender == administrator,
            "You don't have the permission to invoke this function!"
        );

        for (uint i = 0; i < _tokens.length; i++) {
            if(_tokens[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                _participant.transfer(_rewards[i]);
            } else {
                Token t = Token(_tokens[i]);
                 t.transfer(_participant, _rewards[i]);
            }
        }

        administrator.transfer(cost);
    
        emit Claim_RedEnvelope(_participant, _tokens,  _rewards, cost);
    }
    
    function withdraw(address _owner, address[] _tokens, uint[] _rewards, uint cost) public {
        require(
            msg.sender == administrator,
            "You don't have the permission to invoke this function!"
        );

        for (uint i = 0; i < _tokens.length; i++) {
            if(_tokens[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                _owner.transfer(_rewards[i]);
            } else {
                Token t = Token(_tokens[i]);
                 t.transfer(_owner, _rewards[i]);
            }
        }

        administrator.transfer(cost);

        emit WithDraw_RedEnvelope(_owner, _tokens, _rewards, cost);
    }
}