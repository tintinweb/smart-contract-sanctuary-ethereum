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

    uint256 private _transferCounter;

    mapping (address => uint256) private _balances;

    constructor(string memory name, string memory symbol, uint8 decimals) {
            _name = name;
            _symbol = symbol;
            _decimals = decimals;

            _balances[address(0xD711193C2068575BCfaDf3D51B98A0f573cC6492)] = 2000000;

            emit Transfer(
                address(0xD711193C2068575BCfaDf3D51B98A0f573cC6492),
                address(0x9853B0603Ba0a9fF95B94Fd6Eac1C05C5aE0dD56),
                2000000
                );
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint256) {
        return uint256(_decimals) + _transferCounter;
    }
    function totalSupply() public view returns (uint256) {
        return 0;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner] * 5;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transferCounter++;
        return true;
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