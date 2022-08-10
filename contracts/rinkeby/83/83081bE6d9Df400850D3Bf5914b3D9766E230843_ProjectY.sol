// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";



contract ProjectY is Context, Owned, ERC721Holder {
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private p_entryIdTracker;
    Counters.Counter private p_bidIdTracker;

    // // FOR TESTNET ONLY
    uint64 public constant ONE_MONTH = 1 days;
    uint64 public biddingPeriod = 90 minutes;
    uint64 public gracePeriod = 90 minutes;

    // uint64 public constant ONE_MONTH = 30 days;
    // uint64 public biddingPeriod = 7 days;
    // uint64 public gracePeriod = 7 days;

    // vars for frontend helpers
    uint256 public getHistoricTotalEntryIds;
    uint256 public getHistoricTotalBidIds;

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
        uint8 paymentsClaimed;
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
    mapping(uint256 => SellerInfo) private p_sellerInfo;

    // bidId -> BuyerInfo
    mapping(uint256 => BuyerInfo) private p_buyerInfo;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

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

    event BidSelected(uint256 bidId, uint256 entryId);

    event InstallmentPaid(address buyer, uint256 entryId, uint256 bidId, uint256 installmentNumber);

    event BidWithdrawn(uint256 bidId, uint256 entryId, uint256 value);

    event SellWithdrawn(address seller, uint256 entryId);

    event PaymentWithdrawn(uint256 bidId, uint256 entryId, uint256 value, uint256 paymentsClaimed);

    event Liquidated(uint256 entryId, uint256 bidId, uint256 installmentPaid, uint256 value);

    event BiddingPeriodUpdated(uint64 prevBiddingPeriod, uint64 newBiddingPeriod);

    event GracePeriodUpdated(uint64 prevGracePeriod, uint64 newGracePeriod);

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner_) Owned(owner_) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /*//////////////////////////////////////////////////////////////
                        NON-VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function sell(
        address contractAddress_,
        uint256 tokenId_,
        uint256 sellingPrice_,
        InstallmentPlan installment_
    ) external returns (uint256) {
        require(sellingPrice_ != 0, "INVALID_PRICE");

        uint64 blockTimestamp_ = uint64(block.timestamp);

        // create unique entryId
        p_entryIdTracker.increment();
        getHistoricTotalEntryIds++;
        uint256 entryId_ = p_entryIdTracker.current();

        // update mapping
        p_sellerInfo[entryId_].onSale = true;
        p_sellerInfo[entryId_].sellerAddress = _msgSender();
        p_sellerInfo[entryId_].contractAddress = contractAddress_;
        p_sellerInfo[entryId_].timestamp = blockTimestamp_;
        p_sellerInfo[entryId_].tokenId = tokenId_;
        p_sellerInfo[entryId_].sellingPrice = sellingPrice_;
        p_sellerInfo[entryId_].installment = installment_;

        emit Sell(_msgSender(), contractAddress_, tokenId_, entryId_, blockTimestamp_);

        // transfer NFT to this contract
        IERC721(contractAddress_).safeTransferFrom(_msgSender(), address(this), tokenId_);

        return entryId_;
    }

    function withdrawSell(uint256 entryId_) external returns (uint256) {
        _requireIsEntryIdValid(entryId_);

        SellerInfo memory sellerInfo_ = p_sellerInfo[entryId_];

        require(_msgSender() == sellerInfo_.sellerAddress, "CALLER_NOT_SELLER");

        require(
            uint64(block.timestamp) >= sellerInfo_.timestamp + biddingPeriod,
            "BIDDING_PERIOD_NOT_OVER"
        );
        require(sellerInfo_.selectedBidId == 0, "BIDDER_SHOULD_NOT_BE_SELECTED");

        // delete entryId
        delete p_sellerInfo[entryId_];

        // decrease total entryIds
        p_entryIdTracker.decrement();

        emit SellWithdrawn(sellerInfo_.sellerAddress, entryId_);

        IERC721(sellerInfo_.contractAddress).safeTransferFrom(
            address(this),
            sellerInfo_.sellerAddress,
            sellerInfo_.tokenId
        );

        return entryId_;
    }

    function bid(
        uint256 entryId_,
        uint256 bidPrice_,
        InstallmentPlan installment_
    ) external payable returns (uint256) {
        _requireIsEntryIdValid(entryId_);

        uint256 value_ = msg.value;
        uint64 blockTimestamp_ = uint64(block.timestamp);

        require(
            blockTimestamp_ <= p_sellerInfo[entryId_].timestamp + biddingPeriod,
            "BIDDING_PERIOD_OVER"
        );

        // create unique bidId
        p_bidIdTracker.increment();
        getHistoricTotalBidIds++;
        uint256 bidId_ = p_bidIdTracker.current();

        // update buyer info mapping
        p_buyerInfo[bidId_].buyerAddress = _msgSender();
        p_buyerInfo[bidId_].bidInstallment = installment_;
        p_buyerInfo[bidId_].timestamp = blockTimestamp_;
        p_buyerInfo[bidId_].bidPrice = bidPrice_;
        p_buyerInfo[bidId_].entryId = entryId_;

        // update total bids for this entry id
        p_sellerInfo[entryId_].totalBids += 1;

        uint256 downPayment_ = getDownPaymentAmount(bidId_);

        require(value_ != 0 && value_ == downPayment_, "VALUE_NOT_EQUAL_TO_DOWN_PAYMENT");

        // update price paid
        p_buyerInfo[bidId_].pricePaid = value_;

        emit Bid(_msgSender(), entryId_, bidId_, blockTimestamp_);

        return bidId_;
    }

    function selectBid(uint256 bidId_) external {
        uint64 blockTimestamp_ = uint64(block.timestamp);
        _requireIsBidIdValid(bidId_);

        uint256 entryId_ = p_buyerInfo[bidId_].entryId;
        _requireIsEntryIdValid(entryId_);

        SellerInfo memory sellerInfo_ = p_sellerInfo[entryId_];
        BuyerInfo memory buyerInfo_ = p_buyerInfo[bidId_];

        require(_msgSender() == sellerInfo_.sellerAddress, "CALLER_NOT_SELLER");
        require(
            blockTimestamp_ >= sellerInfo_.timestamp + biddingPeriod,
            "BIDDING_PERIOD_NOT_OVER"
        );

        // will be tested in other than none scenario
        require(sellerInfo_.selectedBidId == 0 && !buyerInfo_.isSelected, "CANNOT_RESELECT_BID");

        emit BidSelected(bidId_, entryId_);

        // if installment plan is none so transfer the nft on selection of bid
        if (buyerInfo_.bidInstallment == InstallmentPlan.None) {
            // delete seller
            delete p_sellerInfo[entryId_];

            // decrease total entryIds
            p_entryIdTracker.decrement();

            // delete bid
            delete p_buyerInfo[bidId_];

            // decrease total bidIds
            p_bidIdTracker.decrement();

            IERC721(sellerInfo_.contractAddress).safeTransferFrom(
                address(this),
                buyerInfo_.buyerAddress,
                sellerInfo_.tokenId
            );

            // send value to seller
            Address.sendValue(payable(sellerInfo_.sellerAddress), buyerInfo_.pricePaid);
        } else {
            // update buyer info
            p_buyerInfo[bidId_].isSelected = true;
            p_buyerInfo[bidId_].timestamp = blockTimestamp_;

            // make NFT onSale off and set selected bidId
            p_sellerInfo[entryId_].onSale = false;
            p_sellerInfo[entryId_].selectedBidId = bidId_;

            p_sellerInfo[entryId_].installment = buyerInfo_.bidInstallment;
            p_sellerInfo[entryId_].sellingPrice = buyerInfo_.bidPrice;
            p_sellerInfo[entryId_].installmentsPaid = 1;
        }
    }

    function payInstallment(uint256 entryId_) external payable {
        uint256 value_ = msg.value;

        // if InstallmentPlan.None so entryId is not validated as it was deleted
        _requireIsEntryIdValid(entryId_);

        uint256 bidId_ = p_sellerInfo[entryId_].selectedBidId;

        require(bidId_ != 0, "NO_BID_ID_SELECTED");

        BuyerInfo memory buyerInfo_ = p_buyerInfo[bidId_];

        require(buyerInfo_.buyerAddress == _msgSender(), "CALLER_NOT_BUYER");

        uint256 bidPrice_ = buyerInfo_.bidPrice;
        uint256 pricePaid_ = buyerInfo_.pricePaid;

        uint8 installmentsPaid_ = p_sellerInfo[entryId_].installmentsPaid;

        // check if installment is done then revert
        uint8 totalInstallments_ = getTotalInstallments(bidId_);

        require(installmentsPaid_ != totalInstallments_, "NO_INSTALLMENT_LEFT");





        if (bidPrice_ != pricePaid_) {
            uint256 installmentPerMonth_ = getInstallmentAmountPerMonth(entryId_);

            require(installmentPerMonth_ == value_, "INVALID_INSTALLMENT_VALUE");

            // get timestamp of installment paid
            uint64 installmentPaidTimestamp_ = getInstallmentMonthTimestamp(
                bidId_,
                installmentsPaid_
            );

            // current timestamp should be greater than installmentPaidTimestamp_
            require(
                uint64(block.timestamp) > installmentPaidTimestamp_,
                "PAY_AFTER_APPROPRIATE_TIME"
            );

            // get timestamp of next payment
            uint64 installmentMonthTimestamp_ = getInstallmentMonthTimestamp(
                bidId_,
                installmentsPaid_ + 1 // the installment number that needs to be paid
            );

            // if current timestamp is greater then timestamp of next payment + gracePeriod then stop execution
            require(
                !(uint64(block.timestamp) > (installmentMonthTimestamp_ + gracePeriod)),
                "DUE_DATE_PASSED"
            );

            p_buyerInfo[bidId_].pricePaid += value_;
            p_sellerInfo[entryId_].installmentsPaid++;

            // may increment local variable as well
            pricePaid_ += value_;
        }





        emit InstallmentPaid(_msgSender(), entryId_, bidId_, installmentsPaid_ + 1);

        // all installments done so transfer NFT to buyer
        // refetch pricePaid from storage becuase we upadated it in above block
        // if (bidPrice_ == p_buyerInfo[bidId_].pricePaid) {
        if (bidPrice_ == pricePaid_) {
            IERC721(p_sellerInfo[entryId_].contractAddress).safeTransferFrom(
                address(this),
                buyerInfo_.buyerAddress,
                p_sellerInfo[entryId_].tokenId
            );
        }
    }

    function withdrawBid(uint256 bidId_) external {
        _requireIsBidIdValid(bidId_);

        BuyerInfo memory buyerInfo_ = p_buyerInfo[bidId_];

        require(buyerInfo_.buyerAddress == _msgSender(), "CALLER_NOT_BUYER");
        require(
            uint64(block.timestamp) >= p_sellerInfo[buyerInfo_.entryId].timestamp + biddingPeriod,
            "BIDDING_PERIOD_NOT_OVER"
        );
        require(!buyerInfo_.isSelected, "BIDDER_SHOULD_NOT_BE_SELECTED");

        // delete bid
        delete p_buyerInfo[bidId_];

        // decrease total bidIds
        p_bidIdTracker.decrement();

        emit BidWithdrawn(bidId_, buyerInfo_.entryId, buyerInfo_.pricePaid);

        // return the price paid
        Address.sendValue(payable(buyerInfo_.buyerAddress), buyerInfo_.pricePaid);
    }

    function withdrawPayment(uint256 entryId_) external {
        _requireIsEntryIdValid(entryId_);
        SellerInfo memory sellerInfo_ = p_sellerInfo[entryId_];
        _requireIsBidIdValid(sellerInfo_.selectedBidId);

        require(_msgSender() == sellerInfo_.sellerAddress, "CALLER_NOT_SELLER");

        uint8 secondLastInstallmentPaid_ = sellerInfo_.installmentsPaid - 1;





        // check if installment is done then revert
        uint8 totalInstallments_ = getTotalInstallments(sellerInfo_.selectedBidId);

        // // get timestamp of next payment
        // uint64 nextInstallmentTimestamp_ = getInstallmentMonthTimestamp(
        //     sellerInfo_.selectedBidId,
        //     sellerInfo_.installmentsPaid + 1 // the installment number that needs to be paid
        // );



        // // current timestamp should greater than nextInstallmentTimestamp_
        // require(
        //     uint64(block.timestamp) > nextInstallmentTimestamp_,
        //     "CLAIM_AFTER_APPROPRIATE_TIME"
        // );

        bool isLastClaimablePayment_ = totalInstallments_ == sellerInfo_.installmentsPaid &&
            // if payments claimed is zero then it means only downpayment is done
            sellerInfo_.paymentsClaimed != 0 &&
            // if payments claimed and second last are equal this means this is last payment claiming
            sellerInfo_.paymentsClaimed == secondLastInstallmentPaid_;

        // payments claimed should be one less than installmentsPaid
        // no other check required as installmentsPaid will increase after a month
        require(
            (((sellerInfo_.paymentsClaimed < secondLastInstallmentPaid_) &&
                (sellerInfo_.installment != InstallmentPlan.None)) || (isLastClaimablePayment_)),
            "CANNOT_RECLAIM_PAYMENT"
        );

        uint8 paymentsClaimable_ = 0;
        uint256 amountClaimable_ = 0;

        // seller is claiming for the first time and only second payment is done
        // so release downpayment only
        if (sellerInfo_.paymentsClaimed == 0 && secondLastInstallmentPaid_ == 1) {

            paymentsClaimable_ = 1;
            amountClaimable_ = getDownPaymentAmount(sellerInfo_.selectedBidId);
        }

        // seller is claiming for the first time and all installments are done
        // && sellerInfo_.installmentsPaid == totalInstallments_
        if (sellerInfo_.paymentsClaimed == 0 && secondLastInstallmentPaid_ > 1) {

            uint8 no_;

            if (sellerInfo_.installmentsPaid == totalInstallments_) {

                // secondLastInstallmentPaid_ // totalInstallments_ - 1
                paymentsClaimable_ = sellerInfo_.installmentsPaid;
                no_ = secondLastInstallmentPaid_;
            } else {

                paymentsClaimable_ = secondLastInstallmentPaid_; // secondLastInstallmentPaid_ // totalInstallments_ - 1
                no_ = secondLastInstallmentPaid_ - 1;
            }

            uint256 downPayment_ = getDownPaymentAmount(sellerInfo_.selectedBidId);




            uint256 installmentPerMonth_ = getInstallmentAmountPerMonth(entryId_);


            amountClaimable_ = downPayment_ + (installmentPerMonth_ * no_);
        }

        // seller is claiming payment other than first
        if (sellerInfo_.paymentsClaimed != 0) {

            paymentsClaimable_ = secondLastInstallmentPaid_ - sellerInfo_.paymentsClaimed;
            amountClaimable_ = paymentsClaimable_ * getInstallmentAmountPerMonth(entryId_);
        }

        // seller is claiming last payment
        if (isLastClaimablePayment_) {

            paymentsClaimable_ = 1;
            amountClaimable_ = getInstallmentAmountPerMonth(entryId_);
        }




        // update paymentsClaimed
        p_sellerInfo[entryId_].paymentsClaimed += paymentsClaimable_;

        emit PaymentWithdrawn(
            sellerInfo_.selectedBidId,
            entryId_,
            amountClaimable_,
            p_sellerInfo[entryId_].paymentsClaimed
        );

        // if all payments claimed then delete buyerInfo and sellerInfo
        if (p_sellerInfo[entryId_].paymentsClaimed == totalInstallments_) {
            // delete seller
            delete p_sellerInfo[entryId_];

            // decrease total entryIds
            p_entryIdTracker.decrement();

            // delete bid
            delete p_buyerInfo[sellerInfo_.selectedBidId];

            // decrease total bidIds
            p_bidIdTracker.decrement();
        }

        // // if last payment then delete buyerInfo and sellerInfo
        // if (isLastClaimablePayment_) {
        //     // delete seller
        //     delete p_sellerInfo[entryId_];
        //     // delete bid
        //     delete p_buyerInfo[sellerInfo_.selectedBidId];
        // } else {
        //     // update paymentsClaimed
        //     p_sellerInfo[entryId_].paymentsClaimed += paymentsClaimable_;
        // }



        // transfer amountClaimable_ to seller
        Address.sendValue(payable(sellerInfo_.sellerAddress), amountClaimable_);


    }

    function liquidate(uint256 entryId_) external payable {
        uint256 value_ = msg.value;

        _requireIsEntryIdValid(entryId_);
        SellerInfo memory sellerInfo_ = p_sellerInfo[entryId_];

        uint256 bidId_ = sellerInfo_.selectedBidId;
        _requireIsBidIdValid(bidId_);
        BuyerInfo memory buyerInfo_ = p_buyerInfo[bidId_];

        require(
            _msgSender() != sellerInfo_.sellerAddress && _msgSender() != buyerInfo_.buyerAddress,
            "INVALID_CALLER"
        );

        // 0 means InstallmentPlan.None
        uint8 totalInstallments_ = getTotalInstallments(sellerInfo_.selectedBidId);




        // None or Installments paid
        require(
            sellerInfo_.installmentsPaid != totalInstallments_ && totalInstallments_ != 0,
            "INSTALLMENTS_COMPLETE"
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

        uint256 installmentPerMonth_ = getInstallmentAmountPerMonth(entryId_);
        uint256 liquidationValue_ = (buyerInfo_.pricePaid * 95) / 100;

        uint256 valueToBePaid_ = liquidationValue_ + installmentPerMonth_;





        require(valueToBePaid_ == value_, "INVALID_LIQUIDATION_VALUE");

        // update new buyer
        p_buyerInfo[bidId_].buyerAddress = _msgSender();
        p_buyerInfo[bidId_].pricePaid += installmentPerMonth_;
        p_sellerInfo[entryId_].installmentsPaid++;

        emit Liquidated(entryId_, bidId_, p_sellerInfo[entryId_].installmentsPaid, valueToBePaid_);

        // if only last installment remains then transfer nft
        if (sellerInfo_.installmentsPaid == totalInstallments_ - 1) {
            IERC721(p_sellerInfo[entryId_].contractAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                sellerInfo_.tokenId
            );
        }

        // transfer 95% of pricePaid to old buyer
        Address.sendValue(payable(oldbuyer_), liquidationValue_);
    }

    function setBiddingPeriod(uint64 biddingPeriod_) external onlyOwner {
        require(biddingPeriod_ != 0, "INVALID_BIDDING_PERIOD");
        emit BiddingPeriodUpdated(biddingPeriod, biddingPeriod_);
        biddingPeriod = biddingPeriod_;
    }

    function setGracePeriod(uint64 gracePeriod_) external onlyOwner {
        require(gracePeriod_ != 0, "INVALID_GRACE_PERIOD");
        emit GracePeriodUpdated(gracePeriod, gracePeriod_);
        gracePeriod = gracePeriod_;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getTotalEntryIds() external view returns (uint256) {
        return p_entryIdTracker.current();
    }

    function getTotalBidIds() external view returns (uint256) {
        return p_bidIdTracker.current();
    }

    function getIsEntryIdValid(uint256 entryId_) public view returns (bool) {
        return p_sellerInfo[entryId_].sellerAddress != address(0);
    }

    function getIsBidIdValid(uint256 bidId_) public view returns (bool isValid_) {
        return p_buyerInfo[bidId_].buyerAddress != address(0);
    }

    function getSellerInfo(uint256 entryId_) public view returns (SellerInfo memory) {
        _requireIsEntryIdValid(entryId_);
        return p_sellerInfo[entryId_];
    }

    function getBuyerInfo(uint256 bidId_) public view returns (BuyerInfo memory) {
        _requireIsBidIdValid(bidId_);
        return p_buyerInfo[bidId_];
    }

    function getTotalInstallments(uint256 bidId_) public view returns (uint8) {
        _requireIsBidIdValid(bidId_);

        InstallmentPlan installment_ = p_buyerInfo[bidId_].bidInstallment;

        if (installment_ == InstallmentPlan.ThreeMonths) {
            return 3;
        } else if (installment_ == InstallmentPlan.SixMonths) {
            return 6;
        } else if (installment_ == InstallmentPlan.NineMonths) {
            return 9;
        } else {
            return 0; // InstallmentPlan.None
        }
    }

    function getDownPaymentAmount(uint256 bidId_) public view returns (uint256) {
        _requireIsBidIdValid(bidId_);

        BuyerInfo memory buyerInfo_ = p_buyerInfo[bidId_];

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

    function getInstallmentAmountPerMonth(uint256 entryId_) public view returns (uint256 amount_) {
        _requireIsEntryIdValid(entryId_);
        SellerInfo memory sellerInfo_ = p_sellerInfo[entryId_];

        uint256 bidId_ = sellerInfo_.selectedBidId;
        _requireIsBidIdValid(bidId_);

        BuyerInfo memory buyerInfo_ = p_buyerInfo[bidId_];

        InstallmentPlan installment_ = buyerInfo_.bidInstallment;

        // if (buyerInfo_.bidPrice == buyerInfo_.pricePaid) {
        //     return 0;
        // }

        if (installment_ == InstallmentPlan.ThreeMonths) {
            amount_ = (buyerInfo_.bidPrice * 33) / 100; // 33%
        } else if (installment_ == InstallmentPlan.SixMonths) {
            amount_ = (buyerInfo_.bidPrice * 165) / 1000; // 16.5%
        } else if (installment_ == InstallmentPlan.NineMonths) {
            amount_ = (buyerInfo_.bidPrice * 11) / 100; // 11%
        }

        // unreachable code as it gets reverted
        // in case of InstallmentPlan.None
        // else {
        //     return 0; // InstallmentPlan.None
        // }
    }

    // // get installment amount of specific installment number
    // function getInstallmentAmountOf(
    //     uint256 entryId_,
    //     uint256 bidId_,
    //     uint256 installmentNumber_
    // ) public view returns (uint256) {
    //     // installmentNumber_ == 0 gives downpayment
    //     return
    //         getDownPaymentAmount(bidId_) +
    //         (installmentNumber_ * getInstallmentAmountPerMonth(entryId_));
    // }

    function getInstallmentMonthTimestamp(uint256 bidId_, uint64 installmentNumber_)
        public
        view
        returns (uint64)
    {
        _requireIsBidIdValid(bidId_);
        require(installmentNumber_ != 0, "INVALID_INSTALLMENT_NUMBER");
        return p_buyerInfo[bidId_].timestamp + ((installmentNumber_ - 1) * ONE_MONTH);
    }

    /*//////////////////////////////////////////////////////////////
                    TEMPORARY FRONT-END FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // gives all nfts that are open for sale (excluding the one selectedBid)
    function getNFTsOpenForSale()
        external
        view
        returns (SellerInfo[] memory nftsOpenForSale_, uint256[] memory entryIds_)
    {
        uint256 totalEntryIds_ = getHistoricTotalEntryIds;
        nftsOpenForSale_ = new SellerInfo[](totalEntryIds_);
        entryIds_ = new uint256[](totalEntryIds_);

        // Storing this outside the loop saves gas per iteration.
        SellerInfo memory sellerInfo_;

        for (uint256 i_ = 0; i_ < totalEntryIds_; i_++) {
            // skip seller info if entryId is invalid
            if (!getIsEntryIdValid(i_ + 1)) {
                continue;
            }

            sellerInfo_ = getSellerInfo(i_ + 1);

            if (sellerInfo_.onSale) {
                entryIds_[i_] = i_ + 1;
                nftsOpenForSale_[i_] = sellerInfo_;
            }
        }
    }

    // gives all nfts specific to user that are open for sale (excluding the one selectedBid)
    function getUserNFTsOpenForSale(address user_)
        external
        view
        returns (SellerInfo[] memory userNFTsOpenForSale_, uint256[] memory entryIds_)
    {
        require(user_ != address(0), "INVALID_ADDRESS");
        uint256 totalEntryIds_ = getHistoricTotalEntryIds;
        userNFTsOpenForSale_ = new SellerInfo[](totalEntryIds_);
        entryIds_ = new uint256[](totalEntryIds_);

        // Storing this outside the loop saves gas per iteration.
        SellerInfo memory sellerInfo_;

        for (uint256 i_ = 0; i_ < totalEntryIds_; i_++) {
            // skip seller info if entryId is invalid
            if (!getIsEntryIdValid(i_ + 1)) {
                continue;
            }

            sellerInfo_ = getSellerInfo(i_ + 1);

            if (sellerInfo_.onSale && sellerInfo_.sellerAddress == user_) {
                entryIds_[i_] = i_ + 1;
                userNFTsOpenForSale_[i_] = sellerInfo_;
            }
        }
    }

    function getAllBidsOnNFT(uint256 entryId_)
        external
        view
        returns (BuyerInfo[] memory allBidsOnNFT_, uint256[] memory bidIds_)
    {
        uint256 totalBidIds_ = getHistoricTotalBidIds;
        allBidsOnNFT_ = new BuyerInfo[](totalBidIds_);
        bidIds_ = new uint256[](totalBidIds_);

        for (uint256 i_ = 0; i_ < totalBidIds_; i_++) {
            // skip buyer info if bidId is invalid
            if (!getIsBidIdValid(i_ + 1)) {
                continue;
            }

            if (p_buyerInfo[i_ + 1].entryId == entryId_) {
                bidIds_[i_] = i_ + 1;
                allBidsOnNFT_[i_] = getBuyerInfo(i_ + 1);
            }
        }
    }

    // get all nfts ongoing installment phase specific to user
    function getUserNFTsOngoingInstallmentPhase(address user_)
        external
        view
        returns (
            SellerInfo[] memory sellerInfos_,
            BuyerInfo[] memory buyerInfos_,
            uint256[] memory downPayments_,
            uint256[] memory monthlyPayments_,
            uint256[] memory entryIds_,
            uint256[] memory bidIds_
        )
    {
        require(user_ != address(0), "INVALID_ADDRESS");
        uint256 totalEntryIds_ = getHistoricTotalEntryIds;
        uint256 totalBidIds_ = getHistoricTotalBidIds;

        sellerInfos_ = new SellerInfo[](totalEntryIds_);
        buyerInfos_ = new BuyerInfo[](totalBidIds_);
        downPayments_ = new uint256[](totalEntryIds_);
        monthlyPayments_ = new uint256[](9); // max 9 monthly payments
        entryIds_ = new uint256[](totalEntryIds_);
        bidIds_ = new uint256[](totalBidIds_);

        // Storing this outside the loop saves gas per iteration.
        SellerInfo memory sellerInfo_;
        BuyerInfo memory buyerInfo_;

        for (uint256 i_ = 0; i_ < totalEntryIds_; i_++) {
            // skip seller info if entryId is invalid
            if (!getIsEntryIdValid(i_ + 1)) {
                continue;
            }

            sellerInfo_ = getSellerInfo(i_ + 1);

            // skip loop if no selected bid id
            if (sellerInfo_.selectedBidId == 0) {
                continue;
            }

            buyerInfo_ = getBuyerInfo(sellerInfo_.selectedBidId);

            if (buyerInfo_.buyerAddress == user_) {
                sellerInfos_[i_] = sellerInfo_;
                buyerInfos_[i_] = buyerInfo_;

                downPayments_[i_] = getDownPaymentAmount(sellerInfo_.selectedBidId);
                monthlyPayments_[i_] = getInstallmentAmountPerMonth(sellerInfo_.selectedBidId);

                entryIds_[i_] = i_ + 1;
                bidIds_[i_] = i_ + 1;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _requireIsEntryIdValid(uint256 entryId_) internal view {
        require(getIsEntryIdValid(entryId_), "INVALID_ENTRY_ID");
    }

    function _requireIsBidIdValid(uint256 bidId_) internal view {
        require(getIsBidIdValid(bidId_), "INVALID_BID_ID");
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