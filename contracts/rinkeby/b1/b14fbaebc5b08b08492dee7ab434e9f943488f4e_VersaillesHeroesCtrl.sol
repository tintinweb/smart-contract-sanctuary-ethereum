/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/*
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

interface NFT {
    function mint(address to, uint256 boxId, uint256 boxCategory, uint256 quantity, bytes32 randomHash) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract VersaillesHeroesCtrl is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;


    event HeroTrade(bytes32 orderHash, address seller, address buyer, uint256 tokenId, address paymentToken, uint256 price, uint256 fee);
    event CancelHeroOrder(bytes32 orderHash, address seller, uint256 tokenId);

    event WeaponTrade(bytes32 orderHash, address seller, address buyer, uint256 tokenId, address paymentToken, uint256 price, uint256 fee);
    event CancelWeaponOrder(bytes32 orderHash, address seller, uint256 tokenId);

    event HeroUpgrade(uint256 tokenId, uint256 round);

    event DepositMOH(address sender, uint256 amount);
    event WithdrawMOH(bytes32 withdrawHash, address sender, uint256 amount);

    event DepositVRH(address sender, uint256 amount);
    event WithdrawVRH(bytes32 withdrawHash, address sender, uint256 amount);


    mapping(bytes32 => bool) public hashHistory;


    address public signer;
    address public fundAddress;

    address public heroAddress;
    address public weaponAddress;
    address public mohAddress;
    address public vrhAddress;

    constructor(address _signer, address _fundAddress, address _heroAddress, address _weaponAddress, address _mohAddress, address _vrhAddress){
        signer = _signer;
        fundAddress = _fundAddress;
        heroAddress = _heroAddress;
        weaponAddress = _weaponAddress;
        mohAddress = _mohAddress;
        vrhAddress = _vrhAddress;
    }



    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }



    function checkSigner(bytes32 _hash, bytes memory _rsv, address _signer) internal {
        require(!hashHistory[_hash], "hash exist");
        hashHistory[_hash] = true;
        address signerTemp = _hash.toEthSignedMessageHash().recover(_rsv);
        require(signerTemp == _signer, "signer not match");
    }


    function claimFreeHero(uint256 _heroBoxId, uint256 _heroBoxCategory, bytes memory _rsv, bytes32 _randomHash)
        external nonReentrant whenNotPaused{

        bytes32 hash = keccak256(abi.encode("claimFreeHero", address(this), msg.sender, _heroBoxId, _heroBoxCategory));
        checkSigner(hash, _rsv, signer);

        NFT(heroAddress).mint(msg.sender, _heroBoxId, _heroBoxCategory, 1, _randomHash);

    }


    function charge(address _paymentToken, uint256 _amount) internal{
        if(_paymentToken == address(0)){
            require(msg.value == _amount, "value error");

            payable(fundAddress).transfer(msg.value);
        }else{
            require(IERC20(_paymentToken).transferFrom(msg.sender, fundAddress, _amount));
        }
    }

    function purchaseHero(uint256 _heroBoxId, uint256 _heroBoxCategory, address _paymentToken, uint256 _price,
        uint256 _quantity, bytes32 _randomHash, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        require(_price > 0, "price invalid");
        require(_quantity > 0, "quantity invalid");

        bytes32 hash = keccak256(abi.encode("purchaseHero", address(this), msg.sender, _heroBoxId, _heroBoxCategory, _paymentToken, _price, _quantity, _randomHash));
        checkSigner(hash, _rsv, signer);

        uint256 amount = _price.mul(_quantity);
        charge(_paymentToken, amount);

        NFT(heroAddress).mint(msg.sender, _heroBoxId,  _heroBoxCategory, _quantity, _randomHash);

    }

    function purchaseWeapon(uint256 _weaponBoxId, uint256 _weaponBoxCategory, address _paymentToken, uint256 _price,
        uint256 _quantity, bytes32 _randomHash, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        require(_price > 0, "price invalid");
        require(_quantity > 0, "quantity invalid");

        bytes32 hash = keccak256(abi.encode("purchaseWeapon", address(this), msg.sender, _weaponBoxId, _weaponBoxCategory, _paymentToken, _price, _quantity, _randomHash));
        checkSigner(hash, _rsv, signer);

        uint256 amount = _price.mul(_quantity);
        charge(_paymentToken, amount);

        NFT(weaponAddress).mint(msg.sender, _weaponBoxId,  _weaponBoxCategory, _quantity, _randomHash);

    }

    function upgradeHero(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _level, bytes memory _rsv)
        external payable nonReentrant whenNotPaused{

        require(_price > 0, "price invalid");

        bytes32 hash = keccak256(abi.encode("upgradeHero", address(this), msg.sender, _tokenId, _paymentToken, _price, _level));
        checkSigner(hash, _rsv, signer);

        charge(_paymentToken, _price);

        emit HeroUpgrade(_tokenId, _level);

    }

    function withdrawMOH(uint256 _amount, bytes32 salt, bytes memory _rsv) external nonReentrant whenNotPaused{

        require(_amount > 0, "amount invalid");

        bytes32 hash = keccak256(abi.encode("withdrawMOH", address(this), _amount, salt));
        checkSigner(hash, _rsv, signer);

        IERC20(mohAddress).mint(msg.sender, _amount);

        emit WithdrawMOH(hash, msg.sender, _amount);
    }


    function withdrawVRH(uint256 _amount, bytes32 salt, bytes memory _rsv) external nonReentrant whenNotPaused{

        require(_amount > 0, "amount invalid");

        bytes32 hash = keccak256(abi.encode("withdrawVRH", address(this), _amount, salt));
        checkSigner(hash, _rsv, signer);

        IERC20(vrhAddress).transferFrom(fundAddress, msg.sender, _amount);

        emit WithdrawVRH(hash, msg.sender, _amount);
    }



    function depositMOH(uint256 _amount) external nonReentrant whenNotPaused{
        require(_amount > 0, "amount invalid");

        IERC20(mohAddress).burnFrom(msg.sender, _amount);

        emit DepositMOH(msg.sender, _amount);
    }

    function depositVRH(uint256 _amount) external nonReentrant whenNotPaused{
        require(_amount > 0, "amount invalid");

        require(IERC20(vrhAddress).transferFrom(msg.sender, fundAddress, _amount));

        emit DepositVRH(msg.sender, _amount);
    }





    function hashOrder(address _nftToken, uint256 _tokenId, address _paymentToken,uint256 _price,uint256 _fee,
        address _seller, uint256 _listingTime, uint256 _expirationTime)  public view returns(bytes32){

        return keccak256(abi.encode(address(this), _nftToken, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime));
    }

    function buy(address _nftToken, uint256 _tokenId, address _paymentToken, uint256 _price,uint256 _fee,
        address _seller, uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) internal returns(bytes32){

        require(_expirationTime >= block.timestamp, "order expired");
        require(_fee > 0 && _fee < _price, "fee invalid");
        require(_seller != msg.sender, "buy self" );

        bytes32 hash = hashOrder(_nftToken, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime);
        checkSigner(hash, _rsv, _seller);


        //transfer price & fee
        if(_paymentToken == address(0)){
            require(msg.value == _price, "price error");

            payable(fundAddress).transfer(_fee);
            payable(_seller).transfer(_price.sub(_fee));
        }else{
            require(IERC20(_paymentToken).transferFrom(msg.sender, fundAddress, _price));
            require(IERC20(_paymentToken).transferFrom(fundAddress, _seller, _price.sub(_fee)));
        }

        //transfer nft
        NFT(_nftToken).transferFrom(_seller, msg.sender, _tokenId);

        return hash;
    }


    function cancelSellOrder(address _nftToken, uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) internal returns(bytes32) {

        bytes32 hash = hashOrder(_nftToken, _tokenId, _paymentToken, _price, _fee, msg.sender, _listingTime, _expirationTime);
        checkSigner(hash, _rsv, msg.sender);

        return hash;
    }



    function buyHero(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,address _seller,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        bytes32 hash = buy(heroAddress, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime, _rsv);

        emit HeroTrade(hash, _seller, msg.sender, _tokenId, _paymentToken, _price, _fee);
    }


    function cancelSellHero(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external whenNotPaused{

        bytes32 hash = cancelSellOrder(heroAddress, _tokenId, _paymentToken, _price, _fee, _listingTime, _expirationTime, _rsv);

        emit CancelHeroOrder(hash, msg.sender, _tokenId);
    }




    function buyWeapon(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,address _seller,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external payable nonReentrant whenNotPaused{

        bytes32 hash = buy(weaponAddress, _tokenId, _paymentToken, _price, _fee, _seller, _listingTime, _expirationTime, _rsv);

        emit WeaponTrade(hash, _seller, msg.sender, _tokenId, _paymentToken, _price, _fee);
    }


    function cancelSellWeapon(uint256 _tokenId, address _paymentToken, uint256 _price, uint256 _fee,
        uint256 _listingTime, uint256 _expirationTime, bytes memory _rsv) external whenNotPaused{

        bytes32 hash = cancelSellOrder(weaponAddress, _tokenId, _paymentToken, _price, _fee, _listingTime, _expirationTime, _rsv);

        emit CancelWeaponOrder(hash, msg.sender, _tokenId);
    }
}