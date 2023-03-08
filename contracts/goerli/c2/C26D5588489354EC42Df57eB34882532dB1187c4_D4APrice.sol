// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../interface/ID4ASetting.sol";

library D4APrice {
    struct last_price {
        uint256 round;
        uint256 value;
    }

    struct project_price_info {
        last_price max_price;
        uint256 price_rank;
        uint256[] price_slots;
        mapping(bytes32 => last_price) canvas_price;
    }

    function getCanvasLastPrice(
        mapping(bytes32 => project_price_info) storage all_prices,
        bytes32 _project_id,
        bytes32 _canvas_id
    ) public view returns (uint256 round, uint256 value) {
        last_price storage lp = all_prices[_project_id].canvas_price[_canvas_id];
        round = lp.round;
        value = lp.value;
    }

    function getCanvasNextPrice(
        mapping(bytes32 => project_price_info) storage all_prices,
        ID4ASetting _settings,
        uint256[] memory price_slots,
        uint256 price_rank,
        uint256 start_prb,
        bytes32 _project_id,
        bytes32 _canvas_id
    ) internal view returns (uint256 price) {
        uint256 floor_price = price_slots[price_rank];
        project_price_info storage ppi = all_prices[_project_id];
        ID4APRB prb = _settings.PRB();
        uint256 cur_round = prb.currentRound();
        if (ppi.max_price.round == 0) {
            if (cur_round == start_prb) return floor_price;
            else return floor_price / 2;
        }
        uint256 first_guess = _get_price_in_round(ppi.canvas_price[_canvas_id], cur_round);
        if (first_guess >= floor_price) {
            return first_guess;
        }
        /*if(ppi.canvas_price[_canvas_id].round == cur_round ||
      ppi.canvas_price[_canvas_id].round +1 == cur_round){
      return floor_price;
    }*/

        first_guess = _get_price_in_round(ppi.max_price, cur_round);
        if (first_guess >= floor_price) {
            return floor_price;
        }
        if (ppi.max_price.value == floor_price / 2 && cur_round <= ppi.max_price.round + 1) {
            return floor_price;
        }

        return floor_price / 2;
    }

    function updateCanvasPrice(
        mapping(bytes32 => project_price_info) storage all_prices,
        ID4ASetting _settings,
        bytes32 _project_id,
        bytes32 _canvas_id,
        uint256 price
    ) internal {
        project_price_info storage ppi = all_prices[_project_id];
        ID4APRB prb = _settings.PRB();
        uint256 cp = 0;
        {
            uint256 cur_round = prb.currentRound();
            cp = _get_price_in_round(ppi.max_price, cur_round);
        }
        if (price >= cp) {
            ppi.max_price.round = prb.currentRound();
            ppi.max_price.value = price;
        }

        ppi.canvas_price[_canvas_id].round = prb.currentRound();
        ppi.canvas_price[_canvas_id].value = price;
    }

    function _get_price_in_round(last_price memory lp, uint256 round) internal pure returns (uint256) {
        if (round == lp.round) {
            return lp.value << 1;
        }
        uint256 k = round - lp.round - 1;
        return lp.value >> k;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.10;

import "./ID4AOwnerProxy.sol";

interface IPermissionControl {
    struct Blacklist {
        address[] minterAccounts;
        address[] canvasCreatorAccounts;
    }

    struct Whitelist {
        bytes32 minterMerkleRoot;
        address minterNFTHolderPass;
        bytes32 canvasCreatorMerkleRoot;
        address canvasCreatorNFTHolderPass;
    }

    event MinterBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorBlacklisted(bytes32 indexed daoId, address indexed account);

    event MinterUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event WhitelistModified(bytes32 indexed daoId, Whitelist whitelist);

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./ID4APRB.sol";
import "./ID4AFeePoolFactory.sol";
import "./ID4AERC20Factory.sol";
import "./ID4AOwnerProxy.sol";
import "./ID4AERC721.sol";
import "./ID4AERC721Factory.sol";
import "./IPermissionControl.sol";

interface ID4AProtocolForSetting {
    function getCanvasProject(bytes32 _canvas_id) external view returns (bytes32);
}

contract ID4ASetting {
    uint256 public ratio_base;
    uint256 public min_stamp_duty; //TODO
    uint256 public max_stamp_duty;

    uint256 public create_project_fee;
    address public protocol_fee_pool;
    uint256 public create_canvas_fee;

    uint256 public mint_d4a_fee_ratio;
    uint256 public trade_d4a_fee_ratio;
    uint256 public mint_project_fee_ratio;
    uint256 public mint_project_fee_ratio_flat_price;

    uint256 public erc20_total_supply;

    uint256 public project_max_rounds; //366

    uint256 public project_erc20_ratio;
    uint256 public canvas_erc20_ratio;
    uint256 public d4a_erc20_ratio;

    uint256 public rf_lower_bound;
    uint256 public rf_upper_bound;
    uint256[] public floor_prices;
    uint256[] public max_nft_amounts;

    ID4APRB public PRB;

    string public erc20_name_prefix;
    string public erc20_symbol_prefix;

    ID4AERC721Factory public erc721_factory;
    ID4AERC20Factory public erc20_factory;
    ID4AFeePoolFactory public feepool_factory;
    ID4AOwnerProxy public owner_proxy;
    ID4AProtocolForSetting public protocol;
    IPermissionControl public permission_control;
    address public asset_pool_owner;

    bool public d4a_pause;

    mapping(bytes32 => bool) public pause_status;

    address public WETH;

    address public project_proxy;

    uint256 public reserved_slots;

    constructor() {
        //some default value here
        ratio_base = 10000;
        create_project_fee = 0.1 ether;
        create_canvas_fee = 0.01 ether;
        mint_d4a_fee_ratio = 250;
        trade_d4a_fee_ratio = 250;
        mint_project_fee_ratio = 3000;
        mint_project_fee_ratio_flat_price = 3500;
        rf_lower_bound = 500;
        rf_upper_bound = 1000;

        project_erc20_ratio = 300;
        d4a_erc20_ratio = 200;
        canvas_erc20_ratio = 9500;
        project_max_rounds = 366;
        reserved_slots = 110;
    }

    function floor_prices_length() public view returns (uint256) {
        return floor_prices.length;
    }

    function max_nft_amounts_length() public view returns (uint256) {
        return max_nft_amounts.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4APRB {
    function isStart() external view returns (bool);
    function currentRound() external view returns (uint256);
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

interface ID4AFeePoolFactory {
    function createD4AFeePool(string memory _name) external returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721Factory {
    function createD4AERC721(string memory _name, string memory _symbol) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721 {
    function mintItem(address player, string memory tokenURI) external returns (uint256);

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC20Factory {
    function createD4AERC20(string memory _name, string memory _symbol, address _minter) external returns (address);
}