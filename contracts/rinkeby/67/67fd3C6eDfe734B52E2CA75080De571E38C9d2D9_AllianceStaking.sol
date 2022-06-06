//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Managable.sol";

contract AllianceStaking is Managable, Pausable {
    struct Stake {
        uint256 id;
        address token;
        uint256 amount;
        uint256 seats;
        uint256 unlocksAt;
    }

    struct StakingOptions {
        uint256 pricePerSeat;
        uint256 lockTime;
    }

    // Storage
    mapping(uint256 => uint256) public seats;
    mapping(address => Stake[]) public addressStakings;
    mapping(address => StakingOptions) public stakingOptions;

    // Events
    event AddedStake(address indexed _addr, uint256 indexed _id, uint256 _amount, address _token);
    event RemovedStake(address indexed _addr, uint256 indexed _id, uint256 _amount, address _token);
    event ChangedAllianceStaking(uint256 indexed _id, uint256 _seats);
    event AddedStakingOptions(address indexed _addr, uint256 _pricePerSeat, uint256 _lockTime);
    event RemovedStakingOptions(address indexed _addr);

    constructor() {
        _addManager(msg.sender);
    }

    function stakes() external view returns(Stake[] memory) {
        return addressStakings[msg.sender];
    }

    function stake(uint256 _id, uint256 _amount, address _token) external whenNotPaused {
        _stake(msg.sender, _id, _amount, _token);
    }

    function unstake(uint256 _idx) external whenNotPaused {
        _unstake(msg.sender, _idx);
    }

    function unstakeAll() external whenNotPaused {
        address _addr = msg.sender;
        for(uint256 i = 0; i < addressStakings[_addr].length; i++) {
            _unstake(_addr, i);
        }
    }

    function addStakingToken(address _addr, uint256 _pricePerSeat, uint256 _lockTime) external onlyManager {
        _addToken(_addr, _pricePerSeat, _lockTime);
    }

    function removeStakingToken(address _addr) external onlyManager {
        _removeToken(_addr);
    }

    function allianceSeats(uint256 _id) external view returns(uint256) {
        return seats[_id];
    }

    function pause() external onlyManager {
        _pause();
    }

    function unpause() external onlyManager {
        _unpause();
    }

    // Internal functions
    function _stake(address _sender, uint256 _id, uint256 _amount, address _token) internal {
        StakingOptions memory _opts = stakingOptions[_token];
        require(_opts.pricePerSeat > 0, "price per seat is zero");

        uint256 _seats = _amount / _opts.pricePerSeat;
        require(_seats > 0, "zero seats added");
        uint256 _stakeAmount = _seats * _opts.pricePerSeat;

        Stake memory _s = Stake({
            id: _id,
            token: _token,
            amount: _stakeAmount,
            seats: _seats,
            unlocksAt: block.timestamp + _opts.lockTime
        });
        seats[_id] += _seats;
        addressStakings[_sender].push(_s);

        IERC20(_token).transferFrom(_sender, address(this), _stakeAmount);
        emit AddedStake(_sender, _id, _amount, _token);
        emit ChangedAllianceStaking(_id, seats[_id]);   
    }

    function _unstake(address _sender, uint256 _idx) internal {
        Stake memory _s = addressStakings[_sender][_idx];

        require(_s.amount > 0, "amount is zero");
        require(_s.token != address(0), "token address is zero");
        require(_s.unlocksAt < block.timestamp, "amount is locked");

        for(uint i = _idx; i < addressStakings[_sender].length - 1; i++) {
            addressStakings[_sender][i] = addressStakings[_sender][i+1];      
        }
        addressStakings[_sender].pop();
        seats[_s.id] -= _s.seats;

        IERC20(_s.token).transfer(_sender, _s.amount);
        emit RemovedStake(_sender, _s.id, _s.amount, _s.token);
        emit ChangedAllianceStaking(_s.id, seats[_s.id]);          
    }

    function _addToken(address _addr, uint256 _pricePerSeat, uint256 _lockTime) internal {
        require(_addr != address(0), "address is zero");
        require(_pricePerSeat > 0, "price per seat is zero");

        StakingOptions memory _opts = StakingOptions({
            pricePerSeat: _pricePerSeat,
            lockTime: _lockTime
        });

        stakingOptions[_addr] = _opts;
        emit AddedStakingOptions(_addr, _pricePerSeat, _lockTime);
    }

    function _removeToken(address _addr) internal {
        delete(stakingOptions[_addr]);
        emit RemovedStakingOptions(_addr);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
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