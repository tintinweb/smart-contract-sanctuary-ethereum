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
pragma solidity >=0.8.0;

import "./Ownable.sol";

contract AccessControl is Ownable {

    event GrantAdminRole(address indexed account);
    event RevokeAdminRole(address indexed account);

    mapping(address => bool) private admin;

    modifier onlyAdmin() {
        require(admin[msg.sender] == true, "unauthorized");
        _;
    }

    function grantRole(address _account) internal onlyOwner returns (bool valid) {
        admin[_account] = true;
        emit GrantAdminRole(_account);

        valid = true;
    }

    function revokeRole(address _account) internal onlyOwner returns (bool valid) {
        admin[_account] = false;
        emit RevokeAdminRole(_account);

        valid = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {EventsAndErrors} from "./EventsAndErrors.sol";

contract Base is EventsAndErrors {
    //Declare constants for name, version
    string internal constant _NAME = "Lending";
    string internal constant _VERSION = "1.0";

    //Precompure hasehs, original chainId, and domain separator on deployment
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    bytes32 internal immutable _LEND_TYPEHASH;

    constructor() {
        (
            _NAME_HASH,
            _VERSION_HASH,
            _EIP_712_DOMAIN_TYPEHASH,
            _DOMAIN_SEPARATOR,
            _LEND_TYPEHASH
        ) = _deriveTypeHashes();

        _CHAIN_ID = block.chainid;
    }

    function _deriveTypeHashes()
        internal
        view
        returns (
            bytes32 nameHash,
            bytes32 versionHash,
            bytes32 eip712DomainTypeHash,
            bytes32 domainSeparator,
            bytes32 lendTypeHash
        )
    {
        nameHash = keccak256(bytes(_NAME));

        versionHash = keccak256(bytes(_VERSION));

        lendTypeHash = keccak256(
            abi.encodePacked(
                "LendComponents(",
                "address lender,"
                "address tokenOwner,"
                "address token,"
                "uint256 initialAmount,",
                "uint256 totalAmount,",
                "uint256 lendDuration,",
                "uint256 tokenIdentifier,"
                "uint256 salt"
                ")"
            )
        );

        eip712DomainTypeHash = keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

        domainSeparator = _deriveInitialDomainSeparator(
            eip712DomainTypeHash,
            nameHash,
            versionHash
        );
    }

    function _deriveInitialDomainSeparator(
        bytes32 _eip712DomainTypeHash,
        bytes32 _nameHash,
        bytes32 _versionHash
    ) internal view returns (bytes32 domainSeparator) {
        return
            _deriveDomainSeparator(
                _eip712DomainTypeHash,
                _nameHash,
                _versionHash
            );
    }

    function _deriveDomainSeparator(
        bytes32 _eip712DomainTypeHash,
        bytes32 _nameHash,
        bytes32 _versionHash
    ) internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _eip712DomainTypeHash,
                    _nameHash,
                    _versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _name() internal pure virtual returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x47, 0x074c656e64696e67)
            return(0x20, 0x60)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {BasicLendRealize} from "./BasicLendRealize.sol";
import {BasicLendParameters} from "./Struct.sol";
import {BasicLendInterface} from "./BasicLendInterface.sol";

contract BasicLend is BasicLendInterface, BasicLendRealize {
    constructor() BasicLendRealize() {}

    function proposeConfirm(BasicLendParameters calldata parameters)
        external
        payable
        override
        returns (bool confirmed)
    {
        confirmed = _proposeConfirm(parameters);
    }

    function withdraw(BasicLendParameters calldata parameters)
        external
        override
        returns (bool withdrawed)
    {
        withdrawed = _withdraw(parameters);
    }

    function proposePayment(BasicLendParameters calldata parameters)
        external
        payable
        override
        returns (bool paid)
    {
        paid = _repayment(parameters);
    }

    function name() external pure override returns (string memory lending) {
        lending = _name();
    }

    function getLendHash(BasicLendParameters calldata parameters)
        external
        view
        override
        returns (bytes32 lendHash)
    {
        lendHash = _getLendHash(parameters);
    }

    function repaymentStatus(bytes32 lendHash)
        external
        view
        override
        returns (bool status, uint256 paidAmount)
    {
        return _repaymentStatus(lendHash);
    }

    /**
     * Admin ROLE
     */
    function grantAdmin(address account) external override returns (bool granted) {
        granted = grantRole(account);
    }

    function revokeAdmin(address account) external override returns (bool revoked) {
        revoked = revokeRole(account);
    }

    function pause() external override returns (bool status) {
        status = _pause();
    }

    function unpause() external override returns (bool status) {
        status = _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {BasicLendParameters} from "./Struct.sol";

contract BasicLendInterface {
    /**
     * Lender
     */
    function proposeConfirm(BasicLendParameters calldata parameters)
        external
        payable
        virtual
        returns (bool confirmed)
    {}

    function withdraw(BasicLendParameters calldata parameters)
        external
        virtual
        returns (bool withdrawed)
    {}

    /**
     * Nft Owner
     */
    // function proposeAccept() external returns (bool valid){}

    function proposePayment(BasicLendParameters calldata parameters)
        external
        payable
        virtual
        returns (bool paid)
    {}

    function name() external pure virtual returns (string memory lending) {}

    function getLendHash(BasicLendParameters calldata parameters)
        external
        view
        virtual
        returns (bytes32 lendHash)
    {}

    function repaymentStatus(bytes32 lendHash)
        external
        view
        virtual
        returns (bool status, uint256 paidAmount)
    {}

    /**
     * Admin ROLE
     */
    function grantAdmin(address account) external virtual returns (bool granted) {}

    function revokeAdmin(address account) external virtual returns  (bool revoked) {}

    function pause() external virtual returns (bool paused) {}

    function unpause() external virtual returns (bool unpaused) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {BasicLendParameters, FulfillmentHashes} from "./Struct.sol";
import {BasicLendValidator} from "./BasicLendValidator.sol";

contract BasicLendRealize is BasicLendValidator {
    constructor() BasicLendValidator() {}

    function _proposeConfirm(BasicLendParameters calldata parameters)
        internal
        returns (bool valid)
    {
        // _verifyTime(parameters.endTime, true);

        //Derives parameters into hashes
        _prepareBasicFulfillment(parameters);

        if (msg.value < parameters.initialAmount) {
            revert InsufficientValue();
        }

        // Check if the address is a valid lender
        if (msg.sender != parameters.lender) {
            revert InvalidLender();
        }

        _transferERC721(
            parameters.token,
            parameters.tokenOwner,
            address(this),
            parameters.tokenIdentifier,
            false
        );

        //Transfer ether to NFT owner
        _executeTransferEth(parameters.tokenOwner, parameters.initialAmount);

        valid = true;
    }

    function _withdraw(BasicLendParameters calldata parameters)
        internal
        returns (bool valid)
    {
        // _verifyExceedTime(parameters.endTime, true);

        //Memory store hashes
        FulfillmentHashes memory hashes;

        {
            hashes.typeHash = _LEND_TYPEHASH;
            hashes.lendHash = _hashLend(hashes, parameters);
        }

        if (msg.sender == parameters.tokenOwner) {
            _withdrawERC721ToOriginalOwner(
                parameters.tokenIdentifier,
                parameters.token,
                hashes.lendHash
            );
        } else if (msg.sender == parameters.lender) {
            _withdrawERC721ToLender(
                parameters.tokenIdentifier,
                parameters.token,
                hashes.lendHash
            );
        } else {
            revert InvalidCaller();
        }

        valid = true;
    }

    function _repayment(BasicLendParameters calldata parameters)
        internal
        returns (bool valid)
    {
        uint256 etherSupplied = msg.value;

        // _verifyTime(parameters.endTime, true);

        if (etherSupplied == 0) {
            revert InvalidMsgValue();
        }

        if (msg.sender != parameters.tokenOwner) {
            revert CallerIsNotLoaner();
        }

        _prepareBasicFulfillment(parameters);
        _repaymentBasicFulfillment(parameters);

        valid = true;
    }

    function _repaymentBasicFulfillment(BasicLendParameters calldata parameters)
        internal
    {
        //Memory store hashes
        FulfillmentHashes memory hashes;

        {
            hashes.typeHash = _LEND_TYPEHASH;

            hashes.lendHash = _hashLend(hashes, parameters);
        }

        _validateAndUpdateRepayment(
            hashes.lendHash,
            parameters.totalAmount,
            parameters.lender
        );
    }

    function _prepareBasicFulfillment(BasicLendParameters calldata parameters)
        internal
    {
        // Memory to store hashes
        FulfillmentHashes memory hashes;

        {
            hashes.typeHash = _LEND_TYPEHASH;

            //Derive lending hash
            hashes.lendHash = _hashLend(hashes, parameters);
        }

        _validateLendAndUpdateStatus(
            hashes.lendHash,
            parameters.lender,
            parameters.signature,
            parameters.lendDuration
        );

        // _updateLendHashFulfilled(hashes.lendHash);
    }

    function _getLendHash(BasicLendParameters calldata parameters)
        internal
        view
        returns (bytes32 lendHash)
    {
        FulfillmentHashes memory hashes;

        {
            hashes.typeHash = _LEND_TYPEHASH;
            hashes.lendHash = _hashLend(hashes, parameters);
        }

        lendHash = hashes.lendHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Executor} from "./Executor.sol";
import {LendStatus, LoanerComponents} from "./Struct.sol";

contract BasicLendValidator is Executor {
    //Track lending activity
    mapping(bytes32 => LendStatus) private _lendStatus;
    mapping(bytes32 => LoanerComponents) private _loaner;
    mapping(bytes32 => uint256) public _lendDuration;

    constructor() Executor() {}

    function _validateLendAndUpdateStatus(
        bytes32 lendHash,
        address lender,
        bytes memory signature,
        uint256 lendDuration
    ) internal {
        LendStatus storage lendStatus = _lendStatus[lendHash];

        //Ensure lend is fillable
        _verifyLendStatus(lendHash, lendStatus);

        //Lending time duration start now!
        if (_lendDuration[lendHash] == 0) {
            _lendDuration[lendHash] = block.timestamp + lendDuration;
        }

        if (!lendStatus.isValidated) {
            _verifySignature(lender, lendHash, signature);
        }

        lendStatus.isValidated = true;
        lendStatus.isFulfilled = false;

        emit LendingEndTime(_lendDuration[lendHash]);
    }

    function _updateLendHashFulfilled(bytes32 lendHash) internal {
        LendStatus storage lendStatus = _lendStatus[lendHash];

        lendStatus.isFulfilled = true;
    }

    function _withdrawERC721ToOriginalOwner(
        uint256 tokenIdentifier,
        address token,
        bytes32 lendHash
    ) internal {
        LoanerComponents storage loaner = _loaner[lendHash];

        _verifyExceedTime(_lendDuration[lendHash], true);

        if (loaner.status == false) {
            revert AmountNotFullyPaid();
        }

        _transferERC721(
            token,
            address(this),
            msg.sender,
            tokenIdentifier,
            true
        );
    }

    function _withdrawERC721ToLender(
        uint256 tokenIdentifier,
        address token,
        bytes32 lendHash
    ) internal {
        LoanerComponents storage loaner = _loaner[lendHash];

        _verifyExceedTime(_lendDuration[lendHash], true);

        if (loaner.status == true) {
            revert AmountFullyPaid();
        }

        _transferERC721(
            token,
            address(this),
            msg.sender,
            tokenIdentifier,
            true
        );

        /**
         * No need to refund back for this version
         */
        // if (amountPaid != 0) {
        //     _executeTransferEth(tokenOwner, amountPaid);
        // }
    }

    function _validateAndUpdateRepayment(
        bytes32 lendHash,
        uint256 totalAmount,
        address payable lender
    ) internal {
        LoanerComponents storage loaner = _loaner[lendHash];

        if (loaner.status == true) {
            revert AmountFullyPaid();
        }

        _verifyTime(_lendDuration[lendHash], true);

        //Update amount paid
        uint256 updateAmountPaid = loaner.amountPaid + msg.value;

        _executeTransferEth(lender, msg.value);

        if (totalAmount <= updateAmountPaid) {
            _loaner[lendHash] = LoanerComponents(updateAmountPaid, true);
        } else {
            _loaner[lendHash].amountPaid = updateAmountPaid;
        }
    }

    function _executeTransferEth(address payable to, uint256 amount) internal {
        uint256 etherSupplied = msg.value;

        _transferEth(to, amount);

        //If got remaining ether, refund to the caller
        if (etherSupplied > amount) {
            unchecked {
                _transferEth(payable(msg.sender), (etherSupplied - amount));
            }
        }
    }

    function _repaymentStatus(bytes32 lendHash)
        internal
        view
        returns (bool status, uint256 repaymentUpdate)
    {
        status = _loaner[lendHash].status;
        repaymentUpdate = _loaner[lendHash].amountPaid;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Base} from "./Base.sol";

import {BasicLendParameters, FulfillmentHashes} from "./Struct.sol";

contract Derivers is Base {
    uint256 constant EIP_712_PREFIX = (
        0x1901000000000000000000000000000000000000000000000000000000000000
    );

    function _deriveEIP712Digest(bytes32 domainSeparator, bytes32 orderHash)
        internal
        pure
        returns (bytes32 value)
    {
        //Leverage scratch space to perform an efficient hash
        assembly {
            mstore(0, EIP_712_PREFIX) //2 bytes
            mstore(0x02, domainSeparator) //Offset by 2 bytes
            mstore(0x22, orderHash)

            value := keccak256(0, 0x42)

            mstore(0x22, 0)
        }
    }

    function _domainSeparator() internal view returns (bytes32) {
        return
            block.chainid == _CHAIN_ID
                ? _DOMAIN_SEPARATOR
                : _deriveDomainSeparator(
                    _EIP_712_DOMAIN_TYPEHASH,
                    _NAME_HASH,
                    _VERSION_HASH
                );
    }

    function _hashLend(
        FulfillmentHashes memory hashes,
        BasicLendParameters memory parameters
    ) internal pure returns (bytes32 lendHash) {
        lendHash = keccak256(
            abi.encode(
                hashes.typeHash,
                parameters.lender,
                parameters.tokenOwner,
                parameters.token,
                parameters.initialAmount,
                parameters.totalAmount,
                parameters.lendDuration,
                parameters.tokenIdentifier,
                parameters.salt
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface EIP1271Interface {
    function isValidSignature(bytes32 digest, bytes calldata signature)
        external
        view
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface EventsAndErrors {
    error InvalidTime();
    error InvalidExceedTime();
    error CallerIsNotLender();
    error CallerIsNotTokenOwner();
    error CallerIsNotLoaner();
    error InvalidAmount();
    error InvalidLender();
    error InsufficientValue();
    error InvalidAddress();
    error InvalidCaller();
    error InvalidMsgValue();
    error AmountFullyPaid();
    error AmountNotFullyPaid();

    error LendIsFulfilled(bytes32 lendHash);

    event LendingEndTime(uint256 endTime);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Verifiers} from "./Verifiers.sol";
import {TokenTransferrer} from "./TokenTransferrer.sol";

contract Executor is Verifiers, TokenTransferrer {
    function _transferEth(address payable to, uint256 amount) internal {
        //Ensure the supplied amount is non zero
        _assertNonZeroAmount(amount);

        (bool success, ) = to.call{value: amount}("");

        //If call fail
        if (!success) {
            revert EtherTransferFailure(to, amount);
        }
    }

    function _transferERC721(
        address token,
        address from,
        address to,
        uint256 identifier,
        bool approvalToCurrentOwner
    ) internal {
        _performERC721Transfer(
            token,
            from,
            to,
            identifier,
            approvalToCurrentOwner
        );
    }

    /**
     * @dev Internal function to check if the ether amount is non-zero
     *      Assertion.
     *
     * @param amount       The amount to check
     */
    function _assertNonZeroAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert MissingItemAmount();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Ownable {

    // Owner of the contract
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    constructor() {
        setOwner(msg.sender);
    }

    function owner() internal view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./AccessControl.sol";

contract Pausable is AccessControl {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    function _pause() internal onlyAdmin returns (bool valid) {
        paused = true;
        emit Pause();

        valid = true;
    }

    function _unpause() internal onlyAdmin returns (bool valid) {
        paused = false;
        emit Unpause();

        valid = true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SignatureVerificationErrors} from "./SignatureVerificationErrors.sol";
import {EIP1271Interface} from "./EIP1271Interface.sol";

contract SignatureVerification is SignatureVerificationErrors {
    //Signature-related
    bytes32 constant EIP2098_allButHighestBitMask = (
        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    );

    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signer.code.length > 0) {
            _assertValidEIP1271Signature(signer, digest, signature);

            return;
        } else if (signature.length == 64) {
            bytes32 vs;

            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            s = vs & EIP2098_allButHighestBitMask;

            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            //Ensure the value is properly formatted
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
        } else {
            revert InvalidSignature();
        }

        address recoveredSigner = ecrecover(digest, v, r, s);

        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            revert InvalidSigner();
        }
    }

    function _assertValidEIP1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        if (
            EIP1271Interface(signer).isValidSignature(digest, signature) !=
            EIP1271Interface.isValidSignature.selector
        ) {
            revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface SignatureVerificationErrors {
    error BadSignatureV(uint8 v);
    error InvalidSigner();
    error InvalidSignature();
    error BadContractSignature();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct BasicLendParameters {
    address payable lender;
    address payable tokenOwner;
    address token; //ERC721 address
    uint256 initialAmount;
    uint256 totalAmount;
    uint256 lendDuration;
    uint256 tokenIdentifier;
    uint256 salt;
    bytes signature;
}

struct LendComponents {
    address lender;
    address tokenOwner;
    address token;
    uint256 initialAmount;
    uint256 totalAmount;
    uint256 lendDuration;
    uint256 tokenIdentifier;
    uint256 salt;
}

struct LoanerComponents {
    uint256 amountPaid;
    bool status;
}

struct LendStatus {
    bool isValidated;
    bool isFulfilled;
}

struct FulfillmentHashes {
    bytes32 typeHash;
    bytes32 lendHash;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {TokenTransferrerErrors} from "./TokenTransferrerErrors.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TokenTransferrer is TokenTransferrerErrors {
    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        bool approvalToCurrentOwner
    ) internal {
        if (token.code.length == 0) {
            revert NoContract(token);
        }

        if (approvalToCurrentOwner == false) {
            // Check if token identifier already approved by this address or not
            if (IERC721(token).getApproved(identifier) != address(this)) {
                revert RequireOwnerApproval();
            }
        }

        IERC721(token).transferFrom(from, to, identifier);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TokenTransferrerErrors {
    error EtherTransferFailure(address to, uint256 amount);

    error NoContract(address token);

    error MissingItemAmount();

    error InsufficientEtherSupplied();

    error RequireOwnerApproval();

    error CallerIsTokenOwner();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {LendStatus} from "./Struct.sol";

import {Derivers} from "./Derivers.sol";
import {SignatureVerification} from "./SignatureVerification.sol";
import {Pausable} from "./Pausable.sol";

contract Verifiers is Derivers, SignatureVerification, Pausable {
    constructor() Derivers() {}

    function _verifyTime(uint256 endTime, bool revertOnInvalid)
        internal
        view
        returns (bool valid)
    {
        if (endTime <= block.timestamp) {
            if (revertOnInvalid) {
                revert InvalidTime();
            }
            return false;
        }
        return true;
    }

    function _verifyExceedTime(uint256 endTime, bool revertOnInvalid)
        internal
        view
        returns (bool valid)
    {
        if (endTime >= block.timestamp) {
            if (revertOnInvalid) {
                revert InvalidExceedTime();
            }
            return false;
        }
        return true;
    }

    function _verifyLendStatus(bytes32 lendHash, LendStatus storage lendStatus)
        internal
        view
        returns (bool valid)
    {
        if (lendStatus.isFulfilled) {
            revert LendIsFulfilled(lendHash);
        }

        valid = true;
    }

    function _verifySignature(
        address lender,
        bytes32 lendHash,
        bytes memory signature
    ) internal view {
        // Skip signature verification if the lender is the caller
        if (lender == msg.sender) {
            return;
        }

        bytes32 digest = _deriveEIP712Digest(_domainSeparator(), lendHash);

        //Ensure the signature for the digest is valid for the lender
        _assertValidSignature(lender, digest, signature);
    }
}