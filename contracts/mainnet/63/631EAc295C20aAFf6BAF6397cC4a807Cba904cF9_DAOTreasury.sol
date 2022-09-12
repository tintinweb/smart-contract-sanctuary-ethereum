/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

interface IBaseV1Pair {
  function stable() external view returns(bool);
  function token0() external view returns(address);
  function token1() external view returns(address);
}
interface IConverter {
  function getLDInETH(address _LD, uint _amount, bool stable) external view returns(uint);
  function tradeLD(address from, address to, uint amount) external;
}
interface IVoter {
  function totalVotes() external view returns(uint);
  function votesPerPool(address) external view returns(uint);
}
interface ITreasury {
  function transferOwnership(address newOwner) external;
  function manage(uint256 _amount, address _token, address _to) external;
}
pragma solidity ^0.8.0;






// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract DAOTreasury is Ownable {
  using SafeMath for uint;

  ITreasury public treasury;
  IVoter public voter;
  IConverter public converter;

  // how much can be sub from LD token in WETH value
  mapping(address => uint) public subLD;
  // how much can be add to LD token in WETH value
  mapping(address => uint) public addLD;
  // how much cost LD token in ETH
  mapping(address => uint) private LDTokenInWETH;
  // pause between call compute function
  uint public updatePeriod = 0;


  constructor(address _treasury, address _voter, address _converter)
  {
    treasury = ITreasury(_treasury);
    voter = IVoter(_voter);
    converter = IConverter(_converter);
  }

  // get total current LD in weth value
  // get total ve votes
  // get votes per each LD
  // then compute how much sub and how much add in WETH value
  // according to votes for each pool
  function compute(address[] calldata LDtokens) external {
    // for safe update allow call this only once per week
    // so users can rebalance
    require(block.timestamp >= updatePeriod, "Need wait");

    uint totalLDInWETH = 0;
    uint totalVeVotes = voter.totalVotes();

    // COMPUTE total LD in WETH for each LD
    for(uint i = 0; i < LDtokens.length; i++){
      uint LDAmount = IERC20(LDtokens[i]).balanceOf(address(treasury));
      uint LDInWETH = converter.getLDInETH(
        LDtokens[i],
        LDAmount,
        IBaseV1Pair(LDtokens[i]).stable()
      );

      totalLDInWETH += LDInWETH;
      LDTokenInWETH[LDtokens[i]] = LDInWETH;
    }

    // COMPUTE How much sub and add in WETH for each token
    for(uint j = 0; j < LDtokens.length; j++){
      // compute votes % for current pool
      uint Votes = voter.votesPerPool(LDtokens[j]) * 100 / totalVeVotes;
      // compute how much WETH should be on current pool according to votes %
      uint NewWETHBalance = totalLDInWETH / 100 * Votes;

      // compute how much should be sub or add for current pool in WETH
      (uint _add, uint _sub) = computeSubAdd(
        NewWETHBalance,
        LDTokenInWETH[LDtokens[j]]
      );

      // update sub and add
      addLD[LDtokens[j]] = _add;
      subLD[LDtokens[j]] = _sub;
    }

    updatePeriod = block.timestamp + 7 days;
  }

  // COMPUTE how much SUB or ADD in ETH
  function computeSubAdd(uint updatedETH, uint currentETH)
   public
   view
   returns(uint _add, uint _sub)
  {
     if(updatedETH > currentETH){
        _add = updatedETH - currentETH;
      }
      else if (updatedETH < currentETH){
        _sub = currentETH - updatedETH;
      }
      else{
        _add = 0;
        _sub = 0;
      }
  }

  // how this works
  // user send weth value for sub from and add to
  // we convert subLD[_fromLD] and addLD[_toLD] to weth
  // then remove LD trade and add LD
  // then update sub and add
  function convertLD(address _fromLD, address _toLD, uint WETHAmount) external {
    require(WETHAmount > 0, "0 WETH");
    // check sub allowance
    // can not sub more tahn allowed
    require(subLD[_fromLD] >= WETHAmount, "sub limit");
    require(addLD[_toLD] <= WETHAmount, "add limit");

    // compute how much sub percent of fromLD amount by WETH amount
    uint currentFromLD = IERC20(_fromLD).balanceOf(address(treasury));
    uint currentFromLDInWETH = converter.getLDInETH(
      _fromLD,
      currentFromLD,
      IBaseV1Pair(_fromLD).stable()
    );

    if(currentFromLDInWETH < 1000 || currentFromLD < currentFromLDInWETH / 1000)
      revert("Min LD issue");

    uint _ldAmountFrom = currentFromLD.div(currentFromLDInWETH / 1000).mul(WETHAmount / 1000);

    require(_ldAmountFrom > 0, "0 LD");
    require(_ldAmountFrom <= currentFromLD, "LD overflow");
    // tranfer to conveter
    treasury.manage(_ldAmountFrom, _fromLD, address(converter));
    // convert
    converter.tradeLD(_fromLD, _toLD, _ldAmountFrom);

    // update sub allowance
    subLD[_fromLD] = WETHAmount >= subLD[_fromLD] ? 0 : subLD[_fromLD].sub(WETHAmount);
    // update add allowance
    addLD[_toLD] = WETHAmount >= addLD[_toLD] ? 0 : addLD[_toLD].sub(WETHAmount);
  }

  function computeForConvert(address _fromLD, address _toLD, uint _addWETH)
    external
    view
    returns(uint _subWETH)
  {
    if (_addWETH == 0)
      return _subWETH = 0;

    if(subLD[_fromLD] == 0)
      return _subWETH = 0;

    uint fromSubETH = subLD[_fromLD];
    uint toAddETH = addLD[_toLD];

    // compute how much sub from by add to input
    if(fromSubETH > toAddETH){
      _subWETH = fromSubETH - (fromSubETH - toAddETH);
    }

    // return full 100%
    if(toAddETH >= fromSubETH){
      _subWETH = subLD[_fromLD];
    }
  }

  // allow update voter
  function updateVoter(address _voter) external onlyOwner {
    voter = IVoter(_voter);
  }

  // allow update converter
  function updateConverter(address _converter) external onlyOwner {
    converter = IConverter(_converter);
  }

  // alow migrate treasury to new DAO
  function migrate(address _newDao) external onlyOwner {
    treasury.transferOwnership(_newDao);
  }
}