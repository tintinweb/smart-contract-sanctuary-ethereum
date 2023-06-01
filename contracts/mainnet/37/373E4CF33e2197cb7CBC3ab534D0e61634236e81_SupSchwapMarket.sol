// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./libraries/DSMath.sol";
import "./interfaces/OtcInterface.sol";

contract SupSchwapMarket is DSMath {
    function getOffers(OtcInterface otc, address payToken, address buyToken) public view
        returns (uint[100] memory ids, uint[100] memory payAmts, uint[100] memory buyAmts, address[100] memory owners, uint[100] memory timestamps)
    {
        (ids, payAmts, buyAmts, owners, timestamps) = getOffers(otc, otc.getBestOffer(payToken, buyToken));
    }

    function getOffers(OtcInterface otc, uint offerId) public view
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

    function getOffersAmountToSellAll(OtcInterface otc, address payToken, uint payAmt, address buyToken) public view returns (uint ordersToTake, bool takesPartialOrder) {
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

    function getOffersAmountToBuyAll(OtcInterface otc, address buyToken, uint buyAmt, address payToken) public view returns (uint ordersToTake, bool takesPartialOrder) {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

abstract contract OtcInterface {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

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
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}