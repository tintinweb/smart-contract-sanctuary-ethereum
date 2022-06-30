/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract RoyalityPool is Ownable{

    using SafeMath for uint256;

    mapping (address => uint256 ) public rewardAmount;
    mapping (address => uint256) public nftSetsAmount;
    uint256 public shareValue;
    mapping (uint256 => address) public rewardHolders;
    uint256 public nftSetholdersAmount;                         // total amount of nft set holders of previous month
    uint256 public totalSetAmount;
    uint256 public currentRoyaltyAmount;
    uint256 public ownerDepositRoyaltyAmount = 0;

    event OwnerSetHoldersRewards (address[] holders, uint256[] setAmounts, uint256 totalSetAmount);
    event OwnerClearPreviousRewards ();
    event UserWithdraw (address user, uint256 amount);

    function getRewardAmount (address holder) public view returns (uint256) {
        return rewardAmount[holder];
    }

    function getShareValue () public view returns (uint256) {
        return shareValue;
    }

    function getNFTSetsAmounts (address holder) public view returns (uint256) {
        return nftSetsAmount[holder];
    }

    function getCurrentTime () public view returns (uint256) {
        return block.timestamp;
    }

    function ownerDeposit() external payable {
        ownerDepositRoyaltyAmount = 1;
    }

    function clearPreviousRewards () public onlyOwner{
        for (uint256 i = 0; i < nftSetholdersAmount; i++) {
            rewardAmount[rewardHolders[i]] = 0;
        }
        emit OwnerClearPreviousRewards();
    }

    function setHoldersRewards (address[] calldata holders, uint256[] calldata setAmounts, uint256 _totalSetAmount) public onlyOwner{
        require(ownerDepositRoyaltyAmount == 1, "setHolderRewards : Royalty Amount is not deposited yet");
        require(holders.length == setAmounts.length, "setHoldersRewards : Invalid input, holders lengt must be same as setAmounts length");
        require(_totalSetAmount > 0, "setHoldersReward : there is no NFT sets");
        uint256 sumSetAmount;
        for (uint256 i = 0; i < setAmounts.length; i++) {
            sumSetAmount += setAmounts[i];
        }
        require(sumSetAmount == _totalSetAmount, "setHoldersRewards : sum of setAmounts must be equal to the totalSetAmount");
        clearPreviousRewards();
        totalSetAmount = _totalSetAmount;
        nftSetholdersAmount = holders.length;
        currentRoyaltyAmount = address(this).balance;
        shareValue = currentRoyaltyAmount.div(totalSetAmount);
        for (uint256 i = 0; i < nftSetholdersAmount; i ++) {
            rewardHolders[i] = holders[i];
            rewardAmount[rewardHolders[i]] = shareValue.mul(setAmounts[i]);
            nftSetsAmount[rewardHolders[i]] = setAmounts[i];
        }
        ownerDepositRoyaltyAmount = 0;
        emit OwnerSetHoldersRewards(holders, setAmounts, _totalSetAmount);
    }  

    function withdrawRewards () public {
        require(rewardAmount[msg.sender] > 0, "withdrawRewards : Your reward amount is zero");
        address payable to = payable(msg.sender);        
        to.transfer(rewardAmount[to]);
        rewardAmount[to] = 0;
        emit UserWithdraw(to, rewardAmount[to]);
    }
}