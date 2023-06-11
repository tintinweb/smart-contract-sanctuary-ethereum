// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IBridgeRouter} from "contracts/amb/interfaces/IBridge.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BridgeHandler} from "contracts/amb/interfaces/BridgeHandler.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenMailer is Ownable {
    address public pool;
    uint256 public slipFee;
    IBridgeRouter public bridgeRouter;

    constructor(address _bridgeRouter, address _pool) {
        bridgeRouter = IBridgeRouter(_bridgeRouter);
        pool = _pool;
    }

    struct Token {
        address tokenAddress;
        string tokenName;
        address priceFeedsAddress;
    }

    mapping(uint8 => Token) public Tokens;

    function updateTokenInfo(
        uint8 _tokenId,
        address _tokenAddress,
        string memory _tokenName,
        address _priceFeedsAddress
    ) external onlyOwner {
        Tokens[_tokenId] = Token({
            tokenAddress: _tokenAddress,
            tokenName: _tokenName,
            priceFeedsAddress: _priceFeedsAddress
        });
    }

    function updateSlipFee(uint256 _slipFee) external onlyOwner {
        slipFee = _slipFee;
    }

    function sendMail(
        uint32 _destinationChainId,
        address _destinationMailbox,
        bytes memory _message
    ) external {
        uint8 _index = 0;
        bytes memory message = abi.encodePacked(_index, _message);

        bridgeRouter.sendViaStorage(
            _destinationChainId,
            _destinationMailbox,
            message
        );
    }

    function sendToken(
        uint32 _destinationChainId,
        address _destinationTokenBox,
        uint8 _tokernId,
        uint256 _tokenAmount
    ) external {
        uint256 _tokenFeeAmount = _getFee(_tokernId, _tokenAmount);
        require(_tokenFeeAmount<=_tokenAmount,"token value too low");
        require(IERC20(Tokens[_tokernId].tokenAddress).transferFrom(msg.sender,pool,_tokenAmount),"token transfer fail !!!");
        //string memory data = StringHelper.formatMessage(Tokens[_tokenName],_tokenAmount,ENSHelper.getName(msg.sender));
        uint8 _index = 1;
        bytes memory message = abi.encodePacked(
            _index,
            _tokernId,
            _tokenAmount - _tokenFeeAmount,
            msg.sender
        );

        bridgeRouter.sendViaStorage(
            _destinationChainId,
            _destinationTokenBox,
            message
        );
    }

    function _getFee(
        uint8 _tokenType,
        uint256 _tokenAmount
    ) internal view returns (uint256 _feeAmount) {
        if (Tokens[_tokenType].priceFeedsAddress == address(0)) {
            uint256 baseFee = (_tokenAmount * 5) / 10000;
            _feeAmount = baseFee > 1 ether / 2 ? baseFee : 1 ether / 2;
        } else {
            // 8 decimal
            int256 tokenPrice = getFromChainLink(_tokenType);

            // uint256 decimalPrice = uint256(tokenPrice * 10**10);
            // baseFee = _tokenAmount*5 * decimalPrice / 10000 * 10**18;

            uint256 baseFee = (_tokenAmount * 5 * uint256(tokenPrice)) / 10 ** 12;
            uint256 _tokenFee = baseFee > 1 ether / 10 ? baseFee : 1 ether / 10;
            _feeAmount = _tokenFee*10**8/uint256(tokenPrice);
        }
    }

    function getFromChainLink(
        uint8 _tokenType
    ) internal view returns (int tokenPrice) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            Tokens[_tokenType].priceFeedsAddress
        );
        (, tokenPrice, , , ) = priceFeed.latestRoundData();
    }
}

contract TokenMailBox is BridgeHandler, Ownable {

    address public pool;

    struct Info {
        uint8 tokenId;
        uint256 tokenAmount;
        address sender;
    }

    struct Token {
        address tokenAddress;
        string tokenName;
    }

    mapping(uint8 => Token) public Tokens;

    function updateTokenInfo(
        uint8 _tokenId,
        string memory _tokenName,
        address _tokenAddress
    ) external onlyOwner {
        Tokens[_tokenId] = Token({
            tokenAddress: _tokenAddress,
            tokenName: _tokenName
        });
    }

    event MessageReceived(
        uint32 indexed sourceChainId,
        address indexed sourceAddress,
        string message
    );
    event TokenMessageReceived(
        uint32 indexed sourceChainId,
        address indexed sourceAddress,
        Info message
    );

    constructor(
        address _bridgeRouter,
        address _pool
    ) BridgeHandler(_bridgeRouter) {
        pool = _pool;
    }

    function handleBridgeImpl(uint32 _sourceChainId,address _sourceAddress,bytes memory _message) internal override {
        uint8 index;
        assembly {
            index := mload(add(_message, 1))
        }

        if (index == 0) {
            emit MessageReceived(_sourceChainId,_sourceAddress,string(_message));
        } else {
            Info memory info = decodeInfo(_message);
            address tokenAddress = Tokens[info.tokenId].tokenAddress;
            require(IERC20(tokenAddress).transferFrom(pool,info.sender,info.tokenAmount),"token transfer fail !!!");
            emit TokenMessageReceived(_sourceChainId, _sourceAddress, info);
        }
    }

    function decodeInfo(
        bytes memory _message
    ) public pure returns (Info memory info) {
        uint8 index; // 1 bytes
        uint8 tokenId; // 1 bytes
        uint256 tokenAmount; // 256 / 8 = 32
        address sender; // 20 bytes
        assembly {
            index := mload(add(_message, 1))
            tokenId := mload(add(_message, 2))
            tokenAmount := mload(add(_message, 34))
            sender := mload(add(_message, 54))
        }
        info.tokenId = tokenId;
        info.tokenAmount = tokenAmount;
        info.sender = sender;
    }
}

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
pragma solidity ^0.8.0;

import {IBridgeHandler} from "contracts/amb/interfaces/IBridge.sol";

abstract contract BridgeHandler is IBridgeHandler {
    error NotFromBridgeRouter(address sender);

    address public bridgeRouter;

    constructor(address _bridgeRouter) {
        bridgeRouter = _bridgeRouter;
    }

    function handleBridge(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != bridgeRouter) {
            revert NotFromBridgeRouter(msg.sender);
        }
        handleBridgeImpl(_sourceChainId, _sourceAddress, _data);
        return IBridgeHandler.handleBridge.selector;
    }

    function handleBridgeImpl(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        internal
        virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum MessageStatus {
    NOT_EXECUTED,
    EXECUTION_FAILED,
    EXECUTION_SUCCEEDED
}

struct Message {
    uint8 version;
    uint64 nonce;
    uint32 sourceChainId;
    address sourceAddress;
    uint32 destinationChainId;
    bytes32 destinationAddress;
    bytes data;
}

interface IBridgeRouter {
    event SentMessage(uint64 indexed nonce, bytes32 indexed msgHash, bytes message);

    function send(uint32 destinationChainId, bytes32 destinationAddress, bytes calldata data)
        external
        returns (bytes32);

    function send(uint32 destinationChainId, address destinationAddress, bytes calldata data)
        external
        returns (bytes32);

    function sendViaStorage(
        uint32 destinationChainId,
        bytes32 destinationAddress,
        bytes calldata data
    ) external returns (bytes32);

    function sendViaStorage(
        uint32 destinationChainId,
        address destinationAddress,
        bytes calldata data
    ) external returns (bytes32);
}

interface IBridgeReceiver {
    event ExecutedMessage(
        uint32 indexed sourceChainId,
        uint64 indexed nonce,
        bytes32 indexed msgHash,
        bytes message,
        bool status
    );

    function executeMessage(
        uint64 slot,
        bytes calldata message,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof,
        bytes32 storageRoot
    ) external;

    function executeMessageFromLog(
        bytes calldata srcSlotTxSlotPack,
        bytes calldata messageBytes,
        bytes32[] calldata receiptsRootProof,
        bytes32 receiptsRoot,
        bytes[] calldata receiptProof, // receipt proof against receipt root
        bytes memory txIndexRLPEncoded,
        uint256 logIndex
    ) external;
}

interface IBridgeHandler {
    function handleBridge(uint32 _sourceChainId, address _sourceAddress, bytes memory _data)
        external
        returns (bytes4);
}