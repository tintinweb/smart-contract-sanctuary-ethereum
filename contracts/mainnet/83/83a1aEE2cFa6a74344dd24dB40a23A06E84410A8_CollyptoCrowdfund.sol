// SPDX-License-Identifier: copyleft-next-0.3.1
// CollyptoCrowdfund Contract v1.0.0
pragma solidity ^0.8.17 < 0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Collypto Crowdfund
 * @author Matthew McKnight - Collypto Technologies, Inc.
 * @notice This contract is the crowdfunding platform allowing up to 10,000
 * users to reserve Founder Medallions and pre-order Collypto Credits.
 */
contract CollyptoCrowdfund {    
    /**
     * @dev Numeric value indicating the maximum number of Founder Medallions
     * that may be reserved by users during the crowdfunding campaign
     */
    uint256 private _maxMedallions;

    /**
     * @dev Constant indicating the minimum amount of USDC tokens that must be
     * deposited in order to reserve a Founder Medallion.
     */
    uint256 private constant MIN_USDC_DEPOSIT = 100*(10**6);

    /// @dev Ethereum address of the creator account
    address private _creatorAddress;

    /// @dev Reference instance of the Collypto contract
    IERC20 private collypto;

    /// @dev Reference instance of the USDC contract
    IERC20 private usdc;

    /**
     * @dev Mapping of all deposited USDC balances (indexed by account address)
     */
    mapping(address => uint256) private _deposits;

    /**
     * @dev Mapping of all user accounts that have reserved a medallion
     * (indexed by account address)
     */
    mapping(address => bool) private _medallions;

    /**
     * @dev Mapping of user withdrawal statuses (indexed by account address)
     */
    mapping(address => bool) private _hasWithdrawn;

    /**
     * @dev Total amount of medallions that have been reserved by users
     */
    uint256 private _medallionsReserved;

    /**
     * @dev Boolean value representing whether the crowdfunding campaign has
     * started (defaults to "false")
     */
    bool private _campaignStarted;

    /**
     * @dev Boolean value representing whether the crowdfunding campaign has
     * ended (defaults to "false")
     */
    bool private _campaignEnded;

    /**
     * @dev Boolean value representing whether the crowdfunding campaign has
     * been cancelled by the creator (defaults to "false")
     */
    bool private _campaignCancelled;

    /// @dev Running state of this contract (defaults to "false")
    bool private _isRunning;    

    /**
     * @dev Event emitted when the campaign begins
     */   
    event CampaignStarted();

    /**
     * @dev Event emitted when the campaign ends
     */   
    event CampaignEnded();

    /**
     * @dev Event emitted if the campaign is cancelled by the creator
     */   
    event CampaignCancelled();

    /**
     * @dev Event emitted when `amount` USDC tokens are deposited by `owner`
     */
    event Deposit(address indexed owner, uint256 amount);

    /**
     * @dev Event emitted when `amount` CPTO slivers or USDC tokens are
     * withdrawn by `owner`
     */
    event Withdraw(address indexed owner, uint256 amount);

    /**
     * @dev Event emitted when a Founder Medallion has been reserved by `owner`
     * following their first USDC deposit
     */
    event MedallionReserved(address indexed owner);

    /// @dev Event emitted when this contract is paused
    event Pause();

    /// @dev Event emitted when this contract is unpaused
    event Unpause();    
    
    /**
     * @dev Modifier that determines if this contract is currently running and
     * reverts on "false"
     */       
    modifier isRunning {
        // This contract must be running
        require(
            _isRunning,
            "Collypto Crowdfund is not accepting transactions at this time"
        );
        _;
    }

    /**
     * @dev Modifier that determines if an address belongs to the creator
     * account and reverts on "false"
     */    
    modifier onlyCreator {
        // Operator address must match the address of the creator account
        require(msg.sender == _creatorAddress);
        _;
    }

    /**
     * @notice Initializes this contract, sets the reference contract
     * addresses, specifies the maximum amount of medallions that may be
     * reserved, and defines the creator as the address of the calling operator
     * @param cptoAddress The reference address of the Collypto contract
     * @param usdcAddress The reference address of the USDC contract
     * @param maxMedallions The maximum number of Founder Medallions that may
     * be reserved during the crowdfunding campaign
     */
    constructor(
        address cptoAddress,
        address usdcAddress,
        uint256 maxMedallions
    ) {
       collypto = IERC20(cptoAddress);
       usdc = IERC20(usdcAddress);
       _maxMedallions = maxMedallions;
       _creatorAddress = msg.sender;       
       _medallionsReserved = 0;
       _isRunning = true;
    }

    /**
     * @notice Returns the total number of Founder Medallions that have been
     * reserved by users
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return medallions The total number of Founder Medallions that have been
     * reserved by users
     */
    function medallionsReserved() public view returns (uint256 medallions) {
        return _medallionsReserved;
    }

    /**
     * @notice Returns the total number of Founder Medallions that are
     * available to be reserved
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return medallions The remaining number of Founder Medallions that are
     * available
     */
    function medallionsAvailable() public view returns (uint256 medallions) {
        return _maxMedallions - _medallionsReserved;
    }    

    /**
     * @notice Returns a Boolean value indicating that the user with Ethereum
     * account at `owner` has reserved a Founder Medallion
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return reserved A Boolean value indicating that the user has reserved a
     * Founder Medallion
     */
    function reservedMedallion(address owner)
        public 
        view 
        returns (bool reserved)
    {
        return _medallions[owner];
    }
    
    /**
     * @notice Returns a numeric value representing the total amount of USDC
     * tokens deposited by the user with Ethereum account at `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return deposit A numeric value representing the total amount of USDC
     * tokens deposited by the {owner} account
     */
    function depositAmount(address owner)
        public 
        view 
        returns (uint256 deposit)
    {
        return _deposits[owner];
    }
    
    /**
     * @notice Returns a Boolean value indicating that the user with Ethereum
     * account at `owner` has already withdrawn their credits or USDC tokens
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return withdrawn A Boolean value indicating that credits or USDC tokens
     * have already been withdrawn from the campaign by the {owner} account
     */
    function hasWithdrawn(address owner)
        public 
        view 
        returns (bool withdrawn)
    {
        return _hasWithdrawn[owner];
    }    

    /**
     * @notice Returns a Boolean value indicating whether the campaign has
     * started
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return started A Boolean value indicating whether the campaign has
     * started
     */
    function campaignStarted() public view returns (bool started) {
        return _campaignStarted;
    }

    /**
     * @notice Returns a Boolean value indicating whether the campaign has
     * ended
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return ended A Boolean value indicating whether the campaign has
     * ended
     */
    function campaignEnded() public view returns (bool ended) {
        return _campaignEnded;
    }

    /**
     * @notice Returns a Boolean value indicating whether the campaign has
     * been cancelled
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return cancelled A Boolean value indicating whether the campaign has
     * been cancelled
     */
    function campaignCancelled() public view returns (bool cancelled) {
        return _campaignCancelled;
    }

    /**
     * @notice Returns a Boolean value indicating whether this contract is
     * currently paused
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return paused A Boolean value indicating whether this contract is
     * currently paused
     */
    function isPaused() public view returns (bool paused) {
        return !_isRunning;
    }    

    /**
     * @notice Begins the campaign and allows users to deposit USDC for
     * Founder Medallion reservations and Collypto Credit pre-orders
     * @dev This is a privileged function and can only be conducted if
     * the campaign has not already started, ended, or been cancelled.
     * @return success A Boolean value indicating that the campaign has started
     * successfully
     */
    function startCampaign() public onlyCreator returns (bool success) {
        require(!_campaignStarted && !_campaignEnded && !_campaignCancelled);

        _campaignStarted = true;

        emit CampaignStarted();

        return true;
    }

    /**
     * @notice Ends the campaign and allows users to withdraw credits
     * @dev This is a privileged function and can only be conducted if
     * the campaign has already started and has not ended or been cancelled.
     * @return success A Boolean value indicating that the campaign has ended
     * successfully
     */
    function endCampaign() public onlyCreator returns (bool success) {
        require(_campaignStarted && !_campaignEnded && !_campaignCancelled);

        _campaignEnded = true;

        // Withdraw deposited USDC
        usdc.transfer(
            _creatorAddress,
            usdc.balanceOf(address(this))
        );

        emit CampaignEnded();

        return true;
    }

    /**
     * @notice Cancels the campaign and allows users to withdraw any deposited
     * USDC tokens
     * @dev This is a privileged function and can only be conducted if
     * the campaign has started and has not ended or already been cancelled.
     * @return success A Boolean value indicating that the campaign has been
     * cancelled successfully
     */
    function cancelCampaign() public onlyCreator returns (bool success) {
        require(_campaignStarted && !_campaignEnded && !_campaignCancelled);

        _campaignCancelled = true;

        emit CampaignCancelled();

        return true;
    }

    /**
     * @notice Pauses this contract, blocking all public user operations
     * until this contract is resumed
     * @dev This is a privileged function and can be conducted only when this
     * contract is running.
     * @return success A Boolean value indicating that this contract has been
     * successfully paused
     */
    function pause() public onlyCreator returns (bool success) {
        // This contract must be running to continue
        require(_isRunning);

        _isRunning = false;

        emit Pause();

        return true;
    }

    /**
     * @notice Unpauses this contract, unblocking all public user operations
     * @dev This is a privileged function and can be conducted only when this
     * contract is not running.   
     * @return success A Boolean value indicating that this contract has been
     * successfully unpaused
     */
    function unpause() public onlyCreator returns (bool success) {
        // This contract must be paused to continue
        require(!_isRunning);        
        
        _isRunning = true;
        
        emit Unpause();

        return true;
    }

    /**
     * @notice Deposits `amount` of USDC tokens to be applied toward Founder
     * Medallion reservation and Collypto Credit pre-orders
     * @dev This function can only be conducted if the campaign has started.     
     * @return success A Boolean value indicating that the deposit was
     * successful
     */
    function depositUSDC(uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        require(_campaignStarted && !_campaignEnded && !_campaignCancelled);

        address operator = msg.sender;

        bool firstDeposit = !reservedMedallion(operator);

        require(
            (medallionsAvailable() > 0) || !firstDeposit,
            "There are no more Founder Medallions available for reservation."    
        );

        require(
            (amount >= MIN_USDC_DEPOSIT) || !firstDeposit,
            "Your initial deposit must be a minimum of $100 in USDC."
        );

        // Update deposited balance
        _deposits[operator] += amount;

        // Issue medallion if this is the initial deposit
        if(firstDeposit) {
            _medallionsReserved++;
            _medallions[operator] = true;
        }

        usdc.transferFrom(operator, address(this), amount);

        if(firstDeposit) {
            emit MedallionReserved(operator);
        }

        emit Deposit(operator, amount);

        return true;
    }

    /**
     * @notice Withdraws all USDC tokens deposited by the operator account
     * @dev This function can only be conducted if the campaign has been
     * cancelled.
     * @return success A Boolean value indicating that the withdrawal was
     * successful
     */
    function withdrawUSDC() public isRunning returns (bool success) {
        address operator = msg.sender;
        require(_campaignCancelled && reservedMedallion(operator));       
        require(
            !_hasWithdrawn[operator],
            "You have already withdrawn your USDC "
            "from the Collypto Crowdfund Campaign."    
        );

        _hasWithdrawn[operator] = true;
        
        uint256 usdcTokens = _deposits[operator];

        usdc.transfer(operator, usdcTokens);

        emit Withdraw(operator, usdcTokens);

        return true;
    }   

    /**
     * @notice Withdraws CPTO tokens commensurate to the operator's total USDC
     * token deposits minus the fee for their medallion certification
     * @dev This function can only be conducted if the campaign has ended.
     * @return success A Boolean value indicating that the withdrawal was
     * successful
     */
    function withdrawCPTO() public isRunning returns (bool success) {
        address operator = msg.sender;
        require(_campaignEnded && reservedMedallion(operator));
        require(
            !_hasWithdrawn[operator],
            "You have already withdrawn your credits "
            "from the Collypto Crowdfund Campaign."
        );

        _hasWithdrawn[operator] = true;
        
        // Convert USDC to slivers minus the medallion reservation fee
        uint256 slivers = 2*(10**10)*(_deposits[operator] - 50*(10**6));

        collypto.transfer(operator, slivers);

        emit Withdraw(operator, slivers);

        return true;
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