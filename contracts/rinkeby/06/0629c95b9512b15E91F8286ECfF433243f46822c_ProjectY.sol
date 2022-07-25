// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";

contract ProjectY is Context, Owned, ERC721Holder {
    using Counters for Counters.Counter;

    Counters.Counter private _entryIdTracker;
    Counters.Counter private _bidIdTracker;

    uint64 public constant ONE_MONTH = 30 days;

    uint64 public biddingPeriod = 7 days;
    uint64 public gracePeriod = 7 days;

    enum InstallmentPlan {
        None, // no installment
        ThreeMonths,
        SixMonths,
        NineMonths
    }

    struct SellerInfo {
        bool onSale;
        address sellerAddress;
        address contractAddress;
        uint8 installmentsPaid;
        uint64 timestamp;
        uint256 tokenId;
        uint256 sellingPrice;
        uint256 totalBids;
        uint256 selectedBidId;
        InstallmentPlan installment;
    }

    struct BuyerInfo {
        bool isSelected;
        address buyerAddress;
        uint64 timestamp;
        uint256 bidPrice;
        uint256 entryId;
        uint256 pricePaid; // initially equal to downpayment
        InstallmentPlan bidInstallment;
    }

    // entryId -> SellerInfo
    mapping(uint256 => SellerInfo) internal _sellerInfo;

    // bidId -> BuyerInfo
    mapping(uint256 => BuyerInfo) internal _buyerInfo;

    event Sell(
        address indexed seller,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed entryId,
        uint64 timestamp
    );

    event Bid(
        address indexed buyer,
        uint256 indexed entryId,
        uint256 indexed bidId,
        uint64 timestamp
    );

    event BidSelected(uint256 indexed bidId, uint256 indexed entryId);

    constructor(address owner_) Owned(owner_) {
        // solhint-disable-previous-line no-empty-blocks
    }

    // some additional getters for front-end start

    function getNFTsOpenForSale() public view returns (SellerInfo[] memory nftsOpenForSale_) {
        uint256 totalEntryIds_ = getTotalEntryIds();
        uint256 i_;

        for (i_ = 0; i_ < totalEntryIds_; ) {
            SellerInfo memory sellerInfo_ = _sellerInfo[i_];

            if (sellerInfo_.onSale) {
                nftsOpenForSale_[i_] = sellerInfo_;
            }

            unchecked {
                ++i_;
            }
        }
    }

    function getAllBidsOnNFT(uint256 _entryId)
        public
        view
        returns (BuyerInfo[] memory allBidsOnNFT_)
    {
        uint256 totalBidIds_ = getTotalBidIds();
        uint256 i_;

        for (i_ = 0; i_ < totalBidIds_; ) {
            if (_buyerInfo[i_].entryId == _entryId) {
                allBidsOnNFT_[i_] = _buyerInfo[i_];
            }

            unchecked {
                ++i_;
            }
        }
    }

    function getUserNFTsOpenForSale()
        public
        view
        returns (SellerInfo[] memory userNFTsOpenForSale_)
    {
        uint256 totalEntryIds_ = getTotalEntryIds();
        uint256 i_;

        for (i_ = 0; i_ < totalEntryIds_; ) {
            SellerInfo memory sellerInfo_ = _sellerInfo[i_];

            if (sellerInfo_.onSale && sellerInfo_.sellerAddress == _msgSender()) {
                userNFTsOpenForSale_[i_] = sellerInfo_;
            }

            unchecked {
                ++i_;
            }
        }
    }

    // some additional getters for front-end end

    function isEntryIdValid(uint256 entryId_) public view returns (bool isValid_) {
        require(isValid_ = (_sellerInfo[entryId_].sellerAddress != address(0)), "INVALID_ENTRY_ID");
    }

    function isBidIdValid(uint256 bidId_) public view returns (bool isValid_) {
        require(isValid_ = (_buyerInfo[bidId_].buyerAddress != address(0)), "INVALID_BID_ID");
    }

    function getSellerInfo(uint256 entryId_) public view returns (SellerInfo memory) {
        isEntryIdValid(entryId_);
        return _sellerInfo[entryId_];
    }

    function getBuyerInfo(uint256 bidId_) public view returns (BuyerInfo memory) {
        isBidIdValid(bidId_);
        return _buyerInfo[bidId_];
    }

    function getTotalEntryIds() public view returns (uint256) {
        return _entryIdTracker.current();
    }

    function getTotalBidIds() public view returns (uint256) {
        return _bidIdTracker.current();
    }

    function getDownPayment(uint256 entryId_, uint256 bidId_) public view returns (uint256) {
        isEntryIdValid(entryId_);
        isBidIdValid(bidId_);

        BuyerInfo memory buyerInfo_ = _buyerInfo[bidId_];

        require(buyerInfo_.pricePaid == 0, "DOWN_PAYMENT_DONE");

        InstallmentPlan installment_ = buyerInfo_.bidInstallment;
        uint256 bidPrice_ = buyerInfo_.bidPrice;

        if (installment_ == InstallmentPlan.ThreeMonths) {
            return (bidPrice_ * 34) / 100; // 34%
        } else if (installment_ == InstallmentPlan.SixMonths) {
            return (bidPrice_ * 175) / 1000; // 17.5%
        } else if (installment_ == InstallmentPlan.NineMonths) {
            return (bidPrice_ * 12) / 100; // 12%
        } else {
            return bidPrice_; // InstallmentPlan.None
        }
    }

    function getInstallmentPerMonth(uint256 entryId_) public view returns (uint256) {
        isEntryIdValid(entryId_);
        SellerInfo memory sellerInfo_ = _sellerInfo[entryId_];

        uint256 bidId_ = sellerInfo_.selectedBidId;
        isBidIdValid(bidId_);

        BuyerInfo memory buyerInfo_ = _buyerInfo[bidId_];

        InstallmentPlan installment_ = buyerInfo_.bidInstallment;

        if (buyerInfo_.bidPrice == buyerInfo_.pricePaid) {
            return 0;
        }

        if (installment_ == InstallmentPlan.ThreeMonths) {
            return (buyerInfo_.bidPrice * 33) / 100; // 33%
        } else if (installment_ == InstallmentPlan.SixMonths) {
            return (buyerInfo_.bidPrice * 165) / 1000; // 16.5%
        } else if (installment_ == InstallmentPlan.NineMonths) {
            return (buyerInfo_.bidPrice * 11) / 100; // 11%
        } else {
            return 0; // InstallmentPlan.None
        }
    }

    function getInstallmentPercentageOf(
        uint256 entryId_,
        uint256 bidId_,
        uint256 installmentNumber_
    ) public view returns (uint256) {
        return
            getDownPayment(entryId_, bidId_) +
            (installmentNumber_ * getInstallmentPerMonth(entryId_));
    }

    function getInstallmentPaid(uint256 entryId_, uint256 bidId_) public view returns (uint256) {
        isEntryIdValid(entryId_);
        isBidIdValid(bidId_);

        SellerInfo memory sellerInfo_ = _sellerInfo[entryId_];
        BuyerInfo memory buyerInfo_ = _buyerInfo[bidId_];

        return
            getInstallmentPercentageOf(entryId_, bidId_, sellerInfo_.installmentsPaid) *
            buyerInfo_.bidPrice;
    }

    function getInstallmentMonthTimestamp(uint256 bidId_, uint64 installmentNumber_)
        public
        view
        returns (uint64)
    {
        return _buyerInfo[bidId_].timestamp + ((installmentNumber_ - 1) * ONE_MONTH);
    }

    function sell(
        address contractAddress_,
        uint256 tokenId_,
        uint256 sellingPrice_,
        InstallmentPlan installment_
    ) public returns (uint256) {
        require(sellingPrice_ != 0, "INVALID_PRICE");

        uint64 blockTimestamp_ = uint64(block.timestamp);

        // create unique entryId
        _entryIdTracker.increment();
        uint256 entryId_ = _entryIdTracker.current();

        // transfer NFT to this contract
        IERC721(contractAddress_).safeTransferFrom(_msgSender(), address(this), tokenId_);

        // update mapping
        _sellerInfo[entryId_].onSale = true;
        _sellerInfo[entryId_].sellerAddress = _msgSender();
        _sellerInfo[entryId_].contractAddress = contractAddress_;
        _sellerInfo[entryId_].timestamp = blockTimestamp_;
        _sellerInfo[entryId_].tokenId = tokenId_;
        _sellerInfo[entryId_].sellingPrice = sellingPrice_;
        _sellerInfo[entryId_].installment = installment_;

        emit Sell(_msgSender(), contractAddress_, tokenId_, entryId_, blockTimestamp_);
        return entryId_;
    }

    function bid(
        uint256 entryId_,
        uint256 bidPrice_,
        InstallmentPlan installment_
    ) public payable returns (uint256) {
        uint256 value_ = msg.value;
        uint64 blockTimestamp_ = uint64(block.timestamp);

        // create unique bidId
        _bidIdTracker.increment();
        uint256 bidId_ = _bidIdTracker.current();

        _buyerInfo[bidId_].buyerAddress = _msgSender();

        uint256 downPayment_ = getDownPayment(entryId_, bidId_);

        require(value_ != 0 && value_ == downPayment_, "VALUE_NOT_EQUAL_TO_DOWN_PAYMENT");

        require(
            blockTimestamp_ <= _sellerInfo[entryId_].timestamp + biddingPeriod,
            "BIDDING_PERIOD_OVER"
        );

        // update buyer info mapping
        _buyerInfo[bidId_].buyerAddress = _msgSender();
        _buyerInfo[bidId_].timestamp = blockTimestamp_;
        _buyerInfo[bidId_].bidPrice = bidPrice_;
        _buyerInfo[bidId_].entryId = entryId_;
        _buyerInfo[bidId_].pricePaid = value_;
        _buyerInfo[bidId_].bidInstallment = installment_;

        _sellerInfo[entryId_].totalBids += 1;

        emit Bid(_msgSender(), entryId_, bidId_, blockTimestamp_);
        return bidId_;
    }

    function selectBid(uint256 bidId_) public {
        uint64 blockTimestamp_ = uint64(block.timestamp);
        isBidIdValid(bidId_);

        uint256 entryId_ = _buyerInfo[bidId_].entryId;
        isEntryIdValid(entryId_);

        SellerInfo memory sellerInfo_ = _sellerInfo[entryId_];
        BuyerInfo memory buyerInfo_ = _buyerInfo[bidId_];

        require(_msgSender() == sellerInfo_.sellerAddress, "CALLER_NOT_SELLER");
        require(
            blockTimestamp_ >= sellerInfo_.timestamp + biddingPeriod,
            "BIDDING_PERIOD_NOT_OVER"
        );
        require(sellerInfo_.selectedBidId == 0, "CANNOT_RESELECT_BID");

        // if installment plan is none so transfer the nft on selection of bid
        if (buyerInfo_.bidInstallment == InstallmentPlan.None) {
            IERC721(sellerInfo_.contractAddress).safeTransferFrom(
                address(this),
                buyerInfo_.buyerAddress,
                sellerInfo_.tokenId
            );

            // delete seller
            delete _sellerInfo[entryId_];
            // delete bid
            delete _buyerInfo[bidId_];
        } else {
            // update buyer info
            _buyerInfo[bidId_].isSelected = true;
            _buyerInfo[bidId_].timestamp = blockTimestamp_;

            // make NFT onSale off and set selected bidId
            _sellerInfo[entryId_].onSale = false;
            _sellerInfo[entryId_].selectedBidId = bidId_;

            _sellerInfo[entryId_].installment = buyerInfo_.bidInstallment;
            _sellerInfo[entryId_].sellingPrice = buyerInfo_.bidPrice;
            _sellerInfo[entryId_].installmentsPaid = 1;
        }

        emit BidSelected(bidId_, entryId_);
    }

    function payInstallment(uint256 entryId_) public payable {
        uint256 value_ = msg.value;

        isEntryIdValid(entryId_);

        uint256 bidId_ = _sellerInfo[entryId_].selectedBidId;
        isBidIdValid(bidId_);

        BuyerInfo memory buyerInfo_ = _buyerInfo[bidId_];

        require(buyerInfo_.buyerAddress == _msgSender(), "CALLER_NOT_BUYER");

        uint256 bidPrice_ = buyerInfo_.bidPrice;
        uint256 pricePaid_ = buyerInfo_.pricePaid;

        if (bidPrice_ != pricePaid_) {
            uint256 installmentPayment_ = getInstallmentPerMonth(entryId_);

            require(
                installmentPayment_ == value_ && value_ != 0 && installmentPayment_ != 0,
                "INVALID_INSTALLMENT_VALUE"
            );

            _buyerInfo[bidId_].pricePaid += value_;
            _sellerInfo[entryId_].installmentsPaid++;
        }

        // all installments done so transfer NFT to buyer
        if (bidPrice_ == pricePaid_) {
            IERC721(_sellerInfo[entryId_].contractAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                _sellerInfo[entryId_].tokenId
            );

            // delete seller
            delete _sellerInfo[entryId_];
            // delete bid
            delete _buyerInfo[bidId_];
        }
    }

    function withdrawBid(uint256 bidId_) public {
        isBidIdValid(bidId_);

        BuyerInfo memory buyerInfo_ = _buyerInfo[bidId_];

        uint256 entryId_ = buyerInfo_.entryId;

        require(
            uint64(block.timestamp) >= _sellerInfo[entryId_].timestamp + biddingPeriod,
            "BIDDING_PERIOD_NOT_OVER"
        );
        require(!buyerInfo_.isSelected, "BIDDER_SHOULD_NOT_BE_SELECTED");
        require(_msgSender() == buyerInfo_.buyerAddress, "CALLER_NOT_BUYER");

        // delete bid
        delete _buyerInfo[bidId_];

        // return the price paid
        Address.sendValue(payable(buyerInfo_.buyerAddress), buyerInfo_.pricePaid);
    }

    function liquidate(uint256 entryId_) public payable {
        uint256 value_ = msg.value;

        isEntryIdValid(entryId_);
        SellerInfo memory sellerInfo_ = _sellerInfo[entryId_];

        uint256 bidId_ = sellerInfo_.selectedBidId;
        isBidIdValid(bidId_);
        BuyerInfo memory buyerInfo_ = _buyerInfo[bidId_];

        uint256 installmentPerMonth_ = getInstallmentPerMonth(entryId_);

        // None or Installments paid
        require(
            installmentPerMonth_ != 0 || (buyerInfo_.bidPrice == buyerInfo_.pricePaid),
            "NO_INSTALLMENT_LEFT"
        );

        // get timestamp of next payment
        uint256 installmentMonthTimestamp_ = getInstallmentMonthTimestamp(
            bidId_,
            sellerInfo_.installmentsPaid + 1
        );

        // if timestamp of next payment + gracePeriod is passed then liquidate otherwise stop execution
        require(
            uint64(block.timestamp) > (installmentMonthTimestamp_ + gracePeriod),
            "INSTALLMENT_ON_TRACK"
        );

        address oldbuyer_ = buyerInfo_.buyerAddress;
        uint256 priceToBePaidByLiquidator_ = (buyerInfo_.pricePaid * 95) / 100;

        require(priceToBePaidByLiquidator_ == value_, "INVALID_LIQUIDATION_VALUE");

        // update new buyer
        _buyerInfo[bidId_].buyerAddress = _msgSender();

        // transfer 95% of pricePaid to old buyer
        Address.sendValue(payable(oldbuyer_), priceToBePaidByLiquidator_);
    }

    function setBiddingPeriod(uint64 biddingPeriod_) public onlyOwner {
        require(biddingPeriod_ != 0, "INVALID_BIDDING_PERIOD");
        biddingPeriod = biddingPeriod_;
    }

    function setGracePeriod(uint64 gracePeriod_) public onlyOwner {
        require(gracePeriod_ != 0, "INVALID_GRACE_PERIOD");
        gracePeriod = gracePeriod_;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
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