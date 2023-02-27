// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IICHOR.sol";
import "./interfaces/IVotingFactory.sol";
import "./interfaces/IStakingContract.sol";
import "./interfaces/IUnicornRewards.sol";


/// @title ICHOR token contract
contract ICHOR is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;

    // Mapping (address => (address => uint256)). Contains token's allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    // Mapping (address => bool). Shows if user is excluded from fee
    mapping(address => bool) private _isExcludedFromFee;

    // Mapping (address => bool). Contains list of bots (blacklisted addresses)
    mapping(address => bool) private bots;

    // Mapping (address => uint256). Contains cooldown time for users to purchase ICHOR
    mapping(address => uint256) private cooldown;
    uint256 private constant _tTotal = 1e10 * 10 ** 9;

    // VotingFactory instance
    IVotingFactory public voting;

    // StakingContract address
    address public stakingAddress;

    // UnicornRewards address
    address private unicornRewards;

    // Charity wallet address
    address private _charity;

    // Name of the token
    string private constant _name = "Ethereal Fluid";

    // Symbol of the token
    string private constant _symbol = "ICHOR";

    // Decimals of the token
    uint8 private constant _decimals = 9;

    // UniswapV2Router02 instance
    IUniswapV2Router02 public uniswapV2Router;

    // UniswapV2Pair address
    address public uniswapV2Pair;

    // Shows if trading is open
    bool private tradingOpen;

    // Shows if contract in swap
    bool private inSwap = false;

    // Shows if cooldown if enabled
    bool private cooldownEnabled = false;

    // Contains trading active block
    // 0 means trading is not active
    uint256 private tradingActiveBlock = 0; 

    // Contains the maximum number of tokens to buy at one time
    uint256 private _maxBuyAmount = _tTotal;

    // Contains the maximum number of tokens to sell at one time
    uint256 private _maxSellAmount = _tTotal;

    //Contains the maximum number of tokens to store on one wallet
    uint256 private _maxWalletAmount = _tTotal;

    // Shows if user is claimed his migration tokens
    mapping(address => bool) public hasClaimed;

    // Old ICHOR contract address
    address private oldIchorAddress;

    // Address of wallet of migration payer
    // Tokens for migration will be transferred from this wallet
    address private migrationPayer;

    // Total fee
    uint256 private totalFee;

    // Denominator
    uint256 private DENOMINATOR = 1000;

    /// @dev Indicates that max buy amount was updated
    /// @param _maxBuyAmount New max buy amount
    event MaxBuyAmountUpdated(uint256 _maxBuyAmount);

    /// @dev Indicates that max sell amount was updated
    /// @param _maxSellAmount New max sell amount
    event MaxSellAmountUpdated(uint256 _maxSellAmount);

    /// @dev Indicates that max wallet amount was updated
    /// @param _maxWalletAmount New max wallet amount
    event MaxWalletAmountUpdated(uint256 _maxWalletAmount);

    /// @dev Indicates that tokens was migrated
    /// @param _user Tokens reciever
    /// @param _amount Amount of tokens transfered
    event TokensMigrated(address _user, uint256 _amount);

    /// @dev Checks if contract in swap
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /// @dev Checks if caller is a Voting instance
    modifier onlyVoting() {
        require(
            voting.isVotingInstance(msg.sender),
            "ICHOR: caller is not a Voting contract!"
        );
        _;
    }

    /// @param _uniswapV2Router Address of UniswapV2Router contract
    /// @param _oldIchorAddress Address of old ICHOR contract
    /// @param charity Address of charity wallet
    /// @param _votingFactoryAddress Address of VotingFactory contract
    /// @param _stakingAddress Address of StakingContract
    /// @param _unicornRewards Address of UnicornRewards contract
    /// @param _migrationPayer Address of migration payer wallet
    constructor(
        address _uniswapV2Router,
        address _oldIchorAddress,
        address charity,
        address _votingFactoryAddress,
        address _stakingAddress,
        address _unicornRewards,
        address _migrationPayer
    ) {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);

        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        unicornRewards = _unicornRewards;
        emit Transfer(address(0), _msgSender(), _tTotal);

        totalFee = 40;

        oldIchorAddress = _oldIchorAddress;
        _charity = charity;
        voting = IVotingFactory(_votingFactoryAddress);
        stakingAddress = _stakingAddress;
        migrationPayer = _migrationPayer;
    }

    /// @notice Returns name of the token
    /// @return Name of the token
    function name() public pure returns (string memory) {
        return _name;
    }

    /// @notice Returns symbol of the token
    /// @return Symbol of the token
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    /// @notice Returns decimals of the token
    /// @return Decimals of the token
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    /// @notice Returns totalSupply of the token
    /// @return TotalSupply of the token
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    /// @notice Returns balance of targeted account
    /// @param account Address of target account
    /// @return Balance of targeted account
    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    /// @notice Transfers tokens to targeted account
    /// @param recipient Address of tokens recipient
    /// @param amount Amount of tokens to transfer
    /// @return bool If the transfer was successful or not
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @notice Checks allowance of tokens
    /// @param owner Owner of tokens
    /// @param spender Spender of tokens
    /// @return amount The amount of tokens that the spender can use from the owner's balance
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Approves tokens to spend from callet to targeted account
    /// @param spender Spender of tokens
    /// @param amount The amount of tokens that the spender can use from the caller's balance
    /// @return bool If the approve was successful or not
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @notice Transfers tokens from spender to targeted account
    /// @param sender Owner of tokens
    /// @param recipient Address of tokens recipient
    /// @param amount Amount of tokens to transfer
    /// @return bool If the transfer was successful or not
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /// @notice Sets cooldown enabled or disabled
    /// @param onoff True - on, False - off
    /// @dev This method can be called only by an Owner of the contract
    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    /// @notice Sets Charity wallet address
    /// @param charity New Charity wallet address
    /// @dev This method can be called only by a Voting instance
    function setCharityAddress(address charity) external onlyVoting {
        require(
            charity != address(0),
            "ICHOR: Charity cannot be a zero address!"
        );
        _charity = charity;
    }

    /// @notice Returns address of current charity wallet
    /// @return address Address of current charity wallet
    function getCharityAddress() external view returns (address) {
        return _charity;
    }

    /// @notice Sets new total fee amount in the range from 40 to 100(40 = 4%). Max - 10%
    /// @param newFee_ New total fee amount
    /// @dev This method can be called only by an Owner of the contract
    function setTotalFee(uint256 newFee_) external onlyOwner {
        require(newFee_ <= 100, "ICHOR: Fee cant be greater than 10%");
        totalFee = newFee_;
    }

    /// @notice Returns current total fee amount
    /// @return uint256 Current total fee amount
    function getTotalFee() external view returns (uint256) {
        return totalFee;
    }

    /// @notice Approves tokens to spend from callet to targeted account
    /// @param spender Spender of tokens
    /// @param amount The amount of tokens that the spender can use from the caller's balance
    /// @dev This is a private method
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /// @notice Transfers tokens from spender to targeted account
    /// @param from Sender of tokens
    /// @param to Recipient of tokens
    /// @param amount Amount of tokens to transfer
    /// @dev This is a private method
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        bool takeFee = true;
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ) {
            require(!bots[from] && !bots[to]);

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                cooldownEnabled
            ) {
                require(
                    amount <= _maxBuyAmount,
                    "ICHOR: Transfer amount exceeds the maxBuyAmount!"
                );
                require(
                    balanceOf(to) + amount <= _maxWalletAmount,
                    "ICHOR: Exceeds maximum wallet token amount!"
                );
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }

            if (
                to == uniswapV2Pair &&
                from != address(uniswapV2Router) &&
                !_isExcludedFromFee[from] &&
                cooldownEnabled
            ) {
                require(
                    amount <= _maxSellAmount,
                    "ICHOR: Transfer amount exceeds the maxSellAmount!"
                );
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || totalFee == 0) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    /// @notice Swaps ICHOR tokens for Eth
    /// @param tokenAmount Amount of tokens to swap
    /// @dev This is a private method
    /// @dev Can be called only if contract is not already in a swap
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /** 
    @notice Transfers tokens from migration payer to user. 
    Amount of tokens to migrate defined by old ICHOR contract balance of the user.
    You can call this method only once 
    **/
    function migrateTokens() external {
        uint256 amount = IICHOR(oldIchorAddress).balanceOf(msg.sender);
        require(balanceOf(migrationPayer) >= amount, "ICHOR: cant pay now!");
        require(!hasClaimed[msg.sender], "ICHOR: tokens already claimed!");
        hasClaimed[msg.sender] = true;
        _transferStandard(migrationPayer, msg.sender, amount);
        emit TokensMigrated(msg.sender, amount);
    }

    /**
    @notice Creates liquidity pool of ICHOR token/eth and adds liquidity
    Also sets initial settings
    **/
    /// @dev This method can be called only by an Owner of the contract
    function openTrading() external onlyOwner {
        require(!tradingOpen, "ICHOR: Trading is already open");
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        cooldownEnabled = true;
        _maxBuyAmount = 5e7 * 10 ** 9;
        _maxSellAmount = 5e7 * 10 ** 9;
        _maxWalletAmount = 1e8 * 10 ** 9;
        tradingOpen = true;
        tradingActiveBlock = block.number;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    /// @notice Sets max amount to buy
    /// @param maxBuy New max amount to buy
    /// @dev This method can be called only by an Owner of the contract
    function setMaxBuyAmount(uint256 maxBuy) public onlyOwner {
        _maxBuyAmount = maxBuy;
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    /// @notice Sets max amount to sell
    /// @param maxSell New max amount to sell
    /// @dev This method can be called only by an Owner of the contract
    function setMaxSellAmount(uint256 maxSell) public onlyOwner {
        _maxSellAmount = maxSell;
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    /// @notice Sets max amount to store on one wallet
    /// @param maxToken New max amount to store on one wallet
    /// @dev This method can be called only by an Owner of the contract
    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        _maxWalletAmount = maxToken;
        emit MaxWalletAmountUpdated(_maxWalletAmount);
    }


    /// @notice Excludes the target account from charging fees
    /// @dev This method can be called only by an Owner of the contract
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /// @notice Includes the target account in charging fees
    /// @dev This method can be called only by an Owner of the contract
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /// @notice Adds targeted accounts to the blacklist 
    /// @param bots_ Array of targeted accounts
    /// @dev This method can be called only by an Owner of the contract
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    /// @notice Removes targeted account from the blacklist 
    /// @param notbot Targeted account
    /// @dev This method can be called only by an Owner of the contract
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    /// @notice Transfers tokens from spender to targeted account and takes fee if needed
    /// @param sender Sender of tokens
    /// @param recipient Recipient of tokens
    /// @param amount Amount of tokens to transfer
    /// @param takeFee True - take fee, False - not take fee
    /// @dev This is a private method
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (takeFee) {
            amount = _takeFees(sender, amount);
        }
        _transferStandard(sender, recipient, amount);
    }

    /// @notice Transfers tokens from spender to targeted account
    /// @param sender Sender of tokens
    /// @param recipient Recipient of tokens
    /// @param tAmount Amount of tokens to transfer
    /// @dev This is a private method
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        require(balanceOf(sender) >= tAmount, "ICHOR: Insufficient balance!");
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    /// @notice Calculating and distributing fees
    /// @param sender Sender of tokens
    /// @param amount Amount of tokens to transfer
    /// @return tAmount New amount of tokens to transfer 
    /// @dev This is a private method
    function _takeFees(
        address sender,
        uint256 amount
    ) private returns (uint256) {
        uint256 totalFeeAmount = amount.mul(totalFee).div(DENOMINATOR);
        uint256 amountToCharity = totalFeeAmount.mul(500).div(DENOMINATOR);
        uint256 amountToStaking = (totalFeeAmount.sub(amountToCharity))
            .mul(850)
            .div(DENOMINATOR);
        uint256 amountToUnicorns = totalFeeAmount.sub(
            amountToCharity.add(amountToStaking)
        );

        if (amountToCharity > 0) {
            _transferStandard(sender, _charity, amountToCharity);
        }

        if (amountToStaking > 0) {
            _transferStandard(sender, stakingAddress, amountToStaking);
            IStakingContract(stakingAddress).notifyRewardAmount(
                amountToStaking
            );
        }

        if (amountToUnicorns > 0) {
            _transferStandard(sender, unicornRewards, amountToUnicorns);
            IUnicornRewards(unicornRewards).notifyRewardAmount(
                amountToUnicorns
            );
        }
        return amount -= totalFeeAmount;
    }

    receive() external payable {}


    /// @notice Swaps all ICHOR tokens on this contract for Eth
    /// @dev This method can be called only by an Owner of the contract
    function manualswap() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    /// @notice Transfers all Eth from this contract to the Owner
    /// @dev This method can be called only by an Owner of the contract
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }
}

pragma solidity ^0.8.4;

interface IICHOR {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function totalSupply() external returns (uint256);

    function balanceOf(address account) external returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setCooldownEnabled(bool onoff) external;

    function setSwapEnabled(bool onoff) external;

    function openTrading() external;

    function setBots(address[] memory bots_) external;

    function setMaxBuyAmount(uint256 maxBuy) external;

    function setMaxSellAmount(uint256 maxSell) external;

    function setMaxWalletAmount(uint256 maxToken) external;

    function setSwapTokensAtAmount(uint256 newAmount) external;

    function setProjectWallet(address projectWallet) external;

    function setCharityAddress(address charityAddress) external;

    function getCharityAddress() external view returns (address charityAddress);

    function excludeFromFee(address account) external;

    function includeInFee(address account) external;

    function setBuyFee(uint256 buyProjectFee) external;

    function setSellFee(uint256 sellProjectFee) external;

    function setBlocksToBlacklist(uint256 blocks) external;

    function delBot(address notbot) external;

    function manualswap() external;

    function withdrawStuckETH() external;
}

pragma solidity ^0.8.4;

interface IStakingContract {
    function stakeTransfer(address from, address to, uint256 amount) external;

    function setIchorAddress(address ichorToken_) external;

    function getIchorAddress() external view returns (address);

    function getStakedAmount(address user) external view returns (uint256);

    function getTimeStakeEnds(address user) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function stake(uint256 _amount) external;

    function unstake() external;

    function earned(address _account) external view;

    function getReward() external;

    function notifyRewardAmount(uint256 _amount) external;

    function setMinimalStakingPeriod(uint256 stakingPeriod_) external;
}

pragma solidity ^0.8.4;

interface IUnicornRewards {
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function stake(address _account) external;

    function unstake(address _account) external;

    function earned(address _account) external view returns (uint256);

    function getReward() external;

    function notifyRewardAmount(uint256 _amount) external;
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);
}

pragma solidity ^0.8.4;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IVotingInitialize.sol";

interface IVotingFactory is IVotingInitialize {
    function createVoting(
        VotingVariants _typeVoting,
        bytes memory _voteDescription,
        uint256 _duration,
        uint256 _qtyVoters,
        uint256 _minPercentageVoters,
        address _applicant
    ) external;

    function getVotingInstancesLength() external view returns (uint256);

    function isVotingInstance(address instance) external view returns (bool);

    event CreateVoting(
        address indexed instanceAddress,
        VotingVariants indexed instanceType
    );
    event SetMasterVoting(
        address indexed previousContract,
        address indexed newContract
    );
    event SetMasterVotingAllowList(
        address indexed previousContract,
        address indexed newContract
    );
    event SetVotingTokenRate(
        uint256 indexed previousRate,
        uint256 indexed newRate
    );
    event SetCreateProposalRate(
        uint256 indexed previousRate,
        uint256 indexed newRate
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVotingInitialize {
    enum VotingVariants {
        UNICORNADDING,
        UNICORNREMOVAL,
        CHARITY
    }

    struct Params {
        bytes description;
        uint256 start;
        uint256 qtyVoters;
        uint256 minPercentageVoters;
        uint256 minQtyVoters;
        uint256 duration;
    }
}