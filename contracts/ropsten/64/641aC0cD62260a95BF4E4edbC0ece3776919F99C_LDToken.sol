/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract LDToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 _totalSupply;

    string public _name;
    string public _symbol;
    

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 amount);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _check_non_zero_address(address _address) private pure {
        require(_address != address(0), "ERC20: zero address not applicalble");
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        _check_non_zero_address(_from);
        _check_non_zero_address(_to);
        require(
            _balances[_from] >= _amount,
            "LDToken: sender does not have enough balance"
        );
        unchecked{
            _balances[_from] -= _amount;
        }
        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    

    /**
     * Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
     *
     * The transferFrom method is used for a withdraw workflow,
     * allowing contracts to transfer tokens on your behalf.
     * This can be used for example to allow a contract to transfer tokens on
     * your behalf and/or to charge fees in sub-currencies.
     * The function SHOULD throw unless the _from account has deliberately
     * authorized the sender of the message via some mechanism.
     *
     * Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_allowances[_from][msg.sender] >= _value,
                "LDToken: spender has no approval");
        unchecked {
            _approve(_from, msg.sender, _allowances[_from][msg.sender] - _value);
        }
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Allows _spender to withdraw from your account multiple times,
     * up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value.
     *
     * NOTE: To prevent attack vectors like the one described here and discussed here,
     * clients SHOULD make sure to create user interfaces in such a way
     * that they set the allowance first to 0 before setting it to another value for the same spender.
     * THOUGH The contract itself shouldn’t enforce it,
     * to allow backwards compatibility with contracts deployed before.
     */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount)
        internal
    {
        require(
            _owner != address(0),
            "LDToken: approve from the zero address"
        );
        require(
            _spender != address(0),
            "LDToken: approve to zero address"
        );
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * Returns the amount which _spender is still allowed to withdraw from _owner.
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[_owner][_spender];
    }

    function _mint(address account, uint256 amount) external virtual {
        _balances[account] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }
}