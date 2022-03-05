/**
 * SPDX-License-Identifier: Apache-2.0
 **/

pragma solidity ^0.8.0;
// input  C:\projects\BTCS.CHFToken\contracts\Chftoken\CryptoFranc.sol
interface InterestRateInterface {

    /// @notice get compounding level for currenct day
    function getCurrentCompoundingLevel() external view returns (uint256);

    /// @notice get compounding level for _date `_date`
    /// @param _date The date 
    function getCompoundingLevelDate(uint256 _date) external view returns (uint256);

}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20Interface {
    /// total amount of tokens
    function totalSupply() external view returns(uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    // EVENTS
    
    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IL2StandardERC20 is ERC20Interface, IERC165 {
    function l1Token() external returns (address);

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
}

abstract contract Ownable {
    address public owner;
    address public newOwner;

    // MODIFIERS

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /// @dev Throws if called by any account other than the new owner.
    modifier onlyNewOwner() {
        require(msg.sender == newOwner, "Only New Owner");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0),"address is Null");
        _;
    }

    // CONSTRUCTORS

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner = msg.sender;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param _newOwner The address to transfer ownership to.
    
    function transferOwnership(address _newOwner) public notNull(_newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    /// @dev Allow the new owner to claim ownership and so proving that the newOwner is valid.
    function acceptOwnership() public onlyNewOwner {
        address oldOwner = owner;
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    // EVENTS
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

abstract contract InterestRateNone is InterestRateInterface {

    uint256 public constant SCALEFACTOR = 1e18;
    
    /// @notice get compounding level for currenct day
    function getCurrentCompoundingLevel() public pure override returns (uint256) {
        return SCALEFACTOR;
    }

    /// @notice get compounding level for day `_date`
    /// param _date The daynumber 
    function getCompoundingLevelDate(uint256 /* _date */) public pure override returns (uint256) {
        return SCALEFACTOR;
    }

}
abstract contract MigrationAgent is Ownable {

    address public migrationToContract; // the contract to migrate to
    address public migrationFromContract; // the conttactto migate from

    // MODIFIERS
    
    modifier onlyMigrationFromContract() {
        require(msg.sender == migrationFromContract, "Only from migration contract");
        _;
    }
    // EXTERNAL FUNCTIONS

    // PUBLIC FUNCTIONS

    /// @dev set contract to migrate to 
    /// @param _toContract Then contract address to migrate to
    function startMigrateToContract(address _toContract) public onlyOwner {
        migrationToContract = _toContract;
        require(MigrationAgent(migrationToContract).isMigrationAgent(), "not a migratable contract");
        emit StartMigrateToContract(address(this), _toContract);
    }

    /// @dev set contract to migrate from
    /// @param _fromConstract Then contract address to migrate from
    function startMigrateFromContract(address _fromConstract) public onlyOwner {
        migrationFromContract = _fromConstract;
        require(MigrationAgent(migrationFromContract).isMigrationAgent(), "not a migratable contract");
        emit StartMigrateFromContract(_fromConstract, address(this));
    }

    /// @dev Each user calls the migrate function on the original contract to migrate the users’ tokens to the migration agent migrateFrom on the `migrationToContract` contract
    function migrate() public virtual;   

    /// @dev migrageFrom is called from the migrating contract `migrationFromContract`
    /// @param _from The account to be migrated into new contract
    /// @param _value The token balance to be migrated
    function migrateFrom(address _from, uint256 _value) public virtual returns(bool);

    /// @dev is a valid migration agent
    /// @return true if contract is a migratable contract
    function isMigrationAgent() public pure returns(bool) {
        return true;
    }

    // INTERNAL FUNCTIONS

    // PRIVATE FUNCTIONS

    // EVENTS

    event StartMigrateToContract(address indexed fromConstract, address indexed toContract);

    event StartMigrateFromContract(address indexed fromConstract, address indexed toContract);

    event MigratedTo(address indexed owner, address indexed _contract, uint256 value);

    event MigratedFrom(address indexed owner, address indexed _contract, uint256 value);
}
contract Pausable is Ownable {

    bool public paused = false;

    // MODIFIERS

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "only when not paused");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "only when paused");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

    // EVENTS

    event Pause();

    event Unpause();
}

abstract contract Operator is Ownable {

    address public operator;

    // MODIFIERS

    /**
     * @dev modifier check for operator
     */
    modifier onlyOperator {
        require(msg.sender == operator, "Only Operator");
        _;
    }

    // CONSTRUCTORS

    constructor() {
        operator = msg.sender;
    }

    /**
     * @dev Transfer operator to `newOperator`.
     *
     * @param _newOperator   The address of the new operator
     */
    function transferOperator(address _newOperator) public notNull(_newOperator) onlyOwner {
        operator = _newOperator;
        emit TransferOperator(operator, _newOperator);
    }

    // EVENTS
    
    event TransferOperator(address indexed from, address indexed to);
}

abstract contract ERC20Token is Ownable, ERC20Interface {

    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    // CONSTRUCTORS

    constructor() {
    }

    // EXTERNAL FUNCTIONS

    // PUBLIC FUNCTIONS

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public virtual override returns (bool success) {

        return transferInternal(msg.sender, _to, _value);
    }

    /* ALLOW FUNCTIONS */

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    */
   
    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens   
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public virtual override notNull(_spender) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool success) {
        require(_value <= allowed[_from][msg.sender], "insufficient tokens");

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return transferInternal(_from, _to, _value);
    }

    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) public virtual override view returns (uint256) {
        return balances[_owner];
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // INTERNAL FUNCTIONS

    /// @notice internal send `_value` token to `_to` from `_from` 
    /// @param _from The address of the sender (null check performed in subTokens)
    /// @param _to The address of the recipient (null check performed in addTokens)
    /// @param _value The amount of token to be transferred 
    /// @return Whether the transfer was successful or not
    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool) {
        uint256 value = subTokens(_from, _value);
        addTokens(_to, value);
        emit Transfer(_from, _to, value);
        return true;
    }
   
    /// @notice add tokens `_value` tokens to `owner`
    /// @param _owner The address of the account
    /// @param _value The amount of tokens to be added
    function addTokens(address _owner, uint256 _value) internal virtual;

    /// @notice subtract tokens `_value` tokens from `owner`
    /// @param _owner The address of the account
    /// @param _value The amount of tokens to be subtracted
    function subTokens(address _owner, uint256 _value) internal virtual returns (uint256 _valueDeducted );
    
    /// @notice set balance of account `owner` to `_value`
    /// @param _owner The address of the account
    /// @param _value The new balance 
    function setBalance(address _owner, uint256 _value) internal virtual notNull(_owner) {
        balances[_owner] = _value;
    }

    // PRIVATE FUNCTIONS

}

abstract contract PausableToken is ERC20Token, Pausable {

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool success) {
        return super.transfer(_to, _value);
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public override whenNotPaused returns (bool success) {
        return super.approve(_spender, _value);
    }
}

abstract contract MintableToken is PausableToken
{
    using SafeMath for uint256;

    address public minter; // minter

    uint256 internal minted; // total minted tokens
    uint256 internal burned; // total burned tokens

    // MODIFIERS

    modifier onlyMinter {
        assert(msg.sender == minter);
        _; 
    }

    constructor() {
        minter = msg.sender;   // Set the owner to minter
    }

    // EXTERNAL FUNCTIONS

    // PUBLIC FUNCTIONS

    /// @dev  mint tokens to address
    /// @notice mint `_value` token to `_to`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be minted
    function _mint(address _to, uint256 _value) internal notNull(_to) {
        addTokens(_to, _value);
        notifyMinted(_to, _value);
    }

    /// @dev burn tokens, e.g. when migrating
    /// @notice burn `_value` token to `_to`
    /// @param _value The amount of token to be burned from the callers account
    function _burn(uint256 _value) internal whenNotPaused {
        uint256 value = subTokens(msg.sender, _value);
        notifyBurned(msg.sender, value);
    }

    /// @dev transfer minter to new address
    /// @notice transfer minter addres from  `minter` to `_newMinter`
    /// @param _newMinter The address of the recipient
    function transferMinter(address _newMinter) public notNull(_newMinter) onlyOwner {
        address oldMinter = minter;
        minter = _newMinter;
        emit TransferMinter(oldMinter, _newMinter);
    }

    // INTERNAL FUNCTIONS

    /// @dev update burned and emit Transfer event of burned tokens
    /// @notice burn `_value` token from `_owner`
    /// @param _owner The address of the owner
    /// @param _value The amount of token burned
    function notifyBurned(address _owner, uint256 _value) internal {
        burned = burned.add(_value);
        emit Transfer(_owner, address(0), _value);
    }

    /// @dev update burned and emit Transfer event of burned tokens
    /// @notice mint `_value` token to `_to`
    /// @param _to The address of the recipient
    /// @param _value The amount of token minted
    function notifyMinted(address _to, uint256 _value) internal {
        minted = minted.add(_value);
        emit Transfer(address(0), _to, _value);
    }

    /// @dev helper function to update token supply state and emit events 
    /// @notice checkMintOrBurn for account `_owner` tokens chainging  from `_balanceBefore` to `_balanceAfter`
    /// @param _owner The address of the owner
    /// @param _balanceBefore The balance before the transaction
    /// @param _balanceAfter The balance after the tranaaction
    function checkMintOrBurn(address _owner, uint256 _balanceBefore, uint256 _balanceAfter) internal {
        if (_balanceBefore > _balanceAfter) {
            uint256 burnedTokens = _balanceBefore.sub(_balanceAfter);
            notifyBurned(_owner, burnedTokens);
        } else if (_balanceBefore < _balanceAfter) {
            uint256 mintedTokens = _balanceAfter.sub(_balanceBefore);
            notifyMinted(_owner, mintedTokens);
        }
    }

    /// @dev return total amount of tokens
    function totalSupply() public view override returns(uint256 supply) {
        return minted.sub(burned);
    }

    // PRIVATE FUNCTIONS

    // EVENTS
    
    event TransferMinter(address indexed from, address indexed to);
}

contract CryptoFranc is MintableToken, MigrationAgent, Operator, InterestRateNone {

    using SafeMath for uint256;

    string constant public name = "CryptoFranc";
    string constant public symbol = "XCHF";
    uint256 constant public decimals = 18;
    string constant public version = "1.0.0.0";
    uint256 public dustAmount;

    // Changes as the token is converted to the next vintage
    string public currentFullName;
    string public announcedFullName;
    uint256 public currentMaturityDate;
    uint256 public announcedMaturityDate;
    uint256 public currentTermEndDate;
    uint256 public announcedTermEndDate;
    InterestRateInterface public currentTerms;
    InterestRateInterface public announcedTerms;

    mapping(address => uint256) internal compoundedInterestFactor;

    // CONSTRUCTORS

    constructor(string memory _initialFullName, uint256 _dustAmount) {
        // initially, there is no interest. This contract has an interest-free default implementation
        // of the InterestRateInterface. Having this internalized saves gas in comparison to having an
        // external, separate smart contract.
        currentFullName = _initialFullName;
        announcedFullName = _initialFullName;
        dustAmount = _dustAmount;    
        currentTerms = this;
        announcedTerms = this;
        announcedMaturityDate = block.timestamp;
        announcedTermEndDate = block.timestamp;
    }

    // EXTERNAL FUNCTIONS

    // PUBLIC FUNCTIONS

    /// @dev Invoked by the issuer to convert all the outstanding tokens into bonds of the latest vintage.
    /// @param _newName Name of announced bond
    /// @param _newTerms Address of announced bond
    /// @param _newMaturityDate Maturity Date of announced bond
    /// @param _newTermEndDate End Date of announced bond
    function announceRollover(string memory _newName, address _newTerms, uint256 _newMaturityDate, uint256 _newTermEndDate) public notNull(_newTerms) onlyOperator {
        // a new term can not be announced before the current is expired
        require(block.timestamp >= announcedMaturityDate);

        // for test purposes
        uint256 newMaturityDate;
        if (_newMaturityDate == 0)
            newMaturityDate = block.timestamp;
        else
            newMaturityDate = _newMaturityDate;

        // new newMaturityDate must be at least or greater than the existing announced terms end date
        require(newMaturityDate >= announcedTermEndDate);

        //require new term dates not too far in the future
        //this is to prevent severe operator time calculaton errors
        require(newMaturityDate <= block.timestamp.add(100 days),"sanitycheck on newMaturityDate");
        require(newMaturityDate <= _newTermEndDate,"term must start before it ends");
        require(_newTermEndDate <= block.timestamp.add(200 days),"sanitycheck on newTermEndDate");

        InterestRateInterface terms = InterestRateInterface(_newTerms);
        
        // ensure that _newTerms begins at the compoundLevel that the announcedTerms ends
        // they must align
        uint256 newBeginLevel = terms.getCompoundingLevelDate(newMaturityDate);
        uint256 annEndLevel = announcedTerms.getCompoundingLevelDate(newMaturityDate);
        require(annEndLevel == newBeginLevel,"new initialCompoundingLevel <> old finalCompoundingLevel");

        //rollover
        currentTerms = announcedTerms;
        currentFullName = announcedFullName;
        currentMaturityDate = announcedMaturityDate;
        currentTermEndDate = announcedTermEndDate;
        announcedTerms = terms;
        announcedFullName = _newName;
        announcedMaturityDate = newMaturityDate;
        announcedTermEndDate = _newTermEndDate;

        emit AnnounceRollover(_newName, _newTerms, newMaturityDate, _newTermEndDate);
    }

    /// @dev collectInterest is called to update the internal state of `_owner` balance and force a interest payment
    /// This function does not change the effective amount of the `_owner` as returned by balanceOf
    /// and thus, can be called by anyone willing to pay for the gas.
    /// The designed usage for this function is to allow the CryptoFranc owner to collect interest from inactive accounts, 
    /// since interest collection is updated automatically in normal transfers
    /// calling collectInterest is functional equivalent to transfer 0 tokens to `_owner`
    /// @param _owner The account being updated
    function collectInterest( address _owner) public notNull(_owner) whenNotPaused {
        uint256 rawBalance = super.balanceOf(_owner);
        uint256 adjustedBalance = getAdjustedValue(_owner);
        setBalance(_owner, adjustedBalance);
        checkMintOrBurn(_owner, rawBalance, adjustedBalance);
    }

    /*
        MIGRATE FUNCTIONS
     */
    // safe migrate function
    /// @dev migrageFrom is called from the migrating contract `migrationFromContract`
    /// @param _from The account to be migrated into new contract
    /// @param _value The token balance to be migrated
    function migrateFrom(address _from, uint256 _value) public override onlyMigrationFromContract returns(bool) {
        addTokens(_from, _value);
        notifyMinted(_from, _value);

        emit MigratedFrom(_from, migrationFromContract, _value);
        return true;
    }

    /// @dev Each user calls the migrate function on the original contract to migrate the users’ tokens to the migration agent migrateFrom on the `migrationToContract` contract
    function migrate() public override whenNotPaused {
        require(migrationToContract != address(0), "not in migration mode"); // revert if not in migrate mode
        uint256 value = balanceOf(msg.sender);
        require (value > 0, "no balance"); // revert if not value left to transfer
        value = subTokens(msg.sender, value);
        notifyBurned(msg.sender, value);
        require(MigrationAgent(migrationToContract).migrateFrom(msg.sender, value)==true, "migrateFrom must return true");

        emit MigratedTo(msg.sender, migrationToContract, value);
    }

    /*
        Helper FUNCTIONS
    */

    /// @dev helper function to return foreign tokens accidental send to contract address
    /// @param _tokenaddress Address of foreign ERC20 contract
    /// @param _to Address to send foreign tokens to
    function refundForeignTokens(address _tokenaddress,address _to) public notNull(_to) onlyOperator {
        ERC20Interface token = ERC20Interface(_tokenaddress);
        // transfer current balance for this contract to _to  in token contract
        token.transfer(_to, token.balanceOf(address(this)));
    }

    /// @dev get fullname of active interest contract
    function getFullName() public view returns (string memory) {
        if ((block.timestamp <= announcedMaturityDate))
            return currentFullName;
        else
            return announcedFullName;
    }

    /// @dev get compounding level of an owner account
    /// @param _owner tokens address
    /// @return The compouding level
    function getCompoundingLevel(address _owner) public view returns (uint256) {
        uint256 level = compoundedInterestFactor[_owner];
        if (level == 0) {
            // important note that for InterestRateNone or empty accounts the compoundedInterestFactor is newer stored by setBalance
            return SCALEFACTOR;
        } else {
            return level;
        }
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view override returns (uint256) {
        return getAdjustedValue(_owner);
    }

    // INTERNAL FUNCTIONS

    /// @notice add tokens `_value` tokens to `owner`
    /// @param _owner The address of the account
    /// @param _value The amount of tokens to be added
    function addTokens(address _owner,uint256 _value) internal override notNull(_owner) {
        uint256 rawBalance = super.balanceOf(_owner);
        uint256 adjustedBalance = getAdjustedValue(_owner);
        setBalance(_owner, adjustedBalance.add(_value));
        checkMintOrBurn(_owner, rawBalance, adjustedBalance);
    }

    /// @notice subtract tokens `_value` tokens from `owner`
    /// @param _owner The address of the account
    /// @param _value The amount of tokens to be subtracted
    /// @return _valueDeducted The value deducted
    function subTokens(address _owner, uint256 _value) internal override notNull(_owner) returns (uint256 _valueDeducted ) {
        uint256 rawBalance = super.balanceOf(_owner);
        uint256 adjustedBalance = getAdjustedValue(_owner);
        uint256 newBalance = adjustedBalance.sub(_value);
        if (newBalance <= dustAmount) {
            // dont leave balance below dust, empty account
            _valueDeducted = _value.add(newBalance);
            newBalance =  0;
        } else {
            _valueDeducted = _value;
        }
        setBalance(_owner, newBalance);
        checkMintOrBurn(_owner, rawBalance, adjustedBalance);
    }

    /// @notice set balance of account `owner` to `_value`
    /// @param _owner The address of the account
    /// @param _value The new balance 
    function setBalance(address _owner, uint256 _value) internal override {
        super.setBalance(_owner, _value);
        // update `owner`s compoundLevel
        if (_value == 0) {
            // stall account release storage
            delete compoundedInterestFactor[_owner];
        } else {
            // only update compoundedInterestFactor when value has changed 
            // important note: for InterestRateNone the compoundedInterestFactor is newer stored because the default value for getCompoundingLevel is SCALEFACTOR
            uint256 currentLevel = getInterestRate().getCurrentCompoundingLevel();
            if (currentLevel != getCompoundingLevel(_owner)) {
                compoundedInterestFactor[_owner] = currentLevel;
            }
        }
    }

    /// @dev get address of active bond
    function getInterestRate() internal view returns (InterestRateInterface) {
        if ((block.timestamp <= announcedMaturityDate))
            return currentTerms;
        else
            return announcedTerms;
    }

    /// @notice get adjusted balance of account `owner`
    /// @param _owner The address of the account
    function getAdjustedValue(address _owner) internal view returns (uint256) {
        uint256 _rawBalance = super.balanceOf(_owner);
        // if _rawBalance is 0 dont perform calculations
        if (_rawBalance == 0)
            return 0;
        // important note: for empty/new account the getCompoundingLevel value is not meaningfull
        uint256 startLevel = getCompoundingLevel(_owner);
        uint256 currentLevel = getInterestRate().getCurrentCompoundingLevel();
        return _rawBalance.mul(currentLevel).div(startLevel);
    }

    /// @notice get adjusted balance of account `owner` at data `date`
    /// @param _owner The address of the account
    /// @param _date The date of the balance NB: MUST be within valid current and announced Terms date range
    function getAdjustedValueDate(address _owner,uint256 _date) public view returns (uint256) {
        uint256 _rawBalance = super.balanceOf(_owner);
        // if _rawBalance is 0 dont perform calculations
        if (_rawBalance == 0)
            return 0;
        // important note: for empty/new account the getCompoundingLevel value is not meaningfull
        uint256 startLevel = getCompoundingLevel(_owner);

        InterestRateInterface dateTerms;
        if (_date <= announcedMaturityDate)
            dateTerms = currentTerms;
        else
            dateTerms = announcedTerms;

        uint256 dateLevel = dateTerms.getCompoundingLevelDate(_date);
        return _rawBalance.mul(dateLevel).div(startLevel);
    }

    // PRIVATE FUNCTIONS

    // EVENTS

    event AnnounceRollover(string newName, address indexed newTerms, uint256 indexed newMaturityDate, uint256 indexed newTermEndDate);
}