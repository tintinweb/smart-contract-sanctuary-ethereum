/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity 0.8.10;

contract Asset {
    mapping(address => uint) balances;
    uint sum;

    function deposit(address[] calldata users, uint[] calldata deltas) external {
        for (uint i = 0; i< users.length; i++){
            balances[users[i]] += deltas[i];
        }
    }

    function execSum(address[] calldata users, uint count, bool rev) external {
        uint _sum;
        for (uint c = 0; c < count; c++){
            for (uint i = 0; i< users.length; i++){
                _sum += balances[users[i]];
            }
        }
        
        sum = _sum;
        if (rev){
            revert("revert things");
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