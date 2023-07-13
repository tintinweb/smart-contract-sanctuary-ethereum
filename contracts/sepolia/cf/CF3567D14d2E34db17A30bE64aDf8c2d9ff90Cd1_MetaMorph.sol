// SPDX-License-Identifier: SCRY
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface Morpheus {
    function requestFeeds(
        string[] calldata APIendpoint,
        string[] calldata APIendpointPath,
        uint256[] calldata decimals,
        uint256[] calldata bounties
    ) external payable returns (uint256[] memory feeds);

    function supportFeeds(
        uint256[] calldata feedIds,
        uint256[] calldata values
    ) external payable;

    function getFeed(
        uint256 feedIDs
    ) external view returns (uint256, uint256, uint256, string memory);
}

contract MetaMorph is Ownable {
    function getFeeds(
        address[] memory morpheus,
        uint256[] memory IDs,
        uint256 threshold
    ) external view returns (uint256 value, string memory valStr) {
        uint256 returnPrices;
        uint256 returnTimestamps;
        uint256 returnDecimals;
        string memory returnStr;
        uint256[] memory total = new uint256[](morpheus.length);
        string[] memory strVal = new string[](morpheus.length);
        strValstruct[] memory strVals = new strValstruct[](morpheus.length);
        for (uint256 i = 0; i < IDs.length; i++) {
            (
                returnPrices,
                returnTimestamps,
                returnDecimals,
                returnStr
            ) = Morpheus(morpheus[i]).getFeed(IDs[i]);
            if (
                block.timestamp - threshold < returnTimestamps || threshold == 0
            ) {
                total[i] = returnPrices / 10 ** returnDecimals;
                strVal[i] = returnStr;
                }
        }
        uint256[] memory sorted = new uint256[](morpheus.length);
        sorted = sort(total);
        // uneven so we can take the middle
        if (sorted.length % 2 == 1) {
            uint sizer = (sorted.length + 1) / 2;
            value = sorted[sizer - 1];
            // take average of the 2 most inner numbers
        } else {
            uint size1 = (sorted.length) / 2;
            value = (sorted[size1 - 1] + sorted[size1]) / 2;
        }
       (valStr,)= getMostFrequent(strVal);
    }

    struct strValstruct {
        string key;
        uint value;
    }

    function requestFeed(
        address[] memory morpheus,
        string memory APIendpoint,
        string memory APIendpointPath,
        uint256 decimals,
        uint256[] memory bounties
    ) external payable returns (uint256[] memory) {
        uint256 total;
        uint256[] memory ids = new uint256[](morpheus.length);
        uint256[] memory IDS = new uint256[](morpheus.length);
        string[] memory APIendpnt = new string[](morpheus.length);
        string[] memory APIendpth = new string[](morpheus.length);
        uint256[] memory dec = new uint256[](morpheus.length);
        uint256[] memory bount = new uint256[](morpheus.length);
        for (uint256 i = 0; i < morpheus.length; i++) {
            APIendpnt[0] = APIendpoint;
            APIendpth[0] = APIendpointPath;
            dec[0] = decimals;
            bount[0] = bounties[i];
            ids = Morpheus(morpheus[i]).requestFeeds{value: bount[0]}(
                APIendpnt,
                APIendpth,
                dec,
                bount
            );
            IDS[i] = ids[0];
        }
        return (IDS);
    }

    function updateFeeds(
        address[] memory morpheus,
        uint256[] memory IDs,
        uint256[] memory bounties
    ) external payable {
        require(
            morpheus.length == IDs.length && IDs.length == bounties.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < morpheus.length; i++) {
            uint256[] memory id = new uint256[](1);
            id[0] = IDs[i];
            uint256[] memory bounty = new uint256[](1);
            bounty[0] = bounties[i];
            Morpheus(morpheus[i]).supportFeeds{value: bounty[0]}(id, bounty);
        }
    }

    function withdraw(
        uint256[] memory feedIds,
        uint256[] memory values
    ) external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function CompareStrings(
        string memory str1,
        string memory str2
    ) public pure returns (bool) {
        if (
            keccak256(abi.encodePacked((str1))) ==
            keccak256(abi.encodePacked((str2)))
        ) return true;
        else return false;
    }
// Mapping to store string occurrence counts
    mapping(bytes32 => uint) stringCounts;

    // Function to find the most used string in an array
    function findMostUsedString(string[] memory arr) public returns(string memory,uint) {
        // Reset mapping
        for(uint i = 0; i < arr.length; i++) {
            stringCounts[keccak256(abi.encodePacked(arr[i]))] = 0;
        }

        // Loop over the array and increment the count for each string
        for(uint i = 0; i < arr.length; i++) {
            stringCounts[keccak256(abi.encodePacked(arr[i]))]++;
        }

        return getMostFrequent(arr);
    }

    // Helper function to find the string with the highest count
    function getMostFrequent(string[] memory arr) private view returns(string memory,uint) {
        string memory mostUsedString = arr[0];
        uint highestCount = stringCounts[keccak256(abi.encodePacked(mostUsedString))];

        // Iterate over the array to find the string with the highest count
        for(uint i = 1; i < arr.length; i++) {
            if(stringCounts[keccak256(abi.encodePacked(arr[i]))] > highestCount) {
                mostUsedString = arr[i];
                highestCount = stringCounts[keccak256(abi.encodePacked(mostUsedString))];
            }
        }

        return (mostUsedString, highestCount);
    }
    function quickSort(uint[] memory arr, uint left, uint right) private pure {
        uint i = left;
        uint j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function sort(uint[] memory data) private pure returns (uint[] memory) {
        quickSort(data, 0, data.length - 1);
        return data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}