// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(uint256 amount) external;
}

contract FARM {

    IERC20 public stakingToken;
    uint256 public _totalSupply;
    mapping(address => uint256) private _balances;

    constructor (
        address _stakingToken,
        address[] memory _owners
    ){
        stakingToken = IERC20(_stakingToken);
        for (uint i = 0; i < _owners.length; i++) {
            _balances[_owners[i]] = (10 ** 5) * (10 ** 18);
            _totalSupply += (10 ** 5) * (10 ** 18);
        }
        stakingToken.mint(_totalSupply);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount)
    external
    {
        _totalSupply = _totalSupply + (amount);
        _balances[msg.sender] = _balances[msg.sender] + (amount);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
    external
    {
        _totalSupply = _totalSupply - (amount);
        _balances[msg.sender] = _balances[msg.sender] - (amount);
        stakingToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
    external
    {
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
}