// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../data_type/DataType.sol";
import "../storage/LibLaunchpadStorage.sol";
import "../libs/Ownable.sol";


contract AdminFeature is Ownable {

    event AddAdministrator(address indexed administrator);
    event RemoveAdministrator(address indexed administrator);

    modifier ownerOrAdministrator() {
        require(
            owner() == msg.sender || LibLaunchpadStorage.getStorage().administrators[msg.sender],
            "Caller is not the owner or administrator"
        );
        _;
    }

    function getReentrancyStatus() external view returns(uint256) {
        return LibOwnableStorage.getStorage().reentrancyStatus;
    }

    function initReentrancyStatus() external onlyOwner {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        if (stor.reentrancyStatus == 0) {
            stor.reentrancyStatus = 1;
        }
    }

    // get proxy address
    function getRegistry(bytes4 /* proxyId */) external view returns (address) {
        return address(this);
    }

    function isAdministrator(address account) external view returns(bool) {
        return LibLaunchpadStorage.getStorage().administrators[account];
    }

    function addAdministrator(address account) external onlyOwner {
        require(account != address(0), "account can't be address(0)");
        require(!LibLaunchpadStorage.getStorage().administrators[account], "account is added");
        LibLaunchpadStorage.getStorage().administrators[account] = true;
        emit AddAdministrator(account);
    }

    function removeAdministrator(address account) external onlyOwner {
        require(account != address(0), "account can't be address(0)");
        require(LibLaunchpadStorage.getStorage().administrators[account], "account is removed");
        LibLaunchpadStorage.getStorage().administrators[account] = false;
        emit RemoveAdministrator(account);
    }

    function getLaunchpadSlot(bytes4 launchpadId, uint256 slotId) external view returns(DataType.LaunchpadSlot memory slot) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        return LibLaunchpadStorage.getStorage().launchpadSlots[key];
    }

    function setLaunchpadSlotSaleQty(DataType.LaunchpadSlot calldata slot) external ownerOrAdministrator {
        DataType.LaunchpadSlot storage s = _getLaunchpadSlot(slot.launchpadId, slot.slotId);
        s.saleQty = slot.saleQty;
    }

    function setLaunchpadSlot(DataType.LaunchpadSlot calldata slot) external ownerOrAdministrator {
        if (slot.paymentToken != address(0)) {
            require(slot.feeType == 0, "feeType error");
            require(slot.feeReceipt != address(0), "feeReceipt error");
        }

        DataType.LaunchpadSlot storage s = _getLaunchpadSlot(slot.launchpadId, slot.slotId);
        s.launchpadId = slot.launchpadId;
        s.slotId = slot.slotId;
        s.enable = slot.enable;  // enable flag
        s.whiteListModel = slot.whiteListModel;
        s.feeType = slot.feeType; // 0 - to feeReceipt, 1 - to targetContract
        s.feeReceipt = slot.feeReceipt;

        s.maxSupply = slot.maxSupply; // max supply of this slot
        s.maxBuyQtyPerAccount = slot.maxBuyQtyPerAccount; // max buy qty per address
        // finalPrice = price * (10 ** priceUint)
        s.pricePresale = slot.pricePresale;
        s.price = slot.price;
        s.priceUint = slot.priceUint;
        s.paymentToken = slot.paymentToken;

        s.saleStart = slot.saleStart; // buy start time, seconds
        s.saleEnd = slot.saleEnd; // buy end time, seconds
        s.whiteListSaleStart = slot.whiteListSaleStart; // whitelist start time
        s.signer = slot.signer; // signers for whitelist

        s.storeSaleQtyFlag = slot.storeSaleQtyFlag; // true - store， false - no need to store
        s.storeAccountQtyFlag = slot.storeAccountQtyFlag; // true - store， false - no need to store
        s.mintParams = slot.mintParams;
        s.queryAccountMintedQtyParams = slot.queryAccountMintedQtyParams;
        s.mintSelector = slot.mintSelector;
        s.queryAccountMintedQtySelector = slot.queryAccountMintedQtySelector;
        s.targetContract = slot.targetContract; // target contract of 3rd project,
    }

    function setLaunchpadSlotData1(DataType.LaunchpadSlot calldata slot) external ownerOrAdministrator {
        if (slot.paymentToken != address(0)) {
            require(slot.feeType == 0, "feeType error");
            require(slot.feeReceipt != address(0), "feeReceipt error");
        }

        DataType.LaunchpadSlot storage s = _getLaunchpadSlot(slot.launchpadId, slot.slotId);
        s.launchpadId = slot.launchpadId;
        s.slotId = slot.slotId;
        s.enable = slot.enable;  // enable flag
        s.whiteListModel = slot.whiteListModel;
        s.feeType = slot.feeType; // 0 - to feeReceipt, 1 - to targetContract
        s.feeReceipt = slot.feeReceipt;

        s.maxSupply = slot.maxSupply; // max supply of this slot
        s.maxBuyQtyPerAccount = slot.maxBuyQtyPerAccount; // max buy qty per address
        // finalPrice = price * (10 ** priceUint)
        s.pricePresale = slot.pricePresale;
        s.price = slot.price;
        s.priceUint = slot.priceUint;
        s.paymentToken = slot.paymentToken;
    }

    function setLaunchpadSlotData3(DataType.LaunchpadSlot calldata slot) external ownerOrAdministrator {
        DataType.LaunchpadSlot storage s = _getLaunchpadSlot(slot.launchpadId, slot.slotId);
        s.saleStart = slot.saleStart; // buy start time, seconds
        s.saleEnd = slot.saleEnd; // buy end time, seconds
        s.whiteListSaleStart = slot.whiteListSaleStart; // whitelist start time
        s.signer = slot.signer; // signers for whitelist
    }

    function setLaunchpadSlotData4(DataType.LaunchpadSlot calldata slot) external ownerOrAdministrator {
        DataType.LaunchpadSlot storage s = _getLaunchpadSlot(slot.launchpadId, slot.slotId);
        s.storeSaleQtyFlag = slot.storeSaleQtyFlag; // true - store， false - no need to store
        s.storeAccountQtyFlag = slot.storeAccountQtyFlag; // true - store， false - no need to store
        s.mintParams = slot.mintParams;
        s.queryAccountMintedQtyParams = slot.queryAccountMintedQtyParams;
        s.mintSelector = slot.mintSelector;
        s.queryAccountMintedQtySelector = slot.queryAccountMintedQtySelector;
        s.targetContract = slot.targetContract; // target contract of 3rd project,
    }

    function _getLaunchpadSlot(bytes4 launchpadId, uint256 slotId) internal view returns(DataType.LaunchpadSlot storage) {
        require(launchpadId != bytes4(0), "launchpadId error");
        require(slotId <= 255, "slotId error");

        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        return LibLaunchpadStorage.getStorage().launchpadSlots[key];
    }

    function _getLaunchpadSlotKey(bytes4 launchpadId, uint256 slotId) internal pure returns(bytes32 key) {
        assembly {
            // bytes4(launchpadId) + bytes1(slotId) + bytes27(0)
            key := or(launchpadId, shl(216, and(slotId, 0xff)))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library  DataType {

    // process buy additional flag
    uint256 constant internal BUY_ADDITIONAL_IDX_WL_MAX_BUY_NUM = 0; // whitelist max buy number
    uint256 constant internal BUY_ADDITIONAL_IDX_SIMULATION     = 1; // simulation buy

    // role
    uint256 constant internal ROLE_LAUNCHPAD_FEE_RECEIPTS   = 1; // fee receipt
    uint256 constant internal ROLE_LAUNCHPAD_CONTROLLER     = 2; // launchpad controller
    uint256 constant internal ROLE_PROXY_OWNER              = 4; // proxy admin
    uint256 constant internal ROLE_LAUNCHPAD_SIGNER         = 8; // launchpad signer

    // simulation flag
    uint256 constant internal SIMULATION_NONE                       = 0; // no simulation
    uint256 constant internal SIMULATION_CHECK                      = 1; // check param
    uint256 constant internal SIMULATION_CHECK_REVERT               = 2; // check param, then revert
    uint256 constant internal SIMULATION_CHECK_PROCESS_REVERT       = 3; // check param & process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_START_PROCESS_REVERT = 4; // escape check start time param, process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_WHITELIST_PROCESS_REVERT = 5; // escape check skip whitelist param, process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_BALANCE_PROCESS_REVERT = 6; // escape check skip whitelist param, process, then revert
    uint256 constant internal SIMULATION_NO_CHECK_PROCESS_REVERT    = 7; // escape check param, process, then revert

    enum WhiteListModel {
        NONE,                     // 0 - No White List
        ON_CHAIN_CHECK,           // 1 - Check address on-chain
        OFF_CHAIN_SIGN,           // 2 - Signed by off-chain valid address
        OFF_CHAIN_MERKLE_ROOT     // 3 - check off-chain merkle tree root
    }

    struct LaunchpadSlot {
        uint32 saleQty;    // current sale number, must from 0
        bytes4 launchpadId; // launchpad id
        uint8 slotId; // slot id
        bool enable;  // enable flag
        WhiteListModel whiteListModel;
        uint8 feeType; // 0 - to feeReceipt, 1 - to targetContract
        address feeReceipt;

        uint32 maxSupply; // max supply of this slot
        uint16 maxBuyQtyPerAccount; // max buy qty per address
        // finalPrice = price * (10 ** priceUint)
        uint16 pricePresale;
        uint16 price;
        uint16 priceUint;
        address paymentToken;

        uint32 saleStart; // buy start time, seconds
        uint32 saleEnd; // buy end time, seconds
        uint32 whiteListSaleStart; // whitelist start time
        address signer; // signers for whitelist

        bool storeSaleQtyFlag; // true - store， false - no need to store
        bool storeAccountQtyFlag; // true - store， false - no need to store
        uint8 mintParams;
        uint8 queryAccountMintedQtyParams;
        bytes4 mintSelector;
        bytes4 queryAccountMintedQtySelector;
        address targetContract; // target contract of 3rd project,
    }

    struct Launchpad {
        uint8 slotNum;
    }

    // stats info for buyer account
    struct AccountSlotStats {
        uint16 totalBuyQty; // total buy num already
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../data_type/DataType.sol";


library LibLaunchpadStorage {

    uint256 constant STORAGE_ID_LAUNCHPAD = 2 << 128;

    struct Storage {
        mapping(address => bool) administrators;

        // bytes4(launchpadId) + bytes1(slotId) + bytes27(0)
        mapping(bytes32 => DataType.LaunchpadSlot) launchpadSlots;

        // bytes4(launchpadId) + bytes1(slotId) + bytes7(0) + bytes20(accountAddress)
        mapping(bytes32 => DataType.AccountSlotStats) accountSlotStats;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_LAUNCHPAD }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../storage/LibOwnableStorage.sol";


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
abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibOwnableStorage.getStorage().owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
    function _transferOwnership(address newOwner) private {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library LibOwnableStorage {

    uint256 constant STORAGE_ID_OWNABLE = 1 << 128;

    struct Storage {
        uint256 reentrancyStatus;
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_OWNABLE }
    }
}