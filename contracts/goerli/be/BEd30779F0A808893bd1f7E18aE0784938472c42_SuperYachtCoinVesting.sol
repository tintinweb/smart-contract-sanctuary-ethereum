// SPDX-License-Identifier: MIT
//
//
// UI:
//
// - function "createVesting" ===================================> [address] Create Vesting. Can be called only one by contract deployer
// - function "claim" ===========================================> [uint] Provide vesting index from 0 to 7. Can be called only owner of exact vesting.
// - struct "vesting" ===========================================> [index] Provide vesting index from 0 to 7. Show full information about exact vesting.
//
//
// DEPLOYMENT:
//
// - Depoloy contract with no arguments
// - Use function createVesting for create vesting and begin vesting timer and provide those addresses:
//      address team, teamPrivateSale, advisors, marketing, NFTHolders, liquidity, treasury, stakingReward
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function mint(address _to, uint _amount) external;
}

contract SuperYachtCoinVesting is Ownable {

  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- VESTING PARAMETERS
  // -------------------------------------------------------------------------------------------------------

    uint constant ONE_MONTH = 30 days;

    bool public vestingIsCreated;

    mapping(uint => Vesting) public vesting;

    IERC20 public token;

    // @notice                              provide full information of exact vesting
    struct Vesting {
        address owner;                      //The only owner can call vesting claim function
        uint claimCounter;                  //Currect claim number
        uint totalClaimNum;                 //Maximum amount of claims for this vesting
        uint nextUnlockDate;                //Next date of tokens unlock
        uint tokensRemaining;               //Remain amount of token
        uint tokenToUnclockPerMonth;        //Amount of token can be uncloked each month
    }

    constructor(IERC20 _token) {
        token = _token;
    }

    // @notice                             only contract deployer can call this method and only once
    function createVesting(
        address _teamWallet,
        address _teamPrivateSaleWallet,
        address _advisorsWallet,
        address _marketingWallet,
        address _NFTHoldersWallet,
        address _liquidityWallet,
        address _treasuryWallet,
        address _stakingRewardWallet
        ) public onlyOwner
        {
        require(!vestingIsCreated, "vesting is already created");
        vestingIsCreated = true;
        vesting[0] = Vesting(_teamWallet, 0, 12, block.timestamp + 360 days, 96_000_000 ether, 4_000_000 ether);
        vesting[1] = Vesting(_teamPrivateSaleWallet, 0, 6, block.timestamp + 180 days, 28_000_000 ether, 4_666_667 ether);
        vesting[2] = Vesting(_advisorsWallet, 0, 12, block.timestamp + 360 days, 24_000_000 ether, 2_000_000 ether);
        vesting[3] = Vesting(_marketingWallet, 0, 48, block.timestamp + ONE_MONTH, 112_000_000 ether, 2_333_333 ether);
        vesting[4] = Vesting(_NFTHoldersWallet, 0, 6, block.timestamp + ONE_MONTH, 44_000_000 ether, 7_333_333 ether);
        vesting[5] = Vesting(_liquidityWallet, 0, 12, block.timestamp + ONE_MONTH, 135_000_000 ether, 11_250_000 ether);
        vesting[6] = Vesting(_treasuryWallet, 0, 48, block.timestamp + ONE_MONTH, 193_800_000 ether, 4_037_500 ether);
        vesting[7] = Vesting(_stakingRewardWallet, 0, 48, block.timestamp + ONE_MONTH, 300_000_000 ether, 6_250_000 ether);
        token.mint(_teamPrivateSaleWallet, 7_000_000 ether);
        token.mint(_NFTHoldersWallet, 11_000_000 ether);
        token.mint(_liquidityWallet, 15_000_000 ether);
        token.mint(_treasuryWallet, 34_200_000 ether);
    }

    modifier checkLock(uint _index) {
        require(vesting[_index].owner == msg.sender, "Not an owner of this vesting");
        require(block.timestamp > vesting[_index].nextUnlockDate, "Tokens are still locked");
        require(vesting[_index].tokensRemaining > 0, "Nothing to claim");
        _;
    }

    // @notice                             please use _index from table below
    //
    // 0 - Team
    // 1 - Team Private Sale
    // 2 - Advisors
    // 3 - Marketing
    // 4 - NFT Holders
    // 5 - Liquidity
    // 6 - Treasury
    // 7 - Staking Reward
    //
    function claim(uint256 _index) public checkLock(_index) {
        if(vesting[_index].claimCounter + 1 < vesting[_index].totalClaimNum) {
            uint toMint = vesting[_index].tokenToUnclockPerMonth;
            token.mint(msg.sender, toMint);
            vesting[_index].tokensRemaining -= toMint;
            vesting[_index].nextUnlockDate += ONE_MONTH;
            vesting[_index].claimCounter++;
        } else {
            token.mint(msg.sender, vesting[_index].tokensRemaining);
            vesting[_index].tokensRemaining = 0;
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