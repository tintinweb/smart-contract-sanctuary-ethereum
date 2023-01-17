// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function trustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal virtual {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// https://medium.com/coinmonks/complete-guide-to-meta-transactions-c46ca51dbd21

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
        );

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainID())
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns (bytes32) {
        return domainSeparator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./EIP712Base.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SafeMath.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    event testEvent(address signer, address user, bool res);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version) EIP712Base(name, version) {}

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(
            destinationFunctionSig != msg.sig,
            "functionSignature can not be of executeMetaTransaction method"
        );
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        emit testEvent(userAddress, userAddress, false);
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bool) {
        address signer = ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );

        emit testEvent(signer, user, signer == user);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

//     function recover(
//         uint256 id,
//         uint256 tokenId,
//         uint256 price,
//         uint256 proto,
//         uint256 purity,
//         address seller,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external view returns (address) {
//         return _recover(id, tokenId, price, proto, purity, seller, v, r, s);
//     }

//     function _recover(
//         uint256 id,
//         uint256 tokenId,
//         uint256 price,
//         uint256 proto,
//         uint256 purity,
//         address seller,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) private view returns (address) {
//         return ecrecover(hashSellOrders(id, tokenId, price, proto, purity, seller), v, r, s);
//     }

//     function hashSellOrders(
//         uint256 id,
//         uint256 tokenId,
//         uint256 price,
//         uint256 proto,
//         uint256 purity,
//         address seller
//     ) private view returns (bytes32) {
//         return
//             keccak256(
//                 abi.encodePacked(
//                     "\x19\x01",
//                     domainSeparator,
//                     keccak256(
//                         abi.encode(META_TRANSACTION_TYPEHASH, nonce, from, functionSignature)
//                     )
//                 )
//             );
//     }
// }
//         uint256 nonce;
//         address from;
//         bytes functionSignature;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// SENDTRANSACTION EIP712MetaTransaction("PinataVerify", "1")
import "./HELPER_CONTRACTS/EIP712MetaTransaction.sol";

// import "./HELPER_CONTRACTS/BasicMetaTransaction.sol";

import "@opengsn/contracts/src/ERC2771Recipient.sol";
// import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "@opengsn/contracts/src/Context.sol";

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

error PinataVerify__NoApproval(address approvedFrom, address approvedTo);
error PinataVerify__NotVerified(address approvedFrom, address approvedTo);

contract PinataVerify is EIP712MetaTransaction("PinataVerify", "1"), Ownable {
    enum PermissionLevel {
        None,
        Private,
        Public
    }

    // struct MetaTransactionData {
    //     uint256 nonce;
    //     uint256 from;
    //     bytes functionSignature;
    // }

    struct DataUpload {
        string ipfsHash;
        string ipfsId;
        bool verified;
    }

    event giveApproval(
        address indexed approvedFrom,
        address indexed approvedTo,
        PermissionLevel permissionLevel
    );

    event dataUploadSuccess(
        address indexed uploadedFrom,
        address indexed approvedFrom,
        DataUpload dataUpload
    );

    event dataUploadVerified(
        address indexed uploadedFrom,
        address indexed approvedFrom,
        DataUpload dataUpload
    );

    mapping(address => mapping(address => PermissionLevel)) private s_approvals;
    mapping(address => mapping(address => DataUpload)) private s_uploads;

    modifier isApproved(address approvedFrom) {
        PermissionLevel permissionLevel = s_approvals[approvedFrom][msgSender()];

        if (permissionLevel == PermissionLevel.None) {
            revert PinataVerify__NoApproval(approvedFrom, msgSender());
        }
        _;
    }

    modifier isVerified(address approvedTo) {
        PermissionLevel permissionLevel = s_approvals[msgSender()][approvedTo];
        if (permissionLevel == PermissionLevel.None) {
            revert PinataVerify__NotVerified(approvedTo, msgSender());
        }
        _;
    }

    // constructor(address forwarder) {
    //     _setTrustedForwarder(forwarder);
    // }

    function grantPermission(address approvedTo, PermissionLevel permissionLevel) public {
        require(
            approvedTo != msgSender(),
            "Uploader and the address to grant access should be different"
        );
        s_approvals[msgSender()][approvedTo] = permissionLevel;
        emit giveApproval(msgSender(), approvedTo, permissionLevel);
    }

    function uploadData(
        address approvedFrom,
        string memory ipfsHash,
        string memory ipfsId
    ) external isApproved(approvedFrom) {
        DataUpload memory dataUpload = DataUpload(ipfsHash, ipfsId, false);
        s_uploads[msgSender()][approvedFrom] = DataUpload(ipfsHash, ipfsId, false);
        emit dataUploadSuccess(msgSender(), approvedFrom, dataUpload);
    }

    function verifyDataUpload(
        address approvedTo,
        string memory signedIpfsHash
    ) external isVerified(approvedTo) {
        s_uploads[approvedTo][msgSender()].verified = true;
        s_uploads[approvedTo][msgSender()].ipfsHash = signedIpfsHash;
        DataUpload memory dataUpload = s_uploads[approvedTo][msgSender()];
        emit dataUploadVerified(approvedTo, msgSender(), dataUpload);
    }

    function checkGivenPermission(address approvedTo) public view returns (PermissionLevel) {
        return s_approvals[msgSender()][approvedTo];
    }

    function checkReceivedPermission(address approvedFrom) public view returns (PermissionLevel) {
        return s_approvals[approvedFrom][msgSender()];
    }

    function checkUploads(address approvedFrom) public view returns (DataUpload[2] memory) {
        return [s_uploads[msgSender()][approvedFrom], s_uploads[approvedFrom][msgSender()]];
    }

    function retrieve() public pure returns (uint256) {
        return 10000;
    }

    // function _setTrustedForwarder(address _forwarder) internal override {
    //     _trustedForwarder = _forwarder;
    // }

    // function msgSender()
    //     internal
    //     view
    //     override(Context, ERC2771Recipient)
    //     returns (address sender)
    // {
    //     sender = ERC2771Recipient.msgSender();
    // }

    // function _msgData() internal view override(Context, ERC2771Recipient) returns (bytes calldata) {
    //     return ERC2771Recipient._msgData();
    // }

    // function msgSender()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (address sender)
    // {
    //     sender = ERC2771Recipient.msgSender();
    // }

    // function _msgData()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (bytes calldata)
    // {
    //     return ERC2771Recipient._msgData();
    // }

    // function versionRecipient() external pure returns (string memory) {
    //     return "1";
    // }

    // function setTrustedForwarder(address _trustedForwarder) public {
    //     // trustedForwarder = _trustedForwarder;
    //     // _setTrustedForwarder(_trustedForwarder)
    // }

    // function _msgSender()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (address sender)
    // {
    //     sender = ERC2771Recipient._msgSender();
    // }

    // function _msgData()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (bytes calldata)
    // {
    //     return ERC2771Recipient._msgData();
    // }

    // function versionRecipient() external pure returns (string memory) {
    //     return "1";
    // }
}

/////////////////////////////////////////////////////////
////////////////////NEEDED FUNCTIONS/////////////////////
/////////////////////////////////////////////////////////
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I GAVE PERMISSION
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I RECEIVED PERMISSION