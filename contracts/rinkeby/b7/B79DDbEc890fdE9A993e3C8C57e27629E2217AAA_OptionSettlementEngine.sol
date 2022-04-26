/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
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

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Metadata is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function uri(uint256 id) external view returns (string memory);
}

// TODO(The engine is IERC1155Metadata, but the solmate impl is not compatible with interface, re-implement)
// @title A settlement engine for options
// @author 0xAlcibiades
interface IOptionSettlementEngine {
    // The requested token is not found.
    // @param token token requested.
    error TokenNotFound(uint256 token);

    // The caller doesn't have permission to access that function.
    error AccessControlViolation(address accessor, address permissioned);

    // This options chain already exists and thus cannot be created.
    error OptionsChainExists(bytes32 hash);

    // The expiry timestamp is less than 24 hours from now.
    error ExpiryTooSoon();

    // The option exercise window is less than 24 hours long.
    error ExerciseWindowTooShort();

    // The assets specified are invalid or duplicate.
    error InvalidAssets(address asset1, address asset2);

    // The token specified is not an option.
    error InvalidOption(uint256 token);

    // The token specified is not a claim.
    error InvalidClaim(uint256 token);

    // The optionId specified expired at expiry.
    error ExpiredOption(uint256 optionId, uint40 expiry);

    // This option cannot yet be exercised.
    error ExerciseTooEarly();

    // This option has no claims written against it.
    error NoClaims();

    // This account has no claims.
    error BalanceTooLow();

    // This claimId has already been claimed.
    error AlreadyClaimed();

    // You can't claim before expiry.
    error ClaimTooSoon();

    event FeeSwept(
        address indexed token,
        address indexed feeTo,
        uint256 amount
    );

    event NewChain(
        uint256 indexed optionId,
        address indexed exerciseAsset,
        address indexed underlyingAsset,
        uint96 exerciseAmount,
        uint96 underlyingAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp
    );

    event OptionsExercised(
        uint256 indexed optionId,
        address indexed exercisee,
        uint112 amount
    );

    event OptionsWritten(
        uint256 indexed optionId,
        address indexed writer,
        uint256 claimId,
        uint112 amount
    );

    event FeeAccrued(
        address indexed asset,
        address indexed payor,
        uint256 amount
    );

    event ClaimRedeemed(
        uint256 indexed claimId,
        uint256 indexed optionId,
        address indexed redeemer,
        address exerciseAsset,
        address underlyingAsset,
        uint96 exerciseAmount,
        uint96 underlyingAmount
    );

    event ExerciseAssigned(
        uint256 indexed claimId,
        uint256 indexed optionId,
        uint112 amountAssigned
    );

    // @dev This enumeration is used to determine the type of an ERC1155 subtoken in the engine.
    enum Type {
        None,
        Option,
        Claim
    }

    // @dev This struct contains the data about an options chain associated with an ERC-1155 token.
    struct Option {
        // The underlying asset to be received
        address underlyingAsset;
        // The timestamp after which this option may be exercised
        uint40 exerciseTimestamp;
        // The timestamp before which this option must be exercised
        uint40 expiryTimestamp;
        // The address of the asset needed for exercise
        address exerciseAsset;
        // The amount of the underlying asset contained within an option contract of this type
        uint96 underlyingAmount;
        // Random seed created at the time of option chain creation
        uint160 settlementSeed;
        // The amount of the exercise asset required to exercise this option
        uint96 exerciseAmount;
    }

    // @dev This struct contains the data about a claim ERC-1155 NFT associated with an option chain.
    struct Claim {
        // Which option was written
        uint256 option;
        // These are 1:1 contracts with the underlying Option struct
        // The number of contracts written in this claim
        uint112 amountWritten;
        // The amount of contracts assigned for exercise to this claim
        uint112 amountExercised;
        // The two amounts above along with the option info, can be used to calculate the underlying assets
        bool claimed;
    }

    struct Underlying {
        address underlyingAsset;
        int256 underlyingPosition;
        address exerciseAsset;
        int256 exercisePosition;
    }

    // @notice The protocol fee, expressed in basis points
    // @return The fee in basis points
    function feeBps() external view returns (uint8);

    // @return The address fees accrue to
    function feeTo() external view returns (address);

    // @return The balance of unswept fees for a given address
    function feeBalance(address token) external view returns (uint256);

    // @return The enum (uint8) Type of the tokenId
    function tokenType(uint256 tokenId) external view returns (Type);

    // @return The optionInfo Option struct for tokenId
    function option(uint256 tokenId)
        external
        view
        returns (Option memory optionInfo);

    // @return The claimInfo Claim struct for claimId
    function claim(uint256 tokenId)
        external
        view
        returns (Claim memory claimInfo);

    // @notice Updates the address fees can be swept to
    function setFeeTo(address newFeeTo) external;

    // @return The tokenId if it exists, else 0
    function hashToOptionToken(bytes32 hash)
        external
        view
        returns (uint256 optionId);

    // @notice Sweeps fees to the feeTo address if there are more than 0 wei for each address in tokens
    function sweepFees(address[] memory tokens) external;

    // @notice Create a new options chain from optionInfo if it doesn't already exist
    function newChain(Option memory optionInfo)
        external
        returns (uint256 optionId);

    // @notice write a new bundle of options contract and recieve options tokens and claim ticket
    function write(uint256 optionId, uint112 amount)
        external
        returns (uint256 claimId);

    // @notice exercise amount of optionId transfers and receives required amounts of tokens
    function exercise(uint256 optionId, uint112 amount) external;

    // @notice redeem a claim NFT, transfers the underlying tokens
    function redeem(uint256 claimId) external;

    // @notice Information about the position underlying a token, useful for determining value
    function underlying(uint256 tokenId)
        external
        view
        returns (Underlying memory underlyingPositions);
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

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

/**
   Valorem Options V1 is a DeFi money lego enabling writing covered call and covered put, physically settled, options.
   All written options are fully collateralized against an ERC-20 underlying asset and exercised with an
   ERC-20 exercise asset using a chainlink VRF random number per unique option type for fair settlement. Options contracts
   are issued as fungible ERC-1155 tokens, with each token representing a contract. Option writers are additionally issued
   an ERC-1155 NFT representing a lot of contracts written for claiming collateral and exercise assignment. This design
   eliminates the need for market price oracles, and allows for permission-less writing, and gas efficient transfer, of
   a broad swath of traditional options.
*/

// TODO(DRY code during testing)
// TODO(Gas Optimize)

// @notice This settlement protocol does not support rebase tokens, or fee on transfer tokens

contract OptionSettlementEngine is ERC1155, IOptionSettlementEngine {
    // The protocol fee
    uint8 public immutable feeBps = 5;

    // The address fees accrue to
    address public feeTo = 0x36273803306a3C22bc848f8Db761e974697ece0d;

    // The token type for a given tokenId
    mapping(uint256 => Type) public tokenType;

    // Fee balance for a given token
    mapping(address => uint256) public feeBalance;

    // Input hash to get option token ID if it exists
    mapping(bytes32 => uint256) public hashToOptionToken;

    // The next token id
    uint256 internal nextTokenId = 1;

    // The list of claims for an option
    mapping(uint256 => uint256[]) internal unexercisedClaimsByOption;

    // Accessor for Option contract details
    mapping(uint256 => Option) internal _option;

    // Accessor for claim ticket details
    mapping(uint256 => Claim) internal _claim;

    function option(uint256 tokenId)
        external
        view
        returns (Option memory optionInfo)
    {
        optionInfo = _option[tokenId];
    }

    function claim(uint256 tokenId)
        external
        view
        returns (Claim memory claimInfo)
    {
        claimInfo = _claim[tokenId];
    }

    function setFeeTo(address newFeeTo) public {
        if (msg.sender != feeTo) {
            revert AccessControlViolation(msg.sender, feeTo);
        }
        feeTo = newFeeTo;
    }

    function sweepFees(address[] memory tokens) public {
        address sendFeeTo = feeTo;
        address token;
        uint256 fee;
        uint256 sweep;
        uint256 numTokens = tokens.length;

        unchecked {
            for (uint256 i = 0; i < numTokens; i++) {
                // Get the token and balance to sweep
                token = tokens[i];

                fee = feeBalance[token];
                // Leave 1 wei here as a gas optimization
                if (fee > 1) {
                    sweep = feeBalance[token] - 1;
                    SafeTransferLib.safeTransfer(
                        ERC20(token),
                        sendFeeTo,
                        sweep
                    );
                    feeBalance[token] = 1;
                    emit FeeSwept(token, sendFeeTo, sweep);
                }
            }
        }
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenType[tokenId] != Type.None) {
            revert TokenNotFound(tokenId);
        }
        // TODO(Implement metadata/uri with frontend dev)
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked("{}")))
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function newChain(Option memory optionInfo)
        external
        returns (uint256 optionId)
    {
        // Ensure settlement seed is 0
        optionInfo.settlementSeed = 0;

        // Check that a duplicate chain doesn't exist
        bytes32 chainKey = keccak256(abi.encode(optionInfo));

        // If it does, revert
        if (hashToOptionToken[chainKey] != 0) {
            revert OptionsChainExists(chainKey);
        }

        // Make sure that expiry is at least 24 hours from now
        if (optionInfo.expiryTimestamp < (block.timestamp + 86400)) {
            revert ExpiryTooSoon();
        }

        // Ensure the exercise window is at least 24 hours
        if (
            optionInfo.expiryTimestamp < (optionInfo.exerciseTimestamp + 86400)
        ) {
            revert ExerciseWindowTooShort();
        }

        // The exercise and underlying assets can't be the same
        if (optionInfo.exerciseAsset == optionInfo.underlyingAsset) {
            revert InvalidAssets(
                optionInfo.exerciseAsset,
                optionInfo.underlyingAsset
            );
        }

        // Use the chainKey to seed entropy
        optionInfo.settlementSeed = uint160(uint256(chainKey));

        // Create option token and increment
        tokenType[nextTokenId] = Type.Option;

        // TODO(Is this check really needed?)
        // Check that both tokens are ERC20 by instantiating them and checking supply
        ERC20 underlyingToken = ERC20(optionInfo.underlyingAsset);
        ERC20 exerciseToken = ERC20(optionInfo.exerciseAsset);

        // Check total supplies and ensure the option will be exercisable
        if (
            underlyingToken.totalSupply() < optionInfo.underlyingAmount ||
            exerciseToken.totalSupply() < optionInfo.exerciseAmount
        ) {
            revert InvalidAssets(
                optionInfo.underlyingAsset,
                optionInfo.exerciseAsset
            );
        }

        _option[nextTokenId] = optionInfo;

        optionId = nextTokenId;

        // Increment the next token id to be used
        ++nextTokenId;
        hashToOptionToken[chainKey] = optionId;

        emit NewChain(
            optionId,
            optionInfo.exerciseAsset,
            optionInfo.underlyingAsset,
            optionInfo.exerciseAmount,
            optionInfo.underlyingAmount,
            optionInfo.exerciseTimestamp,
            optionInfo.expiryTimestamp
        );
    }

    function write(uint256 optionId, uint112 amount)
        external
        returns (uint256 claimId)
    {
        if (tokenType[optionId] != Type.Option) {
            revert InvalidOption(optionId);
        }

        Option storage optionRecord = _option[optionId];

        if (optionRecord.expiryTimestamp <= block.timestamp) {
            revert ExpiredOption(optionId, optionRecord.expiryTimestamp);
        }

        uint256 rxAmount = amount * optionRecord.underlyingAmount;
        uint256 fee = ((rxAmount / 10000) * feeBps);
        address underlyingAsset = optionRecord.underlyingAsset;

        // Transfer the requisite underlying asset
        SafeTransferLib.safeTransferFrom(
            ERC20(underlyingAsset),
            msg.sender,
            address(this),
            (rxAmount + fee)
        );

        claimId = nextTokenId;

        // Mint the options contracts and claim token
        uint256[] memory tokens = new uint256[](2);
        tokens[0] = optionId;
        tokens[1] = claimId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = uint256(amount);
        amounts[1] = 1;

        bytes memory data = new bytes(0);

        // Store info about the claim
        tokenType[claimId] = Type.Claim;
        _claim[claimId] = Claim({
            option: optionId,
            amountWritten: amount,
            amountExercised: 0,
            claimed: false
        });
        unexercisedClaimsByOption[optionId].push(claimId);

        feeBalance[underlyingAsset] += fee;

        // Increment the next token ID
        ++nextTokenId;

        emit FeeAccrued(underlyingAsset, msg.sender, fee);
        emit OptionsWritten(optionId, msg.sender, claimId, amount);

        // Send tokens to writer
        _batchMint(msg.sender, tokens, amounts, data);
    }

    function assignExercise(
        uint256 optionId,
        uint112 amount,
        uint160 settlementSeed
    ) internal {
        // Number of claims enqueued for this option
        uint256 claimsLen = unexercisedClaimsByOption[optionId].length;

        if (claimsLen == 0) {
            revert NoClaims();
        }

        // Initial storage pointer
        Claim storage claimRecord;

        // Counter for randomness
        uint256 i;

        // To keep track of the slot to overwrite
        uint256 overwrite;

        // Last index in the claims list
        uint256 lastIndex;

        // The new length for the claims list
        uint256 newLen;

        // While there are still options to exercise
        while (amount > 0) {
            // Get the claim number to assign
            uint256 claimNum;
            if (claimsLen == 1) {
                lastIndex = 0;
                claimNum = unexercisedClaimsByOption[optionId][lastIndex];
            } else {
                lastIndex = settlementSeed % claimsLen;
                claimNum = unexercisedClaimsByOption[optionId][lastIndex];
            }

            claimRecord = _claim[claimNum];

            uint112 amountAvailiable = claimRecord.amountWritten -
                claimRecord.amountExercised;
            uint112 amountPresentlyExercised;
            if (amountAvailiable < amount) {
                amount -= amountAvailiable;
                amountPresentlyExercised = amountAvailiable;
                // We pop the end off and overwrite the old slot
            } else {
                amountPresentlyExercised = amount;
                amount = 0;
            }
            newLen = claimsLen - 1;
            if (newLen > 0) {
                overwrite = unexercisedClaimsByOption[optionId][newLen];
                // Would be nice if I could pop onto the stack here
                unexercisedClaimsByOption[optionId].pop();
                claimsLen = newLen;
                unexercisedClaimsByOption[optionId][lastIndex] = overwrite;
            } else {
                unexercisedClaimsByOption[optionId].pop();
            }
            claimRecord.amountExercised += amountPresentlyExercised;
            emit ExerciseAssigned(claimNum, optionId, amountPresentlyExercised);

            // Increment for the next loop
            settlementSeed = uint160(
                uint256(keccak256(abi.encode(settlementSeed, i)))
            );
            i++;
        }

        // Update the settlement seed in storage for the next exercise.
        _option[optionId].settlementSeed = settlementSeed;
    }

    function exercise(uint256 optionId, uint112 amount) external {
        if (tokenType[optionId] != Type.Option) {
            revert InvalidOption(optionId);
        }

        Option storage optionRecord = _option[optionId];

        if (optionRecord.expiryTimestamp <= block.timestamp) {
            revert ExpiredOption(optionId, optionRecord.expiryTimestamp);
        }
        // Require that we have reached the exercise timestamp
        if (optionRecord.exerciseTimestamp >= block.timestamp) {
            revert ExerciseTooEarly();
        }

        uint256 rxAmount = optionRecord.exerciseAmount * amount;
        uint256 txAmount = optionRecord.underlyingAmount * amount;
        uint256 fee = ((rxAmount / 10000) * feeBps);
        address exerciseAsset = optionRecord.exerciseAsset;

        // Transfer in the requisite exercise asset
        SafeTransferLib.safeTransferFrom(
            ERC20(exerciseAsset),
            msg.sender,
            address(this),
            (rxAmount + fee)
        );

        // Transfer out the underlying
        SafeTransferLib.safeTransfer(
            ERC20(optionRecord.underlyingAsset),
            msg.sender,
            txAmount
        );

        assignExercise(optionId, amount, optionRecord.settlementSeed);

        feeBalance[exerciseAsset] += fee;

        _burn(msg.sender, optionId, amount);

        emit FeeAccrued(exerciseAsset, msg.sender, fee);
        emit OptionsExercised(optionId, msg.sender, amount);
    }

    function redeem(uint256 claimId) external {
        if (tokenType[claimId] != Type.Claim) {
            revert InvalidClaim(claimId);
        }

        uint256 balance = this.balanceOf(msg.sender, claimId);

        if (balance != 1) {
            revert BalanceTooLow();
        }

        Claim storage claimRecord = _claim[claimId];

        if (claimRecord.claimed) {
            revert AlreadyClaimed();
        }

        uint256 optionId = claimRecord.option;
        Option storage optionRecord = _option[optionId];

        if (optionRecord.expiryTimestamp > block.timestamp) {
            revert ClaimTooSoon();
        }

        uint256 exerciseAmount = optionRecord.exerciseAmount *
            claimRecord.amountExercised;
        uint256 underlyingAmount = (optionRecord.underlyingAmount *
            (claimRecord.amountWritten - claimRecord.amountExercised));

        if (exerciseAmount > 0) {
            SafeTransferLib.safeTransfer(
                ERC20(optionRecord.exerciseAsset),
                msg.sender,
                exerciseAmount
            );
        }

        if (underlyingAmount > 0) {
            SafeTransferLib.safeTransfer(
                ERC20(optionRecord.underlyingAsset),
                msg.sender,
                underlyingAmount
            );
        }

        claimRecord.claimed = true;

        _burn(msg.sender, claimId, 1);

        emit ClaimRedeemed(
            claimId,
            optionId,
            msg.sender,
            optionRecord.exerciseAsset,
            optionRecord.underlyingAsset,
            uint96(exerciseAmount),
            uint96(underlyingAmount)
        );
    }

    function underlying(uint256 tokenId)
        external
        view
        returns (Underlying memory underlyingPositions)
    {
        if (tokenType[tokenId] != Type.None) {
            revert TokenNotFound(tokenId);
        } else if (tokenType[tokenId] != Type.Option) {
            Option storage optionRecord = _option[tokenId];
            bool expired = (optionRecord.expiryTimestamp > block.timestamp);
            underlyingPositions = Underlying({
                underlyingAsset: optionRecord.underlyingAsset,
                underlyingPosition: expired
                    ? int256(0)
                    : int256(uint256(optionRecord.underlyingAmount)),
                exerciseAsset: optionRecord.exerciseAsset,
                exercisePosition: expired
                    ? int256(0)
                    : -int256(uint256(optionRecord.exerciseAmount))
            });
        } else {
            Claim storage claimRecord = _claim[tokenId];
            Option storage optionRecord = _option[claimRecord.option];
            uint256 exerciseAmount = optionRecord.exerciseAmount *
                claimRecord.amountExercised;
            uint256 underlyingAmount = (optionRecord.underlyingAmount *
                (claimRecord.amountWritten - claimRecord.amountExercised));
            underlyingPositions = Underlying({
                underlyingAsset: optionRecord.underlyingAsset,
                underlyingPosition: int256(exerciseAmount),
                exerciseAsset: optionRecord.exerciseAsset,
                exercisePosition: int256(underlyingAmount)
            });
        }
    }
}