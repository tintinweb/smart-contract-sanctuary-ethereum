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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOracle.sol";
import "../interfaces/ITokenURIBuilder.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ConditionalTokenLibrary } from "../libraries/ConditionalTokenLibrary.sol";

interface IConditionalTokens {
    function prepareCondition(bytes32 _questionId, uint256 _outcomeSlotCount) external;

    function reportPayouts(bytes32 _questionId, uint256[] calldata _payouts) external;

    function splitPosition(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _amount,
        uint8 _decimalOffset
    ) external;

    function splitPositionETH(
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external payable;

    function mergePositions(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _amount,
        uint8 _decimalOffset
    ) external;

    function mergePositionsETH(
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _amount,
        uint8 _decimalOffset
    ) external payable;

    function redeemPositions(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _indexSets,
        uint256 _decimalOffset
    ) external;

    function redeemPositionsETH(
        bytes32 _conditionId,
        uint256[] calldata _indexSets,
        uint256 _decimalOffset
    ) external payable;

    function allowedOracle(address _oracle) external view returns (bool);

    function getOutcomeSlotCount(bytes32 _conditionId) external view returns (uint256);

    function getCondition(bytes32 _conditionId)
        external
        view
        returns (ConditionalTokenLibrary.Condition memory);

    function getCollection(bytes32 _collectionId)
        external
        view
        returns (ConditionalTokenLibrary.Collection memory);

    function getPosition(uint256 _positionId)
        external
        view
        returns (ConditionalTokenLibrary.Position memory);

    function payoutNumerators(bytes32 _conditionId, uint256) external view returns (uint256);

    function payoutDenominator(bytes32 _conditionId) external view returns (uint256);

    function decimals(uint256 _positionId) external view returns (uint256);

    function getConditionId(
        address _oracle,
        bytes32 _questionId,
        uint256 _outcomeSlotCount
    ) external pure returns (bytes32);

    function getCollectionId(
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256 _indexSet
    ) external view returns (bytes32);

    function getPositionId(
        IERC20 _collateralToken,
        bytes32 _collectionId,
        uint256 _decimalOffset
    ) external pure returns (uint256);

    function setAllowedOracle(address _oracle, bool _isAllowed) external;

    function setRoyaltyReceiver(address _royaltyReceiver) external;

    function setTokenURIBuilder(ITokenURIBuilder _tokenURIBuilder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEACAggregator {
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/PredictFinanceOracleLibrary.sol";
import "../libraries/ConditionalTokenLibrary.sol";

interface IImageURIBuilder {
    function tokenTitle(
        PredictFinanceOracleLibrary.QuestionDetail memory _questionDetail,
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);

    function imageURI(
        PredictFinanceOracleLibrary.QuestionDetail memory _questionDetail,
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ConditionalTokenLibrary } from "../libraries/ConditionalTokenLibrary.sol";
import { PredictFinanceOracleLibrary } from "../libraries/PredictFinanceOracleLibrary.sol";

interface IOracle {
    event QuestionCreated(
        bytes32 questionId,
        string title,
        string description,
        bytes32[] data,
        bytes32[] outcomes,
        uint128 deadline
    );

    function name() external view returns (string memory);

    function getQuestion(bytes32 _questionId)
        external
        view
        returns (PredictFinanceOracleLibrary.QuestionDetail memory);

    function tokenTitle(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);

    function imageURI(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);

    function canSplit(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external view returns (bool);

    function canMerge(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external view returns (bool);

    function canConvertDecimalOffset(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256 _indexSet,
        uint8 _fromDecimalOffset,
        uint8 _toDecimalOffset
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/ConditionalTokenLibrary.sol";

interface ITokenURIBuilder {
    function tokenURI(
        ConditionalTokenLibrary.Condition memory _condition,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Position memory _position,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOracle.sol";

library ConditionalTokenLibrary {
    struct Condition {
        IOracle oracle;
        bytes32 questionId;
        uint256 outcomeSlotCount;
    }

    struct Collection {
        bytes32 parentCollectionId;
        bytes32 conditionId;
        uint256 indexSet;
    }

    struct Position {
        IERC20 collateralToken;
        bytes32 collectionId;
        uint8 decimalOffset;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PredictFinanceOracleLibrary {
    enum DataType {
        BYTES32,
        STRING,
        UINT256,
        BOOL
    }

    struct QuestionDetail {
        bool resolved;
        bytes32[] data;
        bytes32[] outcomes;
        uint256[] payouts;
        DataType dataType;
        DataType outcomesType;
        uint128 deadline;
        string title;
        string description;
        string[3] categories;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IOracle.sol";
import "../../interfaces/IEACAggregator.sol";
import "../../interfaces/IConditionalTokens.sol";
import "../../interfaces/IImageURIBuilder.sol";
import "../../libraries/PredictFinanceOracleLibrary.sol";
import "../../SupportedTokenList.sol";

contract PredictFinanceOfficialOracle is IOracle, Ownable {
    IConditionalTokens public immutable ct;
    IImageURIBuilder public imageURIBuilder;
    string public name;

    bool public isUnlimitedIndexSet;
    mapping(bytes32 => PredictFinanceOracleLibrary.QuestionDetail) public questionDetails;

    // conditionId -> ERC20 -> decimalOffset
    mapping(bytes32 => mapping(IERC20 => mapping(uint256 => bool)))
        public supportedCollateralTokens;

    constructor(address _ct, string memory _name) {
        ct = IConditionalTokens(_ct);
        name = _name;
    }

    function populationCount(uint256 _n) internal pure returns (uint256 count) {
        for (count = 0; _n != 0; count++) {
            _n &= (_n - 1);
        }
    }

    function checkIndexSet(uint256[] memory _partition, uint256 _outcomeSlotCount)
        internal
        view
        returns (bool)
    {
        if (_partition.length == _outcomeSlotCount) {
            return true;
        }
        if (!isUnlimitedIndexSet) {
            if (_partition.length > 2) {
                return false;
            }
            uint256 popCount = populationCount(_partition[0]);
            return (popCount == 1) || (popCount == _outcomeSlotCount - 1);
        }
        return true;
    }

    function getQuestion(bytes32 _questionId)
        public
        view
        returns (PredictFinanceOracleLibrary.QuestionDetail memory)
    {
        return questionDetails[_questionId];
    }

    function createCondition(
        bytes32 _questionId,
        string memory _title,
        string memory _description,
        bytes32[] memory _outcomes,
        string[3] memory _categories,
        uint128 _deadline
    ) public onlyOwner {
        require(
            questionDetails[_questionId].deadline == 0,
            "PredictFinanceOfficialOracle::QuestionId Already Existed"
        );
        require(_deadline > block.timestamp, "PredictFinanceOfficialOracle::Invalid Deadline");

        PredictFinanceOracleLibrary.QuestionDetail
            memory QuestionDetail = PredictFinanceOracleLibrary.QuestionDetail({
                title: _title,
                description: _description,
                outcomes: _outcomes,
                data: new bytes32[](0),
                payouts: new uint256[](0),
                categories: _categories,
                dataType: PredictFinanceOracleLibrary.DataType.STRING,
                outcomesType: PredictFinanceOracleLibrary.DataType.STRING,
                deadline: _deadline,
                resolved: false
            });

        ct.prepareCondition(_questionId, _outcomes.length);

        questionDetails[_questionId] = QuestionDetail;

        emit QuestionCreated(
            _questionId,
            _title,
            QuestionDetail.description,
            QuestionDetail.data,
            QuestionDetail.outcomes,
            QuestionDetail.deadline
        );
    }

    function resolve(bytes32 _questionId, uint256[] memory _payouts) public onlyOwner {
        PredictFinanceOracleLibrary.QuestionDetail storage questionDetail = questionDetails[
            _questionId
        ];

        questionDetail.resolved = true;
        questionDetail.payouts = _payouts;

        ct.reportPayouts(_questionId, _payouts);
    }

    function tokenTitle(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) public view returns (string memory) {
        return
            imageURIBuilder.tokenTitle(
                questionDetails[_condition.questionId],
                _position,
                _collection,
                _condition,
                _positionId,
                _decimals
            );
    }

    function imageURI(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) public view returns (string memory) {
        return
            imageURIBuilder.imageURI(
                questionDetails[_condition.questionId],
                _position,
                _collection,
                _condition,
                _positionId,
                _decimals
            );
    }

    function canSplit(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external view returns (bool) {
        ConditionalTokenLibrary.Condition memory condition = ct.getCondition(_conditionId);
        return
            questionDetails[condition.questionId].deadline > block.timestamp &&
            supportedCollateralTokens[condition.questionId][_collateralToken][_decimalOffset] &&
            checkIndexSet(_partition, condition.outcomeSlotCount) &&
            _parentCollectionId == bytes32(0);
    }

    function canMerge(
        IERC20,
        bytes32,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8
    ) external view returns (bool) {
        ConditionalTokenLibrary.Condition memory condition = ct.getCondition(_conditionId);
        return
            isUnlimitedIndexSet ||
            (_partition.length == 2 &&
                _partition[0] + _partition[1] == 2**condition.outcomeSlotCount - 1) ||
            (_partition.length == condition.outcomeSlotCount); // Further check will be handled in mergePositions
    }

    function canConvertDecimalOffset(
        IERC20 _collateralToken,
        bytes32,
        bytes32 _conditionId,
        uint256,
        uint8,
        uint8 _toDecimalOffset
    ) external view returns (bool) {
        ConditionalTokenLibrary.Condition memory condition = ct.getCondition(_conditionId);
        return supportedCollateralTokens[condition.questionId][_collateralToken][_toDecimalOffset];
    }

    function setImageURIBuilder(IImageURIBuilder _newImageURIBuilder) external onlyOwner {
        imageURIBuilder = _newImageURIBuilder;
    }

    function setSupportedCollateralToken(
        bytes32 _questionId,
        IERC20 _token,
        uint256 _decimalOffset,
        bool _enabled
    ) external onlyOwner {
        supportedCollateralTokens[_questionId][_token][_decimalOffset] = _enabled;
    }

    function setUnlimitedIndexSet(bool _enabled) external onlyOwner {
        isUnlimitedIndexSet = _enabled;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SupportedTokenList is Ownable {
    event AddToken(address token, string symbol);

    mapping(address => string) public tokenList;

    function add(address _token, string memory _symbol) public onlyOwner {
        tokenList[_token] = _symbol;
    }

    function get(address _token) public view returns (string memory) {
        string memory symbol = tokenList[_token];
        if (bytes(symbol).length == 0) {
            return "Unknown";
        }
        return symbol;
    }
}