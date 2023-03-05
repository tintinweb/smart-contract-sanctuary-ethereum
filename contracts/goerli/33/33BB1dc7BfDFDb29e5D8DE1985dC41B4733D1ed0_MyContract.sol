/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

pragma solidity 0.8.18;

contract MyContract {
    mapping(address => uint256) public balance;

    constructor() {
        balance[msg.sender] = 100;
    }

    function transfer(address _to, uint256 _amount) public {
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
    }

    function someRandomCrypticFunctionName(address _addr) public view returns (uint256)
    {
        return balance[_addr];
    }
}