// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ndeteToken {
    // state variables
    string constant NAME = "NDETEMBEA"; // name of our token
    string constant SYMBOL = "NDETE"; // symblo of the token
    address deployer;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    // events
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);

    constructor() {
        deployer = msg.sender;
        balances[deployer] = 10000000 * 1e8;
    }

    // return the name of the token
    function name() public pure returns (string memory) {
        return NAME;
    }

    // returns the symbol of the token
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    // decimals returns the number of decimals the token uses

    function decimals() public pure returns (uint256) {
        return 8;
    }

    // function tota suppliy
    function totalSupply() public pure returns (uint256) {
        return 1000000 * 1e8;
    }

    // function balance of
    function balanceOf(address _ower) public view returns (uint256) {
        return balances[_ower];
    }

    // transfer
    /**transfer _value amount ot tokes to address _to and musst fire the transfer event .
     * the function should throw if the message caller
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] > _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
        }
        return true;
    }

    // transfer from _value amount of tokens from address _from to address _to, and MUST fire the TRANSER event
    /**
     * the transfre fom is used to withdraw workflow, allowing contracts
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (balances[_from] < _value) return false;
        if (allowances[_from][msg.sender] < _value) return false;
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * approve
     * allows _spender to withdraw from your account multiple times,
     *
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    mapping(uint256 => bool) blockMined;
    uint256 totalMinted = 1000000 * 1e8; //1M that has been minted to the deployer in constructor()

    function mine() public returns (bool success) {
        if (blockMined[block.number]) {
            return false;
        }
        balances[msg.sender] = balances[msg.sender] + 10 * 1e8;
        totalMinted = totalMinted + 10 * 1e8;
        return true;
    }
}