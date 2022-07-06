/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

pragma solidity ^0.5.1;

contract MyContract {
    mapping(address => uint256) public balances;
    address payable wallet;
    event Purchase(
        address indexed _buyer,
        uint256 _amount
    );

    constructor(address payable _wallet) public{
        wallet = _wallet;
    }

    function buyToken() public payable {
        balances[msg.sender] += 1;
        wallet.transfer(msg.value);
        emit Purchase(msg.sender, 1);
    }
}