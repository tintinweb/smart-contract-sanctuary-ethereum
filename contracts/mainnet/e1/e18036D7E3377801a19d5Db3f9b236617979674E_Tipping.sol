// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

  function latestRoundData()
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity 0.8.17;

enum AssetType {
    Coin,
    Token,
    NFT,
    ERC1155
}

/**
* Percentage - constant percentage, e.g. 1% of the msg.value
* PercentageOrConstantMaximum - get msg.value percentage, or constant dollar value, depending on what is bigger
* Constant - constant dollar value, e.g. $1 - uses price Oracle
*/
enum FeeType {
    Percentage,
    PercentageOrConstantMaximum,
    Constant
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AssetType } from "../enums/IDrissEnums.sol";

interface ITipping {
    function sendTo(
        address _recipient,
        uint256 _amount,
        string memory _message
    ) external payable;

    function sendTokenTo(
        address _recipient,
        uint256 _amount,
        address _tokenContractAddr,
        string memory _message
    ) external payable;

    function sendERC721To(
        address _recipient,
        uint256 _assetId,
        address _nftContractAddress,
        string memory _message
    ) external payable;

    function sendERC1155To(
        address _recipient,
        uint256 _assetId,
        uint256 _amount,
        address _nftContractAddress,
        string memory _message
    ) external payable;

    function withdraw() external;

    function withdrawToken(address _tokenContract) external;

    function addAdmin(address _adminAddress) external;

    function deleteAdmin(address _adminAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Batchable
 * @author Rafał Kalinowski <[email protected]>
 * @dev This is BoringBatchable based function with a small twist: because delgatecall passes msg.value
 *      on each call, it may introduce double spending issue. To avoid that, we handle cases when msg.value matters separately.
 *      Please note that you'll have to pass msg.value in amount field for native currency per each call
 *      Additionally, please keep in mind that currently you cannot put payable and nonpayable calls in the same batch -
 *      - nonpayable functions will revert when receiving money
 */
abstract contract Batchable {
    uint256 internal _MSG_VALUE;
    uint256 internal constant _BATCH_NOT_ENTERED = 1;
    uint256 internal constant _BATCH_ENTERED = 2;
    uint256 internal _batchStatus;

    error BatchError(bytes innerError);

    constructor() {
        _batchStatus = _BATCH_NOT_ENTERED;
    }

    /**
    * @notice This function allows batched call to self (this contract).
    * @param _calls An array of inputs for each call.
    * @dev - it sets _MSG_VALUE variable for a call, if function is payable
     *       check if the function is payable is done in your implementation of function `isMsgValueOverride()`
     *       and _MSG_VALUE is set based on your `calculateMsgValueForACall()` implementation
    */
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is used on the same contract, and there is reentrancy guard in place
    function batchCall(bytes[] calldata _calls) internal {
        // bacause we already have reentrancy guard for functions, we set second kind of reentrancy guard
        require(_batchStatus != _BATCH_ENTERED, "ReentrancyGuard: reentrant call");
        uint256 msgValueSentAcc;

        _batchStatus = _BATCH_ENTERED;

        for (uint256 i = 0; i < _calls.length; i++) {
            bool success;
            bytes memory result;
            bytes memory data = _calls[i];
            bytes4 sig;

            assembly {
                sig := mload(add(data, add(0x20, 0)))
            }

            // set proper msg.value for payable function, as delegatecall can introduce double spending
            if (isMsgValueOverride(sig)) {
                uint256 currentCallPriceAmount = calculateMsgValueForACall(sig, data);

                _MSG_VALUE = currentCallPriceAmount;
                msgValueSentAcc += currentCallPriceAmount;

                require (msgValueSentAcc <= msg.value, "Can't send more than msg.value");

                (success, result) = address(this).delegatecall(data);

                _MSG_VALUE = 0;
            } else {
                (success, result) = address(this).delegatecall(data);
            }

            if (!success) {
                _getRevertMsg(result);
            }
        }

        _batchStatus = _BATCH_NOT_ENTERED;
    }

    /**
    * @notice This is part of BoringBatchable contract
    *         https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
    * @dev Helper function to extract a useful revert message from a failed call.
    * If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    */
    function _getRevertMsg(bytes memory _returnData) internal pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert BatchError(_returnData);

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    /**
    * @notice Checks if a function is payable, i.e. should _MSG_VALUE be set
    * @param _selector function selector
    * @dev Write your logic checking if a function is payable, e.g. this.<function-name>.selector == _selector
    *      WARNING - if you, or someone else if able to construct the same selector for a malicious function (which is not that hard),
    *      the logic may break and the msg.value may be exploited
    */
    function isMsgValueOverride(bytes4 _selector) virtual pure internal returns (bool);

    /**
    * @notice Calculates msg.value that should be sent with a call
    * @param _selector function selector
    * @param _calldata single call encoded data
    * @dev You should probably decode function parameters and check what value should be passed
    */
    function calculateMsgValueForACall(bytes4 _selector, bytes memory _calldata) virtual view internal returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { AssetType, FeeType } from "../enums/IDrissEnums.sol";

/**
 * @title FeeCalculator
 * @author Rafał Kalinowski <[email protected]>
 * @notice This is an utility contract for calculating a fee
 */
contract FeeCalculator is Ownable {
    AggregatorV3Interface internal immutable MATIC_USD_PRICE_FEED;
    uint256 public constant PAYMENT_FEE_SLIPPAGE_PERCENT = 5;
    uint256 public PAYMENT_FEE_PERCENTAGE = 10;
    uint256 public PAYMENT_FEE_PERCENTAGE_DENOMINATOR = 1000;
    uint256 public MINIMAL_PAYMENT_FEE = 1;
    uint256 public MINIMAL_PAYMENT_FEE_DENOMINATOR = 1;
    // you have to pass your desired fee types in a constructor deriving this contract
    mapping (AssetType => FeeType) FEE_TYPE_MAPPING;

    constructor(address _maticUsdAggregator) {
        require(_maticUsdAggregator != address(0), "Address cannot be 0");

        MATIC_USD_PRICE_FEED = AggregatorV3Interface(_maticUsdAggregator);
    }

    /*
    * @notice Get current amount of wei in a dollar
    * @dev ChainLink officially supports only USD -> MATIC,
    *      so we have to convert it back to get current amount of wei in a dollar
    */
    function _dollarToWei() internal view returns (uint256) {
        (,int256 maticPrice,,,) = MATIC_USD_PRICE_FEED.latestRoundData();
        require (maticPrice > 0, "Unable to retrieve MATIC price.");

        uint256 maticPriceMultiplier = 10**MATIC_USD_PRICE_FEED.decimals();

        return(10**18 * maticPriceMultiplier) / uint256(maticPrice);
    }

    /**
     * @notice Calculates payment fee
     * @param _value - payment value
     * @param _assetType - asset type, required as ERC20 & ERC721 only take minimal fee
     * @return fee - processing fee, few percent of slippage is allowed
     */
    function getPaymentFee(uint256 _value, AssetType _assetType) public view returns (uint256) {
        uint256 minimumPaymentFee = _getMinimumFee();
        uint256 percentageFee = _getPercentageFee(_value);
        FeeType feeType = FEE_TYPE_MAPPING[_assetType];
        if (feeType == FeeType.Constant) {
            return minimumPaymentFee;
        } else if (feeType == FeeType.Percentage) {
            return percentageFee;
        }

        // default case - PercentageOrConstantMaximum
        if (percentageFee > minimumPaymentFee) return percentageFee; else return minimumPaymentFee;
    }

    function _getMinimumFee() internal view returns (uint256) {
        return (_dollarToWei() * MINIMAL_PAYMENT_FEE) / MINIMAL_PAYMENT_FEE_DENOMINATOR;
    }

    function _getPercentageFee(uint256 _value) internal view returns (uint256) {
        return (_value * PAYMENT_FEE_PERCENTAGE) / PAYMENT_FEE_PERCENTAGE_DENOMINATOR;
    }

    /**
     * @notice Calculates value of a fee from sent msg.value
     * @param _valueToSplit - payment value, taken from msg.value
     * @param _assetType - asset type, as there may be different calculation logic for each type
     * @return fee - processing fee, few percent of slippage is allowed
     * @return value - payment value after substracting fee
     */
    function _splitPayment(uint256 _valueToSplit, AssetType _assetType) internal view returns (uint256 fee, uint256 value) {
        uint256 minimalPaymentFee = _getMinimumFee();
        uint256 paymentFee = getPaymentFee(_valueToSplit, _assetType);

        // we accept slippage of matic price if fee type is not percentage - it this case we always get % no matter dollar price
        if (FEE_TYPE_MAPPING[_assetType] != FeeType.Percentage
            && _valueToSplit >= minimalPaymentFee * (100 - PAYMENT_FEE_SLIPPAGE_PERCENT) / 100
            && _valueToSplit <= minimalPaymentFee) {
            fee = _valueToSplit;
        } else {
            fee = paymentFee;
        }

        require (_valueToSplit >= fee, "Value sent is smaller than minimal fee.");

        value = _valueToSplit - fee;
    }


    /**
    * @notice adjust payment fee percentage for big native currenct transfers
    * @dev Solidity is not good when it comes to handling floats. We use denominator then,
    *      e.g. to set payment fee to 1.5% , just pass paymentFee = 15 & denominator = 1000 => 15 / 1000 = 0.015 = 1.5%
    */
    function changePaymentFeePercentage (uint256 _paymentFeePercentage, uint256 _paymentFeeDenominator) external onlyOwner {
        require(_paymentFeePercentage > 0, "Payment fee has to be bigger than 0");
        require(_paymentFeeDenominator > 0, "Payment fee denominator has to be bigger than 0");

        PAYMENT_FEE_PERCENTAGE = _paymentFeePercentage;
        PAYMENT_FEE_PERCENTAGE_DENOMINATOR = _paymentFeeDenominator;
    }

    /**
    * @notice adjust minimal payment fee for all asset transfers
    * @dev Solidity is not good when it comes to handling floats. We use denominator then,
    *      e.g. to set minimal payment fee to 2.2$ , just pass paymentFee = 22 & denominator = 10 => 22 / 10 = 2.2
    */
    function changeMinimalPaymentFee (uint256 _minimalPaymentFee, uint256 _paymentFeeDenominator) external onlyOwner {
        require(_minimalPaymentFee > 0, "Payment fee has to be bigger than 0");
        require(_paymentFeeDenominator > 0, "Payment fee denominator has to be bigger than 0");

        MINIMAL_PAYMENT_FEE = _minimalPaymentFee;
        MINIMAL_PAYMENT_FEE_DENOMINATOR = _paymentFeeDenominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title MultiAssetSender
 * @author Rafał Kalinowski <[email protected]>
 * @notice This is an utility contract for sending different kind of assets
 * @dev Please note that you should make reentrancy check yourself
 */
contract MultiAssetSender {

    constructor() { }

    /**
    * @notice Wrapper for sending native Coin via call function
    * @dev When using this function please make sure to not send it to anyone, verify the
    *      address in IDriss registry
    */
    function _sendCoin (address _to, uint256 _amount) internal {
        (bool sent, ) = payable(_to).call{value: _amount}("");
        require(sent, "Failed to send");
    }

    /**
     * @notice Wrapper for sending single ERC1155 asset 
     * @dev due to how approval in ERC1155 standard is handled, the smart contract has to ask for permissions to manage
     *      ALL tokens "for simplicity"... Hence, it has to be done before calling function that transfers the token
     *      to smart contract, and revoked afterwards
     */
    function _sendERC1155AssetBatch (
        uint256[] memory _assetIds,
        uint256[] memory _amounts,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC1155 nft = IERC1155(_contractAddress);
        nft.safeBatchTransferFrom(_from, _to, _assetIds, _amounts, "");
    }

    /**
     * @notice Wrapper for sending multiple ERC1155 assets
     * @dev due to how approval in ERC1155 standard is handled, the smart contract has to ask for permissions to manage
     *      ALL tokens "for simplicity"... Hence, it has to be done before calling function that transfers the token
     *      to smart contract, and revoked afterwards
     */
    function _sendERC1155Asset (
        uint256 _assetId,
        uint256 _amount,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC1155 nft = IERC1155(_contractAddress);
        nft.safeTransferFrom(_from, _to, _assetId, _amount, "");
    }

    /**
     * @notice Wrapper for sending NFT asset
     */
    function _sendNFTAsset (
        uint256 _assetIds,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC721 nft = IERC721(_contractAddress);
        nft.safeTransferFrom(_from, _to, _assetIds, "");
    }

    /**
     * @notice Wrapper for sending NFT asset with additional checks and iteraton over an array
     */
    function _sendNFTAssetBatch (
        uint256[] memory _assetIds,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        require(_assetIds.length > 0, "Nothing to send");

        IERC721 nft = IERC721(_contractAddress);
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            nft.safeTransferFrom(_from, _to, _assetIds[i], "");
        }
    }

    /**
     * @notice Wrapper for sending ERC20 Token asset with additional checks
     */
    function _sendTokenAsset (
        uint256 _amount,
        address _to,
        address _contractAddress
    ) internal {
        IERC20 token = IERC20(_contractAddress);

        bool sent = token.transfer(_to, _amount);
        require(sent, "Failed to transfer token");
    }

    /**
     * @notice Wrapper for sending ERC20 token from specific account with additional checks and iteraton over an array
     */
    function _sendTokenAssetFrom (
        uint256 _amount,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC20 token = IERC20(_contractAddress);

        bool sent = token.transferFrom(_from, _to, _amount);
        require(sent, "Failed to transfer token");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { ITipping } from "./interfaces/ITipping.sol";
import { MultiAssetSender } from "./libs/MultiAssetSender.sol";
import { FeeCalculator } from "./libs/FeeCalculator.sol";
import { Batchable } from "./libs/Batchable.sol";

import { AssetType, FeeType } from "./enums/IDrissEnums.sol";

error tipping__withdraw__OnlyAdminCanWithdraw();

/**
 * @title Tipping
 * @author Lennard (lennardevertz)
 * @custom:contributor Rafał Kalinowski <[email protected]>
 * @notice Tipping is a helper smart contract used for IDriss social media tipping functionality
 */
contract Tipping is Ownable, ITipping, MultiAssetSender, FeeCalculator, Batchable, IERC165 {
    address public contractOwner;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public admins;

    event TipMessage(
        address indexed recipientAddress,
        string message,
        address indexed sender,
        address indexed tokenAddress
    );

    constructor(address _maticUsdAggregator) FeeCalculator(_maticUsdAggregator) {
        admins[msg.sender] = true;

        FEE_TYPE_MAPPING[AssetType.Coin] = FeeType.Percentage;
        FEE_TYPE_MAPPING[AssetType.Token] = FeeType.Percentage;
        FEE_TYPE_MAPPING[AssetType.NFT] = FeeType.Constant;
        FEE_TYPE_MAPPING[AssetType.ERC1155] = FeeType.Constant;
    }

    /**
     * @notice Send native currency tip, charging a small fee
     */
    function sendTo(
        address _recipient,
        uint256, // amount is used only for multicall
        string memory _message
    ) external payable override {
        uint256 msgValue = _MSG_VALUE > 0 ? _MSG_VALUE : msg.value;
        (, uint256 paymentValue) = _splitPayment(msgValue, AssetType.Coin);
        _sendCoin(_recipient, paymentValue);

        emit TipMessage(_recipient, _message, msg.sender, address(0));
    }

    /**
     * @notice Send a tip in ERC20 token, charging a small fee
     */
    function sendTokenTo(
        address _recipient,
        uint256 _amount,
        address _tokenContractAddr,
        string memory _message
    ) external payable override {
        (, uint256 paymentValue) = _splitPayment(_amount, AssetType.Token);

        _sendTokenAssetFrom(_amount, msg.sender, address(this), _tokenContractAddr);
        _sendTokenAsset(paymentValue, _recipient, _tokenContractAddr);

        emit TipMessage(_recipient, _message, msg.sender, _tokenContractAddr);
    }

    /**
     * @notice Send a tip in ERC721 token, charging a small $ fee
     */
    function sendERC721To(
        address _recipient,
        uint256 _tokenId,
        address _nftContractAddress,
        string memory _message
    ) external payable override {
        // we use it just to revert when value is too small
        uint256 msgValue = _MSG_VALUE > 0 ? _MSG_VALUE : msg.value;
        _splitPayment(msgValue, AssetType.NFT);

        _sendNFTAsset(_tokenId, msg.sender, _recipient, _nftContractAddress);

        emit TipMessage(_recipient, _message, msg.sender, _nftContractAddress);
    }

    /**
     * @notice Send a tip in ERC721 token, charging a small $ fee
     */
    function sendERC1155To(
        address _recipient,
        uint256 _assetId,
        uint256 _amount,
        address _assetContractAddress,
        string memory _message
    ) external payable override {
        // we use it just to revert when value is too small
        uint256 msgValue = _MSG_VALUE > 0 ? _MSG_VALUE : msg.value;
        _splitPayment(msgValue, AssetType.ERC1155);

        _sendERC1155Asset(_assetId, _amount, msg.sender, _recipient, _assetContractAddress);

        emit TipMessage(_recipient, _message, msg.sender, _assetContractAddress);
    }

    /**
     * @notice Withdraw native currency transfer fees
     */
    function withdraw() external override onlyAdminCanWithdraw {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw.");
    }

    modifier onlyAdminCanWithdraw() {
        if (admins[msg.sender] != true) {
            revert tipping__withdraw__OnlyAdminCanWithdraw();
        }
        _;
    }

    /**
     * @notice Withdraw ERC20 transfer fees
     */
    function withdrawToken(address _tokenContract)
        external
        override
        onlyAdminCanWithdraw
    {
        IERC20 withdrawTC = IERC20(_tokenContract);
        withdrawTC.transfer(msg.sender, withdrawTC.balanceOf(address(this)));
    }

    /**
     * @notice Add admin with priviledged access
     */
    function addAdmin(address _adminAddress)
        external
        override
        onlyOwner
    {
        admins[_adminAddress] = true;
    }

    /**
     * @notice Remove admin
     */
    function deleteAdmin(address _adminAddress)
        external
        override
        onlyOwner
    {
        admins[_adminAddress] = false;
    }

    /**
    * @notice This is a function that allows for multicall
    * @param _calls An array of inputs for each call.
    * @dev calls Batchable::callBatch
    */
    function batch(bytes[] calldata _calls) external payable {
        batchCall(_calls);
    }

    function isMsgValueOverride(bytes4 _selector) override pure internal returns (bool) {
        return
            _selector == this.sendTo.selector ||
            _selector == this.sendTokenTo.selector ||
            _selector == this.sendERC721To.selector ||
            _selector == this.sendERC1155To.selector
        ;
    }

    function calculateMsgValueForACall(bytes4 _selector, bytes memory _calldata) override view internal returns (uint256) {
        uint256 currentCallPriceAmount;

        if (_selector == this.sendTo.selector) {
            assembly {
                currentCallPriceAmount := mload(add(_calldata, 68))
            }
        } else if (_selector == this.sendTokenTo.selector) {
            currentCallPriceAmount = getPaymentFee(0, AssetType.Token);
        } else if (_selector == this.sendTokenTo.selector) {
            currentCallPriceAmount = getPaymentFee(0, AssetType.NFT);
        } else {
            currentCallPriceAmount = getPaymentFee(0, AssetType.ERC1155);
        }

        return currentCallPriceAmount;
    }

    /*
    * @notice Always reverts. By default Ownable supports renouncing ownership, that is setting owner to address 0.
    *         However in this case it would disallow receiving payment fees by anyone.
    */
    function renounceOwnership() public override view onlyOwner {
        revert("Operation not supported");
    }

    /**
     * @notice ERC165 interface function implementation, listing all supported interfaces
     */
    function supportsInterface (bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
         || interfaceId == type(ITipping).interfaceId;
    }
}