// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";
import "OwnableWallet.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Wallet is OwnableWallet{

    using SafeMathChainlink for uint256;

    mapping(address => uint256[][]) public depositsBalances; // balance in eth and usd price
    mapping(address => uint256) public ERC20_Balances;
    address[] public ERC20_LIST; 

    event SendERC20(address indexed _to, uint256 indexed _amount);

    uint256 public MINIMUM_DEPOSIT = 0;
    address public immutable eth_usd;
    bool public approvableState;
    
    constructor(address _eth_addr) OwnableWallet() {
        eth_usd = _eth_addr;
        approvableState = true;
        setMinimumDeposit(1000000000000000);
    }

    function setMinimumDeposit(uint256 _amount) public onlyOwner{
        MINIMUM_DEPOSIT = _amount;
    }
    
    function getApproveState() public view returns(bool state){
        state = approvableState;
    }

    function switchApprove() public onlyOwner{
        approvableState = (approvableState == true)?false:true;
    }

    function getLatestPrice(address _pairAddr) public view returns (uint80, int256, uint256, uint256, uint80) {
        return AggregatorV3Interface(_pairAddr).latestRoundData();
    }

    function getTokensList() public view returns(address[] memory){
        return ERC20_LIST;
    }

    receive() payable external{
        require(msg.value >= MINIMUM_DEPOSIT, "NSF"); // dev: Non suffisant funds
        (, int256 priceUsd, , , ) = getLatestPrice(eth_usd);
        depositsBalances[_msgSender()].push([msg.value, uint256(priceUsd), block.timestamp]);
    }
    
    function getDepositBalancesDatas(address depositer) public view returns(uint256[][] memory){
        return depositsBalances[depositer];
    }

    function getEthBalance() public view returns(uint256 balance){
        balance = address(this).balance;
    }

    function withdrawETH(address payable _to, uint256 _amount) public onlyOwner{        
        uint256 balance = getEthBalance();
        require(balance >= _amount); // dev: Non Suffisant Amount
        _to.transfer(_amount);
    }

    function balanceOf(IERC20 _erc20Token) public view returns(uint256){
        return _erc20Token.balanceOf(address(this));
    }
    
    function allowance(IERC20 _erc20Token, address _allower) public view returns(uint256){
        return _erc20Token.allowance(_allower, address(this));
    }

    function setErc20Balances(address _erc20Token, uint256 _amount) public onlyAllower returns(uint256){
        require(_amount > 0); // dev: The minimum Amount should be greater than zero
        if (ERC20_Balances[_erc20Token] == 0) ERC20_LIST.push(_erc20Token);
        ERC20_Balances[_erc20Token] += _amount;
        return _amount;
    }

    function withdrawFromBalance(IERC20 _erc20Token, address _to, uint256 _amount) public onlyOwner{
        uint256 balance = balanceOf(_erc20Token);
        require(balance >= _amount); // dev: Non Suffisant Fund
        _erc20Token.transfer(_to, _amount);
        ERC20_Balances[address(_erc20Token)] -= _amount;
        emit SendERC20(_to, _amount);
    }

    function transferFrom(IERC20 _erc20Token, address _to, uint256 _amount, address _allower) public onlyOwner{

        uint256 balance = allowance(_erc20Token, _allower);
        require(balance >= _amount); // dev: Non Suffisant Fund
        _erc20Token.transferFrom(_allower, _to, _amount);
        emit SendERC20(_allower, _amount);
    }

    function approveToSpend(IERC20 _erc20Token, address _spender, uint256 _amount) public onlyOwner returns(bool){
        require(balanceOf(_erc20Token) > _amount); // dev: Non Suffisant Fund
        return _erc20Token.approve(_spender, _amount);
    }

    function approveToSpend(IERC20 _erc20Token, uint256 _amount) public onlyAllower returns(bool result){

        require(balanceOf(_erc20Token) > _amount, "NSF"); // dev: Non Suffisant Fund
        require(getApproveState(), "NA"); // dev: Not allowed
        return _erc20Token.approve(_msgSender(), _amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "Contest.sol";


abstract contract OwnableWallet is Context {

    address private _owner;
    mapping(address => address) public allowers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        setAllower(_msgSender());
    }

   
    modifier onlyAllower{
        require(_msgSender() == allowers[_msgSender()], "Only the allower can performs this action!");
        _;
    }

    function setAllower(address _allower) public onlyOwner{
        allowers[_allower] = _allower;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }


    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}