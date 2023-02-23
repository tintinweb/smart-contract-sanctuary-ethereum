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
pragma solidity ^0.8.16;

import "./IPostagePriceModule.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error RefundFailed(address to);
error Paused();
error InsufficentPostagePayment(uint256 postageSent, uint256 postageRequired);

contract EthereumPostalService is Ownable {
    event MailReceived(
        PostalAddress postalAddress,
        string msgHtml,
        address sender,
        bool addressEncrypted,
        bool msgEncrypted,
        bytes2 encryptionPubKey
    );

    struct PostalAddress {
        string addressLine1;
        string addressLine2;
        string city;
        string countryCode;
        string postalOrZip;
        string name;
    }

    modifier pausable() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    IPostagePriceModule public postagePriceModule;
    bytes public encryptionPubKey;
    bool public paused;

    constructor(IPostagePriceModule _postagePriceModule, bytes memory _encryptionPubKey) {
        postagePriceModule = _postagePriceModule;
        encryptionPubKey = _encryptionPubKey;
        paused = false;
    }

    function sendMail(PostalAddress calldata postalAddress, string calldata msgHtml) external payable pausable {
        handlePayment();
        emit MailReceived(postalAddress, msgHtml, msg.sender, false, false, 0x0);
    }

    function sendEncryptedMail(
        PostalAddress calldata postalAddress,
        string calldata msgHtml,
        bool addressEncrypted,
        bool msgEncrypted
    ) external payable pausable {
        handlePayment();
        emit MailReceived(postalAddress, msgHtml, msg.sender, addressEncrypted, msgEncrypted, bytes2(encryptionPubKey));
    }

    function handlePayment() internal {
        uint256 weiRequired = postagePriceModule.getPostageWei();
        if (msg.value < weiRequired) {
            revert InsufficentPostagePayment(msg.value, weiRequired);
        }

        if (msg.value > weiRequired) {
            uint256 weiReturn = msg.value - weiRequired;
            bool refunded = payable(address(msg.sender)).send(weiReturn);
            if (!refunded) {
                revert RefundFailed(msg.sender);
            }
        }
    }

    function getPostageWei() public view returns (uint256) {
        return postagePriceModule.getPostageWei();
    }

    // Admin functionality
    function updatePostagePriceModule(IPostagePriceModule newPostagePriceModule) external onlyOwner {
        postagePriceModule = newPostagePriceModule;
    }

    function updateEncryptionPubKey(bytes memory newEncryptionPubKey) external onlyOwner {
        encryptionPubKey = newEncryptionPubKey;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPostagePriceModule {
    function getPostageWei() external view returns (uint256);
}