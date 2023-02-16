// SPDX-License-Identifier: MIT
// This contract was created to raise funding. 
// This is the first round of the Ermine (ERM) token seed sale. 
// Visit and learn more on the official website https://ermine.pro
// Test Goerli

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@ermine/contracts/Ermine.sol";

contract LaunchPadErmine is Ownable {
    uint256 public timeEnd = 1677704340; //Mar 01-03-2023 23-59
    uint256 public totalBuy = 0;
    uint256 public priceERM = 0.000005 ether;
    uint256 day = 86400;
    uint256 public launchLimit = 375 * 1e23; //37,500,000 ERM
    bool public checkForAdd = true;
    bool[] private wRequest = new bool[](4);
    address adminAddress;
    address AddressERM;
    Ermine public coin;

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    struct Users {
        uint256 limit;
        uint256 limitMin;
        uint256 timeBuy;
        uint256 ERMValueBuy;
        uint256 ERMBlock;
        uint256 ERMSend;
        uint256 lastTime;
        bool verify;
    }

    mapping(address => Users) private _user;

    constructor(address _AddressERM, address _adminAddress){
        AddressERM = _AddressERM;
        coin = Ermine(AddressERM);
        adminAddress = _adminAddress;
    }

//For only Admin
    modifier onlyAdmin() {
    require(msg.sender == adminAddress);
    _;                              
    } 

//Only for confirmed members
    modifier onlyVerify() {
    require(_user[msg.sender].verify, "Error: Your address has not been verified, is not listed, or has been deleted after the ETH was returned! Or you have withdrawn all your ERM tokens.");
    _;                              
    } 

//Approving an address for a whitelist
    function verifyUser(address _wallet) external onlyAdmin {
        _user[_wallet].verify = true;
    }

//Approval of the operation by the administrator
    function confirm(uint _id) external onlyAdmin {
        require((_id < 4)&&(_id >= 0), "Error: Non-existent operation ID!");
        wRequest[_id] = true;
    }

//Adding an address and its limits to the whitelist
    function addWL(uint256 _limit, uint256 _limitMin, address _wallet) external onlyOwner {
        Users storage user;
        user = _user[_wallet];
        require(!user.verify, "Error: An approved application cannot be changed!");
        user.limit = _limit;
        user.limitMin = _limitMin;
        user.timeBuy = 0;
        user.ERMValueBuy = 0;
        user.ERMBlock = 0;
        user.ERMSend = 0;
        user.lastTime = 0;
        user.verify = false;
    }

//Purchasing Ermine tokens for approved whitelisted addresses
    function saleERM() external payable onlyVerify {
        Users storage user = _user[msg.sender];
        require(block.timestamp <= timeEnd, "Error: Seed Presale is over!");
        require(user.limit > 0, "Error: Your address is not on the whitelist!");
        require(msg.value >= priceERM * 10, "Error: You cannot buy less than 10ERM in 1 transaction!");
        uint256 _amount = (msg.value / priceERM) * 1e18;
        require(_amount + user.ERMValueBuy >= user.limitMin, "Error: You cannot buy tokens less than the amount of the set limit!");
        require(_amount <= launchLimit - totalBuy, "Error: Not enough tokens to buy, reduce your purchase amount and try again!");
        require(_amount <= user.limit - user.ERMValueBuy, "Error: You have exceeded the allowed purchase limit!");
        uint256 per = _amount / 100;
        coin.transfer(msg.sender, per*10);
        user.ERMValueBuy += _amount;
        user.ERMSend += per*10;
        user.timeBuy = block.timestamp;
        user.lastTime = block.timestamp + 90*day;
        user.ERMBlock += per*90;
        totalBuy += _amount;
    }

//Withdrawal of unlocked Ermine tokens
    function unLockErmine() external onlyVerify {
        require(totalBuy >= 4*1e24, "Error: Withdrawal of Ermine tokens is not possible because the softcap is not full!"); 
        Users storage user = _user[msg.sender];
        require(user.ERMBlock > 0, "Error: Your balance is 0 ERM. There is nothing to withdraw!");
        require(block.timestamp > user.lastTime, "Error: Ermine tokens are still locked and not available for withdrawal. Please wait until the withdrawal date and try again.");
        uint256 diff = block.timestamp - user.lastTime;
        user.lastTime = block.timestamp;
        uint256 totalERM = (diff / 5)*1e18;
        if (totalERM >= user.ERMBlock) {
            coin.transfer(msg.sender, user.ERMBlock);
            user.ERMSend += user.ERMBlock;
            user.ERMBlock = 0;
        }
        else {
            coin.transfer(msg.sender, totalERM);
            user.ERMBlock -= totalERM;
            user.ERMSend += totalERM;
        }
        if (user.ERMBlock == 0) { user.verify = false; }
    }

//If SoftCap is not filled then you can get your money back.
    function returnETH(uint256 _amount) external payable onlyVerify {
        Users storage user = _user[msg.sender];
        require(block.timestamp >= timeEnd, "Error: The end time of the seed pre-sale is not over yet!");  
        require(totalBuy < 4*1e24, "Error: ETH cannot be returned since the softcap has been filled!");  
        require(_amount <= coin.balanceOf(msg.sender), "Error: You don't have that many Ermine tokens in your wallet!"); 
        coin.transferFrom(msg.sender, address(this), _amount);
        uint256 toBack = ((user.ERMBlock + _amount)/1e18) * priceERM;
        user.ERMBlock = user.ERMValueBuy - user.ERMBlock - _amount;
        user.ERMValueBuy = user.ERMBlock;
        user.ERMSend = 0;
        if (user.ERMBlock == 0) {user.verify = false;}
        require(payable(msg.sender).send(toBack));
    }

//Withdraw ERM to the wallet Ermine if SoftCap is not completed.
    function returnERM() external onlyOwner {
        require(block.timestamp >= timeEnd, "Error: The end time of the seed pre-sale is not over yet!");  
        require(totalBuy < 4*1e24, "Error: ERM cannot be returned since the softcap has been filled!");  
        require(wRequest[2], "Error: ERM withdrawal requires admin confirmation!");
        coin.transfer(msg.sender, coin.balanceOf(address(this)));
        checkForAdd = false;
    }

//If fundraising is slow, you can add 30 days, but only once!
    function setTime() external onlyOwner {
        require(wRequest[1], "Error: The administrator must confirm the permission to set the new time (+30days)!");
        require(checkForAdd, "Error: You can add 30 days only once!");
        timeEnd += day * 30; // Add 30 days
        wRequest[1] = false;
        checkForAdd = false;
    }

//Withdrawal of collected ETH if SoftCap is executed.
    function withdrawETH() external payable onlyOwner {
        require(wRequest[0], "Error: The administrator must confirm the withdrawal!");    
        require(totalBuy >= 4*1e24, "Error: Withdrawing ETH is not possible because the softcap is not full!"); 
        require(payable(msg.sender).send(address(this).balance));
        wRequest[0] = false;
    }

//Withdraw remaining ERM tokens to Ermine wallet
    function withdrawErmineTokens() external onlyOwner{
        require(block.timestamp >= timeEnd, "Error: The end time of the seed pre-sale is not over yet!"); 
        require(totalBuy > 4*1e24, "Error: It is not possible to withdraw the balance of ERM tokens. Softcap failed. Call to returnERM.");
        require(launchLimit!=totalBuy, "Error: All ERM tokens have been sold!");
        require(wRequest[3], "Error: Withdrawal of ERM funds is not approved by the administrator!");
        coin.transfer(msg.sender, (launchLimit - totalBuy));
        checkForAdd = false;
    }

//Participant data card
function getUsers(address _wallet) public view returns (Users memory) {
        Users storage user = _user[_wallet];
        return user;
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
// Ermine utility token (ERM) :: https://ermine.pro 


//  ███████╗██████╗$███╗$$$███╗██╗███╗$$$██╗███████╗
//  ██╔════╝██╔══██╗████╗$████║██║████╗$$██║██╔════╝
//  █████╗$$██████╔╝██╔████╔██║██║██╔██╗$██║█████╗$$
//  ██╔══╝$$██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══╝$$
//  ███████╗██║$$██║██║$╚═╝$██║██║██║$╚████║███████╗
//  ╚══════╝╚═╝$$╚═╝╚═╝$$$$$╚═╝╚═╝╚═╝$$╚═══╝╚══════╝


pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Ermine is ERC20, Ownable {
    uint256 public maxAmountERM = 800 * 1e24;
    uint256 public burnedERM = 0;

    event Burn(address indexed from, uint256 amount);
    
    constructor () ERC20 ("Ermine", "ERM") {
        _mint(msg.sender, maxAmountERM);
    }

//Burning is available to everyone
    function burn(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "There are not enough tokens on your balance!");
        require((totalSupply() - amount) >= (400 * 1e24), "No more burning! At least 400M ERM must remain!");
        _burn(msg.sender, amount);
        burnedERM += amount;
        emit Burn(msg.sender, amount);
    }    
}