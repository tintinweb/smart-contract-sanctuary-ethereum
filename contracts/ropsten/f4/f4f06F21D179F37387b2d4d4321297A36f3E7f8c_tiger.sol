/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

pragma solidity ^0.5.4;

interface INFT721 {
  function transferFrom(address from,address to,uint256 tokenId) external;
  function balanceOf(address owner) external view returns (uint256 balance);
  function awardItem(address player, string calldata tokenURI) external returns (uint256 tokenId);
  function updateIsTransfer(bool _flag) external;
}

interface IPancakePair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function totalSupply() external view returns (uint);
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
}

contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
       require(b <= a, errorMessage);
            return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
            return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
            return a % b;
    }
}

contract  tiger is Ownable{
  using SafeMath for uint;

  INFT721 public ntfAddress;
  IPancakePair public pairAddress;
  IERC20 public httrAddress;
  IERC20 public jihAddress;
  address private fee2;
  address private fee3;
  uint public youhuPrice;
  uint public jkhPrice;
  uint public jihUserCount;
  string tokenUrlV0 = "youhu.url";
  string tokenUrlV1 = "jiankanghu.url";
  string tokenUrlV2 = "yinghu.url";
  string tokenUrlV3 = "jinghu.url";
  mapping(address => uint256) public userCount;
  
  // constructor(INFT721 _ntfAddress,IPancakePair _pairAddress,IERC20 _httrAddress,IERC20 _jihAddress,address _fee2,address _fee3,uint _youhuPrice,uint _jihUserCount) public  {
  //   ntfAddress = _ntfAddress;
  //   pairAddress = _pairAddress;
  //   httrAddress = _httrAddress;
  //   jihAddress = _jihAddress;
  //   fee2 = _fee2;
  //   fee3 = _fee3;
  //   youhuPrice = _youhuPrice;
  //   jkhPrice = _jkhPrice;
  //   jihUserCount = _jihUserCount;
  // }

  constructor() public  {
    ntfAddress = INFT721(0x4a4a7787F3c6b0724288E6F79372F9aE8bD20325);
    pairAddress = IPancakePair(0x9F2535dAE734B17d42F2DB992b79b0F898aA8b60);
    httrAddress = IERC20(0xe3c69AD3f1189478d38d1803781CEC253621D4FF);
    jihAddress = IERC20(0x33d78aBD7F4D0081B6f2761eB33da66158dA6866);
    fee2 = address(0x8f4bf43401feACA2eC8E6f308A3b6C3E55d392a9);
    fee3 = address(0x8f4bf43401feACA2eC8E6f308A3b6C3E55d392a9);
    youhuPrice = 100;
    jkhPrice = 14000;
    jihUserCount = 10;
  }

  event CultivationEvent(address sender, uint amount, string uuid, uint256 tokenId,uint firstPrice);
  event CoCultivationEvent(address sender, uint amount, string uuid);
  event UpVipEvent(address sender, uint amount, string uuid);
  event WakeEvent(address sender, uint amount, string uuid);
  

  function updatefee(address _fee2,address _fee3) public onlyOwner {
    fee2 = _fee2;
    fee3 = _fee3;
  }

  function updateHuPrice(uint _youhuPrice, uint _jkhPrice) public onlyOwner {
    youhuPrice = _youhuPrice;
    jkhPrice = _jkhPrice;
  }

    function updateJihUserCount(uint _jihUserCount) public onlyOwner {
    jihUserCount = _jihUserCount;
  }

  
  

  /**
  * 健康虎 幼虎 培育
  */
  function cultivation(uint amount,string memory uuid) public  {
    uint firstPrice = 0;
    if(userCount[msg.sender] == 0 && amount != youhuPrice){
            uint jihCount = getJihCount();
            jihAddress.transferFrom(msg.sender,address(0x000000000000000000000000000000000000dEaD),jihCount);
            userCount[msg.sender] = 1;
            firstPrice = jihCount;
        }
    string memory tokenUrl;
    if(amount == youhuPrice){
      tokenUrl = tokenUrlV0;
    }else if(amount == jkhPrice){
      tokenUrl = tokenUrlV1;
    }else{
      require(false,"Payment condition error");
    }
    payment(amount);
    uint256 tokenId = ntfAddress.awardItem(msg.sender,tokenUrl);
    emit CultivationEvent(msg.sender, amount, uuid, tokenId,firstPrice);
  }

  function getJihCount() public view returns  (uint jihCount){
      uint reserve0;
      uint reserve1;
      (reserve0, reserve1 , ) = pairAddress.getReserves();
      // address token0 = pairAddress.token0();
      // uint jihReserve;
      // uint usdtReserve;
      // if(token0 == address(jihAddress)){
      //   jihReserve = reserve0;
      //   usdtReserve = reserve1;
      // }else{
      //   jihReserve = reserve1;
      //   usdtReserve = reserve0 ;
      // }
      uint jihPrice = reserve1.div(reserve0);
      uint usdtCount = jihUserCount;
      jihCount = usdtCount.div(jihPrice).mul(10**18);
  }

  function payment(uint amount) private{
    uint s0 = amount.mul(70).div(100);
    uint s1 = amount.mul(25).div(100);
    uint s2 = amount.mul(5).div(100);
    
    httrAddress.transferFrom(msg.sender,address(0x000000000000000000000000000000000000dEaD),s0);
    httrAddress.transferFrom(msg.sender,fee2,s1);
    httrAddress.transferFrom(msg.sender,fee3,s2);
  }

  /**
  * 共同培育 支付
  */
  function coCultivation(uint amount,string memory uuid) public  {
    payment(amount);

    emit CoCultivationEvent(msg.sender, amount, uuid);
  }

 /**
  * 用户升级 支付
  */
  function upVip(uint amount,string memory uuid) public  {
    payment(amount);

    emit UpVipEvent(msg.sender, amount, uuid);
  }

  /**
  * 唤醒 支付
  */
  function wake(uint amount,string memory uuid) public  {
    payment(amount);

    emit WakeEvent(msg.sender, amount, uuid);
  }

  /**
  * 更改trc721 交易权限
  */
  function upVip(bool _flag) public onlyOwner {
    ntfAddress.updateIsTransfer(_flag);
  }

  /**
  * 直接创建 健康虎 银虎 金虎
  */
  function createHu(address to, uint _type) public onlyOwner returns  (uint tokenId) {
    string memory tokenUrl;
    if(_type == 1){
      tokenUrl = tokenUrlV1;
    } else if(_type == 2) {
      tokenUrl = tokenUrlV2;
    }else if(_type == 3) {
      tokenUrl = tokenUrlV3;
    }else{
      require(false,"error in type");
    }
    tokenId = ntfAddress.awardItem(to,tokenUrl);
  }

  
}