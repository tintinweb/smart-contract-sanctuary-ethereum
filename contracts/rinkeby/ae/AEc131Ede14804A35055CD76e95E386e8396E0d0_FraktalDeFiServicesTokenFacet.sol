// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {Modifiers} from "../../shared/libraries/LibModifiers.sol";
// import "../../shared/libraries/LibDiamond.sol";


contract FraktalDeFiServicesTokenFacet is Modifiers {
  uint256 constant MAX_UINT = type(uint256).max;
  uint256 constant MAX_SUPPLY = 60000000000 * 10 ** 18;

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  function APP_VERSION () external view returns(string memory _version) {
    return s.APP_VERSION;
  }

  function name() external pure returns (string memory) {
    return "Fraktal DeFi Services Tokens";
  }

  function symbol() external pure returns (string memory) {
    return "FDS";
  }

  function decimals() external pure returns (uint8) {
    return 18;
  }

  function totalSupply() external view returns (uint256) {
    return s.t.totalSupply;
  }

  function maxSupply() external pure returns (uint256) {
    return MAX_SUPPLY;
  }

  function minter () external view returns(address) {
    return s.t.minter;
  }

  function balanceOf(address _owner) external view returns (uint256 balance) {
    balance = s.t.balances[_owner];
  }

  function transfer(address _to, uint256 _value) external returns (bool success) {
    uint256 frombalances = s.t.balances[LibMeta.msgSender()];
    require(frombalances >= _value, "FraktalDeFi: Not enough FraktalDeFi Tokens to transfer");
    s.t.balances[LibMeta.msgSender()] = frombalances - _value;
    s.t.balances[_to] += _value;
    emit Transfer(LibMeta.msgSender(), _to, _value);
    success = true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success) {
    uint256 fromBalance = s.t.balances[_from];
    if (LibMeta.msgSender() == _from || s.t.approvedContractIndexes[LibMeta.msgSender()] > 0) {
        // pass
    } else {
        uint256 l_allowance = s.t.allowances[_from][LibMeta.msgSender()];
        require(l_allowance >= _value, "FraktalDeFi: Not allowed to transfer");
        if (l_allowance != MAX_UINT) {
            s.t.allowances[_from][LibMeta.msgSender()] = l_allowance - _value;
            emit Approval(_from, LibMeta.msgSender(), l_allowance - _value);
        }
    }
    require(fromBalance >= _value, "FraktalDeFi: Not enough FraktalDeFi to transfer");
    s.t.balances[_from] = fromBalance - _value;
    s.t.balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    success = true;
  }

  function approve(address _spender, uint256 _value) external returns (bool success) {
    s.t.allowances[LibMeta.msgSender()][_spender] = _value;
    emit Approval(LibMeta.msgSender(), _spender, _value);
    success = true;
  }

  function increaseAllowance(address _spender, uint256 _value) external returns (bool success) {
    uint256 l_allowance = s.t.allowances[LibMeta.msgSender()][_spender];
    uint256 newAllowance = l_allowance + _value;
    require(newAllowance >= l_allowance, "FraktalDeFiFacet: Allowance increase overflowed");
    s.t.allowances[LibMeta.msgSender()][_spender] = newAllowance;
    emit Approval(LibMeta.msgSender(), _spender, newAllowance);
    success = true;
  }

  function decreaseAllowance(address _spender, uint256 _value) external returns (bool success) {
    uint256 l_allowance = s.t.allowances[LibMeta.msgSender()][_spender];
    require(l_allowance >= _value, "FraktalDeFiFacet: Allowance decreased below 0");
    l_allowance -= _value;
    s.t.allowances[LibMeta.msgSender()][_spender] = l_allowance;
    emit Approval(LibMeta.msgSender(), _spender, l_allowance);
    success = true;
  }

  function allowance(address _owner, address _spender) external view returns (uint256 remaining_) {
    remaining_ = s.t.allowances[_owner][_spender];
  }

  function _mint(uint256 amount) internal {
    // uint256 amount = 10000000e18;
    s.t.balances[LibMeta.msgSender()] += amount;
    s.t.totalSupply += uint96(amount);
    require(s.t.totalSupply <= MAX_SUPPLY, "MINT OVERFLOW");
    emit Transfer(address(0), LibMeta.msgSender(), amount);
  }

  function _mintTo(address _user, uint amount) internal {
    // uint256 amount = 10000000e18;
    s.t.balances[_user] += amount;
    s.t.totalSupply += uint96(amount);
    require(s.t.totalSupply <= MAX_SUPPLY, "MINT OVERFLOW");
    emit Transfer(address(0), _user, amount);
  }
  function mint (uint amount) external onlyMinter {
    _mint(amount);
  }

  function mintTo (address _user, uint amount) external onlyMinter {
    _mintTo(_user, amount);

  }

}

/*
 SPDX-License-Identifier: MIT
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.4;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import { AppStorage, FraktalDeFiServicesToken } from "../libraries/LibAppStorage.sol";
import { LibMeta } from "./LibMeta.sol";
import { AppStore } from "../../AppStore.sol";
import { LibAppStorage } from "../../shared/libraries/LibAppStorage.sol";

library LibModifiers {
  function _hasContract (address _addr) internal view returns(bool exists) {
    AppStore storage s = LibAppStorage.diamondStorage();

    uint i;
    uint totalContracts = s.platformContractsCount;
    exists = false;
    if (totalContracts == 0) return exists;

    for (i = 0; i < totalContracts; i++) {
      if (s.platformContracts[i]._addr == _addr) {
        exists = true;
        return exists;
      }
    }
    return exists;

  }


  // function pause () public onlyPauser {
  //   AppStorage storage s = LibAppStorage.diamondStorage();

  //   s.t.isPaused = true;
  // }
  // function unpause () public onlyPauser {
  //   AppStorage storage s = LibAppStorage.diamondStorage();

  //   s.t.isPaused = false;
  // }
  // function updateMinter (address _newMinter) public {
  //   AppStorage storage s = LibAppStorage.diamondStorage();

  //   require(s.t.minter != _newMinter, "ACCOUNT IS ALREADY MINTER");
  //   address oldMinter = s.t.minter;
  //   s.t.minter = _newMinter;
  //   emit UpdatedMinter(oldMinter, _newMinter);
  // }

  // function updatePauser (address _newPauser) public {
  //   AppStorage storage s = LibAppStorage.diamondStorage();

  //   require(s.t.pauser != _newPauser, "ACCOUNT IS ALREADY PAUSER");
  //   address oldPauser = s.t.pauser;
  //   s.t.pauser = _newPauser;
  //   emit UpdatedPauser(oldPauser, _newPauser);
    
  // }

}
contract Modifiers {
  AppStore internal s;

  event PausedBy(address indexed pauser);
  event UnpausedBy(address indexed pauser);
  event PausedExecution(address indexed user);
  event UpdatedPauser(address indexed oldPauser, address indexed newPauser);
  event UpdatedMinter(address indexed oldMinter, address indexed newMinter);

  modifier onlyMinter () {
    require(LibMeta.msgSender() == s.t.minter, "UNAUTHORIZED: NOT MINTER");
    _;
  }

  modifier onlyPauser () {
    require(LibMeta.msgSender() == s.t.pauser, "UNAUTHORIZED: NOT PAUSER");
    _;
  }

  modifier onlyFlashLoanOperator () {
    require(LibMeta.msgSender() == s.flashLoanOperator, "UNAUTHORIZED: NOT PAUSER");
    _;

  }

  modifier whenPaused () {
    require(s.t.isPaused, "NOT PAUSED");
    // emit PausedExecution(LibMeta.msgSender());
    _;
  }

  modifier whenNotPaused () {
    require(!s.t.isPaused, "NOT PAUSED");
    // emit PausedExecution(LibMeta.msgSender());
    _;
  }

  modifier isAthorized (address _contract) {
    require(LibModifiers._hasContract(_contract), "UNAUTHORIZED: CONTRACT IS NOT LISTED");
    _;
  }

  function _isContractActive (uint id) internal view returns(bool isActive) {
    isActive = s.platformContracts[id].active;
  }
  // function _isContractActive (address _addr) internal view returns(bool isActive) {
  //   isActive = false;

  // }
  
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity ^0.8.4;

import { IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair } from "./shared/interfaces/IUniswapV2.sol";
import { IWETH } from "./shared/interfaces/IWETH.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Storage {
  uint256 MAX_SUPPLY = 60000000000;

  struct Token {
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    address[] approvedContracts;
    mapping(address => uint256) approvedContractIndexes;
    // bytes32[1000] emptyMapSlots;
    address contractOwner;
    uint256 totalSupply;
    // uint256 maxSupply;
    bool isPaused;
    address pauser;
    address minter;
    mapping(bytes32 => mapping(address => bool)) roles;
    mapping(string => bytes32) nameRoles;

  }

  struct Platform {
    string name;
    string url;
  }
  
  struct ContractInfo {
    address _addr;
    string name;
    Platform platform;
    ContractType[] _types;
    bool active;
  }
  
  struct ContractType {
    string name;
  }

  struct UniswapV2Exchange {
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;
  }

  struct UniswapV2TokenPair {
    address[] path;
    IUniswapV2Pair pair;
  }

  struct UniswapV2TokenPairData {
    UniswapV2TokenPair pair;
    uint reserve0;
    uint reserve1;
  }

  enum FlashLoanExecutionType {ARBITRAGE, LIQUIDATION, SELF_LIQUIDATION, COLLATERAL_SWAP, DEBT_SWAP, MINT_NFT}

  struct PriceFeed {
    AggregatorV3Interface feed;
    string name;
  }

}

struct AppStore {
  string APP_VERSION;
  Storage.Token t;

  Storage.ContractType[] contractTypes;
  mapping(uint => Storage.ContractInfo) platformContracts;
  uint platformContractsCount;
  Storage.Platform[] platforms;
  IWETH WETH;

  address flashLoanOperator;
  Storage.PriceFeed[] priceFeeds;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

// address constant  BURN_ADDRESS;
import { AppStore } from "../../AppStore.sol";
// struct UserInfo {
//   address user;
//   uint startBlock;
// }

// // struct RoleData {

// // }
// // struct Roles {
// //   string name;
// //   address admin;
// //   address[] members;
// //   bytes32 hash;
// // }
// enum AssetType{PHYSICAL, VIRTUAL}

// contract Storage {
//   uint256 MAX_SUPPLY = 60000000000;
//   struct FraktalDeFiServicesToken {
//     mapping(address => mapping(address => uint256)) allowances;
//     mapping(address => uint256) balances;
//     address[] approvedContracts;
//     mapping(address => uint256) approvedContractIndexes;
//     bytes32[1000] emptyMapSlots;
//     address contractOwner;
//     uint256 totalSupply;
//     uint256 maxSupply;
//     bool isPaused;
//     address pauser;
//     address minter;
//     mapping(bytes32 => mapping(address => bool)) roles;
//     mapping(string => bytes32) nameRoles;
//   }

//   struct Asset {
//     string description;
//     AssetType _type;
//   }

//   struct BeneficiaryInfo {
//     address beneficiary;
//     uint startBlock;
//     mapping(address => mapping(address => uint)) userBalances;
//   }


//   struct DAOTrust {
//     BeneficiaryInfo[] beneficiaries;
//     address[] trustees;
//     address[] grantors;
//     address[] successorTrusees;
//     Asset[] assets;
//   }

// }
// struct AppStorage {
//   string APP_VERSION;
//   // mapping(bytes32 => );
// }



library LibAppStorage {
    function diamondStorage() internal pure returns (AppStore storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  )
    external
    returns (uint[] memory amounts);
}

interface IUniswapV2Factory  {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC2612 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be `address(0)`.
     * - `spender` cannot be `address(0)`.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
    
    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by EIP712.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import "./IERC2612.sol";
// import "./IERC3156FlashLender.sol";

/// @dev Wrapped Ether v10 (WETH10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH10, which will then burn WETH10 token in your wallet. The amount of WETH10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.

interface ITransferReceiver {
    function onTokenTransfer(address, uint, bytes calldata) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(address, uint, bytes calldata) external returns (bool);
}

interface IWETH10 is IERC20, IERC2612, IERC3156FlashLender {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), 
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}

interface IWETH is IWETH10 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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