/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.10;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function decimals() external returns (uint8); 

    function name() external returns (string memory); 

    function symbol() external returns (string memory); 

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBalanceHolder_ERC20 {
  function withdraw (  ) external;
  function balanceOf ( address ) external view returns ( uint256 );
  function token ( ) external view returns ( IERC20 );
}

interface IRealityETH_ERC20 is IBalanceHolder_ERC20 {
     event LogAnswerReveal (bytes32 indexed question_id, address indexed user, bytes32 indexed answer_hash, bytes32 answer, uint256 nonce, uint256 bond);
     event LogCancelArbitration (bytes32 indexed question_id);
     event LogClaim (bytes32 indexed question_id, address indexed user, uint256 amount);
     event LogFinalize (bytes32 indexed question_id, bytes32 indexed answer);
     event LogFundAnswerBounty (bytes32 indexed question_id, uint256 bounty_added, uint256 bounty, address indexed user);
     event LogMinimumBond (bytes32 indexed question_id, uint256 min_bond);
     event LogNewAnswer (bytes32 answer, bytes32 indexed question_id, bytes32 history_hash, address indexed user, uint256 bond, uint256 ts, bool is_commitment);
     event LogNewQuestion (bytes32 indexed question_id, address indexed user, uint256 template_id, string question, bytes32 indexed content_hash, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 created);
     event LogNewTemplate (uint256 indexed template_id, address indexed user, string question_text);
     event LogNotifyOfArbitrationRequest (bytes32 indexed question_id, address indexed user);
     event LogReopenQuestion (bytes32 indexed question_id, bytes32 indexed reopened_question_id);
     event LogSetQuestionFee (address arbitrator, uint256 amount);

     function askQuestion (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external returns (bytes32);
     function askQuestionERC20 (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 tokens) external returns (bytes32);
     function askQuestionWithMinBondERC20 (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond, uint256 tokens) external returns (bytes32);
     function assignWinnerAndSubmitAnswerByArbitrator (bytes32 question_id, bytes32 answer, address payee_if_wrong, bytes32 last_history_hash, bytes32 last_answer_or_commitment_id, address last_answerer) external;
     function cancelArbitration (bytes32 question_id) external;
     function claimMultipleAndWithdrawBalance (bytes32[] calldata question_ids, uint256[] calldata lengths, bytes32[] calldata hist_hashes, address[] calldata addrs, uint256[] calldata bonds, bytes32[] calldata answers) external;
     function claimWinnings (bytes32 question_id, bytes32[] calldata history_hashes, address[] calldata addrs, uint256[] calldata bonds, bytes32[] calldata answers) external;
     function createTemplate (string calldata content) external returns (uint256);
     function createTemplateAndAskQuestion (string calldata content, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external returns (bytes32);
     function fundAnswerBountyERC20 (bytes32 question_id, uint256 tokens) external;
     function notifyOfArbitrationRequest (bytes32 question_id, address requester, uint256 max_previous) external;
     function reopenQuestionERC20 (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond, bytes32 reopens_question_id, uint256 tokens) external returns (bytes32);
     function setQuestionFee (uint256 fee) external;
     function setToken (address _token) external;
     function submitAnswerByArbitrator (bytes32 question_id, bytes32 answer, address answerer) external;
     function submitAnswerCommitmentERC20 (bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer, uint256 tokens) external;
     function submitAnswerERC20 (bytes32 question_id, bytes32 answer, uint256 max_previous, uint256 tokens) external;
     function submitAnswerForERC20 (bytes32 question_id, bytes32 answer, uint256 max_previous, address answerer, uint256 tokens) external;
     function submitAnswerReveal (bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond) external;
     function arbitrator_question_fees (address) external view returns (uint256);
     function commitments (bytes32) external view returns (uint32 reveal_ts, bool is_revealed, bytes32 revealed_answer);
     function getArbitrator (bytes32 question_id) external view returns (address);
     function getBestAnswer (bytes32 question_id) external view returns (bytes32);
     function getBond (bytes32 question_id) external view returns (uint256);
     function getBounty (bytes32 question_id) external view returns (uint256);
     function getContentHash (bytes32 question_id) external view returns (bytes32);
     function getFinalAnswer (bytes32 question_id) external view returns (bytes32);
     function getFinalAnswerIfMatches (bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 min_timeout, uint256 min_bond) external view returns (bytes32);
     function getFinalizeTS (bytes32 question_id) external view returns (uint32);
     function getHistoryHash (bytes32 question_id) external view returns (bytes32);
     function getMinBond (bytes32 question_id) external view returns (uint256);
     function getOpeningTS (bytes32 question_id) external view returns (uint32);
     function getTimeout (bytes32 question_id) external view returns (uint32);
     function isFinalized (bytes32 question_id) external view returns (bool);
     function isPendingArbitration (bytes32 question_id) external view returns (bool);
     function isSettledTooSoon (bytes32 question_id) external view returns (bool);
     function question_claims (bytes32) external view returns (address payee, uint256 last_bond, uint256 queued_funds);
     function questions (bytes32) external view returns (bytes32 content_hash, address arbitrator, uint32 opening_ts, uint32 timeout, uint32 finalize_ts, bool is_pending_arbitration, uint256 bounty, bytes32 best_answer, bytes32 history_hash, uint256 bond, uint256 min_bond);
     function reopened_questions (bytes32) external view returns (bytes32);
     function reopener_questions (bytes32) external view returns (bool);
     function resultFor (bytes32 question_id) external view returns (bytes32);
     function resultForOnceSettled (bytes32 question_id) external view returns (bytes32);
     function template_hashes (uint256) external view returns (bytes32);
     function templates (uint256) external view returns (uint256);
}

contract RealityETH_ERC20_Factory {

  address public libraryAddress;
  mapping(address => address) public deployments;

  event RealityETH_ERC20_deployed (address reality_eth, address token, uint8 decimals, string token_ticker);

  constructor(address _libraryAddress) {
    libraryAddress = _libraryAddress;
  }

  /// @notice Returns the address of a proxy based on the specified address
  /// @dev based on https://github.com/optionality/clone-factory
  function _deployProxy(address _target)
  internal returns (address result) {
     bytes20 targetBytes = bytes20(_target);
     assembly {
         let clone := mload(0x40)
         mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
         mstore(add(clone, 0x14), targetBytes)
         mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
         result := create(0, clone, 0x37)
     }
  }

  function createInstance(address _token) external {
    require(deployments[_token] == address(0), "There should only be one deployment per version per token");
    uint8 decimals = IERC20(_token).decimals();
    string memory ticker = IERC20(_token).symbol();
    address clone = _deployProxy(libraryAddress);
    IRealityETH_ERC20(clone).setToken(_token);
    deployments[_token] = clone;
    emit RealityETH_ERC20_deployed(clone, _token, decimals, ticker);
  }

}