// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract DemonicScullsContract {
    function mintForAddress(address wallet, uint256 level, uint256 id) external virtual;
    function mintRefund(address wallet) external virtual;
    function setClaimedId(uint256 id) external virtual;
}

contract DemonicSkullsRestoration is Ownable {

    DemonicScullsContract demonicSkullsContract;

    struct MinterInput {
        address wallet;
        uint256[] ids;
    }

    mapping(uint256 => address) minters;
    mapping(uint256 => uint256[]) mintedIds;

    uint256 private constant LEVEL_ONE_BLOOD_AMOUNT = 1;
    uint256 private constant LEVEL_TWO_BLOOD_AMOUNT = 3;
    uint256 private constant LEVEL_THREE_BLOOD_AMOUNT = 5;

    bool public levelOneClaimed = false;
    bool public levelTwoClaimed = false;
    bool public levelThreeClaimed = false;
    uint256 mintersAmount = 0;
    uint256[] claimedIds;

    constructor(
        address[] memory mintersAddresses,
        uint256[][] memory ids,
        uint256[] memory claimedCryptoSkulls,
        address dsContract) {
        demonicSkullsContract = DemonicScullsContract(dsContract);
        for (uint256 i = 0; i < mintersAddresses.length; i++) {
            minters[i] = mintersAddresses[i];
            mintedIds[i] = ids[i];
            mintersAmount++;
        }
        claimedIds = claimedCryptoSkulls;
    }

    function setDemonicSkullsContract(address dsContractAddress) public onlyOwner {
        demonicSkullsContract = DemonicScullsContract(dsContractAddress);
    }

    function setClaimedIds() public onlyOwner {
        for (uint256 i = 0; i < claimedIds.length; i++) {
            demonicSkullsContract.setClaimedId(claimedIds[i]);
        }
    }

    function claimLevelOnes() public onlyOwner {
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id < 10000) {
                    demonicSkullsContract.mintForAddress(minters[i], LEVEL_ONE_BLOOD_AMOUNT, id);
                }
            }
        }
        levelOneClaimed = true;
    }

    function claimLevelTwos() public onlyOwner {
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id > 9999 && id < 12500) {
                    demonicSkullsContract.mintForAddress(minters[i], LEVEL_TWO_BLOOD_AMOUNT, id);
                }
            }
        }
        levelTwoClaimed = true;
    }

    function claimLevelThrees() public onlyOwner {
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id > 12499 && id < 12650) {
                    demonicSkullsContract.mintForAddress(minters[i], LEVEL_THREE_BLOOD_AMOUNT, id);
                }
            }
        }
        levelThreeClaimed = true;
    }

    function claimScrewedOnes() public onlyOwner {
        require(levelTwoClaimed, "You must claim level 2 first!");
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id > 12649) {
                    demonicSkullsContract.mintRefund(minters[i]);
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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