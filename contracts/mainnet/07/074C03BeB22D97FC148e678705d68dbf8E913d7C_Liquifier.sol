/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: Unlicensed
interface FactoryInterface {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface RouterInterface {
	function WETH() external view returns (address);
    function factory() external view returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Liquifier {
	using SafeMath for uint256;
	address public router;
	address public factory;
	address public liquifiable;	// token it will liquify
	address public weth;
	
	address[] path;
	
	address public liquifiablePair;
	
	constructor(address _routerAddr) {
		router = _routerAddr;
		RouterInterface _router = RouterInterface(_routerAddr);
		factory = _router.factory();
		liquifiable = msg.sender;
		weth = _router.WETH();
		path.push(liquifiable);
		path.push(weth);
		
		liquifiablePair = FactoryInterface(factory).createPair(weth, liquifiable);
	}
	
	function _swapForWETH(uint256 amountToken) private {
		ERC20Interface(liquifiable).approve(router, uint256(-1));
		RouterInterface(router).swapExactTokensForTokens(amountToken, 0, path, address(this), block.timestamp);
	}
	
	function _addLiquidity() private {
		ERC20Interface(weth).approve(router, uint256(-1));
		uint256 _amtToken = ERC20Interface(liquifiable).balanceOf(address(this));
		uint256 _amtWETH = ERC20Interface(weth).balanceOf(address(this));
		RouterInterface(router).addLiquidity(liquifiable, weth, _amtToken, _amtWETH, 0, 0, address(this), block.timestamp);
	}
	
	function liquify() public {
		uint256 bal = ERC20Interface(liquifiable).balanceOf(address(this));
		_swapForWETH(bal.div(2));
		_addLiquidity();
	}
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
	event OwnershipRenounced();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
	
	function _chainId() internal pure returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}
	
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
	
	function renounceOwnership() public onlyOwner {
		owner = address(0);
		newOwner = address(0);
		emit OwnershipRenounced();
	}
}

contract Hashbarium is Owned {
	using SafeMath for uint256;
	
	// assigned on constructor
	address public excluder;	// the address that can exclude from antiwhale (owner at start, can be changed later)
	address public marketing;	// marketing address
	string 	public name;		// token name
	string 	public symbol;		// token symbol
	uint256 public supply;		// total supply
	
	// hardcoded
	uint8 public decimals = 18;	// erc20 decimals (18 by default)
	uint256 public mktTax = 3;	// 3% editable later (onlyOwner)
	uint256 public liqTax = 2;	// 2% editable later (onlyOwner too)
	
	// generated on deployment
	address public liquifier;	// liquifier contract address (set by constructor after deploying it)
	address public liquifiablePair;
	
	
	// used by system
	bool isLiquifying;
	
	// user data
	mapping (address => uint256) public balances;							// user balances
	mapping (address => mapping (address => uint256)) public allowances;	// user allowances
	mapping (address => bool) excluded;										// excluded from antiwhale
	
	// ERC20 mandatory events
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	// custom events
	event TaxesChanged(uint256 indexed marketingTax, uint256 indexed liquidityTax);
	event ExcluderChanged(address indexed newExcluder);
	event Excluded(address indexed guy);
	event UnExcluded(address indexed guy);
	event MarketingAddressChanged(address indexed newAddress);
	
	constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address router, address _marketing) {
		name = _name;
		symbol = _symbol;
		supply = _totalSupply;
		
		Liquifier _liquifierCnt = new Liquifier(router);
		liquifier = address(_liquifierCnt);
		liquifiablePair = _liquifierCnt.liquifiablePair();
		excluded[liquifiablePair] = true;
		
		marketing = _marketing;
		balances[msg.sender] = _totalSupply;	// mints supply to deployer
		excluded[msg.sender] = true;			// excludes deployer from antiwhale
		excluder = msg.sender;					// sets msg.sender as excluder
		
		// excludes burn addresses (allows to burn unlimited amount)
		excluded[address(0)] = true;
		excluded[address(0xdead)] = true;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}
	
	// view functions
	function balanceOf(address tokenOwner) public view returns (uint256) {
		return ((tokenOwner == address(0xdead)) || (tokenOwner == address(0))) ? 0 : balances[tokenOwner];	// returns 0 when dead or 0 address asked, otherwise return balance
	}
	
	function totalSupply() public view returns (uint256) {
		return supply.sub(balances[address(0xdead)]).sub(balances[address(0)]);
	}
	
	function allowance(address tokenOwner, address spender) public view returns (uint256) {
		return allowances[tokenOwner][spender];
	}

	// private functions
	function _transfer(address from, address to, uint256 tokens) private {
		uint256 toLP = isLiquifying ? 0 : tokens.mul(liqTax).div(100);	// calculates amount to LP
		uint256 toMkt = isLiquifying ? 0 : tokens.mul(mktTax).div(100);	// calculates amount to marketing
		uint256 totalTax = toLP.add(toMkt);
		uint256 toRecipient = tokens.sub(totalTax);
		
		balances[from] = balances[from].sub(tokens);	// deducts tokens from sender
		
		balances[liquifier] = balances[liquifier].add(toLP);	// adds them to LP balance
		if (!isLiquifying) {	// liquifying when to == liquifiablePair messes with reserves
			isLiquifying = true;	// lock variable to prevent infinite recursion
			(bool success, ) = liquifier.call(abi.encodeWithSelector(bytes4(keccak256(abi.encodePacked("liquify()")))));	// calls liquifier contract to add liquidity
            success;    // silents warning
			isLiquifying = false;	// unlocks it to allow further liquify
		}
		// executed AFTER to avoid messing with reserves
		balances[to] = balances[to].add(toRecipient);			// adds tokens to recipient balance
		balances[marketing] = balances[marketing].add(toMkt);	// adds marketing tokens to marketing balance
		
		emit Transfer(from, to, toRecipient);						// event ALWAYS fired in accordance with ERC20 standard
		if (toLP > 0) { emit Transfer(from, liquifier, toLP); }	// event only if lpTax > 0
		if (toMkt > 0) { emit Transfer(from, marketing, toMkt); }	// event only if mkt tax > 0
		
		require((balances[to] <= totalSupply().div(100)) || excluded[to], "UNMATCHED_ANTIWHALE");
	}
	
	// public functions
	function transfer(address to, uint256 tokens) public returns (bool) {
		_transfer(msg.sender, to, tokens);
		return true;
	}
	
	function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
		allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens, "INSUFFICIENT_ALLOWANCE");
		_transfer(from, to, tokens);
		return true;
	}
	
	function approve(address spender, uint256 tokens) public returns (bool) {
		allowances[msg.sender][spender] = allowances[msg.sender][spender].add(tokens);
		emit Approval(msg.sender, spender, tokens);
		return true;
	}
	
	
	// only owner stuff
	function setTaxes(uint256 _marketing, uint256 _liquidity) public onlyOwner {
		mktTax = _marketing;
		liqTax = _liquidity;
		emit TaxesChanged(_marketing, _liquidity);
	}
	
	
	// only excluder stuff (*allows both owner AND excluder)
	modifier onlyExcluder {
		require(msg.sender == owner || msg.sender == excluder, "Excluder: wut");
		_;
	}
	
	function changeExcluder(address newExcluder) public onlyExcluder {
		excluder = newExcluder;
		emit ExcluderChanged(newExcluder);
	}
	
	function exclude(address addr) public onlyExcluder {
		excluded[addr] = true;
		emit Excluded(addr);
	}
	
	function unexclude(address addr) public onlyExcluder {
		excluded[addr] = false;
		emit UnExcluded(addr);
	}
	
	// set marketing stuff
	function setMarketing(address _newAddress) public {
		require(msg.sender == owner || msg.sender == marketing, "Marketing: wut");
		marketing = _newAddress;
		emit MarketingAddressChanged(_newAddress);
	}
}