// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { DelegationOwner } from "./DelegationOwner.sol";

import { GnosisSafeProxyFactory, GnosisSafeProxy } from "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import { GnosisSafe } from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// import "forge-std/console2.sol";

/**
 * @title RentalsController
 * @author BootNode
 * @dev This contract allows DelegationWallet owners to list NFTs and the signature for rental, and renters to rent NFTs and signatures.
 */
contract RentalsController is Ownable {
    bool internal isExecuting;
    bytes32 internal currentTxHash;

    /**
     * @notice Listing information, it used for NFTs and signatures.
     *
     * @param safe - The address of GnosisSafe used as the DelegationWallet.
     * @param owner - The address that owns the listing and will receive the payment when someone rents it.
     * It needs to match with the msg.sender and be owner of the DelegationWallet.
     * @param minDuration - The minimum number of days a NFT/signature can be rented.
     * @param maxDuration - The maximum number of days a NFT/signature can be rented.
     * @param endDate - The date (seconds timestamp) when this listing expires, 0 if it never expires.
     * Any rental end date made out of this listing should be earlier.
     * @param dailyValue - The amount of ETH (wei) charged per day of rental.
     */
    struct Listing {
        address safe;
        address owner;
        uint256 minDuration; // in days
        uint256 maxDuration; // in days
        uint256 endDate;
        uint256 dailyValue;
    }

    /**
     * @notice List of assets the owner is committed to lock on the DelegationWallet during the period of a signature rental.
     *
     * @param assets - The addresses of the assets.
     * @param assetIds - The ids of the assets.
     */
    struct SignatureAssets {
        address[] assets;
        uint256[] assetIds;
    }

    /**
     * @notice Stores information related to a rental.
     *
     * @param safe - The address of GnosisSafe used as the DelegationWallet.
     * @param owner - The address of the listing owner.
     * @param renter - The address the renter.
     * @param from - The date (seconds timestamp) when the rental starts.
     * @param to - The date (seconds timestamp) when the rental finishes.
     * @param value - The amount of ETH (wei) paid for the rental.
     */
    struct Rental {
        address safe;
        address owner;
        address renter;
        uint256 from;
        uint256 to;
        uint256 value;
    }

    /**
     * @notice Stores information related to assets listed for sale
     *
     * @param safe - The address of GnosisSafe used as the DelegationWallet.
     * @param owner - The address that owns the listing and will receive the payment when someone buys it.
     * It needs to match with the msg.sender and be owner of the DelegationWallet.
     * @param buyer - The address that wants to buy the Asset.
     * @param daysToPayment - The number of days the buyer has to fulfil the purchase payment.
     * @param deposit - The amount of ETH (wei) the buyer has to pay to start the operation.
     * @param value - The amount of ETH (wei) the buyer has to pay before the payment day.
     */
    struct SellAssetListing {
        address safe;
        address owner;
        uint256 daysForPayment;
        uint256 deposit;
        uint256 value;
    }

    /**
     * @notice Stores information related to assets in the process of sale
     *
     * @param safe - The address of GnosisSafe used as the DelegationWallet.
     * @param owner - The address that owns the listing and will receive the payment when someone buys it.
     * It needs to match with the msg.sender and be owner of the DelegationWallet.
     * @param buyer - The address that wants to buy the Asset.
     * @param dueDate - The buyer has to pay for the asset before this date.
     * @param valueToPay - The amount of ETH (wei) the buyer has to pay before dueDate.
     */
    struct SellAsset {
        address safe;
        address owner;
        address buyer;
        uint256 dueDate;
        uint256 valueToPay;
    }

    /**
     * @notice Address of the DelegationWalletFactory contract.
     */
    address public delegationWalletFactory;

    /**
     * @notice Stores the list of current asset listings. asset => id => Listing
     */
    mapping(address => mapping(uint256 => Listing)) public assetListings;

    /**
     * @notice Stores the list of current asset listed for sale. asset => id => SellAssetListing
     */
    mapping(address => mapping(uint256 => SellAssetListing)) public sellAssetListings;

    /**
     * @notice Stores the list of current signature listings. safe => Listing
     */
    mapping(address => Listing) public signatureListings;

    /**
     * @notice Stores the list of assets to be lock when renting a signature
     */
    mapping(address => SignatureAssets) internal assetsBySignature;

    /**
     * @notice Stores the list of current asset rentals. asset => id => Rent
     */
    mapping(address => mapping(uint256 => Rental)) public assetRentals;

    /**
     * @notice Stores the sell information for assets. asset => id => SellAsset
     */
    mapping(address => mapping(uint256 => SellAsset)) public sellAssets;

    /**
     * @notice Stores the list of current signature rentals. safe => Rental
     */
    mapping(address => Rental) public signatureRentals;

    /**
     * @notice Stores the DelegationOwner contract for each DelegationWallet deployed through the
     * DelegationWalletFactory. safe => rentalOwner
     */
    mapping(address => DelegationOwner) public ownerBySafe;

    uint256 public liquidationFee = 100; // 1 bps 10000/100

    // ========== Events ===========
    event SaveAssetListing(
        address indexed safe,
        address indexed nft,
        uint256 indexed id,
        address owner,
        uint256 minDuration,
        uint256 maxDuration,
        uint256 endDate,
        uint256 dailyValue
    );

    event SaveSignatureListing(
        address indexed safe,
        address indexed owner,
        uint256 minDuration,
        uint256 maxDuration,
        uint256 endDate,
        uint256 dailyValue,
        address[] assets,
        uint256[] assetIds
    );

    event SaveAssetForSaleListing(
        address indexed safe,
        address indexed nft,
        uint256 id,
        address indexed owner,
        uint256 dayForPayment,
        uint256 deposit,
        uint256 value
    );

    event RemoveAssetListing(address indexed nft, uint256 indexed id, address indexed safe);
    event RemoveSignatureListing(address indexed safe);
    event RemoveAssetForSaleListing(address indexed nft, uint256 indexed id, address indexed safe);

    event AssetRented(
        address indexed safe,
        address indexed nft,
        uint256 indexed id,
        uint256 duration,
        uint256 value,
        address renter
    );

    event SignatureRented(
        address indexed safe,
        uint256 duration,
        uint256 value,
        address indexed renter,
        address[] assets,
        uint256[] assetIds
    );

    event AssetBought(
        address nft,
        uint256 id,
        address indexed safe,
        address indexed owner,
        address indexed buyer,
        uint256 deposit,
        uint256 value
    );

    event AssetPaid(
        address nft,
        uint256 id,
        address indexed safe,
        address indexed owner,
        address indexed buyer,
        uint256 value
    );

    // ========== Custom Errors ===========
    error RentalsController__onlyFactory();

    error RentalsController__listRental_invalidOwner();
    error RentalsController__listRental_invalidSafe();
    error RentalsController__listRental_invalidNft();
    error RentalsController__listRental_invalidDuration();
    error RentalsController__listRental_invalidValue();
    error RentalsController__listRental_notOwnedNft();
    error RentalsController__listRental_notOwner();
    error RentalsController__listRental_noDelegationOwner();

    error RentalsController__rentAsset_notListed();
    error RentalsController__rentAsset_wrongValue();
    error RentalsController__rentAsset_notOwnedNft();
    error RentalsController__rentAsset_invalidDuration();
    error RentalsController__rentAsset_invalidEndDate();

    error RentalsController__createAssetListing_invalidOwner();
    error RentalsController__createAssetListing_invalidNft();
    error RentalsController__createAssetForSaleListing_invalidOwner();
    error RentalsController__createAssetForSaleListing_invalidNft();
    error RentalsController__createAssetForSaleListing_invalidDaysForPayment();
    error RentalsController__createAssetForSaleListing_invalidDeposit();
    error RentalsController__createAssetForSaleListing_invalidValue();

    error RentalsController__buyAsset_notListed();
    error RentalsController__buyAsset_alreadySold();
    error RentalsController__buyAsset_noDelegationOwner();
    error RentalsController__buyAsset_notOwnedNft();
    error RentalsController__buyAsset_wrongDepositValue();
    error RentalsController__buyAsset_isLocked();
    error RentalsController__buyAsset_isDelegated();
    error RentalsController__buyAsset_isSignatureDelegated();

    error RentalsController__payAsset_notListed();
    error RentalsController__payAsset_noDelegationOwner();
    error RentalsController__payAsset_paydayHasPassed();
    error RentalsController__payAsset_wrongPaymentValue();
    error RentalsController__payAsset_wrongOwner();

    error RentalsController__deploymentSanityChecks_invalidSafe();
    error RentalsController__deploymentSanityChecks_notOwner();
    error RentalsController__deploymentSanityChecks_noDelegationOwner();

    error RentalsController__listingSanityChecks_invalidDuration();
    error RentalsController__listingSanityChecks_invalidValue();

    error RentalsController__updateAssetListing_invalidOwnerChange();
    error RentalsController__updateAssetListing_notOwnedNft();
    error RentalsController__updateAssetListing_notListed();

    error RentalsController__rentSignature_notListed();
    error RentalsController__rentSignature_invalidDuration();
    error RentalsController__rentSignature_invalidEndDate();
    error RentalsController__rentSignature_wrongValue();

    error RentalsController__createSignatureListing_invalidOwner();

    error RentalsController__updateSignaturesListing_notListed();
    error RentalsController__updateSignaturesListing_invalidOwnerChange();

    error RentalsController__removeSignatureListing_invalidOwner();
    error RentalsController__removeAssetListing_invalidOwner();
    error RentalsController__removeAssetForSaleListing_invalidOwner();

    // ========== Modifiers ===========
    /**
     * @notice This modifier indicates that only the DelegationWalletFactory can execute a given function.
     */
    modifier onlyFactory() {
        if (_msgSender() != delegationWalletFactory) revert RentalsController__onlyFactory();
        _;
    }

    /**
     * @notice Sets the DelegationWalletFactory address.
     * @param _delegationWalletFactory - The DelegationWalletFactory address.
     */
    function setDelegationWalletFactory(address _delegationWalletFactory) external onlyOwner {
        delegationWalletFactory = _delegationWalletFactory;
    }

    /**
     * @notice Sets the DelegationOwner address for a given DelegationWallet.
     * @param _safeProxy - The DelegationWallet address, the GnosisSafe.
     * @param _delegationOwner - The DelegationOwner address.
     */
    function setOwnerBySafe(address _safeProxy, address _delegationOwner) external onlyFactory {
        ownerBySafe[_safeProxy] = DelegationOwner(_delegationOwner);
    }

    /**
     * @notice Creates an asset listing.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     * @param _listing - The listing parameters.
     */
    function createAssetListing(
        address _nft,
        uint256 _id,
        Listing calldata _listing
    ) external {
        if (_nft == address(0)) revert RentalsController__createAssetListing_invalidNft();
        if (_listing.owner != msg.sender) revert RentalsController__createAssetListing_invalidOwner();

        _listingSanityChecks(_listing);

        if (IERC721(_nft).ownerOf(_id) != _listing.safe) {
            IERC721(_nft).safeTransferFrom(_listing.owner, _listing.safe, _id);
        }

        assetListings[_nft][_id] = _listing;

        emit SaveAssetListing(
            _listing.safe,
            _nft,
            _id,
            msg.sender,
            _listing.minDuration,
            _listing.maxDuration,
            _listing.endDate,
            _listing.dailyValue
        );
    }

    /**
     * @notice Updates an asset listing.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     * @param _listing - The listing parameters.
     */
    function updateAssetListing(
        address _nft,
        uint256 _id,
        Listing calldata _listing
    ) external {
        Listing storage listing = assetListings[_nft][_id];
        if (listing.owner != msg.sender) revert RentalsController__updateAssetListing_notListed();
        if (listing.owner != _listing.owner) revert RentalsController__updateAssetListing_invalidOwnerChange();

        _listingSanityChecks(_listing);

        // allows to change the safe if it is the same owner and the asset was moved to that safe
        if (IERC721(_nft).ownerOf(_id) != _listing.safe) revert RentalsController__updateAssetListing_notOwnedNft();

        assetListings[_nft][_id] = _listing;

        emit SaveAssetListing(
            _listing.safe,
            _nft,
            _id,
            msg.sender,
            _listing.minDuration,
            _listing.maxDuration,
            _listing.endDate,
            _listing.dailyValue
        );
    }

    /**
     * @notice Removes an asset listing.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     */
    function removeAssetListing(address _nft, uint256 _id) external {
        Listing storage listing = assetListings[_nft][_id];
        if (listing.owner != msg.sender) revert RentalsController__removeAssetListing_invalidOwner();
        emit RemoveAssetListing(_nft, _id, listing.safe);

        delete assetListings[_nft][_id];
    }

    /**
     * @notice Creates a signature listing.
     * @param _listing - The listing parameters.
     * @param _assets - The asset address.
     * @param _assetIds - The asset id.
     */
    function createSignatureListing(
        Listing calldata _listing,
        address[] calldata _assets,
        uint256[] calldata _assetIds
    ) external {
        if (_listing.owner != msg.sender) revert RentalsController__createSignatureListing_invalidOwner();

        // assets ownership is checked when renting

        _listingSanityChecks(_listing);

        signatureListings[_listing.safe] = _listing;
        assetsBySignature[_listing.safe] = SignatureAssets(_assets, _assetIds);

        emit SaveSignatureListing(
            _listing.safe,
            _listing.owner,
            _listing.minDuration,
            _listing.maxDuration,
            _listing.endDate,
            _listing.dailyValue,
            _assets,
            _assetIds
        );
    }

    /**
     * @notice Updates a signature listing.
     * @param _listing - The listing parameters.
     * @param _assets - The asset address.
     * @param _assetIds - The asset id.
     */
    function updateSignaturesListing(
        Listing calldata _listing,
        address[] calldata _assets,
        uint256[] calldata _assetIds
    ) external {
        Listing storage listing = signatureListings[_listing.safe];
        if (listing.owner != msg.sender) revert RentalsController__updateSignaturesListing_notListed();
        if (listing.owner != _listing.owner) revert RentalsController__updateSignaturesListing_invalidOwnerChange();

        _listingSanityChecks(_listing);

        signatureListings[_listing.safe] = _listing;
        assetsBySignature[_listing.safe] = SignatureAssets(_assets, _assetIds);

        emit SaveSignatureListing(
            _listing.safe,
            _listing.owner,
            _listing.minDuration,
            _listing.maxDuration,
            _listing.endDate,
            _listing.dailyValue,
            _assets,
            _assetIds
        );
    }

    /**
     * @notice Removes a signature listing.
     * @param _safe - The DelegationWallet address, a GnosisSafe.
     */
    function removeSignatureListing(address _safe) external {
        Listing storage listing = signatureListings[_safe];
        if (listing.owner != msg.sender) revert RentalsController__removeSignatureListing_invalidOwner();

        emit RemoveSignatureListing(_safe);

        delete signatureListings[_safe];
    }

    /**
     * @notice List asset for sale.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     * @param _listing - The listing parameters.
     */
    function createAssetForSaleListing(
        address _nft,
        uint256 _id,
        SellAssetListing calldata _listing
    ) external {
        if (_nft == address(0)) revert RentalsController__createAssetForSaleListing_invalidNft();
        if (_listing.owner != msg.sender) revert RentalsController__createAssetForSaleListing_invalidOwner();

        _sellAssetListingSanityChecks(_listing);

        if (IERC721(_nft).ownerOf(_id) != _listing.safe) {
            IERC721(_nft).safeTransferFrom(_listing.owner, _listing.safe, _id);
        }

        sellAssetListings[_nft][_id] = SellAssetListing(
            _listing.safe,
            _listing.owner,
            _listing.daysForPayment,
            _listing.deposit,
            _listing.value
        );

        emit SaveAssetForSaleListing(
            _listing.safe,
            _nft,
            _id,
            msg.sender,
            _listing.daysForPayment,
            _listing.deposit,
            _listing.value
        );
    }

        /**
     * @notice Removes a asset for sale listing.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     */
    function removeAssetForSaleListing(address _nft, uint256 _id) external {
        SellAssetListing storage listing = sellAssetListings[_nft][_id];
        if (listing.owner != msg.sender) revert RentalsController__removeAssetForSaleListing_invalidOwner();
        emit RemoveAssetForSaleListing(_nft, _id, listing.safe);

        delete sellAssetListings[_nft][_id];
    }

    /**
     * @notice Rents an asset with current listing parameters.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     * @param _days - The number of days to rent the asset.
     */
    function rentAsset(
        address _nft,
        uint256 _id,
        uint256 _days
    ) external payable {
        Listing storage listing = assetListings[_nft][_id];
        if (listing.safe == address(0)) revert RentalsController__rentAsset_notListed();
        if (IERC721(_nft).ownerOf(_id) != listing.safe) revert RentalsController__rentAsset_notOwnedNft();
        if (_days < listing.minDuration || _days > listing.maxDuration)
            revert RentalsController__rentAsset_invalidDuration();

        uint256 duration = _days * 1 days;
        uint256 endDate = block.timestamp + duration;
        if (listing.endDate > 0 && endDate > listing.endDate) revert RentalsController__rentAsset_invalidEndDate();

        uint256 value = listing.dailyValue * _days;
        if (msg.value != value) revert RentalsController__rentAsset_wrongValue();
        // TODO - fee
        Address.sendValue(payable(listing.owner), value);

        _rentAsset(listing.safe, _nft, _id, duration, value, listing.owner, endDate);

        emit AssetRented(listing.safe, _nft, _id, duration, value, msg.sender);
    }

    /**
     * @notice Rents a signature with current listing parameters.
     * @param _safe - The DelegationWallet address, a GnosisSafe.
     * @param _days - The number of days to rent the asset.
     */
    function rentSignature(address _safe, uint256 _days) external payable {
        Listing storage listing = signatureListings[_safe];
        if (listing.safe == address(0)) revert RentalsController__rentSignature_notListed();
        if (_days < listing.minDuration || _days > listing.maxDuration)
            revert RentalsController__rentSignature_invalidDuration();

        uint256 duration = _days * 1 days;
        uint256 endDate = block.timestamp + duration;
        if (listing.endDate > 0 && endDate > listing.endDate) revert RentalsController__rentSignature_invalidEndDate();

        uint256 value = listing.dailyValue * _days;
        if (msg.value != value) revert RentalsController__rentSignature_wrongValue();
        Address.sendValue(payable(listing.owner), value);

        _rentSignature(
            listing.safe,
            assetsBySignature[_safe].assets,
            assetsBySignature[_safe].assetIds,
            duration,
            value,
            listing.owner,
            endDate
        );

        SignatureAssets storage assets = assetsBySignature[listing.safe];

        emit SignatureRented(
            listing.safe,
            duration,
            value,
            msg.sender,
            assets.assets,
            assets.assetIds
        );
    }

    /**
     * @notice Gets the assets listed for a signature listing.
     * @param _safe - The DelegationWallet address, a GnosisSafe.
     */
    function getAssetsBySignature(address _safe) external view returns (SignatureAssets memory) {
        return assetsBySignature[_safe];
    }

    /**
     * @notice Buy an asset by first making a deposit and paying the asset in the future.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     */
    function buyAsset(address _nft, uint256 _id) external payable {
        SellAssetListing storage listing = sellAssetListings[_nft][_id];
        SellAsset storage sellAssetInfo = sellAssets[_nft][_id];
        DelegationOwner delegationOwner = ownerBySafe[listing.safe];

        if (listing.safe == address(0)) revert RentalsController__buyAsset_notListed();
        if (sellAssetInfo.safe != address(0)) revert RentalsController__buyAsset_alreadySold();
        if (address(delegationOwner) == address(0))
            revert RentalsController__buyAsset_noDelegationOwner();
        if (IERC721(_nft).ownerOf(_id) != listing.safe) revert RentalsController__buyAsset_notOwnedNft();
        if (msg.value != listing.deposit) revert RentalsController__buyAsset_wrongDepositValue();

        if (delegationOwner.isAssetLocked(_nft, _id)) revert RentalsController__buyAsset_isLocked();
        if (delegationOwner.isAssetDelegated(_nft, _id)) revert RentalsController__buyAsset_isDelegated();
        if (delegationOwner.isSignatureDelegated()) revert RentalsController__buyAsset_isSignatureDelegated();

        uint256 duration = listing.daysForPayment * 1 days;
        uint256 dueDate = block.timestamp + duration;
        sellAssets[_nft][_id] = SellAsset(listing.safe, listing.owner, msg.sender, dueDate, listing.value);

        // TODO - fee
        Address.sendValue(payable(listing.owner), msg.value);

        address[] memory asset = new address[](1);
        asset[0] = _nft;
        uint256[] memory id = new uint256[](1);
        id[0] = _id;
        // instead of value 0, we can use deposit. As if the user does not pay on term, the deposit wont be refund
        _rentSignature(listing.safe, asset, id, duration, listing.deposit, listing.owner, dueDate);
        _rentAsset(listing.safe, _nft, _id, duration, listing.deposit, listing.owner, dueDate);

        emit AssetBought(_nft, _id, listing.safe, listing.owner, msg.sender, listing.deposit, listing.value);
    }

    /**
     * @notice Pay for the asset if dueDate has not been reached.
     * @param _nft - The asset address.
     * @param _id - The asset id.
     */
    function payAsset(address _nft, uint256 _id) external payable {
        SellAsset storage sellAssetInfo = sellAssets[_nft][_id];
        DelegationOwner delegationOwner = ownerBySafe[sellAssetInfo.safe];

        if (sellAssetInfo.safe == address(0)) revert RentalsController__payAsset_notListed();
        if (address(delegationOwner) == address(0))
            revert RentalsController__payAsset_noDelegationOwner();
        if (block.timestamp > sellAssetInfo.dueDate) revert RentalsController__payAsset_paydayHasPassed();
        if (msg.value != sellAssetInfo.valueToPay) revert RentalsController__payAsset_wrongPaymentValue();

        // TODO - fee
        Address.sendValue(payable(sellAssetInfo.owner), msg.value);

        delegationOwner.transferAsset(_nft, _id, sellAssetInfo.buyer);

        emit AssetPaid(_nft, _id, sellAssetInfo.safe, sellAssetInfo.owner, msg.sender, sellAssetInfo.valueToPay);

        _processAfterPayment(sellAssetInfo.safe, _nft, _id);
    }

    /**
     * @notice Returns if an asset is in a buy operation
     * @param _nft - The asset address.
     * @param _id - The asset id.
     */
    function isSellActive(address _nft, uint256 _id) external view returns (bool) {
        SellAsset storage sellAssetInfo = sellAssets[_nft][_id];
        if (sellAssetInfo.dueDate > block.timestamp) return true;
        return false;
    }

    /**
     * @notice Delegate signature and register the rental.
     * @param _safe - The safe.
     * @param _duration - The amount of time the signature will be rented.
     * @param _value - The value paid to rent the signature.
     * @param _owner - The owner of the deployment.
     * @param _endDate - The date when the rental ends.
     */
    function _rentSignature(
        address _safe,
        address[] memory _assets,
        uint256[] memory _assetIds,
        uint256 _duration,
        uint256 _value,
        address _owner,
        uint256 _endDate
    ) internal {
        ownerBySafe[_safe].delegateSignature(
            _assets,
            _assetIds,
            msg.sender,
            _duration
        );

        Rental memory newRental = Rental(_safe, _owner, msg.sender, block.timestamp, _endDate, _value);
        signatureRentals[_safe] = newRental;
    }

    /**
     * @notice Delegate asset and register the rental.
     * @param _safe - The safe.
     * @param _nft - The address of the collection.
     * @param _id - The asset if of the collection.
     * @param _duration - The duration of the rent
     * @param _value - The value paid to rent the signature.
     * @param _owner - The owner of the deployment.
     * @param _endDate - The date when the rental ends.
     */
    function _rentAsset(
        address _safe,
        address _nft,
        uint256 _id,
        uint256 _duration,
        uint256 _value,
        address _owner,
        uint256 _endDate
    ) internal {
        ownerBySafe[_safe].delegate(_nft, _id, msg.sender, _duration);

        Rental storage newRental = assetRentals[_nft][_id];
        newRental.renter = msg.sender;
        newRental.from = block.timestamp;
        newRental.to = _endDate;
        newRental.value = _value;
        newRental.owner = _owner;
        newRental.safe = _safe;
    }

    function _processAfterPayment(address _safe, address _nft, uint256 _id) internal {
        address[] memory asset = new address[](1);
        asset[0] = _nft;
        uint256[] memory id = new uint256[](1);
        id[0] = _id;
        ownerBySafe[_safe].endDelegateSignature(asset, id);
        ownerBySafe[_safe].endDelegate(_nft, _id);

        signatureRentals[_safe].to = block.timestamp;
        assetRentals[_nft][_id].to = block.timestamp;

        delete sellAssetListings[_nft][_id];
        delete sellAssets[_nft][_id];
        delete assetListings[_nft][_id];

        uint256 length = assetsBySignature[_safe].assetIds.length;
        if (length > 0) {
            uint256 lastIndex = length - 1;
            for (uint256 j; j < length; ) {
                if (assetsBySignature[_safe].assetIds[j] == _id && assetsBySignature[_safe].assets[j] == _nft) {
                    if (j != lastIndex) {
                        assetsBySignature[_safe].assetIds[j] = assetsBySignature[_safe].assetIds[lastIndex];
                        assetsBySignature[_safe].assets[j] = assetsBySignature[_safe].assets[lastIndex];
                    }
                    assetsBySignature[_safe].assetIds.pop();
                    assetsBySignature[_safe].assets.pop();
                    break;
                }
                unchecked {
                    ++j;
                }
            }
        }
    }

    /**
     * @notice Validates valid deployment.
     * @param _safe - The safe.
     */
    function _deploymentSanityChecks(address _safe) internal view {
        if (_safe == address(0)) revert RentalsController__deploymentSanityChecks_invalidSafe();
        if (!GnosisSafe(payable(_safe)).isOwner(msg.sender))
            revert RentalsController__deploymentSanityChecks_notOwner();
        DelegationOwner delegationOwner = ownerBySafe[_safe];
        if (address(delegationOwner) == address(0))
            revert RentalsController__deploymentSanityChecks_noDelegationOwner();
    }

    /**
     * @notice Validates a listing parameters.
     * @param _listing - The listing.
     */
    function _listingSanityChecks(Listing calldata _listing) internal view {
        if (_listing.maxDuration == 0 || _listing.maxDuration < _listing.minDuration)
            revert RentalsController__listingSanityChecks_invalidDuration();
        if (_listing.dailyValue == 0) revert RentalsController__listingSanityChecks_invalidValue();
        _deploymentSanityChecks(_listing.safe);
    }

    /**
     * @notice Validates a sell listing parameters.
     * @param _listing - The listing.
     */
    function _sellAssetListingSanityChecks(SellAssetListing calldata _listing) internal view {
        if (_listing.daysForPayment == 0) revert RentalsController__createAssetForSaleListing_invalidDaysForPayment();
        if (_listing.deposit == 0) revert RentalsController__createAssetForSaleListing_invalidDeposit();
        if (_listing.value == 0) revert RentalsController__createAssetForSaleListing_invalidValue();
        _deploymentSanityChecks(_listing.safe);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { IGnosisSafe } from "./interfaces/IGnosisSafe.sol";
import { DelegationGuard } from "./DelegationGuard.sol";
import { DelegationRecipes } from "./DelegationRecipes.sol";
import { RentalsController } from "./RentalsController.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { ISignatureValidator } from "@gnosis.pm/safe-contracts/contracts/interfaces/ISignatureValidator.sol";
import { GnosisSafe } from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

// import "forge-std/console2.sol";

/**
 * @title DelegationOwner
 * @author BootNode
 * @dev This contract contains the logic that enables asset/signature delegates to interact with a Gnosis Safe wallet.
 * In the case of assets delegates, it will allow them to execute functions though the Safe, only those registered
 * as allowed on the DelegationRecipes contract.
 * In the case of signatures it validates that a signature was made by the current delegatee.
 * It is also used by the delegation controller to set delegations and the lock controller to lock, unlock and claim
 * assets.
 *
 * It should be use a proxy's implementation.
 */
contract DelegationOwner is ISignatureValidator, Initializable {
    bytes32 public constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /**
     * @notice Delegation information, it used for Assets and signatures.
     *
     * @param delegatee - The delegatee address.
     * @param from - The date (seconds timestamp) when the delegation starts.
     * @param to - The date (seconds timestamp) when the delegation ends.
     */
    struct Delegation {
        address delegatee;
        uint256 from;
        uint256 to;
    }

    /**
     * @notice Safe wallet address.
     */
    address public safe;
    /**
     * @notice The owner of the DelegationWallet - TODO do we need this.
     */
    address public owner;
    /**
     * @notice The delegation controller address. Allowed to execute delegation related functions.
     */
    RentalsController public delegationController;
    /**
     * @notice The lock controller address. Allowed to execute asset locking related functions.
     */
    address public lockController;
    /**
     * @notice The DelegationGuard address.
     */
    DelegationGuard public guard;
    /**
     * @notice The DelegationRecipes address.
     */
    DelegationRecipes public recipes;

    bool internal isExecuting;
    bytes32 internal currentTxHash;

    /**
     * @notice Stores the list of asset delegations. keccak256(address, nft id) => Rent
     */
    mapping(bytes32 => Delegation) public delegations;

    /**
     * @notice Stores the current signature delegation.
     */
    Delegation public signatureDelegation;

    // ========== Events ===========
    event NewDelegation(
        address indexed asset,
        uint256 indexed assetId,
        uint256 from,
        uint256 to,
        address indexed delegatee
    );
    event EndDelegation(address indexed asset,uint256 indexed assetId);
    event DelegatedSignature(uint256 from, uint256 to, address indexed delegatee, address[] assets, uint256[] assetIds);
    event EndDelegatedSignature(address[] assets, uint256[] assetIds);
    event LockedAsset(address indexed asset, uint256 indexed assetId);
    event UnlockedAsset(address indexed asset, uint256 indexed assetId);
    event ClaimedAsset(address indexed asset, uint256 indexed assetId, address indexed receiver);
    event TransferredAsset(address indexed asset, uint256 indexed assetId, address indexed receiver);

    // ========== Custom Errors ===========
    error DelegationOwner__onlyOwner();
    error DelegationOwner__onlyDelegationController();
    error DelegationOwner__onlyLockController();
    error DelegationOwner__onlyFactory();
    error DelegationOwner__configuredGuard();
    error DelegationOwner__delegate_assetNotOwned();
    error DelegationOwner__delegate_assetApproved();
    error DelegationOwner__delegate_currentlyDelegated();
    error DelegationOwner__delegate_invalidDelegatee();
    error DelegationOwner__delegate_invalidDuration();
    error DelegationOwner__delegate_arityMismatch();
    error DelegationOwner__endDelegate_notDelegated();
    error DelegationOwner__isValidSignature_notDelegated();
    error DelegationOwner__isValidSignature_invalidSigner();
    error DelegationOwner__isValidSignature_noSignatureAllowed();
    error DelegationOwner__isValidSignature_invalidExecSig();
    error DelegationOwner__execTransaction_notDelegated();
    error DelegationOwner__execTransaction_invalidDelegatee();
    error DelegationOwner__execTransaction_notAllowedFunction();
    error DelegationOwner__execTransaction_notSuccess();
    error DelegationOwner__lockAsset_assetNotOwned();
    error DelegationOwner__transferAsset_assetNotOwned();
    error DelegationOwner__transferAsset_notSuccess();
    error DelegationOwner__lockAsset_assetApproved();
    error DelegationOwner__lockAsset_assetIsBeingSold();
    error DelegationOwner__unlockAsset_assetNotOwned();
    error DelegationOwner__claimAsset_assetNotOwned();
    error DelegationOwner__claimAsset_assetNotLocked();
    error DelegationOwner__claimAsset_notSuccess();
    error DelegationOwner__delegateSignature_assetNotOwned();
    error DelegationOwner__delegateSignature_assetApproved();
    error DelegationOwner__delegateSignature_currentlyDelegated();
    error DelegationOwner__delegateSignature_invalidDelegatee();
    error DelegationOwner__delegateSignature_invalidDuration();
    error DelegationOwner__endDelegateSignature_notDelegated();
    error DelegationOwner__checkGuardConfigured_noGuard();

    /**
     * @notice This modifier indicates that only the Delegation Controller can execute a given function.
     */
    modifier onlyDelegationController() {
        if (address(delegationController) != msg.sender) revert DelegationOwner__onlyDelegationController();
        _;
    }

    /**
     * @notice This modifier indicates that only the Lock Controller can execute a given function.
     */
    modifier onlyLockController() {
        if (lockController != msg.sender) revert DelegationOwner__onlyLockController();
        _;
    }

    /**
     * @dev Disables the initializer in order to prevent implementation initialization.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the proxy state.
     * @param _guardBeacon - The address of the beacon where the proxy gets the implementation address.
     * @param _recipes - The DelegationRecipes address.
     * @param _safe - The DelegationWallet address, the GnosisSafe.
     * @param _owner - The owner of the DelegationWallet.
     * @param _delegationController - The address that acts as the delegation controller.
     * @param _lockController - The address that acts as the lock controller.
     */
    function initialize(
        address _guardBeacon,
        address _recipes,
        address _safe,
        address _owner,
        address _delegationController,
        address _lockController
    ) public initializer {
        // TODO - validate addresses
        safe = _safe;
        owner = _owner;
        delegationController = RentalsController(_delegationController);
        lockController = _lockController;
        recipes = DelegationRecipes(_recipes);

        address guardProxy = address(
            new BeaconProxy(_guardBeacon, abi.encodeWithSelector(DelegationGuard.initialize.selector, address(this)))
        );
        guard = DelegationGuard(guardProxy);

        _setupGuard(_safe, guard);
    }

    /**
     * @notice Delegates the usage of an asset to the `_delegatee` for a `_duration` of time.
     * @param _asset - The asset address.
     * @param _assetId - The asset id.
     * @param _delegatee - The delegatee address.
     * @param _duration - The duration of the delegation expressed in seconds.
     */
    function delegate(
        address _asset,
        uint256 _assetId,
        address _delegatee,
        uint256 _duration
    ) external onlyDelegationController {
        _checkGuardConfigured();
        // safe should be owner
        if (IERC721(_asset).ownerOf(_assetId) != safe) revert DelegationOwner__delegate_assetNotOwned();
        if (IERC721(_asset).getApproved(_assetId) != address(0)) revert DelegationOwner__delegate_assetApproved();
        // TODO - it could also be approved for all

        Delegation storage delegation = delegations[delegationId(_asset, _assetId)];

        if (_isDelegating(delegation)) revert DelegationOwner__delegate_currentlyDelegated();
        if (_delegatee == address(0)) revert DelegationOwner__delegate_invalidDelegatee();
        if (_duration == 0) revert DelegationOwner__delegate_invalidDuration();

        delegation.delegatee = _delegatee;
        uint256 from = block.timestamp;
        uint256 to = block.timestamp + _duration;
        delegation.from = from;
        delegation.to = to;

        emit NewDelegation(_asset, _assetId, from, to, _delegatee);

        guard.setDelegatedAsset(_asset, _assetId, to);
    }

    /**
     * @notice Ends asset usage delegation.
     * @param _asset - The asset address.
     * @param _assetId - The asset id.
     */
    function endDelegate(
        address _asset,
        uint256 _assetId
    ) external onlyDelegationController {
        _checkGuardConfigured();

        Delegation storage delegation = delegations[delegationId(_asset, _assetId)];

        if (!_isDelegating(delegation)) revert DelegationOwner__endDelegate_notDelegated();

        delegation.to = block.timestamp;

        emit EndDelegation(_asset, _assetId);

        guard.setDelegatedAsset(_asset, _assetId, block.timestamp);
    }

    /**
     * @notice Delegates the usage of the signature to the `_delegatee` for a `_duration` of time. Locking a group of
     * assets in the wallet.
     * @param _assets - The asset addresses.
     * @param _assetIds - The asset ids.
     * @param _delegatee - The delegatee address.
     * @param _duration - The duration of the delegation expressed in seconds.
     */
    function delegateSignature(
        address[] calldata _assets,
        uint256[] calldata _assetIds,
        address _delegatee,
        uint256 _duration
    ) external onlyDelegationController {
        _checkGuardConfigured();
        // TODO - check arity
        if (_isDelegating(signatureDelegation)) revert DelegationOwner__delegateSignature_currentlyDelegated();
        if (_delegatee == address(0)) revert DelegationOwner__delegateSignature_invalidDelegatee();
        if (_duration == 0) revert DelegationOwner__delegateSignature_invalidDuration();

        for (uint256 j; j < _assets.length; ) {
            if (IERC721(_assets[j]).ownerOf(_assetIds[j]) != safe)
                revert DelegationOwner__delegateSignature_assetNotOwned();
            if (IERC721(_assets[j]).getApproved(_assetIds[j]) != address(0))
                revert DelegationOwner__delegateSignature_assetApproved();
            unchecked {
                ++j;
            }
        }

        Delegation memory newDelegation = Delegation(_delegatee, block.timestamp, block.timestamp + _duration);

        signatureDelegation = newDelegation;

        emit DelegatedSignature(newDelegation.from, newDelegation.to, _delegatee, _assets, _assetIds);

        guard.setSignatureExpiry(_assets, _assetIds, newDelegation.to);
    }

    /**
     * @notice Ends the delegation of the usage of the signature to the `_delegatee`. Unlocking a group of assets.
     * @param _assets - The asset addresses.
     * @param _assetIds - The asset ids.
     */
    function endDelegateSignature(
        address[] calldata _assets,
        uint256[] calldata _assetIds
    ) external onlyDelegationController {
        _checkGuardConfigured();
        // TODO - check arity
        if (!_isDelegating(signatureDelegation)) revert DelegationOwner__endDelegateSignature_notDelegated();

        signatureDelegation.to = block.timestamp;

        emit EndDelegatedSignature(_assets, _assetIds);

        guard.setSignatureExpiry(_assets, _assetIds, block.timestamp);
    }

    /**
     * @notice Execute a transaction through the GnosisSafe wallet.
     * The sender should be the delegatee of the given asset and the function should be allowed for the collection.
     */
    function execTransaction(
        address _asset,
        uint256 _assetId,
        address _to,
        uint256 _value,
        bytes calldata _data,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address payable _refundReceiver
    ) external returns (bool success) {
        Delegation storage delegation = delegations[delegationId(_asset, _assetId)];
        if (!_isDelegating(delegation)) revert DelegationOwner__execTransaction_notDelegated();
        if (delegation.delegatee != msg.sender) revert DelegationOwner__execTransaction_invalidDelegatee();
        if (!isAllowedFunction(_asset, _to, _getSelector(_data)))
            revert DelegationOwner__execTransaction_notAllowedFunction();

        isExecuting = true;
        currentTxHash = IGnosisSafe(payable(safe)).getTransactionHash(
            // Transaction info
            _to,
            _value,
            _data,
            Enum.Operation.Call,
            _safeTxGas,
            // Payment info
            _baseGas,
            _gasPrice,
            _gasToken,
            _refundReceiver,
            // Signature info
            IGnosisSafe(payable(safe)).nonce()
        );

        // https://docs.gnosis-safe.io/contracts/signatures#contract-signature-eip-1271
        bytes memory signature = abi.encodePacked(
            abi.encode(address(this)), // r
            abi.encode(uint256(65)), // s
            bytes1(0), // v
            abi.encode(currentTxHash.length),
            currentTxHash
        );

        (success) = IGnosisSafe(safe).execTransaction(
            _to,
            _value,
            _data,
            Enum.Operation.Call,
            _safeTxGas,
            _baseGas,
            _gasPrice,
            _gasToken,
            _refundReceiver,
            signature
        );

        isExecuting = false;
        currentTxHash = bytes32(0);

        if (!success) revert DelegationOwner__execTransaction_notSuccess();
    }

    /**
     * @notice Validates that the signer is the current signature delegatee, or a valid transaction executed by a asset
     * delegatee.
     */
    function isValidSignature(bytes calldata _data, bytes calldata _signature) public view override returns (bytes4) {
        if (!isExecuting) {
            address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_data), _signature);
            if (!_isDelegating(signatureDelegation)) revert DelegationOwner__isValidSignature_notDelegated();
            if (signatureDelegation.delegatee != signer) revert DelegationOwner__isValidSignature_invalidSigner();
        } else {
            bytes32 txHash = abi.decode(_signature, (bytes32));
            if (txHash != currentTxHash) revert DelegationOwner__isValidSignature_invalidExecSig();
        }

        return EIP1271_MAGIC_VALUE;
    }

    /**
     * @notice Checks that a function is allowed to be executed by a delegatee of a given asset.
     */
    function isAllowedFunction(
        address _asset,
        address _contract,
        bytes4 _selector
    ) public view returns (bool) {
        return recipes.isAllowedFunction(_asset, _contract, _selector);
    }

    /**
     * @notice Sets an asset as locked.
     */
    function lockAsset(address _asset, uint256 _assetId) external onlyLockController {
        // safe should be owner
        if (IERC721(_asset).ownerOf(_assetId) != safe) revert DelegationOwner__lockAsset_assetNotOwned();
        // should not be approved for someone else
        if (IERC721(_asset).getApproved(_assetId) != address(0)) revert DelegationOwner__lockAsset_assetApproved();
        // should not be being sold
        if (delegationController.isSellActive(_asset, _assetId)) revert DelegationOwner__lockAsset_assetIsBeingSold();

        emit LockedAsset(_asset, _assetId);

        guard.lockAsset(_asset, _assetId);
    }

    /**
     * @notice Transfer an asset owned by the safe.
     */
    function transferAsset(
        address _asset,
        uint256 _assetId,
        address _receiver
    ) external onlyDelegationController {
        bool success = _transferAsset(_asset, _assetId, _receiver);

        if (!success) revert DelegationOwner__transferAsset_notSuccess();

        emit TransferredAsset(_asset, _assetId, _receiver);
    }

    /**
     * @notice Returns if an asset is locked.
     */
    function isAssetLocked(address _asset, uint256 _assetId) external view returns (bool) {
        return guard.isLocked(_asset, _assetId);
    }

    /**
     * @notice Returns if an asset is delegated.
     */
    function isAssetDelegated(address _asset, uint256 _assetId) external view returns (bool) {
        return _isDelegating(delegations[delegationId(_asset, _assetId)]);
    }

    /**
     * @notice Returns if the signature is delegated.
     */
    function isSignatureDelegated() external view returns (bool) {
        return _isDelegating(signatureDelegation);
    }

    /**
     * @notice Sets an asset as unlocked.
     */
    function unlockAsset(address _asset, uint256 _assetId) external onlyLockController {
        // safe should be owner
        if (IERC721(_asset).ownerOf(_assetId) != safe) revert DelegationOwner__unlockAsset_assetNotOwned();

        emit UnlockedAsset(_asset, _assetId);

        guard.unlockAsset(_asset, _assetId);
    }

    /**
     * @notice Sends a locked asset to the `receiver`.
     */
    function claimAsset(
        address _asset,
        uint256 _assetId,
        address _receiver
    ) external onlyLockController {
        if (!guard.isLocked(_asset, _assetId)) revert DelegationOwner__claimAsset_assetNotLocked();

        guard.unlockAsset(_asset, _assetId);

        bool success = _transferAsset(_asset, _assetId, _receiver);

        if (!success) revert DelegationOwner__claimAsset_notSuccess();

        emit ClaimedAsset(_asset, _assetId, _receiver);
    }

    function delegationId(address _asset, uint256 _assetId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_asset, _assetId));
    }

    function _getSelector(bytes memory _data) internal pure returns (bytes4 selector) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            selector := mload(add(_data, 32))
        }
    }

    function _isDelegating(Delegation storage _delegation) internal view returns (bool) {
        return (_delegation.from <= block.timestamp && block.timestamp <= _delegation.to);
    }

    function _getAllowedFunctionsKey(Delegation storage _delegation) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_delegation.delegatee, _delegation.from, _delegation.to));
    }

    function _checkGuardConfigured() internal view {
        bytes memory storageAt = GnosisSafe(payable(safe)).getStorageAt(uint256(GUARD_STORAGE_SLOT), 1);
        address configuredGuard = abi.decode(storageAt, (address));
        if (configuredGuard != address(guard)) revert DelegationOwner__checkGuardConfigured_noGuard();
    }

    function _setupGuard(address _safe, DelegationGuard _guard) internal {
        // this requires this address to be a owner of the safe already
        isExecuting = true;
        bytes memory payload = abi.encodeWithSelector(IGnosisSafe.setGuard.selector, _guard);
        currentTxHash = IGnosisSafe(payable(_safe)).getTransactionHash(
            // Transaction info
            safe,
            0,
            payload,
            Enum.Operation.Call,
            0,
            // Payment info
            0,
            0,
            address(0),
            payable(0),
            // Signature info
            IGnosisSafe(payable(_safe)).nonce()
        );

        // https://docs.gnosis-safe.io/contracts/signatures#contract-signature-eip-1271
        bytes memory signature = abi.encodePacked(
            abi.encode(address(this)), // r
            abi.encode(uint256(65)), // s
            bytes1(0), // v
            abi.encode(currentTxHash.length),
            currentTxHash
        );

        IGnosisSafe(_safe).execTransaction(
            safe,
            0,
            payload,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(0),
            signature
        );

        isExecuting = false;
        currentTxHash = bytes32(0);
    }

    /**
     * @notice Transfer an asset owned by the safe.
     */
    function _transferAsset(
        address _asset,
        uint256 _assetId,
        address _receiver
    ) internal returns (bool) {
        // safe should be owner
        if (IERC721(_asset).ownerOf(_assetId) != safe) revert DelegationOwner__transferAsset_assetNotOwned();

        bytes memory payload = abi.encodeWithSelector(IERC721.transferFrom.selector, safe, _receiver, _assetId);

        isExecuting = true;
        currentTxHash = IGnosisSafe(payable(safe)).getTransactionHash(
            _asset,
            0,
            payload,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(0),
            IGnosisSafe(payable(safe)).nonce()
        );

        // https://docs.gnosis-safe.io/contracts/signatures#contract-signature-eip-1271
        bytes memory signature = abi.encodePacked(
            abi.encode(address(this)), // r
            abi.encode(uint256(65)), // s
            bytes1(0), // v
            abi.encode(currentTxHash.length),
            currentTxHash
        );

        bool success = IGnosisSafe(safe).execTransaction(
            _asset,
            0,
            payload,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(0),
            signature
        );

        isExecuting = false;
        currentTxHash = bytes32(0);

        return success;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./GnosisSafeProxy.sol";
import "./IProxyCreationCallback.sol";

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <[email protected]>
contract GnosisSafeProxyFactory {
    event ProxyCreation(GnosisSafeProxy proxy, address singleton);

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param singleton Address of singleton contract.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address singleton, bytes memory data) public returns (GnosisSafeProxy proxy) {
        proxy = new GnosisSafeProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, singleton);
    }

    /// @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).runtimeCode;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).creationCode;
    }

    /// @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
    ///      This method is only meant as an utility to be called from other methods
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function deployProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) internal returns (GnosisSafeProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(GnosisSafeProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        if (initializer.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, _singleton);
    }

    /// @dev Allows to create new proxy contact, execute a message call to the new proxy and call a specified callback within one transaction
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// @param callback Callback that will be invoced after the new proxy contract has been successfully deployed and initialized.
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (GnosisSafeProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }

    /// @dev Allows to get the address for a new proxy contact created via `createProxyWithNonce`
    ///      This method is only meant for address calculation purpose when you use an initializer that would revert,
    ///      therefore the response is returned with a revert. When calling this method set `from` to the address of the proxy factory.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function calculateCreateProxyWithNonceAddress(
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        revert(string(abi.encodePacked(proxy)));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./base/FallbackManager.sol";
import "./base/GuardManager.sol";
import "./common/EtherPaymentFallback.sol";
import "./common/Singleton.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./common/StorageAccessible.sol";
import "./interfaces/ISignatureValidator.sol";
import "./external/GnosisSafeMath.sol";

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafe is
    EtherPaymentFallback,
    Singleton,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    ISignatureValidatorConstants,
    FallbackManager,
    StorageAccessible,
    GuardManager
{
    using GnosisSafeMath for uint256;

    string public constant VERSION = "1.3.0";

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);

    uint256 public nonce;
    bytes32 private _deprecatedDomainSeparator;
    // Mapping to keep track of all message hashes that have been approve by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approve by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    // This constructor ensures that this contract can only be used as a master copy for Proxy contracts
    constructor() {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Safe with 0 owners and threshold 1.
        // This is an unusable Safe, perfect for the singleton
        threshold = 1;
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Adddress that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // setupOwners checks if the Threshold is already set, therefore preventing that this method is called twice
        setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
        // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
        setupModules(to, data);

        if (payment > 0) {
            // To avoid running into issues with EIP-170 we reuse the handlePayment function (to avoid adjusting code of that has been verified we do not adjust the method itself)
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
        emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
    }

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transferred, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData =
                encodeTransactionData(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    nonce
                );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }
        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        require(gasleft() >= ((safeTxGas * 64) / 63).max(safeTxGas + 2500) + 500, "GS010");
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            uint256 gasUsed = gasleft();
            // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
            // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
            success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
            // If no safeTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
            // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
            require(success || safeTxGas != 0 || gasPrice != 0, "GS013");
            // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            require(receiver.send(payment), "GS011");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "GS012");
        }
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures.mul(65), "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s).add(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            lastOwner = currentOwner;
        }
    }

    /// @dev Allows to estimate a Safe transaction.
    ///      This method is only meant for estimation purpose, therefore the call will always revert and encode the result in the revert data.
    ///      Since the `estimateGas` function includes refunds, call this method to get an estimated of the costs that are deducted from the safe with `execTransaction`
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @return Estimate without refunds and overhead fees (base transaction and payload data gas costs).
    /// @notice Deprecated in favor of common/StorageAccessible.sol and will be removed in next version.
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }

    /**
     * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
     * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
     */
    function approveHash(bytes32 hashToApprove) external {
        require(owners[msg.sender] != address(0), "GS030");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Gas that should be used for the safe transaction.
    /// @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    SAFE_TX_TYPEHASH,
                    to,
                    value,
                    keccak256(data),
                    operation,
                    safeTxGas,
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    _nonce
                )
            );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    /// @dev Returns hash to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Fas that should be used for the safe transaction.
    /// @param baseGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGnosisSafe {
    function nonce() external view returns (uint256);

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transferred, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function isModuleEnabled(address module) external view returns (bool);

    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4);

    function signedMessages(bytes32 message) external view returns (uint256);

    function getMessageHash(bytes memory message) external view returns (bytes32);

    function domainSeparator() external view returns (bytes32);

    function enableModule(address module) external;

    function setGuard(address guard) external;

    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// TODO - use BaseGuard (but it is not in npm package)
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { IERC165 } from "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import { Guard } from "@gnosis.pm/safe-contracts/contracts/base/GuardManager.sol";
import { OwnerManager, GuardManager, GnosisSafe } from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { DelegationOwner } from "./DelegationOwner.sol";

/**
 * @title DelegationOwner
 * @author BootNode
 * @dev This contract protects a DelegationWallet.
 * - Prevents delegated o locked assets from being transferred.
 * - Prevents the approval of delegated or locked assets.
 * - Prevents all approveForAll
 * - Prevents change in the configuration of the DelegationWallet
 * - Prevents the remotion a this contract as the Guard of the DelegationWallet
 */
contract DelegationGuard is Guard, Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes4 internal constant ERC721_SAFE_TRANSFER_FROM =
        bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256)")));
    bytes4 internal constant ERC721_SAFE_TRANSFER_FROM_DATA =
        bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256,bytes)")));

    address internal delegationOwner;

    // nft address => true/false
    mapping(address => bool) internal checkAsset;

    // keccak256(address, nft id) => expiry
    mapping(bytes32 => uint256) internal delegationExpiries;
    uint256 internal lastExpiry;

    // keccak256(address, nft id)
    EnumerableSet.Bytes32Set internal lockedAssets;

    // keccak256(address, nft id) => expiry
    mapping(bytes32 => uint256) internal signatureExpiries;

    // ========== Custom Errors ===========
    error DelegationGuard__onlyDelegationOwner();
    error DelegationGuard__checkLocked_noTransfer();
    error DelegationGuard__checkLocked_noApproval();
    error DelegationGuard__checkApproveForAll_noApprovalForAll();
    error DelegationGuard__checkConfiguration_ownershipChangesNotAllowed();
    error DelegationGuard__checkConfiguration_guardChangeNotAllowed();

    modifier onlyDelegationOwner() {
        if (delegationOwner != msg.sender) revert DelegationGuard__onlyDelegationOwner();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _delegationOwner) public initializer {
        delegationOwner = _delegationOwner;
    }

    function setSignatureExpiry(
        address[] calldata _assets,
        uint256[] calldata _assetIds,
        uint256 _expiry
    ) external onlyDelegationOwner {
        for (uint256 j; j < _assets.length; ) {
            checkAsset[_assets[j]] = true;
            signatureExpiries[_delegationId(_assets[j], _assetIds[j])] = _expiry;
            unchecked {
                ++j;
            }
        }

        if (_expiry > lastExpiry) {
            lastExpiry = _expiry;
        }
    }

    function setDelegatedAsset(
        address _asset,
        uint256 _id,
        uint256 _to
    ) external onlyDelegationOwner {
        checkAsset[_asset] = true;
        delegationExpiries[_delegationId(_asset, _id)] = _to;

        if (_to > lastExpiry) {
            lastExpiry = _to;
        }
    }

    function lockAsset(address _asset, uint256 _id) external onlyDelegationOwner {
        _setLockedAsset(_asset, _id, true);
    }

    function unlockAsset(address _asset, uint256 _id) external onlyDelegationOwner {
        _setLockedAsset(_asset, _id, false);
    }

    // solhint-disable-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    // do not allow the owner to do stuff on rented assets
    function checkTransaction(
        address _to,
        uint256,
        bytes calldata _data,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address _msgSender
    ) external view override {
        // it is one of the real owners
        if (_msgSender != delegationOwner && checkAsset[_to]) {
            _checkLocked(_to, _data);
        }

        // approveForAll should be never allowed since can't be checked before renting or loaning
        _checkApproveForAll(_data);

        // transactions from rentals owner are already blocked/allowed there
        // renter --execTransaction--> DelegationOwner check allowed --execTransaction--> safe
        if (_msgSender == delegationOwner) {
            // TODO - save balances and approvals, do we need that?
        }

        _checkConfiguration(_to, _data);
    }

    function checkAfterExecution(bytes32 txHash, bool success) external view override {
        // TODO - balances and approvals after if needed (when execute comes from rentals owner)
        // TODO - balances and approvals
    }

    function isLocked(address _asset, uint256 _assetId) external view returns (bool) {
        return _isLocked(_asset, _assetId);
    }

    function _setLockedAsset(
        address _asset,
        uint256 _id,
        bool _loaned
    ) internal {
        checkAsset[_asset] = true;
        if (_loaned) {
            lockedAssets.add(keccak256(abi.encodePacked(_asset, _id)));
        } else {
            lockedAssets.remove(keccak256(abi.encodePacked(_asset, _id)));
        }
    }

    function _checkLocked(address _to, bytes calldata _data) internal view {
        bytes4 selector = _getSelector(_data);
        // move this check to an adaptor per asset address?
        if (_isTransfer(selector)) {
            (, , uint256 assetId) = abi.decode(_data[4:], (address, address, uint256));
            if (_isSignatureDelegating(_to, assetId) || _isDelegating(_to, assetId) || _isLocked(_to, assetId))
                revert DelegationGuard__checkLocked_noTransfer();
        }

        if (selector == IERC721.approve.selector) {
            (, uint256 assetId) = abi.decode(_data[4:], (address, uint256));
            if (_isSignatureDelegating(_to, assetId) || _isDelegating(_to, assetId) || _isLocked(_to, assetId))
                revert DelegationGuard__checkLocked_noApproval();
        }
    }

    function _checkApproveForAll(bytes calldata _data) internal pure {
        bytes4 selector = _getSelector(_data);
        if (selector == IERC721.setApprovalForAll.selector)
            revert DelegationGuard__checkApproveForAll_noApprovalForAll();
    }

    function _checkConfiguration(address _to, bytes calldata _data) internal view {
        bytes4 selector = _getSelector(_data);

        if (_to == DelegationOwner(delegationOwner).safe()) {
            // ownership change not allowed while this guard is configured
            if (
                selector == OwnerManager.addOwnerWithThreshold.selector ||
                selector == OwnerManager.removeOwner.selector ||
                selector == OwnerManager.swapOwner.selector ||
                selector == OwnerManager.changeThreshold.selector
            ) revert DelegationGuard__checkConfiguration_ownershipChangesNotAllowed();

            // Guard change not allowed while delegating or locked asset or delegating signature
            if (
                (lockedAssets.length() > 0 || block.timestamp < lastExpiry) &&
                selector == GuardManager.setGuard.selector
            ) revert DelegationGuard__checkConfiguration_guardChangeNotAllowed();
        }
    }

    function _isDelegating(address _asset, uint256 _assetId) internal view returns (bool) {
        return (block.timestamp <= delegationExpiries[_delegationId(_asset, _assetId)]);
    }

    function _isSignatureDelegating(address _asset, uint256 _assetId) internal view returns (bool) {
        return (block.timestamp <= signatureExpiries[_delegationId(_asset, _assetId)]);
    }

    function _isLocked(address _asset, uint256 _assetId) internal view returns (bool) {
        return lockedAssets.contains(keccak256(abi.encodePacked(_asset, _assetId)));
    }

    function _isTransfer(bytes4 selector) internal pure returns (bool) {
        return (selector == IERC721.transferFrom.selector ||
            selector == ERC721_SAFE_TRANSFER_FROM ||
            selector == ERC721_SAFE_TRANSFER_FROM_DATA);
    }

    function _delegationId(address _asset, uint256 _assetId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_asset, _assetId));
    }

    function _getSelector(bytes memory _data) internal pure returns (bytes4 selector) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            selector := mload(add(_data, 32))
        }
    }

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        virtual
        returns (
            // override
            bool
        )
    {
        return
            _interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            _interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


/**
 * @title DelegationRecipes
 * @author BootNode
 * @dev Registers the functions that will be allowed to be executed by assets delegates.
 * Functions are grouped by target contract and asset collection.
 */
contract DelegationRecipes is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    // collection address -> keccak256(collection, contract, selector)
    mapping(address => EnumerableSet.Bytes32Set) internal functionByCollection;

    // keccak256(collection, contract, selector) -> description
    mapping(bytes32 => string) public functionDescriptions;

    // ========== Events ===========
    event AddRecipe(
        address indexed collection,
        address[] contracts,
        bytes4[] selectors,
        string[] description
    );

    event RemoveRecipe(
        address indexed collection,
        address[] contracts,
        bytes4[] selectors
    );

    /**
     * @notice Adds a group of allowed functions to a asset collection.
     * @param _collection - The asset collection address.
     * @param _contracts - The target contract addresses.
     * @param _selectors - The allowed function selectors.
     */
    function add(
        address _collection,
        address[] calldata _contracts,
        bytes4[] calldata _selectors,
        string[] calldata _descriptions
    ) external onlyOwner {
        // TODO - validate arity

        bytes32 functionId;
        for (uint256 i; i < _contracts.length; ) {
            functionId = keccak256(abi.encodePacked(_collection, _contracts[i], _selectors[i]));
            functionByCollection[_collection].add(functionId);
            functionDescriptions[functionId] = _descriptions[i];

            emit AddRecipe(_collection, _contracts, _selectors, _descriptions);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes a group of allowed functions to a collection.
     * @param _collection - The owner's address.
     * @param _contracts - The owner's address.
     * @param _selectors - The owner's address.
     */
    function remove(
        address _collection,
        address[] calldata _contracts,
        bytes4[] calldata _selectors
    ) external onlyOwner {
        // TODO - validate arity

        bytes32 functionId;
        for (uint256 i; i < _contracts.length; ) {
            functionId = keccak256(abi.encodePacked(_collection, _contracts[i], _selectors[i]));
            functionByCollection[_collection].remove(functionId);
            delete functionDescriptions[functionId];

            emit RemoveRecipe(_collection, _contracts, _selectors);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Checks if a function is allowed for a collection.
     * @param _collection - The owner's address.
     * @param _contract - The owner's address.
     * @param _selector - The owner's address.
     */
    function isAllowedFunction(
        address _collection,
        address _contract,
        bytes4 _selector
    ) external view returns (bool) {
        bytes32 functionId = keccak256(abi.encodePacked(_collection, _contract, _selector));
        return functionByCollection[_collection].contains(functionId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";

interface Guard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "GS100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "GS000");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "GS104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/SelfAuthorized.sol";

/// @title OwnerManager - Manages a set of owners and a threshold to perform actions.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract OwnerManager is SelfAuthorized {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "GS200");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this) && currentOwner != owner, "GS203");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "GS204");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
    /// @param owner New owner address.
    /// @param _threshold New threshold.
    function addOwnerWithThreshold(address owner, uint256 _threshold) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "GS204");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    /// @param _threshold New threshold.
    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public authorized {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "GS201");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == owner, "GS205");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "GS204");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations by Safe owners.
    ///      This can only be done via a Safe transaction.
    /// @notice Changes the threshold of the Safe to `_threshold`.
    /// @param _threshold New threshold.
    function changeThreshold(uint256 _threshold) public authorized {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallbacks calls.
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title EtherPaymentFallback - A contract that has a fallback to accept ether payments
/// @author Richard Meissner - <[email protected]>
contract EtherPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /// @dev Fallback function accepts Ether transactions.
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Singleton - Base for singleton contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/GnosisSafeProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract Singleton {
    // singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private singleton;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SecuredTokenTransfer - Secure token transfer
/// @author Richard Meissner - <[email protected]>
contract SecuredTokenTransfer {
    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
                case 0 {
                    transferred := success
                }
                case 0x20 {
                    transferred := iszero(or(iszero(success), iszero(mload(0))))
                }
                default {
                    transferred := 0
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title GnosisSafeMath
 * @dev Math operations with safety checks that revert on error
 * Renamed from SafeMath to GnosisSafeMath to avoid conflicts
 * TODO: remove once open zeppelin update to solc 0.5.0
 */
library GnosisSafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IProxy {
    function masterCopy() external view returns (address);
}

/// @title GnosisSafeProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeProxy {
    // singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal singleton;

    /// @dev Constructor function sets address of singleton contract.
    /// @param _singleton Singleton address.
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./GnosisSafeProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(
        GnosisSafeProxy proxy,
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}