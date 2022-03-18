/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract DummyERC20Token {
    uint8 public immutable decimals;
    bytes32 private immutable _name;
    bytes32 private immutable _symbol;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) {
        _name = bytes32(bytes(name_));
        _symbol = bytes32(bytes(symbol_));
        decimals = decimals_;
        balanceOf[msg.sender] = initialSupply_;
        totalSupply = initialSupply_;
    }

    function name() public view returns (string memory) {
        return string(abi.encodePacked(_name));
    }

    function symbol() public view returns (string memory) {
        return string(abi.encodePacked(_symbol));
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address to_, uint256 amount_)
        public
        returns (bool success)
    {
        _transfer(msg.sender, to_, amount_);
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public returns (bool success) {
        _spendAllowance(from_, to_, amount_);
        _transfer(from_, to_, amount_);
        return true;
    }

    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal requireNotZeroAccount(from_) requireNotZeroAccount(to_) {
        if (amount_ > balanceOf[from_]) {
            revert NotEnoughBalance();
        }
        balanceOf[from_] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
    }

    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal {
        uint256 currentAllowance = allowance[owner_][spender_];
        if (amount_ > currentAllowance) {
            revert NotEnoughAllowance();
        }
        allowance[owner_][spender_] -= currentAllowance;
    }

    function _mint(address account_, uint256 amount_)
        internal
        requireNotZeroAccount(account_)
    {
        totalSupply += amount_;
        balanceOf[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    function _burn(address account_, uint256 amount_)
        internal
        requireNotZeroAccount(account_)
    {
        balanceOf[account_] -= amount_;
        totalSupply -= amount_;
        emit Transfer(account_, address(0), amount_);
    }

    modifier requireNotZeroAccount(address account_) {
        if (account_ == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    error ZeroAddress();
    error NotEnoughBalance();
    error NotEnoughAllowance();

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}