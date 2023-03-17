// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../Interfaces/IPriceFeed.sol";

contract TestPriceFeed is IPriceFeed {

    uint crvPrice = 1e18;

    uint count = 0;


	function fetchPrice() external override returns (uint) {
        count++;
        return crvPrice;
    }

    function setPrice(uint _crvPrice) external {
        crvPrice = _crvPrice;
    }
}