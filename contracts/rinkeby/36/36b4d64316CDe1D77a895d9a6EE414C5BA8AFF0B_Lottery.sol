// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

contract Lottery {

    uint256 private counter;

    constructor() {
        counter = 0;
    }

    function isWinningCoupon() private view returns (bool) {
        return counter % 3 == 0;
    }

    function returnTheWinningPool() private {
        payable(msg.sender).transfer(address(this).balance);
    }

    modifier isCouponPrice {
        //Coupon price = 0.001ETH
        uint256 couponPriceInWei = 1000000000000000;
        require(couponPriceInWei == msg.value, "You need to pay exactly 0.001ETH for coupon");
        _;
    }

    function buyCouponAndTryToWin() public isCouponPrice payable {
        counter++;
        if (isWinningCoupon()) {
            returnTheWinningPool();
        }
    }
}