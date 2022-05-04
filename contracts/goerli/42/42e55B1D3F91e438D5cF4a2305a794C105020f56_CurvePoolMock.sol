// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
}

contract CurvePoolMock is ICurvePool {
    uint256 public price;

    function set(uint256 price_) external {
        price = price_;
    }

    function get_virtual_price() external view override returns (uint256) {
        return price;
    }
}