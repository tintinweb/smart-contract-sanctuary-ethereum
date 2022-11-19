// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Types {
    struct OptionSeries {
        uint64 expiration;
        uint128 strike;
        bool isPut;
        address underlying;
        address strikeAsset;
        address collateral;
    }
}

contract OptionHandler {
    // order id counter
    uint256 public orderIdCounter;

    event OrderCreated(
        uint256 orderId,
        Types.OptionSeries optionSeries,
        uint256 amount,
        uint256 price,
        uint256 orderExpiry,
        address buyerAddress,
        uint256[2] spotMovementRange
    );

    /**
     * @notice creates an order for a number of options from the pool to a specified user. The function
	 *      is intended to be used to issue options to market makers/ OTC market participants
	 *      in order to have flexibility and customisability on option issuance and market
	 *      participant UX.
	 * @param _optionSeries the option token series to issue - strike in e18
	 * @param _amount the number of options to issue - e18
	 * @param _price the price per unit to issue at - in e18
	 * @param _orderExpiry the expiry of the custom order, after which the
	 *        buyer cannot use this order (if past the order is redundant)
	 * @param _buyerAddress the agreed upon buyer address
	 * @return orderId the unique id of the order
	 */
    function createOrder(
        Types.OptionSeries memory _optionSeries,
        uint256 _amount,
        uint256 _price,
        uint256 _orderExpiry,
        address _buyerAddress,
        uint256[2] memory _spotMovementRange
    ) public returns (uint256) {
        uint256 orderIdCounter__ = orderIdCounter + 1;

        emit OrderCreated(
            orderIdCounter__,
            _optionSeries,
            _amount,
            _price,
            _orderExpiry,
            _buyerAddress,
            _spotMovementRange
        );

        orderIdCounter = orderIdCounter__;
        return orderIdCounter__;
    }

}