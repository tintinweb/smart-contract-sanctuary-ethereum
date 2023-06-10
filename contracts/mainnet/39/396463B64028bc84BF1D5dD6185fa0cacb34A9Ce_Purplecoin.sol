pragma solidity ^0.4.24;

/// @custom:security-contact [email protected]

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import './MathHelp.sol';
import "./Ownable.sol";

contract Purplecoin is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    constructor() public ERC20Detailed("Purplecoin", "XPU", 18) {}

    /**
     * Event for burning tokens
     * @param burner The address burning the tokens
     * @param value amount of tokens burnt
     * @param message burn additional data
     */
    event TokenBurn(
        address burner,
        uint256 value,
        string message
    );

    /**
     * @dev Burn tokens with message. Used to transfer coins to the main chain when message is a Purplecoin address.
     * @param value amount of tokens to be burnt
     * @param message additional data
     */
    function burn(uint256 value, string message) public {
        super.burn(value);
        emit TokenBurn(msg.sender, value, message);
    }

    /**
     * @dev Burn tokens from address with message. Used to transfer coins to the main chain when message is a Purplecoin address.
     * @param account account to burn tokens from
     * @param value amount of tokens to be burnt
     * @param message additional data
     */
    function burnFrom(address account, uint256 value, string message) public {
        super.burnFrom(account, value);
        emit TokenBurn(account, value, message);
    }
}

contract PurplecoinCrowdsale is Ownable {
    using SafeMath for uint256;

    uint256 stage = 0;

    // Mapping of KYC authorisations
    mapping(address => bool) public kyc_authorised;

    // Mapping of Pending purchases 
    mapping(address => bool) public pending;

    // Mapping of pending Wei
    mapping(address => uint256) public pending_wei;

    // Mapping of pending psats 
    mapping(address => uint256) public pending_psats;

    // Balances
    mapping(address => uint256) private _balances;

    // Wei raised per address
    mapping(address => uint256) private _wei_raised_per_address;

    MathHelp math = new MathHelp();

    // Amount sold, refunded, and in escrow
    // --------------------------
    uint256 public totalPsatsInEscrow;
    uint256 public totalWeiInEscrow;
    uint256 public totalSoldPsats;
    uint256 public totalWeiInSettledEscrow;

    // -----------------------
    uint256 public tokensCap;
    uint256 public individualTokensCap;
    uint256 private bonus;
    uint256[] private WAVE_CAPS;
    uint256[] private WAVE_BONUSES;
    bool public isFinalized;
    ERC20Mintable public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    // Minimum buy amount
    uint256 public minBuy;

    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor(uint256 _rate, uint256 _coins, uint256[] _waveCaps, uint256[] _waveBonuses, address _wallet) public {
        wallet = _wallet;
        uint256 decimals = 10 ** 18; // 18 decimal places
        tokensCap = _coins * decimals;
        _waveCaps[0] = 37999000000000000000000000;
        _waveCaps[1] = 75998000000000000000000000;
        _waveCaps[2] = 113997001000000000000000000;
        individualTokensCap = 500000000000000000000000; // Max 500,000 XPU per person 
        minBuy = 10000000000000000; // 0.01 ETH min buy
        rate = _rate;
        token = createTokenContract();
        WAVE_CAPS = _waveCaps;
        WAVE_BONUSES = _waveBonuses;
        setCrowdsaleStage(0); //set in pre Sale stage

        // Init balances
        _balances[0x25E320b95316bAA3d300155aD82A0aEBEE400E66] = 1821600000000000000000; // https://etherscan.io/tx/0x7ae5653adfdeb4f0ec8c7d1e3de11edbc84cac4c0a6fbf5141a9c49b5481497b

        // Dev fund, 0.5% of the supply
        _balances[0x130fCeAD624C57aB46EF073bd1a940ACF8Bf2c85] = 11399700000000000000000000;

        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    // ==============================

    // Events
    // ---------------------
    event EthTransferred(uint256 amount);
    event PurchaseCancelled(address indexed beneficiary);
    event KycAuthorised(address indexed beneficiary);
    event IncrementWave(uint256 newWave);
    event TokenMint(address indexed beneficiary, uint256 amount);
    event CrowdsaleFinalized();

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        bool authorised,
        uint256 value,
        uint256 amount
    );

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer fund with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Reverts if beneficiary is not authorized. Can be used when extending this contract.
     * @param _beneficiary beneficiary address
     */
    modifier isAuthorised(address _beneficiary) {
        require(kyc_authorised[_beneficiary]);
        _;
    }

    /**
     * @dev Reverts if beneficiary is not pending. Can be used when extending this contract.
     */
    modifier isPending(address _beneficiary) {
        require(pending[_beneficiary]);
        _;
    }

    // Reentrancy Guard
    // -----------------------

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }

    // Post delivery
    // -----------------------

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param _beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address _beneficiary) nonReentrant public {
        require(isFinalized);
        uint256 amount = _balances[_beneficiary];
        require(amount > 0);
        _balances[_beneficiary] = 0;
        _deliverTokens(_beneficiary, amount);
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    // Crowdsale Stages
    // -----------------------

    // Change Crowdsale Stage.
    function setCrowdsaleStage(uint256 _stage) private {
        setCurrentBonus(WAVE_BONUSES[_stage]);
        stage = _stage;
    }

    function getCurrentStage() public constant returns (uint256){
        return stage;
    }


    function currentWaveCap() public constant returns (uint256) {
        return WAVE_CAPS[stage];
    }

    function incrementWave() private {
        stage = stage + 1;
        emit IncrementWave(stage);
        return;
    }

    // Change the current bonus
    function setCurrentBonus(uint256 _bonus) private {
        bonus = _bonus;
        return;
    }

    //---------------------------end stages----------------------------------

    // creates the token to be sold.
    // override this method to have crowdsale of a specific ERC20Mintable token.
    function createTokenContract() internal returns (ERC20Mintable) {
        return new Purplecoin();
    }

    function _shouldIncrementWave(uint256 _currentWaveCap) constant internal returns (bool){
        return totalSoldPsats.add(totalPsatsInEscrow) >= _currentWaveCap;
    }

    // Override to execute any logic once the crowdsale finalizes
    // Requires a call to the public finalize method
    function finalization() internal {
        // mint the rest of the tokens
        // if (token.totalSupply() < tokensCap) {
        //     mintTokens(remainingTokensWallet, tokensCap.sub(token.totalSupply()));
        // }
        //no more tokens from now on
        //token.finishMinting();
        emit CrowdsaleFinalized();
    }

    function finalize() public onlyOwner {
        require(!isFinalized);
        finalization();
        isFinalized = true;
    }

    function clearWeiInSettledEscrow() public onlyOwner {
        require(totalWeiInSettledEscrow > 0);
        wallet.transfer(totalWeiInSettledEscrow);
        emit EthTransferred(totalWeiInSettledEscrow);
        totalWeiInSettledEscrow = 0;
    }


    function mintTokens(address _beneficiary, uint256 tokens) internal {
        require(_beneficiary != 0x0);
        // Cannot mint before sale is closed
        require(isFinalized);
        token.mint(_beneficiary, tokens);
        emit TokenMint(_beneficiary, tokens);
    }

    /**
     * @dev Update the rate
     * @param _rate new rate
     */
    function updateRate(uint256 _rate) public onlyOwner {
        require(!isFinalized);
        rate = _rate;
    }

    /**
     * @dev Update the minBuy
     * @param _minBuy new minBuy
     */
    function updateMinBuy(uint256 _minBuy) public onlyOwner {
        require(!isFinalized);
        minBuy = _minBuy;
    }

    /**
     * @dev Update the individualTokensCap
     * @param _individualTokensCap new individualTokensCap
     */
    function updateIndividualTokensCap(uint256 _individualTokensCap) public onlyOwner {
        require(!isFinalized);
        individualTokensCap = _individualTokensCap;
    }

    // KYC
    // -----------------------

    /**
     * @dev Authorise token transfer for address.
     * @param _beneficiary beneficiary address
     */
    function authorise(address _beneficiary) public nonReentrant isPending(_beneficiary) onlyOwner {
        emit KycAuthorised(_beneficiary);
        _forwardPendingFunds(_beneficiary);
    }

    /**
     * @dev Authorise token transfers for a batch of addresses.
     * @param _beneficiaries Beneficiaries array
     */
    function authoriseMany(address[] _beneficiaries) external nonReentrant onlyOwner {
        for(uint256 i=0; i < _beneficiaries.length; i++) {
            authorise(_beneficiaries[i]);
        }
    }

    function withdrawalAllowed(address _beneficiary) public view returns(bool) {
        return kyc_authorised[_beneficiary];
    }

    // Crowdsale overrides
    // -----------------------

    // Override this method to have a way to add business logic to your crowdsale when buying
    // Returns weiAmount times rate by default
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return rate.mul(weiAmount.add(math.getPercentAmount(weiAmount, bonus, 18)));
    }

    function cancelPurchase() public nonReentrant isPending(msg.sender) {
        require(pending_wei[msg.sender] != 0);
        uint256 to_refund = pending_wei[msg.sender];
        totalWeiInEscrow = totalWeiInEscrow.sub(pending_wei[msg.sender]);
        totalPsatsInEscrow = totalPsatsInEscrow.sub(pending_psats[msg.sender]);
        pending[msg.sender] = false;
        pending_wei[msg.sender] = 0;
        pending_psats[msg.sender] = 0;
        msg.sender.transfer(to_refund);
        emit PurchaseCancelled(msg.sender);
    }

    function cancelPurchaseFor(address _beneficiary) public nonReentrant isPending(_beneficiary) onlyOwner {
        require(pending_wei[_beneficiary] != 0);
        uint256 to_refund = pending_wei[_beneficiary];
        totalWeiInEscrow = totalWeiInEscrow.sub(pending_wei[_beneficiary]);
        totalPsatsInEscrow = totalPsatsInEscrow.sub(pending_psats[_beneficiary]);
        pending[_beneficiary] = false;
        pending_wei[_beneficiary] = 0;
        pending_psats[_beneficiary] = 0;
        _beneficiary.transfer(to_refund);
        emit PurchaseCancelled(_beneficiary);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, kyc_authorised[_beneficiary], weiAmount, tokens);

        _forwardFunds(_beneficiary);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *   super._preValidatePurchase(beneficiary, weiAmount);
     *   require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    )
        internal
        view
    {
        uint256 tokenAmount = _getTokenAmount(weiAmount);
        require(beneficiary != address(0));
        require(_wei_raised_per_address[beneficiary].add(pending_wei[beneficiary]).add(weiAmount) >= minBuy);    // Min buy
        require(!isFinalized);
        require(_balances[beneficiary].add(pending_psats[beneficiary]).add(tokenAmount) <= individualTokensCap); // Individual cap
        require(tokenAmount.add(totalSoldPsats).add(totalPsatsInEscrow) <= tokensCap);                           // Sale cap
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) 
        internal 
        isAuthorised(_beneficiary) 
    {
        mintTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        if (kyc_authorised[_beneficiary]) {
            weiRaised = weiRaised.add(msg.value);
            _wei_raised_per_address[_beneficiary] = _wei_raised_per_address[_beneficiary].add(msg.value);
            _balances[_beneficiary] = _balances[_beneficiary].add(_tokenAmount);
            totalSoldPsats = totalSoldPsats.add(_tokenAmount);
        } else {
            kyc_authorised[_beneficiary] = false;
            pending[_beneficiary] = true;
            pending_psats[_beneficiary] = pending_psats[_beneficiary].add(_tokenAmount);
            totalPsatsInEscrow = totalPsatsInEscrow.add(_tokenAmount);
            if (_shouldIncrementWave(currentWaveCap())) {
                incrementWave();
            }
        }
    }

    // Override to create custom fund forwarding mechanisms
    // Forwards funds to the specified wallet by default
    function _forwardFunds(address _beneficiary) internal {
        if (kyc_authorised[_beneficiary]) {
            if (_shouldIncrementWave(currentWaveCap())) {
                incrementWave();
            }
            totalWeiInSettledEscrow = totalWeiInSettledEscrow.add(msg.value);
        } else {
            pending_wei[_beneficiary] = pending_wei[_beneficiary].add(msg.value);
            totalWeiInEscrow = totalWeiInEscrow.add(msg.value);
        }
    }

    // Override to create custom pending fund forwarding mechanisms
    // Forwards funds to the specified wallet by default
    function _forwardPendingFunds(address _beneficiary) internal {
        weiRaised = weiRaised.add(pending_wei[_beneficiary]);
        _wei_raised_per_address[_beneficiary] = _wei_raised_per_address[_beneficiary].add(pending_wei[_beneficiary]);
        totalWeiInEscrow = totalWeiInEscrow.sub(pending_wei[_beneficiary]);
        totalSoldPsats = totalSoldPsats.add(pending_psats[_beneficiary]);
        totalPsatsInEscrow = totalPsatsInEscrow.sub(pending_psats[_beneficiary]);
        
        _balances[_beneficiary] = _balances[_beneficiary].add(pending_psats[_beneficiary]);
        wallet.transfer(pending_wei[_beneficiary]);
        emit EthTransferred(pending_wei[_beneficiary]);

        pending_wei[_beneficiary] = 0;
        pending_psats[_beneficiary] = 0;
        kyc_authorised[_beneficiary] = true;
        pending[_beneficiary] = false;
    }
}

pragma solidity ^0.4.24;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

pragma solidity ^0.4.24;

import "../Roles.sol";

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

pragma solidity ^0.4.24;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

pragma solidity ^0.4.24;

import "./ERC20.sol";

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {

  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

pragma solidity ^0.4.24;

import "./IERC20.sol";

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

pragma solidity ^0.4.24;

import "./ERC20.sol";
import "../../access/roles/MinterRole.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

pragma solidity ^0.4.24;

contract MathHelp {
    function getPercentAmount(uint amount, uint percentage, uint precision) public
    constant returns (uint totalAmount){
        return ((amount * (percentage * power(10, precision +1)) / (1000 * power(10, precision))));
    }

    function power(uint256 A, uint256 B) public
    constant returns (uint result){
        return A ** B;
    }

}

pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}