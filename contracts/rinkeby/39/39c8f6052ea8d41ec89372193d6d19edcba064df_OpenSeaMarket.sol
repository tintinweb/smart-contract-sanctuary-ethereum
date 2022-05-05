/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

    function buyAssetsForEth(address OPENSEA,OpenSeaBuy memory openSeaBuy, bool revertIfTrxFails) public {
        _buyAssetForEth(OPENSEA, openSeaBuy, revertIfTrxFails);
    }

    function _buyAssetForEth(address OPENSEA,OpenSeaBuy memory _openSeaBuy, bool _revertIfTrxFails) internal {
        bytes memory _data = abi.encodeWithSelector(IOpenSea.atomicMatch_.selector, _openSeaBuy.addrs, _openSeaBuy.uints, _openSeaBuy.feeMethodsSidesKindsHowToCalls, _openSeaBuy.calldataBuy, _openSeaBuy.calldataSell, _openSeaBuy.replacementPatternBuy, _openSeaBuy.replacementPatternSell, _openSeaBuy.staticExtradataBuy, _openSeaBuy.staticExtradataSell, _openSeaBuy.vs, _openSeaBuy.rssMetadata);
        (bool success, ) = OPENSEA.call{value:_openSeaBuy.uints[4]}(_data);
        if (!success && _revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

     function helper(
        address[14] memory _addrs,
        uint[18] memory _uints,
        uint8[8] memory _feeMethodsSidesKindsHowToCalls,
        bytes memory _calldataBuy,
        bytes memory _calldataSell,
        bytes memory _replacementPatternBuy,
        bytes memory _replacementPatternSell,
        bytes memory _staticExtradataBuy,
        bytes memory _staticExtradataSell,
        uint8[2] memory _vs,
        bytes32[5] memory _rssMetadata
    ) public pure returns (bytes memory) {
        OpenSeaBuy memory openSeaBuy = OpenSeaBuy(_addrs, _uints, _feeMethodsSidesKindsHowToCalls, _calldataBuy, _calldataSell, _replacementPatternBuy, _replacementPatternSell, _staticExtradataBuy, _staticExtradataSell, _vs, _rssMetadata);
        bytes memory _data = abi.encodeWithSelector(OpenSeaMarket.buyAssetsForEth.selector, _addrs[0], openSeaBuy, true);
        
        return _data;

    }

}