// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title BequestV1
 * @author Bequest Finance Inc.
 * @notice Bequest uses a Dead Man's switch to distribute tokens and NFTs to
 *         selected recipients. Bequest allows decentralized, trustless and
 *         anonymous asset distribution backed by the blockchain.
 */
contract BequestV1 is Ownable, ReentrancyGuard {
  /*
   * @dev: Stores all details about a Bequest
   */
  struct Bequest {
    address executor;
    bool paidDistributionFee;
    Recipient[] recipients;
    IERC20[] tokens;
    NFT[] nfts;
    uint96 lastPaidYearlyFee;
    uint96 timestamp;
    uint64 renewalRate;
  }

  struct Recipient {
    address recipient;
    uint96 percentage;
  }

  struct NFT {
    IERC165 nft;
    uint96 amount;
    address recipient;
    uint256 tokenId;
  }

  /*
   * @dev: Stores all details about a referral
   */
  struct Referral {
    uint256 usesLeft;
    uint256 profit;
    uint8 discount;
    uint8 profitShare;
    address profitAddress;
  }

  /*
   * @dev: Event emitted when Bequest is created
   * @param owner: The owner of the Bequest
   * @param referral: Referral code used
   */
  event CreatedBequest(address owner);

  /*
   * @dev: Event emitted when Bequest is renewed
   * @param owner: The owner of the Bequest
   * @param executor: The executor of the renewal
   */
  event RenewedBequest(address indexed owner, address executor);

  /*
   * @dev: Event emitted when Bequest recipient distributes a Bequest
   * @param owner: The owner of the Bequest
   * @param executor: The recipient of the Bequest
   */
  event DistributedBequest(address indexed owner, address indexed recipient);

  /*
   * @dev: Event emitted when Bequest owner sets a recipient,
   *       used for gas-efficent storage.
   * @param owner: The owner of the Bequest
   */
  event EditedRecipients(address owner);

  /*
   * @dev: Event emitted when Bequest owner sets an executor,
   *       used for gas-efficent storage.
   * @param owner: The owner of the Bequest
   */
  event EditedExecutor(address owner);

  /*
   * @dev: Event emitted when referral code is created
   * @param code: Referral code
   */
  event CreatedReferral(string code);

  /*
   * @dev: Event emitted when yearly fee is edited
   * @param code: New yearly fee
   */
  event ChangedYearlyFee(uint256 newYearlyFee);

  // Stores all Bequests
  mapping(address => Bequest) private addressToBequest;
  // Stores all referral codes
  mapping(string => Referral) public referralCodes;
  // Current profit to be withdrawn for referrers
  uint256 public referralProfit;

  uint64 private constant ONE_YEAR = 365 days;
  uint256 public bequestYearlyFee;
  uint256 public immutable bequestFeeDivisor;

  constructor(uint256 _bequestYearlyFee, uint256 _bequestFeeDivisor) {
    require(_bequestFeeDivisor >= 20, "5% Distribution fee cap");

    bequestYearlyFee = _bequestYearlyFee;
    bequestFeeDivisor = _bequestFeeDivisor;
  }

  /*
   * @dev: Ensures called is a Bequest owner
   */
  modifier onlyBequestOwner() {
    require(isOwner(msg.sender), "Not Bequest owner");
    _;
  }

  /*
   * @dev: Ensures Bequest is up to date on renewal payments
   */
  modifier notClaimable() {
    require(!isClaimable(msg.sender), "Renew Bequest");
    _;
  }

  modifier onlyExecutor(address _owner) {
    require(
      msg.sender == _owner || msg.sender == addressToBequest[_owner].executor,
      "Not executor"
    );
    _;
  }

  function setRenewalRate(uint64 _renewalRate) external payable notClaimable {
    _setRenewalRate(_renewalRate);
  }

  function setRecipients(Recipient[] calldata _recipients)
    external
    payable
    notClaimable
  {
    _setRecipients(_recipients);
  }

  function addTokens(IERC20[] calldata _tokens) external payable notClaimable {
    _setTokens(_tokens, new uint256[](0));
  }

  function addNFTs(NFT[] calldata _nfts) external payable notClaimable {
    _setNFTs(_nfts, new uint256[](0));
  }

  function setTokens(
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenIndexesToReplace
  ) external payable notClaimable {
    _setTokens(_tokens, _tokenIndexesToReplace);
  }

  function setNFTs(
    NFT[] calldata _nfts,
    uint256[] calldata _nftIndexesToReplace
  ) external payable notClaimable {
    _setNFTs(_nfts, _nftIndexesToReplace);
  }

  function setExecutor(address _owner, address _executor)
    external
    payable
    onlyExecutor(_owner)
  {
    _setExecutor(_owner, _executor);
  }

  function setBequest(uint64 _renewalRate, address _executor)
    external
    payable
    notClaimable
  {
    _setRenewalRate(_renewalRate);
    _setExecutor(msg.sender, _executor);
  }

  function setBequest(
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenIndexesToReplace
  ) external payable notClaimable {
    _setRecipients(_recipients);
    _setTokens(_tokens, _tokenIndexesToReplace);
  }

  function setBequest(
    Recipient[] calldata _recipients,
    NFT[] calldata _nfts,
    uint256[] calldata _nftIndexesToReplace
  ) external payable notClaimable {
    _setRecipients(_recipients);
    _setNFTs(_nfts, _nftIndexesToReplace);
  }

  function setBequest(
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenIndexesToReplace,
    NFT[] calldata _nfts,
    uint256[] calldata _nftIndexesToReplace
  ) external payable notClaimable {
    _setTokens(_tokens, _tokenIndexesToReplace);
    _setNFTs(_nfts, _nftIndexesToReplace);
  }

  function setBequest(
    Recipient[] calldata _recipients,
    NFT[] calldata _nfts,
    uint256[] calldata _nftIndexesToReplace,
    uint64 _renewalRate
  ) external payable notClaimable {
    _setRecipients(_recipients);
    _setNFTs(_nfts, _nftIndexesToReplace);
    _setRenewalRate(_renewalRate);
  }

  function setBequest(
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenIndexesToReplace,
    NFT[] calldata _nfts,
    uint256[] calldata _nftIndexesToReplace,
    uint64 _renewalRate
  ) external payable notClaimable {
    _setTokens(_tokens, _tokenIndexesToReplace);
    _setNFTs(_nfts, _nftIndexesToReplace);
    _setRenewalRate(_renewalRate);
  }

  function setBequest(
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenIndexesToReplace,
    uint64 _renewalRate
  ) external payable notClaimable {
    _setRecipients(_recipients);
    _setTokens(_tokens, _tokenIndexesToReplace);
    _setRenewalRate(_renewalRate);
  }

  function setBequest(
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenIndexesToReplace,
    NFT[] calldata _nfts,
    uint256[] calldata _nftIndexesToReplace
  ) external payable notClaimable {
    _setRecipients(_recipients);
    _setTokens(_tokens, _tokenIndexesToReplace);
    _setNFTs(_nfts, _nftIndexesToReplace);
  }

  function setBequest(
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens,
    uint256[] calldata _tokenIndexesToReplace,
    NFT[] calldata _nfts,
    uint256[] calldata _nftIndexesToReplace,
    uint64 _renewalRate
  ) external payable notClaimable {
    _setRecipients(_recipients);
    _setTokens(_tokens, _tokenIndexesToReplace);
    _setNFTs(_nfts, _nftIndexesToReplace);
    _setRenewalRate(_renewalRate);
  }

  function createBequest(address _owner, string calldata _referral)
    external
    payable
  {
    _createBequest(_owner, _referral);
  }

  function createBequestAndSet(string calldata _referral, address _executor)
    external
    payable
  {
    _createBequest(msg.sender, _referral);
    _setExecutor(msg.sender, _executor);
  }

  function createBequestAndSet(string calldata _referral, NFT[] calldata _nfts)
    external
    payable
  {
    _createBequest(msg.sender, _referral);
    _setNFTs(_nfts, new uint256[](0));
  }

  function createBequestAndSet(
    string calldata _referral,
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens
  ) external payable {
    _createBequest(msg.sender, _referral);
    _setRecipients(_recipients);
    _setTokens(_tokens, new uint256[](0));
  }

  function createBequestAndSet(
    string calldata _referral,
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens,
    address _executor
  ) external payable {
    _createBequest(msg.sender, _referral);
    _setRecipients(_recipients);
    _setTokens(_tokens, new uint256[](0));
    _setExecutor(msg.sender, _executor);
  }

  function createBequestAndSet(
    string calldata _referral,
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens,
    NFT[] calldata _nfts
  ) external payable {
    _createBequest(msg.sender, _referral);
    _setRecipients(_recipients);
    _setTokens(_tokens, new uint256[](0));
    _setNFTs(_nfts, new uint256[](0));
  }

  function createBequestAndSet(
    string calldata _referral,
    Recipient[] calldata _recipients,
    IERC20[] calldata _tokens,
    NFT[] calldata _nfts,
    address _executor
  ) external payable {
    _createBequest(msg.sender, _referral);
    _setRecipients(_recipients);
    _setTokens(_tokens, new uint256[](0));
    _setNFTs(_nfts, new uint256[](0));
    _setExecutor(msg.sender, _executor);
  }

  /*
   * @notice: Creates a Bequest
   * @param _owner: To be owner of Bequest
   * @param _referral: Referral code, if any
   */
  function _createBequest(address _owner, string calldata _referral) internal {
    require(!isOwner(_owner), "Already owner");

    uint256 creationFee = getCreationFee(_referral);
    require(msg.value >= creationFee, "Invalid fee");

    if (bytes(_referral).length != 0) {
      Referral storage referralDetails = referralCodes[_referral];

      if (referralDetails.profitShare > 0) {
        uint256 profit = (msg.value * referralDetails.profitShare) / 100;

        referralDetails.profit += profit;
        referralProfit += profit;
      }

      referralDetails.usesLeft--;
    }

    Bequest storage bequest = addressToBequest[_owner];
    bequest.timestamp = uint96(block.timestamp);
    bequest.lastPaidYearlyFee = uint96(block.timestamp);
    bequest.renewalRate = ONE_YEAR;

    emit CreatedBequest(_owner);
  }

  /*
   * @notice: Lets Bequest owners renew their Bequest
   * @dev: Similar to Dead Man's Switch
   */
  function renewBequest(address _owner) external payable onlyExecutor(_owner) {
    (uint256 renewalFee, uint256 yearsPassed) = getRenewalFee(_owner);
    Bequest storage bequest = addressToBequest[_owner];

    if (renewalFee > 0) {
      require(msg.value >= renewalFee, "Invalid fee");
      bequest.lastPaidYearlyFee =
        bequest.timestamp +
        uint96(yearsPassed) *
        ONE_YEAR;
    }

    if (bequest.paidDistributionFee) {
      delete bequest.paidDistributionFee;
    }

    bequest.timestamp = uint96(block.timestamp);
    emit RenewedBequest(_owner, msg.sender);
  }

  /*
   * @notice: Transfers all assets in _owner's Bequest to _recipient
   * @param _owner: Owner of Bequest
   * @dev: Nonreentrant to avoid malicious code when calling external contracts. Only callable by recipient.
   */
  function distribute(address _owner) external nonReentrant {
    address _recipient = msg.sender;

    require(isRecipient(_owner, _recipient), "Not recipient");
    require(isClaimable(_owner), "Cannot distribute now");

    Bequest storage bequest = addressToBequest[_owner];
    Recipient[] memory recipients = bequest.recipients;
    NFT[] memory nfts = bequest.nfts;

    if (recipients.length != 0) {
      if (!bequest.paidDistributionFee) {
        safeSendERC20s(_owner, owner(), 1, bequestFeeDivisor);
        bequest.paidDistributionFee = true;
      }

      uint256 recipientPercentage;
      uint256 index;
      uint256 cumulativePercentage;

      for (uint256 i; i < recipients.length; ) {
        if (recipients[i].recipient == _recipient) {
          recipientPercentage = recipients[i].percentage;
          index = i;
        }
        cumulativePercentage += recipients[i].percentage;

        unchecked {
          i++;
        }
      }

      if (recipientPercentage > 0) {
        safeSendERC20s(
          _owner,
          _recipient,
          recipientPercentage,
          cumulativePercentage
        );

        delete bequest.recipients[index];
      }
    }

    for (uint256 i; i < nfts.length; ) {
      if (nfts[i].recipient == _recipient) {
        safeSendNFT(
          _owner,
          _recipient,
          nfts[i].nft,
          nfts[i].tokenId,
          nfts[i].amount
        );

        delete bequest.nfts[i].recipient;
      }

      unchecked {
        i++;
      }
    }

    emit DistributedBequest(_owner, _recipient);

    for (uint256 i; i < recipients.length; ) {
      if (bequest.recipients[i].recipient != address(0)) {
        return;
      }

      unchecked {
        i++;
      }
    }

    for (uint256 i; i < nfts.length; ) {
      if (bequest.nfts[i].recipient != address(0)) {
        return;
      }

      unchecked {
        i++;
      }
    }

    delete addressToBequest[_owner];
  }

  /*
   * @notice: Lets Bequest owner set nfts in Bequest
   * @param _nfts: NFTs
   * @param _indexesToReplace: Indexes in the nfts array to remove, in increasing order
   */
  function _setNFTs(NFT[] calldata _newNfts, uint256[] memory _indexesToReplace)
    internal
  {
    uint256 index;

    NFT[] storage nfts = addressToBequest[msg.sender].nfts;

    for (uint256 i; i < _newNfts.length; ) {
      if (index < _indexesToReplace.length) {
        nfts[_indexesToReplace[index]] = _newNfts[i];

        unchecked {
          index++;
        }
      } else {
        nfts.push(_newNfts[i]);
      }

      unchecked {
        i++;
      }
    }

    // If there are indexes left to remove, remove in decreasing order (opposite order)
    for (uint256 i = _indexesToReplace.length; i > index; ) {
      uint256 lastNftIndex = nfts.length - 1;
      uint256 indexToRemove = _indexesToReplace[i - 1];

      if (indexToRemove != lastNftIndex) {
        nfts[indexToRemove] = nfts[lastNftIndex];
      }
      nfts.pop();

      unchecked {
        i--;
      }
    }

    emit EditedRecipients(msg.sender);
  }

  /*
   * @notice: Lets Executor or Bequest owner set executor to renew Bequest on owner's behalf
   * @param _owner: Bequest owner's address
   * @param _executor: Exeuctor's address
   */
  function _setExecutor(address _owner, address _executor) internal {
    require(!isClaimable(_owner), "Renew Bequest");
    addressToBequest[_owner].executor = _executor;
    emit EditedExecutor(_owner);
  }

  /*
   * @notice: Creates a referral code
   * @param _code: Referral code name
   * @param _usesLeft: The amount of uses of the referral code
   * @param _discount: The percent of discount
   * @param _profitShare: The percent of profit to give to _profitAddress
   * @param _profitAddress: Address to send profit to
   * @dev: Possible to edit referral code
   */
  function createReferral(
    string calldata _code,
    uint256 _usesLeft,
    uint8 _discount,
    uint8 _profitShare,
    address _profitAddress
  ) external onlyOwner {
    require(bytes(_code).length > 0, "Invalid code");
    require(_discount <= 100, "Invalid discount");
    require(_profitShare <= 100, "Invalid profit share");
    if (_profitShare != 0) {
      require(_profitAddress != address(0), "Invalid address");
    }

    referralCodes[_code].usesLeft = _usesLeft;
    referralCodes[_code].discount = _discount;
    referralCodes[_code].profitShare = _profitShare;
    referralCodes[_code].profitAddress = _profitAddress;

    emit CreatedReferral(_code);
  }

  /*
   * @notice: Transfers all profit, if any, to the profit address
   * @param _code: Referrer code name
   * @dev: Profit set to 0 before transfer to prevent re-entrancy
   */
  function withdrawReferralProfits(string calldata _code) external {
    Referral storage referralDetails = referralCodes[_code];
    uint256 profit = referralDetails.profit;
    require(profit > 0, "No profit");

    referralProfit -= profit;
    referralDetails.profit = 0;
    (bool success, ) = referralDetails.profitAddress.call{ value: profit }("");
    require(success, "Transaction failed");
  }

  /*
   * @notice: Deletes caller's Bequest
   */
  function deleteBequest() external onlyBequestOwner {
    delete addressToBequest[msg.sender];
  }

  /*
   * @notice: Lets contract admin extract fees paid by users
   * @dev: Does not let referral profit be withdrawn
   */
  function extractFees() external onlyOwner {
    uint256 amount = address(this).balance - referralProfit;
    (bool success, ) = owner().call{ value: amount }("");
    require(success, "Transaction failed");
  }

  /*
   * @notice: Sets Bequest yearly fee, admin function
   * @param _fee: New yearly fee
   */
  function setYearlyFee(uint256 _fee) external onlyOwner {
    bequestYearlyFee = _fee;
    emit ChangedYearlyFee(_fee);
  }

  /*
   * @param _owner: Address
   * @returns: _owner's Bequest details
   */
  function getBequest(address _owner) external view returns (Bequest memory) {
    return addressToBequest[_owner];
  }

  /*
   * @notice: Lets Bequest owner set renewal rate
   * @param _rate: New renewal rate
   */
  function _setRenewalRate(uint64 _rate) internal {
    require(_rate >= 1 days, "Invalid input");
    addressToBequest[msg.sender].renewalRate = _rate;
  }

  /*
   * @notice: Lets Bequest owner set token's recipients
   * @param _recipients: Address of token recipients
   * @param _percentages: Percentage alloted to each recipient by index match
   */
  function _setRecipients(Recipient[] calldata _newRecipients) internal {
    Recipient[] storage recipients = addressToBequest[msg.sender].recipients;

    for (uint256 i; i < _newRecipients.length; ) {
      require(_newRecipients[i].percentage > 0, "Invalid recipient");

      if (i < recipients.length) {
        recipients[i] = _newRecipients[i];
      } else {
        recipients.push(_newRecipients[i]);
      }

      unchecked {
        i++;
      }
    }

    for (uint256 i = _newRecipients.length; i < recipients.length; ) {
      recipients.pop();
      unchecked {
        i++;
      }
    }

    emit EditedRecipients(msg.sender);
  }

  /*
   * @notice: Lets Bequest owner set tokens in Bequest
   * @param _tokens: ERC20 contract addresses
   * @param _indexesToReplace: Indexes in the tokens array to remove, in increasing order
   * @dev: Tokens are pre-approved, tokens should not be duplicate
   */
  function _setTokens(
    IERC20[] calldata _newTokens,
    uint256[] memory _indexesToReplace
  ) internal {
    uint256 index;

    IERC20[] storage tokens = addressToBequest[msg.sender].tokens;

    for (uint256 i; i < _newTokens.length; ) {
      if (index < _indexesToReplace.length) {
        tokens[_indexesToReplace[index]] = _newTokens[i];

        unchecked {
          index++;
        }
      } else {
        tokens.push(_newTokens[i]);
      }

      unchecked {
        i++;
      }
    }

    // If there are indexes left to remove, remove in decreasing order (opposite order)
    for (uint256 i = _indexesToReplace.length; i > index; ) {
      uint256 lastTokenIndex = tokens.length - 1;
      uint256 indexToRemove = _indexesToReplace[i - 1];

      if (indexToRemove != lastTokenIndex) {
        tokens[indexToRemove] = tokens[lastTokenIndex];
      }
      tokens.pop();

      unchecked {
        i--;
      }
    }
  }

  /*
   * @param _owner: Bequest owner
   * @returns: True if _owner's Bequest is claimable
   */
  function isClaimable(address _owner) public view returns (bool) {
    Bequest storage bequest = addressToBequest[_owner];
    return block.timestamp >= bequest.renewalRate + bequest.timestamp;
  }

  /*
   * @param _referral: Address
   * @returns: The current creation fee with a possible
   *           referral discount
   */
  function getCreationFee(string calldata _referral)
    public
    view
    returns (uint256)
  {
    uint256 creationFee = bequestYearlyFee;
    if (bytes(_referral).length != 0) {
      Referral storage referralDetails = referralCodes[_referral];

      require(referralDetails.usesLeft > 0, "Referral code expired");
      creationFee = (bequestYearlyFee * (100 - referralDetails.discount)) / 100;
    }
    return creationFee;
  }

  /*
   * @param _owner: Address
   * @returns: The current renewal fee for _owner
   */
  function getRenewalFee(address _owner)
    public
    view
    returns (uint256, uint256)
  {
    uint256 timePassed = block.timestamp -
      addressToBequest[_owner].lastPaidYearlyFee;
    uint256 yearsPassed = timePassed / ONE_YEAR;

    return (yearsPassed * bequestYearlyFee, yearsPassed);
  }

  /*
   * @param _owner: Address
   * @returns A boolean indicatting whether the _owner owns a Bequest
   */
  function isOwner(address _owner) public view returns (bool) {
    return addressToBequest[_owner].timestamp != 0;
  }

  /*
   * @param _owner: Bequest owner address
   * @param _recipient: Recipient address
   * @returns A boolean indicatting whether the _recipent is a recipient
   *          of the _owner's Bequest
   */
  function isRecipient(address _owner, address _recipient)
    public
    view
    returns (bool)
  {
    if (_recipient == address(0)) return false;

    Bequest storage bequest = addressToBequest[_owner];

    for (uint256 i; i < bequest.recipients.length; ) {
      if (bequest.recipients[i].recipient == _recipient) {
        return true;
      }

      unchecked {
        i++;
      }
    }

    for (uint256 i; i < bequest.nfts.length; ) {
      if (bequest.nfts[i].recipient == _recipient) {
        return true;
      }

      unchecked {
        i++;
      }
    }

    return false;
  }

  /*
   * @notice Distributes all ERC20s
   * @param _owner: Owner of Bequest
   * @param _recipient: Recipient address
   * @param _percentage: Percentage alloted to _recipient
   * @param _percentageSum: Sum of percentages alloted to all
   *                        recipients in _owner's Bequest
   */
  function safeSendERC20s(
    address _owner,
    address _recipient,
    uint256 _percentage,
    uint256 _percentageSum
  ) internal {
    Bequest storage bequest = addressToBequest[_owner];

    for (uint256 i; i < bequest.tokens.length; ) {
      IERC20 token = bequest.tokens[i];

      uint256 amount = min(
        getTokenAllowance(_owner, token),
        getBalance(_owner, token)
      );

      uint256 share = (_percentage * amount) / _percentageSum;

      if (share != 0) {
        try token.transferFrom(_owner, _recipient, share) {} catch (
          bytes memory
        ) {}
      }

      unchecked {
        i++;
      }
    }
  }

  /*
   * @notice Sends an NFT
   * @param _owner: Owner of Bequest
   * @param _recipient: Recipient address
   * @param _nft: Address of NFT Contract
   * @param _nft: NFT token ID
   * @dev Only supports ERC721 and ERC1155
   */
  function safeSendNFT(
    address _owner,
    address _recipient,
    IERC165 _nft,
    uint256 _nftId,
    uint256 _amount
  ) internal {
    if (isERC721(_nft)) {
      IERC721 nft = IERC721(address(_nft));
      try nft.safeTransferFrom(_owner, _recipient, _nftId) {} catch (
        bytes memory
      ) {}
    } else if (isERC1155(_nft)) {
      IERC1155 nft = IERC1155(address(_nft));
      uint256 nftBalance;

      try nft.balanceOf(_owner, _nftId) returns (uint256 balance) {
        nftBalance = balance;
      } catch (bytes memory) {}

      if (_amount > 0) nftBalance = min(nftBalance, _amount);

      if (nftBalance > 0) {
        try
          nft.safeTransferFrom(_owner, _recipient, _nftId, nftBalance, "")
        {} catch (bytes memory) {}
      }
    }
  }

  /*
   * @param _nft: NFT address
   * @returns Whether _nft is ERC721
   */
  function isERC721(IERC165 _nft) internal view returns (bool) {
    try _nft.supportsInterface(0x80ac58cd) returns (bool erc721) {
      return erc721;
    } catch (bytes memory) {
      return false;
    }
  }

  /*
   * @param _nft: NFT address
   * @returns Whether _nft is ERC1155
   */
  function isERC1155(IERC165 _nft) internal view returns (bool) {
    try _nft.supportsInterface(0xd9b67a26) returns (bool erc1155) {
      return erc1155;
    } catch (bytes memory) {
      return false;
    }
  }

  /*
   * @param _owner: Bequest owner
   * @param _token: Token contract address
   * @returns: Token allowance
   */
  function getTokenAllowance(address _owner, IERC20 _token)
    internal
    view
    returns (uint256)
  {
    try _token.allowance(_owner, address(this)) returns (uint256 allowance) {
      return allowance;
    } catch (bytes memory) {
      return 0;
    }
  }

  /*
   * @param _owner: Bequest owner
   * @param _token: Token contract address
   * @returns: Token balance
   */
  function getBalance(address _owner, IERC20 _token)
    internal
    view
    returns (uint256)
  {
    try _token.balanceOf(_owner) returns (uint256 balance) {
      return balance;
    } catch (bytes memory) {
      return 0;
    }
  }

  /*
   * @param a: First integer
   * @param b: Second integer
   * @returns Smaller integer
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a <= b ? a : b;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
interface IERC165 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}