/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

contract MaticPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public developerFee = 300; // 300 : 3 %. 10000 : 100 %
    uint256 public rewardPeriod = 1 minutes;
    uint256 public withdrawPeriod = 4 minutes;
    uint256 public apr = 150; // 150 : 1.5 %. 10000 : 100 %
    uint256 public percentRate = 10000;
    address payable private devWallet;
    uint256 private _currentDepositID = 0;
    address[] public investors;

    struct DepositStruct {
        address investor;
        uint256 depositAmount;
        uint256 depositAt; // deposit timestamp
        uint256 claimedAmount; // claimed matic amount
        bool state; // withdraw capital state. false if withdraw capital
    }

    // mapping from depost Id to DepositStruct
    mapping(uint256 => DepositStruct) public depositState;
    // mapping form investor to deposit IDs
    mapping(address => uint256[]) public ownedDeposits;

    constructor(address payable _devWallet) {
        devWallet = _devWallet;
    }

    // deposit funds by user, add pool
    function deposit() external payable {
        // require(msg.value > 0, "you can deposit more than 0 matic");

        uint256 _id = _getNextDepositID();
        _incrementDepositID();

        uint256 depositFee = (msg.value * developerFee).div(percentRate);
        // transfer 3% fee to dev wallet
        (bool success, ) = devWallet.call{value: depositFee}("");
        require(success, "Failed to send fee to the devWallet");

        depositState[_id].investor = msg.sender;
        depositState[_id].depositAmount = msg.value - depositFee;
        depositState[_id].depositAt = block.timestamp;
        depositState[_id].state = true;

        ownedDeposits[msg.sender].push(_id);
        if(!existInInvestors(msg.sender)) investors.push(msg.sender);
    }

    function removeInvestor(uint index) public{
        investors[index] = investors[investors.length - 1];
        investors.pop();
    }

    // claim reward by deposit id
    function claimReward(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can claim reward"
        );

        require(depositState[id].state, "you already withdrawed capital");

        uint256 claimableReward = getClaimableReward(id);
        require(claimableReward > 0, "your reward is zero");

        require(
            claimableReward <= address(this).balance,
            "no enough matic in pool"
        );

        // transfer reward to the user
        (bool success, ) = msg.sender.call{value: claimableReward}("");
        require(success, "Failed to claim reward");

        depositState[id].claimedAmount += claimableReward;
    }

    // claim all rewards of user
    function claimAllReward() public nonReentrant {
        require(ownedDeposits[msg.sender].length > 0, "you can deposit once at least");

        uint256 allClaimableReward;
        for(uint256 i; i < ownedDeposits[msg.sender].length; i ++) {
            uint256 claimableReward = getClaimableReward(ownedDeposits[msg.sender][i]);
            allClaimableReward += claimableReward;
            depositState[ownedDeposits[msg.sender][i]].claimedAmount += claimableReward;
        }

        // transfer reward to the user
        (bool success, ) = msg.sender.call{value: allClaimableReward}("");
        require(success, "Failed to claim reward");
    }

    // calculate all claimable reward of the user
    function getAllClaimableReward(address investor) public view returns (uint256) {
        uint256 allClaimableReward;
        for(uint256 i; i < ownedDeposits[investor].length; i ++) {
            allClaimableReward += getClaimableReward(ownedDeposits[msg.sender][i]);
        }

        return allClaimableReward;
    }

    // calculate claimable reward by deposit id
    function getClaimableReward(uint256 id) public view returns (uint256) {
        if(depositState[id].state == false) return 0;
        uint256 lastedDays = (block.timestamp - depositState[id].depositAt).div(
            rewardPeriod
        );

        // all calculated claimable amount from deposit time
        uint256 allClaimableAmount = (lastedDays *
            depositState[id].depositAmount *
            apr).div(percentRate);

        // allClaimableAmount is always more than claimed amount
        require(
            allClaimableAmount >= depositState[id].claimedAmount,
            "something went wrong"
        );

        return allClaimableAmount - depositState[id].claimedAmount;
    }

    // withdraw capital by deposit id
    function withdrawCapital(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can claim reward"
        );
        require(
            block.timestamp - depositState[id].depositAt > withdrawPeriod,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you already withdrawed capital");

        uint256 claimableReward = getClaimableReward(id);

        require(
            depositState[id].depositAmount + claimableReward <= address(this).balance,
            "no enough matic in pool"
        );

        // transfer capital to the user
        (bool success, ) = msg.sender.call{
            value: depositState[id].depositAmount + claimableReward
        }("");
        require(success, "Failed to claim reward");

        depositState[id].state = false;
    }

    // if the address exists in current investors list
    function existInInvestors(address investor) public view returns(bool) {
        for(uint256 j = 0; j < investors.length; j ++) {
            if (investors[j] == investor) {
                return true;
            }
        }
        return false;
    }

    // calculate total rewards
    function getTotalRewards() public view returns (uint256) {
        uint256 totalRewards;
        for(uint256 i = 0; i < _currentDepositID; i ++) {
            totalRewards += getClaimableReward(i + 1);
        }
        return totalRewards;
    }

    // get all deposit IDs of investor
    function getOwnedDeposits(address investor) public view returns (uint256[] memory) {
        return ownedDeposits[investor];
    }

    function _getNextDepositID() private view returns (uint256) {
        return _currentDepositID + 1;
    }

    function _incrementDepositID() private {
        _currentDepositID++;
    }

    // reset dev wallet address
    function resetContract(address payable _devWallet) public onlyOwner {
        devWallet = _devWallet;
    }

    // adding pool by owner
    function depositFunds() external payable onlyOwner returns(bool) {
        require(msg.value > 0, "you can deposit more than 0 matic");
        return true;
    }

    // withdraw all funds of this contracct by owner
    function withdrawFunds() external onlyOwner nonReentrant {
        // transfer fund of this contract to the manager
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw funds");
    }
}