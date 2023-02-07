// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Events} from './modules/Helpers/events.sol';
import {IAaveAddressProvider, IERC20, IAavePool} from './modules/Helpers/interfaces.sol';

// GOERLI: 0x758abf70a15ad8c3de161393c8144534a3851d57
//0x96C0cf721a4702A8bE30584EFBF4e18a09e43b5e

contract BaseAccount is Events {
  address public owner;
  address public factory;
  bool initialized;
  address internal constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  //whitelisting addresses or contracts for certain actions
  struct Whitelist {
    bool whitelisted;
    uint256 whitelistTime;
  }

  //module structure for dapp sepecifuc actions or standard actions
  mapping(bytes4 => address) enabledModules;

  mapping(address => Whitelist) whitelisted;

  mapping(address => bool) auths;

  function initialize(address factory_, address owner_) public {
    require(initialized == false, 'already-initialized');
    owner = owner_;
    factory = factory_;
  }

  // modifiers to restrict access to certain functions
  modifier onlyOwner() {
    require(msg.sender == owner, 'sender-not-owner');
    _;
  }

  modifier onlyFactoryOrOwner() {
    require(
      msg.sender == owner || msg.sender == factory,
      'sender-not-owner-or-factory'
    );
    _;
  }

  modifier onlyAuth() {
    require(auths[msg.sender] == true, 'sender-not-owner');
    _;
  }

  modifier onlyAddAuth() {
    require(
      auths[msg.sender] == true || msg.sender == factory || msg.sender == owner,
      'sender-not-owner'
    );
    _;
  }

  // owner and auth specific functions
  function setOwner(address newOwner_) external onlyOwner {
    require(newOwner_ != address(0), 'null-owner');
    require(newOwner_ != owner, 'already-owner');
    owner = newOwner_;
    emit OwnerUpdated(newOwner_);
  }

  function setAuth(address newAuth_) external onlyOwner {
    require(newAuth_ != address(0), 'null-auth');
    require(auths[newAuth_] != true, 'already-auth');
    auths[newAuth_] = true;
    emit AuthsUpdated(newAuth_, true);
  }

  function removeAuth(address auth_) external onlyOwner {
    require(auth_ != address(0), 'null-auth');
    require(auths[auth_] == true, 'not-auth');
    auths[auth_] = false;
    emit AuthsUpdated(auth_, false);
  }

  /**
   *@dev function to whitelist contracts for certain actions
   *@param contracts_ array of contracts to whitelist
   *@param durations_ array of durations for which the contract is whitelisted`
   */
  function whitelistContracts(
    address[] memory contracts_,
    uint256[] memory durations_
  ) external onlyOwner {
    uint256 length_ = contracts_.length;
    uint256 i = 0;

    require(length_ == durations_.length, 'invalid-length');

    for (; i < length_; ++i) {
      address contract_ = contracts_[i];
      if (whitelisted[contract_].whitelisted == false) {
        whitelisted[contract_] = Whitelist({
          whitelisted: true,
          whitelistTime: durations_[i]
        });
      }
    }
  }

  //minimal function to make a delegate call to an address
  function _delegateCall(address to_, bytes calldata data_)
    public
    payable
    returns (bool success)
  {
    (success, ) = to_.delegatecall(data_);
    require(success, 'call-failed');
  }

  /**
   * @dev function to batch the approve and supply functions to create position on Aave.
   * @param supplyToken address of the token to supply
   * @param borrowToken address of the token to borrow
   * @param supplyAmount amount of the token to supply
   * @param borrowAmount amount of the token to borrow
   */
  function approveAndSupplyAave(
    address supplyToken,
    address borrowToken,
    uint256 supplyAmount,
    uint256 borrowAmount
  ) public payable {
    IAavePool pool = IAavePool(
      IAaveAddressProvider(0xC911B590248d127aD18546B186cC6B324e99F02c).getPool()
    );
    // transfer the tokens from EOA to the smart contract account
    IERC20(supplyToken).transferFrom(msg.sender, address(this), supplyAmount);
    IERC20(supplyToken).approve(address(pool), supplyAmount);

    //supply to aave
    pool.supply(supplyToken, supplyAmount, msg.sender, 0);

    emit SupplyDone(supplyToken, supplyAmount);
  }

  /**
   * @dev function to batch the transfer of tokens to multiple tokens in a single transaction.
   * @param to_ the array of addresses to send the tokens to
   * @param amount_ the array of amounts to send to the addresses
   * @param token_ the token to transfer
   */
  function batchSend(
    address[] memory to_,
    uint256[] memory amount_,
    address token_
  ) public payable {
    if (token_ == eth) {
      uint256 len_ = to_.length;
      for (uint256 i = 0; i < len_; i++) {
        payable(to_[i]).transfer(amount_[i]);
        emit BatchSend(to_[i], amount_[i], token_);
      }
    } else {
      uint256 len_ = to_.length;
      uint256 total = 0;
      for (uint256 i = 0; i < len_; i++) {
        total += amount_[i];
      }
      IERC20(token_).transferFrom(msg.sender, address(this), total);
      for (uint256 i = 0; i < len_; i++) {
        IERC20(token_).transfer(to_[i], amount_[i]);
        emit BatchSend(to_[i], amount_[i], token_);
      }
    }
  }

  /**
   *@dev function to add modules to the baseAccount
   *@param sig_ array of function signatures to be added
   *@param module_ address of the module to be added
   */
  function addModule(bytes4[] memory sig_, address module_)
    external
    onlyAddAuth
  {
    require(module_ != address(0), 'invalid-module');

    uint256 len_ = sig_.length;

    for (uint256 i = 0; i < len_; ++i) {
      enabledModules[sig_[i]] = module_;
      emit ModuleAdded(module_, sig_[i]);
    }
  }

  /**
   *@dev function to update module addresses of the base account
   *@param sig_ signature whose module is to be updated
   *@param module_ address of the module to update
   */
  function updateModule(bytes4 sig_, address module_) external onlyOwner {
    require(module_ != address(0), 'invalid-module');
    require(enabledModules[sig_] != module_, 'already-enabled');

    enabledModules[sig_] = module_;
    emit ModuleUpdated(module_, sig_);
  }

  /**
   *@dev function to get module address of the corrsponding function signature
   *@param sig_ signature whose module is to be found
   *@return module_ address of the sig
   */
  function getModule(bytes4 sig_) public view returns (address module_) {
    return enabledModules[sig_];
  }

  /**
   *@notice fallback function to delegatecall to the module address
   *@dev it is here that all the calls are transferred to respective modules if the function is not in the base account contract
   *the fallback function is called, it takes in the function selector and finds the corresponding module address, then delegates
   *the call to the module address.
   */
  fallback() external payable {
    address module_ = getModule(msg.sig);
    require(module_ != address(0), 'no-module-found');
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      // copy calldata(tx data) to memory: copy entire data at start of memory(0 offset at 0th position)
      calldatacopy(0, 0, calldatasize())

      // Call the implementation. Forward the data to the module.
      // out offset and out-offset size are 0 because we don"t know the size yet.
      let result := delegatecall(gas(), module_, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Events {
  event OwnerUpdated(address new_);
  event AuthsUpdated(address new_, bool enabled);
  event ModuleUpdated(address module_, bytes4 sig_);
  event ModuleAdded(address module_, bytes4 sig_);
  event LeverageDone(
    address supplyToken,
    address borrowToken,
    uint256 supplyAmount,
    uint256 borrowAmount
  );
  event SupplyDone(
    address supplyToken,
    uint256 supplyAmount
  );
  event BatchSend(address to, uint256 amount, address token);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface IERC20 {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
}

interface IAaveAddressProvider {
  function getPool() external view returns (address);
}

interface IAavePool {
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;
}