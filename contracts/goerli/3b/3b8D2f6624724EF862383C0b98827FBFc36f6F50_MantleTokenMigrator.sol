// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

/// @title Mantle Token Migrator
/// @author 0xMantle
/// @notice Token migration contract for the BIT to MNT token migration
contract MantleTokenMigrator {
    using SafeTransferLib for ERC20;

    /* ========== STATE VARIABLES ========== */

    /// @dev The address of the BIT token contract
    address public immutable BIT_TOKEN_ADDRESS;

    /// @dev The address of the MNT token contract
    address public immutable MNT_TOKEN_ADDRESS;

    /// @dev The numerator of the token conversion rate
    uint256 public immutable TOKEN_CONVERSION_NUMERATOR;

    /// @dev The denominator of the token conversion rate
    uint256 public immutable TOKEN_CONVERSION_DENOMINATOR;

    /// @dev The address of the treasury contract that receives defunded tokens
    address public treasury;

    /// @dev The address of the owner of the contract
    address public owner;

    /// @dev Boolean indicating if this contract is halted
    bool public halted;

    /* ========== EVENTS ========== */

    // TokenSwap Events

    /// @dev Emitted when a user swaps BIT for MNT
    /// @param to The address of the user that swapped BIT for MNT
    /// @param amountOfBitSwapped The amount of BIT swapped
    /// @param amountOfMntReceived The amount of MNT received
    event TokensMigrated(address indexed to, uint256 amountOfBitSwapped, uint256 amountOfMntReceived);

    // Contract State Events

    /// @dev Emitted when the owner of the contract is changed
    /// @param previousOwner The address of the previous owner of this contract
    /// @param newOwner The address of the new owner of this contract
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Emitted when the contract is halted
    /// @param halter The address of the caller that halted this contract
    event ContractHalted(address indexed halter);

    /// @dev Emitted when the contract is unhalted
    /// @param halter The address of the caller that unhalted this contract
    event ContractUnhalted(address indexed halter);

    /// @dev Emitted when the treasury address is changed
    /// @param previousTreasury The address of the previous treasury
    /// @param newTreasury The address of the new treasury
    event TreasuryChanged(address indexed previousTreasury, address indexed newTreasury);

    // Admin Events

    /// @dev Emitted when non BIT/MNT tokens are swept from the contract by the owner to the recipient address
    /// @param token The address of the token contract that was swept
    /// @param recipient The address of the recipient of the swept tokens
    /// @param amount The amount of tokens swept
    event TokensSwept(address indexed token, address indexed recipient, uint256 amount);

    /// @dev Emitted when BIT/MNT tokens are defunded from the contract by the owner to the treasury
    /// @param defunder The address of the defunder
    /// @param token The address of the token contract that was defunded
    /// @param amount The amount of tokens defunded
    event ContractDefunded(address indexed defunder, address indexed token, uint256 amount);

    /* ========== ERRORS ========== */

    /// @notice Thrown when the caller is not the owner and the function being called uses the {onlyOwner} modifier
    /// @param caller The address of the caller
    error MantleTokenMigrator_OnlyOwner(address caller);

    /// @notice Thrown when the contract is halted and the function being called uses the {onlyWhenNotHalted} modifier
    error MantleTokenMigrator_OnlyWhenNotHalted();

    /// @notice Thrown when the input passed into the {_migrateTokens} function is zero
    error MantleTokenMigrator_ZeroSwap();

    /// @notice Thrown when at least one of the inputs passed into the constructor is a zero value
    error MantleTokenMigrator_ImproperlyInitialized();

    /// @notice Thrown when the {_tokenAddress} passed into the {sweepTokens} function is the BIT or MNT token address
    /// @param token The address of the token contract
    error MantleTokenMigrator_SweepNotAllowed(address token);

    /// @notice Thrown when the {_tokenAddress} passed into the {defundContract} function is NOT the BIT or MNT token address
    /// @param token The address of the token contract
    error MantleTokenMigrator_InvalidFundingToken(address token);

    /// @notice Thrown when the contract receives a call with an invalid {msg}.data payload
    /// @param data The msg.data payload
    error MantleTokenMigrator_InvalidMessageData(bytes data);

    /// @notice Thrown when the contract receives a call with a non-zero {msg.value}
    error MantleTokenMigrator_EthNotAccepted();

    /* ========== MODIFIERS ========== */

    /// @notice Modifier that checks that the caller is the owner of the contract
    /// @dev Throws {MantleTokenMigrator_OnlyOwner} if the caller is not the owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert MantleTokenMigrator_OnlyOwner(msg.sender);
        _;
    }

    /// @notice Modifier that checks that the contract is not halted
    /// @dev Throws {MantleTokenMigrator_OnlyWhenNotHalted} if the contract is halted
    modifier onlyWhenNotHalted() {
        if (halted) revert MantleTokenMigrator_OnlyWhenNotHalted();
        _;
    }

    /// @notice Initializes the MantleTokenMigrator contract, setting the initial deployer as the contract owner
    /// @dev _bitTokenAddress, _mntTokenAddress, _tokenConversionNumerator, and _tokenConversionDenominator are immutable: they can only be set once during construction
    /// @dev the contract is initialized in a halted state
    /// @dev Requirements:
    ///     - all parameters must be non-zero
    ///     - _bitTokenAddress and _mntTokenAddress are assumed to have the same number of decimals
    /// @param _bitTokenAddress The address of the BIT token contract
    /// @param _mntTokenAddress The address of the MNT token contract
    /// @param _treasury The address of the treasury contract that receives defunded tokens
    /// @param _tokenConversionNumerator The numerator of the token conversion rate
    /// @param _tokenConversionDenominator The denominator of the token conversion rate
    constructor(
        address _bitTokenAddress,
        address _mntTokenAddress,
        address _treasury,
        uint256 _tokenConversionNumerator,
        uint256 _tokenConversionDenominator
    ) {
        if (
            _bitTokenAddress == address(0) || _mntTokenAddress == address(0) || _treasury == address(0)
                || _tokenConversionNumerator == 0 || _tokenConversionDenominator == 0
        ) revert MantleTokenMigrator_ImproperlyInitialized();

        owner = msg.sender;
        halted = true;

        BIT_TOKEN_ADDRESS = _bitTokenAddress;
        MNT_TOKEN_ADDRESS = _mntTokenAddress;

        treasury = _treasury;

        TOKEN_CONVERSION_NUMERATOR = _tokenConversionNumerator;
        TOKEN_CONVERSION_DENOMINATOR = _tokenConversionDenominator;
    }

    /* ========== FALLBACKS ========== */

    /// @notice Fallback function that reverts if non-valid calldata is sent to the contract
    fallback() external payable {
        if (msg.data.length != 0) revert MantleTokenMigrator_InvalidMessageData(msg.data);
    }

    /// @notice Receive function that reverts if ETH is sent to the contract with a call
    /// @dev This function is called whenever the contract receives ETH
    /// @dev ETH can still be forced into this contract with a selfdestruct, but it has no impact on the contract state
    receive() external payable {
        revert MantleTokenMigrator_EthNotAccepted();
    }

    /* ========== TOKEN SWAPPING ========== */

    /// @notice Swaps all of the caller's BIT tokens for MNT tokens
    /// @dev emits a {TokensMigrated} event
    /// @dev Requirements:
    ///     - The caller must have approved this contract to spend their BIT tokens
    ///     - The caller must have a non-zero balance of BIT tokens
    ///     - The contract must not be halted
    function migrateAllBIT() external onlyWhenNotHalted {
        uint256 amount = ERC20(BIT_TOKEN_ADDRESS).balanceOf(msg.sender);
        _migrateTokens(amount);
    }

    /// @notice Swaps a specified amount of the caller's BIT tokens for MNT tokens
    /// @dev emits a {TokensMigrated} event
    /// @dev Requirements:
    ///     - The caller must have approved this contract to spend at least {_amount} of their BIT tokens
    ///     - The caller must have a balance of at least {_amount} of BIT tokens
    ///     - The contract must not be halted
    /// @param _amount The amount of BIT tokens to swap
    function migrateBIT(uint256 _amount) external onlyWhenNotHalted {
        _migrateTokens(_amount);
    }

    /// @notice Calculates the amount of MNT tokens to be recieved for a given amount of BIT tokens
    /// @param _amount The amount of BIT tokens to swap
    /// @return The amount of MNT tokens to be recieved
    function tokenMigrationAmountToReceive(uint256 _amount) external view returns (uint256) {
        return _tokenSwapCalculation(_amount);
    }

    /// @notice Internal function that swaps a specified amount of the caller's BIT tokens for MNT tokens
    /// @dev emits a {TokensMigrated} event
    /// @dev Requirements:
    ///     - The caller must have approved this contract to spend at least {_amount} of their BIT tokens
    ///     - The caller must have a balance of at least {_amount} of BIT tokens
    /// @param _amount The amount of BIT tokens to swap
    function _migrateTokens(uint256 _amount) internal {
        if (_amount == 0) revert MantleTokenMigrator_ZeroSwap();

        uint256 amountToSwap = _tokenSwapCalculation(_amount);

        // transfer user's BIT tokens to this contract
        ERC20(BIT_TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), _amount);

        // transfer MNT tokens to user, if there are insufficient tokens, in the contract this will revert
        ERC20(MNT_TOKEN_ADDRESS).safeTransfer(msg.sender, amountToSwap);

        emit TokensMigrated(msg.sender, _amount, amountToSwap);
    }

    /// @notice Internal function that calculates the amount of MNT tokens to be recieved for a given amount of BIT tokens
    /// @param _amount The amount of BIT tokens to swap
    /// @return The amount of MNT tokens to be recieved
    function _tokenSwapCalculation(uint256 _amount) internal view returns (uint256) {
        return (_amount * TOKEN_CONVERSION_NUMERATOR) / TOKEN_CONVERSION_DENOMINATOR;
    }

    /* ========== ADMIN UTILS ========== */

    // Ownership Functions

    /// @notice Transfers ownership of the contract to a new address
    /// @dev emits an {OwnershipTransferred} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    // Contract State Functions

    /// @notice Halts the contract, preventing token migrations
    /// @dev emits a {ContractHalted} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function haltContract() public onlyOwner {
        halted = true;

        emit ContractHalted(msg.sender);
    }

    /// @notice Unhalts the contract, allowing token migrations
    /// @dev emits a {ContractUnhalted} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function unhaltContract() public onlyOwner {
        halted = false;

        emit ContractUnhalted(msg.sender);
    }

    /// @notice Sets the treasury address
    /// @dev emits a {TreasuryChanged} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    function setTreasury(address _treasury) public onlyOwner {
        address oldTreasury = treasury;
        treasury = _treasury;

        emit TreasuryChanged(oldTreasury, _treasury);
    }

    // Token Management Functions

    /// @notice Defunds the contract by transferring a specified amount of BIT or MNT tokens to the treasury address
    /// @dev emits a {ContractDefunded} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    ///     - {_tokenAddress} must be either the BIT or the MNT token address
    ///     - The contract must have a balance of at least {_amount} of {_tokenAddress} tokens
    /// @param _tokenAddress The address of the token to defund
    /// @param _amount The amount of tokens to defund
    function defundContract(address _tokenAddress, uint256 _amount) public onlyOwner {
        if (_tokenAddress != BIT_TOKEN_ADDRESS && _tokenAddress != MNT_TOKEN_ADDRESS) {
            revert MantleTokenMigrator_InvalidFundingToken(_tokenAddress);
        }

        // we can only defund BIT or MNT into the predefined treasury address
        ERC20(_tokenAddress).safeTransfer(treasury, _amount);

        emit ContractDefunded(treasury, _tokenAddress, _amount);
    }

    /// @notice Sweeps a specified amount of tokens to an arbitrary address
    /// @dev emits a {TokensSwept} event
    /// @dev Requirements:
    ///     - The caller must be the contract owner
    ///     - {_tokenAddress} must not the BIT or the MNT token address
    ///     - The contract must have a balance of at least {_amount} of {_tokenAddress} tokens
    /// @param _tokenAddress The address of the token to sweep
    /// @param _recipient The address to sweep the tokens to
    /// @param _amount The amount of tokens to sweep
    function sweepTokens(address _tokenAddress, address _recipient, uint256 _amount) public onlyOwner {
        // we can only sweep tokens that are not BIT or MNT to an arbitrary addres
        if ((_tokenAddress == address(BIT_TOKEN_ADDRESS)) || (_tokenAddress == address(MNT_TOKEN_ADDRESS))) {
            revert MantleTokenMigrator_SweepNotAllowed(_tokenAddress);
        }
        ERC20(_tokenAddress).safeTransfer(_recipient, _amount);

        emit TokensSwept(_tokenAddress, _recipient, _amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}