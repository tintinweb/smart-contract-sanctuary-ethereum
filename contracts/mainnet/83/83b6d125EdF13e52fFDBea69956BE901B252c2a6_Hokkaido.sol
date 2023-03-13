//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title IERC20 Token Standard
/// @notice Interface for the ERC20 standard token contract
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// @title Interface for UniswapV2Factory Contract
/// @notice It is used to create new instances of pairs
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

/// @title Interface for UniswapV2Router02 Contract
/// @notice It is used to get information about liquidity reserves
interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

/// @author Kenji Sato
/// @title Hakkaido Token Contract
/// @notice Hokkaido token is a utility token created for use on the Hokkaido platform,
/// acting as an intermediary between the user's token and Uniswap pool.
/// It implements the IERC20 token standard.
/// @custom:website https://www.hokkaido.ai
/// @custom:telegram https://t.me/hokk_token
/// @custom:twitter https://twitter.com/hokk_token
contract Hokkaido is IERC20 {
    // Address of the owner of the contract
    address public owner;

    // Total supply of the token
    uint256 public totalSupply;

    // Mapping of account addresses to their respective balances
    mapping(address => uint256) public balances;
    // Mapping of holder addresses to a mapping of spender addresses to their respective allowances
    mapping(address => mapping(address => uint256)) public allowances;

    // The timestamp when the time lock for purchasing tokens ends
    // This is an anti-sniping bot measure to prevent purchases from the Uniswap during the specified time frame
    uint256 public purchaseTimeLockEnd;

    // The maximum number of tokens that a wallet can hold
    // This is a measure to prevent price manipulation
    // The maxWallet restriction will be removed after 24 hours from allowing trading
    uint256 public maxWallet;

    // The timestamp indicating the end time of the period during
    // which a maximum wallet size is enforced
    uint256 public maxWalletEndTime;

    // The Uniswap V2 router contract
    IUniswapV2Router public uniswapV2Router;
    // The address of the Uniswap V2 liquidity pool for the token
    address public uniswapV2Pair;

    // Constants for token name, symbol and decimals
    string private constant NAME = "Hokkaido";
    string private constant SYMBOL = "HOKK";
    uint8 private constant DECIMALS = 18;

    // Event for transferring ownership of the contract
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Modifier to only allow the contract owner to execute a function
    modifier onlyOwner() {
        require(msg.sender == owner, "Error: Caller is not the contract owner");
        _;
    }

    // Contract constructor
    constructor(uint256 amount, uint256 timelock) {
        // Create a new instance of IUniswapV2Router
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Assign the new instance to the uniswapV2Router variable
        uniswapV2Router = _uniswapV2Router;
        // Create a new Uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // Assign the time lock for purchasing tokens
        purchaseTimeLockEnd = timelock;

        // Assign the end time of the period during which a maximum wallet size is enforced
        maxWalletEndTime = purchaseTimeLockEnd + 24 hours;

        // Assign the totalSupply to the given amount
        totalSupply = amount;
        // Assign the maxWallet to 2% of the totalSupply
        maxWallet = (totalSupply * 2) / 100;
        // Assign the full amount to the balance of the contract creator
        balances[msg.sender] = totalSupply;

        // Emit a Transfer event from address 0 to the contract creator with the totalSupply as the value
        emit Transfer(address(0), msg.sender, totalSupply);
        // Set the owner to the contract creator
        owner = msg.sender;
    }

    /**
     * @dev Returns the balance of the specified address.
     * @param account The address to retrieve the balance of.
     * @return The balance of the specified address.
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    /**
     * @dev Returns the allowance of a spender for a given holder.
     * @param holder The address of the holder.
     * @param spender The address of the spender.
     * @return The allowance of the spender for the given holder.
     */
    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[holder][spender];
    }

    /**
     * @dev Returns the name of the token.
     * @return string memory The name of the token.
     */
    function name() external pure returns (string memory) {
        return NAME;
    }

    /**
     * @dev Returns the symbol of the token.
     * @return string memory The symbol of the token.
     */
    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    /**
     * @dev Returns the number of decimal places used to represent the token amount.
     * @return uint8 The number of decimal places used to represent the token amount.
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Approves the given spender to transfer the specified amount from the msg.sender's account.
     * @param spender The address of the spender to approve.
     * @param amount The amount of token to be approved for transfer.
     * @return bool True if the approval was successful.
     */
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Renounces ownership of the contract.
     */
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers the specified amount of tokens from the sender to the recipient on behalf of the sender.
     * @param sender The address of the token holder to transfer from.
     * @param recipient The address of the recipient to transfer to.
     * @param amount The amount of token to be transferred.
     * @return bool True if the transfer was successful.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        // Check if the allowance is sufficient
        require(
            allowances[sender][msg.sender] >= amount,
            "Error: insufficient allowance."
        );

        // Decrease the allowance
        allowances[sender][msg.sender] -= amount;

        return _transfer(sender, recipient, amount);
    }

    /**
     * @dev Transfers the specified amount of tokens from the msg.sender's account to the recipient.
     * @param recipient The address of the recipient to transfer to.
     * @param amount The amount of token to be transferred.
     * @return bool True if the transfer was successful.
     */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, recipient, amount);
    }

    /**
     * @dev Transfers the ownership of the contract to the new owner.
     * @param newOwner The address of the new owner.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Transfers `amount` tokens from `sender` to `recipient`.
     *
     * @param sender The address of the sender.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens to transfer.
     *
     * @return A boolean indicating whether the transfer was successful.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        // Ensure that the `sender` and `recipient` addresses are not the zero address
        require(
            sender != address(0) && recipient != address(0),
            "Error: Transfer from/to the zero address is not allowed."
        );

        // Check the balance of the `sender` to make sure the transfer amount is valid
        uint256 senderBalance = balances[sender];
        require(
            senderBalance >= amount,
            "Error: Transfer amount exceeds the sender's balance."
        );

        // Prevent purchases from the Uniswap during a specified time lock period
        // which serves as an anti-sniping bot measure.
        if (sender == uniswapV2Pair && block.timestamp < purchaseTimeLockEnd) {
            revert(
                "Error: Purchase from Uniswap DEX not allowed during timelock period."
            );
        }

        // Check whether the maxWallet restriction is in effect
        // and the recipient is not the UniswapV2 pair since we need to add liquidity
        if (block.timestamp < maxWalletEndTime && recipient != uniswapV2Pair) {
            // Check whether the sum of the recipient's current balance
            // and the transferred amount exceeds the maxWallet limit
            require(
                balances[recipient] + amount <= maxWallet,
                "Error: Recipient balance exceeds maximum wallet size."
            );
        } else if (
            block.timestamp >= maxWalletEndTime && maxWalletEndTime != 0
        ) {
            // Remove the maxWallet restriction after the specified time lock period
            maxWallet = totalSupply;
            maxWalletEndTime = 0;
        }

        // Perform the transfer
        balances[sender] -= amount;
        balances[recipient] += amount;

        // Emit the Transfer event
        emit Transfer(sender, recipient, amount);

        // Return true to indicate the transfer was successful
        return true;
    }
}