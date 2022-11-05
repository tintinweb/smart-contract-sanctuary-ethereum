// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../swapper/DealsController.sol';
import '../fee/FeeSettingsDecorator.sol';

contract GigaSwap is DealsController, FeeSettingsDecorator {
    constructor(address feeSettingsAddress)
        FeeSettingsDecorator(feeSettingsAddress)
    {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../lib/factories/HasFactories.sol';
import './IDealsController.sol';
import './IDealPointsController.sol';
import './Deal.sol';
import './DealHeader.sol';

abstract contract DealsController is IDealsController, HasFactories {
    mapping(uint256 => DealHeader) internal _deals; // deal headers by id
    mapping(uint256 => mapping(uint256 => DealPointRef)) internal _dealPoints; // controllers for each deal point
    mapping(uint256 => uint256) internal _dealPointsCounts; // deal points counts
    mapping(address => uint256) internal _dealsCountOfAccount; // deals count by account
    mapping(address => mapping(uint256 => uint256)) internal _dealsByAccounts; // deals by accounts
    uint256 internal dealsCount;
    uint256 internal _totalDealPointsCount;

    modifier onlyEditDealState(uint256 dealId) {
        require(_deals[dealId].state == 1, 'deal is not in edit state');
        _;
    }

    modifier onlyExecutionDealState(uint256 dealId) {
        require(_deals[dealId].state == 2, 'deal is not in execution state');
        _;
    }

    function getDealsCountOfAccount(address account)
        external
        view
        returns (uint256)
    {
        return _dealsCountOfAccount[account];
    }

    function getTotalDealPointsCount() external view returns (uint256) {
        return _totalDealPointsCount;
    }

    function createDeal(address owner1, address owner2)
        external
        onlyFactory
        returns (uint256)
    {
        // create a deal
        DealHeader memory dealHeader = DealHeader(
            1, // editing
            owner1, // 1 owner
            owner2 // 2 owner
        );
        ++dealsCount;
        _deals[dealsCount] = dealHeader;
        _dealsByAccounts[owner1][_dealsCountOfAccount[owner1]++] = dealsCount;
        emit NewDeal(dealsCount, owner1);

        return dealsCount;
    }

    function addDealPoint(
        uint256 dealId,
        address dealPointsController,
        uint256 newPointId
    ) external onlyFactory onlyEditDealState(dealId) {
        uint256 pointsCount = _dealPointsCounts[dealId];
        _dealPoints[dealId][pointsCount] = DealPointRef(
            dealPointsController,
            newPointId
        );
        _dealPointsCounts[dealId] = pointsCount + 1;
        ++_totalDealPointsCount;
    }

    function getDealHeader(uint256 dealId)
        external
        view
        returns (DealHeader memory)
    {
        DealHeader memory header = _deals[dealId];
        require(header.state > 0, 'deal is not exists');
        return header;
    }

    /// @dev returns a deal, if there is no such deal, it gives an error
    function getDeal(uint256 dealId)
        external
        view
        override
        returns (Deal memory)
    {
        DealHeader storage header = _deals[dealId];
        Deal memory deal;
        deal.state = header.state;
        deal.owner1 = header.owner1;
        deal.owner2 = header.owner2;
        deal.pointsCount = this.getDealPointsCount(dealId);
        deal.points = new DealPointRef[](deal.pointsCount);
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            deal.points[i] = this.getDealPoint(dealId, i);
        }
        return deal;
    }

    function getDealByIndex(address account, uint256 dealIndex)
        external
        view
        returns (Deal memory)
    {
        return this.getDeal(this.getDealIdByIndex(account, dealIndex));
    }

    function getDealIdByIndex(address account, uint256 index)
        public
        view
        returns (uint256)
    {
        return _dealsByAccounts[account][index];
    }

    /// @dev returns the deal page for the address
    /// @param account who to get the deals on
    /// @param startIndex start index
    /// @param count how many deals to get
    /// @return how many deals are open in total, deal id, deals, number of points per deal
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
            DealHeader[] memory,
            uint256[] memory
        )
    {
        uint256 playerDealsCount = _dealsCountOfAccount[account];
        if (startIndex + count > playerDealsCount) {
            if (startIndex >= playerDealsCount)
                return (
                    playerDealsCount,
                    new uint256[](0),
                    new DealHeader[](0),
                    new uint256[](0)
                );
            count = playerDealsCount - startIndex;
        }

        uint256[] memory ids = new uint256[](count);
        DealHeader[] memory dealsResult = new DealHeader[](count);
        uint256[] memory pointsCount = new uint256[](count);

        for (uint256 i = 0; i < count; ++i) {
            uint256 id = getDealIdByIndex(account, i);
            ids[startIndex + i] = id;
            dealsResult[startIndex + i] = _deals[id];
            uint256 pc = _dealPointsCounts[id];
            pointsCount[startIndex + i] = pc;
        }

        return (playerDealsCount, ids, dealsResult, pointsCount);
    }

    /// @dev if true, then the transaction is completed and it can be swapped
    function isExecuted(uint256 dealId) external view returns (bool) {
        // get the count of deal points
        uint256 pointsCount = _dealPointsCounts[dealId];
        if (pointsCount == 0) return false;
        // take the deal points
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        // checking all deal points
        for (uint256 i = 0; i < pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            if (
                !IDealPointsController(payable(pointRef.controller)).isExecuted(
                    pointRef.id
                )
            ) return false;
        }
        return true;
    }

    function swap(uint256 dealId) external onlyExecutionDealState(dealId) {
        // take the amount of points
        uint256 pointsCount = _dealPointsCounts[dealId];
        require(pointsCount > 0, 'deal has no points');
        // check all points to be executed
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            require(
                IDealPointsController(payable(pointRef.controller)).isExecuted(
                    pointRef.id
                ),
                'there are not executed deal points'
            );
        }
        // set header as swapped
        _deals[dealId].state = 3; // deal is now swapped
        // emit event
        emit Swap(dealId);
    }

    function isSwapped(uint256 dealId) external view returns (bool) {
        return _deals[dealId].state == 3;
    }

    function withdraw(uint256 dealId) external {
        // take a deal
        DealHeader storage dealHeader = _deals[dealId];
        require(dealHeader.state > 0, 'deal id is not exists');
        // take the amount of details
        uint256 pointsCount = _dealPointsCounts[dealId];
        require(pointsCount > 0, 'deal has no points');
        // user restriction
        require(
            msg.sender == dealHeader.owner1 || msg.sender == dealHeader.owner2,
            'only for deal member'
        );
        // withdraw all the details
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            if (controller.owner(pointRef.id) == msg.sender)
                controller.withdraw(pointRef.id);
        }
    }

    function stopEdit(uint256 dealId) external {
        DealHeader storage dealHeader = _deals[dealId];
        require(dealHeader.state == 1, 'only in editing state');
        require(
            msg.sender == dealHeader.owner1 || msg.sender == dealHeader.owner2,
            'only for owner'
        );
        ++dealHeader.state;
    }

    function getDealPoint(uint256 dealId, uint256 pointIndex)
        external
        view
        returns (DealPointRef memory)
    {
        return _dealPoints[dealId][pointIndex];
    }

    function getDealPointsCount(uint256 dealId)
        external
        view
        returns (uint256)
    {
        return _dealPointsCounts[dealId];
    }

    /// @dev returns all deal points
    /// @param dealId deal id
    function getDealPoints(uint256 dealId)
        external
        view
        returns (DealPointRef[] memory)
    {
        uint256 count = _dealPointsCounts[dealId];
        DealPointRef[] memory res = new DealPointRef[](count);
        for (uint256 i = 0; i < count; ++i) res[i] = _dealPoints[dealId][i];
        return res;
    }

    function stopDealEditing(uint256 dealId)
        external
        onlyFactory
        onlyEditDealState(dealId)
    {
        _deals[dealId].state = 2;
    }

    function execute(uint256 dealId) external payable {
        // if it is openswap - set owner
        DealHeader storage header = _deals[dealId];
        bool isOpenSwapNotOwner;
        if (header.owner2 == address(0) && msg.sender != header.owner1) {
            header.owner2 = msg.sender;
            isOpenSwapNotOwner = true;
        }

        // take the amount of points
        uint256 pointsCount = _dealPointsCounts[dealId];
        require(pointsCount > 0, 'deal has no points');
        // check all points to be executed
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            address from = controller.from(pointRef.id);
            if (
                controller.to(pointRef.id) == address(0) && isOpenSwapNotOwner
            ) {
                controller.setTo(pointRef.id, msg.sender);
                continue;
            }
            if (
                from == msg.sender || (from == address(0) && isOpenSwapNotOwner)
            ) controller.execute{ value: msg.value }(pointRef.id, msg.sender);
        }
        // emit event
        emit Execute(dealId, msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IFeeSettings.sol';

contract FeeSettingsDecorator is IFeeSettings {
    IFeeSettings public feeSettings;

    constructor(address feeSettingsAddress) {
        feeSettings = IFeeSettings(feeSettingsAddress);
    }

    function feeAddress() external virtual returns (address) {
        return feeSettings.feeAddress();
    }

    function feePercent() external virtual returns (uint256) {
        return feeSettings.feePercent();
    }

    function feeDecimals() external view returns(uint256){
        return feeSettings.feeDecimals();
    }

    function feeEth() external virtual returns (uint256) {
        return feeSettings.feeEth();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../ownable/Ownable.sol';
import './IHasFactories.sol';

contract HasFactories is Ownable, IHasFactories {
    mapping(address => bool) internal _factories; // factories

    modifier onlyFactory() {
        require(_factories[msg.sender], 'only for factories');
        _;
    }

    function isFactory(address addr) external view returns (bool) {
        return _factories[addr];
    }

    function addFactory(address factory) external onlyOwner {
        _factories[factory] = true;
    }

    function removeFactory(address factory) external onlyOwner {
        _factories[factory] = false;
    }

    function setFactories(address[] calldata addresses, bool isFactory_)
        external
        onlyOwner
    {
        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; ++i) {
            _factories[addresses[i]] = isFactory_;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../fee/IFeeSettings.sol';
import '../lib/factories/IHasFactories.sol';
import './Deal.sol';
import './DealHeader.sol';
import './DealPointRef.sol';

interface IDealsController is IFeeSettings, IHasFactories {
    /// @dev new deal created
    /// deals are creates by factories by one transaction, therefore another events, such as deal point adding is no need
    event NewDeal(uint256 indexed dealId, address indexed creator);
    /// @dev the deal is swapped
    event Swap(uint256 indexed dealId);
    /// @dev the deal is executed by account
    event Execute(uint256 indexed dealId, address account);

    /// @dev swap the deal
    function swap(uint256 dealId) external;

    /// @dev if true, than deal is swapped
    function isSwapped(uint256 dealId) external view returns (bool);

    /// @dev total deal points count
    function getTotalDealPointsCount() external view returns (uint256);

    /// @dev deals count of a particular account
    function getDealsCountOfAccount(address account)
        external
        view
        returns (uint256);

    /// @dev creates the deal.
    /// Only for factories.
    /// @param owner1 - first owner (creator)
    /// @param owner2 - second owner of deal. If zero than deal is open for any account
    /// @return id of new deal
    function createDeal(address owner1, address owner2)
        external
        returns (uint256);

    /// @dev returns all deal information
    function getDeal(uint256 dealId) external view returns (Deal memory);

    /// @dev dets deal by index for particular acctount
    function getDealByIndex(address account, uint256 dealIndex)
        external
        view
        returns (Deal memory);

    /// @dev returns the deals header information (without points)
    function getDealHeader(uint256 dealId)
        external
        view
        returns (DealHeader memory);

    /// @dev adds the deal point to deal.
    /// only for factories
    /// @param dealId deal id
    function addDealPoint(
        uint256 dealId,
        address dealPointsController,
        uint256 newPointId
    ) external;

    /// @dev returns deal point by its index in deal
    function getDealPoint(uint256 dealId, uint256 pointIndex)
        external
        view
        returns (DealPointRef memory);

    /// @dev returns deal points count for the deal
    function getDealPointsCount(uint256 dealId) external view returns (uint256);

    /// @dev returns true, if all deal points is executed, and can be made swap, if not swapped already
    function isExecuted(uint256 dealId) external view returns (bool);

    /// @dev makes withdraw from all deal points of deal, where caller is owner
    function withdraw(uint256 dealId) external;

    /// @dev stops all editing for deal
    /// only for factories
    function stopDealEditing(uint256 dealId) external;

    /// @dev executes all points of the deal
    function execute(uint256 dealId) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IDealPointsController {
    receive() external payable;

    /// @dev returns deal id for deal point or 0 if point is not exists in this controller
    function dealId(uint256 pointId) external view returns (uint256);

    /// @dev token contract address, that need to be transferred or zero
    function tokenAddress(uint256 pointId) external view returns (address);

    /// @dev from
    /// zero address - for open swap
    function from(uint256 pointId) external view returns (address);

    /// @dev to
    function to(uint256 pointId) external view returns (address);

    /// @dev sets to account for point
    /// only DealsController and only once
    function setTo(uint256 pointId, address account) external;

    /// @dev asset count, needs to execute deal point
    function count(uint256 pointId) external view returns (uint256);

    /// @dev balance of the deal point
    function balance(uint256 pointId) external view returns (uint256);

    /// @dev deal point fee. In ether or token. Only if withdraw after deal is swapped
    function fee(uint256 pointId) external view returns (uint256);

    /// @dev current owner of deal point
    /// zero address - for open deals, before execution
    function owner(uint256 pointId) external view returns (address);

    /// @dev deals controller
    function dealsController() external view returns (address);

    /// @dev if true, than deal is swapped
    function isSwapped(uint256 pointId) external view returns (bool);

    /// @dev if true, than point is executed and can be swaped
    function isExecuted(uint256 pointId) external view returns (bool);

    /// @dev executes the point, by using address
    /// if already executed than nothing happens
    function execute(uint256 pointId, address addr) external payable;

    /// @dev withdraw the asset from deal point
    function withdraw(uint256 pointId) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './DealHeader.sol';
import './DealPointRef.sol';

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner1; // owner 1 - creator
    address owner2; // owner 2 - second part if zero than it is open deal
    uint256 pointsCount;
    DealPointRef[] points;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealHeader {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner1; // owner 1 - creator
    address owner2; // owner 2 - second part if zero than it is open deal
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IOwnable.sol';

contract Ownable is IOwnable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../ownable/IOwnable.sol';

interface IHasFactories is IOwnable {
    /// @dev returns true, if addres is factory
    function isFactory(address addr) external view returns (bool);

    /// @dev mark address as factory (only owner)
    function addFactory(address factory) external;

    /// @dev mark address as not factory (only owner)
    function removeFactory(address factory) external;

    /// @dev mark addresses as factory or not (only owner)
    function setFactories(address[] calldata addresses, bool isFactory_)
        external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealPointRef {
    /// @dev controller of deal point
    address controller;
    /// @dev id of the deal point
    uint256 id;
}