//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";

contract SkyToken is IERC20, Ownable {

    // total supply
    uint256 private _totalSupply = 200_000;

    // token data
    string private constant _name = "Squish Bucks";
    string private constant _symbol = "SQUISH";
    uint8  private constant _decimals = 0;

    // balances
    mapping (address => uint256) private _balances;

    constructor(address supplyWallet) {
        _balances[supplyWallet] = _totalSupply;
        emit Transfer(address(0), supplyWallet, _totalSupply);

        changeOwner(supplyWallet);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address, address) external pure override returns (uint256) { return 0; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256) public override returns (bool) {
        emit Approval(msg.sender, spender, 0);
        return false;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender == msg.sender, 'Use transfer()');
        return _transferFrom(sender, recipient, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function claim(uint256 amount) external {
        _claim(msg.sender, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(
            recipient != address(0),
            'Zero Recipient'
        );
        require(
            amount <= _balances[sender],
            'Insufficient Balance'
        );
        
        // reassign balances
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        // emit transfer
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function withdraw(address token) external onlyOwner {
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function withdrawETH() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function _burn(address account, uint256 amount) internal {
        require(
            account != address(0),
            'Zero Address'
        );
        require(
            amount <= _balances[account],
            'Insufficient Balance'
        );
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(
            to != address(0),
            'Zero Address'
        );
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _claim(address user, uint256 amount) internal {
        require(
            amount <= _balances[user],
            'Insufficient Balance'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        
        // eth balance
        uint256 balance = address(this).balance;
        require(
            balance > 0,
            'Zero ETH To Claim'
        );

        // ETH to claim
        uint256 toClaim = amount * ( balance / _totalSupply );

        // burn tokens from sender
        _burn(user, amount);

        // send eth to caller
        (bool s,) = payable(user).call{value: toClaim}("");
        require(s, 'Failure On ETH Transfer');
    }

    function pendingClaim(address user) external view returns (uint256) {
        if (_balances[user] == 0) { return 0; }
        return _balances[user] * ( address(this).balance / _totalSupply );
    }

    receive() external payable {}
}