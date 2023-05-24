// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {SSTORE2} from "solmate/utils/SSTORE2.sol";

import {SS2ERC721Base, ERC721, ERC721TokenReceiver} from "./common/SS2ERC721Base.sol";

/// @notice SSTORE2-backed version of Solmate's ERC721, optimized for minting in a single batch
abstract contract SS2ERC721 is SS2ERC721Base {
    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// stored as SSTORE2 pointer (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
    ///
    /// array of abi.encodePacked(address1, address2, address3...) where address1 is the owner of token 1,
    /// address2 is the owner of token 2, etc.
    /// This means that:
    /// - addresses are stored contiguously in storage with no gaps (rather than 1 address per slot)
    /// - this is optimized for the mint path and using as few storage slots as possible for the primary owners
    /// - the tradeoff is that it causes extra gas and storage costs in the transfer/burn paths
    /// - this also causes extra costs in the ownerOf/balanceOf/tokenURI functions, but these are view functions
    ///
    /// Assumptions:
    /// - the list of addresses contains no duplicate
    /// - the list of addresses is sorted
    /// - the first valid token id is 1
    address internal _ownersPrimaryPointer;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /*//////////////////////////////////////////////////////////////
                         OWNER / BALANCE LOGIC
    //////////////////////////////////////////////////////////////*/

    function _ownersPrimaryLength() internal view override returns (uint256) {
        if (_ownersPrimaryPointer == address(0)) {
            return 0;
        }

        // checked math will underflow if _ownersPrimaryPointer.code.length == 0
        return (_ownersPrimaryPointer.code.length - 1) / 20;
    }

    function _ownerOfPrimary(
        uint256 id
    ) internal view override returns (address owner) {
        // this is an internal method, so return address(0) and let the caller decide if they want to revert
        if (id == 0) {
            return address(0);
        }

        address pointer = _ownersPrimaryPointer;
        if (pointer == address(0)) {
            return address(0);
        }

        unchecked {
            // can not underflow because we checked id != 0
            uint256 zeroBasedId = id - 1;

            // this can overflow!
            uint256 start = zeroBasedId * 20;

            // check for overflow and exit cleanly if it happens
            if (start < zeroBasedId) {
                return address(0);
            }

            // if we read past the end of the bucket, we will get 0 bytes back
            // which is great, because we're supposed to return address(0) in that case anyway
            owner = SSTORE2_readRawAddress(pointer, start);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev this function creates a new SSTORE2 pointer, and saves it
    /// @dev reading addresses from calldata means we can assemble the creation code with a single memory copy
    function _mint(
        bytes calldata addresses
    ) internal virtual returns (uint256 numMinted) {
        assembly {
            function revert_invalid_addresses() {
                let ptr := mload(FREE_MEM_PTR)
                mstore(ptr, shl(224, ERROR_STRING_SELECTOR))
                mstore(add(ptr, 0x04), WORD_SIZE) // String offset
                mstore(add(ptr, 0x24), 17) // Revert reason length
                mstore(add(ptr, 0x44), "INVALID_ADDRESSES")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            function revert_already_minted() {
                let ptr := mload(FREE_MEM_PTR)
                mstore(ptr, shl(224, ERROR_STRING_SELECTOR))
                mstore(add(ptr, 0x04), WORD_SIZE) // String offset
                mstore(add(ptr, 0x24), 14) // Revert reason length
                mstore(add(ptr, 0x44), "ALREADY_MINTED")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            function revert_not_sorted() {
                let ptr := mload(FREE_MEM_PTR)
                mstore(ptr, shl(224, ERROR_STRING_SELECTOR))
                mstore(add(ptr, 0x04), WORD_SIZE) // String offset
                mstore(add(ptr, 0x24), 20) // Revert reason length
                mstore(add(ptr, 0x44), "ADDRESSES_NOT_SORTED")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            let stored_primary_pointer := sload(_ownersPrimaryPointer.slot)
            let primary_pointer := and(stored_primary_pointer, BITMASK_ADDRESS)

            // if the primary pointer is already set, we can't mint
            // note: we don't clean the upper bits of the address, we check against the full word
            if gt(primary_pointer, 0) {
                revert_already_minted()
            }

            // we expect addresses.length to be > 0
            if eq(addresses.length, 0) {
                revert_invalid_addresses()
            }

            // we expect the SSTORE2 pointer to contain a list of packed addresses
            // so the length must be a multiple of 20 bytes
            if gt(mod(addresses.length, ADDRESS_SIZE_BYTES), 0) {
                revert_invalid_addresses()
            }

            // the SSTORE2 creation code is SSTORE2_CREATION_CODE_PREFIX + addresses_data
            let creation_code_len := add(
                SSTORE2_CREATION_CODE_OFFSET,
                addresses.length
            )
            let creation_code_ptr := mload(FREE_MEM_PTR)

            // copy the creation code prefix
            // this sets up the memory at creation_code_ptr with the following word:
            //      600B5981380380925939F3000000000000000000000000000000000000000000
            // this also has the advantage of storing fresh 0 bytes
            mstore(
                creation_code_ptr,
                shl(
                    168, // shift the prefix to the left by 21 bytes
                    SSTORE2_CREATION_CODE_PREFIX
                )
            )

            // copy the address data in memory after the creation code prefix
            // after this call, the memory at creation_code_ptr will look like this:
            //      600B5981380380925939F300AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            // note that the 00 bytes between the prefix and the first address is guaranteed to be clean
            // because of the shl above
            let addresses_data_ptr := add(
                creation_code_ptr,
                SSTORE2_CREATION_CODE_OFFSET
            )
            calldatacopy(
                addresses_data_ptr, // destOffset in memory
                addresses.offset, // offset in calldata
                addresses.length // length
            )

            numMinted := div(addresses.length, ADDRESS_SIZE_BYTES)
            let prev := 0
            for {
                let i := 0
            } lt(i, numMinted) {

            } {
                // compute the pointer to the recipient address
                let to_ptr := add(
                    addresses_data_ptr,
                    mul(i, ADDRESS_SIZE_BYTES)
                )

                // mload loads a whole 32-byte word, so we get the 20 bytes we want plus 12 bytes we don't:
                //      AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBB
                // so we shift right by 12 bytes to get rid of the extra bytes and align the address:
                //      000000000000000000000000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                // this guarantees that the high bits of `to` are clean
                let to := shr(ADDRESS_OFFSET_BITS, mload(to_ptr))

                // make sure that the addresses are sorted, the binary search in balanceOf relies on it
                if iszero(gt(to, prev)) {
                    revert_not_sorted()
                }

                prev := to

                // counter increment, can not overflow
                // increment before emitting the event, because the first valid tokenId is 1
                i := add(i, 1)

                // emit the Transfer event
                log4(
                    0, // dataOffset
                    0, // dataSize
                    TRANSFER_EVENT_SIGNATURE, // topic1 = signature
                    0, // topic2 = from
                    to, // topic3 = to
                    i // topic4 = tokenId
                )
            }

            // perform the SSTORE2 write
            let clean_pointer := create(
                0, // value
                creation_code_ptr, // offset
                creation_code_len // length
            )

            // we need to restore the upper bits that may have been set if data was packed in the same slot
            // stored_primary_pointer is either 0 (if the slot was clean) or [12-bytes || address(0)]
            // so we OR it with the clean pointer to restore the upper bits
            sstore(
                _ownersPrimaryPointer.slot,
                or(clean_pointer, stored_primary_pointer)
            )
        }
    }

    /// @dev specialized version that performs a batch mint with no safeMint checks
    /// @dev this function reads from an existing SSTORE2 pointer, and saves it
    function _mint(
        address pointer
    ) internal virtual returns (uint256 numMinted) {
        assembly {
            function revert_invalid_addresses() {
                let ptr := mload(FREE_MEM_PTR)
                mstore(ptr, shl(224, ERROR_STRING_SELECTOR))
                mstore(add(ptr, 0x04), WORD_SIZE) // String offset
                mstore(add(ptr, 0x24), 17) // Revert reason length
                mstore(add(ptr, 0x44), "INVALID_ADDRESSES")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            function revert_already_minted() {
                let ptr := mload(FREE_MEM_PTR)
                mstore(ptr, shl(224, ERROR_STRING_SELECTOR))
                mstore(add(ptr, 0x04), WORD_SIZE) // String offset
                mstore(add(ptr, 0x24), 14) // Revert reason length
                mstore(add(ptr, 0x44), "ALREADY_MINTED")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            function revert_not_sorted() {
                let ptr := mload(FREE_MEM_PTR)
                mstore(ptr, shl(224, ERROR_STRING_SELECTOR))
                mstore(add(ptr, 0x04), WORD_SIZE) // String offset
                mstore(add(ptr, 0x24), 20) // Revert reason length
                mstore(add(ptr, 0x44), "ADDRESSES_NOT_SORTED")
                revert(ptr, 0x64) // Revert data length is 4 bytes for selector and 3 slots of 0x20 bytes
            }

            let stored_primary_pointer := sload(_ownersPrimaryPointer.slot)
            let primary_pointer := and(stored_primary_pointer, BITMASK_ADDRESS)

            // if the primary pointer is already set, we can't mint
            // note: we don't clean the upper bits of the address, we check against the full word
            if gt(primary_pointer, 0) {
                revert_already_minted()
            }

            // zero-out the upper bits of `pointer`
            let clean_pointer := and(pointer, BITMASK_ADDRESS)

            let pointer_codesize := extcodesize(clean_pointer)

            // if pointer_codesize is 0, then it is not an SSTORE2 pointer
            // if pointer_codesize is 1, then it may be a valid but empty SSTORE2 pointer
            if lt(pointer_codesize, 2) {
                revert_invalid_addresses()
            }

            // subtract 1 because SSTORE2 prepends the data with a `00` byte (a STOP opcode)
            // can not overflow because pointer_codesize is at least 2
            let addresses_length := sub(pointer_codesize, 1)

            // we expect the SSTORE2 pointer to contain a list of packed addresses
            // so the length must be a multiple of 20 bytes
            if gt(mod(addresses_length, ADDRESS_SIZE_BYTES), 0) {
                revert_invalid_addresses()
            }

            // perform the SSTORE2 read, store the data in memory at `addresses_data`
            let addresses_data := mload(FREE_MEM_PTR)
            extcodecopy(
                clean_pointer, // address
                addresses_data, // memory offset
                SSTORE2_DATA_OFFSET, // destination offset
                addresses_length // size
            )

            numMinted := div(addresses_length, ADDRESS_SIZE_BYTES)
            let prev := 0
            for {
                let i := 0
            } lt(i, numMinted) {

            } {
                // compute the pointer to the recipient address
                let to_ptr := add(addresses_data, mul(i, ADDRESS_SIZE_BYTES))

                // mload loads a whole 32-byte word, so we get the 20 bytes we want plus 12 bytes we don't:
                //      AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBB
                // so we shift right by 12 bytes to get rid of the extra bytes and align the address:
                //      000000000000000000000000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                // this guarantees that the high bits of `to` are clean
                let to := shr(ADDRESS_OFFSET_BITS, mload(to_ptr))

                // make sure that the addresses are sorted, the binary search in balanceOf relies on it
                if iszero(gt(to, prev)) {
                    revert_not_sorted()
                }

                prev := to

                // counter increment, can not overflow
                // increment before emitting the event, because the first valid tokenId is 1
                i := add(i, 1)

                // emit the Transfer event
                log4(
                    0, // dataOffset
                    0, // dataSize
                    TRANSFER_EVENT_SIGNATURE, // topic1 = signature
                    0, // topic2 = from
                    to, // topic3 = to
                    i // topic4 = tokenId
                )
            }

            // we need to restore the upper bits that may have been set if data was packed in the same slot
            // stored_primary_pointer is either 0 (if the slot was clean) or [12-bytes || address(0)]
            // so we OR it with the clean pointer to restore the upper bits
            sstore(
                _ownersPrimaryPointer.slot,
                or(clean_pointer, stored_primary_pointer)
            )
        }
    }

    function _safeMint(
        address pointer
    ) internal virtual returns (uint256 numMinted) {
        numMinted = _safeMint(pointer, "");
    }

    /// @dev specialized version that performs a batch mint with a safeMint check at each iteration
    /// @dev in _safeMint, we try to keep assembly usage at a minimum
    function _safeMint(
        address pointer,
        bytes memory data
    ) internal virtual returns (uint256 numMinted) {
        require(_ownersPrimaryPointer == address(0), "ALREADY_MINTED");

        bytes memory addresses = SSTORE2.read(pointer);
        uint256 length = addresses.length;
        require(length > 0 && length % 20 == 0, "INVALID_ADDRESSES");

        numMinted = length / 20;
        address prev = address(0);

        for (uint256 i = 0; i < numMinted; ) {
            address to;
            assembly {
                to := shr(96, mload(add(addresses, add(32, mul(i, 20)))))
                i := add(i, 1)
            }

            // enforce that the addresses are sorted with no duplicates, and no zero addresses
            require(to > prev, "ADDRESSES_NOT_SORTED");
            prev = to;

            emit Transfer(address(0), to, i);

            require(
                _checkOnERC721Received(address(0), to, i, data),
                "UNSAFE_RECIPIENT"
            );
        }

        _ownersPrimaryPointer = pointer;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

abstract contract SS2ERC721Base is ERC721 {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WORD_SIZE = 32;
    uint256 internal constant ADDRESS_SIZE_BYTES = 20;
    uint256 internal constant ADDRESS_OFFSET_BITS = 96;
    uint256 internal constant FREE_MEM_PTR = 0x40;
    uint256 internal constant SSTORE2_DATA_OFFSET = 1;
    uint256 internal constant ERROR_STRING_SELECTOR = 0x08c379a0; // Error(string)
    uint256 internal constant SSTORE2_CREATION_CODE_PREFIX = 0x600B5981380380925939F3; // see SSTORE2.sol
    uint256 internal constant SSTORE2_CREATION_CODE_OFFSET = 12; // prefix length + 1 for a 0 byte

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 internal constant TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // The mask of the lower 160 bits for addresses.
    uint256 internal constant BITMASK_ADDRESS = (1 << 160) - 1;

    /// @dev a flag for _balanceIndicator
    uint256 internal constant SKIP_PRIMARY_BALANCE = 1 << 255;

    /// @dev a flag for _ownerIndicator
    /// @dev use a different value then SKIP_PRIMARY_BALANCE to avoid confusion
    uint256 internal constant BURNED = 1 << 254;

    uint256 internal constant BALANCE_MASK = type(uint256).max >> 1;

    /*//////////////////////////////////////////////////////////////
                            MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev mapping from token id to indicator (owner address plus burned flag packed in the higher bits)
    mapping(uint256 => uint256) internal _ownerIndicator;

    /// @dev 255-bit balance + 1-bit not primary owner flag
    ///
    /// - ownerIndicator[id] == 0 == (not_burned, address(0))
    ///     means that there is no secondary owner for id and we should fall back to the primary owner check
    ///
    /// - ownerIndicator[id] == (burned, address(0))
    ///     means that address(0) *is* the secondary owner, no need to fall back on the primary owner check
    ///
    /// - ownerIndicator[id] == (not_burned, owner)
    ///     means that `owner` is the secondary owner, no need to fall back on the primary owner check
    mapping(address => uint256) internal _balanceIndicator;

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// implementations must override this function to return the number of tokens minted
    function _ownersPrimaryLength() internal view virtual returns (uint256);

    /// implementations must override this function to return the primary owner of a token
    /// or address(0) if the token does not exist
    function _ownerOfPrimary(uint256 id) internal view virtual returns (address owner);

    /// @dev performs no bounds check, just a raw extcodecopy on the pointer
    /// @return addr the address at the given pointer (may include 0 bytes if reading past the end of the pointer)
    function SSTORE2_readRawAddress(address pointer, uint256 start) internal view returns (address addr) {
        // we're going to read 20 bytes from the pointer in the first scratch space slot
        uint256 dest_offset = 12;

        assembly {
            start := add(start, 1) // add the SSTORE2 DATA_OFFSET

            // clear it the first scratch space slot
            mstore(0, 0)

            extcodecopy(pointer, dest_offset, start, 20)

            addr := mload(0)
        }
    }

    function _getOwnerSecondary(uint256 id) internal view returns (address owner) {
        owner = address(uint160(_ownerIndicator[id]));
    }

    function _setOwnerSecondary(uint256 id, address owner) internal {
        if (owner == address(0)) {
            _setBurned(id);
        } else {
            // we don't expect this to be called after burning, so no need to carry over the BURNED flag
            _ownerIndicator[id] = uint160(owner);
        }
    }

    function _hasBeenBurned(uint256 id) internal view returns (bool) {
        return _ownerIndicator[id] & BURNED != 0;
    }

    /// @dev sets the burned flag *and* sets the owner to address(0)
    function _setBurned(uint256 id) internal {
        _ownerIndicator[id] = BURNED;
    }

    // binary search of the address based on _ownerOfPrimary
    // performs O(log n) sloads
    // relies on the assumption that the list of addresses is sorted and contains no duplicates
    // returns 1 if the address is found in _ownersPrimary, 0 if not
    function _balanceOfPrimary(address owner) internal view returns (uint256) {
        uint256 low = 1;
        uint256 high = _ownersPrimaryLength();
        uint256 mid = (low + high) / 2;

        // TODO: unchecked
        while (low <= high) {
            address midOwner = _ownerOfPrimary(mid);
            if (midOwner == owner) {
                return 1;
            } else if (midOwner < owner) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
            mid = (low + high) / 2;
        }

        return 0;
    }

    /// @dev for internal use -- does not revert on unminted token ids
    function __ownerOf(uint256 id) internal view returns (address owner) {
        uint256 ownerIndicator = _ownerIndicator[id];
        owner = address(uint160(ownerIndicator));

        if (ownerIndicator & BURNED == BURNED) {
            // normally 0, but return what has been set in the mapping in case inherited contract changes it
            return owner;
        }

        // we use 0 as a sentinel value, meaning that we can't burn by setting the owner to address(0)
        if (owner == address(0)) {
            owner = _ownerOfPrimary(id);
        }
    }

    function ownerOf(uint256 id) public view virtual override returns (address owner) {
        owner = __ownerOf(id);
        require(owner != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual override returns (uint256 balance) {
        require(owner != address(0), "ZERO_ADDRESS");

        uint256 balanceIndicator = _balanceIndicator[owner];
        balance = balanceIndicator & BALANCE_MASK;

        if (balanceIndicator & SKIP_PRIMARY_BALANCE == 0) {
            balance += _balanceOfPrimary(owner);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual override {
        // need to use the ownerOf getter here instead of directly accessing the storage
        address owner = __ownerOf(id);

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function transferFrom(address from, address to, uint256 id) public virtual override {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );
        require(to != address(0), "INVALID_RECIPIENT");

        address owner = _moveTokenTo(id, to);

        require(from == owner, "WRONG_FROM");

        unchecked {
            ++_balanceIndicator[to];
        }
    }

    /// @dev needs to be overridden here to invoke our custom version of transferFrom
    function safeTransferFrom(address from, address to, uint256 id) public virtual override {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @dev needs to be overridden here to invoke our custom version of transferFrom
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual override {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _burn(uint256 id) internal virtual override {
        _moveTokenTo(id, address(0));
    }

    function _moveTokenTo(uint256 id, address to) private returns (address owner) {
        owner = _getOwnerSecondary(id);

        if (owner == address(0)) {
            owner = _ownerOfPrimary(id);
            require(owner != address(0), "NOT_MINTED");

            _balanceIndicator[owner] |= SKIP_PRIMARY_BALANCE;
        } else {
            unchecked {
                --_balanceIndicator[owner];
            }
        }

        _setOwnerSecondary(id, to);

        delete getApproved[id];

        emit Transfer(owner, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        internal
        returns (bool)
    {
        if (to.code.length == 0) {
            return true;
        }

        try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == ERC721TokenReceiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("UNSAFE_RECIPIENT");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SSTORE2} from "solmate/utils/SSTORE2.sol";
import {SS2ERC721} from "@SS2ERC721/src/SS2ERC721.sol";

contract MultiMint is SS2ERC721 {
    constructor(
        string memory name_,
        string memory symbol_
    ) SS2ERC721(name_, symbol_) {}

    /// @dev recipients must be a packed encoding of sorted addresses
    /// @dev warning: no auth check on this method
    function mint(bytes calldata recipients) public {
        address ptr = SSTORE2.write(recipients);
        _mint(ptr);
    }

    function tokenURI(
        uint256
    ) public view virtual override returns (string memory) {
        return "";
    }
}