/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/math/[email protected]
pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/access/[email protected]
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/EncryptoTRCVerifyAsset.sol


pragma solidity ^0.8.4;

library EncryptoTRCVerifyAsset {
	function getMessageHash(
		uint256 _tokenId,
		uint256 _amount,
		uint256 _validTo,
		uint256 _parentId,
		uint256 _population,
		uint256 _EncryptoTRCreward,
		uint16 _payType,
		address _recipient		
	) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					_tokenId,
					_amount,
					_validTo,
					_parentId,
					_population,
					_EncryptoTRCreward,
					_payType,
					_recipient
				)
			);
	}

	function getEthSignedMessageHash(bytes32 _messageHash)
		internal
		pure
		returns (bytes32)
	{
		/*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
		return
			keccak256(
				abi.encodePacked(
					"\x19Ethereum Signed Message:\n32",
					_messageHash
				)
			);
	}

	function verify(
		address _signer,
		uint256 _tokenId,
		uint256 _amount,
		uint256 _validTo,
		uint256 _parentId,
		uint256 _population,
		uint256 _EncryptoTRCreward,
		uint16 _payType,
		address _recipient,
		bytes memory signature
	) internal pure returns (bool) {
		bytes32 messageHash = getMessageHash(
			_tokenId,
			_amount,
			_validTo,
			_parentId,
			_population,
			_EncryptoTRCreward,
			_payType,
			_recipient
		);
		bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);		
		return recoverSigner(ethSignedMessageHash, signature) == _signer;
	}

	function verify2(
		address _signer,
		bytes32 messageHash,
		bytes memory signature
	) internal pure returns (bool) {
		bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);		
		return recoverSigner(ethSignedMessageHash, signature) == _signer;
	}

	function verifyMeta(
		address _signer,
		uint256 _tokenId,
		uint256 _validTo,
		uint16 _taxRate,
		string memory  _str1,
		string memory _str2,
		string memory _str3,
		bytes memory signature
	) internal pure returns (bool) {
		bytes32 messageHash = getMessageMetaHash(
			_tokenId,
			_validTo,
			_taxRate,
			_str1,
			_str2,
			_str3
		);
		bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);		
		return recoverSigner(ethSignedMessageHash, signature) == _signer;
	}

	function getMessageMetaHash(
		uint256 _tokenId,
		uint256 _validTo,
		uint16 _taxRate,
		string memory _str1,
		string memory _str2,
		string memory _str3
	) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					_tokenId,
					_validTo,
					_taxRate,
					_str1,
					_str2,
					_str3
				)
			);
	}

	function recoverSigner(
		bytes32 _ethSignedMessageHash,
		bytes memory _signature
	) internal pure returns (address) {
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

		return ecrecover(_ethSignedMessageHash, v, r, s);
	}

	function splitSignature(bytes memory sig)
		internal
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(sig.length == 65, "invalid signature length");

		assembly {
			/*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

			// first 32 bytes, after the length prefix
			r := mload(add(sig, 32))
			// second 32 bytes
			s := mload(add(sig, 64))
			// final byte (first byte of the next 32 bytes)
			v := byte(0, mload(add(sig, 96)))
		}

		// implicitly return (r, s, v)
	}
}


// File contracts/IUniswapV2Pair.sol
pragma solidity ^0.8.4;

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


// File contracts/IUniswapV2Factory.sol
pragma solidity ^0.8.4;

interface IUniswapV2Factory {
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


// File contracts/IUniswapV2Router.sol
pragma solidity ^0.8.4;

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



// pragma solidity >=0.6.2;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]
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
    function transferFrom(
        address sender,
        address recipient,
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


// File contracts/IEncryptoTRCToken.sol
pragma solidity ^0.8.4;
/**
 * @dev EncryptoTRC token Interface
 */
interface IEncryptoTRCToken is IERC20 {
	function setRewardsFactor(address holder, uint256 balance) external;

	function addStaticReward(address recipient, uint256 amount) external;

	function addAirdropReward(address recipient, uint256 amount) external;

	function allowNftTrade(address account, bool value) external;
}


// File contracts/IEncryptoTRCNFT.sol
pragma solidity ^0.8.4;

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IEncryptoTRCAsset {
	struct Asset {
		uint256 id; // token id
		uint256 parentId;
		uint256 price;	// Price $EncryptoTRC
		uint256 priceBNB;
		uint256 population; // Population. Rewards distributed based on population
		uint256 totalTax; // Accumulated tax earned through distribution
		uint256 assetType; // Asset type
		uint16 taxRate; // Asset Distribution tax rate
		string tag; // tag|titleid|0|Henry, eg. Promiseland|1|Henry
		string logoUrl; // Custom logo
		string attributes; // bgColour|future expansion		
	}
}

/**
 * @dev EncryptoTRC NFT Interface
 */
interface IEncryptoTRCNFT {

	function mint(uint256 tokenId, uint256 parentId, uint256 population, uint256 assetType) external;
	function buy(uint256 tokenId) external;
	function airdrop(uint256 tokenId, uint256 parentId,	uint256 population,uint256 assetType) external;

	function setTokenMetadata(uint256 tokenId, uint256 assetType, uint16 taxRate,string memory tag,string memory logoUrl,string memory attributes) external;
	function setTokenPrice(uint256 tokenId, uint256 price, uint256 priceBNB) external;

	function exists(uint256 tokenId) external view returns (bool);

	function increaseTokenTotalTax(uint256 tokenId,	uint256 balance) external;
	function getTokenDetail(uint256 tokenId) external view returns (IEncryptoTRCAsset.Asset memory);
	function getTokenOwner(uint256 tokenId) external view returns (address);
	function getTotalPopulationByOwner(address _owner) external view returns (uint256);
}


// File contracts/EncryptoTRCDapp.sol


pragma solidity ^0.8.4;

// @title dApp / EncryptoTRC.io
// @author [email protected]
// @whitepaper https://EncryptoTRC.io/Whitepaper.pdf
contract EncryptoTRCDapp is Ownable, IEncryptoTRCAsset {
	bool public EncryptoTRC_IS_AWESOME = true;

	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2Pair;

	using SafeMath for uint256;

	IEncryptoTRCToken public _EncryptoTRCToken;
	IEncryptoTRCNFT public _EncryptoTRCNFT;

	uint16 public WORLDTAX = 25; // 2.5%
	uint16 public MARKETINGTAX = 25; // 2.5%
	uint16 public DEFAULT_DISTRIBUTIONTAX = 50; // 5.0%

	uint16 public REFERRALFEE1 = 50; // 5%
	uint16 public REFERRALFEE2 = 100; // 10%
	uint16 public REFERRALFEE2_MIN_TOKENS = 1;
	uint16 public SAFEMATH_PRECISION = 10000;

	uint256 public totalRefferalPayout = 10586456639100000000000000; //Ref. previous dApp 0x4Ba1A3b6999AAcc1189f4738604f31CAA9608D47

	address payable public ownerWallet;
	address public signerAddress;
	address public liquidityWallet;
	address public marketingWallet;
	address public rewardsWallet = 0x24554c414E440000000000000000000000000002; // $EncryptoTRC Internal Rewards Wallet

	string private _tokenBaseURI = "https://api.EncryptoTRC.io/metadata/";

	bool public paused = false;

	mapping(address => bool) private _isExcludedFromFees; // exclude from fees
	mapping(address => bool) public EncryptoTRCContracts; // EncryptoTRC eco-system access

	struct Taxes {
		uint256 WORLDTAX_FEE;
		uint256 DISTRIBUTIONTAX_FEE;
		uint256 MARKETING_FEE;
	}

	modifier onlyEncryptoTRC() {
		require(EncryptoTRCContracts[msg.sender]);
		_;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is not paused.
	 */
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	constructor(
		address router,
		address EncryptoTRCToken,
		address _signerAddress,
		address _marketingWallet,
		address EncryptoTRCNFT
	) {
		_EncryptoTRCToken = IEncryptoTRCToken(EncryptoTRCToken);
		ownerWallet = payable(msg.sender);
		signerAddress = _signerAddress;
		marketingWallet = _marketingWallet;
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
			address(_EncryptoTRCToken),
			_uniswapV2Router.WETH()
		);

		liquidityWallet = address(_EncryptoTRCToken);
		_EncryptoTRCNFT = IEncryptoTRCNFT(EncryptoTRCNFT);

		//excludeFromFees(owner());
	}


	/**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return "EncryptoTRC DAPP";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return "AD";
    }

	function mint(
		uint16 payType,
		uint256 tokenId,
		uint256 price,
		uint256 validTo,
		uint256 parentId,
		uint256 population,
		uint256 EncryptoTRCReward,
		address referral,
		bytes memory signature
	) external payable whenNotPaused {
		require(_EncryptoTRCNFT.exists(tokenId) == false, "TOKEN_EXISTS");
		require(price > 0, "NOT_FOR_SALE");
		require(payType == 1 || payType == 2, "INVALID_PAYTYPE");
		require(population >= 0, "INVALID_POPULATION");
		require(block.timestamp <= validTo, "EXPIRED");

		bytes32 hash = keccak256(
			abi.encodePacked(
				tokenId,
				price,
				validTo,
				parentId,
				population,
				EncryptoTRCReward,
				payType,
				address(0)
			)
		);

		require(
			EncryptoTRCVerifyAsset.verify2(signerAddress, hash, signature) == true,
			"INVALIDSIG"
		); // Invalid signature

		if (payType == 1) // BNB
		{
			require(msg.value >= price, "AMOUNT_TOO_LOW"); //Bid amount too low
			_EncryptoTRCNFT.mint(tokenId, parentId, population, 0);
			standardTransfer(tokenId, msg.sender, address(0), referral);
		}
		// $EncryptoTRC
		else {
			_EncryptoTRCToken.transferFrom(msg.sender, address(this), price);
			_EncryptoTRCNFT.mint(tokenId, parentId, population, 0);
			standardERC20Transfer(
				tokenId,
				price,
				msg.sender,
				address(0),
				referral
			);
		}

		if (EncryptoTRCReward > 0) {
			_EncryptoTRCToken.addAirdropReward(msg.sender, EncryptoTRCReward);
			emit AirdropReward(msg.sender, EncryptoTRCReward);
		}
	}

	function buy(uint16 payType, uint256 tokenId)
		external
		payable
		whenNotPaused
	{
		require(payType == 1 || payType == 2, "INVALID_PAYTYPE");
		require(_EncryptoTRCNFT.exists(tokenId), "NOT_MINTED");

		Asset memory asset = _EncryptoTRCNFT.getTokenDetail(tokenId);
		address previousOwner = _EncryptoTRCNFT.getTokenOwner(tokenId);
		address newOwner = msg.sender;
		require(previousOwner != newOwner, "NO_REBUY"); //Cannot rebuy this

		if (payType == 1) {
			/// BNB
			require(asset.priceBNB > 0, "NOT_FOR_SALE");
			require(msg.value >= asset.priceBNB, "AMOUNT_TOO_LOW");
			_EncryptoTRCNFT.buy(tokenId);
			standardTransfer(tokenId, msg.sender, previousOwner, address(0));
		} else {
			// $EncryptoTRC
			require(asset.price > 0, "NOT_FOR_SALE");
			_EncryptoTRCToken.transferFrom(msg.sender, address(this), asset.price);
			_EncryptoTRCNFT.buy(tokenId);
			standardERC20Transfer(
				tokenId,
				asset.price,
				newOwner,
				previousOwner,
				address(0)
			);
		}
	}

	/* test token transfer */
    	function buytest()
		external
		payable
		whenNotPaused returns (uint256)
	{
            uint256 afterSwapTokenSum = swapExactETHForTokens(
				address(this),
				msg.value
			);
            return afterSwapTokenSum;
	}


	/*
	 * @notice Unlock payments
	 */
	function unlock(
		uint16 payType,
		string calldata trxid,
		uint256 amount
	) external payable whenNotPaused {
		require(payType == 1 || payType == 2, "INVALID_PAYTYPE");

		// BNB
		if (payType == 1) {
			payable(address(marketingWallet)).transfer(msg.value);
			emit Unlock(msg.sender, trxid, payType, msg.value);
		}
		// $EncryptoTRC
		if (payType == 2) {
			_EncryptoTRCToken.transferFrom(msg.sender, marketingWallet, amount);
			emit Unlock(msg.sender, trxid, payType, amount);
		}
	}

	/*
	 * @notice NFT Giveaway to support Airdrops
	 */
	function airdrop(
		uint256 tokenId,
		uint256 validTo,
		uint256 parentId,
		uint256 population,
		uint256 assetType,
		bytes memory signature
	) external whenNotPaused {
		require(population >= 0, "INVALID_POPULATION");
		require(block.timestamp <= validTo, "EXPIRED");
		bytes32 hash = keccak256(
			abi.encodePacked(
				tokenId,
				validTo,
				parentId,
				population,
				assetType,
				address(msg.sender)
			)
		);
		require(
			EncryptoTRCVerifyAsset.verify2(signerAddress, hash, signature) == true,
			"INVALIDSIG"
		); // Invalid signature
		_EncryptoTRCNFT.airdrop(tokenId, parentId, population, assetType);
	}

	/*
	 * @notice Set token metadata
	 */
	function setTokenMetadata(
		uint256 tokenId,
		uint256 validTo, // signature
		uint16 taxRate,
		string memory tag,
		string memory logoUrl,
		string memory attributes,
		bytes memory signature
	) external whenNotPaused {
		require(_EncryptoTRCNFT.exists(tokenId), "NOT_FOUND");
		address tokenOwner = _EncryptoTRCNFT.getTokenOwner(tokenId);
		require(_msgSender() == tokenOwner, "NOT_OWNER");
		require(taxRate >= 0, "TAXRATE_TOO_LOW");
		require(taxRate <= 75, "TAXRATE_TOO_HIGH");
		require(block.timestamp <= validTo, "EXPIRED");
		require(
			EncryptoTRCVerifyAsset.verifyMeta(
				signerAddress,
				tokenId,
				validTo,
				taxRate,
				tag,
				logoUrl,
				attributes,
				signature
			) == true,
			"INVALIDSIG" // Invalid signature
		);
		_EncryptoTRCNFT.setTokenMetadata(
			tokenId,
			0,
			taxRate,
			tag,
			logoUrl,
			attributes
		);
	}

	/*
	 * @notice Set token price
	 *
	 * @param tokenId: Token id
	 * @param price: Price (0 = not for sale)
	 *
	 */
	function setTokenPrice(
		uint256 tokenId,
		uint256 price,
		uint256 priceBNB
	) external whenNotPaused {
		require(_EncryptoTRCNFT.exists(tokenId), "NOT_FOUND");
		address tokenOwner = _EncryptoTRCNFT.getTokenOwner(tokenId);
		require(_msgSender() == tokenOwner, "NOT_OWNER");
		_EncryptoTRCNFT.setTokenPrice(tokenId, price, priceBNB);
	}

	function notifyTokenTransfer(
		address seller,
		uint256 sellerRewardsFactor,
		address buyer,
		uint256 buyerRewardsFactor,
		uint256 tokenId
	) public onlyEncryptoTRC {
		require(tokenId > 0, "INVALID_TOKENID");

		_EncryptoTRCToken.setRewardsFactor(seller, sellerRewardsFactor);
		_EncryptoTRCToken.setRewardsFactor(buyer, buyerRewardsFactor);
	}

	/*
	 * Internal
	 */
	function standardTransfer(
		uint256 tokenId,
		address newOwner,
		address previousOwner,
		address referral
	) private {
		Asset memory asset = _EncryptoTRCNFT.getTokenDetail(tokenId);

		Taxes memory tax = getTaxes(msg.value, tokenId);

		/// @dev Seller balance less taxes
		uint256 sellerBalance = (msg.value)
			.sub(tax.WORLDTAX_FEE)
			.sub(tax.DISTRIBUTIONTAX_FEE)
			.sub(tax.MARKETING_FEE);

		uint256 refferalFee = 0;

		/// @dev (mint only): Calculate refferal fee and transfer balance to liquidity wallet
		if (address(previousOwner) == address(0)) {
			/// @dev Deduct refferral fee from seller balance (mints only)
			refferalFee = getReferralFee(
				previousOwner,
				newOwner,
				referral,
				sellerBalance
			);
			totalRefferalPayout = totalRefferalPayout.add(refferalFee);
			sellerBalance = sellerBalance.sub(refferalFee);

			payable(address(liquidityWallet)).transfer(sellerBalance);
			sellerBalance = 0;
		}

		/// @dev Transfer WORLDTAX_FEE to liquidity wallet
		if (tax.WORLDTAX_FEE > 0) {
			payable(address(liquidityWallet)).transfer(tax.WORLDTAX_FEE);
		}

		if (tax.MARKETING_FEE > 0) {
			payable(address(marketingWallet)).transfer(tax.MARKETING_FEE);
		}

		/// @dev Swap balance into $EncryptoTRC
		uint256 beforeSwapEthBalance = sellerBalance
			.add(tax.DISTRIBUTIONTAX_FEE)
			.add(refferalFee);

		if (beforeSwapEthBalance > 0) {
			uint256 residualTax;

			/// @dev ETH => $EncryptoTRC
			uint256 afterSwapTokenSum = swapExactETHForTokens(
				address(this),
				beforeSwapEthBalance
			);

			uint256 swapPrecisionFactor = afterSwapTokenSum
				.mul(SAFEMATH_PRECISION)
				.div(beforeSwapEthBalance);

			/// @dev Transfer referral fees
			if (refferalFee > 0) {
				uint256 conv = swapPrecisionFactor.mul(refferalFee).div(
					SAFEMATH_PRECISION
				);
				_EncryptoTRCToken.transfer(rewardsWallet, conv);
				_EncryptoTRCToken.addStaticReward(referral, conv);
				afterSwapTokenSum = afterSwapTokenSum.sub(conv);

				emit Referral(referral, tokenId, conv);
			}

			/// @dev Distribute tax to parent NFT holders
			if (tax.DISTRIBUTIONTAX_FEE > 0) {
				uint256 conv = swapPrecisionFactor
					.mul(tax.DISTRIBUTIONTAX_FEE)
					.div(SAFEMATH_PRECISION);
				residualTax = distributeTaxes(asset.parentId, conv);

				afterSwapTokenSum = afterSwapTokenSum.sub(conv);
			}

			/// @dev Pay seller in $EncryptoTRC
			if (sellerBalance > 0) {
				uint256 conv = swapPrecisionFactor.mul(sellerBalance).div(
					SAFEMATH_PRECISION
				);
				_EncryptoTRCToken.transfer(previousOwner, conv);
			}

			/// @dev In case of no parents add remaining balance to liquidity incl. margin precision difference
			if (residualTax > 0) {
				_EncryptoTRCToken.transfer(
					liquidityWallet,
					_EncryptoTRCToken.balanceOf(address(this))
				);
			}
		}

		updateRewards(previousOwner);
		updateRewards(newOwner);
	}

	function updateRewards(address owner) internal {
		if (owner != address(0)) {
			uint256 rewardsFactor = _EncryptoTRCNFT.getTotalPopulationByOwner(owner);
			_EncryptoTRCToken.setRewardsFactor(owner, rewardsFactor);
		}
	}

	function standardERC20Transfer(
		uint256 tokenId,
		uint256 amount,
		address newOwner,
		address previousOwner,
		address referral
	) private {
		Asset memory asset = _EncryptoTRCNFT.getTokenDetail(tokenId);

		Taxes memory tax = getTaxes(amount, tokenId);

		/// @dev Seller balance less taxes
		uint256 sellerBalance = (amount)
			.sub(tax.WORLDTAX_FEE)
			.sub(tax.DISTRIBUTIONTAX_FEE)
			.sub(tax.MARKETING_FEE);

		/// @dev (mint only): Refferal fee
		if (address(previousOwner) == address(0)) {
			/// @dev Deduct refferral fee from seller balance (mints only)
			uint256 refferalFee = getReferralFee(
				previousOwner,
				newOwner,
				referral,
				sellerBalance
			);

			//sellerBalance = sellerBalance.sub(refferalFee);
			if (refferalFee > 0) {
				totalRefferalPayout = totalRefferalPayout.add(refferalFee);
				_EncryptoTRCToken.transfer(rewardsWallet, refferalFee);
				_EncryptoTRCToken.addStaticReward(referral, refferalFee);
				emit Referral(referral, tokenId, refferalFee);
			}
		}

		/// @dev Transfer WORLDTAX_FEE to liquidity wallet
		if (tax.WORLDTAX_FEE > 0) {
			_EncryptoTRCToken.transfer(liquidityWallet, tax.WORLDTAX_FEE);
		}

		if (tax.MARKETING_FEE > 0) {
			_EncryptoTRCToken.transfer(marketingWallet, tax.MARKETING_FEE);
		}

		uint256 residualTax;
		/// @dev Distribute tax to parent NFT holders
		if (tax.DISTRIBUTIONTAX_FEE > 0) {
			residualTax = distributeTaxes(
				asset.parentId,
				tax.DISTRIBUTIONTAX_FEE
			);
		}

		/// @dev Pay seller in $EncryptoTRC

		if (previousOwner != address(0) && sellerBalance > 0) {
			_EncryptoTRCToken.transfer(previousOwner, sellerBalance);
		}

		/// @dev In case of no parents add remaining balance to liquidity
		if (residualTax > 0) {
			_EncryptoTRCToken.transfer(
				liquidityWallet,
				_EncryptoTRCToken.balanceOf(address(this))
			);
		}

		updateRewards(previousOwner);
		updateRewards(newOwner);
	}

	function setEncryptoTRCContractAllow(address contractAddress, bool access)
		public
		onlyOwner
	{
		EncryptoTRCContracts[contractAddress] = access;
		emit EncryptoTRCContractAllowChange(contractAddress, access);
	}

	function getTaxes(uint256 balance, uint256 tokenId)
		private
		view
		returns (Taxes memory)
	{
		Taxes memory taxes;

		if (_isExcludedFromFees[msg.sender]) {
			taxes.WORLDTAX_FEE = 0;
			taxes.DISTRIBUTIONTAX_FEE = 0;
			taxes.MARKETING_FEE = 0;
		} else {
			Asset memory asset = _EncryptoTRCNFT.getTokenDetail(tokenId);

			// @dev Allow for custom distribution tax set individually per NFT asset
			if (asset.parentId == 0) {
				taxes.DISTRIBUTIONTAX_FEE = _getFeeAmount(
					balance,
					DEFAULT_DISTRIBUTIONTAX
				);
			} else {
				taxes.DISTRIBUTIONTAX_FEE = _getFeeAmount(
					balance,
					//assets[tokenId].taxRate
					asset.taxRate
				); // As set by NFT
			}

			taxes.WORLDTAX_FEE = _getFeeAmount(balance, WORLDTAX); // 2.5%
			taxes.MARKETING_FEE = _getFeeAmount(balance, MARKETINGTAX); // 2.5%
		}
		return taxes;
	}

	function distributeTaxes(uint256 tokenId, uint256 taxes)
		private
		returns (uint256)
	{
		if (tokenId == 0) {
			return taxes;
		}
		if (taxes == 0) {
			return 0;
		}
		Asset memory token = _EncryptoTRCNFT.getTokenDetail(tokenId);

		uint256 balance = taxes;
		if (token.parentId != 0) {
			balance = taxes.div(2); // Split taxes
		}

		address payee = _EncryptoTRCNFT.getTokenOwner(tokenId);

		_EncryptoTRCToken.transfer(rewardsWallet, balance);
		_EncryptoTRCToken.addStaticReward(payee, balance);

		_EncryptoTRCNFT.increaseTokenTotalTax(tokenId, balance);

		if (token.parentId != 0) {
			return distributeTaxes(token.parentId, balance);
		}
		return 0;
	}

	function getReferralFee(
		address seller,
		address buyer,
		address referer,
		uint256 sellerBalance
	) internal view returns (uint256) {
		if (
			address(seller) == address(0) &&
			referer != address(0) &&
			buyer != referer
		) {
			if (_EncryptoTRCToken.balanceOf(referer) >= REFERRALFEE2_MIN_TOKENS) {
				return _getFeeAmount(sellerBalance, REFERRALFEE2);
			} else {
				return _getFeeAmount(sellerBalance, REFERRALFEE1);
			}
		}
		return 0;
	}

	function _getFeeAmount(uint256 amount, uint16 fee)
		internal
		pure
		returns (uint256 feeAmount)
	{
		feeAmount = (amount.mul(fee)).div(1000);
	}

	function swapExactETHForTokens(address to, uint256 amount)
		internal
		returns (uint256)
	{
		if (amount == 0) {
			return 0;
		}
		address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = address(_EncryptoTRCToken);

		uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{
			value: amount
		}(0, path, to, block.timestamp + 150);

		emit SwapFromEth(amount, amounts[1]);

		return amounts[1];
	}

	/// @dev Withdraw funds that gets stuck in contract by accident
	function emergencyWithdraw() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	/// @dev Withdraw EncryptoTRC that gets stuck in contract by accident
	function emergencyWithdrawEncryptoTRC() external onlyOwner {
		_EncryptoTRCToken.transfer(owner(), _EncryptoTRCToken.balanceOf(address(this)));
	}

	function excludeFromFees(address account) public onlyOwner {
		if (!_isExcludedFromFees[account]) {
			_isExcludedFromFees[account] = true;
		}
	}

	/*
	 * onlyOwner
	 */

	function setSignerAddress(address _signerAddress) public onlyOwner {
		signerAddress = _signerAddress;
	}

	function setLiquidityWallet(address _liquidityWallet) public onlyOwner {
		liquidityWallet = _liquidityWallet;
	}

	function setRewardsWallet(address _rewardsWallet) public onlyOwner {
		rewardsWallet = _rewardsWallet;
	}

	function setMarketingWallet(address _marketingWallet) public onlyOwner {
		marketingWallet = _marketingWallet;
	}

	function setPause(bool _paused) public onlyOwner {
		paused = _paused;
	}

	function setTaxes(
		uint16 _WORLDTAX,
		uint16 _MARKETINGTAX,
		uint16 _DISTRIBUTIONTAX
	) public onlyOwner {
		require(_WORLDTAX <= 75);
		require(_MARKETINGTAX <= 75);
		require(_DISTRIBUTIONTAX <= 75);
		WORLDTAX = _WORLDTAX;
		MARKETINGTAX = _MARKETINGTAX;
		DEFAULT_DISTRIBUTIONTAX = _DISTRIBUTIONTAX;

		emit SetTaxes(WORLDTAX, MARKETINGTAX, DEFAULT_DISTRIBUTIONTAX);
	}

	function setReferralRates(uint16 _REFERRALFEE1, uint16 _REFERRALFEE2)
		public
		onlyOwner
	{
		require(_REFERRALFEE1 >= 0 && _REFERRALFEE1 <= 200, "_REFERRALFEE1");
		require(_REFERRALFEE2 >= 0 && _REFERRALFEE2 <= 200, "_REFERRALFEE2");
		REFERRALFEE1 = _REFERRALFEE1;
		REFERRALFEE2 = _REFERRALFEE2;
	}

	/*
	 * Events
	 */

	event AirdropReward(address to, uint256 amount);
	event SetTaxes(
		uint256 worldTax,
		uint256 marketingTax,
		uint256 distributionTax
	);
	event SwapFromEth(uint256 eth, uint256 token);
	event Referral(address referrer, uint256 tokenId, uint256 amount);
	event EncryptoTRCContractAllowChange(
		address indexed contractAddress,
		bool access
	);
	event Unlock(address sender, string trxid, uint16 payType, uint256 amount);
}