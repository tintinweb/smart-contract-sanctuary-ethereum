// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Auth.sol";
import "./Parameters.sol";
import "./Assets.sol";


contract BorrowModule is IVersioned, Auth, ReentrancyGuard {
    using Parameters for IParametersStorage;
    using Assets for address;
    using EnumerableSet for EnumerableSet.UintSet;

    string public constant VERSION = '0.1.0';

    enum LoanState { WasNotCreated, AuctionStarted, AuctionCancelled, Issued, Finished, Liquidated }

    struct AuctionInfo {
        address borrower;
        uint32 startTS;
        uint16 interestRateMin;
        uint16 interestRateMax;
    }

    struct Loan {
        // slot 256 bits (Nested struct takes up the whole slot. We have to do this since error "Stack too deep..")
        AuctionInfo auctionInfo;

        // slot 240 bits
        LoanState state;
        uint16 durationDays;
        uint32 startTS;
        uint16 interestRate;
        address collateral;
        Assets.AssetType collateralType;

        // slot 256 bits
        uint collateralIdOrAmount;

        // slot 160 bits
        address lender;

        // slot 160 bits
        address debtCurrency;

        // slot 256 bits
        uint debtAmount;
    }

    struct AuctionStartParams {
        uint16 durationDays;

        uint16 interestRateMin;
        uint16 interestRateMax;

        address collateral;
        Assets.AssetType collateralType;
        uint collateralIdOrAmount;

        address debtCurrency;
        uint debtAmount;
    }

    event AuctionStarted(uint indexed loanId, address indexed borrower);
    event AuctionInterestRateMaxUpdated(uint indexed loanId, address indexed borrower, uint16 newInterestRateMax);
    event AuctionCancelled(uint indexed loanId, address indexed borrower);

    event LoanIssued(uint indexed loanId, address indexed lender);
    event LoanRepaid(uint indexed loanId, address indexed borrower);
    event LoanLiquidated(uint indexed loanId, address indexed liquidator);

    uint public constant BASIS_POINTS_IN_1 = 1e4;
    uint public constant MAX_DURATION_DAYS = 365 * 2;

    Loan[] public loans;
    mapping(address => uint[]) public loanIdsByUser;
    EnumerableSet.UintSet private activeAuctions;
    EnumerableSet.UintSet private activeLoans;

    constructor(address _parametersStorage) Auth(_parametersStorage) {}

    function startAuction(AuctionStartParams memory _params) external nonReentrant returns (uint _loanId) {
        require(0 < _params.durationDays &&_params.durationDays <= MAX_DURATION_DAYS, 'UP borrow module: INVALID_LOAN_DURATION');
        require(0 < _params.interestRateMin && _params.interestRateMin <= _params.interestRateMax, 'UP borrow module: INVALID_INTEREST_RATE');
        require(_params.collateral != address(0), 'UP borrow module: INVALID_COLLATERAL');
        require(_params.collateralType != Assets.AssetType.Unknown, 'UP borrow module: INVALID_COLLATERAL_TYPE');
        require(_params.collateralType == Assets.AssetType.ERC721 || _params.collateralIdOrAmount > 0, 'UP borrow module: INVALID_COLLATERAL_AMOUNT');
        require(_params.debtCurrency != address(0) && _params.debtAmount > 0, 'UP borrow module: INVALID_DEBT_CURRENCY');
        _calcTotalDebt(_params.debtAmount, _params.interestRateMax, _params.durationDays); // just check that there is no overflow on total debt

        _loanId = loans.length;
        loans.push(
            Loan(
                AuctionInfo(
                    msg.sender,
                    uint32(block.timestamp),
                    _params.interestRateMin,
                    _params.interestRateMax
                ),

                LoanState.AuctionStarted,
                _params.durationDays,
                0, // startTS
                0, // interestRate
                _params.collateral,
                _params.collateralType,

                _params.collateralIdOrAmount,

                address(0),

                _params.debtCurrency,

                _params.debtAmount
            )
        );

        loanIdsByUser[msg.sender].push(_loanId);
        require(activeAuctions.add(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        _params.collateral.getFrom(_params.collateralType, msg.sender, address(this), _params.collateralIdOrAmount);

        emit AuctionStarted(_loanId, msg.sender);
    }

    function updateAuctionInterestRateMax(uint _loanId, uint16 _newInterestRateMax) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);
        require(loan.auctionInfo.borrower == msg.sender, 'UP borrow module: AUTH_FAILED');
        require(loan.state == LoanState.AuctionStarted, 'UP borrow module: INVALID_LOAN_STATE');
        require(loan.auctionInfo.startTS + parameters.getAuctionDuration() <= block.timestamp, 'UP borrow module: TOO_EARLY_UPDATE');
        require(_newInterestRateMax > loan.auctionInfo.interestRateMax, 'UP borrow module: NEW_RATE_TOO_SMALL');

        loan.auctionInfo.interestRateMax = _newInterestRateMax;

        emit AuctionInterestRateMaxUpdated(_loanId, msg.sender, _newInterestRateMax);
    }

    function cancelAuction(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);
        require(loan.auctionInfo.borrower == msg.sender, 'UP borrow module: AUTH_FAILED');

        changeLoanState(loan, LoanState.AuctionCancelled);
        require(activeAuctions.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        loan.collateral.sendTo(loan.collateralType, loan.auctionInfo.borrower, loan.collateralIdOrAmount);

        emit AuctionCancelled(_loanId, msg.sender);
    }

    /**
     * @dev acceptance after auction ended is allowed
     */
    function accept(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);

        require(loan.auctionInfo.borrower != msg.sender, 'UP borrow module: OWN_AUCTION');

        changeLoanState(loan, LoanState.Issued);
        require(activeAuctions.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');
        require(activeLoans.add(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        loan.startTS = uint32(block.timestamp);
        loan.lender = msg.sender;
        loan.interestRate =  _calcCurrentInterestRate(loan.auctionInfo.startTS, loan.auctionInfo.interestRateMin, loan.auctionInfo.interestRateMax);

        loanIdsByUser[msg.sender].push(_loanId);

        (uint feeAmount, uint operatorFeeAmount, uint amountWithoutFee) = _calcFeeAmount(loan.debtCurrency, loan.debtAmount);

        loan.debtCurrency.getFrom(Assets.AssetType.ERC20, msg.sender, address(this), loan.debtAmount);
        if (feeAmount > 0) {
            loan.debtCurrency.sendTo(Assets.AssetType.ERC20, parameters.treasury(), feeAmount);
        }
        if (operatorFeeAmount > 0) {
            loan.debtCurrency.sendTo(Assets.AssetType.ERC20, parameters.operatorTreasury(), operatorFeeAmount);
        }
        loan.debtCurrency.sendTo(Assets.AssetType.ERC20, loan.auctionInfo.borrower, amountWithoutFee);

        emit LoanIssued(_loanId, msg.sender);
    }

    /**
     * @notice Repay loan debt. In any time debt + full interest rate for loan period must be repaid.
     * MUST be repaid before loan period end to avoid liquidations. MAY be repaid after loan period end, but before liquidation.
     */
    function repay(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);
        require(loan.auctionInfo.borrower == msg.sender, 'UP borrow module: AUTH_FAILED');

        changeLoanState(loan, LoanState.Finished);
        require(activeLoans.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        uint totalDebt = _calcTotalDebt(loan.debtAmount, loan.interestRate, loan.durationDays);
        loan.debtCurrency.getFrom(Assets.AssetType.ERC20, msg.sender, loan.lender, totalDebt);
        loan.collateral.sendTo(loan.collateralType, loan.auctionInfo.borrower, loan.collateralIdOrAmount);

        emit LoanRepaid(_loanId, msg.sender);
    }

    function liquidate(uint _loanId) external nonReentrant {
        Loan storage loan = requireLoan(_loanId);

        changeLoanState(loan, LoanState.Liquidated);
        require(uint(loan.startTS) + uint(loan.durationDays) * 1 days < block.timestamp, 'UP borrow module: LOAN_IS_ACTIVE');
        require(activeLoans.remove(_loanId), 'UP borrow module: BROKEN_STRUCTURE');

        loan.collateral.sendTo(loan.collateralType, loan.lender, loan.collateralIdOrAmount);

        emit LoanLiquidated(_loanId, msg.sender);
    }

    function requireLoan(uint _loanId) internal view returns (Loan storage _loan) {
        require(_loanId < loans.length, 'UP borrow module: INVALID_LOAN_ID');
        _loan = loans[_loanId];
    }

    function changeLoanState(Loan storage _loan, LoanState _newState) internal {
        LoanState currentState = _loan.state;
        if (currentState == LoanState.AuctionStarted) {
            require(_newState == LoanState.AuctionCancelled || _newState == LoanState.Issued, 'UP borrow module: INVALID_LOAN_STATE');
        } else if (currentState == LoanState.Issued) {
            require(_newState == LoanState.Finished || _newState == LoanState.Liquidated, 'UP borrow module: INVALID_LOAN_STATE');
        } else if (currentState == LoanState.AuctionCancelled || currentState == LoanState.Finished || currentState == LoanState.Liquidated) {
            revert('UP borrow module: INVALID_LOAN_STATE');
        } else {
            revert('UP borrow module: BROKEN_LOGIC'); // just to be sure that all states are covered
        }

        _loan.state = _newState;
    }

    //////

    function getLoansCount() external view returns (uint) {
        return loans.length;
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getLoans() external view returns(Loan[] memory) {
        return loans;
    }

    /**
     * @dev returns empty array with offset >= count
     */
    function getLoansLimited(uint _offset, uint _limit) external view returns(Loan[] memory _loans) {
        uint loansCount = loans.length;
        if (_offset > loansCount) {
            return new Loan[](0);
        }

        uint resultCount = Math.min(loansCount - _offset, _limit);
        _loans = new Loan[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            _loans[i] = loans[_offset + i];
        }
    }

    //////

    function getActiveAuctionsCount() public view returns (uint) {
        return activeAuctions.length();
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getActiveAuctions() public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIds(activeAuctions);
    }

    /**
     * @dev returns empty arrays with offset >= count
     */
    function getActiveAuctionsLimited(uint _offset, uint _limit) public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIdsLimited(activeAuctions, _offset, _limit);
    }

    //////

    function getActiveLoansCount() public view returns (uint) {
        return activeLoans.length();
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getActiveLoans() public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIds(activeLoans);
    }

    /**
     * @dev returns empty arrays with offset >= count
     */
    function getActiveLoansLimited(uint _offset, uint _limit) public view returns (uint[] memory _ids, Loan[] memory _loans) {
        return _getLoansWithIdsLimited(activeLoans, _offset, _limit);
    }

    //////

    function getUserLoansCount(address _user) public view returns (uint) {
        return loanIdsByUser[_user].length;
    }

    /**
     * @dev may not work on huge amount of loans, in this case use version with limits
     */
    function getUserLoans(address _user) external view returns(uint[] memory _ids, Loan[] memory _loans) {
        _ids = loanIdsByUser[_user];
        _loans = new Loan[](_ids.length);
        for (uint i=0; i<_ids.length; i++) {
            _loans[i] = loans[ _ids[i] ];
        }
    }

    /**
     * @dev returns empty arrays with offset >= count
     */
    function getUserLoansLimited(address _user, uint _offset, uint _limit) public view returns (uint[] memory _ids, Loan[] memory _loans) {
        uint loansCount = loanIdsByUser[_user].length;
        if (_offset > loansCount) {
            return (new uint[](0), new Loan[](0));
        }

        uint resultCount = Math.min(loansCount - _offset, _limit);
        _ids = new uint[](resultCount);
        _loans = new Loan[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            _ids[i] = loanIdsByUser[_user][_offset + i];
            _loans[i] = loans[ _ids[i] ];
        }
    }


    //////

    function _calcFeeAmount(address _asset, uint _amount) internal view returns (uint _feeAmount, uint _operatorFeeAmount, uint _amountWithoutFee) {
        uint feeBasisPoints = parameters.getAssetFee(_asset);
        uint _totalFeeAmount = _amount * feeBasisPoints / BASIS_POINTS_IN_1;

        _operatorFeeAmount = _totalFeeAmount * parameters.operatorFeePercent() / 100;
        _feeAmount = _totalFeeAmount - _operatorFeeAmount;

        _amountWithoutFee = _amount - _totalFeeAmount;

        require(_amount == _feeAmount + _operatorFeeAmount + _amountWithoutFee, 'UP borrow module: BROKEN_FEE_LOGIC'); // assert
    }

    function _calcTotalDebt(uint debtAmount, uint interestRateBasisPoints, uint durationDays) internal pure returns (uint) {
        return debtAmount + debtAmount * interestRateBasisPoints * durationDays / BASIS_POINTS_IN_1 / 365;
    }

    function _calcCurrentInterestRate(uint auctionStartTS, uint16 interestRateMin, uint16 interestRateMax) internal view returns (uint16) {
        require(auctionStartTS < block.timestamp, 'UP borrow module: TOO_EARLY');
        require(0 < interestRateMin && interestRateMin <= interestRateMax, 'UP borrow module: INVALID_INTEREST_RATES'); // assert

        uint auctionEndTs = auctionStartTS + parameters.getAuctionDuration();
        uint onTime = Math.min(block.timestamp, auctionEndTs);

        return interestRateMin + uint16((interestRateMax - interestRateMin) * (onTime - auctionStartTS) / (auctionEndTs - auctionStartTS));
    }

    //////

    function _getLoansWithIds(EnumerableSet.UintSet storage _loansSet) internal view returns (uint[] memory _ids, Loan[] memory _loans) {
        _ids = _loansSet.values();
        _loans = new Loan[](_ids.length);
        for (uint i=0; i<_ids.length; i++) {
            _loans[i] = loans[ _ids[i] ];
        }
    }

    function _getLoansWithIdsLimited(EnumerableSet.UintSet storage _loansSet, uint _offset, uint _limit) internal view returns (uint[] memory _ids, Loan[] memory _loans) {
        uint loansCount = _loansSet.length();
        if (_offset > loansCount) {
            return (new uint[](0), new Loan[](0));
        }

        uint resultCount = Math.min(loansCount - _offset, _limit);
        _ids = new uint[](resultCount);
        _loans = new Loan[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            _ids[i] = _loansSet.at(_offset + i);
            _loans[i] = loans[ _ids[i] ];
        }
    }

    //////

    function onERC721Received(
        address operator,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external view returns (bytes4) {
        require(operator == address(this), "UP borrow module: TRANSFER_NOT_ALLOWED");

        return IERC721Receiver.onERC721Received.selector;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;

import "./interfaces/IParametersStorage.sol";


contract Auth {

    // address of the the contract with parameters
    IParametersStorage public immutable parameters;

    constructor(address _parameters) {
        require(_parameters != address(0), "UP borrow module: ZERO_ADDRESS");

        parameters = IParametersStorage(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(parameters.isManager(msg.sender), "UP borrow module: AUTH_FAILED");
        _;
    }
}

// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;

import "./interfaces/IParametersStorage.sol";


/**
 * @dev After new parameter is introduced new lib Parameters(n+1) inherited from Parameters(n) must be created
 * @dev Then use Parameters(n+1) for IParametersStorage
 */
library Parameters {

    /// @dev auction duration in seconds
    uint public constant PARAM_AUCTION_DURATION = 0;

    function getAuctionDuration(IParametersStorage _storage) internal view returns (uint _auctionDurationSeconds) {
        _auctionDurationSeconds = uint(_storage.customParams(PARAM_AUCTION_DURATION));
        require(_auctionDurationSeconds > 0);
    }
}

// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";


library Assets {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    enum AssetType {Unknown, ERC20, ERC721}

    function getFrom(address _assetAddr, AssetType _assetType, address _from, address _to, uint _idOrAmount) internal {
        if (_assetType == AssetType.ERC20) {
            require(!_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC20(_assetAddr).safeTransferFrom(_from, _to, _idOrAmount);
        } else if (_assetType == AssetType.ERC721) {
            require(_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC721(_assetAddr).safeTransferFrom(_from, _to, _idOrAmount);
        } else {
            revert("UP borrow module: UNSUPPORTED_ASSET_TYPE");
        }
    }

    function sendTo(address _assetAddr, AssetType _assetType, address _to, uint _idOrAmount) internal {
        if (_assetType == AssetType.ERC20) {
            require(!_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC20(_assetAddr).safeTransfer(_to, _idOrAmount);
        } else if (_assetType == AssetType.ERC721) {
            require(_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC721(_assetAddr).safeTransferFrom(address(this), _to, _idOrAmount);
        } else {
            revert("UP borrow module: UNSUPPORTED_ASSET_TYPE");
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

// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IVersioned.sol";


interface IParametersStorage is IVersioned {

    struct CustomFee {
        bool enabled; // is custom fee for asset enabled
        uint16 feeBasisPoints; // fee basis points, 1 basis point = 0.0001
    }

    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);
    event TreasuryChanged(address newTreasury);
    event OperatorTreasuryChanged(address newOperatorTreasury);
    event BaseFeeChanged(uint newFeeBasisPoints);
    event AssetCustomFeeEnabled(address indexed _asset, uint16 _feeBasisPoints);
    event AssetCustomFeeDisabled(address indexed _asset);
    event OperatorFeeChanged(uint newOperatorFeePercent);
    event CustomParamChanged(uint indexed param, bytes32 value);
    event AssetCustomParamChanged(address indexed asset, uint indexed param, bytes32 value);

    function isManager(address) external view returns (bool);

    function treasury() external view returns (address);
    function operatorTreasury() external view returns (address);

    function baseFeeBasisPoints() external view returns (uint);
    function assetCustomFee(address) external view returns (bool _enabled, uint16 _feeBasisPoints);
    function operatorFeePercent() external view returns (uint);

    function getAssetFee(address _asset) external view returns (uint _feeBasisPoints);

    function customParams(uint _param) external view returns (bytes32);
    function assetCustomParams(address _asset, uint _param) external view returns (bytes32);

    function setManager(address _who, bool _permit) external;
    function setTreasury(address _treasury) external;
    function setOperatorTreasury(address _operatorTreasury) external;

    function setBaseFee(uint _feeBasisPoints) external;
    function setAssetCustomFee(address _asset, bool _enabled, uint16 _feeBasisPoints) external;
    function setOperatorFee(uint _feeBasisPoints) external;

    function setCustomParam(uint _param, bytes32 _value) external;
    function setCustomParamAsUint(uint _param, uint _value) external;
    function setCustomParamAsAddress(uint _param, address _value) external;

    function setAssetCustomParam(address _asset, uint _param, bytes32 _value) external;
    function setAssetCustomParamAsUint(address _asset, uint _param, uint _value) external;
    function setAssetCustomParamAsAddress(address _asset, uint _param, address _value) external;
}

// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;

/// @title Contract supporting versioning using SemVer version scheme.
interface IVersioned {
    /// @notice Contract version, using SemVer version scheme.
    function VERSION() external view returns (string memory);
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