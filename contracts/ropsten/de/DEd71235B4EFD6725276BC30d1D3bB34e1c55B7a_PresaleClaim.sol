import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PresaleClaim is Ownable, Pausable, ReentrancyGuard {
    /* ======== LIBRARIES ======== */

    using ECDSA for bytes32;

    /* ======== EVENTS ======== */

    event TokenAddress(address tokenAddress);
    event WithdrawAddressSigner(address withdrawAddressSigner);
    event TokenGenerationEvent(uint256 TGE);
    event DeployedOnBlock(uint256 deployedOnBlock);
    event MaxClaimPerBlockWait(uint256 maxClaimPerBlockWait);
    event TotalClaimed(uint256 totalClaimed);
    event BlockWaitForClaim(uint256 blockWaitForClaim);
    event ClaimedTokens(address user, uint256 amount);
    event WithdrawTokens(address user, uint256 amount);
    event EmergecyUpdateWallet(address user, uint256 hasClaimedInTotal);

    /* ======== VARS ======== */

    address public tokenAddress; // The token address the user claims
    address public withdrawAddressSigner; // The recovery signers address

    uint256 public deployedOnBlock; // The block number the contract has been deployed on
    uint256 public TGE = 20; // The first claim is 20% on TGE
    uint256 public blockWaitForClaim = 216000; // Users have to wait 30 days before claim opens again
    uint256 public maxClaimPerBlockWait = 10; // After TGE users can claim only a max of 10%
    uint256 public totalClaimed = 0; // Total tokens that has been claimed

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PRESALE_TYPEHASH = keccak256("PresaleClaim(address buyer,uint256 totalClaim)");

    /* ======== STRUCTS ======== */

    struct Presaler {
        uint256 hasClaimedInTotal; // How many tokens the user has claimed already
    }

    /* ======== MAPPINGS ======== */

    mapping(address => Presaler) public presaler;

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("PARA")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        setWithdrawAddressSigner(owner());
        setDeployedOnBlock(block.number);
    }

    /* ======== OWNER ONLY ======== */

    /**
     * @dev sets the new percentage of max claim the user can do after `blockWaitForClaim` has passed
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setMaxClaimPerBlockWait(uint256 _maxClaimPerBlockWait)
        public
        onlyOwner
    {
        maxClaimPerBlockWait = _maxClaimPerBlockWait;
        emit MaxClaimPerBlockWait(_maxClaimPerBlockWait);
    }

    /**
     * @dev Sets the deployed block number.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setDeployedOnBlock(uint256 _deployedOnBlock) public onlyOwner {
        deployedOnBlock = _deployedOnBlock;
        emit DeployedOnBlock(_deployedOnBlock);
    }

    /**
     * @dev sets the new token address for users to claim.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
        emit TokenAddress(_tokenAddress);
    }

    /**
     * @dev sets the new withdraw address signer
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setWithdrawAddressSigner(address _withdrawAddressSigner)
        public
        onlyOwner
    {
        withdrawAddressSigner = _withdrawAddressSigner;
        emit WithdrawAddressSigner(_withdrawAddressSigner);
    }

    /**
     * @dev sets the new TGE claim percentage
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setTokenGenerationEventAward(uint256 _TGE) public onlyOwner {
        TGE = _TGE;
        emit TokenGenerationEvent(_TGE);
    }

    /**
     * @dev the amount of blocks the users needs to wait before the new claim can happen.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setBlockWaitForClaim(uint256 _blockWaitForClaim) public onlyOwner {
        blockWaitForClaim = _blockWaitForClaim;
        emit BlockWaitForClaim(_blockWaitForClaim);
    }

    /**
     * @dev in case there is a bug where the presaler has wrong stats, we can set it to the correct numbers. Emergency ONLY
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setEmergencyPresalerClaimStats(
        address _user,
        uint256 _hasClaimedInTotal
    ) public onlyOwner {
        presaler[_user] = Presaler({hasClaimedInTotal: _hasClaimedInTotal});
        emit EmergecyUpdateWallet(_user, _hasClaimedInTotal);
    }

    /**
     * @dev in case there is a bug where the total claimed is not right anymore, we can set it back to the correct number. Emergency ONLY
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setEmergencyTotalClaimed(uint256 _totalClaimed) public onlyOwner {
        totalClaimed = _totalClaimed;
        emit TotalClaimed(_totalClaimed);
    }

    /**
     * @dev See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     * - The contract must not be paused.
     */
    function pause() public onlyOwner whenNotPaused {
        super._pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     * - The contract must be paused.
     */
    function unpause() public onlyOwner whenPaused {
        super._unpause();
    }

    /**
     * @dev Withdraw the tokens in the contract if there is leftovers
     *
     * Requirements:
     *
     * - Only the owner can call this function
     * - The contract must be paused.
     * - See {ReentrancyGuard-nonReentrant}
     */
    function withdrawTokens() public whenPaused nonReentrant onlyOwner {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) > 0,
            "Their is no tokens to withdraw"
        );
        IERC20(tokenAddress).approve(
            address(this),
            IERC20(tokenAddress).balanceOf(address(this))
        );
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );

        emit WithdrawTokens(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    /* ======== PRIVATE ======== */

    /**
     * @dev See {ECDSA-recover}.
     *
     * Requirements:
     *
     * - The signature's recover address must be the `withdrawAddressSigner`
     */
    function _validateSignature(bytes memory _signature, uint256 _totalClaim)
        private
        view
    {
          // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PRESALE_TYPEHASH, _msgSender(), _totalClaim))
            )
        );
        address recoveredAddress = digest.recover(_signature);
        require(recoveredAddress != address(0) && recoveredAddress == address(withdrawAddressSigner), "Invalid signature");
    }

    /* ======== PUBLIC ======== */

    /**
     * @dev Returns the claimable amount for a wallet
     */
    function getClaimable(address buyer, uint256 totalClaim)
        public
        view
        returns (uint256, uint256)
    {
        Presaler memory user = presaler[ buyer ];
        uint256 hasClaimedInTotal = 0;

        // calculate TGE
        hasClaimedInTotal += (totalClaim * TGE) / 100;
        // calculate claim amount over periods
        uint256 periodsToClaim = (block.number - deployedOnBlock) / blockWaitForClaim;
        hasClaimedInTotal += (totalClaim * (maxClaimPerBlockWait * periodsToClaim)) / 100;
        if (hasClaimedInTotal > totalClaim) {
            hasClaimedInTotal = totalClaim;
        }
        // substract amount already claimed
        uint256 claimableAmount = hasClaimedInTotal - user.hasClaimedInTotal;

        return (claimableAmount, hasClaimedInTotal);
    }

    /**
     * @dev Claim tokens periodically
     *
     * Requirements:
     *
     * - Paused must be `false`
     * - See {ReentrancyGuard-nonReentrant}
     */
    function claim(bytes memory _signature, uint256 _totalClaim) public whenNotPaused nonReentrant {
        _validateSignature(_signature, _totalClaim);
        Presaler memory user = presaler[_msgSender()];

        require(deployedOnBlock > 0, "deployedOnBlock must be higher than 0");
        require(user.hasClaimedInTotal < _totalClaim, "Already claimed total");
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "No tokens left");

        (uint256 claimableAmount, uint256 hasClaimedInTotal) = getClaimable( _msgSender(), _totalClaim );

        require(claimableAmount > 0, "Nothing to claim");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= claimableAmount, "No tokens left");

        // store new claimed amount
        presaler[_msgSender()] = Presaler({ hasClaimedInTotal: hasClaimedInTotal });
        totalClaimed += claimableAmount;

        // send amount to claim
        IERC20(tokenAddress).approve(address(this), claimableAmount);
        IERC20(tokenAddress).transferFrom(address(this), _msgSender(), claimableAmount);

        emit ClaimedTokens(_msgSender(), claimableAmount);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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

// SPDX-License-Identifier: MIT

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