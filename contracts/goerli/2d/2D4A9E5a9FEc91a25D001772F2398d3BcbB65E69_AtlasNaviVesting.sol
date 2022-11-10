// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AtlasNaviVesting is Ownable {
    address public atlasNaviToken;

    enum VestingCategory {
        Seed,
        Strategic,
        PrivateSale
    }

    struct Vesting {
        uint256 amountOfLockedTokens;
        uint256 amountOfUnlockedTokens;
        uint256 amountOfTokensAlreadyClaimed;
        uint256 vestingCategory;
    }

    struct AddBulkStruct {
        address accountAddress;
        Vesting[] vestings;
    }

    mapping(address => Vesting[]) mappingAddressVesting;

    uint256 public tgeTimestamp;

    constructor(address atlasNaviTokenAddress) {
        atlasNaviToken = atlasNaviTokenAddress;
        tgeTimestamp = 1668124801; //11-11-2022: 0:00:01;
    }

    function setTGE(uint256 timestamp) public onlyOwner {
        tgeTimestamp = timestamp;
    }

    function AddInvestor(
        address accountAddress,
        uint256 vestingCategory,
        uint256 amount
    ) public onlyOwner {
        Vesting memory vestingObj;
        vestingObj.vestingCategory = vestingCategory;
        vestingObj.amountOfLockedTokens = amount;

        mappingAddressVesting[accountAddress].push(vestingObj);
        emit InvestorAdded(accountAddress, vestingCategory, amount);
    }

    function AddInvestorsBulk(AddBulkStruct[] memory objects) public onlyOwner {
        for (uint256 i = 0; i < objects.length; i++) {
            address accountAddress = objects[i].accountAddress;
            Vesting[] memory vestingsForThisAddress = objects[i].vestings;
            for (uint256 j = 0; j < vestingsForThisAddress.length; j++) {
                AddInvestor(
                    accountAddress,
                    vestingsForThisAddress[j].vestingCategory,
                    vestingsForThisAddress[j].amountOfLockedTokens
                );
            }
        }
    }

    function getVestingObject(address accountAddress, uint256 index)
        public
        view
        returns (Vesting memory)
    {
        return mappingAddressVesting[accountAddress][index];
    }

    function getTokensAvailableToClaim(address accountAddress, uint256 index)
        public
        view
        returns (uint256)
    {
        return
            mappingAddressVesting[accountAddress][index]
                .amountOfUnlockedTokens -
            mappingAddressVesting[accountAddress][index]
                .amountOfTokensAlreadyClaimed;
    }

    function claim(uint256 index) public {
        Vesting memory vestingObj = GetVestingObjectUpdated(msg.sender, index);

        IERC20(atlasNaviToken).transfer(
            msg.sender,
            vestingObj.amountOfUnlockedTokens
        );

        emit TokensClaimed(
            msg.sender,
            vestingObj.amountOfUnlockedTokens,
            block.timestamp
        );
    }

    function GetVestingObjectUpdated(address account, uint256 index)
        private
        returns (Vesting memory)
    {
        Vesting memory vestingObj = mappingAddressVesting[account][index];
        uint256 daysFromTGE = (block.timestamp - tgeTimestamp) / 60 / 60 / 24;
        if (vestingObj.vestingCategory == uint256(VestingCategory.Seed)) {
            uint256 nrOfDaysWith5;
            uint256 nrOfdaysWith7;
            if (block.timestamp >= tgeTimestamp) {
                //the instant 5%
                vestingObj.amountOfUnlockedTokens =
                    (vestingObj.amountOfLockedTokens / 100) *
                    5;
                vestingObj.amountOfLockedTokens -=
                    (vestingObj.amountOfLockedTokens / 100) *
                    5;
            }

            if (daysFromTGE >= 90) {
                //5%/day;
                if (daysFromTGE <= 120) {
                    nrOfDaysWith5 = daysFromTGE - 90;
                } else {
                    nrOfDaysWith5 = 30;
                }
            }

            if (daysFromTGE >= 365) {
                //7.5% per day
                if (daysFromTGE <= 730) {
                    nrOfdaysWith7 = daysFromTGE - 365;
                } else {
                    nrOfdaysWith7 = 365;
                }
            }

            for (uint256 i = 0; i < nrOfDaysWith5; i++) {
                vestingObj.amountOfUnlockedTokens +=
                    (vestingObj.amountOfLockedTokens / 100) *
                    5;
                vestingObj.amountOfLockedTokens -=
                    (vestingObj.amountOfLockedTokens / 100) *
                    5;
            }

            for (uint256 i = 0; i < nrOfdaysWith7; i++) {
                uint256 percent = uint256(75) / 100; //7.5%
                vestingObj.amountOfUnlockedTokens +=
                    vestingObj.amountOfLockedTokens *
                    percent;
                vestingObj.amountOfLockedTokens -=
                    vestingObj.amountOfLockedTokens *
                    percent;
            }
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Strategic)
        ) {
            uint256 nrOfDays;
            if (block.timestamp >= tgeTimestamp) {
                //the instant 4.96%
                uint256 percent = uint256(496) / 10000; //4.96%
                vestingObj.amountOfUnlockedTokens =
                    vestingObj.amountOfLockedTokens *
                    percent;
                vestingObj.amountOfLockedTokens -=
                    vestingObj.amountOfLockedTokens *
                    percent;
            }

            if (daysFromTGE >= 365) {
                if (daysFromTGE <= 730) {
                    nrOfDays = daysFromTGE - 365;
                } else {
                    nrOfDays = 365;
                }
            }
            for (uint256 i = 0; i < nrOfDays; i++) {
                uint256 percent = uint256(792) / 10000; //7.92%
                vestingObj.amountOfUnlockedTokens +=
                    vestingObj.amountOfLockedTokens *
                    percent;
                vestingObj.amountOfLockedTokens -=
                    vestingObj.amountOfLockedTokens *
                    percent;
            }
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.PrivateSale)
        ) {
            uint256 nrOfDaysWith5;
            uint256 nrOfDaysWith6;
            uint256 nrOfDaysWith1;
            if (block.timestamp >= tgeTimestamp) {
                //the instant 10%
                vestingObj.amountOfUnlockedTokens =
                    (vestingObj.amountOfLockedTokens / 100) *
                    10;
                vestingObj.amountOfLockedTokens -=
                    (vestingObj.amountOfLockedTokens / 100) *
                    10;
            }

            if (daysFromTGE >= 90) {
                if (daysFromTGE <= 120) {
                    nrOfDaysWith5 = daysFromTGE - 90;
                } else {
                    nrOfDaysWith5 = 30;
                }
            }

            if (daysFromTGE > 120) {
                if (daysFromTGE <= 510) {
                    //month 17
                    nrOfDaysWith6 = daysFromTGE - 120;
                } else {
                    nrOfDaysWith6 = 390;
                }
            }

            if (daysFromTGE > 510) {
                if (daysFromTGE <= 540) {
                    nrOfDaysWith1 = daysFromTGE - 510;
                } else {
                    nrOfDaysWith1 = 30;
                }
            }
        }

        return vestingObj;
    }

    event InvestorAdded(
        address account,
        uint256 vestingCategory,
        uint256 amount
    );

    event TokensClaimed(address account, uint256 amount, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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