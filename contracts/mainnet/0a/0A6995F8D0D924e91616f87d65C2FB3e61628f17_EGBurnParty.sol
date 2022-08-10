/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: EGBurnParty.sol


pragma solidity ^0.8.9;





/**
 *  _______  ______      ______  _     _  ______ __   _       _____  _______  ______ _______ __   __
 *  |______ |  ____      |_____] |     | |_____/ | \  |      |_____] |_____| |_____/    |      \_/  
 *  |______ |_____|      |_____] |_____| |    \_ |  \_|      |       |     | |    \_    |       |   
 *                                                                                                  
 */

contract EGBurnParty is Ownable, KeeperCompatibleInterface {

    using Counters for Counters.Counter;

    struct BurnToken {
        uint256 index;
        address token;
        address burnAddress;
        uint256 minStakeAmount;
        uint256 maxStakeAmount;
        bool enabled;
    }

    struct BurnParty {
        uint256 partyId;
        string partyAPI;
        address creator;
        address token;
        uint256 burnDate;
        uint256 period;
        uint256 currentQuantity;
        uint256 requiredQuantity;
        uint256 maxStakeAmount;
        uint256 stakeCounter;
        bool started;
        bool cancelled;
        bool ended;
    }

    struct StakingPeriod{
        uint256 index;
        uint256 period;
        uint256 partyCount;
        uint256 currentPartyIndex;
        bool enabled;
    }

    struct StakeInfo{
        uint256 amount;
        bool unstaked;
    }

    // gas fee to pay LINK to ChainLink for automation of burning
    uint256 public gasFeeAmount;
    
    // `burnTokenCounter` detail: number of burn token
    Counters.Counter public burnTokenCounter;

    // `burnTokens` detail: tokenAddress => token information
    mapping (address => BurnToken) public burnTokens;

    // `burnTokenIndices` detail: token index => token address
    mapping (uint256 => address) public burnTokenIndices;

    
    // `partyCounter` detail: number of parties
    Counters.Counter public partyCounter;
    
    // `burnParties` detail: id => BurnParty
    mapping (uint256 => BurnParty) public burnParties;

    // `Stakes List` detail: Client_Address => Party_Id => Token_Amount
    mapping (address => mapping (uint256 => StakeInfo)) public stakesList;
    
    
    // `periodCounter` detail: number of staking periods
    Counters.Counter public periodCounter;
    
    // `stakingPeriods` detail: period day => staking period
    mapping(uint256 => StakingPeriod) public stakingPeriods;

    // `periodIndexToDay` detail: period index => period day
    mapping(uint256 => uint256) public periodIndices;

    // period => index => party ID
    mapping(uint256 => mapping(uint256 => uint256)) public periodBurnParties;

    event SetMinStakeAmount(address indexed tokenAddress, uint256 minStakeAmount);
    event SetMaxStakeAmount(address indexed tokenAddress, uint256 maxStakeAmount);
    event AddBurnToken(address indexed tokenAddress, address indexed burnAddress, uint256 minStakeAmount, uint256 maxStakeAmount);
    event SetBurnTokenStatus(address indexed tokenAddress, bool status);
    
    event CreateBurnParty(
        uint256 partyId,
        string partyAPI,
        address indexed creator,
        address indexed token, 
        uint256 startDate,
        uint256 period,
        uint256 indexed requiredQuantity, 
        uint256 stakeAmount,
        uint256 realStakeAmount,
        uint256 gasFeeAmount
    );
    event EndBurnParty(uint256 partyId, address indexed caller, address indexed burnToken, uint256 indexed amount, uint256 realAmount, address burnAddress);
    event CancelBurnParty(uint256 partyId, address indexed caller, address indexed burnToken, uint256 indexed amount);
    event AdminCancelBurnParty(uint256 partyId, address indexed caller, address indexed burnToken, uint256 indexed amount);
    event StakeBurnParty(uint256 indexed partyId, address indexed staker, uint256 indexed amount, uint256 realAmount, uint256 gasFeeAmount);
    event UnstakeFromBurnParty(uint256 indexed partyId, address indexed staker, uint256 indexed amount, uint256 realAmount);

    event RemovePeriod(uint256 period);
    event AddPeriod(uint256 period);
    event SetPeriodStatus(uint256 period, bool status);
    
    event SetGasFeeAmount(uint256 feeAmount);
    event WithdrawGasFee(address indexed feeAddress, uint256 amount);

    constructor() {

    }

    /**
    * @param  feeAmount this is amount of fee tokens
    *
    **/
    function setGasFeeAmount(uint256 feeAmount) external onlyOwner {
        require(feeAmount > 0, "EGBurnParty: Fee amount should be positive number");

        gasFeeAmount = feeAmount;

        emit SetGasFeeAmount(feeAmount);
    }

    /**
    * @param  feeAddress address to receive fee
    *
    **/
    function withdrawGasFee(address payable feeAddress) external onlyOwner {
        uint256 balance = address(this).balance;
        require(feeAddress != address(0), "EGBurnParty: The zero address should not be the fee address");
        require(balance > 0, "EGBurnParty: No balance to withdraw");

        (bool success, ) = feeAddress.call{value: balance}("");
        require(success, "EGBurnParty: Withdraw failed");

        emit WithdrawGasFee(feeAddress, balance);
    }
    function existPeriod(uint256 period) public view returns (bool){
        require(period > 0, "EGBurnParty: Period should be a positive number");
        return period == periodIndices[stakingPeriods[period].index];
    }

    /**
    * @param period date 
    *
    **/
    function addPeriod(uint256 period) external onlyOwner {
        require(period > 0, "EGBurnParty: Period should be a positive number");
        require(existPeriod(period) == false, "EGBurnParty: Period has been already added.");
        
        StakingPeriod memory _stakingPeriod = StakingPeriod({
            index: periodCounter.current(),
            period: period,
            partyCount: 0,
            currentPartyIndex: 0,
            enabled: true
        });
        stakingPeriods[period] = _stakingPeriod;
        periodIndices[periodCounter.current()] = period;

        periodCounter.increment();

        emit AddPeriod(period);
    }

    /**
    * @param period date
    *
    **/
    function removePeriod(uint256 period) external onlyOwner {
        require(period > 0, "EGBurnParty: Period should be a positive number");
        require(existPeriod(period) == true, "EGBurnParty: Period is not added.");
        require(stakingPeriods[period].partyCount == stakingPeriods[period].currentPartyIndex, "EGBurnParty: You cannot remove a period that has parties created against it");
        
        uint256 _lastIndex = periodCounter.current() - 1;
        uint256 _currentIndex = stakingPeriods[period].index;

        if(_currentIndex != _lastIndex){
            uint256 _lastPeriod = periodIndices[_lastIndex];
            periodIndices[_currentIndex] = _lastPeriod;
            stakingPeriods[_lastPeriod].index = _currentIndex;
            stakingPeriods[_lastPeriod].period = _lastPeriod;
        }

        delete stakingPeriods[period];
        delete periodIndices[_lastIndex];

        periodCounter.decrement();

        emit RemovePeriod(period);
    }

    /**
    * @param period date
    *
    **/
    function setPeriodStatus(uint256 period, bool status) external onlyOwner {
        require(period > 0, "EGBurnParty: Period should be a positive number");
        require(existPeriod(period) == true, "EGBurnParty: Period is not added.");

        stakingPeriods[period].enabled = status;

        emit SetPeriodStatus(period, status);
    }

    /**
    * method called from offchain - chainlink
    * call performUnkeep with partyId if returns true
    **/
    function checkUpkeep(bytes calldata /*checkData*/) external override view returns (bool, bytes memory) {
        for(uint256 i = 0; i < periodCounter.current(); i ++){
            uint256  _period = periodIndices[i];
            StakingPeriod storage _stakingPeriod = stakingPeriods[_period];
            if(_stakingPeriod.currentPartyIndex < _stakingPeriod.partyCount){
                uint256 _partyId = periodBurnParties[_period][_stakingPeriod.currentPartyIndex];
                if (
                    burnParties[_partyId].started == true && 
                    burnParties[_partyId].ended == false && 
                    block.timestamp >= burnParties[_partyId].burnDate
                )
                {
                    return (true, abi.encode(_partyId));
                }    
            }
        }
        return (false, abi.encode(""));
    }
    
    /**
    * method called from offchain - chainlink
    * call performUnkeep with partyId if returns true
    **/
    function performUpkeep(bytes calldata performData) external override {
        (uint256 partyId) = abi.decode(performData, (uint256));
        BurnParty storage party = burnParties[partyId];
        require(party.started == true, "EGBurnParty: Party has not started.");
        require(party.ended == false, "EGBurnParty: Party has already ended.");
        require(block.timestamp >= party.burnDate, "EGBurnParty: You can cancel a burn party only after burn date.");
        
        if(party.currentQuantity >= party.requiredQuantity)
            endBurnParty(partyId);
        else
            cancelBurnParty(partyId);
    }


    function existBurnToken(address tokenAddress) public view returns (bool){
        require(tokenAddress != address(0), "EGBurnParty: The zero address should not be added as a burn token");

        return tokenAddress == burnTokenIndices[burnTokens[tokenAddress].index];
    }

    /**
    * @param tokenAddress       burn token address
    * @param burnAddress        burning address
    * @param minStakeAmount     init stake amount
    * @param maxStakeAmount     max stake amount
    * @dev  add burn token
    *       fire `AddBurnToken` event
    */
    function addBurnToken(address tokenAddress, address burnAddress, uint256 minStakeAmount, uint256 maxStakeAmount) external onlyOwner {
        require(tokenAddress != address(0), "EGBurnParty: The zero address should not be added as a burn token");
        require(burnAddress != address(0), "EGBurnParty: The zero address should not be added as a burn address");
        require(minStakeAmount > 0, "EGBurnParty: Stake amount should be a positive number.");
        if(maxStakeAmount > 0){ // if zero maxStakeAmount means no limit of transactions
            require(maxStakeAmount >= minStakeAmount, "EGBurnParty: Max stake amount should be zero or bigger than the minimum stake amount.");
        }
        require(existBurnToken(tokenAddress) == false, "EGBurnParty: Token has been already added.");
        
        BurnToken memory burnToken = BurnToken({
            index: burnTokenCounter.current(),
            token: tokenAddress,
            burnAddress: burnAddress,
            minStakeAmount: minStakeAmount,
            maxStakeAmount: maxStakeAmount,
            enabled: true
        });
        burnTokens[tokenAddress] = burnToken;
        burnTokenIndices[burnTokenCounter.current()] = tokenAddress;

        burnTokenCounter.increment();

        emit AddBurnToken(tokenAddress, burnAddress, minStakeAmount, maxStakeAmount);
    }

    /**
    * @param tokenAddress       burn token address
    * @param minStakeAmount    initial stake amount
    * @dev  set the initial stake amount
    *       fire `SetMinStakeAmount` event
    */
    function setMinStakeAmount(address tokenAddress, uint256 minStakeAmount) external onlyOwner {
        require(tokenAddress != address(0), "EGBurnParty: The zero address should not be added as a burn token");
        require(minStakeAmount > 0, "EGBurnParty: Initial stake amount should be a positive number.");
        if(burnTokens[tokenAddress].maxStakeAmount > 0){ // if zero maxStakeAmount means no limit of transactions
            require(minStakeAmount <= burnTokens[tokenAddress].maxStakeAmount, "EGBurnParty: Stake amount should be smaller than the max stake amount.");
        }
        require(existBurnToken(tokenAddress) == true, "EGBurnParty: The token is not added as a burn token.");

        burnTokens[tokenAddress].minStakeAmount = minStakeAmount;

        emit SetMinStakeAmount(tokenAddress, minStakeAmount);
    }

    /**
    * @param tokenAddress       burn token address
    * @param maxStakeAmount     max stake amount
    * @dev  set the max stake amount
    *       fire `SetMaxStakeAmount` event
    */
    function setMaxStakeAmount(address tokenAddress, uint256 maxStakeAmount) external onlyOwner {
        require(tokenAddress != address(0), "EGBurnParty: The zero address should not be added as a burn token");
        if(maxStakeAmount > 0){ // if zero maxStakeAmount means no limit of transactions
            require(maxStakeAmount >= burnTokens[tokenAddress].minStakeAmount, "EGBurnParty: Max stake amount should be zero or bigger than the minimum stake amount.");
        }
        require(existBurnToken(tokenAddress) == true, "EGBurnParty: The token is not added as a burn token.");

        burnTokens[tokenAddress].maxStakeAmount = maxStakeAmount;

        emit SetMaxStakeAmount(tokenAddress, maxStakeAmount);
    }

    /**
    * @param tokenAddress       burn token address
    * @param status    burn token status
    * @dev  enable or disable this burn token
    *       fire `SetMinStakeAmount` event
    */
    function setBurnTokenStatus(address tokenAddress, bool status) external onlyOwner {
        require(tokenAddress != address(0), "EGBurnParty: The zero address should not be added as a burn token");
        require(existBurnToken(tokenAddress) == true, "EGBurnParty: The token is not added as a burn token.");

        burnTokens[tokenAddress].enabled = status;

        emit SetBurnTokenStatus(tokenAddress, status);
    }

    /**
    * @param token burn token
    * @param requiredQuantity minium amount for burnning
    *
    * @dev  create burn party object
    *       insert object into `burnParties`
    *       fire `CreateBurnParty` event
    */
    function createBurnParty(
        string calldata partyAPI,
        address token,
        uint256 period,
        uint256 requiredQuantity,
        uint256 stakeAmount
    )
        external payable
    {
        BurnToken storage _burnToken = burnTokens[token];
         require( bytes(partyAPI).length > 0, 
            "EGBurnParty: Empty string should not be added as a partyAPI");
        require( token != address(0), 
            "EGBurnParty: The zero address should not be a party token");
        require(existBurnToken(token) == true, 
            "EGBurnParty: The token is not added as a burn token.");
        require(_burnToken.enabled == true, 
            "EGBurnParty: The token is not enabled");
        require(period > 0, 
            "EGBurnParty: The period should be a positive number");
        require(existPeriod(period) == true, 
            "EGBurnParty: The period is not added.");
        require(stakingPeriods[period].enabled == true, 
            "EGBurnParty: The period is not enabled.");
        require(requiredQuantity > 0, 
            "EGBurnParty: Required quantity should be a positive number.");
        require(stakeAmount >= _burnToken.minStakeAmount,
            "EGBurnParty: Stake amount should be greater than the min stake amount.");
        if(_burnToken.maxStakeAmount > 0){ // if zero maxStakeAmount means no limit of transactions
            require(requiredQuantity <= _burnToken.maxStakeAmount, 
            "EGBurnParty: Required quantity should be smaller than the max stake amount.");
            require(stakeAmount <= _burnToken.maxStakeAmount,
            "EGBurnParty: Stake amount should be smaller than the max stake amount.");
        }
        require(msg.value >= gasFeeAmount,
            "EGBurnParty: Insufficent value for gas fee");
        require(IERC20(token).balanceOf(msg.sender) >= stakeAmount,
            "EGBurnParty: There is not the enough tokens in your wallet to create burn party.");

        uint256 _beforeBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), stakeAmount);
        uint256 _stakeAmount = IERC20(token).balanceOf(address(this)) - _beforeBalance;

        BurnParty memory party = BurnParty({
            partyId: partyCounter.current(),
            partyAPI: partyAPI,
            creator: msg.sender,
            token: token,
            burnDate: block.timestamp + period * 60,
            period: period,
            currentQuantity: _stakeAmount,
            requiredQuantity: requiredQuantity,
            maxStakeAmount: _burnToken.maxStakeAmount,
            stakeCounter: 1,
            started: true,
            cancelled: false,
            ended: false
        });

        burnParties[partyCounter.current()] = party;
        StakeInfo memory _stakeInfo = StakeInfo({
            amount: _stakeAmount,
            unstaked: false
        });
        stakesList[msg.sender][partyCounter.current()] = _stakeInfo;
        periodBurnParties[period][stakingPeriods[period].partyCount] = partyCounter.current();
        stakingPeriods[period].partyCount ++;
        partyCounter.increment();

        emit CreateBurnParty(
            partyCounter.current() - 1, 
            partyAPI,
            msg.sender,
            token,
            block.timestamp,
            period,
            requiredQuantity, 
            stakeAmount,
            _stakeAmount,
            msg.value
        );
    }

    /**
    * @param partyId burn party id
    * @dev end burn party by id
    *      fire `EndBurnParty` event
    */
    function endBurnParty(uint256 partyId) public {
        BurnParty storage _party = burnParties[partyId];
        require(_party.started == true, "EGBurnParty: Party is not started.");
        require(_party.ended == false, "EGBurnParty: Party has already ended.");
        require(block.timestamp >= _party.burnDate, 
                "EGBurnParty: You can end burn party after burn date.");
        require(IERC20(_party.token).balanceOf(address(this)) >= _party.currentQuantity, 
                "EGBurnParty: Current balance of token is not enough to end the burn party.");
        require(_party.currentQuantity >= _party.requiredQuantity, 
            "EGBurnParty: Tokens currently staked are less than the quantity required for the burn");
        require(partyId == stakingPeriods[_party.period].currentPartyIndex, 
            "EGBurnParty: You need to end the earliest party first");

        _party.ended = true;
        stakingPeriods[_party.period].currentPartyIndex ++;

        uint256 _beforeBalance = IERC20(_party.token).balanceOf(burnTokens[_party.token].burnAddress);
        IERC20(_party.token)
            .transfer(burnTokens[_party.token].burnAddress, _party.currentQuantity);
        uint256 _burnAmount = IERC20(_party.token).balanceOf(burnTokens[_party.token].burnAddress) - _beforeBalance;

        emit EndBurnParty(partyId, msg.sender, _party.token, _party.currentQuantity, _burnAmount, burnTokens[_party.token].burnAddress);
    }

    /**
    * @param partyId burn party id
    * @dev cancel burn party by id
    *      fire `CancelBurnParty` event
    */
    function cancelBurnParty(uint256 partyId) public {
        BurnParty storage _party = burnParties[partyId];
        require(_party.started == true, "EGBurnParty: Party is not started.");
        require(_party.ended == false, "EGBurnParty: Party has already ended.");
        require(block.timestamp >= _party.burnDate, "EGBurnParty: You can cancel a burn party only after burn date.");
        require(_party.currentQuantity < _party.requiredQuantity, 
                "EGBurnParty: You cannot cancel a burn party which has collected the required amount of tokens.");
        require(partyId == stakingPeriods[_party.period].currentPartyIndex, 
            "EGBurnParty: You need to cancel the earliest party first");

        _party.ended = true;
        _party.cancelled = true;

        stakingPeriods[_party.period].currentPartyIndex ++;

        emit CancelBurnParty(partyId, msg.sender, _party.token, _party.currentQuantity);
    }

    /**
    * @param partyId burn party id
    * @dev cancel burn party by id
    *      fire `AdminCancelBurnParty` event
    */
    function adminCancelBurnParty(uint256 partyId) public onlyOwner {
        BurnParty storage _party = burnParties[partyId];
        require(_party.started == true, "EGBurnParty: Party is not started.");
        require(_party.ended == false, "EGBurnParty: Party has already ended.");
        require(block.timestamp >= _party.burnDate, "EGBurnParty: You can cancel a burn party only after burn date.");
        require(partyId == stakingPeriods[_party.period].currentPartyIndex, 
            "EGBurnParty: You need to cancel the earliest party first.");

        _party.ended = true;
        _party.cancelled = true;

        stakingPeriods[_party.period].currentPartyIndex ++;

        emit AdminCancelBurnParty(partyId, msg.sender, _party.token, _party.currentQuantity);
    }

    /**
    * @param partyId burn party id
    * @param tokenAmount stake token amount
    * @dev  fire `StakeBurnParty` event
    */
    function stakeBurnParty(uint256 partyId, uint256 tokenAmount) external payable {
        BurnParty storage _party = burnParties[partyId];
        require(tokenAmount > 0, "EGBurnParty: Amount required to burn should be a positive number.");
        if(_party.maxStakeAmount > 0){ // if zero maxStakeAmount means no limit of transactions
            require(tokenAmount + _party.currentQuantity <= _party.maxStakeAmount, "EGBurnParty: Amount required to burn should be smaller than the available stake amount.");
        }
        require(_party.started == true, "EGBurnParty: Burn Party has not started.");
        require(_party.ended == false, "EGBurnParty: Burn Party has ended.");
        require(msg.value >= gasFeeAmount,
            "EGBurnParty: Not insufficent value for gas fee");
        require(IERC20(_party.token).balanceOf(msg.sender) >= tokenAmount, "EGBurnParty: Your token balance is insufficient for this burn party stake.");

        if(stakesList[msg.sender][partyId].amount == 0){
            _party.stakeCounter ++;
        }

        uint256 _beforeBalance = IERC20(_party.token).balanceOf(address(this));
        IERC20(_party.token).transferFrom(msg.sender, address(this), tokenAmount);
        uint256 _tokenAmount = IERC20(_party.token).balanceOf(address(this)) - _beforeBalance;

        _party.currentQuantity += _tokenAmount;
        stakesList[msg.sender][partyId].amount += _tokenAmount;


        emit StakeBurnParty(partyId, msg.sender, tokenAmount, _tokenAmount, msg.value);
    }

    /**
    * @param partyId burn party id
    * @dev fire `UnstakeFromBurnParty` event
    */
    function unstakeFromBurnParty(uint256 partyId) external {
        BurnParty storage _party = burnParties[partyId];
        StakeInfo storage _stakeInfo = stakesList[msg.sender][partyId];
        require(_stakeInfo.amount > 0, "EGBurnParty: You have not participated in this burn party.");
        require(!_stakeInfo.unstaked, "EGBurnParty: You have already unstaked from this burn party.");
        require( _party.cancelled == true, 
                 "EGBurnParty: You can unstake when the burn party is cancelled or after burn date.");
        require(IERC20(_party.token).balanceOf(address(this)) >= _stakeInfo.amount, 
                "EGBurnParty: Out of balance.");
        
        uint256 _beforeBalance = IERC20(_party.token).balanceOf(msg.sender);
        IERC20(_party.token).transfer(msg.sender, _stakeInfo.amount);
        uint256 _amount = IERC20(_party.token).balanceOf(msg.sender) - _beforeBalance;

        _party.currentQuantity -= _stakeInfo.amount;
        _party.stakeCounter--;
        
        stakesList[msg.sender][partyId].unstaked = true;
        

        emit UnstakeFromBurnParty(partyId, msg.sender, _stakeInfo.amount, _amount);
    }
}