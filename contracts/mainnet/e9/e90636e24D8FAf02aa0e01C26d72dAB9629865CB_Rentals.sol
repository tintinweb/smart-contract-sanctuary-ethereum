// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@dcl/common-contracts/meta-transactions/NativeMetaTransaction.sol";
import "@dcl/common-contracts/signatures/ContractIndexVerifiable.sol";
import "@dcl/common-contracts/signatures/SignerIndexVerifiable.sol";
import "@dcl/common-contracts/signatures/AssetIndexVerifiable.sol";

import "./interfaces/IERC721Rentable.sol";

contract Rentals is
    ContractIndexVerifiable,
    SignerIndexVerifiable,
    AssetIndexVerifiable,
    NativeMetaTransaction,
    IERC721Receiver,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    /// @dev EIP712 type hashes for recovering the signer from a signature.
    bytes32 private constant LISTING_TYPE_HASH =
        keccak256(
            bytes(
                "Listing(address signer,address contractAddress,uint256 tokenId,uint256 expiration,uint256[3] indexes,uint256[] pricePerDay,uint256[] maxDays,uint256[] minDays,address target)"
            )
        );

    bytes32 private constant OFFER_TYPE_HASH =
        keccak256(
            bytes(
                "Offer(address signer,address contractAddress,uint256 tokenId,uint256 expiration,uint256[3] indexes,uint256 pricePerDay,uint256 rentalDays,address operator,bytes32 fingerprint)"
            )
        );

    uint256 private constant MAX_FEE = 1_000_000;
    uint256 private constant MAX_RENTAL_DAYS = 36525; // 100 years

    /// @dev EIP165 hash used to detect if a contract supports the verifyFingerprint(uint256,bytes) function.
    bytes4 private constant InterfaceId_VerifyFingerprint = bytes4(keccak256("verifyFingerprint(uint256,bytes)"));

    /// @dev EIP165 hash used to detect if a contract supports the onERC721Received(address,address,uint256,bytes) function.
    bytes4 private constant InterfaceId_OnERC721Received = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @notice ERC20 token used to pay for rent and fees.
    IERC20 private token;

    /// @notice Tracks necessary rental data per asset.
    /// @custom:schema (contract address -> token id -> rental)
    mapping(address => mapping(uint256 => Rental)) internal rentals;

    /// @notice Address that will receive ERC20 tokens collected as rental fees.
    address private feeCollector;

    /// @notice Value per million wei that will be deducted from the rental price and sent to the collector.
    uint256 private fee;

    /// @notice Struct received as a parameter in `acceptListing` containing all information about
    /// listing conditions and values required to verify that the signature was created by the signer.
    struct Listing {
        address signer;
        address contractAddress;
        uint256 tokenId;
        uint256 expiration;
        uint256[3] indexes;
        uint256[] pricePerDay;
        uint256[] maxDays;
        uint256[] minDays;
        // Makes the listing acceptable only by the address defined as target.
        // Using address(0) as target will allow any address to accept it.
        address target;
        bytes signature;
    }

    /// @notice Struct received as a parameter in `acceptOffer` or as _data parameter in onERC721Received
    /// containing all information about offer conditions and values required to verify that the signature was created by the signer.
    struct Offer {
        address signer;
        address contractAddress;
        uint256 tokenId;
        uint256 expiration;
        uint256[3] indexes;
        uint256 pricePerDay;
        uint256 rentalDays;
        address operator;
        bytes32 fingerprint;
        bytes signature;
    }

    /// @notice Info stored in the rentals mapping to track rental information.
    struct Rental {
        address lessor;
        address tenant;
        uint256 endDate;
    }

    /// @dev Used internally as an argument of the _rent function as an alternative to passing a long list
    /// of arguments.
    struct RentParams {
        address lessor;
        address tenant;
        address contractAddress;
        uint256 tokenId;
        bytes32 fingerprint;
        uint256 pricePerDay;
        uint256 rentalDays;
        address operator;
        bytes signature;
    }

    event FeeCollectorUpdated(address _from, address _to, address _sender);
    event FeeUpdated(uint256 _from, uint256 _to, address _sender);
    event AssetClaimed(address indexed _contractAddress, uint256 indexed _tokenId, address _sender);
    event AssetRented(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address _lessor,
        address _tenant,
        address _operator,
        uint256 _rentalDays,
        uint256 _pricePerDay,
        bool _isExtension,
        address _sender,
        bytes _signature
    );

    constructor() {
        // Prevents the implementation to be initialized.
        // Initialization can only be done through a Proxy.
        _disableInitializers();
    }

    /// @notice Initialize the contract.
    /// @dev This method should be called as soon as the contract is deployed.
    /// Using this method in favor of a constructor allows the implementation of various kinds of proxies.
    /// @param _owner The address of the owner of the contract.
    /// @param _token The address of the ERC20 token used by tenants to pay rent.
    /// This token is set once on initialization and cannot be changed afterwards.
    /// @param _feeCollector Address that will receive rental fees
    /// @param _fee Value per million wei that will be transferred from the rental price to the fee collector.
    function initialize(
        address _owner,
        IERC20 _token,
        address _feeCollector,
        uint256 _fee
    ) external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __NativeMetaTransaction_init("Rentals", "1");
        __ContractIndexVerifiable_init();
        _transferOwnership(_owner);
        _setFeeCollector(_feeCollector);
        _setFee(_fee);

        token = _token;
    }

    /// @notice Pause the contract and prevent core functions from being called.
    /// Functions that will be paused are:
    /// - acceptListing
    /// - acceptOffer
    /// - onERC721Received (No offers will be accepted through a safeTransfer to this contract)
    /// - claim
    /// - setUpdateOperator
    /// - setManyLandUpdateOperator
    /// @dev The contract has to be unpaused or this function will revert.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resume the normal functionality of the contract.
    /// @dev The contract has to be paused or this function will revert.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the rental data for a given asset.
    /// @param _contractAddress The contract address of the asset.
    /// @param _tokenId The id of the asset.
    function getRental(address _contractAddress, uint256 _tokenId) external view returns (Rental memory) {
        return rentals[_contractAddress][_tokenId];
    }

    /// @notice Get the current token address used for rental payments.
    /// @return The address of the token.
    function getToken() external view returns (IERC20) {
        return token;
    }

    /// @notice Get the current address that will receive a cut of rental payments as a fee.
    /// @return The address of the fee collector.
    function getFeeCollector() external view returns (address) {
        return feeCollector;
    }

    /// @notice Get the value per MAX_FEE that will be cut from the rental payment and sent to the fee collector.
    /// @return The value of the current fee.
    function getFee() external view returns (uint256) {
        return fee;
    }

    /// @notice Get if an asset is currently being rented.
    /// @param _contractAddress The contract address of the asset.
    /// @param _tokenId The token id of the asset.
    /// @return True or false depending if the asset is currently rented.
    function getIsRented(address _contractAddress, uint256 _tokenId) public view returns (bool) {
        return block.timestamp <= rentals[_contractAddress][_tokenId].endDate;
    }

    /// @notice Set the address of the fee collector.
    /// @param _feeCollector The address of the fee collector.
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /// @notice Set the fee (per million wei) for rentals.
    /// @param _fee The value for the fee.
    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    /// @notice Accept a rental listing created by the owner of an asset.
    /// @param _listing Contains the listing conditions as well as the signature data for verification.
    /// @param _operator The address that will be given operator permissions over an asset.
    /// @param _conditionIndex The rental conditions index chosen from the options provided in _listing.
    /// @param _rentalDays The amount of days the caller wants to rent the asset.
    /// Must be a value between the selected condition's min and max days.
    /// @param _fingerprint The fingerprint used to verify composable erc721s.
    /// Useful in order to prevent a front run were, for example, the owner removes LAND from an Estate before
    /// the listing is accepted. Causing the tenant to end up with an Estate that does not have the amount of LAND
    /// they expect.
    function acceptListing(
        Listing calldata _listing,
        address _operator,
        uint256 _conditionIndex,
        uint256 _rentalDays,
        bytes32 _fingerprint
    ) external nonReentrant whenNotPaused {
        _verifyUnsafeTransfer(_listing.contractAddress, _listing.tokenId);

        address lessor = _listing.signer;
        address tenant = _msgSender();

        // Verify that the caller and the signer are not the same address.
        require(tenant != lessor, "Rentals#acceptListing: CALLER_CANNOT_BE_SIGNER");

        // Verify that the targeted address in the listing, if not address(0), is the caller of this function.
        require(_listing.target == address(0) || _listing.target == tenant, "Rentals#acceptListing: TARGET_MISMATCH");

        // Verify that the indexes provided in the listing match the ones in the contract.
        _verifyContractIndex(_listing.indexes[0]);
        _verifySignerIndex(lessor, _listing.indexes[1]);
        _verifyAssetIndex(_listing.contractAddress, _listing.tokenId, lessor, _listing.indexes[2]);

        uint256 pricePerDayLength = _listing.pricePerDay.length;

        // Verify that pricePerDay, maxDays and minDays have the same length
        require(pricePerDayLength == _listing.maxDays.length, "Rentals#acceptListing: MAX_DAYS_LENGTH_MISMATCH");
        require(pricePerDayLength == _listing.minDays.length, "Rentals#acceptListing: MIN_DAYS_LENGTH_MISMATCH");

        // Verify that the provided condition index is not out of bounds of the listing conditions.
        require(_conditionIndex < pricePerDayLength, "Rentals#acceptListing: CONDITION_INDEX_OUT_OF_BOUNDS");

        // Verify that the listing is not already expired.
        require(_listing.expiration >= block.timestamp, "Rentals#acceptListing: EXPIRED_SIGNATURE");

        uint256 maxDays = _listing.maxDays[_conditionIndex];
        uint256 minDays = _listing.minDays[_conditionIndex];

        // Verify that minDays and maxDays have valid values.
        require(minDays <= maxDays, "Rentals#acceptListing: MAX_DAYS_LOWER_THAN_MIN_DAYS");
        require(minDays > 0, "Rentals#acceptListing: MIN_DAYS_IS_ZERO");

        // Verify that the provided rental days is between min and max days range.
        require(_rentalDays >= minDays && _rentalDays <= maxDays, "Rentals#acceptListing: DAYS_NOT_IN_RANGE");

        // Verify that the provided rental days does not exceed MAX_RENTAL_DAYS
        require(_rentalDays <= MAX_RENTAL_DAYS, "Rentals#acceptListing: RENTAL_DAYS_EXCEEDS_LIMIT");

        _verifyListingSigner(_listing);

        _rent(
            RentParams(
                lessor,
                tenant,
                _listing.contractAddress,
                _listing.tokenId,
                _fingerprint,
                _listing.pricePerDay[_conditionIndex],
                _rentalDays,
                _operator,
                _listing.signature
            )
        );
    }

    /// @notice Accept an offer for rent of an asset owned by the caller.
    /// @param _offer Contains the offer conditions as well as the signature data for verification.
    function acceptOffer(Offer calldata _offer) external {
        _verifyUnsafeTransfer(_offer.contractAddress, _offer.tokenId);

        _acceptOffer(_offer, _msgSender());
    }

    /// @notice The original owner of the asset can claim it back if said asset is not being rented.
    /// @param _contractAddresses The contract address of the assets to be claimed.
    /// @param _tokenIds The token ids of the assets to be claimed.
    /// Each tokenId corresponds to a contract address in the same index.
    function claim(address[] calldata _contractAddresses, uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        require(_contractAddresses.length == _tokenIds.length, "Rentals#claim: LENGTH_MISMATCH");

        address sender = _msgSender();

        uint256 contractAddressesLength = _contractAddresses.length;

        for (uint256 i; i < contractAddressesLength; ) {
            address contractAddress = _contractAddresses[i];
            uint256 tokenId = _tokenIds[i];

            // Verify that the rent has finished.
            require(!getIsRented(contractAddress, tokenId), "Rentals#claim: CURRENTLY_RENTED");

            address lessor = rentals[contractAddress][tokenId].lessor;

            // Verify that the caller is the original owner of the asset.
            require(lessor == sender, "Rentals#claim: NOT_LESSOR");

            // Delete the data for the rental as it is not necessary anymore.
            delete rentals[contractAddress][tokenId];

            // Transfer the asset back to its original owner.
            IERC721Rentable asset = IERC721Rentable(contractAddress);

            asset.safeTransferFrom(address(this), sender, tokenId);

            emit AssetClaimed(contractAddress, tokenId, sender);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the update operator of the provided assets.
    /// @dev Only when the rent is active a tenant can change the operator of an asset.
    /// When the rent is over, the lessor is the one that can change operators.
    /// In the case of the lessor, this is useful to update the operator without having to claim the asset back once the rent is over.
    /// Elements in the param arrays correspond to each other in the same index.
    /// For example, asset with address _contractAddresses[0] and token id _tokenIds[0] will be set _operators[0] as operator.
    /// @param _contractAddresses The contract addresses of the assets.
    /// @param _tokenIds The token ids of the assets.
    /// @param _operators The addresses that will have operator privileges over the given assets in the same index.
    function setUpdateOperator(
        address[] calldata _contractAddresses,
        uint256[] calldata _tokenIds,
        address[] calldata _operators
    ) external nonReentrant whenNotPaused {
        require(
            _contractAddresses.length == _tokenIds.length && _contractAddresses.length == _operators.length,
            "Rentals#setUpdateOperator: LENGTH_MISMATCH"
        );

        address sender = _msgSender();

        uint256 tokenIdsLength = _tokenIds.length;

        for (uint256 i; i < tokenIdsLength; ) {
            address contractAddress = _contractAddresses[i];
            uint256 tokenId = _tokenIds[i];
            Rental storage rental = rentals[contractAddress][tokenId];
            bool isRented = getIsRented(contractAddress, tokenId);

            require(
                (isRented && sender == rental.tenant) || (!isRented && sender == rental.lessor),
                "Rentals#setUpdateOperator: CANNOT_SET_UPDATE_OPERATOR"
            );

            IERC721Rentable(contractAddress).setUpdateOperator(tokenId, _operators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set the operator of individual LANDs inside an Estate
    /// @dev LAND inside an Estate can be granularly given update operator permissions by calling the setLandUpdateOperator
    /// (or setManyLandUpdateOperator) in the Estate contract.
    /// All update operators defined like this will remain after the Estate is rented because they are not cleared up on transfer.
    /// To prevent these remaining update operators from being able to deploy and override scenes from the current tenant, the tenant
    /// can call this function to clear or override them.
    /// The lessor can do the same after the rental is over to clear up any individual LAND update operators set by the tenant.
    /// @param _contractAddress The address of the Estate contract containing the LANDs that will have their update operators updated.
    /// @param _tokenId The Estate id.
    /// @param _landTokenIds An array of LAND token id arrays which will have the update operator updated. Each array corresponds to the operator of the same index.
    /// @param _operators An array of addresses that will be set as update operators of the provided LAND token ids.
    function setManyLandUpdateOperator(
        address _contractAddress,
        uint256 _tokenId,
        uint256[][] calldata _landTokenIds,
        address[] calldata _operators
    ) external nonReentrant whenNotPaused {
        require(_landTokenIds.length == _operators.length, "Rentals#setManyLandUpdateOperator: LENGTH_MISMATCH");

        Rental storage rental = rentals[_contractAddress][_tokenId];
        bool isRented = getIsRented(_contractAddress, _tokenId);
        address sender = _msgSender();

        require(
            (isRented && sender == rental.tenant) || (!isRented && sender == rental.lessor),
            "Rentals#setManyLandUpdateOperator: CANNOT_SET_MANY_LAND_UPDATE_OPERATOR"
        );

        uint256 landTokenIdsLength = _landTokenIds.length;

        for (uint256 i; i < landTokenIdsLength; ) {
            IERC721Rentable(_contractAddress).setManyLandUpdateOperator(_tokenId, _landTokenIds[i], _operators[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Standard function called by ERC721 contracts whenever a safe transfer occurs.
    /// Provides an alternative to acceptOffer by letting the asset holder send the asset to the contract
    /// and accepting the offer at the same time.
    /// IMPORTANT: Addresses (Not necessarily EOA but contracts as well) that have been given allowance to an asset can safely transfer said asset to this contract
    /// to accept an offer. The address that has been given allowance will be considered the lessor, and will enjoy all of its benefits,
    /// including the ability to claim the asset back to themselves after the rental period is over.
    /// @param _operator Caller of the safeTransfer function.
    /// @param _tokenId Id of the asset received.
    /// @param _data Bytes containing offer data.
    function onERC721Received(
        address _operator,
        address, // _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (_operator != address(this)) {
            Offer memory offer = abi.decode(_data, (Offer));

            // Check that the caller is the contract defined in the offer to ensure the function is being
            // called through an ERC721.safeTransferFrom.
            // Also check that the token id is the same as the one provided in the offer.
            require(msg.sender == offer.contractAddress && offer.tokenId == _tokenId, "Rentals#onERC721Received: ASSET_MISMATCH");

            _acceptOffer(offer, _operator);
        }

        return InterfaceId_OnERC721Received;
    }

    /// @dev Overriding to return NativeMetaTransaction._getMsgSender for the contract to support meta transactions.
    function _msgSender() internal view override returns (address) {
        return _getMsgSender();
    }

    function _setFeeCollector(address _feeCollector) private {
        emit FeeCollectorUpdated(feeCollector, feeCollector = _feeCollector, _msgSender());
    }

    function _setFee(uint256 _fee) private {
        require(_fee <= MAX_FEE, "Rentals#_setFee: HIGHER_THAN_MAX_FEE");

        emit FeeUpdated(fee, fee = _fee, _msgSender());
    }

    /// @dev Someone might send an asset to this contract via an unsafe transfer, causing ownerOf checks to be inconsistent with the state
    /// of this contract. This function is used to prevent interactions with these assets.
    /// ERC721 ASSETS SENT UNSAFELY WILL REMAIN LOCKED INSIDE THIS CONTRACT.
    function _verifyUnsafeTransfer(address _contractAddress, uint256 _tokenId) private view {
        address lessor = rentals[_contractAddress][_tokenId].lessor;
        address assetOwner = IERC721Rentable(_contractAddress).ownerOf(_tokenId);

        if (lessor == address(0) && assetOwner == address(this)) {
            revert("Rentals#_verifyUnsafeTransfer: ASSET_TRANSFERRED_UNSAFELY");
        }
    }

    function _acceptOffer(Offer memory _offer, address _lessor) private nonReentrant whenNotPaused {
        address tenant = _offer.signer;

        // Verify that the caller and the signer are not the same address.
        require(_lessor != tenant, "Rentals#_acceptOffer: CALLER_CANNOT_BE_SIGNER");

        // Verify that the indexes provided in the offer match the ones in the contract.
        _verifyContractIndex(_offer.indexes[0]);
        _verifySignerIndex(tenant, _offer.indexes[1]);
        _verifyAssetIndex(_offer.contractAddress, _offer.tokenId, tenant, _offer.indexes[2]);

        // Verify that the offer is not already expired.
        require(_offer.expiration >= block.timestamp, "Rentals#_acceptOffer: EXPIRED_SIGNATURE");

        // Verify that the rental days provided in the offer are valid.
        require(_offer.rentalDays > 0, "Rentals#_acceptOffer: RENTAL_DAYS_IS_ZERO");

        // Verify that the provided rental days does not exceed MAX_RENTAL_DAYS
        require(_offer.rentalDays <= MAX_RENTAL_DAYS, "Rentals#_acceptOffer: RENTAL_DAYS_EXCEEDS_LIMIT");

        _verifyOfferSigner(_offer);

        _rent(
            RentParams(
                _lessor,
                tenant,
                _offer.contractAddress,
                _offer.tokenId,
                _offer.fingerprint,
                _offer.pricePerDay,
                _offer.rentalDays,
                _offer.operator,
                _offer.signature
            )
        );
    }

    /// @dev Verify that the signer provided in the listing is the address that created the provided signature.
    function _verifyListingSigner(Listing calldata _listing) private view {
        address listingSigner = _listing.signer;

        bytes32 listingHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LISTING_TYPE_HASH,
                    listingSigner,
                    _listing.contractAddress,
                    _listing.tokenId,
                    _listing.expiration,
                    keccak256(abi.encodePacked(_listing.indexes)),
                    keccak256(abi.encodePacked(_listing.pricePerDay)),
                    keccak256(abi.encodePacked(_listing.maxDays)),
                    keccak256(abi.encodePacked(_listing.minDays)),
                    _listing.target
                )
            )
        );

        _verifySigner(listingSigner, listingHash, _listing.signature);
    }

    /// @dev Verify that the signer provided in the offer is the address that created the provided signature.
    function _verifyOfferSigner(Offer memory _offer) private view {
        address offerSigner = _offer.signer;

        bytes32 offerHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    OFFER_TYPE_HASH,
                    offerSigner,
                    _offer.contractAddress,
                    _offer.tokenId,
                    _offer.expiration,
                    keccak256(abi.encodePacked(_offer.indexes)),
                    _offer.pricePerDay,
                    _offer.rentalDays,
                    _offer.operator,
                    _offer.fingerprint
                )
            )
        );

        _verifySigner(offerSigner, offerHash, _offer.signature);
    }

    /// @dev Verify that the signature is valid for the provided signer and hash.
    /// Will perform an ecrecover for EOA _signers and ERC1271 verification for contract _signers.
    function _verifySigner(
        address _signer,
        bytes32 _hash,
        bytes memory _signature
    ) private view {
        if (_signer.code.length == 0) {
            require(_signer == ECDSAUpgradeable.recover(_hash, _signature), "Rentals#_verifySigner: SIGNER_MISMATCH");
        } else {
            require(
                IERC1271.isValidSignature.selector == IERC1271(_signer).isValidSignature(_hash, _signature),
                "Rentals#_verifySigner: MAGIC_VALUE_MISMATCH"
            );
        }
    }

    function _rent(RentParams memory _rentParams) private {
        IERC721Rentable asset = IERC721Rentable(_rentParams.contractAddress);

        // If the provided contract supports the verifyFingerprint function, validate the provided fingerprint.
        if (asset.supportsInterface(InterfaceId_VerifyFingerprint)) {
            require(asset.verifyFingerprint(_rentParams.tokenId, abi.encode(_rentParams.fingerprint)), "Rentals#_rent: INVALID_FINGERPRINT");
        }

        Rental storage rental = rentals[_rentParams.contractAddress][_rentParams.tokenId];

        // True if the asset is currently rented.
        bool isRented = getIsRented(_rentParams.contractAddress, _rentParams.tokenId);
        // True if the asset rental period is over, but is has not been claimed back from the contract.
        bool isReRent = !isRented && rental.lessor != address(0);
        // True if the asset rental period is not over yet, but the lessor and the tenant are the same.
        bool isExtend = isRented && rental.lessor == _rentParams.lessor && rental.tenant == _rentParams.tenant;

        if (!isExtend && !isReRent) {
            // Verify that the asset is not already rented.
            require(!isRented, "Rentals#_rent: CURRENTLY_RENTED");
        }

        if (isReRent) {
            // The asset is being rented again without claiming it back first, so we need to check that the previous lessor
            // is the same as the lessor this time to prevent anyone else from acting as the lessor.
            require(rental.lessor == _rentParams.lessor, "Rentals#_rent: NOT_ORIGINAL_OWNER");
        }

        if (isExtend) {
            // Increase the current end date by the amount of provided rental days.
            rental.endDate = rental.endDate + _rentParams.rentalDays * 1 days;
        } else {
            // Track the original owner of the asset in the lessors map for future use.
            rental.lessor = _rentParams.lessor;

            // Track the new tenant in the mapping.
            rental.tenant = _rentParams.tenant;

            // Set the end date of the rental according to the provided rental days
            rental.endDate = block.timestamp + _rentParams.rentalDays * 1 days;
        }

        // Update the asset indexes for both the lessor and the tenant to invalidate old signatures.
        _bumpAssetIndex(_rentParams.contractAddress, _rentParams.tokenId, _rentParams.lessor);
        _bumpAssetIndex(_rentParams.contractAddress, _rentParams.tokenId, _rentParams.tenant);

        // Transfer tokens
        if (_rentParams.pricePerDay > 0) {
            _handleTokenTransfers(_rentParams.lessor, _rentParams.tenant, _rentParams.pricePerDay, _rentParams.rentalDays);
        }

        // Only transfer the ERC721 to this contract if it doesn't already have it.
        if (asset.ownerOf(_rentParams.tokenId) != address(this)) {
            asset.safeTransferFrom(_rentParams.lessor, address(this), _rentParams.tokenId);
        }

        // Update the operator
        asset.setUpdateOperator(_rentParams.tokenId, _rentParams.operator);

        emit AssetRented(
            _rentParams.contractAddress,
            _rentParams.tokenId,
            _rentParams.lessor,
            _rentParams.tenant,
            _rentParams.operator,
            _rentParams.rentalDays,
            _rentParams.pricePerDay,
            isExtend,
            _msgSender(),
            _rentParams.signature
        );
    }

    /// @dev Transfer the erc20 tokens required to start a rent from the tenant to the lessor and the fee collector.
    function _handleTokenTransfers(
        address _lessor,
        address _tenant,
        uint256 _pricePerDay,
        uint256 _rentalDays
    ) private {
        uint256 totalPrice = _pricePerDay * _rentalDays;
        uint256 forCollector = (totalPrice * fee) / MAX_FEE;

        // Save the reference in memory so it doesn't access storage twice.
        IERC20 mToken = token;

        // Transfer the rental payment to the lessor minus the fee which is transferred to the collector.
        mToken.transferFrom(_tenant, _lessor, totalPrice - forCollector);
        mToken.transferFrom(_tenant, feeCollector, forCollector);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

abstract contract NativeMetaTransaction is EIP712Upgradeable {
    /// @dev EIP712 type hash for recovering the signer from the signature.
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionData)"));

    /// @notice Track signer nonces so the same signature cannot be used more than once.
    mapping(address => uint256) private nonces;

    /// @notice Struct with the data required to verify that the signature signer is the same as `from`.
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionData;
    }

    event MetaTransactionExecuted(address indexed _userAddress, address indexed _relayerAddress, bytes _functionData);

    function __NativeMetaTransaction_init(string memory _name, string memory _version) internal onlyInitializing {
        __EIP712_init(_name, _version);
    }

    function __NativeMetaTransaction_init_unchained() internal onlyInitializing {}

    /// @notice Get the current nonce of a given signer.
    /// @param _signer The address of the signer.
    /// @return The current nonce of the signer.
    function getNonce(address _signer) external view returns (uint256) {
        return nonces[_signer];
    }

    /// @notice Execute a transaction from the contract appending _userAddress to the call data.
    /// @dev The appended address can then be extracted from the called context with _getMsgSender instead of using msg.sender.
    /// The caller of `executeMetaTransaction` will pay for gas fees so _userAddress can experience "gasless" transactions.
    /// @param _userAddress The address appended to the call data.
    /// @param _functionData Data containing information about the contract function to be called.
    /// @param _signature Signature created by _userAddress to validate that they wanted
    /// @return The data as bytes of what the relayed function would have returned.
    function executeMetaTransaction(
        address _userAddress,
        bytes calldata _functionData,
        bytes calldata _signature
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({nonce: nonces[_userAddress], from: _userAddress, functionData: _functionData});

        require(_verify(_userAddress, metaTx, _signature), "NativeMetaTransaction#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH");

        nonces[_userAddress]++;

        emit MetaTransactionExecuted(_userAddress, msg.sender, _functionData);

        (bool success, bytes memory returnData) = address(this).call{value: msg.value}(abi.encodePacked(_functionData, _userAddress));

        // Bubble up error based on https://ethereum.stackexchange.com/a/83577
        if (!success) {
            assembly {
                // Slice the sighash.
                returnData := add(returnData, 0x04)
            }

            revert(abi.decode(returnData, (string)));
        }

        return returnData;
    }

    function _verify(
        address _signer,
        MetaTransaction memory _metaTx,
        bytes calldata _signature
    ) private view returns (bool) {
        bytes32 structHash = keccak256(abi.encode(META_TRANSACTION_TYPEHASH, _metaTx.nonce, _metaTx.from, keccak256(_metaTx.functionData)));
        bytes32 typedDataHash = _hashTypedDataV4(structHash);

        return _signer == ECDSAUpgradeable.recover(typedDataHash, _signature);
    }

    /// @dev Extract the address of the sender from the msg.data if available. If not, fallback to returning the msg.sender.
    /// @dev It is vital that the implementor uses this function for meta transaction support.
    function _getMsgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }

        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ContractIndexVerifiable is OwnableUpgradeable {
    /// @notice Current index at a contract level. Only updatable by the owner of the contract.
    /// Updating it will invalidate all signatures created with the previous value on a contract level.
    uint256 private contractIndex;

    event ContractIndexUpdated(uint256 _newIndex, address _sender);

    function __ContractIndexVerifiable_init() internal onlyInitializing {
        __Ownable_init();
    }

    function __ContractIndexVerifiable_init_unchained() internal onlyInitializing {}

    /// @notice Get the current contract index.
    /// @return The current contract index.
    function getContractIndex() external view returns (uint256) {
        return contractIndex;
    }

    /// @notice As the owner of the contract, increase the contract index by 1.
    function bumpContractIndex() external onlyOwner {
        _bumpContractIndex();
    }

    /// @dev Increase the contract index by 1
    function _bumpContractIndex() internal {
        emit ContractIndexUpdated(++contractIndex, _msgSender());
    }

    /// @dev Reverts if the provided index does not match the contract index.
    function _verifyContractIndex(uint256 _index) internal view {
        require(_index == contractIndex, "ContractIndexVerifiable#_verifyContractIndex: CONTRACT_INDEX_MISMATCH");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract SignerIndexVerifiable is ContextUpgradeable {
    /// @notice Current index per signer.
    /// Updating it will invalidate all signatures created with the previous value on a signer level.
    /// @custom:schema (signer address -> index)
    mapping(address => uint256) private signerIndex;

    event SignerIndexUpdated(address indexed _signer, uint256 _newIndex, address _sender);

    function __SignerIndexVerifiable_init() internal onlyInitializing {}

    function __SignerIndexVerifiable_init_unchained() internal onlyInitializing {}

    /// @notice Get the current signer index.
    /// @param _signer The address of the signer.
    /// @return The index of the given signer.
    function getSignerIndex(address _signer) external view returns (uint256) {
        return signerIndex[_signer];
    }

    /// @notice Increase the signer index of the sender by 1.
    function bumpSignerIndex() external {
        _bumpSignerIndex(_msgSender());
    }

    /// @dev Increase the signer index by 1
    function _bumpSignerIndex(address _signer) internal {
        emit SignerIndexUpdated(_signer, ++signerIndex[_signer], _msgSender());
    }

    /// @dev Reverts if the provided index does not match the signer index.
    function _verifySignerIndex(address _signer, uint256 _index) internal view {
        require(_index == signerIndex[_signer], "SignerIndexVerifiable#_verifySignerIndex: SIGNER_INDEX_MISMATCH");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract AssetIndexVerifiable is ContextUpgradeable {
    /// @notice Current index per asset per signer.
    /// Updating it will invalidate all signatures created with the previous value on an asset level.
    /// @custom:schema (contract address -> token id -> signer address -> index)
    mapping(address => mapping(uint256 => mapping(address => uint256))) private assetIndex;

    event AssetIndexUpdated(address indexed _signer, address indexed _contractAddress, uint256 indexed _tokenId, uint256 _newIndex, address _sender);

    function __AssetIndexVerifiable_init() internal onlyInitializing {}

    function __AssetIndexVerifiable_init_unchained() internal onlyInitializing {}

    /// @notice Get the signer index for a given ERC721 token.
    /// @param _contractAddress The address of the ERC721 contract.
    /// @param _tokenId The id of the ERC721 token.
    /// @param _signer The address of the signer.
    /// @return The index of the given signer for the provided asset.
    function getAssetIndex(
        address _contractAddress,
        uint256 _tokenId,
        address _signer
    ) external view returns (uint256) {
        return assetIndex[_contractAddress][_tokenId][_signer];
    }

    /// @notice Increase the asset index of the sender by 1.
    /// @param _contractAddress The contract address of the asset.
    /// @param _tokenId The token id of the asset.
    function bumpAssetIndex(address _contractAddress, uint256 _tokenId) external {
        _bumpAssetIndex(_contractAddress, _tokenId, _msgSender());
    }

    /// @dev Increase the asset index by 1
    function _bumpAssetIndex(
        address _contractAddress,
        uint256 _tokenId,
        address _signer
    ) internal {
        emit AssetIndexUpdated(_signer, _contractAddress, _tokenId, ++assetIndex[_contractAddress][_tokenId][_signer], _msgSender());
    }

    /// @dev Reverts if the provided index does not match the asset index.
    function _verifyAssetIndex(
        address _contractAddress,
        uint256 _tokenId,
        address _signer,
        uint256 _index
    ) internal view {
        require(_index == assetIndex[_contractAddress][_tokenId][_signer], "AssetIndexVerifiable#_verifyAssetIndex: ASSET_INDEX_MISMATCH");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice Extended ERC721 interface with methods required by the Rentals contract.
interface IERC721Rentable is IERC721 {
    /// @dev Updates the operator of the asset.
    /// The idea of this role is mostly of a content operator, a role capable of modifying the content of the asset.
    /// It is not the same as the one defined in the ERC721 standard, which can manipulate the asset in itself.
    function setUpdateOperator(uint256, address) external;

    /// @dev Updates the update operator of many DCL LANDs simultaneously inside an Estate.
    function setManyLandUpdateOperator(
        uint256 _tokenId,
        uint256[] memory _landTokenIds,
        address _operator
    ) external;

    /// @dev Checks that the provided fingerprint matches the fingerprint of the composable asset.
    function verifyFingerprint(uint256, bytes memory) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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