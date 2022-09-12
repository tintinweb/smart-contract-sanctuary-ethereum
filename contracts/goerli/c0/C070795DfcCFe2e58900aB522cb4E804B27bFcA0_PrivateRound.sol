// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FounderLogin{
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add 'Founder address' ");
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

contract InvestorLogin{
    mapping(address => bool) private isInvestor;
    address[] private pushInvestors;

    function addInvestor(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add 'Investor address' ");
        isInvestor[_ad] = true;
        pushInvestors.push(_ad);
    }

    function verifyInvestor(address _ad) public view returns(bool condition){
        if(isInvestor[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllInvestorAddress() public view returns(address[] memory){
        return pushInvestors;
    }
}

contract PrivateRound{

    mapping(address => mapping(uint => MilestoneSetup[])) private _milestone;
    // sets investor address to mileStones created by the founder.
    mapping(address => mapping(uint => address)) private addressIdToAddress;    
    // founder => roundId => investor
    mapping(uint => mapping(uint => address)) public fundsRequested;   
    // round id => funds => investor
    mapping(uint => mapping(address => uint)) public initialPercentage;
    // round id => investor => initialPercentage
    mapping(uint => mapping(address => address)) public tokenExpected;
    // round id => tokenContract => investor
    mapping(uint => mapping(address => address)) public seperateContractLink;
    // round id => founder => uinstance contract address.

    struct MilestoneSetup {
        uint256 _num;
        uint256 _date;
        uint256 _percent;
    }

    address public contractOwner = msg.sender;
    address public tokenContract;
    /*
        * This dynamically changes everytime token address is submitted.
        * Either by Investor or Founder.
    */    

    modifier onlyOwner(){
        require(msg.sender == contractOwner,"Sender is not the owner of this contract");
        _;
    }

    /*
        * WRITE FUNCTIONS:
    */

    mapping(address => MilestoneSetup) public dates;

    function createPrivateRound(address _investor, uint _roundId, address _tokenContract, 
    address _founderSM, address _investorSM, uint _fundRequested, uint _initialPercentage, 
    MilestoneSetup[] memory _mile) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        require(investor.verifyInvestor(_investor) == true, "The address is not registered in the 'InvestorLogin' contract");
        for(uint i = 0; i < _mile.length; ++i){
            _milestone[_investor][_roundId].push(_mile[i]);
            milestoneApprovalStatus[_roundId][_mile[i]._num] = 0;
            milestoneWithdrawalStatus[_roundId][_mile[i]._num] = false;
        }
        addressIdToAddress[msg.sender][_roundId] = _investor;
        fundsRequested[_roundId][_fundRequested] = _investor;
        initialPercentage[_roundId][_investor] = _initialPercentage;
        tokenExpected[_roundId][_tokenContract] = _investor;
    }

    // initial90
    // initial10
    // escrowBalance

    mapping(uint => mapping(address => uint)) public remainingTokensOfInvestor;
    // round id => investor => tokens
    mapping(uint => mapping(address => uint)) public initialTokensForFounder;
    // round id => investor => tokens
    uint public escrowBalance;
    // round id => investor => tokens
    mapping(uint => mapping(address => bool)) private initialWithdrawalStatus;
    mapping(uint => address) private contractAddress;


    function depositTokens(address _tokenContract, address _investorSM, address _founder, uint _tokens, uint _roundId) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        tokenContract = _tokenContract;
        FundLock fl = new FundLock(msg.sender, _roundId, _tokens, address(this));
        seperateContractLink[_roundId][_founder] = address(fl);
        contractAddress[_roundId] = address(fl);
        ERC20(_tokenContract).transferFrom(msg.sender, seperateContractLink[_roundId][_founder], _tokens);
        remainingTokensOfInvestor[_roundId][msg.sender] = _tokens;
        uint tax = _tokens * initialPercentage[_roundId][msg.sender] / 100;
        initialTokensForFounder[_roundId][_founder] += tax;
        remainingTokensOfInvestor[_roundId][msg.sender] -= initialTokensForFounder[_roundId][_founder];
        escrowBalance += remainingTokensOfInvestor[_roundId][msg.sender];
    }

    mapping(address => uint) public taxedTokens;
    // 2% tax should be levied on the each transaction
    function withdrawInitialPercentage(address _tokenContract, address _founderSM, uint _roundId) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        if(initialWithdrawalStatus[_roundId][msg.sender] == true){
            revert("Initial withdrawal is already done");
        }
        FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
        uint tax = 2 * (initialTokensForFounder[_roundId][msg.sender] / 100);
        taxedTokens[_tokenContract] += tax;
        initialTokensForFounder[_roundId][msg.sender] -= tax;
        ERC20(_tokenContract).transferFrom(address(fl), msg.sender, initialTokensForFounder[_roundId][msg.sender]);
        initialWithdrawalStatus[_roundId][msg.sender] = true;
    }

    // mapping(uint => bool) private approval;
    mapping(uint => mapping(uint => uint)) private rejectedByInvestor;
    mapping(uint => bool) private projectCancel;
    // milestone id => founder address => uint
    mapping(uint => mapping(uint => address)) private requestForValidation;
    // round id => founder address => milestone id.
    mapping(uint => mapping(uint => int)) private milestoneApprovalStatus; // 0 - means default null, 1 - means approves, -1 means rejected.
    mapping(uint => mapping(uint => bool)) private milestoneWithdrawalStatus;

    function milestoneValidationRequest(address _founderSM, uint _milestoneId, uint _roundId) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        requestForValidation[_roundId][_milestoneId] = msg.sender;
    }

    function validateMilestone(address _investorSM, uint _milestoneId, uint _roundId, bool _status) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        // whether the milestone id => investor address and milestone mapping, it is already validated or not.
        if(milestoneApprovalStatus[_roundId][_milestoneId] == 1){
            revert("The milestone is already approved");
        }
        if(_status == true){
            milestoneApprovalStatus[_roundId][_milestoneId] = 1;
        }else if(_status == false){
            rejectedByInvestor[_roundId][_milestoneId] += 1;
            milestoneApprovalStatus[_roundId][_milestoneId] = -1;
        }
        if(rejectedByInvestor[_roundId][_milestoneId] >= 3){
            projectCancel[_roundId] = true;
        }
    }

    // mapping(uint => mapping(address => uint))releasedTokenToFounder;
    bool private defaultedByFounder;
    mapping(uint => mapping(uint => bool)) private milestoneStatus;

    mapping(uint => mapping(address => uint)) private unlockedRead;
    mapping(uint => mapping(address => uint)) private lockedRead;
    mapping(uint => mapping(address => uint)) private withdrawnByFounder;

    function withdrawMilestoneTokens(address _founderSM, address _investor, uint _roundId, address _tokenContract) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        uint unlockedAmount = 0;
        uint localPercent;
        for(uint i = 0; i < _milestone[_investor][_roundId].length; i++){
            if(milestoneApprovalStatus[_roundId][_milestone[_investor][_roundId][i]._num] == 1 && milestoneWithdrawalStatus[_roundId][_milestone[_investor][_roundId][i]._num] == false){
                localPercent = remainingTokensOfInvestor[_roundId][_investor] * (_milestone[_investor][_roundId][i]._percent / 100);
                unlockedAmount += localPercent;
                milestoneWithdrawalStatus[_roundId][_milestone[_investor][_roundId][i]._num] = true;
                remainingTokensOfInvestor[_roundId][_investor] -= unlockedAmount;
            }
        }
        if(unlockedAmount > 0){
            unlockedRead[_roundId][msg.sender] += unlockedAmount;
            uint tax = 2 * (unlockedAmount / 100);
            taxedTokens[_tokenContract] += tax;
            escrowBalance -= unlockedAmount;
            unlockedAmount -= tax;
            // releasedTokenToFounder[_roundId][msg.sender] += unlockedAmount;
            FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
            ERC20(_tokenContract).transferFrom(address(fl), msg.sender, unlockedAmount);
            withdrawnByFounder[_roundId][msg.sender] += unlockedAmount;
        }else{
            revert("No unlocked tokesn to withdraw");
        } 
    }

    function withdrawByInvestors(address _investorSM, uint _roundId, address _founder, address _tokenContract) public{
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        uint count = 0;
        for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
            if(block.timestamp > _milestone[msg.sender][_roundId][i]._date && requestForValidation[_roundId][_milestone[msg.sender][_roundId][i]._num] != _founder){
                count += 1;
            }
        }
        if(projectCancel[_roundId] == true || count >= 2){
            defaultedByFounder = true;
            // revert("The Founder has failed to request for validation for atleast two milestones or maximum milestone updation has exceeded");
        }
        uint localPercent;
        uint lockedAmount = 0;
        if(defaultedByFounder == true){
            for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
                if(milestoneApprovalStatus[_roundId][_milestone[msg.sender][_roundId][i]._num] != 1){
                    localPercent = remainingTokensOfInvestor[_roundId][msg.sender] * (_milestone[msg.sender][_roundId][i]._percent / 100);
                    lockedAmount += localPercent;
                    remainingTokensOfInvestor[_roundId][msg.sender] -= lockedAmount;
                }
            }
            lockedRead[_roundId][msg.sender] += lockedAmount;
            FundLock fl = FundLock(seperateContractLink[_roundId][_founder]);
            escrowBalance -= lockedAmount;
            uint tax = 2 * (lockedAmount / 100);
            taxedTokens[_tokenContract] += tax;
            lockedAmount -= tax;
            ERC20(_tokenContract).transferFrom(address(fl), msg.sender, lockedAmount);  
        }
    }

    // All the taxed tokens are there in the contract itself. no instance is created
    function withdrawTaxTokens(address _tokenContract) public onlyOwner {
        require(msg.sender != address(0), "Invalid address");
        ERC20(_tokenContract).transfer(msg.sender,  taxedTokens[_tokenContract]);
        taxedTokens[_tokenContract] = 0;
    }   

    /*
        * READ FUNCTIONS:
    */

    function milestoneDetails(address _investor, uint _roundId) public view returns(MilestoneSetup[] memory){
        return _milestone[_investor][_roundId];
    }

    function getMilestonesDetails(address _investor, uint _roundId) public view returns(MilestoneSetup[] memory){
        return _milestone[_investor][_roundId];
    }

    function getContractAddress(uint _roundId) public view returns(address smartContractAddress){
        return contractAddress[_roundId];
    }

    function projectStatus(uint _roundId) public view returns(bool projectLiveOrNot){
        return projectCancel[_roundId];
    }

    function tokenStatus(uint _roundId, address _founder, address _investor) public view returns(uint unlockedAmount, uint lockedAmount, uint withdrawnTokensByFounder){
        return(
            unlockedRead[_roundId][_founder],
            lockedRead[_roundId][_investor],
            withdrawnByFounder[_roundId][_founder]
        );
    }

    function initialWithdrawStatus(uint _roundId) public view returns(bool initialWithdraw){
        return initialWithdrawalStatus[_roundId][msg.sender];
    }

    function availableTaxTokens(address _tokenContract) public view returns(uint taxTokens){
        return taxedTokens[_tokenContract];
    }

    function contractBalance() public view returns(uint escrowBal){
        return escrowBalance;
    }

    function defaultedToWithdrawMilestoneTokens() public view returns(bool){
        return defaultedByFounder;
    }
}

contract FundLock{
    address public _contractOwner;
    mapping(uint => mapping(address => uint)) public _amount;

    constructor (address investor, uint roundId, uint amount, address privateRoundContractAd) {
        _contractOwner = msg.sender;
        _amount[roundId][investor] = amount;
        ERC20(PrivateRound(privateRoundContractAd).tokenContract()).approve(privateRoundContractAd,amount);
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