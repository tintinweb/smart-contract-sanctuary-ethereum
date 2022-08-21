/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
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

contract TokenMigration is Ownable {
    // The previous version of the token
    address private immutable _oldTokenAddress;

    // The new version of the token
    address private immutable _newTokenAddress;

    constructor (Mintable fromToken, Mintable toToken, address tokensOwner) Ownable(tokensOwner) {
        require(fromToken.decimals() == toToken.decimals(), "Token precision mismatch");
        _oldTokenAddress = address(fromToken);
        _newTokenAddress = address(toToken);
    }

    function migrateTokens (address[] memory tokenHolderAddresses) public onlyOwner {
        require(tokenHolderAddresses.length <= 30, "Too many holders");

        Mintable fromToken = Mintable(_oldTokenAddress);
        Mintable toToken = Mintable(_newTokenAddress);

        for (uint8 i = 0; i < tokenHolderAddresses.length; i++) {
            address addr = tokenHolderAddresses[i];
            uint256 currentBalance = fromToken.balanceOf(addr);

            if (currentBalance > 0) {
                uint256 prevBalanceAtNextVersion = toToken.balanceOf(addr);
                uint256 expectedBalanceAtNextVersion = prevBalanceAtNextVersion + currentBalance;

                fromToken.burn(addr, currentBalance);
                require(fromToken.balanceOf(addr) == 0, "Redemption failed");

                toToken.mint(addr, currentBalance);
                require(toToken.balanceOf(addr) == expectedBalanceAtNextVersion, "Issuance failed");
            }
        }
    }
}