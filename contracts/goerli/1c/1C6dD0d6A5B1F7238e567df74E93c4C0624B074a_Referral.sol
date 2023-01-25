/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Referral.sol



pragma solidity 0.8.11;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

interface Token {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

interface Staking {
    function setReferralIncome(address _userAddress, uint256 _amount) external;
}

contract Referral is Ownable
{
    struct ReferralEarning {
        address[] stakingAddress;
        address[] user;
        uint256[] amount;
        uint256[] timestamp;
    }

    mapping(address => bytes3) userReferralCode;
    mapping(bytes3 => address) public getUserByReferralCode;
    mapping(address => address) userReferral; // which refer user used
    mapping(address => address[]) userReferrales; // referral address which use users address
    mapping(address => uint256) public totalReferalAmount; // get my total referal amount
    mapping(address => ReferralEarning) referralEarning;
    uint256[] public referrals;
    address public depositToken;
    address[] public stakingContract;

    constructor(){
        referrals = [800, 400, 200];
    }

    function getReferCode() public {
        require(userReferralCode[msg.sender] == 0, "Already have refer code");
        bytes3 rand = bytes3(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.timestamp,
                    block.difficulty,
                    block.number
                )
            )
        );
        userReferralCode[msg.sender] = bytes3(rand);
        getUserByReferralCode[rand] = msg.sender;
    }

    function getUserReferralCode(address userAddress)
        public
        view
        returns (bytes3)
    {
        return userReferralCode[userAddress];
    }

    function getUserReferralInformation(address userAddress)
        public
        view
        returns (
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            referralEarning[userAddress].stakingAddress,
            referralEarning[userAddress].user,
            referralEarning[userAddress].amount,
            referralEarning[userAddress].timestamp
        );
    }

    function setDepositToken(address _token) public onlyOwner {
        depositToken = _token;
    }

    function addNewLevel(uint256 levelRate) public onlyOwner {
        referrals.push(levelRate);
    }

    function updateExistingLevel(uint256 index, uint256 levelRate)
        public
        onlyOwner
    {
        referrals[index] = levelRate;
    }

    function addNewStaking(address _stakingAddress) public onlyOwner {
        stakingContract.push(_stakingAddress);
    }

    function setUserReferral(address beneficiary, address referral)
        public
        returns (bool)
    {
        bool validCaller = false;
        for (uint256 i = 0; i < stakingContract.length; i++) {
            if (stakingContract[i] == msg.sender) {
                validCaller = true;
            }
        }
        require(validCaller, "Only Staking Contract");
        userReferral[beneficiary] = referral;
        return true;
    }

    function setReferralAddressesOfUsers(address beneficiary, address referral)
        public
        returns (bool)
    {
        bool validCaller = false;
        for (uint256 i = 0; i < stakingContract.length; i++) {
            if (stakingContract[i] == msg.sender) {
                validCaller = true;
            }
        }
        require(validCaller, "Only Staking Contract");
        userReferrales[referral].push(beneficiary);
        return true;
    }

    function getUserReferral(address user) public view returns (address) {
        return userReferral[user];
    }

    function getReferralAddressOfUsers(address user)
        public
        view
        returns (address[] memory)
    {
        return userReferrales[user];
    }

    function getTotalStakingContracts()
        public
        view
        returns (uint256, address[] memory)
    {
        return (stakingContract.length, stakingContract);
    }

    function payReferral(
        address _userAddress,
        address _secondaryAddress,
        uint256 _index,
        uint256 _mainAmount
    ) public returns (bool) {
        bool validCaller = false;
        for (uint256 i = 0; i < stakingContract.length; i++) {
            if (stakingContract[i] == msg.sender) {
                validCaller = true;
            }
        }
        require(validCaller, "Only Staking Contract");
        if (_index >= referrals.length) {
            return true;
        } else {
            if (userReferral[_userAddress] != address(0)) {
                uint256 transferAmount = (_mainAmount * referrals[_index]) /
                    10000;
                referralEarning[userReferral[_userAddress]].stakingAddress.push(
                        msg.sender
                    );
                referralEarning[userReferral[_userAddress]].user.push(
                    _secondaryAddress
                );
                referralEarning[userReferral[_userAddress]].amount.push(
                    transferAmount
                );
                referralEarning[userReferral[_userAddress]].timestamp.push(
                    block.timestamp
                );
                // if(!Staking(msg.sender).isBlackListForRefer(userReferral[_userAddress])){
                // require(
                //     Token(depositToken).transfer(
                //         userReferral[_userAddress],
                //         transferAmount
                //     ),
                //     "Could not transfer referral amount"
                // );
                Staking(msg.sender).setReferralIncome(
                    _userAddress,
                    transferAmount
                );
                totalReferalAmount[userReferral[_userAddress]] =
                    totalReferalAmount[userReferral[_userAddress]] +
                    (transferAmount);
                // }
                payReferral(
                    userReferral[_userAddress],
                    _secondaryAddress,
                    _index + 1,
                    _mainAmount
                );
                return true;
            } else {
                return false;
            }
        }
    }

    function transferAnyBEP20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        Token(_tokenAddr).transfer(_to, _amount);
    }
}