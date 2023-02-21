//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title An Sale Contract for selling single and batched NFTs
/// @author 1WorldOnline R&D Center
/// @notice Multiple offers and Buy Now price for  ERC721 NFT
contract NFTSale {
    //Each Offer is linked to each NFT sale (contract + tokenId + seller)
    mapping(address => mapping(uint256 => mapping(address => Offer[]))) public nftSales;
    // Offer state mapping
    mapping(address => mapping(uint256 => mapping(address => State))) public nftState;    
    // BuyNow price mapping
    mapping(address => mapping(uint256 => mapping(address => BuyNowSale))) public directSales;
    //Fees mapping
    mapping(address => mapping(uint256 => mapping(address => address[]))) public feeRecipients;
    mapping(address => mapping(uint256 => mapping(address => uint32[]))) public feePercentages;

    mapping(address => uint256) failedTransferCredits;
    enum State { Created, Release, Inactive }
    //offer limited by time max for 6 months, no ETH offers could be made, Buyer could make multiple offers.
    struct Offer {
        address nftBuyer;
        uint64  offerEnd;
        address ERC20Token;
        uint128 tokenAmount;
    }
    // Buy Now price is limited by time max for 6 months, it could be set in or ETH or in ERC20 token.
    struct BuyNowSale {
        uint64  saleEnd;
        address ERC20Token;
        uint128 buyNowPrice;
    }


    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event DirectSaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint64  saleEnd,
        address erc20Token,
        uint128 buyNowPrice
    );

    event NFTSoldOnBuyNowPrice (
        address nftContractAddress, 
        uint256 tokenId, 
        address nftSeller, 
        address nftBuyer,
        address erc20Token,
        uint128 tokenAmount
    );

    event OfferMeetBuyNowPrice(
        address nftContractAddress, 
        uint256 tokenId,
        address nftSeller,
        address nftBuyer,
        address erc20Token,
        uint128 amount            
    );

    event DirectSaleClosed(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller
    );

    event OfferMade(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftBuyer,
        uint64  offerEnd,
        address erc20Token,
        uint128 tokenAmount
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftBuyer,
        address erc20Token,
        uint128 tokenAmount
    );

    event OpenedForOffers(
        address nftContractAddress, 
        uint256 tokenId, 
        address nftSeller
    );

    event SaleClosedAndReset(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller
    );

    event OfferWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftBuyer,
        address _erc20Token,
        uint128 _tokenAmount 
    );

    event OfferTaken(
        address nftContractAddress, 
        uint256 tokenId,
        address nftSeller,
        address nftBuyer,
        address erc20Token,
        uint128 tokenAmount
    );

    event OfferExpired (
        address nftContractAddress, 
        uint256 tokenId,
        address nftSeller,
        address nftBuyer,
        address erc20Token,
        uint128 tokenAmount
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

    modifier saleOngoing(address _nftContractAddress, uint256 _tokenId, address _nftSeller) {
        require(
            _isSaleOngoing(_nftContractAddress, _tokenId, _nftSeller),
            "Sale has ended"
        );
        _;
    }

    // max duration is 6 months
    modifier correctDuration(uint64 _periodEnd){
        require(
            _periodEnd > uint64(block.timestamp) &&
                _periodEnd <= (uint64(block.timestamp) + 183 days), 
            "Duration is not valid"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(
            _price > 0, 
            "Price cannot be 0"
        );
        _;
    }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender != 
                IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Seller cannot make an offer on own NFT"
        );
        _;
    }

    modifier onlyNftOwner(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender ==
                IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Only nft owner"
        );
        _;
    }

    modifier isNotASale(address _nftContractAddress, uint256 _tokenId, address _nftSeller) {
        require(
            _isSaleInactive(_nftContractAddress, _tokenId, _nftSeller),
            "Not applicable for a sale"
        );
        _;
    }
 
    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(
                totalPercent <= 10000, 
                "Fee percentages exceed maximum"
            );
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

    /*
     * Payment is accepted if the payment is made in the ERC20 token or ETH specified by the seller.
     */
    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        address _erc20Token
    ) {
        require(
            _isPaymentAccepted(_nftContractAddress, _tokenId, _nftSeller, _erc20Token),
            "Offer should be in specified ERC20/Eth"
        );
        _;
    }

    modifier amountMeetsRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        address _erc20Token,
        uint128 _tokenAmount
    ) {
        require(
            _doesAmountMeetRequirements(
                _nftContractAddress,
                _tokenId,
                _nftSeller,
                _erc20Token,
                _tokenAmount
            ),
            "Not enough funds to buy NFT"
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
    }

    /*╔══════════════════════════════╗
      ║    STATE CHECK FUNCTIONS     ║
      ╚══════════════════════════════╝*/
    /*
     * An NFT is open for offers 
     */
    function _isSaleOngoing(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal view returns (bool)
    {
        return (nftState[_nftContractAddress][_tokenId][_nftSeller] != State.Release &&
        nftState[_nftContractAddress][_tokenId][_nftSeller] != State.Inactive );
    }

    // NFT hidden
    function _isSaleInactive(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal view returns (bool)
    {
        return (nftState[_nftContractAddress][_tokenId][_nftSeller] == State.Inactive);
    }

    // Offer valid until not expired and Buer balance is sufficient
    function _isOfferValid(
        address _nftContractAddress, 
        uint256 _tokenId, 
        address _nftSeller, 
        address _nftBuyer,
        address _erc20Token,
        uint128 _tokenAmount
    ) 
        internal view returns (bool) 
    {
        uint64 _offerEnd =
            _getOfferEnd(_nftContractAddress, _tokenId, _nftSeller, _nftBuyer, _erc20Token, _tokenAmount);
        return (
            _offerEnd > uint64(block.timestamp)
        );
    }

    // Payment should be not less Buy Now price
    function _doesAmountMeetRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        address _erc20Token,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        uint128 buyNowPrice = directSales[_nftContractAddress][_tokenId][_nftSeller]
            .buyNowPrice;
        return (msg.value >= buyNowPrice && _erc20Token == address(0)) || 
            (_tokenAmount >= buyNowPrice && _erc20Token != address(0));
    }

    /**
     * Payment should be in the curreency of proposal
     */
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        address _OfferERC20Token
    ) internal view returns (bool) {
        address SaleERC20Token = directSales[_nftContractAddress][_tokenId][_nftSeller]
            .ERC20Token;
        if (SaleERC20Token != address(0)) {
            return
                msg.value == 0 &&
                SaleERC20Token == _OfferERC20Token;
        } else {
            return
                msg.value != 0 &&
                _OfferERC20Token == address(0);
        }
    }

    /*
     * If the buy now price is set in ERC20, check that the highest Offer in that currency exceeds that price.
     */
    function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal
        view
        returns (bool, address, address, uint128)
    {
        address _erc20Token = directSales[_nftContractAddress][_tokenId][_nftSeller]
            .ERC20Token;
        if(_erc20Token != address(0)) {
            uint128 _buyNowPrice = directSales[_nftContractAddress][_tokenId][_nftSeller]
                .buyNowPrice;
            address _buyer;
            uint128 _currentOffer;
            uint size = nftSales[_nftContractAddress][_tokenId][_nftSeller].length;
            for (uint i = 0; i < size; i++) {
                if (nftSales[_nftContractAddress][_tokenId][_nftSeller][i]
                    .ERC20Token == _erc20Token) {
                    _currentOffer = nftSales[_nftContractAddress][_tokenId][_nftSeller]
                        [i].tokenAmount;
                    if(_currentOffer >= _buyNowPrice) {
                        _buyer = nftSales[_nftContractAddress][_tokenId][_nftSeller]
                            [i].nftBuyer;
                    return (true,  _buyer, _erc20Token, _currentOffer);
                    }
                }  
            }
        }
        return (false, address(0), address(0), 0); //offers are taken only in ERC20 tokens       
    }

    //sale should not expire and price should not be 0
    function isBuyNowPriceSet(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller
    ) internal view returns (bool) {
        return (
            directSales[_nftContractAddress][_tokenId][_nftSeller].buyNowPrice != 0 &&
                directSales[_nftContractAddress][_tokenId][_nftSeller].saleEnd >= uint64(block.timestamp)
        );
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    STATE CHECK FUNCTIONS     ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║    STATE CHANGE FUNCTIONS    ║
      ╚══════════════════════════════╝*/
    /**********************************/
 
     function openForOffers(address _nftContractAddress, uint256 _tokenId)
        external
        isNotASale(_nftContractAddress, _tokenId, msg.sender)
        onlyNftOwner(_nftContractAddress, _tokenId)
    {
        nftState[_nftContractAddress][_tokenId][msg.sender] == State.Created;
        emit OpenedForOffers(_nftContractAddress, _tokenId, msg.sender);
    }

    //only the NFT owner can prematurely close NFT and clear offers
    function closeForOffersAndReset(address _nftContractAddress, uint256 _tokenId)
        external
        onlyNftOwner(_nftContractAddress, _tokenId)
    {
         _resetOffers(_nftContractAddress, _tokenId, msg.sender);
        nftState[_nftContractAddress][_tokenId][msg.sender] == State.Inactive;
        emit SaleClosedAndReset(_nftContractAddress, _tokenId, msg.sender);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    STATE CHANGE FUNCTIONS    ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /*****************************************************************
     * These functions check if the applicable Sale parameter has *
     * been set by the NFT seller. If not, return the default value. *
     *****************************************************************/

    function _getOfferEnd(
        address _nftContractAddress, 
        uint256 _tokenId, 
        address _nftSeller, 
        address _nftBuyer,
        address _erc20Token,
        uint128 _tokenAmount
    )
        internal view returns (uint64)
    {
        uint size = nftSales[_nftContractAddress][_tokenId][_nftSeller].length;
        uint64 _offerEnd;
        for (uint i = 0; i < size; i++) {
            if (nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].nftBuyer == _nftBuyer &&
                nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].ERC20Token == _erc20Token &&
                nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].tokenAmount == _tokenAmount              
                )  
                    _offerEnd = nftSales[_nftContractAddress][_tokenId][_nftSeller]
                        [i].offerEnd;
        }
        return _offerEnd;
    }

    /*
     * Returns the percentage of the total bid (used to calculate fee payments)
     */
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
        internal pure returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║        OFFER FUNCTIONS      ║
      ╚═════════════════════════════╝*/

    /********************************************************************
     * Make offers with an ERC20 Tokens. User could do many offers.     *
     * Offer sum should be approved for transfer from user wallet to    *
     * the contract address.                                            *
     ********************************************************************/

    function _makeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint64  _offerEnd,
        address _erc20Token,
        uint128 _tokenAmount
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_tokenAmount)
    {
        nftSales[_nftContractAddress][_tokenId][_nftSeller]
            .push(Offer(msg.sender, _offerEnd, _erc20Token, _tokenAmount ));

        if (!_isSaleOngoing(_nftContractAddress, _tokenId, _nftSeller)) 
            nftState[_nftContractAddress][_tokenId][_nftSeller] = State.Created;
        emit OfferMade(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            msg.sender,
            _offerEnd,
            _erc20Token,
            _tokenAmount
        );
        _updateOngoingSale(_nftContractAddress, _tokenId, _nftSeller); 
   }

    function makeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint64  _offerEnd,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        saleOngoing(_nftContractAddress, _tokenId, _nftSeller)
        correctDuration(_offerEnd)
    {
        require(
            !_isOfferValid(_nftContractAddress, _tokenId, _nftSeller, msg.sender, _erc20Token, _tokenAmount),
            'Previous Offer is not expired'
        );
        _makeOffer(_nftContractAddress, _tokenId, _nftSeller, _offerEnd, _erc20Token, _tokenAmount);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║        OFFER FUNCTIONS       ║
      ╚══════════════════════════════╝*/
    /**********************************/

      /*╔══════════════════════════════╗
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/

    /*
     * Reset all offers related parameters for an NFT.
     */
    function _resetOffers(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal
    {
        delete nftSales[_nftContractAddress][_tokenId][_nftSeller];
    }

    /*
     * Reset direct sale related parameters for an NFT.
     */
    function _resetDirectSale(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal
    {
        directSales[_nftContractAddress][_tokenId][_nftSeller]
            .saleEnd = 0;
        directSales[_nftContractAddress][_tokenId][_nftSeller]
            .buyNowPrice = 0;
        directSales[_nftContractAddress][_tokenId][_nftSeller]
            .ERC20Token = address(0);
        delete feePercentages[_nftContractAddress][_tokenId][_nftSeller];
        delete feeRecipients[_nftContractAddress][_tokenId][_nftSeller];
    }

    /*
     * Reset expired offers related parameters for an NFT.
     */
    function resetExpiredOffers(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        external
    {
        uint size = nftSales[_nftContractAddress][_tokenId][_nftSeller].length;
        uint activeCount = size;
        uint64 currentTime = uint64(block.timestamp);
        for (uint i = 0; i < size; i++) {
            if (nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].offerEnd <= currentTime              
            ) {
                emit OfferExpired (
                    _nftContractAddress, 
                    _tokenId, 
                    _nftSeller,
                    nftSales[_nftContractAddress][_tokenId][_nftSeller][i].nftBuyer,
                    nftSales[_nftContractAddress][_tokenId][_nftSeller][i].ERC20Token,
                    nftSales[_nftContractAddress][_tokenId][_nftSeller][i].tokenAmount
                );
                delete nftSales[_nftContractAddress][_tokenId][_nftSeller][i];
                activeCount --;
            }
        }
        if (activeCount == 0) 
            delete nftSales[_nftContractAddress][_tokenId][_nftSeller];
    }


    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    /**********************************/

    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,  
        address _nftBuyer,
        address _erc20Token,
        uint128 _tokenAmount
    ) internal {
        IERC721(_nftContractAddress).transferFrom(
            _nftSeller,
            _nftBuyer,
            _tokenId
        );
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftBuyer,
                "nft transfer failed"
        );
        _payFeesAndSeller(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftBuyer,
            _erc20Token,
            _tokenAmount
        );

    }

    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        address _nftBuyer,
        address _erc20Token,
        uint256 _tokenAmount
     ) internal {
        uint256 feesPaid;
        for (
            uint256 i = 0;
            i <  feeRecipients[_nftContractAddress][_tokenId][_nftSeller].length;
            i++
        ) {
            uint256 fee = _getPortionOfBid(
                _tokenAmount,
                feePercentages[_nftContractAddress][_tokenId][_nftSeller][i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                _erc20Token,
                _nftBuyer,
                feeRecipients[_nftContractAddress][_tokenId][_nftSeller][i],
                fee
            );
        }
        _payout(
            _erc20Token,
            _nftBuyer,
            _nftSeller,
            (_tokenAmount - feesPaid)
        );
    }

    function _payout(
        address _erc20Token,
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        if (_erc20Token != address(0)) {
            IERC20(_erc20Token).transferFrom(_sender, _recipient, _amount);
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
      ║         WITHDRAW             ║
      ╚══════════════════════════════╝*/

    //only Buyer could withdaw his offer
    function withdrawOffer(
        address _nftContractAddress, 
        uint256 _tokenId, 
        address _nftSeller,
        address _erc20Token,
        uint128 _tokenAmount        
    )
        external
    {
        uint size = nftSales[_nftContractAddress][_tokenId][_nftSeller].length;
        bool deleted = false;
        for (uint i = 0; i < size; i++) {
            if (nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].nftBuyer == msg.sender &&
                nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].ERC20Token == _erc20Token &&
                nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].tokenAmount == _tokenAmount
                ) {
                    delete nftSales[_nftContractAddress][_tokenId][_nftSeller]
                    [i];
                    deleted = true;
            }
        }
        if (deleted)  
            emit OfferWithdrawn(_nftContractAddress, _tokenId, _nftSeller, msg.sender, _erc20Token, _tokenAmount);
    }

    // Withdraw BuyNow price,
    function withdrawDirectSale(address _nftContractAddress, uint256 _tokenId)
        external
        onlyNftOwner(_nftContractAddress, _tokenId)
    {
         _resetDirectSale(_nftContractAddress, _tokenId, msg.sender);
        emit DirectSaleClosed(_nftContractAddress, _tokenId, msg.sender);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║         END WITHDRAW         ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║       TAKE OFFER             ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*
     * The NFT seller can opt to end an Sale by taking any offer.
     */
    function takeOffer(
        address _nftContractAddress, 
        uint256 _tokenId,  
        address _nftBuyer,
        address _erc20Token,
        uint128 _tokenAmount,
        address[]  memory _feeRecipients,
        uint32[] memory   _feePercentages        
    )
        external
        onlyNftOwner(_nftContractAddress, _tokenId)
        correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        
        require(
            _isOfferValid(_nftContractAddress, _tokenId, msg.sender, _nftBuyer, _erc20Token, _tokenAmount),
            'Offer is expired'
        );

        require(
            IERC20(_erc20Token).balanceOf(_nftBuyer) >= _tokenAmount,
            'Buyer balance is low'
        );
        _updateFees (_nftContractAddress, _tokenId, msg.sender, _feeRecipients, _feePercentages);
        _transferNftAndPaySeller(
            _nftContractAddress, 
            _tokenId,
            msg.sender,
            _nftBuyer,
            _erc20Token,
            _tokenAmount
         );
        _resetOffers(_nftContractAddress, _tokenId, msg.sender);
        emit OfferTaken(
            _nftContractAddress, 
            _tokenId, 
            msg.sender,
            _nftBuyer,
            _erc20Token,
            _tokenAmount 
        );
    }


    /**********************************/
    /*╔══════════════════════════════╗
      ║        END TAKE OFFER        ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║        FEES FUBCTIONS        ║
      ╚══════════════════════════════╝*/
    /**********************************/

    //update Fees for NFT
    function _updateFees (
        address _nftContractAddress, 
        uint256 _tokenId,  
        address _nftSeller,
        address[] memory   _feeRecipients,
        uint32[] memory     _feePercentages        
    ) internal {
        delete feeRecipients[_nftContractAddress][_tokenId][_nftSeller];
        delete feePercentages[_nftContractAddress][_tokenId][_nftSeller];
        feeRecipients[_nftContractAddress][_tokenId][_nftSeller] =  _feeRecipients;
        feePercentages[_nftContractAddress][_tokenId][_nftSeller] =  _feePercentages;
    }

    /**********************************/
    /*╔═════════════════════════╗
      ║        END FEES         ║
      ╚═════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║      BUY NOW FUNCTIONS      ║
      ╚═════════════════════════════╝*/

    /************************************************************
     * Set Buy Now to sale directly in ETH or any ERC20 Tokens. *
     * Direct salecould not be set more than on 6 months.       *
     * Set ERC20Token = address(0) to set price in ETH.         *
     ************************************************************/

    function _setDirectSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint64  _saleEnd,
        address _erc20Token,
        uint128 _buyNowPrice
    )
    internal 
    priceGreaterThanZero(_buyNowPrice)
    correctDuration(_saleEnd)
    {
        directSales[_nftContractAddress][_tokenId][_nftSeller]
                .ERC20Token = _erc20Token;
          directSales[_nftContractAddress][_tokenId][_nftSeller]
            .buyNowPrice = _buyNowPrice;
          directSales[_nftContractAddress][_tokenId][_nftSeller].
            saleEnd = _saleEnd;
        emit DirectSaleCreated(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _saleEnd,
            _erc20Token,
            _buyNowPrice
        );
    }

    function setBuyNowPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint64  _saleEnd,
        address _erc20Token,
        uint128 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    external
    onlyNftOwner(_nftContractAddress, _tokenId)
    correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
    isFeePercentagesLessThanMaximum(_feePercentages)
    {
        _setDirectSale(_nftContractAddress, _tokenId, msg.sender, _saleEnd, _erc20Token, _buyNowPrice);
        _updateFees (_nftContractAddress, _tokenId, msg.sender, _feeRecipients, _feePercentages);
       _updateOngoingSale(_nftContractAddress, _tokenId, msg.sender); // send event if BuyNow price is met
    }

   // Buy NFT on BuyNow price 
   function buyNFT(
        address _nftContractAddress, 
        uint256 _tokenId,  
        address _nftSeller,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external payable
        paymentAccepted(_nftContractAddress, _tokenId, _nftSeller, _erc20Token)
        amountMeetsRequirements(_nftContractAddress, _tokenId, _nftSeller, _erc20Token, _tokenAmount) 
    {
        require(
            msg.sender != 
                IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Owner cannot buy own NFT"
        );
        require(
            isBuyNowPriceSet(_nftContractAddress, _tokenId, _nftSeller),
            "BuyNow price is not set"
        );
        _transferNftAndPaySeller(
            _nftContractAddress, 
            _tokenId,
            _nftSeller, 
            msg.sender,
            _erc20Token,
            _tokenAmount
        );
        _resetOffers(_nftContractAddress, _tokenId, _nftSeller);
        _resetDirectSale(_nftContractAddress, _tokenId, _nftSeller);
        emit NFTSoldOnBuyNowPrice (
            _nftContractAddress, 
            _tokenId, 
            _nftSeller, 
            msg.sender,
            _erc20Token,
            _tokenAmount
        );
    }
       
    // Check offers vs Buy Now price
    function _updateOngoingSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller
    ) internal {
        (bool result, address _buyer, address _erc20Token, uint128 _amount) =
            _isBuyNowPriceMet(_nftContractAddress, _tokenId, _nftSeller);
        if (result) {
            emit OfferMeetBuyNowPrice(
                _nftContractAddress, 
                _tokenId,
                _nftSeller,
                _buyer,
                _erc20Token,
                _amount            
            );
        }
    }
    /*╔════════════════════════════════╗
      ║     END BUY NOW FUNCTIONS      ║
      ╚════════════════════════════════╝*/
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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