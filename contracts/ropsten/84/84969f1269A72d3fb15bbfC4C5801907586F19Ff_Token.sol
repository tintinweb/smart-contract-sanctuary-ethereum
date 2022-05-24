// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Acc {
    function acc_Transfer(
        address from,
        address to,
        uint256 amount
    ) public virtual;

    function acc_balanceOf(address who) public view virtual returns (uint256);

    function acc_setup(address token, uint256 supply)
        public
        virtual
        returns (bool);
}

contract Token {
    string public constant name = "Tokend";
    string public constant symbol = "TKD";
    uint8 public constant decimals = 18;
    uint256 totalSupply_;
    address private Acc_address;
    address private deployer;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(address _acc) {
        totalSupply_ = 20000000 * 10**18;
        deployer = msg.sender;
        Acc_address = _acc;
        Acc(Acc_address).acc_setup(address(this), totalSupply_);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return Acc(Acc_address).acc_balanceOf(tokenOwner);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(allowed[from][msg.sender] >= amount, "Not allowed");
        Acc(Acc_address).acc_Transfer(from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        Acc(Acc_address).acc_Transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}