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

    function transfer(address to, uint256 value) public {
        require(balances[msg.sender] >= value, "not enought token");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public {
        require(balanceOf(from) >= value, "not enought token");
        require(
            allowance[from][msg.sender] >= value,
            "not enought token allower"
        );
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
    }

    function balanceOf(address _spender) public view returns (uint256) {
        return balances[_spender];
    }

    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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

// liquidity - pool here5

contract LiquilityPool is XlpToken {
    IERC20 DAI;
    IERC20 ETH;
    address addrToken0;
    address addrToken1;
    uint256 public k;
    uint256 public fisrtMintXlp = 10**3 * 10**18;
    uint256 public slippage = 2; // truot gia toi da khi add liquidate, remove liquidate

    constructor(address token1, address token2) {
        addrToken0 = token1;
        addrToken1 = token2;
        DAI = IERC20(token1);
        ETH = IERC20(token2);
        k = 0;
    }

    function addLiquidity(uint256 _amount1, uint256 _amount2) public  checkAmountInput(_amount1,_amount2) {
        //amount1 DAI
        //amount2 ETH
        // handleLogic
        // first time
        if (k == 0) {
            DAI.transferFrom(msg.sender, address(this), _amount1);
            ETH.transferFrom(msg.sender, address(this), _amount2);
            k = _amount1 * _amount2;
            mint(msg.sender, fisrtMintXlp);
        } else {
            //calulator
            DAI.transferFrom(msg.sender, address(this), _amount1);
            ETH.transferFrom(msg.sender, address(this), _amount2);
            uint256 amountXlp = (totalSupply * _amount2) /
                ETH.balanceOf(address(this));
            mint(msg.sender, amountXlp);
            k = ETH.balanceOf(address(this)) * DAI.balanceOf(address(this));
        }
        emit AddLiquidity(msg.sender, _amount1, _amount2);
    }

    function swap(
        address _token0,
        address _token1,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) public {
        if (_token0 == addrToken0) {
            // swap dai to eth
            uint256 spendETH = k / (DAI.balanceOf(address(this)) + _amountIn);
            DAI.transferFrom(msg.sender, address(this), _amountIn);
            uint256 amountOut = ETH.balanceOf(address(this)) - spendETH;
            require(
                amountOut >= _minAmountOut,
                "amount out not larger min amount out"
            );
            ETH.transfer(msg.sender, amountOut);
            emit SwapDAItoETH(msg.sender, _amountIn);
        }
        if (_token1 == addrToken0) {
            // swap eth to dai
            uint256 spendDAI = k / (ETH.balanceOf(address(this)) + _amountIn);
            ETH.transferFrom(msg.sender, address(this), _amountIn);
            uint256 amountOut = DAI.balanceOf(address(this)) - spendDAI;
            require(
                amountOut >= _minAmountOut,
                "amount out not larger min amount out"
            );
            DAI.transfer(msg.sender, amountOut);
            emit SwapDAItoETH(msg.sender, _amountIn);
        }
    }

    function removeLiquidity(uint256 _amount1, uint256 _amount2) public  checkAmountInput(_amount1,_amount2){
        //amount1 DAI
        //amount2 ETH
        require(k != 0, "poll is empty");
        require(
            (balances[msg.sender] * DAI.balanceOf(address(this))) /
                totalSupply >=
                _amount1,
            "not enoght amount"
        );
        DAI.transfer(msg.sender, _amount1);
        ETH.transfer(msg.sender, _amount2);
        uint256 spendBurn = (_amount1 * totalSupply) /
            DAI.balanceOf(address(this));
        burnFrom(msg.sender, spendBurn);
        k = ETH.balanceOf(address(this)) * DAI.balanceOf(address(this));
    }
    
    modifier checkAmountInput(uint256 _amount1, uint256 _amount2) {
         uint256 radio = (DAI.balanceOf(address(this)) * 1e12) /
            ETH.balanceOf(address(this));
        uint256 radioInput = (_amount1 * 1e12) / _amount2;
        require(
            (radio * (1 - slippage)) / 100 <= radioInput &&
                radioInput <= (radio * (1 + slippage)) / 100,
            "amount input not radio in pool"
        );
        _; 
    }

    event AddLiquidity(address indexed from, uint256 amount1, uint256 amount2);
    event RemoveLiquidity(
        address indexed from,
        uint256 amount1,
        uint256 amount2
    );
    event SwapDAItoETH(address indexed from, uint256 amount);
    event SwapETHtoDAI(address indexed from, uint256 amount);
}

pragma solidity >= 0.7.0 <0.9.0;

interface IERC20{

    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address indexed owner,address indexed spender,uint value);
    
    function mint(address to,uint value) external ;
    function transfer(address to,uint value) external ;
    function transferFrom(address from,address to,uint value) external ;
    function balanceOf(address owner) external view returns(uint);
    function approve(address spender ,uint value) external ;
}