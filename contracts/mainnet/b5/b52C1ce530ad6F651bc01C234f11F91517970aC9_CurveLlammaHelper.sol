// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


contract CurveLlammaHelper {
    // concat of [active_band(), min_band(), max_band(), price_oracle(), dynamic_fee(), admin_fee(), p_oracle_up()]
    bytes32 private constant _SELECTORS = 0x8f8654c5ca72a821aaa615fc86fc88d377c34594fee3f7f92eb858e700000000;
    bytes4 private constant _BANDS_X_SELECTOR = 0xebcb0067;
    bytes4 private constant _BANDS_Y_SELECTOR = 0x31f7e306;
    uint256 private constant _255_BIT_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _254_BIT_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _TWO_TOP_BITS_MASK = 0xc000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _MASK_WITHOUT_TWO_TOP_BITS = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function get(address pool) external view returns(bytes memory res) {
        assembly {
            let ptr := mload(0x40)
            res := add(ptr, 0x40)
            let resPtr := add(res, 0x20)
            mstore(ptr, _SELECTORS)

            // call active_band()
            if iszero(staticcall(gas(), pool, ptr, 0x04, resPtr, 0x20)) { revert(ptr, 0x04) }

            // copy result to p_oracle_up arg
            mstore(add(ptr, 28), mload(resPtr))

            resPtr := add(resPtr, 0x20)

            // call p_oracle_up(active_band)
            if iszero(staticcall(gas(), pool, add(ptr, 24), 0x24, resPtr, 0x20)) { revert(add(ptr, 24), 0x24) }

            resPtr := add(resPtr, 0x20)

            // call min_band()
            if iszero(staticcall(gas(), pool, add(ptr, 4), 0x04, resPtr, 0x20)) { revert(add(ptr, 4), 0x04) }

            let minBand := mload(resPtr)

            resPtr := add(resPtr, 0x20)

            // call max_band()
            if iszero(staticcall(gas(), pool, add(ptr, 8), 0x04, resPtr, 0x20)) { revert(add(ptr, 8), 0x04) }

            let maxBand := mload(resPtr)

            resPtr := add(resPtr, 0x20)

            // call price_oracle()
            if iszero(staticcall(gas(), pool, add(ptr, 12), 0x04, resPtr, 0x20)) { revert(add(ptr, 12), 0x04) }

            resPtr := add(resPtr, 0x20)

            // call dynamic_fee()
            if iszero(staticcall(gas(), pool, add(ptr, 16), 0x04, resPtr, 0x20)) { revert(add(ptr, 16), 0x04) }

            resPtr := add(resPtr, 0x20)

            // call admin_fee()
            if iszero(staticcall(gas(), pool, add(ptr, 20), 0x04, resPtr, 0x20)) { revert(add(ptr, 20), 0x04) }

            resPtr := add(resPtr, 0x20)

            for { let i := minBand } slt(i, maxBand) { i := add(i, 1) } {
                let dataPtr := add(resPtr, 0x20)
                let c := and(i, _MASK_WITHOUT_TWO_TOP_BITS)

                mstore(ptr, _BANDS_X_SELECTOR)
                mstore(add(ptr, 4), i)
                // call bands_x(i)
                if iszero(staticcall(gas(), pool, ptr, 0x24, dataPtr, 0x20)) { revert(ptr, 0x24) }

                if mload(dataPtr) {
                    dataPtr := add(dataPtr, 0x20)
                    c := or(c, _255_BIT_MASK)
                }

                mstore(ptr, _BANDS_Y_SELECTOR)
                mstore(add(ptr, 4), i)
                // call bands_y(i)
                if iszero(staticcall(gas(), pool, ptr, 0x24, dataPtr, 0x20)) { revert(ptr, 0x24) }

                if mload(dataPtr) {
                    dataPtr := add(dataPtr, 0x20)
                    c := or(c, _254_BIT_MASK)
                }

                if and(c, _TWO_TOP_BITS_MASK) {
                    mstore(resPtr, c)
                    resPtr := dataPtr
                }
            }

            mstore(res, sub(sub(resPtr, res), 0x20))
        }
    }
}