//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "IERC20.sol";
import "Ownable.sol";

contract FirstToken is IERC20, Ownable {
    string public name;
    string public symbol;
    uint256 public totalTokenSupply;
    bytes32 private _password;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) private _allownces;

    event AllowanceIncrease(address, address, uint256);
    event AllowanceDecrease(address, address, uint256);
    event TransferFrom(address spender, address from, address to, uint amount);

    constructor(
        string memory name_,
        string memory sym,
        uint256 totalTokenSupply_,
        bytes32 password
    ) {
        name = name_;
        symbol = sym;
        totalTokenSupply = totalTokenSupply_;
        balances[msg.sender] = totalTokenSupply_;
        _password = password;

        emit Transfer(address(0), msg.sender, totalTokenSupply_);
    }

    function totalSupply() public view override returns (uint256) {
        return totalTokenSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool){
        require(_allownces[from][msg.sender] >= amount, "insufficient allowance");
        _transfer(from,to,amount);
        emit TransferFrom(msg.sender, from, to, amount);
        return true;
    }
    

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Cannot transfer from a zero address");
        require(recipient != address(0), "Cannot transfer to a zero address");
        require(balances[sender] >= amount, "Insufficient balance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function getTokens(string memory password) public {
        require(bytes32(bytes(password)) == _password, "Invalid password");
        _transfer(owner(), msg.sender, 5);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allownces[owner][spender];
    }

    function increaseAllowance(address spender, uint256 amount) public {
        require(spender != address(0), "Address cannot be zero!");
        _allownces[msg.sender][spender] += amount;
        emit AllowanceIncrease(msg.sender, spender, amount);
    }

    function decreaseAllowance(address spender, uint256 amount) public {
        require(spender != address(0), "Address cannot be zero!");
        _allownces[msg.sender][spender] -= amount;
        emit AllowanceDecrease(msg.sender, spender, amount);
    }

    function burnToken(uint256 amount) public {
        require(amount <= balances[owner()], "Insufficient Balance!");
        balances[owner()] -= amount;
        totalTokenSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allownces[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function selfdestructContract() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    fallback() external payable {}

    receive() external payable {}
}