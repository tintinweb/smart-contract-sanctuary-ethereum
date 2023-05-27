// SPDX-License-Identifier: BUSL-1.1

/**
 *
 * @title ArrngController.sol. Core contract for arrng, the world's first
 * pirate themed multi-chain off-chain RNG generator with full
 * on-chain storage of data and signatures.
 *
 * No subscriptions, ERC20 tokens or funds held in escrow.
 *
 * No confusing parameters and hashes. Pay in native token for the
 * randomness you need.
 *
 * @author arrng https://arrng.xyz/
 *
 */

pragma solidity 0.8.19;

import {IArrngController} from "./IArrngController.sol";
import {IArrngConsumer} from "../consumer/IArrngConsumer.sol";
import {IENSReverseRegistrar} from "../ENS/IENSReverseRegistrar.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ArrngController is IArrngController, Ownable, IERC721Receiver {
  using Strings for uint256;

  // Native token required for gas cost to serve RNG:
  uint256 public minimumNativeToken;

  // Address of the oracle:
  address payable public firstMate;

  // Address of the treasury
  address payable public strongbox;

  // Request ID:
  uint256 public skirmishID;

  // Limit on number of returned numbers:
  uint256 public maximumNumberOfNumbers;

  // Address of the ENS reverse registrar to allow assignment of an ENS
  // name to this contract:
  IENSReverseRegistrar public ensLog;

  event ENSLogLoggedInTheCaptainsLogOfLogsMatey(address newENSReverseRegistrar);
  event ColoursNailedToTheMastMatey(string ensName, bytes32 ensNameHash);
  event SmallestTreasureChestSetMatey(uint256 minimumNativeToken);
  event MostNumbersYeCanGetSetMatey(uint256 newNumberLimited);
  event YarrrOfficerOnDeckMatey(address oracle);
  event XMarksTheSpot(address treasury);
  event ArrngRequest(
    address indexed caller,
    uint64 indexed requestId,
    uint32 method,
    uint64 numberOfNumbers,
    uint64 minValue,
    uint64 maxvalue,
    uint64 ethValue,
    address refundAddress
  );
  event ArrngResponse(bytes32 requestTxnHash);
  event ArrngServed(
    uint128 indexed requestId,
    uint128 feeCharged,
    uint256[] randomNumbers,
    string apiResponse,
    string apiSignature
  );
  event ArrngRefundInsufficientTokenForGas(
    address indexed caller,
    uint256 requestId
  );

  /**
   *
   * @dev constructor
   *
   * @param captain_: our master/mistress/other pronoun and commander
   *
   */
  constructor(address captain_) {
    _transferOwnership(captain_);
    maximumNumberOfNumbers = 100;
  }

  /**
   * @dev Walks the plank if called by any account other than the cap'n!
   */
  modifier garrCapnOnly() {
    _checkOwner();
    _;
  }

  /**
   * -------------------------------------------------------------
   * @dev CAPTAIN'S CABIN
   * -------------------------------------------------------------
   */

  /**
   *
   * @dev thisDoBeTheENSLog: set the ENS register address
   *
   * @param ensRegistrar_: ENS Reverse Registrar address
   *
   */
  function thisDoBeTheENSLog(address ensRegistrar_) external garrCapnOnly {
    ensLog = IENSReverseRegistrar(ensRegistrar_);
    emit ENSLogLoggedInTheCaptainsLogOfLogsMatey(ensRegistrar_);
  }

  /**
   *
   * @dev nailColoursToTheMast: used to set reverse record so interactions with this contract
   * are easy to identify
   *
   * @param ensName_: string ENS name
   *
   */
  function nailColoursToTheMast(string memory ensName_) external garrCapnOnly {
    bytes32 ensNameHash = ensLog.setName(ensName_);
    emit ColoursNailedToTheMastMatey(ensName_, ensNameHash);
    (ensName_);
  }

  /**
   *
   * @dev thisDoBeTheSmallestTreasureChest: set a new value of required native token for gas
   *
   * @param minGasFee_: the new minimum native token per call
   *
   */
  function thisDoBeTheSmallestTreasureChest(
    uint256 minGasFee_
  ) external garrCapnOnly {
    minimumNativeToken = minGasFee_;
    emit SmallestTreasureChestSetMatey(minGasFee_);
  }

  /**
   *
   * @dev thisDoBeTheMostNumbersYeCanGet: set a new max number of numbers
   *
   * @param maxNumbersPerTxn_: the new max requested numbers
   *
   */
  function thisDoBeTheMostNumbersYeCanGet(
    uint256 maxNumbersPerTxn_
  ) external garrCapnOnly {
    maximumNumberOfNumbers = maxNumbersPerTxn_;
    emit MostNumbersYeCanGetSetMatey(maxNumbersPerTxn_);
  }

  /**
   *
   * @dev thisDoBeTheFirstMate: set a new oracle address
   *
   * @param oracle_: the new oracle address
   *
   */
  function thisDoBeTheFirstMate(address payable oracle_) external garrCapnOnly {
    require(oracle_ != address(0), "Are ye mad me hearty?!");
    firstMate = oracle_;
    emit YarrrOfficerOnDeckMatey(oracle_);
  }

  /**
   *
   * @dev thisDoBeTheStrongbox: set a new treasury address
   *
   * @param treasury_: the new treasury address
   *
   */
  function thisDoBeTheStrongbox(
    address payable treasury_
  ) external garrCapnOnly {
    require(treasury_ != address(0), "Are ye mad me hearty?!");
    strongbox = treasury_;
    emit XMarksTheSpot(treasury_);
  }

  /**
   *
   * @dev getGold: cap'n can pull native token to the strongbox!
   *
   * @param amount_: amount to withdraw
   *
   */
  function getGold(uint256 amount_) external garrCapnOnly {
    require(strongbox != address(0), "Are ye mad me hearty?!");
    processPayment_(strongbox, amount_);
  }

  /**
   *
   * @dev getDubloons: cap'n can pull tokens to the strongbox!
   *
   * @param erc20Address_: the contract address for the token
   * @param amount_: amount to withdraw
   *
   */
  function getDubloons(
    address erc20Address_,
    uint256 amount_
  ) external garrCapnOnly {
    require(strongbox != address(0), "Are ye mad me hearty?!");
    IERC20(erc20Address_).transfer(strongbox, amount_);
  }

  /**
   *
   * @dev getGems: Pull ERC721s (likely only the ENS
   * associated with this contract) to the strongbox.
   *
   * @param erc721Address_: The token contract for the withdrawal
   * @param tokenIDs_: the list of tokenIDs for the withdrawal
   *
   */
  function getGems(
    address erc721Address_,
    uint256[] memory tokenIDs_
  ) external garrCapnOnly {
    require(strongbox != address(0), "Are ye mad me hearty?!");
    for (uint256 i = 0; i < tokenIDs_.length; ) {
      IERC721(erc721Address_).transferFrom(
        address(this),
        strongbox,
        tokenIDs_[i]
      );
      unchecked {
        ++i;
      }
    }
  }

  /**
   *
   * @dev onERC721Received: allow transfer from owner (for the ENS token).
   *
   * @param from_: used to check this is only from the contract owner
   *
   */
  function onERC721Received(
    address,
    address from_,
    uint256,
    bytes memory
  ) external view returns (bytes4) {
    if (from_ == owner()) {
      return this.onERC721Received.selector;
    } else {
      return ("");
    }
  }

  /**
   * -------------------------------------------------------------
   * @dev HOIST THE MAINSAIL!!
   * -------------------------------------------------------------
   */

  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_
  ) external payable returns (uint256 uniqueID_) {
    return requestRandomWords(numberOfNumbers_, tx.origin);
  }

  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_,
    address refundAddress_
  ) public payable returns (uint256 uniqueID_) {
    return requestWithMethod(numberOfNumbers_, 0, 0, refundAddress_, 0);
  }

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_
  ) public payable returns (uint256 uniqueID_) {
    return
      requestRandomNumbersInRange(
        numberOfNumbers_,
        minValue_,
        maxValue_,
        tx.origin
      );
  }

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_
  ) public payable returns (uint256 uniqueID_) {
    return
      requestWithMethod(
        numberOfNumbers_,
        minValue_,
        maxValue_,
        refundAddress_,
        1
      );
  }

  /**
   *
   * @dev requestWithMethod: public method to allow calls specifying the
   * arrng method, allowing functionality to be extensible without
   * requiring a new controller contract
   * requestWithMethod is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param method_: the arrng method to call
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestWithMethod(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    uint32 method_
  ) public payable returns (uint256 uniqueID_) {
    return
      requestWithMethod(
        numberOfNumbers_,
        minValue_,
        maxValue_,
        tx.origin,
        method_
      );
  }

  /**
   *
   * @dev requestWithMethod: public method to allow calls specifying the
   * arrng method, allowing functionality to be extensible without
   * requiring a new controller contract
   * requestWithMethod is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   * @param method_: the arrng method to call
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestWithMethod(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_,
    uint32 method_
  ) public payable returns (uint256 uniqueID_) {
    return
      ahoy_(
        msg.sender,
        msg.value,
        method_,
        numberOfNumbers_,
        minValue_,
        maxValue_,
        refundAddress_
      );
  }

  /**
   *
   * @dev ahoy_: request RNG
   *
   * @param caller_: the msg.sender that has made this call
   * @param payment_: the msg.value sent with the call
   * @param method_: the method for the oracle to execute
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of ununsed native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function ahoy_(
    address caller_,
    uint256 payment_,
    uint256 method_,
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_
  ) internal returns (uint256 uniqueID_) {
    skirmishID += 1;

    if (payment_ < minimumNativeToken) {
      string memory message = string.concat(
        "Insufficient native token for gas, minimum is ",
        minimumNativeToken.toString(),
        ". You may need more depending on the number of numbers requested and prevailing gas cost. All excess refunded, less txn fee."
      );
      require(payment_ >= minimumNativeToken, message);
    }

    require(numberOfNumbers_ > 0, "GarrrNotEnoughNumbers");

    require(numberOfNumbers_ <= maximumNumberOfNumbers, "GarrrTooManyNumbers");

    processPayment_(firstMate, payment_);

    emit ArrngRequest(
      caller_,
      uint64(skirmishID),
      uint32(method_),
      uint64(numberOfNumbers_),
      uint64(minValue_),
      uint64(maxValue_),
      uint64(payment_),
      refundAddress_
    );

    return (skirmishID);
  }

  /**
   *
   * @dev landHo: serve result of the call
   *
   * @param skirmishID_: unique request ID
   * @param ship_: the contract to call
   * @param requestTxnHash_: the txn hash of the original request
   * @param responseCode_: 0 is success, !0 = failure
   * @param barrelONum_: the array of random integers
   * @param refundAddress_: the address for refund of native token not used for gas
   * @param apiResponse_: the response from the off-chain rng provider
   * @param apiSignature_: signature for the rng response
   * @param feeCharged_: the fee for this rng
   *
   */
  function landHo(
    uint256 skirmishID_,
    address ship_,
    bytes32 requestTxnHash_,
    uint256 responseCode_,
    uint256[] calldata barrelONum_,
    address refundAddress_,
    string calldata apiResponse_,
    string calldata apiSignature_,
    uint256 feeCharged_
  ) external payable {
    require(msg.sender == firstMate, "BelayThatFirstMateOnly");
    emit ArrngResponse(requestTxnHash_);
    if (responseCode_ == 0) {
      arrngSuccess_(
        skirmishID_,
        ship_,
        barrelONum_,
        refundAddress_,
        apiResponse_,
        apiSignature_,
        msg.value,
        feeCharged_
      );
    } else {
      arrngFailure_(skirmishID_, ship_, refundAddress_, msg.value);
    }
  }

  /**
   *
   * @dev arrngSuccess_: process a successful response
   * arrng can be requested by a contract call or from an EOA. In the
   * case of a contract call we call the external method that the calling
   * contract must include to perform downstream processing using the rng. In
   * the case of an EOA call this is a user requesting signed, verifiable rng
   * that is stored on-chain (through emitted events), that they intend to use
   * manually. So in the case of the EOA call we emit the results and send them
   * the refund, i.e. no method call.
   *
   * @param skirmishID_: unique request ID
   * @param ship_: the contract to call
   * @param barrelONum_: the array of random integers
   * @param refundAddress_: the address for unused token refund
   * @param apiResponse_: the response from the off-chain rng provider
   * @param apiSignature_: signature for the rng response
   * @param amount_: the amount of unused native toke to refund
   * @param feeCharged_: the fee for this rng
   *
   */
  function arrngSuccess_(
    uint256 skirmishID_,
    address ship_,
    uint256[] calldata barrelONum_,
    address refundAddress_,
    string calldata apiResponse_,
    string calldata apiSignature_,
    uint256 amount_,
    uint256 feeCharged_
  ) internal {
    // Success
    emit ArrngServed(
      uint128(skirmishID_),
      uint128(feeCharged_),
      barrelONum_,
      apiResponse_,
      apiSignature_
    );
    if (ship_.code.length > 0) {
      // If the calling contract is the same as the refund address then return
      // ramdomness and the refund in a single function call:
      if (refundAddress_ == ship_) {
        IArrngConsumer(ship_).yarrrr{value: amount_}(skirmishID_, barrelONum_);
      } else {
        IArrngConsumer(ship_).yarrrr{value: 0}(skirmishID_, barrelONum_);
        processPayment_(refundAddress_, amount_);
      }
    } else {
      // Refund the EOA any native token not used for gas:
      processPayment_(refundAddress_, amount_);
    }
  }

  /**
   *
   * @dev arrngFailure_: process a failed response
   * Refund any native token not used for gas:
   *
   * @param skirmishID_: unique request ID
   * @param ship_: the contract to call
   * @param refundAddress_: the address for the refund
   * @param amount_: the amount for the refund
   *
   */
  function arrngFailure_(
    uint256 skirmishID_,
    address ship_,
    address refundAddress_,
    uint256 amount_
  ) internal {
    // Failure
    emit ArrngRefundInsufficientTokenForGas(ship_, skirmishID_);
    processPayment_(refundAddress_, amount_);
  }

  /**
   *
   * @dev processPayment_: central function for payment processing
   *
   * @param payeeAddress_: address to pay.
   * @param amount_: amount to pay.
   *
   */
  function processPayment_(address payeeAddress_, uint256 amount_) internal {
    (bool success, ) = payeeAddress_.call{value: amount_}("");
    require(success, "TheTransferWalkedThePlank!(failed)");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

pragma solidity 0.8.19;

// Included to allow setting of ENS reverse register for contract:
interface IENSReverseRegistrar {
  function setName(string memory name) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

/**
 *
 * @title IArrngConsumer.sol. Use arrng
 *
 * @author arrng https://arrng.xyz/
 *
 */

pragma solidity 0.8.19;

interface IArrngConsumer {
  /**
   *
   * @dev avast: receive RNG
   *
   * @param skirmishID_: unique ID for this request
   * @param barrelORum_: array of random integers requested
   *
   */
  function yarrrr(
    uint256 skirmishID_,
    uint256[] memory barrelORum_
  ) external payable;
}

// SPDX-License-Identifier: MIT

/**
 *
 * @title IArrngController.sol. Interface for the arrngController.
 *
 * @author arrng https://arrng.xyz/
 *
 */

pragma solidity 0.8.19;

interface IArrngController {
  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_,
    address refundAddress_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestWithMethod: public method to allow calls specifying the
   * arrng method, allowing functionality to be extensible without
   * requiring a new controller contract
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestWithMethod(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_,
    uint32 method_
  ) external payable returns (uint256 uniqueID_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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