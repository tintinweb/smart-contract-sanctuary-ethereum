// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

library D4APrice {
    uint256 internal constant _PRICE_CHANGE_BASIS_POINT = 10_000;

    struct last_price {
        uint256 round;
        uint256 value;
    }

    struct project_price_info {
        last_price max_price;
        uint256 price_rank;
        uint256[] price_slots;
        mapping(bytes32 => last_price) canvas_price;
    }

    function getCanvasLastPrice(project_price_info storage ppi, bytes32 _canvas_id)
        public
        view
        returns (uint256 round, uint256 value)
    {
        last_price storage lp = ppi.canvas_price[_canvas_id];
        round = lp.round;
        value = lp.value;
    }

    function getCanvasNextPrice(
        project_price_info storage ppi,
        uint256 currentRound,
        uint256[] memory price_slots,
        uint256 price_rank,
        uint256 start_prb,
        bytes32 _canvas_id,
        uint256 multiplyFactor
    ) internal view returns (uint256 price) {
        uint256 floor_price = price_slots[price_rank];
        if (ppi.max_price.round == 0) {
            if (currentRound == start_prb) return floor_price;
            else return (floor_price * _PRICE_CHANGE_BASIS_POINT) / multiplyFactor;
        }
        uint256 first_guess = _get_price_in_round(ppi.canvas_price[_canvas_id], currentRound, multiplyFactor);
        if (first_guess >= floor_price) {
            return first_guess;
        }

        first_guess = _get_price_in_round(ppi.max_price, currentRound, multiplyFactor);
        if (first_guess >= floor_price) {
            return floor_price;
        }
        if (
            ppi.max_price.value == (floor_price * _PRICE_CHANGE_BASIS_POINT) / multiplyFactor
                && currentRound <= ppi.max_price.round + 1
        ) {
            return floor_price;
        }

        return (floor_price * _PRICE_CHANGE_BASIS_POINT) / multiplyFactor;
    }

    function updateCanvasPrice(
        project_price_info storage ppi,
        uint256 currentRound,
        bytes32 _canvas_id,
        uint256 price,
        uint256 multiplyFactor
    ) internal {
        uint256 cp = 0;
        {
            cp = _get_price_in_round(ppi.max_price, currentRound, multiplyFactor);
        }
        if (price >= cp) {
            ppi.max_price.round = currentRound;
            ppi.max_price.value = price;
        }

        ppi.canvas_price[_canvas_id].round = currentRound;
        ppi.canvas_price[_canvas_id].value = price;
    }

    function _get_price_in_round(last_price memory lp, uint256 round, uint256 multiplyFactor)
        internal
        pure
        returns (uint256)
    {
        if (round == lp.round) {
            return (lp.value * multiplyFactor) / _PRICE_CHANGE_BASIS_POINT;
        }
        uint256 k = round - lp.round - 1;
        uint256 value = lp.value;
        for (uint256 i = 0; i < k;) {
            value = (value * _PRICE_CHANGE_BASIS_POINT) / multiplyFactor;
            if (value == 0) {
                return 0;
            }
            unchecked {
                ++i;
            }
        }
        return value;
    }
}