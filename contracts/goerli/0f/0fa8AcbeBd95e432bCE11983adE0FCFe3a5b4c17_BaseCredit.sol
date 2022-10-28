// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./CollateralListings.sol";
import "./CollateralOffers.sol";
import "./BaseLoans.sol";
import "../whitelist/CollateralWhitelist.sol";
import "../whitelist/LoanCurrencyWhitelist.sol";
import "../wrapper/CollateralWrapper.sol";
import "../wrapper/LoanCurrencyWrapper.sol";
import "../utils/TermData.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @title BaseCredit
 * @author
 * @notice
 */
contract BaseCredit is
    Pausable,
    Ownable,
    ERC721Holder,
    ERC1155Holder,
    TermData,
    CollateralWhitelist,
    LoanCurrencyWhitelist,
    CollateralWrapper,
    LoanCurrencyWrapper,
    CollateralListings,
    CollateralOffers,
    BaseLoans
{
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */
    uint256 public constant MAX_DURATION = 366;

    bool private INITIALIZED = false;

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    // collateral address checker
    modifier whenNotZeroCollateralAddress(address _collateralAddress) {
        require(
            _collateralAddress != address(0),
            "Collateral address must not be zero address"
        );
        _;
    }

    modifier whenCollateralWhitelisted(address _collateralAddress) {
        require(
            _isCollateralWhitelisted(_collateralAddress),
            "Collateral is not whitelisted"
        );
        _;
    }

    modifier whenCollateralNotWhitelisted(address _collateralAddress) {
        require(
            !_isCollateralWhitelisted(_collateralAddress),
            "Collateral already whitelisted"
        );
        _;
    }

    // loan currency address checker
    modifier whenNotZeroLoanCurrencyAddress(address _loanCurrencyAddress) {
        require(
            _loanCurrencyAddress != address(0),
            "LoanCurrency address must not be zero address"
        );
        _;
    }

    modifier whenLoanCurrencyWhitelisted(address _loanCurrencyAddress) {
        require(
            _isLoanCurrencyWhitelisted(_loanCurrencyAddress),
            "LoanCurrency is not whitelisted"
        );
        _;
    }

    modifier whenLoanCurrencyNotWhitelisted(address _loanCurrencyAddress) {
        require(
            !_isLoanCurrencyWhitelisted(_loanCurrencyAddress),
            "LoanCurrency already whitelisted"
        );
        _;
    }

    // OfferTerm Duration checker
    modifier whenDurationIsOK(uint256 _duration) {
        require(
            _duration <= MAX_DURATION,
            "Duration must be less than MAX_DURATION"
        );
        _;
    }

    // Collateral Owner checker
    modifier onlyCollateralOwner(
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType
    ) {
        require(
            _haveNFTOwnership(
                _collateralAddress,
                _collateralId,
                _collateralType
            ),
            "Caller is not the owner"
        );
        _;
    }

    modifier onlyIsNotCollateralOwner(
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType
    ) {
        require(
            !_haveNFTOwnership(
                _collateralAddress,
                _collateralId,
                _collateralType
            ),
            "Caller is the owner"
        );
        _;
    }

    // approval checker
    modifier whenCollateralApproved(
        address _collateralAddress,
        CollateralType _collateralType
    ) {
        require(
            _getNFTApproved(_collateralAddress, _collateralType),
            "Collateral is not approved"
        );
        _;
    }

    modifier whenLoanCurrencyApproved(
        address _loanCurrencyAddress,
        address _lender,
        uint256 _principalAmount
    ) {
        require(
            _getFTApproved(_loanCurrencyAddress, _lender, _principalAmount),
            "LoanCurrency is not approved"
        );
        _;
    }

    // collateral listings checker
    modifier whenCollateralListed(
        address _collateralAddress,
        uint256 _collateralId
    ) {
        require(
            !_isLoanLoaned(_collateralAddress, _collateralId),
            "Collateral is loaned"
        );
        require(
            _isLoanListed(_collateralAddress, _collateralId),
            "Collateral is not listed"
        );
        _;
    }

    modifier whenCollateralUnlisted(
        address _collateralAddress,
        uint256 _collateralId
    ) {
        require(
            !_isLoanLoaned(_collateralAddress, _collateralId),
            "Collateral is loaned"
        );
        require(
            !_isLoanListed(_collateralAddress, _collateralId),
            "Collateral is already listed"
        );
        _;
    }

    modifier whenCollateralLoaned(
        address _collateralAddress,
        uint256 _collateralId
    ) {
        require(
            _isLoanLoaned(_collateralAddress, _collateralId),
            "Collateral is loaned"
        );
        _;
    }

    // collateral offers modifiers
    modifier whenOfferRequested(
        address _collateralAddress,
        uint256 _collateralId,
        address _lender
    ) {
        require(
            _isOfferRequested(_collateralAddress, _collateralId, _lender),
            "Offer is not requested"
        );
        _;
    }

    modifier whenOfferNotRequested(
        address _collateralAddress,
        uint256 _collateralId,
        address _lender
    ) {
        require(
            !_isOfferRequested(_collateralAddress, _collateralId, _lender),
            "Offer is already requested"
        );
        _;
    }

    // accept offer checker
    modifier whenNotZeroLenderAddress(address _lender) {
        require(
            _lender != address(0),
            "Lender address must not be zero address"
        );
        _;
    }

    modifier whenOfferTermIsSame(
        OfferTerm calldata _offer1,
        OfferTerm storage _offer2
    ) {
        require(
            _offer1.collateralType == _offer2.collateralType &&
                _offer1.principalAmount == _offer2.principalAmount &&
                _offer1.duration == _offer2.duration &&
                _offer1.annualPercentageRate == _offer2.annualPercentageRate &&
                _offer1.loanCurrencyAddress == _offer2.loanCurrencyAddress &&
                _offer1.offerType == _offer2.offerType,
            "Requested Offer Term is not correct"
        );
        _;
    }

    modifier whenHaveEnoughFund(
        address _loanCurrencyAddress,
        address _owner,
        uint256 _amount
    ) {
        require(
            _getFTBalance(_loanCurrencyAddress, _owner) >= _amount,
            "Don't have enough fund"
        );
        _;
    }

    modifier whenBorrowerIsCorrect(
        address _collateralAddress,
        uint256 _collateralId
    ) {
        require(
            msg.sender ==
                collateralLoans[_collateralAddress][_collateralId].borrower,
            "Caller is not borrower"
        );
        _;
    }

    modifier whenLenderIsCorrect(
        address _collateralAddress,
        uint256 _collateralId
    ) {
        require(
            msg.sender ==
                collateralLoans[_collateralAddress][_collateralId].lender,
            "Caller is not lender"
        );
        _;
    }

    modifier whenLoanIsOverdue(
        address _collateralAddress,
        uint256 _collateralId
    ) {
        require(
            block.timestamp >=
                collateralLoans[_collateralAddress][_collateralId].startTime +
                    collateralLoans[_collateralAddress][_collateralId]
                        .offer
                        .duration *
                    1 minutes,
            "Loan is not overdue"
        );
        _;
    }

    modifier whenLoanIsNotOverdue(
        address _collateralAddress,
        uint256 _collateralId
    ) {
        require(
            block.timestamp <
                collateralLoans[_collateralAddress][_collateralId].startTime +
                    collateralLoans[_collateralAddress][_collateralId]
                        .offer
                        .duration *
                    1 days,
            "Loan is overdue"
        );
        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function initialize() external {
        require(!INITIALIZED, "Contract is already initialized");
        _transferOwnership(msg.sender);
        INITIALIZED = true;
    }

    // Collateral Whitelist external functions
    function whitelistCollateral(
        address _collateralAddress,
        string calldata _name
    ) external {
        _checkCanWhitelistCollateral(_collateralAddress);
        _whitelistCollateral(_collateralAddress, _name);
    }

    function unwhitelistCollateral(address _collateralAddress) external {
        _checkCanUnwhitelistCollateral(_collateralAddress);
        _unwhitelistCollateral(_collateralAddress);
    }

    // LoanCurrency Whitelist external functions
    function whitelistLoanCurrency(
        address _loanCurrencyAddress,
        string calldata _name
    ) external {
        _checkCanWhitelistLoanCurrency(_loanCurrencyAddress);
        _whitelistLoanCurrency(_loanCurrencyAddress, _name);
    }

    function unwhitelistLoanCurrency(address _loanCurrencyAddress) external {
        _checkCanUnwhitelistLoanCurrency(_loanCurrencyAddress);
        _unwhitelistLoanCurrency(_loanCurrencyAddress);
    }

    function listCollateral(OfferTerm calldata _offer) external {
        _checkCanListCollateral(_offer);

        _listCollateral(_offer);
    }

    function unlistCollateral(
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType
    ) external {
        _checkCanUnlistCollateral(
            _collateralAddress,
            _collateralId,
            _collateralType
        );

        _unlistCollateral(_collateralAddress, _collateralId);
        _removeAllRequestedOffers(_collateralAddress, _collateralId);
    }

    function updateCollateralOfferTerm(OfferTerm calldata _offer) external {
        _checkCanUpdateCollateralOfferTerm(_offer);

        _updateCollateralOfferTerm(_offer);
    }

    // Collateral Offers external functions
    function requestOffer(OfferTerm calldata _offer) external {
        _checkCanRequestOffer(_offer);

        _requestOffer(_offer);
    }

    function cancelOffer(address _collateralAddress, uint256 _collateralId)
        external
    {
        _checkCanCancelOffer(_collateralAddress, _collateralId);

        _cancelOffer(_collateralAddress, _collateralId);
    }

    function updateRequestedOfferTerm(OfferTerm calldata _offer) external {
        _checkCanUpdateRequestedOfferTerm(_offer);

        _updateRequestedOfferTerm(_offer);
    }

    // Loans external functions
    function acceptOffer(OfferTerm calldata _offer, address _lender) external {
        _checkCanAcceptOffer(_offer, _lender);
        _safeNFTTransferFrom(
            _offer.collateralAddress,
            _offer.collateralId,
            _offer.collateralType,
            msg.sender,
            address(this)
        );
        _safeFTTransferFrom(
            _offer.loanCurrencyAddress,
            _lender,
            msg.sender,
            _offer.principalAmount
        );
        _startLoanListedCollateral(
            _offer.collateralAddress,
            _offer.collateralId
        );
        _removeAllRequestedOffers(
            _offer.collateralAddress,
            _offer.collateralId
        );
        _addNewLoan(LoanTerm(_offer, msg.sender, _lender, block.timestamp));
    }

    function repayLoan(address _collateralAddress, uint256 _collateralId)
        external
    {
        _checkCanRepayLoan(_collateralAddress, _collateralId);
        _safeNFTTransferFrom(
            _collateralAddress,
            _collateralId,
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .collateralType,
            address(this),
            msg.sender
        );
        _safeFTTransferFrom(
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .loanCurrencyAddress,
            msg.sender,
            collateralLoans[_collateralAddress][_collateralId].lender,
            _calculateRepayAmount(_collateralAddress, _collateralId)
        );
        _safeFTTransferFrom(
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .loanCurrencyAddress,
            msg.sender,
            address(this),
            _calculateCreditFeeAmount(_collateralAddress, _collateralId)
        );
        _endLoanListedCollateral(_collateralAddress, _collateralId);
        _removeLoan(_collateralAddress, _collateralId);
    }

    function breachLoan(address _collateralAddress, uint256 _collateralId)
        external
    {
        _checkCanBreachLoan(_collateralAddress, _collateralId);
        _safeNFTTransferFrom(
            _collateralAddress,
            _collateralId,
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .collateralType,
            address(this),
            msg.sender
        );
        _endLoanListedCollateral(_collateralAddress, _collateralId);
        _removeLoan(_collateralAddress, _collateralId);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    // Collateral Listings external functions
    function _checkCanWhitelistCollateral(address _collateralAddress)
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        onlyOwner
        whenCollateralNotWhitelisted(_collateralAddress)
    {}

    function _checkCanUnwhitelistCollateral(address _collateralAddress)
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        onlyOwner
        whenCollateralWhitelisted(_collateralAddress)
    {}

    // LoanCurrency Whitelist external functions
    function _checkCanWhitelistLoanCurrency(address _loanCurrencyAddress)
        internal
        whenNotZeroLoanCurrencyAddress(_loanCurrencyAddress)
        onlyOwner
        whenLoanCurrencyNotWhitelisted(_loanCurrencyAddress)
    {}

    function _checkCanUnwhitelistLoanCurrency(address _loanCurrencyAddress)
        internal
        whenNotZeroLoanCurrencyAddress(_loanCurrencyAddress)
        onlyOwner
        whenLoanCurrencyWhitelisted(_loanCurrencyAddress)
    {}

    function _checkCanListCollateral(OfferTerm calldata _offer)
        internal
        whenNotZeroCollateralAddress(_offer.collateralAddress)
        whenCollateralWhitelisted(_offer.collateralAddress)
        whenNotZeroLoanCurrencyAddress(_offer.loanCurrencyAddress)
        whenLoanCurrencyWhitelisted(_offer.loanCurrencyAddress)
        whenDurationIsOK(_offer.duration)
        onlyCollateralOwner(
            _offer.collateralAddress,
            _offer.collateralId,
            _offer.collateralType
        )
        whenCollateralApproved(_offer.collateralAddress, _offer.collateralType)
        whenCollateralUnlisted(_offer.collateralAddress, _offer.collateralId)
    {}

    function _checkCanUnlistCollateral(
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType
    )
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        onlyCollateralOwner(_collateralAddress, _collateralId, _collateralType)
        whenCollateralListed(_collateralAddress, _collateralId)
    {}

    function _checkCanUpdateCollateralOfferTerm(OfferTerm calldata _offer)
        internal
        whenNotZeroCollateralAddress(_offer.collateralAddress)
        whenNotZeroLoanCurrencyAddress(_offer.loanCurrencyAddress)
        whenLoanCurrencyWhitelisted(_offer.loanCurrencyAddress)
        whenDurationIsOK(_offer.duration)
        onlyCollateralOwner(
            _offer.collateralAddress,
            _offer.collateralId,
            _offer.collateralType
        )
        whenCollateralListed(_offer.collateralAddress, _offer.collateralId)
    {}

    function _checkCanRequestOffer(OfferTerm calldata _offer)
        internal
        whenNotZeroCollateralAddress(_offer.collateralAddress)
        whenNotZeroLoanCurrencyAddress(_offer.loanCurrencyAddress)
        whenDurationIsOK(_offer.duration)
        whenCollateralWhitelisted(_offer.collateralAddress)
        whenLoanCurrencyWhitelisted(_offer.loanCurrencyAddress)
        whenCollateralListed(_offer.collateralAddress, _offer.collateralId)
        onlyIsNotCollateralOwner(
            _offer.collateralAddress,
            _offer.collateralId,
            _offer.collateralType
        )
        whenLoanCurrencyApproved(
            _offer.loanCurrencyAddress,
            msg.sender,
            _offer.principalAmount
        )
        whenOfferNotRequested(
            _offer.collateralAddress,
            _offer.collateralId,
            msg.sender
        )
    {}

    function _checkCanCancelOffer(
        address _collateralAddress,
        uint256 _collateralId
    )
        internal
        whenNotZeroCollateralAddress(_collateralAddress)
        whenOfferRequested(_collateralAddress, _collateralId, msg.sender)
    {}

    function _checkCanUpdateRequestedOfferTerm(OfferTerm calldata _offer)
        internal
        whenNotZeroCollateralAddress(_offer.collateralAddress)
        whenCollateralListed(_offer.collateralAddress, _offer.collateralId)
        whenDurationIsOK(_offer.duration)
        whenNotZeroLoanCurrencyAddress(_offer.loanCurrencyAddress)
        whenLoanCurrencyWhitelisted(_offer.loanCurrencyAddress)
        whenLoanCurrencyApproved(
            _offer.loanCurrencyAddress,
            msg.sender,
            _offer.principalAmount
        )
        whenOfferRequested(
            _offer.collateralAddress,
            _offer.collateralId,
            msg.sender
        )
    {}

    function _checkCanAcceptOffer(OfferTerm calldata _offer, address _lender)
        internal
        whenNotZeroLenderAddress(_lender)
        whenCollateralListed(_offer.collateralAddress, _offer.collateralId)
        onlyCollateralOwner(
            _offer.collateralAddress,
            _offer.collateralId,
            _offer.collateralType
        )
        whenOfferRequested(
            _offer.collateralAddress,
            _offer.collateralId,
            _lender
        )
        whenOfferTermIsSame(
            _offer,
            requestedOfferTerms[_offer.collateralAddress][_offer.collateralId][
                requestedOffersVersion[_offer.collateralAddress][
                    _offer.collateralId
                ]
            ][_lender].offer
        )
        whenHaveEnoughFund(
            _offer.loanCurrencyAddress,
            _lender,
            _offer.principalAmount
        )
    {}

    function _checkCanRepayLoan(
        address _collateralAddress,
        uint256 _collateralId
    )
        internal
        whenBorrowerIsCorrect(_collateralAddress, _collateralId)
        whenLoanIsNotOverdue(_collateralAddress, _collateralId)
        whenCollateralLoaned(_collateralAddress, _collateralId)
        whenLoanCurrencyApproved(
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .loanCurrencyAddress,
            msg.sender,
            _calculateRepayAmount(_collateralAddress, _collateralId)
        )
        whenHaveEnoughFund(
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .loanCurrencyAddress,
            msg.sender,
            _calculateRepayAmount(_collateralAddress, _collateralId)
        )
    {}

    function _checkCanBreachLoan(
        address _collateralAddress,
        uint256 _collateralId
    )
        internal
        whenCollateralLoaned(_collateralAddress, _collateralId)
        whenLoanIsOverdue(_collateralAddress, _collateralId)
        whenLenderIsCorrect(_collateralAddress, _collateralId)
    {}

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../utils/TermData.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title CollateralListings
 * @author
 * @notice
 */
contract CollateralListings is TermData {
    using Address for address;

    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    mapping(address => mapping(uint256 => ListedCollateralTerm))
        public listedCollateralTerms;

    /* *********** */
    /* EVENTS */
    /* *********** */

    /**
     * @notice This event is fired whenever a borrower listed a collateral by calling listCollateral(), which can only
     * be occured that the msg.sender is borrower, the NFT owner.
     *
     * @param  borrower - The address of the borrower.
     * @param  collateralAddress - The address of the NFT collateral.
     * @param  collateralId - The token id of the NFT collateral.
     * @param  offer - OfferTerm that decided by Borrower.
     */
    event CollateralListed(
        address indexed borrower,
        address indexed collateralAddress,
        uint256 indexed collateralId,
        OfferTerm offer
    );

    /**
     * @notice This event is fired whenever a borrower listed a collateral by calling unlistCollateral(), which can only
     * be occured that the msg.sender is borrower, the NFT owner.
     *
     * @param  borrower - The address of the borrower.
     * @param  collateralAddress - The address of the NFT collateral.
     * @param  collateralId - The token id of the NFT collateral.
     */
    event CollateralUnlisted(
        address indexed borrower,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    /**
     * @notice This event is fired whenever a borrower listed a collateral by calling updateCollateralOfferTerm(), which can only
     * be occured that the msg.sender is borrower, the NFT owner.
     *
     * @param  borrower - The address of the borrower.
     * @param  collateralAddress - The address of the NFT collateral.
     * @param  collateralId - The token id of the NFT collateral.
     * @param  offer - OfferTerm that decided by Borrower.
     */
    event ListedCollateralTermUpdated(
        address indexed borrower,
        address indexed collateralAddress,
        uint256 indexed collateralId,
        OfferTerm offer
    );

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    function _listCollateral(OfferTerm calldata _offer) internal {
        listedCollateralTerms[_offer.collateralAddress][
            _offer.collateralId
        ] = ListedCollateralTerm(
            _offer,
            msg.sender,
            ListedCollateralStatus.LISTED
        );

        emit CollateralListed(
            msg.sender,
            _offer.collateralAddress,
            _offer.collateralId,
            _offer
        );
    }

    function _unlistCollateral(
        address _collateralAddress,
        uint256 _collateralId
    ) internal {
        delete listedCollateralTerms[_collateralAddress][_collateralId];

        emit CollateralUnlisted(msg.sender, _collateralAddress, _collateralId);
    }

    function _updateCollateralOfferTerm(OfferTerm calldata _offer) internal {
        listedCollateralTerms[_offer.collateralAddress][_offer.collateralId]
            .offer = _offer;

        emit ListedCollateralTermUpdated(
            msg.sender,
            _offer.collateralAddress,
            _offer.collateralId,
            _offer
        );
    }

    function _startLoanListedCollateral(
        address _collateralAddress,
        uint256 _collateralId
    ) internal {
        listedCollateralTerms[_collateralAddress][_collateralId]
            .status = ListedCollateralStatus.LOANED;
    }

    function _endLoanListedCollateral(
        address _collateralAddress,
        uint256 _collateralId
    ) internal {
        delete listedCollateralTerms[_collateralAddress][_collateralId];
    }

    function _isLoanListed(address _collateralAddress, uint256 _collateralId)
        internal
        view
        returns (bool)
    {
        return
            listedCollateralTerms[_collateralAddress][_collateralId].borrower !=
            address(0);
    }

    function _isLoanLoaned(address _collateralAddress, uint256 _collateralId)
        internal
        view
        returns (bool)
    {
        return
            listedCollateralTerms[_collateralAddress][_collateralId].status ==
            ListedCollateralStatus.LOANED;
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../utils/TermData.sol";

/**
 * @title BaseLoans
 * @author
 * @notice
 */
contract BaseLoans is TermData {
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    mapping(address => mapping(uint256 => LoanTerm)) public collateralLoans;

    uint256 public constant HUNDRED_PERCENT = 10000;

    uint256 public USER_INTEREST_PERCENTAGE = 9600;

    /* *********** */
    /* EVENTS */
    /* *********** */

    event LoanStarted(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerm loan
    );

    event LoanRepaid(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerm loan,
        uint256 loanRepaidTime
    );

    event LoanBreached(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerm loan,
        uint256 loanBreachedTime
    );

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    function _addNewLoan(LoanTerm memory _loan) internal {
        collateralLoans[_loan.offer.collateralAddress][
            _loan.offer.collateralId
        ] = _loan;
    }

    function _removeLoan(address _collateralAddress, uint256 _collateralId)
        internal
    {
        delete collateralLoans[_collateralAddress][_collateralId];
    }

    function _calculateRepayAmount(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view returns (uint256) {
        if (
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .offerType == OfferType.FIXED
        ) {
            uint256 principalAmount = collateralLoans[_collateralAddress][
                _collateralId
            ].offer.principalAmount;
            uint256 annualPercentageRate = collateralLoans[_collateralAddress][
                _collateralId
            ].offer.annualPercentageRate;
            uint256 duration = collateralLoans[_collateralAddress][
                _collateralId
            ].offer.duration;
            return
                (principalAmount *
                    annualPercentageRate *
                    duration *
                    USER_INTEREST_PERCENTAGE) /
                HUNDRED_PERCENT /
                HUNDRED_PERCENT /
                366 +
                principalAmount;
        }
        return
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .principalAmount;
    }

    function _calculateCreditFeeAmount(
        address _collateralAddress,
        uint256 _collateralId
    ) internal view returns (uint256) {
        if (
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .offerType == OfferType.FIXED
        ) {
            uint256 principalAmount = collateralLoans[_collateralAddress][
                _collateralId
            ].offer.principalAmount;
            uint256 annualPercentageRate = collateralLoans[_collateralAddress][
                _collateralId
            ].offer.annualPercentageRate;
            uint256 duration = collateralLoans[_collateralAddress][
                _collateralId
            ].offer.duration;
            return
                ((principalAmount * annualPercentageRate * duration) *
                    (HUNDRED_PERCENT - USER_INTEREST_PERCENTAGE)) /
                HUNDRED_PERCENT /
                HUNDRED_PERCENT /
                366;
        }
        return
            collateralLoans[_collateralAddress][_collateralId]
                .offer
                .principalAmount;
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title LoanCurrencyWrapper
 * @author
 * @notice
 */
contract LoanCurrencyWrapper {
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function _safeFTTransferFrom(
        address _loanCurrencyAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20 loanCurrency = IERC20(_loanCurrencyAddress);
        loanCurrency.transferFrom(_from, _to, _amount);
    }

    function _getFTApproved(
        address _loanCurrencyAddress,
        address _owner,
        uint256 _amount
    ) internal view returns (bool) {
        IERC20 loanCurrency = IERC20(_loanCurrencyAddress);
        return _amount <= loanCurrency.allowance(_owner, address(this));
    }

    function _getFTBalance(address _loanCurrencyAddress, address _owner)
        internal
        view
        returns (uint256)
    {
        IERC20 loanCurrency = IERC20(_loanCurrencyAddress);
        return loanCurrency.balanceOf(_owner);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../utils/TermData.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title CollateralOffers
 * @author
 * @notice
 */
contract CollateralOffers is TermData {
    using Address for address;

    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    /** */
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(address => RequestedOfferTerm))))
        public requestedOfferTerms;

    mapping(address => mapping(uint256 => uint256))
        public requestedOffersVersion;

    /* *********** */
    /* EVENTS */
    /* *********** */

    event OfferRequested(
        address indexed lender,
        address indexed collateralAddress,
        uint256 indexed collateralId,
        OfferTerm offer
    );

    event OfferCanceled(
        address indexed lender,
        address indexed collateralAddress,
        uint256 indexed collateralId
    );

    event RequestedOfferTermUpdated(
        address indexed lender,
        address indexed collateralAddress,
        uint256 indexed collateralId,
        OfferTerm offer
    );

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    function _requestOffer(OfferTerm calldata _offer) internal {
        requestedOfferTerms[_offer.collateralAddress][_offer.collateralId][
            requestedOffersVersion[_offer.collateralAddress][
                _offer.collateralId
            ]
        ][msg.sender] = RequestedOfferTerm(_offer, msg.sender);

        emit OfferRequested(
            msg.sender,
            _offer.collateralAddress,
            _offer.collateralId,
            _offer
        );
    }

    function _cancelOffer(address _collateralAddress, uint256 _collateralId)
        internal
    {
        delete requestedOfferTerms[_collateralAddress][_collateralId][
            requestedOffersVersion[_collateralAddress][_collateralId]
        ][msg.sender];

        emit OfferCanceled(msg.sender, _collateralAddress, _collateralId);
    }

    function _updateRequestedOfferTerm(OfferTerm calldata _offer) internal {
        requestedOfferTerms[_offer.collateralAddress][_offer.collateralId][
            requestedOffersVersion[_offer.collateralAddress][
                _offer.collateralId
            ]
        ][msg.sender].offer = _offer;

        emit RequestedOfferTermUpdated(
            msg.sender,
            _offer.collateralAddress,
            _offer.collateralId,
            _offer
        );
    }

    function _removeAllRequestedOffers(
        address _collateralAddress,
        uint256 _collateralId
    ) internal {
        requestedOffersVersion[_collateralAddress][_collateralId] += 1;
    }

    function _isOfferRequested(
        address _collateralAddress,
        uint256 _collateralId,
        address _lender
    ) internal view returns (bool) {
        return
            requestedOfferTerms[_collateralAddress][_collateralId][
                requestedOffersVersion[_collateralAddress][_collateralId]
            ][_lender].lender != address(0);
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../utils/TermData.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "erc721a/contracts/IERC721A.sol";

/**
 * @title CollateralWrapper
 * @author
 * @notice
 */
contract CollateralWrapper is TermData {
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function _safeNFTTransferFrom(
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType,
        address _from,
        address _to
    ) internal {
        if (_collateralType == CollateralType.ERC721) {
            IERC721 collateralWrapper = IERC721(_collateralAddress);
            collateralWrapper.safeTransferFrom(_from, _to, _collateralId);
        } else if (_collateralType == CollateralType.ERC721A) {
            IERC721A collateralWrapper = IERC721A(_collateralAddress);
            collateralWrapper.safeTransferFrom(_from, _to, _collateralId);
        } else if (_collateralType == CollateralType.ERC1155) {
            IERC1155 collateralWrapper = IERC1155(_collateralAddress);
            uint256 amount = collateralWrapper.balanceOf(_from, _collateralId);
            return
                collateralWrapper.safeTransferFrom(
                    _from,
                    _to,
                    _collateralId,
                    amount,
                    ""
                );
        }
    }

    function _getNFTApproved(
        address _collateralAddress,
        CollateralType _collateralType
    ) internal view returns (bool) {
        if (_collateralType == CollateralType.ERC721) {
            IERC721 collateralWrapper = IERC721(_collateralAddress);
            return
                collateralWrapper.isApprovedForAll(msg.sender, address(this));
        } else if (_collateralType == CollateralType.ERC721A) {
            IERC721A collateralWrapper = IERC721A(_collateralAddress);
            return
                collateralWrapper.isApprovedForAll(msg.sender, address(this));
        } else if (_collateralType == CollateralType.ERC1155) {
            IERC1155 collateralWrapper = IERC1155(_collateralAddress);
            return
                collateralWrapper.isApprovedForAll(msg.sender, address(this));
        }
        return false;
    }

    function _haveNFTOwnership(
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType
    ) internal view returns (bool) {
        if (_collateralType == CollateralType.ERC721) {
            IERC721 collateralWrapper = IERC721(_collateralAddress);
            return msg.sender == collateralWrapper.ownerOf(_collateralId);
        } else if (_collateralType == CollateralType.ERC721A) {
            IERC721A collateralWrapper = IERC721A(_collateralAddress);
            return msg.sender == collateralWrapper.ownerOf(_collateralId);
        } else if (_collateralType == CollateralType.ERC1155) {
            IERC1155 collateralWrapper = IERC1155(_collateralAddress);
            return collateralWrapper.balanceOf(msg.sender, _collateralId) > 0;
        }
        return false;
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**
 * @title  TermData
 * @author Solarr
 * @notice An interface containg the main Loan struct shared by Direct Loans types.
 */
interface TermData {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    enum CollateralType {
        ERC721,
        ERC721A,
        ERC1155,
        ERC998,
        ERC1190
    }

    enum ListedCollateralStatus {
        LISTED,
        LOANED
    }

    enum OfferType {
        FIXED
    }

    /* ******* */
    /* STORAGE */
    /* ******* */

    /**
     * @notice The offer made by the lender. Used as parameter on both acceptOffer (initiated by the borrower) and
     * acceptListing (initiated by the lender).
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param loanPrincipalAmount - The original sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param repaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     *  collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always
     * have to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the ERC721 contract of the NFT collateral.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param loanDuration - The amount of time (measured in seconds) that can elapse before the lender can liquidate
     * the loan and seize the underlying collateral NFT.
     */
    struct OfferTerm {
        address collateralAddress;
        uint256 collateralId;
        CollateralType collateralType;
        uint256 principalAmount;
        uint256 duration;
        uint256 annualPercentageRate;
        address loanCurrencyAddress;
        OfferType offerType;
    }

    struct CollateralIndicator {
        address collateralAddress;
        uint256 collateralId;
    }

    /**
     * @notice The main Loan Terms struct. This data is saved upon loan creation.
     *
     * @param offer - Term that used to create a Loan.
     * @param loanStartTime - The block.timestamp when the loan first began (measured in seconds).
     * @param borrower
     * @param lender
     */
    struct ListedCollateralTerm {
        OfferTerm offer;
        address borrower;
        ListedCollateralStatus status;
    }

    /**
     * @notice The main Loan Terms struct. This data is saved upon loan creation.
     *
     * @param offer - Term that used to create a Loan.
     * @param loanStartTime - The block.timestamp when the loan first began (measured in seconds).
     * @param borrower
     * @param lender
     */
    struct RequestedOfferTerm {
        OfferTerm offer;
        address lender;
    }

    /**
     * @notice The main Loan Terms struct. This data is saved upon loan creation.
     *
     * @param offer - Term that used to create a Loan.
     * @param loanStartTime - The block.timestamp when the loan first began (measured in seconds).
     * @param borrower
     * @param lender
     */
    struct LoanTerm {
        OfferTerm offer;
        address borrower;
        address lender;
        uint256 startTime;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title  CollateralWhitelist
 * @author Solarr
 * @notice
 */
contract CollateralWhitelist {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @param collateralAddress - The address of the smart contract of the Collateral.
     * @param name - The name the nft Collateral.
     * @param activeDate - The date that the Collateral is listed.
     */
    struct Collateral {
        address collateralAddress;
        string name;
        uint256 activeDate;
    }

    mapping(address => Collateral) public whitelistedCollaterals; // Collaterals information that have been added to whitelist

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /**
     * @notice This event is fired whenever the Collateral is listed to Whitelist.
     */
    event CollateralWhitelisted(address, string, uint256);

    /**
     * @notice This event is fired whenever the Collateral is unlisted from Whitelist.
     */
    event CollateralUnwhitelisted(address, string, uint256);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @dev Constructor
     */
    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /**
     * @notice This function can be called by Owner to list Collateral to Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     * @param _name - The name of the Collateral.
     */
    function _whitelistCollateral(
        address _collateralAddress,
        string calldata _name
    ) internal {
        // create Collateral instance and list to whitelist
        whitelistedCollaterals[_collateralAddress] = Collateral(
            _collateralAddress,
            _name,
            block.timestamp
        );

        emit CollateralWhitelisted(_collateralAddress, _name, block.timestamp);
    }

    /**
     * @notice This function can be called by Owner to unlist Collateral from Whitelist.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     */
    function _unwhitelistCollateral(address _collateralAddress) internal {
        // remove Collateral instance and unlist from whitelist
        Collateral memory collateral = whitelistedCollaterals[
            _collateralAddress
        ];
        string memory name = collateral.name;
        delete whitelistedCollaterals[_collateralAddress];

        emit CollateralUnwhitelisted(_collateralAddress, name, block.timestamp);
    }

    /**
     * @notice This function can be called by Anyone to know the Collateral is listed in Whitelist or not.
     *
     * @param _collateralAddress - The address of the Collateral contract.
     *
     * @return Returns whether the Collateral is whitelisted
     */
    function _isCollateralWhitelisted(address _collateralAddress)
        internal
        view
        returns (bool)
    {
        return
            whitelistedCollaterals[_collateralAddress].collateralAddress !=
            address(0);
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  LoanCurrencyWhitelist
 * @author Solarr
 * @notice
 */
contract LoanCurrencyWhitelist is Ownable {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @param loanCurrencyAddress - The address of the smart contract of the LoanCurrency.
     * @param name - The name the nft LoanCurrency.
     * @param activeDate - The date that the LoanCurrency is listed.
     */
    struct LoanCurrency {
        address loanCurrencyAddress;
        string name;
        uint256 activeDate;
    }

    mapping(address => LoanCurrency) public whitelistedLoanCurrencys; // LoanCurrencys information that have been added to whitelist

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /**
     * @notice This event is fired whenever the LoanCurrency is listed to Whitelist.
     */
    event LoanCurrencyListed(address, string, uint256);

    /**
     * @notice This event is fired whenever the LoanCurrency is unlisted from Whitelist.
     */
    event LoanCurrencyUnlisted(address, string, uint256);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @dev Constructor
     */
    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /**
     * @notice This function can be called by Owner to list LoanCurrency to Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     * @param _name - The name of the LoanCurrency.
     */
    function _whitelistLoanCurrency(
        address _loanCurrencyAddress,
        string calldata _name
    ) internal {
        // create LoanCurrency instance and list to whitelist
        whitelistedLoanCurrencys[_loanCurrencyAddress] = LoanCurrency(
            _loanCurrencyAddress,
            _name,
            block.timestamp
        );

        emit LoanCurrencyListed(_loanCurrencyAddress, _name, block.timestamp);
    }

    /**
     * @notice This function can be called by Owner to unlist LoanCurrency from Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     */
    function _unwhitelistLoanCurrency(address _loanCurrencyAddress) internal {
        // remove LoanCurrency instance and unlist from whitelist
        LoanCurrency memory loanCurrency = whitelistedLoanCurrencys[
            _loanCurrencyAddress
        ];
        string memory name = loanCurrency.name;
        delete whitelistedLoanCurrencys[_loanCurrencyAddress];

        emit LoanCurrencyUnlisted(_loanCurrencyAddress, name, block.timestamp);
    }

    /**
     * @notice This function can be called by Anyone to know the LoanCurrency is listed in Whitelist or not.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     *
     * @return Returns whether the LoanCurrency is whitelisted
     */
    function _isLoanCurrencyWhitelisted(address _loanCurrencyAddress)
        internal
        view
        returns (bool)
    {
        return
            whitelistedLoanCurrencys[_loanCurrencyAddress]
                .loanCurrencyAddress != address(0);
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}