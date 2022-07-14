import "../swapper/Swapper.sol";
import "../fee/FeeSettingsDecorator.sol";

contract GigaSwap is Swapper, FeeSettingsDecorator {
    constructor(address feeSettingsAddress)
        FeeSettingsDecorator(feeSettingsAddress)
    {}
}

pragma solidity >=0.8.7;

//import "hardhat/console.sol";
import "./ISwapper.sol";
import "./Deal.sol";
import "./IDealPoint.sol";
import "./IDealPointFactory.sol";
import "contracts/lib/ownable/Ownable.sol";

/// @dev данные об одной позиции в сделке
struct DealPointData {
    address factory;
    address point;
}

abstract contract Swapper is ISwapper, Ownable {
    mapping(uint256 => Deal) public deals;
    mapping(uint256 => mapping(uint256 => DealPointData)) public dealPoints; // пункты сделок
    mapping(uint256 => uint256) public dealPointsCounts; // количества пунктов сделок
    mapping(address => bool) public factories; // фабрики пунктов сделок
    mapping(address => uint256) public dealsCountByAccount; // количества сделок по аккаунтам
    mapping(address => mapping(uint256 => uint256)) dealsByAccounts; // сделки по их создателям
    uint256 public dealsCount;

    event NewDeal(uint256 indexed dealId, address indexed creator);

    function makeDeal(address anotherAccount) external {
        // создаем сделку
        Deal memory deal = Deal(
            1, // редактирование
            msg.sender, // 0 овнер
            anotherAccount // 1 овнер
        );
        ++dealsCount;
        deals[dealsCount] = deal;
        dealsByAccounts[msg.sender][
            dealsCountByAccount[msg.sender]++
        ] = dealsCount;
        emit NewDeal(dealsCount, msg.sender);
    }

    function addDealPoint(uint256 dealId, address point) external override {
        require(factories[msg.sender], "only for factories");
        require(deals[dealId].state == 1, "deal is not in edit state");
        uint256 pointsCount = dealPointsCounts[dealId];
        dealPoints[dealId][pointsCount] = DealPointData(msg.sender, point);
        dealPointsCounts[dealId] = pointsCount + 1;
    }

    function addFactory(address factory) public onlyOwner {
        factories[factory] = true;
    }

    function removeFactory(address factory) public onlyOwner {
        factories[factory] = false;
    }

    function setFactories(address[] memory factories_, bool value)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < factories_.length; ++i)
            factories[factories_[i]] = value;
    }

    /// @dev возвращает сделку, если такой сделки нет то выдает ошибку
    function getDeal(uint256 dealId) public view returns (Deal memory) {
        Deal memory deal = deals[dealId];
        require(deal.state > 0, "deal is not exists");
        return deal;
    }

    function getDealIdByIndex(address account, uint256 index)
        public
        view
        returns (uint256)
    {
        return dealsByAccounts[account][index];
    }

    /// @dev возвращает страницу сделок для адреса
    /// @param account на кого получить сделки
    /// @param startIndex начальный индекс
    /// @param count сколько максимум получить сделок
    /// @return сколько всего сделок открыто, id сделок, сделки, количество пунктов по сделкам
    function getDealsPage(
        address account,
        uint256 startIndex,
        uint256 count
    )
        external
        view
        returns (
            uint256,
            uint256[] memory,
            Deal[] memory,
            uint256[] memory
        )
    {
        uint256 playerDealsCount = dealsCountByAccount[account];
        if (startIndex + count > playerDealsCount) {
            if (startIndex >= playerDealsCount)
                return (
                    playerDealsCount,
                    new uint256[](0),
                    new Deal[](0),
                    new uint256[](0)
                );
            count = playerDealsCount - startIndex;
        }

        uint256[] memory ids = new uint256[](count);
        Deal[] memory dealsResult = new Deal[](count);
        uint256[] memory pointsCount = new uint256[](count);

        for (uint256 i = 0; i < count; ++i) {
            uint256 id = getDealIdByIndex(account, i);
            ids[startIndex + i] = id;
            dealsResult[startIndex + i] = deals[id];
            uint256 pc = dealPointsCounts[id];
            pointsCount[startIndex + i] = pc;
        }

        return (playerDealsCount, ids, dealsResult, pointsCount);
    }

    /// @dev если истино, то сделка выполнена и ее можно свапать
    function isComplete(uint256 dealId) public view returns (bool) {
        // получаем количество деталей на сделку
        uint256 pointsCount = dealPointsCounts[dealId];
        if (pointsCount == 0) return false;
        // берем детали
        mapping(uint256 => DealPointData) storage points = dealPoints[dealId];
        // проверка всех деталей
        for (uint256 i = 0; i < pointsCount; ++i)
            if (!IDealPoint(points[i].point).isComplete()) return false;
        return true;
    }

    /// @dev производит свап сделки.
    /// Если сделка не выполнена - выдает ошибку.
    /// Если сделка уже свапнута - ошибка
    function swap(uint256 dealId) external {
        // берем сделку
        Deal storage deal = deals[dealId];
        require(deal.state == 2, "only in execution state");
        // берем количество деталей
        uint256 pointsCount = dealPointsCounts[dealId];
        require(pointsCount > 0, "deal has no points");
        // свапаем все детали
        mapping(uint256 => DealPointData) storage points = dealPoints[dealId];
        for (uint256 i = 0; i < pointsCount; ++i) {
            IDealPoint point = IDealPoint(points[i].point);
            require(point.isComplete(), "there are uncompleted parts");
            point.swap();
        }

        ++deal.state; // след состояние, чтобы избежать двойного свапа
        deals[dealId] = deal;
    }

    /// @dev производит вывод средств со сделки
    function withdraw(uint256 dealId) external {
        // берем сделку
        Deal storage deal = deals[dealId];
        require(deal.state > 0, "deal id is not exists");
        // берем количество деталей
        uint256 pointsCount = dealPointsCounts[dealId];
        require(pointsCount > 0, "deal has no points");
        // ограничение пользователя
        require(
            msg.sender == deal.owner0 || msg.sender == deal.owner1,
            "only for deal member"
        );
        // свапаем все детали
        mapping(uint256 => DealPointData) storage points = dealPoints[dealId];
        for (uint256 i = 0; i < pointsCount; ++i) {
            IDealPoint point = IDealPoint(points[i].point);
            point.withdraw();
        }
    }

    function stopEdit(uint256 dealId) external {
        Deal storage deal = deals[dealId];
        require(deal.state == 1, "only in editing state");
        require(
            msg.sender == deal.owner0 || msg.sender == deal.owner1,
            "only for owner"
        );
        ++deal.state;
    }

    /// @dev возвращает пункт сделки
    /// @param dealId id сделки
    /// @param dealPointIndex индекс пункта сделки
    function getDealPoint(uint256 dealId, uint256 dealPointIndex)
        external
        view
        returns (DealPointData memory)
    {
        return dealPoints[dealId][dealPointIndex];
    }

    /// @dev возвращает все пункты сделки
    /// @param dealId id сделки
    function getDealPoints(uint256 dealId)
        external
        view
        returns (DealPointData[] memory)
    {
        uint256 count = dealPointsCounts[dealId];
        DealPointData[] memory res = new DealPointData[](count);
        for (uint256 i = 0; i < count; ++i) res[i] = dealPoints[dealId][i];
        return res;
    }
}

import "./IFeeSettings.sol";

contract FeeSettingsDecorator is IFeeSettings {
    IFeeSettings public feeSettings;

    constructor(address feeSettingsAddress) {
        feeSettings = IFeeSettings(feeSettingsAddress);
    }

    function feeAddress() external virtual returns (address) 
    {
        return feeSettings.feeAddress();
    }

    function feePercentil() external virtual returns (uint256) 
    {
        return feeSettings.feePercentil();
    }

    function feeEth() external virtual returns (uint256)
    {
        return feeSettings.feeEth();
    }
}

import "../fee/IFeeSettings.sol";

interface ISwapper is IFeeSettings{
    /// @dev добавляет в сделку пункт договора с указанным адресом
    /// данный метод может вызывать только фабрика
    function addDealPoint(uint256 dealId, address point) external;
}

pragma solidity >=0.8.7;

import "./IDealPoint.sol";

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner0; // owner 0 - creator
    address owner1; // owner 1 - second part
}

pragma solidity >=0.8.7;

interface IDealPoint{
    function isComplete() external view returns(bool); // выполнены ли условия
    function swap() external;   // свап
    function withdraw() external payable; // выводит средства владельца
}

import "./IDealPoint.sol";

interface IDealPointFactory{
}

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

interface IFeeSettings{
    function feeAddress() external returns (address); // address to pay fee
    function feePercentil() external returns(uint256); // fee percentil for deviding values
    function feeEth() external returns(uint256); // fee value for not dividing deal points
}