/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

contract CTF {


    enum Challenge { one, two, three, four, five, six, bonus }

    //Fields


    bool lock = false;

    mapping(address=>mapping(Challenge=>bool)) progress;

    address immutable here = address(this);
    address hackerOneToken;
    address hackerOneToken2;
    address owner;

    address secret;

    //Events

    event Solved(address indexed _from, Challenge challenge);

    // Modifiers

    modifier LOCK(){
        require(!lock,"reentrancy");
        lock = true;
        _;
        lock = false;
    }

    modifier notCompleted(Challenge challenge){
        require(!progress[msg.sender][challenge],"you already completed this challenge");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"not owner");
        _;
    }

    //Constructor

    constructor(){
        HackerOneToken token1 = new HackerOneToken();
        HackerOneToken2 token2 = new HackerOneToken2();

        hackerOneToken = address(token1);
        hackerOneToken2 = address(token2);

        secret = address(uint160(block.timestamp));

        owner = msg.sender;
    }

    //Getters

    function getBalance(address to) public view returns(uint256,uint256) {
        return (IERC20H1(hackerOneToken).balanceOf(to),IERC20H1(hackerOneToken2).balanceOf(to));
    }

    function getSecret() onlyOwner public view returns(address) {
        return secret;
    }

    function getTokenAddresses() public view returns(address,address) {
        return (hackerOneToken,hackerOneToken2);
    }

    function getProgress(address to, Challenge challenge) public view returns(bool){
        return progress[to][challenge];
    }

    // Internals

    function _upgradeProgress(Challenge challenge) internal {
        progress[msg.sender][challenge] = true;

        emit Solved(msg.sender, challenge);
    }

    function someCheck(bytes memory data, address _address)
        internal
        pure
        returns (bool)
    {
        if (data.length < (36 + 32)) {
            return false;
        }
        uint256 value;
        assembly {
            value := mload(add(data, 36))
        }
        return value == uint160(_address);
    }

    // Challenges


    /*
      This challenge is a swap simulator. Sometimes, it's useful to exchange tokens
      and swap functions are created exactly for that. Example: You should be able to swap 100 of token A for 100 of token B 
      However, sometimes decimals differ :)
    
      Try to gain the "swap" amount without paying anything to the contract.
    */

    function challengeOne(uint256 swap) public LOCK notCompleted(Challenge.one){
        require(swap > 1e10,"too few money");
        require(swap < 1e20, "too much money");

        uint256 balanceOfOneHackerBefore = IERC20(hackerOneToken).balanceOf(msg.sender);
        uint256 balanceOfTwoHackerBefore = IERC20(hackerOneToken2).balanceOf(msg.sender);

        require(IERC20(hackerOneToken).transfer(msg.sender,swap));
        require(IERC20(hackerOneToken2).transferFrom(msg.sender,address(this),swap/1e12));

        uint256 balanceOfOneHackerAfter = IERC20(hackerOneToken).balanceOf(msg.sender);
        uint256 balanceOfTwoHackerAfter = IERC20(hackerOneToken2).balanceOf(msg.sender);

        require(balanceOfOneHackerAfter > balanceOfOneHackerBefore,"not solved, retry");
        require(balanceOfTwoHackerAfter == balanceOfTwoHackerBefore,"not solved, retry");

        _upgradeProgress(Challenge.one);
    }


    /*
      This challenge is another swap simulator. You give something and you take another amount
      but this time you'll need to pay some fees. This time, the transfer function is very secure
      and there is no way that it will fail, the logic is quite solid.
    
      However, since nobody likes paying fees, we want to take everything and give nothing.
    */
    function challengeTwo(uint256 take, uint256 give) public LOCK notCompleted(Challenge.two){
        require(give == take + (take*25/1000), "not returning enough fees");
        require(take > 1e10, "too few money");
        require(take < 1e20, "too much money");


        uint256 balanceOfOneHackerBefore = IERC20(hackerOneToken).balanceOf(msg.sender);
        uint256 balanceOfTwoHackerBefore = IERC20(hackerOneToken2).balanceOf(msg.sender);


        IERC20H1(hackerOneToken).verySafeTransfer(msg.sender,take);
        IERC20H1(hackerOneToken2).verySafeTransferFrom(msg.sender,address(this),give);

        uint256 balanceOfOneHackerAfter = IERC20(hackerOneToken).balanceOf(msg.sender);
        uint256 balanceOfTwoHackerAfter = IERC20(hackerOneToken2).balanceOf(msg.sender);

        require(balanceOfOneHackerAfter > balanceOfOneHackerBefore,"not solved, retry");
        require(balanceOfTwoHackerAfter == balanceOfTwoHackerBefore,"not solved, retry");

        _upgradeProgress(Challenge.two);
    }

    /*
      This is a (almost) real swap function, its name is UniswapV2. Some modifications were made so that it's more secure.
      With amount*Out parameters we are taking some funds from the pool and with payDebt* parameters we are paying back our debt with some fees.

      The last "require" will make sure that the amount taken from the pool will be always less than the one given by the user.
      Therefore, there will be no loss on the pool side. Unless the code is buggy, but I swear that this is not.
    */
    function challengeThree(uint256 amount0Out, uint amount1Out, uint256 payDebt0, uint256 payDebt1) public LOCK notCompleted(Challenge.three) {
        require(amount0Out > 0 || amount1Out > 0, 'please, take something');

        uint deltaDebt = ((payDebt0+payDebt1)*1e4)+((amount0Out + amount1Out)*1e4)*25/1e4;
        uint deltaOut = (amount0Out + amount1Out)*1e4;

        require( deltaDebt < deltaOut, 'you are paying more debt than you should');
        uint112 _reserve0 = 10;
        uint112 _reserve1 = 10;
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'not enough liquidity');

        uint balance0 = _reserve0;
        uint balance1 = _reserve1;
        
        if (amount0Out > 0) {
            balance0 = balance0 - amount0Out;
            balance1 = balance1 + payDebt0;
        }

        if (amount1Out > 0) {
            balance1 = balance1 - amount1Out;
            balance0 = balance0 + payDebt0;
        }

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, 'you did not pay your debt back!');
        
        {
        uint balance0Adjusted = balance0 * 1000 - (amount0In * 25);
        uint balance1Adjusted = balance1 * 1000 - (amount1In * 25);
        require(balance0Adjusted * balance1Adjusted >= _reserve0 * _reserve1 * (1000**2), 'insufficient payback');
        }

        _upgradeProgress(Challenge.three);
    }

    /*
      In this challenge, we are doing a "call" to an arbitrary target. Since we don't trust you, we want to make sure that you do the right function.
      We are pretty confident that "approve" is not an insecure function to call on a random target.

      Try to get some allowance.
    */
    function challengeFour(address target, address to, uint256 take) public LOCK notCompleted(Challenge.four) {
        require(to != address(this),"not here");
        require(take <= 10,"too much money");

        bytes memory input = abi.encodeWithSignature("approve(address,uint256)",to,take);

        (bool success,) = target.call(input);

        require(success,"something went wrong");

        require(IERC20H1(hackerOneToken).allowance(address(this),to) == take,"not solved, retry");

        _upgradeProgress(Challenge.four);
    }

    /*
      In this function, we built an unbreakable function to validate the sender. We wanted to do it in a fancy way, using bytes.

      Sometimes bytes are complex to predict if you don't know how to manipulate them, might this be the case? 
    */
    function challengeFive(bytes calldata data) public LOCK notCompleted(Challenge.five){
        require(someCheck(data, msg.sender),"not correct");

        _upgradeProgress(Challenge.five);
    }

    function callMe(address sender) external {
        require(tx.origin == msg.sender,"don't call it from another contract");
        require(sender == msg.sender,"show yourself!");
    }

    /*
      With this challenge, we want to make a delegatecall to this address, because simply typing the function is boring.
      The function "callMe" should not be called by another contract but only by a user and this contract itself.
      
    */
    function challengeSix(bytes calldata data) public LOCK notCompleted(Challenge.six) {
        bytes4 selector;

        assembly {
            selector := calldataload(data.offset)
        }

        require(selector == 0xb27b8804,"you are calling the wrong function");

        (bool success,) = address(this).delegatecall(data);

        require(success,"something went wrong");

        _upgradeProgress(Challenge.six);
    }

    function challengeBonus(address _secret) public LOCK notCompleted(Challenge.bonus) {
        require(_secret == secret,"wrong secret");

        secret = address(uint160(msg.sender)+uint160(block.timestamp));

        _upgradeProgress(Challenge.bonus);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
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

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/CTF.sol


pragma solidity ^0.8.0;


///import "hardhat/console.sol";

contract HackerOneToken is ERC20 {

    // Decimals are set to 18 by default in `ERC20`
    constructor() ERC20("HackerOneToken", "HKT") {
        _mint(msg.sender, type(uint256).max);
    }

    function verySafeTransferFrom(address from, address to, uint256 amount) external returns(bool){
        if(allowance(from,msg.sender) >= amount || from == msg.sender){
            transferFrom(from,to,amount);
            return true;
        }
        return false;
    }

    function verySafeTransfer(address to, uint256 amount) external {
        transfer(to,amount);
    }
}

contract HackerOneToken2 is ERC20 {
    constructor() ERC20("HackerOneToken2", "HKT2") {
        _mint(msg.sender, type(uint256).max);
    }

    function verySafeTransferFrom(address from, address to, uint256 amount) external returns(bool){
        if(allowance(from,msg.sender) >= amount || from == msg.sender){
            transferFrom(from,to,amount);
            return true;
        }
        return false;
    }

    function verySafeTransfer(address to, uint256 amount) external {
        transfer(to,amount);
    }
}

interface IERC20H1 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address recipient, uint256 amount) external;

    function verySafeTransfer(address recipient, uint256 amount) external;

    function verySafeTransferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint8);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}