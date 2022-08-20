/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner requirement");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OwnershipTransferred(owner, addr);
        owner = addr;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    /**
    * Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the total number of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    /**
    * Gets the balance of the address specified.
    * @param addr The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * This event is triggered when a given amount of tokens is sent to an address.
     * @param from The address of the sender
     * @param to The address of the receiver
     * @param value The amount transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * This event is triggered when a given address is approved to spend a specific amount of tokens
     * on behalf of the sender.
     * @param owner The owner of the token
     * @param spender The spender
     * @param value The amount to transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Represents an ERC-20
 */
contract ERC20 is IERC20 {
    // Basic ERC-20 data
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 internal _totalSupply;

    // The balance of each owner
    mapping(address => uint256) internal _balances;

    // The allowance set by each owner
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @notice Constructor
     * @param tokenName The name of the token
     * @param tokenSymbol The symbol of the token
     * @param tokenDecimals The decimals of the token
     * @param initialSupply The initial supply
     */
    constructor (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 initialSupply) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        _totalSupply = initialSupply;
    }

    /**
    * @notice Transfers a given amount tokens to the address specified.
    * @param from The address of the sender.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return Returns true in case of success.
    */
    function _executeErc20Transfer (address from, address to, uint256 value) private returns (bool) {
        // Checks
        require(to != address(0), "non-zero address required");
        require(from != address(0), "non-zero sender required");
        require(value > 0, "Amount cannot be zero");
        require(_balances[from] >= value, "Amount exceeds sender balance");

        // State changes
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;

        // Emit the event per ERC-20
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param ownerAddr The address of the owner.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return Returns true in case of success.
     */
    function _approveSpender(address ownerAddr, address spender, uint256 value) private returns (bool) {
        require(spender != address(0), "non-zero spender required");
        require(ownerAddr != address(0), "non-zero owner required");

        // State changes
        _allowances[ownerAddr][spender] = value;

        // Emit the event
        emit Approval(ownerAddr, spender, value);

        return true;
    }

    /**
    * @notice Transfers a given amount tokens to the address specified.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return Returns true in case of success.
    */
    function transfer(address to, uint256 value) public override returns (bool) {
        require (_executeErc20Transfer(msg.sender, to, value), "Failed to execute ERC20 transfer");
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @dev Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     * @return Returns true in case of success.
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "Amount exceeds allowance");

        require (_executeErc20Transfer(from, to, value), "Failed to execute transferFrom");

        require(_approveSpender(from, msg.sender, currentAllowance - value), "ERC20: Approval failed");

        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return Returns true in case of success.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        require(_approveSpender(msg.sender, spender, value), "ERC20: Approval failed");
        return true;
    }

    /**
     * Gets the total supply of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Gets the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @notice Gets the symbol of the token.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Gets the decimals of the token.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
    * Gets the balance of the address specified.
    * @param addr The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) public view override returns (uint256) {
        return _balances[addr];
    }

    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
}

/**
 * @notice Represents an ERC20 that can be minted and/or burnt by multiple parties.
 */
contract Mintable is ERC20, Ownable {
    /**
     * @notice The maximum circulating supply of tokens
     */
    uint256 public maxSupply;

    // Keeps track of the authorized minters
    mapping (address => bool) internal _authorizedMinters;

    // Keeps track of the authorized burners
    mapping (address => bool) internal _authorizedBurners;

    // ---------------------------------------
    // Events
    // ---------------------------------------
    /**
     * This event is triggered whenever an address is added as a valid minter.
     * @param addr The address that became a valid minter
     */
    event OnMinterGranted(address addr);

    /**
     * This event is triggered when a minter is revoked.
     * @param addr The address that was revoked
     */
    event OnMinterRevoked(address addr);

    /**
     * This event is triggered whenever an address is added as a valid burner.
     * @param addr The address that became a valid burner
     */
    event OnBurnerGranted(address addr);

    /**
     * This event is triggered when a burner is revoked.
     * @param addr The address that was revoked
     */
    event OnBurnerRevoked(address addr);

    /**
     * This event is triggered when the maximum limit for minting tokens is updated.
     * @param prevValue The previous limit
     * @param newValue The new limit
     */
    event OnMaxSupplyChanged(uint256 prevValue, uint256 newValue);

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    /**
     * @notice Constructor
     * @param newOwner The contract owner
     * @param tokenName The name of the token
     * @param tokenSymbol The symbol of the token
     * @param tokenDecimals The decimals of the token
     * @param initialSupply The initial supply
     */
    constructor (address newOwner, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 initialSupply)
    ERC20(tokenName, tokenSymbol, tokenDecimals, initialSupply)
    Ownable(newOwner) { // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Throws if the sender is not a valid minter
     */
    modifier onlyMinter() {
        require(_authorizedMinters[msg.sender], "Unauthorized minter");
        _;
    }

    /**
     * @notice Throws if the sender is not a valid burner
     */
    modifier onlyBurner() {
        require(_authorizedBurners[msg.sender], "Unauthorized burner");
        _;
    }

    /**
     * @notice Grants the right to issue new tokens to the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function grantMinter (address addr) public onlyOwner {
        require(!_authorizedMinters[addr], "Address authorized already");
        _authorizedMinters[addr] = true;
        emit OnMinterGranted(addr);
    }

    /**
     * @notice Revokes the right to issue new tokens from the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function revokeMinter (address addr) public onlyOwner {
        require(_authorizedMinters[addr], "Address was never authorized");
        _authorizedMinters[addr] = false;
        emit OnMinterRevoked(addr);
    }

    /**
     * @notice Grants the right to burn tokens to the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function grantBurner (address addr) public onlyOwner {
        require(!_authorizedBurners[addr], "Address authorized already");
        _authorizedBurners[addr] = true;
        emit OnBurnerGranted(addr);
    }

    /**
     * @notice Revokes the right to burn tokens from the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function revokeBurner (address addr) public onlyOwner {
        require(_authorizedBurners[addr], "Address was never authorized");
        _authorizedBurners[addr] = false;
        emit OnBurnerRevoked(addr);
    }

    /**
     * @notice Updates the maximum limit for minting tokens.
     * @param newValue The new limit
     */
    function changeMaxSupply (uint256 newValue) public onlyOwner {
        require(newValue == 0 || newValue > _totalSupply, "Invalid max supply");
        emit OnMaxSupplyChanged(maxSupply, newValue);
        maxSupply = newValue;
    }

    /**
     * @notice Issues a given number of tokens to the address specified.
     * @dev This function throws if the sender is not a whitelisted minter.
     * @param addr The destination address
     * @param amount The number of tokens
     */
    function mint (address addr, uint256 amount) public onlyMinter {
        require(addr != address(0) && addr != address(this), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(canMint(amount), "Max token supply exceeded");

        _totalSupply += amount;
        _balances[addr] += amount;
        emit Transfer(address(0), addr, amount);
    }

    /**
     * @notice Burns a given number of tokens from the address specified.
     * @dev This function throws if the sender is not a whitelisted minter. In this context, minters and burners have the same privileges.
     * @param addr The destination address
     * @param amount The number of tokens
     */
    function burn (address addr, uint256 amount) public onlyBurner {
        require(addr != address(0) && addr != address(this), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(_totalSupply > 0, "No token supply");

        uint256 accountBalance = _balances[addr];
        require(accountBalance >= amount, "Burn amount exceeds balance");

        _balances[addr] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(addr, address(0), amount);
    }

    /**
     * @notice Indicates if we can issue/mint the number of tokens specified.
     * @param amount The number of tokens to issue/mint
     */
    function canMint (uint256 amount) public view returns (bool) {
        return (maxSupply == 0) || (_totalSupply + amount <= maxSupply);
    }
}

/**
 * @title Represents a controllable resource.
 */
contract Controllable is Ownable {
    address public controllerAddress;

    event OnControllerChanged (address prevAddress, address newAddress);

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the smart contract
     * @param controllerAddr The address of the controller
     */
    constructor (address ownerAddr, address controllerAddr) Ownable (ownerAddr) {
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != ownerAddr, "Owner cannot be the Controller");
        controllerAddress = controllerAddr;
    }

    /**
     * @notice Throws if the sender is not the controller
     */
    modifier onlyController() {
        require(msg.sender == controllerAddress, "Unauthorized controller");
        _;
    }

    /**
     * @notice Makes sure the sender is either the owner of the contract or the controller
     */
    modifier onlyOwnerOrController() {
        require(msg.sender == controllerAddress || msg.sender == owner, "Only owner or controller");
        _;
    }

    /**
     * @notice Sets the controller
     * @dev This function can be called by the owner only
     * @param controllerAddr The address of the controller
     */
    function setController (address controllerAddr) public onlyOwner {
        // Checks
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != owner, "Owner cannot be the Controller");
        require(controllerAddr != controllerAddress, "Controller already set");

        emit OnControllerChanged(controllerAddress, controllerAddr);

        // State changes
        controllerAddress = controllerAddr;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public override onlyOwner {
        require(addr != controllerAddress, "Cannot transfer to controller");
        super.transferOwnership(addr);
    }
}

/**
 * @title Represents a receipt token. The token is fully compliant with the ERC20 interface.
 * @dev The token can be minted or burnt by whitelisted addresses only. Only the owner is allowed to enable/disable addresses.
 */
contract ReceiptToken is Mintable {
    /**
     * @notice Constructor.
     * @param newOwner The owner of the smart contract.
     */
    constructor (address newOwner, uint256 initialMaxSupply) Mintable(newOwner, "Fractal Protocol Vault Token", "USDF", 6, 0) {
        maxSupply = initialMaxSupply;
    }
}

/**
 * @notice This library provides stateless, general purpose functions.
 */
library Utils {
    // The code hash of any EOA
    bytes32 constant internal EOA_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /**
     * @notice Indicates if the address specified represents a smart contract.
     * @dev Notice that this method returns TRUE if the address is a contract under construction
     * @param addr The address to evaluate
     * @return Returns true if the address represents a smart contract
     */
    function isContract (address addr) internal view returns (bool) {
        bytes32 eoaHash = EOA_HASH;

        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return (codeHash != eoaHash && codeHash != 0x0);
    }

    /**
     * @notice Gets the code hash of the address specified
     * @param addr The address to evaluate
     * @return Returns a hash
     */
    function getCodeHash (address addr) internal view returns (bytes32) {
        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return codeHash;
    }
}

library DateUtils {
    // The number of seconds per day
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;

    // The number of seconds per hour
    uint256 internal constant SECONDS_PER_HOUR = 60 * 60;

    // The number of seconds per minute
    uint256 internal constant SECONDS_PER_MINUTE = 60;

    // The offset from 01/01/1970
    int256 internal constant OFFSET19700101 = 2440588;

    /**
     * @notice Gets the year of the timestamp specified.
     * @param timestamp The timestamp
     * @return year The year
     */
    function getYear (uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    /**
     * @notice Gets the timestamp of the date specified.
     * @param year The year
     * @param month The month
     * @param day The day
     * @param hour The hour
     * @param minute The minute
     * @param second The seconds
     * @return timestamp The timestamp
     */
    function timestampFromDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }

    /**
     * @notice Gets the number of days elapsed between the two timestamps specified.
     * @param fromTimestamp The source date
     * @param toTimestamp The target date
     * @return Returns the difference, in days
     */
    function diffDays (uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256) {
        require(fromTimestamp <= toTimestamp, "Invalid order for timestamps");
        return (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    /**
     * @notice Calculate year/month/day from the number of days since 1970/01/01 using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and adding the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param _days The year
     * @return year The year
     * @return month The month
     * @return day The day
     */
    function _daysToDate (uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);

        int256 x = __days + 68569 + OFFSET19700101;
        int256 n = 4 * x / 146097;
        x = x - (146097 * n + 3) / 4;
        int256 _year = 4000 * (x + 1) / 1461001;
        x = x - 1461 * _year / 4 + 31;
        int256 _month = 80 * x / 2447;
        int256 _day = x - 2447 * _month / 80;
        x = _month / 11;
        _month = _month + 2 - 12 * x;
        _year = 100 * (n - 49) + _year + x;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /**
     * @notice Calculates the number of days from 1970/01/01 to year/month/day using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and subtracting the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param year The year
     * @param month The month
     * @param day The day
     * @return _days Returns the number of days
     */
    function _daysFromDate (uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970, "Error");
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint256(__days);
    }

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }    

    function _isLeapYear (uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
}

interface IDeployable {
    function deployCapital (uint256 deploymentAmount, bytes32 foreignNetwork) external;
    function claim (uint256 dailyInterestAmount) external;
}

/**
 * @title Represents a vault.
 */
contract Vault is Controllable {
    // The decimal multiplier of the receipt token
    uint256 private constant USDF_DECIMAL_MULTIPLIER = uint256(10) ** uint256(6);

    // Represents a record
    struct Record {
        uint256 apr;
        uint256 tokenPrice;
        uint256 totalDeposited;
        uint256 dailyInterest;
    }

    /**
     * @notice The timestamp that defines the start of the current year, per contract deployment.
     * @dev This is the unix epoch of January 1st since the contract deployment.
     */
    uint256 public startOfYearTimestamp;

    /**
     * @notice The current period. It is the zero-based day of the year, ranging from [0..364]
     * @dev Day zero represents January 1st (first day of the year) whereas day 364 represents December 31st (last day of the day)
     */
    uint256 public currentPeriod;

    /**
     * @notice The minimum amount you can deposit in the vault.
     */
    uint256 public minDepositAmount;

    /**
     * @notice The flat fee to apply to vault withdrawals.
     */
    uint256 public flatFeePercent;

    // The decimals multiplier of the underlying ERC20
    uint256 immutable private _decimalsMultiplier;

    /**
     * @notice The percentage of capital that needs to be invested. It ranges from [1..99]
     * @dev The investment percent is set to 90% by default
     */
    uint8 public investmentPercent = 90;

    // The reentrancy guard for deposits
    uint8 private _reentrancyMutexForDeposits;

    // The reentrancy guard for withdrawals
    uint8 private _reentrancyMutexForWithdrawals;

    /**
     * @notice The address of the yield reserve
     */
    address public yieldReserveAddress;

    /**
     * @notice The address that collects the applicable fees
     */
    address public feesAddress;

    /**
     * @notice The interface of the underlying token
     */
    IERC20 public immutable underlyingTokenInterface;

    // The receipt token. This is immutable so it cannot be altered after deployment.
    ReceiptToken private immutable _receiptToken;

    // The snapshots history
    mapping (uint256 => Record) private _records;

    // ---------------------------------------
    // Events
    // ---------------------------------------
    /**
     * @notice This event is fired when the vault receives a deposit.
     * @param tokenAddress Specifies the token address
     * @param fromAddress Specifies the address of the sender
     * @param depositAmount Specifies the deposit amount in USDC or the ERC20 handled by this contract
     * @param receiptTokensAmount Specifies the amount of receipt tokens issued to the user
     */
    event OnVaultDeposit (address tokenAddress, address fromAddress, uint256 depositAmount, uint256 receiptTokensAmount);

    /**
     * @notice This event is fired when a user withdraws funds from the vault.
     * @param tokenAddress Specifies the token address
     * @param toAddress Specifies the address of the recipient
     * @param erc20Amount Specifies the amount in USDC or the ERC20 handled by this contract
     * @param receiptTokensAmount Specifies the amount of receipt tokens withdrawn by the user
     * @param fee Specifies the withdrawal fee
     */
    event OnVaultWithdrawal (address tokenAddress, address toAddress, uint256 erc20Amount, uint256 receiptTokensAmount, uint256 fee);

    event OnTokenPriceChanged (uint256 prevTokenPrice, uint256 newTokenPrice);
    event OnFlatWithdrawalFeeChanged (uint256 prevValue, uint256 newValue);
    event OnYieldReserveAddressChanged (address prevAddress, address newAddress);
    event OnFeesAddressChanged (address prevAddress, address newAddress);
    event OnInvestmentPercentChanged (uint8 prevValue, uint8 newValue);
    event OnCapitalLocked (uint256 amountLocked);
    event OnInterestClaimed (uint256 interestAmount);
    event OnAprChanged (uint256 prevApr, uint256 newApr);
    event OnEmergencyWithdraw (uint256 withdrawalAmount);

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    constructor (
        address ownerAddr, 
        address controllerAddr, 
        ReceiptToken receiptTokenInterface, 
        IERC20 eip20Interface, 
        uint256 initialApr, 
        uint256 initialTokenPrice, 
        uint256 initialMinDepositAmount,
        uint256 flatFeePerc,
        address feesAddr) 
    Controllable (ownerAddr, controllerAddr) {
        // Checks
        require(initialMinDepositAmount > 0, "Invalid min deposit amount");
        require(feesAddr != address(0), "Invalid address for fees");

        // State changes
        underlyingTokenInterface = eip20Interface;
        _receiptToken = receiptTokenInterface;
        minDepositAmount = initialMinDepositAmount;
        _decimalsMultiplier = uint256(10) ** uint256(eip20Interface.decimals());

        uint256 currentTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time

        // Get the current year
        uint256 currentYear = DateUtils.getYear(currentTimestamp);

        // Set the timestamp of January 1st of the current year (the year starts at this unix epoch)
        startOfYearTimestamp = DateUtils.timestampFromDateTime(currentYear, 1, 1, 0, 0, 0);

        // Create the first record
        currentPeriod = DateUtils.diffDays(startOfYearTimestamp, currentTimestamp);
        
        // The APR must be expressed with 2 decimal places. Example: 5% = 500 whereas 5.75% = 575
        _records[currentPeriod] = Record(initialApr, initialTokenPrice, 0, 0);

        flatFeePercent = flatFeePerc;
        feesAddress = feesAddr;
    }

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------
    /**
     * @notice Throws if there is a deposit in progress
     */
    modifier ifNotReentrantDeposit() {
        require(_reentrancyMutexForDeposits == 0, "Reentrant deposit rejected");
        _;
    }

    /**
     * @notice Throws if there is a withdrawal in progress
     */
    modifier ifNotReentrantWithdrawal() {
        require(_reentrancyMutexForWithdrawals == 0, "Reentrant withdrawal rejected");
        _;
    }

    // ---------------------------------------
    // Functions
    // ---------------------------------------
    /**
     * @notice Sets the address of the yield reserve
     * @dev This function can be called by the owner or the controller.
     * @param addr The address of the yield reserve
     */
    function setYieldReserveAddress (address addr) public onlyOwnerOrController {
        require(addr != address(0) && addr != address(this), "Invalid address");
        require(Utils.isContract(addr), "The address must be a contract");

        emit OnYieldReserveAddressChanged(yieldReserveAddress, addr);
        yieldReserveAddress = addr;
    }

    /**
     * @notice Sets the minimum amount for deposits.
     * @dev This function can be called by the owner or the controller.
     * @param minAmount The minimum deposit amount
     */
    function setMinDepositAmount (uint256 minAmount) public onlyOwnerOrController {
        // Checks
        require(minAmount > 0, "Invalid minimum deposit amount");

        // State changes
        minDepositAmount = minAmount;
    }

    /**
     * @notice Sets a new flat fee for withdrawals.
     * @dev The new fee is allowed to be zero (aka: no fees).
     * @param newFeeWithMultiplier The new fee, which is expressed per decimals precision of the underlying token (say USDC for example)
     */
    function setFlatWithdrawalFee (uint256 newFeeWithMultiplier) public onlyOwnerOrController {
        // Example for USDC (6 decimal places):
        // Say the fee is: 0.03%
        // Thus the fee amount is: 0.03 * _decimalsMultiplier = 30000 = 0.03 * (10 to the power of 6)
        emit OnFlatWithdrawalFeeChanged(flatFeePercent, newFeeWithMultiplier);

        flatFeePercent = newFeeWithMultiplier;
    }

    /**
     * @notice Sets the address for collecting fees.
     * @param addr The address
     */
    function setFeeAddress (address addr) public onlyOwnerOrController {
        require(addr != address(0) && addr != feesAddress, "Invalid address for fees");

        emit OnFeesAddressChanged(feesAddress, addr);
        feesAddress = addr;
    }

    /**
     * @notice Sets the total amount deposited in the Vault
     * @dev This function can be called during a migration only. It is guaranteed to fail otherwise.
     * @param newAmount The total amount deposited in the old Vault
     */
    function setTotalDepositedAmount (uint256 newAmount) public onlyOwner {
        require(newAmount > 0, "Non-zero amount required");

        // Make sure no funds were deposited into this contract yet
        require(_records[currentPeriod].totalDeposited == 0, "Deposit amount already set");
        require(_records[currentPeriod].dailyInterest == 0, "Daily interest already set");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance == 0, "Deposits already available");

        // State changes
        _records[currentPeriod].totalDeposited = newAmount;
    }

    /**
     * @notice Deposits funds in the vault. The caller gets the respective amount of receipt tokens in exchange for their deposit.
     * @dev The number of receipt tokens is calculated based on the current token price.
     * @param depositAmount Specifies the deposit amount
     */
    function deposit (uint256 depositAmount) public ifNotReentrantDeposit {
        // Make sure the deposit amount falls within the expected range
        require(depositAmount >= minDepositAmount, "Minimum deposit amount not met");

        // Wake up the reentrancy guard
        _reentrancyMutexForDeposits = 1;

        // Refresh the current timelime, if needed
        compute();

        // Make sure the sender can cover the deposit (aka: has enough USDC/ERC20 on their wallet)
        require(underlyingTokenInterface.balanceOf(msg.sender) >= depositAmount, "Insufficient funds");

        // Make sure the user approved this contract to spend the amount specified
        require(underlyingTokenInterface.allowance(msg.sender, address(this)) >= depositAmount, "Insufficient allowance");

        // Determine how many tokens can be issued/minted to the destination address
        uint256 numberOfReceiptTokens = depositAmount * USDF_DECIMAL_MULTIPLIER / _records[currentPeriod].tokenPrice;

        // Make sure we can issue the number of tokens specified, per limits
        require(_receiptToken.canMint(numberOfReceiptTokens), "Token supply limit exceeded");

        _records[currentPeriod].totalDeposited += depositAmount;

        // Get the current balance of this contract in USDC (or whatever the ERC20 is, which defined at deployment time)
        uint256 balanceBeforeTransfer = underlyingTokenInterface.balanceOf(address(this));

        // Make sure the ERC20 transfer succeeded
        require(underlyingTokenInterface.transferFrom(msg.sender, address(this), depositAmount), "Token transfer failed");

        // The new balance of this contract, after the transfer
        uint256 newBalance = underlyingTokenInterface.balanceOf(address(this));

        // At the very least, the new balance should be the previous balance + the deposit.
        require(newBalance == balanceBeforeTransfer + depositAmount, "Balance verification failed");

        // Issue/mint the respective number of tokens. Users get a receipt token in exchange for their deposit in USDC/ERC20.
        _receiptToken.mint(msg.sender, numberOfReceiptTokens);

        // Emit a new "deposit" event
        emit OnVaultDeposit(address(underlyingTokenInterface), msg.sender, depositAmount, numberOfReceiptTokens);

        // Reset the reentrancy guard
        _reentrancyMutexForDeposits = 0;
    }

    /**
     * @notice Withdraws a specific amount of tokens from the Vault.
     * @param receiptTokenAmount The number of tokens to withdraw from the vault
     */
    function withdraw (uint256 receiptTokenAmount) public ifNotReentrantWithdrawal {
        // Checks
        require(receiptTokenAmount > 0, "Invalid withdrawal amount");

        // Wake up the reentrancy guard
        _reentrancyMutexForWithdrawals = 1;

        // Refresh the current timelime, if needed
        compute();

        // Make sure the sender has enough receipt tokens to burn
        require(_receiptToken.balanceOf(msg.sender) >= receiptTokenAmount, "Insufficient balance of tokens");

        // The amount of USDC you get in exchange, at the current token price
        uint256 withdrawalAmount = toErc20Amount(receiptTokenAmount);
        require(withdrawalAmount <= _records[currentPeriod].totalDeposited, "Invalid withdrawal amount");

        uint256 maxWithdrawalAmount = _records[currentPeriod].totalDeposited * (uint256(100) - uint256(investmentPercent)) / uint256(100);
        require(withdrawalAmount <= maxWithdrawalAmount, "Max withdrawal amount exceeded");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance >= withdrawalAmount, "Insufficient funds in the buffer");

        // Notice that the fee is applied in the underlying currency instead of receipt tokens.
        // The amount applicable to the fee
        uint256 feeAmount = (flatFeePercent > 0) ? withdrawalAmount * flatFeePercent / uint256(100) / _decimalsMultiplier : 0;
        require(feeAmount < withdrawalAmount, "Invalid fee");

        // The amount to send to the destination address (recipient), after applying the fee
        uint256 withdrawalAmountAfterFees = withdrawalAmount - feeAmount;

        // Update the record per amount withdrawn, with no applicable fees.
        // A common mistake would be update the metric below with fees included. DONT DO THAT.
        _records[currentPeriod].totalDeposited -= withdrawalAmount;

        // Burn the number of receipt tokens specified
        _receiptToken.burn(msg.sender, receiptTokenAmount);

        // Transfer the respective amount of underlying tokens to the sender (after applying the fee)
        require(underlyingTokenInterface.transfer(msg.sender, withdrawalAmountAfterFees), "Token transfer failed");

        if (feeAmount > 0) {
            // Transfer the applicable fee, if any
            require(underlyingTokenInterface.transfer(feesAddress, feeAmount), "Fee transfer failed");
        }

        // Emit a new "withdrawal" event
        emit OnVaultWithdrawal(address(underlyingTokenInterface), msg.sender, withdrawalAmount, receiptTokenAmount, feeAmount);

        // Reset the reentrancy guard
        _reentrancyMutexForWithdrawals = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Runs an emergency withdrawal. Sends the whole balance to the address specified.
     * @dev This function can be called by the owner only.
     * @param destinationAddr The destination address
     */
    function emergencyWithdraw (address destinationAddr) public onlyOwner ifNotReentrantWithdrawal {
        require(destinationAddr != address(0) && destinationAddr != address(this), "Invalid address");

        // Wake up the reentrancy guard
        _reentrancyMutexForWithdrawals = 1;

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance > 0, "The vault has no funds");

        // Transfer all funds to the address specified
        require(underlyingTokenInterface.transfer(destinationAddr, currentBalance), "Token transfer failed");

        emit OnEmergencyWithdraw(currentBalance);

        // Reset the reentrancy guard
        _reentrancyMutexForWithdrawals = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Updates the APR
     * @dev The APR must be expressed with 2 decimal places. Example: 5% = 500 whereas 5.75% = 575
     * @param newApr The new APR, expressed with 2 decimal places.
     */
    function changeApr (uint256 newApr) public onlyOwner {
        require(newApr > 0, "Invalid APR");

        compute();

        emit OnAprChanged(_records[currentPeriod].apr, newApr);
        _records[currentPeriod].apr = newApr;
    }

    /**
     * @notice Sets the token price, arbitrarily.
     * @param newTokenPrice The new price of the receipt token
     */
    function setTokenPrice (uint256 newTokenPrice) public onlyOwner {
        require(newTokenPrice > 0, "Invalid token price");

        compute();

        emit OnTokenPriceChanged(_records[currentPeriod].tokenPrice, newTokenPrice);
        _records[currentPeriod].tokenPrice = newTokenPrice;
    }

    /**
     * @notice Sets the investment percent.
     * @param newPercent The new investment percent
     */
    function setInvestmentPercent (uint8 newPercent) public onlyOwnerOrController {
        require(newPercent > 0 && newPercent < 100, "Invalid investment percent");

        emit OnInvestmentPercentChanged(investmentPercent, newPercent);
        investmentPercent = newPercent;
    }

    /**
     * @notice Computes the metrics (token price, daily interest) for the current day of year
     */
    function compute () public {
        uint256 currentTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time

        uint256 newPeriod = DateUtils.diffDays(startOfYearTimestamp, currentTimestamp);
        if (newPeriod <= currentPeriod) return;

        uint256 x = 0;

        for (uint256 i = currentPeriod + 1; i <= newPeriod; i++) {
            x++;
            _records[i].apr = _records[i - 1].apr;
            _records[i].totalDeposited = _records[i - 1].totalDeposited;

            uint256 diff = _records[i - 1].apr * USDF_DECIMAL_MULTIPLIER * uint256(100) / uint256(36500);
            _records[i].tokenPrice = _records[i - 1].tokenPrice + (diff / uint256(10000));
            _records[i].dailyInterest = _records[i - 1].totalDeposited * uint256(_records[i - 1].apr) / uint256(3650000);
            if (x >= 30) break;
        }

        currentPeriod += x;
    }

    /**
     * @notice Moves the deployable capital from the vault to the yield reserve.
     * @dev This function should fail if it would cause the vault to be left with <10% of deposited amount
     */
    function lockCapital () public onlyOwnerOrController ifNotReentrantWithdrawal {
        // Wake up the reentrancy guard
        _reentrancyMutexForWithdrawals = 1;

        compute();

        // Get the maximum amount of capital that can be deployed at this point in time
        uint256 maxDeployableAmount = getDeployableCapital();
        require(maxDeployableAmount > 0, "No capital to deploy");

        require(underlyingTokenInterface.transfer(yieldReserveAddress, maxDeployableAmount), "Transfer failed");
        emit OnCapitalLocked(maxDeployableAmount);

        // Reset the reentrancy guard
        _reentrancyMutexForWithdrawals = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Claims the daily interest promised per APR.
     */
    function claimDailyInterest () public onlyOwnerOrController {
        compute();

        // Get the daily interest that need to be claimed at this point in time
        uint256 dailyInterestAmount = getDailyInterest();

        uint256 balanceBefore = underlyingTokenInterface.balanceOf(address(this));

        IDeployable(yieldReserveAddress).claim(dailyInterestAmount);

        uint256 balanceAfter = underlyingTokenInterface.balanceOf(address(this));

        require(balanceAfter >= balanceBefore + dailyInterestAmount, "Balance verification failed");

        emit OnInterestClaimed(dailyInterestAmount);
    }

    /**
     * @notice Gets the period of the current unix epoch.
     * @dev The period is the zero-based day of the current year. It is the number of days that elapsed since January 1st of the current year.
     * @return Returns a number between [0..364]
     */
    function getPeriodOfCurrentEpoch () public view returns (uint256) {
        return DateUtils.diffDays(startOfYearTimestamp, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    function getSnapshot (uint256 i) public view returns (uint256 apr, uint256 tokenPrice, uint256 totalDeposited, uint256 dailyInterest) {
        apr = _records[i].apr;
        tokenPrice = _records[i].tokenPrice;
        totalDeposited = _records[i].totalDeposited;
        dailyInterest = _records[i].dailyInterest;
    }

    /**
     * @notice Gets the total amount deposited in the vault.
     * @dev This value increases when people deposits funds in the vault. Likewise, it decreases when people withdraw from the vault.
     * @return The total amount deposited in the vault.
     */
    function getTotalDeposited () public view returns (uint256) {
        return _records[currentPeriod].totalDeposited;
    }

    /**
     * @notice Gets the daily interest
     * @return The daily interest
     */
    function getDailyInterest () public view returns (uint256) {
        return _records[currentPeriod].dailyInterest;
    }

    /**
     * @notice Gets the current token price
     * @return The price of the token
     */
    function getTokenPrice () public view returns (uint256) {
        return _records[currentPeriod].tokenPrice;
    }

    /**
     * @notice Gets the maximum amount of USDC/ERC20 you can withdraw from the vault
     * @return The maximum withdrawal amount
     */
    function getMaxWithdrawalAmount () public view returns (uint256) {
        return _records[currentPeriod].totalDeposited * (uint256(100) - uint256(investmentPercent)) / uint256(100);
    }

    /**
     * @notice Gets the amount of capital that can be deployed.
     * @dev This is the amount of capital that will be moved from the Vault to the Yield Reserve.
     * @return The amount of deployable capital
     */
    function getDeployableCapital () public view returns (uint256) {
        // X% of the total deposits should remain in the vault. This is the target vault balance.
        //
        // For example:
        // ------------
        // If the total deposits are 800k USDC and the investment percent is set to 90%
        // then the vault should keep the remaining 10% as a buffer for withdrawals.
        // In this example the vault should keep 80k USDC, which is the 10% of 800k USDC.
        uint256 shouldRemainInVault = _records[currentPeriod].totalDeposited * (uint256(100) - uint256(investmentPercent)) / uint256(100);

        // The current balance at the Vault
        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));

        // Return the amount of deployable capital
        return (currentBalance > shouldRemainInVault) ? currentBalance - shouldRemainInVault : 0;
    }

    /**
     * @notice Returns the amount of USDC you would get by burning the number of receipt tokens specified, at the current price.
     * @return The amount of USDC you get in exchange, at the current token price
     */
    function toErc20Amount (uint256 receiptTokenAmount) public view returns (uint256) {
        return receiptTokenAmount * _records[currentPeriod].tokenPrice / USDF_DECIMAL_MULTIPLIER;
    }
}