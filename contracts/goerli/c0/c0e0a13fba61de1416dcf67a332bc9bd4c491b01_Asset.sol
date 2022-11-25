/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

pragma solidity 0.8.10;

contract Asset {
    mapping(address => uint) balances;

    function deposit(address[] calldata users, uint[] calldata deltas) external {
        for (uint i = 0; i< users.length; i++){
            balances[users[i]] += deltas[i];
        }
    }

    function getBalances(address[] calldata users) public view returns (uint256[]memory) {
        uint[] memory result = new uint[](users.length);
        for (uint i = 0; i < users.length; i++) {
            result[i] = balances[users[i]];
        }
        return result;
    }
}