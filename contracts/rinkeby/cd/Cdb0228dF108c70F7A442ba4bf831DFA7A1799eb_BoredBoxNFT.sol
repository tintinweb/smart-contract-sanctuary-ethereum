// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

import { BoredBoxStorage } from "@boredbox-solidity-contracts/bored-box-storage/contracts/BoredBoxStorage.sol";
import { IBoredBoxNFT_Functions } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";
import { LibraryBoredBoxNFT } from "@boredbox-solidity-contracts/library-bored-box-nft/contracts/LibraryBoredBoxNFT.sol";
import { Ownable } from "@boredbox-solidity-contracts/ownable/contracts/Ownable.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ERC721 } from "../contracts/token/ERC721/ERC721.sol";

// Force descovery of NPM installed contract artifacts
import { ValidateMint_Generation } from "@boredbox-solidity-contracts/validate-mint/contracts/ValidateMint_Generation.sol";
import { IValidateMint_Generation } from "@boredbox-solidity-contracts/validate-mint/contracts/interfaces/IValidateMint_Generation.sol";
import { ValidateMint_PresaleAddresses } from "@boredbox-solidity-contracts/validate-mint/contracts/ValidateMint_PresaleAddresses.sol";
import { IValidateMint_PresaleAddresses } from "@boredbox-solidity-contracts/validate-mint/contracts/interfaces/IValidateMint_PresaleAddresses.sol";
import { ValidateMint_Signature } from "@boredbox-solidity-contracts/validate-mint/contracts/ValidateMint_Signature.sol";
import { IValidateMint_Signature } from "@boredbox-solidity-contracts/validate-mint/contracts/interfaces/IValidateMint_Signature.sol";
// TODO: Remove above when "@truffle/contract" is installed and configured

/// @title Tracks BoredBox token ownership and coordinates minting
///
/// @dev Warning `boxId`, and `tokenId`, indexes start at `1` **not** `0`
///      this is to allow for unset `mapping` values to consistently produce
///      _falsey_ values, however, this does create a _foot-gun_ of possible
///      trickle-down off-by-one errors!
///
/// @author S0AndS0
///
/// @custom:link https://boredbox.io/
contract BoredBoxNFT is BoredBoxStorage, ERC721, Ownable, ReentrancyGuard {
    /// Emitted when owner confirms Box to be minted
    // @param to address of `token__owner[tokenId]`
    // @param tokenId pointer into `token__owner`, `token__opened_timestamp`, `token__status`, `token__generation`
    event Mint(address indexed to, uint256 indexed tokenId);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑         Custom events       ↑ */
    /* ↓  Modifiers and constructor  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @custom:throw "Not authorized" if `msg.sender` is not contract owner or `coordinator` address
    modifier onlyAuthorized() {
        require(
            msg.sender == this.owner() || (coordinator != address(0) && msg.sender == coordinator),
            "Not authorized"
        );
        _;
    }

    /// Called via `new BoredBoxNFT(/* ... */)`
    /// @param name_ NFT name to store in `name`
    /// @param symbol_ NFT symbol to pass to `ERC721` parent contract
    /// @param coordinator_ Address to store in `coordinator`
    /// @param uri_root string pointing to IPFS directory of JSON metadata files
    /// @param quantity Amount of tokens available for first generation
    /// @param price Exact `{ value: _price_ }` required by `mint()` function
    /// @param sale_time The `block.timestamp` to allow general requests to `mint()` function
    /// @param ref_validators List of addresses referencing `ValidateMint` contracts
    /// @param cool_down Time to add to current `block.timestamp` after `token__status` is set to `TOKEN_STATUS__OPENED`
    /// @custom:throw "Open time must be after sale time"
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        address coordinator_,
        string memory uri_root,
        uint256 quantity,
        uint256 price,
        uint256 sale_time,
        uint256 open_time,
        address[] memory ref_validators,
        uint256 cool_down
    ) ERC721(name_, symbol_) Ownable(owner_) {
        require(open_time >= sale_time, "Open time must be after sale time");

        current_box = 1;
        coordinator = coordinator_;

        box__uri_root[1] = uri_root;

        box__lower_bound[1] = 1;
        box__upper_bound[1] = quantity;
        box__quantity[1] = quantity;
        box__price[1] = price;

        box__sale_time[1] = sale_time;
        box__cool_down[1] = cool_down;
        box__open_time[1] = open_time;

        box__validators[1] = ref_validators;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Modifiers and constructor  ↑ */
    /* ↓       on-chain external     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IBoredBoxNFT_Functions-mint}
    function mint(address to, bytes memory auth) external payable {
        uint256 boxId = current_box;
        require(msg.value == box__price[boxId], "Incorrect amount sent");
        return _mintBox(to, boxId, auth);
    }

    /// @dev See {IBoredBoxNFT_Functions-mint}
    function mint(
        address to,
        uint256 boxId,
        bytes memory auth
    ) external payable {
        require(msg.value == box__price[boxId], "Incorrect amount sent");
        return _mintBox(to, boxId, auth);
    }

    /// @dev See {IBoredBoxNFT_Functions-open}
    function setPending(uint256[] memory tokenIds) external onlyAuthorized {
        return LibraryBoredBoxNFT.setPending(token__status, address(this), tokenIds);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑     on-chain external    ↑ */
    /* ↓  miscellaneous external  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  miscellaneous external  ↑ */
    /* ↓    off-chain external    ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IBoredBoxNFT_Functions-box__allValidators}
    function box__allValidators(uint256 boxId) external view virtual returns (address[] memory) {
        return box__validators[boxId];
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function setOpened(uint256[] memory tokenIds) external onlyAuthorized {
        return LibraryBoredBoxNFT.setOpened(token__status, token__opened_timestamp, address(this), tokenIds);
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function setBoxURI(uint256 boxId, string memory uri_root) external onlyAuthorized {
        return LibraryBoredBoxNFT.setBoxURI(box__uri_root, boxId, uri_root);
    }

    /// @dev See {IBoredBoxNFT_Functions-setIsPaused}
    function setIsPaused(uint256 boxId, bool is_paused) external onlyAuthorized {
        box__is_paused[boxId] = is_paused;
    }

    /// @dev See {IBoredBoxNFT_Functions-setAllPaused}
    function setAllPaused(bool is_paused) external onlyAuthorized {
        all_paused = is_paused;
    }

    /// @dev See {IBoredBoxNFT_Functions-setAllPaused}
    function setCoordinator(address coordinator_) external onlyOwner {
        coordinator = coordinator_;
    }

    /// @dev See {IBoredBoxNFT_Functions-newBox}
    function newBox(
        string memory uri_root,
        uint256 quantity,
        uint256 price,
        uint256 sale_time,
        uint256 open_time,
        address[] memory ref_validators,
        uint256 cool_down
    ) external onlyOwner {
        require(!all_paused, "New boxes are paused");
        require(open_time >= sale_time, "Open time must be after sale time");

        uint256 last_boxId = current_box;
        uint256 next_boxId = 1 + last_boxId;

        // Assume               quantity == 100
        //              last_upper_bound == 1000
        //  box__lower_bound[next_boxId] == 1001
        //  box__upper_bound[next_boxId] == 1100
        //
        // Assume               quantity == 1000
        //              last_upper_bound == 1100
        //  box__lower_bound[next_boxId] == 1101
        //  box__upper_bound[next_boxId] == 2101
        uint256 last_upper_bound = box__upper_bound[last_boxId];
        box__lower_bound[next_boxId] += 1 + last_upper_bound;
        box__upper_bound[next_boxId] = last_upper_bound + quantity;
        box__quantity[next_boxId] = quantity;
        box__price[next_boxId] = price;

        box__uri_root[next_boxId] = uri_root;

        box__validators[next_boxId] = ref_validators;

        box__sale_time[next_boxId] = sale_time;
        box__open_time[next_boxId] = open_time;
        box__cool_down[next_boxId] = cool_down;

        current_box = next_boxId;
    }

    /// @dev See {IBoredBoxNFT_Functions-withdraw}
    function withdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Transfer failed");
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑     off-chain external      ↑ */
    /* ↓   Overrides ERC721 public   ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IERC721Metadata-tokenURI}
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return LibraryBoredBoxNFT.tokenURI(address(this), tokenId);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑   Overrides ERC721 public   ↑ */
    /* ↓  Overrides ERC721 internal  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {ERC721-_beforeTokenTransfer}
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        return LibraryBoredBoxNFT.validateTransfer(address(this), from, to, tokenId);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Overrides ERC721 internal  ↑ */
    /* ↓  Customize ERC721 internal  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function _mintBox(
        address to,
        uint256 boxId,
        bytes memory auth
    ) internal nonReentrant {
        uint256 tokenId = LibraryBoredBoxNFT.validateMint(address(this), to, boxId, auth);

        super._safeMint(to, tokenId);
        box__quantity[boxId] -= 1;
        token__generation[tokenId] = boxId;
        token__original_owner[boxId][to] = tokenId;
        emit Mint(to, tokenId);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Collection name
    string public name;

    // Collection symbol
    string public symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public token__owner;

    // Mapping owner address to token count
    mapping(address => uint256) public balanceOf;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = token__owner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return token__owner[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        balanceOf[to] += 1;
        token__owner[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        balanceOf[owner] -= 1;
        delete token__owner[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        balanceOf[from] -= 1;
        balanceOf[to] += 1;
        token__owner[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IOwnable } from "@boredbox-solidity-contracts/ownable/contracts/interfaces/IOwnable.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

/* Variable getters */
interface IValidateMint_Signature_Variables {
    /// @param boxId retrieve public key/address for given `boxId`
    function box__signer(uint256 boxId) external view returns (address);

    /// @param tokenId Retrieve authentication bytes for given `tokenId`
    function token__auth(uint256 tokenId) external view returns (bytes memory);

    /// @param auth Retrieve token Id for given `auth`
    function auth__token(bytes memory auth) external view returns (uint256);
}

/* Function definitions */
interface IValidateMint_Signature_Functions {
    /// Store data for new generation
    /// @param boxId Generation key to store `box__signer` value
    /// @param signer Public key/address to validate signatures with
    /// @custom:throw "Token already has auth"
    /// @custom:throw "Invalid box ID"
    /// @custom:throw "Signer already assigned"
    function newBox(uint256 boxId, address signer) external;
}

/* For external callers */
interface IValidateMint_Signature is
    IValidateMint_Signature_Functions,
    IValidateMint_Signature_Variables,
    IValidateMint,
    IOwnable
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IOwnable } from "@boredbox-solidity-contracts/ownable/contracts/interfaces/IOwnable.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

/* Variable getters */
interface IValidateMint_PresaleAddresses_Variables {
    /// @param boxId Generation of pre-sale addresses
    /// @param index Retrieve pre-sale address of given array `index`
    function presale_addresses(uint256 boxId, uint256 index) external view returns (address);

    /// @param boxId Retrieve max quantity for given `boxId`
    function quantity(uint256 boxId) external view returns (uint256);

    /// @param boxId Retrieve sale time for given `boxId`
    function sale_time(uint256 boxId) external view returns (uint256);
}

/* Function definitions */
interface IValidateMint_PresaleAddresses_Functions {
    /// Store data for new generation
    /// @param presale_addresses_ Array of addresses allowed to participate in pre-sale
    /// @param boxId Generation key to store `presale_addresses`, `sale_time`, and `quantity` values
    /// @param quantity_ Maxim amount of tokens available for pre-sale
    /// @param sale_time_ When pre-sale is allowed for authorized addresses
    /// @custom:throw "No addresses provided"
    /// @custom:throw "Box must be greater than `0`"
    /// @custom:throw "Quantity must be greater than `0`"
    /// @custom:throw "Sale time not in future"
    /// @custom:throw "Box ID already assigned"
    function newBox(
        address[] memory presale_addresses_,
        uint256 boxId,
        uint256 quantity_,
        uint256 sale_time_
    ) external;

    /// Retrieve full array of all pre-sale addresses for given generation
    /// @param boxId Generation key to find within `presale_addresses` storage
    /// @custom:throw "No addresses for Box ID"
    function getPresaleAddresses(uint256 boxId) external view returns (address[] memory);
}

/* For external callers */
interface IValidateMint_PresaleAddresses is
    IValidateMint_PresaleAddresses_Functions,
    IValidateMint_PresaleAddresses_Variables,
    IValidateMint,
    IOwnable
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IOwnable } from "@boredbox-solidity-contracts/ownable/contracts/interfaces/IOwnable.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

/* Variable getters */
interface IValidateMint_Generation_Variables {
    /// @param boxId Retrieve generation `msg.sender` must own for given `boxId`
    function generation(uint256 boxId) external view returns (uint256);

    /// @param boxId Retrieve max quantity for given `boxId`
    function quantity(uint256 boxId) external view returns (uint256);

    /// @param boxId Retrieve sale time for given `boxId`
    function sale_time(uint256 boxId) external view returns (uint256);
}

/* Function definitions */
interface IValidateMint_Generation_Functions {
    /// Store data for new generation
    /// @param boxId Generation key to store `sale_time`, and `quantity` values
    /// @param generation_ Box generation that must be owned to participate
    /// @param quantity_ Maxim amount of tokens available for pre-sale
    /// @param sale_time_ When pre-sale is allowed for authorized addresses
    /// @custom:throw "Box must be greater than `0`"
    /// @custom:throw "Box ID must be greater than target generation"
    /// @custom:throw "Quantity must be greater than `0`"
    /// @custom:throw "Sale time not in future"
    /// @custom:throw "Box ID already assigned"
    function newBox(
        uint256 boxId,
        uint256 generation_,
        uint256 quantity_,
        uint256 sale_time_
    ) external;
}

/* For external callers */
interface IValidateMint_Generation is
    IValidateMint_Generation_Functions,
    IValidateMint_Generation_Variables,
    IValidateMint,
    IOwnable
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Ownable } from "@boredbox-solidity-contracts/ownable/contracts/Ownable.sol";

import { IBoredBoxNFT } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";

import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { BytesLib } from "solidity-bytes-utils/contracts/BytesLib.sol";

import { IValidateMint_Signature_Functions } from "./interfaces/IValidateMint_Signature.sol";
import { AValidateMint } from "./AValidateMint.sol";

/// Reusable validation contract for allowing pre-sale to owners of past Box generations
contract ValidateMint_Signature is AValidateMint, IValidateMint_Signature_Functions, Ownable, ReentrancyGuard {
    // Mapping boxId to ECDSA public key
    mapping(uint256 => address) public box__signer;

    // Mapping tokenId to auth
    mapping(uint256 => bytes) public token__auth;

    // Mapping auth to tokenId
    mapping(bytes => uint256) public auth__token;

    /// @custom:throw "Invalid signer"
    /// @custom:throw "Invalid box ID"
    constructor(
        address owner_,
        uint256 boxId,
        address signer
    ) Ownable(owner_) {
        require(signer != address(0), "Invalid signer");
        require(boxId > 0, "Invalid box ID");
        box__signer[boxId] = signer;
    }

    /// @dev See {IValidateMint_Functions-validate}
    /// @custom:todo double-check that ReentrancyGuard is utilized correctly
    /// @custom:throw "Invalid signer"
    /// @custom:throw "Auth already for token"
    /// @custom:throw "Token already has auth"
    function validate(
        address, /* __to__ */
        uint256 boxId,
        uint256 tokenId,
        bytes memory auth
    ) external virtual override nonReentrant returns (uint256 validate_status) {
        require(box__signer[boxId] != address(0), "Invalid signer");
        require(auth__token[auth] == 0, "Auth already for token");
        require(token__auth[tokenId].length == 0, "Token already has auth");

        bytes32 hash;
        assembly {
            hash := mload(add(auth, 32))
        }

        bytes memory signature = BytesLib.slice(auth, 32, auth.length - 32);

        require(SignatureChecker.isValidSignatureNow(box__signer[boxId], hash, signature), "Invalid signature");

        token__auth[tokenId] = auth;
        auth__token[auth] = tokenId;
        return VALIDATE_STATUS__PASS;
    }

    /// @dev See {IValidateMint_Signature_Functions-validate}
    function newBox(uint256 boxId, address signer) external onlyOwner {
        require(signer != address(0), "Invalid signer");
        require(boxId > 0, "Invalid box ID");
        require(box__signer[boxId] == address(0), "Signer already assigned");
        box__signer[boxId] = signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Ownable } from "@boredbox-solidity-contracts/ownable/contracts/Ownable.sol";

import { IBoredBoxNFT } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";

import { IValidateMint_PresaleAddresses_Functions } from "./interfaces/IValidateMint_PresaleAddresses.sol";
import { AValidateMint } from "./AValidateMint.sol";

/// Allow select addresses access to pre-sale
/// @dev This `.quantity` must be half, or less, of `iBox.box__quantity(boxId)`
contract ValidateMint_PresaleAddresses is AValidateMint, IValidateMint_PresaleAddresses_Functions, Ownable {
    // Mapping of boxId to list of addresses allowed to participate in genesis pre-sale
    mapping(uint256 => address[]) public presale_addresses;

    // Mapping of boxId to quantity available for pre-sale
    mapping(uint256 => uint256) public quantity;

    // Mapping of boxId to when pre-sale starts
    mapping(uint256 => uint256) public sale_time;

    /// @custom:throw "No addresses provided"
    /// @custom:throw "Box must be greater than `0`"
    /// @custom:throw "Quantity must be greater than `0`"
    /// @custom:throw "Sale time not in future"
    constructor(
        address owner_,
        address[] memory _presale_addresses,
        uint256 boxId,
        uint256 _quantity,
        uint256 _sale_time
    ) Ownable(owner_) {
        require(_presale_addresses.length > 0, "No addresses provided");
        require(boxId > 0, "Box must be greater than `0`");
        require(_quantity > 0, "Quantity must be greater than `0`");
        require(_sale_time >= block.timestamp - 1 hours, "Sale time not in future");

        presale_addresses[boxId] = _presale_addresses;
        quantity[boxId] = _quantity;
        sale_time[boxId] = _sale_time;
    }

    /// @dev See {IValidateMint_Functions-validate}
    /// @custom:throw "Pre-sale finished"
    /// @custom:throw "Target not eligible for pre-sale"
    function validate(
        address to,
        uint256 boxId,
        uint256, /* __tokenId__ */
        bytes memory /* __auth__ */
    ) external virtual override returns (uint256 validate_status) {
        if (block.timestamp < sale_time[boxId]) {
            return VALIDATE_STATUS__NA;
        }

        IBoredBoxNFT iBox = IBoredBoxNFT(msg.sender);
        if (block.timestamp >= iBox.box__sale_time(boxId)) {
            // Pre-sale not applicable
            return VALIDATE_STATUS__NA;
        }

        require(iBox.box__quantity(boxId) >= quantity[boxId], "Pre-sale finished");

        address[] memory _presale_addresses = presale_addresses[boxId];
        uint256 length = _presale_addresses.length;
        for (uint256 i; i < length; ) {
            if (to == _presale_addresses[i]) {
                return VALIDATE_STATUS__PASS;
            }
            unchecked {
                ++i;
            }
        }

        return VALIDATE_STATUS__NA;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑   on-chain external  ↑ */
    /* ↓  off-chain external  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {IValidateMint_PresaleAddresses_Functions-newBox}
    function newBox(
        address[] memory _presale_addresses,
        uint256 boxId,
        uint256 _quantity,
        uint256 _sale_time
    ) external onlyOwner {
        require(_presale_addresses.length > 0, "No addresses provided");
        require(boxId > 0, "Box must be greater than `0`");
        require(_quantity > 0, "Quantity must be greater than `0`");
        require(_sale_time >= block.timestamp - 1 hours, "Sale time not in future");
        require(sale_time[boxId] == 0, "Box ID already assigned");

        presale_addresses[boxId] = _presale_addresses;
        sale_time[boxId] = _sale_time;
        quantity[boxId] = _quantity;
    }

    /// @dev See {IValidateMint_PresaleAddresses_Functions-getPresaleAddresses}
    function getPresaleAddresses(uint256 boxId) external view returns (address[] memory) {
        require(presale_addresses[boxId].length > 0, "No addresses for Box ID");
        return presale_addresses[boxId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Ownable } from "@boredbox-solidity-contracts/ownable/contracts/Ownable.sol";

import { IBoredBoxNFT } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";

import { IValidateMint_Generation_Functions } from "./interfaces/IValidateMint_Generation.sol";

import { AValidateMint } from "./AValidateMint.sol";

/// Reusable validation contract for allowing pre-sale to owners of past Box generations
contract ValidateMint_Generation is AValidateMint, IValidateMint_Generation_Functions, Ownable {
    // Mapping boxId to generation owner boxId
    mapping(uint256 => uint256) public generation;

    // Mapping boxId to quantity
    mapping(uint256 => uint256) public quantity;

    // Mapping boxId to sale_time
    mapping(uint256 => uint256) public sale_time;

    /// @custom:throw "Box must be greater than `0`"
    /// @custom:throw "Box ID must be greater than target generation"
    /// @custom:throw "Quantity must be greater than `0`"
    /// @custom:throw "Sale time not in future"
    constructor(
        address owner_,
        uint256 boxId,
        uint256 generation_,
        uint256 quantity_,
        uint256 sale_time_
    ) Ownable(owner_) {
        require(boxId > 0, "Box must be greater than `0`");
        require(boxId > generation_, "Box ID must be greater than target generation");
        require(quantity_ > 0, "Quantity must be greater than `0`");
        require(sale_time_ >= block.timestamp - 1 hours, "Sale time not in future");

        generation[boxId] = generation_;
        quantity[boxId] = quantity_;
        sale_time[boxId] = sale_time_;
    }

    /// @dev See {IValidateMint_Functions-validate}
    /// @custom:throw "Please wait till sale time"
    /// @custom:throw "Invalid generation for boxId"
    /// @custom:throw "Target does not own box of target generation"
    function validate(
        address to,
        uint256 boxId,
        uint256, /* __tokenId__ */
        bytes memory /* __auth__ */
    ) external virtual override returns (uint256 validate_status) {
        IBoredBoxNFT iBox = IBoredBoxNFT(msg.sender);
        if (block.timestamp >= iBox.box__sale_time(boxId)) {
            // Pre-sale not applicable
            return VALIDATE_STATUS__NA;
        }

        require(block.timestamp >= sale_time[boxId], "Please wait till sale time");

        uint256 generation_boxId = generation[boxId];
        require(generation_boxId > 0, "Invalid generation for boxId");

        uint256 upper_bound = iBox.box__upper_bound(generation_boxId);
        for (uint256 i = iBox.box__lower_bound(boxId); i <= upper_bound; ) {
            address token_owner = iBox.token__owner(i);
            if (token_owner == to) {
                return VALIDATE_STATUS__PASS;
            } else if (token_owner == address(0)) {
                // Note: to trust this short-circuit, ownership gaps between
                //       upper/lower bounds should never be allowed
                return VALIDATE_STATUS__NA;
            }
            unchecked {
                ++i;
            }
        }

        revert("Target does not own box of target generation");
    }

    /// @dev See {IValidateMint_Generation_Functions-newBox}
    function newBox(
        uint256 boxId,
        uint256 generation_,
        uint256 quantity_,
        uint256 sale_time_
    ) external onlyOwner {
        require(boxId > 0, "Box must be greater than `0`");
        require(boxId > generation_, "Box ID must be greater than target generation");
        require(quantity_ > 0, "Quantity must be greater than `0`");
        require(sale_time_ >= block.timestamp - 1 hours, "Sale time not in future");
        require(sale_time[boxId] == 0, "Box ID already assigned");

        generation[boxId] = generation_;
        quantity[boxId] = quantity_;
        sale_time[boxId] = sale_time_;
    }
}

// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

abstract contract AValidateMint is IValidateMint {
    uint256 public constant VALIDATE_STATUS__NA = 0;
    uint256 public constant VALIDATE_STATUS__PASS = 1;
    uint256 public constant VALIDATE_STATUS__FAIL = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOwnable_Variables {
    function owner() external view returns (address);
}

interface IOwnable_Functions {
    function transferOwnership(address newOwner) external;
}

interface IOwnable is IOwnable_Functions, IOwnable_Variables {}

// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import { IOwnable_Functions } from "./interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable_Functions {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        owner = owner_ == address(0) ? msg.sender : owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

import { IBoredBoxNFT } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

/// @title Outsourced source code for BoredBoxNFT operations
///
/// @dev Review official documentation
///   https://docs.soliditylang.org/en/v0.8.12/contracts.html#libraries
library LibraryBoredBoxNFT {
    uint256 public constant TOKEN_STATUS__CLOSED = 0;
    uint256 public constant TOKEN_STATUS__OPENED = 1;
    uint256 public constant TOKEN_STATUS__PENDING = 2;

    uint256 public constant VALIDATE_STATUS__NA = 0;
    uint256 public constant VALIDATE_STATUS__PASS = 1;
    uint256 public constant VALIDATE_STATUS__FAIL = 2;

    /// Emitted after assets are fully distributed
    // @param tokenId pointer into `token__owner`, `token__opened_timestamp`, `token__status`, `token__generation`
    event Opened(uint256 indexed tokenId);

    /// Emitted when client requests a Box to be opened
    // @param from address of `msg.sender`
    // @param to address of `token__owner[tokenId]`
    // @param tokenId pointer into storage; `token__owner`, `token__opened_timestamp`, `token__status`, `token__generation`
    event RequestOpen(address indexed from, address indexed to, uint256 indexed tokenId);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑    Custom events   ↑ */
    /* ↓  External setters  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Mutates `token__status` storage if checks pass
    /// @dev See {IBoredBoxNFT_Functions-open}
    function setPending(
        mapping(uint256 => uint256) storage token__status,
        address ref_box,
        uint256[] memory tokenIds
    ) external {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs provided");

        for (uint256 i; i < length; ) {
            _setPending(token__status, ref_box, tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function setOpened(
        mapping(uint256 => uint256) storage token__status,
        mapping(uint256 => uint256) storage token__opened_timestamp,
        address ref_box,
        uint256[] memory tokenIds
    ) external {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs provided");
        for (uint256 i; i < length; ) {
            _setOpened(token__status, token__opened_timestamp, ref_box, tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IBoredBoxNFT_Functions-setBoxURI}
    function setBoxURI(
        mapping(uint256 => string) storage box__uri_root,
        uint256 boxId,
        string memory uri_root
    ) external {
        require(boxId > 0, "Box does not exist");
        box__uri_root[boxId] = uri_root;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑   External setters  ↑ */
    /* ↓   External getters  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    ///
    function tokenURI(address ref_box, uint256 tokenId) external view returns (string memory) {
        require(tokenExists(ref_box, tokenId), "ERC721Metadata: URI query for nonexistent token");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);

        uint256 boxId = iBox.token__generation(tokenId);
        string memory uri_root = iBox.box__uri_root(boxId);
        require(bytes(uri_root).length > 0, "URI not set");

        uint256 token__status = iBox.token__status(tokenId);
        string memory uri_path;
        if (token__status == TOKEN_STATUS__CLOSED) {
            uri_path = "closed";
        } else if (token__status == TOKEN_STATUS__OPENED) {
            uri_path = "opened";
        } else if (token__status == TOKEN_STATUS__PENDING) {
            uri_path = "pending";
        }

        return string(abi.encodePacked("ipfs://", uri_root, "/", uri_path, ".json"));
    }

    /// Check if mint request is valid
    /// @param ref_box Address to BoredBoxNFT compatible contract
    /// @param to Address that will own new Box token
    /// @param boxId Box generation
    /// @param auth Optional set of bytes passed to relevant Validate contract(s)
    /// @return tokenId Number of next valid token ID to mint
    ///
    /// @dev Warning be careful to not create off-by-one errors between `box__quantity` and `tokenId`
    /// ## Example
    /// ```
    /// Assume                      quantity == 100
    ///              box__upper_bound[boxId] == 100
    ///                              tokenId == 1
    ///
    /// Assume                      quantity == 99
    ///              box__upper_bound[boxId] == 100
    ///                              tokenId == 2
    ///
    /// Assume                      quantity == 1
    ///              box__upper_bound[boxId] == 100
    ///                              tokenId == 100
    /// ```
    function validateMint(
        address ref_box,
        address to,
        uint256 boxId,
        bytes memory auth
    ) external returns (uint256 tokenId) {
        require(boxId > 0, "validateMint: boxId must be greater than zero");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);
        require(!iBox.all_paused() && !iBox.box__is_paused(boxId), "Minting is paused");

        uint256 quantity = iBox.box__quantity(boxId);
        require(quantity > 0, "No more for this round");
        tokenId = (iBox.box__upper_bound(boxId) + 1) - quantity;

        // Check for duplicate mint attempt
        uint256 token__original_owner = iBox.token__original_owner(boxId, to);
        require(
            token__original_owner < iBox.box__lower_bound(boxId) ||
                token__original_owner > iBox.box__upper_bound(boxId),
            "To address already owns a box of this generation"
        );

        bool all_validators_passed;
        uint256 validate_status;
        address[] memory _ref_validators = iBox.box__allValidators(boxId);
        uint256 length = _ref_validators.length;
        for (uint256 i; i < length; ) {
            if (_ref_validators[i] == address(0)) {
                all_validators_passed = false;
                break;
            }

            validate_status = IValidateMint(_ref_validators[i]).validate(to, boxId, tokenId, auth);
            unchecked {
                ++i;
            }

            if (validate_status == VALIDATE_STATUS__NA) {
                continue;
            } else if (validate_status == VALIDATE_STATUS__PASS) {
                all_validators_passed = true;
            } else if (validate_status == VALIDATE_STATUS__FAIL) {
                all_validators_passed = false;
                break;
            }
        }

        // WARNING: this is a "foot gun" if `ValidateMint` is coded bad!
        if (!all_validators_passed) {
            require(iBox.box__sale_time(boxId) <= block.timestamp, "Please wait till sale time");
        }

        return tokenId;
    }

    ///
    function validateTransfer(
        address ref_box,
        address from,
        address to,
        uint256 tokenId
    ) external view {
        if (from == address(0)) {
            // Minty fresh token
            return;
        }

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);

        uint256 token__status = iBox.token__status(tokenId);
        require(token__status != TOKEN_STATUS__PENDING, "Pending delivery");

        if (to == address(0)) {
            require(token__status == TOKEN_STATUS__OPENED, "Cannot burn un-opened Box");
            // Burninating the token
            // Burninating the peasants
            return;
        }

        if (token__status == TOKEN_STATUS__OPENED) {
            uint256 boxId = iBox.token__generation(tokenId);
            require(
                block.timestamp >= iBox.token__opened_timestamp(tokenId) + iBox.box__cool_down(boxId),
                "Need to let things cool down"
            );
        }
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  External getters  ↑ */
    /* ↓   Public getters   ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    ///
    function tokenExists(address ref_box, uint256 tokenId) public view returns (bool) {
        return IBoredBoxNFT(ref_box).token__owner(tokenId) != address(0);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Public getters   ↑ */
    /* ↓      internal     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Mutates `token__status` storage if checks pass
    /// @dev See {IBoredBoxNFT_Functions-open}
    function _setPending(
        mapping(uint256 => uint256) storage token__status,
        address ref_box,
        uint256 tokenId
    ) internal {
        require(tokenId > 0, "Invalid token ID");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);

        uint256 old__token__status = iBox.token__status(tokenId);
        if (old__token__status == TOKEN_STATUS__PENDING) {
            // Skip re-writing and repeated event emissions
            return;
        }
        // TODO: Validate `require` conditions with JavaScript based tests
        require(old__token__status != TOKEN_STATUS__OPENED, "Already opened");

        uint256 boxId = iBox.token__generation(tokenId);
        require(boxId > 0, "Box does not exist");
        require(block.timestamp >= iBox.box__open_time(boxId), "Not time yet");

        token__status[tokenId] = TOKEN_STATUS__PENDING;
        emit RequestOpen(msg.sender, iBox.token__owner(tokenId), tokenId);
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function _setOpened(
        mapping(uint256 => uint256) storage token__status,
        mapping(uint256 => uint256) storage token__opened_timestamp,
        address ref_box,
        uint256 tokenId
    ) internal {
        require(tokenId > 0, "Invalid token ID");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);
        require(iBox.token__generation(tokenId) > 0, "Box does not exist");

        require(iBox.token__status(tokenId) == TOKEN_STATUS__PENDING, "Not yet pending delivery");

        token__status[tokenId] = 1;
        token__opened_timestamp[tokenId] = block.timestamp;

        emit Opened(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// Completely optional contract that customizes mint requirements
interface IValidateMint {
    /// Throws `revert` or `require` error message to halt execution
    /// Returns 0 VALIDATE_STATUS__NA
    /// Returns 1 VALIDATE_STATUS__PASS
    /// Returns 2 VALIDATE_STATUS__FAIL
    /// It is up to caller to figure out what to do with returned `bool`
    /// @param to Address that will receive NFT if operation is valid
    /// @param boxId Generation key to possibly use internally or by checking calling contract strage
    /// @param tokenId Specific token ID that needs to be minted
    /// @param auth Optional extra data to require for validation process
    function validate(
        address to,
        uint256 boxId,
        uint256 tokenId,
        bytes memory auth
    ) external returns (uint256 validate_status);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IBoredBoxStorage } from "@boredbox-solidity-contracts/bored-box-storage/contracts/interfaces/IBoredBoxStorage.sol";
import { IOwnable } from "@boredbox-solidity-contracts/ownable/contracts/interfaces/IOwnable.sol";

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/* Function definitions */
interface IBoredBoxNFT_Functions is IERC721Metadata {
    /* From ERC721 */
    // function balanceOf(address owner) external view returns (uint256 balance);
    // function ownerOf(uint256 tokenId) external view returns (address);
    // function transferFrom(address from, address to, uint256 tokenId) external;

    // @dev See {IERC721Metadata-tokenURI}.
    // function tokenURI(uint256 tokenId) external view returns (string memory);

    /// Attempt to retrieve `name` from storage
    /// @return Name for given `boxId` generation
    function name() external view returns (string memory);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Attempt to mint new token for `current_box` generation
    /// @dev Sets `boxId` to `current_box` before passing execution to `_mintBox()` function
    /// @param to Address to set at `token__owner[tokenId]` storage
    /// @param auth Forwarded to any `ValidateMint` contract references set at `box__validators[boxId]`
    /// @custom:throw "Incorrect amount sent"
    function mint(
        address to,
        uint256 boxId,
        bytes memory auth
    ) external payable;

    /// Attempt to mint new token for `boxId` generation
    /// @param to Address to set at `token__owner[tokenId]` storage
    /// @param auth Forwarded to any `ValidateMint` contract references set at `box__validators[boxId]`
    /// @custom:throw "Incorrect amount sent"
    function mint(address to, bytes memory auth) external payable;

    /// Bulk request array of `tokenIds` to have assets delivered
    /// @dev See {IBoredBoxNFT_Functions-open}
    /// @custom:throw "No token IDs provided"
    /// @custom:throw "Not authorized" if `msg.sender` is not contract owner
    /// @custom:throw "Invalid token ID" if `tokenId` is not greater than `0`
    /// @custom:throw "Not time yet" if `block.timestamp` is less than `box__open_time[boxId]`
    /// @custom:throw "Already opened"
    /// @custom:throw "Pending delivery"
    /// @custom:throw "Box does not exist"
    function setPending(uint256[] memory tokenIds) external;

    /// Attempt to set `token__status` and `token__opened_timestamp` storage
    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    /// @custom:throw "No token IDs provided"
    /// @custom:throw "Not authorized"
    /// @custom:throw "Invalid token ID"
    /// @custom:throw "Box does not exist"
    /// @custom:throw "Not yet pending delivery"
    /// @custom:emit Opened
    /// @custom:emit PermanentURI
    function setOpened(uint256[] memory tokenIds) external;

    /// Set `box__uri_root` for given `tokenId` to `uri_root` value
    /// @custom:throw "Not authorized" if `msg.sender` is not contract owner
    /// @custom:throw "Box does not exist"
    function setBoxURI(uint256 boxId, string memory uri_root) external;

    /// Attempt to set `all__paused` storage
    /// @param is_paused Value to assign to storage
    /// @custom:throw "Not authorized"
    function setAllPaused(bool is_paused) external;

    /// Attempt to set `box__is_paused` storage
    /// @custom:throw "Not authorized"
    function setIsPaused(uint256 boxId, bool is_paused) external;

    function setCoordinator(address coordinator_) external;

    /// @param uri_root String pointing to IPFS directory of JSON metadata files
    /// @param quantity Amount of tokens available for first generation
    /// @param price Exact `{ value: _price_ }` required by `mint()` function
    /// @param sale_time The `block.timestamp` to allow general requests to `mint()` function
    /// @param open_time The `block.timestamp` to allow `open` requests
    /// @param ref_validators List of addresses referencing `ValidateMint` contracts
    /// @param cool_down Add time to `block.timestamp` to prevent `transferFrom` after opening
    /// @custom:throw "Not authorized"
    /// @custom:throw "New boxes are paused"
    /// @custom:throw "Open time must be after sale time"
    function newBox(
        string memory uri_root,
        uint256 quantity,
        uint256 price,
        uint256 sale_time,
        uint256 open_time,
        address[] memory ref_validators,
        uint256 cool_down
    ) external;

    /// Helper function to return Array of all validation contract addresses for `boxId`
    /// @param boxId Generation key to get array from `box__validators` storage
    function box__allValidators(uint256 boxId) external view returns (address[] memory);

    /// Send amount of Ether from `this.balance` to some address
    /// @custom:throw "Ownable: caller is not the owner"
    /// @custom:throw "Transfer failed"
    function withdraw(address payable to, uint256 amount) external;
}

///
interface IBoredBoxNFT is IBoredBoxNFT_Functions, IBoredBoxStorage, IOwnable {
    // /* Function definitions from @openzeppelin/contracts/access/Ownable.sol */
    // function owner() external view returns (address);

    // function transferOwnership(address newOwner) external;

    /* Variable getters from contracts/tokens/ERC721/ERC721.sol */
    function token__owner(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

/* Variable getters */
interface IBoredBoxStorage {
    function current_box() external view returns (uint256);

    function coordinator() external view returns (address);

    function all_paused() external view returns (bool);

    /// Get paused state for given `boxId`
    function box__is_paused(uint256) external view returns (bool);

    /// Get latest URI root/hash for given `boxId`
    function box__uri_root(uint256) external view returns (string memory);

    /// Get first token ID allowed to be minted for given `boxId`
    function box__lower_bound(uint256) external view returns (uint256);

    /// Get last token ID allowed to be minted for given `boxId`
    function box__upper_bound(uint256) external view returns (uint256);

    /// Get remaining quantity of tokens for given `boxId`
    function box__quantity(uint256) external view returns (uint256);

    /// Get price for given `boxId`
    function box__price(uint256) external view returns (uint256);

    /// Get address to Validate contract for given `boxId` and array index
    function box__validators(uint256, uint256) external view returns (address);

    /// Get `block.timestamp` given `boxId` generation allows tokens to be sold
    function box__sale_time(uint256) external view returns (uint256);

    /// Get `block.timestamp` given `boxId` generation allows tokens to be opened
    function box__open_time(uint256) external view returns (uint256);

    /// Get amount of time added to `block.timestamp` for `boxId` when token is opened
    function box__cool_down(uint256) external view returns (uint256);

    /// Get `block.timestamp` a given `tokenId` was opened
    function token__opened_timestamp(uint256) external view returns (uint256);

    /// Get _TokenStatus_ value for given `tokenId`
    function token__status(uint256) external view returns (uint256);

    /// Get `boxId` for given `tokenId`
    function token__generation(uint256) external view returns (uint256);

    ///
    function token__original_owner(uint256, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

/// Define additional data storage for BoredBoxNFT
abstract contract BoredBoxStorage {
    uint256 public constant TOKEN_STATUS__CLOSED = 0;
    uint256 public constant TOKEN_STATUS__OPENED = 1;
    uint256 public constant TOKEN_STATUS__PENDING = 2;

    // TODO: rename to something like `box__current_generation`
    uint256 public current_box;

    // Authorized to preform certain actions
    address public coordinator;

    bool public all_paused;

    // Mapping boxId to is paused state
    mapping(uint256 => bool) public box__is_paused;

    // Mapping boxId to URI IPFS root
    mapping(uint256 => string) public box__uri_root;

    // Mapping boxId to tokenId bounds
    mapping(uint256 => uint256) public box__lower_bound;
    mapping(uint256 => uint256) public box__upper_bound;

    // Mapping boxId to quantity
    mapping(uint256 => uint256) public box__quantity;

    // Mapping boxId to price
    mapping(uint256 => uint256) public box__price;

    // Mapping boxId to array of Validate contract references
    mapping(uint256 => address[]) public box__validators;

    // Mapping boxId to open sale
    mapping(uint256 => uint256) public box__sale_time;

    // Mapping boxId to open time
    mapping(uint256 => uint256) public box__open_time;

    // Mapping boxId to cool down after mint
    mapping(uint256 => uint256) public box__cool_down;

    // Mapping tokenId to opened timestamp
    mapping(uint256 => uint256) public token__opened_timestamp;

    // Mapping from tokenId to TokenStatus_{Closed,Opened,Pending} states
    mapping(uint256 => uint256) public token__status;

    // Mapping boxId to owner to tokenId
    mapping(uint256 => mapping(address => uint256)) public token__original_owner;

    // Mapping from tokenId to boxId
    mapping(uint256 => uint256) public token__generation;
}