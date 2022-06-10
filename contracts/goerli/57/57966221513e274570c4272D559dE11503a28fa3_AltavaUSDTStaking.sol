// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ISecondskinContract.sol";
import "./IRewardContract.sol";
import "./IAltavaUSDTStaking.sol";

/* 
    ERR-001 : You are not the owner of the token.
    ERR-002 : You do not have rights to that token.
    ERR-003 : 
    ERR-004 : The billing period has expired.
    ERR-005 : It's not the claim period yet.
*/
contract AltavaUSDTStaking is Ownable, Pausable, IAltavaUSDTStaking {
    using SafeMath for uint256;
    
    struct PlanStructure {
        uint256 earn;    // 하루당 보상
        uint256 duration;    // staking 기간 (flexible의 경우 0)
    }
    struct StakingStructure {
        uint256[] tokenIdArr;           // 적용할 tokenArr
        uint256 planIndex;              // 적용할 planIndex
        uint256 stakingStartTime;       // staking 시작 시간
        uint256 stakingExpiredTime;     // claim 가능 시간
        uint256 stakingClaimDueDate;    // 보상지급 만료 기간
        bool claimStatus;               // 지급 완료 유무 체크
    }

    uint8 public ERAN_DECIMAL = 2;
    uint8 public REWARD_DECIMAL;  // TAVA : 18, USDT : 6

    uint256 totalStakingCnt = 0;
    IRewardContract private rewardContract;
    ISecondskinContract private SecondskinContract;
    mapping (uint256 => PlanStructure) private infoPlan;
    mapping (address => StakingStructure[]) private infoUserStaking; // (account => (tokenid => StakingStructure))

    // nft 소유자 확인
    modifier VerifyToken(uint256[] calldata _tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            require(SecondskinContract.ownerOf(_tokenIdArr[i]) == _msgSender(), "ERR-001");
        }
        _;
    }

    // nft 권한 승인 확인
    modifier VerifyTokenApproved(uint256[] calldata _tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            require(SecondskinContract.isApprovedForAll(_msgSender(), address(this)), "ERR-002");
        }
        _;
    }

    constructor (address _RewardContract, address _NFTAddress, uint8 _decimal){
        rewardContract = IRewardContract(_RewardContract);
        SecondskinContract = ISecondskinContract(_NFTAddress);
        REWARD_DECIMAL = _decimal;
    }

    // plan 생성, 수정
    function SetPlan(uint256 _planIndex, uint256 _earn, uint256 _duration) external override onlyOwner {
        infoPlan[_planIndex].earn = _earn;
        infoPlan[_planIndex].duration = _duration;
        emit PlanCreated(_earn, _duration, _planIndex);
    }

    // plan 정보 조회
    function GetInfoPlan(uint256 _planIndex) external override view onlyOwner returns(uint256, uint256){
        return (infoPlan[_planIndex].earn, infoPlan[_planIndex].duration);
    }

    // staking 시작
    function SetInfoStaking (uint256[] calldata _tokenIdArr, uint256 _planIndex) external override whenNotPaused VerifyToken(_tokenIdArr) VerifyTokenApproved(_tokenIdArr) {
        uint256 _stakingStartTime = block.timestamp;
        uint256 _stakingExpiredTime = _stakingStartTime + infoPlan[_planIndex].duration * 1 seconds;
        uint256 _stakingClaimDueDate = _stakingExpiredTime + 365 days;
        infoUserStaking[_msgSender()].push(StakingStructure(_tokenIdArr, _planIndex, _stakingStartTime, _stakingExpiredTime, _stakingClaimDueDate, false));
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            SecondskinContract.transferFrom(_msgSender(), address(this), _tokenIdArr[i]);
        }
        totalStakingCnt++;
        emit Staked(_msgSender());
    }

    // staking 정보 조회
    function GetInfoStaking(address _account, uint256 _stakingIndex) external override view returns (uint256 _earn, uint256 _duration, uint256 _startTime, uint256 _endTime){
        uint256 PlanIndex = infoUserStaking[_account][_stakingIndex].planIndex;
        _startTime = infoUserStaking[_account][_stakingIndex].stakingStartTime;
        _endTime = infoUserStaking[_account][_stakingIndex].stakingExpiredTime;
        _earn = infoPlan[PlanIndex].earn;
        _duration = infoPlan[PlanIndex].duration;          
    }

    // 총 staking 된 수량 표기
    function GetStakingOfAddressLength(address _account) public view returns(uint256){
        return infoUserStaking[_account].length;
    }
    // 보상받을 contract 수정
    function SetRewardContract(address _newRewardContract) external onlyOwner {
        rewardContract = IRewardContract(_newRewardContract);
    }

    // 보상 지급
    function Claim(uint256 _stakingIndex) external override whenNotPaused {
        // 보상 지급 만료 기간 확인
        StakingStructure memory _infoUserStaking = infoUserStaking[_msgSender()][_stakingIndex];

        require(!_infoUserStaking.claimStatus, "ERR-003");
        require(infoUserStaking[_msgSender()][_stakingIndex].stakingClaimDueDate > block.timestamp, "ERR-004"); 
        require(block.timestamp > infoUserStaking[_msgSender()][_stakingIndex].stakingExpiredTime, "ERR-005"); 

        uint256[] memory _tokenIdArr = _infoUserStaking.tokenIdArr;
        uint256 planIndex = _infoUserStaking.planIndex;

        // 보상 지급 & nft 전달
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            uint256 earn = infoPlan[planIndex].earn;
            uint256 duration = infoPlan[planIndex].duration;
            SecondskinContract.transferFrom(address(this), _msgSender(), _tokenIdArr[i]);
            rewardContract.transferFrom(address(this), _msgSender(), ((earn.mul(duration)).div(10**ERAN_DECIMAL)).mul(10**REWARD_DECIMAL) );
        }
        infoUserStaking[_msgSender()][_stakingIndex].claimStatus = true;
        emit Claimed(_msgSender());
    }
    
    // contract 내부의 ERC20 token 전량 회수
    function RetrieveToken() external override onlyOwner returns (uint256){
        rewardContract.transferFrom(address(this), _msgSender(), ERC20TokenBalance());
        return ERC20TokenBalance();
    }

    // contract 내부의 ERC20 token 회수
    function OwnerClaim (uint256 amount) external onlyOwner {
        rewardContract.transfer(address(this), amount);
    }

    // contract 내부의 ERC20 잔액 표시
    function ERC20TokenBalance() view override public returns (uint256){
        return rewardContract.balanceOf(address(this));
    }

    // 보상지급 권한 부여
    function ClaimApprove() public {
        rewardContract.approve(address(this), ERC20TokenBalance());
    }

    // 스테이킹, 보상지급 기능 잠금
    function Pause() external onlyOwner {
        super._pause();
    }

    // 스테이킹, 보상지급 기능 잠금 해제
    function Unpause() external onlyOwner {
        super._unpause();
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISecondskinContract {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address _account);
    function approve(address _approved, uint256 _tokenId) external returns (address _account);
    function isApprovedForAll(address owner, address operator) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRewardContract {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAltavaUSDTStaking {
    function SetPlan(uint256 _planIndex, uint256 _earn, uint256 _duration) external;
    function GetInfoPlan(uint256 _planIndex) view external returns(uint256, uint256);
    function SetInfoStaking (uint256[] calldata _tokenIdArr, uint256 _planIndex) external;
    function GetInfoStaking(address _account, uint256 _tokenId) view external returns (uint256, uint256, uint256, uint256);
    function Claim(uint256 _stakingIndex) external;
    function RetrieveToken() external returns (uint256);
    function ERC20TokenBalance() external returns (uint256);

    event PlanCreated(uint256 _earn, uint256 _duration, uint256 _planIndex );
    event Staked(address account);
    event Claimed(address account);
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