// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../ICollectionPool.sol";

/// @notice MonotonicIncreasingValidator is suitable for all bonding curves that are monotonic increasing.
/// i.e. the spot price is always non-decreasing when delta increases.
/// @dev Only suitable for TRADE pools
contract MonotonicIncreasingValidator is IValidator {
    /// @dev See {IValidator-validate}
    function validate(ICollectionPool pool, ICurve.Params calldata params, uint96 fee, bytes32 tokenIDFilterRoot) public view override returns (bool) {
        return (
            pool.delta() <= params.delta &&
            pool.fee() <= fee &&
            pool.poolType() == ICollectionPool.PoolType.TRADE &&
            pool.tokenIDFilterRoot() == tokenIDFilterRoot
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";
import {ITokenIDFilter} from "./filter/ITokenIDFilter.sol";

interface ICollectionPool is ITokenIDFilter {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    /**
        @param ids The list of IDs of the NFTs to sell to the pool
        @param proof Merkle multiproof proving list is allowed by pool
        @param proofFlags Merkle multiproof flags for proof
    */
    struct NFTs {
        uint256[] ids;
        bytes32[] proof;
        bool[] proofFlags;
    }

    function bondingCurve() external view returns (ICurve);

    function getAllHeldIds() external view returns (uint256[] memory);

    function delta() external view returns (uint128);

    function fee() external view returns (uint96);

    function nft() external view returns (IERC721);

    function poolType() external view returns (PoolType);

    function spotPrice() external view returns (uint128);

    /**
        @notice Rescues a specified set of NFTs owned by the pool to the owner address. (onlyOwnable modifier is in the implemented function)
        @dev If the NFT is the pool's collection, we also remove it from the id tracking (if the NFT is missing enumerable).
        @param a The NFT to transfer
        @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    /**
        @notice Rescues ERC20 tokens from the pool to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
        @param a The token to transfer
        @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;

    function getSellNFTQuote(uint256 numNFTs) external view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            bytes memory newState,
            uint256 outputAmount,
            uint256 tradeFee,
            uint256 protocolFee
        );
}

interface ICollectionPoolETH is ICollectionPool {
    function withdrawAllETH() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
        @param spotPrice The current selling spot price of the pool, in tokens
        @param delta The delta parameter of the pool, what it means depends on the curve
        @param props The properties of the pool, what it means depends on the curve
        @param state The state of the pool, what it means depends on the curve
    */
    struct Params {
        uint128 spotPrice;
        uint128 delta;
        bytes props;
        bytes state;
    }

    /**
        @param trade The amount of fee to send to the pool, in tokens
        @param protocol The amount of fee to send to the protocol, in tokens
        @param royalties The amount to pay for each item in the order they
        are purchased. Always has length `numItems`.
    */
    struct Fees {
        uint256 trade;
        uint256 protocol;
        uint256[] royalties;
    }

    /**
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param fees.protocolMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @param royaltyNumerator Determines how much of the trade value is awarded as royalties. 5 decimals
        @param carryFeeMultiplier Determines how much carry fee the protocol takes from this trade, 18 decimals
    */
    struct FeeMultipliers {
        uint256 trade;
        uint256 protocol;
        uint256 royaltyNumerator;
        uint256 carry;
    }

    /**
        @notice Validates if a delta value is valid for the curve. The criteria for
        validity can be different for each type of curve, for instance ExponentialCurve
        requires delta to be greater than 1.
        @param delta The delta value to be validated
        @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
        @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's pooled token.
        @param newSpotPrice The new spot price to be set
        @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice)
        external
        view
        returns (bool valid);

    /**
        @notice Validates if a props value is valid for the curve. The criteria for validity can be different for each type of curve.
        @param props The props value to be validated
        @return valid True if props is valid, false otherwise
     */
    function validateProps(bytes calldata props)
        external
        view
        returns (bool valid);

    /**
        @notice Validates if a state value is valid for the curve. The criteria for validity can be different for each type of curve.
        @param state The state value to be validated
        @return valid True if state is valid, false otherwise
     */
    function validateState(bytes calldata state)
        external
        view
        returns (bool valid);

    /**
        @notice Given the current state of the pool and the trade, computes how much the user
        should pay to purchase an NFT from the pool, the new spot price, and other values.
        @dev Do not try to optimize the length of fees.royalties; compiler
        ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
        calculation loop due to stack depth
        @param params Parameters of the pool that affect the bonding curve.
        @param numItems The number of NFTs the user is buying from the pool
        @param feeMultipliers Determines how much fee is taken from this trade.
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newParams The updated parameters of the pool that affect the bonding curve.
        @return inputValue The amount that the user should pay, in tokens
        @return fees The amount of fees
     */
    function getBuyInfo(
        ICurve.Params calldata params,
        uint256 numItems,
        ICurve.FeeMultipliers calldata feeMultipliers
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 inputValue,
            ICurve.Fees calldata fees
        );

    /**
        @notice Given the current state of the pool and the trade, computes how much the user
        should receive when selling NFTs to the pool, the new spot price, and other values.
        @dev Do not try to optimize the length of fees.royalties; compiler
        ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
        calculation loop due to stack depth
        @param params Parameters of the pool that affect the bonding curve.
        @param numItems The number of NFTs the user is selling to the pool
        @param feeMultipliers Determines how much fee is taken from this trade.
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newParams The updated parameters of the pool that affect the bonding curve.
        @return outputValue The amount that the user should receive, in tokens
        @return fees The amount of fees
     */
    function getSellInfo(
        ICurve.Params calldata params,
        uint256 numItems,
        ICurve.FeeMultipliers calldata feeMultipliers
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 outputValue,
            ICurve.Fees calldata fees
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../ICollectionPool.sol";

interface IValidator {
    /// @notice Validates if a pool fulfills the conditions of a bonding curve. The conditions can be different for each type of curve.
    function validate(ICollectionPool pool, ICurve.Params calldata params, uint96 fee, bytes32 tokenIDFilterRoot) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW, // The updated spot price doesn't fit into 128 bits
        TOO_MANY_ITEMS // The value of numItems passes was too great
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenIDFilter {
    function tokenIDFilterRoot() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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