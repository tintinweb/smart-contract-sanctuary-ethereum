/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract tocken_test{
    uint256 public totalsupply = 10000;
    uint256 public decimal = 18;
    string public symbol = "SEMI";
    string public name = "Semiliquid";
    address public owner;
    mapping(address => uint256) Balance;
    mapping(address => mapping(address => uint256)) exchange;
    event approve(address indexed, address indexed, uint256);

    constructor(){
        owner = msg.sender;
        Balance[owner] = totalsupply;
    }

    function transfer(address _to, uint256 amount) public {
        address _from = msg.sender;
        require(_from!=_to,"from cant be equal to to address");
        require(Balance[_from]>=amount,"insufficient tocken balance");
        Balance[_from] = Balance[_from] - amount;
        Balance[_to] = Balance[_to] + amount;
    }

    function getBalance(address _address) public view returns(uint256){
        return(Balance[_address]);
    }

    function approved(address _to, uint _no) external returns(bool){
        exchange[msg.sender][_to] = _no;
        emit approve(msg.sender, _to , _no);
        return(true);
    }

    function transaction(address _from, address _to, uint256 _no) external returns(bool){
        require(Balance[_from]>=_no);
        require(exchange[_from][msg.sender]>=_no);
        exchange[_from][msg.sender] = exchange[_from][msg.sender] - _no;
        transfer(_to, _no);
        return(true);
    }


}