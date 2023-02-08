//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

/// @author Kenji Sato
/// @title Hakkaido Token Contract
/// @custom:telegram https://t.me/hokkaido_ai
/// @custom:website https://hokkaido.ai
/// @custom:twitter https://twitter.com/hokk_hokkaidoai

contract Hokkaido is IERC20 {
    address public owner;

    uint256 public totalSupply;

    // Mapping of account addresses to their respective balances
    mapping(address => uint256) public balances;
    // Mapping of holder addresses to a mapping of spender addresses to their respective allowances
    mapping(address => mapping(address => uint256)) public allowances;

    // Constants for token name, symbol and decimals
    string private constant NAME = "Hokkaido";
    string private constant SYMBOL = "Hokk";
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
    constructor(uint256 amount) {
        // Assign the totalSupply to the given amount
        totalSupply = amount;
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
        // Ensure that the `sender` address is not the zero address
        require(
            sender != address(0),
            "Error: Transfer from the zero address is not allowed."
        );

        // Ensure that the `recipient` address is not the zero address
        require(
            recipient != address(0),
            "Error: Transfer to the zero address is not allowed."
        );

        // Check the balance of the `sender` to make sure the transfer amount is valid
        uint256 senderBalance = balances[sender];
        require(
            senderBalance >= amount,
            "Error: Transfer amount exceeds the sender's balance."
        );

        // Perform the transfer
        balances[sender] -= amount;
        balances[recipient] += amount;

        // Emit the Transfer event
        emit Transfer(sender, recipient, amount);

        // Return true to indicate the transfer was successful
        return true;
    }
}