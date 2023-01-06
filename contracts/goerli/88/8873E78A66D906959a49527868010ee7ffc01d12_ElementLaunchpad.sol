// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./storage/LibFeatureStorage.sol";
import "./storage/LibOwnableStorage.sol";
import "./libs/Ownable.sol";
import "./libs/FixinTokenSpender.sol";

contract ElementLaunchpad is Ownable, FixinTokenSpender {

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        assembly {
            // Copy methodID to memory 0x00~0x04
            calldatacopy(0, 0, 4)

            // Calculate impl.slot and load impl from storage
            let impl := sload(keccak256(0, 0x40))
            if impl {
                calldatacopy(0, 0, calldatasize())
                if delegatecall(gas(), impl, 0, calldatasize(), 0, 0) {
                    // Success, copy the returned data and return.
                    returndatacopy(0, 0, returndatasize())
                    return(0, returndatasize())
                }

                // Failed, copy the returned data and revert.
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // revert("Not implemented method.")
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(0x40, 0x000000174e6f7420696d706c656d656e746564206d6574686f642e0000000000)
            mstore(0x60, 0)
            revert(0, 0x64)
        }
    }

    struct Method {
        bytes4 methodID;
        string methodName;
    }

    struct Feature {
        address feature;
        string name;
        Method[] methods;
    }

    event FeatureFunctionUpdated(
        bytes4 indexed methodID,
        address oldFeature,
        address newFeature
    );

    function registerFeatures(Feature[] calldata features) external onlyOwner {
        unchecked {
            for (uint256 i; i < features.length; ++i) {
                registerFeature(features[i]);
            }
        }
    }

    function registerFeature(Feature calldata feature) public onlyOwner {
        unchecked {
            address impl = feature.feature;
            require(impl != address(0), "registerFeature: invalid feature address.");

            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
            stor.featureNames[impl] = feature.name;

            Method[] calldata methods = feature.methods;
            for (uint256 i; i < methods.length; ++i) {
                bytes4 methodID = methods[i].methodID;
                address oldFeature = stor.featureImpls[methodID];
                if (oldFeature == address(0)) {
                    stor.methodIDs.push(methodID);
                }
                stor.featureImpls[methodID] = impl;
                stor.methodNames[methodID] = methods[i].methodName;
                emit FeatureFunctionUpdated(methodID, oldFeature, impl);
            }
        }
    }

    function unregister(bytes4[] calldata methodIDs) external onlyOwner {
        unchecked {
            uint256 removedFeatureCount;
            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

            // Update storage.featureImpls
            for (uint256 i; i < methodIDs.length; ++i) {
                bytes4 methodID = methodIDs[i];
                address impl = stor.featureImpls[methodID];
                if (impl != address(0)) {
                    removedFeatureCount++;
                    stor.featureImpls[methodID] = address(0);
                }
                emit FeatureFunctionUpdated(methodID, impl, address(0));
            }
            if (removedFeatureCount == 0) {
                return;
            }

            // Remove methodIDs from storage.methodIDs
            bytes4[] storage storMethodIDs = stor.methodIDs;
            for (uint256 i = storMethodIDs.length; i > 0; --i) {
                bytes4 methodID = storMethodIDs[i - 1];
                if (stor.featureImpls[methodID] == address(0)) {
                    if (i != storMethodIDs.length) {
                        storMethodIDs[i - 1] = storMethodIDs[storMethodIDs.length - 1];
                    }
                    delete storMethodIDs[storMethodIDs.length - 1];
                    storMethodIDs.pop();

                    if (removedFeatureCount == 1) { // Finished
                        return;
                    }
                    --removedFeatureCount;
                }
            }
        }
    }

    function getMethodIDs() external view returns (uint256 count, bytes4[] memory methodIDs) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        return (stor.methodIDs.length, stor.methodIDs);
    }

    function getFeatureImpl(bytes4 methodID) external view returns (address impl) {
        return LibFeatureStorage.getStorage().featureImpls[methodID];
    }

    function getFeatures() external view returns (
        uint256 featuresCount,
        address[] memory features,
        string[] memory names,
        uint256[] memory featureMethodsCount
    ) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        uint256[] memory methodsCount = new uint256[](stor.methodIDs.length);
        address[] memory addrs = new address[](stor.methodIDs.length);

        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            address impl = stor.featureImpls[methodID];

            uint256 j = 0;
            while (j < featuresCount && impl != addrs[j]) {
                ++j;
            }
            if (j == featuresCount) {
                addrs[j] = impl;
                ++featuresCount;
            }

            ++methodsCount[j];
        }

        features = new address[](featuresCount);
        names = new string[](featuresCount);
        featureMethodsCount = new uint256[](featuresCount);
        for (uint256 i = 0; i < featuresCount; ++i) {
            features[i] = addrs[i];
            names[i] = stor.featureNames[addrs[i]];
            featureMethodsCount[i] = methodsCount[i];
        }
        return (featuresCount, features, names, featureMethodsCount);
    }

    function approveERC20(IERC20 token, address operator, uint256 amount) external onlyOwner {
        token.approve(operator, amount);
    }

    function rescueETH(address recipient) external onlyOwner {
        require(recipient != address(0));
        _transferEth(recipient, address(this).balance);
    }

    function rescueERC20(address asset, address recipient) external onlyOwner {
        require(recipient != address(0));
        _transferERC20(asset, recipient, IERC20(asset).balanceOf(address(this)));
    }

    function rescueERC721(address asset, uint256[] calldata ids , address recipient) external onlyOwner {
        require(recipient != address(0));
        assembly {
            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, recipient)

            for { let offset := ids.offset } lt(offset, calldatasize()) { offset := add(offset, 0x20) } {
            // tokenID
                mstore(0x44, calldataload(offset))
                if iszero(call(gas(), asset, 0, 0, 0x64, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function rescueERC1155(IERC1155 asset, uint256 id, uint256 amount, address recipient) external onlyOwner {
        require(recipient != address(0));
        asset.safeTransferFrom(address(this), recipient, id, amount, "");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId) external virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibFeatureStorage {

    uint256 constant STORAGE_ID_FEATURE = 0;

    struct Storage {
        // Mapping of methodID -> feature implementation
        mapping(bytes4 => address) featureImpls;
        // Mapping of feature implementation -> feature name
        mapping(address => string) featureNames;
        // Record methodIDs
        bytes4[] methodIDs;
        // Mapping of methodID -> method name
        mapping(bytes4 => string) methodNames;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := STORAGE_ID_FEATURE }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibOwnableStorage {

    uint256 constant STORAGE_ID_OWNABLE = 1 << 128;

    struct Storage {
        uint256 reentrancyStatus;
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_OWNABLE }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../storage/LibOwnableStorage.sol";


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
abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibOwnableStorage.getStorage().owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
    function _transferOwnership(address newOwner) private {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = ((1 << 160) - 1);

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20From(address token, address owner, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20(address token, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address recipient, uint256 amount) internal {
        assembly {
            if amount {
                if iszero(call(gas(), recipient, amount, 0, 0, 0, 0)) {
                    // revert("_transferEth/TRANSFER_FAILED")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x0000001c5f7472616e736665724574682f5452414e534645525f4641494c4544)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }
        }
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