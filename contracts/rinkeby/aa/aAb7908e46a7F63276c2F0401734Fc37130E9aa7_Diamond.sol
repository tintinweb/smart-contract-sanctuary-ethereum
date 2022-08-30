// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

/**
 * @author DIVA protocol team.
 * @title A protocol to create and settle derivative assets.
 * @dev DIVA protocol is implemented using the Diamond Standard 
 * (EIP-2535: https://eips.ethereum.org/EIPS/eip-2535).
 * Contract issues directionally reversed long and short positions
 * (represented as ERC20 tokens) upon collateral deposit. Combined those
 * assets represent a claim on the collateral held in the contract. If held
 * in isolation, they expose the user to the up- or downside of the reference
 * asset. Contract holds all the collateral backing all position tokens in
 * existence. 
 * Users can withdraw collateral by i) submitting both short and long tokens
 * in equal proportions or by redeeming them separately after the final
 * reference asset value and hence the payout for long and short position
 * tokens has been determined. 
 * Contract is the owner of all position tokens and hence the only account
 * authorized to execute the `mint` and `burn` functions inside
 * `PositionToken` contract.
 */

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {LibDiamondStorage} from "./libraries/LibDiamondStorage.sol";
import {LibDIVAStorage} from "./libraries/LibDIVAStorage.sol";
import {LibOwnership} from "./libraries/LibOwnership.sol";
import {LibEIP712} from "./libraries/LibEIP712.sol";
import {LibEIP712Storage} from "./libraries/LibEIP712Storage.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {IERC173} from "./interfaces/IERC173.sol";
import {IERC165} from "./interfaces/IERC165.sol";

contract Diamond {
    /**
     * @dev Deploy DiamondCutFacet before deploying the diamond
     */
    constructor(
        address _contractOwner,
        address _diamondCutFacet,
        address _treasury
    ) payable {
        require(_contractOwner != address(0), "DIVA: owner is 0x0");
        require(_treasury != address(0), "DIVA: treasury is 0x0");

        LibOwnership._setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond._diamondCut(cut, address(0), "");

        // ************************************************************************
        // Initialization of DIVA protocol variables (updateable by contract owner)
        // ************************************************************************
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage._diamondStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage._governanceStorage();
        LibEIP712Storage.EIP712Storage storage es = LibEIP712Storage._eip712Storage();

        // Initialize fee parameters. Ensure that values are 0 or within the
        // bandwidths specified in `setProtocolFee` and ``setSettlementFee``
        gs.protocolFee = 2500000000000000; // 0.25%
        gs.settlementFee = 500000000000000; // 0.05%

        // Initialize settlement related parameters and treasury address
        gs.submissionPeriod = 1 days; 
        gs.challengePeriod = 1 days; 
        gs.reviewPeriod = 2 days; 
        gs.fallbackSubmissionPeriod = 5 days; 
        gs.treasury = _treasury; 
        gs.fallbackDataProvider = _contractOwner;

        // Initializing EIP712 domain separator
        es.EIP712_DOMAIN_SEPARATOR = LibEIP712.getDomainHash(
            LibEIP712.EIP712Domain({
                name: "DIVA Protocol",
                version: "1",
                chainId: LibEIP712._chainId(),
                verifyingContract: address(this)
            })
        );

        // Adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        
        LibDiamondStorage.DiamondStorage storage ds;
        
        bytes32 position = LibDiamondStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }

        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            // copy incoming call data
            calldatacopy(0, 0, calldatasize())

            // forward call to logic contract (facet)
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

            // retrieve return data
            returndatacopy(0, 0, returndatasize())

            // forward return data back to caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamondStorage} from "./LibDiamondStorage.sol";

library LibDiamond {
    event DiamondCut(
        IDiamondCut.FacetCut[] _facetCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function _diamondCut(
        IDiamondCut.FacetCut[] memory _facetCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _facetCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _facetCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                _addFunctions(
                    _facetCut[facetIndex].facetAddress,
                    _facetCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                _replaceFunctions(
                    _facetCut[facetIndex].facetAddress,
                    _facetCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                _removeFunctions(
                    _facetCut[facetIndex].facetAddress,
                    _facetCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_facetCut, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    function _addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            _addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            _addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    // Replacing a function means removing a function and adding a new function
    // from a different facet but with the same function signature as the one
    // removed. In other words, replacing a function in a diamond just means
    // changing the facet address where it comes from.
    function _replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            _addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            _removeFunction(ds, oldFacetAddress, selector);
            _addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function _removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            _removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function _addFacet(
        LibDiamondStorage.DiamondStorage storage ds,
        address _facetAddress
    ) internal {
        _enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function _addFunction(
        LibDiamondStorage.DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function _removeFunction(
        LibDiamondStorage.DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function _initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                _enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function _enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

library LibDiamondStorage {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // Maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // Maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // Facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Owner of the contract
        address contractOwner;
    }

    function _diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

library LibDIVAStorage {
    
    bytes32 constant POOL_STORAGE_POSITION = keccak256("diamond.standard.pool.storage");
    bytes32 constant GOVERNANCE_STORAGE_POSITION = keccak256("diamond.standard.governance.storage");
    bytes32 constant FEE_CLAIM_STORAGE_POSITION = keccak256("diamond.standard.fee.claim.storage");

    // Settlement status
    enum Status {
        Open,
        Submitted,
        Challenged,
        Confirmed
    }

    // Collection of pool related parameters; order was optimized to reduce storage costs
    struct Pool {
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralBalance;
        uint256 finalReferenceValue;
        uint256 capacity;
        uint256 statusTimestamp;
        address shortToken;
        uint96 payoutShort;             // max value: 1e18 <= 2^64
        address longToken;                  
        uint96 payoutLong;              // max value: 1e18 <= 2^64
        address collateralToken;
        uint96 expiryTime;
        address dataProvider;
        uint96 protocolFee;           // max value: 25000000000000000 = 2.5% <= 2^56
        uint96 settlementFee;           // max value: 25000000000000000 = 2.5% <= 2^56
        Status statusFinalReferenceValue;
        string referenceAsset;
    }

    // Collection of governance related parameters
    struct GovernanceStorage {
        uint256 submissionPeriod;           // days since expiry; max value: 15 days <= 2^24
        uint256 challengePeriod;            // days since time of submission; max value: 15 days <= 2^24
        uint256 reviewPeriod;               // days since time of challenge; max value: 15 days <= 2^24
        uint256 fallbackSubmissionPeriod;   // days since the end of the submission period; max value: 15 days <= 2^24
        address treasury;                   // treasury address controlled by DIVA governance
        address fallbackDataProvider;       // initial value set to contract owner
        uint256 pauseReturnCollateralUntil;
        uint96 protocolFee;               // max value: 25000000000000000 = 2.5% <= 2^56
        uint96 settlementFee;               // max value: 25000000000000000 = 2.5% <= 2^56
    }

    struct FeeClaimStorage {
        mapping(address => mapping(address => uint256)) claimableFeeAmount; // collateralTokenAddress -> RecipientAddress -> amount
    }

    struct PoolStorage {
        uint256 poolId;
        mapping(uint256 => Pool) pools;
    }

    function _poolStorage()
        internal
        pure
        returns (PoolStorage storage ps)
    {
        bytes32 position = POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function _governanceStorage()
        internal
        pure
        returns (GovernanceStorage storage gs)
    {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function _feeClaimStorage()
        internal
        pure
        returns (FeeClaimStorage storage fs)
    {
        bytes32 position = FEE_CLAIM_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {LibDiamondStorage} from "./LibDiamondStorage.sol";

// Thrown if `msg.sender` is not contract owner
error NotContractOwner();

library LibOwnership {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _setContractOwner(address _newOwner) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamondStorage._diamondStorage().contractOwner;
    }

    function _enforceIsContractOwner() internal view {
        if (msg.sender != LibDiamondStorage._diamondStorage().contractOwner)
            revert NotContractOwner();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {PositionToken} from "../PositionToken.sol";
import {IPositionToken} from "../interfaces/IPositionToken.sol";
import {IEIP712Create} from "../interfaces/IEIP712Create.sol";
import {LibEIP712Storage} from "./LibEIP712Storage.sol";
import {LibDIVA} from "./LibDIVA.sol";
import {LibDIVAStorage} from "./LibDIVAStorage.sol";

// Thrown if user tries to fill an amount smaller than the minimum provided
// in the offer
error TakerFillAmountSmallerMinimum();

// Thrown if the provided `takerFillAmount` exceeds the remaining fillable amount
error TakerFillAmountExceedsFillableAmount();

// Thrown if `msg.sender` is not equal to maker during cancel operation
error MsgSenderNotMaker();

// Thrown if signature type is not equal to 2 (EIP712)
error InvalidSignatureType();

// Thrown if the signed offer and the provided signature do not match
error InvalidSignature();

// Thrown if offer is not fillable due to being already filled, cancelled or expired
error OfferFilledCancelledOrExpired();

// Thrown if offer is reserved for a different taker
error UnauthorizedTaker();

library LibEIP712 {
    using SafeERC20 for IERC20Metadata;

    // Enum for offer status
    enum OfferStatus {
        FILLABLE,
        FILLED,
        CANCELLED,
        EXPIRED
    }

    struct EIP712Domain {
        string name; // "DIVA Protocol"
        string version; // "1"
        uint256 chainId; // Network ChainId
        address verifyingContract; // Address of DIVA Diamond contract
    }

    // Signature structure
    struct Signature {
        // How to validate the signature.
        uint8 signatureType; // 2 = EIP712
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }

    // Argument for `fillOfferCreateContingentPool` function.
    struct OfferCreateContingentPool {
        address maker; // signer of the message
        address taker; // if zero address, then everyone can take the short side
        uint256 makerCollateralAmount;
        uint256 takerCollateralAmount;
        bool makerDirection; // 0 for signer keeps short position, 1 for signer keeps long position
        uint256 offerExpiry; // offer expiration time
        uint256 minimumTakerFillAmount; // if equal to collateralAmountCounterParty, then only full fill is possible
        string referenceAsset;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        address collateralToken; // note that collateralAmount was dropped as implied by takerFillAmount + makerFillAmount
        address dataProvider;
        uint256 capacity;
        uint256 salt;
    }

    // Argument for `fillOfferAddLiquidity` function.
    struct OfferAddLiquidity {
        address maker; // signer of the message
        address taker; // if zero address, then everyone can take the short side
        uint256 makerCollateralAmount;
        uint256 takerCollateralAmount;
        bool makerDirection; // 0 for signer keeps short position, 1 for signer keeps long position
        uint256 offerExpiry; // offer expiration time
        uint256 minimumTakerFillAmount; // if equal to collateralAmountCounterParty, then only full fill is possible
        uint256 poolId;
        uint256 salt;
    }

    // Argument for `_getOfferHashCreateContingentPool` function inside EIP712DIVA.
    struct CreatePoolOfferHash {
        bytes32 poolTypehash;
        address maker;
        address taker;
        uint256 makerCollateralAmount;
        uint256 takerCollateralAmount;
        bool makerDirection;
        uint256 offerExpiry;
        uint256 minimumTakerFillAmount;
        bytes32 referenceAssetStringHash;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        address collateralToken;
        address dataProvider;
        uint256 capacity;
        uint256 salt;
    }

    // Offer info structure
    struct OfferInfo {
        bytes32 typedOfferHash;
        OfferStatus status;
        uint256 takerFilledAmount;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

    bytes32 internal constant CREATE_POOL_OFFER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "OfferCreateContingentPool(",
                "address maker,"
                "address taker,"
                "uint256 makerCollateralAmount,"
                "uint256 takerCollateralAmount,"
                "bool makerDirection,"
                "uint256 offerExpiry,"
                "uint256 minimumTakerFillAmount,"
                "string referenceAsset,"
                "uint96 expiryTime,"
                "uint256 floor,"
                "uint256 inflection,"
                "uint256 cap,"
                "uint256 gradient,"
                "address collateralToken,"
                "address dataProvider,"
                "uint256 capacity,"
                "uint256 salt)"
            )
        );

    bytes32 internal constant ADD_LIQUIDITY_OFFER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "OfferAddLiquidity(",
                "address maker,"
                "address taker,"
                "uint256 makerCollateralAmount,"
                "uint256 takerCollateralAmount,"
                "bool makerDirection,"
                "uint256 offerExpiry,"
                "uint256 minimumTakerFillAmount,"
                "uint256 poolId,"
                "uint256 salt)"
            )
        );

    // Max int value of a uint256, used to flag cancelled offers.
    uint256 internal constant MAX_INT = ~uint256(0);

    function _chainId() internal view returns (uint256 chainId) {
        chainId = block.chainid;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function _toTypedMessageHash(bytes32 _messageHash)
        internal
        view
        returns (bytes32 typedMessageHash)
    {
        typedMessageHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                LibEIP712Storage._eip712Storage().EIP712_DOMAIN_SEPARATOR,
                _messageHash
            )
        );
    }

    function getDomainHash(EIP712Domain memory _eip712Domain)
        internal
        pure
        returns (bytes32 domainHash)
    {
        domainHash = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(_eip712Domain.name)),
                keccak256(bytes(_eip712Domain.version)),
                _eip712Domain.chainId,
                _eip712Domain.verifyingContract
            )
        );
    }

    function poolId(bytes32 _typedOfferHash) internal view returns (uint256) {
        return
            LibEIP712Storage._eip712Storage().typedOfferHashToPoolId[
                _typedOfferHash
            ];
    }

    function _takerFilledAmount(bytes32 _typedOfferHash)
        internal
        view
        returns (uint256)
    {
        return
            LibEIP712Storage._eip712Storage().typedOfferHashToTakerFilledAmount[
                _typedOfferHash
            ];
    }

    function _min256(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256 min256)
    {
        min256 = _a < _b ? _a : _b;
    }

    /**
     * @notice Function to get info of create coningent pool offer.
     * @param _offerCreateContingentPool Struct containing the create pool offer details
     * @return offerInfo Struct of offer info
     */
    function _getOfferInfoCreateContingentPool(
        OfferCreateContingentPool memory _offerCreateContingentPool
    ) internal view returns (OfferInfo memory offerInfo) {
        // Get typed offer hash with `_offerCreateContingentPool`
        offerInfo.typedOfferHash = _toTypedMessageHash(
            _getOfferHashCreateContingentPool(_offerCreateContingentPool)
        );

        // Get offer status and takerFilledAmount
        _populateCommonOfferInfoFields(
            offerInfo,
            _offerCreateContingentPool.takerCollateralAmount,
            _offerCreateContingentPool.offerExpiry
        );
    }

    // Return hash of create pool offer details
    function _getOfferHashCreateContingentPool(
        OfferCreateContingentPool memory _offerCreateContingentPool
    ) internal pure returns (bytes32 offerHashCreateContingentPool) {
        offerHashCreateContingentPool = keccak256(
            abi.encode(
                CreatePoolOfferHash({
                    poolTypehash: CREATE_POOL_OFFER_TYPEHASH,
                    maker: _offerCreateContingentPool.maker,
                    taker: _offerCreateContingentPool.taker,
                    makerCollateralAmount: _offerCreateContingentPool
                        .makerCollateralAmount,
                    takerCollateralAmount: _offerCreateContingentPool
                        .takerCollateralAmount,
                    makerDirection: _offerCreateContingentPool.makerDirection,
                    offerExpiry: _offerCreateContingentPool.offerExpiry,
                    minimumTakerFillAmount: _offerCreateContingentPool
                        .minimumTakerFillAmount,
                    referenceAssetStringHash: keccak256(
                        bytes(_offerCreateContingentPool.referenceAsset)
                    ),
                    expiryTime: _offerCreateContingentPool.expiryTime,
                    floor: _offerCreateContingentPool.floor,
                    inflection: _offerCreateContingentPool.inflection,
                    cap: _offerCreateContingentPool.cap,
                    gradient: _offerCreateContingentPool.gradient,
                    collateralToken: _offerCreateContingentPool.collateralToken,
                    dataProvider: _offerCreateContingentPool.dataProvider,
                    capacity: _offerCreateContingentPool.capacity,
                    salt: _offerCreateContingentPool.salt
                })
            )
        );
    }

    // Get offer status and taker filled amount for offerInfo
    function _populateCommonOfferInfoFields(
        OfferInfo memory _offerInfo,
        uint256 _takerCollateralAmount,
        uint256 _offerExpiry
    ) internal view {
        // Get the filled and direct cancel state.
        _offerInfo.takerFilledAmount = _takerFilledAmount(
            _offerInfo.typedOfferHash
        );

        // Taker filled amount will be set at MAX_INT
        // if the offer was cancelled.
        if (_offerInfo.takerFilledAmount == MAX_INT) {
            _offerInfo.status = OfferStatus.CANCELLED;
            return;
        }

        if (_offerInfo.takerFilledAmount >= _takerCollateralAmount) {
            _offerInfo.status = OfferStatus.FILLED;
            return;
        }

        // Check for expiration.
        if (_offerExpiry <= block.timestamp) {
            _offerInfo.status = OfferStatus.EXPIRED;
            return;
        }

        _offerInfo.status = OfferStatus.FILLABLE;
    }

    // Calc makerFillAmount and poolFillAmount
    function _calcMakerFillAmountAndPoolFillAmount(
        uint256 _makerCollateralAmount,
        uint256 _takerCollateralAmount,
        uint256 _takerFillAmount
    ) internal pure returns (uint256 makerFillAmount, uint256 poolFillAmount) {
        // Calc maker fill amount
        makerFillAmount =
            (_takerFillAmount * _makerCollateralAmount) /
            _takerCollateralAmount;

        // Calc pool fill amount
        poolFillAmount = makerFillAmount + _takerFillAmount;
    }

    // Check if signature is valid
    function _isSignatureValid(
        bytes32 _typedOfferHash,
        Signature memory _signature,
        address _maker
    ) internal pure returns (bool isSignatureValid) {
        // Recover offerMaker address with `_typedOfferHash` and `_signature` using tryRecover function from ECDSA library
        address recoveredOfferMaker = ECDSA.recover(
            _typedOfferHash,
            _signature.v,
            _signature.r,
            _signature.s
        );

        // Check that recoveredOfferMaker is not zero address
        if (recoveredOfferMaker == address(0)) {
            isSignatureValid = false;
        }
        // Check that maker address is equal to recoveredOfferMaker
        else {
            isSignatureValid = _maker == recoveredOfferMaker;
        }
    }

    // Calc actual taker fillable amount
    function _getActualTakerFillableAmount(
        address _maker,
        address _collateralToken,
        uint256 _makerCollateralAmount,
        uint256 _takerCollateralAmount,
        OfferInfo memory _offerInfo
    ) internal view returns (uint256 actualTakerFillableAmount) {
        if (_makerCollateralAmount == 0 || _takerCollateralAmount == 0) {
            // Empty offer.
            return 0; // QUESTION Can we revert with a message?
        }

        if (_offerInfo.status != OfferStatus.FILLABLE) {
            // Not fillable.
            return 0;
        }

        // Get the fillable maker amount based on the offer quantities and
        // previously filled amount
        uint256 makerFillableAmount = ((_takerCollateralAmount -
            _offerInfo.takerFilledAmount) * _makerCollateralAmount) /
            _takerCollateralAmount;

        // Clamp it to the maker fillable amount we can spend on behalf of the
        // maker.
        makerFillableAmount = _min256(
            makerFillableAmount,
            _min256(
                IERC20(_collateralToken).allowance(_maker, address(this)),
                IERC20(_collateralToken).balanceOf(_maker)
            )
        );

        // Convert to taker fillable amount.
        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        // ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        actualTakerFillableAmount =
            (makerFillableAmount *
                _takerCollateralAmount +
                _makerCollateralAmount -
                1) /
            _makerCollateralAmount; // COMMENT Avoid division by zero
    }

    // validate message sender
    function _validateMessageSenderIsOfferMaker(address _offerMaker)
        internal
        view
    {
        // Check that message sender is `_offerMaker`
        if (msg.sender != _offerMaker) revert MsgSenderNotMaker();
    }

    // check offer fillable and signature
    function _checkFillableAndSignature(
        Signature memory _signature,
        address _offerMaker,
        address _offerTaker,
        OfferInfo memory _offerInfo
    ) internal view {
        // Check that signature type is correct
        if (_signature.signatureType != 2) revert InvalidSignatureType();

        // Check that signature is valid
        if (
            !_isSignatureValid(
                _offerInfo.typedOfferHash,
                _signature,
                _offerMaker
            )
        ) revert InvalidSignature();

        // Must be fillable.
        if (_offerInfo.status != OfferStatus.FILLABLE)
            revert OfferFilledCancelledOrExpired();

        // Check that message sender is `_offerTaker` in offer
        if (msg.sender != _offerTaker && _offerTaker != address(0))
            revert UnauthorizedTaker();
    }

    // Validate that `_takerFillAmount` is greater than the minimum and `takerCollateralAmount` is not exceeded.
    // Increase `takerFilledAmount` after successfully passing the checks.
    function _validateTakerFillAmountAndIncreaseTakerFilledAmount(
        uint256 _takerCollateralAmount,
        uint256 _minimumTakerFillAmount,
        uint256 _takerFillAmount,
        bytes32 _typedOfferHash
    ) internal {
        LibEIP712Storage.EIP712Storage storage es = LibEIP712Storage
            ._eip712Storage();
        // Check that `_takerFillAmount` is not smaller than `_minimumTakerFillAmount`
        if (
            _takerFillAmount +
                es.typedOfferHashToTakerFilledAmount[_typedOfferHash] <
            _minimumTakerFillAmount
        ) revert TakerFillAmountSmallerMinimum();

        // Check that `_takerFillAmount` is not higher than remaining fillable taker amount
        if (
            _takerFillAmount >
            _takerCollateralAmount -
                es.typedOfferHashToTakerFilledAmount[_typedOfferHash]
        ) revert TakerFillAmountExceedsFillableAmount();

        // Increase taker filled amount
        es.typedOfferHashToTakerFilledAmount[
            _typedOfferHash
        ] += _takerFillAmount;
    }

    // Transfer collateral token from offerMaker and offerTaker(msg.sender)
    function _transferCollateralToken(
        address _collateralToken,
        address _offerMaker,
        uint256 _makerFillAmount,
        uint256 _takerFillAmount
    ) internal {
        // Transfer collateral token from `_offerMaker`
        IERC20Metadata(_collateralToken).safeTransferFrom(
            _offerMaker,
            address(this),
            _makerFillAmount
        );
        // Transfer collateral token from offerTaker(msg.sender)
        IERC20Metadata(_collateralToken).safeTransferFrom(
            msg.sender, // offerTaker
            address(this),
            _takerFillAmount
        );
    }

    // Fill add liquidity offer without signature as signature validation is done before calling that function.
    // Note that in `fillOfferCreateContingentPool`, the relevant signature for validation is
    // the original create contingent pool offer rather than an add liquidity offer.
    function _fillAddLiquidityOffer(
        OfferAddLiquidity memory _offerAddLiquidity,
        uint256 _takerFillAmount,
        bytes32 _typedOfferHash
    ) internal {
        // Validate taker fill amount and increase taker filled amount
        _validateTakerFillAmountAndIncreaseTakerFilledAmount(
            _offerAddLiquidity.takerCollateralAmount,
            _offerAddLiquidity.minimumTakerFillAmount,
            _takerFillAmount,
            _typedOfferHash
        );

        // Calc maker fill amount and pool fill amount
        (
            uint256 _makerFillAmount,
            uint256 _poolFillAmount
        ) = _calcMakerFillAmountAndPoolFillAmount(
                _offerAddLiquidity.makerCollateralAmount,
                _offerAddLiquidity.takerCollateralAmount,
                _takerFillAmount
            );

        // Get pool params with poolId in `_offerAddLiquidity`
        LibDIVAStorage.Pool memory _poolParameters = LibDIVA._poolParameters(
            _offerAddLiquidity.poolId
        );

        // Transfer collateral token from offerMaker and offerTaker(msg.sender) to `this`
        _transferCollateralToken(
            _poolParameters.collateralToken,
            _offerAddLiquidity.maker,
            _makerFillAmount,
            _takerFillAmount
        );

        // Add liquidity on DIVA protocol
        LibDIVA._addLiquidity(
            _offerAddLiquidity.poolId,
            _poolFillAmount,
            _offerAddLiquidity.makerDirection
                ? _offerAddLiquidity.maker
                : msg.sender,
            _offerAddLiquidity.makerDirection
                ? msg.sender
                : _offerAddLiquidity.maker,
            false
        );
    }

    /**
     * @notice Function to get info of add liquidity offer.
     * @param _offerAddLiquidity Struct containing the add liquidity offer details
     * @return offerInfo Struct of offer info
     */
    function _getOfferInfoAddLiquidity(
        OfferAddLiquidity memory _offerAddLiquidity
    ) internal view returns (OfferInfo memory offerInfo) {
        // Get typed offer hash with `_offerAddLiquidity`
        offerInfo.typedOfferHash = _toTypedMessageHash(
            _getOfferHashAddLiquidity(_offerAddLiquidity)
        );

        // Get offer status and takerFilledAmount
        _populateCommonOfferInfoFields(
            offerInfo,
            _offerAddLiquidity.takerCollateralAmount,
            _offerAddLiquidity.offerExpiry
        );
    }

    // Return hash of add liquidity offer details
    function _getOfferHashAddLiquidity(
        OfferAddLiquidity memory _offerAddLiquidity
    ) internal pure returns (bytes32 offerHashAddLiquidity) {
        offerHashAddLiquidity = keccak256(
            abi.encode(
                ADD_LIQUIDITY_OFFER_TYPEHASH,
                _offerAddLiquidity.maker,
                _offerAddLiquidity.taker,
                _offerAddLiquidity.makerCollateralAmount,
                _offerAddLiquidity.takerCollateralAmount,
                _offerAddLiquidity.makerDirection,
                _offerAddLiquidity.offerExpiry,
                _offerAddLiquidity.minimumTakerFillAmount,
                _offerAddLiquidity.poolId,
                _offerAddLiquidity.salt
            )
        );
    }

    function _getOfferRelevantStateCreateContingentPool(
        OfferCreateContingentPool memory _offerCreateContingentPool,
        Signature memory _signature
    )
        internal
        view
        returns (
            OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid
        )
    {
        // Get offer info
        offerInfo = _getOfferInfoCreateContingentPool(
            _offerCreateContingentPool
        );

        // Calc actual taker fillable amount
        actualTakerFillableAmount = _getActualTakerFillableAmount(
            _offerCreateContingentPool.maker,
            _offerCreateContingentPool.collateralToken,
            _offerCreateContingentPool.makerCollateralAmount,
            _offerCreateContingentPool.takerCollateralAmount,
            offerInfo
        );

        // Check if signature is valid
        isSignatureValid = _isSignatureValid(
            offerInfo.typedOfferHash,
            _signature,
            _offerCreateContingentPool.maker
        );
    }

    function _getOfferRelevantStateAddLiquidity(
        OfferAddLiquidity memory _offerAddLiquidity,
        Signature memory _signature
    )
        internal
        view
        returns (
            OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid
        )
    {
        // Get offer info
        offerInfo = _getOfferInfoAddLiquidity(_offerAddLiquidity);

        // Get pool params with poolId in offerAddLiquidity
        LibDIVAStorage.Pool memory _poolParameters = LibDIVA._poolParameters(
            _offerAddLiquidity.poolId
        );
        // Calc actual taker fillable amount
        actualTakerFillableAmount = _getActualTakerFillableAmount(
            _offerAddLiquidity.maker,
            _poolParameters.collateralToken,
            _offerAddLiquidity.makerCollateralAmount,
            _offerAddLiquidity.takerCollateralAmount,
            offerInfo
        );

        // Check if signature is valid
        isSignatureValid = _isSignatureValid(
            offerInfo.typedOfferHash,
            _signature,
            _offerAddLiquidity.maker
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

library LibEIP712Storage {
    
    bytes32 constant EIP712_STORAGE_POSITION = keccak256("diamond.standard.eip712.storage");

    struct EIP712Storage {
        // EIP712 domain separator (set in constructor in Diamond.sol)
        bytes32 EIP712_DOMAIN_SEPARATOR;
        // Mapping to store created poolId with typedOfferHash
        mapping(bytes32 => uint256) typedOfferHashToPoolId;
        // Mapping to store takerFilled amount with typedOfferHash
        mapping(bytes32 => uint256) typedOfferHashToTakerFilledAmount;
    }

    function _eip712Storage()
        internal
        pure
        returns (EIP712Storage storage es)
    {
        bytes32 position = EIP712_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // Duplication of event defined in `LibDiamond.sol` as events emitted out of
    // library functions are not reflected in the contract ABI. Read more about it here:
    // https://web.archive.org/web/20180922101404/https://blog.aragon.org/library-driven-development-in-solidity-2bebcaf88736/
    event DiamondCut(
        FacetCut[] _facetCut,
        address _init,
        bytes _calldata
    );

    /// @notice Add/replace/remove any number of functions and optionally
    ///         execute a function with delegatecall
    /// @param _facetCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _facetCut,
        address _init,
        bytes calldata _calldata
    ) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPositionToken} from "./interfaces/IPositionToken.sol";

contract PositionToken is IPositionToken, ERC20 {
    uint256 private immutable _poolId;
    address private immutable _owner;
    uint8 private immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 poolId_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _owner = msg.sender;
        _poolId = poolId_;
        _decimals = decimals_;
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "PositionToken: caller is not owner"
            );
        _;
    }

    function mint(
        address _recipient,
        uint256 _amount
        ) external override onlyOwner {
        _mint(_recipient, _amount);
    }

    function burn(
        address _redeemer,
        uint256 _amount
        ) external override onlyOwner {
        _burn(_redeemer, _amount);
    }

    function poolId() external view override returns (uint256) {
        return _poolId;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Position token contract
 * @dev The `PositionToken` contract inherits from ERC20 contract and stores 
 * the Id of the pool that the position token is linked to. It implements a 
 * `mint` and a `burn` function which can only be called by the `PositionToken`
 * contract owner.
 *
 * Two `PositionToken` contracts are deployed during pool creation process 
 * (`createContingentPool`) with Diamond contract being set as the owner. 
 * The `mint` function is used during pool creation (`createContingentPool`) 
 * and addition of liquidity (`addLiquidity`). Position tokens are burnt 
 * during token redemption (`redeemPositionToken`) and removal of liquidity
 * (`removeLiquidity`). The address of the position tokens is stored in the 
 * pool parameters within Diamond contract and used to verify the tokens that 
 * a user sends back to withdraw collateral.
 *
 * Position tokens have the same number of decimals as the underlying 
 * collateral token.
 */
interface IPositionToken is IERC20 {
    /**
     * @dev Function to mint ERC20 position tokens. Called during 
     * `createContingentPool` and `addLiquidity`. Can only be called by the
     * owner of the position token which is the Diamond contract in the 
     * context of DIVA.
     * @param _recipient The account receiving the position tokens.
     * @param _amount The number of position tokens to mint.
     */
    function mint(
        address _recipient, 
        uint256 _amount
    )
        external;

    /**
     * @dev Function to burn position tokens. Called within `redeemPositionToken`
     * and `removeLiquidity`. Can only be called by the owner of the position
     * token which is the Diamond contract in the context of DIVA.
     * @param _redeemer Address redeeming positions tokens in return for
     * collateral.
     * @param _amount The number of position tokens to burn.
     */
    function burn(
        address _redeemer, 
        uint256 _amount
    )
        external;

    /**
     * @dev Returns the Id of the contingent pool that the position token is 
     * linked to in the context of DIVA.
     */
    function poolId() external view returns (uint256);

    /**
     * @dev Returns the owner of the position token (Diamond contract in the
     * context of DIVA).
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {LibEIP712} from "../libraries/LibEIP712.sol";

/**
 * @title Shortened version of the interface including required functions only
 */
interface IEIP712Create {
    
    /**
     * @dev Emitted whenever an offer is cancelled.
     * @param typedOfferHash The typed offer hash.
     * @param maker The offer maker.
     */
    event OfferCancelled(bytes32 typedOfferHash, address maker);

    /**
     * @dev Emitted whenever an offer is filled.
     * @param typedOfferHash The typed offer hash.
     * @param maker The offer maker.
     * @param taker The offer taker.
     */
    event OfferFilled(bytes32 typedOfferHash, address maker, address taker);

    /**
     * @notice Function to fill create contingent pool offer.
     * @param _offerCreateContingentPool Struct containing the create pool offer details (see `OfferCreateContingentPool` struct)
     * @param _signature Signature of signed message of `_offerCreateContingentPool` by `maker`
     * @param _takerFillAmount Collateral amount to be deposited into the DIVA contingent pool from offer taker
     */
    function fillOfferCreateContingentPool(
        LibEIP712.OfferCreateContingentPool memory _offerCreateContingentPool,
        LibEIP712.Signature memory _signature,
        uint256 _takerFillAmount
    ) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {PositionToken} from "../PositionToken.sol";
import {IPositionToken} from "../interfaces/IPositionToken.sol";
import {SafeDecimalMath} from "./SafeDecimalMath.sol";
import {LibDIVAStorage} from "./LibDIVAStorage.sol";

// Thrown, if collateral amount to be returned to user during `removeLiquidity`
// or `redeemPositionToken` exceeds the pool's collateral balance
error AmountExceedsPoolCollateralBalance();

// Thrown if fee amount to be allocated exceeds the pool's
// current `collateralBalance`
error FeeAmountExceedsPoolCollateralBalance();

// Thrown if expiryTime in pool params is smaller than or equal to the
// current block.timestamp
error Expired();

// Thrown if reference asseet provided by the user is an empty string
error NoReferenceAsset();

// Thrown if floor is greater than inflection
error FloorGreaterInflection();

// Thrown if cap is smaller than inflection
error CapSmallerInflection();

// Thrown if data provider is zero address
error ZeroAddressDataProvider();

// Thrown if gradient is greater than 1 (i.e. 1e18 in integer format)
error GradientGreater1e18();

// Thrown if collateral amount is smaller than the minimum of 1e6
error CollateralAmountSmaller1e6();

// Thrown if `collateralAmount` exceeds pool capacity
error PoolCapacityExceeded();

// Thrown if collateral token decimals is smaller than 6 or greater than 18
error InvalidCollateralTokenDecimals();

library LibDIVA {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20Metadata;

    /**
     * @notice Emitted when fees are allocated.
     * @dev Collateral token can be looked up via the `getPoolParameters`
     * function using the emitted `poolId`.
     * @param poolId The Id of the pool that the fee applies to.
     * @param recipient Address that is allocated the fees.
     * @param amount Fee amount allocated.
     */
    event FeeClaimAllocated(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emitted when a new pool is created.
     * @param poolId The Id of the newly created contingent pool.
     * @param longRecipient The address that received the long position tokens.
     * @param shortRecipient The address that received the short position tokens.
     * @param collateralAmount The collateral amount deposited into the pool.
     */
    event PoolIssued(
        uint256 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount
    );

    /**
     * @notice Emitted when new collateral is added to an existing pool.
     * @param poolId The Id of the pool that collateral was added to.
     * @param longRecipient The address that received the long position token.
     * @param shortRecipient The address that received the short position token.
     * @param collateralAmount The collateral amount added.
     */
    event LiquidityAdded(
        uint256 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount
    );

    function _poolParameters(uint256 _poolId)
        internal
        view
        returns (LibDIVAStorage.Pool memory)
    {
        return LibDIVAStorage._poolStorage().pools[_poolId];
    }

    function _getLatestPoolId() internal view returns (uint256) {
        return LibDIVAStorage._poolStorage().poolId;
    }

    function _claim(address _collateralToken, address _recipient)
        internal
        view
        returns (uint256)
    {
        return
            LibDIVAStorage._feeClaimStorage().claimableFeeAmount[
                _collateralToken
            ][_recipient];
    }

    /**
     * @dev Internal function to transfer the collateral to the user.
     * Openzeppelin's `safeTransfer` method is used to handle different
     * implementations of the ERC20 standard.
     */
    function _returnCollateral(
        uint256 _poolId,
        address _collateralToken,
        address _receiver,
        uint256 _amount
    ) internal {
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        IERC20Metadata collateralToken = IERC20Metadata(_collateralToken);

        if (_amount > _pool.collateralBalance)
            revert AmountExceedsPoolCollateralBalance();

        _pool.collateralBalance -= _amount;

        collateralToken.safeTransfer(_receiver, _amount);
    }

    /**
     * @notice Internal function to calculate the payoff per long and short token
     * (net of fees) and store it in `payoutLong` and
     * `payoutShort` inside pool parameters.
     * @dev Called inside {redeemPositionToken} and {setFinalReferenceValue}
     * functions after status of final reference value has been confirmed.
     * @param _poolId The pool Id for which payout amounts are set.
     * @param _collateralTokenDecimals Collateral token decimals. Passed as
     * argument to avoid reading from storage again.
     */
    function _setPayoutAmount(uint256 _poolId, uint8 _collateralTokenDecimals)
        internal
    {
        // Get references to relevant storage slot
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        // Calculate payoff per short and long token. Output is in collateral
        // token decimals.
        (_pool.payoutShort, _pool.payoutLong) = _calcPayoffs(
            _pool.floor,
            _pool.inflection,
            _pool.cap,
            _pool.gradient,
            _pool.finalReferenceValue,
            _collateralTokenDecimals,
            _pool.protocolFee + _pool.settlementFee
        );
    }

    /**
     * @notice Internal function used within `setFinalReferenceValue` and
     * `redeemPositionToken` to calculate and allocate fee claims to recipient
     * (DIVA Treasury or data provider). Fee is applied to the overall
     * collateral remaining in the pool and allocated in full the first time
     * the respective function is triggered.
     * @dev Fees can be claimed via the `claimFee` function.
     * @param _poolId Pool Id.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * @param _recipient Fee recipient address.
     * @param _collateralBalance Current pool collateral balance expressed as
     * an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     */
    function _calcAndAllocateFeeClaim(
        uint256 _poolId,
        uint96 _fee,
        address _recipient,
        uint256 _collateralBalance,
        uint8 _collateralTokenDecimals
    ) internal {
        uint256 _feeAmount = _calcFee(
            _fee,
            _collateralBalance,
            _collateralTokenDecimals
        );

        _allocateFeeClaim(_poolId, _recipient, _feeAmount);
    }

    /**
     * @notice Internal function to allocate fees to `recipient`.
     * @dev The balance of the recipient is tracked inside the contract and
     * can be claimed via `claimFee` function.
     * @param _poolId Pool Id that the fee applies to.
     * @param _recipient Address of the fee recipient.
     * @param _feeAmount Total fee amount expressed as an integer with
     * collateral token decimals.
     */
    function _allocateFeeClaim(
        uint256 _poolId,
        address _recipient,
        uint256 _feeAmount
    ) internal {
        // Get references to relevant storage slot
        LibDIVAStorage.FeeClaimStorage storage fs = LibDIVAStorage
            ._feeClaimStorage();
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        // Check that fee amount to be allocated doesn't exceed the pool's
        // current `collateralBalance`
        if (_feeAmount > _pool.collateralBalance)
            revert FeeAmountExceedsPoolCollateralBalance();

        // Reduce `collateralBalance` in pool parameters and increase fee claim
        _pool.collateralBalance -= _feeAmount;
        fs.claimableFeeAmount[_pool.collateralToken][_recipient] += _feeAmount;

        // Log recipient and fee amount
        emit FeeClaimAllocated(_poolId, _recipient, _feeAmount);
    }

    /**
     * @notice Function to calculate the fee amount for a given collateral amount.
     * @dev Output is an integer expressed with collateral token decimals.
     * As fee parameter has 18 decimals but collateral tokens may have
     * less, scaling needs to be applied when using `SafeDecimalMath` library.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * (e.g., 0.25% is 2500000000000000).
     * @param _collateralAmount Collateral amount that is used as the basis for
     * the fee calculation expressed as an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @return The fee amount expressed as an integer with collateral token decimals.
     */
    function _calcFee(
        uint96 _fee,
        uint256 _collateralAmount,
        uint8 _collateralTokenDecimals
    ) internal pure returns (uint256) {
        uint256 _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));

        uint256 _feeAmount = uint256(_fee).multiplyDecimal(
            _collateralAmount * _SCALINGFACTOR
        ) / _SCALINGFACTOR;

        return _feeAmount;
    }

    /**
     * @notice Function to calculate the payoffs per long and short token
     * (net of fees).
     * @dev Scaling applied during calculations to handle different decimals.
     * @param _floor Value of underlying at or below which the short token
     * will pay out the max amount and the long token zero. Expressed as an
     * integer with 18 decimals.
     * @param _inflection Value of underlying at which the long token will
     * payout out `_gradient` and the short token `1-_gradient`. Expressed
     * as an integer with 18 decimals.
     * @param _cap Value of underlying at or above which the long token will
     * pay out the max amount and short token zero. Expressed as an integer
     * with 18 decimals.
     * @param _gradient Long token payout at inflection (0 <= _gradient <= 1).
     * Expressed as an integer with 18 decimals.
     * @param _finalReferenceValue Final value submitted by data provider
     * expressed as an integer with 18 decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @param _fee Fee in percent expressed as an integer with 18 decimals.
     * @return payoffShortNet Payoff per short token (net of fees) expressed
     * as an integer with collateral token decimals.
     * @return payoffLongNet Payoff per long token (net of fees) expressed
     * as an integer with collateral token decimals.
     */
    function _calcPayoffs(
        uint256 _floor,
        uint256 _inflection,
        uint256 _cap,
        uint256 _gradient,
        uint256 _finalReferenceValue,
        uint256 _collateralTokenDecimals,
        uint96 _fee // max value: 5% <= 2^96
    ) internal pure returns (uint96 payoffShortNet, uint96 payoffLongNet) {
        uint256 _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));
        uint256 _UNIT = SafeDecimalMath.UNIT;
        uint256 _payoffLong;
        uint256 _payoffShort;

        if (_finalReferenceValue == _inflection) {
            _payoffLong = _gradient;
        } else if (_finalReferenceValue <= _floor) {
            _payoffLong = 0;
        } else if (_finalReferenceValue >= _cap) {
            _payoffLong = _UNIT;
        } else if (_finalReferenceValue < _inflection) {
            _payoffLong = (
                _gradient.multiplyDecimal(_finalReferenceValue - _floor)
            ).divideDecimal(_inflection - _floor);
        } else if (_finalReferenceValue > _inflection) {
            _payoffLong =
                _gradient +
                (
                    (_UNIT - _gradient).multiplyDecimal(
                        _finalReferenceValue - _inflection
                    )
                ).divideDecimal(_cap - _inflection);
        }

        _payoffShort = _UNIT - _payoffLong;

        payoffShortNet = uint96(
            _payoffShort.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
        );
        payoffLongNet = uint96(
            _payoffLong.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
        );

        return (payoffShortNet, payoffLongNet); // collateral token decimals
    }

    // Argument for `createContingentPool` function
    struct PoolParams {
        string referenceAsset;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralAmount;
        address collateralToken;
        address dataProvider;
        uint256 capacity;
        address longRecipient;
        address shortRecipient;
    }

    function _createContingentPool(
        PoolParams memory _poolParams,
        bool _transferCollateral
    ) internal returns (uint256) {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Create reference to collateral token corresponding to the provided pool Id
        IERC20Metadata collateralToken = IERC20Metadata(
            _poolParams.collateralToken
        );

        // Check validity of input parameters
        if (_poolParams.expiryTime <= block.timestamp) revert Expired();
        if (bytes(_poolParams.referenceAsset).length == 0)
            revert NoReferenceAsset();
        if (_poolParams.floor > _poolParams.inflection)
            revert FloorGreaterInflection();
        if (_poolParams.cap < _poolParams.inflection)
            revert CapSmallerInflection();
        if (_poolParams.dataProvider == address(0))
            revert ZeroAddressDataProvider();
        if (_poolParams.gradient > 10**18) revert GradientGreater1e18();
        if (_poolParams.collateralAmount < 10**6)
            revert CollateralAmountSmaller1e6();
        if (_poolParams.collateralAmount > _poolParams.capacity)
            revert PoolCapacityExceeded();
        if (
            (collateralToken.decimals() > 18) ||
            (collateralToken.decimals() < 6)
        ) revert InvalidCollateralTokenDecimals();

        // Note: Conscious decision to not include zero address checks for long/shortRecipient to enable
        // conditional burn use cases.

        // Increment `poolId` every time a new pool is created. Index
        // starts at 1. No overflow risk when using compiler version >= 0.8.0.
        ++ps.poolId;

        // Cache new poolId to avoid reading from storage
        uint256 _poolId = ps.poolId;

        // Transfer approved collateral tokens from msg.sender to Diamond contract.
        if (_transferCollateral) {
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                _poolParams.collateralAmount
            );
        }

        // Deploy two `PositionToken` contracts, one that represents shares in the short
        // and one that represents shares in the long position.
        // Naming convention for short/long token: S13/L13 where 13 is the poolId
        // Diamond contract (address(this) due to delegatecall) is set as the
        // owner of the position tokens and is the only account that is
        // authorized to call the `mint` and `burn` function therein.
        // Note that position tokens have same number of decimals as collateral token.
        string memory _shortId = string(
            abi.encodePacked("S", Strings.toString(_poolId))
        );
        PositionToken _shortToken = new PositionToken(
            _shortId,
            _shortId,
            _poolId,
            collateralToken.decimals()
        );

        string memory _longId = string(
            abi.encodePacked("L", Strings.toString(_poolId))
        );
        PositionToken _longToken = new PositionToken(
            _longId,
            _longId,
            _poolId,
            collateralToken.decimals()
        );

        // Store `Pool` struct in `pools` mapping for the newly generated `poolId`
        ps.pools[_poolId] = LibDIVAStorage.Pool(
            _poolParams.floor,
            _poolParams.inflection,
            _poolParams.cap,
            _poolParams.gradient,
            _poolParams.collateralAmount,
            0, // finalReferenceValue
            _poolParams.capacity,
            block.timestamp,
            address(_shortToken),
            0, // payoutShort
            address(_longToken),
            0, // payoutLong
            _poolParams.collateralToken,
            _poolParams.expiryTime,
            address(_poolParams.dataProvider),
            gs.protocolFee,
            gs.settlementFee,
            LibDIVAStorage.Status.Open,
            _poolParams.referenceAsset
        );

        // Number of position tokens is set equal to the total collateral to
        // standardize the max payout at 1.0. Position tokens are sent to the recipients
        // provided as part of the input parameters.
        _shortToken.mint(
            _poolParams.shortRecipient,
            _poolParams.collateralAmount
        );
        _longToken.mint(
            _poolParams.longRecipient,
            _poolParams.collateralAmount
        );

        // Log pool creation
        emit PoolIssued(
            _poolId,
            _poolParams.longRecipient,
            _poolParams.shortRecipient,
            _poolParams.collateralAmount
        );

        return _poolId;
    }

    function _addLiquidity(
        uint256 _poolId,
        uint256 _collateralAmountIncr,
        address _longRecipient,
        address _shortRecipient,
        bool _transferCollateral
    ) internal {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        // Check that pool has not expired yet
        if (block.timestamp >= _pool.expiryTime) revert Expired();

        // Check that new total pool collateral does not exceed the maximum
        // capacity of the pool
        if ((_pool.collateralBalance + _collateralAmountIncr) > _pool.capacity)
            revert PoolCapacityExceeded();

        // Note: Similar to `createContingentPool`, it's a conscious decision to not
        // include zero address checks for long/shortRecipient to enable conditional
        // burn use cases.

        // Connect to collateral token contract of the given pool Id
        IERC20Metadata collateralToken = IERC20Metadata(_pool.collateralToken);

        // Transfer approved collateral tokens from user to Diamond contract.
        if (_transferCollateral) {
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                _collateralAmountIncr
            );
        }

        // Increase `collateralBalance`
        _pool.collateralBalance += _collateralAmountIncr;

        // Mint long and short position tokens and send to `shortRecipient` and
        // `_longRecipient`, respectively (additional supply equals `_collateralAmountIncr`)
        IPositionToken(_pool.shortToken).mint(
            _shortRecipient,
            _collateralAmountIncr
        );
        IPositionToken(_pool.longToken).mint(
            _longRecipient,
            _collateralAmountIncr
        );

        // Log addition of collateral
        emit LiquidityAdded(
            _poolId,
            _longRecipient,
            _shortRecipient,
            _collateralAmountIncr
        );
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

/**
 * @notice Reduced version of Synthetix' SafeDecimalMath library for decimal
 * calculations:
 * https://github.com/Synthetixio/synthetix/blob/master/contracts/SafeDecimalMath.sol
 * Note that the code was adjusted for solidity 0.8.6 where SafeMath is no
 * longer required to handle overflows
 */

library SafeDecimalMath {
    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands
     * as fixed-point decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is
     * evaluated, so that product must be less than 2**256. As this is an
     * integer division, the internal division always rounds down. This helps
     * save on gas. Rounding is more expensive on gas.
     */
    function multiplyDecimal(
        uint256 x,
        uint256 y
    )
        internal
        pure
        returns (uint256)
    {
        // Divide by UNIT to remove the extra factor introduced by the product
        return (x * y) / UNIT;
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(
        uint256 x,
        uint256 y
    )
        internal
        pure
        returns (uint256)
    {
        // Reintroduce the UNIT factor that will be divided out by y
        return (x * UNIT) / y;
    }
}