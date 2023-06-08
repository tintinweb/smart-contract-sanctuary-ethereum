// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IUserRegistry {
    struct User {
        string name;
        string profileCID;
        uint256 level;
        bool registered;
        uint256 appreciationBalance;
        uint256 contributionBalance;
        uint256 appreciationsTaken;
        uint256 appreciationsGiven;
        uint256 takenAmt;
        uint256 givenAmt;
        uint256 tokenId;
        bool tokenHolder;
    }
    function updateAppreciator(address appreciator, uint256 amt) external returns (bool);
    function updateCreator(address creator, uint256) external returns (bool);
    function withdraw(address creator, uint256 fee, uint256 withdrawalThresholdInEth) external;
    function getUserDetails(address user) external view returns (User memory);
}

interface IPriceConversion {
    function UsdtoEth(uint256) external returns (uint256);
}

interface IVariables {
    function retriveBaseThreshold() external view returns (uint256);
    function retrivePerWithdrawal() external view returns (uint256);
}

contract Handler is Ownable {
    IUserRegistry userRegistry;
    IPriceConversion priceConvertor;
    IVariables variables;
    // @TODO VARIABLE 3
    // uint256 private baseThreshold = 3; // USD

    event AddedFunds(address indexed sender, uint256 amount);

    constructor() {
    }

    function setUserRegistry(address _userRegistryAddr) external onlyOwner {
        userRegistry = IUserRegistry(_userRegistryAddr);
    }
    
    function setPriceConversion(address _priceConversionAddr) external onlyOwner {
        priceConvertor = IPriceConversion(_priceConversionAddr);
    }

    function setVariables(address _variables) external onlyOwner {
        variables = IVariables(_variables);
    }    
    
    function receiveAmount(address creator, address appreciator) external payable returns (bool) {
        uint256 level = userRegistry.getUserDetails(creator).level;
        uint256 maxAppreciation = (2**level - level);
        uint256 maxAppreciationEth = priceConvertor.UsdtoEth(maxAppreciation);
        require(msg.value <= maxAppreciationEth, "max appreciation amount exceeds");        
        bool updatedCreator = userRegistry.updateCreator(creator, msg.value);    
        require(updatedCreator, "Failed to update creator");
        bool updatedAppreciator = userRegistry.updateAppreciator(appreciator, msg.value);    
        require(updatedAppreciator, "Failed to update creator");

        return true;
    }

    function withdraw(address creator) external payable returns (bool) {
        IUserRegistry.User memory user = userRegistry.getUserDetails(creator);
        uint256 level = user.level;
        uint256 appreciationBalance = user.appreciationBalance;
        uint256 withdrawalThreshold = calculateWithdrawalThreshold(level);
        uint256 withdrawalThresholdInEth = priceConvertor.UsdtoEth(withdrawalThreshold);
        require(withdrawalThresholdInEth <= appreciationBalance, "Withdrawal threshold not met");
        // @TODO Variable perWithdrawal 10
        uint256 perWithdrawal = variables.retrivePerWithdrawal();
        uint256 fee = withdrawalThresholdInEth * perWithdrawal / 100;
        userRegistry.withdraw(creator, fee, withdrawalThresholdInEth);
        uint256 amt = withdrawalThresholdInEth - fee;
        (bool success, ) = payable(creator).call{value: amt}("");
        require(success, "Withdrawal failed");
        return success;
    }

    function calculateWithdrawalThreshold(uint256 level) public view returns (uint256) {
        uint256 _threshold = variables.retriveBaseThreshold();
        // @TODO Variable perWithdrawal 10
        uint256 perWithdrawal = variables.retrivePerWithdrawal();
        for (uint256 i = 2; i <= level; i++) {
            uint256 percentageIncrease = _threshold * perWithdrawal / 100;
            _threshold += percentageIncrease;
        }

        return _threshold;
    }

    // @TODO remove these utilities add in Variables.sol
    function getBaseThreshold() public view returns (uint256) {
        return variables.retriveBaseThreshold();
    }
    
    receive() external payable {
        emit AddedFunds(msg.sender, msg.value);
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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