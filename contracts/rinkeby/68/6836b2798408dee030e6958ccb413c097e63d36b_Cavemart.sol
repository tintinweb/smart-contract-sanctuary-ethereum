// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FullMath}               from "./FullMath.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IERC721}                from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

// TODO add ERC721-holder logic

// @notice              Allows a buyer to execute an order given they've got
//                      an secp256k1 signature from a seller containing verifiable
//                      metadata about the trade. The seller can accept native ETH
//                      or an ERC-20 if they're whitelisted.
//
// @author              Dionysus @ConcaveFi
contract Cavemart {

	// @dev This function ensures this contract can receive ETH
	receive() external payable {}

    //////////////////////////////////////////////////////////////////////
    // IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////////////

    uint256 internal constant FEE_DIVISOR = 1e4;

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    // keccak256("Swap(address seller,address erc721,address erc20,uint256 tokenId,uint256 startPrice,uint256 endPrice,uint256 nonce,uint256 start,uint256 deadline)")
    bytes32 public constant SWAP_TYPEHASH = 0x8bca9397be6761f8836a3f24b102db891d663d3e2e89a7c7eea2479c3431068b;

    //////////////////////////////////////////////////////////////////////
    // MUTABLE STORAGE
    //////////////////////////////////////////////////////////////////////

    // @notice Returns the address fees are sent to.
    address payable public feeAddress = payable(msg.sender);

    // @notice Returns the fee charged for selling a token from specific 'collection'
    mapping(address => uint256) public collectionFee;

    // @notice Returns whether a token is allowed to be traded within this contract.
    mapping(address => bool) public allowed;

    // @notice Returns the current nonce of a specific address.
    mapping(address => uint256) public nonces;

    //////////////////////////////////////////////////////////////////////
    // CONSTRUCTION
    //////////////////////////////////////////////////////////////////////

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    //////////////////////////////////////////////////////////////////////
    // USER ACTION EVENTS
    //////////////////////////////////////////////////////////////////////
    
    event OrderExecuted(
        address indexed seller,
        address indexed erc721,
        address indexed erc20,
        uint256 tokenId,
        uint256 price,
        uint256 deadline
    );

    //////////////////////////////////////////////////////////////////////
    // EIP-712 LOGIC
    //////////////////////////////////////////////////////////////////////

    function computeSigner(
        SwapMetadata calldata data,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual view returns (address signer) {
        
        bytes32 hash = keccak256(
            abi.encode(
                SWAP_TYPEHASH, 
                data.seller, 
                data.erc721, 
                data.erc20, 
                data.tokenId, 
                data.startPrice,
                data.endPrice, 
                nonce,
                data.start, 
                data.deadline
            )
        );
        
        signer = ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hash)), v, r, s);
    }

    function DOMAIN_SEPARATOR() public virtual view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("Fixed Order Market")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    //////////////////////////////////////////////////////////////////////
    // PRICE LOGIC
    //////////////////////////////////////////////////////////////////////

    function computePrice(
        SwapMetadata calldata data
    ) public virtual view returns (uint256 price) {

        data.endPrice == 0 || data.start == 0 ? 
            price = data.startPrice : 
            price = data.startPrice - FullMath.mulDiv(
                data.startPrice - data.endPrice, 
                block.timestamp - data.start, 
                data.deadline - data.start
            );
    }

    //////////////////////////////////////////////////////////////////////
    // USER ACTIONS
    //////////////////////////////////////////////////////////////////////

    // @notice              Struct containing metadata for a ERC721 <-> ERC20 trade.
    //
    // @param seller        The address of the account that wants to sell their 
    //                      'erc721' in exchange for 'price' denominated in 'erc20'.
    //
    // @param erc721        The address of a contract that follows the ERC-721 standard,
    //                      also the address of the collection that holds the token that 
    //                      you're purchasing.
    //
    // @param erc20         The address of a contract that follows the ERC-20 standard,
    //                      also the address of the token that the seller wants in exchange
    //                      for their 'erc721'
    //
    // @dev                 If 'erc20' is equal to address(0), we assume the seller wants
    //                      native ETH in exchange for their 'erc721'.
    //
    // @param tokenId       The 'erc721' token identification number, 'tokenId'.
    //
    // @param startPrice    The starting or fixed price the offered 'erc721' is being sold for, 
    //                      if ZERO we assume the 'seller' is hosting a dutch auction.
    //
    // @dev                 If a 'endPrice' and 'start' time are both defined, we assume
    //                      the order type is a dutch auction. So 'startPrice' would be
    //                      the price the auction starts at, otherwise 'startPrice' is
    //                      the fixed cost the 'seller' is charging.
    //
    // @param endPrice      The 'endPrice' is the price in which a dutch auction would no
    //                      no longer be valid after.
    //
    // @param start         The time in which the dutch auction starts, if ZERO we assume 
    //                      the 'seller' is hosting a dutch auction.
    //
    // @param deadline      The time in which the signature/swap is not valid after.
    struct SwapMetadata {
        address seller;
        address erc721;
        address erc20;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endPrice;
        uint256 start;
        uint256 deadline;
    }

    // @notice              Allows a buyer to execute an order given they've got
    //                      an secp256k1 signature from a seller containing verifiable
    //                      swap metadata.
    //
    // @param data          Struct containing metadata for a ERC721 <-> ERC20 trade.
    //
    // @param v             v is part of a valid secp256k1 signature from the seller.
    //
    // @param r             r is part of a valid secp256k1 signature from the seller.
    //
    // @param s             s is part of a valid secp256k1 signature from the seller.
    function swap(
        SwapMetadata calldata data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual payable {

        // Make sure both the 'erc721' and the 'erc20' wanted in exchange are both allowed.
        require(allowed[data.erc721] && allowed[data.erc20], "tokenNotWhitelisted()");

        // Make sure the deadline the 'seller' has specified has not elapsed.
        require(data.deadline >= block.timestamp, "orderExpired()");

        address signer = computeSigner(data, nonces[data.seller], v, r, s);

        // Make sure the recovered address is not NULL, and is equal to the 'seller'.
        require(signer != address(0) && signer == data.seller, "signatureInvalid()");
        
        uint256 price = computePrice(data);

        // Cache the fee that's going to be charged to the 'seller'.
        uint256 fee = FullMath.mulDiv(price, collectionFee[data.erc721], FEE_DIVISOR);

        // If 'erc20' is NULL, we assume the seller wants native ETH.
        if (data.erc20 == address(0)) {

            // Make sure the amount of ETH sent is at least the price specified.
            require(msg.value >= price, "insufficientMsgValue()");

            // Transfer msg.value minus 'fee' from this contract to 'seller'
            SafeTransferLib.safeTransferETH(signer, price - fee);

        // If 'erc20' is not NULL, we assume the seller wants a ERC20.
        } else {

            // Transfer 'erc20' 'price' minus 'fee' from caller to 'seller'.
            SafeTransferLib.safeTransferFrom(ERC20(data.erc20), msg.sender, signer, price - fee);
            
            // Transfer 'fee' to 'feeAddress'.
            SafeTransferLib.safeTransferFrom(ERC20(data.erc20), msg.sender, feeAddress, fee);
        }

        // Transfer 'erc721' from 'seller' to msg.sender/caller.
        IERC721(data.erc721).safeTransferFrom(signer, msg.sender, data.tokenId);

        // Emit event since state was mutated.
        emit OrderExecuted(signer, data.erc721, data.erc20, data.tokenId, price, data.deadline);
    }

    //////////////////////////////////////////////////////////////////////
    // MANAGMENT EVENTS
    //////////////////////////////////////////////////////////////////////

    // @notice emitted when 'feeAddress' is updated.
    event FeeAddressUpdated(
        address newFeeAddress
    );
    
    // @notice emitted when 'collectionFee' for 'collection' is updated.
    event CollectionFeeUpdated(
        address collection, 
        uint256 percent
    );
    
    // @notice emitted when 'allowed' for a 'token' has been updated.
    event WhitelistUpdated(
        address token,
        bool whitelisted
    );

    // @notice emitted when ETH from fees is collected from the contract.
    event FeeCollection(
        address token,
        uint256 amount
    );
    
    //////////////////////////////////////////////////////////////////////
    // MANAGMENT MODIFIERS
    //////////////////////////////////////////////////////////////////////

    // @notice only allows 'feeAddress' to call modified function.
    modifier access() {
        require(msg.sender == feeAddress, "ACCESS");
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // MANAGMENT ACTIONS
    //////////////////////////////////////////////////////////////////////

    function updateFeeAddress(address payable account) external virtual access {
        feeAddress = account;
        emit FeeAddressUpdated(account);
    }

    function updateCollectionFee(address collection, uint256 percent) external virtual access {
        collectionFee[collection] = percent;
        emit CollectionFeeUpdated(collection, percent);
    }

    function updateWhitelist(address token) external virtual access {
        bool whitelisted = !allowed[token];
        allowed[token] = whitelisted;
        emit WhitelistUpdated(token, whitelisted);
    }

    function collectEther() external virtual access {
        uint256 balance = address(this).balance;
        SafeTransferLib.safeTransferETH(feeAddress, balance);
        emit FeeCollection(address(0), balance);
    }

    function collectERC20(address token) external virtual access {
        uint256 balance = ERC20(token).balanceOf(address(this));
        SafeTransferLib.safeTransfer(ERC20(token), feeAddress, balance);
        emit FeeCollection(token, balance);
    }

    //////////////////////////////////////////////////////////////////////
    // EXTERNAL SIGNATURE VERIFICATION LOGIC
    //////////////////////////////////////////////////////////////////////

    // TODO 

    function verify(
        SwapMetadata calldata data,
        address buyer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual view returns (bool valid) {
        
        // make sure users have approvals as well

        // Make sure current time is greater than 'start' if order type is dutch auction. 
        if (data.start == 0 || data.endPrice == 0) {
            if (data.start > block.timestamp) return false;
        }

        // Make sure both the 'erc721' and the 'erc20' wanted in exchange are both allowed.
        if (!allowed[data.erc721] || !allowed[data.erc20]) return false;

        // Make sure the deadline the 'seller' has specified has not elapsed.
        if (data.deadline < block.timestamp) return false;

        // Make sure the 'seller' still owns the 'erc721' being offered.
        if (IERC721(data.erc721).ownerOf(data.tokenId) != data.seller) return false;

        // Make sure the buyer has 'price' denominated in 'erc20' if 'erc20' is not native ETH.
        if (data.erc20 != address(0)) {
            if (ERC20(data.erc20).balanceOf(buyer) < computePrice(data) && buyer != address(0)) return false;
        }

        address signer = computeSigner(data, nonces[data.seller], v, r, s);

        // Make sure the recovered address is not NULL, and is equal to the 'seller'.
        if (signer == address(0) || signer != data.seller) return false;

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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