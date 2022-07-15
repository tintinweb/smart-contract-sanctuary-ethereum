// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IODINNFT {
    function checkAccountLevels(address _account) external view returns (uint256[] memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function getTokensOfOwner(address owner) external view returns (uint256[] memory);
    function transferFrom(address from, address to, uint256 _id) external;
}

interface IODINToken {
    function transfer(address _from, address _to, uint256 amount) external returns(bool);
    function totalSupply() external view returns(uint256);
}

interface IMarket {
    function getTokenPrice(uint256 _tokenId) external view returns (uint256);
    function getTokenPaymentType(uint256 _tokenId) external view returns (string memory);
}

struct Staker {
    uint256[] tokenIds;
    uint256 lastStartTime;
    uint256 readyTime;
    uint256 period;
    uint256 rewardPercentage;
    uint256 bonusPercentage;
    bool isStaking;
}

contract OdinNFTStaking is Context, Ownable {
    using SafeMath for uint256;

    IODINNFT public iODINNFT;
    IODINToken public iODINToken;
    IMarket public iMarket;

    uint256 nonce;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;

    address public rewardTokenAddress;
    address public NFTTokenAddress;
    address public MarketAddress;
    address public adminRecoveryAddress;
    uint256[] public rewardPercentage = [5, 10, 15, 20, 25, 30, 35, 40, 50];

    mapping (address => Staker) public stakers;
    mapping (address => mapping(uint256 => bool)) public levelOfOwner;
    mapping (address => uint256) public levelCountOfOwner;

    constructor(address nftAddress_, address rewardAddress_, address adminRecoveryAddress_) {
        rewardTokenAddress = address(rewardAddress_);
        NFTTokenAddress = address(nftAddress_);
        adminRecoveryAddress = adminRecoveryAddress_;
        MarketAddress = address(0);

        iODINNFT = IODINNFT(nftAddress_);
        iODINToken = IODINToken(rewardAddress_);
    }

    receive() external payable {}

    function stake(uint256 _period) external {
        require(isStakable(msg.sender), "Must have at least 2 different NFTs");

        uint256[] memory _tokens = getTokensOfOwner(msg.sender);
        for(uint256 i = 0; i < _tokens.length; i++) {
            iODINNFT.transferFrom(msg.sender, address(this), _tokens[i]);
        }

        stakers[msg.sender].tokenIds = getTokensOfOwner(msg.sender);
        stakers[msg.sender].lastStartTime = _getNow();
        stakers[msg.sender].readyTime = _getNow() + SECONDS_PER_DAY.mul(_period);
        stakers[msg.sender].period = _period;
        stakers[msg.sender].rewardPercentage = setRewardPercentage(msg.sender, _period);
        stakers[msg.sender].bonusPercentage = setStakeLevel(msg.sender);
        stakers[msg.sender].isStaking = true;
    }

    function isStakable (address owner) public returns(bool) {
        require(getTokenCount(owner) > 1, "Must have at least 2 NFTs");
        bool _isStakable = false;
        uint256[] memory levels = iODINNFT.checkAccountLevels(owner);
        
        uint256 levelCount = checkLevels(owner, levels);
        if(levelCount > 1) {
            _isStakable = true;
        }

        return _isStakable;
    }

    function checkLevels(address _owner, uint256[] memory levels) internal returns(uint256) {
        require(levels.length > 0, "nothing levels");
        uint256 levelCount = 0;
        for(uint256 i = 0; i < levels.length; i++) {
            if(!levelOfOwner[_owner][levels[i]]) {
                levelOfOwner[_owner][levels[i]] = true;
                levelCount++;
            }
        }
        levelCountOfOwner[_owner] = levelCount;

        return levelCount;
    }

    function getAccountLevelsInfo(address _owner) public view returns(uint256[] memory) {
        return iODINNFT.checkAccountLevels(_owner);
    }

    function getTokenCount(address _owner) public view returns(uint256) {
        return iODINNFT.balanceOf(_owner);
    }

    function getTokensOfOwner(address _owner) public view returns(uint256[] memory) {
        return iODINNFT.getTokensOfOwner(_owner);
    }

    function getLevelCount(address _owner) public view returns(uint256) {
        return levelCountOfOwner[_owner];
    }

    function random(uint maxNumber) internal returns (uint) {
        uint _random = uint(
            keccak256(
                abi.encodePacked(block.difficulty+uint(keccak256(abi.encodePacked(block.gaslimit))), uint(keccak256(abi.encodePacked(block.timestamp+nonce))), uint(keccak256(abi.encodePacked(msg.sender))))
            )
        ) % maxNumber;
        nonce += _random;
        return _random;
    }

    function getIsStaking(address _owner) public view returns(bool) {
        return stakers[_owner].isStaking;
    }

    function setStakeLevel(address _owner) internal view returns (uint256) {
        uint256 _stakeReward = 0;
        if(levelOfOwner[_owner][2] && levelOfOwner[_owner][3]) {
            _stakeReward = 5;
        }
        if(levelOfOwner[_owner][3] && levelOfOwner[_owner][4]) {
            _stakeReward = 10;
        }
        if(levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 15;
        }
        if(levelOfOwner[_owner][1] && levelOfOwner[_owner][2] && levelOfOwner[_owner][3]) {
            _stakeReward = 20;
        }
        if(levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4]) {
            _stakeReward = 25;
        }
        if(levelOfOwner[_owner][3] && levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 30;
        }
        if(levelOfOwner[_owner][1] && levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4]) {
            _stakeReward = 35;
        }
        if(levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 40;
        }
        if(levelOfOwner[_owner][1] && levelOfOwner[_owner][2] && levelOfOwner[_owner][3] && levelOfOwner[_owner][4] && levelOfOwner[_owner][5]) {
            _stakeReward = 50;
        }

        return _stakeReward;
    }

    function getRestTime(address _owner) external view returns(uint256) {
        require(stakers[_owner].isStaking, "Must be staked.");
        uint256 _now = _getNow();
        return stakers[_owner].readyTime.sub(_now);
    }

    function _getNow() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getNFTTokenAddress() public view returns(address) {
        return NFTTokenAddress;
    }

    function getRewardTokenAddress() public view returns(address) {
        return rewardTokenAddress;
    }

    function getMarketAddress() public view returns (address) {
        return MarketAddress;
    }

    function setNFTTokenAddress(address _new) external onlyOwner {
        NFTTokenAddress = _new;
    }

    function setRewardTokenAddress(address _new) external onlyOwner {
        rewardTokenAddress = _new;
    }

    function setMarketAddress(address _new) public onlyOwner {
        MarketAddress = _new;
    }

    function setRewardContract() public onlyOwner {
        iODINToken = IODINToken(rewardTokenAddress);
    }

    function setNFTContract() public onlyOwner {
        iODINNFT = IODINNFT(NFTTokenAddress);
    }

    function setMarketContract() public onlyOwner {
        iMarket = IMarket(MarketAddress);
    }

    function isClaimable(address owner) public view returns(bool) {
        require(stakers[owner].isStaking, "Must be staked.");
        uint256 _now = _getNow();

        return _now >= stakers[owner].readyTime;
    }

    function claimReward() external returns(bool) {
        bool isClaimed = isClaimable(msg.sender);
        require(isClaimed, "not ready time");

        uint256 totalToken = IERC20(rewardTokenAddress).balanceOf(address(this));
        bool result = iODINToken.transfer(address(this), msg.sender, totalToken.mul(stakers[msg.sender].rewardPercentage.add(stakers[msg.sender].bonusPercentage)).div(100));

        uint256[] memory _tokens = stakers[msg.sender].tokenIds;
        for(uint256 i = 0; i < _tokens.length; i++) {
            iODINNFT.transferFrom(address(this), msg.sender, _tokens[i]);
        }
        stakers[msg.sender].isStaking = false;

        return result;
    }

    function setRewardPercentage(address _owner, uint256 _period) public view returns (uint256) {
        require(MarketAddress != address(0), "Not started marketplace");

        uint256 _tPrice = 0;
        uint256[] memory _tokens = getTokensOfOwner(_owner);
        for(uint256 i = 0; i < _tokens.length; i++) {
            string memory _paymentType = iMarket.getTokenPaymentType(_tokens[i]);
            if(keccak256(abi.encodePacked((_paymentType))) == keccak256(abi.encodePacked(("BNB")))) {
                uint256 _price = iMarket.getTokenPrice(_tokens[i]);
                _tPrice = _tPrice.add(_price);
            }
        }

        uint256 _adminRecoveryBalance = IERC20(rewardTokenAddress).balanceOf(adminRecoveryAddress);
        uint256 _rewardProfit = (_tPrice.mul(_period)).div((_adminRecoveryBalance.mul(10)));

        return _rewardProfit;
    }

    function getRewardPercentage(address _owner) public view returns(uint256) {
        require(stakers[_owner].isStaking, "Must be staked.");
        return stakers[_owner].rewardPercentage;
    }

    function getStakedTokens(address _owner) public view returns(uint256[] memory) {
        return stakers[_owner].tokenIds;
    } 
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}