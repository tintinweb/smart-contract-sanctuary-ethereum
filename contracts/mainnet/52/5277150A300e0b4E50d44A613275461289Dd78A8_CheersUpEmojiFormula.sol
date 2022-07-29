// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title OnChainRandom
 * @author BaseLabs
 */
contract OnChainRandom {
    uint256 private _seed;
    /**
     * @notice _unsafeRandom is used to generate a random number by on-chain randomness.
     * Please note that on-chain random is potentially manipulated by miners,
     * so VRF is recommended for most security-sensitive scenarios.
     * @return randomly generated number.
     */
    function _unsafeRandom() internal returns (uint256) {
    unchecked {
        _seed++;
        return uint256(keccak256(abi.encodePacked(
                blockhash(block.number - 1),
                block.difficulty,
                block.timestamp,
                block.coinbase,
                _seed,
                tx.origin
            )));
    }
    }
}

/**
 * @title RandomPairs
 * @author BaseLabs
 */
contract RandomPairs is OnChainRandom {
    struct Uint256Pair {
        uint256 key;
        uint256 value;
    }

    function _getPairsValueSum(Uint256Pair[] memory pairs_) internal pure returns (uint256) {
        unchecked {
            uint256 totalSize = 0;
            for (uint256 i = 0; i < pairs_.length; i++) {
                totalSize += pairs_[i].value;
            }
            return totalSize;
        }
    }

    /**
     * @notice _genRandKeyByPairsWithSize is used to randomly generate a key
     * according to the probability configuration.
     * @param pairs_ the probability configuration.
     * @param totalSize_ the sum probabilities.
     * @return the key.
     */
    function _genRandKeyByPairsWithSize(Uint256Pair[] memory pairs_, uint256 totalSize_) internal returns (uint256) {
        unchecked {
            if (pairs_.length == 1) {
                return pairs_[0].key;
            }
            uint256 entropy = _unsafeRandom() % totalSize_;
            uint256 step = 0;
            for (uint256 i = 0; i < pairs_.length; i++) {
                step += pairs_[i].value;
                if (entropy < step) {
                    return pairs_[i].key;
                }
            }
            revert("unreachable code");
        }
    }

    /**
     * @notice _genRandKeyByPairs is used to randomly generate a key
     * according to the probability configuration.
     * @param pairs_ the probability configuration.
     * @return the key.
     */
    function _genRandKeyByPairs(Uint256Pair[] memory pairs_) internal returns (uint256) {
        return _genRandKeyByPairsWithSize(pairs_, _getPairsValueSum(pairs_));
    }
}



/**
 * @title IExtendableERC1155
 * @author BaseLabs
 */
abstract contract IExtendableERC1155 is IERC1155 {
    /**
     * @dev Transfers `amount_` tokens of token type `id_` from `from_` to `to`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - `from_` must have a balance of tokens of type `id_` of at least `amount`.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawSafeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     * Emits a {TransferBatch} event.
     * Requirements:
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawSafeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Creates `amount_` tokens of token type `id_`, and assigns them to `to_`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawMint(address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawMintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Destroys `amount_` tokens of token type `id_` from `from_`
     * Requirements:
     * - `from_` cannot be the zero address.
     * - `from_` must have at least `amount` tokens of token type `id`.
     */
    function rawBurn(address from_, uint256 id_, uint256 amount_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     */
    function rawBurnBatch(address from_, uint256[] memory ids_, uint256[] memory amounts_) external virtual;

    /**
     * @dev Approve `operator_` to operate on all of `owner_` tokens
     * Emits a {ApprovalForAll} event.
     */
    function rawSetApprovalForAll(address owner_, address operator_, bool approved_) external virtual;
}


/**
 * @title CheersUpEmojiFormula
 * @author BaseLabs
 */
contract CheersUpEmojiFormula is Ownable, RandomPairs, ReentrancyGuard {
    event FormulaCreated(uint256 indexed formulaId);
    event Rerolled(address indexed account, uint256 indexed formulaId, uint256 indexed tokenId);
    struct Formula {
        uint256 startTime;
        uint256 endTime;
        Uint256Pair[] input;
        Uint256Pair[] output;
    }

    IExtendableERC1155 private _basic;
    mapping(uint256 => Formula) private _formulas;

    constructor(address basicAddress_) {
        _basic = IExtendableERC1155(basicAddress_);
    }

    /**
     * @notice use a formula to reroll,
     * it will generate a new token id according to the input and output of the formula, with some randomness
     * @param formulaId_ the id of the formula.
     */
    function reroll(uint256 formulaId_) external nonReentrant {
        (Formula memory formula, bool valid) = getFormula(formulaId_);
        require(valid, "formula is not valid now");
        for (uint256 i = 0; i < formula.input.length; i++) {
            _basic.rawBurn(msg.sender, formula.input[i].key, formula.input[i].value);
        }
        uint256 tokenId = _genRandKeyByPairs(formula.output);
        _basic.rawMint(msg.sender, tokenId, 1, "");
        emit Rerolled(msg.sender, formulaId_, tokenId);
    }

    /**
     * @notice create a new formula.
     * @param formulaId_ the id of the formula, when the id is already in used and the overwrite_ is true,
       the original formula will be overwritten.
     * @param formula_ the config of the formula.
     * @param overwrite_ whether to overwrite the existing formula.
     */
    function setFormula(uint256 formulaId_, Formula calldata formula_, bool overwrite_) external onlyOwner {
        if (!overwrite_) {
            require(_formulas[formulaId_].input.length == 0, "formula id already exists");
        }
        require(formula_.output.length > 0, "formula output is empty");
        require(formula_.input.length > 0, "formula input is empty");
        _formulas[formulaId_] = formula_;
        emit FormulaCreated(formulaId_);
    }

    /**
     * @notice get formula by id.
     * @param formulaId_ the id of the formula.
     * @return formula_ the config of the formula.
     * @return valid_ whether the formula is valid.
     */
    function getFormula(uint256 formulaId_) public view returns (Formula memory formula_, bool valid_) {
        formula_ = _formulas[formulaId_];
        valid_ = isFormulaValid(formula_);
    }

    /**
     * @notice check if the formula is valid.
     * @param formula_ the config of the formula.
     * @return valid_ whether the formula is valid.
     */
    function isFormulaValid(Formula memory formula_) public view returns (bool) {
        if (formula_.input.length == 0 || formula_.output.length == 0) {
            return false;
        }
        if (formula_.endTime > 0 && block.timestamp > formula_.endTime) {
            return false;
        }
        return formula_.startTime > 0 && block.timestamp > formula_.startTime;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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