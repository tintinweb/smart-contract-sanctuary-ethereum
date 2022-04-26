/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/*
* 
* $DEWO Token - The Native Token In DecentraWorld's Ecosystem
* DecentraWorld - Increasing Privacy Standards In DeFi
*
* Documentation: http://docs.decentraworld.co/
* GitHub: https://github.com/decentraworldDEWO
* DecentraWorld: https://DecentraWorld.co/
* DAO: https://dao.decentraworld.co/
* Governance: https://gov.decentraworld.co/
* DecentraMix: https://decentramix.io/
*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░██████╗░███████╗░█████╗░███████╗███╗░░██╗████████╗██████╗░░█████╗░░░
*░░██╔══██╗██╔════╝██╔══██╗██╔════╝████╗░██║╚══██╔══╝██╔══██╗██╔══██╗░░
*░░██║░░██║█████╗░░██║░░╚═╝█████╗░░██╔██╗██║░░░██║░░░██████╔╝███████║░░
*░░██║░░██║██╔══╝░░██║░░██╗██╔══╝░░██║╚████║░░░██║░░░██╔══██╗██╔══██║░░
*░░██████╔╝███████╗╚█████╔╝███████╗██║░╚███║░░░██║░░░██║░░██║██║░░██║░░
*░░╚═════╝░╚══════╝░╚════╝░╚══════╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░░░░░░░░░░░░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░░░░░░░░░░░░░
*░░░░░░░░░░░░░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗░░░░░░░░░░░░
*░░░░░░░░░░░░░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║░░░░░░░░░░░░
*░░░░░░░░░░░░░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║░░░░░░░░░░░░
*░░░░░░░░░░░░░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝░░░░░░░░░░░░
*░░░░░░░░░░░░░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░░░░░░░░░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*
*/
// SPDX-License-Identifier: MIT

// File: @OpenZeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: @OpenZeppelin/contracts/utils/Context.sol

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

// File: @OpenZeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/DecentraWorld_Multichain.sol

/*
* 
* $DEWO Token - The Native Token In DecentraWorld's Ecosystem
* DecentraWorld - Increasing Privacy Standards In DeFi
*
* Documentation: http://docs.decentraworld.co/
* GitHub: https://github.com/decentraworldDEWO
* DecentraWorld: https://DecentraWorld.co/
* DAO: https://dao.decentraworld.co/
* Governance: https://gov.decentraworld.co/
* DecentraMix: https://decentramix.io/
*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░██████╗░███████╗░█████╗░███████╗███╗░░██╗████████╗██████╗░░█████╗░░░
*░░██╔══██╗██╔════╝██╔══██╗██╔════╝████╗░██║╚══██╔══╝██╔══██╗██╔══██╗░░
*░░██║░░██║█████╗░░██║░░╚═╝█████╗░░██╔██╗██║░░░██║░░░██████╔╝███████║░░
*░░██║░░██║██╔══╝░░██║░░██╗██╔══╝░░██║╚████║░░░██║░░░██╔══██╗██╔══██║░░
*░░██████╔╝███████╗╚█████╔╝███████╗██║░╚███║░░░██║░░░██║░░██║██║░░██║░░
*░░╚═════╝░╚══════╝░╚════╝░╚══════╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░░░░░░░░░░░░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░░░░░░░░░░░░░
*░░░░░░░░░░░░░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗░░░░░░░░░░░░
*░░░░░░░░░░░░░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║░░░░░░░░░░░░
*░░░░░░░░░░░░░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║░░░░░░░░░░░░
*░░░░░░░░░░░░░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝░░░░░░░░░░░░
*░░░░░░░░░░░░░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░░░░░░░░░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*
*/

pragma solidity ^0.8.7;



/**
 * @dev Interfaces
 */

interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IDEXRouter {
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakeswapV2Pair {
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
}

contract DecentraWorld_Multichain is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
	// DecentraWorld - $DEWO
    uint256 _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    // Mapping
    mapping (string => uint) txTaxes;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public excludeFromTax;
    mapping (address => bool) public exclueFromMaxTx;
    // Addresses Of Tax Receivers
    address public daoandfarmingAddress;
    address public marketingAddress;
    address public developmentAddress;
    address public coreteamAddress;
    // Address of the bridge controling the mint/burn of the cross-chain 
    address public MPC;
    // taxes for differnet levels
    struct TaxLevels {
        uint taxDiscount;
        uint amount;
    }

    struct DEWOTokenTax {
        uint forMarketing;
        uint forCoreTeam;
        uint forDevelopment;
        uint forDAOAndFarming;
    }

    struct TxLimit {
        uint buyMaxTx;
        uint sellMaxTx;
        uint txcooldown;
        mapping(address => uint) buys;
        mapping(address => uint) sells;
        mapping(address => uint) lastTx;
    }

    mapping (uint => TaxLevels) taxTiers;
    TxLimit txSettings;

    IDEXRouter public router;
    address public pair;

    constructor() {
        _name = "DecentraWorld";
        _symbol = "$DEWO";
        _decimals = 18;
        //Temporary Tax Receivers
        daoandfarmingAddress = msg.sender;
        marketingAddress = 0x5d5a0368b8C383c45c625a7241473A1a4F61eA4E;
        developmentAddress = 0xdA9f5e831b7D18c35CA7778eD271b4d4f3bE183E;
        coreteamAddress = 0x797BD28BaE691B21e235E953043337F4794Ff9DB;
         
        // Exclude From Taxes By Default
        excludeFromTax[msg.sender] = true;
        excludeFromTax[daoandfarmingAddress] = true;
        excludeFromTax[marketingAddress] = true;
        excludeFromTax[developmentAddress] = true;
        excludeFromTax[coreteamAddress] = true;

        // Exclude From MaxTx By Default
        exclueFromMaxTx[msg.sender] = true;
        exclueFromMaxTx[daoandfarmingAddress] = true;
        exclueFromMaxTx[marketingAddress] = true;
        exclueFromMaxTx[developmentAddress] = true;
        exclueFromMaxTx[coreteamAddress] = true;

        // Cross-Chain Bridge Temp Settings
        MPC = msg.sender;

        // Transaction taxes apply solely on swaps (buys/sells)
        // Tier 1 - Default Buy Fee [6% Total]
        // Tier 2 - Buy Fee [3% Total]
        // Tier 3 - Buy Fee [0% Total]
        //
        // Automatically set the default transactions taxes
        // [Tier 1: 6% Buy Fee]
        txTaxes["marketingBuyTax"] = 3;      // [3%] DAO, Governance, Farming Pools
        txTaxes["developmentBuyTax"] = 1;    // [1%] Marketing Fee
        txTaxes["coreteamBuyTax"] = 1;       // [1%] Development Fee
        txTaxes["daoandfarmingBuyTax"] = 1;  // [1%] DecentraWorld's Core-Team
        // [Tier 1: 10% Sell Fee]
        txTaxes["marketingSellTax"] = 4;     // 4% DAO, Governance, Farming Pools 
        txTaxes["developmentSellTax"] = 3;   // 3% Marketing Fee
        txTaxes["coreteamSellTax"] = 1;      // 1% Development Fee
        txTaxes["daoandfarmingSellTax"] = 2; // 2% DecentraWorld's Core-Team
        /*
           Buy Transaction Tax - 3 tiers:
           *** Must buy these amounts to qualify
           Tier 1: 6%/10% (0+    $DEWO balance)
           Tier 2: 3%/8%  (100K+ $DEWO balance)
           Tier 3: 0%/6%  (400K+ $DEWO balance) 

           Sell Transaction Tax - 3 tiers:
           *** Must hold these amounts to qualify
           Tier 1: 6%/10% (0+    $DEWO balance)
           Tier 2: 3%/8%  (150K+ $DEWO balance)
           Tier 3: 0%/6%  (300K+ $DEWO balance) 

           Tax Re-distribution Buys (6%/3%/0%):
           DAO Fund/Farming:      3% | 1% | 0%
           Marketing Budget:      1% | 1% | 0% 
           Development Fund:      1% | 0% | 0%
           Core-Team:             1% | 1% | 0% 

           Tax Re-distribution Sells (10%/8%/6%):
           DAO Fund/Farming:        4% | 3% | 3%
           Marketing Budget:        3% | 2% | 1% 
           Development Fund:        1% | 1% | 1%
           Core-Team:               2% | 2% | 1% 
           The community can disable the holder rewards fee and migrate that 
           fee to the rewards/staking pool. This can be done via the Governance portal.
        */
        // Default Tax Tiers & Discounts
        // Get a 50% discount on purchase tax taxes
        taxTiers[0].taxDiscount = 50;
        // When buying over 0.1% of total supply (100,000 $DEWO)
        taxTiers[0].amount = 100000 * (10 ** decimals()); 

        // Get a 100% discount on purchase tax taxes
        taxTiers[1].taxDiscount = 99;
        // When buying over 0.4% of total supply (400,000 $DEWO)
        taxTiers[1].amount = 400000 * (10 ** decimals());

        // Get a 20% discount on sell tax taxes
        taxTiers[2].taxDiscount = 20;
        // When holding over 0.15% of total supply (150,000 $DEWO)
        taxTiers[2].amount = 150000 * (10 ** decimals());

        // Get a 40% discount on sell tax taxes
        taxTiers[3].taxDiscount = 40;
        // When holding over 0.3% of total supply (300,000 $DEWO)
        taxTiers[3].amount = 300000 * (10 ** decimals());

        // Default txcooldown limit in minutes
        txSettings.txcooldown = 30 minutes;

        // Default buy limit: 1.25% of total supply
        txSettings.buyMaxTx = _totalSupply.div(80);

        // Default sell limit: 0.25% of total supply
        txSettings.sellMaxTx = _totalSupply.div(800);


        /**
        Removed from the cross-chain $DEWO token, the pair settings were replaced with a function,
        and the mint function of 100,000,000 $DEWO to deployer was replaced with 0. Since this token is
        a cross-chain token and not the native EVM chain where $DEWO was deployed (BSC) then there's no need
        in any additional supply. The Multichain.org bridge will call burn/mint functions accordingly. 
        
        ---
        // Create a PancakeSwap (DEX) Pair For $DEWO 
        // This will be used to track the price of $DEWO & charge taxes to all pool buys/sells
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Wrapped BNB on Binance Smart Chain
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PancakeSwap Router (ChainID: 56 = BSC)
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        approve(_router, _totalSupply);
        
        // Send 100,000,000 $DEWO tokens to the dev (one time only)
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

         */
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    // onlyAuth = allow MPC contract address to call certain functions
    // The MPC = Multichain bridge contract of each chain
    modifier onlyAuth() {
        require(msg.sender == mmpc(), "DecentraWorld: FORBIDDEN");
        _;
    }
  
      function mmpc() public view returns (address) {
        return MPC;
    }

    // This can only be done once by the deployer, once the MPC is set only the MPC can call this function again.
    function setMPC(address _setmpc) external onlyAuth {
        MPC = _setmpc;
    }
    
    // Mint will be used when individuals cross-chain $DEWO from one chain to another
    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);
        return true;
    }

    // The burn function will be used to burn tokens that were cross-chained into another EVM chain
    function burn(address from, uint256 amount) external onlyAuth returns (bool) {
        require(from != address(0), "DecentraWorld: address(0x0)");
        _burn(from, amount);
        return true;
    }

    function Swapin(bytes32 txhash, address account, uint256 amount) public onlyAuth returns (bool) {
        _mint(account, amount);
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    function Swapout(uint256 amount, address bindaddr) public returns (bool) {
        require(bindaddr != address(0), "DecentraWorld: address(0x0)");
        _burn(msg.sender, amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }
    
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint amount);
      

    // Set the router & native token of each chain to tax the correct LP POOL of $DEWO
    // This will always be the most popular DEX on the chain + its native token. 
    function setDEXPAIR(address _nativetoken, address _nativerouter) external onlyOwner {
        // Create a  DEX Pair For $DEWO 
        // This will be used to track the price of $DEWO & charge taxes to all pool buys/sells
        router = IDEXRouter(_nativerouter);
        pair = IDEXFactory(router.factory()).createPair(_nativetoken, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        approve(_nativerouter, _totalSupply);
    }

    // Set Buy Taxes
    event BuyTaxes(
        uint _daoandfarmingBuyTax,
        uint _coreteamBuyTax,
        uint _developmentBuyTax, 
        uint _marketingBuyTax
    );
    function setBuyTaxes(
        uint _daoandfarmingBuyTax,
        uint _coreteamBuyTax,
        uint _developmentBuyTax, 
        uint _marketingBuyTax
    // Hardcoded limitation to the maximum tax fee per address 
    // Maximum tax for each buys/sells: 6% max tax per tax receiver, 24% max tax total
    ) external onlyOwner {
        require(_daoandfarmingBuyTax <= 6, "DAO & Farming tax is above 6%!");
        require(_coreteamBuyTax <= 6, "Core-Team Buy tax is above 6%!");
        require(_developmentBuyTax <= 6, "Development Fund tax is above 6%!");
        require(_marketingBuyTax <= 6, "Marketing tax is above 6%!");
        txTaxes["daoandfarmingBuyTax"] = _daoandfarmingBuyTax;
        txTaxes["coreteamBuyTax"] = _coreteamBuyTax; 
        txTaxes["developmentBuyTax"] = _developmentBuyTax; 
        txTaxes["marketingBuyTax"] = _marketingBuyTax; 
        emit BuyTaxes(
            _daoandfarmingBuyTax,
            _coreteamBuyTax, 
            _developmentBuyTax, 
            _marketingBuyTax
        );
    }

    // Set Sell Taxes
        event SellTaxes(
        uint _daoandfarmingSellTax,
        uint _coreteamSellTax, 
        uint _developmentSellTax,
        uint _marketingSellTax
    );
    function setSellTaxes(
        uint _daoandfarmingSellTax,
        uint _coreteamSellTax, 
        uint _developmentSellTax,
        uint _marketingSellTax
        // Hardcoded limitation to the maximum tax fee per address 
        // Maximum tax for buys/sells: 6% max tax per tax receiver, 24% max tax total
    ) external onlyOwner {
        require(_daoandfarmingSellTax <= 6, "DAO & Farming tax is above 6%!");
        require(_coreteamSellTax <= 6, "Core-team tax is above 6%!");
        require(_developmentSellTax <= 6, "Development tax is above 6%!");
        require(_marketingSellTax <= 6, "Marketing tax is above 6%!");
        txTaxes["daoandfarmingSellTax"] = _daoandfarmingSellTax;
        txTaxes["coreteamSellTax"] = _coreteamSellTax; 
        txTaxes["developmentSellTax"] = _developmentSellTax; 
        txTaxes["marketingSellTax"] = _marketingSellTax; 
        emit SellTaxes(
            _daoandfarmingSellTax,
            _coreteamSellTax, 
            _developmentSellTax, 
            _marketingSellTax
        );
    }


    // Displays a list of all current taxes
    function getSellTaxes() public view returns(
        uint marketingSellTax,
        uint developmentSellTax,
        uint coreteamSellTax,
        uint daoandfarmingSellTax
    ) {
        return (
            txTaxes["marketingSellTax"],
            txTaxes["developmentSellTax"],
            txTaxes["coreteamSellTax"],
            txTaxes["daoandfarmingSellTax"]
        );
    }

        // Displays a list of all current taxes
    function getBuyTaxes() public view returns(
        uint marketingBuyTax,
        uint developmentBuyTax,
        uint coreteamBuyTax,
        uint daoandfarmingBuyTax
    ) {
        return (
            txTaxes["marketingBuyTax"],
            txTaxes["developmentBuyTax"],
            txTaxes["coreteamBuyTax"],
            txTaxes["daoandfarmingBuyTax"]
        );
    }
    
    // Set the DAO and Farming Tax Receiver Address (daoandfarmingAddress)
    function setDAOandFarmingAddress(address _daoandfarmingAddress) external onlyOwner {
        daoandfarmingAddress = _daoandfarmingAddress;
    }

    // Set the Marketing Tax Receiver Address (marketingAddress)
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    // Set the Development Tax Receiver Address (developmentAddress)
    function setDevelopmentAddress(address _developmentAddress) external onlyOwner {
        developmentAddress = _developmentAddress;
    }

    // Set the Core-Team Tax Receiver Address (coreteamAddress)
    function setCoreTeamAddress(address _coreteamAddress) external onlyOwner {
        coreteamAddress = _coreteamAddress;
    }

    // Exclude an address from tax
    function setExcludeFromTax(address _address, bool _value) external onlyOwner {
        excludeFromTax[_address] = _value;
    }

    // Exclude an address from maximum transaction limit
    function setExclueFromMaxTx(address _address, bool _value) external onlyOwner {
        exclueFromMaxTx[_address] = _value;
    }

    // Set Buy Tax Tiers
    function setBuyTaxTiers(uint _discount1, uint _amount1, uint _discount2, uint _amount2) external onlyOwner {
        require(_discount1 > 0 && _discount1 < 100 && _discount2 > 0 && _discount2 < 100 && _amount1 > 0 && _amount2 > 0, "Values have to be bigger than zero!");
        taxTiers[0].taxDiscount = _discount1;
        taxTiers[0].amount = _amount1;
        taxTiers[1].taxDiscount = _discount2;
        taxTiers[1].amount = _amount2;
        
    }

    // Set Sell Tax Tiers
        function setSellTaxTiers(uint _discount3, uint _amount3, uint _discount4, uint _amount4) external onlyOwner {
        require(_discount3 > 0 && _discount3 < 100 && _discount4 > 0 && _discount4 < 100 && _amount3 > 0 && _amount4 > 0, "Values have to be bigger than zero!");
        taxTiers[2].taxDiscount = _discount3;
        taxTiers[2].amount = _amount3;
        taxTiers[3].taxDiscount = _discount4;
        taxTiers[3].amount = _amount4;
        
    }

    // Get Buy Tax Tiers
    function getBuyTaxTiers() public view returns(uint discount1, uint amount1, uint discount2, uint amount2) {
        return (taxTiers[0].taxDiscount, taxTiers[0].amount, taxTiers[1].taxDiscount, taxTiers[1].amount);
    }

    // Get Sell Tax Tiers
    function getSellTaxTiers() public view returns(uint discount3, uint amount3, uint discount4, uint amount4) {
        return (taxTiers[2].taxDiscount, taxTiers[2].amount, taxTiers[3].taxDiscount, taxTiers[3].amount);
    }

    // Set Transaction Settings: Max Buy Limit, Max Sell Limit, Cooldown Limit. 
    function setTxSettings(uint _buyMaxTx, uint _sellMaxTx, uint _txcooldown) external onlyOwner {
        require(_buyMaxTx >= _totalSupply.div(200), "Buy transaction limit is too low!"); // 0.5%
        require(_sellMaxTx >= _totalSupply.div(400), "Sell transaction limit is too low!"); // 0.25%
        require(_txcooldown <= 4 minutes, "Cooldown should be 4 minutes or less!");
        txSettings.buyMaxTx = _buyMaxTx;
        txSettings.sellMaxTx = _sellMaxTx;
        txSettings.txcooldown = _txcooldown;
    }

    // Get Max Transaction Settings: Max Buy, Max Sell, Cooldown Limit.
    function getTxSettings() public view returns(uint buyMaxTx, uint sellMaxTx, uint txcooldown) {
        return (txSettings.buyMaxTx, txSettings.sellMaxTx, txSettings.txcooldown);
    }

    // Check Buy Limit During A Cooldown (used in _transfer)
    function checkBuyTxLimit(address _sender, uint256 _amount) internal view {
        require(
            exclueFromMaxTx[_sender] == true ||
            txSettings.buys[_sender].add(_amount) < txSettings.buyMaxTx,
            "Buy transaction limit reached!"
        );
    }

    // Check Sell Limit During A Cooldown (used in _transfer)
    function checkSellTxLimit(address _sender, uint256 _amount) internal view {
        require(
            exclueFromMaxTx[_sender] == true ||
            txSettings.sells[_sender].add(_amount) < txSettings.sellMaxTx,
            "Sell transaction limit reached!"
        );
    }
    
    // Saves the recent buys & sells during a cooldown  (used in _transfer)
    function setRecentTx(bool _isSell, address _sender, uint _amount) internal {
        if(txSettings.lastTx[_sender].add(txSettings.txcooldown) < block.timestamp) {
            _isSell ? txSettings.sells[_sender] = _amount : txSettings.buys[_sender] = _amount;
        } else {
            _isSell ? txSettings.sells[_sender] += _amount : txSettings.buys[_sender] += _amount;
        }

        txSettings.lastTx[_sender] = block.timestamp;
    }

    // Get the recent buys, sells, and the last transaction
    function getRecentTx(address _address) public view returns(uint buys, uint sells, uint lastTx) {
        return (txSettings.buys[_address], txSettings.sells[_address], txSettings.lastTx[_address]);
    }

    // Get $DEWO Token Price In BNB
    function getTokenPrice(uint _amount) public view returns(uint) {
        IPancakeswapV2Pair pcsPair = IPancakeswapV2Pair(pair);
        IERC20 token1 = IERC20(pcsPair.token1());
        (uint Res0, uint Res1,) = pcsPair.getReserves();
        uint res0 = Res0*(10**token1.decimals());
        return((_amount.mul(res0)).div(Res1)); 
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token taxes, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint marketingFee;
        uint developmentFee;
        uint coreteamFee;
        uint daoandfarmingFee;

        uint taxDiscount;
        bool hasTaxes = true;

        // Buys from PancakeSwap's $DEWO pool

        if(from == pair) {
            checkBuyTxLimit(to, amount); 
            setRecentTx(false, to, amount);
            marketingFee = txTaxes["marketingBuyTax"];
            developmentFee = txTaxes["developmentBuyTax"];
            coreteamFee = txTaxes["coreteamBuyTax"];
            daoandfarmingFee = txTaxes["daoandfarmingBuyTax"];
            // Transaction Tax Tiers 2 & 3 - Discounted Rate
            if(amount >= taxTiers[0].amount && amount < taxTiers[1].amount) {
                taxDiscount = taxTiers[0].taxDiscount;
            } else if(amount >= taxTiers[1].amount) {
                taxDiscount = taxTiers[1].taxDiscount;
            }
        }

        // Sells from PancakeSwap's $DEWO pool
        else if(to == pair) {
            checkSellTxLimit(from, amount);
            setRecentTx(true, from, amount);
            marketingFee = txTaxes["marketingSellTax"];
            developmentFee = txTaxes["developmentSellTax"];
            coreteamFee = txTaxes["coreteamSellTax"];
            daoandfarmingFee = txTaxes["daoandfarmingSellTax"];
            // Calculate the balance after this transaction
            uint newBalanceAmount = fromBalance.sub(amount);
            // Transaction Tax Tiers 2 & 3 - Discounted Rate
            if(newBalanceAmount >= taxTiers[2].amount && newBalanceAmount < taxTiers[3].amount) {
                taxDiscount = taxTiers[2].taxDiscount;
            } else if(newBalanceAmount >= taxTiers[3].amount) {
                taxDiscount = taxTiers[3].taxDiscount;
            }
        }
        


        unchecked {
            _balances[from] = fromBalance - amount;
        }
        if(excludeFromTax[to] || excludeFromTax[from]) {
            hasTaxes = false;
        }

        // Calculate taxes if this wallet is not excluded and buys/sells from $DEWO's PCS pair pool
        if(hasTaxes && (to == pair || from == pair)) {
            DEWOTokenTax memory DEWOTokenTaxes;
            DEWOTokenTaxes.forDAOAndFarming = amount.mul(daoandfarmingFee).mul(100 - taxDiscount).div(10000);
            DEWOTokenTaxes.forDevelopment = amount.mul(developmentFee).mul(100 - taxDiscount).div(10000);
            DEWOTokenTaxes.forCoreTeam = amount.mul(coreteamFee).mul(100 - taxDiscount).div(10000);
            DEWOTokenTaxes.forMarketing = amount.mul(marketingFee).mul(100 - taxDiscount).div(10000);
             

            // Calculate total taxes and deduct from the transfered amount
            uint totalTaxes =
                DEWOTokenTaxes.forDAOAndFarming
                .add(DEWOTokenTaxes.forDevelopment)
                .add(DEWOTokenTaxes.forCoreTeam)
                .add(DEWOTokenTaxes.forMarketing);
            amount = amount.sub(totalTaxes);

            // Pay DAO And Farming Taxes
            _balances[daoandfarmingAddress] += DEWOTokenTaxes.forDAOAndFarming;
            emit Transfer(from, daoandfarmingAddress, DEWOTokenTaxes.forDAOAndFarming);

            // Pay Development Fund Taxes
            _balances[developmentAddress] += DEWOTokenTaxes.forDevelopment;
            emit Transfer(from, developmentAddress, DEWOTokenTaxes.forDevelopment);

            // Pay Core-Team Taxes
            _balances[coreteamAddress] += DEWOTokenTaxes.forCoreTeam;
            emit Transfer(from, coreteamAddress, DEWOTokenTaxes.forCoreTeam);

            // Pay Marketing Taxes
            _balances[marketingAddress] += DEWOTokenTaxes.forMarketing;
            emit Transfer(from, marketingAddress, DEWOTokenTaxes.forMarketing);

        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}