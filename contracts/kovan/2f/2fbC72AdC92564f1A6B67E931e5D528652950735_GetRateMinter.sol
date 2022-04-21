pragma solidity ^0.5.0;

import "SafeMath.sol";
import "Ownable.sol";
//import "SafeMath.sol";
//import "Ownable.sol";
import "IManager.sol";
import "INetAssetValueUSD.sol";
import "IPriceUSD.sol";
import "ISRC20.sol";

/**
 * @title GetRateMinter
 * @dev Serves as proxy (manager) for SRC20 minting/burning.
 */
contract GetRateMinter {
    IManager public _registry;
    INetAssetValueUSD public _asset;
    IPriceUSD public _SWMPriceOracle;

    using SafeMath for uint256;

    constructor(address registry, address asset, address SWMRate) public {
        _registry = IManager(registry);
        _asset = INetAssetValueUSD(asset);
        _SWMPriceOracle = IPriceUSD(SWMRate);
    }

    modifier onlyTokenOwner(address src20) {
	
        require(msg.sender == Ownable(src20).owner() ||
                msg.sender == ISRC20(src20).fundRaiserAddr(), "caller not token owner");
        _;
    }

    /**
     *  Calculate how many SWM tokens need to be staked to tokenize an asset
     *  This function is custom for each GetRateMinter contract
     *  Specification: https://docs.google.com/document/d/1Z-XuTxGf5LQudO5QLmnSnD-k3nTb0tlu3QViHbOSQXo/
     *
     *  Note: The stake requirement depends only on the asset USD value and USD/SWM exchange rate (SWM price).
     *        It doesn't depend on the number of tokens to be minted!
     *
     *  @param netAssetValueUSD Tokenized Asset Value in USD
     *  @return the number of SWM tokens
     */
    function calcStake(uint256 netAssetValueUSD) public view returns (uint256) {

        uint256 NAV = netAssetValueUSD; // Value in USD, an integer
        uint256 stakeUSD;

        if(NAV >= 0 && NAV <= 500000) // Up to 500,000 NAV the stake is flat at 2,500 USD
            stakeUSD = 2500;

        if(NAV > 500000 && NAV <= 1000000) // From 500K up to 1M stake is 0.5%
            stakeUSD = NAV.mul(5).div(1000);

        if(NAV > 1000000 && NAV <= 5000000) // From 1M up to 5M stake is 0.45%
            stakeUSD = NAV.mul(45).div(10000);

        if(NAV > 5000000 && NAV <= 15000000) // From 5M up to 15M stake is 0.40%
            stakeUSD = NAV.mul(4).div(1000);

        if(NAV > 15000000 && NAV <= 50000000) // From 15M up to 50M stake is 0.25%
            stakeUSD = NAV.mul(25).div(10000);

        if(NAV > 50000000 && NAV <= 100000000) // From 50M up to 100M stake is 0.20%
            stakeUSD = NAV.mul(2).div(1000);

        if(NAV > 100000000 && NAV <= 150000000) // From 100M up to 150M stake is 0.15%
            stakeUSD = NAV.mul(15).div(10000);

        if(NAV > 150000000) // From 150M up stake is 0.10%
            stakeUSD = NAV.mul(1).div(1000);

        (uint256 numerator, uint denominator) = _SWMPriceOracle.getPrice(); // 0.04 is returned as (4, 100)

        return stakeUSD.mul(denominator).div(numerator).mul(10**18); // 10**18 because we return Wei

    } /// fn calcStake

    /**
     *  This proxy function calls the SRC20Registry function that will do two things
     *  Note: prior to this, the msg.sender has to call approve() on the SWM ERC20 contract
     *        and allow the Manager to withdraw SWM tokens
     *  1. Withdraw the SWM tokens that are required for staking
     *  2. Mint the SRC20 tokens
     *  Only the Owner of the SRC20 token can call this function
     *
     *  @param src20 The address of the SRC20 token to mint tokens for
     *  @param numSRC20Tokens Number of SRC20 tokens to mint
     *  @return true on success
     */
    function stakeAndMint(address src20, uint256 numSRC20Tokens)
        external
        onlyTokenOwner(src20)
        returns (bool)
    {
        uint256 numSWMTokens = calcStake(_asset.getNetAssetValueUSD(src20));
	
	if (msg.sender == ISRC20(src20).fundRaiserAddr())
       		require(_registry.mintSupply(src20, Ownable(src20).owner(), numSWMTokens, numSRC20Tokens), 'supply minting failed');
	else
       		require(_registry.mintSupply(src20, msg.sender, numSWMTokens, numSRC20Tokens), 'supply minting failed');

        return true;
    }
}

pragma solidity ^0.5.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Manager handles SRC20 burn/mint in relation to
 * SWM token staking.
 */
interface IManager {
 
    event SRC20SupplyMinted(address src20, address swmAccount, uint256 swmValue, uint256 src20Value);
    event SRC20StakeIncreased(address src20, address swmAccount, uint256 swmValue);
    event SRC20StakeDecreased(address src20, address swmAccount, uint256 swmValue);

    function mintSupply(address src20, address swmAccount, uint256 swmValue, uint256 src20Value) external returns (bool);
    function increaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function decreaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function renounceManagement(address src20) external returns (bool);
    function transferManagement(address src20, address newManager) external returns (bool);
    function calcTokens(address src20, uint256 swmValue) external view returns (uint256);

    function getStake(address src20) external view returns (uint256);
    function swmNeeded(address src20, uint256 srcValue) external view returns (uint256);
    function getSrc20toSwmRatio(address src20) external returns (uint256);
    function getTokenOwner(address src20) external view returns (address);
}

pragma solidity ^0.5.0;

/**
 * @dev Interface for the AssetRegistry contract
 */
interface INetAssetValueUSD {

    function getNetAssetValueUSD(address src20) external view returns (uint256);
}

pragma solidity ^0.5.0;

/**
    @title interface for exchange rate provider contracts
 */
interface IPriceUSD {

    function getPrice() external view returns (uint256 numerator, uint256 denominator);

}

pragma solidity ^0.5.0;

/**
 * @title SRC20 public interface
 */
interface ISRC20 {

    event RestrictionsAndRulesUpdated(address restrictions, address rules);

    function transferToken(address to, uint256 value, uint256 nonce, uint256 expirationTime,
        bytes32 msgHash, bytes calldata signature) external returns (bool);
    function transferTokenFrom(address from, address to, uint256 value, uint256 nonce,
        uint256 expirationTime, bytes32 hash, bytes calldata signature) external returns (bool);
    function getTransferNonce() external view returns (uint256);
    function getTransferNonce(address account) external view returns (uint256);
    function executeTransfer(address from, address to, uint256 value) external returns (bool);
    function updateRestrictionsAndRules(address restrictions, address rules) external returns (bool);

    // ERC20 part-like interface
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function increaseAllowance(address spender, uint256 value) external returns (bool);
    function decreaseAllowance(address spender, uint256 value) external returns (bool);

    function fundRaiserAddr() external returns (address);
}