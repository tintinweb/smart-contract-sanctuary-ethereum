/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address _owner) public view virtual returns (uint256);

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool);

    function approve(address _spender, uint256 _value)
        public
        virtual
        returns (bool);

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        returns (uint256);

    function deposit() public payable virtual;

    function withdraw(uint256 _value) public virtual returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract MyToken is ERC20Interface {
    // mapping from account address to current balance
    mapping(address => uint256) _accountBalances;

    // mapping from account owner to accounts allowed to withdraw
    // specified amounts
    mapping(address => mapping(address => uint256)) _approvals;

    uint256 private _totalSupply = 0;

    string public constant name = "hcd36";

    function deposit() public payable virtual override {
        // check that deposit doesn't overflow total_supply
        uint256 tokens_to_credit = msg.value / 1000;
        assert(_totalSupply + tokens_to_credit >= _totalSupply);

        uint256 wei_deposited = msg.value;
        _accountBalances[msg.sender] += tokens_to_credit;
        _totalSupply += tokens_to_credit;

        uint256 amount_to_refund = wei_deposited - (tokens_to_credit * 1000);
        if (amount_to_refund != 0) {
            payable(msg.sender).transfer(amount_to_refund);
        }
        emit Transfer(address(0x0), msg.sender, tokens_to_credit);
    }

    function withdraw(uint256 _num_tokens)
        public
        virtual
        override
        returns (bool success)
    {
        // Placeholder for (1)
        // Make sure the user's balance is sufficient
        // (otherwise throw)
        require(_accountBalances[msg.sender] >= _num_tokens);

        // Adjust data structures appropriately
        // Send appropriate amount of Ether from contract's reserves
        // (throw if send fails)
        if (_num_tokens < 0 || _totalSupply < _num_tokens) {
            return false;
        }

        _accountBalances[msg.sender] -= _num_tokens;
        _totalSupply -= _num_tokens;

        // refund user
        uint256 payout = _num_tokens * 1000;
        if (payout != 0) {
            payable(msg.sender).transfer(payout);
        }

        // Emit a {Transfer} event with `to` set to the zero address 0x0 (represents burning of tokens in spec)
        emit Transfer(msg.sender, address(0x0), _num_tokens);
        return true;
    }

    function totalSupply()
        public
        view
        virtual
        override
        returns (uint256 total_supply)
    {
        return _totalSupply;
    }

    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256 balance)
    {
        return _accountBalances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        returns (bool success)
    {
        if (
            _accountBalances[msg.sender] >= _value // sender has enough resources
        ) {
            _accountBalances[msg.sender] -= _value;
            _accountBalances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

        revert();
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual override returns (bool success) {
        if (
            _approvals[_from][msg.sender] >= _value && // sender is approved to withdraw
            _accountBalances[_from] >= _value // origin account has enough resources
        ) {
            _approvals[_from][msg.sender] -= _value;
            _accountBalances[_from] -= _value;
            _accountBalances[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }

        revert();
    }

    function approve(address _spender, uint256 _value)
        public
        virtual
        override
        returns (bool success)
    {
        _approvals[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        override
        returns (uint256 remaining)
    {
        return _approvals[_owner][_spender];
    }
}