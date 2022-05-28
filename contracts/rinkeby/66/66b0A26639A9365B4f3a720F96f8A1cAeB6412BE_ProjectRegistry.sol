pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IProjectRegistry.sol";
import "./IClaimsRegistry.sol";
import "./IAudnToken.sol";

contract ProjectRegistry is IProjectRegistry, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IAudnToken;

  IAudnToken public audn;
  IClaimsRegistry public claims;

  uint256 requiredAudn = 20 * 10 ** decimals();

  uint256 blocksPerDay = 40000;

  uint256 apyDeposit = 20;

  struct ProjectInfo{
    string projectName;
    address submitter;
    // uint256 proposalType;
    string metaData;
    bool bountyStatus;
    mapping(uint256 => ContractInfo) contracts;
    // mapping(uint256 => DepositInfo) deposits;
    uint256 contractCount;
    // uint256 depositCount;
    bool active;
  }

  struct ContractInfo{
    uint256 projectId;
    uint256 contractId;
    string contractName;
    string contractSourceUri;
    address contractAddr;
    bool bountyStatus;
    bool active;
  }

  struct DepositInfo{
    uint256 projectId;
    uint256 depositId;
    address submitter;
    uint256 amount;
    DepositType depositType;
    uint256 condition;
    uint256 startBlock; // deposit start block
    uint256 releasedAmount;
    uint256 releasedBlock;
    uint256 claimedAmount;
    uint256 releasedTo;
    bool released;
  }

  enum DepositType {DEFAULT, INSURANCE, BOUNTY}

  mapping(uint256 => ProjectInfo) public map_id_info;
  mapping(uint256 => DepositInfo[]) public map_id_deposit;
  mapping(address => mapping(uint256 => uint256[])) public map_address_id_depositIds;
  uint256 internal projectIdCounter = 0;
  uint256 feeBalance;  // keep track of fees accrued from registrations
  uint256 depositBalance; // keep track of total deposit pool
  // uint256 yieldBalance;  //keep track of unpaid yield balance
  // uint256 lastYieldBlock; //last block to mint yield

  event RegisterProject(address indexed _from, uint256 _id, string _name, string _metaData);
  event RegisterContract(address indexed _from, uint256 _projectId, uint256 _id, string _contractSourceUri, address _contractAddress);

  constructor(IAudnToken _audn) {
    audn = _audn;
    // lastYieldBlock = block.number;
  }

  function registerProject(string memory _projectName, string memory _metaData, string memory _contractName, string memory _contractSourceUri, address _contractAddress) public{
    // require(audn.balanceOf(msg.sender) >= requiredAudn, "insufficient AUDN balance to register project");
    // audn.safeTransferFrom(msg.sender, address(this), requiredAudn);
    // feeBalance += requiredAudn;
    uint256 projectId = projectIdCounter + 1;
    map_id_info[projectId].projectName = _projectName;
    map_id_info[projectId].submitter = msg.sender;
    map_id_info[projectId].metaData = _metaData;
    map_id_info[projectId].bountyStatus = false;
    map_id_info[projectId].active = true;
    map_id_info[projectId].contracts[1].projectId = projectId;
    map_id_info[projectId].contracts[1].contractId = 1;
    map_id_info[projectId].contracts[1].contractName = _contractName;
    map_id_info[projectId].contracts[1].contractSourceUri = _contractSourceUri;
    map_id_info[projectId].contracts[1].contractAddr = _contractAddress;
    map_id_info[projectId].contracts[1].active = true;
    map_id_info[projectId].contractCount++;
    projectIdCounter++;
    emit RegisterProject(msg.sender, projectId, _projectName, _metaData);
    emit RegisterContract(msg.sender, projectId, 1, _contractSourceUri, _contractAddress);
  }

  function registerContract(uint256 _projectId, string memory _contractName, string memory _contractSourceUri, address _contractAddress) public{
    require(map_id_info[_projectId].active, "invalid project id");
    // require(audn.balanceOf(msg.sender) >= requiredAudn, "insufficient AUDN balance to register contract");
    // audn.safeTransferFrom(msg.sender, address(this), requiredAudn);
    // feeBalance += requiredAudn;
    uint256 contractId = map_id_info[_projectId].contractCount + 1;
    map_id_info[_projectId].contracts[contractId].projectId = _projectId;
    map_id_info[_projectId].contracts[contractId].contractId = contractId;
    map_id_info[_projectId].contracts[contractId].contractName = _contractName;
    map_id_info[_projectId].contracts[contractId].contractSourceUri = _contractSourceUri;
    map_id_info[_projectId].contracts[contractId].contractAddr = _contractAddress;
    map_id_info[_projectId].contracts[contractId].active = true;
    map_id_info[_projectId].contractCount++;
    emit RegisterContract(msg.sender, _projectId, contractId, _contractSourceUri, _contractAddress);
  }

  function rejectProject(uint256 _projectId) public onlyOwner{
    require(map_id_info[_projectId].active, "project is already deactivated");
    map_id_info[_projectId].active = false;
  }

  function setDeposit(uint256 _projectId, uint256 _amount, DepositType _type, uint256 _condition) public {
    require(map_id_info[_projectId].active, "project is currently not active");
    uint256 depositAmount = _amount * 10 ** decimals();
    require(audn.balanceOf(msg.sender) >= depositAmount, "insufficient AUDN balance to set bounty");
    audn.safeTransferFrom(msg.sender, address(this), depositAmount);
    depositBalance += depositAmount;
    map_id_info[_projectId].bountyStatus = true;
    map_address_id_depositIds[msg.sender][_projectId].push(map_id_deposit[_projectId].length);
    DepositInfo memory deposit = DepositInfo(_projectId, map_id_deposit[_projectId].length, msg.sender, depositAmount, _type, _condition, block.number, 0, 0, 0, 0, false);
    map_id_deposit[_projectId].push(deposit);
  }

  function setInsuranceDeposit(uint256 _projectId, uint256 _amount, uint256 _maxPremium) public {
    require(map_id_info[_projectId].active, "project is currently not active");
    uint256 depositAmount = _amount * 10 ** decimals();
  }

  function getDeposits(uint256 _projectId) public view returns(DepositInfo[] memory) {
    return map_id_deposit[_projectId];
  }

  function rejectContract(uint256 _projectId, uint256 _contractId) public onlyOwner{
    require(map_id_info[_projectId].contracts[_contractId].active, "contract is already deactivated");
    map_id_info[_projectId].contracts[_contractId].active = false;
  }

  function setRequiredAudn(uint256 _value) public onlyOwner {
    requiredAudn = _value;
  }

  function verifyContract(uint256 _projectId, uint256 _contractId) public view override returns(bool) {
    require(map_id_info[_projectId].active, "project is invalid");
    require(map_id_info[_projectId].contracts[_contractId].active, "contract is invalid");
    return true;
  }

  function verifyProject(uint256 _projectId) public view returns(bool) {
    require(map_id_info[_projectId].active, "project is invalid");
    return true;
  }

  function getContractInfo(uint256 _projectId, uint256 _contractId) public view returns (ContractInfo memory) {
    return map_id_info[_projectId].contracts[_contractId];
  }

  function getContractsFromProject(uint256 _projectId) public view returns (ContractInfo[] memory) {
    require(map_id_info[_projectId].contractCount > 0, "contract count is 0");
    uint256 count = map_id_info[_projectId].contractCount;
    ContractInfo[] memory contracts = new ContractInfo[](count);
    for(uint i = 1; i <= count; i++) {
      ContractInfo storage pushContract = map_id_info[_projectId].contracts[i];
      contracts[i-1] = pushContract;
    }
    return contracts;
  }

  function getContractCount(uint256 _projectId) public view returns (uint256) {
    return map_id_info[_projectId].contractCount;
  }

  function getProjectInfo(uint256 _projectId) public view returns (string memory, address, string memory, bool, uint256, bool) {
    return (map_id_info[_projectId].projectName, map_id_info[_projectId].submitter, map_id_info[_projectId].metaData,
            map_id_info[_projectId].bountyStatus, map_id_info[_projectId].contractCount, map_id_info[_projectId].active);
  }

  function getProjectCount() public view returns (uint256){
    return projectIdCounter;
  }

  function setClaimsRegistry(IClaimsRegistry _claims) public{
    claims = _claims;
  }

  function decimals() public view returns (uint256){
    return 18;
  }

  function withdrawDeposit(DepositInfo memory _deposit) public {

  }

  function getNumDepositsForUser(uint256 _projectId, address _user) public view returns (uint256) {
    return map_address_id_depositIds[_user][_projectId].length;
  }

  function getDepositIndexesGivenUser(uint256 _projectId, address _user) public view returns(uint256[] memory) {
    uint256 count = map_address_id_depositIds[_user][_projectId].length;
    uint256[] memory indexes = new uint256[](count);
    for(uint i = 0; i < count; i++) {
      indexes[i] = map_address_id_depositIds[_user][_projectId][i];
    }

    return indexes;
  }

  function getDepositsGivenUser(uint256 _projectId, address _user) public view returns(DepositInfo[] memory) {
    uint256 count = map_id_deposit[_projectId].length;
    require(count > 0, "no deposits for project");
    uint256 counter;
    DepositInfo[] memory deposits = new DepositInfo[](map_address_id_depositIds[_user][_projectId].length);
    for(uint i = 0; i < count; i++) {
      if(map_id_deposit[_projectId][i].submitter == _user) {
        DepositInfo storage deposit = map_id_deposit[_projectId][i];
        deposits[counter++] = deposit;
      }
    }
    return deposits;
  }

  function verifyDepositGivenIdAndUser(uint256 _projectId, uint256 _depositId, address _user) public view returns(bool) {
    verifyProject(_projectId);
    bool flag;
    uint256 count = map_address_id_depositIds[_user][_projectId].length;
    require(count > 0, "no deposits found for user");
    for(uint i = 0; i < count && !flag; i++) {
      if(map_address_id_depositIds[_user][_projectId][i] == _depositId) {
        flag = true;
      }
    }
    return flag;
  }

  function getDepositGivenIdAndUser(uint256 _projectId, uint256 _depositId, address _user) public view returns(DepositInfo memory) {
    require(verifyDepositGivenIdAndUser(_projectId, _depositId, _user));
    DepositInfo memory deposit = map_id_deposit[_projectId][_depositId];
    return deposit;
  }

  function calculateYieldGivenDeposit(uint256 _projectId, uint256 _depositId, address _user) public view returns(uint256) {
    DepositInfo memory deposit = getDepositGivenIdAndUser(_projectId, _depositId, _user);
    uint256 depositTime = block.number - deposit.startBlock;
    if(depositTime < blocksPerDay) {
      return 0;
    } else {
      uint256 depositDays = depositTime.div(blocksPerDay);
      return deposit.amount.div(100).mul(apyDeposit).div(365).mul(depositDays);
    }
  }

  function releaseDeposit(uint256 _projectId, uint256 _depositId, uint256 _claimId) public {
    uint256 yieldAmount = calculateYieldGivenDeposit(_projectId, _depositId, msg.sender);
    require(map_id_deposit[_projectId][_depositId].released == false, "deposit is already released");
    address claimOwner = claims.ownerOf(_claimId);
    if(yieldAmount > 0) {
      audn.mint(msg.sender, yieldAmount);
    }
    map_id_deposit[_projectId][_depositId].released = true;
    map_id_deposit[_projectId][_depositId].releasedTo = _claimId;
    map_id_deposit[_projectId][_depositId].releasedAmount = map_id_deposit[_projectId][_depositId].amount;
  }

  function collectClaim(uint256 _projectId, uint256 _depositId, uint256 _claimId) public {
    address claimOwner = claims.ownerOf(_claimId);
    require(claimOwner == msg.sender, "you do not own the claim");
    require(map_id_deposit[_projectId][_depositId].released, "claim is not released");
    require(map_id_deposit[_projectId][_depositId].releasedTo == _claimId, "invalid claimer");
    IClaimsRegistry.ClaimType claimType = claims.getClaimType(_claimId);
    if(claimType == IClaimsRegistry.ClaimType.INSURANCE && map_id_deposit[_projectId][_depositId].depositType == DepositType.INSURANCE) {
      uint256 allowedClaimAmount;
      uint256 premiumBalance = claims.getPremiumBalance(_claimId);
      uint256 remainingDepositBalance = map_id_deposit[_projectId][_depositId].releasedAmount - map_id_deposit[_projectId][_depositId].claimedAmount;
      allowedClaimAmount = premiumBalance.mul(map_id_deposit[_projectId][_depositId].condition);
      require(remainingDepositBalance > 0, "insufficient balance in deposit to claim insurance");
      if(remainingDepositBalance > allowedClaimAmount) {
        audn.safeTransfer(msg.sender, allowedClaimAmount);
        map_id_deposit[_projectId][_depositId].claimedAmount += allowedClaimAmount;
        depositBalance -= allowedClaimAmount;
      } else {
        audn.safeTransfer(msg.sender, remainingDepositBalance);
        map_id_deposit[_projectId][_depositId].claimedAmount += remainingDepositBalance;
        depositBalance -= remainingDepositBalance;
      }
    } else {
      require(map_id_deposit[_projectId][_depositId].claimedAmount == 0, "deposit was already claimed");
      audn.safeTransfer(msg.sender, map_id_deposit[_projectId][_depositId].releasedAmount);
      depositBalance -= map_id_deposit[_projectId][_depositId].releasedAmount;
      map_id_deposit[_projectId][_depositId].claimedAmount = map_id_deposit[_projectId][_depositId].releasedAmount;
    }

  }


  function getDepositBalance() public view returns (uint256) {
    return depositBalance;
  }

  function getTotalDepositsGivenId(uint256 _projectId) public view returns (uint256){
    verifyProject(_projectId);
    uint256 count = map_id_deposit[_projectId].length;
    uint256 total = 0;
    for(uint i = 0; i < count; i++) {
      total += map_id_deposit[_projectId][i].amount;
    }
    return total;
  }


  function verifyInsuranceDeposit(uint256 _projectId, uint256 _depositId) public view override returns (bool) {
    if(map_id_deposit[_projectId][_depositId].depositType == DepositType.INSURANCE) {
      return true;
    } else {
      return false;
    }
  }

  function verifyPremiumAmount(uint256 _projectId, uint256 _depositId, uint256 _premium) public view override returns (bool) {
    uint256 multiplier = map_id_deposit[_projectId][_depositId].condition;
    uint256 depositAmount = map_id_deposit[_projectId][_depositId].amount;

    if(_premium.mul(multiplier) <= depositAmount) {
      return true;
    } else {
      return false;
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

interface IProjectRegistry {

  function verifyContract(uint256 _projectId, uint256 _contractId) external view returns(bool);
  function verifyInsuranceDeposit(uint256 _projectId, uint256 _depositId) external view returns (bool);
  function verifyPremiumAmount(uint256 _projectId, uint256 _depositId, uint256 _premium) external view returns (bool);

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IClaimsRegistry is IERC721 {

  struct ClaimInfo {
      uint256 projectId;
      uint256 claimId;
      uint256 contractId;
      address contractAddress;
      address submitter;
      string metaData;
      ClaimType claimType;
      uint256 claimStart;
      uint256 premiumBalance;
      bool refClaim;
      uint256 refClaimId;
      uint256 blockNumber;
      uint256 proposalId;
      bool approved;
  }

  enum ClaimType {
      DEFAULT,
      INSURANCE,
      BOUNTY
  }

  function getClaimInfo(uint256 _claimId) external view returns (ClaimInfo memory);

  function getClaimType(uint256 _claimId) external view returns (ClaimType claimType);

  function getPremiumBalance(uint256 _claimId) external view returns (uint256);

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAudnToken is IERC20{

  function mint(address to, uint256 amount) external;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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