//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "ERC20.sol";
import "TRSYERC20.sol";
import "TokenPool.sol";
import "IRegistry.sol";
import "ITokenPool.sol";
import "Registry.sol";
import "IERC20.sol";



contract Treasury {
// State Variables
TRSYERC20 public immutable TRSY;
mapping (address => uint256) public timestamp;
mapping (address => bool) public whitelistedUsers;
mapping (address => bool) public whitelistedTokens;
address public owner;
address public registry;
uint256 constant PRECISION = 1e6;
uint public endTime;
address[] public rewardees;
mapping (address => bool) public isRewardee;

//Errors
error Error_Unauthorized();
error InsufficientBalance(uint256 available, uint256 required);

//enum
enum INCENTIVE{
        OPEN,
        CLOSED
    }

INCENTIVE public incentive = INCENTIVE.CLOSED;

//struct
struct Concentrations{
        uint256 currentConcentration;
        uint256 targetConcentration;
        uint256 newConcentration;
        uint256 aum;
    }
//modifier
modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Error_Unauthorized();
        }
        _;
    }

//events
event TokenDeposited(
        address indexed depositor,
        address token,
        uint256 amount,
        uint256 usdValueDeposited,
        uint256 sharesMinted
    );

event IncentiveOpen(
        uint256 endTime
    );

//constructor
constructor(
        address _trsy,
        address _registry
    ) {
    owner = msg.sender;
    registry = _registry;
    TRSY = TRSYERC20(_trsy);
    }
/**
@dev function that adds a user to the whitelist
 */
    function whitelistUser(address _user) public onlyOwner {
        whitelistedUsers[_user] =true;
    }

function getIncentiveStatus() public view returns (uint) {
     return uint(incentive);
}
/**
@dev function that adds a token to the whitelist
 */
    function whitelistToken(address _token) public onlyOwner {
         whitelistedTokens[_token] =true;
    }
/**
@dev function that makes a concentration struct by calculating the new, current, aum and target concentration 
@param pool - pool to make the struct for
@param amount - new amount to be added to pool
 */
    function makeConcentrationStruct(address pool, uint amount) public view returns (Concentrations memory){
        Concentrations memory concentration;
        concentration.currentConcentration = Registry(registry).getConcentration(pool);
        concentration.targetConcentration = Registry(registry).PoolToConcentration(pool);
        concentration.newConcentration = Registry(registry).getNewConcentration(pool, amount);
        concentration.aum = Registry(registry).getTotalAUMinUSD();
        return concentration;
    }
/**
@dev function that allows a whitelisted user to deposit a whitelisted token into the treasury in exchange for TRSY
@param _token - token to be deposited
@param _amount - amount of token to be deposited
 */
    function deposit(uint256 _amount, address _token) public {
        require(whitelistedUsers[msg.sender], "User is not whitelisted");
        require(whitelistedTokens[_token], "Token is not whitelisted");
        address pool = IRegistry(registry).tokenToPool(_token);
        uint256 USDValue = ITokenPool(pool).getDepositValue(_amount);
        require(USDValue > 1e18, "Amount must be greater than $1");
        Concentrations memory c = makeConcentrationStruct(pool,USDValue);
        if (c.aum>10000e18 && c.aum!=0){
        require(c.currentConcentration < (c.targetConcentration + 200000), "Concentration is too high"); //concentration is too high to deposit into pool
        require(c.newConcentration < (c.targetConcentration + 300000), "This will make the pool too concentrated");}

        uint taxamt = USDValue * 50000 / PRECISION; // tax user 5%
        //if users deposit makes concentration too high, tax them an addition 7.5% per dollar that is over the target concentration
        if ((c.newConcentration>c.targetConcentration) && (c.newConcentration >= c.currentConcentration)&&(c.aum>10000e18)){
           uint change =  c.targetConcentration < c.currentConcentration ? USDValue * 75000 / PRECISION : USDValue * (c.newConcentration - c.targetConcentration)/PRECISION * 75000 / PRECISION ;
           taxamt += change;
        } 
        uint256 trsyamt = getTRSYAmount(USDValue);
        uint256 trsytaxamt = getTRSYAmount(taxamt);
        bool success = IERC20(_token).transferFrom(msg.sender, pool, _amount);
        require(success);
        timestamp[msg.sender] = block.timestamp;
        TRSY.mint(msg.sender, (trsyamt-trsytaxamt)/1e18);
        TRSY.mint(address(this), trsytaxamt); //give this contract the tax 
        checkIncentive();
        emit TokenDeposited(msg.sender, _token, _amount, USDValue, trsyamt-trsytaxamt);
    }

    /**
    @dev function to get how much TRSY a user will get for a certain amount of USD
    @param _amount - amount of USD to be converted to TRSY
     */
    function getTRSYAmount(uint256 _amount) public view returns (uint256){
        uint256 tvl = IRegistry(registry).getTotalAUMinUSD();
        uint256 supply = TRSY.totalSupply();
        return tvl == 0 ? _amount : (_amount * supply) / tvl;
    }

/**
@dev function that allows a user to withdraw TRSY
@param _amount - amount of treasury to be withdrawn 
 */
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 trsyamt = TRSY.balanceOf(msg.sender);
        if (trsyamt < _amount) {
            revert InsufficientBalance({available: trsyamt, required: _amount});
        }
        uint tax = calculateTax(_amount, msg.sender); //withdrawal tax 
        uint postTax = _amount -tax; // actualy trsy that will be withdrawn 
        uint256 usdamt = getWithdrawAmount(postTax);
        (address[] memory pools, uint256[] memory amt) = IRegistry(registry).tokensToWithdraw(usdamt);
        TRSY.burn(msg.sender, _amount); //burn total amount from user
        TRSY.mint(address(this), tax); // mint this address the tax
        uint len = pools.length;
        for (uint i; i<len;){
            if( pools[i]!= address(0)){
            address pool = pools[i];
            uint256 amount = getTokenAmount(amt[i], pools[i]);
            ITokenPool(pool).withdrawToken(msg.sender,amount);
            }
            unchecked{++i;}
        }
    }
    /**
    @dev function  that calculates how much tax a user will pay on a withdrawal
    @param _amount - amount of TRSY to be withdrawn
    @param sender - user that is withdrawing
     */
    function calculateTax(uint256 _amount, address sender) public view returns (uint256){
        uint256 tax = _amount * 10000 / PRECISION; //all withdrawals taxed at 1%
        uint time = block.timestamp - timestamp[sender];
        int numdays = int(time / 86400);
        if(numdays <= 30){ //if user withdraws within 30 days of depositing, it is taxed more
             int calcTax =  ((200000 * numdays / 30) - 200000);
             int taxamt = 0 - calcTax;
             tax += _amount * uint(taxamt) / PRECISION;
        }
             return tax;
        }
        

    /**
    @dev calculate how many tokens a certain usd amount is worth 
    @param usdamt - dollar amount
    @param pool - tokenPool
     */
    function getTokenAmount(uint usdamt, address pool) public returns (uint256){
        uint price = ITokenPool(pool).getPrice();
        return ((usdamt * 10**18)/price);
    }

/**
@dev function to convert TRSY to usd
@param trsyamt - trsy amount 
 */
    function getWithdrawAmount(uint256 trsyamt) public view returns(uint256) {
        uint256 trsy = (PRECISION * trsyamt) / TRSY.totalSupply();
        uint256 tvl = IRegistry(registry).getTotalAUMinUSD();
        uint256 usdAmount = (tvl * trsy) / PRECISION;
        return usdAmount;
    }

    function checkIncentive() internal {
        if (Registry(registry).checkDeposit(50000)){
            incentivize();
         }
    }
    function ownerStartIncentive () public onlyOwner {
       incentivize();
    }

    function incentivize() internal {
        if (incentive == INCENTIVE.CLOSED){
            incentive = INCENTIVE.OPEN;
            endTime = block.timestamp + 2 hours;
            emit IncentiveOpen (endTime);
        }
        
    }

    function closeIncentive() public onlyOwner {
        incentive = INCENTIVE.CLOSED;
        finishIncentive();
    }

    function depositIncentive(uint256 _amount, address _token) public {
        if (block.timestamp >= endTime){
            incentive = INCENTIVE.CLOSED;
            finishIncentive();
        }
        if (incentive == INCENTIVE.OPEN){
        require(whitelistedTokens[_token], "Token is not whitelisted");
        address pool = IRegistry(registry).tokenToPool(_token);
        uint256 USDValue = ITokenPool(pool).getDepositValue(_amount);
        require(USDValue > 1e18, "Amount must be greater than $1");
        require(USDValue * 50000/PRECISION < getWithdrawAmount(TRSY.balanceOf(address(this))), "Amount exceeds max incentive");
        Concentrations memory c = makeConcentrationStruct(pool,USDValue);
        require(c.currentConcentration<c.targetConcentration, "Pool is already above target concentration");
        require(c.newConcentration < (c.targetConcentration + 300000), "This will make the pool too concentrated");
        uint256 trsyamt = getTRSYAmount(USDValue);
        uint reward = trsyamt * 50000 / PRECISION;
        bool success = IERC20(_token).transferFrom(msg.sender, pool, _amount);
        require(success);
        timestamp[msg.sender] = block.timestamp;
        TRSY.mint(msg.sender, trsyamt);
        TRSY.transfer(msg.sender, reward);
        if (!isRewardee[msg.sender]){
            isRewardee[msg.sender] = true;
            rewardees.push(msg.sender);
        }
        if (!Registry(registry).checkDeposit(10000) || TRSY.balanceOf(address(this)) < 1e18){
            incentive = INCENTIVE.CLOSED;
            finishIncentive();
        }    }
    }

    function finishIncentive() internal {
        uint256 diff = Registry(registry).calcDeposit();
        if (diff < 30000){
            uint256 total = TRSY.balanceOf(address(this));
            uint256 len = rewardees.length;
            uint256 reward = total / len;
            for (uint i; i<len;){
                address person = rewardees[i];
                rewardees[i] = address(0);
                TRSY.transfer(person, reward);
                unchecked{++i;}
            }
        }
        rewardees = new address[](0);
        endTime = 0;
    }

   

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

//SPDX-License-Identifier:MIT
pragma solidity 0.8.12;

import "ERC20.sol";

contract TRSYERC20 is ERC20 {

    constructor () ERC20("ASTreasury", "TRSY")  {
    }
    
    /** @dev Create own mint function as token is only minted upon depositing, not upon creation of the token contract
    @param receiver - who to send minted tokens to
    @param amt - how many tokens to mint */

    function mint(address receiver, uint256 amt) public {
        _mint(receiver, amt);
    }
    /** @dev function to burn tokens from a specific address
    @param user - the user whose tokens are to be burned
    @param amt - how many tokens are to be burned */

    function burn (address user, uint256 amt) public {
        _burn(user, amt);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

//import "AggregatorV3Interface.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenPool{
//variables
IERC20 public immutable token;
address public chainlinkfeed;
uint256 public targetconcentration;
AggregatorV3Interface public oracle;
uint256 public decimal;

//constructor
constructor (address _tokenAddress, address _chainlinkfeed, uint256 _targetconcentration, uint256 _decimal)  {
    token = IERC20(_tokenAddress);
    chainlinkfeed = _chainlinkfeed;
    oracle = AggregatorV3Interface(_chainlinkfeed);
    targetconcentration = _targetconcentration;
    decimal = _decimal;

}
/** 
@dev function to get current price of the token from the oracle 
returns the price of the token in USD with 18 decimals 
(token has 18 decimals, oracle has 8 decimals, so we multiply by 10^10 to make oracle price same decimals as token) )
 */
function getPrice() public  view returns (uint256){
    (,int256 price, , , ) = oracle.latestRoundData();
    uint256 decimals = oracle.decimals();
    return (uint256(price) * (10**(18-decimals)));
}

/**
@dev function to get the current pool value in USD
Multiplies the price of the token by number of tokens in the pool and divides by amount of token decimals 
 */
function getPoolValue() public view returns(uint256){
    uint256 price = getPrice();
    return ((token.balanceOf(address(this)) * price)/10**decimal);
}

/**
@dev function to get the usd value of the number of tokens someone wants to deposit
@param _amount (number of tokens to be deposited)
 */
 
function getDepositValue(uint256 _amount) external view returns(uint256){
    uint256 price = getPrice();
    return ((_amount * price) / (10 ** decimal));
}

/**
@dev function to send user tokens upon withdrawal
@param receiver - who to send the tokens to
@param amount - how much to send 
 */
function withdrawToken(address receiver, uint256 amount) external  {
    bool success = token.transfer(receiver, amount);
    require(success);
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IRegistry {
    function addTokenPool(address, address,uint256) external;

    function tokenToPool(address) external view returns (address);

    function getTotalAUMinUSD() external view returns (uint256);
    
    function tokensToWithdraw(uint256 _amount) external returns (address[] memory, uint256[] memory);}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface ITokenPool {
    
    
    function getPoolValue() external view returns (uint256);

    function getDepositValue(uint256) external view returns (uint256);
    
    function withdrawToken(address , uint256) external ;
    
    function getPrice() external returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "IERC20.sol";
import "ITokenPool.sol";
import "TokenPool.sol";

contract Registry {
//Variables
address public owner;
address[] public tokenPools;
address public factory; 
mapping (address => address) public tokenToPool;
mapping (address => address) public PoolToToken;
mapping (address => uint256) public PoolToConcentration;
uint256 constant PRECISION = 1e6;


//Structs
struct Rebalancing {
    address pool;
    uint256 amt;
}

//Errors
error Error_Unauthorized();

//Events
event ReservePoolDeployed(
        address indexed poolAddress,
        address tokenAddress
    );

//Modifier
modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Error_Unauthorized();
        }
        _;
    }
//Constructor
    constructor(){
       owner = msg.sender;
    }

/**
@dev function to set the factory address
@param _factory (address of the factory)
 */
    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

/**
@dev function to add TokenPool to tokenPool array and various mappings
@param _tokenPool - address of tokenPool
@param _token - address of token
@param concentration - value of target concentration 
 */
    function addTokenPool(address _tokenPool, address _token, uint256 concentration) public {
        require(msg.sender == factory, "Only the factory can add token pools");
        tokenPools.push(_tokenPool);
        tokenToPool[_token] = _tokenPool;
        PoolToToken[_tokenPool] = _token;
        PoolToConcentration[_tokenPool] = concentration;
    }

/** 
@dev function to update the target concentration of a specific pool 
@param _pool - address of tokenPool
@param _target - value of target concentration
 */
    function setTargetConcentration(address _pool, uint256 _target)
        external
        onlyOwner
    {
        PoolToConcentration[_pool] = _target;
    }

/**
@dev function to get the total USD value of all assets in the protocol
iterates through all the pools to get their usd value and adds all the values together
 */

    function getTotalAUMinUSD() public view returns (uint256) {
        uint256 total = 0;
        uint256 len = tokenPools.length;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];  
            uint256 poolBalance = ITokenPool(pool).getPoolValue();
            total += poolBalance;
            unchecked{++i;}
        }
        return total;
    }

/** 
@dev function to get the pools to withdraw from and the amount to withdraw from each pool
@param _amount - amount in usd to be withdrawn
 */
    function tokensToWithdraw(uint256 _amount) public view returns (address[] memory, uint256[] memory){
        (address[] memory pools, uint256[] memory tokenAmt) = checkWithdraw(_amount);
        return (pools, tokenAmt);
    }


/**
@dev function that finds which pools need to be rebalanced through a withdraw
@param _amount - how much usd is to be withdrawn
Calculates new aum and how much money has to be added/removed from pool to reach the target concentration
Checks which pool have to have money removed (and how much) and adds them to the array 
 */
    function liquidityCheck(uint256 _amount) public view returns(Rebalancing[] memory)  {
        uint len = tokenPools.length;
        Rebalancing[] memory withdraw = new Rebalancing[](len);
        uint aum = getTotalAUMinUSD();
        uint newAUM = aum - _amount;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];
            uint256 poolBalance = ITokenPool(pool).getPoolValue();
            uint256 target = PoolToConcentration[pool];
            uint256 poolTarget = newAUM*target/PRECISION;
            if(poolBalance > poolTarget){
                uint256 amt = poolBalance - poolTarget;
                withdraw[i]=(Rebalancing({pool: pool, amt: amt}));
            }
            else{
                withdraw[i]=(Rebalancing({pool: pool, amt: 0}));
            }
            unchecked{++i;}
        }
        return withdraw;
        }
    
/**
@dev function that takes the rebalancing array from liquidityCheck and returns the pools to withdraw from
and how much to withdraw from each pool
Checks total amount to be withdraw, finds pools with greatest concentration disparity and takes from those first
@param _amount - amount to be withdrawn
 */
    function checkWithdraw(uint _amount)public view returns (address[] memory, uint256[] memory){
        Rebalancing[] memory withdraw = liquidityCheck(_amount);
        uint256 len = withdraw.length;
        address[] memory pool = new address[](len);
        uint[] memory tokenamt = new uint[](len);
        uint total = 0;
        for (uint i; i<len;){
            (Rebalancing memory max, uint index) = findMax(withdraw);
            if ((total<_amount)&&(total + max.amt > _amount)){
                tokenamt[i]= (_amount - total);
                pool[i] = (max.pool);
                total += tokenamt[i];
            }
            else if ((total<_amount)&&(total + max.amt <= _amount)){
                tokenamt[i] = (max.amt);
                pool[i] = (max.pool);
                total += max.amt;
                 withdraw[index].amt = 0;
            }
            unchecked{++i;}
           }
        return (pool, tokenamt);
    }
/**
@dev helper function that finds which pool has to have the most money withdrawn
@param _rebalance - rebalancing array 
 */
        function findMax (Rebalancing[] memory _rebalance) public pure returns (Rebalancing memory, uint256){ 
        uint256 len = _rebalance.length;
        uint max = 0;
        uint index = 0;
        for (uint i = 0; i<len;){
            if (max < _rebalance[i].amt){
                max = _rebalance[i].amt;
                index = i;
            }
            unchecked{++i;}
        }
        return (_rebalance[index],index);
    }
/**
@dev function to get the current concentration of a specific pool
@param pool - pool to fnd concentration of 
 */

    function getConcentration(address pool) view public returns(uint){
            uint256 total = getTotalAUMinUSD();
            uint256 poolBalance = ITokenPool(pool).getPoolValue();       
            return total == 0 ? 0 :poolBalance*PRECISION/total;
        }
/**
@dev function to get the concentration of certain pool when a certain amount is added to the pool
@param pool - pool to find concentration of
@param amount - amount to be added to pool
 */
    function getNewConcentration (address pool, uint amount) view public returns (uint){    
            uint256 total = getTotalAUMinUSD() + amount;
            uint256 poolBalance = ITokenPool(pool).getPoolValue() + amount;       
            return total == 0 ? 0 : poolBalance*PRECISION/total;
            
        }
/**
@dev checks if any pool has a concentration more than "percent" % above/below target concentration
@param percent - percent above/below target concentration 
 */
    function checkDeposit(uint percent) public view returns (bool){
        uint len = tokenPools.length;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];
            uint currentConcentration = getConcentration(pool);
            int diff = int(currentConcentration) - int(PoolToConcentration[pool]);
            uint absdiff = abs(diff);
            if (absdiff>percent) {
                return (true);
            }
            unchecked{++i;}
        }
        return (false);
    }
    function abs (int256 x) public pure returns (uint){
        if (x<0){
            x = 0 - x;
            return uint(x);
        }
        else{
            return uint(x);
        }
    }
    
    function calcDeposit() public view returns (uint){
        uint total = 0;
        uint len = tokenPools.length;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];
            uint currentConcentration = getConcentration(pool);
            int diff = int(currentConcentration) - int(PoolToConcentration[pool]);
            uint absdiff = abs(diff);
            total += absdiff;
            unchecked {++i;}
    } return total;}

    }