// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Test5 {

    bool public isNormal;

    struct Bid {
        uint256 amount;
    }

    struct Auction {
        Bid[] bids;
    }

    Auction private auction;

    constructor() {
        Bid memory newBid;
        newBid.amount = 0;

        auction.bids.push(newBid);
        auction.bids.push(newBid);
        auction.bids.push(newBid);
        auction.bids.push(newBid);
        auction.bids.push(newBid);
        auction.bids.push(newBid);
    }

    function getAuction() external view returns (Auction memory) {
        return auction;
    }

    function flipIsNormal() external {
        isNormal = !isNormal;
    } 

    function bid(uint256 amount) external {
        Bid memory currentBid;
        currentBid.amount = amount;

        auction.bids.push(currentBid);
    }

    function reset() external {
        if (isNormal) {
            auction.bids[0].amount = 6;
            auction.bids[1].amount = 5;
            auction.bids[2].amount = 4;
            auction.bids[3].amount = 3;
            auction.bids[4].amount = 2;
            auction.bids[5].amount = 1;
        }
        else {
            auction.bids[0].amount = 1;
            auction.bids[1].amount = 2;
            auction.bids[2].amount = 3;
            auction.bids[3].amount = 4;
            auction.bids[4].amount = 5;
            auction.bids[5].amount = 6;
        }
    }

    function sort(uint256 sortType) external {
        _sort(sortType);
    }

    function _sort(uint256 sortType) internal {
        // storage -> memory
        Bid[] memory bidToSort = auction.bids;

        // sorting/reverse sorting
        if (sortType == 0) {
            if (isNormal) {
                _quickSort(bidToSort, int(0), int(bidToSort.length - 1)); // 62757 gas
            }
            else {
                _quickSortReverse(bidToSort, int(0), int(bidToSort.length - 1)); // 62768 gas
            }
        }
        else if (sortType == 1) {
            if (isNormal) {
                _insertionSort(bidToSort); // 70780 gas
            }
            else {
                _insertionSortReverse(bidToSort); // 70803 gas
            }
        }
        else if (sortType == 2) {
            if (isNormal) {
                _mergeSort(bidToSort, int(0), int(bidToSort.length - 1)); // 82766 gas
            }
            else {
                // _mergeSortReverse(bidToSort, int(0), int(bidToSort.length - 1));
            }
        }

        // memory -> storage
        for (uint256 i = 0 ; i < bidToSort.length ; i++) {
            auction.bids[i] = bidToSort[i];
        }
    }

    /// @dev Sort Type 0 is Quick Sort
    function _quickSort(Bid[] memory unsortedBids, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;

        if (i == j) return;

        uint256 pivot = unsortedBids[uint256(left + (right - left) / 2)].amount;

        while (i <= j) {
            while (unsortedBids[uint256(i)].amount < pivot) i++;

            while (pivot < unsortedBids[uint256(j)].amount) j--;

            if (i <= j) {
                (unsortedBids[uint256(i)], unsortedBids[uint256(j)]) = (unsortedBids[uint256(j)], unsortedBids[uint256(i)]);
                i++;
                j--;
            }
        }
    
        if (left < j) _quickSort(unsortedBids, left, j);

        if (i < right) _quickSort(unsortedBids, i, right);
    }

    function _quickSortReverse(Bid[] memory unsortedBids, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;

        if (i == j) return;

        uint256 pivot = unsortedBids[uint256(left + (right - left) / 2)].amount;

        while (i <= j) {
            while (pivot < unsortedBids[uint256(i)].amount) i++;

            while (unsortedBids[uint256(j)].amount < pivot) j--;

            if (i <= j) {
                (unsortedBids[uint256(i)], unsortedBids[uint256(j)]) = (unsortedBids[uint256(j)], unsortedBids[uint256(i)]);
                i++;
                j--;
            }
        }
    
        if (left < j) _quickSortReverse(unsortedBids, left, j);

        if (i < right) _quickSortReverse(unsortedBids, i, right);
    }

    /// @dev Sort Type 1 is Insertion Sort
    function _insertionSort(Bid[] memory unsortedBids) internal pure {
        int256 i;
        uint256 key;
        int256 j;

        for (i = 1 ; uint256(i) < unsortedBids.length ; i++) {
            key = unsortedBids[uint256(i)].amount;
            j = i - 1;

            /**
             * @dev moving elements of unsortedBids[0..i-1], that are 
             * greater than key, to one position ahead 
             * of their current position
             */
            while (j >= 0 && unsortedBids[uint256(j)].amount > key) {
                Bid memory temp = unsortedBids[uint256(j + 1)];
                unsortedBids[uint256(j + 1)] = unsortedBids[uint256(j)];
                unsortedBids[uint256(j)] = temp;
                j = j - 1;
            }
            unsortedBids[uint256(j + 1)].amount = key;
        }
    }

    function _insertionSortReverse(Bid[] memory unsortedBids) internal pure {
        int256 i;
        uint256 key;
        int256 j;

        for (i = 1 ; uint256(i) < unsortedBids.length ; i++) {
            key = unsortedBids[uint256(i)].amount;
            j = i - 1;

            /**
             * @dev moving elements of unsortedBids[0..i-1], that are 
             * lesser than key, to one position ahead 
             * of their current position
             */
            while (j >= 0 && unsortedBids[uint256(j)].amount < key) {
                Bid memory temp = unsortedBids[uint256(j + 1)];
                unsortedBids[uint256(j + 1)] = unsortedBids[uint256(j)];
                unsortedBids[uint256(j)] = temp;
                j = j - 1;
            }
            unsortedBids[uint256(j + 1)].amount = key;
        }
    }

    /// @dev Sort Type 2 is Merge Sort
    function _mergeSort(Bid[] memory unsortedBids, int256 left, int256 right) internal pure {
        if(left >= right){
            return;//returns recursively
        }

        int256 mid = left + ((right - left) / 2);

        _mergeSort(unsortedBids, left, mid);
        _mergeSort(unsortedBids, mid + 1, right);

        int256 n1 = mid - left + 1;
        int256 n2 = right - mid;

        // Create temp arrays
        Bid[] memory L = new Bid[](uint256(n1));
        Bid[] memory R = new Bid[](uint256(n2));

        // Copy data to temp arrays L[] and R[]
        for (int256 x = 0 ; x < n1 ; x++) {
            L[uint256(x)] = unsortedBids[uint256(left + x)];
        }
        for (int256 y = 0 ; y < n2 ; y++) {
            R[uint256(y)] = unsortedBids[uint256(mid + 1 + y)];
        }

        // Merge the temp arrays back into unsortedBids[left..right]

        // Initial index of first subarray
        int256 i = 0;

        // Initial index of second subarray
        int256 j = 0;

        // Initial index of merged subarray
        int256 k = left;

        while (i < n1 && j < n2) {
            if (L[uint256(i)].amount <= R[uint256(j)].amount) {
                unsortedBids[uint256(k)] = L[uint256(i)];
                i++;
            }
            else {
                unsortedBids[uint256(k)] = R[uint256(j)];
                j++;
            }
            k++;
        }

        // Copy the remaining elements of
        // L[], if there are any
        while (i < n1) {
            unsortedBids[uint256(k)] = L[uint256(i)];
            i++;
            k++;
        }

        // Copy the remaining elements of
        // R[], if there are any
        while (j < n2) {
            unsortedBids[uint256(k)] = R[uint256(j)];
            j++;
            k++;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint256);

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

    /**
    * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint256);

    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
    * another (`to`).
    *
    * Note that `value` may be zero.
    */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
    * @dev Emitted when the allowance of a `spender` for an `owner` is set by
    * a call to {approve}. `value` is the new allowance.
    */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}