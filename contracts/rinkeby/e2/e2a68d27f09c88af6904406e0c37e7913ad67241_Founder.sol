/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



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

pragma solidity ^0.8.0;

// import "../IERC20.sol";

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


pragma solidity ^0.8.0;

// import "./IERC20.sol";
// import "./extensions/IERC20Metadata.sol";
// import "../../utils/Context.sol";

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


pragma solidity 0.8.0;

contract Factory {

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    mapping(bytes32 => RoleData) private _roles;

    function getRoleAdmin(bytes32 role) private view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function _grantRole(bytes32 role, address account) private{
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _setupRole(bytes32 role, address account) private{
        _grantRole(role, account);
    }

    bytes32 public constant VALIDATORS = keccak256("validator");
    address[] private allValidatorsArray;
    mapping(address => bool) private validatorBoolean;
    
    function addValidators(address _ad) public {
        allValidatorsArray.push(_ad);
        validatorBoolean[_ad] = true;
        _setupRole(VALIDATORS, _ad);
    }

    function returnArray() public view returns(address[] memory){ 
        return allValidatorsArray;
    }

    function checkValidatorIsRegistered(address _ad) public view returns(bool condition){
        require(validatorBoolean[_ad] == true,"This is not validators address");
        return true;
    }
        
}


pragma solidity ^0.8.0;

contract Founder{
    
    mapping(address => bool) public isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) public view returns(bool condition){
        require(isFounder[_ad] == true,"Founder is not added yet");
        return true;
    }

    function getAllFounderAddress() public view returns(address[] memory){
        return pushFounders;
    }    
}

/*

1. ProjectAndProposal Contract Setup
2. Create a Enum where, if founder,investor and project id(This can be restricted 
to 10% founder and 10% investor action).
3.  


*/


contract ProjectAndProposal{

    address public founder;
    address public investor;

    uint public totalValueForProject;
    uint public totalDepositedStableCoinsInThePot;
    uint public totalDepositedFounderTokenInPot;
    uint public TenPercentBalanceOfStableCoin;
    uint public TenPercentBalanceOfFounderToken;
    
    address[] private validatorWhoApproved;
    address[] private validatorWhoRejected;
    address[] private allValidators;
    address[] public validatorMatching;

    bool private proposalCancelledRevertWithdrawlToInvestors;
  
    mapping(address => bool) private whitelistValidators;
    mapping(address => uint) public totalDepositedStableCoins;
    mapping(address => uint) public totalFoundersToken;
    mapping(address => uint) private viewInvestors;
    mapping(bytes32 => address) private whitelistedTokens;
    mapping(address => mapping(bytes32 => uint256)) public accountBalances;
    mapping(address => uint) public getInvestorsId;

    modifier founderAction(){
        require(founder == msg.sender,"You are not the Founder");
        _;
    }

    modifier investorAction(){
        require(investor == msg.sender,"you are not the investor");
        _;
    }

    function setFounderAndTotalValueForProject(address _founderSmartContractAd, address _founderAd,uint _totalValProject) public{
        Founder f = Founder(_founderSmartContractAd);
        if(f.verifyFounder(_founderAd) == true){
            founder = _founderAd;
            totalValueForProject = _totalValProject;
        }else{
            revert("The address is not one of validators");
        }
        // f.isAddressAndInitialIdMatched(_founderAd,_initialId);
    }

    mapping(address => uint) private founderAndInitialId;
    uint public initialProjectId;
    uint public subsequentProjectId;

    function setInitialId(uint _val) public {
        require(msg.sender == founder,"you are not founder");
        founderAndInitialId[founder] = _val;
        initialProjectId = _val;
    }

    function setSubsequentId(uint _val) public {
        require(msg.sender == founder,"you are not founder");
        founderAndInitialId[founder] = _val;
        subsequentProjectId = _val;
    }


    mapping(uint => address[]) private arrApprovedValidator;
    mapping(uint => address[]) private arrRejectedValidator;


    function Validate(bool _choice, address _ad, address _contractad, uint _subsId, address _foun) public returns (bool voted){

        Factory f = Factory(_contractad);
        bool found = false;
        require(f.checkValidatorIsRegistered(_ad) == true,"The address is not one of validators");
        require(msg.sender == _ad,"The connected wallet is not a validator");
        require(founderAndInitialId[_foun] == _subsId, "The validation is not matched with subsequent id");            
            if(_choice == true){
                arrApprovedValidator[_subsId].push(_ad);
            }                   
            if(_choice == false){
                arrRejectedValidator[_subsId].push(_ad);
            }                       
            if(_choice == false && arrRejectedValidator[_subsId].length > 3){
                proposalCancelledRevertWithdrawlToInvestors = true;
            }
        return found;
	}

    function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
        return whitelistedTokens[token];
    }

    function depositTokens(uint256 amount, bytes32 symbol,address tokenAddress) external {
        if(amount >= totalDepositedStableCoinsInThePot && totalDepositedStableCoinsInThePot >= totalValueForProject){
            revert("The maximum pool limit is reached");
            }
                investor = msg.sender;
                whitelistedTokens[symbol] = tokenAddress;
                accountBalances[msg.sender][symbol] += amount;
                ERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
                viewInvestors[msg.sender] = amount;
                totalDepositedStableCoins[msg.sender] = amount;  

                require(amount == totalValueForProject,"The investing amount is a mismatch");
                uint sendOnly10Percent = amount * 10/100;
                    if(totalDepositedStableCoins[msg.sender] == totalValueForProject){
                        TenPercentBalanceOfStableCoin += sendOnly10Percent;
                    }
                    totalDepositedStableCoinsInThePot += amount;
                    getInvestorsId[msg.sender];
                    totalDepositedStableCoinsInThePot -= sendOnly10Percent;
    }

    function depositFoundersToken(uint256 amount, bytes32 symbol, address tokenAddress) external founderAction{
        whitelistedTokens[symbol] = tokenAddress;
        ERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
        totalFoundersToken[msg.sender] = amount;
        totalDepositedFounderTokenInPot += amount;
        uint sendOnly10Percent = amount * 10/100;
        TenPercentBalanceOfFounderToken += sendOnly10Percent;
        totalDepositedFounderTokenInPot -= sendOnly10Percent;
    }


    function withdrawAllStableCoinFromThePool(uint256 amount, bytes32 symbol, uint _subsId, address _foun) external founderAction returns(bool condition){
        bool status = false;
        require(founderAndInitialId[_foun] == _subsId, "The withdrawl is not matched with subsequent id");
        require(arrApprovedValidator[_subsId].length > 3,"maximum validators has not voted yet");
        if(arrApprovedValidator[_subsId].length > 3){
            status = true;
        }
        if(arrRejectedValidator[_subsId].length > 3){
            revert("validation is rejected");
            status = false;
        }
        totalDepositedStableCoinsInThePot -= amount;
        ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
        return status;
    }

    function withdrawAllFounderTokenFromThePool(uint256 amount, bytes32 symbol, uint _subsId, address _foun) external investorAction returns(bool condition) {
        bool status = false;
        require(founderAndInitialId[_foun] == _subsId, "The withdrawl is not matched with subsequent id");
        require(arrApprovedValidator[_subsId].length > 3,"maximum validators has not voted yet");
        if(arrApprovedValidator[_subsId].length > 3){
            status = true;
        }
        if(arrRejectedValidator[_subsId].length > 3){
            revert("validation is rejected");
            status = false;
        }
        totalDepositedStableCoinsInThePot -= amount;
        ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
        return status;
    }

    function whoApprovedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrApprovedValidator[subs_id];
    }

    function whoRejectedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrRejectedValidator[subs_id];
    }

    function withdrawTokens(uint256 amount, bytes32 symbol, uint _subsId) external investorAction {
        require(accountBalances[msg.sender][symbol] >= amount, "Insufficent funds");
    
        if(proposalCancelledRevertWithdrawlToInvestors == false){
            revert("The invested stable coin is approved and set to get released for founders, cannot withdraw back tokens");      
        }
                
        if(proposalCancelledRevertWithdrawlToInvestors == true){
            if(arrApprovedValidator[_subsId].length > 3){
                revert("The Proposal has been approved and the payment is released for the founders");
            }
            
            if(arrApprovedValidator[_subsId].length < 3 ){
                accountBalances[msg.sender][symbol] -= amount;
                ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
            }
        }
    } 

    function Withdraw10PercentOfStableCoin(bytes32 symbol) public founderAction {
        totalDepositedStableCoinsInThePot -= TenPercentBalanceOfStableCoin;
        ERC20(whitelistedTokens[symbol]).transfer(msg.sender, TenPercentBalanceOfStableCoin);
        TenPercentBalanceOfStableCoin = 0;
    }

    function Withdraw10PercentOfFounderToken(bytes32 symbol) public investorAction {
        totalDepositedFounderTokenInPot -= TenPercentBalanceOfFounderToken;
        ERC20(whitelistedTokens[symbol]).transfer(msg.sender, TenPercentBalanceOfFounderToken);
        TenPercentBalanceOfFounderToken = 0;
    }
}