/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/libraries/DSMath.sol

pragma solidity 0.8.10;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

}


// File contracts/interfaces/IOtc.sol

pragma solidity 0.8.10;

abstract contract IOtc {
    struct OfferInfo {
        uint              pay_amt;
        address           pay_gem;
        uint              buy_amt;
        address           buy_gem;
        address           owner;
        uint64            timestamp;
    }
    mapping (uint => OfferInfo) public offers;
    function getBestOffer(address, address) public virtual view returns (uint);
    function getWorseOffer(uint) public virtual view returns (uint);
}


// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity 0.8.10;

interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/OrderBookUpgradable.sol

pragma solidity 0.8.10;

contract OrderBookUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "Restricted only to maintainer.");
        _;
    }

    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "Restricted only to HordCongress.");
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        require(_hordCongress != address(0), "Hord congress can't be 0x0 address");
        require(_maintainersRegistry != address(0), "Maintainers regsitry can't be 0x0 address");
        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

}


// File contracts/MakerOtcSupportMethods.sol

// Normally, querying offers directly OasisDEX order book would require making several
// calls to the contract to extract all the active orders. An alternative would be to cache this
// information on the server side, but we can also use a support contract to save on the number of queries.
// The MakerOtcSupportsMethods contract provides an easy way to list all the pending orders in a
// single call, considerably speeding the request.
pragma solidity 0.8.10;



contract MakerOtcSupportMethods is DSMath, OrderBookUpgradable {

    /**
         * @notice          Function to return all the current orders using several arrays
         * @param           otc is MatchingMarket
         * @param           payToken is the token user wants to sell
         * @param           buyToken is the token user wants to buy
     */
    function getOffers(IOtc otc, address payToken, address buyToken) public view
    returns (uint[100] memory ids, uint[100] memory payAmts, uint[100] memory buyAmts, address[100] memory owners, uint[100] memory timestamps)
    {
        (ids, payAmts, buyAmts, owners, timestamps) = getOffersWithId(otc, otc.getBestOffer(payToken, buyToken));
    }

    function getOffersWithId(IOtc otc, uint offerId) public view
    returns (uint[100] memory ids, uint[100] memory payAmts, uint[100] memory buyAmts, address[100] memory owners, uint[100] memory timestamps)
    {
        uint i = 0;
        do {
            (payAmts[i],, buyAmts[i],, owners[i], timestamps[i]) = otc.offers(offerId);
            if(owners[i] == address(0)) break;
            ids[i] = offerId;
            offerId = otc.getWorseOffer(offerId);
        } while (++i < 100);
    }

    function getOffersAmountToSellAll(IOtc otc, address payToken, uint payAmt, address buyToken) public view returns (uint ordersToTake, bool takesPartialOrder) {
        uint offerId = otc.getBestOffer(buyToken, payToken);                        // Get best offer for the token pair
        ordersToTake = 0;
        uint payAmt2 = payAmt;
        uint orderBuyAmt = 0;
        (,,orderBuyAmt,,,) = otc.offers(offerId);
        while (payAmt2 > orderBuyAmt) {
            ordersToTake ++;                                                        // New order taken
            payAmt2 = sub(payAmt2, orderBuyAmt);                                    // Decrease amount to pay
            if (payAmt2 > 0) {                                                      // If we still need more offers
                offerId = otc.getWorseOffer(offerId);                               // We look for the next best offer
                require(offerId != 0);                                              // Fails if there are not enough offers to complete
                (,,orderBuyAmt,,,) = otc.offers(offerId);
            }

        }
        ordersToTake = payAmt2 == orderBuyAmt ? ordersToTake + 1 : ordersToTake;    // If the remaining amount is equal than the latest order, then it will also be taken completely
        takesPartialOrder = payAmt2 < orderBuyAmt;                                  // If the remaining amount is lower than the latest order, then it will take a partial order
    }

    function getOffersAmountToBuyAll(IOtc otc, address buyToken, uint buyAmt, address payToken) public view returns (uint ordersToTake, bool takesPartialOrder) {
        uint offerId = otc.getBestOffer(buyToken, payToken);                        // Get best offer for the token pair
        ordersToTake = 0;
        uint buyAmt2 = buyAmt;
        uint orderPayAmt = 0;
        (orderPayAmt,,,,,) = otc.offers(offerId);
        while (buyAmt2 > orderPayAmt) {
            ordersToTake ++;                                                        // New order taken
            buyAmt2 = sub(buyAmt2, orderPayAmt);                                    // Decrease amount to buy
            if (buyAmt2 > 0) {                                                      // If we still need more offers
                offerId = otc.getWorseOffer(offerId);                               // We look for the next best offer
                require(offerId != 0);                                              // Fails if there are not enough offers to complete
                (orderPayAmt,,,,,) = otc.offers(offerId);
            }
        }
        ordersToTake = buyAmt2 == orderPayAmt ? ordersToTake + 1 : ordersToTake;    // If the remaining amount is equal than the latest order, then it will also be taken completely
        takesPartialOrder = buyAmt2 < orderPayAmt;                                  // If the remaining amount is lower than the latest order, then it will take a partial order
    }
}