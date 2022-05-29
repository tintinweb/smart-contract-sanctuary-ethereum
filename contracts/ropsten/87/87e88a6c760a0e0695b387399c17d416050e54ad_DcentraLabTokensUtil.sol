/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts-upgradeable/math/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
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
library SafeMathUpgradeable {
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


// File contracts/governance/IMaintainersRegistry.sol

pragma solidity 0.6.12;

interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/governance/ICongressMembersRegistry.sol

pragma solidity 0.6.12;

/**
 * ICongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 13.9.21.
 * Github: madjarevicn
 */

interface ICongressMembersRegistry {
    function isMember(address _address) external view returns (bool);
    function getMinimalQuorum() external view returns (uint256);
}


// File contracts/system/DcentralabUpgradable.sol

pragma solidity 0.6.12;


//to be fixed
contract DcentralabUpgradable {

    // Address of tokens congress
    address public dcentralabCongress;
    // Instance of maintainers registry object
    IMaintainersRegistry public maintainersRegistry;

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(
            maintainersRegistry.isMaintainer(msg.sender),
            "DcentralabUpgradable: Restricted only to Maintainer"
        );
        _;
    }

    // Only tokens farm congress modifier
    modifier onlyDcentralabCongress {
        require(
            msg.sender == dcentralabCongress,
            "DcentralabUpgradable: Restricted only to DcentralabCongress"
        );
        _;
    }

    /**
     * @notice function to set congress and maintainers registry address
     *
     * @param _dcentralabCongress - address of dcentralab congress
     * @param _maintainersRegistry - address of maintainers registry
     */
    function setCongressAndMaintainersRegistry(
        address _dcentralabCongress,
        address _maintainersRegistry
    )
        internal
    {
        require(
            _dcentralabCongress != address(0x0),
            "dcentralabCongress can not be 0x0 address"
        );
        require(
            _maintainersRegistry != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        dcentralabCongress = _dcentralabCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    /**
     * @notice function to set new maintainers registry address
     *
     * @param _maintainersRegistry - address of new maintainers registry
     */
    function setMaintainersRegistry(
        address _maintainersRegistry
    )
        external
    onlyDcentralabCongress
    {
        require(
            _maintainersRegistry != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    /**
    * @notice function to set new congress registry address
    *
    * @param _dcentralabCongress - address of new dcentralab congress
    */
    function setDcentralabCongress(
        address _dcentralabCongress
    )
        external
        onlyDcentralabCongress
    {
        require(
            _dcentralabCongress != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        dcentralabCongress = _dcentralabCongress;
    }
}


// File contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/DcentraLabTokensUtil.sol

pragma solidity 0.6.12;




contract DcentraLabTokensUtil is DcentralabUpgradable {

    using SafeMathUpgradeable for uint256;
    /* Fallback function, don't accept any ETH */
    receive() external payable {
        revert("DcentraLabTokensUtil does not accept payments");
    }

    /**
     * @notice function sets initial state of contract
     *
     * @param _dcentralabCongress - address of farm congress
     * @param _maintainersRegistry - address of maintainers registry
     */
    function initialize(
        address _dcentralabCongress,
        address _maintainersRegistry
    )
    external
    {
        // set congress and maintainers registry address
        setCongressAndMaintainersRegistry(
            _dcentralabCongress,
            _maintainersRegistry
        );
    }

    /**
    * @dev Checks the token balance of a wallet in a token contract
    * @param user the wallet address to be checked
    * @param token the token address whose balance will be returned
    * @notice will return 0 if address is not a contract
    */
    function tokenBalance(address user, address token) public view onlyMaintainer returns (uint)  {
        if (token == address(0x0)) {
            return user.balance;
        }
        uint256 contractSize;
        assembly { contractSize := extcodesize(token) }
        if (contractSize > 0 ) {  
            return IERC20Upgradeable(token).balanceOf(user);
        } else {
            return 0;
        }
    }

    /**
    * @dev Checks the balance of a single token across multiple wallets
    * @param users the wallet addresses to be checked
    * @param token the token address whose balance will be returned
    * @notice pass 0x0 as token address to get native token balance
    * @notice will return 0 if token address is not a contract
    * @notice will return 0 if token contract address doesnt implement balanceOf or 
    */
    function tokenBalanceForUsers(address[] calldata users, address token) external view onlyMaintainer returns (address[] calldata, uint[] memory) {
        uint256[] memory userBalances = new uint256[](users.length);

        for (uint i = 0; i < userBalances.length; i++) {     
            userBalances[i] = tokenBalance(users[i], token);
        }
        return (users, userBalances);
    }

    /**
    * @dev Checks the token balances of multiple tokens within a wallet
    * @param user the wallet address to be checked
    * @param tokens the token address whose balance will be returned
    * @notice pass 0x0 as token address to get native token balance
    * @notice will return 0 if address is not a contract
    * @notice will return 0 if contract address doesnt implement balanceOf or 
    */
    function tokenBalancesForUser(address user, address[] calldata tokens) external view onlyMaintainer returns (address[] calldata, uint[] memory) {
        uint256[] memory addrBalances = new uint256[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            addrBalances[i] = tokenBalance(user, tokens[i]);       
        }    
        return (tokens, addrBalances);
    }

    /**
    * @dev Checks the token price of token0 relative to token1
    * @param pool the pool that contains the token pair
    * @notice will return 0 if liquidity pool doesnt contain token0 or token1
    */
    function calculateTokenPriceFromPair(address pool) public view onlyMaintainer returns (uint)  {
        address token0 = IUniswapV2Pair(pool).token0();
        address token1 = IUniswapV2Pair(pool).token1();
        uint256 token0_balance = tokenBalance(pool, token0);
        uint256 token1_balance = tokenBalance(pool, token1);

        if (token0_balance == 0) {
            return  0;
        }
        uint256 base = token0_balance;
        return (token1_balance.mul(100000).div(base));
    }

    /**
    * @dev Checks the token price of token0 relative to token1
    * @param pool the pool that contains the token pair
    * @param amount of LP token that we want to calculate its token0 & token1 amounts
    * @notice will return 0 if liquidity pool has 0 total supply
    */
    function calculateTokenAmountsFromPair(address pool, uint256 amount) public view onlyMaintainer returns (uint256, uint256)  {
        address token0 = IUniswapV2Pair(pool).token0();
        address token1 = IUniswapV2Pair(pool).token1();
        uint256 token0_balance = tokenBalance(pool, token0);
        uint256 token1_balance = tokenBalance(pool, token1);
        uint256 lpTokenSupply = IERC20Upgradeable(pool).totalSupply();

        require(lpTokenSupply > 0, "the LP token has no supply");

        uint256 token0_userBalance = amount.mul(token0_balance).div(lpTokenSupply);
        uint256 token1_userBalance = amount.mul(token1_balance).div(lpTokenSupply);

        return (token0_userBalance , token1_userBalance);
    }

    /**
    * @dev Checks the token prices for multiple pairs of tokens
    * @param pools the pools that contain the token pairs
    * @notice will revert if the three argument arrays are not of all equal length
    */
    function calculateTokenPricesFromPairs(address[] calldata pools) external view onlyMaintainer returns (address[] calldata, uint[] memory)  {
        require(pools.length > 0, "pools address array is empty");

        uint256[] memory tokenPrices = new uint256[](pools.length);
        for (uint i = 0; i < pools.length; i++) {
            tokenPrices[i] = calculateTokenPriceFromPair(pools[i]);
        }
        return (pools, tokenPrices);
    }

}