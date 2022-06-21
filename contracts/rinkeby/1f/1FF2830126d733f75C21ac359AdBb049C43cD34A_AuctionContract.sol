// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "IERC721.sol";
import "IERC20.sol";
import "Ownable.sol";


//                          &&&&&%%%%%%%%%%#########*
//                      &&&&&&&&%%%%%%%%%%##########(((((
//                   @&&&&&&&&&%%%%%%%%%##########((((((((((
//                @@&&&&&&&&&&%%%%%%%%%#########(((((((((((((((
//              @@@&&&&&&&&%%%%%%%%%%##########((((((((((((((///(
//            %@@&&&&&&               ######(                /////.
//           @@&&&&&&&&&           #######(((((((       ,///////////
//          @@&&&&&&&&%%%           ####((((((((((*   .//////////////
//         @@&&&&&&&%%%%%%          ##((((((((((((/  ////////////////*
//         &&&&&&&%%%%%%%%%          *(((((((((//// //////////////////
//         &&&&%%%%%%%%%####          .((((((/////,////////////////***
//        %%%%%%%%%%%########.          ((/////////////////***********
//         %%%%%##########((((/          /////////////****************
//         ##########((((((((((/          ///////*********************
//         #####((((((((((((/////          /*************************,
//          #(((((((((////////////          *************************
//           (((((//////////////***          ***********************
//            ,//////////***********        *************,*,,*,,**
//              ///******************      *,,,,,,,,,,,,,,,,,,,,,
//                ******************,,    ,,,,,,,,,,,,,,,,,,,,,
//                   ****,,*,,,,,,,,,,,  ,,,,,,,,,,,,,,,,,,,
//                      ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                          .,,,,,,,,,,,,,,,,,,,,,,,


/**
 * @title Auction Contract for NFTs
 * @author VINCI
 * @notice This contract is meant to be used with the Vinci NFT contract and
 * Vinci ERC20 token.
 */
contract AuctionContract is Ownable {
    /// The backing NFT contract
    IERC721 private nftContract;

    /// Tokens withdrawable by address of the ERC20 token.
    mapping(address => mapping(address => uint256)) public withdrawable;

    /// Current sales
    mapping(uint256 => Sale) private _sales;

    /// Current english auctions
    mapping(uint256 => EnglishAuction) public englishAuctions;

    /// Current dutch auctions
    mapping(uint256 => DutchAuction) public dutchAuctions;

    /// Reentrancy lock
    bool private _locked;

    /// Fee in basis points
    uint256 public fee;

    // Margin in seconds for Dutch auction
    uint8 public marginSecondsDutchAuction = 180;

    /**
     * @notice An object describing a price
     * @param erc20Contract The address of the erc20 contract
     * @param price         The amount specified in erc20
     */
    struct Price {
        address erc20Contract;
        uint256 price;
    }

    /**
     * @dev An object describing a sale.
     * @param owner The owner of the NFT
     * @param erc20Contracts ERC20 contracts
     * @param prices         The prices of the NFT (denoted in erc20Contracts)
     * @dev Note that storage[] struct is not supported in Solidity, so we have
     *      to work around this by storing the values separately.
     */
    struct Sale {
        address owner;
        address[] erc20Contracts;
        uint256[] prices;
    }

    /**
     * @dev An object describing an english auction. English auctions are
     *      restricted by time. Any bid extends by a given amount of seconds.
     *
     * @param owner        The owner of the NFT
     * @param minPrice     The minimum amount that needs to be bid
     * @param bidder       The currently highest bidder. If no bid has been
     *                     made so far, bidder is address(0)
     * @param amount       The amount of the highest bid. If no bid has
     *                     been made so far, amount is 0
     * @param erc20token   Token used for bidding. Use address(0) for native payments
     * @param closeTime    The time when the auction closes
     * @param timeIncrease Amount of time added to the close time on every
     *                     bid
     */
    struct EnglishAuction {
        address owner;
        uint256 minPrice;
        address bidder;
        uint256 amount;
        address erc20token;
        uint256 closeTime;
        uint256 timeIncrease;
    }

    /**
     * @dev An object describing a dutch auction.
     * @param owner         The owner of the NFT
     * @param startPrice    The starting price of the dutch auction
     * @param endPrice      The ending price of the dutch auction
     * @param start         Timestamp of the auction start. It establishes when the price starts decreasing,
     although it can be bought before the start date.
     * @param end           Timestamp of the auction end. It establishes when the price stops decreasing,
     although it can be bought after this date.
     * @param erc20token    token used for the auction. Address(0) if native payment
     */
    struct DutchAuction {
        address owner;
        uint256 startPrice;
        uint256 endPrice;
        uint256 start;
        uint256 end;
        address erc20token;
    }

    modifier reentrancyLock() {
        require(!_locked, "locked");
        _locked = true;
        _;
        _locked = false;
    }

    modifier notSoldOrInAuction(uint256 tokenId) {
        require(
            _sales[tokenId].owner == address(0),
            "Token is already being sold"
        );
        require(
            englishAuctions[tokenId].owner == address(0),
            "Token is already in english auction"
        );
        require(
            dutchAuctions[tokenId].owner == address(0),
            "Token is already in dutch auction"
        );
        _;
    }

    modifier beingSold(uint256 tokenId) {
        require(_sales[tokenId].owner != address(0), "Token is not being sold");
        _;
    }

    modifier beingEnglishAuctioned(uint256 tokenId) {
        require(
            englishAuctions[tokenId].owner != address(0),
            "Token is not being auctioned"
        );
        require(
            englishAuctions[tokenId].closeTime > block.timestamp,
            "Auction is closed"
        );
        _;
    }

    // Start and end dates of Dutch auction do not modify the beingDutchAuctioned status.
    // It can be sold at any time regardless of start and end date.
    modifier beingDutchAuctioned(uint256 tokenId) {
        require(
            dutchAuctions[tokenId].owner != address(0),
            "Token is not being auctioned"
        );
        _;
    }

    /**
     * @dev Event for the start of a sale
     * @param tokenId The id of the NFT
     * @param owner   The owner of the NFT
     * @param prices  List of prices of the sale (list of Price struct)
     */
    event SaleStarted(uint256 tokenId, address owner, Price[] prices);

    /**
     * @dev Event for the start of a sale
     * @param tokenId The id of the NFT
     * @param owner   The owner of the NFT
     * @param erc20TokenSale  erc20 contract address (zero for native payments)
     * @param price   Price of the sale
     */
    event SaleStartedInBatch(uint256 tokenId, address owner, address erc20TokenSale, uint price);

    /**
     * @dev Event for the cancel of a sale
     * @param tokenId The id of the NFT
     * @param owner   The owner of the NFT
     */
    event SaleCanceled(uint256 tokenId, address owner);

    /**
     * @dev Event for a successful sale
     * @param tokenId       The id of the NFT
     * @param price         The price of the NFT (denoted in erc20contract)
     * @param buyer         The buyer of the NFT
     * @param erc20contract The buyer of the NFT
     */
    event NFTSold(
        uint256 tokenId,
        uint256 price,
        address buyer,
        address erc20contract
    );

    /**
     * @dev Event for the start of an english auction
     * @param tokenId      The id of the NFT
     * @param minPrice     The minimum bid
     * @param owner        The owner of the NFT
     * @param erc20token   Token address in which NFT is being auctioned
     * @param closeTime    Timestamp when this auction closes
     * @param timeIncrease Amount of seconds added to close time on every bid
     */
    event EnglishAuctionStarted(
        uint256 tokenId,
        uint256 minPrice,
        address owner,
        address erc20token,
        uint256 closeTime,
        uint256 timeIncrease
    );

    /**
     * @dev Event for a new bid on an english auction
     * @param tokenId The id of the NFT
     * @param amount  The bid
     * @param bidder  The bidder
     */
    event EnglishNewBid(uint256 tokenId, uint256 amount, address bidder);

    /**
     * @dev Event for a successful auction
     * @param tokenId The id of the NFT
     * @param amount  The price of the NFT (denoted in erc20contract of the auction)
     * @param buyer   The buyer of the NFT
     */
    event EnglishAuctionFinalized(
        uint256 tokenId,
        uint256 amount,
        address buyer
    );

    /**
     * @dev Event for a canceled english auction
     * @param tokenId The id of the NFT
     * @param owner   The owner of the NFT
     */
    event EnglishAuctionCanceled(uint256 tokenId, address owner);

    /**
     * @dev Event for the start of a dutch auction
     * @param tokenId    The id of the NFT
     * @param startPrice Starting price
     * @param endPrice   Ending price
     * @param start      Starting timestamp
     * @param end        Ending timestamp
     * @param erc20token    token used for the auction. Address(0) if native payment
     */
    event DutchAuctionStarted(
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 start,
        uint256 end,
        address erc20token
    );

    /**
     * @dev Event for a successful dutch auction
     * @param tokenId       The id of the NFT
     * @param amount        The price of the NFT (denoted in erc20contract of the auction)
     * @param buyer         The buyer of the NFT
     * @param erc20token    token used for the auction. Address(0) if native payment
     */
    event DutchAuctionFinalized(uint256 tokenId, uint256 amount, address buyer, address erc20token);

    /**
     * @dev Event for a canceled dutch auction
     * @param tokenId The id of the NFT
     * @param owner   The owner of the NFT
     */
    event DutchAuctionCanceled(uint256 tokenId, address owner);

    /**
     * @dev Event for a withdrawal action
     * @param erc20token   address of the token withdrawn (address(0) for native token)
     * @param amount        amount withdrawn
     * @param sender        caller
     */
    event Withdrawal(address erc20token, uint amount, address sender);

    /**
     * @dev Create a new NFT auction contract
     * @param _nftContract   The address of a ERC721 compatible NFT contract
     */
    constructor(IERC721 _nftContract) {
        nftContract = _nftContract;
        _locked = false;
        fee = 1000;
    }

    /**
     * @notice Witdraw ERC20 token that belong to me. Use this function to
     *         withdraw after a successful auction or sale, or when a bid was
     *         outbid.
     * @param _erc20token The address of the erc20 token
     */
    function withdraw(address _erc20token) public reentrancyLock {
        address sender = _msgSender();
        uint256 amount = withdrawable[sender][_erc20token];
        require(amount > 0, "Nothing to withdraw");

        withdrawable[sender][_erc20token] = 0;

        // address(0) is used as a proxy for native currency payments
        if (_erc20token == address(0)) {
            (bool success,) = sender.call{value : amount}("");
            require(success, "Native payment to address failed");
        } else {
            IERC20 _erc20contract = IERC20(_erc20token);
            require(_erc20contract.balanceOf(address(this)) >= amount, "Not enough funds in contract");
            _erc20contract.transfer(sender, amount);
        }
        emit Withdrawal(_erc20token, amount, sender);
    }

    /**
     * @notice Set the fee. Only owner.
     * @param _fee The fee specified in BPS
     */
    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= 10000, "Can't set a fee larger than 100%");
        fee = _fee;
    }

    /**
     * @notice Sets the margin in seconds for which not to take into account the price
     variations in a dutch bid
     * @param _marginSecondsDutchAuction margin in seconds
     */
    function setMarginSecondsForDutchAuction(uint8 _marginSecondsDutchAuction) public onlyOwner {
        require(_marginSecondsDutchAuction > 0, "Can't set a negative number");
        marginSecondsDutchAuction = _marginSecondsDutchAuction;
    }


    /**
     * @notice Start a new sale
     * @dev Emits a `SaleStarted` event
     * @dev While the sale proceeds, the NFT is stored inside of the sales
     *      contract.
     * @param tokenId        The id of the NFT
     * @param prices         Prices of the sale
     */
    function startSale(uint256 tokenId, Price[] calldata prices)
    public
    reentrancyLock
    notSoldOrInAuction(tokenId)
    {
        require(prices.length <= 10, "Only up to 10 prices are supported");
        require(prices.length > 0, "At least one price needs to be specified");

        uint256[] memory _prices = new uint256[](prices.length);
        address[] memory _addresses = new address[](prices.length);

        for (uint256 i = 0; i < prices.length; i++) {
            _prices[i] = prices[i].price;
            _addresses[i] = prices[i].erc20Contract;
        }

        _sales[tokenId] = Sale(_msgSender(), _addresses, _prices);

        nftContract.transferFrom(_msgSender(), address(this), tokenId);
        emit SaleStarted(tokenId, _msgSender(), prices);
    }

    /**
     * @notice Start a new sale for multiple tokenIds in the same transaction (to save gas)
               All tokens are put for sale for the same price (and the same erc20 token)
               Accepts the zero address for native payments
     * @dev Emits a `SaleStartedInBatch` event
     * @dev While the sale proceeds, the NFT is stored inside of the sales
     *      contract.
     * @param tokenIds        The id of the NFT
     * @param _erc20Contract  Contract address of the erc20 to put for sale (or zero address for native)
     * @param _price          Price for the sale
     */
    function startBatchSale(uint256[] calldata tokenIds, address _erc20Contract, uint256 _price) public {
        require(tokenIds.length < 301, "Only up to 300 tokenIds at once");

        address[] memory _addresses = new address[](1);
        uint256[] memory _prices = new uint256[](1);

        _addresses[0] = _erc20Contract;
        _prices[0] = _price;

        for (uint i = 0; i < tokenIds.length; i++) {
            _sales[tokenIds[i]] = Sale(_msgSender(), _addresses, _prices);
            nftContract.transferFrom(_msgSender(), address(this), tokenIds[i]);
            emit SaleStartedInBatch(tokenIds[i], _msgSender(), _erc20Contract, _price);
        }
    }

    /**
     * @notice Cancel of an ongoing sale
     * @dev Emits a `SaleCanceled` event
     * @notice Returns the NFT to its owner
     * @param tokenId The id of the token
     * @dev Requires to be executed as the same account that initially crated
     *      the sale.
     */
    function cancelSale(uint256 tokenId)
    public
    reentrancyLock
    beingSold(tokenId)
    {
        require(_msgSender() == _sales[tokenId].owner, "Must be token owner");
        delete _sales[tokenId].owner;
        delete _sales[tokenId].prices;
        delete _sales[tokenId].erc20Contracts;
        nftContract.transferFrom(address(this), _msgSender(), tokenId);
        emit SaleCanceled(tokenId, _msgSender());
    }

    /**
     * @notice Buy an NFT for sale. Requires ERC20 to be approved. Use address(0) to buy with native token
     * @dev Transfers NFT, makes ERC20 claimable
     * @param tokenId       The id of the token to buy
     * @param _erc20Contract The address of the ERC20 the buyer wants to use. Use address(0) to buy
     with native token
     */
    function buy(uint256 tokenId, address _erc20Contract)
    public
    payable
    reentrancyLock
    beingSold(tokenId)
    {
        uint256 price = 0;
        bool found = false;
        for (uint256 i = 0; i < _sales[tokenId].erc20Contracts.length; i++) {
            if (_sales[tokenId].erc20Contracts[i] == _erc20Contract) {
                found = true;
                price = _sales[tokenId].prices[i];
            }
        }
        require(
            found,
            "The token is not being sold in exchange for the given erc20 address"
        );

        _addWithdrawable(_sales[tokenId].owner, _erc20Contract, price);
        delete _sales[tokenId].owner;
        delete _sales[tokenId].prices;
        delete _sales[tokenId].erc20Contracts;

        // Execute payments
        if (_erc20Contract == address(0)) {
            // for native payments, the payment needs to come in the msg.value
            require(msg.value == price, "Not enough value to purchase");
        } else {
            IERC20 erc20 = IERC20(_erc20Contract);
            require(msg.value == 0, "Payment cannot be in ERC20 and native currency simultaneously");
            require(erc20.balanceOf(_msgSender()) >= price, "Not enough token balance");
            erc20.transferFrom(_msgSender(), address(this), price);
        }
        nftContract.transferFrom(address(this), _msgSender(), tokenId);

        emit NFTSold(tokenId, price, _msgSender(), _erc20Contract);
    }


    /**
     * @notice Start a new english auction. The NFT is kept in this contract
     *         during the auction
     * @param tokenId      The id of the token to start auctioning
     * @param minPrice     The minimum amount a bid should be
     * @param erc20token   Token address in which the item is being auctioned
     * @param closeTime    Timestamp when the auction should close
     * @param timeIncrease How many seconds are added for every bid?
     */
    function englishStartAuction(
        uint256 tokenId,
        uint256 minPrice,
        uint256 closeTime,
        uint256 timeIncrease,
        address erc20token
    ) public reentrancyLock notSoldOrInAuction(tokenId) {
        // It must be -1, because bids can only enter if greater than current amount
        uint amount = minPrice == 0 ? 0 : minPrice - 1;

        englishAuctions[tokenId] = EnglishAuction(
            _msgSender(),
            minPrice,
            address(0),
            amount,
            erc20token,
            closeTime,
            timeIncrease
        );
        nftContract.transferFrom(_msgSender(), address(this), tokenId);
        emit EnglishAuctionStarted(
            tokenId,
            minPrice,
            _msgSender(),
            erc20token,
            closeTime,
            timeIncrease
        );
    }

    /**
     * @notice Bid on an english auction
     * @param tokenId Id of token
     * @param amount  Amount being bid
     */
    function englishBid(uint256 tokenId, uint256 amount)
    public
    payable
    reentrancyLock
    beingEnglishAuctioned(tokenId) {

        address sender = _msgSender();
        address erc20BidToken = englishAuctions[tokenId].erc20token;

        require(amount >= englishAuctions[tokenId].amount, "Bid is not high enough");

        // store tokens from the previous bidder in a withdrawable
        if (englishAuctions[tokenId].bidder != address(0)) {
            withdrawable[englishAuctions[tokenId].bidder][
            address(englishAuctions[tokenId].erc20token)
            ] += englishAuctions[tokenId].amount;
        }

        englishAuctions[tokenId].bidder = sender;
        englishAuctions[tokenId].amount = amount;
        englishAuctions[tokenId].closeTime += englishAuctions[tokenId]
        .timeIncrease;

        if (erc20BidToken == address(0)) {
            // for native payments, the payment needs to come in the msg.value
            require(msg.value == amount, "Value not matching amount");
        } else {
            require(msg.value == 0, "No need to add value if paid with ERC20");
            IERC20 erc20BidContract = IERC20(erc20BidToken);
            // if sender does not have enough tokens, the transaction will simply revert
            erc20BidContract.transferFrom(sender, address(this), amount);
        }

        emit EnglishNewBid(tokenId, amount, _msgSender());
    }

    /**
     * @notice Cancel English auction. This is only possible as long as there
     *         has not been any bids so far.
     * @param tokenId The token to cancel the auction for
     */
    function englishCancelAuction(uint256 tokenId) public reentrancyLock {
        require(
            englishAuctions[tokenId].owner == _msgSender(),
            "Must be token owner"
        );
        require(
            englishAuctions[tokenId].bidder == address(0),
            "There is already a bid, can't cancel anymore"
        );

        _deleteEnglishAuction(tokenId);

        nftContract.transferFrom(address(this), _msgSender(), tokenId);
        emit EnglishAuctionCanceled(tokenId, _msgSender());
    }

    /**
     * @notice Finalize an english auction. Call this once the auction is over
     *         to accept the final bid.
     * @param tokenId The token id
     */
    function englishFinalizeAuction(uint256 tokenId) public reentrancyLock {
        require(
            englishAuctions[tokenId].owner != address(0),
            "Token is not being auctioned"
        );
        require(
            englishAuctions[tokenId].closeTime <= block.timestamp ||
            _msgSender() == englishAuctions[tokenId].owner,
            "Only the owner can finalize the auction before its end"
        );
        require(
            englishAuctions[tokenId].bidder != address(0),
            "No bid has been made"
        );

        uint256 amount = englishAuctions[tokenId].amount;
        _addWithdrawable(
            englishAuctions[tokenId].owner,
            englishAuctions[tokenId].erc20token,
            amount
        );

        nftContract.transferFrom(
            address(this),
            englishAuctions[tokenId].bidder,
            tokenId
        );

        emit EnglishAuctionFinalized(
            tokenId,
            amount,
            englishAuctions[tokenId].bidder
        );

        _deleteEnglishAuction(tokenId);
    }

    /**
     * @notice Starts a new dutch auction. The NFT is kept in this contract
     *         during the auction
     * @param tokenId       The id of the token
     * @param startPrice    Starting price
     * @param endPrice      Ending price
     * @param start         Starting timestamp
     * @param end           Ending timestamp
     * @param erc20token    token used for the auction. Address(0) if native payment
     */
    function dutchStartAuction(
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 start,
        uint256 end,
        address erc20token
    ) public reentrancyLock notSoldOrInAuction(tokenId) {
        require(startPrice > endPrice, "Price has to be decreasing with time");
        require(start < end, "End has to be after start");

        dutchAuctions[tokenId] = DutchAuction(
            _msgSender(),
            startPrice,
            endPrice,
            start,
            end,
            erc20token
        );
        nftContract.transferFrom(_msgSender(), address(this), tokenId);
        emit DutchAuctionStarted(tokenId, startPrice, endPrice, start, end, erc20token);
    }

    /**
     * @notice Function to determine price of dutch auction at given timestamp
     * @param tokenId   The token id
     * @param timestamp The timestamp.
     * @return The price of the token
     */
    function dutchAuctionPriceAtTimestamp(uint256 tokenId, uint256 timestamp)
    public
    view
    beingDutchAuctioned(tokenId)
    returns (uint256)
    {
        if (timestamp <= dutchAuctions[tokenId].start) {
            return dutchAuctions[tokenId].startPrice;
        }
        if (dutchAuctions[tokenId].end <= timestamp) {
            return dutchAuctions[tokenId].endPrice;
        }
        return
        dutchAuctions[tokenId].startPrice -
        ((timestamp - dutchAuctions[tokenId].start) *
        (dutchAuctions[tokenId].startPrice -
        dutchAuctions[tokenId].endPrice)) /
        (dutchAuctions[tokenId].end - dutchAuctions[tokenId].start);
    }

    /**
     * @notice Function to determine current price of dutch auction
     * @param tokenId   The token id
     * @return The price of the token
     */
    function dutchAuctionCurrentPrice(uint256 tokenId)
    public
    view
    returns (uint256)
    {
        return dutchAuctionPriceAtTimestamp(tokenId, block.timestamp);
    }

    /**
     * @notice Buy a token from a dutch auction
     * @param tokenId The id of the token
     */
    function dutchBuyToken(uint256 tokenId)
    public
    payable
    reentrancyLock
    beingDutchAuctioned(tokenId)
    {
        uint256 price = dutchAuctionCurrentPrice(tokenId);
        address erc20BidToken = dutchAuctions[tokenId].erc20token;

        _addWithdrawable(
            dutchAuctions[tokenId].owner,
            address(erc20BidToken), // address(0) for native payment
            price
        );

        if (erc20BidToken == address(0)) {
            // for native payments, the payment needs to come in the msg.value

            require(msg.value >= price, "Not enough value to purchase");
            require(msg.value < price + marginSecondsDutchAuction * _priceDropPerSecondForDutchAuction(tokenId), "Value too high");
        } else {
            IERC20 erc20BidContract = IERC20(erc20BidToken);
            erc20BidContract.transferFrom(_msgSender(), address(this), price);
        }
        nftContract.transferFrom(address(this), _msgSender(), tokenId);

        emit DutchAuctionFinalized(tokenId, price, _msgSender(), erc20BidToken);
        _deleteDutchAuction(tokenId);
    }

    /**
     * @notice Owner of NFT Cancels a dutch auction only when it has finished. Used to retrieve
     the NFT (by the owner) when nobody has set a bid on it before the end-time.
     * @param tokenId The id of the token
     */
    function dutchCancelAuction(uint256 tokenId)
    public
    reentrancyLock
    beingDutchAuctioned(tokenId)
    {
        require(
            dutchAuctions[tokenId].end <= block.timestamp,
            "Auction has not ended yet"
        );

        require(_msgSender() == dutchAuctions[tokenId].owner, "Must be token owner");

        emit DutchAuctionCanceled(tokenId, dutchAuctions[tokenId].owner);

        nftContract.transferFrom(
            address(this),
            dutchAuctions[tokenId].owner,
            tokenId
        );

        _deleteDutchAuction(tokenId);
    }

    /**
     * @notice Get owner of sale
     * @param tokenId The id of the token
     */
    function getSaleOwner(uint256 tokenId) public view returns (address) {
        return _sales[tokenId].owner;
    }

    /**
     * @notice Get number of prices of a sale
     * @param tokenId The id of the token
     */
    function getSalePricesLength(uint256 tokenId)
    public
    view
    returns (uint256)
    {
        return _sales[tokenId].prices.length;
    }

    /**
     * @notice Get a price of a sale
     * @param tokenId The id of the token
     * @param index   The index into the sale array
     */
    function getSalePrice(uint256 tokenId, uint256 index)
    public
    view
    returns (Price memory)
    {
        return
        Price(
            _sales[tokenId].erc20Contracts[index],
            _sales[tokenId].prices[index]
        );
    }

    /**
     * @notice Displays the last price bid on a tokenId that is being auctioned
     * @param tokenId The id of the token
     */
    function readEnglishAuctionCurrentPrice(uint256 tokenId) public view returns (uint){
        require(isInEnglishAuction(tokenId), "Not in English auction");
        return englishAuctions[tokenId].amount;
    }

    /**
     * @notice Reads the ERC20 in which the tokenId is being auctioned. Returns 0x address if auctioned with nativee
     * @param tokenId The id of the token
     */
    function readEnglishAuctionERC20token(uint256 tokenId) public view returns (address){
        require(isInEnglishAuction(tokenId), "Not in English auction");
        return englishAuctions[tokenId].erc20token;
    }

    /**
     * @notice Reads the ERC20 in which the tokenId is being auctioned. Returns 0x address if auctioned with nativee
     * @param tokenId The id of the token
     */
    function readDucthAuctionERC20token(uint256 tokenId) public view returns (address){
        require(isInDutchAuction(tokenId), "Not in Dutch auction");
        return dutchAuctions[tokenId].erc20token;
    }

    /**
     * @notice Displays the price of a token in a specific ERC20 token, if it is being sold on that token
     * @param tokenId The id of the token
     */
    function readSalePrice(uint256 tokenId, address _erc20token) public view returns (uint){
        require(isBeingSold(tokenId), "Not for sale");
        bool found;
        for (uint i = 0; i < getSalePricesLength(tokenId); i++) {
            Price memory price = getSalePrice(tokenId, i);
            if (_erc20token == price.erc20Contract) {
                return price.price;
            }
        }
        revert("Item is not for sale for this ERC20 token");
    }

    /**
     * @notice Checks if a specific tokenid is for sale at the moment
     * @param tokenId The id of the token
     */
    function isBeingSold(uint tokenId) public view returns (bool) {
        return _sales[tokenId].owner != address(0);
    }
    /**
     * @notice Checks if a specific tokenid is being auctioned on an English auction at the moment
     * @param tokenId The id of the token
     */
    function isInEnglishAuction(uint tokenId) public view returns (bool) {
        return englishAuctions[tokenId].owner != address(0);
    }
    /**
     * @notice Checks if a specific tokenid is being auctioned on a Dutch auction at the moment
     Start and end dates do not interfere with the status.
     * @param tokenId The id of the token
     */
    function isInDutchAuction(uint tokenId) public view returns (bool) {
        return dutchAuctions[tokenId].owner != address(0);
    }

    /**
     * @notice Checks if a specific tokenid is being sold or actioned at the moment
     * @param tokenId The id of the token
     */
    function isBeingSoldOrAuctioned(uint tokenId) public view returns (bool) {
        return (isBeingSold(tokenId) || isInEnglishAuction(tokenId) || isInDutchAuction(tokenId));
    }

    function _addWithdrawable(
        address beneficiary,
        address _erc20Contract,
        uint256 amount
    ) private {
        uint256 feeAmount = (amount * fee) / 10000;
        uint256 newAmount = amount - feeAmount;
        withdrawable[beneficiary][_erc20Contract] += newAmount;
        withdrawable[owner()][_erc20Contract] += feeAmount;
    }

    function _deleteEnglishAuction(uint256 tokenId) private {
        delete englishAuctions[tokenId].owner;
        delete englishAuctions[tokenId].minPrice;
        delete englishAuctions[tokenId].bidder;
        delete englishAuctions[tokenId].amount;
        delete englishAuctions[tokenId].closeTime;
        delete englishAuctions[tokenId].timeIncrease;
    }

    function _deleteDutchAuction(uint256 tokenId) private {
        delete dutchAuctions[tokenId].owner;
        delete dutchAuctions[tokenId].startPrice;
        delete dutchAuctions[tokenId].endPrice;
        delete dutchAuctions[tokenId].start;
        delete dutchAuctions[tokenId].end;
    }

    /**
     * @notice Calculates the drop in price per second of an NFT being dutch auctioned.
     * Important: returns a positive value
     * @param tokenId    TokenId that is in dutch auction for which to calculate the drop in price
     */
    function _priceDropPerSecondForDutchAuction(uint256 tokenId)
    internal
    returns (uint256){

        return (dutchAuctions[tokenId].startPrice - dutchAuctions[tokenId].endPrice) /
        (dutchAuctions[tokenId].end - dutchAuctions[tokenId].start);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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