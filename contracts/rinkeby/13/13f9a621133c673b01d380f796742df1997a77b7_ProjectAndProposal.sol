/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

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
        require(msg.sender == _ad,"please use the address of connected wallet");
        allValidatorsArray.push(_ad);
        validatorBoolean[_ad] = true;
        _setupRole(VALIDATORS, _ad);
    }

    function returnArray() public view returns(address[] memory){ 
        return allValidatorsArray;
    }

    function checkValidatorIsRegistered(address _ad) public view returns(bool condition){
        if(validatorBoolean[_ad] == true){
            return true;
        }else{
            return false;
        }
    }
}


pragma solidity ^0.8.0;

contract Founder{
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) public view returns(bool condition){
        if(isFounder[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() public view returns(address[] memory){
        return pushFounders;
    }    
}

contract ProjectAndProposal{

    uint private totalValueForProject;               // initial
    uint private totalDepositedStableCoinsInThePot;  // sub
    uint private totalDepositedFounderTokenInPot;    // sub
    uint private TenPercentBalanceOfStableCoin;      // initial
    uint private TenPercentBalanceOfFounderToken;    // initial
    
    address[] private validatorWhoApproved;
    address[] private validatorWhoRejected;
    address[] private allValidators;

    bool private proposalCancelledRevertWithdrawlToInvestors;
  
// MAPPINGS: LINKING ID TO INITIAL AND SUBSEQUENT:
    mapping(address => bool) private whitelistValidators;
    mapping(bytes32 => address) private whitelistedTokens;
    mapping(address => uint) public getInvestorsId;
    mapping(uint => address[]) private arrApprovedValidator;
    mapping(uint => address[]) private arrRejectedValidator;

// MAPPINGS: GETTING THE BALANCE DATA:
    mapping(address => mapping(uint => uint)) public subsequentBalanceOfFounder;
    mapping(address => mapping(uint => uint)) public subsequentBalanceOfInvestor;
    mapping(address => mapping(uint => uint)) public initialBalanceOfInvestor;
    mapping(address => mapping(uint => uint)) public initialBalanceOfFounder;



// MAPPINGS-NEW: GETTING THE BALANCE DATA FOR INITIAL DATA:
    mapping(address => mapping(uint => uint)) public initialNinentyInvestor;
    mapping(address => mapping(uint => uint)) public initialNinentyFounder;



// MAPPINGS: LINKING ID'S TO FOUNDER AND SUBSEQUENT PROPOSALS:
    mapping(uint => mapping(address => address)) public initialfounderId;
    mapping(uint => mapping(address => address)) public subsfounderId;
    mapping(uint => mapping(address => address)) public initialInvestorId;
    mapping(uint => mapping(address => address)) public subsInvestorId;

    mapping(uint => mapping(address => address)) public founderAndInvestorConnection;
    mapping(address => mapping(uint => uint)) public totalValueExpectedRespectiveToFounder;

    function returnFounderAndInvestorConnection(uint _initialId, address _founder, address _investor) public view returns(bool){
        bool status;
        if(founderAndInvestorConnection[_initialId][_founder] == _investor){
            status = true;
            return status;
        }else{
            revert("The connection is mismatch");
        }
    }

// MATCHING FOUNDER AND TOTAL VALUE FOR PROJECT:
    function setFounderAndTotalValueForProject(address _founderSmartContractAd, address _founderAd,uint _totalValProject) public{
        Founder f = Founder(_founderSmartContractAd);
        if(f.verifyFounder(_founderAd) == true){
            totalValueForProject = _totalValProject;
        }else{
            revert("The address is not found amoung the founders");
        }
    }

    mapping(address => uint) private founderAndInitialId;
    mapping(address => uint) private founderAndSubsequentId;
    uint public initialProjectId;
    uint public subsequentProjectId;

    function returnFounderAndInitialId(address _ad, uint _initialId) public view returns(uint){
        require(founderAndInitialId[_ad] == _initialId, "The id is a mismatch");
        return founderAndInitialId[_ad];
    }

// INITIAL ID SETUP:
    function setInitialId(address _founder, uint _initialId) public {
        require(msg.sender == _founder,"The connected wallet is not a founder wallet");
        totalValueExpectedRespectiveToFounder[_founder][_initialId] = totalValueForProject;       
        initialfounderId[_initialId][_founder] = msg.sender;
        founderAndInitialId[_founder] = _initialId;
        initialProjectId = _initialId;
    }

// SUBSEQUENT ID SETUP:
    function setSubsequentId(address _founder, uint _subsVal) public {
        require(msg.sender == _founder,"you are not founder");
        subsfounderId[_subsVal][_founder] = msg.sender;
        founderAndSubsequentId[_founder] = _subsVal;
        subsequentProjectId = _subsVal;
    }

    // function gettotalValueForProjectFounderAndInitialId(address _founder,uint _initialId) public view returns(uint){
    //     return totalProjectValueBasedOnProject[_founder][_initialId];
    // }

    // function getTenPercentBalanceOfStableCoin(uint _initialId) public view returns(uint){
    //     require(founderAndInitialId[founder] == _initialId, "Please check if you are passing the correct initial id");
    //     return initialBalanceOfInvestor[investor][_initialId];
    // }

    // function getTenPercentBalanceOfFounderToken(uint _initialId) public view returns(uint){
    //     require(founderAndInitialId[founder] == _initialId, "Please check if you are passing the correct initial id");
    //     return initialBalanceOfFounder[founder][_initialId];
    // }

    // function gettotalDepositedStableCoinsInPot(uint _subsId) public view returns(uint){
    //     require(founderAndSubsequentId[founder] == _subsId, "The validation is not matched with subsequent id");
    //     return subsequentBalanceOfInvestor[investor][_subsId];
    // }

    // function gettotalDepositedFounderTokenInPot(uint _subsId) public view returns(uint){
    //     require(founderAndSubsequentId[founder] == _subsId, "The validation is not matched with subsequent id");
    //     return subsequentBalanceOfFounder[founder][_subsId];
    // }

    uint[] private withdrawlSetup;
    bool public projectRejectionStatus;

    function getWithdrawlSetup() public view returns(uint[] memory){
        return withdrawlSetup;
    }

    function Validate(bool _choice, address _ad, address _contractad, uint _subsId, address _founder) public returns (bool voted){

        Factory f = Factory(_contractad);
        bool found = false;
        require(f.checkValidatorIsRegistered(_ad) == true,"The address is not one of validators");
        require(msg.sender == _ad,"The connected wallet is not a validator");
            if(founderAndSubsequentId[_founder] == _subsId){
                if(_choice == true){
                    arrApprovedValidator[_subsId].push(_ad);
                    // according to the subsequent id number, the address is stored and validation is done.
                }                   
                if(_choice == false){
                    arrRejectedValidator[_subsId].push(_ad);
                }      
                if(arrRejectedValidator[_subsId].length == 3){
                    withdrawlSetup.push(1);
                }                   
                if(_choice == false && arrRejectedValidator[_subsId].length >= 3){
                    proposalCancelledRevertWithdrawlToInvestors = true;
                }
            }else{
                revert("The founder is not matched with the project id for the validation to start");
            }       
            return found;
	}

    function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
        return whitelistedTokens[token];
    }

    // INVESTOR DEPOSIT:
    function depositStableTokens(address _investor,address _founder, uint256 amount, bytes32 symbol,address tokenAddress, uint _initialId) external {
        require(msg.sender == _investor,"The connected wallet is not matching");           
        require(amount == totalValueExpectedRespectiveToFounder[_founder][_initialId],"The amount is a mismatch or id's are mismatching");
            whitelistedTokens[symbol] = tokenAddress;
            // subsInvestorId[_subsId][_investor] = msg.sender;
            initialInvestorId[_initialId][_investor] = msg.sender;
            ERC20(whitelistedTokens[symbol]).transferFrom(_investor, address(this), amount);
            founderAndInvestorConnection[_initialId][_founder] = _investor;
            initialNinentyInvestor[_investor][_initialId] = amount;
            uint sendOnly10Percent = amount * 10/100;
            initialBalanceOfInvestor[_investor][_initialId] += sendOnly10Percent;
            getInvestorsId[msg.sender];
            initialNinentyInvestor[_investor][_initialId] -= initialBalanceOfInvestor[_investor][_initialId];
            // subsequentBalanceOfInvestor[_investor][_subsId] -= initialBalanceOfInvestor[_investor][_initialId];
    }

    // MULTIPLE INVESTOR DEPOSIT IN THE SMART CONTRACT:

    // mapping(uint => mapping(address => uint)) public multipleInvestorData;

    // function multipleInvestorDepositInSubsequentId(address _investor,address _founder, uint256 amount, bytes32 symbol,address tokenAddress, uint _initialId, uint _subsId) external{
    // require with multiple checks whether the deposited investor address is noted.
    // }

    // FOUNDER DEPOSIT:
    function depositFoundersToken(address _founder, uint256 amount, bytes32 symbol, address tokenAddress, uint _initialId) external {
        require(founderAndInitialId[_founder] == _initialId, "Please check if you are passing the correct initial id");
        whitelistedTokens[symbol] = tokenAddress;
        if(initialfounderId[_initialId][_founder] == msg.sender){
            ERC20(whitelistedTokens[symbol]).transferFrom(_founder, address(this), amount);
            initialNinentyFounder[_founder][_initialId] = amount;
            // subsequentBalanceOfFounder[_founder][_subsId] = amount;
            uint sendOnly10Percent = amount * 10/100;
            initialBalanceOfFounder[_founder][_initialId] += sendOnly10Percent;
            initialNinentyFounder[_founder][_initialId] -= initialBalanceOfFounder[_founder][_initialId];
            // subsequentBalanceOfFounder[_founder][_subsId] -= sendOnly10Percent;
        }       
    }

    // FOUNDER CAN WITHDRAW INVESTOR SUBSEQUENT BALANCE:
    function withdrawAllStableCoinFromThePool(address _founder,address _investor,  uint256 amount, bytes32 symbol, uint _subsId, uint _initialId) external  returns(bool condition){
        bool status = false;
        require(founderAndSubsequentId[_founder] == _subsId, "The withdrawl is not matched with subsequent id");
        require(arrApprovedValidator[_subsId].length >= 3,"maximum validators has not voted yet");
        if(arrApprovedValidator[_subsId].length >= 3){
            status = true;
        }
        if(arrRejectedValidator[_subsId].length >= 3){
            revert("validation is rejected");
        }
        if(subsfounderId[_subsId][_founder] == msg.sender){
            initialNinentyInvestor[_investor][_initialId] = subsequentBalanceOfInvestor[_investor][_subsId];
            subsequentBalanceOfInvestor[_investor][_subsId] -= amount;
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
            return status;
        }        
    }

    // INVESTOR CAN WITHDRAW FOUNDER SUBSEQUENT BALANCE:
    
    // function withdrawAllFounderTokenFromThePool(address _founder, address _investor, uint256 amount, bytes32 symbol, uint _subsId, uint _initialId) external  returns(bool condition) {
    //     bool status = false;
    //     require(arrApprovedValidator[_subsId].length >= 3,"maximum validators has not voted yet");
    //     if(arrApprovedValidator[_subsId].length >= 3){
    //         status = true;
    //     }
    //     if(arrRejectedValidator[_subsId].length >= 3){
    //         revert("validation is rejected");
    //     }
    //     if(subsInvestorId[_subsId][_investor] == msg.sender){
    //         initialNinentyFounder[_founder][_initialId] = subsequentBalanceOfFounder[_founder][_subsId];
    //         subsequentBalanceOfFounder[_founder][_subsId] -= amount;
    //         ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
    //         return status;
    //     }
    // }

    function whoApprovedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrApprovedValidator[subs_id];
    }

    function whoRejectedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrRejectedValidator[subs_id];
    }

    // INVESTOR WITHDRAW TOKENS WHEN 3 SUBSEQUENT PROPOSALS HAVE FAILED
    function withdrawTokens(address _investor, uint256 amount, bytes32 symbol, uint _subsId) external  {
        require(subsInvestorId[_subsId][_investor] == msg.sender,"investor address is mismatch with subsequent id");
        if(withdrawlSetup.length >= 3){
            subsequentBalanceOfInvestor[_investor][_subsId] -= amount;
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
            projectRejectionStatus = true;
        }
    } 

    // FOUNDER WITHDRAW 10% TOKENS:
    function Withdraw10PercentOfStableCoin(address _investor, address _founder, bytes32 symbol, uint _initialId) public  {
        if(initialfounderId[_initialId][_founder] == msg.sender){
            // subsequentBalanceOfInvestor[_investor][_subsId] -= initialBalanceOfInvestor[_investor][_initialId];
            // initialBalanceOfInvestor[_investor][_initialId];
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, initialBalanceOfInvestor[_investor][_initialId]);
            initialBalanceOfInvestor[_investor][_initialId] = 0;
        }else{
            revert("The connected wallet and the project id is mismatch therefore initial withdrawl is suspended");
        }
    }

    // INVESTOR WITHDRAW 10% TOKENS:

    // function Withdraw10PercentOfFounderToken(address _founder, address _investor, bytes32 symbol, uint _initialId) public  {
    //     require(founderAndInvestorConnection[_initialId][_founder] == _investor && _investor == msg.sender, "investor wallet is mismatching with founder project");
    //     if(initialInvestorId[_initialId][_investor] == msg.sender){
    //         // subsequentBalanceOfFounder[_founder][_subsId] -= initialBalanceOfFounder[_founder][_initialId];    
    //         ERC20(whitelistedTokens[symbol]).transfer(msg.sender, initialBalanceOfFounder[_founder][_initialId]);
    //         initialBalanceOfFounder[_founder][_initialId] = 0;
    //     }else{
    //         revert("The connected wallet and the project id is mismatch therefore initial withdrawl is suspended");
    //     }
    // }

    // INVESTOR DEPOSIT ACCORDING TO THE PROJECT ID:
    function DirectDepositTokens(address _investor, uint256 amount, bytes32 symbol, address tokenAddress, uint _subsId) external {
        require(msg.sender == _investor,"The connected wallet is not matching");
        require(subsInvestorId[_subsId][_investor] == msg.sender,"The wallet address and the id of project is not correct");
        whitelistedTokens[symbol] = tokenAddress;
        ERC20(whitelistedTokens[symbol]).transferFrom(_investor, address(this), amount);
        subsequentBalanceOfInvestor[_investor][_subsId] += amount;
    }
}

pragma solidity 0.8.0;

contract Vesting{
    /*
    ------------
    Rules Setup:
    ------------
    1. Founder deposit his token as his wish, record the flow using a 
    nested mapping according to project id.
    Function name is Deposit.

    2. depositFounderToken:

    3. Investor can withdraw tokens according to their initial id 
    that should be linked to the 
    */

    mapping(bytes32 => address) private whitelistedTokens;
    mapping(uint => mapping(address => uint)) public depositsOfFounderTokens;

    function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
        return whitelistedTokens[token];
    }

    function depositFounderToken(uint _amount, address _tokenAddress, bytes32 _symbol, address _founder, address _proposalContractAd, uint _initialId) public {
        uint local;
        ProjectAndProposal pap = ProjectAndProposal(_proposalContractAd);
        local = pap.returnFounderAndInitialId(_founder,_initialId);
        require(msg.sender == _founder,"The connected wallet is not matching");
        require(local == _initialId, "Please check if you are passing the correct initial id");
        whitelistedTokens[_symbol] = _tokenAddress;
        ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
        depositsOfFounderTokens[_initialId][_founder] = _amount;
    }

    function withdrawFounderTokenByInvestor(address _proposalContractAd, address _founder, address _investor, uint256 _amount, bytes32 symbol, uint _initialId) external {
        bool status;
        bool local1;
        ProjectAndProposal pap = ProjectAndProposal(_proposalContractAd);
        status = pap.projectRejectionStatus();
        local1 = pap.returnFounderAndInvestorConnection(_initialId, _founder, _investor);

        require(status == false,"The project has ended and withdrawl of founder token is restricted");
        if(local1 == true){
            depositsOfFounderTokens[_initialId][_founder] -= _amount;
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, _amount);
        }else{
            revert("error in the connection between founder and investor");
        }
    }
}