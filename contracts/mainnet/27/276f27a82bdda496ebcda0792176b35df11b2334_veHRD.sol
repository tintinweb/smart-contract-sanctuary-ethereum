// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract veHRD is Ownable, ReentrancyGuard {
    uint256 private _tokenIds;

    uint256 private emissions = 1_500_000 * (10 ** 9);

    uint256[3] private periods = [604800, 2419200, 29030400];

    uint256 private constant lockerLimit = 99;

    uint256 private votingPower;

    bool private canSetHoarder;
    bool private canSetTransfers;

    address public hoarder;
    bool public transfers = true;

    struct Locker {
        uint256 id;
        address minter;
        address locker;
        uint256 created;
        uint256 unlocks;
        uint256 amount;
        uint256 interest;
        bool locked;
        uint256 period;
    }

    mapping (uint256 => Locker) private lockers;
    mapping (address => Locker[]) private lockersByVoter;
    mapping (address => uint256) private lockersByVoterTotal;
    mapping (uint256 => uint256) private lockersByVoterIds;

    mapping (address => address) private delegateeByVoter;
    mapping (address => uint256) private lastDelegationByVoter;

    IERC20 private immutable HRD;
    IERC20 private immutable USDH;

    IVault private _weekVault;
    IVault private _monthVault;
    IVault private _yearVault;

    bool private initialized;

    constructor() {
        HRD = IERC20(0x461B71cff4d4334BbA09489acE4b5Dc1A1813445);
        USDH = IERC20(0xe350E32ca91B04F2D7307185BB352F0b7E7BcE35);
        _weekVault = IVault(0x6D81D0B84bDe2C41227E11ACBF64080752380882);
        _monthVault = IVault(0x4bfBE723264baFCA7e8774f5352aED0653A6B692);
        _yearVault = IVault(0xb92dEb93436aa953bA4a89470e2ddD6C44026419);
        hoarder = msg.sender;
    }

    function initialize() external nonReentrant onlyOwner {
        require(!initialized);
        require(HRD.balanceOf(msg.sender) >= emissions && HRD.allowance(msg.sender, address(this)) >= emissions);
        HRD.transferFrom(msg.sender, address(this), emissions);
        require(HRD.balanceOf(address(this)) == emissions);
        uint256 _max = type(uint256).max;
        USDH.approve(address(_weekVault), _max);
        USDH.approve(address(_monthVault), _max);
        USDH.approve(address(_yearVault), _max);
        initialized = true;
    }

    function createLocker(uint256 _amount, uint256 _period) external nonReentrant returns (uint256) {
        require(initialized && _amount > 0 && (_period > 0 && _period < 4) && lockersByVoterTotal[msg.sender] < lockerLimit);

        require(HRD.balanceOf(msg.sender) >= _amount && HRD.allowance(msg.sender, address(this)) >= _amount);
        uint256 balance = HRD.balanceOf(address(this));
        HRD.transferFrom(msg.sender, address(this), _amount);
        require(HRD.balanceOf(address(this)) == balance + _amount);

        uint256 _tokenId = _tokenIds;
        _tokenIds = _tokenIds + 1;

        uint256 _balance = getBalances(msg.sender)[_period - 1];

        uint256 _seconds = periods[_period - 1];
        uint256 _interest = _amount * 50 / 10000;
        if (_period == 1) {
            _weekVault.setBalance(msg.sender, _balance + 1);
        } else if (_period == 2) {
            _monthVault.setBalance(msg.sender, _balance + 1);
            _interest = _amount * 250 / 10000;
        } else if (_period == 3) {
            _yearVault.setBalance(msg.sender, _balance + 1);
            _interest = _amount * 4500 / 10000;
        }
        votingPower = votingPower + (_seconds * _amount);

        if (_interest > emissions) _interest = emissions > 0 ? emissions : 0;
        if (_interest > 0) emissions = emissions - _interest;

        Locker memory _locker = Locker(_tokenId, msg.sender, address(0), block.timestamp, block.timestamp + _seconds, _amount, _interest, true, _period);
        lockers[_tokenId] = _locker;
        lockersByVoter[msg.sender].push(_locker);
        lockersByVoterIds[_tokenId] = lockersByVoterTotal[msg.sender];
        lockersByVoterTotal[msg.sender] = lockersByVoterTotal[msg.sender] + 1;

        return _tokenId;
    }

    function claimUSDH(uint256 _id) external nonReentrant {
        Locker memory _locker = lockers[_id];
        require(_locker.minter == msg.sender);
        require(_locker.unlocks > block.timestamp);
        require(_locker.locked);

        _refresh(msg.sender, _locker.period, false);

        Locker memory _lockerNew = Locker(_id, _locker.minter, _locker.locker, _locker.created, _locker.unlocks, _locker.amount, _locker.interest, _locker.locked, _locker.period);
        lockers[_id] = _lockerNew;
        lockersByVoter[msg.sender][lockersByVoterIds[_id]] = _lockerNew;
    }

    function _refresh(address _voter, uint256 _period, bool _slash) private {
        uint256[3] memory _balances = getBalances(_voter);
        uint256 _amount;
        if (_period == 1) _amount = _weekVault.claimUSDH(_voter);
        else if (_period == 2) _amount = _monthVault.claimUSDH(_voter);
        else if (_period == 3) _amount = _yearVault.claimUSDH(_voter);
        if (_amount > 0) {
            if (_slash) {
                uint256 _reward = _amount * 250 / 10000;
                USDH.transfer(msg.sender, _reward);
                USDH.transfer(_voter, _amount - _reward);
            } else {
                USDH.transfer(_voter, _amount);
            }
        }
        _weekVault.setBalance(_voter, _balances[0]);
        _monthVault.setBalance(_voter, _balances[1]);
        _yearVault.setBalance(_voter, _balances[2]);
    }

    function _unlockHRD(uint256 _id, bool _slash) private {
        Locker memory _locker = lockers[_id];
        require(_locker.unlocks <= block.timestamp && _locker.locked);
        _refresh(_locker.minter, _locker.period, _slash);
        uint256 _amount = _locker.amount;
        if (_locker.interest > 0) _amount = _amount + _locker.interest;
        HRD.transfer(_locker.minter, _amount);
        Locker memory _lockerNew = Locker(_id, _locker.minter, msg.sender, _locker.created, _locker.unlocks, _locker.amount, _locker.interest, false, _locker.period);
        lockers[_id] = _lockerNew;
        lockersByVoter[_locker.minter][lockersByVoterIds[_id]] = _lockerNew;
        votingPower = votingPower - (periods[_locker.period - 1] * _locker.amount);
    }

    function unlockHRD(uint256 _id) external nonReentrant {
        require(lockers[_id].minter == msg.sender);
        _unlockHRD(_id, false);
    }

    function slashLocker(uint256 _id) external nonReentrant {
        Locker memory _locker = lockers[_id];
        require(_locker.unlocks <= block.timestamp && _locker.locked);
        _unlockHRD(_id, true);
    }

    function delegateVotes(address _delegatee) external nonReentrant {
        require(block.timestamp + 86400 >= lastDelegationByVoter[msg.sender]);
        lastDelegationByVoter[msg.sender] = block.timestamp;
        delegateeByVoter[msg.sender] = _delegatee;
    }

    function getVotingPowerTotal() external view returns (uint256) {
        return votingPower;
    }

    function getVotingPower(address _voter) external view returns (uint256) {
        uint256 _votingPower;
        uint256 _matches = lockersByVoterTotal[_voter];
        Locker[] memory _array = lockersByVoter[_voter];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].locked && _array[_i].unlocks > block.timestamp) _votingPower = _votingPower + (periods[_array[_i].period - 1] * _array[_i].amount);
        }
        return _votingPower;
    }

    function getDelegateeByVoter(address _voter) external view returns (address) {
        return delegateeByVoter[_voter];
    }

    function getLastDelegationByVoter(address _voter) external view returns (uint256) {
        return lastDelegationByVoter[_voter];
    }

    function getLocker(uint256 _id) external view returns (Locker memory) {
        return lockers[_id];
    }

    function getLockersByVoter(address _voter) external view returns (Locker[] memory) {
        return lockersByVoter[_voter];
    }

    function getLockersByVoterTotal(address _voter) external view returns (uint256) {
        return lockersByVoterTotal[_voter];
    }

    function getVaults() external view returns (address, address, address) {
        return (address(_weekVault), address(_monthVault), address(_yearVault));
    }

    function deposit(uint256 _amount, uint256 _period) external nonReentrant {
        require(hoarder == msg.sender);
        require(_period > 0 && _period < 4);
        require(USDH.balanceOf(msg.sender) >= _amount && USDH.allowance(msg.sender, address(this)) >= _amount);
        uint256 balance = USDH.balanceOf(address(this));
        USDH.transferFrom(msg.sender, address(this), _amount);
        require(USDH.balanceOf(address(this)) == balance + _amount);
        if (_period == 1) _weekVault.deposit(_amount);
        else if (_period == 2) _monthVault.deposit(_amount);
        else if (_period == 3) _yearVault.deposit(_amount);
    }

    function getBalances(address _voter) public view returns (uint[3] memory) {
        uint256[3] memory _balances;
        uint256 _matches = lockersByVoterTotal[_voter];
        Locker[] memory _array = lockersByVoter[_voter];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].locked && _array[_i].unlocks > block.timestamp) _balances[_array[_i].period - 1] = _balances[_array[_i].period - 1] + 1;
        }
        return _balances;
    }

    function setHoarder(address _hoarder, bool _canSetHoarder) external nonReentrant onlyOwner {
        require(canSetHoarder);
        hoarder = _hoarder;
        canSetHoarder = _canSetHoarder;
    }

    function setTransfers(bool _transfers, bool _canSetTransfers) external nonReentrant onlyOwner {
        require(canSetTransfers);
        transfers = _transfers;
        canSetTransfers = _canSetTransfers;
    }

    function rescue(address token) external nonReentrant onlyOwner {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(token != address(HRD));
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IVault {
    function setBalance(address _voter, uint256 _amount) external;
    function deposit(uint256 _amount) external;
    function claimUSDH(address _voter) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}