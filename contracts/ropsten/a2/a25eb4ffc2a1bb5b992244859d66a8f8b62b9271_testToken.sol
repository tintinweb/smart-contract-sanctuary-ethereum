/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity >=0.8.0;

contract testToken
{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) {
            _name = name;
            _symbol = symbol;
            _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint256) {
        return 0;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return 3000;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        revert();
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        revert();
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        revert();
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        revert();
    }

}