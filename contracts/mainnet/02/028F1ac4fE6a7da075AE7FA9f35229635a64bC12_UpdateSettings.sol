/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

abstract contract Setter {
    function setTotalAllowance(address, uint256) external virtual;

    function setPerBlockAllowance(address, uint256) external virtual;

    function modifyParameters(bytes32, uint) public virtual;

    function removeAuthorization(address) public virtual;
}

contract UpdateSettings {
    Setter public constant GEB_STABILITY_FEE_TREASURY =
        Setter(0xB3c5866f6690AbD50536683994Cc949697a64cd0);
    Setter public constant GEB_LIQUIDATION_TIPPER =
        Setter(0x651CC1F11E5dcA4Fc662cd20ffCAC24731Ad1D86);
    Setter public constant COLLATERAL_AUCTION_HOUSE_ETH_A =
        Setter(0x5C38b5E779Cb1de646485Cf2A3B4510f805CF400);
    Setter public constant COLLATERAL_AUCTION_HOUSE_ETH_B =
        Setter(0x5349c79fd4fa239F8a073F4CEc15cee982CD0438);
    Setter public constant COLLATERAL_AUCTION_HOUSE_ETH_C =
        Setter(0x51b898efAf8366b494b917d51839a4E015DCde3A);
    Setter public constant COLLATERAL_AUCTION_HOUSE_WSTETH_A =
        Setter(0x17EBdA4166fb97c0Eb91ed458909fd166D830301);
    Setter public constant COLLATERAL_AUCTION_HOUSE_WSTETH_B =
        Setter(0xC2A8b2cDDF4B20E3c865e4D446165Eb565D382f5);
    Setter public constant COLLATERAL_AUCTION_HOUSE_RETH_A =
        Setter(0x74fBBd942a5E93C4A5383391000b21C255F7Cc86);
    Setter public constant COLLATERAL_AUCTION_HOUSE_RETH_B =
        Setter(0xF6FE1349838222698C8E5e44F6693A63629E9C4F);
    Setter public constant COLLATERAL_AUCTION_HOUSE_RAI_A =
        Setter(0xcf75DAd110D6Ca835FdA8329521375437b4C362d);
    Setter public constant COLLATERAL_AUCTION_HOUSE_CBETH_A =
        Setter(0x8e93e24E85524E9B63a383A28CEe2516B85d2650);
    Setter public constant COLLATERAL_AUCTION_HOUSE_CBETH_B =
        Setter(0xD6ba3332aD84913c0570991BE706DC8c48F013D6);

    function run() external {
        // set liqiudation tipper allowances
        GEB_STABILITY_FEE_TREASURY.setPerBlockAllowance(
            address(GEB_LIQUIDATION_TIPPER),
            200 * 10 ** 45
        );
        GEB_STABILITY_FEE_TREASURY.setTotalAllowance(
            address(GEB_LIQUIDATION_TIPPER),
            type(uint256).max
        );

        // set fixed reward to 25 TAI on liquidation tipper
        GEB_LIQUIDATION_TIPPER.modifyParameters("fixedReward", 25 ether);
        GEB_LIQUIDATION_TIPPER.removeAuthorization(
            0x92f2373CAf9C5b7b45e80648749Eb633718E09f4
        ); //deployer

        // update rates on collateral auction houses
        COLLATERAL_AUCTION_HOUSE_ETH_A.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        ); // -30% over 7 days
        COLLATERAL_AUCTION_HOUSE_ETH_B.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_ETH_C.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_WSTETH_A.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_WSTETH_B.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_RETH_A.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_RETH_B.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_RAI_A.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_CBETH_A.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        COLLATERAL_AUCTION_HOUSE_CBETH_B.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
    }
}