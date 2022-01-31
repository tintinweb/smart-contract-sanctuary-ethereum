// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {IERC20, ILockedWETHOffer, IOfferFactory, IOwnable} from "./Interfaces.sol";

contract WETHLens {
    // supported stablecoins
    address public constant USDC = 0xA3F8E2FeE6E754617e0f0917A1BA4f77De2D9423;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant FEI = 0x224e64ec1BDce3870a6a6c777eDd450454068FEC; 

    address public constant WETH = 0xf3aC2d4e676Ed31F21Ab5C31D6478FfCdF0E0086;

    function getVolume(IOfferFactory factory) public view returns (uint256 sum) {
        address[4] memory stables = [USDC, USDT, DAI, FEI];
        address factoryOwner = IOwnable(address(factory)).owner();

        uint256 volume;
        for (uint256 i; i < stables.length; i++) {
            volume += IERC20(stables[i]).balanceOf(factoryOwner) * (10**(18 - IERC20(stables[i]).decimals()));
        }
        sum = volume * 40;
    }

    function getOfferInfo(ILockedWETHOffer offer)
        public
        view
        returns (
            uint256 WETHBalance,
            address tokenWanted,
            uint256 amountWanted
        )
    {
        return (IERC20(WETH).balanceOf(address(offer)), offer.tokenWanted(), offer.amountWanted());
    }

    function getActiveOffersPruned(IOfferFactory factory) public view returns (ILockedWETHOffer[] memory) {
        ILockedWETHOffer[] memory activeOffers = factory.getActiveOffers();
        // determine size of memory array
        uint count;
        for (uint i; i < activeOffers.length; i++) {
            if (address(activeOffers[i]) != address(0)) {
                count++;
            }
        }
        ILockedWETHOffer[] memory pruned = new ILockedWETHOffer[](count);
        for (uint j; j < count; j++) {
            pruned[j] = activeOffers[j];
        }
        return pruned;
    }

    function getAllActiveOfferInfo(IOfferFactory factory)
        public
        view
        returns (
            address[] memory offerAddresses,
            uint256[] memory WETHBalances,
            address[] memory tokenWanted,
            uint256[] memory amountWanted
        )
    {
        ILockedWETHOffer[] memory activeOffers = factory.getActiveOffers();
        uint256 offersLength = activeOffers.length;
        offerAddresses = new address[](offersLength);
        WETHBalances = new uint256[](offersLength);
        tokenWanted = new address[](offersLength);
        amountWanted = new uint256[](offersLength);
        uint256 count;
        for (uint256 i; i < activeOffers.length; i++) {
            uint256 bal = IERC20(WETH).balanceOf(address(activeOffers[i]));
            if (bal > 0) {
                WETHBalances[count] = bal;
                offerAddresses[count] = address(activeOffers[i]);
                tokenWanted[count] = activeOffers[i].tokenWanted();
                amountWanted[count] = activeOffers[i].amountWanted();
                count++;
            }
        }
    }
}