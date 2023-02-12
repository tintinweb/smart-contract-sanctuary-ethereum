//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract nftescrow is IERC721Receiver {
    enum LoanState {
        nftDeposited,
        ethDeposited,
        ethWithdrawn,
        payed,
        nftReturned,
        lastInstallmentWithdrawn,
        finished,
        canceled
    }

    using Counters for Counters.Counter;
    Counters.Counter private _loanIds;
    Counters.Counter private _offerIds;

    event LoanCreated(uint256 _loanId, address _borrowerAddress);
    event LoanStarted(
        uint256 _loanId,
        address _borrowerAddress,
        address _lenderAddress,
        uint256 _loanAmount
    );
    event LoanDepositWithdrawn(
        uint256 _loanId,
        address _borrowerAddress,
        address _lenderAddress,
        uint256 _ethWithdrawn
    );
    event InstallmentPayed(
        uint256 _loanId,
        address _borrowerAddress,
        address _lenderAddress,
        uint256 _ethPayed,
        uint256 _installmentPayed
    );
    event OfferDepositWithdrawn(
        uint256 _loanId,
        uint256 _offerId,
        address _offererAddress,
        uint256 _offerWithdrawn
    );
    event LoanOfferCreated(uint256 _loanId, address _borrowerAddress);
    event LoanOfferAccepted(uint256 _loanId, address _lenderAddress);

    struct Loan {
        uint256 loanId;
        uint256 tokenId;
        uint256 loanAmount;
        uint256 rateAmount;
        uint256 ethDeposit;
        uint256 maxTimestampInitialDespositWithrawal;
        address nftAddress;
        address payable borrowerAddress;
        address payable lenderAddress;
        InstallmentData installments;
        LoanState loanState;
    }

    struct InstallmentData {
        uint256 installments;
        uint256 installmentsEthDeposit;
        uint256 maxTimestampNextPayment;
        uint256 payedInstallments;
    }

    struct Offer {
        uint256 offerId;
        address payable offerer;
        uint256 loanAmount;
        uint256 rateAmount;
        uint256 installments;
        uint256 offerDeposit;
        uint256 deleted;
    }

    mapping(uint256 => Loan) private loans;
    mapping(uint256 => Offer[]) offers; //Va de loanId a Offer
    uint private DAYS_TO_WITHDRAW_INITIAL_DEPOSIT = 3;

    constructor() {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function _calculateInstallmentAmountToPay(
        uint _loanId
    ) public view returns (uint256) {
        return
            (loans[_loanId].loanAmount +
                ((loans[_loanId].loanAmount *
                    (loans[_loanId].rateAmount / 100)) / 10 ** decimals())) /
            loans[_loanId].installments.installments;
    }

    function createLoan(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _loanAmount,
        uint256 _rateAmount,
        uint256 _installments
    ) external {
        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        _loanIds.increment();
        uint256 loanId = _loanIds.current();
        loans[loanId] = Loan({
            loanId: loanId,
            tokenId: _tokenId,
            loanAmount: _loanAmount,
            rateAmount: _rateAmount,
            ethDeposit: 0,
            maxTimestampInitialDespositWithrawal: 0,
            nftAddress: _nftAddress,
            borrowerAddress: payable(msg.sender),
            lenderAddress: payable(address(0)),
            installments: InstallmentData(_installments, 0, 0, 0),
            loanState: LoanState.nftDeposited
        });
        emit LoanCreated(loanId, msg.sender);
    }

    function makeOffer(
        uint256 _loanId,
        uint256 _loanAmount,
        uint256 _rateAmount,
        uint256 _installments
    ) external payable {
        require(
            loans[_loanId].loanState == LoanState.nftDeposited,
            "ERR_1"
        );
        require(
            loans[_loanId].borrowerAddress != msg.sender,
            "ERR_2"
        );
        require(
            _loanAmount == msg.value,
            "ERR_3"
        );
        bool alreadyOfferer = isOfferer(_loanId, msg.sender);
        require(
            !alreadyOfferer,
            "ERR_4"
        );
        _offerIds.increment();
        uint256 offerId = _offerIds.current();
        offers[_loanId].push(
            Offer({
                offerId: offerId,
                offerer: payable(msg.sender),
                loanAmount: _loanAmount,
                rateAmount: _rateAmount,
                installments: _installments,
                offerDeposit: msg.value,
                deleted: 0
            })
        );
        emit LoanOfferCreated(_loanId, loans[_loanId].borrowerAddress);
    }

    function deleteOffer(
        uint256 _loanId,
        uint256 _offerId
    ) external payable onlyOfferer(_loanId, _offerId) {
        require(
            loans[_loanId].loanState == LoanState.nftDeposited,
            "ERR_5"
        );
        Offer memory offerToDelete = getLoanOffer(_loanId, _offerId);
        // TODO: REALLY??
        require(!(offerToDelete.deleted == 1), "ERR_6");
        Offer[] storage loanOffers = offers[_loanId];

        for (uint i = 0; i < loanOffers.length; i++) {
            if (loanOffers[i].offerId == _offerId) {
                loanOffers[i].deleted = 1;
            }
        }
        _transferDeletedOfferDeposit(_loanId, _offerId);
    }

    function _transferDeletedOfferDeposit(
        uint256 _loanId,
        uint _offerId
    ) private {
        Offer[] memory loanOffers = offers[_loanId];
        for (uint i = 0; i < loanOffers.length; i++) {
            if (
                loanOffers[i].deleted == 1 && loanOffers[i].offerId == _offerId
            ) {
                loanOffers[i].offerer.transfer(offers[_loanId][i].offerDeposit);
                offers[_loanId][i].deleted = 1;
                emit OfferDepositWithdrawn(
                    _loanId,
                    _offerId,
                    loanOffers[i].offerer,
                    offers[_loanId][i].offerDeposit
                );
                offers[_loanId][i].offerDeposit = 0;
            }
        }
    }

    function acceptOffer(
        uint256 _loanId,
        uint256 _offerId
    ) external payable onlyBorrower(_loanId) {
        Offer memory offer = getLoanOffer(_loanId, _offerId);
        require(
            loans[_loanId].loanState == LoanState.nftDeposited,
            "ERR_7"
        );
        require(offer.deleted == 0, "ERR_8");
        Offer[] storage loanOffers = offers[_loanId];

        for (uint i = 0; i < loanOffers.length; i++) {
            if (loanOffers[i].offerId == _offerId) {
                loans[_loanId].lenderAddress = loanOffers[i].offerer;
                loans[_loanId].loanAmount = loanOffers[i].loanAmount;
                loans[_loanId].rateAmount = loanOffers[i].rateAmount;
                loans[_loanId].installments.installments = loanOffers[i]
                    .installments;
                loans[_loanId].ethDeposit = loanOffers[i].offerDeposit;
                loans[_loanId].installments.maxTimestampNextPayment =
                    block.timestamp +
                    30 days;
                loanOffers[i].offerDeposit = 0;
                _transferInitialEthDeposit(_loanId);
            }
        }
        _transferOffersDeposit(_loanId);
        emit LoanOfferAccepted(_loanId, loans[_loanId].lenderAddress);
    }

    function _transferOffersDeposit(uint256 _loanId) private {
        Offer[] memory loanOffers = offers[_loanId];
        for (uint i = 0; i < loanOffers.length; i++) {
            if (loanOffers[i].deleted == 0) {
                if (loanOffers[i].offerer != loans[_loanId].lenderAddress) {
                    loanOffers[i].offerer.transfer(
                        offers[_loanId][i].offerDeposit
                    );
                    emit OfferDepositWithdrawn(
                        _loanId,
                        loanOffers[i].offerId,
                        loanOffers[i].offerer,
                        offers[_loanId][i].offerDeposit
                    );
                    offers[_loanId][i].offerDeposit = 0;
                    offers[_loanId][i].deleted = 1;
                } else if (
                    loanOffers[i].offerer == loans[_loanId].lenderAddress
                ) {
                    loans[_loanId].borrowerAddress.transfer(
                        offers[_loanId][i].offerDeposit
                    );
                    emit OfferDepositWithdrawn(
                        _loanId,
                        loanOffers[i].offerId,
                        loans[_loanId].borrowerAddress,
                        offers[_loanId][i].offerDeposit
                    );
                    offers[_loanId][i].offerDeposit = 0;
                }
            }
        }
    }

    function _transferInitialEthDeposit(uint256 _loanId) private {
        loans[_loanId].borrowerAddress.transfer(loans[_loanId].ethDeposit);
        loans[_loanId].loanState = LoanState.ethWithdrawn;
        emit LoanDepositWithdrawn(
            _loanId,
            loans[_loanId].borrowerAddress,
            loans[_loanId].lenderAddress,
            loans[_loanId].ethDeposit
        );
        loans[_loanId].ethDeposit = 0;
    }

    function depositETH(uint256 _loanId) external payable {
        require(loans[_loanId].loanState == LoanState.nftDeposited);
        require(
            loans[_loanId].borrowerAddress != msg.sender,
            "ERR_9"
        );
        require(loans[_loanId].loanAmount == msg.value);
        bool alreadyOfferer = isOfferer(_loanId, msg.sender);
        require(
            !alreadyOfferer,
            "ERR_10"
        );
        loans[_loanId].lenderAddress = payable(msg.sender);
        loans[_loanId].ethDeposit = msg.value;
        loans[_loanId].installments.maxTimestampNextPayment =
            block.timestamp +
            30 days;
        loans[_loanId].maxTimestampInitialDespositWithrawal =
            block.timestamp +
            3 days;
        loans[_loanId].loanState = LoanState.ethDeposited;
        _transferOffersDeposit(_loanId);
        emit LoanStarted(
            _loanId,
            loans[_loanId].borrowerAddress,
            msg.sender,
            msg.value
        );
    }

    function withdrawInitialEthDeposit(
        uint256 _loanId
    ) public onlyBorrower(_loanId) {
        require(
            loans[_loanId].maxTimestampInitialDespositWithrawal >=
                block.timestamp,
            "ERR_11"
        );
        require(loans[_loanId].loanState == LoanState.ethDeposited);
        _transferInitialEthDeposit(_loanId);
    }

    function payInstallment(
        uint256 _loanId
    ) external payable onlyBorrower(_loanId) {
        require(loans[_loanId].loanState == LoanState.ethWithdrawn);
        require(checkLastPayment(_loanId), "ERR_12");
        require(
            loans[_loanId].installments.payedInstallments <
                loans[_loanId].installments.installments,
            "ERR_13"
        );
        uint256 installmentAmountToPay = _calculateInstallmentAmountToPay(
            _loanId
        );
        require(
            msg.value == installmentAmountToPay,
            "ERR_14"
        );
        loans[_loanId].installments.installmentsEthDeposit += msg.value;
        loans[_loanId].installments.maxTimestampNextPayment += 30 days;
        loans[_loanId].installments.payedInstallments += 1;
        if (
            loans[_loanId].installments.payedInstallments ==
            loans[_loanId].installments.installments
        ) {
            loans[_loanId].loanState = LoanState.payed;
        }
        emit InstallmentPayed(
            _loanId,
            loans[_loanId].borrowerAddress,
            loans[_loanId].lenderAddress,
            msg.value,
            loans[_loanId].installments.payedInstallments
        );
    }

    function withdrawInstallmentEth(
        uint256 _loanId
    ) public onlyLender(_loanId) {
        require(
            loans[_loanId].loanState == LoanState.ethWithdrawn ||
                loans[_loanId].loanState == LoanState.payed ||
                loans[_loanId].loanState == LoanState.nftReturned
        );
        payable(msg.sender).transfer(
            loans[_loanId].installments.installmentsEthDeposit
        );
        loans[_loanId].installments.installmentsEthDeposit = 0;
        if (loans[_loanId].loanState == LoanState.nftReturned) {
            loans[_loanId].loanState = LoanState.finished;
        } else if (loans[_loanId].loanState == LoanState.payed) {
            loans[_loanId].loanState = LoanState.lastInstallmentWithdrawn;
        }
    }

    function getInitialDepositBack(uint256 _loanId) public onlyLender(_loanId) {
        require(loans[_loanId].loanState == LoanState.ethDeposited);
        require(
            loans[_loanId].maxTimestampInitialDespositWithrawal <
                block.timestamp,
            "ERR_15"
        );
        payable(msg.sender).transfer(loans[_loanId].ethDeposit);
        loans[_loanId].ethDeposit = 0;
        loans[_loanId].loanState = LoanState.nftDeposited;
    }

    function executeNft(uint256 _loanId) public onlyLender(_loanId) {
        require(
            !checkLastPayment(_loanId),
            "ERR_16"
        );
        require(loans[_loanId].loanState == LoanState.ethWithdrawn);
        address nftAddress = loans[_loanId].nftAddress;
        uint256 tokenId = loans[_loanId].tokenId;
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        loans[_loanId].loanState = LoanState.canceled;
    }

    function getNftBack(uint256 _loanId) public onlyBorrower(_loanId) {
        require(
            loans[_loanId].loanState == LoanState.nftDeposited ||
                loans[_loanId].loanState == LoanState.payed ||
                loans[_loanId].loanState == LoanState.lastInstallmentWithdrawn
        );
        address nftAddress = loans[_loanId].nftAddress;
        uint256 tokenId = loans[_loanId].tokenId;
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        if (loans[_loanId].loanState == LoanState.nftDeposited) {
            loans[_loanId].loanState = LoanState.canceled;
        } else if (loans[_loanId].loanState == LoanState.payed) {
            loans[_loanId].loanState = LoanState.nftReturned;
        } else if (
            loans[_loanId].loanState == LoanState.lastInstallmentWithdrawn
        ) {
            loans[_loanId].loanState = LoanState.finished;
        }
    }

    function checkInitialDepositWithdrawal(
        uint _loanId
    ) public view returns (bool) {
        require(loans[_loanId].loanState == LoanState.ethDeposited);
        return
            loans[_loanId].maxTimestampInitialDespositWithrawal >=
            block.timestamp;
    }

    function checkLastPayment(uint256 _loanId) public view returns (bool) {
        require(loans[_loanId].loanState == LoanState.ethWithdrawn);
        return
            block.timestamp <=
            loans[_loanId].installments.maxTimestampNextPayment;
    }

    function getRemainingAmount(uint256 _loanId) public view returns (uint256) {
        require(
            loans[_loanId].loanState == LoanState.ethWithdrawn,
            "ERR_17"
        );
        return
            (loans[_loanId].installments.installments -
                loans[_loanId].installments.payedInstallments) *
            _calculateInstallmentAmountToPay(_loanId);
    }

    function getLoans(
        address _address,
        bool _isBorrower
    ) external view returns (Loan[] memory) {
        Loan[] memory loansByAddress = new Loan[](_loanIds.current());
        uint count = 0;
        for (uint i = 0; i < _loanIds.current(); i++) {
            if (
                loans[i + 1].loanState != LoanState.finished &&
                loans[i + 1].loanState != LoanState.canceled
            ) {
                if (
                    (_isBorrower &&
                        (loans[i + 1].borrowerAddress == _address)) ||
                    (!_isBorrower && (loans[i + 1].lenderAddress == _address))
                ) {
                    loansByAddress[count] = loans[i + 1];
                    count += 1;
                }
            }
        }

        Loan[] memory filteredLoans = new Loan[](count);
        for (uint i = 0; i < count; i++) {
            filteredLoans[i] = loansByAddress[i];
        }

        return filteredLoans;
    }

    function getLoansByState(
        LoanState _loanState
    ) public view returns (Loan[] memory) {
        uint itemCount = _loanIds.current();
        uint currentIndex = 0;

        Loan[] memory items = new Loan[](itemCount);

        for (uint i = 0; i < itemCount; i++) {
            if (loans[i + 1].loanState == _loanState) {
                uint currentId = i + 1;
                Loan memory currentItem = loans[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        Loan[] memory filteredLoans = new Loan[](currentIndex);
        for (uint i = 0; i < currentIndex; i++) {
            filteredLoans[i] = items[i];
        }

        return filteredLoans;
    }

    function getLoanById(uint256 _loanId) public view returns (Loan memory) {
        return loans[_loanId];
    }

    function getLoanOffer(
        uint256 _loanId,
        uint256 _offerId
    ) public view returns (Offer memory) {
        Offer[] memory loanOffers = offers[_loanId];
        Offer memory ret;

        for (uint i = 0; i < loanOffers.length; i++) {
            if (loanOffers[i].offerId == _offerId) {
                ret = loanOffers[i];
            }
        }
        return ret;
    }

    function getLoanOffers(
        uint256 _loanId,
        uint256 _deleted
    ) public view returns (Offer[] memory) {
        uint itemCount = _offerIds.current();
        uint currentIndex = 0;

        Offer[] memory items = new Offer[](itemCount);

        Offer[] memory loanOffers = offers[_loanId];

        for (uint i = 0; i < loanOffers.length; i++) {
            if (loanOffers[i].deleted == _deleted) {
                Offer memory currentItem = loanOffers[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        Offer[] memory filteredOffers = new Offer[](currentIndex);
        for (uint i = 0; i < currentIndex; i++) {
            filteredOffers[i] = items[i];
        }

        return filteredOffers;
    }

    function isOfferer(
        uint256 _loanId,
        address _offerer
    ) public view returns (bool) {
        Offer[] memory loanOffers = offers[_loanId];
        bool ret = false;

        for (uint i = 0; i < loanOffers.length; i++) {
            if (
                (loanOffers[i].deleted == 0) &&
                loanOffers[i].offerer == _offerer
            ) {
                ret = true;
            }
        }
        return ret;
    }

    modifier onlyBorrower(uint256 _loanId) {
        require(
            msg.sender == loans[_loanId].borrowerAddress,
            "ERR_18"
        );
        _;
    }

    modifier onlyLender(uint256 _loanId) {
        require(
            msg.sender == loans[_loanId].lenderAddress,
            "ERR_19"
        );
        _;
    }

    modifier onlyOfferer(uint256 _loanId, uint256 _offerId) {
        Offer memory offer = getLoanOffer(_loanId, _offerId);
        require(
            msg.sender == offer.offerer,
            "ERR_20"
        );
        _;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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