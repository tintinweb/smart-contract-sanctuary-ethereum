//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IPrivateSaleFactory.sol";
import "./interfaces/IPrivateSale.sol";

contract PrivateSaleLens {
    struct SaleData {
        uint96 id;
        address sale;
        string name;
        uint256 maxSupply;
        uint256 amountSold;
        uint256 minAmount;
        uint256 price;
        bool isOver;
        uint256 userBalance;
        uint248 userAmount;
        uint248 userAmountBought;
        bool userIsWhitelisted;
        bool userIsComplient;
    }
    IPrivateSaleFactory public factory;

    constructor(IPrivateSaleFactory _factory) {
        factory = _factory;
    }

    function getSaleData(
        uint256 start,
        uint256 end,
        address user
    ) external view returns (SaleData[] memory availableSale) {
        uint256 len = factory.lenPrivateSales();
        if (end > len) {
            end = len;
        }
        availableSale = new SaleData[](end - start);

        for (uint256 i = start; i < end; i++) {
            IPrivateSale privateSale = IPrivateSale(factory.privateSales(i));
            IPrivateSale.UserInfo memory userInfo = privateSale.userInfo(user);

            if (userInfo.isWhitelisted) {
                availableSale[i - start] = SaleData({
                    id: uint96(i),
                    sale: address(privateSale),
                    name: privateSale.name(),
                    maxSupply: privateSale.maxSupply(),
                    amountSold: privateSale.amountSold(),
                    minAmount: privateSale.minAmount(),
                    price: privateSale.price(),
                    isOver: privateSale.isOver(),
                    userBalance: msg.sender.balance,
                    userAmount: userInfo.amount,
                    userAmountBought: userInfo.amountBought,
                    userIsWhitelisted: userInfo.isWhitelisted,
                    userIsComplient: userInfo.isComplient
                });
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPrivateSaleFactory {
    function receiverAddress() external view returns (address);

    function devAddress() external view returns (address);

    function devFee() external view returns (uint256);

    function implementation() external view returns (address);

    function getPrivateSale(string memory name) external view returns (address);

    function privateSales(uint256 index) external view returns (address);

    function initialize(address receiverAddress, address implementation)
        external;

    function lenPrivateSales() external view returns (uint256);

    function createPrivateSale(
        string calldata name,
        uint256 price,
        uint256 maxSupply,
        uint256 minAmount
    ) external returns (address);

    function addToWhitelist(string calldata name, address[] calldata addresses)
        external;

    function removeFromWhitelist(
        string calldata name,
        address[] calldata addresses
    ) external;

    function validateUsers(string calldata name, address[] calldata addresses)
        external;

    function claim(string calldata name) external;

    function endSale(string calldata name) external;

    function setImplemention(address implementation) external;

    function setReceiverAddress(address receiver) external;

    function setDevAddress(address dev) external;

    function setDevFee(uint256 devFee) external;

    function emergencyWithdraw(string calldata name) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPrivateSale {
    struct UserInfo {
        bool isWhitelisted;
        uint248 amount;
        uint248 amountBought;
        bool isComplient;
    }

    function factory() external view returns (address);

    function name() external view returns (string memory);

    function maxSupply() external view returns (uint256);

    function amountSold() external view returns (uint256);

    function minAmount() external view returns (uint256);

    function price() external view returns (uint256);

    function claimableAmount() external view returns (uint256);

    function isOver() external view returns (bool);

    function userInfo(address user) external view returns (UserInfo memory);

    function initialize(
        string calldata name,
        uint256 price,
        uint256 maxSupply,
        uint256 minAmount
    ) external;

    function participate() external payable;

    function addToWhitelist(address[] calldata addresses) external;

    function removeFromWhitelist(address[] calldata addresses) external;

    function validateUsers(address[] calldata addresses) external;

    function claim() external;

    function endSale() external;

    function emergencyWithdraw() external;
}