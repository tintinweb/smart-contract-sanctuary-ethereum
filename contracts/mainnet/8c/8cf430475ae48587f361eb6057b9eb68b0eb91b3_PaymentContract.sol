/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * (.note) This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * (.warning) `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling `toEthSignedMessageHash` on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * [`eth_sign`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign)
     * JSON-RPC method.
     *
     * See `recover`.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.0;

contract PaymentContract {
    using ECDSA for bytes32;

    address private _owner;
    IERC20 private _token;
    mapping(string => Subscription) private _subscriptions;

    struct Subscription {
        address owner;
        uint64 timestamp;
        uint192 tokens;
        address tokenAddress;
    }

    constructor(address owner, address token) public nonZeroAddress(owner) nonZeroAddress(token) {
        _owner = owner;
        _token = IERC20(token);
    }

    event SubscriptionPaid(string indexed subscriptionId, uint64 timestampFrom, address indexed ownerAddress, uint192 tokens, address tokenAddress);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TokenChanged(address indexed previousToken, address indexed newToken);

    event Withdraw(address indexed byOwner, address indexed toAddress, uint256 amount);

    modifier nonZeroAddress(address account) {
        require(account != address(0), "new owner can't be with the zero address");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, "only owner can exec this function");
        _;
    }

    modifier isValidSubscription(string memory subscriptionId){
        require(bytes(subscriptionId).length > 0, "incorrect subscription id");
        require(bytes(subscriptionId).length < 13, "incorrect subscription id");
        require(_subscriptions[subscriptionId].owner == address(0), "subscription already exists");
        _;
    }

    function changeToken(address newToken) external onlyOwner {
        require(newToken != address(_token), "already in use");
        require(newToken != address(0), "invalid address");

        address oldToken = address(_token);
        _token = IERC20(newToken);

        emit TokenChanged(oldToken, newToken);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner can't be the zero address");
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function withdrawAll(address to) external onlyOwner returns (bool){
        uint256 amount = _token.balanceOf(address(this));
        bool success = _token.transfer(to, amount);
        require(success, "withdraw transfer failed");

        emit Withdraw(_owner, to, amount);

        return success;
    }

    function createSubscriptionIfSignatureMatch(bytes calldata signature, string calldata subscriptionId, uint192 tokens, uint256 deadline, address sender) external isValidSubscription(subscriptionId) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,address verifyingContract)"
                ),
                keccak256(bytes("PaymentContract")),
                keccak256(bytes("1")),
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("_createSubscription(string subscriptionId,uint192 tokens,uint256 deadline,address sender)"),
                keccak256(bytes(subscriptionId)),
                tokens,
                deadline,
                sender
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ECDSA.recover(hash, signature);

        require(signer == sender, "_createSubscription: invalid signature");
        require(sender == msg.sender, "_createSubscription: invalid sender");
        require(signer != address(0), "ECDSA: invalid signature");
        require(block.timestamp < deadline, "signed transaction expired");

        _createSubscription(subscriptionId, tokens);
    }

    function _createSubscription(string memory subscriptionId, uint192 tokens) internal {
        address tokenAddress = address(_token);
        bool success = _token.transferFrom(msg.sender, address(this), tokens);
        require(success, "tokens transfer failed!");
        _subscriptions[subscriptionId] = Subscription(
            msg.sender, uint64(block.timestamp), tokens, tokenAddress
        );
        emit SubscriptionPaid(subscriptionId, uint64(block.timestamp), msg.sender, tokens, tokenAddress);
    }

    function getSubscription(string calldata subscriptionId) external view returns (address, uint64, uint192, address){
        return (_subscriptions[subscriptionId].owner, _subscriptions[subscriptionId].timestamp, _subscriptions[subscriptionId].tokens, address(_token));
    }

    function owner() external view returns (address){
        return _owner;
    }

    function token() external view returns (address){
        return address(_token);
    }
}