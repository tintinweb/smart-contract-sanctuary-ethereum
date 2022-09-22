pragma solidity ^0.8.4;

import "./SocialMediaRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EventRouter is Ownable, ReentrancyGuard {
    SocialMediaRouter SOCIAL_MEDIA_ROUTER;
    uint256 public fee = 5; // percentage
    uint256 public erc20Fee = 5; // percentage
    uint256 public flatTokenFee = 0.0006 ether;
    bool public isFlatFeeActive = false;
    address payable public milianBank;

    constructor() {
        milianBank = payable(owner());
    }

    event Payment(uint256 indexed paymentId);

    event PendingPayment(
        address indexed sender,
        string serviceId,
        string userId,
        string ruleId
    );

    struct OwedPayment {
        address tokenAddress;
        uint256 amount;
        uint256 paymentId;
    }

    struct Pay {
        address tokenAddress;
        uint256 amount;
        address from;
        address to;
        string serviceId;
        string userId;
        string ruleId;
    }

    // pending payments
    mapping(string => mapping(string => mapping(address => uint256)))
        public owedAmounts;
    mapping(string => mapping(string => mapping(uint256 => OwedPayment)))
        public owedPayments;
    mapping(string => mapping(string => uint256)) public owedPaymentCounts;

    mapping(uint256 => Pay) public payments;
    uint256 public paymentCount = 0;

    /** @dev Withdrawls all tokens in a list for a specific user if the user exists.
     * @param tokenAddresses token addresses the user wishes to withdrawl.
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @notice This function does not withdrawl all pending tokens to ensure no errors occur running out of gas.
     * @notice address(0) represents ETH
     * @notice nonReentrant to prevent reentrancy attack once the tokens/ETH have been transfered
     */
    function withdrawlTokenList(
        address[] memory tokenAddresses,
        string memory serviceId,
        string memory userId
    ) public nonReentrant {
        address toAddress = SOCIAL_MEDIA_ROUTER.getAddress(serviceId, userId);
        require(toAddress != address(0), "User does not exist");
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            uint256 a = owedAmounts[serviceId][userId][tokenAddresses[i]];
            if (a > 0) {
                owedAmounts[serviceId][userId][tokenAddresses[i]] = 0;
                // if token address is ETH
                if (tokenAddresses[i] == address(0)) {
                    payable(toAddress).transfer(a);
                } else {
                    IERC20 token = IERC20(tokenAddresses[i]);
                    token.transfer(toAddress, a);
                }
            }
        }
    }

    /** @dev Creates a new Pay struct in the payments mapping and emits a payment event
     * @param tokenAddress token addresses the user wishes to withdrawl.
     * @param amount amount of the payment.
     * @param from address of whos sending the payment
     * @param to address of whos receiving the payment
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @param ruleId Id of the offchain rule corresponding to the payment.
     * @notice This is an internal function that creates a new payment, an on chain record for the off chain listeners to access
     */
    function createNewPayment(
        address tokenAddress,
        uint256 amount,
        address from,
        address to,
        string memory serviceId,
        string memory userId,
        string memory ruleId
    ) private {
        paymentCount = paymentCount + 1;
        payments[paymentCount] = Pay(
            tokenAddress,
            amount,
            from,
            to,
            serviceId,
            userId,
            ruleId
        );
        emit Payment(paymentCount);
    }

    /** @dev Creates a new Owed Payment struct in the payments mapping and emits a payment event
     * @param tokenAddress token addresses the user wishes to withdrawl.
     * @param amount amount of the payment.
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @notice This is an internal function that creates a new owed payment, an on chain record for the off chain listeners to access
     */

    function createOwedPayment(
        address tokenAddress,
        uint256 amount,
        string memory serviceId,
        string memory userId
    ) private {
        owedPaymentCounts[serviceId][userId] =
            owedPaymentCounts[serviceId][userId] +
            1;
        owedPayments[serviceId][userId][
            owedPaymentCounts[serviceId][userId]
        ] = OwedPayment({
            tokenAddress: tokenAddress,
            amount: amount,
            paymentId: paymentCount
        });
        owedAmounts[serviceId][userId][tokenAddress] =
            owedAmounts[serviceId][userId][tokenAddress] +
            amount;
    }

    /** @dev Pays ETH regarding a specific ruleId
     * @param toAddress address of receiver.
     * @param ruleId Id of the off chain rule
     * @notice Public function allowing users to pay ETH
     */
    function payEth(address toAddress, string memory ruleId) public payable {
        uint256 ownerCut = (fee * msg.value) / 100;
        payable(toAddress).transfer(msg.value - ownerCut);
        milianBank.transfer(ownerCut);
        createNewPayment(
            address(0),
            msg.value,
            msg.sender,
            toAddress,
            "",
            "",
            ruleId
        );
    }

    /** @dev pays ETH through service
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @param ruleId Id of the off chain rule for offchain listeners to process
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function payEthThroughService(
        string calldata serviceId,
        string calldata userId,
        string memory ruleId
    ) public payable nonReentrant {
        address toAddress = SOCIAL_MEDIA_ROUTER.getAddress(serviceId, userId);
        uint256 ownerCut = (fee * msg.value) / 100;
        milianBank.transfer(ownerCut);
        // social media router found a match
        if (toAddress != address(0)) {
            payable(toAddress).transfer(msg.value - ownerCut);
            createNewPayment(
                address(0),
                msg.value,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
        } else {
            createNewPayment(
                address(0),
                msg.value,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
            createOwedPayment(
                address(0),
                msg.value - ownerCut,
                serviceId,
                userId
            );
        }
    }

    /** @dev pays ERC20
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of the ERC20 token.
     * @param toAddress Address whos receiving the funds
     * @param ruleId Id of the off chain rule for offchain listeners to process
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function payERC20(
        address tokenAddress,
        uint256 amount,
        address toAddress,
        string memory ruleId
    ) public payable nonReentrant {
        require(
            tokenAddress != address(0),
            "Token address cannot be zero address"
        );
        require(amount > 0, "Amount is zero");

        IERC20 token = IERC20(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance is too low");

        if (isFlatFeeActive) {
            require(msg.value >= flatTokenFee, "Flat fee not met");
            milianBank.transfer(msg.value);
        }

        uint256 ownerCut = (erc20Fee * amount) / 100;
        if (ownerCut > 0) {
            token.transferFrom(msg.sender, milianBank, ownerCut);
        }
        token.transferFrom(msg.sender, toAddress, amount - ownerCut);

        createNewPayment(
            tokenAddress,
            msg.value,
            msg.sender,
            toAddress,
            "",
            "",
            ruleId
        );
    }

    /** @dev pays ERC20 through service
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of the ERC20 token.
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @param ruleId Id of the off chain rule for offchain listeners to process
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function payERC20ThroughService(
        address tokenAddress,
        uint256 amount,
        string calldata serviceId,
        string calldata userId,
        string memory ruleId
    ) public payable nonReentrant {
        require(amount > 0, "Amount is zero");

        IERC20 token = IERC20(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance is too low");

        if (isFlatFeeActive) {
            require(msg.value >= flatTokenFee, "Flat fee not met");
            milianBank.transfer(msg.value);
        }

        uint256 ownerCut = (erc20Fee * amount) / 100;
        if (ownerCut > 0) {
            token.transferFrom(msg.sender, milianBank, ownerCut);
        }

        address toAddress = SOCIAL_MEDIA_ROUTER.getAddress(serviceId, userId);

        // social media router found a match
        if (toAddress != address(0)) {
            token.transferFrom(msg.sender, toAddress, amount - ownerCut);
            createNewPayment(
                tokenAddress,
                amount,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
        } else {
            token.transferFrom(msg.sender, address(this), amount - ownerCut);
            createNewPayment(
                tokenAddress,
                amount,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
            createOwedPayment(
                tokenAddress,
                amount - ownerCut,
                serviceId,
                userId
            );
        }
    }

    /** @dev Adds account to social media router and withdrawls tokens
     * @param signature Signature from bond signer
     * @param accountAddress Address to route payments to
     * @param serviceId Id of the service to link (ex. twitter).
     * @param userId Id of the user to link (ex. abc123)
     * @param nonce nonce to ensure past signatures cannot be used
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function addAccountAndWithdrawl(
        bytes memory signature,
        address accountAddress,
        string memory serviceId,
        string memory userId,
        uint256 nonce,
        address[] memory tokenAddresses
    ) public {
        // non reentrant?
        SOCIAL_MEDIA_ROUTER.addAccount(
            signature,
            accountAddress,
            serviceId,
            userId,
            nonce
        );
        withdrawlTokenList(tokenAddresses, serviceId, userId);
    }

    function setSMR(address _a) public onlyOwner {
        SOCIAL_MEDIA_ROUTER = SocialMediaRouter(_a);
    }

    function setFee(uint256 _f) public onlyOwner {
        require(_f <= 100, "Fee is not valid");
        fee = _f;
    }

    function setErc20Fee(uint256 _f) public onlyOwner {
        require(_f <= 100, "ERC20 Fee is not valid");
        erc20Fee = _f;
    }

    function setFlatTokenFee(uint256 _f) public onlyOwner {
        flatTokenFee = _f;
    }

    function setIsFlatFeeActive(bool _a) public onlyOwner {
        isFlatFeeActive = _a;
    }

    function setBank(address payable _bank) public onlyOwner {
        milianBank = _bank;
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SocialMediaRouter is Ownable {
    address public bondSigner;

    struct Account {
        address payable ownerAddress;
        uint256 nonce;
    }

    mapping(string => mapping(string => Account)) public accounts;

    function getAccount(string calldata serviceId, string calldata userId)
        public
        view
        returns (Account memory)
    {
        return accounts[serviceId][userId];
    }

    function getAddress(string calldata serviceId, string calldata userId)
        public
        view
        returns (address)
    {
        return accounts[serviceId][userId].ownerAddress;
    }

    function addAccount(
        bytes memory signature,
        address accountAddress,
        string memory serviceId,
        string memory userId,
        uint256 nonce
    ) public {    
        bytes32 _hash = keccak256(
            abi.encodePacked(accountAddress, nonce, serviceId, userId)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(_hash);
        address receivedAddress = ECDSA.recover(message, signature);
        require(
            receivedAddress != address(0) && receivedAddress == bondSigner,
            "Bond Signer not verified"
        );
        require(nonce > accounts[serviceId][userId].nonce, "Nonce is too low");
        accounts[serviceId][userId] = Account(payable(accountAddress), nonce);
    }

    function setBondSigner(address _bondSigner) public onlyOwner {
        bondSigner = _bondSigner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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