pragma solidity ^0.8.0;

contract LIAMKING {
    string public name = "LIAMKING";
    string public symbol = "LIAM";
    uint256 public totalSupply = 1337;

    mapping (address => uint256) public balanceOf;
    address public owner;

    constructor() public {
        owner = 0x8D6314DbAb207d923058b12FCB66D92B49E8cbE7;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0, "transfer failed");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }
}