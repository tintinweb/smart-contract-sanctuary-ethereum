/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
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
 * @notice This library provides stateless, general purpose functions.
 */
library Utils {
    // The number of seconds in a day
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;

    /**
     * @notice Indicates if the address specified represents a smart contract.
     * @dev Notice that this method returns TRUE if the address is a contract under construction
     * @param addr The address to evaluate
     * @return Returns true if the address represents a smart contract
     */
    function isContract (address addr) internal view returns (bool) {
        bytes32 eoaHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return (codeHash != eoaHash && codeHash != 0x0);
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
}

/**
 * @title Represents an Oracle.
 */
contract Oracle is IOracle, Ownable {
    // ---------------------------------------
    // Tightly packed declarations
    // ---------------------------------------
    /**
     * @notice The decimals multiplier of the receipt token
     */
    uint256 public constant USDF_DECIMAL_MULTIPLIER = uint256(10) ** uint256(6);

    /**
     * @notice The target APR. It is set through a governance mechanism.
     */
    uint256 public targetApr;

    // The current price of the USDF token.
    uint256 private _currentTokenPrice;

    /**
     * @notice The APR history
     */
    uint256[] public aprHistory;

    /**
     * @notice The address authorized to update the token price
     */
    address public tokenPriceAuthority;

    /**
     * @notice The address authorized to update the APR
     */
    address public aprAuthority;

    // The reentrancy guard for token price updates
    uint8 private _reentrancyGuardForPriceUpdate;

    // ---------------------------------------
    // Events
    // ---------------------------------------
    /**
     * @notice This event is triggered when the token price gets updated
     * @param newTokenPrice Specifies the new token price
     */
    event OnTokenPriceUpdated (uint256 newTokenPrice);

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    /**
     * @notice Constructor
     * @param ownerAddr The owner of the smart contract
     * @param initialApr The initial APR
     * @param initialTokenPrice The initial price of the token
     */
    constructor (address ownerAddr, uint256 initialApr, uint256 initialTokenPrice) Ownable(ownerAddr) {
        require(initialApr > 0, "APR must be greater than zero");
        require(initialTokenPrice > 0, "Token price cannot be zero");

        targetApr = initialApr;
        _currentTokenPrice = initialTokenPrice;
    }

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------
    /**
     * @notice Throws if a token price update is in progress
     */
    modifier ifNotUpdatingTokenPrice() {
        require(_reentrancyGuardForPriceUpdate == 0, "Token price update in progress");
        _;
    }

    /**
     * @notice Throws if the sender is not authorized to update the token price
     */
    modifier onlyIfTokenPriceAuthority() {
        require(msg.sender == tokenPriceAuthority, "Sender not authorized");
        _;
    }

    /**
     * @notice Throws if the sender is not authorized to update the APR
     */
    modifier onlyIfAprAuthority() {
        require(msg.sender == aprAuthority, "Sender not authorized");
        _;
    }

    // ---------------------------------------
    // Functions
    // ---------------------------------------
    /**
     * @notice Sets the address authorized to update the token price.
     * @dev This function can be called by the contract owner only.
     * @param newAddr The address of the authoritative party
     */
    function setTokenPriceAuthority (address newAddr) public override onlyOwner {
        require(newAddr != address(0), "Invalid address");

        // Make sure the authoritative address is a smart contract.
        // Otherwise, the token price could be set arbitrarily through any EOA defined by the owner.
        require(Utils.isContract(newAddr), "Address must be a smart contract");

        // Likewise, let's make sure the caller is an EOA.
        // Otherwise, the caller could game us through a constructor call (submarine attack).
        // That would allow the owner (EOA) to change the token price through a constructor call (submarine attack).
        // To prevent this, let's make sure the sender (which is the valid owner) is still an EOA per ownership transfers.
        require(!Utils.isContract(msg.sender), "The sender must be an EOA");

        // State changes
        tokenPriceAuthority = newAddr;
    }

    /**
     * @notice Sets the address authorized to update the APR.
     * @dev This function can be called by the contract owner only.
     * @param newAddr The address of the authoritative party
     */
    function setAprAuthority (address newAddr) public override onlyOwner {
        require(newAddr != address(0), "Invalid address");

        // State changes
        aprAuthority = newAddr;
    }

    /**
     * @notice Updates the APR
     * @param newApr The new APR
     */
    function changeApr (uint256 newApr) public override onlyIfAprAuthority {
        require(newApr > 0, "APR must be greater than zero");
        aprHistory.push(targetApr);
        targetApr = newApr;
    }

    /**
     * @notice Updates the token price based on the parameters specified.
     * @param amountDeployed The amount of capital that was deployed
     * @param amountReceived The amount of capital received, or the current balance
     * @param decimalsMultiplier The decimal positions of the underlying token
     */
    function updateTokenPrice (uint256 amountDeployed, uint256 amountReceived, uint256 decimalsMultiplier)
    public override onlyIfTokenPriceAuthority ifNotUpdatingTokenPrice {
        require(amountDeployed > 0, "Amount deployed cannot be zero");
        require(amountReceived > 0, "Amount received cannot be zero");
        require(decimalsMultiplier > 0, "Decimal positions required");

        // Calculate the new price of the token
        uint256 newTokenPrice = calculateTokenPrice(amountDeployed, amountReceived, decimalsMultiplier);
        require(newTokenPrice > 0, "The token price cannot be zero");

        // Wake up the reentrancy guard
        _reentrancyGuardForPriceUpdate = 1;

        // Update the price of the token
        _currentTokenPrice = newTokenPrice;

        // Let others know that the token price was updated
        emit OnTokenPriceUpdated(newTokenPrice);

        // Reset the reentrancy guard
        _reentrancyGuardForPriceUpdate = 0;
    }

    // ---------------------------------------
    // Views
    // ---------------------------------------
    /**
     * @notice Gets the daily interest rate based on the current APR
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the daily interest rate
     */
    function getDailyInterestRate (uint256 decimalsMultiplier) public view override returns (uint256) {
        return (targetApr * 100 * decimalsMultiplier) / 365;
    }

    /**
     * @notice Calculates the token price based on the parameters specified.
     * @param amountDeployed The amount of capital deployed
     * @param currentBalance The current balance of the contract
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the token price
     */
    function calculateTokenPrice (uint256 amountDeployed, uint256 currentBalance, uint256 decimalsMultiplier)
    public pure override returns (uint256) {
        return (currentBalance * decimalsMultiplier) / amountDeployed;
    }

    /**
     * @notice Converts the amount of receipt tokens specified to the respective amount of the ERC-20 handled by this contract (eg: USDC)
     * @param receiptTokenAmount The number of USDF tokens to convert
     * @param atPrice The token price
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the number of ERC-20 tokens that can be burnt
     */
    function toErc20Amount (uint256 receiptTokenAmount, uint256 atPrice, uint256 decimalsMultiplier) public pure override returns (uint256) {
        return receiptTokenAmount * atPrice / decimalsMultiplier;
    }

    /**
     * @notice Gets the number of tokens to mint based on the amount of USDC/ERC20 specified.
     * @param erc20Amount The amount of USDC/ERC20
     * @param atPrice The token price
     * @return Returns the number of tokens
     */
    function toNumberOfTokens (uint256 erc20Amount, uint256 atPrice) public pure override returns (uint256) {
        // The number of tokens (USDF) that can be minted based on the deposit amount
        return erc20Amount * USDF_DECIMAL_MULTIPLIER / atPrice;
    }

    /**
     * @notice Gets the current price of the USDF token
     * @return Returns the token price
     */
    function getTokenPrice () public view override returns (uint256) {
        return _currentTokenPrice;
    }

}