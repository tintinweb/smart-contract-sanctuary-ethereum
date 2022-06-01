// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

//interface OracleInterface {
//    function getTargetAssets() external view returns (string[] memory, uint256);
//}

interface ISTRebalancer {
    function sellList(address _walletAddress)
        external
        returns (string[] memory);

    function adjustList(address _walletAddress)
        external
        returns (string[] memory);

    function buyList(address _walletAddress) external returns (string[] memory);
}

contract Wallet {
    address STRebalancerAddress;

    string[] public ownedSymbols = ["A", "B", "Z", "D"];
    string[] public targetAssets = ["B", "Z", "Q"];

    string[] public sellSymbolsList;
    string[] public adjustSymbolsList;
    string[] public buySymbolsList;

    constructor(address _STRebalancer) {
        STRebalancerAddress = _STRebalancer;
    }

    ISTRebalancer STRebalancer = ISTRebalancer(STRebalancerAddress);

    function getOwnedAssets() public view returns (string[] memory) {
        return ownedSymbols;
    }

    function getTargetAssets() external view returns (string[] memory) {
        return targetAssets;
    }

    function getSellList() internal {
        string[] memory sellResult = STRebalancer.sellList(address(this));
        for (uint256 x = 0; x < sellResult.length; x++) {
            if (
                keccak256(abi.encodePacked(sellResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                sellSymbolsList.push(sellResult[x]);
            }
        }
    }

    function getAdjustList() internal {
        string[] memory adjustResult = STRebalancer.adjustList(address(this));
        for (uint256 x = 0; x < adjustResult.length; x++) {
            if (
                keccak256(abi.encodePacked(adjustResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                adjustSymbolsList.push(adjustResult[x]);
            }
        }
    }

    function getBuyList() internal {
        string[] memory buyResult = STRebalancer.buyList(address(this));
        for (uint256 x = 0; x < buyResult.length; x++) {
            if (
                keccak256(abi.encodePacked(buyResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                buySymbolsList.push(buyResult[x]);
            }
        }
    }

    function updateTargetAssets() public {
        //(string[] memory targetAssets, ) = OracleInterface(_oracleAddress)
        //    .getTargetAssets();

        getSellList();
        getAdjustList();
        getBuyList();
    }
}