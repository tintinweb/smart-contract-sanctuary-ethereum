// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PayForSuccess {
  // Contract identification.
  address public immutable fakeTokenAddrForNativeCurrency = address(0);

  //PayForSuccess "vault" address: here is where we deposit and release tokens.
  //address public PayForSuccess;
  address public owner;
  address public admin;

  // Store actor/users wallet balance. UserAddress->AssetAddress->Amount
  mapping(address => mapping(address => uint256)) public UserInfo;
  mapping(address => uint256) public UserEthInfo;

  //stores payer amount and URI for NFT issued to Payer
  struct Stake {
    uint256 amount; //amount contributed by Payer
    string uri; //uri for the NFT issued to Payer
  }
  mapping(address => mapping(address => Stake)) public Payers;

  address[] private s_funders;

  enum EventFlags {
    DEPOSITED,
    RELEASED,
    NFTISSUED,
    RESULTRELEASED,
    RESULTSIGNED
  }

  // Asset Received handling.
  event AssetReceived(
    address indexed from,
    uint256 amount,
    address indexed tokenAddress,
    EventFlags flag
  );
  //NFT issued
  event NFTIssued(
    address indexed to,
    uint256 amount,
    address tokenAddress,
    string indexed uri,
    EventFlags flag
  );
  //Clinical Submission Event
  event ClinialResult(
    address indexed submitter,
    string indexed documentURI,
    uint32 clinicalTrialStage,
    EventFlags flag
  );
  //result signed
  event SignedClinicalResult(
    address indexed submitter,
    string documentURI,
    uint32 trialStage,
    string rootTxnId,
    bytes[] signatures,
    EventFlags indexed flag
  );

  // One time call: assigns our wallet address as the vault master.
  constructor(address _admin) {
    owner = msg.sender;
    admin = _admin;
  }

  modifier onlyOwner(address sender) {
    require(sender == admin, "Only the admin of the contract can perform this operation.");
    _;
  }

  function getContractName() public pure returns (string memory) {
    return "Pay4Success";
  }

  function getUserAsset(address assetAddress) public view returns (uint256 amount) {
    return UserInfo[msg.sender][assetAddress];
  }

  function getUserEthAmount() public view returns (uint256 amount) {
    return UserEthInfo[msg.sender];
  }

  receive() external payable {}

  /*
   * Deposit and transfer function:
   * The User needs to approve this contract with the amount of asset initially.
   * Using the ERC20 standard we then transfer the same amount of asset approved to this contract using transferFrom.
   * We modify the UserInfo to keep track of deposit operations.
   * we notify PFS contract providers/validators of transaction.
   */
  function depositAssets(uint256 amount, address assetAddress) public payable {
    UserInfo[msg.sender][assetAddress] += amount;
    IERC20(assetAddress).transferFrom(msg.sender, address(this), amount);
    s_funders.push(msg.sender);

    emit AssetReceived(msg.sender, amount, assetAddress, EventFlags.DEPOSITED);
  }

  //updates NFT URI with the asset deposited
  function issueNFT(
    uint256 amount,
    address assetAddress,
    string memory uri
  ) public {
    Stake memory stake;
    stake.amount = amount;
    stake.uri = uri;
    Payers[msg.sender][assetAddress] = stake;

    emit NFTIssued(msg.sender, amount, assetAddress, uri, EventFlags.NFTISSUED);
  }

  /*
   * Deposit and transfer function:
   * The User needs to approve this contract with the amount of ETH initially.
   * We modify the UserInfo to keep track of deposit operations.
   * we notify PFS contract providers/validators of transaction.
   */
  function depositEth() public payable {
    //IERC20(fakeTokenAddrForNativeCurrency).transferFrom(msg.sender, address(this), msg.value);

    UserInfo[msg.sender][fakeTokenAddrForNativeCurrency] += msg.value;
    UserEthInfo[msg.sender] += msg.value;
    s_funders.push(msg.sender);
    emit AssetReceived(
      msg.sender,
      msg.value,
      fakeTokenAddrForNativeCurrency,
      EventFlags.DEPOSITED
    );
  }

  //
  function getFunder(uint256 index) public view returns (address) {
    return s_funders[index];
  }

  //Submit URI for the documents submitted towards clinical trial results
  function submitClinialResult(string calldata documentURI, uint32 clinicalTrialStage) public {
    emit ClinialResult(msg.sender, documentURI, clinicalTrialStage, EventFlags.RESULTRELEASED);
  }

  //Signed transaction posted on net
  function submitSignedClinialResult(
    string calldata documentURI,
    uint32 clinicalTrialStage,
    string calldata rootTxnId,
    bytes[] memory signatures
  ) public {
    emit SignedClinicalResult(
      msg.sender,
      documentURI,
      clinicalTrialStage,
      rootTxnId,
      signatures,
      EventFlags.RESULTSIGNED
    );
  }

  /*
   * Release function:
   * Check caller if PFS Contract owner.
   * We add tokens to user address.
   * We remove tokens from out vault.
   */
  function releaseAssets(
    uint256 amount,
    address userAddress,
    address assetAddress
  ) public onlyOwner(msg.sender) {
    uint256 _userAssetBalance = UserInfo[msg.sender][assetAddress];
    require(_userAssetBalance >= amount, "The user doesn't have enough amount of this asset.");
    IERC20(assetAddress).transferFrom(address(this), userAddress, amount);
    UserInfo[msg.sender][assetAddress] -= amount;
  }

  //
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