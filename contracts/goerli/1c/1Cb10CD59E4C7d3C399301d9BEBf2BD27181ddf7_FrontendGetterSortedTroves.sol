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


contract FrontendGetterSortedTroves {

    struct TroveData {
        address user;
        uint debtPart;
        uint collShare;
        uint collRate;
        bool isSolvent;
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

        _troves = new TroveData[](_count);
        bool isSolvent;
        for (uint idx = 0; idx < _count; ++idx) {
            isSolvent = troveManager.isSolvent(currentTroveowner);
            // end with not solvent position
            if (isSolvent || currentTroveowner == address(0)) {
                break;
            }
            _troves[idx].user = currentTroveowner;
            _troves[idx].debtPart = troveManager.userBorrowPart(currentTroveowner);
            _troves[idx].collShare = troveManager.userCollateralShare(currentTroveowner);
            _troves[idx].collRate = troveManager.getCurrentCR(currentTroveowner);
            _troves[idx].isSolvent = isSolvent;

            currentTroveowner = sortedTroves.getNext(currentTroveowner);
        }
    }

}