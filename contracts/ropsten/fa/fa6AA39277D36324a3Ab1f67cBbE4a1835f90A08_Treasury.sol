//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/ITreasury.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../util/CommonModifiers.sol";
import "../pusd/PUSD.sol";

contract Treasury is Ownable, ITreasury, CommonModifiers {
    constructor(
        address payable _pusdAddress,
        address payable _loanAgentAddress,
        uint256 _buyPrice,
        uint256 _sellPrice,
        uint8 buySellPriceDecimals
    ) {
        require(_pusdAddress != address(0), "NON_ZEROADDRESS");
        require(_loanAgentAddress != address(0), "NON_ZEROADDRESS");
        pusdAddress = _pusdAddress;
        loanAgent = _loanAgentAddress;
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
        buySellPriceDecimals = buySellPriceDecimals;
    }

    /**
     * @notice Buy PUSD from the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin used to buy PUSD
     * @param _pusdAmount Amount of PUSD the buyer would like to purchase
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function buyPUSD(
        address stablecoinAddress,
        uint256 _pusdAmount
    ) external override nonReentrant() returns (bool) {
        PUSD pusd = PUSD(pusdAddress);

        ERC20 stablecoin = ERC20(stablecoinAddress);

        uint8 stablecoinDecimals = stablecoin.decimals();
        uint8 pusdDecimals = pusd.decimals();
        uint256 multiplier = 10**(pusdDecimals - stablecoinDecimals + 8);
        uint256 stablecoinAmount = (buyPrice * _pusdAmount) / multiplier; // TODO: Should this be sellPrice or buyPrice

        require(
            stablecoin.balanceOf(msg.sender) >= stablecoinAmount,
            "Stablecoin balance is too low"
        );

        stablecoinReserves[stablecoinAddress] += stablecoinAmount;

        require(stablecoin.transferFrom(msg.sender, address(this), stablecoinAmount), "TKN_TRANSFER_FAILED");

        pusd.mint(msg.sender, _pusdAmount);

        return true;
    }

    /**
     * @notice Sell PUSD from the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin given to seller in exchange for PUSD
     * @param _pusdAmount Amount of PUSD the seller would like to sell
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function sellPUSD(
        address stablecoinAddress,
        uint256 _pusdAmount
    ) external override nonReentrant() returns (bool) {
        // TODO: Should this be sellPrice or buyPrice
        PUSD pusd = PUSD(pusdAddress);
        ERC20 stablecoin = ERC20(stablecoinAddress);
        uint8 stablecoinDecimals = stablecoin.decimals();
        uint8 pusdDecimals = pusd.decimals();
        uint256 multiplier = 10**(pusdDecimals - stablecoinDecimals + 8);
        uint256 stablecoinAmount = (sellPrice * _pusdAmount) / multiplier;

        uint256 stablecoinReserve = stablecoinReserves[stablecoinAddress];

        require(
            stablecoinReserve >= stablecoinAmount,
            "Insufficient stablecoin in reserves"
        );

        stablecoinReserves[stablecoinAddress] = stablecoinReserve - stablecoinAmount;

        pusd.burnFrom(msg.sender, _pusdAmount);
        require(stablecoin.transfer(msg.sender, stablecoinAmount), "TKN_TRANSFER_FAILED");

        return true;
    }

    /**
     * @notice Get the amount of a given token that the treasury holds
     * @dev This is called by a third party applications to analyze treasury holdings
     * @param tokenAddress Address of the coin to check balance of
     * @return The amount of the given token that this deployment of the treasury holds
     */
    function checkReserves(
        address tokenAddress
    ) external view override returns (uint256) {
        return stablecoinReserves[tokenAddress];
    }

    /**
     * @notice Deposit a given ERC20 token into the treasury
     * @dev The caller transfers assets into the treasury
     * @param tokenAddress Address of the coin to deposit
     * @param amount Amount of the token to deposit
     */
    function deposit(
        address tokenAddress,
        uint256 amount
    ) external override nonReentrant() {
        IERC20 token = IERC20(tokenAddress);

        stablecoinReserves[tokenAddress] += amount;

        require(token.transferFrom(msg.sender, address(this), amount), "TKN_TRANSFER_FAILED");
    }

    /**
     * @notice Withdraw a given ERC20 token from the treasury
     * @dev Only the admin can withdraw assets
     * @param tokenAddress Address of the coin to withdraw
     * @param amount Amount of the token to withdraw
     * @param recipient Address where tokens are sent to
     */
    function withdraw(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) external override onlyOwner() nonReentrant() {
        uint256 stablecoinReserve = stablecoinReserves[tokenAddress];

        require(stablecoinReserve > amount, "not enough reserves");

        IERC20 token = IERC20(tokenAddress);

        stablecoinReserves[tokenAddress] = stablecoinReserve - amount;

        require(token.transfer(recipient, amount), "TKN_TRANSFER_FAILED");
    }

    /**
     * @notice Add a stablecoin to the list of accepted stablecoins
     * @dev Update both the array and mapping
     * @param stablecoinAddress Stablecoin to be added to reserve whitelist
     */
    function addReserveStablecoin(
        address stablecoinAddress
    ) external override onlyOwner() {
        if (!supportedStablecoins[stablecoinAddress]) {
            supportedStablecoins[stablecoinAddress] = true;
            stablecoinReserves[stablecoinAddress] = 0;
        }
    }

    /**
     * @notice Remove a stablecoin to the list of accepted reserve stablecoins
     * @dev Update both the array and mapping
     * @param stablecoinAddress Stablecoin to be removed from reserve whitelist
     */
    function removeReserveStablecoin(
        address stablecoinAddress
    ) external override onlyOwner() {
        supportedStablecoins[stablecoinAddress] = false;
    }

    /**
     * @notice Sets the address of the PUSD contract
     * @param _pusdAddress Address of the new PUSD contract
     */
    function setPUSDAddress(
        address payable _pusdAddress
    ) external override onlyOwner() {
        pusdAddress = _pusdAddress;
    }

    /**
     * @notice Sets the address of the loan agent contract
     * @param _loanAgentAddress Address of the new loan agent contract
     */
    function setLoanAgent(
        address payable _loanAgentAddress
    ) external override onlyOwner() {
        loanAgent = _loanAgentAddress;
    }

    //transfer funds to the xPrime contract
    function accrueProfit() external override {
        // TODO
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/* 
    Tokens in the treasury are divided between three buckets: reserves, insurance, and surplus. 

    Reserve tokens accrue from the result of arbitrageurs buying PUSD from the treasury. 

    Insurance tokens are held in for the event where a liquidation does not fully cover an outstanding loan.
    If an incomplete liquidation occurs, insurance tokens are transferred to reserves to back the newly outstanding PUSD
    When sufficient insurance tokens are accrued, newly recieved tokens are diverted to surplus. 

    Surplus tokens are all remaining tokens that aren't backing or insuring ourstanding PUSD.
    When profit accrues, the value of surplus tokens is distributed to xPrime stakers. 
*/

abstract contract ITreasury is Ownable {
    // Address of the PUSD contract on the same blockchain
    address payable public pusdAddress;

    // Address of the loan agent on the same blockchain
    address payable public loanAgent;

    /*
     * Mapping of addesss of accepted stablecoin to amount held in reserve
     */
    mapping(address => uint256) public stablecoinReserves;

    // Addresses of all the tokens in the treasury
    mapping(address => bool) public reserveTypes;

    // Addresses of stablecoins that can be swapped for PUSD at the guaranteed rate
    mapping(address => bool) public supportedStablecoins;

    // Price at which a trader can sell PUSD from the treasury. Should be slightly less than one
    uint256 public sellPrice;

    // Price at which a trader can buy PUSD from the treasury. Should be slightly more than 1
    uint256 public buyPrice;

    /**
     * @notice Buy PUSD from the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin used to buy PUSD
     * @param amountPUSD Amount of PUSD the buyer would like to purchase
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function buyPUSD(address stablecoinAddress, uint256 amountPUSD)
        external
        virtual
        returns (bool);

    /**
     * @notice Sell PUSD from the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin given to seller in exchange for PUSD
     * @param _PUSDamount Amount of PUSD the seller would like to sell
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function sellPUSD(address stablecoinAddress, uint256 _PUSDamount)
        external
        virtual
        returns (bool);

    /**
     * @notice Get the amount of a given token that the treasury holds
     * @dev This is called by a third party applications to analyze treasury holdings
     * @param tokenAddress Address of the coin to check balance of
     * @return The amount of the given token that this deployment of the treasury holds
     */
    function checkReserves(address tokenAddress)
        external
        view
        virtual
        returns (uint256);

    /**
     * @notice Deposit a given ERC20 token into the treasury
     * @dev Msg.sender will be the address used to transfer tokens from
     * @param tokenAddress Address of the coin to deposit
     * @param amount Amount of the token to deposit
     */
    function deposit(address tokenAddress, uint256 amount) external virtual;

    /**
     * @notice Withdraw a given ERC20 token from the treasury
     * @dev Withdrawals should not be allowed to come from reserves
     * @param tokenAddress Address of the coin to withdraw
     * @param amount Amount of the token to withdraw
     * @param recipient Address where tokens are sent to
     */
    function withdraw(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) external virtual;

    /**
     * @notice Add a stablecoin to the list of accepted stablecoins for reserve status
     * @dev Update both the array and mapping
     * @param stablecoinAddress Stablecoin to be added to reserve whitelist
     */
    function addReserveStablecoin(address stablecoinAddress) external virtual;

    /**
     * @notice Remove a stablecoin to the list of accepted reserve stablecoins
     * @dev Update both the array and mapping
     * @param stablecoinAddress Stablecoin to be removed from reserve whitelist
     */
    function removeReserveStablecoin(address stablecoinAddress)
        external
        virtual;

    /**
     * @notice Sets the address of the PUSD contract
     * @param pusd Address of the new PUSD contract
     */
    function setPUSDAddress(address payable pusd) external virtual;

    /**
     * @notice Sets the address of the loan agent contract
     * @param loanAgentAddress Address of the new loan agent contract
     */
    function setLoanAgent(address payable loanAgentAddress) external virtual;

    /**
     * @notice Transfers funds to the xPrime contract
     */
    function accrueProfit() external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract CommonModifiers {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal _notEntered;

    constructor() {
        _notEntered = true;
    }

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../interfaces/IHelper.sol";
import "./PUSDStorage.sol";
import "./PUSDMessageHandler.sol";
import "./PUSDAdmin.sol";

contract PUSD is PUSDAdmin, PUSDMessageHandler {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _chainId,
        address _ecc
    ) ERC20(_name, _symbol) {
        admin = msg.sender;
        chainId = _chainId;
        ecc = IECC(_ecc);
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyPermissioned() {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens on the local chain and mint on the destination chain
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _dstChainId Destination chain to mint
     * @param _receiver Wallet that is sending/burning PUSD
     * @param amount Amount to burn locally/mint on the destination chain
     */
    function sendTokensToChain(
        uint256 _dstChainId,
        address _receiver,
        uint256 amount
    ) external payable {
        require(!paused, "PUSD_TRANSFERS_PAUSED");
        _sendTokensToChain(_dstChainId, _receiver, amount);
    }

    /// @dev Used to estimate the fee of sending cross chain- commented out until we test with network tokens
    // function estimateSendTokensFee(
    //     uint256 _dstChainId,
    //     bytes calldata _toAddress,
    //     bool _useZro,
    //     bytes calldata _txParameters
    // ) external view returns (uint256 nativeFee, uint256 zroFee) {
    //     // mock the payload for sendTokens()
    //     bytes memory payload = abi.encode(_toAddress, 1);
    //     return
    //         lzManager.estimateFees(
    //             _dstChainId,
    //             address(this),
    //             payload,
    //             _useZro,
    //             _txParameters
    //         );
    // }

    fallback() external payable {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address _route
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_REDEEM_ALLOWED,
        FB_REDEEM,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        MASTER_TRANSFER_ALLOWED,
        FB_COMPLETE_TRANSFER,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 previousAmount;
        uint256 amountIncreased;
    }

    struct MRedeemAllowed {
        Selector selector; // = Selector.MASTER_REDEEM_ALLOWED
        address pToken;
        address user;
        uint256 amount;
    }

    struct FBRedeem {
        Selector selector; // = Selector.FB_REDEEM
        address pToken;
        address user;
        uint256 redeemAmount;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }

    struct MTransferAllowed {
        uint8 selector; // = Selector.MASTER_TRANSFER_ALLOWED
        address pToken;
        address spender;
        address user;
        address dst;
        uint256 amount;
    }

    struct FBCompleteTransfer {
        uint8 selector; // = Selector.FB_COMPLETE_TRANSFER
        address pToken;
        address spender;
        address src;
        address dst;
        uint256 tokens;
    }

    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract PUSDStorage {
    address internal admin;

    IMiddleLayer internal middleLayer;
    IECC internal ecc;

    address internal treasuryAddress;
    address internal loanAgentAddress;
    uint256 internal chainId;
    bool internal paused;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./PUSDStorage.sol";
import "./PUSDAdmin.sol";
import "../../interfaces/IHelper.sol";
import "../../util/CommonModifiers.sol";

abstract contract PUSDMessageHandler is
    PUSDStorage,
    PUSDAdmin,
    ERC20Burnable,
    CommonModifiers
{
    function _sendTokensToChain(
        uint256 _dstChainId,
        address receiver,
        uint256 amount
    ) internal {
        require(msg.sender == receiver, "X_CHAIN_ADDRESS_MUST_MATCH");
        require(!paused, "PUSD_TRANSFERS_PAUSED");

        uint256 _chainId = chainId;

        require(_dstChainId != _chainId, "DIFFERENT_CHAIN_REQUIRED");

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.PUSDBridge(
                uint8(IHelper.Selector.PUSD_BRIDGE),
                receiver,
                amount
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        // burn senders PUSD locally
        _burn(msg.sender, amount);

        middleLayer.msend{ value: msg.value }(
            _dstChainId,
            payload,
            payable(receiver), // refund address
            address(0)
        );

        emit SentToChain(_chainId, _dstChainId, receiver, amount);
    }

    function mintFromChain(
        IHelper.PUSDBridge memory params,
        bytes32 metadata,
        uint256 srcChain
    ) external onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        _mint(params.minter, params.amount);

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

        emit ReceiveFromChain(srcChain, params.minter, params.amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPUSD.sol";
import "./PUSDModifiers.sol";
import "./PUSDEvents.sol";

abstract contract PUSDAdmin is IPUSD, PUSDModifiers, PUSDEvents, Ownable {

    function setLoanAgent(
        address _loanAgentAddress
    ) external onlyOwner() {
        loanAgentAddress = _loanAgentAddress;

        emit SetLoanAgent(_loanAgentAddress);
    }

    function setOwner(
        address _owner
    ) external onlyOwner() {
        admin = _owner;

        emit SetOwner(_owner);
    }

    function setTreasury(
        address _treasuryAddress
    ) external onlyOwner() {
        treasuryAddress = _treasuryAddress;

        emit SetTreasury(_treasuryAddress);
    }

    function setMiddleLayer(
        address _lzManager
    ) external onlyOwner() {
        middleLayer = IMiddleLayer(_lzManager);

        emit SetMiddleLayer(_lzManager);
    }

    function pauseSendTokens(
        bool _pause
    ) external onlyOwner() {
        paused = _pause;
        emit Paused(_pause);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IPUSD {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./PUSDStorage.sol";

abstract contract PUSDModifiers is PUSDStorage {

    modifier onlyPermissioned() {
        require(
            msg.sender == treasuryAddress ||
            msg.sender == loanAgentAddress ||
            msg.sender == admin, // FIXME: Remove
            "Unauthorized minter"
        );
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MIDDLE_LAYER");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract PUSDEvents {
    /**
     * @notice Event emitted when contract is paused
     */
    event Paused(bool isPaused);

    /**
     * @notice Event emitted when PUSD is sent cross-chain
     */
    event SentToChain(
        uint256 srcChainId,
        uint256 destChainId,
        address toAddress,
        uint256 amount
    );

    /**
     * @notice Event emitted when PUSD is received cross-chain
     */
    event ReceiveFromChain(
        uint256 srcChainId,
        address toAddress,
        uint256 amount
    );

    event SetLoanAgent(
        address loanAgentAddress
    );

    event SetOwner(
        address owner
    );

    event SetTreasury(
        address treasuryAddress
    );

    event SetMiddleLayer(
        address lzManager
    );
}