/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





interface IFundProxy {

    function getRawFundBalancesAndPrices()
        external
        returns (
            string[] memory,
            uint256[] memory,
            uint8[][] memory,
            uint256[][] memory,
            uint256[] memory
        );
}





interface IFundController {
    function fuseAssets(uint8,string memory) external view returns (address);
}





interface IFuseAsset {
    function getCash() external returns (uint256);
}




contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
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








contract RariView is DSMath {

    /// @dev Not set as view because it calls some non view methods
    /// @param _tokenAddr Address od the underlying token
    /// @param _fundProxyAddr FundProxy addr
    /// @param _controllerAddr RariFundController addr
    function getPoolLiquidity(
        address _tokenAddr,
        address _fundProxyAddr,
        address _controllerAddr
    ) public returns (uint256) {

        string memory currencyCode = IERC20(_tokenAddr).symbol();

        // Step 1: Get raw data of fund
        (
            string[] memory currencyArr,
            ,
            uint8[][] memory pools,
            uint256[][] memory amountsMap,
        ) = IFundProxy(_fundProxyAddr).getRawFundBalancesAndPrices();

        // Step 2: Get index of currency code we are searching for
        uint256 currencyIndex = findCurrencyIndex(currencyArr, currencyCode);

        uint8[] memory currencyPoolIds = pools[currencyIndex];
        uint256[] memory amounts = amountsMap[currencyIndex];

        // Step 3: Go over each pool and calculate pool asset liquidity (skip over legacy)
        uint256 totalFuseAssetBalance = 0;
        for (uint256 i = 0; i < currencyPoolIds.length; ++i) {
            // under 100 ids are legacy
            if (uint8(currencyPoolIds[i]) < 100 && amounts[i] == 0) continue;

            address fuseAssetsAddr = IFundController(_controllerAddr).fuseAssets(
                uint8(currencyPoolIds[i]),
                currencyCode
            );

            uint256 cash = IFuseAsset(fuseAssetsAddr).getCash();

            if (cash >= amounts[i]){
                totalFuseAssetBalance += amounts[i];
            } else {
                totalFuseAssetBalance += cash;
                break;
            }

        }

        // STEP 4: Add contract balance to final sum
        uint256 contractBalance = IERC20(_tokenAddr).balanceOf(_controllerAddr);

        return contractBalance + totalFuseAssetBalance;
    }

    function findCurrencyIndex(string[] memory _currencyArr, string memory _targetCode)
        public        
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < _currencyArr.length; ++i) {
            if (keccak256(abi.encode(_currencyArr[i])) == keccak256(abi.encode(_targetCode))) {
                return i;
            }
        }

        // so we revert down the line if we don't find the index
        return type(uint256).max;
    }
}