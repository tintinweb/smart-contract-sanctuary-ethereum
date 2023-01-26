/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for calculating lending discounts

There are four mechanisms to receive loan origination and premium discounts:

    1. Holding the Borrowing Maxi NFT
    2. Holding (and having consumed) the Borrowing Incentive NFT
    3. Borrowing a greater amount
    4. Borrowing for a shorter time

All discounts are additive.

The NFTs provide a fixed percentage discount. The Borrowing Incentive NFT is consumed upon loan origination.

The latter two discounts provide a linear sliding scale, based on the minimum and maximum loan amounts and loan periods.
The starting values for these discounts are 0-10% discount.

The time based discount is imposing an opportunity cost of lent funds - and incentivizing taking out the shortest loan possible.
The amount based discount is recognizing that a loan origination now is more valuable than a possible loan origination later.

These sliding scales can be modified to ensure they have optimal market fit.

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setAuthorizedConsumer(address consumer, bool isAuthorized) external onlyOwner {
        require(authorizedConsumers[consumer] != isAuthorized);
        authorizedConsumers[consumer] = isAuthorized;
        emit AuthorizedConsumerSet(consumer, isAuthorized);
    }

    function setTimeBasedDiscount(uint256 min, uint256 max) external onlyOwner {
        require(min != timeBasedFeeDiscountMin || max != timeBasedFeeDiscountMax);
        uint256 oldMin = timeBasedFeeDiscountMin;
        uint256 oldMax = timeBasedFeeDiscountMax;
        timeBasedFeeDiscountMin = min;
        timeBasedFeeDiscountMax = max;
        emit TimeBasedDiscountSet(oldMin, oldMax, min, max);
    }

    function setAmountBasedDiscount(uint256 min, uint256 max) external onlyOwner {
        require(min != amountBasedFeeDiscountMin || max != amountBasedFeeDiscountMax);
        uint256 oldMin = amountBasedFeeDiscountMin;
        uint256 oldMax = amountBasedFeeDiscountMax;
        amountBasedFeeDiscountMin = min;
        amountBasedFeeDiscountMax = max;
        emit AmountBasedDiscountSet(oldMin, oldMax, min, max);
    }

    function setDiscountNFT(address discountNFTAddress) external onlyOwner {
        require(discountNFTAddress != address(discountNFT));
        address oldDiscountNFTAddress = address(discountNFT);
        discountNFT = IDiscountNFT(discountNFTAddress);
        emit DiscountNFTSet(oldDiscountNFTAddress, discountNFTAddress);
    }

    function setConsumableDiscountNFT(address consumableDiscountNFTAddress) external onlyOwner {
        require(consumableDiscountNFTAddress != address(consumableDiscountNFT));
        address oldConsumableDiscountNFTAddress = address(consumableDiscountNFT);
        consumableDiscountNFT = IConsumableDiscountNFT(consumableDiscountNFTAddress);
        emit ConsumableDiscountNFTSet(oldConsumableDiscountNFTAddress, consumableDiscountNFTAddress);
    }

    function setDiscountNFTDiscounts(uint256 premiumFeeDiscount, uint256 originationFeeDiscount) external onlyOwner {
        require(premiumFeeDiscount != discountNFTPremiumFeeDiscount || originationFeeDiscount != discountNFTOriginationFeeDiscount);
        require(premiumFeeDiscount <= 10000);
        require(originationFeeDiscount <= 10000);
        uint256 oldPremiumFeeDiscount = discountNFTPremiumFeeDiscount;
        uint256 oldOriginationFeeDiscount = discountNFTOriginationFeeDiscount;
        discountNFTPremiumFeeDiscount = premiumFeeDiscount;
        discountNFTOriginationFeeDiscount = originationFeeDiscount;

        emit DiscountNFTDiscountsSet(oldOriginationFeeDiscount, oldPremiumFeeDiscount, originationFeeDiscount, premiumFeeDiscount);
    }

    function setConsumableDiscountNFTDiscounts(uint256 premiumFeeDiscount, uint256 originationFeeDiscount) external onlyOwner {
        require(premiumFeeDiscount != consumableDiscountNFTPremiumFeeDiscount || originationFeeDiscount != consumableDiscountNFTOriginationFeeDiscount);
        require(premiumFeeDiscount <= 10000);
        require(originationFeeDiscount <= 10000);
        uint256 oldPremiumFeeDiscount = consumableDiscountNFTPremiumFeeDiscount;
        uint256 oldOriginationFeeDiscount = consumableDiscountNFTOriginationFeeDiscount;
        consumableDiscountNFTPremiumFeeDiscount = premiumFeeDiscount;
        consumableDiscountNFTOriginationFeeDiscount = originationFeeDiscount;

        emit ConsumableDiscountNFTDiscountsSet(oldOriginationFeeDiscount, oldPremiumFeeDiscount, originationFeeDiscount, premiumFeeDiscount);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IX7LendingDiscountAuthority {
    function getFeeModifiers(
        address borrower,
        uint256[3] memory loanAmountDetails,
        uint256[3] memory loanDurationDetails
    ) external view returns (uint256, uint256);

    function useFeeModifiers(
        address borrower,
        uint256[3] memory loanAmountDetails,
        uint256[3] memory loanDurationDetails
    ) external returns (uint256, uint256);
}

interface IDiscountNFT {
    function balanceOf(address) external view returns (uint256);
}

interface IConsumableDiscountNFT {
    function balanceOf(address) external view returns (uint256);
    function consumeOne(address) external;
    function consumeMany(address, uint256) external;
}

contract X7LendingDiscountAuthorityV1 is Ownable, IX7LendingDiscountAuthority {

    IDiscountNFT public discountNFT;
    IConsumableDiscountNFT public consumableDiscountNFT;

    // Only addresses in this mapping may call useFeeModifiers
    mapping(address => bool) public authorizedConsumers;

    // Discounts as a fraction of 10,000
    uint256 public discountNFTOriginationFeeDiscount;
    uint256 public discountNFTPremiumFeeDiscount;

    // Discounts as a fraction of 10,000
    uint256 public consumableDiscountNFTOriginationFeeDiscount;
    uint256 public consumableDiscountNFTPremiumFeeDiscount;

    // Time based discount scale as a fraction of 10,000
    uint256 public timeBasedFeeDiscountMin;
    uint256 public timeBasedFeeDiscountMax;

    // Amount based discount scale as a fraction of 10,000
    uint256 public amountBasedFeeDiscountMin;
    uint256 public amountBasedFeeDiscountMax;

    event AuthorizedConsumerSet(address indexed consumer, bool isAuthorized);
    event TimeBasedDiscountSet(uint256 oldMin, uint256 oldMax, uint256 min, uint256 max);
    event AmountBasedDiscountSet(uint256 oldMin, uint256 oldMax, uint256 min, uint256 max);
    event DiscountNFTSet(address indexed oldAddress, address indexed newAddress);
    event ConsumableDiscountNFTSet(address indexed oldAddress, address indexed newAddress);
    event DiscountNFTDiscountsSet(uint256 oldOriginationFeeDiscount, uint256 oldPremiumFeeDiscount, uint256 originationFeeDiscount, uint256 premiumFeeDiscount);
    event ConsumableDiscountNFTDiscountsSet(uint256 oldOriginationFeeDiscount, uint256 oldPremiumFeeDiscount, uint256 originationFeeDiscount, uint256 premiumFeeDiscount);

    constructor(address discountNFT_, address consumableDiscountNFT_) Ownable(msg.sender) {
        discountNFT = IDiscountNFT(discountNFT_);
        consumableDiscountNFT = IConsumableDiscountNFT(consumableDiscountNFT_);
        emit DiscountNFTSet(address(0), discountNFT_);
        emit ConsumableDiscountNFTSet(address(0), consumableDiscountNFT_);
    }

    modifier onlyAuthorizedConsumers {
        require(authorizedConsumers[msg.sender]);
        _;
    }

    function setAuthorizedConsumer(address consumer, bool isAuthorized) external onlyOwner {
        require(authorizedConsumers[consumer] != isAuthorized);
        authorizedConsumers[consumer] = isAuthorized;
        emit AuthorizedConsumerSet(consumer, isAuthorized);
    }

    function setTimeBasedDiscount(uint256 min, uint256 max) external onlyOwner {
        require(min != timeBasedFeeDiscountMin || max != timeBasedFeeDiscountMax);
        uint256 oldMin = timeBasedFeeDiscountMin;
        uint256 oldMax = timeBasedFeeDiscountMax;
        timeBasedFeeDiscountMin = min;
        timeBasedFeeDiscountMax = max;
        emit TimeBasedDiscountSet(oldMin, oldMax, min, max);
    }

    function setAmountBasedDiscount(uint256 min, uint256 max) external onlyOwner {
        require(min != amountBasedFeeDiscountMin || max != amountBasedFeeDiscountMax);
        uint256 oldMin = amountBasedFeeDiscountMin;
        uint256 oldMax = amountBasedFeeDiscountMax;
        amountBasedFeeDiscountMin = min;
        amountBasedFeeDiscountMax = max;
        emit AmountBasedDiscountSet(oldMin, oldMax, min, max);
    }

    function setDiscountNFT(address discountNFTAddress) external onlyOwner {
        require(discountNFTAddress != address(discountNFT));
        address oldDiscountNFTAddress = address(discountNFT);
        discountNFT = IDiscountNFT(discountNFTAddress);
        emit DiscountNFTSet(oldDiscountNFTAddress, discountNFTAddress);
    }

    function setConsumableDiscountNFT(address consumableDiscountNFTAddress) external onlyOwner {
        require(consumableDiscountNFTAddress != address(consumableDiscountNFT));
        address oldConsumableDiscountNFTAddress = address(consumableDiscountNFT);
        consumableDiscountNFT = IConsumableDiscountNFT(consumableDiscountNFTAddress);
        emit ConsumableDiscountNFTSet(oldConsumableDiscountNFTAddress, consumableDiscountNFTAddress);
    }

    function setDiscountNFTDiscounts(uint256 premiumFeeDiscount, uint256 originationFeeDiscount) external onlyOwner {
        require(premiumFeeDiscount != discountNFTPremiumFeeDiscount || originationFeeDiscount != discountNFTOriginationFeeDiscount);
        require(premiumFeeDiscount <= 10000);
        require(originationFeeDiscount <= 10000);
        uint256 oldPremiumFeeDiscount = discountNFTPremiumFeeDiscount;
        uint256 oldOriginationFeeDiscount = discountNFTOriginationFeeDiscount;
        discountNFTPremiumFeeDiscount = premiumFeeDiscount;
        discountNFTOriginationFeeDiscount = originationFeeDiscount;

        emit DiscountNFTDiscountsSet(oldOriginationFeeDiscount, oldPremiumFeeDiscount, originationFeeDiscount, premiumFeeDiscount);
    }

    function setConsumableDiscountNFTDiscounts(uint256 premiumFeeDiscount, uint256 originationFeeDiscount) external onlyOwner {
        require(premiumFeeDiscount != consumableDiscountNFTPremiumFeeDiscount || originationFeeDiscount != consumableDiscountNFTOriginationFeeDiscount);
        require(premiumFeeDiscount <= 10000);
        require(originationFeeDiscount <= 10000);
        uint256 oldPremiumFeeDiscount = consumableDiscountNFTPremiumFeeDiscount;
        uint256 oldOriginationFeeDiscount = consumableDiscountNFTOriginationFeeDiscount;
        consumableDiscountNFTPremiumFeeDiscount = premiumFeeDiscount;
        consumableDiscountNFTOriginationFeeDiscount = originationFeeDiscount;

        emit ConsumableDiscountNFTDiscountsSet(oldOriginationFeeDiscount, oldPremiumFeeDiscount, originationFeeDiscount, premiumFeeDiscount);
    }

    function getFeeModifiers(
        address borrower,
        uint256[3] memory loanAmountDetails,
        uint256[3] memory loanDurationDetails
    ) external view returns (uint256, uint256) {
        (uint256 premiumFeeModifier, uint256 originationFeeModifier,) = _getFeeModifiers(
            borrower,
            loanAmountDetails,
            loanDurationDetails
        );

        return (premiumFeeModifier, originationFeeModifier);
    }

    function useFeeModifiers(
        address borrower,
        uint256[3] memory loanAmountDetails,
        uint256[3] memory loanDurationDetails
    ) external onlyAuthorizedConsumers returns (uint256, uint256) {
        (uint256 premiumFeeModifier, uint256 originationFeeModifier, bool usedConsumable) = _getFeeModifiers(
            borrower,
            loanAmountDetails,
            loanDurationDetails
        );

        if (usedConsumable) {
            consumableDiscountNFT.consumeOne(borrower);
        }

        return (premiumFeeModifier, originationFeeModifier);
    }

    function _getFeeModifiers(
        address borrower,
        uint256[3] memory loanAmountDetails,
        uint256[3] memory loanDurationDetails
    ) internal view returns (uint256 premiumFeeModifier, uint256 originationFeeModifier, bool usedConsumable) {
        uint256 premiumDiscount;
        uint256 originationDiscount;

        if (discountNFT.balanceOf(borrower) > 0) {
            premiumDiscount = discountNFTPremiumFeeDiscount;
            originationDiscount = discountNFTOriginationFeeDiscount;
        }

        if (consumableDiscountNFT.balanceOf(borrower) > 0) {
            premiumDiscount += consumableDiscountNFTPremiumFeeDiscount;
            originationDiscount += consumableDiscountNFTOriginationFeeDiscount;
            usedConsumable = true;
        } else {
            usedConsumable = false;
        }

        uint256 amountBasedDiscount = amountBasedFeeDiscountMin + (
            (amountBasedFeeDiscountMax - amountBasedFeeDiscountMin)
            * (loanAmountDetails[1] - loanAmountDetails[0])
            / (loanAmountDetails[2] - loanAmountDetails[0])
        );

        uint256 timeBasedDiscount = timeBasedFeeDiscountMax - (
            (timeBasedFeeDiscountMax - timeBasedFeeDiscountMin)
            * (loanDurationDetails[1] - loanDurationDetails[0])
            / (loanDurationDetails[2] - loanDurationDetails[0])
        );

        premiumDiscount += (amountBasedDiscount + timeBasedDiscount);
        originationDiscount += (amountBasedDiscount + timeBasedDiscount);

        if (premiumDiscount > 10000) {
            premiumFeeModifier = 0;
        } else {
            premiumFeeModifier = 10000 - premiumDiscount;
        }

        if (originationDiscount > 10000) {
            originationFeeModifier = 0;
        } else {
            originationFeeModifier = 10000 - originationDiscount;
        }
    }
}