// SPDX-License-Identifier: MIT

/// @title Ultra Sound Parts
/// @author -wizard

// Inspired by - Nouns DAO art contract

pragma solidity ^0.8.6;

import {SSTORE2} from "./libs/SSTORE2.sol";
import {IUltraSoundParts} from "./interfaces/IUltraSoundParts.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract UltraSoundParts is IUltraSoundParts, Ownable {
    address[] private symbolPointers;
    address[] private palettePointers;
    address[] private gradientPointers;

    uint16[8] private quantity = [80, 40, 20, 10, 5, 4, 1, 0];

    constructor() {}

    function addSymbol(bytes calldata data) external override onlyOwner {
        _addSymbol(data);
    }

    function addSymbols(bytes[] calldata data) external override onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            _addSymbol(data[i]);
        }
    }

    // Note: Palette must be an abi encoded string array
    function addPalette(bytes calldata data) external override onlyOwner {
        _addPalette(data);
    }

    // Note: Palette must be an abi encoded string array
    function addPalettes(bytes[] calldata data) external override onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            _addPalette(data[i]);
        }
    }

    // Note: Gradients must be an abi encoded string array
    function addGradient(bytes calldata data) external override onlyOwner {
        _addGradient(data);
    }

    // Note: Gradients must be an abi encoded string array
    function addGradients(bytes[] calldata data) external override onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            _addGradient(data[i]);
        }
    }

    function symbols(uint256 index)
        public
        view
        override
        returns (bytes memory)
    {
        address pointer = symbolPointers[index];
        if (pointer == address(0)) revert PartNotFound();
        bytes memory data = SSTORE2.read(symbolPointers[index]);
        return data;
    }

    function palettes(uint256 index)
        public
        view
        override
        returns (bytes memory)
    {
        address pointer = palettePointers[index];
        if (pointer == address(0)) revert PartNotFound();
        bytes memory data = SSTORE2.read(pointer);
        return data;
    }

    function gradients(uint256 index)
        public
        view
        override
        returns (bytes memory)
    {
        address pointer = gradientPointers[index];
        if (pointer == address(0)) revert PartNotFound();
        bytes memory data = SSTORE2.read(pointer);
        return data;
    }

    function quantities(uint256 index) public view override returns (uint16) {
        return quantity[index];
    }

    function symbolsCount() public view override returns (uint256) {
        return symbolPointers.length;
    }

    function palettesCount() public view override returns (uint256) {
        return palettePointers.length;
    }

    function gradientsCount() public view override returns (uint256) {
        return gradientPointers.length;
    }

    function quantityCount() public view override returns (uint256) {
        return quantity.length;
    }

    function _addSymbol(bytes calldata data) internal {
        address pointer = SSTORE2.write(data);
        symbolPointers.push(pointer);
        emit SymbolAdded();
    }

    function _addPalette(bytes calldata data) internal {
        address pointer = SSTORE2.write(data);
        palettePointers.push(pointer);
        emit PaletteAdded();
    }

    function _addGradient(bytes calldata data) internal {
        address pointer = SSTORE2.write(data);
        gradientPointers.push(pointer);
        emit GradientAdded();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.6;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*///////////////////////////////////////////////////////////////
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

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return
            readBytecode(
                pointer,
                DATA_OFFSET,
                pointer.code.length - DATA_OFFSET
            );
    }

    function read(address pointer, uint256 start)
        internal
        view
        returns (bytes memory)
    {
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

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
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

// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Parts
/// @author -wizard

pragma solidity ^0.8.6;

interface IUltraSoundParts {
    error SenderIsNotDescriptor();
    error PartNotFound();

    event SymbolAdded();
    event PaletteAdded();
    event GradientAdded();

    function addSymbol(bytes calldata data) external;

    function addSymbols(bytes[] calldata data) external;

    function addPalette(bytes calldata data) external;

    function addPalettes(bytes[] calldata data) external;

    function addGradient(bytes calldata data) external;

    function addGradients(bytes[] calldata data) external;

    function symbols(uint256 index) external view returns (bytes memory);

    function palettes(uint256 index) external view returns (bytes memory);

    function gradients(uint256 index) external view returns (bytes memory);

    function quantities(uint256 index) external view returns (uint16);

    function symbolsCount() external view returns (uint256);

    function palettesCount() external view returns (uint256);

    function gradientsCount() external view returns (uint256);

    function quantityCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}