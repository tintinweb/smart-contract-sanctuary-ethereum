// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";

contract PackBorders is Ownable {
    uint256 public packBorders = 6;
    address public parentAddress = address(0x0);

    constructor(address _parentAddress) {
        parentAddress = _parentAddress;
    }

    modifier onlySeapad() {
        _;
        require(
            msg.sender == parentAddress || msg.sender == owner(),
            "Only parent contract can call this.(PackBorders.sol)."
        );
    }

    // STRUCTS
    struct ValidPackBorders {
        uint256 borderId;
        bool created;
        bool valid;
        bytes packBorderLink;
        bool isCustom;
        uint256 isUsed;
        uint256 usageLimitationAmount;
        mapping(address => BorderUser) borderBoughtUser;
    }
    struct BorderUser {
        address user;
        uint256 borderId;
        uint256 timeAdded;
        uint256 used;
        uint256 amountUsageLeft;
    }
    // MAPPING
    mapping(uint256 => ValidPackBorders) public VPB;

    // FUNCTIONS

    // ADD A BORDER OR UPDATES IT.
    function updateBorder(
        uint256 borderId,
        bool valid,
        uint256 usageLimitationAmount,
        uint256 amountTimesUsed,
        string memory packBorderLink
    ) public onlyOwner {
        ValidPackBorders storage PB = VPB[borderId];
        require(borderId != 0, "Invalid borderId");
        PB.created = true;
        PB.borderId = borderId;
        PB.valid = valid;
        PB.usageLimitationAmount = usageLimitationAmount;
        PB.isUsed = amountTimesUsed;
        PB.packBorderLink = abi.encodePacked(packBorderLink);
        if (borderId > 6) {
            PB.isCustom = true;
        }
    }

    // ADD USER TO THE BORDER ID
    function addUserToBorder(
        uint256 borderId,
        address user,
        uint256 amountUsageLeft
    ) public onlySeapad {
        ValidPackBorders storage PB = VPB[borderId];
        require(PB.borderId != 0, "Invalid borderId");
        BorderUser storage BU = PB.borderBoughtUser[user];
        BU.user = user;
        BU.borderId = borderId;
        BU.timeAdded = block.timestamp;
        BU.amountUsageLeft = amountUsageLeft;
    }

    // LET USER USE BORDER
    function useBorder(uint256 borderId) public onlySeapad {
        ValidPackBorders storage PB = VPB[borderId];
        require(PB.borderId != 0, "Invalid borderId");
        require(PB.valid == true, "Pack has not yet been validated");
        BorderUser storage BU = PB.borderBoughtUser[tx.origin];
        if (borderId > 6) {
            require(
                BU.amountUsageLeft > 0,
                "You dont have access to this border."
            );
            BU.amountUsageLeft = BU.amountUsageLeft - 1;
            BU.used = BU.used + 1;
        }
    }

    // CHANGES THE FREE EDITION BORDER IMAGES BASE URL
    function changeFreeEditionBorderImages(string calldata borderImageLinks)
        public
        onlyOwner
    {
        for (uint256 i = 0; i <= 6; i++) {
            VPB[i].borderId = i;
            VPB[i].valid = true;
            //link needs to be something like https://..../ , and we manually add the id and .png, so the image link MUST CONTAIN PNG IMAGE FILES (1-6)
            bytes memory t = abi.encodePacked(
                borderImageLinks,
                uint2str(i),
                ".png"
            );
            VPB[i].packBorderLink = t;
            VPB[i].usageLimitationAmount = 0;
        }
    }

    // UPDATES PARENT CONTRACT ADDRESS
    function updateParentContract(address newParentAddress) public onlyOwner {
        parentAddress = newParentAddress;
    }

    // GETS PACK BORDER BY ID
    function getPackBorder(uint256 borderId)
        public
        view
        returns (
            uint256 _borderId,
            bool valid,
            string memory packBorderLink,
            bool isCustom,
            uint256 isUsed,
            uint256 usageLimitationAmount
        )
    {
        ValidPackBorders storage packBorder = VPB[borderId];

        return (
            packBorder.borderId,
            packBorder.valid,
            bytesToString(packBorder.packBorderLink),
            packBorder.isCustom,
            packBorder.isUsed,
            packBorder.usageLimitationAmount
        );
    }

    // GETS BORDER USER FOR PACK BORDER
    function getPackBorderWallet(uint256 _borderId, address wallet)
        public
        view
        returns (
            address user,
            uint256 borderId,
            uint256 timePurchased,
            uint256 used,
            uint256 amountUsageLeft
        )
    {
        ValidPackBorders storage packBorder = VPB[_borderId];
        BorderUser memory borderUser = packBorder.borderBoughtUser[wallet];
        return (
            borderUser.user,
            borderUser.borderId,
            borderUser.timeAdded,
            borderUser.used,
            borderUser.amountUsageLeft
        );
    }

    // HELPER FUNCTION
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // HELPER FUNCTION
    function bytesToString(bytes memory byteCode)
        public
        pure
        returns (string memory stringData)
    {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint256 cycles = byteCode.length / 0x20;
        uint256 requiredAlloc = length;

        if (
            length % 0x20 > 0
        ) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20) //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0) {
            uint256 offsetStart = 0x20 + length;
            assembly {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
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