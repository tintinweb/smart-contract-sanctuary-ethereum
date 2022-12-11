//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

error TwoLevelReferral__TransferFailed();
error TwoLevelReferral__InvalidDenomination();
error TwoLevelReferral__InvalidReferralDecimal();
error TwoLevelReferral__InvalidReferralPercentage();
error TwoLevelReferral__ContractAddressNotAllowed();

interface IPrevTwoLevelReferral {
    function getAllReferralKeys() external view returns (address[] memory);

    function referralMap(address _referral) external view returns (address);
}

contract TwoLevelReferral is Ownable {
    /** @dev Decimal is 1000 so first level percentage will be 0.5%, second level percentage will be 0.1%,
     * and root owner percentages will 0.4%, 0.5%, and 1%;
     */

    uint16 public decimal = 10**3; // 1000
    uint8 public firstLevelPercentage = 5;
    uint8 public secondLevelPercentage = 1;
    uint8 public totalFee = 10;
    uint8[3] public rootOwnerPercentage = [4, 5, 10];

    address[] public allReferralKeys;
    address[] public allowedToPayContractsArray;

    bool public allowAnyonePay = false;

    mapping(address => address) public referralMap; // key (playing user) -> value (refferer)
    mapping(address => bool) public depositorAdded;
    mapping(address => bool) public allowedToPayMap;

    event FirstLevelReferral(address indexed depositor, address referrer, uint256 reward);
    event SecondLevelReferral(address indexed depositor, address referrer, address secondLevelReferrer, uint256 reward);

    receive() external payable {}

    function payReferral(
        address _depositor,
        address _referrerAddress,
        uint256 _denomination
    ) public {
        // check if message sender is allowed contract address
        if (!allowedToPayMap[msg.sender] && !allowAnyonePay) {
            revert TwoLevelReferral__ContractAddressNotAllowed();
        }

        address rootOwner = owner();

        if (_denomination == 0) {
            revert TwoLevelReferral__InvalidDenomination();
        }

        bool success = false;

        if (_referrerAddress != address(0)) {
            uint256 firstLevelReward = (_denomination * firstLevelPercentage) / decimal;
            referralMap[_depositor] = _referrerAddress;

            if (referralMap[_referrerAddress] != address(0)) {
                // Send 0.5% to the refferer if decimal is 1000
                (success, ) = _referrerAddress.call{value: firstLevelReward}("");
                if (!success) {
                    revert TwoLevelReferral__TransferFailed();
                }

                emit FirstLevelReferral(_depositor, _referrerAddress, firstLevelReward);

                // Send 0.1% to the second level refferer if decimal is 1000
                address secondLevelReferrer = referralMap[_referrerAddress];
                uint256 secondLevelReward = (_denomination * secondLevelPercentage) / decimal;

                (success, ) = secondLevelReferrer.call{value: secondLevelReward}("");
                if (!success) {
                    revert TwoLevelReferral__TransferFailed();
                }

                emit SecondLevelReferral(_depositor, _referrerAddress, secondLevelReferrer, secondLevelReward);

                // Send 0.4% to the root owner if decimal is 1000
                (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage[0]) / decimal}("");
                if (!success) {
                    revert TwoLevelReferral__TransferFailed();
                }
            } else {
                // Send 0.5% to the refferer if decimal is 1000
                (success, ) = _referrerAddress.call{value: firstLevelReward}("");
                if (!success) {
                    revert TwoLevelReferral__TransferFailed();
                }

                emit FirstLevelReferral(_depositor, _referrerAddress, firstLevelReward);

                // Send 0.5% to the root owner if decimal is 1000
                (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage[1]) / decimal}("");
                if (!success) {
                    revert TwoLevelReferral__TransferFailed();
                }
            }
        } else {
            // Send 1% to the root owner if decimal is 1000
            (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage[2]) / decimal}("");
            if (!success) {
                revert TwoLevelReferral__TransferFailed();
            }
        }
    } //end pay

    function getTotalFee() public view returns (uint8) {
        return totalFee;
    }

    function getDecimal() public view returns (uint16) {
        return decimal;
    }

    function getAllReferralKeys() external view returns (address[] memory) {
        return allReferralKeys;
    }

    function getAllAllowedToPayContractsArray() external view returns (address[] memory) {
        return allowedToPayContractsArray;
    }

    function getAllReferralMap() external view returns (address[] memory, address[] memory) {
        address[] memory keyAddresses = new address[](allReferralKeys.length);
        address[] memory valueAddresses = new address[](allReferralKeys.length);

        for (uint256 i = 0; i < allReferralKeys.length; i++) {
            address refKey = allReferralKeys[i];
            keyAddresses[i] = refKey;
            valueAddresses[i] = referralMap[refKey];
        }
        return (keyAddresses, valueAddresses);
    }

    function getAllUserFirstLevel(address _userAddress) public view returns (address[] memory) {
        address[] memory firstLevel = new address[](allReferralKeys.length);
        uint256 lvIndex = 0;
        for (uint256 i = 0; i < allReferralKeys.length; i++) {
            address refKey = allReferralKeys[i];
            if (referralMap[refKey] == _userAddress) {
                firstLevel[lvIndex] = refKey;
                lvIndex++;
            }
        }

        return firstLevel;
    }

    function getAllUserSecondLevel(address _userAddress) public view returns (address[] memory) {
        address[] memory secondLevel = new address[](allReferralKeys.length);
        uint256 lvIndex = 0; //just leave empty items in the back of the array
        for (uint256 i = 0; i < allReferralKeys.length; i++) {
            address firstLevel = referralMap[allReferralKeys[i]]; //value is first level refferer
            if (referralMap[firstLevel] == _userAddress) {
                secondLevel[lvIndex] = allReferralKeys[i];
                lvIndex++;
            }
        }
        return secondLevel;
    }

    function addAllowedToPayContractAddress(address _contractAllowed) external onlyOwner {
        allowedToPayContractsArray.push(_contractAllowed);
        allowedToPayMap[_contractAllowed] = true;
    }

    function toggleAllowAnyonePay(bool _allowAnyAddress) external onlyOwner {
        allowAnyonePay = _allowAnyAddress;
    }

    function removeAllowedContractAddress(address _contractAllowed) external onlyOwner {
        require(allowedToPayMap[_contractAllowed], "Token not added");

        uint256 indexToDelete = 2**256 - 1;

        for (uint256 i = 0; i < allowedToPayContractsArray.length; i++) {
            if (allowedToPayContractsArray[i] == _contractAllowed) {
                indexToDelete = i;
            }
        }

        allowedToPayContractsArray[indexToDelete] = allowedToPayContractsArray[allowedToPayContractsArray.length - 1];
        allowedToPayContractsArray.pop();
        allowedToPayMap[_contractAllowed] = false;
    }

    function setFirstLevelPercentage(uint8 _firstLevelPercentage) external onlyOwner {
        firstLevelPercentage = _firstLevelPercentage;
    }

    function setSecondLevelPercentage(uint8 _secondLevelPercentage) external onlyOwner {
        secondLevelPercentage = _secondLevelPercentage;
    }

    function setRootOwnerPercentage(uint8[3] memory _rootOwnerPercentage) external onlyOwner {
        rootOwnerPercentage = _rootOwnerPercentage;
        totalFee = _rootOwnerPercentage[2];
    }

    function migrateReferrals(address previousContract) external onlyOwner {
        IPrevTwoLevelReferral prevTwoLevelReferral = IPrevTwoLevelReferral(previousContract);
        address[] memory referralKeys = prevTwoLevelReferral.getAllReferralKeys();

        for (uint256 i = 0; i < referralKeys.length; i++) {
            address referralKey = referralKeys[i];
            referralMap[referralKey] = prevTwoLevelReferral.referralMap(referralKey);
            allReferralKeys.push(referralKey);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}