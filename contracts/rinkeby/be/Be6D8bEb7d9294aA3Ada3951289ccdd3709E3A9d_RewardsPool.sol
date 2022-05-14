// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";

import "SafeMath.sol";
import "CheckContract.sol";
import "IRewardsPool.sol";
import "IStakingPool.sol";
import "IUSDCToken.sol";
import "ICollateralPool.sol";
import "IActivePool.sol";
import "IoETHToken.sol";
import "IBorrowersRewardsPool.sol";
import "IUniswapV2Router02.sol";
import "ISortedVaults.sol";
import "IOrumRevenue.sol";

contract RewardsPool is IRewardsPool, Ownable, CheckContract{
    IUSDCToken public usdc_token;
    IStakingPool public staking_pool;
    ICollateralPool public collateral_pool;
    IActivePool public active_pool;
    IoETHToken public oeth_token;
    IBorrowersRewardsPool public borrowers_rewards_pool;
    IUniswapV2Router02 public uniswapV2Router02;
    ISortedVaults public sortedVaults;
    IOrumRevenue public orum_revenue;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 500;

    address treasury;

    uint constant public DECIMAL_PRECISION = 1e18;
    uint public totalUSDCRewards;
    uint public totaloETHRewards;

    struct RewardsRatios {
        uint StakingPool;
        uint Treasury;
        uint Borrowers;
    }

    RewardsRatios public rewardsRatios;

    function setAddresses(
        address _usdcToken,
        address _stakingPool,
        address _treasury,
        address _collateralPool,
        address _activePool,
        address _oethToken,
        address _borrowersRewardsPoolAddress,
        address _swapRouterAddress,
        address _sortedVaultAddress
    ) 
    external 
    onlyOwner
    {
        usdc_token = IUSDCToken(_usdcToken);
        staking_pool = IStakingPool(_stakingPool);
        treasury = _treasury;
        collateral_pool = ICollateralPool(_collateralPool);
        active_pool = IActivePool(_activePool);
        oeth_token = IoETHToken(_oethToken);
        borrowers_rewards_pool = IBorrowersRewardsPool(_borrowersRewardsPoolAddress);
        uniswapV2Router02 = IUniswapV2Router02(_swapRouterAddress);
        sortedVaults = ISortedVaults(_sortedVaultAddress);
        orum_revenue = IOrumRevenue(_treasury);

        checkContract(_usdcToken);
        checkContract(_stakingPool);
        checkContract(_treasury);
        checkContract(_collateralPool);
        checkContract(_activePool);
        checkContract(_oethToken);
        checkContract(_borrowersRewardsPoolAddress);
        // checkContract(_swapRouterAddress);
        checkContract(_sortedVaultAddress);

        emit UsdcTokenAddressChanged(_usdcToken);
        emit StakingPoolAddressChanged(_stakingPool);
        emit OrumRevenueAddressChanged(_treasury);
        emit CollateralPoolAddressChanged(_collateralPool);
        emit ActivePoolAddressChanged(_activePool);
        emit OETHTokenAddressChanged(_oethToken);
        emit BorrowersRewardsPoolAddressChanged(_borrowersRewardsPoolAddress);
        emit SwapRouterAddressChanged(_swapRouterAddress);
        emit SortedVaultsAddressChanged(_sortedVaultAddress);
    
    }

    function setRewardsRatio(uint _StakingPoolRatio, uint _TreasuryRatio, uint _BorrowersRatio) external onlyOwner {
        require((_StakingPoolRatio + _TreasuryRatio + _BorrowersRatio) == 100, "RewardsPool: Total ratio does not add upto 100%");

        rewardsRatios.StakingPool = _StakingPoolRatio;
        rewardsRatios.Treasury = _TreasuryRatio;
        rewardsRatios.Borrowers = _BorrowersRatio;
    }

    function swapethToUSDC(uint _amount) public payable returns (uint) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router02.WETH(); 
        path[1] = address(usdc_token);
        uint[] memory _amounts = new uint[](path.length);
        _amounts = uniswapV2Router02.swapExactETHForTokens{ value:  _amount }(0, path, address(this), block.timestamp+300);
        require(_amounts[1] > 0, "RewardsPool: swapping Failed");
    }

    function _transferUSDCRewards(uint256 _rewards) internal {
        //Rewards split
        uint spRewards = _rewards;

        // 80%(initial) of block rewards to the stability pool
        bool success_spRewards = usdc_token.transfer(address(staking_pool), spRewards);
        require(success_spRewards, "RewardsPool: sending SP rewards failed");
        staking_pool.rewardsOffset(spRewards); 
    }

    function _transferRewards(uint _rewards) internal {
        if(staking_pool.getUSDCDeposits() > 0) {
            // USDC rewards to stability pool
            uint amount = (_rewards * (100 - rewardsRatios.Borrowers - rewardsRatios.Treasury)) / 100;
            swapethToUSDC(amount);
            uint USDCRewards = usdc_token.balanceOf(address(this));
            _transferUSDCRewards(USDCRewards);
            totalUSDCRewards += USDCRewards;

            // oETH rewards to borrower's + treasury
            (bool success, ) = payable(address(collateral_pool)).call{ value: address(this).balance }("");
            require(success, "RewardsPool: ETH transfer to CP failed");
            uint oeth_rewards = oeth_token.balanceOf(address(this));
            uint oeth_rewards_scaled = (oeth_rewards * 100) / (rewardsRatios.Borrowers + rewardsRatios.Treasury);
            totaloETHRewards += oeth_rewards;

            // Borrower rewards
            if (sortedVaults.getSize() > 0 && rewardsRatios.Borrowers > 0 ){
                uint b_rewards = (oeth_rewards_scaled * rewardsRatios.Borrowers) / 100;
                oeth_token.transfer(address(borrowers_rewards_pool), b_rewards);
                borrowers_rewards_pool.receiveoETHBorrowersRewardsPool(b_rewards);
            }
            else {
                uint b_rewards = (oeth_rewards_scaled * rewardsRatios.Borrowers) / 100;
                oeth_token.transfer(address(orum_revenue), b_rewards);
                orum_revenue.checkpoint_token();
            }

            // Treasury rewards
            uint t_rewards = (oeth_rewards_scaled * rewardsRatios.Treasury) / 100;
            oeth_token.transfer(address(orum_revenue), t_rewards);
            orum_revenue.checkpoint_token();
        }
        else {
            // oETH rewards to borrower's + treasury
            (bool success, ) = payable(address(collateral_pool)).call{ value: address(this).balance }("");
            require(success, "RewardsPool: ETH transfer to CP failed");
            uint oeth_rewards = oeth_token.balanceOf(address(this));
            totaloETHRewards += oeth_rewards;

            // Borrower rewards
            if (sortedVaults.getSize() > 0 && rewardsRatios.Borrowers > 0 ){
                uint b_rewards = (oeth_rewards * rewardsRatios.Borrowers) / 100;
                oeth_token.transfer(address(borrowers_rewards_pool), b_rewards);
                borrowers_rewards_pool.receiveoETHBorrowersRewardsPool(b_rewards);
            }
            else {
                uint b_rewards = (oeth_rewards * rewardsRatios.Borrowers) / 100;
                oeth_token.transfer(address(orum_revenue), b_rewards);
                orum_revenue.checkpoint_token();
            }

            // Treasury rewards
            uint t_rewards = (oeth_rewards * (rewardsRatios.Treasury + rewardsRatios.StakingPool)) / 100;
            oeth_token.transfer(address(orum_revenue), t_rewards);
            orum_revenue.checkpoint_token();
        }
    }

    receive() external payable {
        _transferRewards(msg.value);
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

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 * 
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


interface IRewardsPool{
    // --Events

    event UsdcTokenAddressChanged(address _usdcToken);
    event StakingPoolAddressChanged(address _stakingPool);
    event OrumRevenueAddressChanged(address _treasury);
    event CollateralPoolAddressChanged(address _collateralPool);
    event ActivePoolAddressChanged(address _activePool);
    event OETHTokenAddressChanged(address _oethToken);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event SwapRouterAddressChanged(address _swapRouterAddress);
    event SortedVaultsAddressChanged(address _sortedVaultAddress);

    // --Function
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IUSDCToken.sol";

interface IStakingPool {
    // Events

    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event OETHTokenChanged(address _oETHToken);
    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event CommunityIssuanceAddressChanged(address _communityIssuanceAddress);
    event RewardsPoolAddressChanged(address _rewardsPoolAddress);
    event OUSDCTokenChanged(address _oUSDCToken);
    event BufferPoolAddress(address _bufferPoolAddress);
    event ExternalStakerChanged(address _address);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);
    event StakingPoolUSDCBalanceUpdated(uint _newBalance);
    event StakingPoolReceivedETH(uint value);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event sendUSDCtoBorrowerEvent(address _to,uint _amount);
    event USDCSent(address _to,uint _amount);
    event DepositSnapshotUpdated(address _depositor, uint _P, uint _G);
    event BufferRatioUpdated(uint _buffer, uint _staking);

    // Functions

    function provideToStakingPool(uint _amount) external;
    
    function decreaseLentAmount(uint _amount) external;

    function allowBorrow() external returns (bool);

    function withdrawFromStakingPool(uint _amount) external;

    function sendUSDCtoBorrower(address _to, uint _amount) external;

    function getDepositorOrumGain(address _depositor) external returns (uint);

    function getUSDCDeposits() external returns (uint);

    function getUtilisationRatio() external view returns (uint);

    function convertOUSDCToUSDC(uint _amount) external view returns (uint);

    function convertUSDCToOUSDC(uint _amount) external view returns (uint);

    function rewardsOffset(uint _rewards) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event StakingPoolAddressChanged(address _newStakingPoolAddress);

    event USDCTokenBalanceUpdated(address _user, uint _amount);

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

interface ICollateralPool {
    // --- Events ---
    event oETHTokenAddressChanged(address _oETHTokenAddress);
    event BufferPoolAddressChanged(address _bufferPoolAddress);
    event ExternalStakingAddressChanged(address _address);

    event OETHTokenMintedTo(address _account, uint _amount);
    event oethSwappedToeth(address _from, address _to,uint _amount);
    event BufferRatioUpdated(uint _buffer, uint staking);

    // --- Functions ---
    function swapoETHtoETH(uint _amount) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoETHToken.sol";


interface IActivePool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event OETHTokenAddressChanged(address _oETHTokenAddress);
    event CollateralPoolAddressChanged(address _collateralPoolAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event UniswapV2Router02AddressChanged(address _uniswapAddress);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event StakingInterfaceAddressChanged(address _stakingInterfaceAddress);
    event BufferPoolAddressChanged(address _bufferPoolAddress);
    
    event ActivePoolUSDCDebtUpdated(uint _USDCDebt);
    event ActivePooloETHBalanceUpdated(uint oETH);
    event SentoETHActiveVault(address _to,uint _amount );
    event ActivePoolReceivedETH(uint _ETH);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event StakingPoolAddressChanged(address _stakingPoolAddress);
    event oETHSent(address _to, uint _amount);


    // --- Functions ---
    function sendoETH(address _account, uint _amount) external;
    function receiveoETH(uint new_coll) external;
    function getoETH() external view returns (uint);
    function getUSDCDebt() external view returns (uint);
    function increaseUSDCDebt(uint _amount) external;
    function decreaseUSDCDebt(uint _amount) external;
    function offsetLiquidation(uint _collAmount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IoETHToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event CollateralPoolAddressChanged(address _collateralPoolAddress);


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoETHToken.sol";


interface IBorrowersRewardsPool  {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event  ActivePoolAddressChanged(address _activePoolAddress);
    event OETHTokenAddressChanged(address _oETHTokenAddress);
    event RewardsPoolAddressChanged(address _rewardsPoolAddress);
    
    event BorrowersRewardsPoolborrowersoETHRewardsBalanceUpdated(uint _borrowersoETHRewards);
    event BorrowersRewardsPoolborrowersoETHRewardsBalanceUpdated_before(uint _borrowersoETHRewards);
    event borrowersoETHRewardsSent(address activePool, uint _amount);
    event BorrowersRewardsPooloETHBalanceUpdated(uint _OrumwithdrawalborrowersoETHRewards);
    

    // --- Functions ---
    function sendborrowersoETHRewardsToActivePool(uint _amount) external;
    function receiveoETHBorrowersRewardsPool(uint new_coll) external;
    function getBorrowersoETHRewards() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// Common interface for the SortedVaults Doubly Linked List.
interface ISortedVaults {

    // --- Events ---
    
    event SortedVaultsAddressChanged(address _sortedDoublyLinkedListAddress);
    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _VaultManagerAddress, address _borrowerOpsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IOrumRevenue {
    // --- Events ---
    event CommitAdmin(address admin);
    event ApplyAdmin(address admin);
    event ToggleAllowCheckpointToken(bool toggleFlag);
    event Claimed(address indexed recipient, uint amount, uint claimEpoch, uint maxEpoch);

    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event RewardsPoolAddressChanged(address _rewardsPoolAddress);
    event OETHTokenAddressChanged(address _oETH);

    // --- Functions ---
    function checkpoint_token() external;

    // function checkpointToken() external;
    // function veForAt(address _user, uint _timestamp) external view returns (uint);
    // function checkpointTotalSupply() external;
    // function claimable(address _addr) external view returns (uint);
    // function applyAdmin() external;
    // function commitAdmin(address _addr) external;
    // function toggleAllowCheckpointToken() external;
}