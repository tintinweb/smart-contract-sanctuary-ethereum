// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PayCurveInterface } from "./interfaces/PayCurveInterface.sol";

contract PaymentModule {
    modifier onlyMarket() {
        _;
    }

    function earned(
          address payCurve
        , uint256 x
    ) 
        public 
        returns (
            uint256
        ) 
    {
        return PayCurveInterface(payCurve).curvePoint(x);
    }

    function claim(
          address payCurve
        , uint256 x
    ) 
        public 
        returns (
            uint256
        ) 
    {
        uint256 amount = earned(
              payCurve
            , x
        );
        
        return amount;
    }

    function pay() public {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface PayCurveInterface {
    function curvePoint(uint256 x) 
        external 
        returns (
            uint256
        );
}