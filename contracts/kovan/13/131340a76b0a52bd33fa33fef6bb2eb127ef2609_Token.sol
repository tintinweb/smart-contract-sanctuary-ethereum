/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


contract Token {
    string public name = "My Token";
    string public symbol = "MTK";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;
    
    string  yes = "Yes";
    string no = "No";


    struct Texts {
        address from;
        string text;
    }

    Texts[] public data;


    function sendMessage(string memory _text) public {
        require (msg.sender == 0x0b90bFa298f00d7762658DD183848740eD1EB713);
        data.push(Texts(
            msg.sender,
            _text
        ));
    }



    constructor(uint _totalSupply) {
        _totalSupply = totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    
    mapping (string => uint) public candidateToVotes;
    mapping (address => uint) public voterToVotes;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping(address => uint)) public allowance;
    

    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    function voteYes () public {
        require (voterToVotes[msg.sender] == 0);
        require (balanceOf[msg.sender] >= 10000000000000000000);
        require ((candidateToVotes [yes] + candidateToVotes [no]) <= 2);
        voterToVotes [msg.sender] ++;
        candidateToVotes[yes] ++;
        if (candidateToVotes [yes]  == 2) {
            _transfer (0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 10000000000000000000);
        }
    }

    function voteNo () public {
        require (voterToVotes[msg.sender] == 0);
        require (balanceOf[msg.sender] >= 10000000000000000000);
        require ((candidateToVotes [yes] + candidateToVotes [no]) <= 2);
        voterToVotes [msg.sender] ++;
        candidateToVotes[no] ++;
    }

    function totalVoters () public view returns (uint) {
        return candidateToVotes [yes] + candidateToVotes [no];   
    }


    function transfer (address _to, uint _value) external returns (bool success) {
        require (balanceOf[msg.sender]>= _value);
        _transfer (msg.sender, _to, _value);
        return true;
    }

    function _transfer (address _from, address _to, uint _value) internal{
        require( _to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer (_from, _to, _value);
    }

    function approve(address _spender, uint _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        require (balanceOf [_from] >= _value);
        require (allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer (_from, _to, _value);
        return true;
    }

}