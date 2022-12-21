// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ISilicaV2_1} from "./interfaces/silica/ISilicaV2_1.sol";
import {SilicaV2_1Storage} from "./storage/SilicaV2_1Storage.sol";
import {SilicaV2_1Types} from "./libraries/SilicaV2_1Types.sol";

import "./libraries/math/PayoutMath.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract AbstractSilicaV2_1 is ERC20, Initializable, ISilicaV2_1, SilicaV2_1Storage {
    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of days between deploymentDay and firstDueDay
    uint8 internal constant DAYS_BETWEEN_DD_AND_FDD = 2;

    /*///////////////////////////////////////////////////////////////
                                 Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyBuyers() {
        require(balanceOf(msg.sender) != 0, "Not Buyer");
        _;
    }

    modifier onlyOpen() {
        require(isOpen(), "Not Open");
        _;
    }

    modifier onlyExpired() {
        require(isExpired(), "Not Expired");
        _;
    }

    modifier onlyDefaulted() {
        if (defaultDay == 0) {
            tryDefaultContract();
        }
        _;
    }

    modifier onlyFinished() {
        if (finishDay == 0) {
            tryFinishContract();
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyOnePayout() {
        require(!didSellerCollectPayout, "Payout already collected");
        didSellerCollectPayout = true;
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                 Initializer
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize a new SilicaV2_1
    function initialize(InitializeData calldata initializeData) external override initializer {
        _initializeAddresses(
            initializeData.rewardTokenAddress,
            initializeData.paymentTokenAddress,
            initializeData.oracleRegistry,
            initializeData.sellerAddress
        );
        _initializeSilicaState(initializeData.dayOfDeployment, initializeData.lastDueDay);

        resourceAmount = initializeData.resourceAmount;

        reservedPrice = calculateReservedPrice(
            initializeData.unitPrice,
            initializeData.lastDueDay - initializeData.dayOfDeployment - 1,
            decimals(),
            initializeData.resourceAmount
        );
        require(reservedPrice > 0, "reservedPrice = 0");

        initialCollateral = initializeData.collateralAmount;
    }

    /// @notice Set the reward token address, payment token address, oracle Registery address and
    ///         seller address in this Silica
    /// @notice Owner of this silica is the seller
    function _initializeAddresses(
        address rewardTokenAddress,
        address paymentTokenAddress,
        address oracleRegistryAddress,
        address sellerAddress
    ) internal {
        require(
            rewardTokenAddress != address(0) &&
                paymentTokenAddress != address(0) &&
                oracleRegistryAddress != address(0) &&
                sellerAddress != address(0),
            "Invalid Address"
        );

        rewardToken = rewardTokenAddress;
        paymentToken = paymentTokenAddress;
        oracleRegistry = oracleRegistryAddress;
        owner = sellerAddress;
    }

    /// @notice Set last due day and first due day of the Silica contract when contract starts
    /// @dev last due day should always be after first due day
    function _initializeSilicaState(uint256 dayOfDeployment, uint256 _lastDueDay) internal {
        require(_lastDueDay >= dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD, "Invalid lastDueDay");

        lastDueDay = uint32(_lastDueDay);
        firstDueDay = uint32(dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD);
    }

    /// @notice Calculate the Reserved Price of the silica
    function calculateReservedPrice(
        uint256 unitPrice,
        uint256 numDeposits,
        uint256 _decimals,
        uint256 _resourceAmount
    ) internal pure returns (uint256) {
        return (unitPrice * _resourceAmount * numDeposits) / (10**_decimals);
    }

    /*///////////////////////////////////////////////////////////////
                                 Contract states
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the status of the contract
    function getStatus() public view override returns (SilicaV2_1Types.Status) {
        if (isOpen()) {
            return SilicaV2_1Types.Status.Open;
        } else if (isExpired()) {
            return SilicaV2_1Types.Status.Expired;
        } else if (isRunning()) {
            return SilicaV2_1Types.Status.Running;
        } else if (finishDay > 0 || isFinished()) {
            return SilicaV2_1Types.Status.Finished;
        } else if (defaultDay > 0 || isDefaulted()) {
            return SilicaV2_1Types.Status.Defaulted;
        }
    }

    /// @notice Check if contract is in open state
    function isOpen() public view override returns (bool) {
        return (getLastIndexedDay() == firstDueDay - DAYS_BETWEEN_DD_AND_FDD);
    }

    /// @notice Check if contract is in expired state
    function isExpired() public view override returns (bool) {
        return (defaultDay == 0 && finishDay == 0 && totalSupply() == 0 && getLastIndexedDay() >= firstDueDay - 1);
    }

    /// @notice Check if contract is in defaulted state
    function isDefaulted() public view override returns (bool) {
        return (getDayOfDefault() > 0);
    }

    /// @notice Returns the day of default. If X is returned, then the contract has paid X - firstDueDay payments.
    function getDayOfDefault() public view override returns (uint256) {
        if (defaultDay > 0) return defaultDay;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        if (numDaysRequired == 0) return 0;

        (uint256 numDays, ) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        // The rewardBalance is insufficient to cover numDaysRequired, hence defaulted
        if (numDays < numDaysRequired) {
            return firstDueDayMem + numDays;
        } else {
            return 0;
        }
    }

    /// @notice Function to set a contract as default
    ///         If the contract is not defaulted, revert
    function tryDefaultContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        require(numDaysRequired > 0, "Not Defaulted");

        (uint256 numDays, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        // The rewardBalance is insufficient to cover numDaysRequired, hence defaulted
        if (numDays < numDaysRequired) {
            uint256 dayOfDefaultMem = firstDueDayMem + numDays;
            defaultContract(dayOfDefaultMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Defaulted");
        }
    }

    /// @notice Snapshots variables necessary to perform default settlements.
    /// @dev This tx should only happen once in the Silica's lifetime.
    function defaultContract(
        uint256 _dayOfDefault,
        uint256 silicaRewardBalance,
        uint256 _totalRewardDelivered
    ) internal {
        if (silicaRewardBalance > _totalRewardDelivered) {
            rewardExcess = silicaRewardBalance - _totalRewardDelivered;
        }
        defaultDay = uint32(_dayOfDefault);
        rewardDelivered = _totalRewardDelivered;
        resourceAmount = totalSupply();
        totalUpfrontPayment = IERC20(paymentToken).balanceOf(address(this));

        emit StatusChanged(SilicaV2_1Types.Status.Defaulted);
    }

    /// @notice Check if the contract is in running state
    function isRunning() public view override returns (bool) {
        if (!isOpen() && !isExpired() && defaultDay == 0 && finishDay == 0) {
            uint256 firstDueDayMem = firstDueDay;
            uint256 lastDueDayMem = lastDueDay;
            uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

            if (lastDayContractOwesReward < firstDueDayMem) return true;

            (uint256 numDays, ) = getDaysAndRewardFulfilled(
                IERC20(rewardToken).balanceOf(address(this)),
                firstDueDayMem,
                lastDayContractOwesReward
            );

            uint256 contractDurationDays = lastDayContractOwesReward + 1 - firstDueDayMem;
            uint256 maxContractDurationDays = lastDueDayMem + 1 - firstDueDayMem;

            // For contracts that progressed GE firstDueDay
            // Contract is running if it's progressed as far as it can, but not finished
            return numDays == contractDurationDays && numDays != maxContractDurationDays;
        } else {
            return false;
        }
    }

    /// @notice Check if contract is in finished state
    function isFinished() public view override returns (bool) {
        if (finishDay != 0) return true;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

        (uint256 numDays, ) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        if (numDays == lastDueDayMem + 1 - firstDueDayMem) {
            return true;
        }
        return false;
    }

    /// @notice Function to set a contract status as Finished
    /// @dev If the contract hasn't finished, revert
    function tryFinishContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

        (uint256 numDays, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        if (numDays == lastDueDayMem + 1 - firstDueDayMem) {
            // Set finishDay to non-zero value. Subsequent calls to onlyFinished functions should skip this function all together
            finishContract(lastDueDayMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Finished");
        }
    }

    /// @notice Snapshots variables necessary to perform settlements.
    /// @dev This tx should only happen once in the Silica's lifetime.
    function finishContract(
        uint256 _finishDay,
        uint256 silicaRewardBalance,
        uint256 _totalRewardDelivered
    ) internal {
        if (silicaRewardBalance > _totalRewardDelivered) {
            rewardExcess = silicaRewardBalance - _totalRewardDelivered;
        }

        finishDay = uint32(_finishDay);
        rewardDelivered = _totalRewardDelivered;
        resourceAmount = totalSupply();

        emit StatusChanged(SilicaV2_1Types.Status.Finished);
    }

    function getDaysAndRewardFulfilled() external view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastIndexedDayMem = getLastIndexedDay();
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, lastIndexedDayMem);

        uint256 rewardFulfilled = rewardDelivered == 0 ? IERC20(rewardToken).balanceOf(address(this)) : rewardDelivered;
        return getDaysAndRewardFulfilled(rewardFulfilled, firstDueDay, lastDayContractOwesReward);
    }

    /// @notice Returns the number of days N fulfilled by this contract, as well as the reward delivered for all N days
    function getDaysAndRewardFulfilled(
        uint256 _rewardBalance,
        uint256 _firstDueDay,
        uint256 _lastDayContractOwesReward
    ) internal view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        if (_lastDayContractOwesReward < _firstDueDay) {
            return (0, 0); //@ATTN: include collateral
        }

        uint256 totalDue;

        uint256[] memory rewardDueArray = getRewardDueInRange(_firstDueDay, _lastDayContractOwesReward);
        for (uint256 i = 0; i < rewardDueArray.length; i++) {
            uint256 curDay = _firstDueDay + i;

            if (_rewardBalance < totalDue + rewardDueArray[i] + getCollateralLocked(curDay)) {
                return (i, totalDue + getCollateralLocked(curDay));
            }
            totalDue += rewardDueArray[i];
        }

        // Otherwise, contract delivered up to last day that it owes reward
        return (rewardDueArray.length, totalDue + getCollateralLocked(_lastDayContractOwesReward));
    }

    /*///////////////////////////////////////////////////////////////
                            Contract settlement and updates
    //////////////////////////////////////////////////////////////*/

    /// @notice Function returns the accumulative rewards delivered
    function getRewardDeliveredSoFar() external view override returns (uint256) {
        if (rewardDelivered == 0) {
            (, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
                IERC20(rewardToken).balanceOf(address(this)),
                firstDueDay,
                getLastDayContractOwesReward(lastDueDay, getLastIndexedDay())
            );
            return totalRewardDelivered;
        } else {
            return rewardDelivered;
        }
    }

    /// @notice Function returns the last day contract needs to deliver rewards
    function getLastDayContractOwesReward(uint256 _lastDueDay, uint256 lastIndexedDay) public pure override returns (uint256) {
        // Silica always owes up to DayX-1 in rewards
        return lastIndexedDay - 1 <= _lastDueDay ? lastIndexedDay - 1 : _lastDueDay;
    }

    /// @notice Function returns the Collateral Locked on the day inputed
    function getCollateralLocked(uint256 day) internal view returns (uint256) {
        uint256 firstDueDayMem = firstDueDay;
        uint256 initialCollateralAfterRelease = getInitialCollateralAfterRelease();
        if (day <= firstDueDayMem) {
            return initialCollateralAfterRelease;
        }

        (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay) = getCollateralUnlockDays(firstDueDayMem);

        if (day >= finalCollateralReleaseDay) {
            return (0);
        }
        if (day >= initCollateralReleaseDay) {
            return ((initialCollateralAfterRelease * 3) / 4);
        }
        return (initialCollateralAfterRelease);
    }

    /// @notice Function that calculate the collateral based on purchased amount after contract starts
    function getInitialCollateralAfterRelease() internal view returns (uint256) {
        return ((totalSupply() * initialCollateral) / resourceAmount);
    }

    /// @notice Function that calculates the dates collateral gets partial release
    function getCollateralUnlockDays(uint256 _firstDueDay)
        internal
        view
        returns (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay)
    {
        uint256 numDeposits = lastDueDay + 1 - _firstDueDay;

        initCollateralReleaseDay = numDeposits % 4 > 0 ? _firstDueDay + 1 + (numDeposits / 4) : _firstDueDay + (numDeposits / 4);
        finalCollateralReleaseDay = numDeposits % 2 > 0 ? _firstDueDay + 1 + (numDeposits / 2) : _firstDueDay + (numDeposits / 2);

        if (numDeposits == 2) {
            finalCollateralReleaseDay += 1;
        }
    }

    /// @notice Function returns the rewards amount the seller needs deliver for next Oracle update
    function getRewardDueNextOracleUpdate() external view override returns (uint256 rewardDueNextOracleUpdate) {
        uint256 nextIndexedDay = getLastIndexedDay() + 1;
        uint256 firstDueDayMem = firstDueDay;
        if (nextIndexedDay < firstDueDayMem) {
            return (0);
        }
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, nextIndexedDay);
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256[] memory rewardDueArray = getRewardDueInRange(firstDueDayMem, lastDayContractOwesReward);
        uint256 totalDue;
        uint256 balanceNeeded;

        for (uint256 i = 0; i < rewardDueArray.length; i++) {
            uint256 curDay = firstDueDayMem + i;
            totalDue += rewardDueArray[i];

            if (balanceNeeded < totalDue + getCollateralLocked(curDay)) {
                balanceNeeded = totalDue + getCollateralLocked(curDay);
            }
        }

        if (balanceNeeded <= rewardBalance) {
            return 0;
        } else {
            return (balanceNeeded - rewardBalance);
        }
    }

    /**
     * @notice Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
     * Silica is minted proportional to purchaseAmount and transfered to buyer.
     * @dev confirms the buyer's payment, mint the Silicas and transfer the tokens.
     */
    function deposit(uint256 amountSpecified) external override onlyOpen returns (uint256 mintAmount) {
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, msg.sender, totalSupply(), amountSpecified);
        _mint(msg.sender, mintAmount);
    }

    /**
     * @notice Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
     * Silica is minted proportional to purchaseAmount and transfered to the address specified _to.
     * @dev confirms the buyer's payment, mint the Silicas and transfer the tokens.
     */
    function proxyDeposit(address _to, uint256 amountSpecified) external override onlyOpen returns (uint256 mintAmount) {
        require(_to != address(0), "Invalid Address");
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, _to, totalSupply(), amountSpecified);
        _mint(_to, mintAmount);
    }

    /// @notice Internal function to process buyer's deposit
    function _deposit(
        address from,
        address to,
        uint256 _totalSupply,
        uint256 amountSpecified
    ) internal returns (uint256 mintAmount) {
        mintAmount = getMintAmount(resourceAmount, amountSpecified, reservedPrice);

        require(_totalSupply + mintAmount <= resourceAmount, "Insufficient Supply");

        emit Deposit(to, amountSpecified, mintAmount);

        _transferPaymentTokenFrom(from, address(this), amountSpecified);
    }

    /// @notice Function that returns the minted Silica amount from purchase amount
    function getMintAmount(
        uint256 consensusResource,
        uint256 purchaseAmount,
        uint256 _reservedPrice
    ) internal pure returns (uint256) {
        return (consensusResource * purchaseAmount) / _reservedPrice;
    }

    /// @notice Internal function to safely transfer payment token
    function _transferPaymentTokenFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(paymentToken), from, to, amount);
    }

    /// @notice Function that buyer calls to collect reward when silica is finished
    function buyerCollectPayout() external override onlyFinished onlyBuyers returns (uint256 rewardPayout) {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnFinish(msg.sender, buyerBalance);
    }

    /// @notice Internal function to process rewards to Buyer when contract is Finished
    function _transferBuyerPayoutOnFinish(address buyerAddress, uint256 buyerBalance) internal returns (uint256 rewardPayout) {
        rewardPayout = PayoutMath.getBuyerRewardPayout(rewardDelivered, buyerBalance, resourceAmount);

        emit BuyerCollectPayout(rewardPayout, 0, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);
    }

    /// @notice Internal function to safely transfer rewards to Buyer
    function _transferRewardToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), to, amount);
    }

    /// @notice Function that buyer calls to settle defaulted contract
    function buyerCollectPayoutOnDefault()
        external
        override
        onlyDefaulted
        onlyBuyers
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnDefault(msg.sender, buyerBalance);
    }

    /// @notice Internal funtion to process rewards and payment return to Buyer when contract is default
    function _transferBuyerPayoutOnDefault(address buyerAddress, uint256 buyerBalance)
        internal
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        rewardPayout = PayoutMath.getRewardTokenPayoutToBuyerOnDefault(buyerBalance, rewardDelivered, resourceAmount); //rewardDelivered in the case of a default represents the rewardTokenBalance of the contract at default

        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;

        paymentPayout = PayoutMath.getPaymentTokenPayoutToBuyerOnDefault(
            buyerBalance,
            totalUpfrontPayment,
            resourceAmount,
            PayoutMath.getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired)
        );

        emit BuyerCollectPayout(rewardPayout, paymentPayout, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);

        if (paymentPayout > 0) {
            _transferPaymentToken(buyerAddress, paymentPayout);
        }
    }

    /// @notice Internal funtion to safely transfer payment return to Buyer
    function _transferPaymentToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), to, amount);
    }

    /// @notice Gets the owner of silica
    function getOwner() external view override returns (address) {
        return owner;
    }

    /// @notice Gets reward type
    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }

    /// @notice Gets the Payment type
    function getPaymentToken() external view override returns (address) {
        return address(paymentToken);
    }

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return The last day of reward the seller is selling with this contract
    function getLastDueDay() external view override returns (uint32) {
        return lastDueDay;
    }

    /// @notice Function seller calls to settle finished silica
    function sellerCollectPayout()
        external
        override
        onlyOwner
        onlyFinished
        onlyOnePayout
        returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess)
    {
        paymentTokenPayout = IERC20(paymentToken).balanceOf(address(this));
        rewardTokenExcess = rewardExcess;

        emit SellerCollectPayout(paymentTokenPayout, rewardTokenExcess);
        _transferPaymentToSeller(paymentTokenPayout);
        if (rewardTokenExcess > 0) {
            _transferRewardToSeller(rewardTokenExcess);
        }
    }

    /// @notice Function seller calls to settle default contract
    function sellerCollectPayoutDefault()
        external
        override
        onlyOwner
        onlyDefaulted
        onlyOnePayout
        returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess)
    {
        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;
        uint256 haircut = PayoutMath.getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired);
        paymentTokenPayout = PayoutMath.getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut);
        rewardTokenExcess = rewardExcess;

        emit SellerCollectPayout(paymentTokenPayout, rewardTokenExcess);
        _transferPaymentToSeller(paymentTokenPayout);
        if (rewardTokenExcess > 0) {
            _transferRewardToSeller(rewardTokenExcess);
        }
    }

    /// @notice Function seller calls to settle when contract is
    function sellerCollectPayoutExpired() external override onlyExpired onlyOwner returns (uint256 rewardTokenPayout) {
        rewardTokenPayout = IERC20(rewardToken).balanceOf(address(this));

        _transferRewardToSeller(rewardTokenPayout);
        emit SellerCollectPayout(0, rewardTokenPayout);
    }

    /// @notice Internal funtion to safely transfer payment to Seller
    function _transferPaymentToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), owner, amount);
    }

    /// @notice Internal funtion to safely transfer excess reward to Seller
    function _transferRewardToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), owner, amount);
    }

    /// @notice Function to return the reward due on a given day
    function getRewardDueOnDay(uint256 _day) internal view virtual returns (uint256);

    /// @notice Function to return the last day silica is synced with Oracle
    function getLastIndexedDay() internal view virtual returns (uint32);

    /// @notice Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)
    function getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view virtual returns (uint256[] memory);

    /// @notice Function to return contract reserved price
    function getReservedPrice() external view override returns (uint256) {
        return reservedPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {AbstractSilicaV2_1} from "./AbstractSilicaV2_1.sol";

import "./interfaces/oracle/oracleEthStaking/IOracleEthStaking.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "./libraries/math/RewardMath.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SilicaEthStaking is AbstractSilicaV2_1 {
    uint8 public constant COMMODITY_TYPE = 2;

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    constructor() ERC20("Silica", "SLC") {}

    /// @notice Function to return the last day silica is synced with Oracle
    function getLastIndexedDay() internal view override returns (uint32) {
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE)
        );
        uint32 lastIndexedDayMem = oracleEthStaking.getLastIndexedDay();
        require(lastIndexedDayMem != 0, "Invalid State");

        return lastIndexedDayMem;
    }

    /// @notice Function to return the amount of rewards due by the seller to the contract on day inputed
    function getRewardDueOnDay(uint256 _day) internal view override returns (uint256) {
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE)
        );
        (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(_day);

        return RewardMath.getEthStakingRewardDue(totalSupply(), baseRewardPerIncrementPerDay, decimals());
    }

    /// @notice Function to return an array with the amount of rewards due by the seller to the contract on days in range inputed
    function getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view override returns (uint256[] memory) {
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE)
        );
        uint256[] memory baseRewardPerIncrementPerDayArray = oracleEthStaking.getInRange(_firstDay, _lastDay);

        uint256[] memory rewardDueArray = new uint256[](baseRewardPerIncrementPerDayArray.length);

        uint8 decimalsMem = decimals();
        uint256 totalSupplyCopy = totalSupply();
        for (uint256 i = 0; i < baseRewardPerIncrementPerDayArray.length; i++) {
            rewardDueArray[i] = RewardMath.getEthStakingRewardDue(totalSupplyCopy, baseRewardPerIncrementPerDayArray[i], decimalsMem);
        }

        return rewardDueArray;
    }

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure override returns (uint8) {
        return COMMODITY_TYPE;
    }

    /// @notice Returns decimals of the contract
    function getDecimals() external pure override returns (uint8) {
        return decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya Oracle Addresses
 * @author Alkimiya Team
 * */
interface IOracleRegistry {
    event OracleRegistered(address token, uint256 oracleType, address oracleAddr);

    function getOracleAddress(address _token, uint256 _oracleType) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IOracleEthStakingEvents.sol";

/**
 * @title Alkimiya OraclePoS
 * @author Alkimiya Team
 * @notice This is the interface for Proof of Stake Oracle contract
 * */
interface IOracleEthStaking is IOracleEthStakingEvents {
    /**
     * @notice Update the Alkimiya Index for PoS instruments on Oracle for a given day
     */
    function updateIndex(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized,
        bytes memory signature
    ) external returns (bool success);

    /// @notice Function to return Oracle index on given day
    function get(uint256 _referenceDay)
        external
        view
        returns (
            uint256 referenceDay,
            uint256 baseRewardPerIncrementPerDay,
            uint256 burnFee,
            uint256 priorityFee,
            uint256 burnFeeNormalized,
            uint256 priorityFeeNormalized,
            uint256 timestamp
        );

    /// @notice Function to return array of oracle data between firstday and lastday (inclusive)
    function getInRange(uint256 _firstDay, uint256 _lastDay) external view returns (uint256[] memory baseRewardPerIncrementPerDayArray);

    /**
     * @notice Return if the network data on a given day is updated to Oracle
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool);

    /**
     * @notice Return the last day on which the Oracle is updated
     */
    function getLastIndexedDay() external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya OraclePoS
 * @author Alkimiya Team
 * @notice This is the interface for Proof of Stake Oracle contract
 * */
interface IOracleEthStakingEvents {
    /**
     * @notice Oracle Uptade Event
     */
    event OracleUpdate(
        address indexed caller,
        uint256 indexed referenceDay,
        uint256 timestamp,
        uint256 baseRewardPerIncrementPerDay,
        uint256 burnFee,
        uint256 priorityFee,
        uint256 burnFeeNormalized,
        uint256 priorityFeeNormalized
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

/**
 * @title The interface for Silica
 * @author Alkimiya Team
 * @notice A Silica contract lists hashrate for sale
 * @dev The Silica interface is broken up into smaller interfaces
 */
interface ISilicaV2_1 {
    /*///////////////////////////////////////////////////////////////
                                 Events
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed buyer, uint256 purchaseAmount, uint256 mintedTokens);
    event BuyerCollectPayout(uint256 rewardTokenPayout, uint256 paymentTokenPayout, address buyerAddress, uint256 burntAmount);
    event SellerCollectPayout(uint256 paymentTokenPayout, uint256 rewardTokenExcess);
    event StatusChanged(SilicaV2_1Types.Status status);

    struct InitializeData {
        address rewardTokenAddress;
        address paymentTokenAddress;
        address oracleRegistry;
        address sellerAddress;
        uint256 dayOfDeployment;
        uint256 lastDueDay;
        uint256 unitPrice;
        uint256 resourceAmount;
        uint256 collateralAmount;
    }

    /// @notice Returns the amount of rewards the seller must have delivered before next update
    /// @return rewardDueNextOracleUpdate amount of rewards the seller must have delivered before next update
    function getRewardDueNextOracleUpdate() external view returns (uint256);

    /// @notice Initializes the contract
    /// @param initializeData is the address of the token the seller is selling
    function initialize(InitializeData memory initializeData) external;

    /// @notice Function called by buyer to deposit payment token in the contract in exchange for Silica tokens
    /// @param amountSpecified is the amount that the buyer wants to deposit in exchange for Silica tokens
    function deposit(uint256 amountSpecified) external returns (uint256);

    /// @notice Called by the swapProxy to make a deposit in the name of a buyer
    /// @param _to the address who should receive the Silica Tokens
    /// @param amountSpecified is the amount the swapProxy is depositing for the buyer in exchange for Silica tokens
    function proxyDeposit(address _to, uint256 amountSpecified) external returns (uint256);

    /// @notice Function the buyer calls to collect payout when the contract status is Finished
    function buyerCollectPayout() external returns (uint256 rewardTokenPayout);

    /// @notice Function the buyer calls to collect payout when the contract status is Defaulted
    function buyerCollectPayoutOnDefault() external returns (uint256 rewardTokenPayout, uint256 paymentTokenPayout);

    /// @notice Function the seller calls to collect payout when the contract status is Finised
    function sellerCollectPayout() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Defaulted
    function sellerCollectPayoutDefault() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Expired
    function sellerCollectPayoutExpired() external returns (uint256 rewardTokenPayout);

    /// @notice Returns the owner of this Silica
    /// @return address: owner address
    function getOwner() external view returns (address);

    /// @notice Returns the Payment Token accepted in this Silica
    /// @return Address: Token Address
    function getPaymentToken() external view returns (address);

    /// @notice Returns the rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    /// @return The rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    function getRewardToken() external view returns (address);

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return The last day of reward the seller is selling with this contract
    function getLastDueDay() external view returns (uint32);

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure returns (uint8);

    /// @notice Get the current status of the contract
    /// @return status: The current status of the contract
    function getStatus() external view returns (SilicaV2_1Types.Status);

    /// @notice Returns the day of default.
    /// @return day: The day the contract defaults
    function getDayOfDefault() external view returns (uint256);

    /// @notice Returns true if contract is in Open status
    function isOpen() external view returns (bool);

    /// @notice Returns true if contract is in Running status
    function isRunning() external view returns (bool);

    /// @notice Returns true if contract is in Expired status
    function isExpired() external view returns (bool);

    /// @notice Returns true if contract is in Defaulted status
    function isDefaulted() external view returns (bool);

    /// @notice Returns true if contract is in Finished status
    function isFinished() external view returns (bool);

    /// @notice Returns amount of rewards delivered so far by contract
    function getRewardDeliveredSoFar() external view returns (uint256);

    /// @notice Returns the most recent day the contract owes in rewards
    /// @dev The returned value does not indicate rewards have been fulfilled up to that day
    /// This only returns the most recent day the contract should deliver rewards
    function getLastDayContractOwesReward(uint256 lastDueDay, uint256 lastIndexedDay) external view returns (uint256);

    /// @notice Returns the reserved price of the contract
    function getReservedPrice() external view returns (uint256);

    /// @notice Returns decimals of the contract
    function getDecimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SilicaV2_1Types {
    enum Status {
        Open,
        Running,
        Expired,
        Defaulted,
        Finished
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Calculations for when buyer initiates default
 * @author Alkimiya Team
 */
library PayoutMath {
    uint256 internal constant SCALING_FACTOR = 1e8;

    //Contract Constants
    uint128 internal constant FIXED_POINT_SCALE_VALUE = 10**14;
    uint128 internal constant FIXED_POINT_BASE = 10**6;
    uint32 internal constant HAIRCUT_BASE_PCT = 80;

    /**
     * @notice Returns haircut in fixed-point (base = 100000000 = 1).
     * @dev Granting 6 decimals precision. 1 - (0.8) * (day/contract)^3
     */
    function getHaircut(uint256 _numDepositsCompleted, uint256 _contractNumberOfDeposits) internal pure returns (uint256) {
        uint256 contractNumberOfDepositsCubed = uint256(_contractNumberOfDeposits)**3;
        uint256 multiplier = ((_numDepositsCompleted**3) * FIXED_POINT_SCALE_VALUE) / (contractNumberOfDepositsCubed);
        uint256 result = (HAIRCUT_BASE_PCT * multiplier) / (100 * FIXED_POINT_BASE);
        return (FIXED_POINT_BASE * 100) - result;
    }

    /**
     * @notice Calculates reward given to buyer when contract defaults.
     * @dev result = tokenBalance * (totalReward / hashrate)
     */
    function getRewardTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalRewardDelivered,
        uint256 _totalSilicaMinted
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalRewardDelivered) / _totalSilicaMinted;
    }

    /**
     * @notice  Calculates payment returned to buyer when contract defaults.
     * @dev result =  haircut * totalpayment tokenBalance / hashrateSold
     */
    function getPaymentTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalUpfrontPayment,
        uint256 _totalSilicaMinted,
        uint256 _haircut
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalUpfrontPayment * _haircut) / (_totalSilicaMinted * SCALING_FACTOR);
    }

    function getRewardPayoutToSellerOnDefault(uint256 _totalUpfrontPayment, uint256 _haircutPct) internal pure returns (uint256) {
        require(_haircutPct <= 100000000, "Scaled haircut PCT cannot be greater than 100000000");
        uint256 haircutPctRemainder = uint256(100000000) - _haircutPct;
        return (haircutPctRemainder * _totalUpfrontPayment) / 100000000;
    }

    function calculateReservedPrice(
        uint256 unitPrice,
        uint256 resourceAmount,
        uint256 numDeposits,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (unitPrice * resourceAmount * numDeposits) / (10**decimals);
    }

    function getBuyerRewardPayout(
        uint256 rewardDelivered,
        uint256 buyerBalance,
        uint256 resourceAmount
    ) internal pure returns (uint256) {
        return (rewardDelivered * buyerBalance) / resourceAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Calculations for when buyer initiates default
 * @author Alkimiya Team
 */
library RewardMath {
    function getMiningRewardDue(
        uint256 _hashrate,
        uint256 _networkReward,
        uint256 _networkHashrate
    ) internal pure returns (uint256) {
        return (_hashrate * _networkReward) / _networkHashrate;
    }

    function getEthStakingRewardDue(
        uint256 _stakedAmount,
        uint256 _baseRewardPerIncrementPerDay,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (_stakedAmount * _baseRewardPerIncrementPerDay) / (10**decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SilicaV2_1Types} from "../libraries/SilicaV2_1Types.sol";

abstract contract SilicaV2_1Storage {
    uint32 public finishDay;
    bool public didSellerCollectPayout;
    address public rewardToken;
    address public paymentToken;
    address public oracleRegistry;
    address public silicaFactory;
    address public owner;

    uint32 public firstDueDay;
    uint32 public lastDueDay;
    uint32 public defaultDay;

    uint256 public initialCollateral;
    uint256 public resourceAmount;
    uint256 public reservedPrice;
    uint256 public rewardDelivered;
    uint256 public totalUpfrontPayment; //@review: why is it set to 1 as default in silicaV2
    uint256 public rewardExcess;
    SilicaV2_1Types.Status status;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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