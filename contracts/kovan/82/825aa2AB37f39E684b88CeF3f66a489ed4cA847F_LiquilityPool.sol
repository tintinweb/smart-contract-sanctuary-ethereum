pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";

contract XlpToken {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 0;
    string public name = "XLP";
    string public symbol = "XLP";
    uint256 public decimal = 18;

    function mint(address to, uint256 value) internal {
        balances[to] += value;
        totalSupply += value;
    }

    function balanceOf(address _spender) public view returns (uint256) {
        return balances[_spender];
    }

    function burnFrom(address spender, uint256 _amount) internal {
        require(spender != address(0), "only diffirence address 0");
        require(_amount <= balances[spender], "not enoght amount");
        balances[spender] -= _amount;
        totalSupply -= _amount;
        
        emit Transfer(spender, address(0), _amount);
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// liquidity - pool here

contract LiquilityPool is XlpToken {
    IERC20 TokenA;
    IERC20 TokenB;
    uint256 public k;
    uint256 public fisrtMintXlp = 10**3 * 10**18;

    constructor(address token1, address token2) {
        TokenA = IERC20(token1);
        TokenB = IERC20(token2);
    }

    function addLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _maxAmount1
    ) public {
        uint256 amount1 = _amount0 * TokenB.balanceOf(address(this));
        require(
            amount1 <= _maxAmount1 * TokenA.balanceOf(address(this)),
            "error in add lp"
        );
        amount1 = amount1 == 0 ? _amount1 : amount1 / TokenA.balanceOf(address(this));
        uint256 spendXlp = k == 0 ? fisrtMintXlp : (totalSupply * _amount0) / TokenA.balanceOf(address(this));
        TokenA.transferFrom(msg.sender, address(this), _amount0);
        TokenB.transferFrom(msg.sender, address(this), amount1);
        mint(msg.sender, spendXlp);
        k = TokenB.balanceOf(address(this)) * TokenA.balanceOf(address(this));

        emit AddLiquidity(msg.sender, _amount0, amount1);
    }

    function swap(
        address _token0,
        address _token1,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) public {
        uint256 spend = k /
            (IERC20(_token0).balanceOf(address(this)) + _amountIn);
        uint256 amountOut = IERC20(_token1).balanceOf(address(this)) - spend;
        require(amountOut >= _minAmountOut, "err in swap");
        IERC20(_token0).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_token1).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, _amountIn);
    }

    function removeLiquidity(uint256 _amountLp,uint256 _minAmountA,uint256 _minAmountB) public {
        require(balanceOf(msg.sender) >= _amountLp, "err1 in remove lp");
        uint256 amountA =  _amountLp * TokenA.balanceOf(address(this)) / totalSupply;
        uint256 amountB = _amountLp * TokenB.balanceOf(address(this)) / totalSupply;
        require(amountA >= _minAmountA && amountB >= _minAmountB ,'err2 in remove lp');
        TokenA.transfer(msg.sender, amountA);
        TokenB.transfer(msg.sender, amountB);
        burnFrom(msg.sender, _amountLp);
        k = TokenA.balanceOf(address(this)) * TokenB.balanceOf(address(this));

        emit RemoveLiquidity(msg.sender, _amountLp);
    }

    event AddLiquidity(address indexed from, uint256 amount0, uint256 amount1);
    event RemoveLiquidity(address indexed from, uint256 amountLP);
    event Swap(address indexed from, uint256 amount);
}

pragma solidity >= 0.7.0 <0.9.0;

interface IERC20{

    
    function mint(address to,uint value) external ;
    function transfer(address to,uint value) external ;
    function transferFrom(address from,address to,uint value) external ;
    function balanceOf(address owner) external view returns(uint);
    function approve(address spender ,uint value) external ;
}