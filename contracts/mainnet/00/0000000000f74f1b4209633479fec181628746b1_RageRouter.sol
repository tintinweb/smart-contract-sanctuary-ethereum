/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Contract Helpers.

/// @notice Contract helper for ERC1155 safeTransferFrom.
abstract contract ERC1155STF {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual;
}

/// @notice Contract helper for remote token (ERC20/721/1155) burns.
/// @dev These functions are opinionated to OpenZeppelin implementations.
abstract contract TokenBurn {
    /// @dev ERC20.
    function burnFrom(address from, uint256 amount) public virtual;

    /// @dev ERC721.
    function burn(uint256 id) public virtual;

    /// @dev ERC1155.
    function burn(address from, uint256 id, uint256 amount) public virtual;
}

/// @notice Contract helper for fetching token (ERC20/721/1155) balances and supply.
abstract contract TokenSupply {
    /// @dev ERC20/721.

    function balanceOf(address account) public view virtual returns (uint256);

    function totalSupply() public view virtual returns (uint256);

    /// @dev ERC721.

    function ownerOf(uint256 id) public view virtual returns (address);

    /// @dev ERC1155.

    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256);

    function totalSupply(uint256 id) public view virtual returns (uint256);
}

/// @dev Free functions.

/// @notice Arithmetic free function collection with operations for fixed-point numbers.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/FixedPointMath.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)

/// @dev The multiply-divide operation failed, either due to a
/// multiplication overflow, or a division by a zero.
error MulDivFailed();

/// @dev The maximum possible integer.
uint256 constant MAX_UINT256 = 2**256 - 1;

/// @dev Returns `floor(x * y / denominator)`.
/// Reverts if `x * y` overflows, or `denominator` is zero.
function mulDivDown(
    uint256 x,
    uint256 y,
    uint256 denominator
) pure returns (uint256 z) {
    assembly {
        // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
        if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
            // Store the function selector of `MulDivFailed()`.
            mstore(0x00, 0xad251c27)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }

        // Divide x * y by the denominator.
        z := div(mul(x, y), denominator)
    }
}

/// @notice Safe ETH and ERC20 free function transfer collection that gracefully handles missing return values.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransfer.sol)
/// @author Modified from Zolidity (https://github.com/z0r0z/zolidity/blob/main/src/utils/SafeTransfer.sol)

/// @dev The ERC20 `transferFrom` has failed.
error TransferFromFailed();

/// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
/// Reverts upon failure.
///
/// The `from` account must have at least `amount` approved for
/// the current contract to manage.
function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 amount
) {
    assembly {
        // We'll write our calldata to this slot below, but restore it later.
        let memPointer := mload(0x40)

        // Write the abi-encoded calldata into memory, beginning with the function selector.
        mstore(0x00, 0x23b872dd)
        mstore(0x20, from) // Append the "from" argument.
        mstore(0x40, to) // Append the "to" argument.
        mstore(0x60, amount) // Append the "amount" argument.

        if iszero(
            and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(eq(mload(0x00), 1), iszero(returndatasize())),
                // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
            )
        ) {
            // Store the function selector of `TransferFromFailed()`.
            mstore(0x00, 0x7939f424)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }

        mstore(0x60, 0) // Restore the zero slot to zero.
        mstore(0x40, memPointer) // Restore the memPointer.
    }
}

/// @dev Contracts.

/// @notice Contract helper for any EIP-2612, EIP-4494 or Dai-style token permit.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/Permit.sol)
abstract contract Permit {
    /// @dev ERC20.

    /// @notice Permit to spend tokens for EIP-2612 permit signatures.
    /// @param owner The address of the token holder.
    /// @param spender The address of the token permit holder.
    /// @param value The amount permitted to spend.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param v Must produce valid secp256k1 signature from the `owner` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `owner` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `owner` along with `r` and `v`.
    /// @dev This permit will work for certain ERC721 supporting EIP-2612-style permits,
    /// such as Uniswap V3 position and Solbase NFTs.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual;

    /// @notice Permit to spend tokens for permit signatures that have the `allowed` parameter.
    /// @param owner The address of the token holder.
    /// @param spender The address of the token permit holder.
    /// @param nonce The current nonce of the `owner`.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param allowed If true, `spender` will be given permission to spend `owner`'s tokens.
    /// @param v Must produce valid secp256k1 signature from the `owner` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `owner` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `owner` along with `r` and `v`.
    function permit(
        address owner,
        address spender,
        uint256 nonce,
        uint256 deadline,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual;

    /// @dev ERC721.

    /// @notice Permit to spend specific NFT `tokenId` for EIP-2612-style permit signatures.
    /// @param spender The address of the token permit holder.
    /// @param tokenId The ID of the token that is being approved for permit.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param v Must produce valid secp256k1 signature from the `owner` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `owner` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `owner` along with `r` and `v`.
    /// @dev Modified from Uniswap
    /// (https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/IERC721Permit.sol).
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual;

    /// @notice Permit to spend specific NFT `tokenId` for EIP-4494 permit signatures.
    /// @param spender The address of the token permit holder.
    /// @param tokenId The ID of the token that is being approved for permit.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param sig A traditional or EIP-2098 signature.
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata sig
    ) public virtual;

    /// @dev ERC1155.

    /// @notice Permit to spend multitoken IDs for EIP-2612-style permit signatures.
    /// @param owner The address of the token holder.
    /// @param operator The address of the token permit holder.
    /// @param approved If true, `operator` will be given permission to spend `owner`'s tokens.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param v Must produce valid secp256k1 signature from the `owner` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `owner` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `owner` along with `r` and `v`.
    function permit(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual;
}

/// @notice Self helper for any EIP-2612, EIP-4494 or Dai-style token permit.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SelfPermit.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/SelfPermit.sol)
/// @dev These functions are expected to be embedded in multicall to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit {
    /// @dev ERC20.

    /// @notice Permits this contract to spend a given EIP-2612 `token` from `msg.sender`.
    /// @dev The `owner` is always `msg.sender` and the `spender` is always `address(this)`.
    /// @param token The address of the asset spent.
    /// @param value The amount permitted to spend.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param v Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `msg.sender` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `v`.
    function selfPermit(
        Permit token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        token.permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// @notice Permits this contract to spend a given Dai-style `token` from `msg.sender`.
    /// @dev The `owner` is always `msg.sender` and the `spender` is always `address(this)`.
    /// @param token The address of the asset spent.
    /// @param nonce The current nonce of the `owner`.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param v Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `msg.sender` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `v`.
    function selfPermitAllowed(
        Permit token,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        token.permit(msg.sender, address(this), nonce, deadline, true, v, r, s);
    }

    /// @dev ERC721.

    /// @notice Permits this contract to spend a given EIP-2612-style NFT `tokenID` from `msg.sender`.
    /// @dev The `spender` is always `address(this)`.
    /// @param token The address of the asset spent.
    /// @param tokenId The ID of the token that is being approved for permit.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param v Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `msg.sender` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `v`.
    function selfPermit721(
        Permit token,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        token.permit(address(this), tokenId, deadline, v, r, s);
    }

    /// @notice Permits this contract to spend a given EIP-4494 NFT `tokenID`.
    /// @dev The `spender` is always `address(this)`.
    /// @param token The address of the asset spent.
    /// @param tokenId The ID of the token that is being approved for permit.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param sig A traditional or EIP-2098 signature.
    function selfPermit721(
        Permit token,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata sig
    ) public virtual {
        token.permit(address(this), tokenId, deadline, sig);
    }

    /// @dev ERC1155.

    /// @notice Permits this contract to spend a given EIP-2612-style multitoken.
    /// @dev The `owner` is always `msg.sender` and the `operator` is always `address(this)`.
    /// @param token The address of the asset spent.
    /// @param deadline The unix timestamp before which permit must be spent.
    /// @param v Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `s`.
    /// @param r Must produce valid secp256k1 signature from the `msg.sender` along with `v` and `s`.
    /// @param s Must produce valid secp256k1 signature from the `msg.sender` along with `r` and `v`.
    function selfPermit1155(
        Permit token,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        token.permit(msg.sender, address(this), true, deadline, v, r, s);
    }
}

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @dev WARNING!
/// Multicallable is NOT SAFE for use in contracts with checks / requires on `msg.value`
/// (e.g. in NFT minting / auction contracts) without a suitable nonce mechanism.
/// It WILL open up your contract to double-spend vulnerabilities / exploits.
/// See: (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire transaction is reverted,
    /// and the error is bubbled up.
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        assembly {
            if data.length {
                results := mload(0x40) // Point `results` to start of free memory.
                mstore(results, data.length) // Store `data.length` into `results`.
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20.
                let end := shl(5, data.length)
                // Copy the offsets from calldata into memory.
                calldatacopy(results, data.offset, end)
                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(results, end)
                end := add(results, end)

                // prettier-ignore
                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(results))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `memPtr` into `results`.
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
                    // prettier-ignore
                    if iszero(lt(results, end)) { break }
                }
                // Restore `results` and allocate memory for it.
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}

/// @notice Gas-optimized reentrancy protection for smart contracts.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        if (locked == 2) revert Reentrancy();

        locked = 2;

        _;

        locked = 1;
    }
}

/// @title Rage Router
/// @notice Fair share ragequit redemption for any token burn.

enum Standard {
    ERC20,
    ERC721,
    ERC1155
}

struct Redemption {
    address burner;
    address token;
    uint88 start;
    Standard std;
    uint256 id;
}

struct Withdrawal {
    address asset;
    Standard std;
    uint256 id;
}

/// @author z0r0z.eth
/// @custom:coauthor ameen.eth
/// @custom:coauthor mick.eth
contract RageRouter is SelfPermit, Multicallable, ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event RagequitSet(
        address indexed treasury,
        address indexed burner,
        address indexed token,
        Standard std,
        uint256 id,
        uint256 start
    );

    event Ragequit(
        address indexed redeemer,
        address indexed treasury,
        Withdrawal[] withdrawals,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error NotStarted();

    error InvalidAssetOrder();

    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Ragequit Storage
    /// -----------------------------------------------------------------------

    mapping(address => Redemption) public redemptions;

    /// -----------------------------------------------------------------------
    /// Configuration Logic
    /// -----------------------------------------------------------------------

    /// @dev Gas savings.
    constructor() payable {}

    /// @notice Configuration for ragequittable treasuries.
    /// @param burner The redemption sink for burnt `token`.
    /// @param token The redemption `token` that will be burnt.
    /// @param std The EIP interface for the redemption `token`.
    /// @param id The ID to set redemption configuration against.
    /// @param start The unix timestamp at which redemption starts.
    /// @dev The caller of this function will be set as the `treasury`.
    /// If `burner` is zero address, ragequit will trigger `token` burn.
    /// Otherwise, the user will have `token` pulled to `burner` and supply
    /// will be calculated with respect to `burner` balance before ragequit.
    /// `id` will be used if the `token` follows ERC1155 std. Kali slays Moloch.
    function setRagequit(
        address burner,
        address token,
        Standard std,
        uint256 id,
        uint256 start
    ) public payable virtual {
        redemptions[msg.sender] = Redemption({
            burner: burner,
            token: token,
            start: uint88(start),
            std: std,
            id: id
        });

        emit RagequitSet(msg.sender, burner, token, std, id, start);
    }

    /// -----------------------------------------------------------------------
    /// Ragequit Logic
    /// -----------------------------------------------------------------------

    /// @notice Allows ragequit redemption against `treasury`.
    /// @param treasury The vault holding `assets` for redemption.
    /// @param withdrawals Withdrawal instructions for `treasury`.
    /// @param quitAmount The amount of redemption tokens to be burned.
    /// @dev `quitAmount` acts as the token ID where redemption is ERC721.
    function ragequit(
        address treasury,
        Withdrawal[] calldata withdrawals,
        uint256 quitAmount
    ) public payable virtual nonReentrant {
        Redemption storage red = redemptions[treasury];

        if (block.timestamp < red.start) revert NotStarted();

        emit Ragequit(msg.sender, treasury, withdrawals, quitAmount);

        uint256 supply;

        // Branch on `Standard` of `token` burned in redemption
        // and whether `burner` is zero address.
        if (red.std == Standard.ERC20) {
            if (red.burner == address(0)) {
                supply = TokenSupply(red.token).totalSupply();

                TokenBurn(red.token).burnFrom(msg.sender, quitAmount);
            } else {
                // The `burner` balance cannot exceed total supply.
                unchecked {
                    supply =
                        TokenSupply(red.token).totalSupply() -
                        TokenSupply(red.token).balanceOf(red.burner);
                }

                safeTransferFrom(red.token, msg.sender, red.burner, quitAmount);
            }
        } else if (red.std == Standard.ERC721) {
            // Use `quitAmount` as `id`.
            if (msg.sender != TokenSupply(red.token).ownerOf(quitAmount))
                revert NotOwner();

            if (red.burner == address(0)) {
                supply = TokenSupply(red.token).totalSupply();

                TokenBurn(red.token).burn(quitAmount);
            } else {
                // The `burner` balance cannot exceed total supply.
                unchecked {
                    supply =
                        TokenSupply(red.token).totalSupply() -
                        TokenSupply(red.token).balanceOf(red.burner);
                }

                safeTransferFrom(red.token, msg.sender, red.burner, quitAmount);
            }

            // Overwrite `quitAmount` `id` to 1 for single NFT burn.
            quitAmount = 1;
        } else {
            if (red.burner == address(0)) {
                supply = TokenSupply(red.token).totalSupply(red.id);

                TokenBurn(red.token).burn(msg.sender, red.id, quitAmount);
            } else {
                // The `burner` balance cannot exceed total supply.
                unchecked {
                    supply =
                        TokenSupply(red.token).totalSupply(red.id) -
                        TokenSupply(red.token).balanceOf(red.burner, red.id);
                }

                ERC1155STF(red.token).safeTransferFrom(
                    msg.sender,
                    red.burner,
                    red.id,
                    quitAmount,
                    ""
                );
            }
        }

        address prevAddr;
        Withdrawal calldata draw;

        for (uint256 i; i < withdrawals.length; ) {
            draw = withdrawals[i];

            // Prevent null and duplicate `asset`.
            if (prevAddr >= draw.asset) revert InvalidAssetOrder();

            prevAddr = draw.asset;

            // Calculate fair share of given `asset` for `quitAmount`.
            uint256 amountToRedeem = mulDivDown(
                quitAmount,
                draw.std == Standard.ERC20
                    ? TokenSupply(draw.asset).balanceOf(treasury)
                    : TokenSupply(draw.asset).balanceOf(treasury, draw.id),
                supply
            );

            // Transfer fair share from `treasury` to caller.
            if (amountToRedeem != 0) {
                draw.std == Standard.ERC20
                    ? safeTransferFrom(
                        draw.asset,
                        treasury,
                        msg.sender,
                        amountToRedeem
                    )
                    : ERC1155STF(draw.asset).safeTransferFrom(
                        treasury,
                        msg.sender,
                        draw.id,
                        amountToRedeem,
                        ""
                    );
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
    }
}