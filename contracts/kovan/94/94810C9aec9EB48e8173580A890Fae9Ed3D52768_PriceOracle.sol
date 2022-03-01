pragma solidity =0.5.4;

import "../interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle {
    function exchangePrice() external view returns (uint256) {
        return 10 * 10**8;
        //hardcoded as 1 Hydra equals to 10$
    }
}

pragma solidity =0.5.4;

interface IPriceOracle {
    function exchangePrice() external view returns (uint256);
}