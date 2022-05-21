/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity ^0.8.0;

contract HelicopterCoin {
    uint256 internal launchTime;
    mapping (address => int256) internal balanceDelta;
    mapping (address => mapping (address => uint256)) public allowance;

    string public constant name = "Helicopter";
    string public constant symbol = "HELI";
    uint8 public constant decimals = 6;

    constructor () {
        launchTime = block.timestamp;
    }

    function totalSupply () public view returns (uint256) {
        return (block.timestamp - launchTime) << 160;
    }

    function balanceOf (address owner) public view returns (uint256) {
        return uint256 (int256 (block.timestamp - launchTime) + balanceDelta [owner]);
    }

    function transfer (address to, uint256 amount) public returns (bool) {
        int256 fromBalanceDelta = balanceDelta [msg.sender];
        if (amount > uint256 (int256 (block.timestamp - launchTime) + fromBalanceDelta)) return false;
        else {
            balanceDelta [msg.sender] = fromBalanceDelta - int256 (amount);
            balanceDelta [to] += int256 (amount);
            emit Transfer (msg.sender, to, amount);
            return true;
        }
    }

    function transferFrom (address from, address to, uint256 amount) public returns (bool) {
        uint256 fromAllowance = allowance [from][msg.sender];
        if (amount > fromAllowance) return false;
        else {
            int256 fromBalanceDelta = balanceDelta [from];
            if (amount > uint256 (int256 (block.timestamp - launchTime) + fromBalanceDelta)) return false;
            else {
                allowance [from][msg.sender] = fromAllowance - amount;
                balanceDelta [from] = fromBalanceDelta - int256 (amount);
                balanceDelta [to] += int256 (amount);
                emit Transfer (from, to, amount);
                return true;
            }
        }
    }

    function approve (address spender, uint256 amount) public returns (bool) {
        allowance [msg.sender][spender] = amount;
        emit Approval (msg.sender, spender, amount);
        return true;
    }

    event Transfer (address indexed from, address indexed to, uint256 amount);
    event Approval (address indexed owner, address indexed spender, uint256 amount);
}