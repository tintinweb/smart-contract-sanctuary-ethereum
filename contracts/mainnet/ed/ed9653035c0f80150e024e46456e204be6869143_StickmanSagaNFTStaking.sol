/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: AGPL-3.0-only

//AUTHOR: NIKE :)

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
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

interface IOwnable {
    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyManager() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ITreasury {
    function transferRewards( address _recipient, uint _amount ) external;
}

interface IOHMERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}


interface IStickmanERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

contract StickmanSagaNFTStaking is Ownable, IERC721Receiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public nftContract;
  address public stixToken;

  bool public locked; // Locks all deposits, claims, and withdrawls
  uint256 public withdrawlFee; //fee in ETH for withdrawing staked NFT
  uint256 public claimLength; // Length of time between claims
  uint256 public claimReward = 49*(10**18); // Reward per Stickman staked
 
  mapping(address => vestedInfo) public inventory; // Each token ID mapped to the info about each one
  mapping(uint8 => uint256) public stakingTimestamps;

  struct vestedInfo {
    uint256 lastClaimTime; // Current length of time between claims
    bool locked; // Lock NFT to prevent claiming or withdraw
    uint8[] depositedNFTs; //keep track of all the NFTs deposited
    uint256 rewardAmount; //when number of NFTs changes, update this number
    uint256 initialDepositDate;
  }

  uint256[] public rewardChangeTime; //tracks when rewards are changed, used to calculate rewards over multiple claim rewards
  mapping (uint256 => uint256) public rewardAmounts; //tracks reward amount when they are changed, used to calculate rewards over multiple claim rewards
  
  /** reentrancy */
  uint256 private guard = 1;
  modifier reentrancyGuard() {
      require (guard == 1, "reentrancy failure.");
      guard = 2;
      _;
      guard = 1;
  }

  // modifiers
  modifier checkNFTOwner(uint8[] calldata tokenIds, address owner){
    for (uint256 index = 0; index < tokenIds.length; index++) {
      require(owner == IStickmanERC721(nftContract).ownerOf(tokenIds[index]), "You can only deposit NFTs that are yours.");
    }
    _;
  }

  modifier checkNFTOwnerInContract(uint8 token, address owner){
    bool correctOwner = false;
    for (uint256 index = 0; index < inventory[owner].depositedNFTs.length; index++) {
      if(token == inventory[owner].depositedNFTs[index]){
        correctOwner = true;
      }
    }
    require(correctOwner, "You can only withdraw NFTs that are yours.");
    _;
  }

  modifier checkFees(uint8[] calldata tokenIds){
    uint256 totalFee=0;
    for (uint256 index = 0; index < tokenIds.length; index++) {
      if(stakingTimestamps[tokenIds[index]] + 30 days >  block.timestamp){
        totalFee += withdrawlFee;
      }
    }
    require(msg.value >= totalFee, "Must send the correct fee amount.");
    _;
  }

  constructor(
    address _nftContract, // Stickman Saga NFT contract
    address _stixToken // STIX token contract
  ) {
    nftContract = _nftContract;
    claimLength = 1 days;
    stixToken = _stixToken;
    withdrawlFee = .01 * 10**18;
    rewardChangeTime.push(block.timestamp);
    rewardAmounts[block.timestamp] = 49*(10**18);
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

  function depositNFTs(uint8[] calldata tokenIds) public reentrancyGuard checkNFTOwner(tokenIds, msg.sender) {
    require(!locked, "Deposit: All deposits are currently locked.");
    require(tokenIds.length + inventory[msg.sender].depositedNFTs.length >= 2, "Deposit: you must deposit at least 2 NFTs");
    claimBalance(msg.sender);

    for (uint256 index = 0; index < tokenIds.length; index++) {
      require(IStickmanERC721(nftContract).ownerOf(tokenIds[index]) == msg.sender, "Deposit: You are not the owner of this token ID.");
      inventory[msg.sender].depositedNFTs.push(tokenIds[index]);
      IStickmanERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenIds[index]);
      stakingTimestamps[tokenIds[index]] = block.timestamp;
    }
  }

  function withdraw(uint8[] calldata tokenIds) public payable reentrancyGuard checkFees(tokenIds) {
    require(!locked, "Withdraw: All withdrawls are currently locked.");
    require(!inventory[msg.sender].locked, "Withdraw: Withdraw is locked for this token ID.");
    require(inventory[msg.sender].depositedNFTs.length-tokenIds.length != 1, "Withdrawl: must keep at least two NFTs staked.");
    for (uint256 index = 0; index < tokenIds.length; index++) {
      transferNFTs(tokenIds[index], msg.sender);
    }
    claimBalance(msg.sender);
  }
  
  function claim() public reentrancyGuard {
    require(!locked, "Claim: All claims are currently locked.");
    claimBalance(msg.sender);
  }

  function balanceOf(address _address) public view returns (uint) {
    return inventory[_address].depositedNFTs.length;
  }

  // Policy Functions
  function setClaimlength(uint256 _claimLength) public onlyManager() {
    claimLength = _claimLength;
  }

  function pullWithdrawlFees() external onlyManager() {
      uint256 total = address(this).balance;
      payable(_owner).transfer(total);
  }  

  function setWithdrawalFee(uint256 newFee) public onlyManager() {
    withdrawlFee = newFee;
  }

  function setClaimReward(uint256 newClaimReward) public onlyManager(){
    rewardChangeTime.push(block.timestamp);
    rewardAmounts[block.timestamp] = newClaimReward;
    claimReward = newClaimReward;
  }

  function managerSafeNFTWithdrawal(uint256[] calldata tokenIDs, address recipient) public onlyManager() {
    for (uint256 index = 0; index < tokenIDs.length; index++) {
          deleteDeposit(tokenIDs[index], recipient);
          IStickmanERC721(nftContract).safeTransferFrom(address(this), recipient, tokenIDs[index]);
    }
  }

  function managerBypassNFTWithdrawal(uint256 tokenID) public onlyManager() {
    IStickmanERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenID); // Forcefully withdraw NFT and bypass deleteDeposit() in emergency or incase of accidental transfer
  }

  function managerTokenWithdrawal(address tokenAddress, address recipient) public onlyManager() {
    IERC20(tokenAddress).safeTransferFrom(address(this), recipient, IERC20(tokenAddress).balanceOf(address(this)));
  }

  function managerTokenTransfer(address tokenAddress, address recipient, uint256 amount) public onlyManager() {
    IERC20(tokenAddress).safeTransferFrom(address(this), recipient, amount);
  }

  function toggleNFTLock(address user) public onlyManager() {
    require(user == address(0x0), "toggleNFTLock: Token ID does not exist.");
    inventory[user].locked = !inventory[user].locked;
  }

  function toggleLock() public onlyManager() {
    locked = !locked;
  }

  enum CONTRACTS { nftContract, stixToken }
  function setContract(CONTRACTS _contracts, address _address) public onlyManager() {
    if (_contracts == CONTRACTS.nftContract) { // 0
      nftContract = _address;
    }else if (_contracts == CONTRACTS.stixToken) { // 2
      stixToken = _address;
    } 
  }

  // Internal Functions
  function getMultiplier(uint numStakedNFTs) internal pure returns(uint){
    if (numStakedNFTs == 2) {
      return 10;
    } 
    else if (numStakedNFTs == 3){
      return 11;
    }
    else if (numStakedNFTs == 4){
      return 12;
    }
    else if (numStakedNFTs >= 5){
      return 13;
    }
    else {
      return 0;
    }
  }

  function deleteDeposit(uint256 tokenId, address _recipient) internal {
    uint8[] memory list = new uint8[](inventory[_recipient].depositedNFTs.length-1);
      uint z=0;
      for (uint i=0; i < inventory[_recipient].depositedNFTs.length; i++) {
        if (inventory[_recipient].depositedNFTs[i] != tokenId) {
          list[z] = inventory[_recipient].depositedNFTs[i];
          z++;
        }
      }
      inventory[_recipient].depositedNFTs = list;
  }

  function transferNFTs(uint8 token, address recipient) internal checkNFTOwnerInContract(token, recipient) {
      IStickmanERC721(nftContract).safeTransferFrom(address(this), recipient, token);
      deleteDeposit(token, recipient);
  }

  function claimBalance(address _recipient) internal {
      uint256 rewards = calculateRewards(_recipient);
      if(rewards > 0){
        IERC20(stixToken).transfer(
        _recipient, 
        rewards
      );
    }
    
    inventory[_recipient].lastClaimTime = block.timestamp - ((block.timestamp-inventory[_recipient].lastClaimTime) % claimLength);
  }

  function calculateRewards(address _recipient) public view returns (uint256){
    uint256 rewards = 0;
    for (uint256 index = 1; index <= rewardChangeTime.length; index++) {
      uint256 currentClaimReward = rewardAmounts[rewardChangeTime[rewardChangeTime.length-index]];
      if (rewards > 0){
        if(inventory[_recipient].lastClaimTime > rewardChangeTime[rewardChangeTime.length-index]){
          rewards += (rewardChangeTime[rewardChangeTime.length-index+1] - inventory[_recipient].lastClaimTime).div(claimLength).mul(currentClaimReward).mul(inventory[_recipient].depositedNFTs.length);
          return rewards.mul(getMultiplier(inventory[_recipient].depositedNFTs.length)).div(10);
        }
        else{
          rewards += (rewardChangeTime[rewardChangeTime.length-index+1] - rewardChangeTime[rewardChangeTime.length-index]).div(claimLength).mul(currentClaimReward).mul(inventory[_recipient].depositedNFTs.length);
        }
      }
      else{
        if(inventory[_recipient].lastClaimTime > rewardChangeTime[rewardChangeTime.length-index]){
          rewards += (block.timestamp - inventory[_recipient].lastClaimTime).div(claimLength).mul(claimReward).mul(inventory[_recipient].depositedNFTs.length);
          return rewards.mul(getMultiplier(inventory[_recipient].depositedNFTs.length)).div(10);
        }
        else{
          rewards += (block.timestamp - rewardChangeTime[rewardChangeTime.length-index]).div(claimLength).mul(claimReward).mul(inventory[_recipient].depositedNFTs.length);
        }
      }
    }

    return rewards.mul(getMultiplier(inventory[_recipient].depositedNFTs.length)).div(10);
  }

  // Visual Functions
  function getClaimableAmount(address _recipient) public view returns (uint256) {
    return calculateRewards(_recipient);
  }

  function getWithdrawlFee(address _recipient) public view returns (uint256) {
    uint256 totalFee=0;
    for (uint256 index = 0; index < inventory[_recipient].depositedNFTs.length; index++) {
      if(stakingTimestamps[inventory[_recipient].depositedNFTs[index]] + 30 days >  block.timestamp){
        totalFee += withdrawlFee;
      }
    }
    return totalFee;
  }

  function getWithdrawlFeesForTokens(uint8[] calldata tokenIds) public view returns (uint256){
    uint256 totalFee=0;
    for (uint256 index = 0; index < tokenIds.length; index++) {
      if(stakingTimestamps[tokenIds[index]] + 30 days >  block.timestamp){
        totalFee += withdrawlFee;
      }
    }
    return totalFee;
  }

  function getTokenIdsForAddressExternal(address nftOwner) public view returns(uint8[] memory){
    uint8[] memory tokenIds = new uint8[](IStickmanERC721(nftContract).balanceOf(nftOwner));
    uint z=0;
    for (uint8 index = 1; index <= IStickmanERC721(nftContract).totalSupply(); index++) {
      if(IStickmanERC721(nftContract).ownerOf(index)==nftOwner){
        tokenIds[z]= index;
        z++;
      }
    }
    return tokenIds;
  }

  function getTokenIdsForAddress(address addr) public view returns(uint8[] memory){
    return inventory[addr].depositedNFTs;
  }
}