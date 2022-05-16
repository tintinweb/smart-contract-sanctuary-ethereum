// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IDocumentVerificationManagement.sol";
import "./SignatureSet.sol";
import "./Search.sol";

/**
 * @title Document verification contract for verifying contract with their hash values
 */
contract DocumentVerification is IDocumentVerificationManagement {
    using SignatureSet for SignatureSet.SignSet;
    using Search for address[];

    error LateToExecute(uint256 executeTime);
    error SignerIsNotRequested();
    error SignerAlreadySigned();
    error SignerDidNotSigned();
    error InvalidDocument();
    error CallerIsNotManagement();
    error CallerIsNotDocumentCreator();
    error DocumentCreatorAllowanceNotEnough();
    error DocumentIsAlreadyOnVerification();
    error RequestedSignersAreNotEnough(uint256 sentLength, uint256 requiredLength);

    uint256 public constant MIN_VOTER_COUNT = 1;

    /// @dev Enum for holding different verification types
    enum VerificationType {
        INVALID,
        MULTISIG,
        VOTING
    }

    /**
     * @dev This struct holds information about the document
     * @param verificationCreatedAt Creation time for the verification
     * @param verificationDeadline Deadline for the signing period
     * @param documentDeadline Deadline for the document validity
     * @param verificationType See {VerificationType}
     * @param requestedSigners List of addresses that are allowed to sign this document
     */
    struct Document {
        uint128 verificationCreatedAt;
        uint128 verificationDeadline;
        uint128 documentDeadline;
        VerificationType verificationType;
        address[] requestedSigners;
    }

    /// A mapping for storing documents for each hash
    mapping(bytes32 => Document) private _documents;
    /// A mapping for storing document signatures for each document
    mapping(bytes32 => SignatureSet.SignSet) private _signatures;

    /// A mapping for storing document creator list
    mapping(address => bool) private _documentCreators;
    /// A mapping for storing document creator allowance
    mapping(address => uint256) private _documentCreatorAllowance;

    /// Management contract address
    address public immutable management;

    /**
     * @dev Emitted when the document put on verification
     * @param documentHash The hash of the document
     * @param documentCreator The document creator address that put document on verification
     */
    event DocumentPutOnVerification(bytes32 indexed documentHash, address indexed documentCreator);
    /**
     * @dev Emitted when the document signed
     * @param documentHash The hash of the document
     * @param signer The document signer address
     */
    event DocumentSigned(bytes32 indexed documentHash, address indexed signer);
    /**
     * @dev Emitted when the document signed
     * @param documentHash The hash of the document
     * @param signRevoker The document sign revoker address
     */
    event DocumentSignRevoked(bytes32 indexed documentHash, address indexed signRevoker);

    constructor(address _management) {
        management = _management;
    }

    modifier onlyDocumentCreator() {
        if (!_documentCreators[msg.sender]) revert CallerIsNotDocumentCreator();
        _;
    }

    modifier onlyManagement() {
        if (msg.sender != management) revert CallerIsNotManagement();
        _;
    }

    modifier validDocument(bytes32 documentHash) {
        if (_documents[documentHash].verificationCreatedAt == 0) revert InvalidDocument();
        _;
    }

    /**
     * @dev Puts document to verification
     * @param documentHash hash of the document to put on verification
     * @param verificationDeadline deadline for the signing period
     * @param documentDeadline deadline for the document validity
     * @param verificationType see {VerificationType}
     * @param requestedSigners list of addresses that are allowed to sign this document
     */
    function putDocumentToVerification(
        bytes32 documentHash,
        uint128 verificationDeadline,
        uint128 documentDeadline,
        VerificationType verificationType,
        address[] calldata requestedSigners
    ) external onlyDocumentCreator {
        if (_documents[documentHash].verificationCreatedAt != 0) revert DocumentIsAlreadyOnVerification();
        if (requestedSigners.length < MIN_VOTER_COUNT)
            revert RequestedSignersAreNotEnough({
                sentLength: requestedSigners.length,
                requiredLength: MIN_VOTER_COUNT
            });
        if (_documentCreatorAllowance[msg.sender] == 0) revert DocumentCreatorAllowanceNotEnough();

        Document storage document = _documents[documentHash];

        document.verificationCreatedAt = uint128(block.timestamp);
        document.verificationDeadline = verificationDeadline;
        document.documentDeadline = documentDeadline;
        document.verificationType = verificationType;
        document.requestedSigners = requestedSigners;

        _documentCreatorAllowance[msg.sender]--;

        emit DocumentPutOnVerification(documentHash, msg.sender);
    }

    /**
     * @dev Signs the document (approves it's validity)
     * @param documentHash hash of the document to put on sign
     */
    function signDocument(bytes32 documentHash) external validDocument(documentHash) {
        Document memory document = _documents[documentHash];
        if (block.timestamp > document.verificationDeadline)
            revert LateToExecute({ executeTime: document.verificationDeadline });
        if (!_isSignerRequestedByDocument(documentHash, msg.sender)) revert SignerIsNotRequested();
        if (_isSignerSignedTheDocument(documentHash, msg.sender)) revert SignerAlreadySigned();

        // add signature to document
        SignatureSet.Sign memory sign = SignatureSet.Sign({ signer: msg.sender, timestamp: block.timestamp });
        _signatures[documentHash].add(sign);

        emit DocumentSigned(documentHash, msg.sender);
    }

    /**
     * @dev Revokes the sign from the document (approves it's validity)
     * @param documentHash hash of the document to revoke sign from
     */
    function revokeSign(bytes32 documentHash) external validDocument(documentHash) {
        Document memory document = _documents[documentHash];
        if (block.timestamp > document.verificationDeadline)
            revert LateToExecute({ executeTime: document.verificationDeadline });
        if (!_isSignerSignedTheDocument(documentHash, msg.sender)) revert SignerDidNotSigned();

        _signatures[documentHash].remove(msg.sender);

        emit DocumentSignRevoked(documentHash, msg.sender);
    }

    /// @dev See `IDocumentVerificationManagement-configureDocumentCreator`
    function configureDocumentCreator(address documentCreator, uint256 allowedAmount) external override onlyManagement {
        _documentCreators[documentCreator] = true;
        _documentCreatorAllowance[documentCreator] = allowedAmount;
    }

    /// @dev See `IDocumentVerificationManagement-removeDocumentCreator`
    function removeDocumentCreator(address documentCreator) external override onlyManagement {
        _documentCreators[documentCreator] = false;
        _documentCreatorAllowance[documentCreator] = 0;
    }

    /**
     * @dev Returns if the document is legit (checks the document  depending on `VerificationType`)
     * @param documentHash hash of the document to check legit status
     * @return legit the documents legit result
     */
    function isDocumentLegit(bytes32 documentHash) external view returns (bool legit) {
        Document memory document = _documents[documentHash];
        SignatureSet.SignSet storage signSet = _signatures[documentHash];

        if (block.timestamp < document.documentDeadline) {
            if (signSet.length() >= MIN_VOTER_COUNT) {
                if (document.verificationType == VerificationType.MULTISIG) {
                    legit = _multisigCheck(document, signSet);
                }
                if (document.verificationType == VerificationType.VOTING) {
                    legit = _votingCheck(document, signSet);
                }
            }
        }
    }

    /// @dev See `IDocumentVerificationManagement-documentCreatorAllowance`
    function documentCreatorAllowance(address documentCreator) external view override returns (uint256 allowance) {
        allowance = _documentCreatorAllowance[documentCreator];
    }

    /// @dev See `IDocumentVerificationManagement-isDocumentCreator`
    function isDocumentCreator(address documentCreator) external view override returns (bool result) {
        result = _documentCreators[documentCreator];
    }

    /**
     * @dev Returns the document from given hash
     * @param documentHash hash of the document
     * @return document the document
     */
    function getDocument(bytes32 documentHash) external view returns (Document memory document) {
        document = _documents[documentHash];
    }

    /**
     * @dev Returns the signers that signed the document
     * @param documentHash hash of the document
     * @return signers see {SignatureSet-Sign}
     */
    function getSigners(bytes32 documentHash) external view returns (SignatureSet.Sign[] memory signers) {
        signers = _signatures[documentHash].values();
    }

    /**
     * @dev Returns if the given `signer` requested by the document
     * @param documentHash hash of the document
     * @param signer the address of the signer to check
     * @return requested the result of the check
     */
    function _isSignerRequestedByDocument(bytes32 documentHash, address signer) private view returns (bool requested) {
        requested = _documents[documentHash].requestedSigners.contains(signer);
    }

    /**
     * @dev Returns if the given `signer` signed the document
     * @param documentHash hash of the document
     * @param signer the address of the signer to check
     * @return signed the result of the check
     */
    function _isSignerSignedTheDocument(bytes32 documentHash, address signer) private view returns (bool signed) {
        signed = _signatures[documentHash].contains(signer);
    }

    /**
     * @dev Returns if the document is valid for multi signature standards
     * @param document see {Document}
     * @param signSet see {SignatureSet-SignSet}
     * @return legit the documents legit result
     */
    function _multisigCheck(Document memory document, SignatureSet.SignSet storage signSet)
        private
        view
        returns (bool legit)
    {
        legit = document.requestedSigners.length == signSet.length();
    }

    /**
     * @dev Returns if the document is valid for voting standards
     * @param document see {Document}
     * @param signSet see {SignatureSet-SignSet}
     * @return legit the documents legit result
     */
    function _votingCheck(Document memory document, SignatureSet.SignSet storage signSet)
        private
        view
        returns (bool legit)
    {
        legit = (signSet.length() * 10e18) / document.requestedSigners.length > 5 * 10e17;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IDocumentVerificationManagement {
    /**
     * @dev Adds document creator with given `allowedAmount`
     * @param documentCreator document creator address
     * @param allowedAmount allowed document amount for document creator
     */
    function configureDocumentCreator(address documentCreator, uint256 allowedAmount) external;

    /**
     * @dev Removes document creator
     * @param documentCreator document creator address
     */
    function removeDocumentCreator(address documentCreator) external;

    /**
     * @dev Returns document creator allowance
     * @param documentCreator document creator address
     * @return allowance document creator allowance
     */
    function documentCreatorAllowance(address documentCreator) external view returns (uint256 allowance);

    /**
     * @dev Returns if the given address document creator
     * @param documentCreator document creator address
     * @return result document creator result
     */
    function isDocumentCreator(address documentCreator) external view returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SignatureSet {
    struct Sign {
        address signer;
        uint256 timestamp;
    }

    struct SignSet {
        // Storage of set values
        Sign[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    function add(SignSet storage self, Sign memory value) internal returns (bool) {
        if (!contains(self, value.signer)) {
            self._values.push(value);
            self._indexes[value.signer] = self._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(SignSet storage self, address signer) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = self._indexes[signer];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = self._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Sign memory lastvalue = self._values[lastIndex];

                // Move the last value to the index where the value to delete is
                self._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                self._indexes[lastvalue.signer] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            self._values.pop();

            // Delete the index for the deleted slot
            delete self._indexes[signer];

            return true;
        } else {
            return false;
        }
    }

    function contains(SignSet storage self, address signer) internal view returns (bool) {
        return self._indexes[signer] != 0;
    }

    function indexOf(SignSet storage self, address signer) internal view returns (uint256) {
        return self._indexes[signer];
    }

    function length(SignSet storage self) internal view returns (uint256) {
        return self._values.length;
    }

    function at(SignSet storage self, uint256 index) internal view returns (Sign memory) {
        return self._values[index];
    }

    function values(SignSet storage self) internal view returns (Sign[] memory) {
        return self._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Search {
    uint256 public constant INVALID_INDEX = 2**256 - 1;

    function indexOf(address[] storage self, address value) internal view returns (uint256) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == value) return i;
        }
        return INVALID_INDEX;
    }

    function contains(address[] storage self, address value) internal view returns (bool) {
        return indexOf(self, value) != INVALID_INDEX;
    }
}