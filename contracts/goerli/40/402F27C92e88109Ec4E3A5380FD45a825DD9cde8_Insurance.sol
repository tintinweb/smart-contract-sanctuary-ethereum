// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IInsurance.sol";
import "./interfaces/IRaw.sol";
import "./interfaces/ISynt.sol";
import "./interfaces/IOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Insurance is Ownable {
    event CreatedInsurance(address indexed user, bytes32 indexed insId, uint256 amount, uint256 lockTime);
    event RemovedInsurance(address indexed user, bytes32 indexed insId);
    event Compensated(address indexed user, bytes32 indexed insId, uint256 amount);

    IRaw public raw; // RAW token contract
    address public rUsd;
    address public synergy; // Synergy contract address
    IOracle public oracle;

    uint256 public maxLockTime; // after this time compensation = 100%. If 0 => compensations are turned off
    uint256 public minLockTime; // min insurance lock time
    mapping(bytes32 => UserInsurance) public insurances; // every insurance has unique id
    mapping(address => bytes32[]) public userInsurances; // list of user's insurances
    mapping(address => uint32) public totalInsurances; // total numbler of insurances of each user

    constructor(uint256 _minLockTime, uint256 _maxLockTime) {
        minLockTime = _minLockTime;
        maxLockTime = _maxLockTime;
    }

    /* ================= INITIALIZATION ================= */

    /**
     * @dev Reinitialization available only for test purposes to spare goerli ETH
     */
    function initialize(address _rUsd, address _raw, address _synergy, address _oracle) external onlyOwner {
        // require(_rUsd != address(0) && address(rUsd) == address(0), "Inicialize only once");
        // require(_raw != address(0) && address(raw) == address(0), "Inicialize only once");
        // require(_synergy != address(0) && address(_synergy) == address(0), "Inicialize only once");
        // require(_oracle != address(0) && address(oracle) == address(0), "Inicialize only once");

        rUsd = _rUsd;
        raw = IRaw(_raw);
        synergy = _synergy;
        oracle = IOracle(_oracle);
    }

    /* ================= USER FUNCTIONS ================= */

    /**
     * @notice stake RAW tokens to insure against global debt losses
     * @param _lockTime time to lock the insurance
     * @param _amount amount of RAW to lock for insurance
     * @return insId_ Unique id of the insurance
     */
    function stakeRaw(uint32 _lockTime, uint256 _amount) external returns (bytes32 insId_) {
        require(_lockTime >= minLockTime, "Lock time is too low");
        require(_amount != 0, "Lock amount is zero");

        bool success_ = raw.transferFrom(msg.sender, address(this), _amount);
        require(success_, "Cannot transfer RAW token");

        insId_ = keccak256(abi.encode(msg.sender, msg.data, block.number, userInsurances[msg.sender].length));
        require(insurances[insId_].user == address(0), "Cannot duplicate insurances");

        insurances[insId_] = UserInsurance({
            user: msg.sender,
            stakedRaw: _amount,
            repaidRaw: 0,
            startTime: block.timestamp,
            lockTime: _lockTime,
            insInd: totalInsurances[msg.sender]++
        });

        userInsurances[msg.sender].push(insId_);

        emit CreatedInsurance(msg.sender, insId_, _amount, _lockTime);
    }

    /**
     * @notice Unstake unlocked insurance position
     * @param _insId unique insurance id
     */
    function unstakeRaw(bytes32 _insId) external {
        UserInsurance storage insurance_ = insurances[_insId];

        require(insurance_.user == msg.sender, "Wrong user");
        require(getUnlockTime(_insId) <= block.timestamp, "Insurance is locked up");

        raw.transfer(msg.sender, insurance_.stakedRaw);

        uint32 insIndex_ = insurance_.insInd;

        uint256 totalIns_ = totalInsurances[msg.sender]--;

        userInsurances[msg.sender][insIndex_] = userInsurances[msg.sender][totalIns_ - 1];

        userInsurances[msg.sender].pop();
        // change index of the last collateral which was moved
        if (userInsurances[msg.sender].length != insIndex_) {
            insurances[userInsurances[msg.sender][insIndex_]].insInd = insIndex_;
        }

        delete insurances[_insId];

        emit RemovedInsurance(msg.sender, _insId);
    }

    /* ================= SYNERGY FUNCTIONS ================= */

    /**
     * @notice Function to mint compensation
     * @dev Callable only by synergy contract
     * @param _insId unique insurance id
     * @param _overpayed compensation required in rUSD
     * @return compensated in rUSD
     */
    function compensate(bytes32 _insId, uint256 _overpayed) external returns (uint256) {
        require(msg.sender == address(synergy), "Callable only by the Synergy contract");

        uint256 availableCompensation_ = availableCompensation(_insId); // in RAW

        (uint256 rawPrice_, uint8 rawDecimals_) = oracle.getPrice(address(raw));
        (uint256 rUsdPrice_, uint8 rUsdDecimals_) = oracle.getPrice(address(rUsd));

        uint256 claimedCompensation_ =
            (_overpayed * rUsdPrice_ * 10 ** rawDecimals_) / (rawPrice_ * 10 ** rUsdDecimals_);

        uint256 compensationInRaw_ =
            claimedCompensation_ < availableCompensation_ ? claimedCompensation_ : availableCompensation_;

        UserInsurance storage insur = insurances[_insId];

        insur.repaidRaw += compensationInRaw_;
        raw.mint(insur.user, compensationInRaw_);

        emit Compensated(insur.user, _insId, compensationInRaw_);

        return (compensationInRaw_ * rawPrice_ * 10 ** rUsdDecimals_) / (rUsdPrice_ * 10 ** rawDecimals_);
    }

    /* ================= PUBLIC FUNCTIONS ================= */

    /**
     * @notice Get insurance deposit unlock time
     * @param _insId unique insurance id
     * @return unlock timestamp
     */
    function getUnlockTime(bytes32 _insId) public view returns (uint256) {
        return insurances[_insId].lockTime + insurances[_insId].startTime;
    }

    /**
     * @notice Available compensation amount of the insurance
     * @param _insId unique insurance id
     * @return amount of RAW
     */
    function availableCompensation(bytes32 _insId) public view returns (uint256) {
        if (maxLockTime == 0) {
            return 0;
        } // compensations are turned off

        UserInsurance storage insur = insurances[_insId];

        uint256 totalCompensation_;
        if (insur.lockTime >= maxLockTime) {
            totalCompensation_ = insur.stakedRaw;
        } else {
            totalCompensation_ = (insur.stakedRaw * insur.lockTime) / maxLockTime;
        }

        return totalCompensation_ == 0 ? 0 : totalCompensation_ - insur.repaidRaw;
    }

    /* ================= OWNER FUNCTIONS ================= */

    function setMaxLockTime(uint256 _newTime) external onlyOwner {
        maxLockTime = _newTime;
    }

    function setMinLockTime(uint256 _newTime) external onlyOwner {
        minLockTime = _newTime;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct UserInsurance {
    address user;
    uint256 stakedRaw;
    uint256 repaidRaw;
    uint256 startTime;
    uint32 lockTime;
    uint32 insInd;
}

interface IInsurance {
    function stakeRaw(uint256 lockTime, uint256 amount) external returns (bytes32 insId);
    function unstakeRaw(bytes32 insId) external; // cancel all insurance
    function compensate(bytes32 insId, uint256 amount) external returns (uint256);
    function userInsurances(address user) external view returns (uint256);
    function totalInsurance(address user) external view returns (uint256);
    function insurances(bytes32 insId) external view returns (UserInsurance memory);
    function availableCompensation(bytes32 insId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRaw is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IOracle {
    function getPrice(address _address) external view returns (uint256, uint8);
    function changeFeed(address _address, address _priceFeed) external;
    function changeRusdAddress(address _newAddress) external;
    function changeTruflationFeed(address _address, address _priceFeed) external;
    function updateTruflationPrice(address _address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISynt is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address user, uint256 amount) external;
    function setMaxSupply(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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