/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





contract MainnetYearnAddresses {
    address internal constant YEARN_REGISTRY_ADDR = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;
}





abstract contract IYearnRegistry {
    function latestVault(address) external virtual view returns (address);
    function numVaults(address) external virtual view returns (uint256);
    function vaults(address,uint256) external virtual view returns (address);
}






contract YearnHelper is MainnetYearnAddresses {

    IYearnRegistry public constant yearnRegistry =
        IYearnRegistry(YEARN_REGISTRY_ADDR);
}





interface IYVault {
    function withdraw(uint256 _shares) external ;
    function deposit(uint256 _amount) external ;
    function token() external view returns (address);

    function totalSupply() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function withdrawalQueue(uint256 i) external view returns (address);

    function strategies(address) external view returns (uint256, uint256, uint256,uint256, uint256, uint256, uint256, uint256, uint256);
}





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








contract YearnView is YearnHelper, DSMath  {
    function getUnderlyingBalanceInVault(address _user, address _vault) public view returns (uint256) {
        uint256 exchangeRate = rdiv(IYVault(_vault).totalAssets(), IYVault(_vault).totalSupply());

        uint256 yTokenBalance = IERC20(_vault).balanceOf(_user);

        return rmul(yTokenBalance, exchangeRate);
    }

    function getPoolLiquidity(address _vault) public view returns (uint256) {
        address underlyingToken = IYVault(_vault).token();

        uint256 balanceInVault = IERC20(underlyingToken).balanceOf(_vault);

        uint256 strategyDebtSum = 0;

        for(uint256 i = 0; i < 20; ++i) {
            address strategyAddr = IYVault(_vault).withdrawalQueue(i);
            (,,,,,,uint totalDebt,,) = IYVault(_vault).strategies(strategyAddr);

            strategyDebtSum += totalDebt;
        }

        return balanceInVault + strategyDebtSum;
    }

    function getVaultsForUnderlying(address _regAddr, address _tokenAddr) public view returns (address[] memory vaultAddresses) {
        uint256 numVaults = IYearnRegistry(_regAddr).numVaults(_tokenAddr);

        vaultAddresses = new address[](numVaults);

        for(uint256 i = 0; i < numVaults; ++i) {
            vaultAddresses[i] = IYearnRegistry(_regAddr).vaults(_tokenAddr, i);
        }
    }

    function getBalanceAndCheckLiquidity(address _user, address _tokenAddr, address _regAddr) public view returns (uint256) {
        address[] memory vaultAddresses = getVaultsForUnderlying(_regAddr, _tokenAddr);

        uint256 biggestUsableVaultBalance = 0;
        address targetVault;

        for(uint256 i = 0; i < vaultAddresses.length; ++i) {
            uint256 userBalance = getUnderlyingBalanceInVault(_user, vaultAddresses[i]);
            uint256 availLiquidity = getPoolLiquidity(targetVault);

            uint256 usableBalance = userBalance > availLiquidity ? availLiquidity : userBalance;

            if (usableBalance > biggestUsableVaultBalance) {
                biggestUsableVaultBalance = userBalance;
                targetVault = vaultAddresses[i];
            }
        }

        return biggestUsableVaultBalance;
    }
}