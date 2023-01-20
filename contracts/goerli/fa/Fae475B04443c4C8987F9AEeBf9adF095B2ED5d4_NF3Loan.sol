// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./Interfaces/IVault.sol";
import "./Interfaces/INF3Loan.sol";
import "./tokens/NF3LoanPromissoryToken.sol";
import "./lib/Utils.sol";

/// @title NF3 Loan
/// @author Jack Jin
/// @author Priyam Anand
/// @notice This is the contract that handles peer to peer loan on NFTs.
/// @dev During a loan, the assets are stored in a common vault used by the NF3 protocol.

contract NF3Loan is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    NF3LoanPromissoryToken,
    INF3Loan
{
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Utils for *;

    /// -----------------------------------------------------------------------
    /// Storage Variables
    /// -----------------------------------------------------------------------

    uint256 public constant FEE_CAP = 2500; // 25% hard cap on fee

    /// @notice Id of loan
    /// NOTE loanId will always be odd.
    ///      loanId is same as lender's promissory tokenId
    ///      borrower's promissory tokenId is lender's tokenId + 1
    uint256 public loanId;

    /// @notice Vault contract address
    address public vaultContract;

    /// @notice Admin fee percentage
    uint256 public adminFeesInBasisPoints;

    /// @notice Maximum loan duration
    uint256 public maximumLoanDuration;

    /// @notice Mapping of user's and their nonce
    ///         Only meant for trusted forwarer address because this address is immutable and
    ///         is not stored in the storage.
    mapping(address => mapping(uint256 => bool)) public nonce;

    /* ===== INIT ===== */

    /// @dev Constructor
    constructor(address trustedForwarder)
        ERC2771ContextUpgradeable(trustedForwarder)
    {
        _disableInitializers();
    }

    /// @dev Initialize
    function initialize(
        uint256 _adminFeesInBasisPoints,
        uint256 _maximumLoanDuration
    ) public initializer {
        if (_adminFeesInBasisPoints > FEE_CAP) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_FEE_VALUE);
        }
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721_init("NF3Loan Promissory Token", "NF3 PT");
        maximumLoanDuration = _maximumLoanDuration;
        adminFeesInBasisPoints = _adminFeesInBasisPoints;
    }

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Loan
    function cancelLoanOffer(
        LoanOffer calldata _loanOffer,
        bytes memory _signature
    ) external override {
        // Verify offer signature and nonce.
        _loanOffer.verifyLoanOfferSignature(_signature);

        // Cancel offer.
        cancelOffer(_loanOffer.owner, _loanOffer.nonce);

        emit LoanOfferCancelled(_loanOffer, _loanOffer.owner);
    }

    /// @notice Inherit from INF3Loan
    function cancelCollectionLoanOffer(
        CollectionLoanOffer calldata _loanOffer,
        bytes memory _signature
    ) external override nonReentrant {
        // Verify offer signature and nonce.
        _loanOffer.verifyCollectionLoanOfferSignature(_signature);

        // Cancel offer.
        cancelOffer(_loanOffer.owner, _loanOffer.nonce);

        emit CollectionLoanOfferCancelled(_loanOffer, _loanOffer.owner);
    }

    /// @notice Inherit from INF3Loan
    function cancelLoanUpdateOffer(
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) external override nonReentrant {
        // Verify offer signature and nonce.
        _loanOffer.verifyUpdateLoanSignature(_signature);

        // Cancel offer.
        cancelOffer(_loanOffer.owner, _loanOffer.nonce);

        emit LoanUpdateOfferCancelled(_loanOffer, _loanOffer.owner);
    }

    /// -----------------------------------------------------------------------
    /// Loan Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Loan
    function beginLoan(LoanOffer calldata _loanOffer, bytes memory _signature)
        external
        override
        whenNotPaused
        nonReentrant
    {
        // Verify offer signature.
        _loanOffer.verifyLoanOfferSignature(_signature);

        // Check the nonce.
        if (nonce[_loanOffer.owner][_loanOffer.nonce]) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_NONCE);
        }

        // Memoize loanId to minimise sload.
        uint256 _loanId = loanId + 1;

        // Create the loan.
        Loan memory _loan = Loan(
            _loanId,
            _loanOffer.nftCollateralContract,
            _loanOffer.nftCollateralId,
            _loanOffer.loanPaymentToken,
            _loanOffer.loanPrincipalAmount,
            _loanOffer.maximumRepaymentAmount,
            block.timestamp,
            _loanOffer.loanDuration,
            _loanOffer.loanInterestRate,
            _loanOffer.adminFees,
            _loanOffer.isLoanProrated
        );

        // If the loan info is valid.
        checkLoan(_loan);

        // Get the lender and borrower from borrowerTerms.
        (address lender, address borrower) = getUsers(
            _loanOffer.owner,
            _loanOffer.isBorrowerTerms
        );

        // Lender and borrower shouldn't be the same.
        if (lender == borrower) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_LENDER);
        }

        // Perform start loan actions
        startLoan(_loan, _loanOffer.owner, _loanOffer.nonce, lender, borrower);

        emit LoanStarted(_loan, lender, borrower);
    }

    /// @notice Inherit from INF3Loan
    function acceptCollectionLoanOffer(
        CollectionLoanOffer calldata _loanOffer,
        bytes memory _signature,
        uint256 _nftCollateralId,
        bytes32[] calldata _proof
    ) external override whenNotPaused nonReentrant {
        // Verify offer signature.
        _loanOffer.verifyCollectionLoanOfferSignature(_signature);

        // Check the nonce.
        if (nonce[_loanOffer.owner][_loanOffer.nonce]) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_NONCE);
        }

        // Memoize loanId to minimise sload.
        uint256 _loanId = loanId + 1;

        // Create the loan.
        Loan memory _loan = Loan(
            _loanId,
            _loanOffer.nftCollateralContract,
            _nftCollateralId,
            _loanOffer.loanPaymentToken,
            _loanOffer.loanPrincipalAmount,
            _loanOffer.maximumRepaymentAmount,
            block.timestamp,
            _loanOffer.loanDuration,
            _loanOffer.loanInterestRate,
            _loanOffer.adminFees,
            _loanOffer.isLoanProrated
        );

        // Check if the loan is valid.
        checkLoan(_loan);

        // Get the lender and borrower.
        address lender = _loanOffer.owner;
        address borrower = _msgSender();

        // Should not be called by lender.
        if (lender == borrower) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_LENDER);
        }

        // Verify merkle proof of _nftCollateralId existing in the _loanOffer.nftCollateralIdRoot.
        if (
            _loanOffer.nftCollateralIdRoot != bytes32(0) &&
            !_loanOffer.nftCollateralIdRoot.verifyMerkleProof(
                _proof,
                keccak256(abi.encodePacked(_nftCollateralId))
            )
        ) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_COLLATERAL_TOKEN_ID);
        }

        // Perform start loan actions
        startLoan(_loan, _loanOffer.owner, _loanOffer.nonce, lender, borrower);

        emit LoanStarted(_loan, lender, borrower);
    }

    /// @notice Inherit from INF3Loan
    function payBackLoan(Loan calldata _loan) external override nonReentrant {
        // Verify the loan if it exists and is valid.
        verifyLoan(_loan);

        // Should be called by only borrower.
        address borrower = ownerOf(_loan.loanId + 1);

        if (_msgSender() != borrower) {
            revert NF3LoanError(NF3LoanErrorCodes.BORRWOER_ONLY);
        }

        // Get the lender.
        address lender = ownerOf(_loan.loanId);

        // Calculate amounts to send to lender and admin.
        uint256 interestDue = _loan.maximumRepaymentAmount -
            _loan.loanPrincipalAmount;

        if (_loan.isLoanProrated) {
            interestDue = computeInterestDue(
                _loan.loanPrincipalAmount,
                _loan.maximumRepaymentAmount,
                block.timestamp - _loan.loanStartTime,
                _loan.loanDuration,
                _loan.loanInterestRate
            );
        }

        uint256 adminFee = computeAdminFee(
            interestDue,
            uint256(_loan.adminFees)
        );

        uint256 payoffAmount = _loan.loanPrincipalAmount +
            interestDue -
            adminFee;

        // Burn the promissory token of lender and borrower.
        burn(_loan.loanId);

        // Loan vaultAddress to stack to save sload.
        address _vaultContract = vaultContract;

        // Transefer the (total amount - admin fee) to lender.
        IVault(_vaultContract).transferAssets(
            Assets({
                tokens: new address[](0),
                tokenIds: new uint256[](0),
                paymentTokens: toAddressArray(_loan.loanPaymentToken),
                amounts: toIntArray(payoffAmount)
            }),
            borrower,
            lender,
            Royalty({to: new address[](0), percentage: new uint256[](0)}),
            false
        );

        // Transfer the admin fees to the owner.
        IVault(_vaultContract).transferAssets(
            Assets({
                tokens: new address[](0),
                tokenIds: new uint256[](0),
                paymentTokens: toAddressArray(_loan.loanPaymentToken),
                amounts: toIntArray(adminFee)
            }),
            borrower,
            owner(),
            Royalty({to: new address[](0), percentage: new uint256[](0)}),
            false
        );

        // Return collateral assets to the borrower.
        IVault(_vaultContract).sendAssets(
            Assets({
                tokens: toAddressArray(_loan.nftCollateralContract),
                tokenIds: toIntArray(_loan.nftCollateralId),
                paymentTokens: new address[](0),
                amounts: new uint256[](0)
            }),
            borrower,
            Royalty({to: new address[](0), percentage: new uint256[](0)}),
            false
        );

        emit LoanRepaid(_loan, lender, borrower);
    }

    /// @notice Inherit from INF3Loan
    function updateLoanTerms(
        Loan memory _loan,
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) external override nonReentrant {
        // Verify the loan if it exists and is valid.
        verifyLoan(_loan);

        // Check update offer signature.
        _loanOffer.verifyUpdateLoanSignature(_signature);

        // Check the nonce.
        if (nonce[_loanOffer.owner][_loanOffer.nonce]) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_NONCE);
        }

        // Check if the loan id is same as loanOffer id.
        if (_loanOffer.loanId != _loan.loanId) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_LOAN_OFFER_PAIR);
        }

        // Get lender and borrower from _isBorrowerOffer.
        (address lender, address borrower) = getUsers(
            _loanOffer.owner,
            _loanOffer.isBorrowerTerms
        );

        // Check if the lender and borrower are the owner of promissory token.
        if (ownerOf(_loan.loanId) != lender) {
            revert NF3LoanError(NF3LoanErrorCodes.LENDER_ONLY);
        }

        if (ownerOf(_loan.loanId + 1) != borrower) {
            revert NF3LoanError(NF3LoanErrorCodes.BORRWOER_ONLY);
        }

        // Update the loan info in the memory for easier validation.
        _loan.maximumRepaymentAmount = _loanOffer.maximumRepaymentAmount;
        _loan.loanDuration = _loanOffer.loanDuration;
        _loan.loanInterestRate = _loanOffer.loanInterestRate;
        _loan.isLoanProrated = _loanOffer.isLoanProrated;

        // Check updated loan.
        commonCheckLoan(_loan);

        // Update loan data hash.
        setLoanDataHash(_loan);

        emit LoanTermsUpdated(_loan, lender, borrower);
    }

    /// @notice Inherit from INF3Loan
    function claimOverdueLoanCollateral(Loan calldata _loan)
        external
        override
        whenNotPaused
        nonReentrant
    {
        // Verify the loan if it exists and is valid.
        verifyLoan(_loan);

        // Should be called by only lender.
        address lender = ownerOf(_loan.loanId);

        if (_msgSender() != lender) {
            revert NF3LoanError(NF3LoanErrorCodes.LENDER_ONLY);
        }

        // Check if the loan is overdue.
        if ((_loan.loanStartTime + _loan.loanDuration) >= block.timestamp) {
            revert NF3LoanError(NF3LoanErrorCodes.LOAN_NOT_OVERDUE);
        }

        // Fetch the borrower.
        address borrower = ownerOf(_loan.loanId + 1);

        // Burn lender and borrower promissory token.
        burn(_loan.loanId);

        // Transfer locked collateral assets to the lender.
        IVault(vaultContract).sendAssets(
            Assets({
                tokens: toAddressArray(_loan.nftCollateralContract),
                tokenIds: toIntArray(_loan.nftCollateralId),
                paymentTokens: new address[](0),
                amounts: new uint256[](0)
            }),
            lender,
            Royalty({to: new address[](0), percentage: new uint256[](0)}),
            false
        );

        emit LoanCollateralClaimed(_loan, lender, borrower);
    }

    /// -----------------------------------------------------------------------
    /// Owner Functions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Loan
    function setVaultContract(address _vaultContract)
        external
        override
        onlyOwner
    {
        if (_vaultContract == address(0)) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_ADDRESS);
        }
        emit VaultContractSet(vaultContract, _vaultContract);

        vaultContract = _vaultContract;
    }

    /// @notice Inherit from INF3Loan
    function setMaximumLoanDuration(uint256 _maximumLoanDuration)
        external
        override
        onlyOwner
    {
        emit MaximumLoanDurationSet(maximumLoanDuration, _maximumLoanDuration);
        maximumLoanDuration = _maximumLoanDuration;
    }

    /// @notice Inherit from INF3Loan
    function updateAdminFee(uint256 _adminFeeInBasisPoints)
        external
        override
        onlyOwner
    {
        if (_adminFeeInBasisPoints > FEE_CAP) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_FEE_VALUE);
        }

        emit AdminFeesSet(adminFeesInBasisPoints, _adminFeeInBasisPoints);
        adminFeesInBasisPoints = _adminFeeInBasisPoints;
    }

    /// @notice Inherit from INF3Loan
    function setPause(bool _setPause) external override onlyOwner {
        if (_setPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// -----------------------------------------------------------------------
    /// Internal Actions
    /// -----------------------------------------------------------------------

    /// @notice Cancel the loan offer.
    /// @param _owner Offer owner address
    /// @param _nonce Nonce that needs to be operated
    function cancelOffer(address _owner, uint256 _nonce) internal {
        // Check the nonce.
        if (nonce[_owner][_nonce]) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_NONCE);
        }

        // Should be called by offer owner.
        if (_owner != _msgSender()) {
            revert NF3LoanError(NF3LoanErrorCodes.ONLY_OWNER);
        }

        // Update the nonce.
        nonce[_owner][_nonce] = true;
    }

    /// @dev Check the loan if it is valid.
    /// @param _loan Loan info
    function checkLoan(Loan memory _loan) internal view {
        // Common check.
        commonCheckLoan(_loan);

        // Admin fees should be the same as declared by the protocol.
        if (_loan.adminFees != adminFeesInBasisPoints) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_ADMIN_FEES);
        }
    }

    /// @dev Check related to the loan payment tokens.
    /// @param _loan Loan info
    function commonCheckLoan(Loan memory _loan) internal view {
        // Interest rate should not be negative.
        if (_loan.maximumRepaymentAmount < _loan.loanPrincipalAmount) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_LOAN_INTEREST_RATE);
        }

        // Interest rate can not be more than 100%.
        if (_loan.loanInterestRate > 10000) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_LOAN_INTEREST_RATE);
        }

        // Duration should not be more than max duration set by protocol and not equal to zero.
        if (
            _loan.loanDuration > maximumLoanDuration || _loan.loanDuration == 0
        ) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_LOAN_DURATION);
        }
    }

    /// @dev common actions performed when loan is started
    /// @param _loanInfo Loan information struct
    /// @param _owner Owner of the loan offer
    /// @param _nonce nonce of the loan offer
    /// @param _lender Lender's address
    /// @param _borrower Borrower's address
    function startLoan(
        Loan memory _loanInfo,
        address _owner,
        uint256 _nonce,
        address _lender,
        address _borrower
    ) internal {
        // Mint the promissory token to lender and borrower.
        mint(_loanInfo, _lender, _borrower);

        // Update the nonce.
        nonce[_owner][_nonce] = true;

        // Update the loanId.
        loanId = _loanInfo.loanId + 1;

        // Loan vaultAddress to stack to save sload.
        address _vaultContract = vaultContract;

        // Lock the collateral token to the vault.
        IVault(_vaultContract).receiveAssets(
            Assets({
                tokens: toAddressArray(_loanInfo.nftCollateralContract),
                tokenIds: toIntArray(_loanInfo.nftCollateralId),
                paymentTokens: new address[](0),
                amounts: new uint256[](0)
            }),
            _borrower,
            false
        );

        // Transfer the principal amount to the borrower.
        IVault(_vaultContract).transferAssets(
            Assets({
                tokens: new address[](0),
                tokenIds: new uint256[](0),
                paymentTokens: toAddressArray(_loanInfo.loanPaymentToken),
                amounts: toIntArray(_loanInfo.loanPrincipalAmount)
            }),
            _lender,
            _borrower,
            Royalty({to: new address[](0), percentage: new uint256[](0)}),
            false
        );
    }

    /// @dev Compute the interest due after a given time period of the loan.
    /// @param _loanPrincipalAmount Loan principal amount
    /// @param _maximumRepaymentAmount Loan maximum refund amount
    /// @param _loanFinishedDuration Finished loan duration
    /// @param _loanDuration Agreed loan duration at the beginning
    /// @param _loanInterestRate Loan interest rate
    function computeInterestDue(
        uint256 _loanPrincipalAmount,
        uint256 _maximumRepaymentAmount,
        uint256 _loanFinishedDuration,
        uint256 _loanDuration,
        uint256 _loanInterestRate
    ) internal pure returns (uint256) {
        uint256 originalInterest = (_loanPrincipalAmount * _loanInterestRate) /
            10000;
        uint256 currentInterest = (originalInterest * _loanFinishedDuration) /
            _loanDuration;
        if (
            (_loanPrincipalAmount + currentInterest) > _maximumRepaymentAmount
        ) {
            return _maximumRepaymentAmount - _loanPrincipalAmount;
        } else {
            return currentInterest;
        }
    }

    /// @notice Compute the adminFee taken from a specified quantity of interest.
    /// @param  _adminFeeInBasisPoints - The percent (measured in basis
    ///         points) of the interest earned that will be taken as a fee by
    ///         the contract admins when the loan is repaid. The fee is stored
    ///         in the loan struct to prevent an attack where the contract
    ///         admins could adjust the fee right before a loan is repaid, and
    ///         take all of the interest earned.
    function computeAdminFee(
        uint256 _interestDue,
        uint256 _adminFeeInBasisPoints
    ) internal pure returns (uint256) {
        return (_interestDue * _adminFeeInBasisPoints) / 10000;
    }

    /// @dev Get the lender and borrower of the trade.
    /// @param _loanOfferOwner Owner of the loan
    /// @param _isBorrowerTerms Bool value to specify terms of lender/borrower
    /// @return lender Lender address
    /// @return borrower Borrower address
    function getUsers(address _loanOfferOwner, bool _isBorrowerTerms)
        internal
        view
        returns (address lender, address borrower)
    {
        if (_isBorrowerTerms) {
            lender = _msgSender();
            borrower = _loanOfferOwner;
        } else {
            lender = _loanOfferOwner;
            borrower = _msgSender();
        }
    }

    /// @dev Verify if the loan exists and loan's hash with it's stored hash in promissory token.
    /// @param _loan Loan info
    function verifyLoan(Loan memory _loan) internal view {
        if (!_exists(_loan.loanId)) {
            if (_loan.loanId < loanId) {
                revert NF3LoanError(
                    NF3LoanErrorCodes.LOAN_ALREADY_REPAIED_OR_LIQUIDATED
                );
            } else {
                revert NF3LoanError(NF3LoanErrorCodes.LOAN_DOES_NOT_EXIST);
            }
        }

        bytes32 computedHash = computeLoanHash(_loan);

        bytes32 storedHash = getLoanDataHash(_loan.loanId);

        if (computedHash != storedHash) {
            revert NF3LoanError(NF3LoanErrorCodes.INVALID_LOAN_PARAMS);
        }
    }

    /// -----------------------------------------------------------------------
    /// Pure Operations
    /// -----------------------------------------------------------------------

    /// @dev Convert and return address to address array.
    /// @param _addr Address
    function toAddressArray(address _addr)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory _arr = new address[](1);
        _arr[0] = _addr;
        return _arr;
    }

    /// @dev Convert and return uint256 to uint256 array.
    /// @param _val Uint256 value
    function toIntArray(uint256 _val) internal pure returns (uint256[] memory) {
        uint256[] memory _arr = new uint256[](1);
        _arr[0] = _val;
        return _arr;
    }

    /// -----------------------------------------------------------------------
    /// EIP-2771 Actions
    /// -----------------------------------------------------------------------

    function _msgSender()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[45] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Vault Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines all the functions related to assets transfer and assets escrow.

interface IVault {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum VaultErrorCodes {
        CALLER_NOT_APPROVED,
        FAILED_TO_SEND_ETH,
        ETH_NOT_ALLOWED,
        INVALID_ASSET_TYPE,
        COULD_NOT_RECEIVE_KITTY,
        COULD_NOT_SEND_KITTY,
        INVALID_PUNK,
        COULD_NOT_RECEIVE_PUNK,
        COULD_NOT_SEND_PUNK,
        INVALID_ADDRESS
    }

    error VaultError(VaultErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when the assets have transferred.
    /// @param assets Assets
    /// @param from Sender address
    /// @param to Receiver address
    event AssetsTransferred(Assets assets, address from, address to);

    /// @dev Emits when the assets have been received by the vault.
    /// @param assets Assets
    /// @param from Sender address
    event AssetsReceived(Assets assets, address from);

    /// @dev Emits when the assets have been sent by the vault.
    /// @param assets Assets
    /// @param to Receiver address
    event AssetsSent(Assets assets, address to);

    /// @dev Emits when new swap address has set.
    /// @param oldSwapAddress Previous swap contract address
    /// @param newSwapAddress New swap contract address
    event SwapSet(address oldSwapAddress, address newSwapAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// @dev Emits when new whitelist contract address has set
    /// @param oldWhitelistAddress Previous whitelist contract address
    /// @param newWhitelistAddress New whitelist contract address
    event WhitelistSet(
        address oldWhitelistAddress,
        address newWhitelistAddress
    );

    /// @dev Emits when new loan contract address has set
    /// @param oldLoanAddress Previous loan contract address
    /// @param newLoanAddress New whitelist contract address
    event LoanSet(address oldLoanAddress, address newLoanAddress);

    /// -----------------------------------------------------------------------
    /// Transfer actions
    /// -----------------------------------------------------------------------

    /// @dev Transfer the assets "assets" from "from" to "to".
    /// @param assets Assets to be transfered
    /// @param from Sender address
    /// @param to Receiver address
    /// @param royalty Royalty info
    /// @param allowEth Bool variable if can send ETH or not
    function transferAssets(
        Assets calldata assets,
        address from,
        address to,
        Royalty calldata royalty,
        bool allowEth
    ) external;

    /// @dev Receive assets "assets" from "from" address to the vault
    /// @param assets Assets to be transfered
    /// @param from Sender address
    function receiveAssets(
        Assets calldata assets,
        address from,
        bool allowEth
    ) external;

    /// @dev Send assets "assets" from the vault to "_to" address
    /// @param assets Assets to be transfered
    /// @param to Receiver address
    /// @param royalty Royalty info
    function sendAssets(
        Assets calldata assets,
        address to,
        Royalty calldata royalty,
        bool allowEth
    ) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Swap contract address.
    /// @param swapAddress Swap contract address
    function setSwap(address swapAddress) external;

    /// @dev Set Reserve contract address.
    /// @param reserveAddress Reserve contract address
    function setReserve(address reserveAddress) external;

    /// @dev Set Whitelist contract address.
    /// @param whitelistAddress Whitelist contract address
    function setWhitelist(address whitelistAddress) external;

    /// @dev Set Loan contract address
    /// @param loanAddress Whitelist contract address
    function setLoan(address loanAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utils/LoanDataTypes.sol";

interface INF3Loan {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum NF3LoanErrorCodes {
        ONLY_OWNER,
        INVALID_NONCE,
        INVALID_LENDER,
        LENDER_ONLY,
        BORRWOER_ONLY,
        INVALID_LOAN_INTEREST_RATE,
        INVALID_LOAN_DURATION,
        INVALID_ADMIN_FEES,
        INVALID_COLLATERAL_TOKEN_ID,
        INVALID_LOAN_PARAMS,
        INVALID_LOAN_OFFER_PAIR,
        INVALID_BASIS_VALUE,
        LOAN_ALREADY_REPAIED_OR_LIQUIDATED,
        LOAN_DOES_NOT_EXIST,
        LOAN_NOT_OVERDUE,
        INVALID_ADDRESS,
        INVALID_FEE_VALUE
    }

    error NF3LoanError(NF3LoanErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when a loan offering has been cancelled.
    /// @param loanOffer Loan offer info
    /// @param owner Owner of the the loan offer
    event LoanOfferCancelled(LoanOffer loanOffer, address indexed owner);

    /// @dev Emits when a collection loan offer has been cancelled.
    /// @param loanOffer Collection loan offer info
    /// @param owner Owner of the collection loan offer
    event CollectionLoanOfferCancelled(
        CollectionLoanOffer loanOffer,
        address indexed owner
    );

    /// @dev Emits when a loan update terms offer has been cancelled.
    /// @param loanOffer Update loan terms offer info
    /// @param owner Owner of the update loan terms
    event LoanUpdateOfferCancelled(
        LoanUpdateOffer loanOffer,
        address indexed owner
    );

    /// @dev Emits when loan offer has accepted and started.
    /// @param loanInfo Loan struct containig all the loan terms
    /// @param lender Lender address
    /// @param borrower Borrower address
    event LoanStarted(
        Loan loanInfo,
        address indexed lender,
        address indexed borrower
    );

    /// @dev Emits when the loan amount has paid by the borrower.
    /// @param loan Loan info containing all the loan terms
    /// @param lender Lender address
    /// @param borrower borrower address
    event LoanRepaid(
        Loan loan,
        address indexed lender,
        address indexed borrower
    );

    /// @dev Emits when the overdue loan is liquidated and it's collateral is claimed
    ///      by the lender.
    /// @param loan Loan info containing all the loan terms
    /// @param lender Lender address
    /// @param borrower Borrower address
    event LoanCollateralClaimed(
        Loan loan,
        address indexed lender,
        address indexed borrower
    );

    /// @dev Emits when the terms of a loan is updated, ie. loan is extended etc.
    /// @param loan Loan info containing all the upated loan terms
    /// @param lender Lender address
    /// @param borrower Borrower address
    event LoanTermsUpdated(
        Loan loan,
        address indexed lender,
        address indexed borrower
    );

    /// @dev Emits when admin fee percentage has set.
    /// @param oldAdminFees Previous admin fee
    /// @param newAdminFees New admin fee
    event AdminFeesSet(uint256 oldAdminFees, uint256 newAdminFees);

    /// @dev Emits when new maximum loan duration has set.
    /// @param oldMaximumLoanDuration Previous maximum loan duration
    /// @param newMaximumLoanDuration New maximum loan duration
    event MaximumLoanDurationSet(
        uint256 oldMaximumLoanDuration,
        uint256 newMaximumLoanDuration
    );

    /// @dev Emits when protocol vault contract has updated.
    /// @param oldVaultContract Previous vault contract address
    /// @param newVaultContract New vault contract address
    event VaultContractSet(address oldVaultContract, address newVaultContract);

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @dev Cancel loan offer.
    /// @param loanOffer Loan offer info
    /// @param signature Signature of loan offer
    function cancelLoanOffer(
        LoanOffer calldata loanOffer,
        bytes memory signature
    ) external;

    /// @dev Cancel collection loan offer.
    /// @param loanOffer Collection loan offer info
    /// @param signature Signature of the collection loan offer
    function cancelCollectionLoanOffer(
        CollectionLoanOffer calldata loanOffer,
        bytes memory signature
    ) external;

    /// @dev Cancel update loan offer.
    /// @param loanOffer Update loan offer info
    /// @param signature Signature of update loan offer
    function cancelLoanUpdateOffer(
        LoanUpdateOffer calldata loanOffer,
        bytes memory signature
    ) external;

    /// -----------------------------------------------------------------------
    /// Loan Actions
    /// -----------------------------------------------------------------------

    /// @dev Start loan.
    /// @param loanOffer Loan offer info
    /// @param signature Signature of loan offer info
    function beginLoan(LoanOffer calldata loanOffer, bytes memory signature)
        external;

    /// @dev Accept collection level loan offer and start the loan.
    /// @param loanOffer Collection level loan offer
    /// @param signature Signature of loan offer params
    /// @param nftCollateralId Token id of the given collection being offered as collateral
    /// @param proof Merkle proof that nftCollateralId exist in the nftCollateralIdRoot
    function acceptCollectionLoanOffer(
        CollectionLoanOffer calldata loanOffer,
        bytes memory signature,
        uint256 nftCollateralId,
        bytes32[] calldata proof
    ) external;

    /// @dev Pay back the loan and get back the collateral NFT.
    /// @param loan Loan info
    function payBackLoan(Loan calldata loan) external;

    /// @dev Update the terms of an existing loan with the consent of both borrower and lender.
    /// @param loan Loan info containig the current terms
    /// @param loanOffer Updated loan offer terms
    /// @param signature Signature of the loanOffer terms
    function updateLoanTerms(
        Loan memory loan,
        LoanUpdateOffer calldata loanOffer,
        bytes memory signature
    ) external;

    /// @dev Claim the collateral in the case of an overdue loan.
    /// @param loan Loan info containing all the params
    function claimOverdueLoanCollateral(Loan calldata loan) external;

    /// -----------------------------------------------------------------------
    /// Owner Functions
    /// -----------------------------------------------------------------------

    /// @dev Update address of protocol vault contract.
    /// @param vaultContract Address of the new vault contract
    function setVaultContract(address vaultContract) external;

    /// @dev Set pause and unpause of the contract.
    ///      This function can only called through protocol admin contract
    /// @param pause Bool value to represent pause and unpause state
    function setPause(bool pause) external;

    /// @dev Update maximum loan duration time.
    /// @param maximumLoanDuration New maximum duration of the loan
    function setMaximumLoanDuration(uint256 maximumLoanDuration) external;

    /// @dev Update admin fee percentage.
    /// @param adminFeeInBasisPoints Admin's fee in basis points
    function updateAdminFee(uint256 adminFeeInBasisPoints) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title NF3 Loan promissory token contract
/// @author Jack Jin
/// @author Priyam Anand
/// @notice This is the contract is an ERC721 contract that has the NFT promisarry tokens for
///         lender and borrower of the loans.
/// @dev During a loan, the assets are stored in a common vault used by the NF3 protocol.

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../../utils/LoanDataTypes.sol";

abstract contract NF3LoanPromissoryToken is ERC721Upgradeable {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Hash of each loan struct stored loanId wise
    mapping(uint256 => bytes32) public loanDataHash;

    /// @dev Mint the promissory token to both of lender and borrower.
    /// @param _loan Loan info
    /// @param _lender Lender address
    /// @param _borrower Borrower address
    function mint(
        Loan memory _loan,
        address _lender,
        address _borrower
    ) internal {
        bytes32 _loanHash = computeLoanHash(_loan);

        _safeMint(_lender, _loan.loanId);

        _safeMint(_borrower, _loan.loanId + 1);

        loanDataHash[_loan.loanId] = _loanHash;
    }

    /// @dev Burn the promissory token of both lender's and borrower's.
    ///      Loan id is the same as token id.
    /// @param _tokenId LoanId / tokenId to be burnt.
    function burn(uint256 _tokenId) internal {
        _tokenId = _tokenId % 2 == 0 ? _tokenId - 1 : _tokenId;

        _burn(_tokenId);
        _burn(_tokenId + 1);

        delete loanDataHash[_tokenId];
    }

    /// @dev Set loan data hash to the promissary token.
    /// @param _loan Loan ino
    function setLoanDataHash(Loan memory _loan) internal {
        bytes32 _loanHash = computeLoanHash(_loan);

        loanDataHash[_loan.loanId] = _loanHash;
    }

    /// @dev Get the hash of the loan info.
    /// @param _tokenId LoanId / tokenId
    function getLoanDataHash(uint256 _tokenId) public view returns (bytes32) {
        _tokenId = _tokenId % 2 == 0 ? _tokenId - 1 : _tokenId;

        return loanDataHash[_tokenId];
    }

    /// @dev Compute hash of loan info.
    /// @param _loan Loan info
    /// @return loanHash Hash of the loan
    function computeLoanHash(Loan memory _loan)
        internal
        pure
        returns (bytes32 loanHash)
    {
        loanHash = keccak256(
            abi.encodePacked(
                _loan.loanId,
                _loan.nftCollateralContract,
                _loan.nftCollateralId,
                _loan.loanPaymentToken,
                _loan.loanPrincipalAmount,
                _loan.maximumRepaymentAmount,
                _loan.loanStartTime,
                _loan.loanDuration,
                _loan.loanInterestRate,
                _loan.adminFees,
                _loan.isLoanProrated
            )
        );
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../../utils/DataTypes.sol";
import "../../utils/LoanDataTypes.sol";

/// @title NF3 Utils Library
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This library contains all the pure functions that are used across the system of contracts.

library Utils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum UtilsErrorCodes {
        INVALID_LISTING_SIGNATURE,
        INVALID_SWAP_OFFER_SIGNATURE,
        INVALID_COLLECTION_OFFER_SIGNATURE,
        INVALID_RESERVE_OFFER_SIGNATURE,
        INVALID_ITEMS,
        ONLY_OWNER,
        OWNER_NOT_ALLOWED,
        INVALID_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_LOAN_OFFER_SIGNATURE,
        INVALID_UPDATE_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE
    }

    error UtilsError(UtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    /* ===== Verify Signatures ===== */

    /// @dev Check the signature if the listing info is valid or not.
    /// @param _listing Listing info
    /// @param _signature Listing signature
    function verifyListingSignature(
        Listing calldata _listing,
        bytes memory _signature
    ) internal pure {
        address owner = getListingSignatureOwner(_listing, _signature);

        if (_listing.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_LISTING_SIGNATURE);
        }
    }

    /// @dev Check the signature if the swap offer is valid or not.
    /// @param _offer Offer info
    /// @param _signature Offer signature
    function verifySwapOfferSignature(
        SwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getSwapOfferSignatureOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_SWAP_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the collection offer is valid or not.
    /// @param _offer Offer info
    /// @param _signature Offer signature
    function verifyCollectionSwapOfferSignature(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionSwapOfferOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_OFFER_SIGNATURE
            );
        }
    }

    /// @dev Check the signature if the reserve offer is valid or not.
    /// @param _offer Reserve offer info
    /// @param _signature Reserve offer signature
    function verifyReserveOfferSignature(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getReserveOfferSignatureOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_RESERVE_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the loan offer is valid or not.
    /// @param _loanOffer Loan offer info
    /// @param _signature Loan offer signature
    function verifyLoanOfferSignature(
        LoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getLoanOfferOwer(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_LOAN_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the collection loan offer is valid or not.
    /// @param _loanOffer Collection loan offer info
    /// @param _signature Collection loan offer signature
    function verifyCollectionLoanOfferSignature(
        CollectionLoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionLoanOwner(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_LOAN_OFFER_SIGNATURE
            );
        }
    }

    function verifyCollectionReserveOfferSignature(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionReserveOfferOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE
            );
        }
    }

    /// @dev Check the signature if the update loan offer is valid or not.
    /// @param _loanOffer Update loan offer info
    /// @param _signature Update loan offer signature
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getUpdateLoanOfferOwner(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_UPDATE_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /* ===== Verify Assets ===== */

    /// @dev Verify assets1 and assets2 if they are the same.
    /// @param _assets1 First assets
    /// @param _assets2 Second assets
    function verifyAssets(Assets calldata _assets1, Assets calldata _assets2)
        internal
        pure
    {
        if (
            _assets1.paymentTokens.length != _assets2.paymentTokens.length ||
            _assets1.tokens.length != _assets2.tokens.length
        ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets1.paymentTokens.length; i++) {
                if (
                    _assets1.paymentTokens[i] != _assets2.paymentTokens[i] ||
                    _assets1.amounts[i] != _assets2.amounts[i]
                ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
            }

            for (i = 0; i < _assets1.tokens.length; i++) {
                if (
                    _assets1.tokens[i] != _assets2.tokens[i] ||
                    _assets1.tokenIds[i] != _assets2.tokenIds[i]
                ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
            }
        }
    }

    /// @dev Verify swap assets to be satisfied as the consideration items by the seller.
    /// @param _swapAssets Swap assets
    /// @param _tokens NFT addresses
    /// @param _tokenIds NFT token ids
    /// @param _value Eth value
    /// @return assets Verified swap assets
    function verifySwapAssets(
        SwapAssets memory _swapAssets,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        uint256 _value
    ) internal pure returns (Assets memory) {
        uint256 ethAmount;
        uint256 i;

        // check Eth amounts
        for (i = 0; i < _swapAssets.paymentTokens.length; ) {
            if (_swapAssets.paymentTokens[i] == address(0))
                ethAmount += _swapAssets.amounts[i];
            unchecked {
                ++i;
            }
        }
        if (ethAmount > _value) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }

        unchecked {
            // check compatible NFTs
            for (i = 0; i < _swapAssets.tokens.length; i++) {
                if (
                    _swapAssets.tokens[i] != _tokens[i] ||
                    (!verifyMerkleProof(
                        _swapAssets.roots[i],
                        _proofs[i],
                        keccak256(abi.encodePacked(_tokenIds[i]))
                    ) && _swapAssets.roots[i] != bytes32(0))
                ) {
                    revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
                }
            }
        }

        return
            Assets(
                _tokens,
                _tokenIds,
                _swapAssets.paymentTokens,
                _swapAssets.amounts
            );
    }

    /// @dev Verify if the passed asset is present in the merkle root passed.
    /// @param _root Merkle root to check in
    /// @param _consideration Consideration assets
    /// @param _proof Merkle proof
    function verifyAssetProof(
        bytes32 _root,
        Assets calldata _consideration,
        bytes32[] calldata _proof
    ) internal pure {
        bytes32 _leaf = addAssets(_consideration, bytes32(0));

        if (!verifyMerkleProof(_root, _proof, _leaf)) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }
    }

    /* ===== Check Validations ===== */

    /// @dev Check if the ETH amount is valid.
    /// @param _assets Assets
    /// @param _value ETH amount
    function checkEthAmount(Assets memory _assets, uint256 _value)
        internal
        pure
    {
        uint256 ethAmount;

        for (uint256 i = 0; i < _assets.paymentTokens.length; ) {
            if (_assets.paymentTokens[i] == address(0))
                ethAmount += _assets.amounts[i];
            unchecked {
                ++i;
            }
        }
        if (ethAmount > _value) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }
    }

    /// @dev Check if the function is called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function itemOwnerOnly(address _owner, address _caller) internal pure {
        if (_owner != _caller) {
            revert UtilsError(UtilsErrorCodes.ONLY_OWNER);
        }
    }

    /// @dev Check if the function is not called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function notItemOwner(address _owner, address _caller) internal pure {
        if (_owner == _caller) {
            revert UtilsError(UtilsErrorCodes.OWNER_NOT_ALLOWED);
        }
    }

    /* ===== Get Functions ===== */

    /// @dev Get the hash of data saved in position token.
    /// @param _listingAssets Listing assets
    /// @param _reserveInfo Reserve ino
    /// @param _listingOwner Listing owner
    /// @return hash Hash of the passed data
    function getPostitionTokenDataHash(
        Assets calldata _listingAssets,
        ReserveInfo calldata _reserveInfo,
        address _listingOwner
    ) internal pure returns (bytes32 hash) {
        hash = addAssets(_listingAssets, hash);

        hash = keccak256(
            abi.encodePacked(getReserveHash(_reserveInfo), _listingOwner, hash)
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /* ===== Get Owner Of Signatures ===== */

    /// @dev Get the signature owner from listing data info and its signature.
    /// @param _listing Listing info
    /// @param _signature Listing signature
    /// @return owner Listing signature owner
    function getListingSignatureOwner(
        Listing calldata _listing,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getListingHash(_listing);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from the swap offer info and its signature.
    /// @param _offer Swap offer info
    /// @param _signature Swap offer signature
    /// @return owner Swap offer signature owner
    function getSwapOfferSignatureOwner(
        SwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getSwapOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from collection offer info and its signature.
    /// @param _offer Collection offer info
    /// @param _signature Collection offer signature
    /// @return owner Collection offer signature owner
    function getCollectionSwapOfferOwner(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getCollectionSwapOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from reserve offer info and its signature.
    /// @param _offer Reserve offer info
    /// @param _signature Reserve offer signature
    /// @return owner Reserve offer signature owner
    function getReserveOfferSignatureOwner(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getReserveOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    function getCollectionReserveOfferOwner(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getCollectionReserveOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from loan offer info and its signature.
    /// @param _loanOffer Loan offer info
    /// @param _signature Loan offer signature
    /// @return owner Signature owner
    function getLoanOfferOwer(
        LoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.nftCollateralContract,
                _loanOffer.nftCollateralId,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.loanPaymentToken,
                _loanOffer.loanPrincipalAmount,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.adminFees,
                _loanOffer.isLoanProrated,
                _loanOffer.isBorrowerTerms
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from collection loan offer info and its signature.
    /// @param _loanOffer Collection loan offer info
    /// @param _signature Collection loan offer signature
    /// @return owner Signature owner
    function getCollectionLoanOwner(
        CollectionLoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.nftCollateralContract,
                _loanOffer.nftCollateralIdRoot,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.loanPaymentToken,
                _loanOffer.loanPrincipalAmount,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.adminFees,
                _loanOffer.isLoanProrated
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from update loan offer info and its signature.
    /// @param _loanOffer Update loan offer info
    /// @param _signature Update loan offer signature
    /// @return owner Signature owner
    function getUpdateLoanOfferOwner(
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.loanId,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.isLoanProrated,
                _loanOffer.isBorrowerTerms
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /* ===== Get Hash ===== */

    /// @dev Get the hash of listing info.
    /// @param _listing Listing info
    /// @return hash Hash of the listing info
    function getListingHash(Listing calldata _listing)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;
        uint256 i;

        signature = addAssets(_listing.listingAssets, signature);

        unchecked {
            for (i = 0; i < _listing.directSwaps.length; i++) {
                signature = addSwapAssets(_listing.directSwaps[i], signature);
            }

            for (i = 0; i < _listing.reserves.length; i++) {
                signature = addAssets(_listing.reserves[i].deposit, signature);
                signature = addAssets(
                    _listing.reserves[i].remaining,
                    signature
                );
                signature = keccak256(
                    abi.encodePacked(_listing.reserves[i].duration, signature)
                );
            }
        }

        signature = addRoyalty(_listing.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _listing.tradeIntendedFor,
                _listing.timePeriod,
                _listing.owner,
                _listing.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of the swap offer info.
    /// @param _offer Offer info
    /// @return hash Hash of the offer
    function getSwapOfferHash(SwapOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_offer.offeringItems, signature);

        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.considerationRoot,
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of collection offer info.
    /// @param _offer Collection offer info
    /// @return hash Hash of the collection offer info
    function getCollectionSwapOfferHash(CollectionSwapOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_offer.offeringItems, signature);

        signature = addSwapAssets(_offer.considerationItems, signature);

        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of reserve offer info.
    /// @param _offer Reserve offer info
    /// @return hash Hash of the reserve offer info
    function getReserveOfferHash(ReserveOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = getReserveHash(_offer.reserveDetails);

        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.considerationRoot,
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    function getCollectionReserveOfferHash(
        CollectionReserveOffer calldata _offer
    ) internal pure returns (bytes32) {
        bytes32 signature;
        signature = getReserveHash(_offer.reserveDetails);
        signature = addSwapAssets(_offer.considerationItems, signature);
        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of reserve info.
    /// @param _reserve Reserve info
    /// @return hash Hash of the reserve info
    function getReserveHash(ReserveInfo calldata _reserve)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_reserve.deposit, signature);

        signature = addAssets(_reserve.remaining, signature);

        signature = keccak256(abi.encodePacked(_reserve.duration, signature));

        return signature;
    }

    /// @dev Get the hash of the given pair of hashes.
    /// @param _a First hash
    /// @param _b Second hash
    function getHash(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return _a < _b ? _hash(_a, _b) : _hash(_b, _a);
    }

    /// @dev Hash two bytes32 variables efficiently using assembly
    /// @param a First bytes variable
    /// @param b Second bytes variable
    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    /// @dev Get the final signed hash by appending the prefix to params hash.
    /// @param _messageHash Hash of the params message
    /// @return hash Final signed hash
    function getSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /* ===== Verify Merkle Proof ===== */

    /// @dev Verify that the given leaf exist in the passed root and has the correct proof.
    /// @param _root Merkle root of the given criterial
    /// @param _proof Merkle proof of the given leaf and root
    /// @param _leaf Hash of the token id to be searched in the root
    /// @return bool Validation of the leaf, root and proof
    function verifyMerkleProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = _leaf;

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                computedHash = getHash(computedHash, _proof[i]);
            }
        }

        return computedHash == _root;
    }

    /* ===== Make Signature Hashes ===== */

    /// @dev Add the hash of type assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addAssets(Assets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = addNFTsArray(_assets.tokens, _assets.tokenIds, _sig);
        _sig = addFTsArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of type swap assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addSwapAssets(SwapAssets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = addSwapNFTsArray(_assets.tokens, _assets.roots, _sig);
        _sig = addFTsArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of type royalty to signature.
    /// @param _royalty Royalty struct
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addRoyalty(Royalty calldata _royalty, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        unchecked {
            for (uint256 i = 0; i < _royalty.to.length; i++) {
                _sig = keccak256(
                    abi.encodePacked(
                        _royalty.to[i],
                        _royalty.percentage[i],
                        _sig
                    )
                );
            }
            return _sig;
        }
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _tokenIds Array of NFT tokenIds to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addNFTsArray(
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_tokenIds)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_tokenIds, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Add the hash of FT information to signature.
    /// @param _paymentTokens Array of FT address to be hashed
    /// @param _amounts Array of FT amounts to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addFTsArray(
        address[] memory _paymentTokens,
        uint256[] memory _amounts,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_paymentTokens)
            if eq(eq(len, mload(_amounts)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_paymentTokens, 0x20)
            let idPtr := add(_amounts, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)
                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _roots Array of valid tokenId's merkle root to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addSwapNFTsArray(
        address[] memory _tokens,
        bytes32[] memory _roots,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_roots)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_roots, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev Royalties for collection creators and platform fee for platform manager.
///      to[0] is platform owner address.
/// @param to Creators and platform manager address array
/// @param percentage Royalty percentage based on the listed FT
struct Royalty {
    address[] to;
    uint256[] percentage;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param tokens NFT asset address
/// @param tokenIds NFT token id
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct Assets {
    address[] tokens;
    uint256[] tokenIds;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common SwapAssets type, packing Bundle of NFTs and FTs. Notice tokenIds is a 2d array.
///      Each collection address ie. tokens[i] will have an array tokenIds[i] corrosponding to it.
///      This is used to select particular tokenId in corrospoding collection. If tokenIds[i]
///      is empty, this means the entire collection is considered valid.
/// @param tokens NFT asset address
/// @param roots Merkle roots of the criterias. NOTE: bytes32(0) represents the entire collection
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct SwapAssets {
    address[] tokens;
    bytes32[] roots;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common Reserve type, packing data related to reserve listing and reserve offer.
/// @param deposit Assets considered as initial deposit
/// @param remaining Assets considered as due amount
/// @param duration Duration of reserve now swap later
struct ReserveInfo {
    Assets deposit;
    Assets remaining;
    uint256 duration;
}

/// @dev All the reservation details that are stored in the position token
/// @param reservedAssets Assets that were reserved as a part of the reservation
/// @param reservedAssestsRoyalty Royalty offered by the assets owner
/// @param reserveInfo Deposit, remainig and time duriation details of the reservation
/// @param assetOwner Original owner of the reserved assets
struct Reservation {
    Assets reservedAssets;
    Royalty reservedAssetsRoyalty;
    ReserveInfo reserveInfo;
    address assetOwner;
}

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param royalty Listing royalty and platform fee info
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
    Royalty royalty;
    address tradeIntendedFor;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Listing type of special NF3 banner listing
/// @param token address of collection
/// @param tokenId token id being listed
/// @param editions number of tokenIds being distributed
/// @param gateCollectionsRoot merkle root for eligible collections
/// @param timePeriod timePeriod of listing
/// @param owner owner of listing
struct NF3GatedListing {
    address token;
    uint256 tokenId;
    uint256 editions;
    bytes32 gatedCollectionsRoot;
    uint256 timePeriod;
    address owner;
}

/// @dev Swap Offer type info.
/// @param offeringItems Assets being offered
/// @param royalty Swap offer royalty info
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    Royalty royalty;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationRoot Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    bytes32 considerationRoot;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Collection offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionSwapOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection Reserve type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionReserveOffer {
    ReserveInfo reserveDetails;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

enum Status {
    AVAILABLE,
    EXHAUSTED
}

enum AssetType {
    INVALID,
    ETH,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev Common loan offer struct to be used both the borrower and lender
///      to propose new offers,
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId NFT collateral token id
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanOffer {
    address nftCollateralContract;
    uint256 nftCollateralId;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Collection loan offer struct to be used to making collection
///      specific offers and trait level offers.
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralIdRoot Merkle root of the tokenIds for collateral
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
struct CollectionLoanOffer {
    address nftCollateralContract;
    bytes32 nftCollateralIdRoot;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

/// @dev Update loan offer struct to propose new terms for an ongoing loan.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanUpdateOffer {
    uint256 loanId;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    address owner;
    uint256 nonce;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Main loan struct that stores the details of an ongoing loan.
///      This struct is used to create hashes and store them in promissory tokens.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId TokenId of the NFT collateral
/// @param loanPaymentToken Address of the ERC20 token involved
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanStartTime Timestamp of when the loan started
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest Rate of the loan
/// @param isLoanProrated Flag for interest rate type of loan
struct Loan {
    uint256 loanId;
    address nftCollateralContract;
    uint256 nftCollateralId;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanStartTime;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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