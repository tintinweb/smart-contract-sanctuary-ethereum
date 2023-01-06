// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import './EthVault.sol';

// For security, contact [email protected]
contract EthMaster is Ownable{
    struct Employer{
        address vaultAddress;
        uint256 deadline;
    }
    // TODO: Change USDC contract address and fees
    mapping(address => Employer) public allVaults;
    uint256 public monthlyTimestamp = 2629743; // 1 Month
    uint256 public monthlyFee = 50000000; // 50 USDC
    IERC20 USDCContract = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43); // Mainnet -   0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

    event VaultCreated(address owner, address vaultAddress);
    event SubscriptionRenewed(address owner);

    // Approve needs to be called before calling this function
    /// @param _timePeriod - The number of months to subscribe. 1, 2, 3, 4 ... etc months
    /// @param _amount - The fee. Depends on the number of months that the employer subscribes
    function createVault(uint256 _timePeriod, uint256 _amount) external returns(address){
        require(_amount >= monthlyFee*_timePeriod, "Fee sent is wrong");
        require(allVaults[msg.sender].vaultAddress == address(0), "You already have a vault created for this address");
        USDCContract.transferFrom(msg.sender, address(this), _amount);
        address newVault = address(new EthVault(msg.sender, address(this)));
        allVaults[msg.sender].vaultAddress = newVault;
        allVaults[msg.sender].deadline = block.timestamp + (monthlyTimestamp*_timePeriod);
        emit VaultCreated(msg.sender, newVault);
        return newVault;
    }

    // Approve needs to be called before calling this function
    /// @param _timePeriod - The number of months to subscribe. 1, 2, 3, 4 ... etc months
    /// @param _amount - The fee. Depends on the number of months that the employer subscribes
    function renew(uint256 _timePeriod, uint256 _amount) external{
        require(_amount >= monthlyFee*_timePeriod, "Fee sent is wrong");
        require(allVaults[msg.sender].vaultAddress != address(0), "Vault not found");
        USDCContract.transferFrom(msg.sender, address(this), _amount);
        if(block.timestamp >= allVaults[msg.sender].deadline){
            allVaults[msg.sender].deadline = block.timestamp + (monthlyTimestamp*_timePeriod);
        }else{
            allVaults[msg.sender].deadline = allVaults[msg.sender].deadline + (monthlyTimestamp*_timePeriod);
        }
        EthVault(allVaults[msg.sender].vaultAddress).resume();
        emit SubscriptionRenewed(msg.sender);
    }

    function withdrawFees(uint256 _amount) external onlyOwner{
        USDCContract.transfer(msg.sender, _amount);
    }

    function changeFees(uint256 _newFee) external onlyOwner{
        monthlyFee = _newFee;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "chainlink/src/v0.8/AutomationCompatible.sol";
import {AutomationRegistryInterface, State, Config} from "chainlink/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "chainlink/src/v0.8/interfaces/LinkTokenInterface.sol";

// For security, contact [email protected]
interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

interface MasterInterface {
    struct Employer{
        address vaultAddress;
        uint256 deadline;
    }
    function allVaults(address _owner) external view returns(Employer memory);
}

contract EthVault is AutomationCompatibleInterface, Ownable {
    address[] public employees;
    uint256 public totalEmployees;
    uint256 public upkeepId;
    bool public paused;
    address public masterAddress;
    LinkTokenInterface public immutable ILink;
    MasterInterface public IMaster;
    // TODO: Change for Mainnet
    address public registrar = 0x9806cf6fBc89aBF286e8140C42174B94836e36F2; // Mainnet -  0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d
    address public registry = 0x02777053d6764996e594c3E88AF1D58D5363a2e6; // Mainnet -  0x02777053d6764996e594c3E88AF1D58D5363a2e6
    AutomationRegistryInterface public immutable IRegistry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    struct Employee {
        uint256 salary;
        address token;
        uint256 nextPayTimestamp;
        uint256 timePeriod;
        bool deleted;
    }
    mapping(address => Employee) public employeeDetails;

    event SalarySent(address indexed, uint256);
    event EmployeeAdded(address indexed, uint256);
    event EmployeeEdited(address indexed);
    event EmployeeDeleted(address indexed);

    constructor(address _owner, address _masterContract) {
        // TODO: Change below address for Mainnet
        ILink = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); // Mainnet -   0x514910771AF9Ca656af840dff83E8264EcF986CA
        IRegistry = AutomationRegistryInterface(registry);
        masterAddress = _masterContract;
        IMaster = MasterInterface(_masterContract);
        transferOwnership(_owner);
    }

     function registerAndPredictID(
        string memory name,
        address adminAddress,
        uint96 amount
    ) external onlyOwner{
        require(upkeepId == 0, "Upkeep already created");
        (State memory state, Config memory _c, address[] memory _k) = IRegistry.getState();
        uint256 oldNonce = state.nonce;

        bytes memory payload = abi.encode(
            name,
            "",
            address(this),
            500000,
            adminAddress,
            "",
            amount,
            0,
            address(this)
        );

        ILink.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );

        (state, _c, _k) = IRegistry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(IRegistry),
                        uint32(oldNonce)
                    )
                )
            );
            upkeepId = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    function addEmployees(
        address _employeeAddress,
        uint256 _employeeSalary,
        address _token,
        uint256 _firstPayTimestamp,
        uint256 _timePeriod
    ) external onlyOwner {
        require(employeeDetails[_employeeAddress].token == address(0) || employeeDetails[_employeeAddress].deleted == true, "This employee is already registered");
        employeeDetails[_employeeAddress].salary = _employeeSalary;
        employeeDetails[_employeeAddress].token = _token;
        employeeDetails[_employeeAddress].nextPayTimestamp = _firstPayTimestamp;
        employeeDetails[_employeeAddress].timePeriod = _timePeriod;
        employeeDetails[_employeeAddress].deleted = false;
        totalEmployees++;
        employees.push(_employeeAddress);
        emit EmployeeAdded(_employeeAddress, _employeeSalary);
    }

    function editEmployees(
        address _employeeAddress,
        uint256 _employeeSalary,
        address _token,
        uint256 _nextPayTimestamp,
        uint256 _timePeriod
    ) external onlyOwner {
        employeeDetails[_employeeAddress].salary = _employeeSalary;
        employeeDetails[_employeeAddress].token = _token;
        employeeDetails[_employeeAddress].nextPayTimestamp = _nextPayTimestamp;
        employeeDetails[_employeeAddress].timePeriod = _timePeriod;
        emit EmployeeEdited(_employeeAddress);
    }

    function removeEmployees(address _employeeAddress) external onlyOwner {
        employeeDetails[_employeeAddress].deleted = true;
        emit EmployeeDeleted(_employeeAddress);
    }

    function withdrawToken(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if(!paused){
            for (uint256 i = 0; i < totalEmployees; i++) {
                bool isPaymentTime = block.timestamp >= employeeDetails[employees[i]].nextPayTimestamp;
                bool isDeleted = employeeDetails[employees[i]].deleted == false;
                upkeepNeeded = isPaymentTime && isDeleted;
                if(upkeepNeeded){
                    performData = abi.encode(employees[i]);
                    return(upkeepNeeded, performData);
                }
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if (block.timestamp >= IMaster.allVaults(owner()).deadline){
            paused = true;
        }else{
            address employeeAddress = abi.decode(performData, (address));
            bool isPaymentTime = block.timestamp >= employeeDetails[employeeAddress].nextPayTimestamp;
            bool isDeleted = employeeDetails[employeeAddress].deleted == false;
            if (isPaymentTime && isDeleted) {
                employeeDetails[employeeAddress].nextPayTimestamp = block.timestamp + employeeDetails[employeeAddress].timePeriod;
                uint256 amount = employeeDetails[employeeAddress].salary;
                IERC20(employeeDetails[employeeAddress].token).transfer(
                    employeeAddress,
                    amount
                );
                emit SalarySent(employeeAddress, amount);
            }
        }
    }

    function resume() external{
        require(msg.sender == masterAddress, "You cannot call this function");
        paused = false;
    }

    function checkIfLinkIsWithdrawable() external view returns(bool){
        (,,,,,,uint64 maxValidBlocknumber,) = IRegistry.getUpkeep(upkeepId);
        if (maxValidBlocknumber > block.number){
            return false;
        }else{
            return true;
        }
    }

}