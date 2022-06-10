// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ITraitOracle.sol";

contract CircuitOracle is ITraitOracle {
    uint256 internal constant OP_STOP = 0x00;
    uint256 internal constant OP_NOT = 0x01;
    uint256 internal constant OP_OR = 0x02;
    uint256 internal constant OP_AND = 0x03;

    string internal constant ERR_OVERRUN_BASE_TRAIT =
        "CircuitOracle: base trait buffer overrun";
    string internal constant ERR_OVERRUN_ARG =
        "CircuitOracle: arg buffer overrun";

    /// Checks if the given token satisfies the circuit specified by `_buf`.
    ///
    /// `_buf` should be at least 96 bytes long, with the following format:
    ///
    ///   - Bytes 0 through 31 specify the address of an underlying trait
    ///     oracle (zero-padded per Solidity ABI conventions).
    ///   - Bytes 32 through 63 specify a `uint256` that encodes the lengths of
    ///     between 0 and 16 (inclusive) base traits, each 16 bits long.
    ///   - Bytes 64 through 95 specify between 0 and 128 (inclusive) circuit
    ///     opcodes, each 2 bits long.
    ///   - The remaining bytes consist of two parts: first, all the base
    ///     traits, concatenated together without delimeters; second, one byte
    ///     per operand to the ops in the circuit up to and excluding the first
    ///     STOP op, totaling one byte per NOT op plus two bytes per OR or AND
    ///     op.
    ///
    /// Details of base trait lengths: There are at most 16 base traits, and
    /// each must be at most 65534 (0xfffe) bytes long. The length of each base
    /// trait is incremented by one to form a `uint16`, and the `_i`th such
    /// value is stored in  `(_encodedLengths >> (16 * _i)) & 0xffff`. There
    /// are no more base traits once this evaluates to `0` (because `0` is not
    /// `_len + 1` for any `_len`).
    ///
    /// Details of opcodes: There are at most 128 ops in the circuit. Each
    /// opcode is encoded as a 2-bit value: STOP is 0, NOT is 1, OR is 2, AND
    /// is 3. Opcode `_i` is stored in `(_ops >> (2 * _i)) & 0x03`. Once this
    /// evaluates to 0, circuit evaluation stops and returns the most recently
    /// computed value, or `false` if there were no base traits and no ops
    /// other than STOP.
    ///
    /// Details of evaluation: There is a bank of 256 boolean variables, all
    /// initially false. First, the base traits (if any) are read from `_buf`.
    /// The underlying trait oracle is invoked for each, and the result for the
    /// `_i`th trait is stored into variable `_i`. Next, the ops are processed
    /// sequentially. A STOP op immediately stops evaluation. A NOT, OR, or AND
    /// op consumes either 1 or 2 argument indices from `_buf`, reads the
    /// argument variable(s) from the 256-cell bank, and applies the operation.
    /// Each argument index is a single byte from `_buf` and corresponds to one
    /// of the 256 boolean variables. Once the op is evaluated, it is written
    /// into the next free variable. Thus, if there were `_n` base traits, the
    /// `_i`th op's result is stored into variable `_n + _i`.
    ///
    /// When evaluation stops, the result is the most recently written
    /// variable, or `false` if no variables were written. That is: the result
    /// is the result of the last op, or the last base trait if there were no
    /// ops, or `false` if there were no ops and no base traits.
    function hasTrait(
        IERC721 _tokenContract,
        uint256 _tokenId,
        bytes calldata _buf
    ) external view override returns (bool) {
        // Decode the static part of the header (the first 96 bytes), then
        // advance to the dynamic part.
        (ITraitOracle _delegate, uint256 _traitLengths, uint256 _ops) = abi
            .decode(_buf, (ITraitOracle, uint256, uint256));
        uint256 _bufIdx = 96; // read-offset into dynamic part of `_buf`

        uint256 _mem = 0; // `_mem & (1 << _i)` stores variable `_i`
        uint256 _v = 0; // next variable to assign
        //
        // INVARIANT: `_v` is always at most 144, because it's only ever
        // changed by incrementing it by 1 once per loop iteration, and the two
        // loops run at most 16 and 128 times, respectively. In particular,
        // it's always safe to increment `_v`.

        // Read and initialize base trait variables.
        //
        // NOTE: This loop runs at most 16 times, because it shifts
        // `_traitLengths` right by 16 bits each iteration and stops once
        // that reaches zero.
        while (true) {
            // `_traitLength` is zero if we're out of traits, else it's one
            // more than the length of the next trait.
            uint256 _traitLength = _traitLengths & 0xffff;
            _traitLengths >>= 16;
            if (_traitLength == 0) break;
            // SAFETY: We've just checked that `_traitLength != 0`, so this
            // can't underflow.
            _traitLength = uncheckedSub(_traitLength, 1);

            if (_bufIdx + _traitLength > _buf.length)
                revert(ERR_OVERRUN_BASE_TRAIT);
            bool _hasTrait = _delegate.hasTrait(
                _tokenContract,
                _tokenId,
                _buf[_bufIdx:_bufIdx + _traitLength]
            );
            _bufIdx += _traitLength;
            _mem |= boolToUint256(_hasTrait) << _v;
            // SAFETY: `_v` is at most 144, so incrementing it can't overflow.
            _v = uncheckedAdd(_v, 1);
        }

        // Evaluate operations. Henceforth, `_buf` represents the full array of
        // arguments.
        //
        // NOTE: This loop runs at most 128 times, because it shifts `_ops`
        // right by 2 bits each iteration and stops once that reaches zero.
        //
        // NOTE: Before this loop, `_bufIdx <= _buf.length`, and during this
        // loop, `_bufIdx` advances by at most 2 per iteration. Thus, it always
        // holds that `_bufIdx <= _buf.length + 256`, so these increments to
        // `_bufIdx` can't overflow unless `_buf` is order-of 2^256 bytes long.
        while (true) {
            uint256 _op = _ops & 0x03;
            _ops >>= 2;
            if (_op == OP_STOP) break;

            // This is a unary or binary operation; compute its output.
            bool _output;
            if (_op == OP_NOT) {
                uint256 _idx0 = _bufIdx;
                // SAFETY: `_bufIdx <= _buf.length + 256`, so this shouldn't
                // overflow.
                _bufIdx = uncheckedAdd(_bufIdx, 1);

                if (_buf.length < _bufIdx) revert(ERR_OVERRUN_ARG);
                bool _v0 = (_mem & (1 << uint256(uint8(_buf[_idx0])))) != 0;
                _output = !_v0;
            } else {
                // It's a binary operation, either `OP_OR` or `OP_AND`.
                uint256 _idx0 = _bufIdx;
                // SAFETY: `_bufIdx <= _buf.length + 256`, so this shouldn't
                // overflow.
                uint256 _idx1 = uncheckedAdd(_bufIdx, 1);
                _bufIdx = uncheckedAdd(_bufIdx, 2);

                if (_buf.length < _bufIdx) revert(ERR_OVERRUN_ARG);
                bool _v0 = (_mem & (1 << uint256(uint8(_buf[_idx0])))) != 0;
                bool _v1 = (_mem & (1 << uint256(uint8(_buf[_idx1])))) != 0;
                if (_op == OP_OR) {
                    _output = _v0 || _v1;
                } else {
                    _output = _v0 && _v1;
                }
            }

            // Store its output into the next free variable.
            _mem |= boolToUint256(_output) << _v;
            // SAFETY: `_v` is at most 144, so incrementing it can't overflow.
            _v = uncheckedAdd(_v, 1);
        }

        if (_v == 0) return false; // no base traits or ops
        // SAFETY: We've just checked that `_v != 0`, so this subtraction
        // can't underflow.
        return (_mem & (1 << uncheckedSub(_v, 1))) != 0;
    }

    /// Returns `_a + _b` without checking for or signalling overflow.
    ///
    /// # Safety
    ///
    /// Caller must ensure that `_a + _b` would not overflow or be prepared to
    /// handle an overflowed result.
    function uncheckedAdd(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return _a + _b;
        }
    }

    /// Returns `_a - _b` without checking for or signalling underflow.
    ///
    /// # Safety
    ///
    /// Caller must ensure that `_a - _b` would not underflow or be prepared to
    /// handle an underflowed result.
    function uncheckedSub(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return _a - _b;
        }
    }

    /// Equivalent to `uint256(_b ? 1 : 0)`, but without the `jump`/`jumpi`
    /// sequence that solc generates for that input.
    function boolToUint256(bool _b) internal pure returns (uint256 _x) {
        assembly {
            _x := _b
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitOracle {
    /// Queries whether the given NFT has the given trait. The NFT is specified
    /// by token ID only; the token contract is assumed to be known already.
    /// For instance, a trait oracle could be designed for a specific token
    /// contract, or it could call a method on `msg.sender` to determine what
    /// contract to use.
    ///
    /// The interpretation of trait IDs may be domain-specific and is at the
    /// discretion of the trait oracle. For example, an oracle might choose to
    /// encode traits called "Normal" and "Rare" as `0` and `1` respectively,
    /// or as `uint256(keccak256("Normal"))` and `uint256(keccak256("Rare"))`,
    /// or as something else. The trait oracle may expose other domain-specific
    /// methods to describe these traits.
    function hasTrait(
        IERC721 _tokenContract,
        uint256 _tokenId,
        bytes calldata _trait
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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