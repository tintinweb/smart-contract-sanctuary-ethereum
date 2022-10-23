// SPDX-License-Identifier: GPL-3.0
// @title A contract that represents a Found Management System
// @author Zhifei (Soso) Song

pragma solidity >=0.7.0 <0.9.0;

import "./FMDToken.sol";

/**
 * @title FundManagement
 * @dev Digital Fund Management System
 */
contract FundManagement {

    // A Spending of Fund Management System
    struct Spending {
        string purpose; // purpose of spending, should be non-empty
        uint256 amt; // ETH amount to spend
        address receiver; // receiver of the spending
        bool executed; // whether the spending has been executed
        // mapping(address => bool) approvals; // true:+1, false:-1 (stakeholders => vote)
        uint256 approvalCount; // number of tokens controlled by the addresses that approved
    }
    mapping(uint256 => mapping(address => int)) public approvals; // 0 unvoted, 1 approve, -1 disapprove

    // The owner of the contract
    address public admin;

    // Min amount ETH to deposit to become a stakeholder
    uint256 public minBuyETH;

    // (holder => ETH amount deposited)
    mapping(address => uint256) public stakeholders;
    
    // (spendingId => Spending)
    mapping(uint256 => Spending) public spending;

    // percent of votes needed from total tokens to pass a spending request, number should be rounded down.
    uint256 MIN_VOTE_PERCENT = 75;

    // address of the Share Token
    address public shareToken;

    // other valiables ----------------------------------------------
    // total minted tokens in wei
    uint256 public tokenMinted; // unit in wei represent FMD token

    // helper variable to keep track of amount of spendingId
    uint256 public spendingIdCounter;

  

    // ------------------------------------------------------------------

    // Stakeholder has deposited tokens (to contract address)
    event Deposit(address indexed newStakeholder, uint256 depositAmt);

    // An approval vote has been sent
    event Vote(address indexed voter, int vote); // no spending ID
    // event Approval(address indexed stakeholder, uint256 spendingId, bool vote);

    // A new spending request has been made
    event NewSpending(address indexed receiver, uint256 spendingAmt);
    // event NewSpending(uint256 spendingId, string purpose, uint256 amt, address receiver);

    // A spending request has been executed
    event SpendingExecuted(address indexed executor, uint256 spendingId);
    // event SpendingExecuted(uint256 spendingId, string purpose, uint256 amt, address receiver);

    /**
     * @dev Sets the admin that manages the Fund Management System and the min amount of ETH to become a stakeholder
     * @param _admin the admin who manages the Fund Management System
     * @param _minBuyETH the min amount of ETH to become a stakeholder
     */
    constructor(address _admin, uint256 _minBuyETH) {
        admin = _admin;
        minBuyETH = _minBuyETH;
        shareToken = address(new FMDToken(address(this)));
    }

    /**
     * @dev Deposit ETH and mint FMD (ERC20 tokens) to sender
     * @param depositAmt the amount of ETH deposited
     */
    function deposit(uint256 depositAmt) public payable{
        // check if the deposit amount is greater than the minBuyETH
        require(depositAmt >= minBuyETH, "Deposit amount is less than minBuyETH");
        require(msg.value == depositAmt, "ETH sent and depositAmt not machting");
        // require(msg.value >= depositAmt, "Not enough ETH sent"); why we dont just use msg.value

        uint256 FMDAmt = depositAmt * 10; // 10 FMD = 1 ETH

        // mint 1 x ethChargeAmt FMD tokens to sender (1 FMD token = 0.1 ETH)     
        FMDToken(shareToken).mint(msg.sender, FMDAmt);
        tokenMinted += FMDAmt;

        // add depositAmt to the sender's balance
        stakeholders[msg.sender] += depositAmt; // unit: Gwei (1 ETH)

        emit Deposit(msg.sender, depositAmt);
    }

    /**
     * @dev Transfer FMD back to contract address (and not withdraw ETH)
     * @param transferAmt the amount of FMD to Transfer
     */
    function transfer(uint256 transferAmt) public {
        // check if the withdraw amount is greater than the minBuyETH
        require(transferAmt >= minBuyETH * 10, "transfer amount must be greater than 1 FMD = 0.1 ETH");

        uint256 ETHAmt = transferAmt / 10; // 10 FMD = 1 ETH

        // check if the transferAmt amount is less than the sender's balance
        // transferAmt is FMD, divide by 10 to get ETH amount

        require(ETHAmt <= stakeholders[msg.sender], "transfer amount is greater than sender's balance");

        // transfer FMD tokens from sender to contract address
        FMDToken(shareToken).transfer(msg.sender, transferAmt);
        // tokenMinted -= transferAmt * 10; David said we dont need to decrease tokenMinted

        // subtract transferAmt from the sender's balance
        stakeholders[msg.sender] -= ETHAmt; // unit: Gwei (1 ETH)
    }

    /**
     * @dev Admin creates a spending request
     * @param receiver the spending will be sent to this address
     * @param spendingAmt the amount of ETH to spend
     * @param _purpose the purpose of the spending
     */
    function createSpending(address receiver, uint256 spendingAmt, string memory _purpose) public {
        // check if the sender is the admin
        require(msg.sender == admin, "Only admin can create spending");
        
        // About max spendingAmt: It's ok to spend more than the contract balance because
        // executeSpending would reduce the contract balance, which still makes some spending
        // unable to perform for the moment, so it's not helpful to check it in this function.

        // About min spendingAmt: it's ok to spend less than the minBuyETH, because spending
        // is not about buying tokens, it's about spending ETH
        require(spendingAmt > 0, "Spending amount should be greater than 0");

        require(bytes(_purpose).length > 0, "Purpose should not be empty");

        spending[spendingIdCounter] = Spending({
            purpose: _purpose, // no way to get purpose from frontend?
            amt: spendingAmt,
            receiver: receiver,
            executed: false,
            approvalCount: 0
        });
        spendingIdCounter++;

        emit NewSpending(receiver, spendingAmt);
    }

    /**
     * @dev Stakeholder adds an approval vote to a spending request
     * @param spendingId the spending request ID
     * @param vote true:+1, false:-1, other:0
     */
    function approveSpending(uint256 spendingId, int vote) public {
        // check if the sender is a stakeholder
        require(stakeholders[msg.sender] > 0, "Only stakeholders can approve spending");

        // check if the vote is valid
        require(vote == 1 || vote == -1, "Vote should be 1 or -1");

        // check if the spendingId is valid, 0 <= uint256
        require(spendingId < spendingIdCounter, "Invalid spendingId");

        // check if the spending has been executed
        require(spending[spendingId].executed == false, "Spending has been executed");

        // check if the sender has not voted
        require(approvals[spendingId][msg.sender] == 0, "Sender has already voted");

        // update the vote
        approvals[spendingId][msg.sender] = vote;

        // update the approvalCount
        if (vote == 1) {
            spending[spendingId].approvalCount += stakeholders[msg.sender]; // stakeholders map to ETH amount
        } else if (spending[spendingId].approvalCount > stakeholders[msg.sender]) {
            spending[spendingId].approvalCount -= stakeholders[msg.sender]; // approvalCount is in number of FMD tokens
        } else {
            spending[spendingId].approvalCount = 0;
        }

        emit Vote(msg.sender, vote);
    }

    /**
     * @dev Send money to address if there are enough approvals
     * @param spendingId the id of the spending request
     */
    function executeSpending(uint256 spendingId) public {

        // check if the sender is the admin
        require(msg.sender == admin, "Only admin can execute spending");

        // check if the spendingId is valid
        require(spendingId < spendingIdCounter, "Invalid spendingId");

        // check if the spending has been executed
        require(spending[spendingId].executed == false, "Spending has been executed");

        // check if the spending has enough approvals
        uint256 votePercent;
        if (tokenMinted>0){
            // approvalCount is in unit of Wei repersent the amount of ETH
            // tokenMinted is in unit of Wei repersent the amount of FMD tokens
            votePercent = 1000*spending[spendingId].approvalCount/tokenMinted; // vote percentage = should be 0 ~ 100
            // Note: 1000 = 100(percent) * 10 (1 FMD = 0.1 ETH), for less calculation/gas
        }

        require(votePercent >= MIN_VOTE_PERCENT, "Not enough approvals");
        // check if the contract has enough balance
        require(address(this).balance >= spending[spendingId].amt, "Not enough balance");

        // execute the spending
        spending[spendingId].executed = true;

        // send the spending to the receiver
        (bool sent,) = spending[spendingId].receiver.call{value: spending[spendingId].amt}("");
        require(sent, "Failed to send Ether");

        emit SpendingExecuted(msg.sender, spendingId);
    }
}

// SPDX-License-Identifier: GPL-3.0
// @title A contract that represents a Found Management System
// @author Zhifei (Soso) Song

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FMDToken
 * @dev Digital FMD Token
 */
contract FMDToken is ERC20 {

    address public admin;

    // (minter => isMinter)
    mapping(address => bool) public isMinter;

    // (holder => balance)
    // mapping(address => uint256) public balanceOf;

    // (account => (approvedSpender => isApproved))
    mapping(address => mapping(address => bool)) public isApproved;

    // event Transfer(address indexed sender, address indexed receiver, uint256 amt);

    /**
     * @dev Sets the admin that manages the FMDToken
     * @param _admin the admin who manages the FMDToken
     */
    constructor(address _admin) ERC20("FMDToken", "FMD") {
        admin = _admin;
        isMinter[admin] = true;
    }

    /**
     * @dev Mints new FMDToken to an account
     * @param receiver the account that receives the newly minted FMDToken
     * @param mintAmt the amt of FMDToken to mint
     */
    function mint(address receiver, uint256 mintAmt) public {
        require(isMinter[msg.sender], "Caller does not have minting rights");

        _mint(receiver, mintAmt);

        emit Transfer(address(0), receiver, mintAmt);
    }

     /**
     * @dev Tranfer FMDTokens from the caller's account to another account
     * @param stackholder the sender of the FMDToken transfer
     * @param transferAmt the amt of FMDTokens to transfer
     */ 
    function transfer(address stackholder, uint256 transferAmt) override public returns (bool success) {
        // note that receiver is hardcoded to admin, which is the FundManagement contract
        // we are not allowing transfer bettwen accounts other than admin
        // should be only called by contract = admin, waiting for slide about keyword != public
        require(msg.sender == admin || isApproved[stackholder][msg.sender], 
            "Transfer not allowed, sender is not msg.sender or isApproved is false"
        );
        _transfer(stackholder, admin, transferAmt);

        emit Transfer(stackholder, admin, transferAmt);

        return true;
    }

    /**
     * @dev Set Minter Permissions
     * @param minter the target minter
     * @param _isMinter whether or not the minter had minting rights
     */
    function manageMinters(address minter, bool _isMinter) public {
        require(msg.sender == admin, "Caller is not admin");

        isMinter[minter] = _isMinter;
    }

    /**
     * @dev Set the approval permission of tranferring FMDToken for caller's account
     * @param spender the target account that can havce permission to transfer caller's FMDToken
     * @param _isApproved whether or not the spender is approved
     */
    function approveSpender(address spender, bool _isApproved) public {
       isApproved[msg.sender][spender] = _isApproved;
    }

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