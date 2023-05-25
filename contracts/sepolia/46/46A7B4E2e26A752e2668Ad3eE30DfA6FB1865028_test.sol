/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

pragma solidity ^0.8.20;

contract test {
    address public contractOwner;
    mapping(address => uint256) public walletBalances;

    constructor() {
        contractOwner = msg.sender;
    }

    function buyTokens(address _contributor) external payable {

        uint256 amount = msg.value;
        walletBalances[_contributor] += amount;
        payable(contractOwner).transfer(amount);
    }

    function claimPug() external  {

    }
}