// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract HouseFunding {
    error HouseFunding__ValueTooLow();
    error HouseFunding__NoBalance();
    error HouseFunding__CurrentFundedAmoutIsTooLow();
    error HouseFunding__NotAuthorized();
    error HouseFunding__AlreadyWithdrawn();
    error HouseFunding__FundingAlreadyAchieved();

    struct House {
        uint256 id;
        uint256 price;
        string location;
        address seller;
        uint256 currentFundedAmount;
        bool goalAchieved;
    }

    struct Funder {
        uint256 id;
        address funder;
        uint256 fundedAmount;
        uint256 houseInvested;
    }

    constructor() {
        owner = msg.sender;
    }

    address private owner;
    House[] public houses;
    Funder[] public funders;

    /** @notice Creates a House Listing
     *  @param price the price for the listing in ether
     *  @param location the location of the house
     *  @return the created house listing
     */
    function createHouseListing(uint256 price, string memory location)
        external
        returns (House memory)
    {
        uint256 housesCount = houses.length;
        uint256 id = housesCount++;

        //price in eth
        //add price converter later
        uint256 convertedPrice = price * 10**18;

        House memory house = House(
            id,
            convertedPrice,
            location,
            msg.sender,
            0,
            false
        );
        houses.push(house);

        return house;
    }

    /** @notice Removes a House Listing
     *  @param houseId the id of the house that should be removed from the listing
     *  @return the length of the houses array
     */
    function removeListing(uint256 houseId) external returns (uint256) {
        houses[houseId] = houses[houses.length - 1];
        houses.pop();
        return houses.length;
    }

    /** @notice Gets the price of a listed house
     *  @param houseId the id of the house to query
     *  @return the price of the house
     */
    function getHousePrice(uint256 houseId) external view returns (uint256) {
        return houses[houseId].price;
    }

    /** @notice Gets all the listed Houses
     *  @return an array of all Houses
     */
    function getAllHouses() external view returns (House[] memory) {
        return houses;
    }

    /** @notice Funds a listed House
     *  @param houseId the id of the house to fund
     */
    function fundHouse(uint256 houseId) external payable {
        if (msg.value <= 0) {
            revert HouseFunding__ValueTooLow();
        }

        if (houses[houseId].currentFundedAmount == houses[houseId].price) {
            revert HouseFunding__FundingAlreadyAchieved();
        }

        uint256 fundersCount = funders.length;
        uint256 id = fundersCount++;

        Funder memory funder = Funder(id, msg.sender, msg.value, 0);

        funders.push(funder);

        funders[id].houseInvested = houseId;

        houses[houseId].currentFundedAmount += msg.value;
    }

    /** @notice Gets the total amount funded for the current wallet
     *  @return the total amount funded for this wallet
     */
    function getTotalAmountFunded() external view returns (uint256) {
        uint256 totalAmount;
        for (uint256 i = 0; i < funders.length; i++) {
            if (msg.sender == funders[i].funder) {
                totalAmount += funders[i].fundedAmount;
            }
        }
        return totalAmount;
    }

    /** @notice Gets the invested house ids for the current wallet
     *  @return an Array of invested House ids
     */
    function getInvestedHouses() external view returns (uint256[] memory) {
        //TO REFACTOR - Calculate the size of the memory array
        uint256 size;

        for (uint256 i = 0; i < funders.length; i++) {
            if (msg.sender == funders[i].funder) {
                size++;
            }
        }

        uint256[] memory houseInvested = new uint256[](size);

        for (uint256 i = 0; i < funders.length; i++) {
            if (msg.sender == funders[i].funder) {
                houseInvested[i] = funders[i].houseInvested;
            }
        }

        return houseInvested;
    }

    /** @notice Gets the percentage of each house the current wallet owns
     *  @param houseId the id of the house to query
     *  @return the percent of the house the wallet owns
     */
    function getPercentOwned(uint256 houseId) external view returns (uint256) {
        uint256 percent;
        for (uint256 i = 0; i < funders.length; i++) {
            if (
                msg.sender == funders[i].funder &&
                funders[i].houseInvested == houseId
            ) {
                percent =
                    (funders[i].fundedAmount * 100) /
                    houses[houseId].price;
            }
        }

        return percent;
    }

    /** @notice Withdraw the funds of a specific house to the owner wallet
     *  @param houseId the id of the house to withdraw
     */
    function withdraw(uint256 houseId) external payable {
        House memory house = houses[houseId];

        if (address(this).balance <= 0) {
            revert HouseFunding__NoBalance();
        }

        if (house.currentFundedAmount < house.price && !house.goalAchieved) {
            revert HouseFunding__CurrentFundedAmoutIsTooLow();
        }

        if (msg.sender != owner) {
            revert HouseFunding__NotAuthorized();
        }

        if (house.goalAchieved) {
            revert HouseFunding__AlreadyWithdrawn();
        }

        house.goalAchieved = true;
        payable(msg.sender).transfer(house.currentFundedAmount);
        house.currentFundedAmount = 0;
        houses[houseId] = house;
    }
}