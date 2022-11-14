// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../DealPointsController.sol';
import './IEtherDealPointsController.sol';

contract EtherDealPointsController is
    DealPointsController,
    IEtherDealPointsController
{
    constructor(address dealsController_)
        DealPointsController(dealsController_)
    {}

    function dealPointTypeId() external pure returns (uint256) {
        return 1;
    }

    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        uint256 count_
    ) external onlyFactory {
        uint256 pointId = _dealsController.getTotalDealPointsCount() + 1;
        _dealId[pointId] = dealId_;
        _from[pointId] = from_;
        _to[pointId] = to_;
        _count[pointId] = count_;
        _dealsController.addDealPoint(dealId_, address(this), pointId);
    }

    function _execute(uint256 pointId, address) internal virtual override {
        // transfer
        uint256 count = _count[pointId];
        require(msg.value >= count, 'not enough eth');
        payable(address(this)).transfer(count);
        _balances[pointId] = count;

        // calculate fee
        _fee[pointId] =
            (count * _dealsController.feePercent()) /
            _dealsController.feeDecimals();
    }

    function _withdraw(uint256 pointId, address withdrawAddr)
        internal
        virtual
        override
    {
        uint256 pointBalance = _balances[pointId];
        uint256 pointFee = _fee[pointId];
        if (!this.isSwapped(pointId)) pointFee = 0;
        uint256 toTransfer = pointBalance - pointFee;
        if (pointFee > 0)
            payable(_dealsController.feeAddress()).transfer(pointFee);
        payable(withdrawAddr).transfer(toTransfer);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IDealPointsController.sol';
import './IDealsController.sol';

abstract contract DealPointsController is IDealPointsController {
    IDealsController internal _dealsController;
    mapping(uint256 => uint256) internal _dealId;
    mapping(uint256 => address) internal _tokenAddress;
    mapping(uint256 => address) internal _from;
    mapping(uint256 => address) internal _to;
    mapping(uint256 => uint256) internal _count;
    mapping(uint256 => uint256) internal _balances;
    mapping(uint256 => uint256) internal _fee;
    mapping(uint256 => bool) internal _isExecuted;

    constructor(address dealsController_) {
        _dealsController = IDealsController(dealsController_);
    }

    receive() external payable {}

    modifier onlyDealsController() {
        require(
            address(_dealsController) == msg.sender,
            'only deals controller can call this function'
        );
        _;
    }

    modifier onlyFactory() {
        require(
            _dealsController.isFactory(msg.sender),
            'only factory can call this function'
        );
        _;
    }

    function isSwapped(uint256 pointId) external view returns (bool) {
        return _dealsController.isSwapped(_dealId[pointId]);
    }

    function isExecuted(uint256 pointId) external view returns (bool) {
        return _isExecuted[pointId];
    }

    function dealId(uint256 pointId) external view returns (uint256) {
        return _dealId[pointId];
    }

    function from(uint256 pointId) external view returns (address) {
        return _from[pointId];
    }

    function to(uint256 pointId) external view returns (address) {
        return _to[pointId];
    }

    function setTo(uint256 pointId, address account)
        external
        onlyDealsController
    {
        require(
            _to[pointId] == address(0),
            'to can be setted only once for deal point'
        );
        _to[pointId] = account;
    }

    function tokenAddress(uint256 pointId) external view returns (address) {
        return _tokenAddress[pointId];
    }

    function count(uint256 pointId) external view returns (uint256) {
        return _count[pointId];
    }

    function balance(uint256 pointId) external view returns (uint256) {
        return _balances[pointId];
    }

    function fee(uint256 pointId) external view returns (uint256) {
        return _fee[pointId];
    }

    function owner(uint256 pointId) external view returns (address) {
        return this.isSwapped(pointId) ? this.to(pointId) : this.from(pointId);
    }

    function dealsController() external view returns (address) {
        return address(_dealsController);
    }

    function withdraw(uint256 pointId) external payable onlyDealsController {
        address ownerAddr = this.owner(pointId);
        require(_balances[pointId] > 0, 'has no balance to withdraw');
        require(
            address(_dealsController) == msg.sender || ownerAddr == msg.sender,
            'only owner or deals controller can withdraw'
        );
        _withdraw(pointId, ownerAddr);
        _balances[pointId] = 0;
        if (ownerAddr == _from[pointId]) _isExecuted[pointId] = false;
    }

    function execute(uint256 pointId, address addr)
        external
        payable
        onlyDealsController
    {
        if (_isExecuted[pointId]) return;
        if (_from[pointId] == address(0)) _from[pointId] = addr;
        //else if (_to[pointId] == address(0)) _to[pointId] = addr;
        _execute(pointId, addr);
        _isExecuted[pointId] = true;
    }

    function _execute(uint256 pointId, address from) internal virtual;

    function _withdraw(uint256 pointId, address withdrawAddr) internal virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../IDealPointsController.sol';

interface IEtherDealPointsController is IDealPointsController {
    /// @dev creates the deal point
    /// only for factories
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        uint256 count_
    ) external;
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
    function getDeal(uint256 dealId)
        external
        view
        returns (Deal memory, DealPointData[] memory);

    /// @dev dets deal by index for particular acctount
    function getDealByIndex(address account, uint256 dealIndex)
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
    function withdraw(uint256 dealId) external;

    /// @dev stops all editing for deal
    /// only for factories
    function stopDealEditing(uint256 dealId) external;

    /// @dev executes all points of the deal
    function execute(uint256 dealId) external payable;
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

import './DealPointRef.sol';

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner1; // owner 1 - creator
    address owner2; // owner 2 - second part if zero than it is open deal
    uint256 pointsCount;
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
    uint256 count;
    uint256 balance;
    uint256 fee;
    address tokenAddress;
    bool isSwapped;
    bool isExecuted;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealPointRef {
    /// @dev controller of deal point
    address controller;
    /// @dev id of the deal point
    uint256 id;
}