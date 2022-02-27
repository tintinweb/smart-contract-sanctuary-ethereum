/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

pragma solidity ^0.8.10;

contract DogCoin {
    address public owner;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint256 public decimals;
    address[] public holders;
    mapping(address => uint256) public balances;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event UserAdded(address indexed _user);
    event UserRemoved(address indexed _user);


    constructor(string memory _name, string memory _symbol, uint256 _decimals){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 1000 * 10 ** decimals;
        balances[msg.sender] = totalSupply;
        holders.push(msg.sender);
        owner = msg.sender;
    }


    function balanceOf(address _address) external view returns (uint){
        return balances[_address];
    }

    function transfer(address _address, uint _amount) public returns (bool){
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_address] += _amount;
        checkForZeroBalance(msg.sender);
        checkIfNewHolder(_address);
        emit Transfer(msg.sender, _address, _amount);
        return true;
    }


    function destroyCoin() public {
        require(msg.sender == owner);
        selfdestruct(payable(address(msg.sender)));
    }

    function checkForZeroBalance(address _address) private {
        if (balances[_address] == 0) {
            removeFromArrayAndFillGaps(_address);}}

    function removeFromArrayAndFillGaps(address _address) private {
        for (uint i = 0; i < holders.length; i++) {
            if (holders[i] == _address) {
                delete holders[i];
                emit UserRemoved(_address);
                address lastItem = holders[holders.length - 1];
                holders[i] = lastItem;
                holders.pop();
                break;
            }
        }
    }

    function checkIfNewHolder(address _address) private returns (bool){
        for (uint i = 0; i < holders.length; i++) {
            if (holders[i] == _address) {
                return false;
            }
        }
        holders.push(_address);
        emit UserAdded(_address);
        return true;
    }
}