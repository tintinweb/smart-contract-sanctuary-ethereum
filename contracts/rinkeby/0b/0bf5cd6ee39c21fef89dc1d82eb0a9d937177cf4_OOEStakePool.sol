/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: DAO.sol



pragma solidity 0.8.11;





////待优化，complete的lock要从mapping中移除吗？ 历史数据存储在链下？


contract OOEStakePool is ReentrancyGuard,Ownable{

    struct Lock{
        address locker;
        uint256 lockId;
        uint256 timestampLockStart;
        uint256 timestampLockEnd;
        uint256 OOELockedAmount;
        uint256 XOOEBaseAmount;
        uint256 lockWeeks;
        State state;       
    }

    struct gasRefund{
        address user;
        uint256 amount;
        uint256 nonce;//Change until receive the event
        bytes32 Hash;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum State {
        UNSTART,
        LOCKING,
        COMPLETE
    }

    enum MixLockType {
        AllEXTERNAL,
        ALLREVERSE,
        MIX
    }
   
    bool public pause;
    IERC20 public OOE;
    mapping (address => uint256) public totalOOE;
    mapping (address => uint256) public availableOOE;
    mapping (uint256 => Lock) private _lock;
    mapping (address => uint256[]) private _locksId;
    mapping (address => bool) public signers;
    mapping (address => uint256) public gasRefundNonce;
    
    event logAddOOEToPool(uint256 amount);
    event logHarvest(address user, Lock lock);
    event logLocks(address user, Lock[] lock);
    event logLock(address user, Lock lock);
    event logUnLock(address user,Lock lock);
    event logUserWithdrew(address user, uint256 amount);
    event logSigner(address signer, bool isRemoval);
    event logGasRefund(address user, bytes32 Hash, uint256 amount, uint256 nonce);



    modifier notPause() {
        require(!pause, "OPENOCEAN_STAKING_POOL_V1:PAUSE_NOW");
        _;
    }

    constructor(IERC20 OOE_) {
        OOE = OOE_;
    }


    function setPause(bool pauseOrNot_) external onlyOwner {
        pause = pauseOrNot_;
    }

    function getVotingPower(address voter) public view returns(uint256){
        uint256 locksAmount = _locksId[voter].length;
        uint256 power;
        for(uint256 i = 0; i < locksAmount; i++){
            Lock memory lo = _lock[_locksId[voter][i]];
            if(lo.state == State.LOCKING){
                if(lo.timestampLockEnd > block.timestamp){
                    power = power + lo.OOELockedAmount + (lo.XOOEBaseAmount - lo.OOELockedAmount) * (block.timestamp - lo.timestampLockStart)/(lo.timestampLockEnd - lo.timestampLockStart);
                }else{
                    uint256 rate = _minimumIncrease();
                    power = power + lo.XOOEBaseAmount + (block.timestamp - lo.timestampLockEnd) * rate * lo.XOOEBaseAmount / 60480000000;
                }
            }
        }
        return power;
    }

    function getOOEAmountInpool() public view returns(uint256){
        return OOE.balanceOf(address(this));
    }

    function getUserStakingOOE(address user) public view returns(uint256){
        return totalOOE[user] - availableOOE[user];
    }

    function getBatchStakeAmount(Lock[] memory lock_) public pure returns(uint256){
        uint256 amount_;
        for(uint256 i; i<lock_.length;i++){
            amount_ = amount_ + lock_[i].OOELockedAmount;
        }
        return amount_;
    }

    function AddOOEToPool(uint256 amount_) external{
        OOE.transferFrom(msg.sender, address(this), amount_);
        emit logAddOOEToPool(amount_);
    }

    function updateSigners(address[] memory toAdd, address[] memory toRemove)
        public
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit logSigner(toAdd[i], false);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit logSigner(toRemove[i], true);
        }
    }

// harvest all the locks OOE
    function harvest() external notPause{
        uint256 locksAmount = _locksId[msg.sender].length;
        for(uint256 i = 0; i<locksAmount; i++){
            Lock storage lo = _lock[_locksId[msg.sender][i]];
            //include unlock locks and complete locks
            if(block.timestamp > lo.timestampLockEnd && lo.state == State.LOCKING){
            lo.state = State.COMPLETE;
            uint256 rate = _minimumIncrease();
            availableOOE[msg.sender] = availableOOE[msg.sender] + lo.XOOEBaseAmount + (block.timestamp - lo.timestampLockEnd) * rate * lo.XOOEBaseAmount / 60480000000;
            totalOOE[msg.sender] = totalOOE[msg.sender] + lo.XOOEBaseAmount - lo.OOELockedAmount + (block.timestamp - lo.timestampLockEnd) * rate * lo.XOOEBaseAmount / 60480000000;
            emit logHarvest(msg.sender,lo);
            }
        }
    }

    function unlock(uint256[] calldata lockid) external notPause{
        for(uint256 i = 0; i < lockid.length; i++){
            require(_lock[lockid[i]].locker == msg.sender,"OPENOCEAN_STAKING_POOL_V1:THIS_LOCK_WAS_ALREADY_COMPLETED");
            require(_lock[lockid[i]].timestampLockEnd > block.timestamp,"OPENOCEAN_STAKING_POOL_V1:THIS_LOCK_WAS_ALREADY_COMPLETED");
            Lock storage lo = _lock[lockid[i]];
            lo.state=State.COMPLETE;
            availableOOE[msg.sender] = availableOOE[msg.sender] + lo.OOELockedAmount + (lo.XOOEBaseAmount - lo.OOELockedAmount) * (block.timestamp - lo.timestampLockStart)/(lo.timestampLockEnd - lo.timestampLockStart) - _punishment(lo);
            totalOOE[msg.sender] = totalOOE[msg.sender] + (lo.XOOEBaseAmount - lo.OOELockedAmount) * (block.timestamp - lo.timestampLockStart)/(lo.timestampLockEnd - lo.timestampLockStart) - _punishment(lo);
            emit logUnLock(msg.sender, lo);
        }  
    }

    function lock(Lock memory lock_) external notPause{
        //require(block.timestamp - lock_.timestampLockStart < 60,"OPENOCEAN_STAKING_POOL_V1:WRONG_START_TIME");
        require(_lock[lock_.lockId].OOELockedAmount == 0, "OPENOCEAN_STAKING_POOL_V1:LOCK_ALREADY_EXIST");
        _receiveOOE(lock_.OOELockedAmount); 
        _singleLock(lock_);
        emit logLock(msg.sender, lock_);
    }

    function lockWithReverse(Lock memory lock_) public notPause{
        require(_lock[lock_.lockId].OOELockedAmount == 0, "OPENOCEAN_STAKING_POOL_V1:WRONG_SENDER");
        require(lock_.locker == msg.sender, "OPENOCEAN_STAKING_POOL_V1:ONLY_ALLOW_SELFLOCK");
        _singleLock(lock_); 
        emit logLock(msg.sender, lock_);
    }

    function batchMixLock(Lock[] memory lock_, MixLockType type_, uint256 externalOOEAmount) external notPause{
        if(type_ == MixLockType.AllEXTERNAL){ 
            _receiveOOE(getBatchStakeAmount(lock_)); 
            for(uint256 i; i<lock_.length; i++){
                require(_lock[lock_[i].lockId].OOELockedAmount == 0, "OPENOCEAN_STAKING_POOL_V1:LOCK_ALREADY_EXIST");
                 _singleLock(lock_[i]);
            }
        }else if(type_ == MixLockType.ALLREVERSE){
            for(uint256 i; i<lock_.length; i++){
                lockWithReverse(lock_[i]);
            }
        }else if(type_ == MixLockType.MIX){
            uint256 amount = externalOOEAmount + availableOOE[msg.sender];
            require(amount >= getBatchStakeAmount(lock_), "OPENOCEAN_STAKING_POOL_V1:EXTERNALOOE_NOT_ENOUGH");
            _receiveOOE(externalOOEAmount);
            for(uint256 i; i<lock_.length; i++){
                lockWithReverse(lock_[i]);
            }
        }
        emit logLocks(msg.sender, lock_);
    }

    function adminWithdrew(uint256 amount_) external onlyOwner{
        require(OOE.balanceOf(address(this)) >= amount_,"OPENOCEAN_STAKING_POOL_V1:WITHDREW_TOO_MUCH");
        OOE.transfer(msg.sender,amount_);
    }

    function withdrew(uint256 amount_) external notPause{
        _sendOOE(amount_, msg.sender);
        emit logUserWithdrew(msg.sender, amount_);
    }

    function GasRefund(gasRefund memory input) external nonReentrant notPause{
        require(msg.sender == input.user,"WRONG_USER");
        require(gasRefundNonce[msg.sender] == input.nonce,"WRONG_ORDER");
        _verifyInputSignature(input);
        require(OOE.balanceOf(address(this)) >= input.amount,"OOE_IS_NOT_ENOUGHT_PLZ_CONTACT_ADMIN");
        OOE.transfer(msg.sender,input.amount);
        emit logGasRefund(input.user, input.Hash, input.amount, input.nonce);
    }

    function gasrefundTest(gasRefund memory input) public view returns(bytes32){
        bytes32 hashs = keccak256(abi.encode(input.user, input.amount, input.nonce));
        return hashs;
    }

    function _verifyInputSignature(gasRefund memory input) internal view virtual {
        bytes32 hash = keccak256(abi.encode(input.user, input.amount, input.nonce));
        require(hash == input.Hash,"WRONG_ENCODE");
        address signer = ECDSA.recover(hash, input.v, input.r, input.s);
        require(signers[signer], 'Input signature error');
    }

    function _sendOOE(uint256 amount_, address destination_) internal nonReentrant{
        require(availableOOE[msg.sender] >= amount_,"OPENOCEAN_STAKING_POOL_V1:WITHDREW_TOO_MUCH");
        totalOOE[msg.sender] = totalOOE[msg.sender] - amount_;
        availableOOE[msg.sender] = availableOOE[msg.sender] - amount_;
        OOE.transfer(destination_,amount_);
    }

    function _receiveOOE(uint256 amount_) internal nonReentrant{
        totalOOE[msg.sender] = totalOOE[msg.sender] + amount_;
        availableOOE[msg.sender] = availableOOE[msg.sender] + amount_;
        OOE.transferFrom(msg.sender, address(this), amount_);
    }

    function _punishment(Lock memory lock_) internal view returns(uint256){
/////////!!!!!!!need to add punishment
        uint256 punishmentAmount = (lock_.XOOEBaseAmount - lock_.OOELockedAmount) * (block.timestamp - lock_.timestampLockStart) / (lock_.timestampLockEnd - lock_.timestampLockStart) / 2;
        return punishmentAmount;
    }

    function _singleLock(Lock memory lock_) internal{
        uint256 rate = lock_.lockWeeks * 200 + (lock_.lockWeeks - 1) * 265 + 100000;
        require(lock_.XOOEBaseAmount == lock_.OOELockedAmount * rate / 100000,"OPENOCEAN_STAKING_POOL_V1:NOT_CORRECT_AMOUNT");
        require(availableOOE[msg.sender] >= lock_.OOELockedAmount,"OPENOCEAN_STAKING_POOL_V1:AVAILABLEOOE_NOT_ENOUGH");
        availableOOE[msg.sender] = availableOOE[msg.sender] - lock_.OOELockedAmount;
        _locksId[lock_.locker].push(lock_.lockId);
        _lock[lock_.lockId] = lock_;
    }

    function _minimumIncrease() public pure returns(uint256){
        return 100;
    }
    
}