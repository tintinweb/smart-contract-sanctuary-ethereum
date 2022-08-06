// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../registry/ITokenRegistry.sol";
import "./Checkout.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
 * @title {InstantMintCheckout} is an implementation of {Checkout} for which the {_postCheckoutAction}
 * instantly mints a new token in a {ITokenRegistry}
 */
contract InstantMintCheckout is Checkout {

    event TokenMinted(address indexed registry, address indexed receiver, bytes32 proofOfIntegrity, string checkoutId);

    /**
     * @dev post-checkout action data required to mint a token. This struct is formed by the calling application.
     */
    struct PostCheckoutCallData {
        bytes32 tokenProofOfIntegrity;  // the proof of integrity of the token to mint.
        address tokenRegistryAddress;   // the {ITokenRegistry} where the token will be minted post-checkout.
        address tokenReceiver;          // the account that will receive the newly minted token.
    }

    /**
     * @dev constructor.
     * @param paymentReceiver_ the address of the payment receiver account.
     * @param checkoutOracle_ the address of the checkout oracle account.
     */
    constructor(
        address paymentReceiver_,
        address checkoutOracle_
    ) Checkout(paymentReceiver_, checkoutOracle_) {}

    /**
     * @dev modifier to check that the token registry implements {ITokenRegistry}.
     */
    modifier onlyValidRegistry(address tokenRegistryAddress) {
        require(
            ERC165Checker.supportsInterface(tokenRegistryAddress, type(ITokenRegistry).interfaceId),
            "InstantMintCheckout: Target token registry contract does not match the interface requirements."
        );
        _;
    }

    /**
     * @dev helper function to encode {PostCheckoutCallData} from the input arguments so that it can be passed to
     * {Checkout._encodeCheckoutRequest} and {_postCheckoutAction} in the right format.
     * @param tokenProofOfIntegrity the proof of integrity of the token to mint.
     * @param tokenRegistryAddress the {ITokenRegistry} where the token will be minted post-checkout.
     * @param tokenReceiver the account that will receive the newly minted token.
     * 
     * Requirements:
     * 
     *      - {tokenRegistryAddress} must be a valid {ITokenRegistry}.
     *      - If {data} is the result of this function, ethers.utils.arrayify(data) must be called to
     *        appropriately pass it through as an input to {_encodeCheckoutRequest}.
     */
    function encodePostCheckoutCallData(
        bytes32 tokenProofOfIntegrity,
        address tokenRegistryAddress,
        address tokenReceiver
    ) public view onlyValidRegistry(tokenRegistryAddress) returns (bytes memory) {
        return abi.encode(
            PostCheckoutCallData(
                tokenProofOfIntegrity,
                tokenRegistryAddress,
                tokenReceiver
            )
        ); 
    }


    /* =========================================== POST-CHECKOUT ACTION =========================================== */

    /**
     * @dev a post-checkout function that mints a new token in the appropriate {ITokenRegistry}.
     * @param checkoutId the checkout id.
     * @param data the encoded input data to execute this function.
     * 
     * Requirements:
     * 
     *      - {data} must decode to {PostCheckoutCallData decoded}.
     *      - {decoded.tokenRegistryAddress} must be the address of a {ITokenRegistry} contract.
     *      - All the equirements from {ITokenRegistry.mintToken} must be met.
     * 
     */
     function _postCheckoutAction(string memory checkoutId, bytes memory data) internal override {
        PostCheckoutCallData memory decoded = abi.decode(data, (PostCheckoutCallData));
        try ITokenRegistry(decoded.tokenRegistryAddress).mintToken(decoded.tokenReceiver, decoded.tokenProofOfIntegrity) {
            emit TokenMinted(
                decoded.tokenRegistryAddress,
                decoded.tokenReceiver,
                decoded.tokenProofOfIntegrity,
                checkoutId
            );
        } catch Error(string memory reason) {
            revert(
                string(abi.encodePacked(
                    "InstantMintCheckout: Post-checkout action failure (", 
                    reason,
                    ")"
                ))
            );
        }
     }

}

// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title {ITokenRegistry} is an interface for a token registry.
 */
interface ITokenRegistry is IERC165 {

    /**
     * @dev mint a new token to {to}, and return the token id of the newly minted token. Upon minting a token, it is
     * required to provide the {proofOfIntegrity} of integrity of the token. 
     * 
     * The proof of integrity uniquely identifies the token and is used to guarantee the integrity of the token at all times.
     * 
     * Use-case: for a token representing a physical asset, {proofOfIntegrity} is a hash of the information that uniquely
     * identifies the physical asset in the physical world. 
     */
    function mintToken(address to, bytes32 proofOfIntegrity) external returns (uint256);

    /**
     * @dev burn a token. The calling burner account or contract should be approved to manipulate the token.
     * 
     * To prevent mistakes from happening, an implementation of {burnToken} should add a safeguard so that only an
     * account that is allowed to burn tokens AND is approved to maniputate the token should be able to call this
     * function.
     */
    function burnToken(bytes32 proofOfIntegrity) external returns (bool);

}

// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @author The Courtyard Team
 * @title {Checkout} allows generic checkouts using either the native cryptocurrency of the underlying blockchain
 * ex: ETH for Ethereum) or ERC20 tokens (ex: USDC, WETH, WBTC...) to pay for something.
 * 
 * It works as follows:
 * 
 *  1. A user starts the checkout process in a front-end application off-chain and is ready to pay using the native
 *     currency or one of the ERC20 tokens that are accepted for payment.
 * 
 *  2. Upon receiving a checkout request, a back-end service would typically generate a {signature} containing the
 *     following information:
 * 
 *      - {operatingContract}: the address of the appropriate checkout contract.
 *      - {checkoutId}: a unique identifier for that checkout. The {checkoutId} is used to guarantee that each checkout
 *        would not be processed multiple times accidentally.
 *      - {authorizedPayer}: the account (i.e. address) that will be given the autorization to pay.
 *      - {paymentToken}: the address of the ERC20 token used for payment, or address(0) if the native currency is used.
 *      - {paymentValue}: a uint256 representing the payment value in the smallest unit of the associated currency.
 *        Note that all currencies are not equal: for example ETH has 18 decimals while USDC only has 6.
 *        The appropriate uint256 value must be correctly generated by the caller of the checkout contract beforehand.
 *      - {expirationTimestamp}: timestamp in seconds from epoch after which the checkout cannot be completed anymore.
 *      - {postCheckoutCallData}: the input bytes used to call a {_postCheckoutAction} function immediately after the
 *        checkout has been processed. This is used when an on-chain action needs to happen post-checkout.
 * 
 *  4. The backend sends the signed data along with {signature} back to the front-end application so the transaction
 *     can be executed.
 * 
 *  5. On the front end:
 * 
 *      - (optional, if the payment is to be executed with an ERC20 token): the user is first prompted to approve the
 *        appropriate token allowance to the checkout contract (this does not happen for a native currency checkout).
 *      - The user is then prompted to sign the checkout transaction.
 * 
 *  6. During the on-chain transaction:
 * 
 *      - If everything is in order according to the checkout contract processing the request, the funds are withdrawn
 *        and sent to a receiver wallet.
 *      - Then the {_postCheckoutAction} function is executed before returning. A child contract can implement it
 *        however it sees fit. For example, a minter contract could mint a token at the end of the checkout.
 *      - Finally, the {checkoutId} is marked as processed and a {CheckoutSuccess} event is emitted.
 *  
 *  7. The user now has a successful transaction hash that is a "proof of payment" that can be used to retrieve the 
 *    full transaction result on a block explorer, containing all the information relevant to the checkout, including
 *    the emitted events. This is alike a transaction receipt.
 */
abstract contract Checkout is Pausable, Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    event PaymentReceiverUpdated(address indexed oldAddress, address indexed newAddress);
    event CheckoutOracleUpdated(address indexed oldAddress, address indexed newAddress);
    event PaymentProcessed(address indexed from, address indexed to, address indexed token, uint256 amount);
    event CheckoutSuccess(address indexed caller, string checkoutId);

    /**
     * @dev using a struct to encapsulate all the data that is used to encode a checkout signature.
     */
    struct CheckoutRequest {
        address operatingContract;      // the contract that is supposed to process the given request.
        string checkoutId;              // the id of the checkout.
        address authorizedPayer;        // the account that is authorized to complete this checkout.
        address paymentToken;           // address(0) for the native cryptocurrency (ex: ETH for Ethereum).
        uint256 paymentValue;           // the payment value in the smallest unit of the associated currency.
        uint256 expirationTimestamp;    // expiration timestamp of the request.
        bytes postCheckoutCallData;     // encoded input data to the post-checkout action. Can be empty.
    }

    address public paymentReceiver;         // the account that will be transferred the payments.
    address public checkoutOracle;          // the account that delivers signed messages to enable checkouts.
    mapping(bytes32 => bool) processed;     // mapping of all the checkouts that were processed to avoid duplicate charges.

    /**
     * @dev modifier to ensure the input address is the non null address.
     * @param addr the address to verify as non null.
     */
    modifier nonNullAddress(address addr) {
        require(addr != address(0), "Checkout: Non null address required.");
        _;
    }


    /* ========================================== CONSTRUCTOR AND SETTERS ========================================== */

    /**
     * @dev constructor.
     * @param paymentReceiver_ the address of the payment receiver account.
     * @param checkoutOracle_ the address of the checkout oracle account.
     */
    constructor(
        address paymentReceiver_,
        address checkoutOracle_
    ) Ownable() nonNullAddress(paymentReceiver_) nonNullAddress(checkoutOracle_) {
        paymentReceiver = paymentReceiver_;
        checkoutOracle = checkoutOracle_;
    }

    /**
     * @dev update the payment receiver address.
     * @param newReceiver the address of the new payment receiver account.
     * 
     * Requirements:
     * 
     *      - {newReceiver} cannot be the null address.
     */
    function updatePaymentReceiver(address newReceiver) public onlyOwner nonNullAddress(newReceiver) {
        address oldReceiver = paymentReceiver;
        paymentReceiver = newReceiver;
        emit PaymentReceiverUpdated(oldReceiver, paymentReceiver);
    }

    /**
     * @dev update the checkout oracle address.
     * @param newOracle the address of the new checkout oracle account.
     * 
     * Requirements:
     * 
     *      - {newOracle} cannot be the null address.
     */
    function updateCheckoutOracle(address newOracle) public onlyOwner nonNullAddress(newOracle) {
        address oldOracle = checkoutOracle;
        checkoutOracle = newOracle;
        emit CheckoutOracleUpdated(oldOracle, checkoutOracle);
    }


    /* ============================================= PAUSABLE HELPERS ============================================= */

    /**
     * @dev pause the contract
     * 
     * Requirements:
     * 
     *      - Only the owner of the contract can pause it. 
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause the contract
     * 
     * Requirements:
     * 
     *      - Only the owner of the contract can unpause it. 
     */
    function unpause() public onlyOwner {
        _unpause();
    }


    /* ========================================= CHECKOUT REQUEST HELPERS ========================================= */

    /**
     * @dev helper to encode a checkout hash for both {encodeErc20CheckoutRequest} and {encodeNativeCheckoutRequest}.
     * @param checkoutId the checkout id.
     * @param authorizedPayer the account that is authorized to complete this checkout.
     * @param paymentToken the address of the payment token, or address(0) for the native cryptocurrency.
     * @param paymentValue the payment value in the smallest unit of the associated currency
     * @param expirationTimestamp the expiration timestamp after which this checkout request is no longer valid.
     * @param postCheckoutCallData the input for {_postCheckoutAction}.
     * @return the encoded checkout request as bytes, ready to be signed by the checkout oracle.
     */
    function _encodeCheckoutRequest(
        string memory checkoutId,
        address authorizedPayer,
        address paymentToken,
        uint256 paymentValue,
        uint256 expirationTimestamp,
        bytes calldata postCheckoutCallData
    ) private view returns (bytes memory) {
        return abi.encode(
            CheckoutRequest(
                address(this),
                checkoutId,
                authorizedPayer,
                paymentToken,
                paymentValue,
                expirationTimestamp,
                postCheckoutCallData
            )
        );  
    }

    /**
     * @dev modifier to ensure that a checkout request signature is valid.
     * @param requestData the checkout request as bytes.
     * @param signature the signature block of {requestData}, signed by teh checkout oracle.
     */
    modifier onlyValidSignature(
        bytes memory requestData,
        bytes memory signature
    ) {
        bytes32 expectedSignedMessage = ECDSA.toEthSignedMessageHash(requestData);
        require(ECDSA.recover(expectedSignedMessage, signature) == checkoutOracle, "Checkout: Invalid signature.");
        _;
    }

    /**
     * @dev helper to check the eligibility of a checkout request.
     * @param request the checkout request data as bytes.
     * 
     * Requirements:
     * 
     *      - {request.operatingContract} must be this contract.
     *      - {caller} must be {request.authorizedPayer}, i.e. the account authorized to complete this checkout.
     *      - {request.checkoutId} must not have been marked as processed.
     *      - {request.expirationTimestamp} must not have passed. 
     */
    function _checkEligibility(address caller, CheckoutRequest memory request) private view {
        require(request.operatingContract == address(this), "Checkout: Contract is not authorized to process this request.");
        require(caller == request.authorizedPayer, "Checkout: Caller is not authorized to complete this checkout.");
        require(!exists(request.checkoutId), "Checkout: Checkout with checkoutId was already processed.");
        require(request.expirationTimestamp >= block.timestamp, "Checkout: Checkout time window has expired.");
    }


    /* ============================================ CHECKOUT ID HELPERS ============================================ */

    /**
     * @dev helper to compute the hash of a {checkoutId}.
     * @param checkoutId the checkout id.
     * @return a keccak256 hash of the checkout id.
     */
    function _checkoutIdHash(string memory checkoutId) private pure returns (bytes32) {
        return keccak256(abi.encode(checkoutId));
    }

    /**
     * @dev helper to check if a checkoutId exists, i.e. if the checkout for that id was completed.
     * @param checkoutId the checkout id.
     * @return true if {checkoutId} has been processed, false otherwise.
     */
    function exists(string memory checkoutId) public view returns (bool) {
        return processed[_checkoutIdHash(checkoutId)];
    }


    /* ============================================== ERC20 CHECKOUT ============================================== */

    /**
     * @dev creates and encode a {CheckoutRequest} for a checkout to be paid using an ERC20 token.
     * The {CheckoutRequest} is returned in an encoded form (bytes) and must be signed by the {checkoutOracle} to
     * authorize a checkout. That signature is then fed to {erc20Checkout} along with the encoded {CheckoutRequest} 
     * to be validated before proceeding with the checkout.
     * @param checkoutId the checkout id.
     * @param authorizedPayer the account that is authorized to complete this checkout.
     * @param paymentToken the address of the payment token, or address(0) for the native cryptocurrency.
     * @param paymentValue the payment value in the smallest unit of the associated currency
     * @param expirationTimestamp the expiration timestamp after which this checkout request is no longer valid.
     * @param postCheckoutCallData the input for {_postCheckoutAction}.
     * @return the encoded checkout request as bytes, ready to be signed by the checkout oracle.
     *
     * Notes:
     * 
     *      - A {Checkout} implementation should define its own helper to generate {postCheckoutCallData}.
     *      - The returned encoded {CheckoutRequest} needs to be signed by {checkoutOracle} to be valid.
     *      - If {data} is the result of this function, checkoutOracleAccount.signMessage(ethers.utils.arrayify(data))
     *        must be called in order to properly encode the hash before signing it.
     */
    function encodeErc20CheckoutRequest(
        string calldata checkoutId,
        address authorizedPayer,
        address paymentToken,
        uint256 paymentValue,
        uint256 expirationTimestamp,
        bytes calldata postCheckoutCallData
    ) public view returns (bytes memory) {
        return _encodeCheckoutRequest(checkoutId, authorizedPayer, paymentToken, paymentValue, expirationTimestamp, postCheckoutCallData);
    }

    /**
     * @dev checkout with an ERC20 token.
     * @param requestData the checkout request as bytes.
     * @param signature the signature block of {requestData}, signed by teh checkout oracle.
     */
    function erc20Checkout(
        bytes calldata requestData,
        bytes calldata signature
    ) external nonReentrant whenNotPaused onlyValidSignature(requestData, signature) {
        CheckoutRequest memory request = abi.decode(requestData, (CheckoutRequest));
        address caller = _msgSender();
        _checkEligibility(caller, request);
        require(request.paymentToken != address(0), "Checkout: Wrong call - use nativeCheckout() to pay with the native cryptocurrency.");
        IERC20(request.paymentToken).safeTransferFrom(caller, paymentReceiver, request.paymentValue);
        emit PaymentProcessed(caller, paymentReceiver, request.paymentToken, request.paymentValue);
        _wrapUp(caller, request.checkoutId, request.postCheckoutCallData);
    }


    /* ============================================== NATIVE CHECKOUT ============================================== */

    /**
     * @dev creates and encode a {CheckoutRequest} for a checkout to be paid using a native cryptocurrency.
     * The {CheckoutRequest} is returned in an encoded form (bytes) and must be signed by the {checkoutOracle} to
     * authorize a checkout. That signature then is fed to {erc20Checkout} along with the encoded {CheckoutRequest} 
     * to be validated before proceeding with the checkout.
     * @param checkoutId the checkout id.
     * @param authorizedPayer the account that is authorized to complete this checkout.
     * @param paymentValue the payment value in the smallest unit of the associated currency
     * @param expirationTimestamp the expiration timestamp after which this checkout request is no longer valid.
     * @param postCheckoutCallData the input for {_postCheckoutAction}.
     * @return the encoded checkout request as bytes, ready to be signed by the checkout oracle.
     * 
     * Notes:
     *
     *      - A {Checkout} implementation should define its own helper to generate {postCheckoutCallData}.
     *      - The returned encoded {CheckoutRequest} needs to be signed by {checkoutOracle} to be valid.
     *      - If {data} is the result of this function, checkoutOracleAccount.signMessage(ethers.utils.arrayify(data))
     *        must be called in order to properly encode the hash before signing it.
     *      - Calling this function externally is the same as calling encodeErc20CheckoutRequest with address(0) as
     *        the {paymentToken}. This is not a bug, just an incidental feature.
     */
    function encodeNativeCheckoutRequest(
        string calldata checkoutId,
        address authorizedPayer,
        uint256 paymentValue,
        uint256 expirationTimestamp,
        bytes calldata postCheckoutCallData
    ) public view returns (bytes memory) {
        return _encodeCheckoutRequest(checkoutId, authorizedPayer, address(0), paymentValue, expirationTimestamp, postCheckoutCallData);
    }

    /**
     * @dev checkout with the native cryptocurrency (ex: ETH for Ethereum).
     * @param requestData the checkout request as bytes.
     * @param signature the signature block of {requestData}, signed by teh checkout oracle.
     * 
     * Notes:
     * 
     *      - We could have chosen to send a refund if the user sends too much funds, but because we expect the funds
     *        to match exactly what is requested via the signature and we do not expect users to call the contract
     *        directly on their own, not sending the exact required funds will always result in a failure.
     */
    function nativeCheckout(
        bytes calldata requestData,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused onlyValidSignature(requestData, signature) {
        CheckoutRequest memory request = abi.decode(requestData, (CheckoutRequest));
        address caller = _msgSender();
        _checkEligibility(caller, request);
        require(request.paymentToken == address(0), "Checkout: Wrong call - use erc20Checkout() to pay with an ERC20 token.");
        require(msg.value == request.paymentValue, "Checkout: Unexpected payment value received.");
        payable(paymentReceiver).transfer(msg.value);
        emit PaymentProcessed(caller, paymentReceiver, request.paymentToken, request.paymentValue);
        _wrapUp(caller, request.checkoutId, request.postCheckoutCallData);
    }


    /* ================================================== WRAP UP ================================================== */

    /**
     * @dev wrap up the checkout by calling {_postCheckoutAction} and marking the checkout as processed.
     * @param caller the account that is checking out.
     * @param checkoutId the checkout id.
     * @param postCheckoutCallData the input to {_postCheckoutAction}. 
     */
    function _wrapUp(address caller, string memory checkoutId, bytes memory postCheckoutCallData) private {
        _postCheckoutAction(checkoutId, postCheckoutCallData);
        processed[_checkoutIdHash(checkoutId)] = true;
        emit CheckoutSuccess(caller, checkoutId);
    }

    /**
     * @dev a post-checkout function that is called at the end of {erc20Checkout} or {nativeCheckout}.
     * @param checkoutId the checkout id.
     * @param data the encoded input data to the post-checkout action.
     * 
     * Notes:
     * 
     *      - This paradigm gives some flexibility for a child contract to implement their own post-checkout logic.
     *        For example, a minting contract could mint a token immediately after a successful check out, or call an
     *        external contract to perform an action.
     *      - The input argument {data} may need to be decoded before being used by a child contract.
     *      - If nothing needs to happen post-checkout, this function can simply be implemented with an empty body.
     */
     function _postCheckoutAction(string memory checkoutId, bytes memory data) internal virtual;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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