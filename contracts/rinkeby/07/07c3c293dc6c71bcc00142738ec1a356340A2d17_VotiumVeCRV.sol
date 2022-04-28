// SPDX-License-Identifier: MIT
// Votium veCRV Rewarder

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./Ownable.sol";

interface GController {
  function gauge_types(address _addr) external view returns (int128);
}

contract VotiumVeCRV is Ownable {

  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  mapping(address => bool) public tokenListed;       // accepted tokens
  mapping(address => bool) public approvedTeam;      // for team functions that do not require multi-sig security

  address public feeAddress = 0x29e3b0E8dF4Ee3f71a62C34847c34E139fC0b297; // Votium fee address
  uint256 public platformFee = 200;             // 2%
  uint256 public constant DENOMINATOR = 10000;  // denominates weights 10000 = 100%

  address public distributor = 0xd9145CCE52D386f254917e481eB44e9943F39138; // rinkby

  GController public gc = GController(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);



  /* ========== CONSTRUCTOR ========== */

  constructor() {
    approvedTeam[msg.sender] = true;
    approvedTeam[0x540815B1892F888875E800d2f7027CECf883496a] = true;
  }

  /* ========== PUBLIC FUNCTIONS ========== */

  // Deposit vote incentive
  function depositReward(address _token, uint256 _amount, uint256 _week, address _gauge) public {
    require(tokenListed[_token] == true, "token unlisted");
    require(_week > week(), "week expired");  // must give voters an entire week to vote
    require(_week < week()+7, "more than 6 weeks ahead"); // cannot post future rewards beyond 6 weeks
    // disabled for rinkeby // require(gc.gauge_types(_gauge) >= 0, "invalid gauge");  // check gauge controller to ensure valid gauge
    require(distributor != address(0), "distributor not set"); // prevent deposits if distributor is 0x0

    uint256 fee = _amount*platformFee/DENOMINATOR;
    uint256 rewardTotal = _amount-fee;
    IERC20(_token).safeTransferFrom(msg.sender, feeAddress, fee); // transfer to fee address
    IERC20(_token).safeTransferFrom(msg.sender, distributor, rewardTotal);  // transfer to distributor
    emit NewReward(_token, rewardTotal, _week, _gauge);
  }

	// current week number
  function week() public view returns (uint256) {
    return block.timestamp/(86400*7);
  }


  /* ========== APPROVED TEAM FUNCTIONS ========== */


  // list token
  function listToken(address _token) public onlyTeam {
	  tokenListed[_token] = true;
	  emit Listed(_token);
  }

  // list multiple tokens
  function listTokens(address[] memory _tokens) public onlyTeam {
	  for(uint256 i=0;i<_tokens.length;++i) {
		  tokenListed[_tokens[i]] = true;
		  emit Listed(_tokens[i]);
	  }
  }


  /* ========== MUTLI-SIG FUNCTIONS ========== */

	// unlist token
  function unlistToken(address _token) public onlyOwner {
	  tokenListed[_token] = false;
	  emit Unlisted(_token);
  }

  // update fee address
  function updateFeeAddress(address _feeAddress) public onlyOwner {
	  feeAddress = _feeAddress;
  }

  // update token distributor address
  function updateDistributor(address _distributor) public onlyOwner {
	  // can be changed for future use in case of cheaper gas options than current merkle approach
	  distributor = _distributor;
	  emit UpdatedDistributor(_distributor);
  }

  // update fee amount
  function updateFeeAmount(uint256 _feeAmount) public onlyOwner {
	  require(_feeAmount < 400, "max fee"); // Max fee 4%
	  platformFee = _feeAmount;
	  emit UpdatedFee(_feeAmount);
  }

  // add or remove address from team functions
  function modifyTeam(address _member, bool _approval) public onlyOwner {
	  approvedTeam[_member] = _approval;
	  emit ModifiedTeam(_member, _approval);
  }

  // update curve gauge controller (for gauge validation)
  function updateGaugeController(address _gc) public onlyOwner {
	  gc = GController(_gc);
  }


  /* ========== MODIFIERS ========== */

  modifier onlyTeam() {
	  require(approvedTeam[msg.sender] == true, "Team only");
	  _;
  }

  /* ========== EVENTS ========== */

  event NewReward(address indexed _token, uint256 _amount, uint256 indexed _week, address indexed _gauge);
  event Listed(address _token);
  event Unlisted(address _token);
  event UpdatedFee(uint256 _feeAmount);
  event ModifiedTeam(address _member, bool _approval);
  event UpdatedDistributor(address _distributor);

}