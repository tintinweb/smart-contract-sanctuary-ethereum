// SPDX-License-Identifier: Unlicense
import {OwnableOpenSeaDefaultOperatorFilterer} from "./access/OwnableOperatorFilterer.sol";
import {LibString} from "./utils/LibString.sm.sol";
import "./interfaces/IFactoryERC721.sol";

interface IERC721Mintable {
    function mintTo(address to_, uint quantity_) external;
}

contract FactoryPetTTrees is IFactoryERC721, OwnableOpenSeaDefaultOperatorFilterer {
    uint remainingTokens;

    uint8 constant NUM_OPTIONS = 4;
    uint8 constant SINGLE_OPTION = 0;
    uint8 constant SOME_OPTION = 1;
    uint8 constant MULTIPLE_OPTION = 2;
    uint8 constant MANY_OPTION = 3;
    uint8 constant NUM_IN_MULTIPLE_OPTION = 5;

    IERC721Mintable token;

    constructor(address nft, uint supplyCap_) {
        token = IERC721Mintable(nft);
        remainingTokens = supplyCap_;
    }
    /**
     * Returns the name of this factory.
     */
    function name() external pure override returns (string memory) {
        return "Pet T Tree Min TS Tore";
    }

    /**
     * Returns the symbol for this factory.
     */
    function symbol() external pure override returns (string memory) {
        return "PTTSTORE";
    }

    /**
     * Number of options the factory supports.
     */
    function numOptions() external pure override returns (uint256) {
        return NUM_OPTIONS;
    }

    /**
     * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
     * restrict a total supply per option ID (or overall).
     */
    function canMint(uint256 _optionId) external override view returns (bool) {
        return _canMint(uint8(_optionId));
    }

    function _canMint(uint8 _optionId) internal view returns(bool) {
        unchecked {
            return remainingTokens > (_optionId * NUM_IN_MULTIPLE_OPTION);
        }
    }

    /**
     * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
     * same structure as the ERC721 metadata.
     */
    function tokenURI(uint256 _optionId) external pure override returns (string memory) {
        string memory uri = "ipfs://bafybeicljh52mptljtvo3j7t4ngbrrt3qer4wupp5rsi3bqrilattkwali/";
        return string(abi.encodePacked(uri, LibString.toString(_optionId), ".json"));
    }

    /**
     * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
     */
    function supportsFactoryInterface() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) 
        external override 
        onlyAllowedOperator(_toAddress) 
    {
        uint8 option = uint8(_optionId);
        require(_canMint(option), "Mint has ended");
        
        uint16 total = 1 + (option * NUM_IN_MULTIPLE_OPTION);   
        
        remainingTokens -= total;
        token.mintTo(_toAddress, total);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./OperatorFilterer.sol";

abstract contract OwnableOperatorFilterer is Ownable, OperatorFilterer {
    modifier onlyAllowedOperatorOrOwner() virtual {
        if(owner() != msg.sender) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

abstract contract OwnableOpenSeaDefaultOperatorFilterer is OwnableOperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface IFactoryERC721 {
    /**
     * Returns the name of this factory.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol for this factory.
     */
    function symbol() external view returns (string memory);

    /**
     * Number of options the factory supports.
     */
    function numOptions() external view returns (uint256);

    /**
     * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
     * restrict a total supply per option ID (or overall).
     */
    function canMint(uint256 _optionId) external view returns (bool);

    /**
     * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
     * same structure as the ERC721 metadata.
     */
    function tokenURI(uint256 _optionId) external view returns (string memory);

    /**
     * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
     */
    function supportsFactoryInterface() external view returns (bool);

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sm.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sm.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

abstract contract Ownable {
    address internal _owner_;

    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner_ = msg.sender;
        emit OwnershipTransferred(address(0), _owner_);
    }

    function owner() public view returns (address) {
        return _owner_;
    }

    modifier onlyOwner() {
        if(_owner_ != msg.sender) revert NotOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner_, address(0));
        _owner_ = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if(newOwner == address(0) || newOwner == _owner_) 
            revert InvalidOwner();
        emit OwnershipTransferred(_owner_, newOwner);
        _owner_ = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../interfaces/IOperatorFilterRegistry.sol";

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    bool public isOperatorFilterEnabled = true;
    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check if filter operator is enabled
        if (!isOperatorFilterEnabled) {
            _;
            return;
        }
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}

abstract contract OpenSeaDefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}