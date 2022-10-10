/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ITroveManager {
    function sortedTroves() external view returns (address);
    function userCollateralShare(address _borrower) external view returns (uint256);
    function userBorrowPart(address _borrower) external view returns (uint256);
    function getCurrentCR(address _borrower) external view returns (uint256);
    function isSolvent(address _borrower) external view returns (bool);
}

interface ISortedTrove {
    function getSize() external view returns (uint256);
    function getFirst() external view returns (address);
    function getNext(address _id) external view returns (address);
}


contract SortedTrovesForFrontend {

    struct TroveData {
        address user;
        uint debtPart;
        uint collShare;
        uint collRate;
        bool isSolvent;
    }

    function getPoolRiskyTrovesSize(address _poolAddr) external view returns (uint) {
        ITroveManager troveManager = ITroveManager(_poolAddr);
        ISortedTrove sortedTroves = ISortedTrove(address(troveManager.sortedTroves()));

        uint sortedTrovesSize = sortedTroves.getSize();
        if (sortedTrovesSize == 0) {
            return 0;
        }

        address currentTroveowner = sortedTroves.getFirst();
        bool isSolvent;
        uint maxSize;
        for (uint idx = 0; idx < sortedTrovesSize; ++idx) {
            isSolvent = troveManager.isSolvent(currentTroveowner);
            // end with not solvent position
            if (isSolvent || currentTroveowner == address(0)) {
                maxSize = idx;
                break;
            }
            currentTroveowner = sortedTroves.getNext(currentTroveowner);
        }

        return maxSize;
    }
    
    function getPoolSortedTroves(address _poolAddr, int _startIdx, uint _count)
        external view returns (TroveData[] memory _troves)
    {
        uint startIdx;

        ITroveManager troveManager = ITroveManager(_poolAddr);
        ISortedTrove sortedTroves = ISortedTrove(address(troveManager.sortedTroves()));

        startIdx = uint(_startIdx);

        uint sortedTrovesSize = sortedTroves.getSize();

        if (startIdx >= sortedTrovesSize) {
            _troves = new TroveData[](0);
        } else {
            uint maxCount = sortedTrovesSize - startIdx;

            if (_count > maxCount) {
                _count = maxCount;
            }

            _troves = _getMultipleSortedTrovesFromHead(startIdx, _count, troveManager, sortedTroves);
        }
    }

    function _getMultipleSortedTrovesFromHead(uint _startIdx, uint _count, ITroveManager troveManager, ISortedTrove sortedTroves)
        internal view returns (TroveData[] memory _troves)
    {
        address currentTroveowner = sortedTroves.getFirst();

        for (uint idx = 0; idx < _startIdx; ++idx) {
            currentTroveowner = sortedTroves.getNext(currentTroveowner);
        }
        if (currentTroveowner == address(0)) {
            _troves = new TroveData[](0);
        } else {
            TroveData[] memory tempTroves = new TroveData[](_count);
            bool isSolvent;
            uint lastIdx;
            bool hasInsolvent;
            for (uint idx = 0; idx < _count; ++idx) {
                isSolvent = troveManager.isSolvent(currentTroveowner);
                // end with not solvent position
                if (isSolvent || currentTroveowner == address(0)) {
                    break;
                }
                tempTroves[idx].user = currentTroveowner;
                tempTroves[idx].debtPart = troveManager.userBorrowPart(currentTroveowner);
                tempTroves[idx].collShare = troveManager.userCollateralShare(currentTroveowner);
                tempTroves[idx].collRate = troveManager.getCurrentCR(currentTroveowner);
                tempTroves[idx].isSolvent = isSolvent;
                lastIdx = idx;
                hasInsolvent = true;
                currentTroveowner = sortedTroves.getNext(currentTroveowner);
            }

            // choice non zero elements
            if (hasInsolvent) {
                _troves = new TroveData[](lastIdx+1);
                for (uint i = 0; i <= lastIdx; ++i) {
                    _troves[i] = tempTroves[i];
                }
            }
        }
    }

}