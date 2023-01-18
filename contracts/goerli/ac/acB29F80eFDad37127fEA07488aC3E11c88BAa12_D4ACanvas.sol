// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "../interface/ID4ASetting.sol";

library D4ACanvas{
  struct canvas_info{
    bytes32 project_id;
    uint256[] nft_tokens;
    uint256 nft_token_number;
    uint256 index;
    string canvas_uri;
    bool exist;
  }

  error D4AInsufficientEther(uint256 required);
  error D4ACanvasAlreadyExist(bytes32 canvas_id);

  event NewCanvas(bytes32 project_id, bytes32 canvas_id, string uri);

  function createCanvas(mapping(bytes32=>canvas_info) storage all_canvases,
                        ID4ASetting _settings,
                        address fee_pool,
                        bytes32 _project_id,
                        uint256 _project_start_prb,
                        uint256 canvas_num,
                        string memory _canvas_uri) public returns(bytes32){

    {
      ID4APRB prb = _settings.PRB();
      uint256 cur_round = prb.currentRound();
      require(cur_round >=  _project_start_prb, "project not start yet");
    }

    {
      uint256 minimal = _settings.create_canvas_fee();
      require(minimal <= msg.value, "not enough ether to create canvas");
      if(msg.value < minimal) revert D4AInsufficientEther(minimal);

      (bool succ, ) = fee_pool.call{value:minimal}("");
      require(succ, "transfer fee failed");

      uint256 exchange = msg.value - minimal;
      if(exchange != 0){
        (succ, ) = msg.sender.call{value:exchange}("");
        require(succ, "transfer exchange failed");
      }
    }
    bytes32 canvas_id = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
    if(all_canvases[canvas_id].exist) revert D4ACanvasAlreadyExist(canvas_id);

    {
      canvas_info storage ci = all_canvases[canvas_id];
      ci.project_id = _project_id;
      ci.canvas_uri = _canvas_uri;
      ci.index = canvas_num + 1;
      _settings.owner_proxy().initOwnerOf(canvas_id, msg.sender);
      ci.exist = true;
    }
    emit NewCanvas(_project_id, canvas_id, _canvas_uri);
    return canvas_id;
  }

  function getCanvasNFTCount(mapping(bytes32=>canvas_info) storage all_canvases,
                             bytes32 _canvas_id) internal view returns(uint256){
    canvas_info storage ci = all_canvases[_canvas_id];
    return ci.nft_token_number;
  }
  function getTokenIDAt(mapping(bytes32=>canvas_info) storage all_canvases,
                        bytes32 _canvas_id, uint256 _index) internal view returns(uint256){
    canvas_info storage ci = all_canvases[_canvas_id];
    return ci.nft_tokens[_index];
  }

  function getCanvasURI(mapping(bytes32=>canvas_info) storage all_canvases,
                        bytes32 _canvas_id) internal view returns(string memory){
    canvas_info storage ci = all_canvases[_canvas_id];
    return ci.canvas_uri;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "./ID4APRB.sol";
import "./ID4AFeePoolFactory.sol";
import "./ID4AERC20Factory.sol";
import "./ID4AOwnerProxy.sol";
import "./ID4AERC721.sol";
import "./ID4AERC721Factory.sol";

interface ID4AProtocolForSetting {
  function getCanvasProject(bytes32 _canvas_id) external view returns(bytes32);
}

contract ID4ASetting{
  uint256 public ratio_base;
  uint256 public min_stamp_duty; //TODO
  uint256 public max_stamp_duty;

  uint256 public create_project_fee;
  address public protocol_fee_pool;
  uint256 public create_canvas_fee;

  uint256 public mint_d4a_fee_ratio;
  uint256 public trade_d4a_fee_ratio;
  uint256 public mint_project_fee_ratio;

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
  address public asset_pool_owner;

  bool public d4a_pause;

  mapping(bytes32 => bool) public pause_status;

  address public WETH;

  address public project_proxy;

  uint256 public reserved_slots;

  constructor(){
    //some default value here
    ratio_base = 10000;
    create_project_fee = 0.1 ether;
    create_canvas_fee = 0.01 ether;
    mint_d4a_fee_ratio = 250;
    trade_d4a_fee_ratio = 250;
    mint_project_fee_ratio = 3000;
    rf_lower_bound = 500;
    rf_upper_bound = 1000;

    project_erc20_ratio = 300;
    d4a_erc20_ratio = 200;
    canvas_erc20_ratio = 9500;
    project_max_rounds = 366;
    reserved_slots = 110;
  }

  function floor_prices_length() public view returns(uint256){
    return floor_prices.length;
  }
  function max_nft_amounts_length() public view returns(uint256){
    return max_nft_amounts.length;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4APRB{
  function isStart() external view returns(bool);
  function currentRound() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AOwnerProxy{
  function ownerOf(bytes32 hash) external view returns(address);
  function initOwnerOf(bytes32 hash, address addr) external returns(bool);
  function transferOwnership(bytes32 hash, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AFeePoolFactory{
  function createD4AFeePool(string memory _name) external returns(address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721Factory{
  function createD4AERC721(string memory _name, string memory _symbol) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721{
  function mintItem(address player, string memory tokenURI) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC20Factory{
  function createD4AERC20(string memory _name, string memory _symbol, address _minter) external returns(address);
}