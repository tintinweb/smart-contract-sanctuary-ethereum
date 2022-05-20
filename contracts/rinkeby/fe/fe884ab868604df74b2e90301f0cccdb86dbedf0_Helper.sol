/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpenSea {
    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) external payable;
}

library OpenSeaMarket {

    //address public constant OPENSEA = 0xdD54D660178B28f6033a953b0E55073cFA7e3744;
    
    struct OpenSeaBuy {
        address[14] addrs;
        uint[18] uints;
        uint8[8] feeMethodsSidesKindsHowToCalls;
        bytes calldataBuy;
        bytes calldataSell;
        bytes replacementPatternBuy;
        bytes replacementPatternSell;
        bytes staticExtradataBuy;
        bytes staticExtradataSell;
        uint8[2] vs;
        bytes32[5] rssMetadata;
    }

    function _buyAsset(bool _revertIfTrxFail, OpenSeaBuy memory _openSeaBuy) internal returns (bool){
        address OPENSEA = 0xdD54D660178B28f6033a953b0E55073cFA7e3744;
        bytes memory _data = abi.encodeWithSelector(IOpenSea.atomicMatch_.selector, _openSeaBuy.addrs, _openSeaBuy.uints, _openSeaBuy.feeMethodsSidesKindsHowToCalls, _openSeaBuy.calldataBuy, _openSeaBuy.calldataSell, _openSeaBuy.replacementPatternBuy, _openSeaBuy.replacementPatternSell, _openSeaBuy.staticExtradataBuy, _openSeaBuy.staticExtradataSell, _openSeaBuy.vs, _openSeaBuy.rssMetadata);
        (bool success, ) = OPENSEA.call{value:_openSeaBuy.uints[4]}(_data);
        if (!success && _revertIfTrxFail) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        return success;
    }

    function buyAsset(
        bool revertIfTrxFail,
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes  memory calldataBuy,
        bytes  memory calldataSell,
        bytes  memory replacementPatternBuy,
        bytes  memory replacementPatternSell,
        bytes  memory staticExtradataBuy,
        bytes  memory staticExtradataSell,
        uint8[2]  memory vs,
        bytes32[5]  memory rssMetadata
    ) public returns (bool){
        OpenSeaBuy memory openSeaBuy = OpenSeaBuy(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell, vs, rssMetadata);
        bool success = _buyAsset(revertIfTrxFail, openSeaBuy);    
        return success;
    }

    function getBuyAssetSelector() public pure returns (bytes4){
        return OpenSeaMarket.buyAsset.selector;
    }
}

contract Helper{

    function buyAssetHelper(
        bool revertIfTrxFail,
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes  memory calldataBuy,
        bytes  memory calldataSell,
        bytes  memory replacementPatternBuy,
        bytes  memory replacementPatternSell,
        bytes  memory staticExtradataBuy,
        bytes  memory staticExtradataSell,
        uint8[2]  memory vs,
        bytes32[5]  memory rssMetadata
    ) public pure returns (bytes memory){
        return abi.encodeWithSelector(OpenSeaMarket.buyAsset.selector, revertIfTrxFail, addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell, vs, rssMetadata);
    }

}