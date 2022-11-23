/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.6;

contract CafeToken {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public totalSupply;

    string public name = "Cafe Token";
    string public symbol = "Cafe";
    uint8 public decimals = 18;

    constructor(address minter) {
        _mint(minter, 5_000_000_000 * 10**18);
        _mint(address(this), 95_000_000_000 * 10**18);
    }

    function transfer(address recipient_, uint256 amount_)
        public
        returns (bool)
    {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function allowance(address owner_, address spender_)
        public
        view
        returns (uint256)
    {
        return _allowances[owner_][spender_];
    }

    function approve(address spender_, uint256 amount_)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function transferFrom(
        address sender_,
        address recipient_,
        uint256 amount_
    ) public virtual returns (bool) {
        _transfer(sender_, recipient_, amount_);
        uint256 currentAllowance = _allowances[sender_][msg.sender];
        require(
            currentAllowance >= amount_,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender_, msg.sender, currentAllowance - amount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedValue_)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender_,
            _allowances[msg.sender][spender_] + addedValue_
        );
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender_];
        require(
            currentAllowance >= subtractedValue_,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender_, currentAllowance - subtractedValue_);

        return true;
    }

    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal virtual {
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(
            recipient_ != address(0),
            "ERC20: transfer to the zero address"
        );

        uint256 senderBalance = balanceOf[sender_];
        require(
            senderBalance >= amount_,
            "ERC20: transfer amount exceeds balance"
        );
        balanceOf[sender_] = senderBalance - amount_;
        balanceOf[recipient_] += amount_;

        emit Transfer(sender_, recipient_, amount_);
    }

    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function _mint(address account_, uint256 amount_) private {
        require(account_ != address(0), "ERC20: mint to the zero address");
        totalSupply += amount_;
        balanceOf[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    function faucet() public returns (bool) {
        require(!alreadyFauceted[msg.sender], "Cannot faucet twice");
        alreadyFauceted[msg.sender] = true;
        _transfer(address(this), msg.sender, 10_000_000 * 10**18);
        return true;
    }

    mapping(address => bool) private alreadyFauceted;
}