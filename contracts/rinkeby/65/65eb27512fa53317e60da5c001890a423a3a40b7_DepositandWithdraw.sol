/**
 *Submitted for verification at Etherscan.io on 2022-05-24
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

// The Escrow Smart contract starts from here.
/*
    1. While depositing Founder tokens to this smart contract, make sure after transfering tokens.
    2. The recipient has to import initial token contract address to his wallet to check the balance of founder token

*/

pragma solidity ^0.8.0;

contract Project{
    address[] public FounderAddress;
    string[] public FounderName;
    string[] public ProposalDetails;
    uint FounderAddressCount;
    address public SuperAdmin;
    address public Founder;
    address public contractDeployer = msg.sender;
    uint public totalValueForProject;
    uint public FounderProposalIdData;

    modifier contractDeployerAccess(){
        require(contractDeployer == msg.sender,"Your address does not match with contract deployer address");
        _;
    }

    function setFounderAndSuperAdmin(address _founder, address _superAdmin, uint _totalValProject) public contractDeployerAccess{
        Founder = _founder;
        SuperAdmin = _superAdmin;
        totalValueForProject = _totalValProject;
    }

    modifier onlySuperAdminAccess(){
        require(SuperAdmin == msg.sender,"You are not the SuperAdmin");
        _;
    }

     modifier onlyFounderAccess(){
        require(Founder == msg.sender,"You are not the Founder");
        _;
    }
    
    function addFounderAndProposal(address _ad, string memory _name, string memory _proposal, uint _proposalId) public contractDeployerAccess{
        FounderAddress.push(_ad);
        FounderName.push(_name);
        FounderProposalIdData = _proposalId;
        ProposalDetails.push(_proposal);
        // FounderAddressCount++;
        // if(FounderAddressCount > 5){
        //     revert("Only 5 Validators can be added by the superAdmin");
        // }
    }
  
}

pragma solidity ^0.8.0;

contract DepositandWithdraw is Project{ 

    Project p = new Project();

    struct vote{
        address voterAddress;
        bool choice;
    }

    struct voter{
        string voterName;
        bool voted;
    }

    uint private countResult = 0;
    uint public totalValidators = 0;
    uint public totalDepositedStableCoinsInThePot;
    uint public totalDepositedFounderTokenInPot;
    uint public TotalValueAllocatedForTheProposalContract = totalValueForProject;
    uint public singleUserHugeDeposit;

    string public ballotOfficialName;
    string public proposal;
    string public founderName;
    uint256 public founderProposalId;

    address[] public validatorWhoApproved;
    address[] public validatorWhoRejected;
    address[] public allInvestors;
    address[] public allValidators;
    address[] public viewAllInvestorAddress;
    address owner;
    address founderAddress;
    address superAdminAddress;
    address contractDeployerAddress = msg.sender;

    // bool private forVali;
    bool private proposalCancelledRevertWithdrawlToInvestors;
  
    mapping(address => bool) private whitelistValidators;
    mapping(address => uint) public totalDepositedStableCoins;
    mapping(address => uint) public totalFoundersToken;
    mapping(address => uint) private viewInvestors;
    mapping(uint => vote) private votes;
    mapping(address => voter) public voterRegister;
    mapping(bytes32 => address) public whitelistedTokens;
    mapping(address => mapping(bytes32 => uint256)) public accountBalances;

    enum State{ Created, HugeDepositor, DepositorAmtReleased }

    State public state; 

	modifier condition(bool _condition){
		require(_condition);
		_;
	}

	modifier onlySuperAdmin(){
		require(SuperAdmin == msg.sender, "You are not the SuperAdmin");
		_;
	}

	modifier inState(State _state){
		require(state == _state);
		_;
	}

    modifier onlyWhitelist {
        require(whitelistValidators[msg.sender], "You are not whitelisted.");
        _;
    }

    modifier FounderOnlyWithdraw {
        require(Founder == msg.sender, "You are not the Founder");
        _;
    }


	// constructor(
	// 	string memory _proposal, uint valueAllocated, address _setFounder, address _superAdmin
	// 	){
    //     owner = msg.sender;
	// 	SuperAdmin = _superAdmin;
	// 	proposal = _proposal;
	// 	state = State.Created;
    //     TotalValueAllocatedForTheProposalContract = valueAllocated;
    //     Founder = _setFounder;
    // }
    
    // function getFounderAndSuperAdminAddress(address _ad, address _ad1, ) public{
    //     p._setFounderAndSuperAdmin(_ad,_ad1);
    //     founderAddress = _ad;
    //     superAdminAddress = _ad1;
    // }

    function founderAndProposalVerification(uint _proposalid) public contractDeployerAccess returns(string memory id){
        founderProposalId = _proposalid;
        if(FounderProposalIdData == founderProposalId){
            return "The id is a match";
        }else{
            revert("The id has not matched with the data");
        }
    }

	function addValidators(address _voterAddress, string memory _voterOfficialName) public  onlySuperAdminAccess{
		voter memory v;
		v.voterName = _voterOfficialName;	
		v.voted = false;
		voterRegister[_voterAddress] = v;
        totalValidators++;
        allValidators.push(_voterAddress);
        if(totalValidators > 5){
            revert("Maximum number of validators has been reached for the proposal");
        }
        whitelistValidators[_voterAddress] = true; 
	}

	function Validate(bool _choice) public onlyWhitelist returns (bool voted){
		    bool found = false;
            if(bytes(voterRegister[msg.sender].voterName).length != 0 && !voterRegister[msg.sender].voted){
			    voterRegister[msg.sender].voted = true;
			    vote memory v;
			    v.voterAddress = msg.sender;
			    v.choice = _choice;
			        if(_choice){
				        countResult++;
			        }
			    found = true;	
		    }	
                            
            if(_choice == true){
                validatorWhoApproved.push(msg.sender);
            }
                                
            if(_choice == false){
                validatorWhoRejected.push(msg.sender);
            }
                                    
            if(_choice == false && validatorWhoRejected.length > 3){
                proposalCancelledRevertWithdrawlToInvestors = true;
            }
		    return found;
	}

    function whitelistToken(bytes32 symbol, address tokenAddress) external {
        require(msg.sender == owner, 'This function is not public');
        whitelistedTokens[symbol] = tokenAddress;
    }

    function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
        return whitelistedTokens[token];
    }

    function depositTokens(uint256 amount, bytes32 symbol) inState(State.Created) external {
        if(amount >= totalDepositedStableCoinsInThePot && totalDepositedStableCoinsInThePot >= TotalValueAllocatedForTheProposalContract){
            revert("The maximum pool limit is reached");
            }
                accountBalances[msg.sender][symbol] += amount;
                ERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
                viewInvestors[msg.sender] = amount;
                totalDepositedStableCoins[msg.sender] = amount;
                totalFoundersToken[msg.sender] = amount;
                totalDepositedFounderTokenInPot += amount;

                uint hugeDeposit = TotalValueAllocatedForTheProposalContract * 80/100;
                    if(totalDepositedStableCoins[msg.sender] > hugeDeposit){
                        uint sendOnly10Percent = amount * 10/100;
                        singleUserHugeDeposit += sendOnly10Percent;
                        state = State.HugeDepositor;
                    }           
                    allInvestors.push(msg.sender);
                    totalDepositedStableCoinsInThePot += amount;
    }

    function depositFoundersToken(uint256 amount, bytes32 symbol) external onlyFounderAccess{
        ERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
        totalFoundersToken[msg.sender] = amount;
        totalDepositedFounderTokenInPot += amount;
    }

    function transferFounderTokenToInvestors(uint256 amount,address _investor, bytes32 symbol) onlyFounderAccess external{
        totalDepositedFounderTokenInPot -= amount;
        ERC20(whitelistedTokens[symbol]).transfer(_investor, amount);
    }

    function withdrawAllTokenFromThePool(uint256 amount, uint _i, bytes32 symbol) onlyFounderAccess external {
        require(validatorWhoApproved.length >= 3 && validatorWhoApproved[_i] != address(0),"the validation has not exceeded 3 or the one of the address is 0 address");
        totalDepositedStableCoinsInThePot -= amount;
        ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
    }

    function withdrawTokens(uint256 amount, bytes32 symbol) external {
        require(accountBalances[msg.sender][symbol] >= amount, "Insufficent funds");
    
        if(proposalCancelledRevertWithdrawlToInvestors == false){
            revert("The invested stable coin is approved and set to get released for founders, cannot withdraw back tokens");      
        }
                
        if(proposalCancelledRevertWithdrawlToInvestors == true){
            if(validatorWhoApproved.length > 3){
                revert("The Proposal has been approved and the payment is released for the founders");
            }
            
            if(validatorWhoApproved.length < 3 ){
                accountBalances[msg.sender][symbol] -= amount;
                ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
            }
        }
    }

    function Withdraw10PercentOfSingleTokenDeposit(bytes32 symbol) inState(State.HugeDepositor) onlyFounderAccess public{
        totalDepositedStableCoinsInThePot -= singleUserHugeDeposit;
        ERC20(whitelistedTokens[symbol]).transfer(msg.sender, singleUserHugeDeposit);
        state = State.DepositorAmtReleased; 
    }

    function SuperAdminDecision(uint i, address _ap, bool _choice) public onlySuperAdminAccess {
        if(validatorWhoApproved[i] == _ap && _choice == false){    
            validatorWhoRejected.push(_ap);
            delete validatorWhoApproved[i];
        }

        if(validatorWhoRejected[i] == _ap && _choice == true){
            validatorWhoApproved.push(_ap);
            delete validatorWhoRejected[i];
        }
    }

    function DirectDepositTokens(uint256 amount, bytes32 symbol) external {
        accountBalances[msg.sender][symbol] += amount;
        ERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
        viewInvestors[msg.sender] = amount;
        totalDepositedStableCoins[msg.sender] = amount;
        allInvestors.push(msg.sender);
        totalDepositedStableCoinsInThePot += amount;
    }
}