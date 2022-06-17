/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

pragma solidity ^0.5.4;

interface INFT721 {
  function transferFrom(address from,address to,uint256 tokenId) external;
  function balanceOf(address owner) external view returns (uint256 balance);
  function awardItem(address player, string calldata tokenURI) external returns (uint256 tokenId);
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

contract  MyContract is Ownable{
  using SafeMath for uint;

  INFT721 public ntfAddress;
  IPancakePair public pairAddress;
  IERC20 public httrAddress;
  IERC20 public jihAddress;
  address private fee2;
  address private fee3;
  mapping(address => uint256) public userCount;
  
  constructor(INFT721 _ntfAddress,IPancakePair _pairAddress,IERC20 _httrAddress,IERC20 _jihAddress,address _fee2,address _fee3) public  {
    ntfAddress = _ntfAddress;
    pairAddress = _pairAddress;
    httrAddress = _httrAddress;
    jihAddress = _jihAddress;
    fee2 = _fee2;
    fee3 = _fee3;
  }

  event CultivationEvent(address sender, uint amount, string uuid);

  function updatefee(address _fee2,address _fee3) public onlyOwner {
    fee2 = _fee2;
    fee3 = _fee3;
  }
  
  

  /**
  * 培育健康虎
  */
  function cultivation(uint amount,string memory uuid) public  {
    if(userCount[msg.sender] == 0){
      uint jihCount = getJihCount();
      jihAddress.transferFrom(msg.sender,address(0x000000000000000000000000000000000000dEaD),jihCount);
      userCount[msg.sender] = 1;
    }
    uint s0 = amount.mul(70).div(100);
    uint s1 = amount.mul(25).div(100);
    uint s2 = amount.mul(5).div(100);
    
    httrAddress.transferFrom(msg.sender,address(0x000000000000000000000000000000000000dEaD),s0);
    httrAddress.transferFrom(msg.sender,fee2,s1);
    httrAddress.transferFrom(msg.sender,fee3,s2);
    emit CultivationEvent(msg.sender, amount, uuid);
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
      uint usdtCount = 20;
      jihCount = usdtCount.mul(jihPrice);
  }
  
}