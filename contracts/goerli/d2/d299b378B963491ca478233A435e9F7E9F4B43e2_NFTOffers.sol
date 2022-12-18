//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A Contract for Offerding and selling single and batched NFTs
/// @author 1WOR&D 
/// @notice This contract can be used for Saling any NFTs, and accepts any ERC20 token as payment. Initial idea of Avo Labs GmbH
contract NFTOffers {
    mapping(address => mapping(uint256 => Offer)) public nftOffers;
    mapping(address => uint256) failedTransferCredits;
    //Each NFT Sale is unique to each NFT (contract + id pairing).
    struct Offer {
        //map token ID to
        uint32 offerIncreasePercentage;
        uint128 buyNowPrice;
        uint128 nftHighestOffer;
        address nftHighestBidder;
        address nftSeller;
        address nftRecipient; //The Bidder can specify a recipient for the NFT if their Offer is successful.
        address ERC20Token; // The seller can specify an ERC20 token that can be used to Offer or purchase the NFT.
        address[] feeRecipients;
        uint32[] feePercentages;
    }
    /*
     * Default values that are used if not specified by the NFT seller.
     */
        uint32 public defaultOfferIncreasePercentage;

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event SaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 buyNowPrice,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event OfferMade(
        address nftContractAddress,
        uint256 tokenId,
        address Bidder,
        uint256 ethAmount,
        address erc20Token,
        uint256 tokenAmount
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestOffer,
        address nftHighestBidder,
        address nftRecipient
    );

    event SaleSettled(
        address nftContractAddress,
        uint256 tokenId,
        address SaleSettler
    );

    event SaleClosed(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event OfferWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address highestBidder
    );

    event BuyNowPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint128 newBuyNowPrice
    );

    event HighestOfferTaken(
        address nftContractAddress, 
        uint256 tokenId
    );

    event NFTMovedToSaleContract(
        address _nftContractAddress, 
        uint256 _tokenId
    );


    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
 
    /*
    * Clear offer structure by request of NFT Owner if it is not set before
    */
    modifier isSaleNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            nftOffers[_nftContractAddress][_tokenId].nftSeller !=
                msg.sender,
            "Sale already started by owner"
        );

        if (
            nftOffers[_nftContractAddress][_tokenId].nftSeller !=
            address(0)
        ) {
            require(
                msg.sender == IERC721(_nftContractAddress).ownerOf(_tokenId),
                "Sender doesn't own NFT"
            );

            _resetSale(_nftContractAddress, _tokenId);
        }
        _;
    }

    modifier SaleOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isSaleOngoing(_nftContractAddress, _tokenId),
            "Sale has ended"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }



    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender ==
                nftOffers[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        _;
    }

    /*
     * The Offer amount was either equal the buyNowPrice or it must be higher than the previous
     * Offer by the specified Offer increase percentage.
     */
    modifier OfferAmountMeetsOfferRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) {
        require(
            _doesOfferMeetOfferRequirements(
                _nftContractAddress,
                _tokenId,
                _tokenAmount
            ),
            "Not enough funds to Offer on NFT"
        );
        _;
    }


    /*
     * Payment is accepted if the payment is made in the ERC20 token or ETH specified by the seller.
     * Early Offers on NFTs not yet up for Sale must be made in ETH.
     */
    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    ) {
        require(
            _isPaymentAccepted(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _tokenAmount
            ),
            "Offer to be in specified ERC20/Eth"
        );
        _;
    }


    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Recipients != percentages"
        );
        _;
    }


    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/
    // constructor
    constructor() {
        defaultOfferIncreasePercentage = 100;
     }

    /*╔══════════════════════════════╗
      ║    Sale CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    function _isSaleOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        address SellerSet = nftOffers[_nftContractAddress][
            _tokenId
        ].nftSeller;
        //if the nftSeller is set to 0, the Sale is stopped.
        return (SellerSet == address(0));
    }

    /*
     * Check if a Offer has been made. This is applicable in the early Offer scenario
     * to ensure that if an Sale is created after an early Offer, the Sale
     * begins appropriately or is settled if the buy now price is met.
     */
    function _isAOfferMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (nftOffers[_nftContractAddress][_tokenId]
            .nftHighestOffer > 0);
    }

    /*
     * If the buy now price is set by the seller, check that the highest Offer meets that price.
     */
    function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint128 buyNowPrice = nftOffers[_nftContractAddress][_tokenId]
            .buyNowPrice;
        return
            buyNowPrice > 0 &&
            nftOffers[_nftContractAddress][_tokenId].nftHighestOffer >=
            buyNowPrice;
    }

    /*
     * Check that a Offer is applicable for the purchase of the NFT.
     * In the case of a sale: the Offer needs to meet the buyNowPrice.
     * In the case of an early offers: the Offer needs to be a % higher than the previous Offer.
     */
    function _doesOfferMeetOfferRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        uint128 buyNowPrice = nftOffers[_nftContractAddress][_tokenId]
            .buyNowPrice;
        //if buyNowPrice is met, ignore increase percentage
        if (
            buyNowPrice > 0 &&
            (msg.value >= buyNowPrice || _tokenAmount >= buyNowPrice)
        ) {
            return true;
        }
        //if the NFT is up for Sale, the Offer needs to be a higher than the previous Offer
        uint256 OfferHighestAmount = (nftOffers[_nftContractAddress][_tokenId]
            .nftHighestOffer *
            (10000 +
                _getOfferIncreasePercentage(_nftContractAddress, _tokenId))) /
            10000;
        return (msg.value >= OfferHighestAmount ||
            _tokenAmount >= OfferHighestAmount);
    }


    /**
     * Payment is accepted in the following scenarios:
     * (1) Sale already created - can accept ETH or Specified Token
     *  --------> Cannot Offer with ETH & an ERC20 Token together in any circumstance<------
     * (2) Sale not created - only ETH accepted (cannot early Offer with an ERC20 Token
     * (3) Cannot make a zero Offer (no ETH or Token amount)
     */
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _OfferERC20Token,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        address SaleERC20Token = nftOffers[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_isERC20Sale(SaleERC20Token)) {
            return
                msg.value == 0 &&
                SaleERC20Token == _OfferERC20Token &&
                _tokenAmount > 0;
        } else {
            return
                msg.value != 0 &&
                _OfferERC20Token == address(0) &&
                _tokenAmount == 0;
        }
    }

    function _isERC20Sale(address _SaleERC20Token)
        internal
        pure
        returns (bool)
    {
        return _SaleERC20Token != address(0);
    }

    /*
     * Returns the percentage of the total Offer (used to calculate fee payments)
     */
    function _getPortionOfOffer(uint256 _totalOffer, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalOffer * (_percentage)) / 10000;
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    Sale CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /*****************************************************************
     * These functions check if the applicable Sale parameter has *
     * been set by the NFT seller. If not, return the default value. *
     *****************************************************************/
    function _getOfferIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint32) {
        uint32 offerIncreasePercentage = nftOffers[_nftContractAddress][
            _tokenId
        ].offerIncreasePercentage;

        if (offerIncreasePercentage == 0) {
            return defaultOfferIncreasePercentage;
        } else {
            return offerIncreasePercentage;
        }
    }

    /*
     * The default value for the NFT recipient is the highest Bidder
     */
    function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (address)
    {
        address nftRecipient = nftOffers[_nftContractAddress][
            _tokenId
        ].nftRecipient;

        if (nftRecipient == address(0)) {
            return
                nftOffers[_nftContractAddress][_tokenId]
                    .nftHighestBidder;
        } else {
            return nftRecipient;
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFTS TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    function _transferNftToSaleContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftOffers[_nftContractAddress][_tokenId]
            .nftSeller;
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller) {
            IERC721(_nftContractAddress).transferFrom(
                _nftSeller,
                address(this),
                _tokenId
            );
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "nft transfer failed"
            );
        } else {
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "Seller doesn't own NFT"
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║  TRANSFER NFTS TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       Sale CREATION       ║
      ╚══════════════════════════════╝*/

    /**
     * Setup parameters applicable to all Sales:
     * -> ERC20 Token for payment (if specified by the seller) : _erc20Token
     * -> buy now price : _buyNowPrice
     * -> the nft seller: msg.sender
     * -> The fee recipients & their respective percentages for a sucessful Sale/sale
     */
    function _setupSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        internal
        correctFeeRecipientsAndPercentages(
            _feeRecipients.length,
            _feePercentages.length
        )
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        if (_erc20Token != address(0)) {
            nftOffers[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        nftOffers[_nftContractAddress][_tokenId]
            .feeRecipients = _feeRecipients;
        nftOffers[_nftContractAddress][_tokenId]
            .feePercentages = _feePercentages;
        nftOffers[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
        nftOffers[_nftContractAddress][_tokenId].nftSeller = msg
            .sender;
    }


    function openForOffers(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        external
        isSaleNotStartedByOwner(_nftContractAddress, _tokenId)
    {
        nftOffers[_nftContractAddress][_tokenId]
            .offerIncreasePercentage = defaultOfferIncreasePercentage;
        _setupSale(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages
        );
        emit SaleCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages
        );
        _updateOngoingSale(_nftContractAddress, _tokenId); // transfer NFT to Sale contract if BuyNow price is met
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       Sale CREATION       ║
      ╚══════════════════════════════╝*/
    /**********************************/


    /*╔═════════════════════════════╗
      ║        Offer FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /********************************************************************
     * Make Offers with ETH or an ERC20 Token specified by the NFT seller.*
     * Additionally, a buyer can pay the asking price to conclude a sale*
     * of an NFT.                                                      *
     ********************************************************************/

    function _makeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        internal
        paymentAccepted(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _tokenAmount
        )
        OfferAmountMeetsOfferRequirements(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        )
    {
        _reversePreviousOfferAndUpdateHighestOffer(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        );
        emit OfferMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            msg.value,
            _erc20Token,
            _tokenAmount
        );
        _updateOngoingSale(_nftContractAddress, _tokenId);
    }

    function makeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        payable
        SaleOngoing(_nftContractAddress, _tokenId)
    {
        _makeOffer(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
    }

    function makeCustomOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount,
        address _nftRecipient
    )
        external
        payable
        SaleOngoing(_nftContractAddress, _tokenId)
        notZeroAddress(_nftRecipient)
    {
        nftOffers[_nftContractAddress][_tokenId]
            .nftRecipient = _nftRecipient;
        _makeOffer(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║        Offer FUNCTIONS         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE Sale         ║
      ╚══════════════════════════════╝*/

    /***************************************************************
     * Copy  NFT to sale contract if the buyNowPrice is met. Then the sale could be settled*
     ***************************************************************/
    function _updateOngoingSale(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToSaleContract(_nftContractAddress, _tokenId);
            emit NFTMovedToSaleContract(_nftContractAddress, _tokenId);
        //    _transferNftAndPaySeller(_nftContractAddress, _tokenId);
            return;
        }
    }

     /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       UPDATE Sale         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/

    /*
     * Reset all Sale related parameters for an NFT.
     * This effectively removes an NFT as an item up for Sale
     */
    function _resetSale(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftOffers[_nftContractAddress][_tokenId].buyNowPrice = 0;
        nftOffers[_nftContractAddress][_tokenId].nftSeller = address(
            0
        );
        nftOffers[_nftContractAddress][_tokenId].ERC20Token = address(
            0
        );
        nftOffers[_nftContractAddress][_tokenId]
            .offerIncreasePercentage = 0;
    }

    /*
     * Reset all Offer related parameters for an NFT.
     * This effectively sets an NFT as having no active Offers
     */
    function _resetOffers(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftOffers[_nftContractAddress][_tokenId]
            .nftHighestBidder = address(0);
        nftOffers[_nftContractAddress][_tokenId].nftHighestOffer = 0;
        nftOffers[_nftContractAddress][_tokenId]
            .nftRecipient = address(0);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║         UPDATE OfferS          ║
      ╚══════════════════════════════╝*/
    /******************************************************************
     * Internal functions that update Offer parameters and reverse Offers *
     * to ensure contract only holds the highest Offer.                 *
     ******************************************************************/
    function _updateHighestOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address SaleERC20Token = nftOffers[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_isERC20Sale(SaleERC20Token)) {
            IERC20(SaleERC20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            nftOffers[_nftContractAddress][_tokenId]
                .nftHighestOffer = _tokenAmount;
        } else {
            nftOffers[_nftContractAddress][_tokenId]
                .nftHighestOffer = uint128(msg.value);
        }
        nftOffers[_nftContractAddress][_tokenId]
            .nftHighestBidder = msg.sender;
    }

    function _reverseAndResetPreviousOffer(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;

        uint128 nftHighestOffer = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestOffer;
        _resetOffers(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestOffer);
    }

    function _reversePreviousOfferAndUpdateHighestOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address prevNftHighestBidder = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;

        uint256 prevNftHighestOffer = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestOffer;
        _updateHighestOffer(_nftContractAddress, _tokenId, _tokenAmount);

        if (prevNftHighestBidder != address(0)) {
            _payout(
                _nftContractAddress,
                _tokenId,
                prevNftHighestBidder,
                prevNftHighestOffer
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║         UPDATE OfferS          ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftOffers[_nftContractAddress][_tokenId]
            .nftSeller;
        address _nftHighestBidder = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestOffer = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestOffer;
        _resetOffers(_nftContractAddress, _tokenId);

        _payFeesAndSeller(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestOffer
        );
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );

        _resetSale(_nftContractAddress, _tokenId);
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestOffer,
            _nftHighestBidder,
            _nftRecipient
        );
    }

    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _highestOffer
    ) internal {
        uint256 feesPaid;
        for (
            uint256 i = 0;
            i <
            nftOffers[_nftContractAddress][_tokenId]
                .feeRecipients
                .length;
            i++
        ) {
            uint256 fee = _getPortionOfOffer(
                _highestOffer,
                nftOffers[_nftContractAddress][_tokenId]
                    .feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                _nftContractAddress,
                _tokenId,
                nftOffers[_nftContractAddress][_tokenId]
                    .feeRecipients[i],
                fee
            );
        }
        _payout(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            (_highestOffer - feesPaid)
        );
    }

    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal {
        address SaleERC20Token = nftOffers[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_isERC20Sale(SaleERC20Token)) {
            IERC20(SaleERC20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    function settleSale(address _nftContractAddress, uint256 _tokenId)
        external
    {
        if(_isBuyNowPriceMet(_nftContractAddress, _tokenId)){
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
            emit SaleSettled(_nftContractAddress, _tokenId, msg.sender);
        }
    }

    function closeForOffers(address _nftContractAddress, uint256 _tokenId)
        external
    {
        //only the NFT owner can prematurely close for offers but the latest offer will be kept.
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender,
            "Not NFT owner"
        );
        _resetSale(_nftContractAddress, _tokenId);
        emit SaleClosed(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawOffer(address _nftContractAddress, uint256 _tokenId)
        external
    {
        address nftHighestBidder = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        require(msg.sender == nftHighestBidder, "Cannot withdraw funds");

        uint128 nftHighestOffer = nftOffers[_nftContractAddress][
            _tokenId
        ].nftHighestOffer;
        _resetOffers(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestOffer);

        emit OfferWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE Sale         ║
      ╚══════════════════════════════╝*/

    function updateBuyNowPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newBuyNowPrice
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        nftOffers[_nftContractAddress][_tokenId]
            .buyNowPrice = _newBuyNowPrice;
        emit BuyNowPriceUpdated(_nftContractAddress, _tokenId, _newBuyNowPrice);
        _updateOngoingSale(_nftContractAddress, _tokenId);
        //    _transferNftAndPaySeller(_nftContractAddress, _tokenId);
       
    }

    /*
     * The NFT seller can opt to end an Sale by taking the current highest Offer. Sale is settled automatically
     */
    function takeHighestOffer(address _nftContractAddress, uint256 _tokenId)
        external
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        require(
            _isAOfferMade(_nftContractAddress, _tokenId),
            "cannot payout 0 Offer"
        );
        _transferNftToSaleContract(_nftContractAddress, _tokenId);
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit HighestOfferTaken(_nftContractAddress, _tokenId);
    }

    /*
     * Query the owner of an NFT deposited for Sale
     */
    function ownerOfNFT(address _nftContractAddress, uint256 _tokenId)
        external
        view
        returns (address)
    {
        address nftSeller = nftOffers[_nftContractAddress][_tokenId]
            .nftSeller;
        require(nftSeller != address(0), "NFT not deposited");

        return nftSeller;
    }

    /*
     * If the transfer of a Offer has failed, allow the recipient to reclaim their amount later.
     */
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call{
            value: amount,
            gas: 20000
        }("");
        require(successfulWithdraw, "withdraw failed");
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       UPDATE Sale         ║
      ╚══════════════════════════════╝*/
    /**********************************/
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