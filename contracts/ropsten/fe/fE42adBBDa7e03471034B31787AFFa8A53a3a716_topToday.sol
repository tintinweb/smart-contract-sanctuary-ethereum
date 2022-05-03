/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.8.0;

struct userData {
    uint256 dataId;
    string mainData;
    string dataDescription;
    uint256 publishedTime;
}

struct topDataDetails {
    string publisher;
    string mainData;
    string dataDescription;
    uint256 publishedTime;
}

interface topTodayInterface {
    function createAccount(string memory userName, string memory aboutUser)
        external
        returns (bool);

    function getData(string memory userName)
        external
        view
        returns (userData[] memory);

    function setTopData(
        uint256 position,
        string memory mainData,
        string memory description
    ) external payable returns (bool);

    function getTopData() external view returns (topDataDetails[10] memory);

    function setTopDataPrice(uint256 position, uint256 newPrice)
        external
        returns (bool);

    function getTopDataItemsPrice() external view returns (uint256[10] memory);

    function setPriceInterval(uint256 newPriceInterval) external returns (bool);
}

contract topToday is topTodayInterface {
    address public contractCreator;
    uint256 public totalDataItems;
    uint256 public totalUsers;
    topDataDetails[10] public topDataItems;
    uint256[10] public topDataItemsPrice;
    uint256 public priceInterval = 2;

    mapping(string => address) public userNames;
    mapping(address => userData[]) public usersData;

    constructor() {
        contractCreator = msg.sender;
    }

    // It Will Simply Create User Account.
    // userName Should Unique.
    function createAccount(string memory userName, string memory aboutUser)
        external
        override
        returns (bool)
    {
        require((checkUserName(userName) == false), "Username Already Exists");
        userNames[userName] = msg.sender;
        totalUsers++;
        usersData[msg.sender].push(
            userData(totalUsers, userName, aboutUser, block.timestamp)
        );
        return true;
    }

    function donateUs() public payable returns (bool) {
        return true;
    }

    function totalFund() public view returns (uint256) {
        return (address(this)).balance;
    }

    function transferFund() public returns (bool) {
        require(
            msg.sender == contractCreator,
            "Only Contract Creator Can Use This Function"
        );
        address payable to = payable(contractCreator);
        bool isDone = to.send((address(this)).balance);
        return isDone;
    }

    // Using This Fuction User Can Set Data Or Publish Data But It Will Not Set For TopData.
    function setData(string memory mainData, string memory description)
        public
        returns (bool)
    {
        require(
            (usersData[msg.sender][0].dataId > 0),
            "Please Create Your Account"
        );
        totalDataItems++;
        usersData[msg.sender].push(
            userData(totalDataItems, mainData, description, block.timestamp)
        );
        return true;
    }

    // It Will Return Data Of Specific Data And Anyone Can Call It.
    // This Function Will Return Array Of Object Who Will Consist All Information About User.
    // This Function Will Be Used For Displaying Data Of User In FrontEnd.
    function getData(string memory userName)
        external
        view
        override
        returns (userData[] memory)
    {
        return usersData[userNames[userName]];
    }

    // It Will Take UserName And Check That Whether User Exists Or Not.
    function checkUserName(string memory userName) private view returns (bool) {
        if (userNames[userName] == 0x0000000000000000000000000000000000000000) {
            return false;
        } else {
            return true;
        }
    }

    // Using This Function Any User Can Set TopData.
    // User Should Have Account And Their Amount For TopData Should Greater Than Current Amount.
    // Amount Of User Should According To Price Interval.
    // This Fucntion Will Set Data In TopData And Also In UsersData.
    function setTopData(
        uint256 position,
        string memory mainData,
        string memory description
    ) external payable override returns (bool) {
        require(
            (usersData[msg.sender][0].dataId > 0),
            "Please Create Your Account"
        );
        require(((position) <= 10 && position > 0), "Invalid Position");
        require(
            ((msg.value / priceInterval) * priceInterval == msg.value),
            "Price Should Be According To Interval"
        );
        position--;
        require(
            (msg.value > topDataItemsPrice[position]),
            "Your Amount Should Greater Than Current Price"
        );
        totalDataItems++;
        usersData[msg.sender].push(
            userData(totalDataItems, mainData, description, block.timestamp)
        );

        topDataItemsPrice[position] = msg.value;

        topDataItems[position] = topDataDetails(
            usersData[msg.sender][0].mainData,
            mainData,
            description,
            block.timestamp
        );
        return true;
    }

    // This Fuction Will Just Return TopData.
    // Array Of TopData Details Will Be Returned By This Fuction.
    // It Can Be Called By Anyone And Mainly It Will Be Used For Displaying TopData On FrontEnd.
    function getTopData()
        external
        view
        override
        returns (topDataDetails[10] memory)
    {
        return topDataItems;
    }

    // This Fuction Is Used For Specifying Price Of Each TopData,
    // Basically Using This We Can Control Prices Of TopData And Only Contract Creator Can Use This Function.
    // Try To Avoid Use Of This Fuction Use It When There Is Imbalance In Prices Of TopData Or Any Big Problem Occurs.
    function setTopDataPrice(uint256 position, uint256 newPrice)
        external
        override
        returns (bool)
    {
        require(
            msg.sender == contractCreator,
            "Only Contract Creator Can Use This Function"
        );
        require(((position) <= 10 && position > 0), "Invalid Position");
        position--;
        topDataItemsPrice[position] = newPrice;
        return true;
    }

    // For Getting Price List Of TopData
    function getTopDataItemsPrice()
        external
        view
        override
        returns (uint256[10] memory)
    {
        return topDataItemsPrice;
    }

    // It Is Used For Specifyig Interval Price, Interval Price Refers To Interval Between New Price And Old Price Of TopData Price.
    // Basically We Can Use It For Increasing Or Decreasing Extra Charges On New TopData.
    // Only Contract Creator Can Use It And They Can Use It As Per Market.
    function setPriceInterval(uint256 newPriceInterval)
        external
        override
        returns (bool)
    {
        require(
            msg.sender == contractCreator,
            "Only Contract Creator Can Use This Function"
        );
        priceInterval = newPriceInterval;
        return true;
    }
}