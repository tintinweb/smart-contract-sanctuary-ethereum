/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface IUniswap {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
        
        
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract PrintMoney {
    address owner;
    address uni_addr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswap uni = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IWETH private constant WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    
    event OwnerChanged(address old_owner, address new_owner);

    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setOwner(address _newOwner) onlyOwner external {
        require(_newOwner != address(0) && owner != _newOwner, "Owners same/zero");
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }
    
    function approveToken(address token) onlyOwner external {
        IERC20 erc20 = IERC20(token);
        erc20.approve(uni_addr, uint(-1)); // usdt six decimal would fail!
    }
    
    // assuming tokenIn always WETH
    function printMoney(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline,
        uint256 miner_share
    ) external {
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        require(amountIn <= _wethBalanceBefore, "Insufficient Balance");
        uni.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceBefore < _wethBalanceAfter, "No profit");
        uint256 profit = _wethBalanceAfter - _wethBalanceBefore;
        uint256 _ethBalance = address(this).balance;
        uint256 miner_take = profit * miner_share / 100;
        if (_ethBalance < miner_take) {
            WETH.withdraw(miner_take - _ethBalance);
        }
        block.coinbase.transfer(miner_take);
    }

    receive() external payable {}

    function withdraw(address to) onlyOwner external payable {
        payable(to).transfer(address(this).balance);
    }

    function withdrawToken(address token, address to) onlyOwner external {
        IERC20 erc20 = IERC20(token);
        uint bal = erc20.balanceOf(address(this));
        erc20.transfer(to, bal);
    }
}