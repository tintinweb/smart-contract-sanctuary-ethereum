/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returndatasize())

                // Revert with the same message.
                revert(0, returndatasize())
            }

            switch returndatasize()
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returndatasize())

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed output.
                success := 0
            }
        }
    }
}

/**
 * @title Ownable contract using Two-Step Ownership Transfer pattern
 *
 * @dev Contract module which provides a basic access controler mechanism,
 *      where there is an account (an owner) that can be granted exclusive
 *      access specific functions.
 *
 *      The contract owner is changeable through a two-step transfer pattern,
 *      in which a pending owner is assigned by the owner. Afterwards the
 *      pending owner can accept the contract's ownership.
 *
 *      Note that the contract's owner can NOT be set to the zero address,
 *      i.e. the contract can not be without ownership.
 *
 *      The contract's initial owner is the contract deployer.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `onlyOwner`, which can be applied to your functions to
 *      restrict their use to the owner.
 *
 *      This contract is heavily inspired by OpenZeppelin's `Ownable` contract.
 *      For more info see https://github.com/OpenZeppelin/openzeppelin-contracts.
 *
 * @author byterocket
 */
abstract contract Ownable {

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by contract's owner.
    error OnlyCallableByOwner();

    /// @notice Function is only callable by contract's pending owner.
    error OnlyCallableByPendingOwner();

    /// @notice Address for new pending owner is invalid.
    error InvalidPendingOwner();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when new pending owner set.
    event NewPendingOwner(address indexed previousPendingOwner,
                          address indexed newPendingOwner);

    /// @notice Event emitted when new owner set.
    event NewOwner(address indexed previousOwner, address indexed newOwner);

    //--------------------------------------------------------------------------
    // Modifiers

    /// @notice Modifier to guarantee function is only callable by contract's
    ///         owner.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyCallableByOwner();
        }
        _;
    }

    // Note that there is no `onlyPendingOwner` modifier because downstream
    // contracts should not build authentication upon the pending owner.

    //--------------------------------------------------------------------------
    // Storage

    /// @notice The contract's owner.
    address public owner;

    /// @notice The contract's pending owner.
    address public pendingOwner;

    //--------------------------------------------------------------------------
    // Constructor

    constructor() {
        owner = msg.sender;
        // pendingOwner = address(0);
    }

    //--------------------------------------------------------------------------
    // Owner Mutating Functions

    /// @notice Set a new pending owner.
    /// @dev Only callable by current owner.
    /// @dev Current owner as pending owner is invalid.
    /// @param pendingOwner_ The new pending owner.
    function setPendingOwner(address pendingOwner_) external onlyOwner {
        if (pendingOwner_ == msg.sender) {
            revert InvalidPendingOwner();
        }

        emit NewPendingOwner(pendingOwner, pendingOwner_);

        pendingOwner = pendingOwner_;
    }

    /// @notice Accept the contract's ownership as current pending owner.
    /// @dev Only callable by current pending owner.
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) {
            revert OnlyCallableByPendingOwner();
        }

        emit NewOwner(owner, msg.sender);

        owner = msg.sender;
        pendingOwner = address(0);
    }

}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 *
 * @author OpenZeppelin
 */
interface IERC20 {
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
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 *
 * @author OpenZeppelin
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @title Rebasing ERC20 Interface
 *
 * @dev Interface definition for Rebasing ERC20 tokens which have an "elastic"
 *      external balance and "fixed" internal balance.
 *      Each user's external balance is represented as a product of a "scalar"
 *      and the user's internal balance.
 *
 *      In regular time intervals the rebase operation updates the scalar,
 *      which increases or decreases all user balances proportionally.
 *
 *      The standard ERC20 methods are denomintaed in the elastic balance.
 *
 * @author Buttonwood Foundation <https://button.foundation/>
 */
interface IRebasingERC20 is IERC20Metadata {

     /// @notice Returns the fixed balance of the specified address.
    /// @param who The address to query.
    function scaledBalanceOf(address who) external view returns (uint256);

    /// @notice Returns the total fixed supply.
    function scaledTotalSupply() external view returns (uint256);

    /// @notice Transfer all of the sender's balance to a specified address.
    /// @param to The address to transfer to.
    /// @return True on success, false otherwise.
    function transferAll(address to) external returns (bool);

    /// @notice Transfer all balance tokens from one address to another.
    /// @param from The address to send tokens from.
    /// @param to The address to transfer to.
    function transferAllFrom(address from, address to) external returns (bool);

    /// @notice Triggers the next rebase, if applicable.
    function rebase() external;

    /// @notice Event emitted when the balance scalar is updated.
    /// @param epoch The number of rebases since inception.
    /// @param newScalar The new scalar.
    event Rebase(uint256 indexed epoch, uint256 newScalar);

}interface IOracle {

    /// @notice Returns the current underlier's valuation in USD terms
    ///         with 18 decimal precision.
    /// @return uint: USD valuation.
    ///         bool: True if data is valid.
    function getData() external returns (uint, bool);

}
// @todo supplyTarget should never be zero.
// @todo supplyTarget has to use same decimals as ERC20 decimals in constructor.

/**
 * @title The Elastic Receipt Token
 *
 * @dev The Elastic Receipt Token is a rebase token that "continuously"
 *      syncs the token supply with a supply target.
 *
 *      A downstream contract, inheriting from this contract, needs to
 *      implement the `_supplyTarget()` function returning the current
 *      supply target for the Elastic Receipt Token supply.
 *
 *      The downstream contract can mint and burn tokens to addresses with
 *      the assumption that the supply target changes precisely by the amount
 *      of tokens minted/burned.
 *
 *      For example:
 *      Using the Elastic Receipt Token with a treasury as downstream contract
 *      holding assets worth 10_000 USD, and returning that amount in the
 *      `_supplyTarget()` function, leads to a token supply of 10_000.
 *      If a user wants to deposit assets worth 1_000 USD into the treasury,
 *      the treasury fetches the assets from the user and mints 1_000 Elastic
 *      Receipt Tokens to the user.
 *      If the treasury's valuation contracts to 5_000 USD, the tokens balance
 *      of each user, and the total token supply, is decreased by 50%.
 *      In case of an expansion of the treasury valuation, the user balances
 *      and the total token supply is increased by the percentage change of the
 *      treasury's valuation.
 *      Note that the expansion/contraction of the treasury needs to be send
 *      upstream through the `_supplyTarget()` function!
 *
 *      As any elastic supply token, the Elastic Receipt Token defines an
 *      internal (fixed) user balance and an external (elastic) user balance.
 *      The internal balance is called `bits`, the external `tokens`.
 *
 *      -> Internal account balance             `_accountBits[account]`
 *      -> Internal bits-token conversion rate  `_bitsPerToken`
 *      -> Public account balance               `_accountBits[account] / _bitsPerToken`
 *      -> Public total token supply            `_totalTokenSupply`
 *
 * @author merkleplant
 */
abstract contract ElasticReceiptToken is IRebasingERC20 {
    //--------------------------------------------------------------------------
    // !!!        PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH         !!!
    //
    // Anytime there is a division, there is a risk of numerical instability
    // from rounding errors.
    //
    // We make the following guarantees:
    // - If address A transfers x tokens to address B, A's resulting external
    //   balance will be decreased by "precisely" x tokens and B's external
    //   balance will be increased by "precisely" x tokens.
    // - If address A mints x tokens, A's resulting external balance will
    //   increase by "precisely" x tokens.
    // - If address A burns x tokens, A's resulting external balance will
    //   decrease by "precisely" x tokens.
    //
    // We do NOT guarantee that the sum of all balances equals the total token
    // supply. This is because, for any conversion function `f()` that has
    // non-zero rounding error, `f(x0) + f(x1) + ... f(xn)` is not equal to
    // `f(x0 + x1 + ... xn)`.
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Invalid token recipient.
    error InvalidRecipient();

    /// @notice Invalid token amount.
    error InvalidAmount();

    /// @notice Maximum supply reached.
    error MaxSupplyReached();

    //--------------------------------------------------------------------------
    // Modifiers

    /// @dev Modifier to guarantee token recipient is valid.
    modifier validRecipient(address to) {
        if (to == address(0) || to == address(this)) {
            revert InvalidRecipient();
        }
        _;
    }

    /// @dev Modifier to guarantee token amount is valid.
    modifier validAmount(uint amount) {
        if (amount == 0) {
            revert InvalidAmount();
        }
        _;
    }

    /// @dev Modifier to guarantee a rebase operation is executed before any
    ///      state is mutated.
    modifier onAfterRebase() {
        _rebase();
        _;
    }

    //--------------------------------------------------------------------------
    // Constants

    /// @dev Math constant.
    uint private constant MAX_UINT = type(uint).max;

    /// @dev The max supply target allowed.
    /// @dev Note that this constant is internal in order for downstream
    ////     contracts to enforce this constraint directly.
    uint internal constant MAX_SUPPLY = 1_000_000_000e18;

    /// @dev The total amount of bits is a multiple of MAX_SUPPLY so that
    ///      BITS_PER_UNDERLYING is an integer.
    ///      Use the highest value that fits in a uint for max granularity.
    uint private constant TOTAL_BITS = MAX_UINT - (MAX_UINT % MAX_SUPPLY);

    /// @dev Initial conversion rate of bits per unit of denomination.
    uint private constant BITS_PER_UNDERLYING = TOTAL_BITS / MAX_SUPPLY;

    //--------------------------------------------------------------------------
    // Internal Storage

    /// @dev The rebase counter, i.e. the number of rebases executed since
    ///      inception.
    uint private _epoch;

    /// @dev The amount of bits one token is composed of, i.e. the bits-token
    ///      conversion rate.
    uint private _bitsPerToken;

    /// @dev The total supply of tokens. In each mutating function the token
    ///      supply is synced with the underlier's USD valuation.
    uint private _totalTokenSupply;

    /// @dev The user balances, denominated in bits.
    mapping(address => uint) private _accountBits;

    /// @dev The user allowances, denominated in tokens.
    mapping(address => mapping(address => uint)) private _tokenAllowances;

    //--------------------------------------------------------------------------
    // ERC20 Storage

    /// @inheritdoc IERC20Metadata
    string public override name;

    /// @inheritdoc IERC20Metadata
    string public override symbol;

    /// @inheritdoc IERC20Metadata
    uint8 public override decimals;

    //--------------------------------------------------------------------------
    // EIP-2616 Storage

    /// @notice The EIP-712 version.
    string public constant EIP712_REVISION = "1";

    /// @notice The EIP-712 domain hash.
    bytes32 public immutable EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-2612 permit hash.
    bytes32 public immutable PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /// @dev Number of EIP-2612 permits per address.
    mapping(address => uint256) private _nonces;

    //--------------------------------------------------------------------------
    // Constructor

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        // Set IERC20Metadata.
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // Total supply of bits are 'pre-mined' to zero address.
        //
        // During mint, bits are transferred from the zero address and
        // during burn, bits are transferred to the zero address.
        _accountBits[address(0)] = TOTAL_BITS;
    }

    //--------------------------------------------------------------------------
    // Abstract Functions

    /// @dev Returns the current supply target.
    /// @dev Has to be implemented in downstream contract.
    function _supplyTarget() internal virtual returns (uint);

    //--------------------------------------------------------------------------
    // Public ERC20-like Mutating Functions

    /// @inheritdoc IERC20
    function transfer(address to, uint tokens)
        public
        override(IERC20)
        validRecipient(to)
        validAmount(tokens)
        onAfterRebase
        returns (bool)
    {
        uint bits = tokens * _bitsPerToken;

        _transfer(msg.sender, to, tokens, bits);

        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint tokens)
        public
        override(IERC20)
        validRecipient(from)
        validRecipient(to)
        validAmount(tokens)
        onAfterRebase
        returns (bool)
    {
        uint bits = tokens * _bitsPerToken;

        _useAllowance(from, msg.sender, tokens);
        _transfer(from, to, tokens, bits);

        return true;
    }

    /// @inheritdoc IRebasingERC20
    function transferAll(address to)
        public
        override(IRebasingERC20)
        validRecipient(to)
        onAfterRebase
        returns (bool)
    {
        uint bits = _accountBits[msg.sender];
        uint tokens = bits / _bitsPerToken;

        _transfer(msg.sender, to, tokens, bits);

        return true;
    }

    /// @inheritdoc IRebasingERC20
    function transferAllFrom(address from, address to)
        public
        override(IRebasingERC20)
        validRecipient(from)
        validRecipient(to)
        onAfterRebase
        returns (bool)
    {
        uint bits = _accountBits[from];
        uint tokens = bits / _bitsPerToken;

        // Note that a transfer of zero tokens is valid to handle dust.
        if (tokens == 0) {
            // Decrease allowance by one. This is a conservative security
            // compromise as the dust could otherwise be stolen.
            // Note that allowances could be off by one because of this.
            _useAllowance(from, msg.sender, 1);
        } else {
            _useAllowance(from, msg.sender, tokens);
        }

        _transfer(from, to, tokens, bits);

        return true;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint tokens)
        public
        override(IERC20)
        validRecipient(spender)
        returns (bool)
    {
         _tokenAllowances[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /// @notice Increases the amount of tokens that msg.sender has allowed
    ///         to spender.
    /// @param spender The address of the spender.
    /// @param tokens The amount of tokens to increase allowance by.
    /// @return True if successful.
    function increaseAllowance(address spender, uint tokens)
        public
        returns (bool)
    {
        _tokenAllowances[msg.sender][spender] += tokens;

        emit Approval(msg.sender, spender, _tokenAllowances[msg.sender][spender]);
        return true;
    }

    /// @notice Decreases the amount of tokens that msg.sender has allowed
    ///         to spender.
    /// @param spender The address of the spender.
    /// @param tokens The amount of tokens to decrease allowance by.
    /// @return True if successful.
    function decreaseAllowance(address spender, uint tokens)
        public
        returns (bool)
    {
        if (tokens >= _tokenAllowances[msg.sender][spender]) {
            delete _tokenAllowances[msg.sender][spender];
        } else {
            _tokenAllowances[msg.sender][spender] -= tokens;
        }

        emit Approval(msg.sender, spender, _tokenAllowances[msg.sender][spender]);
        return true;
    }

    //--------------------------------------------------------------------------
    // Public IRebasingERC20 Mutating Functions

    /// @inheritdoc IRebasingERC20
    function rebase()
        public
        override(IRebasingERC20)
        onAfterRebase
    {
        // NO-OP because modifier executes rebase.
        return;
    }

    //--------------------------------------------------------------------------
    // Public EIP-2616 Mutating Functions

    // @todo docs, maybe Interface?
    function permit(
        address owner_,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline);

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
                                PERMIT_TYPEHASH,
                                owner_,
                                spender,
                                value,
                                _nonces[owner_]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0)
                    && recoveredAddress == owner_);

            _tokenAllowances[owner_][spender] = value;
        }

        emit Approval(owner_, spender, value);
    }

    //--------------------------------------------------------------------------
    // Public View Functions

    /// @inheritdoc IERC20
    function allowance(address owner_, address spender)
        public
        view
        returns (uint)
    {
        return _tokenAllowances[owner_][spender];
    }

    /// @inheritdoc IERC20
    function totalSupply() public view returns (uint) {
        return _totalTokenSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address who) public view returns (uint) {
        return _accountBits[who] / _bitsPerToken;
    }

    /// @inheritdoc IRebasingERC20
    function scaledTotalSupply() public view returns (uint) {
        return _activeBits();
    }

    /// @inheritdoc IRebasingERC20
    function scaledBalanceOf(address who) public view returns (uint) {
        return _accountBits[who];
    }

    /// @notice Returns the number of successful permits for an address.
    /// @param who The address to check the number of permits for.
    /// @return The number of successful permits.
    function nonces(address who) public view returns (uint256) {
        return _nonces[who];
    }

    /// @notice Returns the EIP-712 domain separator hash.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    keccak256(bytes(name)),
                    keccak256(bytes(EIP712_REVISION)),
                    block.chainid,
                    address(this)
                )
            );
    }

    //--------------------------------------------------------------------------
    // Internal View Functions

    /// @dev Convert tokens (elastic amount) to bits (fixed amount).
    function _tokensToBits(uint tokens) internal view returns (uint) {
        return tokens * _bitsPerToken;
    }

    /// @dev Convert bits (fixed amount) to tokens (elastic amount).
    function _bitsToTokens(uint bits) internal view returns (uint) {
        return bits / _bitsPerToken;
    }

    //--------------------------------------------------------------------------
    // Internal Mutating Functions

    /// @dev Mints an amount of tokens to some address.
    /// @dev It's assumed that the downstream contract increases its supply
    ///      target by exactly the token amount minted!
    function _mint(address to, uint tokens)
        internal
        validRecipient(to)
        validAmount(tokens)
        onAfterRebase
    {
        // Do not mint more than allowed.
        if (_totalTokenSupply + tokens > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // Calculate the amount of bits to mint and the new total amount of
        // active bits.
        uint bitsNeeded;
        if (_bitsPerToken == 0) {
            // Use initial conversion rate for first mint.
            bitsNeeded = tokens * BITS_PER_UNDERLYING;
        } else {
            // Use current conversion rate for non-initial mint.
            bitsNeeded = tokens * _bitsPerToken;
        }
        uint newActiveBits = _activeBits() + bitsNeeded;

        // Increase total token supply and adjust conversion rate only if no
        // conversion rate defined yet. Otherwise the conversion rate should
        // not change as the downstream contract is assumed to increase the
        // supply target by exactly the amount of tokens minted.
        _totalTokenSupply += tokens;
        if (_bitsPerToken == 0) {
            _bitsPerToken = newActiveBits / _totalTokenSupply;
        }

        // Notify about new rebase.
        _epoch++;
        emit Rebase(_epoch, _totalTokenSupply);

        // Transfer newly minted bits from zero address.
        _transfer(address(0), to, tokens, bitsNeeded);
    }

    /// @dev Burns an amount of tokens from some address and returns the
    ///      amount of tokens burned.
    ///      Note that due to rebasing the requested token amount to burn and
    ///      the actual amount burned may differ.
    /// @dev It's assumed that the downstream contract decreases its supply
    ///      target by exactly the token amount burned!
    /// @dev It's not possible to burn all tokens.
    function _burn(address from, uint tokens)
        internal
        validRecipient(from)
        validAmount(tokens)
        // onAfterRebase
        returns (uint)
    {
        // Cache the bit amount of tokens and execute rebase.
        uint bits = tokens * _bitsPerToken;
        _rebase();

        // Re-calculate the token amount and transfer them to zero address.
        tokens = bits / _bitsPerToken;
        _transfer(from, address(0), tokens, bits);

        // Adjust total token supply and conversion rate.
        // Note that it's not possible to withdraw all tokens as this would lead
        //      to a division by 0.
        _totalTokenSupply -= tokens;
        _bitsPerToken = _activeBits() / _totalTokenSupply;

        // Notify about new rebase.
        _epoch++;
        emit Rebase(_epoch, _totalTokenSupply);

        // Return updated tokens amount.
        return tokens;
    }

    //--------------------------------------------------------------------------
    // Private Functions

    /// @dev Internal function to execute a rebase operation.
    ///      Fetches the current supply target from the downstream contract and
    ///      updates the bit-tokens conversion rate and the total token supply.
    function _rebase() private {
        uint supplyTarget = _supplyTarget();

        // Don't run into a div by zero.
        if (supplyTarget == 0) {
            return;
        }

        // Do not accept a supply target higher than MAX_SUPPLY.
        if (supplyTarget > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // Adjust conversion rate and total token supply.
        _bitsPerToken = _activeBits() / supplyTarget;
        _totalTokenSupply = supplyTarget;

        // Notify about new rebase.
        _epoch++;
        emit Rebase(_epoch, supplyTarget);
    }

    /// @dev Internal function returning the total amount of active bits,
    ///      i.e. all bits not held by zero address.
    function _activeBits() private view returns (uint) {
        return TOTAL_BITS - _accountBits[address(0)];
    }

    /// @dev Internal function to transfer bits.
    ///      Note that the bits and tokens are expected to be pre-calculated.
    function _transfer(
        address from,
        address to,
        uint tokens,
        uint bits
    ) private {
        _accountBits[from] -= bits;
        _accountBits[to] += bits;

        if (_accountBits[from] == 0) {
            delete _accountBits[from];
        }

        emit Transfer(from, to, tokens);
    }

    /// @dev Internal function to decrease ERC20 allowance.
    ///      Note that the allowance denomination is in tokens.
    function _useAllowance(
        address owner_,
        address spender,
        uint tokens
    ) private {
        // Note that an allowance of max uint is interpreted as infinite.
        if (_tokenAllowances[owner_][spender] != type(uint).max) {
            _tokenAllowances[owner_][spender] -= tokens;
        }
    }
}
// Interface definition for ButtonWrapper contract, which wraps an
// underlying ERC20 token into a new ERC20 with different characteristics.
// NOTE: "uAmount" => underlying token (wrapped) amount and
//       "amount" => wrapper token amount
interface IButtonWrapper {
    //--------------------------------------------------------------------------
    // ButtonWrapper write methods

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mint(uint256 amount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mintFor(address to, uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burn(uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burnTo(address to, uint256 amount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of underlying tokens withdrawn.
    function burnAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of underlying tokens withdrawn.
    function burnAllTo(address to) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function deposit(uint256 uAmount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function depositFor(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdraw(uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdrawTo(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAllTo(address to) external returns (uint256);

    //--------------------------------------------------------------------------
    // ButtonWrapper view methods

    /// @return The address of the underlying token.
    function underlying() external view returns (address);

    /// @return The total underlying tokens held by the wrapper contract.
    function totalUnderlying() external view returns (uint256);

    /// @param who The account address.
    /// @return The underlying token balance of the account.
    function balanceOfUnderlying(address who) external view returns (uint256);

    /// @param uAmount The amount of underlying tokens.
    /// @return The amount of wrapper tokens exchangeable.
    function underlyingToWrapper(uint256 uAmount) external view returns (uint256);

    /// @param amount The amount of wrapper tokens.
    /// @return The amount of underlying tokens exchangeable.
    function wrapperToUnderlying(uint256 amount) external view returns (uint256);
}

/**
 * @title The RebaseHedger Interface
 *
 * @dev A RebaseHedger implementation can be used to deposit Ample
 *      tokens into a protocol which hedges, to some degree, the rebase.
 *
 *      While a RebaseHedger uses an own receipt token, e.g. Aave the
 *      aAmple token, this interface *only* uses Ample denominated amounts.
 *
 *      Note that in case a withdrawal of Ample tokens in the underlying
 *      protocol is not possible, the RebaseHedger's implementation
 *      *market sells* the protocol's receipt token for Ample tokens!
 *
 *      Therefore, the following invariant can NOT be guaranteed:
 *          balance = balanceOf(address(this));
 *          withdrawed = withdraw(balance);
 *          assert(balance == withdrawed);
 *
 * @author merkleplant
 */
interface IRebaseHedger {

    /// @notice Deposits Amples from msg.sender and mints *same amount* of
    ///         receipt tokens as Amples deposited.
    /// @param amples The amount of Amples to deposit.
    function deposit(uint amples) external;

    /// @notice Burns receipt tokens from msg.sender and withdraws Amples.
    /// @dev Note that in case a withdrawal in the underlying protocol is not
    ///      possible, the underlying receipt tokens will be sold in the open
    ///      market for Amples.
    /// @param amples The amount of Amples to withdraw.
    function withdraw(uint amples) external;

    /// @notice Returns the underlying Ample balance of an address.
    /// @param who The address to fetch the Ample balance from.
    /// @return The amount of Amples the address holds in the underlying protocol.
    function balanceOf(address who) external view returns (uint);

    /// @notice Returns the rebase hedger's receipt token address.
    /// @dev Note to be careful using this token directly as there can
    ///      be different conversion rates for different implementations.
    /// @return The address of the rebase hedger's receipt token.
    function token() external view returns (address);

    /// @notice Claims rewards from the underlying protocol and sends them to
    ///         some address.
    /// @dev Must be called via delegate call so that caller's address is
    ///      forwarded as msg.sender.
    /// @param receiver The address to send the rewards to.
    function claimRewards(address receiver) external;

}
/**
 * @title The RebaseStrategy Interface
 *
 * @dev A RebaseStrategy implementation can be used to decide whether one
 *      should hedge against an upcoming rebase or not.
 *
 * @author merkleplant
 */
interface IRebaseStrategy {

    /// @notice Returns whether Ample's upcoming rebase should be hedged or not.
    /// @return bool: True if Ample's upcoming rebase should be hedged, false
    ///               otherwise.
    ///         bool: Whether the signal is valid.
    function getSignal() external returns (bool, bool);

}

/*
 * @title The rebase-hedged Ample (rhAmple) Token
 *
 * @dev The rhAmple token is a %-ownership of Ample supply interest-bearing
 *      token, i.e. wAmple interest bearing.
 *
 *      However, the rhAmple token denominates user deposits in Ample.
 *      This is possible by using the ElasticReceiptToken which ensures the
 *      rhAmple supply always equals the amount of Amples deposited.
 *
 *      The conversion rate of rhAmple:Ample is therefore 1:1. This conversion
 *      rate can only break _during_ a user's withdrawal in which rebase-hedged
 *      receipt tokens may be selled in the open market.
 *
 * @author merkleplant
 */
contract RhAmple is ElasticReceiptToken, Ownable, IButtonWrapper {
    using SafeTransferLib for ERC20;

    //--------------------------------------------------------------------------
    // Events

    //----------------------------------
    // onlyOwner Events

    /// @notice Emitted when the max amount of Amples allowed to hedge changed.
    event MaxAmplesToHedgeChanged(uint from, uint to);

    /// @notice Emitted when Ample's market oracle changed.
    event RebaseStrategyChanged(address from, address to);

    /// @notice Emitted when the {IRebaseHedger} address changed.
    event RebaseHedgerChanged(address from, address to);

    /// @notice Emitted when the receiver address for the {IRebaseHedger}'s
    ///         underlying protocol's rewards changed.
    event RebaseHedgerRewardsReceiverChanged(address from, address to);

    /// @notice Emitted when the {IRebaseHedger}'s underlying protocol rewards
    ///         claimed.
    event RebaseHedgerRewardsClaimed();

    //----------------------------------
    // User Events

    /// @notice Emitted when a user mints rhAmples.
    event RhAmplesMinted(address to, uint rhAmples);

    /// @notice Emitted when a user burns rhAmples.
    event RhAmplesBurned(address from, uint rhAmples);

    //----------------------------------
    // Restructuring Events

    /// @notice Emitted when Amples deposited into the {IRebaseHedger}.
    event AmplesHedged(uint epoch, uint amples);

    /// @notice Emitted when Amples withdrawn from the {IRebaseHedger}.
    event AmplesDehedged(uint epoch, uint amples);

    //----------------------------------
    // Failure Events

    /// @notice Emitted when the {IRebaseStrategy} implementation sends an
    ///         invalid signal.
    event RebaseStrategyFailure();

    //--------------------------------------------------------------------------
    // Constants

    /// @dev The ERC20 decimals of rhAmple.
    /// @dev Is the same as Ample's.
    uint private constant DECIMALS = 9;

    //--------------------------------------------------------------------------
    // Storage

    /// @notice The Ample token address.
    address public immutable ample;

    /// @notice The {IRebaseStrategy} implementation address.
    /// @dev Changeable by owner.
    address public rebaseStrategy;

    /// @notice The {IRebaseHedger} implementation address.
    /// @dev Changeable by owner.
    address public rebaseHedger;

    /// @notice The {IRebaseHedger}'s receipt token address.
    /// @dev Updated if {IRebaseHedger} implementation changes.
    address public receiptToken;

    /// @notice The address to send {IRebaseHedger}'s underlying protocol
    ///         rewards to.
    /// @dev Changeable by owner.
    address public rebaseHedgerRewardsReceiver;

    /// @notice The max amount of Amples allowed to deposit into
    ///         the {IRebaseHedger}.
    /// @dev Changeable by owner.
    /// @dev Setting to zero disables hedging.
    uint public maxAmplesToHedge;

    /// @dev The restructure counter, i.e. the number of rhAmple restructurings
    ///      executed since inception.
    uint private _epoch;

    /// @notice True if Ample deposits are hedged against the rebase,
    ///         false otherwise.
    /// @dev Updated every time rhAmple restructures.
    /// @dev Useful for off-chain services to fetch rhAmple's hedging state.
    bool public isHedged;

    //--------------------------------------------------------------------------
    // Constructor

    constructor(
        address ample_,
        address rebaseStrategy_,
        address rebaseHedger_,
        address rebaseHedgerRewardsReceiver_,
        uint maxAmplesToHedge_
    ) ElasticReceiptToken("rebase-hedged Ample", "rhAMPL", uint8(DECIMALS)) {
        // Make sure that strategy is working.
        bool isValid;
        ( , isValid) = IRebaseStrategy(rebaseStrategy_).getSignal();
        require(isValid);

        // Set storage variables.
        ample = ample_;
        rebaseStrategy = rebaseStrategy_;
        rebaseHedger = rebaseHedger_;
        receiptToken = IRebaseHedger(rebaseHedger_).token();
        rebaseHedgerRewardsReceiver = rebaseHedgerRewardsReceiver_;
        maxAmplesToHedge = maxAmplesToHedge_;

        // Approve tokens for rebase hedger.
        ERC20(ample_).approve(rebaseHedger_, type(uint).max);
        ERC20(receiptToken).approve(rebaseHedger_, type(uint).max);
    }

    //--------------------------------------------------------------------------
    // Restructure Function

    /// @notice Restructure Ample deposits, i.e. re-evaluate if Amples should
    ///         hedged against upcoming rebase.
    function restructure() external {
        _restructure();
    }

    //--------------------------------------------------------------------------
    // IButtonWrapper Mutating Functions

    /// @inheritdoc IButtonWrapper
    function mint(uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        uint amples = rhAmples;

        _deposit(msg.sender, msg.sender, amples);
        return amples;
    }

    /// @inheritdoc IButtonWrapper
    function mintFor(address to, uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        uint amples = rhAmples;

        _deposit(msg.sender, to, amples);
        return amples;
    }

    /// @inheritdoc IButtonWrapper
    function burn(uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _withdraw(msg.sender, msg.sender, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function burnTo(address to, uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _withdraw(msg.sender, to, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function burnAll()
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));
        return _withdraw(msg.sender, msg.sender, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function burnAllTo(address to)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));
        return _withdraw(msg.sender, to, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function deposit(uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _deposit(msg.sender, msg.sender, amples);
    }

    /// @inheritdoc IButtonWrapper
    function depositFor(address to, uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _deposit(msg.sender, to, amples);
    }

    /// @inheritdoc IButtonWrapper
    function withdraw(uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        uint rhAmples = amples;

        _withdraw(msg.sender, msg.sender, rhAmples);
        return rhAmples;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawTo(address to, uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        uint rhAmples = amples;

        _withdraw(msg.sender, to, rhAmples);
        return rhAmples;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawAll()
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));
        _withdraw(msg.sender, msg.sender, rhAmples);
        return rhAmples;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawAllTo(address to)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));
        _withdraw(msg.sender, to, rhAmples);
        return rhAmples;
    }

    //--------------------------------------------------------------------------
    // IButtonWrapper View Functions

    /// @inheritdoc IButtonWrapper
    function underlying()
        external
        view
        override(IButtonWrapper)
        returns (address)
    {
        return ample;
    }

    /// @inheritdoc IButtonWrapper
    function totalUnderlying()
        external
        view
        override(IButtonWrapper)
        returns (uint256)
    {
        return _totalAmpleBalance();
    }

    /// @inheritdoc IButtonWrapper
    function balanceOfUnderlying(address who)
        external
        view
        override(IButtonWrapper)
        returns (uint256)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        return super.balanceOf(who);
    }

    /// @inheritdoc IButtonWrapper
    function underlyingToWrapper(uint amples)
        external
        pure
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        return amples;
    }

    /// @inheritdoc IButtonWrapper
    function wrapperToUnderlying(uint256 rhAmples)
        external
        pure
        override(IButtonWrapper)
        returns (uint256)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        return rhAmples;
    }

    //--------------------------------------------------------------------------
    // onlyOwner Mutating Functions

    /// @notice Sets the max amount of Amples allowed to hedge.
    /// @dev Only callable by owner.
    function setMaxAmplesToHedge(uint maxAmplesToHedge_) external onlyOwner {
        // Note that MAX_SUPPLY is defined in the upstream ElasticReceiptToken
        // contract.
        if (maxAmplesToHedge_ > MAX_SUPPLY) {
            emit MaxAmplesToHedgeChanged(maxAmplesToHedge, MAX_SUPPLY);
            maxAmplesToHedge = MAX_SUPPLY;
        } else {
            emit MaxAmplesToHedgeChanged(maxAmplesToHedge, maxAmplesToHedge_);
            maxAmplesToHedge = maxAmplesToHedge_;
        }
    }

    /// @notice Sets the rebase strategy implementation.
    /// @dev Only callable by owner.
    function setRebaseStrategy(address rebaseStrategy_) external onlyOwner {
        // Make sure that strategy is working.
        bool isValid;
        ( , isValid) = IRebaseStrategy(rebaseStrategy_).getSignal();
        require(isValid);

        emit RebaseStrategyChanged(rebaseStrategy, rebaseStrategy_);
        rebaseStrategy = rebaseStrategy_;
    }

    /// @notice Set rebase hedger's underlying protocol's rewards receiver.
    /// @dev Only callable by owner.
    function setRebaseHedgerRewardsReceiver(address rebaseHedgerRewardsReceiver_)
        external
        onlyOwner
    {
        emit RebaseHedgerRewardsReceiverChanged(
            rebaseHedgerRewardsReceiver,
            rebaseHedgerRewardsReceiver_
        );
        rebaseHedgerRewardsReceiver = rebaseHedgerRewardsReceiver_;
    }

    /// @notice Sets the rebase hedger implementation.
    /// @dev Only callable by owner.
    function setRebaseHedger(
        address rebaseHedger_,
        bool withdrawTokens,
        bool claimRewards
    ) external onlyOwner {
        // If requested, claim rebase hedger's underlying protocol rewards.
        if (claimRewards) {
            // Note that the claimRewards function has to be called via
            // delegate call so that the rebase hedger's "claim" call to the
            // underlying protocol forwards address(this) as msg.sender.
            bool success;
            (success, /*data*/) = rebaseHedger.delegatecall(
                abi.encodeWithSignature(
                    "claimRewards(address)",
                    rebaseHedgerRewardsReceiver
                )
            );
            require(success, "Claim failed");

            emit RebaseHedgerRewardsClaimed();
        }

        // If requested, withdraw receipt tokens.
        if (withdrawTokens) {
            _dehedgeAmples();
        }

        // Remove approvals for old rebase hedger.
        ERC20(ample).approve(rebaseHedger, 0);
        ERC20(receiptToken).approve(rebaseHedger, 0);

        // Set new rebase hedger.
        emit RebaseHedgerChanged(rebaseHedger, rebaseHedger_);
        rebaseHedger = rebaseHedger_;
        receiptToken = IRebaseHedger(rebaseHedger).token();

        // Approve tokens for rebase hedger.
        ERC20(ample).approve(rebaseHedger_, type(uint).max);
        ERC20(receiptToken).approve(rebaseHedger_, type(uint).max);
    }

    //--------------------------------------------------------------------------
    // Overriden ElasticReceiptToken Functions

    /// @dev Internal function restructuring the Ample deposits and returning
    ///      the total amount of Amples under management, i.e. the supply target
    ///      for rhAmple.
    function _supplyTarget()
        internal
        override(ElasticReceiptToken)
        returns (uint)
    {
        _restructure();

        return _totalAmpleBalance();
    }

    //--------------------------------------------------------------------------
    // Private Functions

    /// @dev Private function restructuring the Ample deposits, i.e.
    ///      hedging or dehedging Amples depending on the {IRebaseStrategy}
    ///      implementation's signal.
    function _restructure() private {
        bool shouldHedge;
        bool isValid;
        (shouldHedge, isValid) = IRebaseStrategy(rebaseStrategy).getSignal();

        if (!isValid) {
            isHedged = false;

            // Handle strategy failure by dehedging all Amples and setting max
            // Amples allowed to hedge to zero.
            _handleStrategyFailure();
            return;
        }

        if (shouldHedge) {
            _hedgeAmples();
            isHedged = true;
        } else {
            _dehedgeAmples();
            isHedged = false;
        }
    }

    /// @dev Private function to handle a user deposit. Returns the amount
    ///      of rhAmples minted.
    function _deposit(address from, address to, uint amples)
        private
        returns (uint)
    {
        super._mint(to, amples);
        ERC20(ample).safeTransferFrom(from, address(this), amples);

        emit RhAmplesMinted(to, amples);

        return amples;
    }

    /// @dev Private function to handle a user withdrawal. Returns the amount
    ///      of Amples withdrawn.
    function _withdraw(address from, address to, uint rhAmples)
        private
        returns (uint)
    {
        // Note that the rhAmple amount could change due to rebasing and needs
        // to be updated.
        rhAmples = super._burn(from, rhAmples);

        uint amples = _ableToWithdraw(rhAmples);

        // Note that Ample disallows transfers to zero address.
        ERC20(ample).safeTransfer(to, amples);

        emit RhAmplesBurned(from, rhAmples);

        return amples;
    }

    /// @dev Private function to prepare Ample withdrawal. Returns the amount
    ///      of Amples eligible to withdraw for given amount of rhAmples.
    function _ableToWithdraw(uint rhAmples) private returns (uint) {
        uint rawAmpleBalance = _rawAmpleBalance();

        if (rawAmpleBalance >= rhAmples) {
            return rhAmples;
        }

        uint amplesMissing = rhAmples - rawAmpleBalance;

        // Note that the withdrawed amount does not have to equal amplesMissing.
        // For more info see {IRebaseHedger}.
        IRebaseHedger(rebaseHedger).withdraw(amplesMissing);

        // Note that positive slippage is attributed to user.
        return ERC20(ample).balanceOf(address(this));
    }

    /// @dev Private function to hedge Ample deposits against negative rebase.
    function _hedgeAmples() private {
        uint amplesToHedge = _rawAmpleBalance();
        uint hedgedAmpleBalance = _hedgedAmpleBalance();

        // Return if nothing to hedge or hedged Amples is already at max.
        if (amplesToHedge == 0 || hedgedAmpleBalance >= maxAmplesToHedge) {
            return;
        }

        // Don't hedge more than allowed.
        if (amplesToHedge + hedgedAmpleBalance > maxAmplesToHedge) {
            amplesToHedge = maxAmplesToHedge - hedgedAmpleBalance;
        }

        IRebaseHedger(rebaseHedger).deposit(amplesToHedge);

        emit AmplesHedged(++_epoch, amplesToHedge);
    }

    /// @dev Private function to de-hedge Ample deposits against negative
    ///      rebase.
    function _dehedgeAmples() private {
        uint amplesToDehedge = _hedgedAmpleBalance();

        // Return if nothing to dehedge.
        if (amplesToDehedge == 0) {
            return;
        }

        IRebaseHedger(rebaseHedger).withdraw(amplesToDehedge);

        emit AmplesDehedged(++_epoch, amplesToDehedge);
    }

    /// @dev Private function to handle strategy failure. De-hedges all Amples
    ///      and sets maxAmplesToHedge to 0.
    function _handleStrategyFailure() private {
        // Dehedge all Amples while price is unknown.
        _dehedgeAmples();

        // Set max Ample allowed to hedge to zero.
        // Note that this effectively pauses the hedging functionality.
        emit MaxAmplesToHedgeChanged(maxAmplesToHedge, 0);
        maxAmplesToHedge = 0;

        emit RebaseStrategyFailure();
    }

    /// @dev Private function returning the total amount of Amples
    ///      under management. The amount of Amples under management is the
    ///      sum of raw Amples held in the contract and Amples hedged in the
    ///      {IRebaseHedger}.
    function _totalAmpleBalance() private view returns (uint) {
        return _rawAmpleBalance() + _hedgedAmpleBalance();
    }

    /// @dev Private function returning the total amount of raw Amples held
    ///      in this contract.
    function _rawAmpleBalance() private view returns (uint) {
        return ERC20(ample).balanceOf(address(this));
    }

    /// @dev Private function returning the total amount of Amples hedged in
    ///      the {IRebaseHedger}.
    function _hedgedAmpleBalance() private view returns (uint) {
        // Note that {IRebaseHedger} defines the ratio of its token to
        // Ample as 1:1.
        return ERC20(receiptToken).balanceOf(address(this));
    }

}