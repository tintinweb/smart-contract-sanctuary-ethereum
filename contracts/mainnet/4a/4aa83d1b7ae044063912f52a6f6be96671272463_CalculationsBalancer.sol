/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint256);
}

interface IBalancerVault {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] calldata tokens,
            uint256[] calldata balances,
            uint256 lastChangeBlock
        );
}

interface IBalancerPool is IERC20 {
    function getPoolId() external view returns (bytes32 poolId);
    function totalSupply() external view returns (uint256);
    function getActualSupply() external view returns (uint256);
    function getVirtualSupply() external view returns (uint256);
}

interface IWrappedAsset {
    function ASSET() external view returns (address);
    function ATOKEN() external view returns (address);
}

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
    function usdcAddress() external view returns (address);
}

interface IYearnAddressesProvider {
    function addressById(string memory) external view returns (address);
}

contract Ownable {
    address public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        _;
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }
}

contract CalculationsBalancer is Ownable {
    IYearnAddressesProvider public yearnAddressesProvider;

    IBalancerVault internal constant balancerVault =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    constructor(address _yearnAddressesProviderAddress) {
        yearnAddressesProvider = IYearnAddressesProvider(
            _yearnAddressesProviderAddress
        );
    }

    function updateYearnAddressesProviderAddress(
        address _yearnAddressesProviderAddress
    ) external onlyOwner {
        yearnAddressesProvider = IYearnAddressesProvider(
            _yearnAddressesProviderAddress
        );
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(yearnAddressesProvider.addressById("ORACLE"));
    }

    //Phantom pools
    //Stable Pools
    function poolLpTotalValueUsdc(address lpAddress)
        public
        view
        returns (uint256)
    {
        //If the token is a Wrapped Aave asset return the total atoken value held
        try IWrappedAsset(lpAddress).ASSET() returns (address _asset) {
            IERC20 aToken = IERC20(IWrappedAsset(lpAddress).ATOKEN());
            return
                (oracle().getPriceUsdcRecommended(_asset) *
                    aToken.balanceOf(lpAddress)) / (10**aToken.decimals());
        } catch {}

        bytes32 poolId = IBalancerPool(lpAddress).getPoolId();

        (IERC20[] memory tokens, uint256[] memory balances, ) = balancerVault
            .getPoolTokens(poolId);
        uint256 totalValue;
        uint256 i;
        address token;
        for (i; i < tokens.length; ++i) {
            token = address(tokens[i]);

            if(token == lpAddress) continue;

            totalValue += getTokenAmountUsdc(token, balances[i]);
        }
        return totalValue;
    }

    function getTokenAmountUsdc(address _token, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint8 decimals = IERC20(_token).decimals();
        uint256 tokenPrice = oracle().getPriceUsdcRecommended(_token);
        uint256 tokenValueUsdc = (_amount * tokenPrice) / 10**decimals;
        return tokenValueUsdc;
    }

    function poolLpPriceUsdc(address lpAddress) public view returns (uint256) {
        uint256 totalValueUsdc = poolLpTotalValueUsdc(lpAddress);
        
        IBalancerPool pool = IBalancerPool(lpAddress);

        uint256 totalSupply = pool.totalSupply();
        //If its a phantom pool we need to use "actual supply" or virtual supply
        try pool.getVirtualSupply() returns (uint256 _supply) {
            totalSupply = _supply;
        } catch {}
        try pool.getActualSupply() returns (uint256 _supply) {
            totalSupply = _supply;
        } catch {}

        uint256 priceUsdc = (totalValueUsdc * (10**pool.decimals())) /
            totalSupply;
        return priceUsdc;
    }

    function getPriceUsdc(address assetAddress) public view returns (uint256) {
        return poolLpPriceUsdc(assetAddress);
    }
}