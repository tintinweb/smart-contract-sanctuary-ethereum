// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./EIP712.sol";
import "./IDEXRouter.sol";

/**
 * @title ClaimRewards smart contract.
 */
contract ClaimRewards is EIP712, Ownable, ReentrancyGuard {
  /// @notice _BATCH_TYPE type hash of the Batch struct
  bytes32 private constant _BATCH_TYPE = keccak256("Batch(uint256 batchId,uint256 issuedTimestamp)");
  /// @notice _BATCH_TYPE type hash of the Ticket struct
  bytes32 private constant _TICKET_TYPE = keccak256("Ticket(uint8 rewardType,address tokenAddress,uint256 amount,address claimerAddress,uint256 ticketId,bytes32 batchProofSignature)");

  uint256 public maxTicketsPerBatch = 1_000_000;
  uint256 public minCharityDonationPercent = 15;
  uint256 public maxCharityDonationPercent = 100;

  // @notice duration since the issued date of a batch in a ticket that a user can convert ETH to reward tokens
  uint256 public durationToConvertETHToTokens = 5 days;

  // @notice the charity address that a user can distribute some proportion of claim rewards to
  address public charityAddress;
  // @notice the signer that signed the batchProofSignature
  address public batchSigner;
  // @notice the signer that signed the ticketProofSignature
  address public ticketSigner;

  // @notice total ETH claimed amount
  uint256 public totalETHClaimedAmount;
  // @notice total ETH donate amount
  uint256 public totalETHDonatedAmount;
  // @notice total ERC20 token claimed amount
  mapping(address => uint256) public totalERC20ClaimedAmount;
  // @notice total ERC20 token donated amount
  mapping(address => uint256) public totalERC20DonatedAmount;

  // @notice router address of the DEX
  IDEXRouter public dexRouter;

  constructor(
    string memory contractName,
    string memory contractVersion,
    address _dexRouter,
    address _charityAddress
  ) EIP712(contractName, contractVersion) {
    dexRouter = IDEXRouter(_dexRouter);
    charityAddress = _charityAddress;
  }

  // @notice RewardType
  // ETH - reward in Ethers
  // ERC20 - reward in ERC20 tokens
  enum RewardType {
    ETH,
    ERC20
  }

  // @notice Batch will contain multiple tickets
  struct Batch {
    uint256 batchId;
    // issuedTimestamp: the date that the batch was issued
    uint256 issuedTimestamp;
  }

  // @notice Ticket is a proof that you are eligible to claim the rewards
  // each Ticket must belong to a batch and must include a valid batch signature as well as a valid ticket signature
  struct Ticket {
    uint8 rewardType;
    // tokenAddress is the reward token that a user will receive if the rewardType is ERC20
    address tokenAddress;
    uint256 amount;
    address claimerAddress;
    uint256 ticketId;
    Batch batch;
    bytes batchProofSignature;
    bytes ticketProofSignature;
  }

  // @notice isTicketClaimed tracks if a ticket has been claimed or not
  mapping(uint256 => bool) public isTicketClaimed;

  // @notice _hashBatch compute the hash of the provided batch
  function _hashBatch(Batch calldata batch) private pure returns (bytes32) {
    return keccak256(abi.encode(_BATCH_TYPE, batch.batchId, batch.issuedTimestamp));
  }

  // @notice _hashTicket compute the hash of the provided ticket
  function _hashTicket(Ticket calldata ticket) private pure returns (bytes32) {
    return keccak256(abi.encode(_TICKET_TYPE, ticket.rewardType, ticket.tokenAddress, ticket.amount, ticket.claimerAddress, ticket.ticketId, keccak256(ticket.batchProofSignature)));
  }

  // @notice setDexRouter - owner can set the dex router address
  function setDexRouter(address router) external onlyOwner {
    dexRouter = IDEXRouter(router);
  }

  // @notice setCharityAddress - owner can set the charityAddress
  function setCharityAddress(address address_) external onlyOwner {
    charityAddress = address_;
  }

  // @notice setBatchSignerAddress - set the batch signer address
  function setBatchSignerAddress(address signer) external onlyOwner {
    batchSigner = signer;
  }

  // @notice setTicketSignerAddress - set the ticket signer address
  function setTicketSignerAddress(address signer) external onlyOwner {
    ticketSigner = signer;
  }

  // @notice setSigners - set batch signer and ticket signer
  function setSigners(address _batchSigner, address _ticketSigner) external onlyOwner {
    batchSigner = _batchSigner;
    ticketSigner = _ticketSigner;
  }

  /*
   * @notice setParams for the contract
   * @param _maxTicketsPerBatch The maximum number of tickets per batch
   * @param _minCharityDonationPercent The minimum percentage of the reward that a user must donate
   * @param _maxCharityDonationPercent The minimum percentage of the reward that a user must donate
   * @param _durationToConvertETHToTokensInSeconds Duration in seconds that a user can convert ETH reward to the desired tokens
   */
  function setParams(
    uint256 _maxTicketsPerBatch,
    uint256 _minCharityDonationPercent,
    uint256 _maxCharityDonationPercent,
    uint256 _durationToConvertETHToTokensInSeconds
  ) external onlyOwner {
    maxTicketsPerBatch = _maxTicketsPerBatch;
    minCharityDonationPercent = _minCharityDonationPercent;
    maxCharityDonationPercent = _maxCharityDonationPercent;
    durationToConvertETHToTokens = _durationToConvertETHToTokensInSeconds;
  }

  // @notice getBatchIdOfTicket calculate the batchId given ticketId
  function getBatchIdOfTicket(uint256 ticketId) private view returns (uint256) {
    return ticketId - (ticketId % maxTicketsPerBatch);
  }

  // @notice _validateDonationPercent validate if the donation percentage of the reward is valid
  function _validateDonationPercent(uint256 percent) private view {
    require(percent >= minCharityDonationPercent && percent <= maxCharityDonationPercent, "INVALID_CHARITY_DONATION_PERCENT");
  }

  // @notice _convertETHToTokenAmount calculate the expected token amount if a user decided to convert ETH reward to the desired tokens
  function _convertETHToTokenAmount(uint256 amountETH, address tokenAddress) private view returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = dexRouter.WETH();
    path[1] = tokenAddress;
    uint256[] memory amounts = dexRouter.getAmountsOut(amountETH, path);
    return amounts[1];
  }

  // @notice _swapTokensForETH swap reward tokens for ETH
  function _swapTokensForETH(address tokenAddress, uint256 tokenAmount) internal returns (uint256) {
    uint256 balanceBefore = address(this).balance;
    address[] memory path = new address[](2);
    path[0] = tokenAddress;
    path[1] = dexRouter.WETH();

    if (IERC20(tokenAddress).allowance(address(this), address(dexRouter)) < tokenAmount) {
      IERC20(tokenAddress).approve(address(dexRouter), type(uint256).max);
    }

    dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    uint256 amountETH = address(this).balance - balanceBefore;
    return amountETH;
  }

  // @notice _validateTicket validate if a ticket is valid
  function _validateTicket(Ticket calldata ticket, RewardType expectedRewardType) private view {
    require(!isTicketClaimed[ticket.ticketId], "ALREADY_CLAIMED");
    require(RewardType(ticket.rewardType) == expectedRewardType, "INVALID_REWARD_TYPE");
    require(_isValidSignature(_hashBatch(ticket.batch), ticket.batchProofSignature, batchSigner), "INVALID_BATCH_SIGNATURE");
    require(_isValidSignature(_hashTicket(ticket), ticket.ticketProofSignature, ticketSigner), "INVALID_TICKET_SIGNATURE");
    require(ticket.batch.batchId == getBatchIdOfTicket(ticket.ticketId), "MISMATCHED_TICKET_ID");
    require(ticket.claimerAddress == msg.sender, "CALLER_ADDRESS_MUST_MATCH_CLAIMER_ADDRESS");
  }

  /*
   * @notice claim ETH reward by providing tickets
   * @param tickets The array of ticket struct, any tickets must contain a batchProofSignature and a ticketProofSignature
   * @param charityDonationPercent percent of the rewards that the caller want to donate to charity
   * @param shouldConvertToToken a user can choose to convert ETH rewards to a desired tokens as long as
   */
  function claimETH(
    Ticket[] calldata tickets,
    uint256 charityDonationPercent,
    bool shouldConvertToToken,
    address tokenAddress
  ) external nonReentrant {
    require(tickets.length != 0, "NO_TICKET_TO_PROCESS");
    _validateDonationPercent(charityDonationPercent);

    uint256 totalETHForClaimAmount;
    for (uint256 i; i < tickets.length; i++) {
      _validateTicket(tickets[i], RewardType.ETH);
      totalETHForClaimAmount += tickets[i].amount;
      isTicketClaimed[tickets[i].ticketId] = true;
    }

    require(totalETHForClaimAmount > 0, "INVALID_REWARD_AMOUNT");

    uint256 charityAmount = (totalETHForClaimAmount * charityDonationPercent) / 100;
    _safeTransferETH(charityAddress, charityAmount);
    totalETHForClaimAmount -= charityAmount;

    uint256 convertDeadline = tickets[0].batch.issuedTimestamp + durationToConvertETHToTokens;
    if (shouldConvertToToken && block.timestamp <= convertDeadline) {
      uint256 tokenAmount = _convertETHToTokenAmount(totalETHForClaimAmount, tokenAddress);
      require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "FAILED_TO_TRANSFER_TOKENS");
      totalERC20ClaimedAmount[tokenAddress] += tokenAmount;
    } else {
      _safeTransferETH(msg.sender, totalETHForClaimAmount);
      totalETHClaimedAmount += totalETHForClaimAmount;
    }

    totalETHDonatedAmount += charityAmount;
  }

  /*
   * @notice claim ERC20 reward tokens by providing tickets
   * @param tickets The array of ticket struct, any tickets must contain a batchProofSignature and a ticketProofSignature
   * @param charityDonationPercent percent of the rewards that the caller want to donate to charity
   */
  function claimERC20(
    Ticket[] calldata tickets,
    uint256 charityDonationPercent,
    bool shouldSwapRewardTokenToETH
  ) external nonReentrant {
    require(tickets.length != 0, "NO_TICKET_TO_PROCESS");
    _validateDonationPercent(charityDonationPercent);

    address tokenAddress = tickets[0].tokenAddress;
    require(tokenAddress != address(0), "MUST_BE_A_VALID_TOKEN_ADDRESS");

    uint256 tokenForClaimAmount;
    for (uint256 i; i < tickets.length; i++) {
      _validateTicket(tickets[i], RewardType.ERC20);
      require(tickets[i].tokenAddress == tokenAddress, "ALL_TICKETS_MUST_HAVE_SAME_TOKEN_ADDRESS");

      tokenForClaimAmount += tickets[i].amount;
      isTicketClaimed[tickets[i].ticketId] = true;
    }

    require(tokenForClaimAmount > 0, "INVALID_REWARD_AMOUNT");

    uint256 charityAmount = (tokenForClaimAmount * charityDonationPercent) / 100;
    if (shouldSwapRewardTokenToETH) {
      uint256 amountETHForClaim = _swapTokensForETH(tokenAddress, tokenForClaimAmount);
      uint256 charityAmountETH = (amountETHForClaim * charityDonationPercent) / 100;
      if (charityAmountETH > 0) {
        _safeTransferETH(charityAddress, charityAmountETH);
        amountETHForClaim = amountETHForClaim - charityAmountETH;
      }

      _safeTransferETH(msg.sender, amountETHForClaim);
      tokenForClaimAmount -= charityAmount;
    } else {
      require(IERC20(tokenAddress).transfer(charityAddress, charityAmount), "FAILED_TO_TRANSFER_TOKENS");
      tokenForClaimAmount -= charityAmount;
      require(IERC20(tokenAddress).transfer(msg.sender, tokenForClaimAmount), "FAILED_TO_TRANSFER_TOKENS");
    }

    totalERC20ClaimedAmount[tokenAddress] += tokenForClaimAmount;
    totalERC20DonatedAmount[tokenAddress] += charityAmount;
  }

  // @notice _safeTransferETH to a destination address
  function _safeTransferETH(address to, uint256 value) internal {
    require(address(this).balance >= value, "INSUFFICIENT_BALANCE");
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "SafeTransferETH: ETH transfer failed");
  }

  // @notice withdraw all ETH amount in the contract
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  // @notice withdraw all stuck ERC20 tokens in the contract
  function withdrawErc20(IERC20 token) external onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  receive() external payable {}
}