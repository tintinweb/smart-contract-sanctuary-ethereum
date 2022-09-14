// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Coffer is Ownable, ReentrancyGuard {

    using Strings for uint256;

    using Strings for address;

    address public manager;

    mapping(string => bool) private businessBook;

    mapping(string => Receipt) private receipts;

    mapping(address => uint256) public balanceOf;

    struct Receipt {
        string receiptNum;
        address operator;
        address NFTAddr;
        uint256 NFTId;
        address tokenAddr;
        uint256 tokenAmount;
        uint256 slipPoint;
        uint256 timestamp;
    }

    event ReceiptReceived(string receiptNum);

    event ManagerChanged(address oldManager, address newManager);

    event Withdraw(string serialNum, address payee, address tokenAddr, uint256 amount);

    modifier onlyManager(){
        require(msg.sender == manager, "caller is not the manager");
        _;
    }

    constructor(){
        manager = msg.sender;
    }

    receive() payable external {}

    fallback() payable external {}

    function sendReceipt(
        Receipt calldata receipt
    )
    public
    nonReentrant
    returns (bool){
        require(receipt.NFTAddr == msg.sender, "Caller must be NFT contract");
        bytes32 _receiptNumHash = keccak256(abi.encodePacked(receipt.NFTAddr.toHexString(), "#", receipt.NFTId.toString()));
        bytes32 receiptNumHash = keccak256(abi.encodePacked(receipt.receiptNum));
        require(_receiptNumHash == receiptNumHash, "Receipt source unknown");
        require(bytes(receipts[receipt.receiptNum].receiptNum).length == 0, "This receipt has been stored");
        uint256 balanceBefor = balanceOf[receipt.tokenAddr];
        uint256 balanceNow;
        if (receipt.tokenAddr != address(0)) {
            IERC20 token = IERC20(receipt.tokenAddr);
            balanceNow = token.balanceOf(address(this));
        } else {
            balanceNow = address(this).balance;
        }
        require(balanceNow >= balanceBefor + (receipt.tokenAmount + receipt.slipPoint), "Token not received");
        balanceOf[receipt.tokenAddr] = balanceNow;
        receipts[receipt.receiptNum] = receipt;
        emit ReceiptReceived(receipt.receiptNum);
        return true;
    }


    function setManager(
        address newManager
    )
    public
    onlyOwner {
        address oldManager = manager;
        manager = newManager;
        emit ManagerChanged(oldManager, newManager);
    }

    function managerWithdraw(
        string memory businessId,
        address payable payee,
        address tokenAddr,
        uint256 amount
    )
    public
    onlyManager
    nonReentrant {
        if (businessBook[businessId] == true) revert("Withdraw invalid");
        if (tokenAddr == address(0)) {//withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH");
            businessBook[businessId] = true;
            payee.transfer(amount);
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
        } else {//withdraw ERC20
            IERC20 token = IERC20(tokenAddr);
            require(token.balanceOf(address(this)) >= amount, "Insufficient ERC20");
            businessBook[businessId] = true;
            require(token.transfer(payee, amount) == true, "transfer ERC20 fail");
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
        }

    }

    function userWithdraw(
        string memory businessId,
        address payable payee,
        address tokenAddr,
        uint256 amount,
        bytes memory sign
    )
    public
    nonReentrant {
        verify(businessId, tokenAddr, amount, payee, sign);
        if (businessBook[businessId] == true) revert("Withdraw invalid");
        if (tokenAddr == address(0)) {//withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH");
            businessBook[businessId] = true;
            payee.transfer(amount);
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
        } else {//withdraw ERC20
            IERC20 token = IERC20(tokenAddr);
            require(token.balanceOf(address(this)) >= amount, "Insufficient ERC20");
            businessBook[businessId] = true;
            require(token.transfer(payee, amount) == true, "transfer ERC20 fail");
            balanceOf[tokenAddr] -= amount;
            emit Withdraw(businessId, payee, tokenAddr, amount);
        }

    }

    function verify(
        string memory businessId,
        address tokenAddr,
        uint256 amount,
        address payable payee,
        bytes memory sign
    )
    internal
    view
    returns (bool) {
        bytes memory message = abi.encode(businessId, tokenAddr, amount, payee, msg.sender);
        bytes32 hash = keccak256(message);
        address _address = ecrecovery(hash, sign);
        require(manager == _address, "illegal signature");
        return true;
    }

    function ecrecovery(
        bytes32 hash,
        bytes memory sig
    )
    internal
    pure
    returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        /* prefix might be needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        bytes32 Hash = keccak256(abi.encodePacked(prefix, hash));

        return ecrecover(Hash, v, r, s);
    }

    function checkReceipt(string memory receiptNum_)
    public
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 slipPoint,
        uint256 timestamp
    ){
        Receipt memory receipt = receipts[receiptNum_];
        receiptNum = receipt.receiptNum;
        operator = receipt.operator;
        NFTAddr = receipt.NFTAddr;
        NFTId = receipt.NFTId;
        tokenAddr = receipt.tokenAddr;
        tokenAmount = receipt.tokenAmount;
        slipPoint = receipt.slipPoint;
        timestamp = receipt.timestamp;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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