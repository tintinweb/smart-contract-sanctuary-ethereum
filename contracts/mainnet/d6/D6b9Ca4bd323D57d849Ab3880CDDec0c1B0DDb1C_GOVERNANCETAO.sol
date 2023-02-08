//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";

contract GOVERNANCETAO is IERC20 {

    // master contract to inflate supply
    address public immutable master;

    // total supply
    uint256 private _totalSupply;

    // token data
    string private constant _name = 'GOVERNANCE TAO';
    string private constant _symbol = 'GTAO';
    uint8  private constant _decimals = 15;

    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor(address master_) {

        // set master
        master = master_;

        // emit transfer to show token on explorer
        emit Transfer(address(0), msg.sender, 0);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(
            _allowances[sender][msg.sender] >= amount,
            'Insufficient Allowance'
        );
        _allowances[sender][msg.sender] -= amount;
        return _transferFrom(sender, recipient, amount);
    }

    function burn(uint256 amount) external returns (bool) {
        return _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        require(
            _allowances[account][msg.sender] >= amount,
            'Insufficient Allowance'
        );
        _allowances[account][msg.sender] -= amount;
        return _burn(account, amount);
    }

    function mint(address account, uint256 amount) external returns (bool) {
        require(msg.sender == master, 'Only Master');
        require(
            account != address(0),
            'Zero Recipient'
        );

        // increment sender balance
        _balances[account] += amount;
        _totalSupply += amount;

        // emit transfer
        emit Transfer(address(0), account, amount);
        return true;
    }

    function withdraw(address token) external {
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(master, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function withdrawETH() external {
        (bool s,) = payable(master).call{value: address(this).balance}("");
        require(s);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(
            recipient != address(0),
            'Zero Recipient'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            amount <= balanceOf(sender),
            'Insufficient Balance'
        );
        
        // decrement sender balance
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        // emit transfer
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal returns (bool) {
        require(
            account != address(0),
            'Zero Address'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            amount <= balanceOf(account),
            'Insufficient Balance'
        );
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    receive() external payable {}
}