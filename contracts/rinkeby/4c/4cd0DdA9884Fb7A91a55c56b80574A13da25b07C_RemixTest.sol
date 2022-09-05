// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Operations} from "./Operations.sol";
import {SafeCast} from "./SafeCast.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract RemixTest is Operations, ReentrancyGuard {
    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    /// @notice List of registered tokens by listingId
    mapping(uint16 => address) public tokenAddresses;

    /// @notice List of registered token type by listingId
    mapping(uint16 => AssetType) public tokenType;

    /// @notice List of liquidity limit by listingId
    mapping(uint16 => uint128) public liquidityLimit;

    /// @notice List of limit per tx by listingId
    mapping(uint16 => uint128) public limitPerTx;

    /// @notice List of registered tokens by address
    mapping(address => uint16) public listingIds;

    /// @notice Paused tokens list, deposits are impossible to create for paused tokens
    mapping(uint16 => bool) public pausedTokens;

    /// @notice The current commited batchId
    uint64 public currentBatchId;

    /// @notice The current commited batchId
    uint64 public currentPendingRequestId;

    /// @notice The current number of pending requests
    uint64 public numberOfPendingRequest;

    /// @notice List of pending deposit records by Id
    mapping(uint64 => PendingDepositRecord) public pendingDepositRecord;

    /// @dev Expiration delta for onchain request to be satisfied (in seconds)
    uint256 internal constant REQUEST_EXPIRATION_PERIOD = 18 days;

    event NewDeposit(
        address from,
        uint32 atherId,
        uint16 listingId,
        uint40 tokenId,
        uint88 amount,
        uint256 newRequestId,
        uint256 currentBatchId
    );

    event NewDepositBatch(
        address from,
        uint32 atherId,
        uint16 listingId,
        uint40[] tokenIds,
        uint88[] amounts,
        uint256 newRequestId,
        uint256 currentBatchId
    );

    /// @notice Token paused status changed
    event TokenPausedUpdate(address indexed token, bool paused);

    /// @notice New token added
    event NewToken(
        address indexed newTokenAddress,
        AssetType newTokenType,
        uint16 indexed newLisitingId,
        uint88 liquidityLimit,
        uint88 limitPerTx
    );

    event SetTokenLimits(
        uint16 indexed listingId,
        uint88 liquidityLimit,
        uint88 limitPerTx
    );

    /// @notice Pause token deposits for the given token
    /// @param _tokenAddr Token address
    /// @param _tokenPaused Token paused status
    function setTokenPaused(address _tokenAddr, bool _tokenPaused) external {
        uint16 listingId = validateTokenAddress(_tokenAddr);
        if (pausedTokens[listingId] != _tokenPaused) {
            pausedTokens[listingId] = _tokenPaused;
            emit TokenPausedUpdate(_tokenAddr, _tokenPaused);
        }
    }

    /// @notice Add token to the list of tokens
    /// @param _tokenAddress Token address
    /// @param _tokenType Token type
    /// @param _limitPerTx Limit amount per tx
    /// @param _liquidityLimit Minimum balance limit of the token on this contract
    /// @param _newListingId Token's listing Id
    function addToken(
        address _tokenAddress,
        AssetType _tokenType,
        uint88 _limitPerTx,
        uint88 _liquidityLimit,
        uint16 _newListingId
    ) external {
        require(_newListingId != 0, "Gov:invalid Id");
        require(listingIds[_tokenAddress] == 0, "Gov:existed token");

        tokenAddresses[_newListingId] = _tokenAddress;
        tokenType[_newListingId] = _tokenType;
        limitPerTx[_newListingId] = _limitPerTx;
        liquidityLimit[_newListingId] = _liquidityLimit;
        emit NewToken(
            _tokenAddress,
            _tokenType,
            _newListingId,
            _liquidityLimit,
            _limitPerTx
        );
    }

    /// @notice Set token limits
    /// @param _listingId listingId of token
    /// @param _limitPerTx limit amount per tx
    /// @param _liquidityLimit minimum balance limit of the token on this contract
    function setTokenLimit(
        uint16 _listingId,
        uint88 _limitPerTx,
        uint88 _liquidityLimit
    ) external {
        limitPerTx[_listingId] = _limitPerTx;
        liquidityLimit[_listingId] = _liquidityLimit;

        emit SetTokenLimits(_listingId, _liquidityLimit, _limitPerTx);
    }

    /// @notice Deposit native token to Sipher portal - transfer ERC20 tokens from user into contract, validate it, register deposit
    /// @param _atherId receiver's address on layer 2
    function depositNativeToken(uint32 _atherId, uint88 _value)
        external
        payable
    {
        Deposit memory deposit = Deposit({
            from: msg.sender,
            atherId: _atherId,
            listingId: 0,
            tokenId: 0,
            amount: _value
        });
        bytes32 _hashDepositRequest = hashDepositRequest(deposit);
        uint256 newRequestId = addPendingRequest(_hashDepositRequest);

        emit NewDeposit(
            msg.sender,
            deposit.atherId,
            deposit.listingId,
            deposit.tokenId,
            deposit.amount,
            newRequestId,
            currentBatchId
        );
    }

    function depositERC20(
        uint32 _atherId,
        uint88 _amount,
        IERC20 _tokenAddress
    ) external nonReentrant {
        uint16 _listingId = validateTokenAddress(address(_tokenAddress));

        Deposit memory deposit = Deposit({
            from: msg.sender,
            atherId: _atherId,
            listingId: _listingId,
            tokenId: 0,
            amount: _amount
        });
        bytes32 _hashDepositRequest = hashDepositRequest(deposit);
        uint256 newRequestId = addPendingRequest(_hashDepositRequest);

        emit NewDeposit(
            msg.sender,
            deposit.atherId,
            deposit.listingId,
            deposit.tokenId,
            deposit.amount,
            newRequestId,
            currentBatchId
        );
    }

    function depositERC721(
        uint32 _atherId,
        uint40 _tokenId,
        IERC721 _tokenAddress
    ) external nonReentrant {
        uint16 listingId = validateTokenAddress(address(_tokenAddress));

        Deposit memory deposit = Deposit({
            from: msg.sender,
            atherId: _atherId,
            listingId: listingId,
            tokenId: _tokenId,
            amount: 1
        });
        bytes32 _hashDepositRequest = hashDepositRequest(deposit);
        uint256 newRequestId = addPendingRequest(_hashDepositRequest);

        emit NewDeposit(
            msg.sender,
            deposit.atherId,
            deposit.listingId,
            deposit.tokenId,
            deposit.amount,
            newRequestId,
            currentBatchId
        );
    }

    function depositERC1155(
        uint32 _atherId,
        uint40 _tokenId,
        uint88 _amount,
        IERC1155 _tokenAddress
    ) external nonReentrant {
        uint16 listingId = validateTokenAddress(address(_tokenAddress));

        Deposit memory deposit = Deposit({
            from: msg.sender,
            atherId: _atherId,
            listingId: listingId,
            tokenId: _tokenId,
            amount: _amount
        });
        bytes32 _hashDepositRequest = hashDepositRequest(deposit);
        uint256 newRequestId = addPendingRequest(_hashDepositRequest);

        emit NewDeposit(
            msg.sender,
            deposit.atherId,
            deposit.listingId,
            deposit.tokenId,
            deposit.amount,
            newRequestId,
            currentBatchId
        );
    }

    function depositBatchERC1155(
        uint32 _atherId,
        IERC1155 _tokenAddress,
        uint40[] calldata _tokenIds,
        uint88[] calldata _amounts
    ) external nonReentrant {
        uint8 _batchLength = SafeCast.toUint8(_tokenIds.length);

        uint16 listingId = validateTokenAddress(address(_tokenAddress));

        require(_tokenIds.length == _amounts.length, "invalid input");

        DepositBatch memory depositBatch = DepositBatch({
            from: msg.sender,
            atherId: _atherId,
            listingId: listingId,
            batchLength: _batchLength,
            tokenIds: _tokenIds,
            amounts: _amounts
        });
        bytes32 _hashDepositBatchRequest = hashDepositBatchRequest(
            depositBatch
        );
        uint256 newRequestId = addPendingRequest(_hashDepositBatchRequest);

        emit NewDepositBatch(
            msg.sender,
            depositBatch.atherId,
            depositBatch.listingId,
            depositBatch.tokenIds,
            depositBatch.amounts,
            newRequestId,
            currentBatchId
        );
    }

    /// @notice Validate if token address is valid
    /// @param _tokenAddr Token address
    /// @return tokens id of valid token
    function validateTokenAddress(address _tokenAddr)
        public
        view
        returns (uint16)
    {
        uint16 listingId = listingIds[_tokenAddr];
        require(listingId != 0, "Gov:invalid token");
        return listingId;
    }

    /// @notice Private function to add new pending request
    function addPendingRequest(bytes32 _hashedRequestData)
        private
        returns (uint64 newRequestId)
    {
        uint256 _expirationTimeStamp = block.timestamp +
            REQUEST_EXPIRATION_PERIOD;
        newRequestId = currentPendingRequestId + numberOfPendingRequest;

        pendingDepositRecord[newRequestId] = PendingDepositRecord({
            hashedRequestData: _hashedRequestData,
            expirationTimeStamp: _expirationTimeStamp
        });
        numberOfPendingRequest++;
    }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

/// @author Ather Labs

import {Bytes} from "./Bytes.sol";

contract Operations {
    /* ------ TYPE & VARIABLES ------ */

    /// @notice All type of requests
    enum RequestType {
        Deposit,
        DepositBatch,
        FullExit,
        FullExitBatch,
        FullExit1155Classic,
        Withdraw,
        WithdrawBatch,
        Withdraw1155Classic
    }

    /// @notice Struct data for Deposit request, support: Native, ERC20, ERC721, ERC1155(Single)
    struct Deposit {
        address from; //L1 address
        uint32 atherId;
        uint16 listingId;
        uint40 tokenId;
        uint88 amount;
    } //42 bytes

    /// @notice Struct data for Deposit Batch request, support: ERC1155(Batch)
    struct DepositBatch {
        address from; //L1 address
        uint32 atherId;
        uint16 listingId;
        uint8 batchLength;
        uint40[] tokenIds;
        uint88[] amounts;
    } //min 59 + n*16 bytes

    /// @notice Struct data for FullExit request, support: Native, ERC20, ERC721, ERC1155(Single)
    struct FullExit {
        address to; //L1 address
        uint32 atherId;
        uint16 listingId;
        uint40 tokenId;
        uint88 amount;
    } // 42 bytes

    /// @notice Struct data for FullBatchExit request, support: ERC1155(Batch)
    struct FullBatchExit {
        address to; //L1 address
        uint32 atherId;
        uint16 listingId;
        uint8 batchLength;
        uint40[] tokenIds;
        uint88[] amounts;
    } // min 59 + n*16 bytes

    /// @notice Struct data for FullBatchExit request, support: Sipher Classic ERC1155 (Single & Batch)
    struct FullExitClassic {
        bytes executeSig;
        address to; //L1 address
        uint32 atherId;
        uint16 listingId;
        uint24 salt;
        uint8 batchLength;
        uint40[] tokenIds;
        uint88[] amounts;
    } // min 127 + n*16 bytes

    ///@notice Struct data for Withdraw request, support: Native, ERC20, ERC721, ERC1155(Single)
    struct Withdraw {
        address to; //L1 address
        uint32 atherId;
        uint16 listingId;
        uint40 tokenId;
        uint88 amount;
    } // 42 bytes

    /// @notice Struct data for WithdrawBatch request, support: ERC1155(Batch)
    struct WithdrawBatch {
        address to; //L1 address
        uint32 atherId;
        uint16 listingId;
        uint8 batchLength;
        uint40[] tokenIds;
        uint88[] amounts;
    } // 59 + n*16 bytes

    /// @notice Struct data for FullBatchExit request, support: Sipher Classic ERC1155 (Single & Batch)
    struct WithdrawClassic {
        bytes executeSig;
        address to; //L1 address
        uint32 atherId;
        uint24 salt; 
        uint16 listingId;
        uint8 batchLength;
        uint88[] amounts;
        uint40[] tokenIds;
    } // min 128 + n*16 bytes

    struct PendingDepositRecord {
        bytes32 hashedRequestData;
        uint256 expirationTimeStamp;
    }

    /// @notice Domain info struct
    struct EIP712Domain {
        uint256 chainId;
        address verifyingContract;
    }

    /// @notice Domain separator follow EIP712
    bytes32 immutable DOMAIN_SEPARATOR;

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    /* ------ CONSTRUCTOR ------ */
    constructor() {
        DOMAIN_SEPARATOR = hashDomain(
            EIP712Domain({
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    /* ------ EXTERNAL FUNTIONS ------ */

    /* ------ PUBLIC FUNTIONS ------ */

    /* ------ INTERNAL FUNTIONS ------ */

    /// @notice Read bytes input to reconstruct the Deposit request data struct
    /// @param _data Data input in bytes
    function readDepositRequest(bytes calldata _data)
        internal
        pure
        returns (Deposit memory deposit)
    {
        uint256 offset;
        (offset, deposit.from) = Bytes.readAddress(_data, offset);
        (offset, deposit.atherId) = Bytes.readUInt32(_data, offset);
        (offset, deposit.listingId) = Bytes.readUInt16(_data, offset);
        (offset, deposit.tokenId) = Bytes.readUInt40(_data, offset);
        (offset, deposit.amount) = Bytes.readUInt88(_data, offset);
        require(offset == 42, "Bytes: invalid length"); //42 bytes
    }

    /// @notice Read bytes input to reconstruct the DepositBatch request data struct
    /// @param _data Data input in bytes
    function readDepositBatchRequest(bytes calldata _data)
        internal
        pure
        returns (DepositBatch memory depositBatch)
    {
        uint256 offset;
        (offset, depositBatch.from) = Bytes.readAddress(_data, offset);
        (offset, depositBatch.atherId) = Bytes.readUInt32(_data, offset);
        (offset, depositBatch.listingId) = Bytes.readUInt16(_data, offset);
        (offset, depositBatch.batchLength) = Bytes.readUint8(_data, offset);
        (offset, depositBatch.tokenIds) = Bytes.readUInt40Array(
            _data,
            offset,
            depositBatch.batchLength
        );
        (offset, depositBatch.amounts) = Bytes.readUInt88Array(
            _data,
            offset,
            depositBatch.batchLength
        );
        require(
            offset == 27 + depositBatch.batchLength * 16,
            "Bytes: invalid length"
        ); //min 59 + (n-1)*16 bytes
    }

    /// @notice Read bytes input to reconstruct the Withdraw request data struct
    /// @param _data Data input in bytes
    function readWithdrawRequest(bytes calldata _data)
        internal
        pure
        returns (Withdraw memory withdraw)
    {
        uint256 offset;
        (offset, withdraw.to) = Bytes.readAddress(_data, offset);
        (offset, withdraw.atherId) = Bytes.readUInt32(_data, offset);
        (offset, withdraw.listingId) = Bytes.readUInt16(_data, offset);
        (offset, withdraw.tokenId) = Bytes.readUInt40(_data, offset);
        (offset, withdraw.amount) = Bytes.readUInt88(_data, offset);
        require(offset == 42, "Bytes: invalid length"); //42 bytes
    }

    /// @notice Read bytes input to reconstruct the WithdrawBatch request data struct
    /// @param _data Data input in bytes
    function readWithdrawBatchRequest(bytes calldata _data)
        internal
        pure
        returns (WithdrawBatch memory withdrawBatch)
    {
        uint256 offset;
        (offset, withdrawBatch.to) = Bytes.readAddress(_data, offset);
        (offset, withdrawBatch.atherId) = Bytes.readUInt32(_data, offset);
        (offset, withdrawBatch.listingId) = Bytes.readUInt16(_data, offset);
        (offset, withdrawBatch.batchLength) = Bytes.readUint8(_data, offset);
        (offset, withdrawBatch.tokenIds) = Bytes.readUInt40Array(
            _data,
            offset,
            withdrawBatch.batchLength
        );
        (offset, withdrawBatch.amounts) = Bytes.readUInt88Array(
            _data,
            offset,
            withdrawBatch.batchLength
        );
        require(
            offset == 43 + withdrawBatch.batchLength * 16,
            "Bytes: invalid length"
        ); //min 59 + (n-1)*16 bytes
    }

    /// @notice Read bytes input to reconstruct the WithdrawClassic request data struct
    /// @param _data Data input in bytes
    function readWithdrawClassicRequest(bytes calldata _data)
        external
        pure
        returns (WithdrawClassic memory withdrawClassic)
    {
        uint256 offset;
        withdrawClassic.executeSig = Bytes.slice(_data, offset, 65);
        offset = 65;
        (offset, withdrawClassic.to) = Bytes.readAddress(_data, offset);
        (offset, withdrawClassic.atherId) = Bytes.readUInt32(_data, offset);
        (offset, withdrawClassic.salt) = Bytes.readUInt24(_data, offset);
        (offset, withdrawClassic.listingId) = Bytes.readUInt16(_data, offset);
        (offset, withdrawClassic.batchLength) = Bytes.readUint8(_data, offset);
        (offset, withdrawClassic.tokenIds) = Bytes.readUInt40Array(
            _data,
            offset,
            withdrawClassic.batchLength
        );
        (offset, withdrawClassic.amounts) = Bytes.readUInt88Array(
            _data,
            offset,
            withdrawClassic.batchLength
        );
        require(
            offset == 112 + withdrawClassic.batchLength * 16,
            "Bytes: invalid length"
        ); //min 128 + (n-1)*16 bytes
    }


    /// @notice Hash the Deposit data struct
    function hashDepositRequest(Deposit memory deposit)
        internal
        view
        returns (bytes32 r)
    {
        r = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR,
                deposit.from,
                deposit.atherId,
                deposit.listingId,
                deposit.tokenId,
                deposit.amount
            )
        );
    }

    /// @notice Hash the DepositBatch data struct
    function hashDepositBatchRequest(DepositBatch memory depositBatch)
        internal
        view
        returns (bytes32 r)
    {
        r = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR,
                depositBatch.from,
                depositBatch.atherId,
                depositBatch.listingId,
                depositBatch.batchLength,
                keccak256(abi.encode(depositBatch.tokenIds)),
                keccak256(abi.encode(depositBatch.amounts))
            )
        );
    }

    /* ------ PRIVATE FUNTIONS ------ */

    function hashDomain(EIP712Domain memory eip712Domain)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "16");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value < 2**88, "11");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "08");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "05");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "04");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "02");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "01");
        return uint8(value);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT OR Apache-2.0


// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
                add(bts, 32), // BYTES_HEADER_SIZE
                data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    // function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
    //     bts = toBytesFromUIntTruncated(uint256(self), 20);
    // }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x5)
    function bytesToUInt40(bytes memory _bytes, uint256 _start) internal pure returns (uint40 r) {
        uint256 offset = _start + 0x5;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x5)
    function bytesToUInt40Array(bytes memory _bytes, uint256 _start, uint8 _arrayLength) internal pure returns (uint40[] memory) {
        uint256 offset = _start + 0x5;
        require(_bytes.length >= offset, "V");
        uint40[] memory r = new uint40[](_arrayLength);
        uint40 n;
        for (uint8 i =0; i < _arrayLength; i++){
            assembly{
                n:= mload(add(_bytes, offset))
            }
            offset = offset + 0x5;
            r[i]=n;
        }
        return r;
    }

    // NOTE: theoretically possible overflow of (_start + 0x8)
    function bytesToUInt64(bytes memory _bytes, uint256 _start) internal pure returns (uint64 r) {
        uint256 offset = _start + 0x8;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 10)
    function bytesToUInt80(bytes memory _bytes, uint256 _start) internal pure returns (uint80 r) {
        uint256 offset = _start + 0xa;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0xa)
    function bytesToUInt80Array(bytes memory _bytes, uint256 _start, uint8 _arrayLength) internal pure returns (uint80[] memory) {
        uint256 offset = _start + 0xa;
        require(_bytes.length >= offset, "V");
        uint80[] memory r = new uint80[](_arrayLength);
        uint80 n;
        for (uint8 i =0; i < _arrayLength; i++){
            assembly{
                n:= mload(add(_bytes, offset))
            }
            offset = offset + 0xa;
            r[i]=n;
        }
        return r;
    }

    // NOTE: theoretically possible overflow of (_start + 0xb)
    function bytesToUInt88(bytes memory _bytes, uint256 _start) internal pure returns (uint88 r) {
        uint256 offset = _start + 0xb;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0xb)
    function bytesToUInt88Array(bytes memory _bytes, uint256 _start, uint8 _arrayLength) internal pure returns (uint88[] memory) {
        uint256 offset = _start + 0xb;
        require(_bytes.length >= offset, "V");
        uint88[] memory r = new uint88[](_arrayLength);
        uint88 n;
        for (uint8 i =0; i < _arrayLength; i++){
            assembly{
                n:= mload(add(_bytes, offset))
            }
            offset = offset + 0xb;
            r[i]=n;
        }
        return r;
    }


    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128Array(bytes memory _bytes, uint256 _start, uint8 _arrayLength) internal pure returns (uint128[] memory) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "V");
        uint128[] memory r = new uint128[](_arrayLength);
        uint128 n;
        for (uint8 i = 0; i < _arrayLength; i++){
            assembly{
                n:= mload(add(_bytes, offset))
            }
            offset = offset + 0x10;
            r[i]=n;
        }
        return r;
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }


    /// Reads byte stream
    /// @return newOffset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 newOffset, bytes memory data) {
        data = slice(_data, _offset, _length);
        newOffset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bool r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint8 r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint16 r) {
        newOffset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint24 r) {
        newOffset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint32 r) {
        newOffset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 5)
    function readUInt40(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint40 r) {
        newOffset = _offset + 5;
        r = bytesToUInt40(_data, _offset);
    }

        // NOTE: theoretically possible overflow of (_offset + 5*arrayLength)
    function readUInt40Array(bytes memory _data, uint256 _offset, uint8 _arrayLength) internal pure returns (uint256 newOffset, uint40[] memory r) {
        newOffset = _offset + 5*_arrayLength;
        r = bytesToUInt40Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 8)
    function readUInt64(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint64 r) {
        newOffset = _offset + 8;
        r = bytesToUInt64(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 10)
    function readUInt80(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint80 r) {
        newOffset = _offset + 10;
        r = bytesToUInt80(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 10*arrayLength)
    function readUInt80Array(bytes memory _data, uint256 _offset, uint8 _arrayLength) internal pure returns (uint256 newOffset, uint80[] memory r) {
        newOffset = _offset + 10*_arrayLength;
        r = bytesToUInt80Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 11)
    function readUInt88(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint88 r) {
        newOffset = _offset + 11;
        r = bytesToUInt88(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 11*arrayLength)
    function readUInt88Array(bytes memory _data, uint256 _offset, uint8 _arrayLength) internal pure returns (uint256 newOffset, uint88[] memory r) {
        newOffset = _offset + 11*_arrayLength;
        r = bytesToUInt88Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint128 r) {
        newOffset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16*_arrayLength)
    function readUInt128Array(bytes memory _data, uint256 _offset, uint8 _arrayLength) internal pure returns (uint256 newOffset, uint128[] memory r) {
        newOffset = _offset + 16*_arrayLength;
        r = bytesToUInt128Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint160 r) {
        newOffset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, address r) {
        newOffset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes20 r) {
        newOffset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes32 r) {
        newOffset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }


    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _newLength) internal pure returns (uint256 r) {
        require(_newLength <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _newLength, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _newLength) * 8);
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
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