// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

//import 'hardhat/console.sol';

import './IDealsController.sol';
import './plugins/erc20/IErc20DealPointsController.sol';
import './plugins/ether/IEtherDealPointsController.sol';
import './plugins/erc721/erc721item/IErc721ItemDealPointsController.sol';
import './plugins/erc721/erc721count/IErc721CountDealPointsController.sol';

struct EtherPointCreationData {
    address from;
    address to;
    uint256 count;
}
struct Erc20PointCreationData {
    address from;
    address to;
    address token;
    uint256 count;
}
struct Erc721ItemPointCreationData {
    address from;
    address to;
    address token;
    uint256 tokenId;
}
struct Erc721CountPointCreationData {
    address from;
    address to;
    address token;
    uint256 count;
}
struct DealCreationData {
    address owner2; // another owner or zero if open swap
    EtherPointCreationData[] eth; // tyoe id 1
    Erc20PointCreationData[] erc20; // type id 2
    Erc721ItemPointCreationData[] erc721Item; // type id 3
    Erc721CountPointCreationData[] erc721Count; // type id 4
}

contract DealsFactory {
    IDealsController public dealsController;
    IEtherDealPointsController public eth;
    IErc20DealPointsController public erc20;
    IErc721ItemDealPointsController public erc721Item;
    IErc721CountDealPointsController public erc721Count;

    constructor(
        IDealsController dealsController_,
        IEtherDealPointsController eth_,
        IErc20DealPointsController erc20_,
        IErc721ItemDealPointsController erc721Item_,
        IErc721CountDealPointsController erc721Count_
    ) {
        dealsController = dealsController_;
        erc20 = erc20_;
        eth = eth_;
        erc721Item = erc721Item_;
        erc721Count = erc721Count_;
    }

    function createDeal(DealCreationData calldata data) external {
        // limitation
        uint256 dealPointsCount = data.erc20.length +
            data.erc721Item.length +
            data.eth.length;
        require(dealPointsCount > 1, 'at least 2 deal points required');
        // create deal
        uint256 dealId = dealsController.createDeal(msg.sender, data.owner2);
        // create points
        for (uint256 i = 0; i < data.eth.length; ++i) {
            checkPoindAddresses(data.eth[i].from, data.eth[i].to, data.owner2);
            eth.createPoint(
                dealId,
                data.eth[i].from,
                data.eth[i].to,
                data.eth[i].count
            );
        }
        for (uint256 i = 0; i < data.erc20.length; ++i) {
            checkPoindAddresses(
                data.erc20[i].from,
                data.erc20[i].to,
                data.owner2
            );
            erc20.createPoint(
                dealId,
                data.erc20[i].from,
                data.erc20[i].to,
                data.erc20[i].token,
                data.erc20[i].count
            );
        }
        for (uint256 i = 0; i < data.erc721Item.length; ++i) {
            checkPoindAddresses(
                data.erc721Item[i].from,
                data.erc721Item[i].to,
                data.owner2
            );
            erc721Item.createPoint(
                dealId,
                data.erc721Item[i].from,
                data.erc721Item[i].to,
                data.erc721Item[i].token,
                data.erc721Item[i].tokenId
            );
        }
        for (uint256 i = 0; i < data.erc721Count.length; ++i) {
            checkPoindAddresses(
                data.erc721Count[i].from,
                data.erc721Count[i].to,
                data.owner2
            );
            erc721Count.createPoint(
                dealId,
                data.erc721Count[i].from,
                data.erc721Count[i].to,
                data.erc721Count[i].token,
                data.erc721Count[i].count
            );
        }

        // stop deal editing
        dealsController.stopDealEditing(dealId);
    }

    function checkPoindAddresses(
        address from,
        address to,
        address owner2
    ) private view {
        require(from != to, 'from equals to address');
        require(
            !(from == address(0) && to == address(0)),
            'from ant to booth equals zero address'
        );
        require(
            from == msg.sender || from == owner2,
            'from must be msg.sender address or owner2 address'
        );
        require(
            to == msg.sender || to == owner2,
            'to must be msg.sender address or owner2 address'
        );
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

import '../../IDealPointsController.sol';

interface IErc20DealPointsController is IDealPointsController {
    /// @dev creates the deal point
    /// only for factories
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external;
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

import '../../../IDealPointsController.sol';

interface IErc721ItemDealPointsController is IDealPointsController {
    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 tokenId_
    ) external;

    /// @dev token id that need to transfer
    function tokenId(uint256 pointId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IErc721CountDealPointsController {
    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external;

    /// @dev all tokens, that stores deal point
    function tokensId(uint256 pointId) external view returns (uint256[] memory);
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
    uint256 value;
    uint256 balance;
    uint256 fee;
    address tokenAddress;
    bool isSwapped;
    bool isExecuted;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external view returns (address);

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