/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


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

contract BuyOpenSeaTestnet {

    // rinkeby
    // address public openSea = 0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9;
    // // mainnet v1
    // address public openSea = 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b;
    // mainnet v2
    address public openSea = 0x7f268357A8c2552623316e2562D90e642bB538E5;


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

    function buyAssetsForEth(OpenSeaBuy[] memory openSeaBuys, bool revertIfTrxFails) payable public {
        for (uint256 i = 0; i < openSeaBuys.length; i++) {
            buySingleAssetForEth(openSeaBuys[i], revertIfTrxFails);
        }
    }

    function buySingleAssetForEth(OpenSeaBuy memory _openSeaBuy, bool _revertIfTrxFails) payable public {
        bytes memory _data = abi.encodeWithSelector(IOpenSea.atomicMatch_.selector, _openSeaBuy.addrs, _openSeaBuy.uints, _openSeaBuy.feeMethodsSidesKindsHowToCalls, _openSeaBuy.calldataBuy, _openSeaBuy.calldataSell, _openSeaBuy.replacementPatternBuy, _openSeaBuy.replacementPatternSell, _openSeaBuy.staticExtradataBuy, _openSeaBuy.staticExtradataSell, _openSeaBuy.vs, _openSeaBuy.rssMetadata);
        (bool success, ) = openSea.call{value:_openSeaBuy.uints[4]}(_data);
        if (!success && _revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
    
    function buyOpenSea(uint256 buyValue, bytes memory inputData) payable public {
        (bool success, ) = openSea.call{value: buyValue}(inputData);

        _checkCallResult(success);
    }

    function checkEncodedData(OpenSeaBuy memory _openSeaBuy) public pure returns (bytes memory) {
        bytes memory _data = abi.encodeWithSelector(IOpenSea.atomicMatch_.selector, _openSeaBuy.addrs, _openSeaBuy.uints, _openSeaBuy.feeMethodsSidesKindsHowToCalls, _openSeaBuy.calldataBuy, _openSeaBuy.calldataSell, _openSeaBuy.replacementPatternBuy, _openSeaBuy.replacementPatternSell, _openSeaBuy.staticExtradataBuy, _openSeaBuy.staticExtradataSell, _openSeaBuy.vs, _openSeaBuy.rssMetadata);
        return _data;
    }

    function checkOpenSeaSelector() public pure returns (bytes4) {
        return IOpenSea.atomicMatch_.selector;
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}