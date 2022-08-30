// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface capsStaking_Interface {
    function notifyReward() external payable;
}

interface capsToken_Interface {
    function mintTokens(address receiver, uint256 amount) external;

    function burnTokens(uint256 amount) external;
}

contract fixlineBetting is Ownable, ReentrancyGuard {
    event Created(address indexed by, uint indexed id, uint at);
    event Cancelled(address indexed by, uint indexed id, uint at);
    event SlotPurchased(
        address indexed by,
        uint indexed id,
        uint amount,
        uint at
    );
    event Withdraw(address indexed by, uint amount, uint at);
    event ClaimLoss(
        address indexed by,
        uint indexed id,
        uint totalBetAmount,
        uint at,
        bool isDeclaredByAdmin
    );
    event RewardSended(uint amount, uint at);

    struct Bet {
        address maker;
        uint basePrice;
        uint expiryTime;
        uint totalSlots;
        address[] slotTakers;
        bool[] isLossClaimed; // Note n+1th Index Will Tell About Whether Maker Claimed Loss.
        bytes data;
        bool isCancelled;
    }

    struct User {
        uint balance;
        uint withdrawableBalance;
        int reputation;
        uint[] createdBets;
        uint[] participatedInBets;
    }

    uint public subReputationAmount = 5;
    uint public addReputationAmount = 10;
    uint public minSlotsInBet = 1;
    uint public maxSlotsInBet = 16;
    uint public minSlotBasePrice = 1000000000000;
    uint public maxSlotBasePrice = 100000000000000000000;
    uint public winnerRewardPortion = 90;
    uint public losserRewardPortion = 5;
    uint public adminRewardPortion = 3;
    uint public capsStackingContractRewardPortion = 1;
    uint public fixlineStackingContractRewardPortion = 1; // Currently FixlineStacking Contract Not Exists And On Behalf Of This We Will Transfer Funds To Any Temp Account.
    uint public capsTokenDistributionAmount = 1000000000000000000;
    uint private totalBets;

    uint public nextRewardTime;
    uint private maxRewardsInDay = 4;
    uint private pendingRewardsToSend;

    mapping(address => User) private usersData;
    mapping(uint => Bet) private betsData;

    capsStaking_Interface private capsStakingContract_Ins;
    capsToken_Interface private capsTokenContract_Ins;

    constructor(
        address capsStakingContractAddress,
        address capsTokenContractAddress
    ) {
        capsStakingContract_Ins = capsStaking_Interface(
            capsStakingContractAddress
        );
        capsTokenContract_Ins = capsToken_Interface(capsTokenContractAddress);
        nextRewardTime = block.timestamp + (24 hours / maxRewardsInDay);
    }

    modifier isValidBetId(uint betId) {
        require(
            betsData[betId].maker != address(0),
            "Invalid Bet Id, Bet Not Exists"
        );
        _;
    }

    function createBet(
        uint slots,
        uint basePrice,
        uint expiryTime,
        bytes calldata data
    ) external payable returns (uint) {
        require(
            slots >= minSlotsInBet && slots <= maxSlotBasePrice,
            "Slots Should Be Less Or Equal To Max Bets And Greater Or Equal To Min Bets Value"
        );
        require(
            basePrice >= minSlotBasePrice && basePrice <= maxSlotBasePrice,
            "BasePrice Should Be Less Or Equal To Max BasePrice And Greater Or Equal To Min BasePrice Value"
        );
        require(
            expiryTime > block.timestamp,
            "Expiry Time Should Greater Than Current Time"
        );
        require(
            msg.value == (basePrice * slots),
            "Please Send Suffecient Amount Of Ethers"
        );
        address msgSender = msg.sender;
        totalBets++;
        uint curBetId = totalBets;
        address[] memory emptyArr;
        bool[] memory emptyBoolArr = new bool[](slots + 1);
        betsData[curBetId] = Bet(
            msgSender,
            basePrice,
            expiryTime,
            slots,
            emptyArr,
            emptyBoolArr,
            data,
            false
        );
        usersData[msgSender].balance += msg.value;
        usersData[msgSender].reputation -= int(slots * subReputationAmount);
        usersData[msgSender].createdBets.push(curBetId);
        emit Created(msgSender, curBetId, block.timestamp);

        return curBetId;
    }

    function buyBetSlots(uint[] calldata betIds) external payable {
        uint totalPasssedAmount = msg.value;
        for (uint256 i; i < betIds.length; ) {
            totalPasssedAmount = buyBetSlot(betIds[i], totalPasssedAmount);
            unchecked {
                i++;
            }
        }
    }

    function buyBetSlot(uint betId, uint remainingAmount)
        private
        isValidBetId(betId)
        returns (uint)
    {
        Bet memory tempBetData = betsData[betId];
        require(
            tempBetData.isCancelled == false,
            "You Cannot Buy Slots Because Bet Is Cancelled"
        );
        require(
            tempBetData.expiryTime > block.timestamp,
            "You Cannot Buy Slots Because Bet Is Expired"
        );
        require(
            tempBetData.slotTakers.length < tempBetData.totalSlots,
            "All Slots Of Bet Are Sold"
        );
        require(
            remainingAmount >= tempBetData.basePrice,
            "Please Pass Value More Or Equal To Slot Price"
        );
        remainingAmount -= tempBetData.basePrice;
        address msgSender = msg.sender;
        require(tempBetData.maker != msgSender, "Bet Maker Cannot Buy Slot");
        require(
            getUserSlotNum(msgSender, betId) == 0,
            "You Cannot Buy Slots Because You Has Already Purchased Slot"
        );

        betsData[betId].slotTakers.push(msgSender);
        usersData[msgSender].balance += tempBetData.basePrice;
        usersData[msgSender].reputation -= int(subReputationAmount);
        usersData[msgSender].participatedInBets.push(betId);

        emit SlotPurchased(msgSender, betId, msg.value, block.timestamp);
        return remainingAmount;
    }

    function cancelBet_Batch(uint[] calldata betIds) external {
        for (uint256 i; i < betIds.length; ) {
            cancelBet(betIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function cancelBet(uint betId) private {
        address msgSender = msg.sender;
        Bet memory tempBetData = betsData[betId];
        require(
            tempBetData.maker == msgSender,
            "Only Bet Maker Can Cancel This Bet"
        );
        require(
            tempBetData.expiryTime <= block.timestamp,
            "You Can Claim Loss After Bet Expiry Time"
        );
        require(tempBetData.isCancelled == false, "Bet Is Already Cancelled");
        uint totalUnsoldSlots = (tempBetData.totalSlots -
            tempBetData.slotTakers.length);
        usersData[msgSender].reputation += int(
            totalUnsoldSlots * subReputationAmount
        );
        uint amountToReturn = tempBetData.basePrice * totalUnsoldSlots;
        usersData[msgSender].balance -= amountToReturn;
        usersData[msgSender].withdrawableBalance += amountToReturn;
        betsData[betId].isCancelled = true;
        emit Cancelled(msgSender, betId, block.timestamp);
    }

    function sendRewardsToStackingContract(uint amountToSend) private {
        if ((block.timestamp >= nextRewardTime)) {
            uint totalRewardToSend = pendingRewardsToSend + amountToSend;
            pendingRewardsToSend = 0;
            nextRewardTime = block.timestamp + (24 hours / maxRewardsInDay);
            capsStakingContract_Ins.notifyReward{value: totalRewardToSend}();
            emit RewardSended(totalRewardToSend, block.timestamp);
        } else {
            pendingRewardsToSend += amountToSend;
        }
    }

    function makerLoss(
        uint betId,
        Bet memory tempBetData,
        bool isDeclaredByAdmin
    ) private {
        address makerAddress = tempBetData.maker;
        uint totalSlotTakers = tempBetData.slotTakers.length;
        betsData[betId].isLossClaimed[tempBetData.totalSlots] = true;
        usersData[makerAddress].reputation += int(
            addReputationAmount * totalSlotTakers
        );
        uint totalBetAmount = tempBetData.basePrice * totalSlotTakers;
        usersData[makerAddress].balance -= totalBetAmount;
        usersData[makerAddress].withdrawableBalance +=
            ((totalBetAmount * 2) * losserRewardPortion) /
            100;
        usersData[owner()].withdrawableBalance += (((totalBetAmount * 2) *
            adminRewardPortion) / 100);
        sendRewardsToStackingContract(
            ((totalBetAmount * 2) * capsStackingContractRewardPortion) / 100
        );
        /* 0x90a23757BabC1a2823D1f085A7f3f3d426E751d6 This Is Address Of Developer At Time Of Deployment Replace It To Address Of Fixline Stacking Contract Address */
        payable(0x90a23757BabC1a2823D1f085A7f3f3d426E751d6).transfer(
            ((totalBetAmount * 2) * fixlineStackingContractRewardPortion) / 100
        );
        uint rewardPerUser = ((totalBetAmount * 2) * winnerRewardPortion) /
            100 /
            totalSlotTakers;
        for (uint256 i; i < totalSlotTakers; ) {
            usersData[tempBetData.slotTakers[i]].balance -= tempBetData
                .basePrice;
            usersData[tempBetData.slotTakers[i]]
                .withdrawableBalance += rewardPerUser;
            usersData[tempBetData.slotTakers[i]].reputation += int(
                subReputationAmount
            );
            unchecked {
                i++;
            }
        }
        capsTokenContract_Ins.mintTokens(
            makerAddress,
            capsTokenDistributionAmount * totalSlotTakers
        );
        emit ClaimLoss(
            makerAddress,
            betId,
            totalBetAmount,
            block.timestamp,
            isDeclaredByAdmin
        );
    }

    function takerLoss(
        uint betId,
        address takerAddress,
        uint userBetSlotNum,
        Bet memory tempBetData,
        bool isDeclaredByAdmin
    ) private {
        betsData[betId].isLossClaimed[userBetSlotNum] = true;
        usersData[tempBetData.maker].reputation += int(subReputationAmount);
        usersData[takerAddress].reputation += int(addReputationAmount);
        usersData[takerAddress].balance -= tempBetData.basePrice;
        usersData[takerAddress].withdrawableBalance +=
            ((tempBetData.basePrice * 2) * losserRewardPortion) /
            100;
        usersData[tempBetData.maker].balance -= tempBetData.basePrice;
        usersData[tempBetData.maker].withdrawableBalance += (((tempBetData
            .basePrice * 2) * winnerRewardPortion) / 100);
        usersData[owner()].withdrawableBalance += (((tempBetData.basePrice *
            2) * adminRewardPortion) / 100);
        sendRewardsToStackingContract(
            ((tempBetData.basePrice * 2) * capsStackingContractRewardPortion) /
                100
        );
        /* 0x90a23757BabC1a2823D1f085A7f3f3d426E751d6 This Is Address Of Developer At Time Of Deployment Replace It To Address Of Fixline Stacking Contract Address */
        payable(0x90a23757BabC1a2823D1f085A7f3f3d426E751d6).transfer(
            ((tempBetData.basePrice * 2) *
                fixlineStackingContractRewardPortion) / 100
        );
        capsTokenContract_Ins.mintTokens(
            takerAddress,
            capsTokenDistributionAmount
        );
        emit ClaimLoss(
            takerAddress,
            betId,
            tempBetData.basePrice,
            block.timestamp,
            isDeclaredByAdmin
        );
    }

    function declareLosserByAdmin_Batch(
        uint[] calldata betIds,
        bool[] calldata isMakerLoss
    ) external {
        require(betIds.length == isMakerLoss.length, "Invalid Input");
        for (uint256 i; i < betIds.length; ) {
            declareLosserByAdmin(betIds[i], isMakerLoss[i]);
            unchecked {
                i++;
            }
        }
    }

    function declareLosserByAdmin(uint betId, bool isMakerLoss)
        public
        onlyOwner
        isValidBetId(betId)
    {
        Bet memory tempBetData = betsData[betId];
        require(
            tempBetData.expiryTime <= block.timestamp,
            "You Can Claim Loss After Bet Expiry Time"
        );
        require(
            tempBetData.slotTakers.length > 0,
            "Loss Cannot Be Claimed Until Bet Slot Is Purchased By Any User"
        );
        if (isMakerLoss == true) {
            require(
                tempBetData.isLossClaimed[tempBetData.totalSlots] == false,
                "Maker Has Already Claimed Loss"
            );
            makerLoss(betId, tempBetData, true);
        } else {
            for (uint256 i; i < tempBetData.slotTakers.length; ) {
                if (tempBetData.isLossClaimed[i] == false) {
                    takerLoss(
                        betId,
                        tempBetData.slotTakers[i],
                        i,
                        tempBetData,
                        true
                    );
                }
                unchecked {
                    i++;
                }
            }
        }
    }

    function claimLossByMaker(uint betId) public nonReentrant {
        address msgSender = msg.sender;
        Bet memory tempBetData = betsData[betId];
        require(
            tempBetData.maker == msgSender,
            "Only Bet Maker Can Access This Method"
        );
        require(
            tempBetData.expiryTime <= block.timestamp,
            "You Can Claim Loss After Bet Expiry Time"
        );
        require(
            tempBetData.slotTakers.length > 0,
            "You Cannot Claim Loss Until Bet Slot Is Purchased By Any User"
        );
        require(
            tempBetData.isLossClaimed[tempBetData.totalSlots] == false,
            "Maker Has Already Claimed Loss"
        );
        makerLoss(betId, tempBetData, false);
    }

    function claimLossByTaker(uint betId) public nonReentrant {
        address msgSender = msg.sender;
        Bet memory tempBetData = betsData[betId];
        require(
            tempBetData.expiryTime <= block.timestamp,
            "You Can Claim Loss After Bet Expiry Time"
        );
        uint userBetSlotNum = getUserSlotNum(msgSender, betId);
        require(
            userBetSlotNum != 0,
            "You Cannot Calim Loss Because You Has Not Buy Slot"
        );
        userBetSlotNum -= 1;
        require(
            tempBetData.isLossClaimed[userBetSlotNum] == false,
            "You Has Already Calimed Loss"
        );
        takerLoss(betId, msgSender, userBetSlotNum, tempBetData, false);
    }

    function claimLoss_Batch(uint[] calldata betIds) external {
        address msgSender = msg.sender;
        for (uint256 i; i < betIds.length; ) {
            if (betsData[betIds[i]].maker == msgSender) {
                claimLossByMaker(betIds[i]);
            } else {
                claimLossByTaker(betIds[i]);
            }
            unchecked {
                i++;
            }
        }
    }

    function withdrawBalance(uint amount) external {
        address msgSender = msg.sender;
        require(
            amount <= usersData[msgSender].withdrawableBalance,
            "Insufficient Withdrawable Balance"
        );
        usersData[msgSender].withdrawableBalance -= amount;
        payable(msgSender).transfer(amount);
        emit Withdraw(msgSender, amount, block.timestamp);
    }

    /********** Setter Functions **********/

    function setSubReputationAmount(uint newAmountValue) external onlyOwner {
        subReputationAmount = newAmountValue;
    }

    function setAddReputationAmount(uint newAmountValue) external onlyOwner {
        addReputationAmount = newAmountValue;
    }

    function setMinSlotsInBet(uint newMinSlotsValue) external onlyOwner {
        minSlotsInBet = newMinSlotsValue;
    }

    function setMaxSlotsInBet(uint newMaxSlotsValue) external onlyOwner {
        maxSlotsInBet = newMaxSlotsValue;
    }

    function setMinSlotBasePrice(uint _minSlotBasePrice) external onlyOwner {
        minSlotBasePrice = _minSlotBasePrice;
    }

    function setMaxSlotBasePrice(uint _maxSlotBasePrice) external onlyOwner {
        maxSlotBasePrice = _maxSlotBasePrice;
    }

    function setWinnerRewardPortion(uint _winnerRewardPortion)
        external
        onlyOwner
    {
        winnerRewardPortion = _winnerRewardPortion;
    }

    function setLosserRewardPortion(uint _losserRewardPortion)
        external
        onlyOwner
    {
        losserRewardPortion = _losserRewardPortion;
    }

    function setAdminRewardPortion(uint _adminRewardPortion)
        external
        onlyOwner
    {
        adminRewardPortion = _adminRewardPortion;
    }

    function setCapsStackingContractRewardPortion(
        uint _capsStackingContractRewardPortion
    ) external onlyOwner {
        capsStackingContractRewardPortion = _capsStackingContractRewardPortion;
    }

    function setFixlineStackingContractRewardPortion(
        uint _fixlineStackingContractRewardPortion
    ) external onlyOwner {
        fixlineStackingContractRewardPortion = _fixlineStackingContractRewardPortion;
    }

    function setCapsTokenDistributionAmount(uint _capsTokenDistributionAmount)
        external
        onlyOwner
    {
        capsTokenDistributionAmount = _capsTokenDistributionAmount;
    }

    // Note:- Owner Avoid To Set Large Amount Of Rewards In A Day, We Suggests You To Set Value Of Param "newMaxRewardsInDay" Less Than 10;
    function setMaxRewardsInDay(uint newMaxRewardsInDay) external onlyOwner {
        maxRewardsInDay = newMaxRewardsInDay;
    }

    function setCapsTokenContract_Ins(address newAddress) external onlyOwner {
        capsTokenContract_Ins = capsToken_Interface(newAddress);
    }

    function setCapsStackingContract_Ins(address newAddress)
        external
        onlyOwner
    {
        capsStakingContract_Ins = capsStaking_Interface(newAddress);
    }

    /********** View Functions **********/

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getTotalBets() external view returns (uint) {
        return totalBets;
    }

    function getCapsTokenAddress() external view returns (address) {
        return address(capsTokenContract_Ins);
    }

    function getCapsStackingAddress() external view returns (address) {
        return address(capsStakingContract_Ins);
    }

    function getUserSlotNum(address userAddress, uint betId)
        public
        view
        returns (uint)
    {
        address[] memory _slotTakers = betsData[betId].slotTakers;
        uint totalSlotTakers = _slotTakers.length;

        for (uint256 i; i < totalSlotTakers; ) {
            if (_slotTakers[i] == userAddress) {
                return i + 1;
            }
            unchecked {
                i++;
            }
        }
        return 0;
    }

    function getUserData(address userAddress)
        external
        view
        returns (
            uint,
            uint,
            int,
            uint[] memory,
            uint[] memory
        )
    {
        return (
            usersData[userAddress].balance,
            usersData[userAddress].withdrawableBalance,
            usersData[userAddress].reputation,
            usersData[userAddress].createdBets,
            usersData[userAddress].participatedInBets
        );
    }

    function getBetData(uint betId)
        external
        view
        returns (
            address,
            uint,
            uint,
            uint,
            address[] memory,
            bool[] memory,
            bool
        )
    {
        return (
            betsData[betId].maker,
            betsData[betId].basePrice,
            betsData[betId].expiryTime,
            betsData[betId].totalSlots,
            betsData[betId].slotTakers,
            betsData[betId].isLossClaimed,
            betsData[betId].isCancelled
        );
    }

    function getBetAPIData(uint betId) external view returns (bytes memory) {
        return betsData[betId].data;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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