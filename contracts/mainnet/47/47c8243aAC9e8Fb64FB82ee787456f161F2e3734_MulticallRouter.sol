// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../libs/Resolver.sol";
import "../../libs/ErrorHelper.sol";

contract MulticallRouter {
    using Resolver for *;
    using ErrorHelper for *;

    function multicall(
        address[] calldata targets_,
        uint256[] calldata values_,
        bytes[] calldata data_
    ) external payable {
        require(
            targets_.length == values_.length && values_.length == data_.length,
            "MulticallRouter: lengths mismatch"
        );

        for (uint256 i = 0; i < targets_.length; ++i) {
            (bool ok_, bytes memory revertData_) = targets_[i].resolve().call{
                value: values_[i].resolve()
            }(data_[i]);

            require(ok_, revertData_.toStringReason().wrap("MulticallRouter"));
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity ^0.8.9;

library Constants {
    uint256 internal constant CONTRACT_BALANCE =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    address internal constant THIS_ADDRESS = 0x0000000000000000000000000000000000000001;
    address internal constant CALLER_ADDRESS = 0x0000000000000000000000000000000000000002;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library ErrorHelper {
    string internal constant ERROR_DELIMITER = ": ";

    function toStringReason(bytes memory data_) internal pure returns (string memory) {
        if (data_.length < 68) {
            return "ErrorHelper: command reverted silently";
        }

        assembly {
            data_ := add(data_, 0x04)
        }

        return abi.decode(data_, (string));
    }

    function wrap(
        string memory error_,
        string memory prefix_
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(prefix_, ERROR_DELIMITER, error_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./Constants.sol";
import "../master-facet/MasterRouterStorage.sol";

library Resolver {
    function resolve(address address_) internal view returns (address) {
        if (address_ == Constants.THIS_ADDRESS) {
            return address(this);
        }

        if (address_ == Constants.CALLER_ADDRESS) {
            return MasterRouterStorage(address(this)).getCallerAddress();
        }

        return address_;
    }

    function resolve(uint256 amount_) internal view returns (uint256) {
        if (amount_ == Constants.CONTRACT_BALANCE) {
            return address(this).balance;
        }

        return amount_;
    }

    function resolve(uint256 amount_, IERC20 erc20_) internal view returns (uint256) {
        if (amount_ == Constants.CONTRACT_BALANCE) {
            return erc20_.balanceOf(address(this));
        }

        return amount_;
    }

    function resolve(
        uint256 amount_,
        IERC1155 erc1155_,
        uint256 tokenId_
    ) internal view returns (uint256) {
        if (amount_ == Constants.CONTRACT_BALANCE) {
            return erc1155_.balanceOf(address(this), tokenId_);
        }

        return amount_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MasterRouterStorage {
    bytes32 public constant MASTER_ROUTER_STORAGE_SLOT =
        keccak256("diamond.standard.masterrouter.storage");

    struct MRStorage {
        address caller;
    }

    modifier onlyCaller() {
        MRStorage storage _ds = getMasterRouterStorage();

        require(_ds.caller == address(0), "MasterRouterStorage: new caller");

        _ds.caller = msg.sender;
        _;
        _ds.caller = address(0);
    }

    function getMasterRouterStorage() internal pure returns (MRStorage storage _ds) {
        bytes32 slot_ = MASTER_ROUTER_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }

    function getCallerAddress() public view returns (address caller_) {
        return getMasterRouterStorage().caller;
    }
}