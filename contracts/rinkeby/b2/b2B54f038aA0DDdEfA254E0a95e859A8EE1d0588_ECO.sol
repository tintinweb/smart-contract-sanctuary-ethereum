// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./VestingManager.sol";
import "./CompanyERC.sol";

/** 
 * @title ECO
 * @dev This is the main contract for the ECO Vesting Manager
 */
contract ECO {
    address _owner;
    
    // Store company vesting contracts
    mapping(address => VestingManager) public companies;
    address[] allCompanies;     
    
    // Store ERC20 token address for a company token
    mapping(string => address) public companyERC20;
    uint128 public totalCompanies;

    event VestingWalletAdded(address company);
    event CompanyERCTokenDeployed(string tokenName, address tokenAddress);

    constructor(){
        _owner = msg.sender;
    }

    function createCompany(string memory company, address tokenAddress) external returns (bool) {
        // Check if VestingManager wallet already exist or not
        // require(companies[msg.sender].isWalletAvailable() == false, "Vesting wallet already exist.");

        // Create a Vesting Wallet for the callee wallet
        companies[msg.sender] = new VestingManager(company, msg.sender, tokenAddress);
        allCompanies.push(address(companies[msg.sender]));
        totalCompanies++;

        // Emit VestingWallet Added Event
        emit VestingWalletAdded(msg.sender);

        return true;
    }

    // Allows a company to deploy an ERC20 token through ECO contract
    function createCompanyERC(string memory companyName, string memory tokenName, uint256 totalSupply) external returns (address) {
        // Check if ERC20 token already exist or not
        require(companyERC20[tokenName] == 0x0000000000000000000000000000000000000000, "Company ERC20 tokens already exist.");

        CompanyERC erc20 = new CompanyERC(msg.sender, companyName, tokenName, totalSupply);
        companyERC20[tokenName] = address(erc20);

        // Emit Company ERC20 Token Deployed Event
        emit CompanyERCTokenDeployed(tokenName, address(erc20));

        return address(erc20);
    }

    function getAllCompanies() external view returns (address[] memory) {
        return allCompanies;
    }

    function getCompanyERC20Address(string memory tokenName) external view returns (address) {
        return companyERC20[tokenName];
    }    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** 
 * @title VestingManager
 * @dev This contract holds the company and employee token allocations
 */
contract VestingManager {
    // Owner by default will be the Company who will provide the wallet address
    address public owner;        

    // ERC20 Token address
    address public companyERC20;
    IERC20 public _companyERC20;
    
    // This is the kill switch to kind of enable/disable the working of Vesting
    bool public isActive;
    bool public isAvailable;

    uint256 tokensAllocated;
    string public companyName;    

    struct MemberAllotment {
        bool isComplete;
        bool isPaused;

        uint256 totalTokensAllotted;
        uint256 totalTokensTransferred;        

        // Accept a custom schedule with % and time range array
        // Make sure the tokensAlloted total is 100% and length of both arrays are same
        uint256[] tokensAlloted;
        uint256[] transferSchedule;        
    }

    // Keep all member allotments and also the reference in array for easy iteration
    mapping(address => MemberAllotment) public allotments;
    address[] public allMembers;

    // Events
    event MemberAdded(address indexed to, uint256 tokens);
    event MemberTokensVested(address indexed to, uint256 tokens, bool isComplete);
    event MemberVestingComplete(address indexed to, uint256 tokens);
    event MemberTokenAllotmentPaused(address indexed to);
    event MemberTokenAllotmentResumed(address indexed to);

    constructor(string memory company, address walletAddress, address tokenAddress){
        owner = walletAddress;
        companyName = company;
        companyERC20 = tokenAddress;
        isActive = true;
        isAvailable = true;

        _companyERC20 = IERC20(tokenAddress);
    }

    modifier ownerOnly {
        require(msg.sender == owner, "You are not the company owner.");
        _;
    }

    modifier isVestingActive {
        require(isActive == true, "Vesting plan is inactive.");
        _;
    }

    function pauseAllVesting() external ownerOnly {
        isActive = false;
    }

    function resumeAllVesting() external ownerOnly {
        isActive = true;
    }
    
    // This method will accept a custom schedule that is easy to follow
    // For a one time transfer the totalTokens = N, tokensSplit = [100] and timeSchedule = [future time]
    // For an equal split in 4 parts the totalTokens = N, tokenSplit = [25,25,25,25] and timeSchedule = [future1, future2, future3, future4]
    // This way we can build any kind of custom schedule
    // All the input params will be pre-calculated from UI side and validated in the function    
    function allocateTokens(address to, uint256 tokens, uint256[] memory tokenAllotment, uint256[] memory transferSchedule) external ownerOnly returns (bool) {
        uint256 tokenAllotmentLen = tokenAllotment.length;
        require(tokenAllotmentLen == transferSchedule.length, "Token allotment and schedule length is not matching.");

        // In case of allowance, there is a possibility that the Company can spend other tokens
        // In case of transfer, the tokens are already reserved and can not be spent on anywhere else
        // Transfer the Tokens to current contract
        uint256 balanceTokens = _companyERC20.balanceOf(address(this));        
        require(balanceTokens >= tokens, "Not enough tokens allocated to Vesting Manager. Make sure you are the owner of your ERC20 tokens.");
        require(balanceTokens >= (tokensAllocated + tokens), "Not enough tokens allocated to Vesting Manager. Make sure you are the owner of your ERC20 tokens.");

        MemberAllotment storage _lot = allotments[to];
        _lot.totalTokensAllotted = 0; // total vesting tokens for entire schedule
        _lot.totalTokensTransferred = 0;
        _lot.isComplete= false;
        _lot.isPaused= false;
        _lot.tokensAlloted = tokenAllotment;
        _lot.transferSchedule = transferSchedule;

        for(uint8 i = 0; i < tokenAllotmentLen; i++){            
            _lot.totalTokensAllotted += tokenAllotment[i];            
        }

        if(allotments[to].totalTokensAllotted != tokens){
            delete allotments[to];
            revert("Token allotment is not matching with total tokens.");
        }

        tokensAllocated += _lot.totalTokensAllotted;
        allMembers.push(to);
        emit MemberAdded(to, tokens);

        return true;
    }    

    function resumeAllotment(address to) external ownerOnly returns (bool) {
        // Check member allotment
        
        MemberAllotment storage memberAllotment = allotments[to];
        require(!memberAllotment.isComplete, "Allotment already completed.");
        require(!memberAllotment.isPaused, "Allotment already paused.");

        memberAllotment.isPaused = false;

        emit MemberTokenAllotmentResumed(to);        
        return true;
    }

    function pauseAllotment(address to) external ownerOnly returns (bool) {
        // Check member allotment
        
        MemberAllotment storage memberAllotment = allotments[to];
        require(!memberAllotment.isComplete, "Allotment already completed.");
        require(!memberAllotment.isPaused, "Allotment already paused.");

        memberAllotment.isPaused = true;

        emit MemberTokenAllotmentPaused(to);        
        return true;
    }

    function releaseTokens(address to) external ownerOnly returns (bool) {
        // Check member allotment
        
        MemberAllotment storage memberAllotment = allotments[to];
        require(!memberAllotment.isComplete, "Allotment already completed.");
        require(!memberAllotment.isPaused, "Allotment is paused.");
        
        // Any tokens released in this call!!
        bool isReleased = false;

        // This is a simple transfer. This will be replaced with custom schedule for simplicity.
        uint256 transferScheduleLen = memberAllotment.transferSchedule.length;
        for(uint8 i = 0; i < transferScheduleLen ; i++){
            // Check for previously vesting tokens
            if(memberAllotment.tokensAlloted[i] > 0){

                // Check for the current vested tokens
                if(block.timestamp > memberAllotment.transferSchedule[i]){
                    
                    // Trasnfer tokens from VestingContract to Member address
                    bool _success = _companyERC20.transfer(to, memberAllotment.tokensAlloted[i]);
                    require(_success, "Unable to transfer tokens to Vesting Account.");

                    memberAllotment.totalTokensAllotted -= memberAllotment.tokensAlloted[i];
                    memberAllotment.totalTokensTransferred += memberAllotment.tokensAlloted[i];
                    memberAllotment.tokensAlloted[i] = 0;

                    // Reduce the allotment value after transfer
                    tokensAllocated += memberAllotment.totalTokensAllotted;

                    isReleased = true;

                    // Check if all tokens are transferred
                    if(memberAllotment.totalTokensAllotted == 0){
                        memberAllotment.isComplete = true;

                        // Emit full vesting event
                        emit MemberVestingComplete(to, memberAllotment.totalTokensTransferred);
                    }else{
                        // Emit partial vesting event
                        emit MemberTokensVested(to, memberAllotment.totalTokensTransferred, memberAllotment.isComplete);
                    }                    
                }
            }            
        }        

        // If nothing released, then throw timing error.
        if(!isReleased){            
            revert("Tokens are still within the vesting period. Please check the vesting schedule.");            
        }

        return true;
    }

    function getAllotmentFor(address to) public view returns (MemberAllotment memory) {
        return allotments[to];
    }

    function getAllotment() external view returns (MemberAllotment memory) {
        return getAllotmentFor(msg.sender);
    }

    function getAllotedMembers() external view returns (address[] memory) {
        return allMembers;
    }

    function isWalletAvailable() public view returns (bool) {
        return isAvailable;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CompanyERC is ERC20 {

    constructor (address tokenOwner, string memory companyName, string memory tokenName, uint256 totalSupply) ERC20(companyName, tokenName) {
        _mint(tokenOwner, totalSupply);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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