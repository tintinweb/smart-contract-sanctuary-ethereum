// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTDAO {

  uint256 private currentIndex;
  uint c;
  uint d;
  uint e;
  uint f;
  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }
  mapping(address => AddressData) private _addressData;
  uint g;
  uint h;
  uint j;
  address private _owner;
  uint k;
  uint l;
  uint m;
  uint n;
  uint o;
  uint p;
  uint q;
  uint r;

  uint256 public percentToVote = 60;
  uint256 public votingDuration = 86400;
  bool public percentToVoteFrozen;
  bool public votingDurationFrozen;
  Voting[] public votings;
  bool public isDao;
  
  event VotingCreated(
    address contractAddress,
    bytes data,
    uint256 value,
    string comment,
    uint256 indexed index,
    uint256 timestamp
  );
  event VotingSigned(uint256 indexed index, address indexed signer, uint256 timestamp);
  event VotingActivated(uint256 indexed index, uint256 timestamp, bytes result);

  struct Voting {
    address contractAddress;
    bytes data;
    uint256 value;
    string comment;
    uint256 index;
    uint256 timestamp;
    bool isActivated;
    address[] signers;
  }

  function balanceOf(address owner_) public view returns (uint256) {
      require(owner_ != address(0), "0");
      return uint256(_addressData[owner_].balance);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
      require(owner() == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  modifier onlyHoldersOrOwner {
    require((isDao && balanceOf(msg.sender) > 0) || msg.sender == owner(), "boop");
    _;
  }

  modifier onlyContractOrOwner {
    require(msg.sender == address(this) || msg.sender == owner());
    _;
  }

  function createVoting(
    address _contractAddress,
    bytes calldata _data,
    uint256 _value,
    string memory _comment
  ) external onlyHoldersOrOwner() returns (bool success) {
    address[] memory _signers;

    votings.push(
      Voting({
        contractAddress: _contractAddress,
        data: _data,
        value: _value,
        comment: _comment,
        index: votings.length,
        timestamp: block.timestamp,
        isActivated: false,
        signers: _signers
      })
    );

    emit VotingCreated(_contractAddress, _data, _value, _comment, votings.length - 1, block.timestamp);

    return true;
  }

  function signVoting(uint256 _index) external onlyHoldersOrOwner() returns (bool success) {
    for (uint256 i = 0; i < votings[_index].signers.length; i++) {
        require(msg.sender != votings[_index].signers[i], "v");
    }

    require(block.timestamp <= votings[_index].timestamp + votingDuration, "t");

    votings[_index].signers.push(msg.sender);
    emit VotingSigned(_index, msg.sender, block.timestamp);
    return true;
  }

  function activateVoting(uint256 _index) external {
    uint256 sumOfSigners = 0;

    for (uint256 i = 0; i < votings[_index].signers.length; i++) {
      sumOfSigners += balanceOf(votings[_index].signers[i]);
    }
    
    require(sumOfSigners >= currentIndex * percentToVote / 100, "s");
    require(!votings[_index].isActivated, "a");

    address _contractToCall = votings[_index].contractAddress;
    bytes storage _data = votings[_index].data;
    uint256 _value = votings[_index].value;
    (bool b, bytes memory result) = _contractToCall.call{value: _value}(_data);

    require(b);

    votings[_index].isActivated = true;

    emit VotingActivated(_index, block.timestamp, result);
  }

  function changePercentToVote(uint256 _percentToVote) external onlyContractOrOwner() returns (bool success) {
    require(_percentToVote >= 1 && _percentToVote <= 100 && !percentToVoteFrozen, "f");
    percentToVote = _percentToVote;
    return true;
  }

  function changeVotingDuration(uint256 _votingDuration) external onlyContractOrOwner() returns (bool success) {
    require(!votingDurationFrozen, "f");
    require(
        _votingDuration == 2 hours || _votingDuration == 24 hours || _votingDuration == 72 hours, "t"
    );
    votingDuration = _votingDuration;
    return true;
  }

  function freezePercentToVoteFrozen() external onlyContractOrOwner() {
    percentToVoteFrozen = true;
  }

  function freezeVotingDuration() external onlyContractOrOwner() {
    votingDurationFrozen = true;
  }

  function withdraw() external onlyContractOrOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(address tokenAddress) external onlyContractOrOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}