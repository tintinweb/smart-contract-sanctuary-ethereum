// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";

import "IStakingPool.sol";
import "IstETHToken.sol";
import "CheckContract.sol";

contract StakingPool is IStakingPool, Ownable, CheckContract {
    uint256 internal constant DECIMAL_PRECISION = 1e18;
    uint256 public withdrawAmount;
    uint256 public feePercentage = 0;
    uint256 public LOCKED_WITHDRAWAL_PERIOD = 86400;

    IstETHToken public stETHToken;
    uint256 public totalETHDeposits;
    uint256 public totalUserRewards;

    struct RequestWithdraw {
        uint256 ETHAmount;
        uint256 stETHAmount;
        uint256 conversionRate;
        uint256 withdrawlTime;
    }

    // Rewards tracker
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;
    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    mapping(address => RequestWithdraw) public withdrawRequest;

    // Rewards snapshots
    struct Snapshots {
        uint P;
        uint G;
        uint128 scale;
        uint128 epoch;
    }
    uint256 public P = DECIMAL_PRECISION;
    mapping (address => uint) public deposits;  // depositor address -> deposited amount
    mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct


    function setAddresses(address _stETHTokenAddress) external onlyOwner {
        stETHToken = IstETHToken(_stETHTokenAddress);

        checkContract(_stETHTokenAddress);

        emit stETHTokenAddressChanged(_stETHTokenAddress);
    }

    // --- Getters for public variables. ---
    function gestETHDeposits() external view returns (uint256) {
        return address(this).balance;
    }

    function getMaxWithdrawalAmount(address _user)
        external
        view
        returns (uint256)
    {
        uint256 stETHBalance = stETHToken.balanceOf(_user);
        return convertstETHToETH(stETHBalance);
    }

    function getWithdrawAmount() external view override returns (uint256) {
        return withdrawAmount;
    }

    function getWithdrawDetails(address _address)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        RequestWithdraw memory nftVariable = withdrawRequest[_address];
        return (
            nftVariable.ETHAmount,
            nftVariable.stETHAmount,
            nftVariable.conversionRate,
            nftVariable.withdrawlTime
        );
    }

    function withdrawETHFromStakingPool(uint256 _amount) external {
        uint256 stETHAmount = convertETHTostETH(_amount);
        require(
            stETHToken.balanceOf(msg.sender) >= stETHAmount,
            "StakingPool: Insufficient stETH balance in user wallet"
        );
        RequestWithdraw memory value = withdrawRequest[msg.sender];
        require(
            value.withdrawlTime <= block.timestamp,
            "WithdrawalPool: Withdrawal can only be made after the mentioned time"
        );
        uint initialDeposit = convertstETHToETH(_amount);
        require(initialDeposit > 0, "StakingPool: Initial deposit is 0");
        // stETH token burn
        stETHToken.burn(msg.sender, stETHAmount);
        withdrawAmount -= _amount;
        totalETHDeposits -= _amount;

        // Update deposit
        uint newDeposit = initialDeposit - _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "StakingPool: Transfer to User failed");
    }

    // StakingPool interaction functions

    function requestWithdrawFromStakingPool(uint256 _amount) external override {
        uint256 stETHAmount = convertETHTostETH(_amount);
        require(
            stETHToken.balanceOf(msg.sender) >= stETHAmount,
            "StakingPool: Insufficient stETH balance in user wallet"
        );
        uint256 conversionRate = getConversionRate();

        withdrawAmount += _amount;

        withdrawRequest[msg.sender] = RequestWithdraw(
            _amount,
            stETHAmount,
            conversionRate,
            block.timestamp + LOCKED_WITHDRAWAL_PERIOD
        );
        emit requestWithdrawFromStakingPoolEvent(_amount, conversionRate, stETHAmount);
    }

    function provideToStakingPool() external payable override {
        require(
            (msg.sender).balance >= msg.value,
            "StakingPool: Insufficient ETH balance in user wallet"
        );

        // Transfer of stETH to depositor
        uint256 stETHAmount = convertETHTostETH(msg.value);
        stETHToken.mint(msg.sender, stETHAmount);


        // Current USDC deposit based on updated CR
        uint initialDeposit = deposits[msg.sender];

        // Update deposit
        uint newDeposit = initialDeposit + msg.value;
        _updateDepositAndSnapshots(msg.sender, newDeposit);

        totalETHDeposits += msg.value;

        //Stable coin transfer from lender to SP
        bool sentToStakingInterface = _sendETHtoStakingPool(
            address(this),
            msg.value
        );
        require(
            sentToStakingInterface,
            "StakingPool: Transfer to StakingInterface failed"
        );
        emit provideToStakingPoolEvent(msg.value, stETHAmount);
    }

    // Transfer the ETH tokens from the user to the Staking Pool's address, and update its recorded ETH
    function _sendETHtoStakingPool(address _address, uint256 _amount)
        internal
        returns (bool)
    {
        (bool success, ) = payable(_address).call{value: _amount}("");
        return success;
    }

     // --- Staking Pool Deposit Functionality ---
    function _updateDepositAndSnapshots(address _depositor, uint _newValue) internal {
        deposits[_depositor] = _newValue;

        if (_newValue == 0) {
            delete depositSnapshots[_depositor];
            emit DepositSnapshotUpdated(_depositor, 0, 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentP = P;

        // Get S and G for the current epoch and current scale
        uint currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P and sum S for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].G = currentG;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(_depositor, currentP, currentG);
    }

    // ETH - stETH conversion functions
    function convertstETHToETH(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 CR = getConversionRate();

        uint256 ETHAmount = (_amount * CR) / DECIMAL_PRECISION;
        return ETHAmount;
    }

    function convertETHTostETH(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 CR = getConversionRate();

        uint256 stETHAmount = (_amount * DECIMAL_PRECISION) / CR;
        return stETHAmount;
    }

    function getConversionRate() public view returns (uint256) {
        uint256 totalETH = (address(this)).balance;
        uint256 totalstETH = stETHToken.totalSupply();

        uint256 CR = totalETH == 0 || totalstETH == 0
            ? DECIMAL_PRECISION
            : (totalETH * DECIMAL_PRECISION) / totalstETH;
        return CR;
    }

    function modifyLockedWithdrawlPeriod(uint256 _time)
        external
        onlyOwner
        returns (uint256)
    {
        LOCKED_WITHDRAWAL_PERIOD = _time;
        return LOCKED_WITHDRAWAL_PERIOD;
    }

    // --- Fallback function ---

    receive() external payable {
        totalETHDeposits += msg.value;
        emit StakingPoolRecieveFallback(totalETHDeposits, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity >=0.8.0;

interface IStakingPool {
    // Events
    event StakingPoolUSDCBalanceUpdated(uint _newBalance);
    event stETHTokenAddressChanged(address _tusdcTokenAddress);
    event StakingPoolRecieveFallback(uint totalETHDeposits, uint amount);
    event DepositSnapshotUpdated(address _depositor, uint _P, uint _G);
    event provideToStakingPoolEvent(uint _amount, uint _stEthminted);
    event requestWithdrawFromStakingPoolEvent(uint _amount, uint _conversionRate, uint _stETHAmount);
    // Functions

    function provideToStakingPool() external payable;

    function requestWithdrawFromStakingPool(uint _amount) external;

    function convertstETHToETH(uint _amount) external view returns (uint);

    function convertETHTostETH(uint _amount) external view returns (uint);

    function getWithdrawDetails(address _address) external view returns (uint, uint, uint, uint);

    function getWithdrawAmount() external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IstETHToken is IERC20, IERC2612 { 
    
    // --- Events ---
    
    event stakingPoolAddressChanged(address _stakingPoolAddress);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}