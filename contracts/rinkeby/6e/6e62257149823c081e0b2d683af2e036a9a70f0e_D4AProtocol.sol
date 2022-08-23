// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./impl/D4AProject.sol";
import "./impl/D4ACanvas.sol";
import "./impl/D4APrice.sol";
import "./impl/D4AReward.sol";
import "./interface/ID4ASetting.sol";
import "./interface/ID4AProtocol.sol";


contract D4AProtocol is Initializable, ReentrancyGuardUpgradeable, ID4AProtocol{
  using D4AProject for mapping(bytes32=>D4AProject.project_info);
  using D4ACanvas for mapping(bytes32=>D4ACanvas.canvas_info);
  using D4APrice for mapping(bytes32=>D4APrice.project_price_info);
  using D4AReward for mapping(bytes32=>D4AReward.reward_info);


  mapping (bytes32=>bool) public uri_exists;

  uint256 public project_num;
  //event from library
  event NewProject(bytes32 project_id, string uri, address fee_pool, address erc20_token, address erc721_token, uint256 royalty_fee);
  event NewCanvas(bytes32 project_id, bytes32 canvas_id, string uri);

  function initialize(address _settings) public initializer{
    __ReentrancyGuard_init();
    settings = ID4ASetting(_settings);
  }

  function createProject(uint256 _start_prb,
                         uint256 _mintable_rounds,
                         uint256 _floor_price_rank,
                         uint256 _max_nft_rank,
                         uint96 _royalty_fee,
                         string memory _project_uri) public override payable nonReentrant returns(bytes32 project_id){
    require(!uri_exists[keccak256(abi.encodePacked(_project_uri))], "project_uri already exist");
    uri_exists[keccak256(abi.encodePacked(_project_uri))] = true;
    project_num ++;
    return all_projects.createProject(settings, _start_prb, _mintable_rounds, _floor_price_rank, _max_nft_rank, _royalty_fee, project_num, _project_uri);
  }

  function getProjectCanvasCount(bytes32 _project_id) public view returns(uint256){
    return all_projects.getProjectCanvasCount(_project_id);
  }


  error D4AProjectNotExist(bytes32 project_id);
  error D4ACanvasNotExist(bytes32 canvas_id);

  function createCanvas(bytes32 _project_id, string memory _canvas_uri) public payable nonReentrant
    returns(bytes32 canvas_id){
    if(!all_projects[_project_id].exist) revert D4AProjectNotExist(_project_id);

    require(!uri_exists[keccak256(abi.encodePacked(_canvas_uri))], "canvas_uri already exist");
    uri_exists[keccak256(abi.encodePacked(_canvas_uri))] = true;

    canvas_id = all_canvases.createCanvas(settings,
                                          all_projects[_project_id].fee_pool,
                                          _project_id,
                                          all_projects[_project_id].start_prb,
                                          all_projects.getProjectCanvasCount(_project_id),
                                          _canvas_uri);

    all_projects[_project_id].canvases.push(canvas_id);
    //creating canvas does not affect price
    //all_prices.updateCanvasPrice(settings, _project_id, canvas_id, 0);
  }


  event D4AMintNFT(bytes32 project_id, bytes32 canvas_id, uint256 token_id, string token_uri, uint256 price);
  function mintNFT(bytes32 _canvas_id, string memory _token_uri) public payable nonReentrant returns(uint256 token_id){
    if(!all_canvases[_canvas_id].exist) revert D4ACanvasNotExist(_canvas_id);
    bytes32 proj_id = all_canvases[_canvas_id].project_id;

    require(!uri_exists[keccak256(abi.encodePacked(_token_uri))], "token_uri already exist");
    require(all_projects[proj_id].nft_supply < all_projects[proj_id].max_nft_amount, "nft exceeds limit");
    uri_exists[keccak256(abi.encodePacked(_token_uri))] = true;

    uint256 price = 0;
    {
      price = all_prices.getCanvasNextPrice(settings,
                                            all_projects[proj_id].floor_prices,
                                            all_projects[proj_id].floor_price_rank,
                                            all_projects[proj_id].start_prb,
                                            proj_id, _canvas_id);
      require(msg.value >= price, "not enough ether to mint NFT");
      uint256 exchange = msg.value - price;
      uint256 m = price * settings.mint_project_fee_ratio()/settings.ratio_base();
      uint256 n = price * settings.mint_d4a_fee_ratio()/settings.ratio_base();
      bool succ;
      if(m != 0){
        (succ, ) = all_projects[proj_id].fee_pool.call{value:m}("");
        require(succ, "transfer project portion failed");
      }
      if(n != 0){
        (succ, ) = settings.protocol_fee_pool().call{value:n}("");
        require(succ, "transfer protocol portion failed");
      }
      (succ, ) = settings.owner_proxy().ownerOf(_canvas_id).call{value:price-m-n}("");
      require(succ, "transfer canvas portion failed");

      if(exchange != 0){
        (succ, ) = msg.sender.call{value:exchange}("");
        require(succ, "transfer exchange failed");
      }
      all_prices.updateCanvasPrice(settings, proj_id, _canvas_id, price);
      all_rewards.updateMintWithAmount(settings, proj_id, _canvas_id, price -m -n );
      all_rewards.updateRewardForCanvas(settings,
                                        proj_id,
                                        _canvas_id,
                                        all_projects[proj_id].start_prb,
                                        all_projects[proj_id].mintable_rounds);
    }

    token_id = ID4AERC721(all_projects[proj_id].erc721_token).mintItem(msg.sender, _token_uri);
    all_projects[proj_id].nft_supply++;
    all_canvases[_canvas_id].nft_tokens.push(token_id);
    all_canvases[_canvas_id].nft_token_number++;
    tokenid_2_canvas[keccak256(abi.encodePacked(proj_id, token_id))] = _canvas_id;
    emit D4AMintNFT(proj_id, _canvas_id, token_id, _token_uri, price);
  }

  function getNFTTokenCanvas(bytes32 _project_id, uint256 _token_id) public view returns(bytes32){
    return tokenid_2_canvas[keccak256(abi.encodePacked(_project_id, _token_id))];
  }

  event D4AClaimProjectERC20Reward(bytes32 project_id, address erc20_token, uint256 amount);

  function claimProjectERC20Reward(bytes32 _project_id) public returns(uint256){
    if(!all_projects[_project_id].exist) revert D4AProjectNotExist(_project_id);

    D4AProject.project_info storage pi = all_projects[_project_id];
    all_rewards.issueTokenToCurrentRound(settings, _project_id, pi.erc20_token, pi.start_prb, pi.mintable_rounds);
    uint256 amount = all_rewards.claimProjectReward(settings, _project_id, pi.erc20_token, pi.start_prb, pi.mintable_rounds);
    emit D4AClaimProjectERC20Reward(_project_id, pi.erc20_token, amount);
    return amount;
  }

  event D4AClaimCanvasReward(bytes32 project_id, bytes32 canvas_id, address erc20_token, uint256 amount);
  function claimCanvasReward(bytes32 _canvas_id) public returns(uint256){
    if(!all_canvases[_canvas_id].exist) revert D4ACanvasNotExist(_canvas_id);
    bytes32 project_id = all_canvases[_canvas_id].project_id;
    if(!all_projects[project_id].exist) revert D4AProjectNotExist(project_id);

    D4AProject.project_info storage pi = all_projects[project_id];
    all_rewards.issueTokenToCurrentRound(settings, project_id, pi.erc20_token, pi.start_prb, pi.mintable_rounds);
    uint256 amount =  all_rewards.claimCanvasReward(settings, project_id,
                                         _canvas_id, pi.erc20_token,
                                         pi.start_prb, pi.mintable_rounds);
    emit D4AClaimCanvasReward(project_id, _canvas_id, pi.erc20_token, amount);
    return amount;
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

contract ID4ASetting{
  uint256 public ratio_base;
  uint256 public min_stamp_duty; //TODO
  uint256 public max_stamp_duty;

  uint256 public create_project_fee;
  address public protocol_fee_pool;
  uint256 public create_canvas_fee;

  uint256 public mint_d4a_fee_ratio;
  uint256 public mint_project_fee_ratio;

  uint256 public erc20_total_supply;

  uint256 public project_max_rounds; //366

  uint256 public project_erc20_ratio;
  uint256 public canvas_erc20_ratio;
  uint256 public d4a_erc20_ratio;

  uint256[] public floor_prices;
  uint256[] public max_nft_amounts;

  ID4APRB public PRB;

  string public erc20_name_prefix;
  string public erc20_symbol_prefix;

  ID4AERC721Factory public erc721_factory;
  ID4AERC20Factory public erc20_factory;
  ID4AFeePoolFactory public feepool_factory;
  ID4AOwnerProxy public owner_proxy;
  address public asset_pool_owner;

  constructor(){
    //some default value here
    ratio_base = 10000;
    create_project_fee = 1 ether;
    create_canvas_fee = 0.01 ether;
    mint_d4a_fee_ratio = 250;
    mint_project_fee_ratio = 3000;

    project_erc20_ratio = 300;
    d4a_erc20_ratio = 200;
    canvas_erc20_ratio = 9500;
    project_max_rounds = 366;
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
import "../impl/D4AProject.sol";
import "../impl/D4ACanvas.sol";
import "../impl/D4APrice.sol";
import "../impl/D4AReward.sol";

abstract contract ID4AProtocol{
  using D4AProject for mapping(bytes32=>D4AProject.project_info);
  using D4ACanvas for mapping(bytes32=>D4ACanvas.canvas_info);
  using D4APrice for mapping(bytes32=>D4APrice.project_price_info);
  using D4AReward for mapping(bytes32=>D4AReward.reward_info);

  mapping (bytes32=>D4AProject.project_info) public all_projects;
  mapping (bytes32=>D4ACanvas.canvas_info) public all_canvases;
  mapping (bytes32=>D4APrice.project_price_info) public all_prices;
  mapping (bytes32=>D4AReward.reward_info) public all_rewards;
  mapping (bytes32=> bytes32) public tokenid_2_canvas;

  ID4ASetting public settings;

  function createProject(uint256 _start_prb,
                         uint256 _mintable_rounds,
                         uint256 _floor_price_rank,
                         uint256 _max_nft_rank,
                         uint96 _royalty_fee,
                         string memory _project_uri) virtual external payable returns(bytes32 project_id);

  function getProjectCanvasAt(bytes32 _project_id, uint256 _index) public view returns(bytes32){
    return all_projects.getProjectCanvasAt(_project_id, _index);
  }

  function getProjectInfo(bytes32 _project_id) public view
    returns(uint256 start_prb, uint256 mintable_rounds, uint256 floor_price_rank,
                                  uint256 max_nft_amount, address fee_pool, uint96 royalty_fee, uint256 index, string memory uri, uint256 erc20_total_supply){
    return all_projects.getProjectInfo(_project_id);
  }
  function getProjectTokens(bytes32 _project_id) public view returns(address erc20_token, address erc721_token){
    erc20_token = all_projects[_project_id].erc20_token;
    erc721_token = all_projects[_project_id].erc721_token;
  }

  function getCanvasNFTCount(bytes32 _canvas_id) public view returns(uint256){
    return all_canvases.getCanvasNFTCount(_canvas_id);
  }
  function getTokenIDAt(bytes32 _canvas_id, uint256 _index) public view returns(uint256){
    return all_canvases.getTokenIDAt(_canvas_id, _index);
  }
  function getCanvasProject(bytes32 _canvas_id) public view returns(bytes32){
    return all_canvases[_canvas_id].project_id;
  }
  function getCanvasIndex(bytes32 _canvas_id) public view returns(uint256){
    return all_canvases[_canvas_id].index;
  }
  function getCanvasURI(bytes32 _canvas_id) public view returns(string memory){
    return all_canvases.getCanvasURI(_canvas_id);
  }
  function getCanvasLastPrice(bytes32 _canvas_id) public view returns(uint256 round, uint256 price){
    bytes32 proj_id = all_canvases[_canvas_id].project_id;
    return all_prices.getCanvasLastPrice(proj_id, _canvas_id);
  }
  function getCanvasNextPrice(bytes32 _canvas_id) public view returns(uint256){
    bytes32 project_id = all_canvases[_canvas_id].project_id;
    D4AProject.project_info storage pi = all_projects[project_id];
    return all_prices.getCanvasNextPrice(settings, pi.floor_prices, pi.floor_price_rank, pi.start_prb, project_id, _canvas_id);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AChangeAdmin{
  function changeAdmin(address new_admin) external;
  function transferOwnership(address new_owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "../interface/ID4ASetting.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ID4AMintableERC20{
  function mint(address to, uint256 amount) external;
}

library D4AReward{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  struct reward_info{
    uint256[] active_rounds;
    uint256 to_issue_round_index;
    uint256 final_issued_round_index;
    uint256 project_owner_to_claim_round_index;
    uint256 issued_rounds;
    mapping (uint256=>uint256) round_2_total_amount;
    mapping (bytes32=>uint256) canvas_2_to_claim_round_index;
    mapping(bytes32=>mapping(uint256=>uint256)) canvas_2_block_2_amount;
    mapping(bytes32=>uint256) canvas_2_unclaimed_amount;
  }

  function issueTokenToCurrentRound(mapping(bytes32=>reward_info) storage all_rewards,
                                   ID4ASetting _settings,
                                   bytes32 _project_id,
                                   address erc20_token,
                                   uint256 _start_round,
                                   uint256 total_rounds) internal returns(uint256){
    ID4APRB prb = _settings.PRB();
    uint256 cur_round = prb.currentRound();
    if(cur_round <= _start_round){
      return 0;
    }
    reward_info storage ri = all_rewards[_project_id];

    uint256 n = ri.issued_rounds;
    if(n >= total_rounds){
      return 0;
    }
    {
      uint i = 0;
      for(i = ri.to_issue_round_index ; i < ri.active_rounds.length; i++){
        if(ri.active_rounds[i] == cur_round){
          break;
        }
        if(all_rewards[_project_id].round_2_total_amount[ri.active_rounds[i]] != 0){
          n = n + 1;
          all_rewards[_project_id].final_issued_round_index = i;
          all_rewards[_project_id].to_issue_round_index = i + 1;
          if(n == total_rounds){
            break;
          }
        }
      }
    }


    uint256 amount = (n - all_rewards[_project_id].issued_rounds)*_settings.erc20_total_supply()/total_rounds;

    ID4AMintableERC20(erc20_token).mint(address(this),  amount);
    all_rewards[_project_id].issued_rounds = n;
    return amount;
  }

  function updateMintWithAmount(mapping(bytes32=>reward_info) storage all_rewards,
                             ID4ASetting _settings,
                             bytes32 _project_id, bytes32 _canvas_id, uint256 _amount) internal {
    ID4APRB prb = _settings.PRB();
    uint256 cur_round = prb.currentRound();

    reward_info storage ri = all_rewards[_project_id];
    ri.round_2_total_amount[cur_round] += _amount;
    ri.canvas_2_block_2_amount[_canvas_id][cur_round] += _amount;
    if(ri.active_rounds.length == 0){
      ri.active_rounds.push(cur_round);
    }else{
      if(ri.active_rounds[ri.active_rounds.length - 1] != cur_round){
        ri.active_rounds.push(cur_round);
      }
    }
  }

  function claimCanvasReward(mapping(bytes32=>reward_info) storage all_rewards,
                             ID4ASetting _settings,
                             bytes32 _project_id,
                             bytes32 _canvas_id,
                             address _erc20_token,
                             uint256 _start_round,
                             uint256 _total_rounds) internal returns(uint256){
    uint256 cur_round;
    {
      ID4APRB prb = _settings.PRB();
      cur_round = prb.currentRound();
    }

    if(cur_round == _start_round){
      return 0;
    }

    uint256 total_amount = 0;
    {
      reward_info storage ri = all_rewards[_project_id];
      if(ri.active_rounds.length == 0){
        return 0;
      }
      if(ri.active_rounds.length <= ri.canvas_2_to_claim_round_index[_canvas_id]){
        return 0;
      }

      uint256 tk =
        _settings.erc20_total_supply() * _settings.canvas_erc20_ratio() /(_settings.ratio_base() *_total_rounds);

      for(uint256 i = ri.canvas_2_to_claim_round_index[_canvas_id]; i <= ri.final_issued_round_index; i++){
        if(ri.active_rounds[i] == cur_round){
          break;
        }
        total_amount += tk * ri.canvas_2_block_2_amount[_canvas_id][ri.active_rounds[i]]/
          ri.round_2_total_amount[ri.active_rounds[i]] ;
        ri.canvas_2_to_claim_round_index[_canvas_id] = i + 1;
      }
      total_amount = total_amount + ri.canvas_2_unclaimed_amount[_canvas_id];
      ri.canvas_2_unclaimed_amount[_canvas_id] = 0;
    }

    if(total_amount > 0){
      address canvas_owner = _settings.owner_proxy().ownerOf(_canvas_id);
      IERC20Upgradeable(_erc20_token).safeTransfer(canvas_owner, total_amount);
    }

    return total_amount;
  }

  function updateRewardForCanvas(mapping(bytes32=>reward_info) storage all_rewards,
                                 ID4ASetting _settings,
                                 bytes32 _project_id,
                                 bytes32 _canvas_id, uint256 _start_round, uint256 _total_rounds) internal{
    uint256 cur_round;
    {
      ID4APRB prb = _settings.PRB();
      cur_round = prb.currentRound();
    }

    if(cur_round == _start_round){
      return ;
    }

    uint256 total_amount = 0;
    {
      reward_info storage ri = all_rewards[_project_id];
      if(ri.active_rounds.length == 0){
        return ;
      }
      if(ri.active_rounds.length <= ri.canvas_2_to_claim_round_index[_canvas_id]){
        return ;
      }

      uint256 tk =
        _settings.erc20_total_supply() * _settings.canvas_erc20_ratio() /(_settings.ratio_base() *_total_rounds);

      for(uint256 i = ri.canvas_2_to_claim_round_index[_canvas_id]; i <= ri.final_issued_round_index; i++){
        if(ri.active_rounds[i] == cur_round){
          break;
        }
        total_amount += tk * ri.canvas_2_block_2_amount[_canvas_id][ri.active_rounds[i]]/
          ri.round_2_total_amount[ri.active_rounds[i]] ;
        ri.canvas_2_to_claim_round_index[_canvas_id] = i + 1;
      }

      ri.canvas_2_unclaimed_amount[_canvas_id] += total_amount;
    }
  }

  function claimProjectReward(mapping(bytes32=>reward_info) storage all_rewards,
                             ID4ASetting _settings,
                             bytes32 _project_id,
                             address erc20_token,
                             uint256 _start_round,
                             uint256 _total_rounds) internal
    returns(uint256){
    reward_info storage ri = all_rewards[_project_id];
    if(ri.active_rounds.length == 0){
      return 0;
    }
    if(ri.active_rounds.length <= ri.project_owner_to_claim_round_index){
      return 0;
    }

    uint256 from = ri.active_rounds[ri.project_owner_to_claim_round_index];
    if(from == 0){
      from = _start_round;
    }
    ID4APRB prb = _settings.PRB();
    uint256 cur_round = prb.currentRound();
    if(from == cur_round){
      return 0;
    }

    uint256 n = ri.final_issued_round_index - ri.project_owner_to_claim_round_index + 1;
    ri.project_owner_to_claim_round_index = ri.final_issued_round_index + 1;

    uint256 d4a_amount =
      _settings.erc20_total_supply() * _settings.d4a_erc20_ratio() * n /(_settings.ratio_base() *_total_rounds);
    uint256 project_amount =
      _settings.erc20_total_supply() * _settings.project_erc20_ratio() * n /(_settings.ratio_base() *_total_rounds);

    if(project_amount != 0){
      address project_owner = _settings.owner_proxy().ownerOf(_project_id);
      IERC20Upgradeable(erc20_token).safeTransfer(project_owner, project_amount);
    }
    if(d4a_amount != 0){
      IERC20Upgradeable(erc20_token).safeTransfer(_settings.protocol_fee_pool(), d4a_amount);
    }
    return project_amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "../interface/ID4ASetting.sol";
import "../interface/ID4AChangeAdmin.sol";
import "../D4AERC721.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

library D4AProject{
  struct project_info{
    uint256 start_prb;
    uint256 mintable_rounds;
    uint256 floor_price_rank;
    uint256 max_nft_amount;
    uint256 nft_supply;
    uint96 royalty_fee;
    uint256 index;
    address erc20_token;
    address erc721_token;
    address fee_pool;
    string project_uri;
    //from setting
    uint256 erc20_total_supply;
    uint256[] floor_prices;
    bytes32[] canvases;
    bool exist;
  }

  using StringsUpgradeable for uint256;

  error D4AInsufficientEther(uint256 required);
  error D4AProjectAlreadyExist(bytes32 project_id);
  event NewProject(bytes32 project_id, string uri, address fee_pool, address erc20_token, address erc721_token, uint256 royalty_fee);

  function createProject(mapping(bytes32=>project_info) storage all_projects,
                         ID4ASetting _settings,
                        uint256 _start_prb,
                         uint256 _mintable_rounds,
                         uint256 _floor_price_rank,
                         uint256 _max_nft_rank,
                         uint96 _royalty_fee,
                         uint256 _project_index,
                         string memory _project_uri) internal returns(bytes32 project_id){
    require(_settings.project_max_rounds() >= _mintable_rounds, "rounds too long, not support");
    {
      uint256 protocol_fee = _settings.mint_d4a_fee_ratio();
      require(_royalty_fee >= 500 + protocol_fee && _royalty_fee <= 1000 + protocol_fee, "royalty fee out of range");
    }
    {
      uint256 minimal = _settings.create_project_fee();
      require(msg.value >= minimal, "not enough ether to create project");
      (bool succ, ) = _settings.protocol_fee_pool().call{value:minimal}("");
      require(succ, "transfer fee failed");
      uint256 exchange = msg.value - minimal;
      if(exchange != 0){
        (succ, ) = msg.sender.call{value:exchange}("");
        require(succ, "transfer exchange failed");
      }
    }

    project_id = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));


    if(all_projects[project_id].exist) revert D4AProjectAlreadyExist(project_id);
    {
      project_info storage pi = all_projects[project_id];
      pi.start_prb= _start_prb;
      {
        ID4APRB prb = _settings.PRB();
        uint256 cur_round = prb.currentRound();
        require(_start_prb >  cur_round, "start round already passed");
      }
      pi.mintable_rounds = _mintable_rounds;
      pi.floor_price_rank = _floor_price_rank;
      pi.max_nft_amount = _settings.max_nft_amounts(_max_nft_rank);
      pi.project_uri = _project_uri;
      pi.royalty_fee = _royalty_fee;
      pi.index = _project_index;
      pi.erc20_token = _createERC20Token(_settings, _project_index);
      address pool= _settings.feepool_factory().createD4AFeePool(
        string(abi.encodePacked("Asset Pool for DAO4Art Project ", _project_index.toString())));
      ID4AChangeAdmin(pool).changeAdmin(_settings.asset_pool_owner());
      ID4AChangeAdmin(pi.erc20_token).changeAdmin(_settings.asset_pool_owner());
      pi.fee_pool = pool;

      _settings.owner_proxy().initOwnerOf(project_id, msg.sender);

      pi.erc721_token = _createERC721Token(_settings, _project_index);
      D4AERC721(pi.erc721_token).grantRole(keccak256("ROYALTY"), address(this));
      D4AERC721(pi.erc721_token).setRoyaltyInfo(pi.fee_pool, _royalty_fee);
      D4AERC721(pi.erc721_token).grantRole(keccak256("MINTER"), address(this));
      D4AERC721(pi.erc721_token).setContractUri(_project_uri);
      ID4AChangeAdmin(pi.erc721_token).changeAdmin(_settings.asset_pool_owner());
      ID4AChangeAdmin(pi.erc721_token).transferOwnership(msg.sender);

      //We copy from setting in case setting may change later.
      pi.erc20_total_supply = _settings.erc20_total_supply();
      for(uint i = 0; i < _settings.floor_prices_length(); i++){
        pi.floor_prices.push(_settings.floor_prices(i));
      }
      require(pi.floor_price_rank < pi.floor_prices.length, "invalid floor price rank");

      pi.exist = true;
      emit NewProject(project_id, _project_uri, pool, pi.erc20_token, pi.erc721_token, _royalty_fee);
    }
  }


  function getProjectCanvasCount(mapping(bytes32=>project_info) storage all_projects,
                          bytes32 _project_id) internal view returns(uint256){

    project_info storage pi = all_projects[_project_id];
    return pi.canvases.length;
  }
  function getProjectCanvasAt(mapping(bytes32=>project_info) storage all_projects,
                              bytes32 _project_id, uint256 _index) internal view returns(bytes32){
    project_info storage pi = all_projects[_project_id];
    return pi.canvases[_index];
  }
  function getProjectInfo(mapping(bytes32=>project_info) storage all_projects,
                          bytes32 _project_id) internal view
                          returns(uint256 start_prb, uint256 mintable_rounds, uint256 floor_price_rank,
                                  uint256 max_nft_amount, address fee_pool, uint96 royalty_fee, uint256 index, string memory uri, uint256 erc20_total_supply){
    project_info storage pi = all_projects[_project_id];
    start_prb = pi.start_prb;
    mintable_rounds = pi.mintable_rounds;
    floor_price_rank = pi.floor_price_rank;
    max_nft_amount = pi.max_nft_amount;
    fee_pool = pi.fee_pool;
    royalty_fee = pi.royalty_fee;
    index = pi.index;
    uri = pi.project_uri;
    erc20_total_supply = pi.erc20_total_supply;
  }

  /*function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
    result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);

  }

  function toHex (bytes32 data) internal pure returns (string memory) {
    return string (abi.encodePacked (toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
  }
  function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
          result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }*/

  function _createERC20Token(ID4ASetting _settings, uint256 _project_num) internal returns(address){
    string memory name = string(abi.encodePacked("D4A Token for [email protected]", _project_num.toString()));
    string memory sym = string(abi.encodePacked("D4A_T ", _project_num.toString()));
    return _settings.erc20_factory().createD4AERC20(name, sym, address(this));
  }

  function _createERC721Token(ID4ASetting _settings, uint256 _project_num) internal returns(address){
    string memory name = string(abi.encodePacked("D4A NFT for [email protected]", _project_num.toString()));
    string memory sym = string(abi.encodePacked("D4A_N ", _project_num.toString()));
    return _settings.erc721_factory().createD4AERC721(name, sym);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "../interface/ID4ASetting.sol";

library D4APrice {
  struct last_price{
    uint256 round;
    uint256 value;
  }
  struct project_price_info{
    last_price max_price;
    uint256 price_rank;
    uint256[] price_slots;
    mapping(bytes32=>last_price) canvas_price;
  }

  function getCanvasLastPrice(mapping(bytes32=>project_price_info) storage all_prices,
                              bytes32 _project_id, bytes32 _canvas_id) internal view
    returns(uint256 round, uint256 value){
    last_price storage lp = all_prices[_project_id].canvas_price[_canvas_id];
    round = lp.round;
    value = lp.value;
  }

  function getCanvasNextPrice(mapping(bytes32=>project_price_info) storage all_prices,
                              ID4ASetting _settings,
                              uint256[] memory price_slots, uint256 price_rank, uint256 start_prb,
                              bytes32 _project_id, bytes32 _canvas_id) internal view returns(uint256 price){

    uint256 floor_price = price_slots[price_rank];
    project_price_info storage ppi = all_prices[_project_id];
    ID4APRB prb = _settings.PRB();
    uint256 cur_round = prb.currentRound();
    if (ppi.max_price.round == 0){
      if (cur_round == start_prb) return floor_price;
      else return floor_price/2;
    }
    uint256 first_guess = _get_price_in_round(ppi.canvas_price[_canvas_id], cur_round);
    if(first_guess >= floor_price){
      return first_guess;
    }
    /*if(ppi.canvas_price[_canvas_id].round == cur_round ||
      ppi.canvas_price[_canvas_id].round +1 == cur_round){
      return floor_price;
    }*/

    first_guess = _get_price_in_round(ppi.max_price, cur_round);
    if(first_guess >= floor_price){
      return floor_price;
    }
    if (ppi.max_price.value == floor_price/2 && cur_round <= ppi.max_price.round + 1){
      return floor_price;
    }
    
    return floor_price/2;
  }

  function updateCanvasPrice(mapping(bytes32=>project_price_info) storage all_prices,
                              ID4ASetting _settings,
                              bytes32 _project_id, bytes32 _canvas_id,
                              uint256 price) internal {
    project_price_info storage ppi = all_prices[_project_id];
    ID4APRB prb = _settings.PRB();
    uint256 cp = 0;
    {
      uint256 cur_round = prb.currentRound();
      cp = _get_price_in_round(ppi.max_price, cur_round);
    }
    if(price >= cp){
      ppi.max_price.round = prb.currentRound();
      ppi.max_price.value= price;
    }

    ppi.canvas_price[_canvas_id].round = prb.currentRound();
    ppi.canvas_price[_canvas_id].value = price;
  }

  function _get_price_in_round(last_price memory lp, uint256 round) internal pure returns(uint256){
    if(round == lp.round){
      return lp.value << 1;
    }
    uint256 k = round - lp.round - 1;
    return lp.value >>k;
  }
}

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
                        string memory _canvas_uri) internal returns(bytes32){

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

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interface/ID4AERC721Factory.sol";

contract D4AERC721 is Initializable, ERC721URIStorageUpgradeable, AccessControlUpgradeable, ERC721RoyaltyUpgradeable, OwnableUpgradeable{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _tokenIds;

  bytes32 public constant MINTER = keccak256("MINTER");
  bytes32 public constant ROYALTY_OWNER = keccak256("ROYALTY");

  string private project_uri;

  function setContractUri(string memory _uri) public onlyOwner{
    project_uri = _uri;
  }

  function contractURI() public view returns (string memory) {
    return project_uri;
  }


  function initialize(string memory name, string memory symbol) public initializer{
    __ERC721_init(name, symbol);
    __ERC721URIStorage_init();
    __ERC721Royalty_init();

    __AccessControl_init();
    __Ownable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _tokenIds.reset();

  }

  function mintItem(address player, string memory uri) public onlyRole(MINTER) returns (uint256){
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _mint(player, newItemId);
    _setTokenURI(newItemId, uri);
    return newItemId;
  }

  function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) public onlyRole(ROYALTY_OWNER){
    _setDefaultRoyalty(_receiver, _royaltyFeeInBips);
  }

  function _burn(uint256 _tokenId) internal override(ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable){
    super._burn(_tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view
    override(ERC721Upgradeable, AccessControlUpgradeable, ERC721RoyaltyUpgradeable)
    returns(bool){
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns(string memory){
    return super.tokenURI(tokenId);
  }

  function changeAdmin(address new_admin) public onlyRole(DEFAULT_ADMIN_ROLE){
    _grantRole(DEFAULT_ADMIN_ROLE, new_admin);
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}

contract D4AERC721Factory is ID4AERC721Factory{
  using Clones for address;
  D4AERC721 impl;
  event NewD4AERC721(address addr);
  constructor() {
    impl = new D4AERC721();
  }

  function createD4AERC721(string memory _name, string memory _symbol) public returns(address){
    address t = address(impl).clone();
    D4AERC721(t).initialize(_name, _symbol);
    D4AERC721(t).changeAdmin(msg.sender);
    D4AERC721(t).transferOwnership(msg.sender);
    emit NewD4AERC721(t);
    return t;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../common/ERC2981Upgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721RoyaltyUpgradeable is Initializable, ERC2981Upgradeable, ERC721Upgradeable {
    function __ERC721Royalty_init() internal onlyInitializing {
    }

    function __ERC721Royalty_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}