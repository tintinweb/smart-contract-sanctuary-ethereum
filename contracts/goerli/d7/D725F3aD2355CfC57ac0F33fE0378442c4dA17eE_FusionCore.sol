//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./FusionToken.sol";

///@notice Main Fusion Finance contract responsible for lending, collateralizing and borrowing
///@author John Nguyen (jooohn.eth)
contract FusionCore {

    ///@notice events emitted after each action.
    event Lend(address indexed lender, uint amount);
    event WithdrawLend(address indexed lender, uint amount);
    event ClaimYield(address indexed lender, uint amount);
    event Collateralize(address indexed borrower, uint amount);
    event WithdrawCollateral(address indexed borrower, uint amount);
    event Borrow(address indexed borrower, uint amount);
    event Repay(address indexed borrower, uint amount);
    event Liquidate(address liquidator, uint reward, address indexed borrower);

    ///@notice mappings needed to keep track of lending
    mapping(address => uint) public lendingBalance;
    mapping(address => uint) public fusionBalance;
    mapping(address => uint) public startTime;
    mapping(address => bool) public isLending;

    ///@notice mappings needed to keep track of collateral and borrowing
    mapping(address => uint) public collateralBalance;
    mapping(address => uint) public borrowBalance;
    mapping(address => bool) public isBorrowing;

    ///@notice declaring chainlink's price aggregator.
    AggregatorV3Interface internal priceFeed;
    address public constant baseAssetAddress = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;

    ///@notice declaring token variables.
    IERC20 public immutable baseAsset;
    FusionToken public immutable fusionToken;

    ///@notice initiating tokens
    ///@param _baseAssetAddress address of base asset token
    ///@param _fusionAddress address of $FUSN token
    constructor(IERC20 _baseAssetAddress, FusionToken _fusionAddress) {
        baseAsset = _baseAssetAddress;
        fusionToken = _fusionAddress;
        priceFeed = AggregatorV3Interface(baseAssetAddress);
    } 

    ///@notice checks if the borrow position has passed the liquidation point
    ///@dev added 'virtual' identifier for MockCore to override
    modifier passedLiquidation(address _borrower) virtual {
        uint ethPrice = getEthPrice();
        require((ethPrice * collateralBalance[_borrower]) <= calculateLiquidationPoint(_borrower), "Position can't be liquidated!");
        _;
    }

    ///@notice Function to get latest price of ETH in USD
    ///@return ethPrice price of ETH in USD
    function getEthPrice() public view returns(uint ethPrice){
        (,int price,,,) = priceFeed.latestRoundData();
        ethPrice = uint(price) / 10**8;
    }

    ///@notice calculates amount of time the lender has been lending since the last update.
    ///@param _lender address of lender
    ///@return lendingTime amount of time staked by lender
    function calculateYieldTime(address _lender) public view returns(uint lendingTime) {
        lendingTime = block.timestamp - startTime[_lender];
    }

    ///@notice calculates amount of $FUSN tokens the lender has earned since the last update.
    ///@dev rate = timeStaked / amount of time needed to earn 100% of $FUSN tokens. 31536000 = number of seconds in a year.
    ///@param _lender address of lender
    ///@return yield amount of $FUSN tokens earned by lender
    function calculateYieldTotal(address _lender) public view returns(uint yield) {
        uint timeStaked = calculateYieldTime(_lender) * 10**18;
        uint rate = timeStaked / 31536000; 
        yield = (lendingBalance[_lender] * rate) / 10**18;
    }

    ///@notice calculates the borrow limit depending on the price of ETH and borrow limit rate.
    ///@return limit current borrow limit for user
    function calculateBorrowLimit(address _borrower) public view returns(uint limit) {
        uint ethPrice = getEthPrice();
        limit = ((((ethPrice * collateralBalance[_borrower]) / 100) * 70)) - borrowBalance[_borrower];
    }

    function calculateLiquidationPoint(address _borrower) public view returns(uint point) {
        point = borrowBalance[_borrower] + ((borrowBalance[_borrower] / 100) * 10);
    }

    ///@notice lends base asset.
    ///@param _amount amount of tokens to lend
    function lend(uint _amount) public {
        require(_amount > 0, "Can't lend amount: 0!");
        require(baseAsset.balanceOf(msg.sender) >= _amount, "Insufficient balance!");

        if(isLending[msg.sender]) {
            uint yield = calculateYieldTotal(msg.sender);
            fusionBalance[msg.sender] += yield; 
        }

        lendingBalance[msg.sender] += _amount;
        startTime[msg.sender] = block.timestamp;
        isLending[msg.sender] = true;

        require(baseAsset.transferFrom(msg.sender, address(this), _amount), "Transaction failed!");

        emit Lend(msg.sender, _amount);
    }

    ///@notice withdraw base asset.
    ///@param _amount amount of tokens to withdraw
    function withdrawLend(uint _amount) public {
        require(isLending[msg.sender], "Can't withdraw before lending!");
        require(lendingBalance[msg.sender] >= _amount, "Insufficient lending balance!");

        uint yield = calculateYieldTotal(msg.sender);
        startTime[msg.sender] = block.timestamp;
        uint withdrawAmount = _amount;
        _amount = 0;
        lendingBalance[msg.sender] -= withdrawAmount;

        require(baseAsset.transfer(msg.sender, withdrawAmount), "Transaction failed!");
        fusionBalance[msg.sender] += yield;

        if(lendingBalance[msg.sender] == 0){
            isLending[msg.sender] = false;
        }

        emit WithdrawLend(msg.sender, withdrawAmount);
    }
    
    ///@notice claims all yield earned by lender.
    function claimYield() public {
        uint yield = calculateYieldTotal(msg.sender);

        require(yield > 0 || fusionBalance[msg.sender] > 0, "No, $FUSN tokens earned!");

        if(fusionBalance[msg.sender] != 0) {
            uint oldYield = fusionBalance[msg.sender];
            fusionBalance[msg.sender] = 0;
            yield += oldYield;
        }

        startTime[msg.sender] = block.timestamp;
        fusionToken.mint(msg.sender, yield);

        emit ClaimYield(msg.sender, yield);
    }

    ///@notice collateralizes user's ETH and sets borrow limit
    function collateralize() public payable {
        require(msg.value > 0, "Can't collaterlize ETH amount: 0!");

        collateralBalance[msg.sender] += msg.value;

        emit Collateralize(msg.sender, msg.value);
    } 

    ///@notice withdraw user's collateral ETH and recalculates the borrow limit
    ///@param _amount amount of ETH the user wants to withdraw
    function withdrawCollateral(uint _amount) public {
        require(collateralBalance[msg.sender] >= _amount, "Not enough collateral to withdraw!");
        require(!isBorrowing[msg.sender], "Can't withdraw collateral while borrowing!");

        collateralBalance[msg.sender] -= _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transaction Failed!");

        emit WithdrawCollateral(msg.sender, _amount);
    }

    ///@notice borrows base asset
    ///@param _amount amount of base asset to borrow
    ///@dev deducting 0.3% from msg.sender's ETH collateral as protocol's fees
    function borrow(uint _amount) public {
        collateralBalance[msg.sender] -= (collateralBalance[msg.sender] / 1000) * 3;

        require(collateralBalance[msg.sender] > 0, "No ETH collateralized!");
        require(calculateBorrowLimit(msg.sender) >= _amount, "Borrow amount exceeds borrow limit!");

        isBorrowing[msg.sender] = true;
        borrowBalance[msg.sender] += _amount;

        require(baseAsset.transfer(msg.sender, _amount), "Transaction failed!");

        emit Borrow(msg.sender, _amount);
    }
    
    ///@notice repays base asset debt
    ///@param _amount amount of base asset to repay
    function repay(uint _amount) public {
        require(isBorrowing[msg.sender], "Can't repay before borrowing!");
        require(baseAsset.balanceOf(msg.sender) >= _amount, "Insufficient funds!");
        require(_amount > 0 && _amount <= borrowBalance[msg.sender], "Can't repay amount: 0 or more than amount borrowed!");

        if(_amount == borrowBalance[msg.sender]){ 
            isBorrowing[msg.sender] = false;
        }

        borrowBalance[msg.sender] -= _amount;

        require(baseAsset.transferFrom(msg.sender, address(this), _amount), "Transaction Failed!");

        emit Repay(msg.sender, _amount);
    }

    ///@notice liquidates a borrow position
    ///@param _borrower address of borrower
    ///@dev passedLiquidation modifier checks if the borrow position has passed liquidation point
    ///@dev liquidationReward 1.25% of borrower's ETH collateral
    function liquidate(address _borrower) public passedLiquidation(_borrower) {
        require(isBorrowing[_borrower], "This address is not borrowing!");

        uint liquidationReward = (collateralBalance[_borrower] / 10000) * 125; 

        collateralBalance[_borrower] = 0;
        borrowBalance[_borrower] = 0;
        isBorrowing[_borrower] = false;

        (bool success, ) = msg.sender.call{value: liquidationReward}("");
        require(success, "Transaction Failed!");

        emit Liquidate(msg.sender, liquidationReward, _borrower);
    }

    ///@notice returns lending status of lender
    function getLendingStatus(address _lender) external view returns(bool){
        return isLending[_lender];
    }  

    ///@notice retuns amount of $FUSN tokens earned
    function getEarnedFusionTokens(address _lender) external view returns(uint){
        return fusionBalance[_lender] + calculateYieldTotal(_lender);
    }

    ///@notice returns amount of base asset lent
    function getLendingBalance(address _lender) external view returns(uint){
        return lendingBalance[_lender];
    }

    ///@notice returns amount of collateralized asset
    function getCollateralBalance(address _borrower) external view returns(uint){
        return collateralBalance[_borrower];
    }

    ///@notice returns borrowing status of borrower
    function getBorrowingStatus(address _borrower) external view returns(bool){
        return isBorrowing[_borrower];
    }

    ///@notice returns amount of base asset borrowed
    function getBorrowBalance(address _borrower) external view returns(uint){
        return borrowBalance[_borrower];
    }

    ///@notice returns amount of base asset available to borrow
    function getBorrowLimit(address _borrower) external view returns(uint){
        return calculateBorrowLimit(_borrower);
    }

    ///@notice returns liquidation point
    function getLiquidationPoint(address _borrower) external view returns(uint){
        return calculateLiquidationPoint(_borrower);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///@notice Fusion Finance's governance token
///@author John Nguyen (jooohn.eth)
contract FusionToken is ERC20, Ownable {

    constructor() ERC20("Fusion Token", "FUSN") {}

    ///@notice wrapper for the _mint function, so that only the owner of the contract can mint tokens
    ///@param _to address of the user to mint
    ///@param _amount amount of $FUSN tokens to mint
    function mint(address _to, uint _amount) public onlyOwner {
        _mint(_to, _amount);
    }

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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