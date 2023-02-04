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
import './DealPointRef.sol';
import './DealPointData.sol';

abstract contract DealsController is IDealsController, HasFactories {
    mapping(uint256 => Deal) internal _deals; // deal headers by id
    mapping(uint256 => mapping(uint256 => DealPointRef)) internal _dealPoints; // controllers for each deal point
    uint256 internal _dealsCount;
    uint256 internal _totalDealPointsCount;
    uint256 constant dealPointsLimit = 20;

    modifier onlyEditDealState(uint256 dealId) {
        require(_deals[dealId].state == 1, 'deal is not in edit state');
        _;
    }

    modifier onlyExecutionDealState(uint256 dealId) {
        require(_deals[dealId].state == 2, 'deal is not in execution state');
        _;
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
        Deal memory dealHeader = Deal(
            1, // editing
            owner1, // 1 owner
            owner2, // 2 owner
            0
        );
        ++_dealsCount;
        _deals[_dealsCount] = dealHeader;
        emit NewDeal(_dealsCount, owner1);

        return _dealsCount;
    }

    function addDealPoint(
        uint256 dealId,
        address dealPointsController,
        uint256 newPointId
    ) external onlyFactory onlyEditDealState(dealId) {
        Deal storage deal = _deals[dealId];
        require(deal.state == 1, 'only for editing deal state');
        _dealPoints[dealId][deal.pointsCount] = DealPointRef(
            dealPointsController,
            newPointId
        );
        ++deal.pointsCount;
        require(
            deal.pointsCount <= dealPointsLimit,
            'deal points count exceeds of limit'
        );
        ++_totalDealPointsCount;
    }

    function getDealHeader(uint256 dealId) external view returns (Deal memory) {
        Deal memory header = _deals[dealId];
        require(header.state > 0, 'deal is not exists');
        return header;
    }

    /// @dev returns a deal, if there is no such deal, it gives an error
    function getDeal(uint256 dealId)
        external
        view
        override
        returns (Deal memory, DealPointData[] memory)
    {
        Deal memory deal = _deals[dealId];
        DealPointData[] memory points = new DealPointData[](deal.pointsCount);
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            points[i] = this.getDealPoint(dealId, i);
        }
        return (deal, points);
    }

    /// @dev if true, then the transaction is completed and it can be swapped
    function isExecuted(uint256 dealId) external view returns (bool) {
        // get the count of deal points
        Deal memory deal = _deals[dealId];
        if (deal.pointsCount == 0) return false;
        // take the deal points
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        // checking all deal points
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
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
        Deal storage deal = _deals[dealId];
        require(deal.pointsCount > 0, 'deal has no points');
        // check all points to be executed
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            require(
                IDealPointsController(payable(pointRef.controller)).isExecuted(
                    pointRef.id
                ),
                'there are not executed deal points'
            );
        }
        // set header as swapped
        deal.state = 3; // deal is now swapped
        // emit event
        emit Swap(dealId);
    }

    function isSwapped(uint256 dealId) external view returns (bool) {
        return _deals[dealId].state == 3;
    }

    function withdraw(uint256 dealId) external payable {
        // take a deal
        Deal storage deal = _deals[dealId];
        require(deal.state > 0, 'deal id is not exists');
        require(deal.pointsCount > 0, 'deal has no points');
        // user restriction
        require(
            msg.sender == deal.owner1 || msg.sender == deal.owner2,
            'only for deal member'
        );
        // withdraw all the details
        uint256 dif = msg.value;
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            if (controller.owner(pointRef.id) == msg.sender) {
                if (deal.state == 3 && controller.feeIsEthOnWithdraw()) {
                    uint256 v = controller.fee(pointRef.id);
                    controller.withdraw{ value: v }(pointRef.id);
                    dif -= v;
                } else {
                    controller.withdraw(pointRef.id);
                }
            }
        }

        if (dif > 0) {
            (bool sent, ) = payable(msg.sender).call{ value: dif }('');
            require(sent, 'sent ether error: ether is not sent');
        }

        // emit deal not executed (if not swapped)
        if (deal.state != 3) emit Execute(dealId, msg.sender, false);

        // emit event
        emit OnWithdraw(dealId, msg.sender);
    }

    function feeEthOnWithdraw(uint256 dealId, uint256 ownerNumber)
        external
        view
        returns (uint256)
    {
        uint256 fee;
        Deal storage deal = _deals[dealId];
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            if (ownerNumber == 1) {
                if (controller.owner(pointRef.id) == deal.owner1) {
                    if (controller.feeIsEthOnWithdraw())
                        fee += controller.fee(pointRef.id);
                }
            } else if (ownerNumber == 2) {
                if (controller.owner(pointRef.id) == deal.owner2) {
                    if (controller.feeIsEthOnWithdraw())
                        fee += controller.fee(pointRef.id);
                }
            }
        }
        return fee;
    }

    function getDealPoint(uint256 dealId, uint256 pointIndex)
        external
        view
        returns (DealPointData memory)
    {
        DealPointRef storage ref = _dealPoints[dealId][pointIndex];
        IDealPointsController controller = IDealPointsController(
            payable(ref.controller)
        );
        return
            DealPointData(
                ref.controller,
                ref.id,
                controller.dealPointTypeId(),
                dealId,
                controller.from(ref.id),
                controller.to(ref.id),
                controller.owner(ref.id),
                controller.value(ref.id),
                controller.balance(ref.id),
                controller.fee(ref.id),
                controller.tokenAddress(ref.id),
                controller.isSwapped(ref.id),
                controller.isExecuted(ref.id)
            );
    }

    function getDealPointsCount(uint256 dealId)
        external
        view
        returns (uint256)
    {
        return _deals[dealId].pointsCount;
    }

    /// @dev returns all deal points
    /// @param dealId deal id
    function getDealPoints(uint256 dealId)
        external
        view
        returns (DealPointRef[] memory)
    {
        Deal memory deal = _deals[dealId];
        DealPointRef[] memory res = new DealPointRef[](deal.pointsCount);
        for (uint256 i = 0; i < deal.pointsCount; ++i)
            res[i] = _dealPoints[dealId][i];
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
        Deal storage deal = _deals[dealId];
        require(deal.state == 2, 'only executing state');
        bool isOpenSwapNotOwner;
        if (deal.owner2 == address(0) && msg.sender != deal.owner1) {
            deal.owner2 = msg.sender;
            isOpenSwapNotOwner = true;
        }

        // take the amount of points
        require(deal.pointsCount > 0, 'deal has no points');
        // check all points to be executed
        uint256 dif = msg.value;
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
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
            ) {
                uint256 v = controller.executeEtherValue(pointRef.id);
                controller.execute{ value: v }(pointRef.id, msg.sender);
                dif -= v;
            }
        }

        if (dif > 0) {
            (bool sent, ) = payable(msg.sender).call{ value: dif }('');
            require(sent, 'sent ether error: ether is not sent');
        }

        // emit event
        emit Execute(dealId, msg.sender, true);
    }

    function executeEtherValue(uint256 dealId, uint256 ownerNumber)
        external
        view
        returns (uint256)
    {
        uint256 value;
        Deal storage deal = _deals[dealId];
        mapping(uint256 => DealPointRef) storage points = _dealPoints[dealId];
        for (uint256 i = 0; i < deal.pointsCount; ++i) {
            DealPointRef memory pointRef = points[i];
            IDealPointsController controller = IDealPointsController(
                payable(pointRef.controller)
            );
            if (ownerNumber == 1) {
                if (controller.owner(pointRef.id) == deal.owner1) {
                    value += controller.executeEtherValue(pointRef.id);
                }
            } else if (ownerNumber == 2) {
                if (controller.owner(pointRef.id) == deal.owner2) {
                    value += controller.executeEtherValue(pointRef.id);
                }
            }
        }
        return value;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IFeeSettings.sol';

contract FeeSettingsDecorator is IFeeSettings {
    IFeeSettings public immutable feeSettings;

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
        require(_isFactory(msg.sender), 'only for factories');
        _;
    }

    function isFactory(address addr) external view returns (bool) {
        return _isFactory(addr);
    }

    function _isFactory(address addr) internal view returns (bool) {
        if (addr == address(this)) return true;
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
import './DealPointData.sol';

interface IDealsController is IFeeSettings, IHasFactories {
    /// @dev new deal created
    /// deals are creates by factories by one transaction, therefore another events, such as deal point adding is no need
    event NewDeal(uint256 indexed dealId, address indexed creator);
    /// @dev the deal is swapped
    event Swap(uint256 indexed dealId);
    /// @dev the deal is executed by account
    event Execute(uint256 indexed dealId, address account, bool executed);
    /// @dev the deal withdraw
    event OnWithdraw(uint256 indexed dealId, address indexed account);

    /// @dev swap the deal
    function swap(uint256 dealId) external;

    /// @dev if true, than deal is swapped
    function isSwapped(uint256 dealId) external view returns (bool);

    /// @dev total deal points count
    function getTotalDealPointsCount() external view returns (uint256);

    /// @dev creates the deal.
    /// Only for factories.
    /// @param owner1 - first owner (creator)
    /// @param owner2 - second owner of deal. If zero than deal is open for any account
    /// @return id of new deal
    function createDeal(address owner1, address owner2)
        external
        returns (uint256);

    /// @dev returns all deal information
    function getDeal(uint256 dealId)
        external
        view
        returns (Deal memory, DealPointData[] memory);

    /// @dev returns the deals header information (without points)
    function getDealHeader(uint256 dealId) external view returns (Deal memory);

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
        returns (DealPointData memory);

    /// @dev returns deal points count for the deal
    function getDealPointsCount(uint256 dealId) external view returns (uint256);

    /// @dev returns true, if all deal points is executed, and can be made swap, if not swapped already
    function isExecuted(uint256 dealId) external view returns (bool);

    /// @dev makes withdraw from all deal points of deal, where caller is owner
    function withdraw(uint256 dealId) external payable;

    /// @dev stops all editing for deal
    /// only for factories
    function stopDealEditing(uint256 dealId) external;

    /// @dev executes all points of the deal
    function execute(uint256 dealId) external payable;

    /// @dev the execute ether value for owner with number
    function executeEtherValue(uint256 dealId, uint256 ownerNumber) external view returns(uint256);

    /// @dev returns fee in ether on withdraw for owner number
    function feeEthOnWithdraw(uint256 dealId, uint256 ownerNumber)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IDealPointsController {
    receive() external payable;

    /// @dev returns type id of dealpoints
    /// 1 - eth
    /// 2 - erc20
    /// 3 erc721 item
    /// 4 erc721 count
    function dealPointTypeId() external pure returns (uint256);

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

    /// @dev asset value (count or nft id), needs to execute deal point
    function value(uint256 pointId) external view returns (uint256);

    /// @dev balance of the deal point
    function balance(uint256 pointId) external view returns (uint256);

    /// @dev deal point fee. In ether or token. Only if withdraw after deal is swapped
    function fee(uint256 pointId) external view returns (uint256);

    /// @dev if true, than fee is ether, that sends on withdraw after swapped
    function feeIsEthOnWithdraw() external pure returns (bool);

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

    /// @dev the execute ether value for owner with number
    function executeEtherValue(uint256 pointId) external view returns(uint256);

    /// @dev withdraw the asset from deal point
    /// only deals controller
    function withdraw(uint256 pointId) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './DealPointRef.sol';

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner1; // owner 1 - creator
    address owner2; // owner 2 - second part if zero than it is open deal
    uint256 pointsCount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealPointRef {
    /// @dev controller of deal point
    address controller;
    /// @dev id of the deal point
    uint256 id;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealPointData {
    address controller;
    uint256 id;
    /// @dev deal point id
    /// 1 - eth
    /// 2 - erc20
    /// 3 erc721 item
    /// 4 erc721 count
    uint256 dealPointTypeId;
    uint256 dealId;
    address from;
    address to;
    address owner;
    uint256 value;
    uint256 balance;
    uint256 fee;
    address tokenAddress;
    bool isSwapped;
    bool isExecuted;
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

    function owner() external virtual view returns (address) {
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
    function owner() external view returns (address);

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