pragma solidity ^0.8.0;

import {TokenLogic} from "../TokenLogic.sol";
import {TransferData, TokenStandard} from "../../IToken.sol";
import {ExtendableHooks} from "../../extension/ExtendableHooks.sol";
import {ERC20Upgradeable} from "@gnus.ai/contracts-upgradeable-diamond/token/ERC20/ERC20Upgradeable.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";
import {ERC20TokenInterface} from "../../registry/ERC20TokenInterface.sol";

/**
* @title Extendable ERC20 Logic with Diamond Storage
* @notice An ERC20 logic contract that implements the IERC20 interface. This contract
* can be deployed as-is.
*
* The logic contract is not responsible for the logic required for name() and symbol() (The proxy
* contract handles this). This means that no constructor arguments are required for deployment.
*
*
* @dev This logic contract inherits from OpenZeppelin's ERC20Upgradeable, TokenLogic and ERC20TokenInterface.
* This meaning it supports the full ERC20 spec along with any OpenZeppelin (or other 3rd party) contract extensions.
* You may inherit from this logic contract to add additional functionality.
*
* Any additional functions added to the logic contract through a child contract that is not explictly declared in the
* proxy contract may be overriden by registered & enabled extensions. To prevent this, explictly declare the new function
* in the proxy contract and forward the call using delegated function modifier
*
* All transfer events (including minting/burning) trigger a transfer event to all registered
* and enabled extensions. By default, no data (or operatorData) is passed to extensions. The
* functions transferWithData and transferFromWithData allow a caller to pass data to extensions during
* these transfer events. This is done through the {ExtendableHooks._triggerTokenTransfer} function inside
* the {ERC20Logic._afterTokenTransfer} function. The _afterTokenTransfer function was chosen to follow
* the checks, effects and interactions pattern
*/
contract ERC20Logic is ERC20TokenInterface, TokenLogic, ERC20Upgradeable {
    using BytesLib for bytes;

    /**
    * @dev The storage slot that will be used to store the ProtectedTokenData struct inside
    * this TokenProxy
    */
    bytes32 constant ERC20_PROTECTED_TOKEN_DATA_SLOT = bytes32(uint256(keccak256("consensys.contracts.token.erc20.metadata")) - 1);

    /**
    * @notice Protected ERC20 token metadata stored in the proxy storage in a special storage slot.
    * Includes thing such as name, symbol and deployment options.
    * @dev This struct should only be written to inside the constructor and should be treated as readonly.
    * Solidity 0.8.7 does not have anything for marking storage slots as read-only, so we'll just use
    * the honor system for now.
    * @param initialized Whether this proxy is initialized
    * @param name The name of this ERC20 token
    * @param symbol The symbol of this ERC20 token
    * @param maxSupply The max supply of token allowed
    * @param allowMint Whether minting is allowed
    * @param allowBurn Whether burning is allowed
    */
    struct ProtectedTokenData {
        bool initialized;
        string name;
        string symbol;
        uint256 maxSupply;
        bool allowMint;
        bool allowBurn;
    }

    /**
     * @dev Get the ProtectedTokenData struct stored in this contract
     */
    function _getProtectedTokenData() internal pure returns (ProtectedTokenData storage r) {
        bytes32 slot = ERC20_PROTECTED_TOKEN_DATA_SLOT;
        assembly {
            r.slot := slot
        }
    }

    /**
    * @dev We don't need to do anything here
    */
    function _onInitialize(bytes memory) internal virtual override returns (bool) {
        return true;
    }

    /**
    * @dev This function is invoked directly before each token transfer. This is overriden here
    * so we can invoke the transfer event on all registered & enabled extensions. We do this
    * by building a TransferData object and invoking _triggerBeforeTokenTransfer
    * @param from The sender of this token transfer
    * @param to The recipient of this token transfer
    * @param amount How many tokens were transferred
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        TransferCallData storage tcd = _transferCallData();
        
        address operator = _msgSender();
        if (tcd._currentOperator != address(0)) {
            operator = tcd._currentOperator;
        }

        TransferData memory data = TransferData(
            address(this),
            _msgData(),
            0x00000000000000000000000000000000,
            operator,
            from,
            to,
            amount,
            0,
            tcd._currentData,
            tcd._currentOperatorData
        );

        _triggerTokenBeforeTransferEvent(data);
    }

    /**
    * @dev This function is invoked directly after each token transfer. This is overriden here
    * so we can invoke the transfer event on all registered & enabled extensions. We do this
    * by building a TransferData object and invoking _triggerTokenTransfer
    * @param from The sender of this token transfer
    * @param to The recipient of this token transfer
    * @param amount How many tokens were transferred
    */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        TransferCallData storage tcd = _transferCallData();
        
        address operator = _msgSender();
        if (tcd._currentOperator != address(0)) {
            operator = tcd._currentOperator;
        }

        TransferData memory data = TransferData(
            address(this),
            _msgData(),
            0x00000000000000000000000000000000,
            operator,
            from,
            to,
            amount,
            0,
            tcd._currentData,
            tcd._currentOperatorData
        );

        _resetTransferCallData();

        _triggerTokenTransferEvent(data);
    }

    /**
    * @dev Mints `amount` tokens and sends to `to` address.
    * Only an address with the Minter role can invoke this function
    * @param to The recipient of the minted tokens
    * @param amount The amount of tokens to be minted
    */
    function mint(address to, uint256 amount) external virtual onlyMinter returns (bool) {
        _mint(to, amount);
        require(totalSupply() <= _getProtectedTokenData().maxSupply, "Max supply has been exceeded");
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
    

    /**
    * @dev Executes a controlled transfer where the sender is `td.from` and the recipeint is `td.to`.
    * Only token controllers can use this funciton
    * @param td The TransferData containing the kind of transfer to perform
    */
    function tokenTransfer(TransferData calldata td) external virtual override onlyControllers returns (bool) {
        require(td.partition == bytes32(0), "Invalid transfer data: partition");
        require(td.token == address(this), "Invalid transfer data: token");
        require(td.tokenId == 0, "Invalid transfer data: tokenId");

        TransferCallData storage tcd = _transferCallData();
        tcd._currentData = td.data;
        tcd._currentOperatorData = td.operatorData;
        tcd._currentOperator = td.operator;
        _transfer(td.from, td.to, td.value);

        return true;
    }

    /**
    * @dev This will always return {TokenStandard.ERC20}
    */
    function tokenStandard() external pure override returns (TokenStandard) {
        return TokenStandard.ERC20;
    }

    // Override normal transfer functions
    // That way we can grab any extra data
    // that may be attached to the calldata
    uint256 private constant APPROVE_CALL_SIZE = 4 + 32 + 32;
    uint256 private constant TRANSFER_CALL_SIZE = 4 + 32 + 32;
    uint256 private constant TRANSFER_FROM_CALL_SIZE = 4 + 32 + 32 + 32;
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * @param recipient The recipient of the transfer
     * @param amount The amount of tokens to transfer
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        bytes memory extraData = _extractExtraCalldata(TRANSFER_CALL_SIZE);

        TransferCallData storage tcd = _transferCallData();
        tcd._currentData = extraData;
        tcd._currentOperatorData = extraData;

        return ERC20Upgradeable.transfer(recipient, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     * @param sender The sender of tokens
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens to transfer
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        bytes memory extraData = _extractExtraCalldata(TRANSFER_FROM_CALL_SIZE);

        TransferCallData storage tcd = _transferCallData();
        tcd._currentData = extraData;
        tcd._currentOperatorData = extraData;

        return ERC20Upgradeable.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        super.approve(spender, amount);

        bytes memory extraData = _extractExtraCalldata(TRANSFER_CALL_SIZE);

        TransferData memory data = TransferData(
            address(this),
            _msgData(),
            0x00000000000000000000000000000000,
            _msgSender(),
            _msgSender(),
            spender,
            amount,
            0,
            extraData,
            extraData
        );
        _triggerTokenApprovalEvent(data);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        super.increaseAllowance(spender, addedValue);
        uint256 amount = super.allowance(_msgSender(), spender) + addedValue;

        bytes memory extraData = _extractExtraCalldata(TRANSFER_CALL_SIZE);

        TransferData memory data = TransferData(
            address(this),
            _msgData(),
            0x00000000000000000000000000000000,
            _msgSender(),
            _msgSender(),
            spender,
            amount,
            0,
            extraData,
            extraData
        );
        _triggerTokenApprovalEvent(data);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        super.decreaseAllowance(spender, subtractedValue);
        uint256 amount = super.allowance(_msgSender(), spender) - subtractedValue;

        bytes memory extraData = _extractExtraCalldata(TRANSFER_CALL_SIZE);

        TransferData memory data = TransferData(
            address(this),
            _msgData(),
            0x00000000000000000000000000000000,
            _msgSender(),
            _msgSender(),
            spender,
            amount,
            0,
            extraData,
            extraData
        );
        _triggerTokenApprovalEvent(data);

        return true;
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

pragma solidity ^0.8.0;

import {TokenERC1820Provider} from "../TokenERC1820Provider.sol";

/**
* @title ERC1820 Provider for ERC20
* @notice This should be inherited by the token proxy & token logic contracts
* @dev A base contract that inherits from TokenERC1820Provider and implements
* the interface name functions for ERC20
*/
abstract contract ERC20TokenInterface is TokenERC1820Provider {
    string constant internal ERC20_INTERFACE_NAME = "ERC20Token";
    string constant internal ERC20_LOGIC_INTERFACE_NAME = "ERC20TokenLogic";

    /**
    * @dev The interface name for the token logic contract to be used in ERC1820.
    * @return string ERC20TokenLogic
    */
    function __tokenLogicInterfaceName() internal pure override returns (string memory) {
        return ERC20_LOGIC_INTERFACE_NAME;
    }

    /**
    * @dev The interface name for the token logic contract to be used in ERC1820.
    * @return string ERC20Token
    */
    function __tokenInterfaceName() internal virtual override pure returns (string memory) {
        return ERC20_INTERFACE_NAME;
    }
}

pragma solidity ^0.8.0;

import {ITokenLogic} from "./ITokenLogic.sol";
import {TokenRoles} from "../../roles/TokenRoles.sol";
import {ExtendableHooks} from "../extension/ExtendableHooks.sol";
import {ERC1820Client} from "../../erc1820/ERC1820Client.sol";
import {ERC1820Implementer} from "../../erc1820/ERC1820Implementer.sol";
import {TokenERC1820Provider} from "../TokenERC1820Provider.sol";
import {StorageSlotUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/utils/StorageSlotUpgradeable.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

/**
* @title Base Token Logic Contract
* @notice This should be inherited by the token logic contract
* @dev An abstract contract to be inherited by a token logic contract. This contract
* inherits from TokenERC1820Provider, TokenRoles and ExtendableHooks. It is recommended
* that a token logic contract inherit from a TokenERC1820Provider contract or implement those functions.
*
* This contract uses the TokenERC1820Provider to automatically register the required token logic
* interface name to the ERC1820 registry. This is used by the token proxy contract to lookup the current
* token logic address.
*
* The child contract should override _onInitialize to determine how the logic contract should initalize
* when it's attached to a proxy. This occurs during deployment and during upgrading.
*/
abstract contract TokenLogic is TokenERC1820Provider, TokenRoles, ExtendableHooks, ITokenLogic {
    using BytesLib for bytes;

        
    struct TransferCallData {
        address _currentOperator;
        bytes _currentData;
        bytes _currentOperatorData;
    }

    bytes32 private constant TRANSFER_CALLDATA_SLOT = keccak256("consensys.contracts.token.storage.logic.upgrading");

    bytes32 private constant UPGRADING_FLAG_SLOT = keccak256("consensys.contracts.token.storage.logic.upgrading");

    /**
    * @dev Register token logic interfaces to the ERC1820 registry. These
    * interface names are provided by TokenERC1820Provider implementing contract.
    */
    constructor() {
        ERC1820Client.setInterfaceImplementation(__tokenLogicInterfaceName(), address(this));
        ERC1820Implementer._setInterface(__tokenLogicInterfaceName()); // For migration
    }

    function caller() external override view returns (address) {
        return msg.sender;
    }

    function _resetTransferCallData() internal {
        TransferCallData storage r = _transferCallData();
        r._currentOperator = address(0);
        r._currentData = "";
        r._currentOperatorData = "";
    }

    function _transferCallData() internal pure returns (TransferCallData storage r) {
        bytes32 slot = TRANSFER_CALLDATA_SLOT;
        assembly {
            r.slot := slot
        }
    }

    function _extractExtraCalldata(uint256 normalCallsize) internal view returns (bytes memory) {
        bytes memory cdata = _msgData();

        if (cdata.length > normalCallsize) {
            //Start the slice from where the normal 
            //parameter arguments should end
            uint256 start = normalCallsize;

            //The size of the slice will be the difference
            //in expected size to actual size
            uint256 size = cdata.length - normalCallsize;
 
            bytes memory extraData = cdata.slice(start, size);

            return extraData;
        }
        return bytes("");
    }

    /**
    * @notice This cannot be invoked directly. It must be invoked by a TokenProxy inside of upgradeTo or 
    * in the consturctor.
    * 
    * @dev This function can only be invoked if the uint256 value in the UPGRADING_FLAG_SLOT storage slot
    * is non-zero and matches the length of the data provided
    *
    * @param data The data to initalize with
    */
    function initialize(bytes memory data) external override {
        uint256 upgradeChallengeCheck = StorageSlotUpgradeable.getUint256Slot(UPGRADING_FLAG_SLOT).value;
        require(upgradeChallengeCheck != 0 && upgradeChallengeCheck == data.length, "The contract is not upgrading or was invoked incorrectly");

        require(_onInitialize(data), "Initialize failed");
    }

    /**
    * @dev To be implemented by the child logic contract. This function is invoked when the logic
    * contract is attached to the proxy, either through the constructor or when upgrading. When
    * attached during deployment, the data length will be the encoded constructor arguments inside
    * TokenProxy. When attached inside upgradeTo, the data passed along with the upgradeTo call will
    * be passed here.
    *
    * @param data The data to initalize with
    */
    function _onInitialize(bytes memory data) internal virtual returns (bool);
}

pragma solidity ^0.8.0;

import {IToken} from "../IToken.sol";

/**
* @title Token Logic Interface
* @dev An interface that all Token Logic contracts should implement
*/
interface ITokenLogic is IToken {
    function initialize(bytes memory data) external;

    function caller() external view returns (address);
}

pragma solidity ^0.8.0;


abstract contract TokenEventManagerStorage {
    bytes32 constant EVENT_MANAGER_DATA_SLOT = keccak256("consensys.contracts.token.eventmanager.data");
    
    struct ExtensionListeningCache {
        bool listening;
        uint256 listenIndex;
    }

    struct SavedCallbackFunction {
        address callbackAddress;
        bytes4 callbackSelector;
    }

    struct EventManagerData {
        uint256 eventFiringStack;
        mapping(address => bytes32[]) eventListForExtensions;
        mapping(address => mapping(bytes32 => ExtensionListeningCache)) listeningCache;
        mapping(bytes32 => SavedCallbackFunction[]) listeners;
        mapping(bytes32 => bool) isFiring;
    }

    function eventManagerData() internal pure returns (EventManagerData storage ds) {
        bytes32 position = EVENT_MANAGER_DATA_SLOT;
        assembly {
            ds.slot := position
        }
    }
}

pragma solidity ^0.8.0;

import {TransferData} from "../../interface/IExtension.sol";
import {ExtensionRegistrationStorage} from "./ExtensionRegistrationStorage.sol";
import {TokenEventManagerStorage} from "./TokenEventManagerStorage.sol";

/**
* @title Token Event Manager
* @notice A contract implementation of an on-chain event manager specifically
* for the TransferData data structure.
* @dev This is extended by TokenExtension and TokenLogic to both trigger and listen
* to events with a given event id. To listen for an event id, use the _on(eventId, callback) 
* or external on(eventId, callback) functions. The eventId parameter is a bytes32, the
* callback parameter is the type function (TransferData memory) external returns (bool).
*
* To trigger an event, use the internal _trigger(eventId, eventData) function. The eventId
* parameter is a bytes32 and should match what is passed to eventId for in on/_on function.
* The eventData is type TransferData and is passed to each callback invoked.
* Currently, only enabled registered extensions are invoked if they listen for a 
* given eventId. If the extension listens for an eventId but is disabled, it is
* not triggered.
* 
* TODO To make this contract generic in the future when Solidity eventually supports
* generic types, simply replace TransferData with type T and replace the callback
* type with function (T memory) external returns (bool)
*/
abstract contract TokenEventManager is TokenEventManagerStorage, ExtensionRegistrationStorage {
    
    function _extensionState(address ext) internal view returns (ExtensionState) {
        return _addressToExtensionData(ext).state;
    }

    function _trigger(bytes32 eventId, TransferData memory data) internal {
        EventManagerData storage emd = eventManagerData();

        SavedCallbackFunction[] storage callbacks = emd.listeners[eventId];
        
        require(!emd.isFiring[eventId], "Recursive trigger not allowed");
        
        emd.eventFiringStack++;
        emd.isFiring[eventId] = true;


        for (uint i = 0; i < callbacks.length; i++) {
            bytes4 listenerFuncSelector = callbacks[i].callbackSelector;
            address listenerAddress = callbacks[i].callbackAddress;

            if (_extensionState(listenerAddress) == ExtensionState.EXTENSION_DISABLED) {
                continue; //Skip disabled extensions
            }

            bytes memory cdata = abi.encodePacked(abi.encodeWithSelector(listenerFuncSelector, data), listenerAddress);

            (bool success, bytes memory result) = listenerAddress.delegatecall{gas: gasleft()}(cdata);

            require(success, string(result));
        }

        emd.isFiring[eventId] = false;
        emd.eventFiringStack--;
    }
}

pragma solidity ^0.8.0;

abstract contract TokenEventConstants {
    /**
    * @dev The event hash for a token transfer event to be used by the ExtendableEventManager
    * and any extensions wanting to listen to the event
    */
    bytes32 constant TOKEN_TRANSFER_EVENT = keccak256("consensys.contracts.token.events.transfer");

    /**
    * @dev The event hash for a token transfer event to be used by the ExtendableEventManager
    * and any extensions wanting to listen to the event
    */
    bytes32 constant TOKEN_BEFORE_TRANSFER_EVENT = keccak256("consensys.contracts.token.events.before.transfer");

    /**
    * @dev The event hash for a token approval event to be used by the ExtendableEventManager
    * and any extensions wanting to listen to the event
    */
    bytes32 constant TOKEN_APPROVE_EVENT = keccak256("consensys.contracts.token.events.approve");
}

/**
* @title Extension Registration Storage
* @notice Internal functions and definations to access extension registration on the current
* token
* @dev This contract should be inherited from any other contract (include extensions/facets) that
* wish to access the extensions registered. For the sake of contract size, this is intentionally left
* very minimal.
*/
abstract contract ExtensionRegistrationStorage {
    /**
    * @dev The storage slot that will hold the MappedExtensions struct
    */
    bytes32 constant MAPPED_EXTENSION_STORAGE_SLOT = keccak256("consensys.contracts.token.storage.ext.registration.data");

    /**
    * @dev A state of all possible registered extension states
    * A registered extension can either not exist, be enabled or disabled
    */
    enum ExtensionState {
        EXTENSION_NOT_EXISTS,
        EXTENSION_ENABLED,
        EXTENSION_DISABLED
    }

    /**
    * @dev Registered extension data
    * @param state The current state of this registered extension
    * @param index The current index of this registered extension in registeredExtensions array
    * @param executeContext The current address this extension will be executed in
    */
    struct ExtensionData {
        ExtensionState state;
        uint256 index;
        address executeContext;
        bytes4[] externalFunctions;
    }

    /**
    * @dev All Registered extensions + additional mappings for easy lookup
    * @param registeredExtensions An array of all registered extensions, both enabled and disabled extensions
    * @param funcToExtension A mapping of function selector to global extension address
    * @param extensions A mapping of global extension address to ExtensionData
    */
    struct MappedExtensions {
        address[] registeredExtensions;
        mapping(bytes4 => address) funcToExtension;
        mapping(address => ExtensionData) extensions;
    }

    /**
    * @dev Get the MappedExtensions data stored inside this contract.
    * @return ds The MappedExtensions struct stored in this contract
    */
    function _extensionStorage() internal pure returns (MappedExtensions storage ds) {
        bytes32 position = MAPPED_EXTENSION_STORAGE_SLOT;
        assembly {
            ds.slot := position
        }
    }

    /**
    * @dev Obtain data about an extension address in the form of the ExtensionData struct.
    * @param extension The extension address to lookup
    * @return ExtensionData Data about the extension in the form of the ExtensionData struct
    */
    function _addressToExtensionData(address extension) internal view returns (ExtensionData memory) {
        MappedExtensions storage extLibStorage = _extensionStorage();
        return extLibStorage.extensions[extension];
    }
}

pragma solidity ^0.8.0;

import {TokenEventManager} from "./TokenEventManager.sol";
import {TokenEventConstants} from "./TokenEventConstants.sol";
import {TransferData} from "../../interface/IExtension.sol";

/**
* @title Transfer Hooks for Extensions
* @notice This should be inherited by a token logic contract
* @dev ExtendableHooks provides the _triggerTokenTransferEvent and _triggerTokenApproveEvent internal
* function that can be used to notify extensions when a transfer/approval occurs.
*/
abstract contract ExtendableHooks is TokenEventManager, TokenEventConstants {

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * @param data The transfer data to that represents this transfer to send to extensions.
     */
    function _triggerTokenBeforeTransferEvent(TransferData memory data) internal virtual {
        _trigger(TOKEN_BEFORE_TRANSFER_EVENT, data);
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * @param data The transfer data to that represents this transfer to send to extensions.
     */
    function _triggerTokenTransferEvent(TransferData memory data) internal virtual {
        _trigger(TOKEN_TRANSFER_EVENT, data);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * @param data The transfer data to that represents this transfer to send to extensions.
     */
    function _triggerTokenApprovalEvent(TransferData memory data) internal virtual {
        _trigger(TOKEN_APPROVE_EVENT, data);
    }
}

pragma solidity ^0.8.0;

import {ERC1820Client} from "../erc1820/ERC1820Client.sol";
import {ERC1820Implementer} from "../erc1820/ERC1820Implementer.sol";

/**
* @title ERC1820 Provider for Tokens
* @notice This is an abstract contract, you may want to inherit from
* the contracts in the registry folder
* @dev A base contract that provides ERC1820 functionality and also
* provides pure functions to obtain the interface name for both the
* current token logic contract and the current token contract
*/
abstract contract TokenERC1820Provider is ERC1820Implementer, ERC1820Client {
    /**
    * @dev The interface name for the token logic contract to be used in ERC1820.
    */
    function __tokenLogicInterfaceName() internal virtual pure returns (string memory);

    /**
    * @dev The interface name for the token contract to be used in ERC1820
    */
    function __tokenInterfaceName() internal virtual pure returns (string memory);
}

pragma solidity ^0.8.0;

/**
* @dev A struct containing information about the current token transfer.
* @param token Token address that is executing this extension.
* @param payload The full payload of the initial transaction.
* @param partition Name of the partition (left empty for ERC20 transfer).
* @param operator Address which triggered the balance decrease (through transfer or redemption).
* @param from Token holder.
* @param to Token recipient for a transfer and 0x for a redemption.
* @param value Number of tokens the token holder balance is decreased by.
* @param data Extra information (if any).
* @param operatorData Extra information, attached by the operator (if any).
*/
struct TransferData {
    address token;
    bytes payload;
    bytes32 partition;
    address operator;
    address from;
    address to;
    uint256 value;
    uint256 tokenId;
    bytes data;
    bytes operatorData;
}

/**
* @notice An enum of different token standards by name
*/
enum TokenStandard {
    ERC20,
    ERC721,
    ERC1400,
    ERC1155
}

/**
* @title Token Interface
* @dev A standard interface all token standards must inherit from. Provides token standard agnostic 
* functions
*/
interface IToken {
    /**
    * @notice Perform a transfer given a TransferData struct. Only addresses with the token controllers 
    * role should be able to invoke this function.
    * @return bool If this contract does not support the transfer requested, it should return false. 
    * If the contract does support the transfer but the transfer is impossible, it should revert. 
    * If the contract does support the transfer and successfully performs the transfer, it should return true
    */
    function tokenTransfer(TransferData calldata transfer) external returns (bool);

    /**
    * @notice A function to determine what token standard this token implements. This
    * is a pure function, meaning the value should not change
    * @return TokenStandard The token standard this token implements
    */
    function tokenStandard() external pure returns (TokenStandard);
}

pragma solidity ^0.8.0;

abstract contract TokenRolesConstants {
    /**
    * @dev The storage slot for the burn/burnFrom toggle
    */
    bytes32 constant TOKEN_ALLOW_BURN = keccak256("consensys.contracts.token.storage.core.burn");
    /**
    * @dev The storage slot for the mint toggle
    */
    bytes32 constant TOKEN_ALLOW_MINT = keccak256("consensys.contracts.token.storage.core.mint");
    /**
    * @dev The storage slot that holds the current Owner address
    */
    bytes32 constant TOKEN_OWNER = keccak256("consensys.contracts.token.storage.core.owner");
    /**
    * @dev The access control role ID for the Minter role
    */
    bytes32 constant TOKEN_MINTER_ROLE = keccak256("consensys.contracts.token.storage.core.mint.role");
    /**
    * @dev The storage slot that holds the current Manager address
    */
    bytes32 constant TOKEN_MANAGER_ADDRESS = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    /**
    * @dev The access control role ID for the Controller role
    */
    bytes32 constant TOKEN_CONTROLLER_ROLE = keccak256("consensys.contracts.token.storage.controller.address");
}

pragma solidity ^0.8.0;

import {TokenRolesConstants} from "./TokenRolesConstants.sol";
import {ContextUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/utils/ContextUpgradeable.sol";
import {StorageSlotUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/utils/StorageSlotUpgradeable.sol";
import {RolesBase} from "./RolesBase.sol";
import {ITokenRoles} from "../interface/ITokenRoles.sol";

/**
* @title Token Roles
* @notice A base contract for handling token roles. 
* @dev This contract is responsible for the storage and API of access control
* roles that all tokens should implement. This includes the following roles
*  * Owner
*     - A single owner address of the token, as implemented as Ownerable
*  * Minter
      - The access control role that allows an address to mint tokens
*  * Manager
*     - The single manager address of the token, can manage extensions
*  * Controller
*     - The access control role that allows an address to perform controlled-transfers
* 
* This contract also handles the storage of the burning/minting toggling.
*/
abstract contract TokenRoles is TokenRolesConstants, RolesBase, ContextUpgradeable, ITokenRoles {

    /**
    * @notice This event is triggered when transferOwnership is invoked
    * @param previousOwner The previous owner before the transfer
    * @param newOwner The new owner of the token
    */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
    * @notice This event is triggered when the manager address is updated. This
    * can occur when transferOwnership is invoked or when changeManager is invoked.
    * This event name is taken from EIP1967
    * @param previousAdmin The previous manager before the update
    * @param newAdmin The new manager of the token
    */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
    * @dev A function modifier that will only allow the current token manager to
    * invoke the function
    */
    modifier onlyManager {
        require(_msgSender() == manager(), "This function can only be invoked by the manager");
        _;
    }

    /**
    * @dev A function modifier that will only allow addresses with the Minter role granted
    * to invoke the function
    */
    modifier onlyMinter {
        require(isMinter(_msgSender()), "This function can only be invoked by a minter");
        _;
    }

    /**
    * @dev A function modifier that will only allow addresses with the Controller role granted
    * to invoke the function
    */
    modifier onlyControllers {
        require(isController(_msgSender()), "This function can only be invoked by a controller");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @notice Returns the current token manager
    */
    function manager() public override view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(TOKEN_MANAGER_ADDRESS).value;
    }

    /**
    * @notice Returns true if `caller` has the Controller role granted
    */
    function isController(address caller) public override view returns (bool) {
        return hasRole(caller, TOKEN_CONTROLLER_ROLE);
    }

    /**
    * @notice Returns true if `caller` has the Minter role granted
    */
    function isMinter(address caller) public override view returns (bool) {
        return hasRole(caller, TOKEN_MINTER_ROLE);
    }

    /**
    * @notice Grant the Controller role to `caller`. Only addresses with
    * the Controller role granted may invoke this function
    * @param caller The address to grant the Controller role to
    */
    function addController(address caller) public override onlyControllers {
        _addRole(caller, TOKEN_CONTROLLER_ROLE);
    }

    /**
    * @notice Remove the Controller role from `caller`. Only addresses with
    * the Controller role granted may invoke this function
    * @param caller The address to remove the Controller role from
    */
    function removeController(address caller) public override onlyControllers {
        _removeRole(caller, TOKEN_CONTROLLER_ROLE);
    }

    /**
    * @notice Grant the Minter role to `caller`. Only addresses with
    * the Minter role granted may invoke this function
    * @param caller The address to grant the Minter role to
    */
    function addMinter(address caller) public override onlyMinter {
        _addRole(caller, TOKEN_MINTER_ROLE);
    }

    /**
    * @notice Remove the Minter role from `caller`. Only addresses with
    * the Minter role granted may invoke this function
    * @param caller The address to remove the Minter role from
    */
    function removeMinter(address caller) public override onlyMinter {
        _removeRole(caller, TOKEN_MINTER_ROLE);
    }

    /**
    * @notice Change the current token manager. Only the current token manager
    * can set a new token manager.
    * @dev This function is also invoked if transferOwnership is invoked
    * when the current token owner is also the current manager. 
    */
    function changeManager(address newManager) public override onlyManager {
        _changeManager(newManager);
    }

    function _changeManager(address newManager) private {
        address oldManager = manager();
        StorageSlotUpgradeable.getAddressSlot(TOKEN_MANAGER_ADDRESS).value = newManager;
        
        emit AdminChanged(oldManager, newManager);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public override view virtual returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(TOKEN_OWNER).value;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public override virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * If the current owner is also the current manager, then the manager address
     * is also updated to be the new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public override virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * If the current owner is also the current manager, then the manager address
     * is also updated to be the new owner
     * @param newOwner The address of the new owner
     */
    function _setOwner(address newOwner) private {
        address oldOwner = owner();
        StorageSlotUpgradeable.getAddressSlot(TOKEN_OWNER).value = newOwner;
        if (oldOwner == manager()) {
            _changeManager(newOwner);
        }
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

import {Roles} from "./Roles.sol";

abstract contract RolesBase {
    using Roles for Roles.Role;

    event RoleAdded(address indexed caller, bytes32 indexed roleId);
    event RoleRemoved(address indexed caller, bytes32 indexed roleId);
    
    function hasRole(address caller, bytes32 roleId) public view returns (bool) {
        return Roles.roleStorage(roleId).has(caller);
    }

    function _addRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).add(caller);

        emit RoleAdded(caller, roleId);
    }

    function _removeRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).remove(caller);

        emit RoleRemoved(caller, roleId);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function roleStorage(bytes32 _rolePosition) internal pure returns (Role storage ds) {
        bytes32 position = _rolePosition;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.8.0;

interface ITokenRoles {
    function manager() external view returns (address);

    function isController(address caller) external view returns (bool);

    function isMinter(address caller) external view returns (bool);

    function addController(address caller) external;

    function removeController(address caller) external;

    function addMinter(address caller) external;

    function removeMinter(address caller) external;

    function changeManager(address newManager) external;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;

import {TokenStandard} from "../tokens/IToken.sol";

/**
* @title Extension Metadata Interface
* @dev An interface that extensions must implement that provides additional
* metadata about the extension. 
*/
interface IExtensionMetadata {
    /**
    * @notice An array of function signatures this extension adds when
    * registered when a TokenProxy
    * @dev This function is used by the TokenProxy to determine what
    * function selectors to add to the TokenProxy
    */
    function externalFunctions() external view returns (bytes4[] memory);
    
    /**
    * @notice An array of role IDs that this extension requires from the Token
    * in order to function properly
    * @dev This function is used by the TokenProxy to determine what
    * roles to grant to the extension after registration and what roles to remove
    * when removing the extension
    */
    function requiredRoles() external view returns (bytes32[] memory);

    /**
    * @notice Whether a given Token standard is supported by this Extension
    * @param standard The standard to check support for
    */
    function isTokenStandardSupported(TokenStandard standard) external view returns (bool);

    /**
    * @notice The address that deployed this extension.
    */
    function extensionDeployer() external view returns (address);

    /**
    * @notice The hash of the package string this extension was deployed with
    */
    function packageHash() external view returns (bytes32);

    /**
    * @notice The version of this extension, represented as a number
    */
    function version() external view returns (uint256);

    /**
    * @notice The ERC1820 interface label the extension will be registered as in the ERC1820 registry
    */
    function interfaceLabel() external view returns (string memory);
}

pragma solidity ^0.8.0;

import {TransferData} from "../tokens/IToken.sol";
import {IExtensionMetadata, TokenStandard} from "./IExtensionMetadata.sol";

/**
* @title Extension Interface
* @dev An interface to be implemented by Extensions
*/
interface IExtension is IExtensionMetadata {
    /**
    * @notice This function cannot be invoked directly
    * @dev This function is invoked when the Extension is registered
    * with a TokenProxy 
    */
    function initialize() external;
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/// @dev The interface a contract MUST implement if it is the implementer of
/// some (other) interface for any address other than itself.
interface IERC1820Implementer {
    /// @notice Indicates whether the contract implements the interface 'interfaceHash' for the address 'addr' or not.
    /// @param interfaceHash keccak256 hash of the name of the interface
    /// @param addr Address for which the contract will implement the interface
    /// @return ERC1820_ACCEPT_MAGIC only if the contract implements 'interfaceHash' for the address 'addr'.
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr) external view returns(bytes32);
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import {IERC1820Implementer} from "../interface/IERC1820Implementer.sol";


contract ERC1820Implementer is IERC1820Implementer {
  bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  mapping(address => mapping(bytes32 => bool)) internal _interfaceHashes;

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr)
    external
    override
    view
    returns(bytes32)
  {
    //If we implement the interface for this address
    //or if we implement the interface for every address
    if(_interfaceHashes[addr][interfaceHash] || _interfaceHashes[address(0)][interfaceHash]) {
      return ERC1820_ACCEPT_MAGIC;
    } else {
      return "";
    }
  }

  function _removeInterface(string memory interfaceLabel) internal {
    _removeInterface(interfaceLabel, true, true);
  }

  function _removeInterface(string memory interfaceLabel, bool forSelf, bool forAll) internal {
    //Implement the interface for myself
    if (forSelf)
      _interfaceHashes[address(this)][keccak256(abi.encodePacked(interfaceLabel))] = false;

    //Implement the interface for everyone
    if (forAll)
      _interfaceHashes[address(0)][keccak256(abi.encodePacked(interfaceLabel))] = false;
  }

  //TODO Rename to _setInterfaceForAll
  function _setInterface(string memory interfaceLabel) internal {
    _setInterface(interfaceLabel, true, true);
  }

  function _setInterface(string memory interfaceLabel, bool forSelf, bool forAll) internal {
    //Implement the interface for myself
    if (forSelf)
      _interfaceHashes[address(this)][keccak256(abi.encodePacked(interfaceLabel))] = true;

    //Implement the interface for everyone
    if (forAll)
      _interfaceHashes[address(0)][keccak256(abi.encodePacked(interfaceLabel))] = true;
  }

  function _setInterfaceForAddress(string memory interfaceLabel, address addr) internal {
    //Implement the interface for addr
    _interfaceHashes[addr][keccak256(abi.encodePacked(interfaceLabel))] = true;
  }
  
  
  /**
  * This empty reserved space is put in place to allow future versions to add new
  * variables without shifting down storage in the inheritance chain.
  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  */
  uint256[49] private __gap;
}

pragma solidity ^0.8.0;

import "@gnus.ai/contracts-upgradeable-diamond/utils/introspection/IERC1820RegistryUpgradeable.sol";


/// Base client to interact with the registry.
contract ERC1820Client {
    IERC1820RegistryUpgradeable constant ERC1820REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820RegistryUpgradeable {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import { ERC20Storage } from "./ERC20Storage.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    using ERC20Storage for ERC20Storage.Layout;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC20Storage.layout()._name = name_;
        ERC20Storage.layout()._symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return ERC20Storage.layout()._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC20Storage.layout()._symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC20Storage.layout()._totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return ERC20Storage.layout()._balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return ERC20Storage.layout()._allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, ERC20Storage.layout()._allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = ERC20Storage.layout()._allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = ERC20Storage.layout()._balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            ERC20Storage.layout()._balances[from] = fromBalance - amount;
        }
        ERC20Storage.layout()._balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        ERC20Storage.layout()._totalSupply += amount;
        ERC20Storage.layout()._balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = ERC20Storage.layout()._balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            ERC20Storage.layout()._balances[account] = accountBalance - amount;
        }
        ERC20Storage.layout()._totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        ERC20Storage.layout()._allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC20Upgradeable } from "./ERC20Upgradeable.sol";

library ERC20Storage {

  struct Layout {
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

    string _name;
    string _symbol;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.ERC20');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library InitializableStorage {

  struct Layout {
    /*
     * @dev Indicates that the contract has been initialized.
     */
    bool _initialized;

    /*
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool _initializing;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.Initializable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";
import { InitializableStorage } from "./InitializableStorage.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(InitializableStorage.layout()._initializing ? _isConstructor() : !InitializableStorage.layout()._initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
            InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(InitializableStorage.layout()._initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}