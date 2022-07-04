// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./OwnableBase.sol";

interface IERC721Transfers {
  function safeTransferFrom (
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom (
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  function transferFrom (
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract JumpPort is IERC721Receiver, OwnableBase {
  bool public depositPaused;
  bytes32 public constant PORTAL_ROLE = keccak256("PORTAL_ROLE");

  struct LockRecord {
    address parentLock;
    bool isLocked;
  }

  /**
   * @dev Record an Owner's collection balance, and the block it was last updated.
   *
   * Stored as less than uint256 values to fit into one storage slot.
   *
   * This structure will work until approximately the year 2510840694154672305534315769283066566440942177785607
   * (when the block height becomes too large for a uint192), and for oners who don't have more than
   * 18,​446,​744,​073,​709,​551,​615 items from a single collection deposited.
   */
  struct BalanceRecord {
    uint64 balance;
    uint192 blockHeight;
  }

  mapping(address => bool) public lockOverride;
  mapping(address => bool) public executionBlocked;
  mapping(address => mapping(uint256 => mapping(address => LockRecord))) internal portalLocks; // collection address => token ID => portal address => LockRecord
  mapping(address => mapping(uint256 => address)) private currentLock; // collection address => token ID => portal address

  mapping(address => mapping(uint256 => address)) private Owners; // collection address => token ID => owner address
  mapping(address => mapping(address => BalanceRecord)) private OwnerBalances; // collection address => owner Address => count
  mapping(address => mapping(uint256 => uint256)) private DepositBlock; // collection address => token ID => block height
  mapping(address => mapping(uint256 => uint256)) private PingRequestBlock; // collection address => token ID => block height
  mapping(address => mapping(uint256 => address)) private Copilots; // collection address => token ID => copilot address
  mapping(address => mapping(address => bool)) private CopilotApprovals; // owner address => copilot address => is approved

  event Deposit(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId);
  event Withdraw(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, uint256 duration);
  event Approval(address indexed owner, address indexed approved, address indexed tokenAddress, uint256 tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event Lock(address indexed portalAddress, address indexed owner, address indexed tokenAddress, uint256 tokenId);
  event Unlock(address indexed portalAddress, address indexed owner, address indexed tokenAddress, uint256 tokenId);
  event ActionExecuted(address indexed tokenAddress, uint256 indexed tokenId, address target, bytes data);

  constructor (address documentationAddress) OwnableBase(documentationAddress) {}

  /* Deposit Tokens */

  /**
   * @dev Receive a token directly; transferred with the `safeTransferFrom` method of another ERC721 token.
   * @param operator the _msgSender of the transaction
   * @param from the address of the former owner of the incoming token
   * @param tokenId the ID of the incoming token
   * @param data additional metdata
   */
  function onERC721Received (
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) public override whenDepositNotPaused returns (bytes4) {

    Owners[msg.sender][tokenId] = from;
    unchecked {
      OwnerBalances[msg.sender][from].balance++;
      OwnerBalances[msg.sender][from].blockHeight = uint192(block.number);
    }
    DepositBlock[msg.sender][tokenId] = block.number;
    PingRequestBlock[msg.sender][tokenId] = 0;
    emit Deposit(from, msg.sender, tokenId);

    return IERC721Receiver.onERC721Received.selector;
  }

  /**
   * @dev Deposit an individual token from a specific collection.
   * To be successful, the JumpPort contract must be "Approved" to move this token on behalf
   * of the current owner, in the token's contract.
   */
  function deposit (address tokenAddress, uint256 tokenId) public whenDepositNotPaused {
    IERC721Transfers(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
    Owners[tokenAddress][tokenId] = msg.sender;
    unchecked {
      OwnerBalances[tokenAddress][msg.sender].balance++;
      OwnerBalances[tokenAddress][msg.sender].blockHeight = uint192(block.number);
    }
    DepositBlock[tokenAddress][tokenId] = block.number;
    PingRequestBlock[tokenAddress][tokenId] = 0;
    emit Deposit(msg.sender, tokenAddress, tokenId);
  }

  /**
   * @dev Deposit multiple tokens from a single collection.
   * To be successful, the JumpPort contract must be "Approved" to move these tokens on behalf
   * of the current owner, in the token's contract.
   */
  function deposit (address tokenAddress, uint256[] calldata tokenIds) public {
    unchecked {
      for (uint256 i; i < tokenIds.length; i++) {
        deposit(tokenAddress, tokenIds[i]);
      }
    }
  }

  /**
   * @dev Deposit multiple tokens from multiple different collections.
   * To be successful, the JumpPort contract must be "Approved" to move these tokens on behalf
   * of the current owner, in the token's contract.
   */
  function deposit (address[] calldata tokenAddresses, uint256[] calldata tokenIds) public {
    require(tokenAddresses.length == tokenIds.length, "Mismatched inputs");
    unchecked {
      for (uint256 i; i < tokenIds.length; i++) {
        deposit(tokenAddresses[i], tokenIds[i]);
      }
    }
  }

  /* Withdraw Tokens */

  /**
   * @dev Internal helper function that clears out the tracked metadata for the token.
   * Does not do any permission checks, and does not do the actual transferring of the token.
   */
  function _withdraw (address tokenAddress, uint256 tokenId) internal {
    address currentOwner = Owners[tokenAddress][tokenId];
    emit Withdraw(
      currentOwner,
      tokenAddress,
      tokenId,
      block.number - DepositBlock[tokenAddress][tokenId]
    );
    unchecked {
      OwnerBalances[tokenAddress][currentOwner].balance--;
      OwnerBalances[tokenAddress][currentOwner].blockHeight = uint192(block.number);
    }
    Owners[tokenAddress][tokenId] = address(0);
    DepositBlock[tokenAddress][tokenId] = 0;
    Copilots[tokenAddress][tokenId] = address(0);
  }

  /**
   * @dev Withdraw a token, to the owner's address, using `safeTransferFrom`, with no additional data.
   */
  function safeWithdraw (address tokenAddress, uint256 tokenId)
    public
    isPilot(tokenAddress, tokenId)
    withdrawAllowed(tokenAddress, tokenId)
  {
    address ownerAddress = Owners[tokenAddress][tokenId];
    _withdraw(tokenAddress, tokenId);
    IERC721Transfers(tokenAddress).safeTransferFrom(address(this), ownerAddress, tokenId);
  }

  /**
   * @dev Withdraw a token, to the owner's address, using `safeTransferFrom`, with additional calldata.
   */
  function safeWithdraw (address tokenAddress, uint256 tokenId, bytes calldata data)
    public
    isPilot(tokenAddress, tokenId)
    withdrawAllowed(tokenAddress, tokenId)
  {
    address ownerAddress = Owners[tokenAddress][tokenId];
    _withdraw(tokenAddress, tokenId);
    IERC721Transfers(tokenAddress).safeTransferFrom(address(this), ownerAddress, tokenId, data);
  }

  /**
   * @dev Bulk withdraw multiple tokens, using `safeTransferFrom`, with no additional data.
   */
  function safeWithdraw (address[] calldata tokenAddresses, uint256[] calldata tokenIds) public {
    require(tokenAddresses.length == tokenIds.length, "Inputs mismatched");
    for(uint256 i = 0; i < tokenAddresses.length; i++) {
      safeWithdraw(tokenAddresses[i], tokenIds[i]);
    }
  }

  /**
   * @dev Bulk withdraw multiple tokens, using `safeTransferFrom`, with additional calldata.
   */
  function safeWithdraw (address[] calldata tokenAddresses, uint256[] calldata tokenIds, bytes[] calldata data) public {
    require(tokenAddresses.length == tokenIds.length, "Inputs mismatched");
    for(uint256 i = 0; i < tokenAddresses.length; i++) {
      safeWithdraw(tokenAddresses[i], tokenIds[i], data[i]);
    }
  }

  /**
   * @dev Withdraw a token, to the owner's address, using `transferFrom`.
   * USING `transferFrom` RATHER THAN `safeTransferFrom` COULD RESULT IN LOST TOKENS. USE `safeWithdraw` FUNCTIONS
   * WHERE POSSIBLE, OR DOUBLE-CHECK RECEIVING ADDRESSES CAN HOLD TOKENS IF USING THIS FUNCTION.
   */
  function withdraw (address tokenAddress, uint256 tokenId)
    public
    isPilot(tokenAddress, tokenId)
    withdrawAllowed(tokenAddress, tokenId)
  {
    address ownerAddress = Owners[tokenAddress][tokenId];
    _withdraw(tokenAddress, tokenId);
    IERC721Transfers(tokenAddress).transferFrom(address(this), ownerAddress, tokenId);
  }

  /**
   * @dev Bulk withdraw multiple tokens, to specific addresses, using `transferFrom`.
   * USING `transferFrom` RATHER THAN `safeTransferFrom` COULD RESULT IN LOST TOKENS. USE `safeWithdraw` FUNCTIONS
   * WHERE POSSIBLE, OR DOUBLE-CHECK RECEIVING ADDRESSES CAN HOLD TOKENS IF USING THIS FUNCTION.
   */
  function withdraw (address[] calldata tokenAddresses, uint256[] calldata tokenIds) public {
    require(tokenAddresses.length == tokenIds.length, "Inputs mismatched");
    for(uint256 i = 0; i < tokenAddresses.length; i++) {
      withdraw(tokenAddresses[i], tokenIds[i]);
    }
  }

  /**
   * @dev Designate another address that can act on behalf of this token.
   * This allows the Copliot address to withdraw the token from the JumpPort, and interact with any Portal
   * on behalf of this token.
   */
  function setCopilot (address copilot, address tokenAddress, uint256 tokenId) public {
    require(Owners[tokenAddress][tokenId] == msg.sender, "Not the owner of that token");
    require(msg.sender != copilot, "approve to caller");
    Copilots[tokenAddress][tokenId] = copilot;
    emit Approval(msg.sender, copilot, tokenAddress, tokenId);
  }

  /**
   * @dev Designate another address that can act on behalf of all tokens owned by the sender's address.
   * This allows the Copliot address to withdraw the token from the JumpPort, and interact with any Portal
   * on behalf of any token owned by the sender.
   */
  function setCopilotForAll (address copilot, bool approved) public {
    require(msg.sender != copilot, "approve to caller");
    CopilotApprovals[msg.sender][copilot] = approved;
    emit ApprovalForAll(msg.sender, copilot, approved);
  }

  /* Receive actions from Portals */

  /**
   * @dev Lock a token into the JumpPort.
   * Causes a token to not be able to be withdrawn by its Owner, until the same Portal contract calls the `unlockToken` function for it,
   * or the locks for that portal are all marked as invalid (either by JumpPort administrators, or the Portal itself).
   */
  function lockToken (address tokenAddress, uint256 tokenId) public tokenDeposited(tokenAddress, tokenId) onlyRole(PORTAL_ROLE) {
    if (portalLocks[tokenAddress][tokenId][msg.sender].isLocked) return; // Already locked; nothing to do

    // Check if this lock is already in the chain of "active" locks
    address checkPortal = currentLock[tokenAddress][tokenId];
    while (checkPortal != address(0)) {
      if (checkPortal == msg.sender) {
        // This portal is already in the chain of active locks
        portalLocks[tokenAddress][tokenId][msg.sender].isLocked = true;
        emit Lock(msg.sender, Owners[tokenAddress][tokenId], tokenAddress, tokenId);
        return;
      }
      checkPortal = portalLocks[tokenAddress][tokenId][checkPortal].parentLock;
    }

    // Looped through all active locks and didn't find this Portal. So, add it as the new head
    portalLocks[tokenAddress][tokenId][msg.sender] = LockRecord(currentLock[tokenAddress][tokenId], true);
    currentLock[tokenAddress][tokenId] = msg.sender;
    emit Lock(msg.sender, Owners[tokenAddress][tokenId], tokenAddress, tokenId);
  }

  /**
   * @dev Unlocks a token held in the JumpPort.
   * Does not withdraw the token from the JumpPort, but makes it available for withdraw whenever the Owner wishes to.
   */
  function unlockToken (address tokenAddress, uint256 tokenId) public tokenDeposited(tokenAddress, tokenId) onlyRole(PORTAL_ROLE) {
    portalLocks[tokenAddress][tokenId][msg.sender].isLocked = false;
    emit Unlock(msg.sender, Owners[tokenAddress][tokenId], tokenAddress, tokenId);
    if (!isLocked(tokenAddress, tokenId)) {
      currentLock[tokenAddress][tokenId] = address(0);
    }
  }

  /**
   * @dev Take an action as the JumpPort (the owner of the tokens within it), as directed by a Portal.
   * This is a powerful function and Portals that wish to use it NEEDS TO MAKE SURE its execution is guarded by
   * checks to ensure the address passed as `operator` to this function is the one authorizing the action
   * (in most cases, it should be the `msg.sender` communicating to the Portal), and that the `payload`
   * being passed in operates on the `tokenId` indicated, and no other tokens.
   *
   * Here on the JumpPort side, it verifies that the `operator` passed in is the current owner or a Copilot of the
   * token being operated upon, but has to trust the Portal that the passed-in `tokenId` matches what token
   * will get acted upon in the `payload`.
   */
  function executeAction (address operator, address tokenAddress, uint256 tokenId, address targetAddress, bytes calldata payload)
    public
    payable
    tokenDeposited(tokenAddress, tokenId)
    onlyRole(PORTAL_ROLE)
    returns(bytes memory result)
  {
    require(executionBlocked[msg.sender] == false, "Execution blocked for that Portal");

    // Check if operator is allowed to act for this token
    address owner = Owners[tokenAddress][tokenId];
    require(
      operator == owner || operator == Copilots[tokenAddress][tokenId] || CopilotApprovals[owner][operator] == true,
      "Not an operator of that token"
    );

    // Make the external call
    (bool success, bytes memory returnData) = targetAddress.call{ value: msg.value }(payload);
    if (success == false) {
      if (returnData.length == 0) {
        revert("Executing action on other contract failed");
      } else {
        assembly {
          revert(add(32, returnData), mload(returnData))
        }
      }
    } else {
      emit ActionExecuted(tokenAddress, tokenId, targetAddress, payload);
      return returnData;
    }
  }

  /**
   * @dev Unlocks all locks held by a Portal.
   * Intended to be called in the situation of a large failure of an individual Portal's operation,
   * as a way for the Portal itself to indicate it has failed, and all tokens that were previously
   * locked by it should be allowed to exit.
   *
   * This function only allows Portals to enable/disable the locks they created. The function `setAdminLockOverride`
   * is similar, but allows JumpPort administrators to set/clear the lock ability for any Portal contract.
   */
  function unlockAllTokens (bool isOverridden) public onlyRole(PORTAL_ROLE) {
    lockOverride[msg.sender] = isOverridden;
  }

  /**
   * @dev Prevent a Portal from executing calls to other contracts.
   * Intended to be called in the situation of a large failure of an individual Portal's operation,
   * as a way for the Portal itself to indicate it has failed, and arbitrary contract calls should not
   * be allowed to originate from it.
   *
   * This function only allows Portals to enable/disable their own execution right. The function `setAdminExecutionBlocked`
   * is similar, but allows JumpPort administrators to set/clear the execution block for any Portal contract.
   */
  function blockExecution (bool isBlocked) public onlyRole(PORTAL_ROLE) {
    executionBlocked[msg.sender] = isBlocked;
  }

  /* View functions */

  /**
   * @dev Is the specified token currently deposited in the JumpPort?
   */
  function isDeposited (address tokenAddress, uint256 tokenId) public view returns (bool) {
    return Owners[tokenAddress][tokenId] != address(0);
  }

  /**
   * @dev When was the specified token deposited in the JumpPort?
   */
  function depositedSince (address tokenAddress, uint256 tokenId) public view tokenDeposited(tokenAddress, tokenId) returns (uint256 blockNumber) {
    blockNumber = DepositBlock[tokenAddress][tokenId];
  }

  /**
   * @dev Is the specified token currently locked in the JumpPort?
   * If any Portal contract has a valid lock (the Portal has indicated the token should be locked,
   * and the Portal's locking rights haven't been overridden) on the token, this function will return true.
   */
  function isLocked (address tokenAddress, uint256 tokenId) public view tokenDeposited(tokenAddress, tokenId) returns (bool) {
    address checkPortal = currentLock[tokenAddress][tokenId];
    while (checkPortal != address(0)) {
      if (portalLocks[tokenAddress][tokenId][checkPortal].isLocked && lockOverride[checkPortal] == false) return true;
      checkPortal = portalLocks[tokenAddress][tokenId][checkPortal].parentLock;
    }
    return false;
  }

  /**
   * @dev Get a list of all Portal contract addresses that hold a valid lock (the Portal has indicated the token should be locked,
   * and the Portal's locking rights haven't been overridden) on the token.
   */
  function lockedBy (address tokenAddress, uint256 tokenId) public view returns (address[] memory) {
    address[] memory lockedRaw = new address[](500);
    uint256 index = 0;
    address checkPortal = currentLock[tokenAddress][tokenId];
    while (checkPortal != address(0)) {
      if (portalLocks[tokenAddress][tokenId][checkPortal].isLocked && lockOverride[checkPortal] == false) {
        lockedRaw[index] = checkPortal;
        index++;
      }
      checkPortal = portalLocks[tokenAddress][tokenId][checkPortal].parentLock;
    }

    address[] memory lockedFinal = new address[](index);
    unchecked {
      for (uint256 i = 0; i < index; i++) {
        lockedFinal[i] = lockedRaw[i];
      }
    }
    return lockedFinal;
  }

  /**
   * @dev Who is the owner of the specified token that is deposited in the JumpPort?
   * A core tenent of the JumpPort is that this value will not change while the token is deposited;
   * a token cannot change owners while in the JumpPort, though they can add/remove Copilots.
   */
  function ownerOf (address tokenAddress, uint256 tokenId) public view tokenDeposited(tokenAddress, tokenId) returns (address owner) {
    owner = Owners[tokenAddress][tokenId];
  }

  /**
   * @dev Who are the owners of a specified range of tokens in a collection?
   * Bulk query function, to be able to enumerate a whole token collection more easily on the client end
   */
  function ownersOf (address tokenAddress, uint256 tokenSearchStart, uint256 tokenSearchEnd) public view returns (address[] memory tokenOwners) {
    unchecked {
      require(tokenSearchEnd >= tokenSearchStart, "Search parameters out of order");
      tokenOwners = new address[](tokenSearchEnd - tokenSearchStart + 1);
      for (uint256 i = tokenSearchStart; i <= tokenSearchEnd; i++) {
        tokenOwners[i - tokenSearchStart] = Owners[tokenAddress][i];
      }
    }
  }

  /**
   * @dev For a specified owner address, what tokens in the specified range do they own?
   * Bulk query function, to be able to enumerate a specific address' collection more easily on the client end
   */
  function ownedTokens (address tokenAddress, address owner, uint256 tokenSearchStart, uint256 tokenSearchEnd) public view returns (uint256[] memory tokenIds) {
    unchecked {
      require(tokenSearchEnd >= tokenSearchStart, "Search parameters out of order");
      require(owner != address(0), "Balance query for the zero address");
      uint256[] memory ownedRaw = new uint256[](tokenSearchEnd - tokenSearchStart);
      uint256 index = 0;
      for (uint256 i = tokenSearchStart; i <= tokenSearchEnd; i++) {
        if (Owners[tokenAddress][i] == owner) {
          ownedRaw[index] = i;
          index++;
        }
      }
      uint256[] memory ownedFinal = new uint256[](index);
      for (uint256 i = 0; i < index; i++) {
        ownedFinal[i] = ownedRaw[i];
      }
      return ownedFinal;
    }
  }

  /**
   * @dev For a specific token collection, how many tokens in that collection does a specific owning address own in the JumpPort?
   */
  function balanceOf (address tokenAddress, address owner) public view returns (BalanceRecord memory) {
    require(owner != address(0), "Balance query for the zero address");
    return OwnerBalances[tokenAddress][owner];
  }

  /**
   * @dev For a specific set of token collections, how many tokens total does a specific owning address own in the JumpPort?
   * Bulk query function, to be able to enumerate a specific address' collection more easily on the client end
   */
  function balanceOf (address[] calldata tokenAddresses, address owner) public view returns (uint256) {
    require(owner != address(0), "Balance query for the zero address");
    uint256 totalBalance = 0;
    unchecked {
      for (uint256 i = 0; i < tokenAddresses.length; i++) {
        totalBalance += OwnerBalances[tokenAddresses[i]][owner].balance;
      }
    }
    return totalBalance;
  }

  /**
   * @dev For a specific token, which other address is approved to act as the owner of that token for actions pertaining to the JumpPort?
   */
  function getApproved (address tokenAddress, uint256 tokenId) public view tokenDeposited(tokenAddress, tokenId) returns (address copilot) {
    copilot = Copilots[tokenAddress][tokenId];
  }

  /**
   * @dev For a specific owner's address, is the specified operator address allowed to act as the owner for actions pertaining to the JumpPort?
   */
  function isApprovedForAll (address owner, address operator) public view returns (bool) {
    return CopilotApprovals[owner][operator];
  }

  /* Modifiers */

  /**
   * @dev Prevent execution if the specified token is not currently deposited in the JumpPort.
   */
  modifier tokenDeposited (address tokenAddress, uint256 tokenId) {
    require(Owners[tokenAddress][tokenId] != address(0), "Not currently deposited");
    _;
  }

  /**
   * @dev Prevent execution if deposits to the JumpPort overall are paused.
   */
  modifier whenDepositNotPaused () {
    require(depositPaused == false, "Paused");
    _;
  }

  /**
   * @dev Prevent execution if the specified token is locked by any Portal currently.
   */
  modifier withdrawAllowed (address tokenAddress, uint256 tokenId) {
    require(!isLocked(tokenAddress, tokenId), "Token is locked");
    _;
  }

  /**
   * @dev Prevent execution if the transaction sender is not the owner nor Copliot for the specified token.
   */
  modifier isPilot (address tokenAddress, uint256 tokenId) {
    address owner = Owners[tokenAddress][tokenId];
    require(
      msg.sender == owner || msg.sender == Copilots[tokenAddress][tokenId] || CopilotApprovals[owner][msg.sender] == true,
      "Not an operator of that token"
    );
    _;
  }

  /* Administration */

  /**
   * @dev Add or remove the "Portal" role to a specified address.
   */
  function setPortalValidation (address portalAddress, bool isValid) public onlyRole(ADMIN_ROLE) {
    roles[PORTAL_ROLE][portalAddress] = isValid;
    emit RoleChange(PORTAL_ROLE, portalAddress, isValid, msg.sender);
  }

  /**
   * @dev Prevent new tokens from being added to the JumpPort.
   */
  function setPaused (bool isDepositPaused)
    public
    onlyRole(ADMIN_ROLE)
  {
    depositPaused = isDepositPaused;
  }

  /**
   * @dev As an administrator of the JumpPort contract, set a Portal's locks to be valid or not.
   *
   * This function allows JumpPort administrators to set/clear the override for any Portal contract.
   * The `unlockAllTokens` function is similar (allowing Portal addresses to set/clear lock overrides as well)
   * but only for their own Portal address.
   */
  function setAdminLockOverride (address portal, bool isOverridden) public onlyRole(ADMIN_ROLE) {
    lockOverride[portal] = isOverridden;
  }

  /**
   * @dev As an administrator of the JumpPort contract, set a Portal to be able to execute other functions or not.
   *
   * This function allows JumpPort administrators to set/clear the execution block for any Portal contract.
   * The `blockExecution` function is similar (allowing Portal addresses to set/clear lock overrides as well)
   * but only for their own Portal address.
   */
  function setAdminExecutionBlocked (address portal, bool isBlocked) public onlyRole(ADMIN_ROLE) {
    executionBlocked[portal] = isBlocked;
  }

  /**
   * @dev Contract owner requesting the owner of a token check in.
   * This starts the process of the owner of the contract being able to remove any token, after a time delay.
   * If the current owner does not want the token removed, they have 2,400,000 blocks (about one year)
   * to trigger the `ownerPong` method, which will abort the withdraw
   */
  function adminWithdrawPing (address tokenAddress, uint256 tokenId)
    public
    onlyRole(ADMIN_ROLE)
  {
    require(Owners[tokenAddress][tokenId] != address(0), "Token not deposited");
    PingRequestBlock[tokenAddress][tokenId] = block.number;
  }

  /**
   * @dev As the owner of a token, abort an attempt to force-remove it.
   * The owner of the contract can remove any token from the JumpPort, if they trigger the `adminWithdrawPing` function
   * for that token, and the owner does not respond by calling this function within 2,400,000 blocks (about one year)
   */
  function ownerPong (address tokenAddress, uint256 tokenId) public isPilot(tokenAddress, tokenId) {
    PingRequestBlock[tokenAddress][tokenId] = 0;
  }

  /**
   * @dev As an Administrator, abort an attempt to force-remove a token.
   * This is a means for the Administration to change its mind about a force-withdraw, or to correct the actions of a rogue Administrator.
   */
  function adminPong (address tokenAddress, uint256 tokenId) public onlyRole(ADMIN_ROLE) {
    PingRequestBlock[tokenAddress][tokenId] = 0;
  }

  /**
   * @dev Check if a token has a ping from the contract Administration pending, and if so, what block it was requested at
   * Returns zero if there is no request pending.
   */
  function tokenPingRequestBlock (address tokenAddress, uint256 tokenId) public view returns (uint256 blockNumber) {
    return PingRequestBlock[tokenAddress][tokenId];
  }

  /**
   * @dev Check if a set of tokens have a ping from the contract Administration pending, and if so, what block it was requested at
   * Returns zero for a token if there is no request pending for that token.
   */
  function tokenPingRequestBlocks (address[] calldata tokenAddresses, uint256[] calldata tokenIds) public view returns(uint256[] memory blockNumbers) {
    require(tokenAddresses.length == tokenIds.length, "Inputs mismatched");
    unchecked {
      blockNumbers = new uint256[](tokenAddresses.length);
      for (uint256 i = 0; i < tokenAddresses.length; i++) {
        blockNumbers[i] = PingRequestBlock[tokenAddresses[i]][tokenIds[i]];
      }
    }
  }

  /**
   * @dev Rescue ERC721 assets sent directly to this contract.
   */
  function withdrawForeignERC721 (address tokenContract, uint256 tokenId)
    public
    override
    onlyRole(ADMIN_ROLE)
  {
    if (Owners[tokenContract][tokenId] == address(0)) {
      // This token got here without being properly recorded; allow withdraw immediately
      DepositBlock[tokenContract][tokenId] = 0;
      Copilots[tokenContract][tokenId] = address(0);
      IERC721(tokenContract).safeTransferFrom(
        address(this),
        msg.sender,
        tokenId
      );
      return;
    }

    // This token is deposited into the JumpPort in a valid manner.
    // Only allow contract-owner withdraw if owner does not respond to ping
    unchecked {
      require(PingRequestBlock[tokenContract][tokenId] > 0 && PingRequestBlock[tokenContract][tokenId] < block.number - 2_400_000, "Owner ping has not expired");
    }
    currentLock[tokenContract][tokenId] = address(0); // Remove all locks on this token
    _withdraw(tokenContract, tokenId);
    IERC721(tokenContract).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId
    );
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface IReverseResolver {
  function claim (address owner) external returns (bytes32);
}

interface IERC20 {
  function balanceOf (address account) external view returns (uint256);
  function transfer (address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
  function safeTransferFrom (address from, address to, uint256 tokenId ) external;
}

interface IDocumentationRepository {
  function doc (address contractAddress) external view returns (string memory name, string memory description, string memory details);
}

error MissingRole(bytes32 role, address operator);

abstract contract OwnableBase {
  bytes32 public constant ADMIN_ROLE = 0x00;
  mapping(bytes32 => mapping(address => bool)) internal roles; // role => operator => hasRole
  mapping(bytes32 => uint256) internal validSignatures; // message hash => expiration block height
  IDocumentationRepository public DocumentationRepository;

  event RoleChange (bytes32 indexed role, address indexed account, bool indexed isGranted, address sender);

  constructor (address documentationAddress) {
    roles[ADMIN_ROLE][msg.sender] = true;
    DocumentationRepository = IDocumentationRepository(documentationAddress);
  }

  function doc () public view returns (string memory name, string memory description, string memory details) {
    return DocumentationRepository.doc(address(this));
  }

  /**
   * @dev See {ERC1271-isValidSignature}.
   */
  function isValidSignature(bytes32 hash, bytes memory)
    external
    view
    returns (bytes4 magicValue)
  {
    if (validSignatures[hash] >= block.number) {
      return 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    } else {
      return 0xffffffff;
    }
  }

  /**
   * @dev Inspect whether a specific address has a specific role.
   */
  function hasRole (bytes32 role, address account) public view returns (bool) {
    return roles[role][account];
  }

  /* Modifiers */

  modifier onlyRole (bytes32 role) {
    if (roles[role][msg.sender] != true) revert MissingRole(role, msg.sender);
    _;
  }

  /* Administration */

  /**
   * @dev Allow current administrators to be able to grant/revoke admin role to other addresses.
   */
  function setAdmin (address account, bool isAdmin) public onlyRole(ADMIN_ROLE) {
    roles[ADMIN_ROLE][account] = isAdmin;
    emit RoleChange(ADMIN_ROLE, account, isAdmin, msg.sender);
  }

  /**
   * @dev Claim ENS reverse-resolver rights for this contract.
   * https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
   */
  function setReverseResolver (address registrar) public onlyRole(ADMIN_ROLE) {
    IReverseResolver(registrar).claim(msg.sender);
  }

  /**
   * @dev Update address for on-chain documentation lookup.
   */
  function setDocumentationRepository (address documentationAddress) public onlyRole(ADMIN_ROLE) {
    DocumentationRepository = IDocumentationRepository(documentationAddress);
  }

  /**
   * @dev Set a message as valid, to be queried by ERC1271 clients.
   */
  function markMessageSigned (bytes32 hash, uint256 expirationLength) public onlyRole(ADMIN_ROLE) {
    validSignatures[hash] = block.number + expirationLength;
  }

  /**
   * @dev Rescue ERC20 assets sent directly to this contract.
   */
  function withdrawForeignERC20 (address tokenContract) public onlyRole(ADMIN_ROLE) {
    IERC20 token = IERC20(tokenContract);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  /**
   * @dev Rescue ERC721 assets sent directly to this contract.
   */
  function withdrawForeignERC721 (address tokenContract, uint256 tokenId)
    public
    virtual
    onlyRole(ADMIN_ROLE)
  {
    IERC721(tokenContract).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId
    );
  }

  function withdrawEth () public onlyRole(ADMIN_ROLE) {
    payable(msg.sender).transfer(address(this).balance);
  }

}