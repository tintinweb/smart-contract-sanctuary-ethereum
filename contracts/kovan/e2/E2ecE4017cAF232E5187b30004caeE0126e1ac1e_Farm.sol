pragma solidity ^0.8.10;

import "./Token1.sol";
import "./Token2.sol";
import "./Pair.sol";
import "./Ownable.sol";

contract Farm is Ownable {

    struct UserInfo{
        uint256 stakingBalance;
        uint256 startTime;
        uint256 rewordsBalance;
    }
    mapping(address => UserInfo) public userInfo;

    string public name = "MTKN1 Farm";

    Token1 public rewordsToken;
    address public LPtoken;

    constructor(address _rewordsToken, address _LPtoken) {
        rewordsToken = Token1(_rewordsToken);
        LPtoken = _LPtoken;
    }

    uint256 timeLock = 600;
    uint256 proccentRewards = 200;

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event Claim(address indexed to, uint256 amount);

    function getStakingBalance() public view returns (uint){
        return userInfo[msg.sender].stakingBalance;
    }

    function getStartTime() public view returns (uint){
        return userInfo[msg.sender].startTime;
    }

    function getRewordsTokenBalance() public view returns (uint){
        return userInfo[msg.sender].rewordsBalance;
    }

    function getProccentRewards() public view returns (uint) {
        return proccentRewards;
    }

    function getTimeLock() public view returns (uint) {
        return timeLock;
    }

    function changeProccentRewards(uint256 newProccentRewards) public onlyOwner {
        proccentRewards = newProccentRewards;
    }

    function changeTimeLock(uint256 newTime) public onlyOwner {
        timeLock = newTime;
    }


    function stake(uint256 amount) public {
        require(amount > 0 && IERC20(LPtoken).balanceOf(msg.sender) >= amount, "You cannot stake zero tokens");
        
        if(userInfo[msg.sender].startTime != 0) {
            uint256 tokenReward = totalReward(msg.sender);
            userInfo[msg.sender].rewordsBalance += tokenReward;
        }

        IERC20(LPtoken).transferFrom(msg.sender, address(this), amount);
        userInfo[msg.sender].stakingBalance += amount;
        userInfo[msg.sender].startTime = block.timestamp;
        emit Stake(msg.sender, amount);
    }

    function timeStaking(address user) public view returns(uint256) {
        uint totalTime = block.timestamp - userInfo[user].startTime;
        return totalTime;
    }

    function totalReward(address user) public view returns(uint256) {
        uint256 amountReward = timeStaking(user) / timeLock;
        uint tokenReward = (userInfo[user].stakingBalance * amountReward * proccentRewards / 1000);
        return tokenReward; 
    }

    function unstake(uint256 amount) public {
        require(
            timeStaking(msg.sender) >= timeLock &&
            userInfo[msg.sender].stakingBalance >= amount,
            "Tokens is locked"
        );

        uint totalReward = totalReward(msg.sender);
        userInfo[msg.sender].startTime = block.timestamp;

        userInfo[msg.sender].stakingBalance -= amount;

        IERC20(LPtoken).transfer(msg.sender, amount);
        userInfo[msg.sender].rewordsBalance += totalReward;

        emit Unstake(msg.sender, amount);
    }

    function claim() public {
        require(totalReward(msg.sender) > 0 || userInfo[msg.sender].rewordsBalance > 0, "You dont have reward tokens");
        require(timeStaking(msg.sender) >= timeLock, "Your tokens are locked, the staking time has not passed yet");
        uint256 toClaim = totalReward(msg.sender);
        
        if(userInfo[msg.sender].rewordsBalance != 0) {
            uint unclaimBalance = userInfo[msg.sender].rewordsBalance;
            toClaim += unclaimBalance;
            userInfo[msg.sender].rewordsBalance = 0;
        }

        userInfo[msg.sender].startTime = block.timestamp;
        rewordsToken.transfer(msg.sender, toClaim);
        emit Claim(msg.sender, toClaim);
    } 

}

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
//import '@openzeppelin/contracts/access/AccessControl.sol';

contract Token1 is IERC20, Ownable {
    string public constant name = 'MyToken1';
    string public constant symbol = 'MTKN1';
    uint32 public constant decimals = 18;

    //bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowances;

    

    constructor() {
        mint(msg.sender, 10**decimals * 10000);
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        // require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(amount >= 0);
        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function totalSupply() public view returns (uint256) {
       return _totalSupply;
    }

    function balanceOf(address account) external view returns(uint256){
        return balances[account];
    }

    function transfer(address to, uint amount) public returns (bool) {
        require(balances[msg.sender] >= amount, 'Not enough tokens');
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint){
        return allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 amount) public returns(bool) {
        require(spender != address(0) && amount >= 0);
        allowances[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

        function decreaseAllowance(address spender, uint256 amount) public returns(bool) {
        require(spender != address(0) && allowances[msg.sender][spender] >= amount && amount >= 0);
        allowances[msg.sender][spender] -= amount;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool){
        if(allowances[from][msg.sender] >= amount
            && amount > 0) {
                allowances[from][msg.sender] -= amount;
                balances[from] -= amount;
                balances[to] += amount;
                emit Transfer(from, to, amount);
                return true;  
            }
        return false;
    }

    function burn(address account, uint amount) public onlyOwner {
        require(amount <= balances[account], 'Not enough tokens for burn');
        _totalSupply -= amount;
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

}

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";

contract Token2 is IERC20, Ownable {
    string public constant name = 'MyToken2';
    string public constant symbol = 'MTKN2';
    uint32 public constant decimals = 18;
                                        
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowances;

    

    constructor() {
        mint(msg.sender, 10**decimals * 10000);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(amount >= 0);
        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function totalSupply() public view returns (uint256) {
       return _totalSupply;
    }

    function balanceOf(address account) external view returns(uint256){
        return balances[account];
    }

    function transfer(address to, uint amount) public returns (bool) {
        require(balances[msg.sender] >= amount, 'Not enough tokens');
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint){
        return allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 amount) public returns(bool) {
        require(spender != address(0) && amount >= 0);
        allowances[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

        function decreaseAllowance(address spender, uint256 amount) public returns(bool) {
        require(spender != address(0) && allowances[msg.sender][spender] >= amount && amount >= 0);
        allowances[msg.sender][spender] -= amount;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool){
        if(allowances[from][msg.sender] >= amount
            && amount > 0) {
                allowances[from][msg.sender] -= amount;
                balances[from] -= amount;
                balances[to] += amount;
                emit Transfer(from, to, amount);
                return true;  
            }
        return false;
    }

    function burn(address account, uint amount) public onlyOwner {
        require(amount <= balances[account], 'Not enough tokens for burn');
        _totalSupply -= amount;
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

}

pragma solidity ^0.8.10;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./IERC20.sol";



contract Pair {

    address public factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  

    function addNewLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB)   external {

        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        IERC20(_tokenA).approve(router , _amountA);
        IERC20(_tokenB).approve(router , _amountB);


        IUniswapV2Router02(router).addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            1,
            1,
            msg.sender,
            block.timestamp);
        
    }

    function remouteLiquidity(address _tokenA, address _tokenB) external {
        address pair = IUniswapV2Factory(factory).getPair(_tokenA, _tokenB);

        uint256 liquidity = IERC20(pair).balanceOf(msg.sender);

        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);

        IERC20(pair).approve(router, liquidity);

        IUniswapV2Router02(router).removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            msg.sender,
            block.timestamp
        );
    }

}

pragma solidity ^0.8.10;

abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() {
        _owner = msg.sender;
    }


  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(isOwner(), "Is not owner");
    _;
  }


  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }


  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }


  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }


  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

pragma solidity ^0.8.10;

interface IERC20 {

    function balanceOf(address account) external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}