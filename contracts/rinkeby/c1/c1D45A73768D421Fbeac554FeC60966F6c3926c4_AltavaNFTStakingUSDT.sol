// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ISecondskinContract.sol";
import "./IRewardContract.sol";
import "./IUSDTStaking.sol";

/* 
    ERR-001 : You are not the owner of the token.
    ERR-002 : You do not have rights to that token.
    ERR-003 : The billing period has expired.
    ERR-004 : It's not the claim period yet.
*/
contract AltavaNFTStakingUSDT is Ownable, Pausable, IUSDTStaking {
    struct PlanStructure {
        uint8 earn;    // 하루당 보상
        uint8 duration;    // staking 기간 (flexible의 경우 0)
        uint256 planStartTime;
        uint256 planEndTime;
        uint256 claimDueDate;
    }
    struct StakingStructure {
        uint8 earn;    // 하루당 보상
        uint8 duration;    // staking 기간 (flexible의 경우 0)
        uint256 stakingStartTime;   // staking 시작 시간
        uint256 stakingExpiredTime; // 종료시간
    }
    uint256 totalStakingCnt = 0;
    IRewardContract private rewardContract;
    ISecondskinContract private SecondskinContract;
    PlanStructure private infoPlan;
    mapping (address => mapping (uint256 => StakingStructure)) private infoUserStaking; // (account => (tokenid => StakingStructure))


    modifier VerifyToken(uint256[] calldata _tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            require(SecondskinContract.ownerOf(_tokenIdArr[i]) ==_msgSender(), "ERR-001");
        }
        _;
    }
    modifier VerifyTokenApproved(uint256[] calldata _tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            require(SecondskinContract.getApproved(_tokenIdArr[i]) == address(this), "ERR-002");
        }
        _;
    }

    constructor (address _RewardContract, address _NFTAddress){
        rewardContract = IRewardContract(_RewardContract);
        SecondskinContract = ISecondskinContract(_NFTAddress);
    }

    function SetPlan(uint8 _duration, uint8 _earn, uint256 _startTime) external onlyOwner {
        infoPlan.earn = _earn;
        infoPlan.duration = _duration;
        infoPlan.planStartTime = _startTime;
        infoPlan.planEndTime = _startTime + 90 days;
        infoPlan.claimDueDate = _startTime + 455 days;
        
        emit PlanCreated(_earn, _duration, 0);
    }

    function GetPlan() view external returns (uint8, uint8, uint256, uint256) {
        return (infoPlan.earn, infoPlan.duration, infoPlan.planStartTime, infoPlan.planEndTime);
    }

    function SetStaking(uint256[] calldata _tokenIdArr) external whenNotPaused VerifyToken(_tokenIdArr) VerifyTokenApproved(_tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            infoUserStaking[_msgSender()][_tokenIdArr[i]] = StakingStructure(infoPlan.earn, infoPlan.duration, block.timestamp, block.timestamp + infoPlan.duration * 1 seconds);
            SecondskinContract.transferFrom(_msgSender(), address(this), _tokenIdArr[i]);
        }
        totalStakingCnt++;
        emit Staked(_msgSender());
    }

    function GetStaking(address _account, uint256 _tokenId) view external returns (uint8 _earn, uint8 _duration, uint256 _startTime, uint256 _endTime){
        _startTime = infoUserStaking[_account][_tokenId].stakingStartTime;
        _endTime = infoUserStaking[_account][_tokenId].stakingExpiredTime;
        _earn = infoUserStaking[_account][_tokenId].earn;
        _duration = infoUserStaking[_account][_tokenId].duration;
    }

    // 
    function SetRewardContract(address _newRewardContract) external onlyOwner {
        rewardContract = IRewardContract(_newRewardContract);
    }

    function Claim(uint256[] calldata _tokenIdArr) external override whenNotPaused {
        require(infoPlan.claimDueDate > block.timestamp, "ERR-003");
        //TavaApprove();
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            require(block.timestamp > infoUserStaking[_msgSender()][_tokenIdArr[i]].stakingExpiredTime, "ERR-004");
        }
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            uint8 earn = infoUserStaking[_msgSender()][_tokenIdArr[i]].earn;
            uint8 duration = infoUserStaking[_msgSender()][_tokenIdArr[i]].duration;
            SecondskinContract.transferFrom(address(this), _msgSender(), _tokenIdArr[i]);
            rewardContract.transferFrom(address(this), _msgSender(), earn * duration);
            delete infoUserStaking[_msgSender()][_tokenIdArr[i]];
        }
        emit Claimed(_msgSender());
    }
    function MultiNftApprove(uint256[] calldata _tokenIdArr) external VerifyToken(_tokenIdArr) {
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            SecondskinContract.approve(address(this), _tokenIdArr[i]);
        }
    }
    // 현재 contract가 보유한 ERC20 token 전량 회수
    function RetrieveToken() external override onlyOwner returns (uint256){
        //TavaApprove();
        rewardContract.transferFrom(address(this), _msgSender(), ERC20TokenBalance());
        return ERC20TokenBalance();
    }

    function OwnerClaim (uint256 amount) external onlyOwner {
        rewardContract.transfer(address(this), amount);
    }

    // @ "ERC20" token balance held by "contract"
    function ERC20TokenBalance() view public override returns (uint256){
        return rewardContract.balanceOf(address(this));
    }

    function TavaApprove() internal {
        rewardContract.approve(address(this), ERC20TokenBalance());
    }

    // @ staking & claim stop
    function pause() external onlyOwner {
        super._pause();
    }

    // @ staking & claim doesn't stop
    function unpause() external onlyOwner {
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
pragma solidity 0.8.9;

interface ISecondskinContract {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address _account);
    function approve(address _approved, uint256 _tokenId) external;
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

interface IUSDTStaking {
    function SetPlan(uint8 _duration, uint8 _earn, uint256 _startTime) external;
    function GetPlan() view external returns (uint8, uint8, uint256, uint256);
    function SetStaking(uint256[] calldata _tokenIdArr) external;
    function GetStaking(address _account, uint256 _tokenId) view external returns (uint8, uint8, uint256, uint256);
    function Claim(uint256[] calldata _tokenIdArr) external;
    function RetrieveToken() external returns (uint256);
    function ERC20TokenBalance() external returns (uint256);

    event PlanCreated(uint8 _earn, uint8 _duration, uint8 _planIndex );
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