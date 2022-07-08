// // File: @openzeppelin/contracts/utils/Context.sol

// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// /*
//  * @dev Provides information about the current execution context, including the
//  * sender of the transaction and its data. While these are generally available
//  * via msg.sender and msg.data, they should not be accessed in such a direct
//  * manner, since when dealing with meta-transactions the account sending and
//  * paying for execution may not be the actual sender (as far as an application
//  * is concerned).
//  *
//  * This contract is only required for intermediate, library-like contracts.
//  */
// abstract contract Context {
//     function _msgSender() internal view virtual returns (address) {
//         return msg.sender;
//     }

//     function _msgData() internal view virtual returns (bytes calldata) {
//         this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
//         return msg.data;
//     }
// }



// // File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity ^0.8.0;

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// // File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



// pragma solidity ^0.8.0;


// /**
//  * @dev Interface for the optional metadata functions from the ERC20 standard.
//  *
//  * _Available since v4.1._
//  */
// interface IERC20Metadata is IERC20 {
//     /**
//      * @dev Returns the name of the token.
//      */
//     function name() external view returns (string memory);

//     /**
//      * @dev Returns the symbol of the token.
//      */
//     function symbol() external view returns (string memory);

//     /**
//      * @dev Returns the decimals places of the token.
//      */
//     function decimals() external view returns (uint8);
// }

// // File: @openzeppelin/contracts/token/ERC20/ERC20.sol



// pragma solidity ^0.8.0;




// /**
//  * @dev Implementation of the {IERC20} interface.
//  *
//  * This implementation is agnostic to the way tokens are created. This means
//  * that a supply mechanism has to be added in a derived contract using {_mint}.
//  * For a generic mechanism see {ERC20PresetMinterPauser}.
//  *
//  * TIP: For a detailed writeup see our guide
//  * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
//  * to implement supply mechanisms].
//  *
//  * We have followed general OpenZeppelin guidelines: functions revert instead
//  * of returning `false` on failure. This behavior is nonetheless conventional
//  * and does not conflict with the expectations of ERC20 applications.
//  *
//  * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
//  * This allows applications to reconstruct the allowance for all accounts just
//  * by listening to said events. Other implementations of the EIP may not emit
//  * these events, as it isn't required by the specification.
//  *
//  * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
//  * functions have been added to mitigate the well-known issues around setting
//  * allowances. See {IERC20-approve}.
//  */
// contract ERC20 is Context, IERC20, IERC20Metadata {
//     mapping (address => uint256) private _balances;

//     mapping (address => mapping (address => uint256)) private _allowances;

//     uint256 private _totalSupply;

//     string private _name;
//     string private _symbol;

//     /**
//      * @dev Sets the values for {name} and {symbol}.
//      *
//      * The defaut value of {decimals} is 18. To select a different value for
//      * {decimals} you should overload it.
//      *
//      * All two of these values are immutable: they can only be set once during
//      * construction.
//      */
//     constructor (string memory name_, string memory symbol_) {
//         _name = name_;
//         _symbol = symbol_;
//     }

//     /**
//      * @dev Returns the name of the token.
//      */
//     function name() public view virtual override returns (string memory) {
//         return _name;
//     }

//     /**
//      * @dev Returns the symbol of the token, usually a shorter version of the
//      * name.
//      */
//     function symbol() public view virtual override returns (string memory) {
//         return _symbol;
//     }

//     /**
//      * @dev Returns the number of decimals used to get its user representation.
//      * For example, if `decimals` equals `2`, a balance of `505` tokens should
//      * be displayed to a user as `5,05` (`505 / 10 ** 2`).
//      *
//      * Tokens usually opt for a value of 18, imitating the relationship between
//      * Ether and Wei. This is the value {ERC20} uses, unless this function is
//      * overridden;
//      *
//      * NOTE: This information is only used for _display_ purposes: it in
//      * no way affects any of the arithmetic of the contract, including
//      * {IERC20-balanceOf} and {IERC20-transfer}.
//      */
//     function decimals() public view virtual override returns (uint8) {
//         return 18;
//     }

//     /**
//      * @dev See {IERC20-totalSupply}.
//      */
//     function totalSupply() public view virtual override returns (uint256) {
//         return _totalSupply;
//     }

//     /**
//      * @dev See {IERC20-balanceOf}.
//      */
//     function balanceOf(address account) public view virtual override returns (uint256) {
//         return _balances[account];
//     }

//     /**
//      * @dev See {IERC20-transfer}.
//      *
//      * Requirements:
//      *
//      * - `recipient` cannot be the zero address.
//      * - the caller must have a balance of at least `amount`.
//      */
//     function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
//         _transfer(_msgSender(), recipient, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-allowance}.
//      */
//     function allowance(address owner, address spender) public view virtual override returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     /**
//      * @dev See {IERC20-approve}.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function approve(address spender, uint256 amount) public virtual override returns (bool) {
//         _approve(_msgSender(), spender, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-transferFrom}.
//      *
//      * Emits an {Approval} event indicating the updated allowance. This is not
//      * required by the EIP. See the note at the beginning of {ERC20}.
//      *
//      * Requirements:
//      *
//      * - `sender` and `recipient` cannot be the zero address.
//      * - `sender` must have a balance of at least `amount`.
//      * - the caller must have allowance for ``sender``'s tokens of at least
//      * `amount`.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
//         _transfer(sender, recipient, amount);

//         uint256 currentAllowance = _allowances[sender][_msgSender()];
//         require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
//         _approve(sender, _msgSender(), currentAllowance - amount);

//         return true;
//     }

//     /**
//      * @dev Atomically increases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
//         return true;
//     }

//     /**
//      * @dev Atomically decreases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      * - `spender` must have allowance for the caller of at least
//      * `subtractedValue`.
//      */
//     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
//         uint256 currentAllowance = _allowances[_msgSender()][spender];
//         require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
//         _approve(_msgSender(), spender, currentAllowance - subtractedValue);

//         return true;
//     }

//     /**
//      * @dev Moves tokens `amount` from `sender` to `recipient`.
//      *
//      * This is internal function is equivalent to {transfer}, and can be used to
//      * e.g. implement automatic token fees, slashing mechanisms, etc.
//      *
//      * Emits a {Transfer} event.
//      *
//      * Requirements:
//      *
//      * - `sender` cannot be the zero address.
//      * - `recipient` cannot be the zero address.
//      * - `sender` must have a balance of at least `amount`.
//      */
//     function _transfer(address sender, address recipient, uint256 amount) internal virtual {
//         require(sender != address(0), "ERC20: transfer from the zero address");
//         require(recipient != address(0), "ERC20: transfer to the zero address");

//         _beforeTokenTransfer(sender, recipient, amount);

//         uint256 senderBalance = _balances[sender];
//         require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
//         _balances[sender] = senderBalance - amount;
//         _balances[recipient] += amount;

//         emit Transfer(sender, recipient, amount);
//     }

//     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
//      * the total supply.
//      *
//      * Emits a {Transfer} event with `from` set to the zero address.
//      *
//      * Requirements:
//      *
//      * - `to` cannot be the zero address.
//      */
//     function _mint(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: mint to the zero address");

//         _beforeTokenTransfer(address(0), account, amount);

//         _totalSupply += amount;
//         _balances[account] += amount;
//         emit Transfer(address(0), account, amount);
//     }

//     /**
//      * @dev Destroys `amount` tokens from `account`, reducing the
//      * total supply.
//      *
//      * Emits a {Transfer} event with `to` set to the zero address.
//      *
//      * Requirements:
//      *
//      * - `account` cannot be the zero address.
//      * - `account` must have at least `amount` tokens.
//      */
//     function _burn(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: burn from the zero address");

//         _beforeTokenTransfer(account, address(0), amount);

//         uint256 accountBalance = _balances[account];
//         require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
//         _balances[account] = accountBalance - amount;
//         _totalSupply -= amount;

//         emit Transfer(account, address(0), amount);
//     }

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
//      *
//      * This internal function is equivalent to `approve`, and can be used to
//      * e.g. set automatic allowances for certain subsystems, etc.
//      *
//      * Emits an {Approval} event.
//      *
//      * Requirements:
//      *
//      * - `owner` cannot be the zero address.
//      * - `spender` cannot be the zero address.
//      */
//     function _approve(address owner, address spender, uint256 amount) internal virtual {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//     /**
//      * @dev Hook that is called before any transfer of tokens. This includes
//      * minting and burning.
//      *
//      * Calling conditions:
//      *
//      * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * will be to transferred to `to`.
//      * - when `from` is zero, `amount` tokens will be minted for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
// }

// // File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// pragma solidity ^0.8.0;



// /**
//  * @dev Extension of {ERC20} that allows token holders to destroy both their own
//  * tokens and those that they have an allowance for, in a way that can be
//  * recognized off-chain (via event analysis).
//  */
// abstract contract ERC20Burnable is Context, ERC20 {
//     /**
//      * @dev Destroys `amount` tokens from the caller.
//      *
//      * See {ERC20-_burn}.
//      */
//     function burn(uint256 amount) public virtual {
//         _burn(_msgSender(), amount);
//     }

//     /**
//      * @dev Destroys `amount` tokens from `account`, deducting from the caller's
//      * allowance.
//      *
//      * See {ERC20-_burn} and {ERC20-allowance}.
//      *
//      * Requirements:
//      *
//      * - the caller must have allowance for ``accounts``'s tokens of at least
//      * `amount`.
//      */
//     function burnFrom(address account, uint256 amount) public virtual {
//         uint256 currentAllowance = allowance(account, _msgSender());
//         require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
//         _approve(account, _msgSender(), currentAllowance - amount);
//         _burn(account, amount);
//     }
// }

// // File: ERC20_Token_Sample.sol

// // contracts/GLDToken.sol

// pragma solidity ^0.8.0;




// contract ERC20_Token_Sample is ERC20, ERC20Burnable {
//     constructor() ERC20("ERC20 Token Sample1", "Sample 1") {
//         _mint(msg.sender, 100000000000 * 10**18 );
//     } 

//     function mint(uint amount) public {
//         _mint(msg.sender, amount );
//     }
// }

// /**
//  *Submitted for verification at Etherscan.io on 2020-05-04
// */

// pragma solidity =0.5.16;

// interface IUniswapV2Factory {
//     event PairCreated(address indexed token0, address indexed token1, address pair, uint);

//     function feeTo() external view returns (address);
//     function feeToSetter() external view returns (address);

//     function getPair(address tokenA, address tokenB) external view returns (address pair);
//     function allPairs(uint) external view returns (address pair);
//     function allPairsLength() external view returns (uint);

//     function createPair(address tokenA, address tokenB) external returns (address pair);

//     function setFeeTo(address) external;
//     function setFeeToSetter(address) external;
// }

// interface IUniswapV2Pair {
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     function name() external pure returns (string memory);
//     function symbol() external pure returns (string memory);
//     function decimals() external pure returns (uint8);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address owner) external view returns (uint);
//     function allowance(address owner, address spender) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);
//     function transfer(address to, uint value) external returns (bool);
//     function transferFrom(address from, address to, uint value) external returns (bool);

//     function DOMAIN_SEPARATOR() external view returns (bytes32);
//     function PERMIT_TYPEHASH() external pure returns (bytes32);
//     function nonces(address owner) external view returns (uint);

//     function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

//     event Mint(address indexed sender, uint amount0, uint amount1);
//     event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
//     event Swap(
//         address indexed sender,
//         uint amount0In,
//         uint amount1In,
//         uint amount0Out,
//         uint amount1Out,
//         address indexed to
//     );
//     event Sync(uint112 reserve0, uint112 reserve1);

//     function MINIMUM_LIQUIDITY() external pure returns (uint);
//     function factory() external view returns (address);
//     function token0() external view returns (address);
//     function token1() external view returns (address);
//     function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
//     function price0CumulativeLast() external view returns (uint);
//     function price1CumulativeLast() external view returns (uint);
//     function kLast() external view returns (uint);

//     function mint(address to) external returns (uint liquidity);
//     function burn(address to) external returns (uint amount0, uint amount1);
//     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
//     function skim(address to) external;
//     function sync() external;

//     function initialize(address, address) external;
// }

// interface IUniswapV2ERC20 {
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     function name() external pure returns (string memory);
//     function symbol() external pure returns (string memory);
//     function decimals() external pure returns (uint8);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address owner) external view returns (uint);
//     function allowance(address owner, address spender) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);
//     function transfer(address to, uint value) external returns (bool);
//     function transferFrom(address from, address to, uint value) external returns (bool);

//     function DOMAIN_SEPARATOR() external view returns (bytes32);
//     function PERMIT_TYPEHASH() external pure returns (bytes32);
//     function nonces(address owner) external view returns (uint);

//     function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
// }

// interface IERC20 {
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     function name() external view returns (string memory);
//     function symbol() external view returns (string memory);
//     function decimals() external view returns (uint8);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address owner) external view returns (uint);
//     function allowance(address owner, address spender) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);
//     function transfer(address to, uint value) external returns (bool);
//     function transferFrom(address from, address to, uint value) external returns (bool);
// }

// interface IUniswapV2Callee {
//     function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
// }

// contract UniswapV2ERC20 is IUniswapV2ERC20 {
//     using SafeMath for uint;

//     string public constant name = 'Uniswap V2';
//     string public constant symbol = 'UNI-V2';
//     uint8 public constant decimals = 18;
//     uint  public totalSupply;
//     mapping(address => uint) public balanceOf;
//     mapping(address => mapping(address => uint)) public allowance;

//     bytes32 public DOMAIN_SEPARATOR;
//     // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
//     bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
//     mapping(address => uint) public nonces;

//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     constructor() public {
//         uint chainId;
//         assembly {
//             chainId := chainid
//         }
//         DOMAIN_SEPARATOR = keccak256(
//             abi.encode(
//                 keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
//                 keccak256(bytes(name)),
//                 keccak256(bytes('1')),
//                 chainId,
//                 address(this)
//             )
//         );
//     }

//     function _mint(address to, uint value) internal {
//         totalSupply = totalSupply.add(value);
//         balanceOf[to] = balanceOf[to].add(value);
//         emit Transfer(address(0), to, value);
//     }

//     function _burn(address from, uint value) internal {
//         balanceOf[from] = balanceOf[from].sub(value);
//         totalSupply = totalSupply.sub(value);
//         emit Transfer(from, address(0), value);
//     }

//     function _approve(address owner, address spender, uint value) private {
//         allowance[owner][spender] = value;
//         emit Approval(owner, spender, value);
//     }

//     function _transfer(address from, address to, uint value) private {
//         balanceOf[from] = balanceOf[from].sub(value);
//         balanceOf[to] = balanceOf[to].add(value);
//         emit Transfer(from, to, value);
//     }

//     function approve(address spender, uint value) external returns (bool) {
//         _approve(msg.sender, spender, value);
//         return true;
//     }

//     function transfer(address to, uint value) external returns (bool) {
//         _transfer(msg.sender, to, value);
//         return true;
//     }

//     function transferFrom(address from, address to, uint value) external returns (bool) {
//         if (allowance[from][msg.sender] != uint(-1)) {
//             allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
//         }
//         _transfer(from, to, value);
//         return true;
//     }

//     function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
//         require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
//         bytes32 digest = keccak256(
//             abi.encodePacked(
//                 '\x19\x01',
//                 DOMAIN_SEPARATOR,
//                 keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
//             )
//         );
//         address recoveredAddress = ecrecover(digest, v, r, s);
//         require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
//         _approve(owner, spender, value);
//     }
// }

// contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
//     using SafeMath  for uint;
//     using UQ112x112 for uint224;

//     uint public constant MINIMUM_LIQUIDITY = 10**3;
//     bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

//     address public factory;
//     address public token0;
//     address public token1;

//     uint112 private reserve0;           // uses single storage slot, accessible via getReserves
//     uint112 private reserve1;           // uses single storage slot, accessible via getReserves
//     uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

//     uint public price0CumulativeLast;
//     uint public price1CumulativeLast;
//     uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

//     uint private unlocked = 1;
//     modifier lock() {
//         require(unlocked == 1, 'UniswapV2: LOCKED');
//         unlocked = 0;
//         _;
//         unlocked = 1;
//     }

//     function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
//         _reserve0 = reserve0;
//         _reserve1 = reserve1;
//         _blockTimestampLast = blockTimestampLast;
//     }

//     function _safeTransfer(address token, address to, uint value) private {
//         (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
//     }

//     event Mint(address indexed sender, uint amount0, uint amount1);
//     event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
//     event Swap(
//         address indexed sender,
//         uint amount0In,
//         uint amount1In,
//         uint amount0Out,
//         uint amount1Out,
//         address indexed to
//     );
//     event Sync(uint112 reserve0, uint112 reserve1);

//     constructor() public {
//         factory = msg.sender;
//     }

//     // called once by the factory at time of deployment
//     function initialize(address _token0, address _token1) external {
//         require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
//         token0 = _token0;
//         token1 = _token1;
//     }

//     // update reserves and, on the first call per block, price accumulators
//     function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
//         require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
//         uint32 blockTimestamp = uint32(block.timestamp % 2**32);
//         uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
//         if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
//             // * never overflows, and + overflow is desired
//             price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
//             price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
//         }
//         reserve0 = uint112(balance0);
//         reserve1 = uint112(balance1);
//         blockTimestampLast = blockTimestamp;
//         emit Sync(reserve0, reserve1);
//     }

//     // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
//     function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
//         address feeTo = IUniswapV2Factory(factory).feeTo();
//         feeOn = feeTo != address(0);
//         uint _kLast = kLast; // gas savings
//         if (feeOn) {
//             if (_kLast != 0) {
//                 uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
//                 uint rootKLast = Math.sqrt(_kLast);
//                 if (rootK > rootKLast) {
//                     uint numerator = totalSupply.mul(rootK.sub(rootKLast));
//                     uint denominator = rootK.mul(5).add(rootKLast);
//                     uint liquidity = numerator / denominator;
//                     if (liquidity > 0) _mint(feeTo, liquidity);
//                 }
//             }
//         } else if (_kLast != 0) {
//             kLast = 0;
//         }
//     }

//     // this low-level function should be called from a contract which performs important safety checks
//     function mint(address to) external lock returns (uint liquidity) {
//         (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
//         uint balance0 = IERC20(token0).balanceOf(address(this));
//         uint balance1 = IERC20(token1).balanceOf(address(this));
//         uint amount0 = balance0.sub(_reserve0);
//         uint amount1 = balance1.sub(_reserve1);

//         bool feeOn = _mintFee(_reserve0, _reserve1);
//         uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
//         if (_totalSupply == 0) {
//             liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
//            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
//         } else {
//             liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
//         }
//         require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
//         _mint(to, liquidity);

//         _update(balance0, balance1, _reserve0, _reserve1);
//         if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
//         emit Mint(msg.sender, amount0, amount1);
//     }

//     // this low-level function should be called from a contract which performs important safety checks
//     function burn(address to) external lock returns (uint amount0, uint amount1) {
//         (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
//         address _token0 = token0;                                // gas savings
//         address _token1 = token1;                                // gas savings
//         uint balance0 = IERC20(_token0).balanceOf(address(this));
//         uint balance1 = IERC20(_token1).balanceOf(address(this));
//         uint liquidity = balanceOf[address(this)];

//         bool feeOn = _mintFee(_reserve0, _reserve1);
//         uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
//         amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
//         amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
//         require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
//         _burn(address(this), liquidity);
//         _safeTransfer(_token0, to, amount0);
//         _safeTransfer(_token1, to, amount1);
//         balance0 = IERC20(_token0).balanceOf(address(this));
//         balance1 = IERC20(_token1).balanceOf(address(this));

//         _update(balance0, balance1, _reserve0, _reserve1);
//         if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
//         emit Burn(msg.sender, amount0, amount1, to);
//     }

//     // this low-level function should be called from a contract which performs important safety checks
//     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
//         require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
//         (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
//         require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

//         uint balance0;
//         uint balance1;
//         { // scope for _token{0,1}, avoids stack too deep errors
//         address _token0 = token0;
//         address _token1 = token1;
//         require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
//         if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
//         if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
//         if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
//         balance0 = IERC20(_token0).balanceOf(address(this));
//         balance1 = IERC20(_token1).balanceOf(address(this));
//         }
//         uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
//         uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
//         require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
//         { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
//         uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
//         uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
//         require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
//         }

//         _update(balance0, balance1, _reserve0, _reserve1);
//         emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
//     }

//     // force balances to match reserves
//     function skim(address to) external lock {
//         address _token0 = token0; // gas savings
//         address _token1 = token1; // gas savings
//         _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
//         _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
//     }

//     // force reserves to match balances
//     function sync() external lock {
//         _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
//     }
// }

// contract UniswapV2Factory is IUniswapV2Factory {
//     address public feeTo;
//     address public feeToSetter;

//     mapping(address => mapping(address => address)) public getPair;
//     address[] public allPairs;

//     event PairCreated(address indexed token0, address indexed token1, address pair, uint);

//     constructor(address _feeToSetter) public {
//         feeToSetter = _feeToSetter;
//     }

//     function allPairsLength() external view returns (uint) {
//         return allPairs.length;
//     }

//     function createPair(address tokenA, address tokenB) external returns (address pair) {
//         require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
//         (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
//         require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
//         require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
//         bytes memory bytecode = type(UniswapV2Pair).creationCode;
//         bytes32 salt = keccak256(abi.encodePacked(token0, token1));
//         assembly {
//             pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
//         }
//         IUniswapV2Pair(pair).initialize(token0, token1);
//         getPair[token0][token1] = pair;
//         getPair[token1][token0] = pair; // populate mapping in the reverse direction
//         allPairs.push(pair);
//         emit PairCreated(token0, token1, pair, allPairs.length);
//     }

//     function setFeeTo(address _feeTo) external {
//         require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
//         feeTo = _feeTo;
//     }

//     function setFeeToSetter(address _feeToSetter) external {
//         require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
//         feeToSetter = _feeToSetter;
//     }
// }

// // a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

// library SafeMath {
//     function add(uint x, uint y) internal pure returns (uint z) {
//         require((z = x + y) >= x, 'ds-math-add-overflow');
//     }

//     function sub(uint x, uint y) internal pure returns (uint z) {
//         require((z = x - y) <= x, 'ds-math-sub-underflow');
//     }

//     function mul(uint x, uint y) internal pure returns (uint z) {
//         require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
//     }
// }

// // a library for performing various math operations

// library Math {
//     function min(uint x, uint y) internal pure returns (uint z) {
//         z = x < y ? x : y;
//     }

//     // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
//     function sqrt(uint y) internal pure returns (uint z) {
//         if (y > 3) {
//             z = y;
//             uint x = y / 2 + 1;
//             while (x < z) {
//                 z = x;
//                 x = (y / x + x) / 2;
//             }
//         } else if (y != 0) {
//             z = 1;
//         }
//     }
// }

// // a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// // range: [0, 2**112 - 1]
// // resolution: 1 / 2**112

// library UQ112x112 {
//     uint224 constant Q112 = 2**112;

//     // encode a uint112 as a UQ112x112
//     function encode(uint112 y) internal pure returns (uint224 z) {
//         z = uint224(y) * Q112; // never overflows
//     }

//     // divide a UQ112x112 by a uint112, returning a UQ112x112
//     function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
//         z = x / uint224(y);
//     }
// }

/**
 *Submitted for verification at Etherscan.io on 2020-06-05
*/

pragma solidity =0.6.6;

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

interface IUniswapV2Router02 is IUniswapV2Router01 {
   
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// // File: @openzeppelin/contracts/utils/math/SafeMath.sol


// // OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// pragma solidity ^0.8.0;

// // CAUTION
// // This version of SafeMath should only be used with Solidity 0.8 or later,
// // because it relies on the compiler's built in overflow checks.

// /**
//  * @dev Wrappers over Solidity's arithmetic operations.
//  *
//  * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
//  * now has built in overflow checking.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         unchecked {
//             uint256 c = a + b;
//             if (c < a) return (false, 0);
//             return (true, c);
//         }
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         unchecked {
//             if (b > a) return (false, 0);
//             return (true, a - b);
//         }
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         unchecked {
//             // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//             // benefit is lost if 'b' is also tested.
//             // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//             if (a == 0) return (true, 0);
//             uint256 c = a * b;
//             if (c / a != b) return (false, 0);
//             return (true, c);
//         }
//     }

//     /**
//      * @dev Returns the division of two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         unchecked {
//             if (b == 0) return (false, 0);
//             return (true, a / b);
//         }
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         unchecked {
//             if (b == 0) return (false, 0);
//             return (true, a % b);
//         }
//     }

//     /**
//      * @dev Returns the addition of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `+` operator.
//      *
//      * Requirements:
//      *
//      * - Addition cannot overflow.
//      */
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a + b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a - b;
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `*` operator.
//      *
//      * Requirements:
//      *
//      * - Multiplication cannot overflow.
//      */
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a * b;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator.
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a % b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {trySub}.
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(
//         uint256 a,
//         uint256 b,
//         string memory errorMessage
//     ) internal pure returns (uint256) {
//         unchecked {
//             require(b <= a, errorMessage);
//             return a - b;
//         }
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(
//         uint256 a,
//         uint256 b,
//         string memory errorMessage
//     ) internal pure returns (uint256) {
//         unchecked {
//             require(b > 0, errorMessage);
//             return a / b;
//         }
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting with custom message when dividing by zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryMod}.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(
//         uint256 a,
//         uint256 b,
//         string memory errorMessage
//     ) internal pure returns (uint256) {
//         unchecked {
//             require(b > 0, errorMessage);
//             return a % b;
//         }
//     }
// }

// // File: @openzeppelin/contracts/utils/Context.sol


// // OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

// /**
//  * @dev Provides information about the current execution context, including the
//  * sender of the transaction and its data. While these are generally available
//  * via msg.sender and msg.data, they should not be accessed in such a direct
//  * manner, since when dealing with meta-transactions the account sending and
//  * paying for execution may not be the actual sender (as far as an application
//  * is concerned).
//  *
//  * This contract is only required for intermediate, library-like contracts.
//  */
// abstract contract Context {
//     function _msgSender() internal view virtual returns (address) {
//         return msg.sender;
//     }

//     function _msgData() internal view virtual returns (bytes calldata) {
//         return msg.data;
//     }
// }

// // File: @openzeppelin/contracts/access/Ownable.sol


// // OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;


// /**
//  * @dev Contract module which provides a basic access control mechanism, where
//  * there is an account (an owner) that can be granted exclusive access to
//  * specific functions.
//  *
//  * By default, the owner account will be the one that deploys the contract. This
//  * can later be changed with {transferOwnership}.
//  *
//  * This module is used through inheritance. It will make available the modifier
//  * `onlyOwner`, which can be applied to your functions to restrict their use to
//  * the owner.
//  */
// abstract contract Ownable is Context {
//     address private _owner;

//     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//     /**
//      * @dev Initializes the contract setting the deployer as the initial owner.
//      */
//     constructor() {
//         _transferOwnership(_msgSender());
//     }

//     /**
//      * @dev Returns the address of the current owner.
//      */
//     function owner() public view virtual returns (address) {
//         return _owner;
//     }

//     /**
//      * @dev Throws if called by any account other than the owner.
//      */
//     modifier onlyOwner() {
//         require(owner() == _msgSender(), "Ownable: caller is not the owner");
//         _;
//     }

//     /**
//      * @dev Leaves the contract without owner. It will not be possible to call
//      * `onlyOwner` functions anymore. Can only be called by the current owner.
//      *
//      * NOTE: Renouncing ownership will leave the contract without an owner,
//      * thereby removing any functionality that is only available to the owner.
//      */
//     function renounceOwnership() public virtual onlyOwner {
//         _transferOwnership(address(0));
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Can only be called by the current owner.
//      */
//     function transferOwnership(address newOwner) public virtual onlyOwner {
//         require(newOwner != address(0), "Ownable: new owner is the zero address");
//         _transferOwnership(newOwner);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Internal function without access restriction.
//      */
//     function _transferOwnership(address newOwner) internal virtual {
//         address oldOwner = _owner;
//         _owner = newOwner;
//         emit OwnershipTransferred(oldOwner, newOwner);
//     }
// }

// // File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// // OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);

//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `to`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address to, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `from` to `to` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(
//         address from,
//         address to,
//         uint256 amount
//     ) external returns (bool);
// }

// // File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// // OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

// pragma solidity ^0.8.0;


// /**
//  * @dev Interface for the optional metadata functions from the ERC20 standard.
//  *
//  * _Available since v4.1._
//  */
// interface IERC20Metadata is IERC20 {
//     /**
//      * @dev Returns the name of the token.
//      */
//     function name() external view returns (string memory);

//     /**
//      * @dev Returns the symbol of the token.
//      */
//     function symbol() external view returns (string memory);

//     /**
//      * @dev Returns the decimals places of the token.
//      */
//     function decimals() external view returns (uint8);
// }

// // File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// // OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

// pragma solidity ^0.8.0;




// /**
//  * @dev Implementation of the {IERC20} interface.
//  *
//  * This implementation is agnostic to the way tokens are created. This means
//  * that a supply mechanism has to be added in a derived contract using {_mint}.
//  * For a generic mechanism see {ERC20PresetMinterPauser}.
//  *
//  * TIP: For a detailed writeup see our guide
//  * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
//  * to implement supply mechanisms].
//  *
//  * We have followed general OpenZeppelin Contracts guidelines: functions revert
//  * instead returning `false` on failure. This behavior is nonetheless
//  * conventional and does not conflict with the expectations of ERC20
//  * applications.
//  *
//  * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
//  * This allows applications to reconstruct the allowance for all accounts just
//  * by listening to said events. Other implementations of the EIP may not emit
//  * these events, as it isn't required by the specification.
//  *
//  * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
//  * functions have been added to mitigate the well-known issues around setting
//  * allowances. See {IERC20-approve}.
//  */
// contract ERC20 is Context, IERC20, IERC20Metadata {
//     mapping(address => uint256) private _balances;

//     mapping(address => mapping(address => uint256)) private _allowances;

//     uint256 private _totalSupply;

//     string private _name;
//     string private _symbol;

//     /**
//      * @dev Sets the values for {name} and {symbol}.
//      *
//      * The default value of {decimals} is 18. To select a different value for
//      * {decimals} you should overload it.
//      *
//      * All two of these values are immutable: they can only be set once during
//      * construction.
//      */
//     constructor(string memory name_, string memory symbol_) {
//         _name = name_;
//         _symbol = symbol_;
//     }

//     /**
//      * @dev Returns the name of the token.
//      */
//     function name() public view virtual override returns (string memory) {
//         return _name;
//     }

//     /**
//      * @dev Returns the symbol of the token, usually a shorter version of the
//      * name.
//      */
//     function symbol() public view virtual override returns (string memory) {
//         return _symbol;
//     }

//     /**
//      * @dev Returns the number of decimals used to get its user representation.
//      * For example, if `decimals` equals `2`, a balance of `505` tokens should
//      * be displayed to a user as `5.05` (`505 / 10 ** 2`).
//      *
//      * Tokens usually opt for a value of 18, imitating the relationship between
//      * Ether and Wei. This is the value {ERC20} uses, unless this function is
//      * overridden;
//      *
//      * NOTE: This information is only used for _display_ purposes: it in
//      * no way affects any of the arithmetic of the contract, including
//      * {IERC20-balanceOf} and {IERC20-transfer}.
//      */
//     function decimals() public view virtual override returns (uint8) {
//         return 18;
//     }

//     /**
//      * @dev See {IERC20-totalSupply}.
//      */
//     function totalSupply() public view virtual override returns (uint256) {
//         return _totalSupply;
//     }

//     /**
//      * @dev See {IERC20-balanceOf}.
//      */
//     function balanceOf(address account) public view virtual override returns (uint256) {
//         return _balances[account];
//     }

//     /**
//      * @dev See {IERC20-transfer}.
//      *
//      * Requirements:
//      *
//      * - `to` cannot be the zero address.
//      * - the caller must have a balance of at least `amount`.
//      */
//     function transfer(address to, uint256 amount) public virtual override returns (bool) {
//         address owner = _msgSender();
//         _transfer(owner, to, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-allowance}.
//      */
//     function allowance(address owner, address spender) public view virtual override returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     /**
//      * @dev See {IERC20-approve}.
//      *
//      * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
//      * `transferFrom`. This is semantically equivalent to an infinite approval.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function approve(address spender, uint256 amount) public virtual override returns (bool) {
//         address owner = _msgSender();
//         _approve(owner, spender, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-transferFrom}.
//      *
//      * Emits an {Approval} event indicating the updated allowance. This is not
//      * required by the EIP. See the note at the beginning of {ERC20}.
//      *
//      * NOTE: Does not update the allowance if the current allowance
//      * is the maximum `uint256`.
//      *
//      * Requirements:
//      *
//      * - `from` and `to` cannot be the zero address.
//      * - `from` must have a balance of at least `amount`.
//      * - the caller must have allowance for ``from``'s tokens of at least
//      * `amount`.
//      */
//     function transferFrom(
//         address from,
//         address to,
//         uint256 amount
//     ) public virtual override returns (bool) {
//         address spender = _msgSender();
//         _spendAllowance(from, spender, amount);
//         _transfer(from, to, amount);
//         return true;
//     }

//     /**
//      * @dev Atomically increases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
//         address owner = _msgSender();
//         _approve(owner, spender, allowance(owner, spender) + addedValue);
//         return true;
//     }

//     /**
//      * @dev Atomically decreases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      * - `spender` must have allowance for the caller of at least
//      * `subtractedValue`.
//      */
//     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
//         address owner = _msgSender();
//         uint256 currentAllowance = allowance(owner, spender);
//         require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
//         unchecked {
//             _approve(owner, spender, currentAllowance - subtractedValue);
//         }

//         return true;
//     }

//     /**
//      * @dev Moves `amount` of tokens from `sender` to `recipient`.
//      *
//      * This internal function is equivalent to {transfer}, and can be used to
//      * e.g. implement automatic token fees, slashing mechanisms, etc.
//      *
//      * Emits a {Transfer} event.
//      *
//      * Requirements:
//      *
//      * - `from` cannot be the zero address.
//      * - `to` cannot be the zero address.
//      * - `from` must have a balance of at least `amount`.
//      */
//     function _transfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal virtual {
//         require(from != address(0), "ERC20: transfer from the zero address");
//         require(to != address(0), "ERC20: transfer to the zero address");

//         _beforeTokenTransfer(from, to, amount);

//         uint256 fromBalance = _balances[from];
//         require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
//         unchecked {
//             _balances[from] = fromBalance - amount;
//         }
//         _balances[to] += amount;

//         emit Transfer(from, to, amount);

//         _afterTokenTransfer(from, to, amount);
//     }

//     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
//      * the total supply.
//      *
//      * Emits a {Transfer} event with `from` set to the zero address.
//      *
//      * Requirements:
//      *
//      * - `account` cannot be the zero address.
//      */
//     function _mint(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: mint to the zero address");

//         _beforeTokenTransfer(address(0), account, amount);

//         _totalSupply += amount;
//         _balances[account] += amount;
//         emit Transfer(address(0), account, amount);

//         _afterTokenTransfer(address(0), account, amount);
//     }

//     /**
//      * @dev Destroys `amount` tokens from `account`, reducing the
//      * total supply.
//      *
//      * Emits a {Transfer} event with `to` set to the zero address.
//      *
//      * Requirements:
//      *
//      * - `account` cannot be the zero address.
//      * - `account` must have at least `amount` tokens.
//      */
//     function _burn(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: burn from the zero address");

//         _beforeTokenTransfer(account, address(0), amount);

//         uint256 accountBalance = _balances[account];
//         require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
//         unchecked {
//             _balances[account] = accountBalance - amount;
//         }
//         _totalSupply -= amount;

//         emit Transfer(account, address(0), amount);

//         _afterTokenTransfer(account, address(0), amount);
//     }

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
//      *
//      * This internal function is equivalent to `approve`, and can be used to
//      * e.g. set automatic allowances for certain subsystems, etc.
//      *
//      * Emits an {Approval} event.
//      *
//      * Requirements:
//      *
//      * - `owner` cannot be the zero address.
//      * - `spender` cannot be the zero address.
//      */
//     function _approve(
//         address owner,
//         address spender,
//         uint256 amount
//     ) internal virtual {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//     /**
//      * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
//      *
//      * Does not update the allowance amount in case of infinite allowance.
//      * Revert if not enough allowance is available.
//      *
//      * Might emit an {Approval} event.
//      */
//     function _spendAllowance(
//         address owner,
//         address spender,
//         uint256 amount
//     ) internal virtual {
//         uint256 currentAllowance = allowance(owner, spender);
//         if (currentAllowance != type(uint256).max) {
//             require(currentAllowance >= amount, "ERC20: insufficient allowance");
//             unchecked {
//                 _approve(owner, spender, currentAllowance - amount);
//             }
//         }
//     }

//     /**
//      * @dev Hook that is called before any transfer of tokens. This includes
//      * minting and burning.
//      *
//      * Calling conditions:
//      *
//      * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * will be transferred to `to`.
//      * - when `from` is zero, `amount` tokens will be minted for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _beforeTokenTransfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal virtual {}

//     /**
//      * @dev Hook that is called after any transfer of tokens. This includes
//      * minting and burning.
//      *
//      * Calling conditions:
//      *
//      * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * has been transferred to `to`.
//      * - when `from` is zero, `amount` tokens have been minted for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _afterTokenTransfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal virtual {}
// }

// // File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// // OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

// pragma solidity ^0.8.0;

// /**
//  * @dev Contract module that helps prevent reentrant calls to a function.
//  *
//  * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
//  * available, which can be applied to functions to make sure there are no nested
//  * (reentrant) calls to them.
//  *
//  * Note that because there is a single `nonReentrant` guard, functions marked as
//  * `nonReentrant` may not call one another. This can be worked around by making
//  * those functions `private`, and then adding `external` `nonReentrant` entry
//  * points to them.
//  *
//  * TIP: If you would like to learn more about reentrancy and alternative ways
//  * to protect against it, check out our blog post
//  * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
//  */
// abstract contract ReentrancyGuard {
//     // Booleans are more expensive than uint256 or any type that takes up a full
//     // word because each write operation emits an extra SLOAD to first read the
//     // slot's contents, replace the bits taken up by the boolean, and then write
//     // back. This is the compiler's defense against contract upgrades and
//     // pointer aliasing, and it cannot be disabled.

//     // The values being non-zero value makes deployment a bit more expensive,
//     // but in exchange the refund on every call to nonReentrant will be lower in
//     // amount. Since refunds are capped to a percentage of the total
//     // transaction's gas, it is best to keep them low in cases like this one, to
//     // increase the likelihood of the full refund coming into effect.
//     uint256 private constant _NOT_ENTERED = 1;
//     uint256 private constant _ENTERED = 2;

//     uint256 private _status;

//     constructor() {
//         _status = _NOT_ENTERED;
//     }

//     /**
//      * @dev Prevents a contract from calling itself, directly or indirectly.
//      * Calling a `nonReentrant` function from another `nonReentrant`
//      * function is not supported. It is possible to prevent this from happening
//      * by making the `nonReentrant` function external, and making it call a
//      * `private` function that does the actual work.
//      */
//     modifier nonReentrant() {
//         // On the first call to nonReentrant, _notEntered will be true
//         require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

//         // Any calls to nonReentrant after this point will fail
//         _status = _ENTERED;

//         _;

//         // By storing the original value once again, a refund is triggered (see
//         // https://eips.ethereum.org/EIPS/eip-2200)
//         _status = _NOT_ENTERED;
//     }
// }

// // File: contracts/ERC20.sol

// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;





// interface IFactory {
//     function createPair(address tokenA, address tokenB)
//         external
//         returns (address pair);

//     function getPair(address tokenA, address tokenB)
//         external
//         view
//         returns (address pair);
// }


// interface IRouter {
//     function factory() external pure returns (address);

//     function WETH() external pure returns (address);

//     function getAmountsOut(uint256 amountIn, address[] calldata path)
//         external
//         view
//         returns (uint256[] memory amounts);

//     function addLiquidityETH(
//         address token,
//         uint256 amountTokenDesired,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline
//     )
//         external
//         payable
//         returns (
//             uint256 amountToken,
//             uint256 amountETH,
//             uint256 liquidity
//         );

//     function swapExactTokensForETHSupportingFeeOnTransferTokens(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external;
// }



// contract WEXIBA is  ERC20 , Ownable { 

//     using SafeMath for uint256;
//     address public  adminWallet;
//     uint256 public burnPercent = 25;
//     uint256 public dailyLimit = 1000 * (10**18);
//     uint256 public SellingLimit = 100 * (10**18);
//     uint256 public buyingLimit = 100 * (10**18);
//     uint256 public lastDailyLimitUpdated;
//     uint256 public dailySelling = 0;


//     mapping(address=>bool)  whitelist;

//     struct User {
//         address user;
//         uint256 dailyBuying;
//         uint256 dailySelling;
//         uint256 lastUpdated;
//     }

//     mapping(address => User) Users;

//     IRouter public pancakeRouter;
//     address public pancakePair;
  


//     constructor(uint256 initialSupply) ERC20("WEXIBA", "WXB") { 
//         _mint(_msgSender(), initialSupply); 
//         lastDailyLimitUpdated = block.timestamp;
//         adminWallet = _msgSender(); 

//         pancakeRouter = IRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

//         pancakePair = IFactory(pancakeRouter.factory()).createPair(
//             address(this),
//             pancakeRouter.WETH()
//         );
//     }  

//     modifier isPanCakeSwap(address sender, address recipient,uint256 amount){

//           if(lastDailyLimitUpdated + 24 * 1 hours < block.timestamp){
//                 dailySelling = 0;
//             }


//          if (sender == pancakePair){
//              User storage user =  Users[sender];
//              if(user.lastUpdated + 24 * 1 hours < block.timestamp){
//                  user.dailySelling = 0;
//                  user.dailyBuying = 0;
//                  user.lastUpdated = block.timestamp;
//              }
//             require(user.dailyBuying + amount <=  buyingLimit,"Daily Selling maximum limit reached");
//             user.dailyBuying += amount;
//             //buying of token
//             //giving bnb and taking token
//          }

//          if(recipient == pancakePair){
//            User storage user =  Users[recipient];
//              if(user.lastUpdated + 24 * 1 hours < block.timestamp){
//                  user.dailySelling = 0;
//                  user.dailyBuying = 0;
//                  user.lastUpdated = block.timestamp;
//              }
//             require(dailySelling+amount<dailyLimit,"Daily Selling limit reached");
//             require(user.dailySelling + amount <= SellingLimit,"maximum selling limit reached");
//             user.dailySelling += amount;
//             dailySelling += amount;
//              //selling of token
//              //giving token and taking bnb
//          }
//          _;
//     }

//    function burnToken(address _from , uint256 _amount) internal returns(uint256){
//         if(!whitelist[_from]){
//             uint256 _burnAmount =  _amount.mul(burnPercent).div(1000);
//             _burn(_from,_burnAmount);
//             return _burnAmount;
//         }
//         return 0;
//     }



//     receive() external payable {} 

//     function transferFrom(
//         address from,
//         address to,
//         uint256 amount
//     ) public virtual  override isPanCakeSwap(from,to,amount) returns (bool) { 
//         address spender = _msgSender();
//         _spendAllowance(from, spender, amount);
//         uint256 burntToken = burnToken(from, amount);
//         _transfer(from, to, amount-(burntToken));
//         return true;
//     }

//     function transfer(address to, uint256 amount) public virtual override  isPanCakeSwap(msg.sender,to,amount) returns (bool) {
//         address owner = _msgSender();
//         uint256 burntToken = burnToken(owner, amount);
//         _transfer(owner, to, amount-(burntToken));
//         return true;
//     }

   

//      function setRouterAddress(address newRouter) external  onlyOwner {
//         require(address(pancakeRouter) != newRouter, "Router already set");
//         //give the option to change the router down the line
//         IRouter _newRouter = IRouter(newRouter);
//         address get_pair = IFactory(_newRouter.factory()).getPair(
//             address(this),
//             _newRouter.WETH()
//         );
//         //checks if pair already exists
//         if (get_pair == address(0)) {
//             pancakePair = IFactory(_newRouter.factory()).createPair(
//                 address(this),
//                 _newRouter.WETH()
//             );
//         } else {
//             pancakePair = get_pair;
//         }
//         pancakeRouter = _newRouter;
        
//     }

//     function whitelistAddress(address _address , bool _value) external onlyOwner {
//         whitelist[_address] = _value  ; 
//     }  


//     function setDailyLimit(uint256 _amount) public onlyOwner{
//         dailyLimit = _amount;
//     }


//     function setSellingLimit(uint256 _amount) public onlyOwner{
//         SellingLimit = _amount;
//     }

//     function setBuyingLimit(uint256 _amount) public onlyOwner{
//         buyingLimit = _amount;
//     }

//      function setBurnPercent(uint256 _burnPercent) external onlyOwner {
//         burnPercent = _burnPercent; 
//     } 
 
//     function rescueBNBFromContract() external onlyOwner {
//         address payable _owner = payable(msg.sender);
//         _owner.transfer(address(this).balance);
//     }

//     function rescueBEPTokenFromContract() external onlyOwner {
//         IERC20 ERC20Token = IERC20(address(this));
//         address payable _owner = payable(msg.sender);
//         ERC20Token.transfer(_owner, ERC20Token.balanceOf(address(this))) ;
//     }

//     function getUser(address _address) view public returns(address,uint256,uint256,uint256){
//         User memory user = Users[_address];
//         return(user.user,user.dailyBuying,user.dailySelling,user.lastUpdated);
//     }

// }