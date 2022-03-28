// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Token/IRepToken.sol";
import "../Token/RepToken.sol";
import "../Arbitration/Arbitration.sol";
import "../Voting/IVoting.sol";
import "../Project/IDepartment.sol";
import "../Factory/IClientProjectFactory.sol";
import "../Factory/IInternalProjectFactory.sol";
import "../Factory/IdOrgFactory.sol";


/// @title Main DAO contract
/// @author dOrg
/// @dev Experimental status
/// @custom:experimental This is an experimental contract.
contract Source {  // maybe ERC1820
    
    bool public deprecated;
    
    enum MotionType {setDefaultPaymentToken,
                 removePaymentToken,
                 changePaymentInterval,
                 resetPaymentTimer,
                 liquidateInternalProject,
                 migrateDORG,
                 migrateRepToken,
                 changeInitialVotingDuration}
                 
    struct Poll {
        MotionType motionType;
        uint256 index;
        address internalProjectAddress;
    }

    /* ========== CONTRACT VARIABLES ========== */

    IVoting public voting;
    IRepToken public repToken;
    IRepToken public oldRepToken;
    ArbitrationEscrow public arbitrationEscrow;
    IClientProjectFactory public clientProjectFactory;
    IInternalProjectFactory public internalProjectFactory;
    IdOrgFactory public dOrgFactory;

    /* ========== LOCAL VARIABLES ========== */
    
    // maps Motion to Poll
    mapping(uint8 => Poll) public currentPoll;

    uint256 public startPaymentTimer;
    address internal deployer;
    // TODO: SET INITIAL PAYMENT TIMER!!!

    address[] public paymentTokens;
    IERC20 public defaultPaymentToken;
    mapping(address => uint256) public _paymentTokenIndex;
    address[] public clientProjects;
    address[] public internalProjects;
    uint256 public numberOfDepartments;
    uint256 public numberOfProjects;
    mapping(address=>bool) _isProject;

    uint256 public initialVotingDuration = 300; //  change to 300 s for demo; // 1 weeks;
    uint256 public paymentInterval;
    uint120 public defaultPermilleThreshold = 500;  // 50 percent
    uint256 public payoutRep = 100 * (10 ** 18);
    uint40 public defaultVotingDuration = uint40(50);

    /* ========== EVENTS ========== */

    event ProjectCreated(address _project);
    event Refunded(address recipient, uint256 amount, bool successful);
    event Payment(uint256 amount, uint256 repAmount);

    /* ========== CONSTRUCTOR ========== */
    constructor (address votingContract){
        
        repToken = IRepToken(address(new RepToken("DORG", "DORG")));
        voting = IVoting(votingContract);
        // _importMembers(initialMembers, initialRep);
        arbitrationEscrow = new ArbitrationEscrow();

        // // either at construction or after set default paymentToken
        paymentTokens.push(address(0x0));


        startPaymentTimer = block.timestamp;
        deployer = msg.sender;
    }

    function importMembers(address[] memory initialMembers,uint256[] memory initialRep)
    external
    {
        require(msg.sender==deployer, "Only after Deployment");
        _importMembers(initialMembers, initialRep);
    }

    function _importMembers(address[] memory initialMembers,uint256[] memory initialRep) internal{
        // only once!
        require(initialMembers.length==initialRep.length);
        for (uint256 i=0; i< initialMembers.length; i++){
            repToken.mint(initialMembers[i], initialRep[i]);
        }
    }

    function setDeploymentFactories(address _clientProjectFactory, address _internalProjectFactory) external {
        // require(false, " requires DAO VOTE. To be implemented");
        clientProjectFactory = IClientProjectFactory(_clientProjectFactory);
        internalProjectFactory = IInternalProjectFactory(_internalProjectFactory);
    }
    
    
    /* ========== PROJECT HANDLING ========== */


    function createClientProject(address payable _client, address payable _arbiter, address paymentToken)
    public
    isEligibleToken(paymentToken)
     {
        require(!deprecated);
        address projectAddress = clientProjectFactory.createClientProject(
            payable(msg.sender), 
            _client,
            _arbiter,
            address(repToken),
            address(arbitrationEscrow),
            address(voting),
            paymentToken,
            initialVotingDuration
        );
        clientProjects.push(projectAddress);
        _isProject[address(projectAddress)] = true;
        numberOfProjects += 1;
    }


    function createInternalProject(uint256[] memory _requestedAmounts, address[] memory _requestedTokenAddresses) 
    external
    {
        require(!deprecated);
        address projectAddress = internalProjectFactory.createInternalProject(
                                payable(msg.sender),
                                address(voting),
                                initialVotingDuration,
                                paymentInterval,
                                _requestedAmounts,
                                _requestedTokenAddresses);

        internalProjects.push(address(projectAddress));
        _isProject[address(projectAddress)] = true;
        numberOfDepartments += 1;
    }



    /* ========== GOVERNANCE ========== */


    function mintRepTokens(address payee, uint256 amount) external{
        require(_isProject[msg.sender]);
        _mintRepTokens(payee, amount);
    }

    function _mintRepTokens(address receiver, uint256 amount) internal {
        repToken.mint(receiver, amount);
    }

    // change default payment token.
    // add new payment tokens.
    function removePaymentToken(address _erc20TokenAddress) external {
        // TODO: not everyone should be able to call this.
        paymentTokens[_paymentTokenIndex[_erc20TokenAddress]] = address(0x0);
        _paymentTokenIndex[_erc20TokenAddress] = 0;
    }

    function addPaymentToken(address _erc20TokenAddress) external requiredRep() {
        require(_paymentTokenIndex[_erc20TokenAddress] == 0, "already exists");
        paymentTokens.push(_erc20TokenAddress);
        _paymentTokenIndex[_erc20TokenAddress] = paymentTokens.length - 1;
    }

    
    // TODO: Current attack vector with voting is that anyone can trigger a vote anytime
    // and by current design there is only one vote per Motion at any time. So one could 
    // congest the voting service (i.e. denial of service attack).
    // Solution could be to add the index for the particular vote.
    // TODO: Also currently options are encoded by different addresses
    function setDefaultPaymentToken(address _erc20TokenAddress)
    public 
    isEligibleToken(_erc20TokenAddress)
    {
        // DAO Vote: The MotionId is 0
        // address newPaymentTokenAddress = voting.getElected(currentPoll[0].index);
        defaultPaymentToken = IERC20(_erc20TokenAddress);
    }

    function withdrawByProject(uint256 _amount) external onlyProject() {
        // TODO: A bit risky like this. 
        // Or course there is currently no way to trigger this function
        // other than if the payment amount is approved by DAO, but
        // we should make this manifestly secure against malicious changes to the contract.
        defaultPaymentToken.transfer(msg.sender, _amount);
    }

    function transferToken(address _erc20address, address _recipient, uint256 _amount) 
    external 
    onlyProject(){
        //DAO Vote on transfer Token to address
        // isEligibleToken(_erc20address)
        
        IERC20(_erc20address).transfer(_recipient, _amount);
        
    }

    function changeInitialVotingDuration(uint256 _votingDuration)
    external
    onlyTwice {  // FIXME Need to change the modifier!! Or rather adapt the new voting interaction.
        initialVotingDuration = _votingDuration;
        // DAO Vote: The MotionId is 4
        // address unconvertedDuration = voting.getElected(currentPoll[7].index);
        // initialVotingDuration = uint256(uint160(unconvertedDuration));
    }

    function liquidateInternalProject(address _project)
    external 
    voteOnMotion(4, _project){
        // DAO Vote: The MotionId is 4
        IInternalProject(_project).withdraw();
    }

    function changePaymentInterval(uint160 duration)
    external
    voteOnMotion(2, address(duration)){        
        // DAO Vote: The MotionId is 2
        address unconvertedDuration = voting.getElected(currentPoll[2].index);
        paymentInterval = uint256(uint160(unconvertedDuration));
    }

    

    function resetPaymentTimer() 
    external 
    voteOnMotion(3, address(0x0)){        
        // DAO Vote: The MotionId is 3
        startPaymentTimer = block.timestamp;
        // drawback that timer restarts when the majority is reached.
        // which is a little bit unpredictable.
        // But it will start before the end of defaultVotingDuration
    }

    function getStartPaymentTimer() view external returns(uint256) {
        return startPaymentTimer;
    }
    


    // make sure no funds are locked in the departments!
    // TODO!!! Change default at each project.
    function getPollStatus(uint256 pollIndex) external view
    returns(uint8, uint40, uint256, uint256, address)
    {
        return voting.retrieve(pollIndex);
    }


    
    function payout()
    external 
    refundGas()
    {
        
        require(block.timestamp - startPaymentTimer > paymentInterval);
        //TODO: Maybe just those internal projects that are still active
        uint256 totalAmount = 0;
        uint256 totalRep = 0;
        for (uint256 i = 0; i<internalProjects.length; i++){
            // set amounts to zero again.
            (uint256 amount, uint256 repAmount) = IInternalProject(internalProjects[i]).pay();
            totalAmount += amount;
            totalRep += repAmount;
        }
        // TODO!! Start this in constructor
        startPaymentTimer = block.timestamp;

        emit Payment(totalAmount, totalRep);
        // Maybe earn some DORG.
        // TODO: Maybe discuss with feedback
        // _mintRepTokens(msg.sender, payoutRep);

        
    }

    modifier refundGas() {
        uint256 _gasbefore = gasleft();
        _;
        // TODO: How can I not care about the return value something? I think the notaiton  is _, right?
        uint256 refundAmount = (_gasbefore - gasleft()) * tx.gasprice;
        (bool sent, bytes memory something) = payable(msg.sender).call{value: refundAmount}("");
        emit Refunded(msg.sender, refundAmount, sent);
    }

    function _refundGas() internal {
        // require(False)
        // TODO: DOUBLE CHECK THIS REFUND
        if (false){

            uint256 roughGasAmountEstimate = 1000000;
            payable(msg.sender).transfer(roughGasAmountEstimate * tx.gasprice);
        }
    }

    modifier requiredRep() {
        require(repToken.balanceOf(msg.sender)>0, "Caller has no Rep");
        _;
    }

    modifier onlyProject() {
        require(_isProject[msg.sender]);
        _;
    }

    uint8 internal onlyTwoCallsFlag = 0;
    modifier onlyTwice() {
        require(onlyTwoCallsFlag < 2);
        _;
        onlyTwoCallsFlag += 1;
    }

    modifier isEligibleToken(address _tokenAddres){
        require(_paymentTokenIndex[_tokenAddres]>0);
        _;
    }

    modifier voteOnMotion(uint8 _motion, address _address) {
        // Motion motion = Motion.setDefaultPaymentToken;
        // Motion is 0
        require(voting.getStatus(currentPoll[_motion].index) <= uint8(1), "inactive or active");
        if (voting.getStatus(currentPoll[_motion].index) == uint8(0)){
            // TODO!! If one changes the enum in Voting to include other statuses then
            // one should maybe not use the exclusion here.
            // currentPoll[_motion].index = voting.start(uint8(4), uint40(defaultVotingDuration), uint120(defaultPermilleThreshold), uint120(repToken.totalSupply()));
        }

        _;

        // voting.safeVoteReturnStatus(
        //     currentPoll[0].index,
        //     msg.sender,
        //     _address,
        //     uint128(repToken.balanceOf(msg.sender)));

        // if (voting.getStatus(currentPoll[_motion].index) == 2){
        //     _;
        //     // reset status to inactive, so that polls can take place again.
        // }
    }

    /* ========== MIGRATION ========== */

    function migrateDORG()
    external 
    voteOnMotion(5, address(0x0)){ 
        // TODO! MUST BE a lot higher CONDITONS and THRESHOLD!!!
        dOrgFactory.createDORG(address(voting), address(repToken), true);
        deprecated = true;  // cant start new projects
        _refundGas();
    }

    function migrateRepToken(address _newRepToken)
    external
    voteOnMotion(6, address(_newRepToken)){ 
        // TODO! MUST BE a lot higher CONDITONS and THRESHOLD!!!
        // TODO: Check whethe I need to call this via RepToken(address(repToken))
        oldRepToken = repToken;
        repToken = IRepToken(voting.getElected(currentPoll[6].index));
        _refundGas();
    }


    function claimOldRep() external {
        uint256 oldBalance = oldRepToken.balanceOf(msg.sender);
        require(oldBalance>0);
        // transfer and burn
        repToken.mint(msg.sender, oldBalance);
        oldRepToken.burn(msg.sender, oldBalance);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
pragma solidity ^0.8.7;

interface IRepToken {
    function mint(address holder, uint256 amount) external;

    function burn(address holder, uint256 amount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

        /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract RepToken is ERC20 {
    address public source;
    // add top 7 holders only for the case that transfers are disabled

    // mapping(address=>address) holderBelow;
    // address topHolder;
    
    constructor(string memory name, string memory symbol) ERC20 (name, symbol)  {
        // _mint(msg.sender, initialSupply);
        source = msg.sender;
    }



    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override pure {
        require(false, "non-transferrable");
        
    }

    function mint(address holder, uint256 amount) external onlyDAO() {
        _mint(holder, amount);
        // walk up until holderabove has more
        // for (uint256 j=0; j<100; j++){
        //     if (_balances[holder]
        // }
        
    } 

    function burn(address holder, uint256 amount) external onlyDAO() {
        _burn(holder, amount);
    }

    modifier onlyDAO() {
        require(msg.sender==source);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract ArbitrationEscrow {
    mapping(address=>uint256) arbrationFee;  // project address => fee
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IVoting {
    function start(uint8 _votingType, uint40 _deadline, uint120 _threshold, uint120 _totalAmount) external returns(uint256);
    function vote(uint256 poll_id, address votedBy, address votedOn, uint256 amount) external;
    function safeVote(uint256 poll_id, address votedBy, address votedOn, uint128 amount) external;
    function safeVoteReturnStatus(uint256 poll_id, address votedBy, address votedOn, uint128 amount) external returns(uint8);
    function getStatus(uint256 poll_id) external returns(uint8);
    function getElected(uint256 poll_id) view external returns(address);
    function getStatusAndElected(uint256 poll_id) view external returns(uint8, address);
    function stop(uint256 poll_id) external;
    function retrieve(uint256 poll_id) view external returns(uint8, uint40, uint256, uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IInternalProject {
    function pay() external returns(uint256 totalPaymentValue, uint256 totalRepValue);
    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IClientProjectFactory {
    function createClientProject(address payable _souringLead, 
                                 address _client,
                                 address _arbiter,
                                 address _repTokenAddress,
                                 address _arbitrationEscrow,
                                 address _votingAddress,
                                 address _paymentTokenAddress,
                                 uint256 _votingDuration) 
    external
    returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IInternalProjectFactory {
    function createInternalProject(address payable _teamLead,
                                   address _votingAddress,
                                   uint256 _votingDuration,
                                   uint256 _paymentInterval,
                                   uint256[] memory _requestedAmounts,
                                   address[] memory _requestedTokenAddresses) 
    external
    returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IdOrgFactory {
    function createDORG(address votingAddress, address tokenAddress, bool setAsNewMaster) 
    external
    returns(address);

    function getMasterDorg() external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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