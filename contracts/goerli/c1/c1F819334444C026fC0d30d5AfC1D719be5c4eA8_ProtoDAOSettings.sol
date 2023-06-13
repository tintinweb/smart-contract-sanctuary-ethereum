// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IProtoDAOSettings} from "./IProtoDAOSettings.sol";
import {ProtoDAOSettingsReadable} from "./ProtoDAOSettingsReadable.sol";
import {ProtoDAOSettingsWritable} from "./ProtoDAOSettingsWritable.sol";

contract ProtoDAOSettings is IProtoDAOSettings, ProtoDAOSettingsReadable, ProtoDAOSettingsWritable {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IProtoDAOSettingsReadable} from "./IProtoDAOSettingsReadable.sol";
import {IProtoDAOSettingsWritable} from "./IProtoDAOSettingsWritable.sol";

interface IProtoDAOSettings is IProtoDAOSettingsReadable, IProtoDAOSettingsWritable {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ProtoDAOSettingsBaseStorage.sol";
import "./IProtoDAOSettingsReadable.sol";

import "../D4ASettings/D4ASettingsBaseStorage.sol";

contract ProtoDAOSettingsReadable is IProtoDAOSettingsReadable {
    function getCanvasCreatorERC20Ratio(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];
        if (di.canvasCreatorERC20Ratio == 0 && di.nftMinterERC20Ratio == 0) {
            return D4ASettingsBaseStorage.layout().canvas_erc20_ratio;
        }
        return di.canvasCreatorERC20Ratio;
    }

    function getNftMinterERC20Ratio(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];
        if (di.canvasCreatorERC20Ratio == 0 && di.nftMinterERC20Ratio == 0) {
            return 0;
        }
        return di.nftMinterERC20Ratio;
    }

    function getDaoFeePoolETHRatio(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];
        if (di.daoFeePoolETHRatio == 0) {
            return D4ASettingsBaseStorage.layout().mint_project_fee_ratio;
        }
        return di.daoFeePoolETHRatio;
    }

    function getDaoFeePoolETHRatioFlatPrice(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];

        if (di.daoFeePoolETHRatioFlatPrice == 0) {
            return D4ASettingsBaseStorage.layout().mint_project_fee_ratio_flat_price;
        }
        return di.daoFeePoolETHRatioFlatPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IProtoDAOSettingsWritable} from "./IProtoDAOSettingsWritable.sol";
import "./ProtoDAOSettingsBaseStorage.sol";
import "./ProtoDAOSettingsReadable.sol";
import "../D4ASettings/D4ASettingsBaseStorage.sol";
import {NotDaoOwner, InvalidERC20Ratio, InvalidETHRatio} from "contracts/interface/D4AErrors.sol";

contract ProtoDAOSettingsWritable is IProtoDAOSettingsWritable {
    function setRatio(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    ) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId) && msg.sender != l.project_proxy) revert NotDaoOwner();
        if (canvasCreatorERC20Ratio + nftMinterERC20Ratio + l.project_erc20_ratio + l.d4a_erc20_ratio != l.ratio_base) {
            revert InvalidERC20Ratio();
        }
        uint256 ratioBase = l.ratio_base;
        uint256 d4aETHRatio = l.mint_d4a_fee_ratio;
        if (daoFeePoolETHRatioFlatPrice > ratioBase - d4aETHRatio || daoFeePoolETHRatio > daoFeePoolETHRatioFlatPrice) {
            revert InvalidETHRatio();
        }

        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[daoId];
        di.canvasCreatorERC20Ratio = canvasCreatorERC20Ratio;
        di.nftMinterERC20Ratio = nftMinterERC20Ratio;
        di.daoFeePoolETHRatio = daoFeePoolETHRatio;
        di.daoFeePoolETHRatioFlatPrice = daoFeePoolETHRatioFlatPrice;

        emit DaoRatioSet(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IProtoDAOSettingsReadable {
    function getCanvasCreatorERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getNftMinterERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IProtoDAOSettingsWritable {
    event DaoRatioSet(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    );

    function setRatio(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

library ProtoDAOSettingsBaseStorage {
    struct DaoInfo {
        uint256 canvasCreatorERC20Ratio;
        uint256 nftMinterERC20Ratio;
        uint256 daoFeePoolETHRatio;
        uint256 daoFeePoolETHRatioFlatPrice;
        bool newDAO;
    }

    struct Layout {
        mapping(bytes32 daoId => DaoInfo) allDaos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("ProtoDAO.contracts.storage.Setting");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import {ID4ADrb} from "../interface/ID4ADrb.sol";
import "../interface/ID4AFeePoolFactory.sol";
import "../interface/ID4AERC20Factory.sol";
import "../interface/ID4AOwnerProxy.sol";
import "../interface/ID4AERC721.sol";
import "../interface/ID4AERC721Factory.sol";
import "../interface/IPermissionControl.sol";

interface ID4AProtocolForSetting {
    function getCanvasProject(bytes32 _canvas_id) external view returns (bytes32);
}

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library D4ASettingsBaseStorage {
    struct Layout {
        uint256 ratio_base;
        uint256 min_stamp_duty; //TODO
        uint256 max_stamp_duty;
        uint256 create_project_fee;
        address protocol_fee_pool;
        uint256 create_canvas_fee;
        uint256 mint_d4a_fee_ratio;
        uint256 trade_d4a_fee_ratio;
        uint256 mint_project_fee_ratio;
        uint256 mint_project_fee_ratio_flat_price;
        uint256 erc20_total_supply;
        uint256 project_max_rounds; //366
        uint256 project_erc20_ratio;
        uint256 canvas_erc20_ratio;
        uint256 d4a_erc20_ratio;
        uint256 rf_lower_bound;
        uint256 rf_upper_bound;
        uint256[] floor_prices;
        uint256[] max_nft_amounts;
        ID4ADrb drb;
        string erc20_name_prefix;
        string erc20_symbol_prefix;
        ID4AERC721Factory erc721_factory;
        ID4AERC20Factory erc20_factory;
        ID4AFeePoolFactory feepool_factory;
        ID4AOwnerProxy owner_proxy;
        //ID4AProtocolForSetting protocol;
        IPermissionControl permission_control;
        address asset_pool_owner;
        bool d4a_pause;
        mapping(bytes32 => bool) pause_status;
        address project_proxy;
        uint256 reserved_slots;
        uint256 defaultNftPriceMultiplyFactor;
        bool initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4A.contracts.storage.Setting");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error NotDaoOwner();

error InvalidERC20Ratio();

error InvalidETHRatio();

error UnauthorizedToExchangeRoyaltyTokenToETH();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ID4ADrb {
    event CheckpointSet(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18);

    function getCheckpointsLength() external view returns (uint256);

    function getStartBlock(uint256 drb) external view returns (uint256);

    function getDrb(uint256 blockNumber) external view returns (uint256);

    function currentRound() external view returns (uint256);

    function setNewCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;

    function modifyLastCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AFeePoolFactory {
    function createD4AFeePool(string memory _name) external returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC20Factory {
    function createD4AERC20(string memory _name, string memory _symbol, address _minter) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AOwnerProxy {
    function ownerOf(bytes32 hash) external view returns (address);
    function initOwnerOf(bytes32 hash, address addr) external returns (bool);
    function transferOwnership(bytes32 hash, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721 {
    function mintItem(address player, string memory tokenURI) external returns (uint256);

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721Factory {
    function createD4AERC721(string memory _name, string memory _symbol) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./ID4AOwnerProxy.sol";

interface IPermissionControl {
    struct Blacklist {
        address[] minterAccounts;
        address[] canvasCreatorAccounts;
    }

    struct Whitelist {
        bytes32 minterMerkleRoot;
        address[] minterNFTHolderPasses;
        bytes32 canvasCreatorMerkleRoot;
        address[] canvasCreatorNFTHolderPasses;
    }

    event MinterBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorBlacklisted(bytes32 indexed daoId, address indexed account);

    event MinterUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event WhitelistModified(bytes32 indexed daoId, Whitelist whitelist);

    function getWhitelist(bytes32 daoId) external view returns (Whitelist calldata whitelist);

    function addPermissionWithSignature(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        bytes calldata signature
    ) external;

    function addPermission(bytes32 daoId, Whitelist calldata whitelist, Blacklist calldata blacklist) external;

    function modifyPermission(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        Blacklist calldata unblacklist
    ) external;

    function isMinterBlacklisted(bytes32 daoId, address _account) external view returns (bool);

    function isCanvasCreatorBlacklisted(bytes32 daoId, address _account) external view returns (bool);

    function inMinterWhitelist(bytes32 daoId, address _account, bytes32[] calldata _proof)
        external
        view
        returns (bool);

    function inCanvasCreatorWhitelist(bytes32 daoId, address _account, bytes32[] calldata _proof)
        external
        view
        returns (bool);

    function setOwnerProxy(ID4AOwnerProxy _ownerProxy) external;
}