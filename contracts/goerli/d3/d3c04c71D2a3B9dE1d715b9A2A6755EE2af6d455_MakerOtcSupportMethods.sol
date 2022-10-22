/**
 *Submitted for verification at Etherscan.io on 2022-10-22
 */

pragma solidity ^0.4.23;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract OtcInterface {
    struct OfferInfo {
        uint256 pay_amt;
        address pay_gem;
        uint256 buy_amt;
        address buy_gem;
        address owner;
        uint64 timestamp;
    }
    mapping(uint256 => OfferInfo) public offers;

    function getBestOffer(address, address) public view returns (uint256);

    function getWorseOffer(uint256) public view returns (uint256);
}

contract MakerOtcSupportMethods is DSMath {
    function getOffers(
        OtcInterface otc,
        address payToken,
        address buyToken
    )
        public
        view
        returns (
            uint256[100] ids,
            uint256[100] payAmts,
            uint256[100] buyAmts,
            address[100] owners,
            uint256[100] timestamps
        )
    {
        (ids, payAmts, buyAmts, owners, timestamps) = getOffers(
            otc,
            otc.getBestOffer(payToken, buyToken)
        );
    }

    function getOffers(OtcInterface otc, uint256 offerId)
        public
        view
        returns (
            uint256[100] ids,
            uint256[100] payAmts,
            uint256[100] buyAmts,
            address[100] owners,
            uint256[100] timestamps
        )
    {
        uint256 i = 0;
        do {
            (payAmts[i], , buyAmts[i], , owners[i], timestamps[i]) = otc.offers(
                offerId
            );
            if (owners[i] == 0) break;
            ids[i] = offerId;
            offerId = otc.getWorseOffer(offerId);
        } while (++i < 100);
    }

    function getOffersAmountToSellAll(
        OtcInterface otc,
        address payToken,
        uint256 payAmt,
        address buyToken
    ) public view returns (uint256 ordersToTake, bool takesPartialOrder) {
        uint256 offerId = otc.getBestOffer(buyToken, payToken); // Get best offer for the token pair
        ordersToTake = 0;
        uint256 payAmt2 = payAmt;
        uint256 orderBuyAmt = 0;
        (, , orderBuyAmt, , , ) = otc.offers(offerId);
        while (payAmt2 > orderBuyAmt) {
            ordersToTake++; // New order taken
            payAmt2 = sub(payAmt2, orderBuyAmt); // Decrease amount to pay
            if (payAmt2 > 0) {
                // If we still need more offers
                offerId = otc.getWorseOffer(offerId); // We look for the next best offer
                require(offerId != 0); // Fails if there are not enough offers to complete
                (, , orderBuyAmt, , , ) = otc.offers(offerId);
            }
        }
        ordersToTake = payAmt2 == orderBuyAmt ? ordersToTake + 1 : ordersToTake; // If the remaining amount is equal than the latest order, then it will also be taken completely
        takesPartialOrder = payAmt2 < orderBuyAmt; // If the remaining amount is lower than the latest order, then it will take a partial order
    }

    function getOffersAmountToBuyAll(
        OtcInterface otc,
        address buyToken,
        uint256 buyAmt,
        address payToken
    ) public view returns (uint256 ordersToTake, bool takesPartialOrder) {
        uint256 offerId = otc.getBestOffer(buyToken, payToken); // Get best offer for the token pair
        ordersToTake = 0;
        uint256 buyAmt2 = buyAmt;
        uint256 orderPayAmt = 0;
        (orderPayAmt, , , , , ) = otc.offers(offerId);
        while (buyAmt2 > orderPayAmt) {
            ordersToTake++; // New order taken
            buyAmt2 = sub(buyAmt2, orderPayAmt); // Decrease amount to buy
            if (buyAmt2 > 0) {
                // If we still need more offers
                offerId = otc.getWorseOffer(offerId); // We look for the next best offer
                require(offerId != 0); // Fails if there are not enough offers to complete
                (orderPayAmt, , , , , ) = otc.offers(offerId);
            }
        }
        ordersToTake = buyAmt2 == orderPayAmt ? ordersToTake + 1 : ordersToTake; // If the remaining amount is equal than the latest order, then it will also be taken completely
        takesPartialOrder = buyAmt2 < orderPayAmt; // If the remaining amount is lower than the latest order, then it will take a partial order
    }
}