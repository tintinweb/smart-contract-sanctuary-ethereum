pragma solidity ^0.8.0;

import "./Administrable.sol";

interface IMultiPriceOracle {
    function getMultiPrice() external view returns (uint256 multiPrice);
}

interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

contract MultiPriceOracle is IMultiPriceOracle, Administrable {
    uint256 public maxPrice;
    uint256 public minPrice;

    address public router;
    address[] public path; // multi - weth - usdc

    event SetMaxMinPrice(uint256 maxPrice, uint256 minPrice);
    event SetRouter(address router);
    event SetPath(address[] path);

    constructor(
        uint256 maxPrice_,
        uint256 minPrice_,
        address router_,
        address[] memory path_
    ) {
        setAdmin(msg.sender);
        maxPrice = maxPrice_;
        minPrice = minPrice_;
        router = router_;
        path = path_;
        emit SetMaxMinPrice(maxPrice, minPrice);
        emit SetRouter(router);
        emit SetPath(path);
    }

    function setMaxMinPrice(uint256 maxPrice_, uint256 minPrice_)
        public
        onlyAdmin
    {
        maxPrice = maxPrice_;
        minPrice = minPrice_;
        emit SetMaxMinPrice(maxPrice, minPrice);
    }

    function setRouter(address router_) public onlyAdmin {
        router = router_;
        emit SetRouter(router);
    }

    function setPath(address[] memory path_) public onlyAdmin {
        path = path_;
        emit SetPath(path);
    }

    function getMultiPrice() public view returns (uint256 multiPrice) {
        uint256[] memory amounts = IRouter(router).getAmountsOut(1 ether, path);

        multiPrice = amounts[amounts.length - 1];

        if (multiPrice > maxPrice) {
            revert("no available price");
        }
        if (multiPrice < minPrice) {
            revert("no available price");
        }
        return multiPrice;
    }
}