/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        _owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only owner requirement");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Destroys the smart contract.
     * @param addr The payable address of the recipient.
     */
    function destroy(address payable addr) public virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        selfdestruct(addr);
    }

    /**
     * @notice Gets the address of the owner.
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Indicates if the address specified is the owner of the resource.
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPLv3
pragma solidity 0.8.3;

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
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

////import "./IERC20.sol";

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
    function executeErc20Transfer (address from, address to, uint256 value) private returns (bool) {
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
    function approveSpender(address ownerAddr, address spender, uint256 value) private returns (bool) {
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
        require (executeErc20Transfer(msg.sender, to, value), "Failed to execute ERC20 transfer");
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
        require (executeErc20Transfer(from, to, value), "Failed to execute transferFrom");

        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "Amount exceeds allowance");

        require(approveSpender(from, msg.sender, currentAllowance - value), "ERC20: Approval failed");

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
        require(approveSpender(msg.sender, spender, value), "ERC20: Approval failed");
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
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

// The standard interface of ERC-20
////import "./ERC20.sol";

// The contract for ownership
////import "./../access/Ownable.sol";

contract Mintable is ERC20, Ownable {
    mapping (address => bool) internal _authorizedMinters;
    mapping (address => bool) internal _authorizedBurners;

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
    }

    /**
     * @notice Revokes the right to issue new tokens from the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function revokeMinter (address addr) public onlyOwner {
        require(_authorizedMinters[addr], "Address was never authorized");
        _authorizedMinters[addr] = false;
    }

    /**
     * @notice Grants the right to burn tokens to the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function grantBurner (address addr) public onlyOwner {
        require(!_authorizedBurners[addr], "Address authorized already");
        _authorizedBurners[addr] = true;
    }

    /**
     * @notice Revokes the right to burn tokens from the address specified.
     * @dev This function can be called by the owner only.
     * @param addr The destination address
     */
    function revokeBurner (address addr) public onlyOwner {
        require(_authorizedBurners[addr], "Address was never authorized");
        _authorizedBurners[addr] = false;
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

        _totalSupply += amount;
        _balances[addr] += amount;
        emit Transfer(address(this), addr, amount);
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
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

// The contract for ownership
////import "./../access/Ownable.sol";

/**
 * @title Represents a controllable resource.
 */
contract Controllable is Ownable {
    // The address of the controller
    address internal _controllerAddress;

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the smart contract
     * @param controllerAddr The address of the controller
     */
    constructor (address ownerAddr, address controllerAddr) Ownable (ownerAddr) {
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != ownerAddr, "Owner cannot be the Controller");
        _controllerAddress = controllerAddr;
    }

    /**
     * @notice Throws if the sender is not the controller
     */
    modifier onlyController() {
        require(msg.sender == _controllerAddress, "Unauthorized controller");
        _;
    }

    /**
     * @notice Makes sure the sender is either the owner of the contract or the controller
     */
    modifier onlyOwnerOrController() {
        require(msg.sender == _controllerAddress || msg.sender == _owner, "Only owner or controller");
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
        require(controllerAddr != _owner, "Owner cannot be the Controller");
        require(controllerAddr != _controllerAddress, "Controller already set");

        // State changes
        _controllerAddress = controllerAddr;
    }

    /**
     * @notice Gets the address of the controller
     * @return Returns an address
     */
    function getControllerAddress () public view returns (address) {
        return _controllerAddress;
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

// Mintable ERC-20
////import "./../standards/Mintable.sol";

/**
 * @title Represents a receipt token. The token is fully compliant with the ERC20 interface.
 * @dev The token can be minted or burnt by whitelisted addresses only. Only the owner is allowed to enable/disable addresses.
 */
contract ReceiptToken is Mintable {
    /**
     * @notice Constructor.
     * @param newOwner The owner of the smart contract.
     */
    constructor (address newOwner) Mintable(newOwner, "Fractal", "USDF", 6, 0) { // solhint-disable-line no-empty-blocks
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

/**
 * @title Defines the interface of the Oracle.
 */
interface IOracle {
    /**
     * @notice Sets the address authorized to update the token price.
     * @dev This function can be called by the contract owner only.
     * @param newAddr The address of the authoritative party
     */
    function setTokenPriceAuthority (address newAddr) external;

    /**
     * @notice Sets the address authorized to update the APR.
     * @dev This function can be called by the contract owner only.
     * @param newAddr The address of the authoritative party
     */
    function setAprAuthority (address newAddr) external;

    /**
     * @notice Updates the token price based on the parameters specified.
     * @param amountDeployed The amount of capital that was deployed
     * @param amountReceived The amount of capital received, or the current balance
     * @param decimalsMultiplier The decimal positions of the underlying token
     */
    function updateTokenPrice (uint256 amountDeployed, uint256 amountReceived, uint256 decimalsMultiplier) external;

    /**
     * @notice Updates the APR
     * @param newApr The new APR
     */
    function changeApr (uint256 newApr) external;

    /**
     * @notice Calculates the token price based on the parameters specified.
     * @param amountDeployed The amount of capital deployed
     * @param currentBalance The current balance of the contract
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the token price
     */
    function calculateTokenPrice (uint256 amountDeployed, uint256 currentBalance, uint256 decimalsMultiplier) external pure returns (uint256);

    /**
     * @notice Converts the amount of receipt tokens specified to the respective amount of the ERC-20 handled by this contract (eg: USDC)
     * @param receiptTokenAmount The number of USDF tokens to convert
     * @param atPrice The token price
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the number of ERC-20 tokens that can be burnt
     */
    function toErc20Amount (uint256 receiptTokenAmount, uint256 atPrice, uint256 decimalsMultiplier) external pure returns (uint256);

    /**
     * @notice Gets the number of tokens to mint based on the amount of USDC/ERC20 specified.
     * @param erc20Amount The amount of USDC/ERC20
     * @param atPrice The token price
     * @return Returns the number of tokens
     */
    function toNumberOfTokens (uint256 erc20Amount, uint256 atPrice) external pure returns (uint256);

    /**
     * @notice Gets the daily interest rate based on the current APR
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the daily interest rate
     */
    function getDailyInterestRate (uint256 decimalsMultiplier) external view returns (uint256);

    /**
     * @notice Gets the current price of the USDF token
     * @return Returns the token price
     */
    function getTokenPrice () external view returns (uint256);
}

/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\Vault.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

// The interface of the oracle
////import "./../oracles/IOracle.sol";

// The receipt token
////import "./../tokens/ReceiptToken.sol";

////import "./../access/Controllable.sol";

/**
 * @title Represents a Vault. It works with a single currency only (for example: USDC)
 */
contract Vault is Controllable {
    // ---------------------------------------
    // Tightly packed declarations
    // ---------------------------------------
    /**
     * @notice The maximum amount you can deposit in the vault.
     */
    uint256 public maxDepositAmount;

    /**
     * @notice The minimum amount you can deposit in the vault.
     */
    uint256 public minDepositAmount;

    // The amount of uninvested capital. This is the total amount of sight deposits received by the Vault prior deploying capital.
    uint256 private _uninvestedCapital;

    // The amount of deployable capital. This is the amount to send to the yield reserve.
    uint256 private _deployableCapital;

    /**
     * @notice The timelock for deposits, in hours
     */
    uint256 public depositsTimeLock = 26;

    // The decimals multiplier of the underlying ERC20
    uint256 immutable private _decimalsMultiplier;

    /**
     * @notice The percentage of capital that needs to be invested (eg: 90 = Send 90% of the funds to the yield reserve)
     * @dev The security buffer is computed as 100 - investmentPercent ==> 100% - 90% = 10% 
     */
    uint8 public investmentPercent;

    // The reentrancy guard for deposits
    uint8 private _reentrancyGuardForDeposits;

    // The reentrancy guard for withdrawals
    uint8 private _reentrancyGuardForWithdrawals;

    // The reentrancy guard for capital deployments
    uint8 private _reentrancyGuardForCapital;

    /**
     * @notice The interface of the underlying token
     */
    IERC20 public immutable tokenInterface;

    /**
     * @notice The address of the yield reserve
     */
    address public immutable yieldReserveAddress;

    // The receipt token. This is immutable so it cannot be altered after deployment.
    ReceiptToken private immutable _receiptToken;

    // The interface of the oracle
    IOracle private immutable _oracle;

    // The timelock for user deposits
    mapping (address => uint256) private _timelocks;

    // ---------------------------------------
    // Events
    // ---------------------------------------
    /**
     * @notice This event is fired when the vault receives a deposit
     * @param tokenAddress Specifies the token address
     * @param fromAddress Specifies the address of the sender
     * @param depositAmount Specifies the deposit amount in USDC or the ERC20 handled by this contract
     * @param receiptTokensAmount Specifies the amount of receipt tokens issued to the user
     */
    event OnVaultDeposit (address tokenAddress, address fromAddress, uint256 depositAmount, uint256 receiptTokensAmount);

    /**
     * @notice This event is fired when a user withdraws funds from the vault
     * @param tokenAddress Specifies the token address
     * @param toAddress Specifies the address of the recipient
     * @param erc20Amount Specifies the amount in USDC or the ERC20 handled by this contract
     * @param receiptTokensAmount Specifies the amount of receipt tokens withdrawn by the user
     */
    event OnVaultWithdrawal (address tokenAddress, address toAddress, uint256 erc20Amount, uint256 receiptTokensAmount);

    /**
     * @notice This event is fired when funds are sent to the yield reserve
     * @param fromAddress Specifies the address of the vault
     * @param toAddress Specifies the address of the bridge
     * @param amount Specifies the amount that was locked
     */
    event OnCapitalLocked (address fromAddress, address toAddress, uint256 amount);

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    /**
     * @notice Constructor
     * @param ownerAddr The owner of the vault
     * @param controllerAddr The controller of the vault
     * @param receiptToken The receipt token
     * @param underlyingTokenInterface The interface of the underlying ERC-20
     * @param oracleInterface The interface of the oracle
     * @param yieldReserve The yield reserve
     * @param initialMinDepositAmount The minimum deposit amount
     * @param initialMaxDepositAmount The maximum deposit amount
     * @param initialInvestmentPercent The initial investment percent
     */
    constructor (address ownerAddr, address controllerAddr, ReceiptToken receiptToken, IERC20 underlyingTokenInterface, IOracle oracleInterface, address yieldReserve, uint256 initialMinDepositAmount, uint256 initialMaxDepositAmount, uint8 initialInvestmentPercent) Controllable (ownerAddr, controllerAddr) {
        require(address(underlyingTokenInterface) != address(0), "Invalid address for ERC20");
        require(address(receiptToken) != address(0), "non-zero address required for RT");
        require(address(receiptToken) != address(underlyingTokenInterface), "Invalid Receipt Token");
        require(address(oracleInterface) != address(0), "Invalid address for oracle");
        require(address(yieldReserve) != address(0), "Invalid address for reserve");
        require(initialInvestmentPercent > 0 && initialInvestmentPercent < 100, "Invalid threshold for capital");
        require(initialMinDepositAmount > 0, "Invalid min deposit amount");
        require(initialMaxDepositAmount > initialMinDepositAmount, "Invalid maximum amount");

        tokenInterface = underlyingTokenInterface;
        _receiptToken = receiptToken;
        _oracle = oracleInterface;
        yieldReserveAddress = yieldReserve;
        investmentPercent = initialInvestmentPercent;
        minDepositAmount = initialMinDepositAmount;
        maxDepositAmount = initialMaxDepositAmount;
        _decimalsMultiplier = uint256(10) ** uint256(underlyingTokenInterface.decimals());
    }

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------
    /**
     * @notice Throws if there is a deposit in progress
     */
    modifier ifNotReentrantDeposit() {
        require(_reentrancyGuardForDeposits == 0, "Reentrant deposit rejected");
        _;
    }

    /**
     * @notice Throws if there is a withdrawal in progress
     */
    modifier ifNotReentrantWithdrawal() {
        require(_reentrancyGuardForWithdrawals == 0, "Reentrant withdrawal rejected");
        _;
    }

    /**
     * @notice Throws if there is a capital lock in progress
     */
    modifier ifNotReentrantCapitalLock() {
        require(_reentrancyGuardForCapital == 0, "Reentrant withdrawal rejected");
        _;
    }

    // ---------------------------------------
    // Functions
    // ---------------------------------------
    /**
     * @notice Sets the investment percent. It is the percent of capital that must be deployed in the run.
     * @dev This function can be called by the owner or the controller.
     * @param investmentPerc The percentage
     */
    function setInvestmentPercent (uint8 investmentPerc) public onlyOwnerOrController {
        require(investmentPerc > 0 && investmentPerc < 100, "Invalid threshold");
        investmentPercent = investmentPerc;
    }

    /**
     * @notice Sets the timelock for deposits.
     * @dev This function can be called by the owner or the controller.
     * @param newDepositsTimeLock The timelock, in hours.
     */
    function setDepositsTimeLock (uint256 newDepositsTimeLock) public onlyOwnerOrController {
        require(newDepositsTimeLock > 5 && newDepositsTimeLock < 170, "Invalid timelock for deposits");
        require(newDepositsTimeLock != depositsTimeLock, "Deposits Timelock already set");
        depositsTimeLock = newDepositsTimeLock;
    }

    /**
     * @notice Sets the maximum amount for deposits.
     * @dev This function can be called by the owner or the controller.
     * @param minAmount The minimum deposit amount
     * @param maxAmount The maximum deposit amount
     */
    function setMinMaxDepositAmount (uint256 minAmount, uint256 maxAmount) public onlyOwnerOrController {
        // Checks
        require(minAmount > 0, "Invalid minimum deposit amount");
        require(maxAmount > minAmount, "Invalid maximum deposit amount");

        // State changes
        maxDepositAmount = maxAmount;
        minDepositAmount = minAmount;
    }

    /**
     * @notice Deposits USDC/ERC20 in this contract and gets receipt tokens in exchange.
     * @dev This function is publicly available on purpose. It can be called by any party.
     * @param depositAmount Specifies the deposit amount
     */
    function deposit (uint256 depositAmount) public ifNotReentrantDeposit {
        // Make sure the deposit amount falls within the expected range
        require(depositAmount >= minDepositAmount, "Minimum deposit amount not met");
        require(depositAmount <= maxDepositAmount, "Maximum deposit amount exceeded");

        // Wake up the reentrancy guard
        _reentrancyGuardForDeposits = 1;

        address senderAddr = msg.sender;

        // Make sure the sender can cover the deposit (aka: has enough USDC/ERC20 on their wallet)
        require(tokenInterface.balanceOf(senderAddr) >= depositAmount, "Insufficient funds");

        // Make sure the user approved this contract to spend the amount specified
        require(tokenInterface.allowance(senderAddr, address(this)) >= depositAmount, "Insufficient allowance");

        // Determine the current price of the token. Make sure the token is not available for free.
        uint256 tokenPrice = _oracle.getTokenPrice();

        // Determine how many tokens can be issued/minted to the destination address
        uint256 numberOfReceiptTokens = _oracle.toNumberOfTokens(depositAmount, tokenPrice);

        // Get the current balance of this contract in USDC (or whatever the ERC20 is, which defined at deployment time)
        uint256 currentBalance = tokenInterface.balanceOf(address(this));

        // This is the balance we expect if the transfer succeeds
        uint256 expectedBalanceAfterTransfer = currentBalance + depositAmount;

        // Make sure the ERC20 transfer succeeded
        require(tokenInterface.transferFrom(senderAddr, address(this), depositAmount), "Token transfer failed");

        // The new balance of this contract, after the transfer
        uint256 newBalance = tokenInterface.balanceOf(address(this));

        // At the very least, the new balance should be the previous balance + the deposit.
        require(newBalance >= expectedBalanceAfterTransfer, "Balance verification failed");

        // Increase the amount of funds received by this contract. These new funds represent on sight deposits (uninvested capital)
        _uninvestedCapital += depositAmount;

        // Update the amount of deployable capital
        _updateDeployableCapital();

        // The sender can withdraw funds in X hours from now
        _timelocks[senderAddr] = block.timestamp + (60 * 60 * depositsTimeLock); // solhint-disable-line not-rely-on-time

        // Issue/mint the respective number of tokens. Users get a receipt token in exchange for their deposit in USDC/ERC20.
        _receiptToken.mint(senderAddr, numberOfReceiptTokens);

        // Emit a new "deposit" event
        emit OnVaultDeposit(address(tokenInterface), senderAddr, depositAmount, numberOfReceiptTokens);

        // Reset the reentrancy guard
        _reentrancyGuardForDeposits = 0;
    }

    /**
     * @notice Withdraws a specific amount of tokens from the Vault.
     * @param receiptTokenAmount The number of tokens to withdraw from the vault
     */
    function withdraw (uint256 receiptTokenAmount) public ifNotReentrantWithdrawal {
        require(receiptTokenAmount > 0, "Invalid withdrawal amount");

        // Wake up the reentrancy guard
        _reentrancyGuardForWithdrawals = 1;

        address senderAddr = msg.sender;

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > _timelocks[senderAddr], "Timelocked withdrawal rejected");

        // Make sure the sender has enough receipt tokens to burn
        require(_receiptToken.balanceOf(senderAddr) >= receiptTokenAmount, "Insufficient balance of tokens");

        // Determine the current price of the token. Make sure the token is not available for free.
        uint256 tokenPrice = _oracle.getTokenPrice();

        // The amount of ERC-20 tokens to get in exchange (eg: USDC)
        uint256 erc20Amount = _oracle.toErc20Amount(receiptTokenAmount, tokenPrice, _decimalsMultiplier);
        require(erc20Amount > 0, "Invalid ERC20 amount");

        uint256 currentBalance = tokenInterface.balanceOf(address(this));
        require(currentBalance >= erc20Amount, "Insufficient funds in the buffer");

        // The uninvested capital is zero right after funds are sent to the yield reserve.
        // If we make a withdrawal and the uninvested capital is zero then there is no need to update the deployable capital.
        if (_uninvestedCapital > 0) {
            // The user withdraws funds before locking capital.
            // In this case we must decrease the amount of funds deposited accordingly, due to the withdrawal
            _uninvestedCapital = (erc20Amount >= _uninvestedCapital) ? 0 : _uninvestedCapital - erc20Amount;

            // Update the deployable capital accordingly
            _updateDeployableCapital();
        }

        // Burn the number of receipt tokens specified
        _receiptToken.burn(senderAddr, receiptTokenAmount);

        // Run the token transfer
        require(tokenInterface.transfer(senderAddr, erc20Amount), "Token transfer failed");

        // Emit a new "withdrawal" event
        emit OnVaultWithdrawal(address(tokenInterface), senderAddr, erc20Amount, receiptTokenAmount);

        // Reset the reentrancy guard
        _reentrancyGuardForWithdrawals = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Runs an emergency withdrawal. Sends the whole balance to the address specified.
     * @dev This function can be called by the owner only.
     * @param destinationAddr The destination address
     */
    function emergencyWithdraw (address destinationAddr) public onlyOwner ifNotReentrantWithdrawal {
        require(destinationAddr != address(0) && destinationAddr != address(this), "Invalid address");

        // Wake up the reentrancy guard
        _reentrancyGuardForWithdrawals = 1;

        uint256 currentBalance = tokenInterface.balanceOf(address(this));
        require(currentBalance > 0, "The vault has no funds");

        // Transfer all funds to the address specified
        require(tokenInterface.transfer(destinationAddr, currentBalance), "Token transfer failed");

        // Reset the reentrancy guard
        _reentrancyGuardForWithdrawals = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Locks the amount of deployable capital and transfers such amount to the yield reserve.
     * @dev This function can only be called by the controller.
     */
    function lockCapital () public onlyController ifNotReentrantCapitalLock {
        // Wake up the reentrancy guard
        _reentrancyGuardForCapital = 1;

        // The amount of USDC/ERC20 to be transferred to the yield reserve
        uint256 transferAmount = _deployableCapital;

        // Make sure the contract holds enough funds for the capital deployment
        uint256 currentBalance = tokenInterface.balanceOf(address(this));
        require(currentBalance >= transferAmount, "Insufficient balance for lock");

        // Update the investment amounts
        _uninvestedCapital = 0;
        _updateDeployableCapital();

        // Send the deployable capital to the yield reserve
        require(tokenInterface.transfer(yieldReserveAddress, transferAmount), "Yield reserve transfer failed");

        // Emit the "Capital locked" event
        emit OnCapitalLocked(address(this), yieldReserveAddress, transferAmount);

        // Reset the reentrancy guard
        _reentrancyGuardForCapital = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Updates the amount of deployable capital
     */
    function _updateDeployableCapital () private {
        _deployableCapital = (_uninvestedCapital == 0) ? 0 : (uint256(investmentPercent) * _uninvestedCapital / uint256(100));
    }

    // ---------------------------------------
    // Views
    // ---------------------------------------
    /**
     * @notice Gets the current balance of the contract in USDC/ERC20
     * @return Returns the balance
     */
    function getCurrentBalance () public view returns (uint256) {
        return tokenInterface.balanceOf(address(this));
    }

    /**
     * @notice Gets the amount of uninvested capital. This is the total amount of deposits received by the Vault prior making a capital deployment.
     * @return Returns the amount of uninvested capital.
     */
    function getUninvestedCapital () public view returns (uint256) {
        return _uninvestedCapital;
    }

    /**
     * @notice Gets the amount of deployable capital.
     * @return Returns the amount of deployable capital.
     */
    function getDeployableCapital () public view returns (uint256) {
        return _deployableCapital;
    }

    /**
     * @notice Indicates if the contract can deploy the uninvested capital.
     * @return Returns true if capital can be deployed
     */
    function canDeployCapital () public view returns (bool) {
        return (_deployableCapital > 0) && (tokenInterface.balanceOf(address(this)) >= _deployableCapital);
    }
}