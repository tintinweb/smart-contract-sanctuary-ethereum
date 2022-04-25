// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "ERC20.sol";
import "AggregatorV3Interface.sol";

contract SolidStateToken is ERC20 {
    struct artworkMeta {
        string title;
        string artist;
        string medium;
        uint256 year;
        string dimensions;
        string mediaDataPackURI;
    }
    struct pMeta {
        string title;
        string URI;
    }

    /*
    struct buyOrder {
        address orderOwner;
        uint256 shareValue;
        uint256 ethValue;
        uint256 balance;
        OrderState state;
    }
    struct sellOrder {
        address orderOwner;
        uint256 shareValue;
        uint256 ethValue;
        uint256 balance;
        OrderState state;
    }

    enum OrderState {
        OPEN,
        CLOSED,
        CANCELLED
    }

    mapping(uint256 => buyOrder) public buyOrders;
    mapping(uint256 => sellOrder) public sellOrders;
    uint256 buyOrderCount = 0;
    uint256 sellOrderCount = 0;
    */
    mapping(uint256 => pMeta) public provinance;
    artworkMeta public artworkmeta;
    uint256 pPointer = 0;
    uint256 public initialSupply;
    uint256 public contractSalePrice;
    bool hasMinted = false;
    address private purchaserAddress;
    uint256 private purchaserOfferETH;
    uint256 private decreaseLimit = 5;
    address private PriceFeed;
    bool public forSale = false;
    AggregatorV3Interface public priceFeed;
    address[] private owners;
    uint256 ownerCount = 0;

    enum OfferState {
        FOR_SALE,
        NOT_FOR_SALE,
        OFFER_MADE,
        OFFER_ACCEPTED
    }
    OfferState public offerState;

    constructor(
        uint256 _initialSupply,
        uint256 _salePrice,
        string memory _name,
        string memory _tokenSymbol,
        address _priceFeed
    ) public ERC20(_name, _tokenSymbol) {
        initialSupply = _initialSupply;
        contractSalePrice = _salePrice;
        offerState = OfferState.NOT_FOR_SALE;
        PriceFeed = _priceFeed;
        owners.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owners[ownerCount]);
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function setMetaData(
        string memory _title,
        string memory _artist,
        string memory _medium,
        string memory _dimensions,
        uint256 _year,
        string memory _mediaDataPackURI
    ) public onlyOwner {
        if (bytes(_title).length != 0) {
            artworkmeta.title = _title;
        }
        if (bytes(_artist).length != 0) {
            artworkmeta.artist = _artist;
        }
        if (bytes(_medium).length != 0) {
            artworkmeta.medium = _medium;
        }
        if (bytes(_dimensions).length != 0) {
            artworkmeta.dimensions = _dimensions;
        }
        if (_year != 0) {
            artworkmeta.year = _year;
        }
        if (bytes(_mediaDataPackURI).length != 0) {
            artworkmeta.mediaDataPackURI = _mediaDataPackURI;
        }
    }

    function getMetaData() public view returns (artworkMeta memory) {
        return (artworkmeta);
    }

    function mintTokens() public onlyOwner {
        require(hasMinted == false, "Tokens Already Minted!");
        require(pPointer > 0, "Provinance must be supplied");
        _mint(address(this), initialSupply);
        hasMinted = true;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function addProvinance(string memory _title, string memory _meta)
        public
        onlyOwner
    {
        pMeta storage pmeta = provinance[pPointer];
        pmeta.title = _title;
        pmeta.URI = _meta;
        pPointer += 1;
    }

    function getProvinanceCount() public view returns (uint256) {
        return pPointer;
    }

    function getProvinanceByIndex(uint256 _index)
        public
        view
        returns (string memory, string memory)
    {
        return (provinance[_index].title, provinance[_index].URI);
    }

    // Token functions to release tokens into the wild
    function contractReleaseTokens(address _address, uint256 _value)
        public
        onlyOwner
    {
        require(
            IERC20(address(this)).balanceOf(address(this)) > _value,
            "Not Enough Tokens"
        );

        //
        IERC20(address(this)).transfer(_address, _value);
    }

    function contractTokenBalance() public view returns (uint256) {
        return IERC20(address(this)).balanceOf(address(this));
    }

    function setForSaleOn() public onlyOwner {
        offerState = OfferState.FOR_SALE;
    }

    function setForSaleOff() public onlyOwner {
        offerState = OfferState.NOT_FOR_SALE;
    }

    function isForSale() public view returns (bool) {
        if (offerState == OfferState.FOR_SALE) {
            return true;
        } else {
            return false;
        }
    }

    ///// functions to sell the contract/artwork in ether
    function getContractPriceInETH() public returns (uint256) {
        (uint256 price, uint256 _decimals) = getPriceFeedCurrencyETHValue();

        return
            (contractSalePrice * (10**_decimals)) / (price / (10**_decimals));
    }

    function getContractPricePriceFeedCurrency() public returns (uint256) {
        (uint256 price, uint256 _decimals) = getPriceFeedCurrencyETHValue();

        return
            (contractSalePrice * (10**_decimals)) / (price / (10**_decimals));
    }

    function makeOfferToBuyContract() public payable {
        // this has to be updated to ETH
        /*
        require(offerState == OfferState.FOR_SALE, "NOT FOR SALE");
        offerState = OfferState.OFFER_MADE;
        uint256 contractPriceETH = getContractPriceInETH();
        uint256 minimumETH = (contractPriceETH / 100) * (100 - decreaseLimit);
        require(msg.value >= minimumETH, "Offer To Low");
        offerState = OfferState.OFFER_ACCEPTED;
        require(
            offerState == OfferState.OFFER_ACCEPTED,
            "No Offer has been accepted!"
        );
        address payable OWNER = payable(owners[ownerCount]);
        // this will need to be updated
        OWNER.transfer(address(this).balance);
        owners.push(msg.sender);
        ownerCount += 1;
        offerState = OfferState.NOT_FOR_SALE;
        */
        require(offerState == OfferState.FOR_SALE, "NOT FOR SALE");
        offerState = OfferState.OFFER_MADE;
        require(msg.value == contractSalePrice, "Incorrect Price");
        offerState = OfferState.OFFER_ACCEPTED;
        require(
            offerState == OfferState.OFFER_ACCEPTED,
            "No Offer has been accepted!"
        );
        address payable OWNER = payable(owners[ownerCount]);
        OWNER.transfer(msg.value);
        owners.push(msg.sender);
        ownerCount += 1;
        offerState = OfferState.NOT_FOR_SALE;
    }

    function updateOfferDecreaseLimit(uint256 _percent) public onlyOwner {
        decreaseLimit = _percent;
    }

    function viewOfferDecreaseLimit() public view returns (uint256) {
        return decreaseLimit;
    }

    function setPriceFeed(address _priceFeed) public onlyOwner {
        PriceFeed = _priceFeed;
    }

    function getPriceFeed() public view onlyOwner returns (address) {
        return PriceFeed;
    }

    function getPriceFeedCurrencyETHValue() public returns (uint256, uint256) {
        //function getUSDETHValue() public returns (uint256, uint256) {
        priceFeed = AggregatorV3Interface(PriceFeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 _decimals = uint256(priceFeed.decimals());
        return (uint256(price), _decimals);
    }

    function updateContractSalePrice(uint256 _salePrice) public onlyOwner {
        contractSalePrice = _salePrice;
    }

    function getContractSalePrice() public view returns (uint256) {
        return contractSalePrice;
    }

    ///. trade share functions
    struct buyOrder {
        //address artworkAddress;
        address orderOwner;
        uint256 shareValue;
        uint256 ethValue;
        uint256 balance;
        OrderState state;
    }
    struct sellOrder {
        //address artworkAddress;
        address orderOwner;
        uint256 shareValue;
        uint256 ethValue;
        uint256 balance;
        OrderState state;
    }

    enum OrderState {
        OPEN,
        CLOSED,
        CANCELLED
    }
    struct transaction {
        // address artwork;
        uint256 eth;
        uint256 share;
        uint256 buyId;
        uint256 sellId;
        address buyer;
        address seller;
        uint256 timestamp;
    }

    mapping(uint256 => transaction) private transactions;
    uint256 transactionCount = 0;

    mapping(uint256 => buyOrder) private buyOrders;
    mapping(uint256 => sellOrder) private sellOrders;
    uint256 buyOrderCount = 0;
    uint256 sellOrderCount = 0;

    function balanceOfHeldShares() public view returns (uint256) {
        (
            uint256[] memory _shareValues,
            uint256[] memory _ethValues,
            uint256[] memory _balances,
            uint256[] memory _ids
        ) = getAllSellOrders();
        uint256 total = 0;
        for (uint8 j = 0; j < _balances.length; j++) {
            total += _balances[j];
        }
        return total;
    }

    function getAllBuyOrders()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].state == OrderState.OPEN) {
                //if (buyOrders[j].artworkAddress == _artworkAddress) {
                c += 1;
                //}
            }
        }

        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].state == OrderState.OPEN) {
                // if (buyOrders[j].artworkAddress == _artworkAddress) {
                _shareValues[c] = buyOrders[j].shareValue;
                _ethValues[c] = buyOrders[j].ethValue;
                _balances[c] = buyOrders[j].balance;
                _ids[c] = j;
                c++;
                // }
            }
        }
        return (_shareValues, _ethValues, _balances, _ids);
    }

    function getBuyOrdersByAddress(address _address)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            OrderState[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].orderOwner == _address) {
                //if (buyOrders[j].artworkAddress == _artworkAddress) {
                c++;
                //}
            }
        }
        address[] memory _orderOwners = new address[](c);
        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        OrderState[] memory _states = new OrderState[](c);
        c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].orderOwner == _address) {
                //if (buyOrders[j].artworkAddress == _artworkAddress) {
                _orderOwners[c] = buyOrders[j].orderOwner;
                _shareValues[c] = buyOrders[j].shareValue;
                _ethValues[c] = buyOrders[j].ethValue;
                _balances[c] = buyOrders[j].balance;

                _ids[c] = j;
                _states[c] = buyOrders[j].state;
                c++;
                //}
            }
        }
        return (
            _orderOwners,
            _shareValues,
            _ethValues,
            _balances,
            _states,
            _ids
        );
    }

    function getAllSellOrders()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            //if (sellOrders[j].artworkAddress == _artworkAddress) {
            if (sellOrders[j].state == OrderState.OPEN) {
                c++;
            }
            //}
        }
        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            // if (sellOrders[j].artworkAddress == _artworkAddress) {
            if (sellOrders[j].state == OrderState.OPEN) {
                _shareValues[c] = sellOrders[j].shareValue;
                _ethValues[c] = sellOrders[j].ethValue;
                _balances[c] = sellOrders[j].balance;
                _ids[c] = j;
                c++;
            }
            //  }
        }
        return (_shareValues, _ethValues, _balances, _ids);
    }

    function getSellOrdersByAddress(address _address)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            OrderState[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            //  if (sellOrders[j].artworkAddress == _artworkAddress) {
            if (sellOrders[j].orderOwner == _address) {
                c++;
            }
            // }
        }
        address[] memory _orderOwners = new address[](c);
        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        OrderState[] memory _states = new OrderState[](c);
        c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].orderOwner == _address) {
                //if (sellOrders[j].artworkAddress == _artworkAddress) {
                _orderOwners[c] = sellOrders[j].orderOwner;
                _shareValues[c] = sellOrders[j].shareValue;
                _ethValues[c] = sellOrders[j].ethValue;
                _balances[c] = sellOrders[j].balance;
                _states[c] = sellOrders[j].state;
                _ids[c] = j;
                c++;
                //}
            }
        }
        return (
            _orderOwners,
            _shareValues,
            _ethValues,
            _balances,
            _states,
            _ids
        );
    }

    function placeBuyOrder(uint256 shareValue, uint256 ethValue)
        public
        payable
        returns (uint256)
    {
        require(shareValue > 0, "share value can not be 0");
        require(ethValue > 0, "share value can not be 0");

        require((msg.value / shareValue) == ethValue, "can not make order");
        buyOrders[buyOrderCount] = buyOrder(
            //  _artworkAddress,
            msg.sender,
            shareValue,
            ethValue,
            msg.value,
            OrderState.OPEN
        );

        fillBuyOrder(buyOrderCount);
        buyOrderCount += 1;
        return buyOrderCount - 1;
    }

    function placeSellOrder(uint256 shareValue, uint256 ethValue)
        public
        returns (uint256)
    {
        require(shareValue > 0, "share value can not be 0");
        require(ethValue > 0, "share value can not be 0");
        //IERC20(_artworkAddress).allowance(msg.sender, address(this));
        IERC20(address(this)).transferFrom(
            msg.sender,
            address(this),
            shareValue
        );
        sellOrders[sellOrderCount] = sellOrder(
            //   _artworkAddress,
            msg.sender,
            shareValue,
            ethValue,
            shareValue,
            OrderState.OPEN
        );

        fillSellOrder(sellOrderCount);
        sellOrderCount += 1;
        return sellOrderCount - 1; // IERC20(_artworkAddress).balanceOf(msg.sender); //
    }

    function cancelBuyOrder(uint256 id) public {
        require(
            buyOrders[id].orderOwner == msg.sender,
            "msg.sender is not order owner"
        );
        require(buyOrders[id].state == OrderState.OPEN, "order is not open");

        address payable payee = payable(msg.sender);
        payee.transfer(buyOrders[id].balance);
        buyOrders[id].balance = 0;
        buyOrders[id].state = OrderState.CANCELLED;
    }

    function cancelSellOrder(uint256 id) public {
        require(
            sellOrders[id].orderOwner == msg.sender,
            "msg.sender is not order owner"
        );
        require(sellOrders[id].state == OrderState.OPEN, "order is not open");

        sellOrders[id].state = OrderState.CANCELLED;
        IERC20(address(this)).transfer(
            sellOrders[id].orderOwner,
            sellOrders[id].balance
        );
        sellOrders[id].balance = 0;
    }

    function getHeldShares() public view returns (uint256) {
        uint256 heldShares = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            // if (sellOrders[j].artworkAddress == _artworkAddress) {
            heldShares += sellOrders[j].balance;
            //  }
        }
        return heldShares;
    }

    function getHeldETH() public view returns (uint256) {
        uint256 heldETH = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            //  if (buyOrders[j].artworkAddress == _artworkAddress) {
            heldETH += buyOrders[j].balance;
            //  }
        }
        return heldETH;
    }

    function fillBuyOrder(uint256 bc) private {
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].state == OrderState.OPEN) {
                if (buyOrders[bc].state == OrderState.OPEN) {
                    // if (
                    //     sellOrders[j].artworkAddress ==
                    //     buyOrders[bc].artworkAddress
                    //) {
                    if (sellOrders[j].ethValue == buyOrders[bc].ethValue) {
                        address payable seller = payable(
                            sellOrders[j].orderOwner
                        );
                        uint256 transferAmount = 0;
                        if (sellOrders[j].balance >= buyOrders[bc].shareValue) {
                            sellOrders[j].balance =
                                sellOrders[j].balance -
                                buyOrders[bc].shareValue;

                            transferAmount = buyOrders[bc].shareValue;

                            buyOrders[bc].balance = 0;
                            buyOrders[bc].shareValue = 0;

                            buyOrders[bc].state = OrderState.CLOSED;

                            if (sellOrders[j].balance == 0) {
                                sellOrders[j].state = OrderState.CLOSED;
                            }
                        } else {
                            buyOrders[bc].balance =
                                buyOrders[bc].balance -
                                (sellOrders[j].ethValue *
                                    sellOrders[j].balance);

                            buyOrders[bc].shareValue =
                                buyOrders[bc].shareValue -
                                sellOrders[j].balance;

                            transferAmount = sellOrders[j].balance;

                            sellOrders[j].balance = 0;
                            sellOrders[j].state = OrderState.CLOSED;
                            if (buyOrders[bc].balance == 0) {
                                buyOrders[bc].state = OrderState.CLOSED;
                            }
                        }
                        seller.transfer(
                            buyOrders[bc].ethValue * transferAmount
                        );

                        IERC20(address(this)).transfer(
                            buyOrders[bc].orderOwner,
                            transferAmount
                        );
                        orderTransaction(
                            buyOrders[bc].ethValue * transferAmount,
                            transferAmount,
                            bc,
                            j,
                            buyOrders[bc].orderOwner,
                            sellOrders[j].orderOwner
                        );
                    }
                    //}
                }
            }
        }
    }

    function fillSellOrder(uint256 sc) private {
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (sellOrders[sc].state == OrderState.OPEN) {
                if (buyOrders[j].state == OrderState.OPEN) {
                    // if (
                    //    sellOrders[sc].artworkAddress ==
                    //     buyOrders[j].artworkAddress
                    // ) {
                    if (sellOrders[sc].ethValue == buyOrders[j].ethValue) {
                        address payable seller = payable(
                            sellOrders[sc].orderOwner
                        );
                        uint256 transferAmount = 0;
                        if (sellOrders[sc].balance >= buyOrders[j].shareValue) {
                            sellOrders[sc].balance =
                                sellOrders[sc].balance -
                                buyOrders[j].shareValue;

                            transferAmount = buyOrders[j].shareValue;

                            buyOrders[j].balance = 0;
                            buyOrders[j].shareValue = 0;

                            buyOrders[j].state = OrderState.CLOSED;

                            if (sellOrders[sc].balance == 0) {
                                sellOrders[sc].state = OrderState.CLOSED;
                            }
                        } else {
                            buyOrders[j].balance =
                                buyOrders[j].balance -
                                (sellOrders[sc].ethValue *
                                    sellOrders[sc].balance);

                            transferAmount = sellOrders[sc].balance;
                            buyOrders[j].shareValue =
                                buyOrders[j].shareValue -
                                sellOrders[sc].balance;

                            sellOrders[sc].balance = 0;
                            sellOrders[sc].state = OrderState.CLOSED;
                            if (buyOrders[j].balance == 0) {
                                buyOrders[j].state = OrderState.CLOSED;
                            }
                        }

                        seller.transfer(buyOrders[j].ethValue * transferAmount);
                        IERC20(address(this)).transfer(
                            buyOrders[j].orderOwner,
                            transferAmount
                        );
                        orderTransaction(
                            //    buyOrders[j].artworkAddress,
                            buyOrders[j].ethValue * transferAmount,
                            transferAmount,
                            j,
                            sc,
                            buyOrders[j].orderOwner,
                            sellOrders[sc].orderOwner
                        );
                    }
                    // }
                }
            }
        }
    }

    function orderTransaction(
        //   address artwork,
        uint256 eth,
        uint256 share,
        uint256 buyId,
        uint256 sellId,
        address buyer,
        address seller
    ) internal {
        // transactions[transactionCount].artwork = artwork;
        transactions[transactionCount].eth = eth;
        transactions[transactionCount].share = share;
        transactions[transactionCount].timestamp = block.timestamp;
        transactions[transactionCount].buyId = buyId;
        transactions[transactionCount].sellId = sellId;
        transactions[transactionCount].buyer = buyer;
        transactions[transactionCount].seller = seller;
        transactionCount++;
    }

    function getTransactions()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address[] memory,
            address[] memory
        )
    {
        uint256 c = 0;
        for (uint8 j = 0; j < transactionCount; j++) {
            //if (transactions[j].artwork == _artworkAddress) {
            c++;
            //}
        }
        // address[] memory artwork = new address[](c);
        uint256[] memory eth = new uint256[](c);
        uint256[] memory share = new uint256[](c);
        uint256[] memory timestamp = new uint256[](c);
        address[] memory buyer = new address[](c);
        address[] memory seller = new address[](c);
        c = 0;
        for (uint8 j = 0; j < transactionCount; j++) {
            // if (transactions[j].artwork == _artworkAddress) {
            // artwork[c] = transactions[j].artwork;
            eth[c] = transactions[j].eth;
            share[c] = transactions[j].share;
            timestamp[c] = transactions[j].timestamp;
            buyer[c] = transactions[j].buyer;
            seller[c] = transactions[j].seller;
            c++;
            //}
        }
        return (eth, share, timestamp, buyer, seller);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}