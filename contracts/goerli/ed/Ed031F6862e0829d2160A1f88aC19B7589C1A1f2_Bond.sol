// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Bond_RefundFailed();
error Bond_CommissionFailed();
error Bond_ExchangeCoinsToEtherError();
error Bond_HasNoCoins();
error Bond_MonthNotPassed();
error Bond_NotEnoughETHEntered();
error Bond_NotFound();
error Bond_NotOwner();

contract Bond is ReentrancyGuard {
    address payable public immutable iOwner;
    mapping(address => uint256) public sLastUserReward;
    mapping(address => uint256) public sUsersBonds;
    mapping(address => uint256) public sUsersCoins;
    uint256 public immutable iBondsToCoinsExchangeRate;
    uint256 public immutable iParticipationAmount;
    uint256 public immutable iRewardInterval;
    uint256 public immutable iRewardTimeUnit;
    uint256 public sBondCounter;
    uint256 public sCoinsCounter;

    event BuyBond(address indexed participant, uint256 eth);
    event ChangeBondToCoins(
        address indexed participant,
        uint256 userCoins,
        uint256 userBonds
    );
    event ChangeCoinsToEth(
        address indexed participant,
        uint256 userCoins,
        uint256 eth
    );
    event RequestReward(address indexed participant, uint256 userCoins);

    constructor(
        uint256 participationAmount,
        uint256 rewardInterval,
        uint256 rewardTimeUnit,
        uint256 bondsToCoinsExchangeRate
    ) {
        iOwner = payable(msg.sender);
        iParticipationAmount = participationAmount;
        iRewardInterval = rewardInterval;
        iRewardTimeUnit = rewardTimeUnit;
        iBondsToCoinsExchangeRate = bondsToCoinsExchangeRate;
    }

    function buyBond() public payable nonReentrant {
        if (msg.value < iParticipationAmount) {
            revert Bond_NotEnoughETHEntered();
        }
        uint userBonds = sUsersBonds[msg.sender];

        if (userBonds > 0) {
            mintUserCoinsFromRequest();
        }

        sUsersBonds[msg.sender] += 1;
        sLastUserReward[msg.sender] = block.timestamp;
        sBondCounter++;

        emit BuyBond(msg.sender, iParticipationAmount);

        if (msg.value > iParticipationAmount) {
            (bool success, ) = msg.sender.call{
                value: msg.value - iParticipationAmount
            }("");
            if (!success) {
                revert Bond_RefundFailed();
            }
        }

        (bool successCommission, ) = iOwner.call{
            value: ((iParticipationAmount * 6) / 100)
        }("");

        if (!successCommission) {
            revert Bond_CommissionFailed();
        }
    }

    function requestReward() external {
        uint256 userBonds = sUsersBonds[msg.sender];
        if (userBonds < 1) {
            revert Bond_NotFound();
        }

        if (
            block.timestamp <
            (sLastUserReward[msg.sender] + (iRewardTimeUnit * iRewardInterval))
        ) {
            revert Bond_MonthNotPassed();
        }

        uint256 rewardUserCoins = mintUserCoinsFromRequest();

        sLastUserReward[msg.sender] = block.timestamp;
        emit RequestReward(msg.sender, rewardUserCoins);
    }

    function getNotRequestedCoins() public view returns (uint256) {
        uint256 userBonds = sUsersBonds[msg.sender];

        return
            (userBonds * (block.timestamp - sLastUserReward[msg.sender])) /
            iRewardTimeUnit;
    }

    function changeCoinsToEth() external nonReentrant {
        uint256 userCoins = sUsersCoins[msg.sender];
        sUsersCoins[msg.sender] = 0;
        if (userCoins < 1) {
            revert Bond_HasNoCoins();
        }

        uint256 exchangerate = exchangeCoinsToEthRate();
        uint256 eth = exchangerate * userCoins;
        sCoinsCounter -= userCoins;
        emit ChangeCoinsToEth(msg.sender, userCoins, eth);
        (bool success, ) = msg.sender.call{value: eth}("");

        if (!success) {
            revert Bond_ExchangeCoinsToEtherError();
        }
    }

    function changeBondsToCoins() external {
        uint256 userBonds = sUsersBonds[msg.sender];
        if (userBonds < 1) {
            revert Bond_NotFound();
        }
        uint256 coins = userBonds * iBondsToCoinsExchangeRate;
        sUsersCoins[msg.sender] += coins;
        sUsersBonds[msg.sender] = 0;
        sBondCounter -= userBonds;
        sCoinsCounter += coins;
        emit ChangeBondToCoins(msg.sender, coins, userBonds);
    }

    function getExchangeCoinsToEthRate(
        uint256 contractBalance,
        uint256 bondCounter,
        uint256 coinsCounter,
        uint256 bondsToCoinsExchangeRate
    ) public pure returns (uint256) {
        uint256 coins = (bondCounter * bondsToCoinsExchangeRate) + coinsCounter;

        if (coins < 1) {
            return 0;
        }

        return contractBalance / coins;
    }

    function exchangeCoinsToEthRate() public view returns (uint256) {
        return
            getExchangeCoinsToEthRate(
                address(this).balance,
                sBondCounter,
                sCoinsCounter,
                iBondsToCoinsExchangeRate
            );
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function mintUserCoinsFromRequest() public returns (uint256) {
        uint256 userCoins = getNotRequestedCoins();
        sUsersCoins[msg.sender] += userCoins;
        sCoinsCounter += userCoins;
        return userCoins;
    }
}