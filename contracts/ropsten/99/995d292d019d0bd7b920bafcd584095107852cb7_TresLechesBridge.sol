/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

/*
    Website: https://tresleches.finance
    Contract Name: TresLechesBridgeETH
    Instagram: https://www.instagram.com/treslechestoken
    Twitter: https://twitter.com/treslechestoken
    Telegram: https://t.me/TresLechesCakeOfficial_EN
    Contract Version: 2.08
    Contract Supply: 25,000,000,000 Max Mint Token
    
    The following contract will be used to bridge the token accross multiple blockchains to it needs the mint and burnBridge, however we are making a burnBridge compliance.

Dev Notes:


*/
// SPDX-License-Identifier: MIT


pragma solidity = 0.8.16;

// File: node_modules\@openzeppelin\contracts\utils\Context.sol
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol
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
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IToken {
function mintBridge(address to, uint amount) external;
function burnBridge(address owner, uint amount) external;
}


// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol
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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


contract BridgeBase is ReentrancyGuard {
address public admin;
IToken public token;
mapping(address => mapping(uint => bool)) public processedNonces;
enum Step { burnBridge, mintBridge }
event Transfer(
address from,
address to,
uint amount,
uint date,
uint nonce,
bytes signature,
Step indexed step
);
constructor(address _token) {
admin = msg.sender;
token = IToken(_token);
}
function burnBridge(address to, uint amount, uint nonce, bytes calldata signature) external nonReentrant {
require(to != address(0), "ERC20: transfer from the zero address");

require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
processedNonces[msg.sender][nonce] = true;
token.burnBridge(msg.sender, amount);
emit Transfer(
msg.sender,
to,
amount,
block.timestamp,
nonce,
signature,
Step.burnBridge
);
}
function mintBridge(
address from,
address to,
uint amount,
uint nonce,
bytes calldata signature
) external nonReentrant {
bytes32 message = prefixed(keccak256(abi.encodePacked(
from,
to,
amount,
nonce
)));
require(from != address(0), "ERC20: transfer from the zero address");
require(to != address(0), "ERC20: transfer from the zero address");
require(recoverSigner(message, signature) == from , 'wrong signature');
require(processedNonces[from][nonce] == false, 'transfer already processed');
processedNonces[from][nonce] = true;
token.mintBridge(to, amount);
emit Transfer(
from,
to,
amount,
block.timestamp,
nonce,
signature,
Step.mintBridge
);
}
function prefixed(bytes32 hash) internal pure returns (bytes32) {
return keccak256(abi.encodePacked(
'\x19Ethereum Signed Message:\n32',
hash
));
}
function recoverSigner(bytes32 message, bytes memory sig)
internal
pure
returns (address)
{
uint8 v;
bytes32 r;
bytes32 s;
(v, r, s) = splitSignature(sig);
return ecrecover(message, v, r, s);
}
function splitSignature(bytes memory sig)
internal
pure
returns (uint8, bytes32, bytes32)
{
require(sig.length == 65);
bytes32 r;
bytes32 s;
uint8 v;
assembly {
// first 32 bytes, after the length prefix
r := mload(add(sig, 32))
// second 32 bytes
s := mload(add(sig, 64))
// final byte (first byte of the next 32 bytes)
v := byte(0, mload(add(sig, 96)))
}
return (v, r, s);
}
}


contract TresLechesBridge is BridgeBase {
constructor(address token) BridgeBase(token) {}
}