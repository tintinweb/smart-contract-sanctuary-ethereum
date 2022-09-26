// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function mint(address, uint256) external;
}

interface IVotingEscrow {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOfAt(address, uint256) external view returns (uint256);
    function totalSupplyAt(uint256) external view returns (uint256);
    function epoch() external view returns (uint256);
    function locked__end(address) external view returns (uint256);
    function token() external view returns (address);
}

interface IGauge {
    function setEmission(uint256) external;
    function setKilled() external;
    function isKilled() external view returns (bool);
}

interface IRewardGaugeController {
    function userCheckpointGauge(address _gauge, address _user) external;
    function votingescrow() external view returns (address);
    function isTrustedForwarder(address _address) external view returns (bool);
    function mint(address, uint) external;
}

contract RewardGaugeController is Ownable {

    uint256 public constant WEEK = 604800;

    IVotingEscrow public immutable votingescrow;

    uint256 public baseEmission; // Per second between all gauges

    address[] public gauges;
    mapping(address => uint) private gaugesIndexes;

    struct Gauge {
        bool allowedGauge;
        uint256 votes;
        uint256 weight;
        uint256 checkpoint;
    }

    mapping(address => Gauge) public gauge;
    mapping(address => uint256) public userVotes;
    mapping(address => mapping(address => uint256)) public userGaugeVotes;
    mapping(address => mapping(address => uint256)) public userGaugeWeights;
    uint256 public totalWeight;

    mapping(address => bool) private minter;

    constructor(address _votingescrow) {
        votingescrow = IVotingEscrow(_votingescrow);
    }

    function createGauge(address _lp) external onlyOwner {
        address _gauge = address(new RewardGauge(_lp, votingescrow.token(), address(this)));
        gaugesIndexes[_lp] = gauges.length;
        gauges.push(_gauge);
        gauge[_gauge].checkpoint = votingescrow.epoch();
        gauge[_gauge].allowedGauge = true;
        minter[_gauge] = true;
        
        emit CreateGauge(_gauge, _lp);
    }

    function killGauge(address _gauge) external onlyOwner {
        require(gauge[_gauge].allowedGauge, "Not added");
        gaugesIndexes[gauges[gauges.length-1]] = gaugesIndexes[_gauge];
        gauges[gaugesIndexes[_gauge]] = gauges[gauges.length-1];
        delete gaugesIndexes[_gauge];
        gauges.pop();
        gauge[_gauge].allowedGauge = false;
        IGauge(_gauge).setKilled();

        emit KillGauge(_gauge);
    }

    function finalizeKill(address _killedGauge) external onlyOwner {
        require(gauges[gaugesIndexes[_killedGauge]] != _killedGauge, "!Killed");
        delete minter[_killedGauge];
    }

    function vote(address[] memory _gauges, uint256[] memory _amounts) external {

        uint256 next_time = (block.timestamp + WEEK) / WEEK * WEEK;
        uint256 lock_end = votingescrow.locked__end(_msgSender());
        require(lock_end > next_time, "Your token lock expires too soon");

        require(_gauges.length == _amounts.length, "!Equal length arrays");

        for(uint256 i=0; i<_gauges.length; i++) {
            address _gauge = _gauges[i];
            uint256 _amount = _amounts[i];
            if (IGauge(_gauge).isKilled()) require(_amount == 0, "Cannot vote for killed gauge");
            if (!gauge[_gauge].allowedGauge) require(_amount == 0, "!Gauge");
            uint256 currentVote = userGaugeVotes[_msgSender()][_gauge];
            if (currentVote < _amount) {
                userVotes[_msgSender()] += _amount-currentVote;
                gauge[_gauge].votes += _amount-currentVote;
            } else if (currentVote > _amount) {
                userVotes[_msgSender()] -= currentVote-_amount;
                gauge[_gauge].votes -= currentVote-_amount;
            }
            userGaugeVotes[_msgSender()][_gauge] = _amount;

            uint256 newUserWeight = _amount*votingescrow.balanceOf(_msgSender());
            uint256 currentUserWeight = userGaugeWeights[_msgSender()][_gauge];
            if (currentUserWeight < newUserWeight) {
                gauge[_gauge].weight += newUserWeight-currentUserWeight;
                totalWeight += newUserWeight-currentUserWeight;
            } else if (currentUserWeight > newUserWeight) {
                gauge[_gauge].weight -= currentUserWeight-newUserWeight;
                totalWeight -= currentUserWeight-newUserWeight;
            }
            userGaugeWeights[_msgSender()][_gauge] = newUserWeight;
        }
        require(userVotes[_msgSender()] <= 10000, "Used too much voting power");
        _checkpointAll();
    }

    function userCheckpointAll(address _user) external {
        for(uint256 i=0; i<gauges.length; i++) {
            address _gauge = gauges[i];
            uint256 _amount = userGaugeVotes[_user][_gauge];
            if (_amount > 0) {
                uint256 userWeight = _amount*votingescrow.balanceOf(_user);
                if (userGaugeWeights[_user][_gauge] < userWeight) {
                    gauge[_gauge].weight += userWeight-userGaugeWeights[_user][_gauge];
                    totalWeight += userWeight-userGaugeWeights[_user][_gauge];
                } else if (userGaugeWeights[_user][_gauge] > userWeight) {
                    gauge[_gauge].weight -= userGaugeWeights[_user][_gauge]-userWeight;
                    totalWeight -= userGaugeWeights[_user][_gauge]-userWeight;
                }
                userGaugeWeights[_user][_gauge] = userWeight;
            }
        }
    }

    function userCheckpointGauge(address _gauge, address _user) external {
        uint256 _amount = userGaugeVotes[_user][_gauge];
        if (_amount > 0) {
            uint256 userWeight = _amount*votingescrow.balanceOf(_user);
            if (userGaugeWeights[_user][_gauge] < userWeight) {
                gauge[_gauge].weight += userWeight-userGaugeWeights[_user][_gauge];
                totalWeight += userWeight-userGaugeWeights[_user][_gauge];
            } else if (userGaugeWeights[_user][_gauge] > userWeight) {
                gauge[_gauge].weight -= userGaugeWeights[_user][_gauge]-userWeight;
                totalWeight -= userGaugeWeights[_user][_gauge]-userWeight;
            }
            userGaugeWeights[_user][_gauge] = userWeight;  
        }
    }

    function _checkpointAll() public {
        for(uint256 i=0; i<gauges.length; i++) {
            address _gauge = gauges[i];
            if (gauge[_gauge].checkpoint < votingescrow.epoch()) {
                IGauge(_gauge).setEmission(baseEmission*gauge[_gauge].weight/totalWeight);
                gauge[_gauge].checkpoint = votingescrow.epoch();
            }
        }
    }

    function _checkpoint(address _gauge) public {
        if (gauge[_gauge].checkpoint < votingescrow.epoch()) {
            IGauge(_gauge).setEmission(baseEmission*gauge[_gauge].weight/totalWeight);
            gauge[_gauge].checkpoint = votingescrow.epoch();
        }
    }

    function setBaseEmission(uint256 _baseEmission) external onlyOwner {
        baseEmission = _baseEmission;

        emit NextBaseEmission(_baseEmission);
    }

    function forceBaseEmission(uint256 _baseEmission) external onlyOwner {
        baseEmission = _baseEmission;
        for(uint256 i=0; i<gauges.length; i++) {
            address _gauge = gauges[i];
            IGauge(_gauge).setEmission(baseEmission*gauge[_gauge].weight/totalWeight);
        }

        emit ForceBaseEmission(_baseEmission);
    }

    function gaugesLength() external view returns (uint) {
        return gauges.length;
    }

    function mint(address _to, uint _amount) external {
        require(minter[msg.sender], "!Minter");
        if(_amount > 0) {
            IERC20(votingescrow.token()).transfer(_to, _amount);
        }
    }

    // META-TX

    mapping(address => bool) public isTrustedForwarder;

    function setTrustedForwarder(address _forwarder, bool _bool) external onlyOwner {
        isTrustedForwarder[_forwarder] = _bool;
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (isTrustedForwarder[msg.sender]) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }  

    // EVENTS
    event CreateGauge(address _gauge, address _lp);
    event KillGauge(address _gauge);
    event NextBaseEmission(uint _baseEmission);
    event ForceBaseEmission(uint _baseEmission);
}



// ===== GAUGE CONTRACT =====

contract RewardGauge is Context {

    IERC20 public immutable reward;
    IERC20 public immutable lp;

    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public workingUserStaked;
    mapping(address => uint256) public userPaid;

    uint256 public totalStaked; // Total amount of lp staked
    uint256 public workingTotalStaked;
    uint256 public accRewardsPerLP; // Accumulated rewards per staked LP
    uint256 public emission; // Token being emitted per second
    uint256 public lastUpdate; // Last time updatePool() was called

    IRewardGaugeController public controller;
    bool public isKilled;
    IVotingEscrow public immutable votingescrow;

    constructor(address _lp, address _reward, address _controller) {
        lp = IERC20(_lp);
        reward = IERC20(_reward);
        controller = IRewardGaugeController(_controller);
        votingescrow = IVotingEscrow(IRewardGaugeController(_controller).votingescrow());
    }

    function deposit(uint256 amount) external {
        address user = _msgSender();
        _claim(user);
        lp.transferFrom(user, address(this), amount);
        userStaked[user] += amount;
        totalStaked += amount;
        updateWorkingState(user);
        userPaid[user] = accRewardsPerLP*workingUserStaked[user]/1e18;
    }

    function depositWithPermit(uint256 amount, uint256 _deadline, bool _maxAllow, uint8 v, bytes32 r, bytes32 s) external {
        address user = _msgSender();
        _claim(user);
        uint _toAllow = amount;
        if (_maxAllow) _toAllow = type(uint).max;
        IERC20Permit(address(lp)).permit(_msgSender(), address(this), _toAllow, _deadline, v, r, s);
        lp.transferFrom(user, address(this), amount);
        userStaked[user] += amount;
        totalStaked += amount;
        updateWorkingState(user);
        userPaid[user] = accRewardsPerLP*workingUserStaked[user]/1e18;
    }    

    function withdraw(uint256 amount) external {
        address user = _msgSender();
        _claim(user);
        if (userStaked[user] < amount) amount = userStaked[user];
        userStaked[user] -= amount;
        totalStaked -= amount;
        updateWorkingState(user);
        lp.transfer(user, amount);
        userPaid[user] = accRewardsPerLP*workingUserStaked[user]/1e18;
    }

    function claim() external {
        _claim(_msgSender());
    }

    function _claim(address user) private {
        uint256 amount = pending(user);
        updatePool();
        userPaid[user] += amount;
        updateWorkingState(user);
        controller.mint(user, amount);
        controller.userCheckpointGauge(address(this), user);
    }

    function updatePool() private {
        uint256 time = block.timestamp;
        if (totalStaked > 0) {
            accRewardsPerLP += emission*(time-lastUpdate)*1e18/workingTotalStaked;
        }
        lastUpdate = time;
    }

    function updateWorkingState(address user) private {
        uint voting_balance = votingescrow.balanceOf(user);
        uint voting_total = votingescrow.totalSupply();
        uint lim = userStaked[user]*40/100;
        if (voting_total > 0) {
            lim += totalStaked*voting_balance/voting_total*60/100;
        }
        if (userStaked[user] < lim) {
            lim = userStaked[user];
        }
        uint _oldWorkingUserStaked = workingUserStaked[user];
        workingUserStaked[user] = lim;
        workingTotalStaked = workingTotalStaked+lim-_oldWorkingUserStaked;
    }

    function setEmission(uint256 _emission) external {
        require(_msgSender() == address(controller), "!Permission");
        updatePool();
        emission = _emission;
    }

    function setKilled() external {
        require(_msgSender() == address(controller), "!Permission");
        updatePool();
        emission = 0;
        isKilled = true;
    }

    function pending(address user) public view returns (uint256) {
        if (totalStaked == 0) return 0;
        return (workingUserStaked[user]*(accRewardsPerLP+(emission*(block.timestamp-lastUpdate)*1e18/workingTotalStaked))/1e18)-userPaid[user];
    }

    // function _msgSender() internal view override returns (address sender) {
    //     if (controller.isTrustedForwarder(msg.sender)) {
    //         // The assembly code is more direct than the Solidity version using `abi.decode`.
    //         /// @solidity memory-safe-assembly
    //         assembly {
    //             sender := shr(96, calldataload(sub(calldatasize(), 20)))
    //         }
    //     } else {
    //         return super._msgSender();
    //     }
    // }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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