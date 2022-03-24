/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity ^0.5.17;

contract mytokencontract {
    mapping(address => uint256) public balances;
    address payable wallet;

    constructor(address payable _wallet) public {
        wallet = _wallet;
    }

    function buyToken() public payable {
        balances[msg.sender] += 1;
        wallet.transfer(msg.value);
    }
}