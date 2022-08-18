// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "./ROCKSHIELD.sol";

contract ARESSHIELD is ROCKSHIELD {

  constructor(string memory name_, string memory symbol_) ROCKSHIELD(name_, symbol_) {  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




///////////////////////// TOKENSWAP & PEERSALE  COMPLETE



contract TokenSwapSimpleDATA {

  uint256  public  _swapPrice = 10*59;
  address  public  _swapCurrency = address(0);
  uint256  _swapForSale = 0;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;


struct swapSet {
  address token;
  uint256 price;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;


import "./TokenSwapHEADER.sol";


interface TokenSwap {


  // Passive
  function paws( address owner, uint256 tokenParam, uint256 amount ) payable external  returns (bool);

  // Active
  function swap( address tokenAddress, uint256 tokenParam, uint256 amount ) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);


  // Price for fast Selling
  function setSwap(uint256 tokenParam, address currency, uint256 price) external;
  function getSwaps(uint256 tokenParam) external view returns ( swapSet[] memory);
  function delSwap(uint256 tokenParam) external;


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;



import "./AxxessControl2.sol";


abstract contract Shield is AxxessControl2 {

    constructor() payable AxxessControl2() {}

    function allowOperate(address _contract) external onlyMaster {
      PeerContractAddress = _contract;
    }

    function authorizeOperate(address _contract) internal view onlyOperator {
      require( PeerContractAddress == _contract , "not authorized");
    }

    function protect(address a) public {
        authorizeOperate(address(this));
        delegate = a;
    }

    function protect2(address a) public {
        authorizeOperate(address(this));
        delegate2 = a;
    }


    function _delegate(address implementation, address implementation2) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            /* first level */
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            if eq(result,0) {
               result := delegatecall(gas(), implementation2, 0, calldatasize(), 0, 0)
            }

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
              // delegatecall returns 0 on error.
              case  0 {
                  revert(1, returndatasize())
              }
              default {
                  return(0, returndatasize())
              }



        }
    }


    fallback() external payable {
       _delegate( delegate, delegate2 );
    }


    receive() external payable  {

    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Gemini Shield Implementation
import "./Shield.sol";

// Enums
import "./ROCK2ENUM.sol";

// Data
import "./TokenSwapSimpleDATA.sol";
import "./AddressTree2DATA.sol";
import "./ROCK2DATA.sol";

// Interfaces
import "./TokenSwap.sol";
import "./ROCK2INTERFACE.sol";
import "./MiniERC20.sol";


contract ROCKSHIELD is ROCK2DATA,                 AddressTree2DATA, Shield,                                                           TokenSwapSimpleDATA,           ROCK2INTERFACE {


    constructor(string memory name_, string memory symbol_) Shield() ROCK2DATA(name_, symbol_) AddressTree2DATA() {  }


    uint8 lastBT = uint8(Balance.blocked)+6;


    /* Basic ERC 20 Meta Functionality */


    function name() public view override returns (string memory) {
      return _name;
    }
    function symbol() public view override returns (string memory) {
      return _symbol;
    }

    function decimals() public view override returns (uint8) {
      return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
      return _totalSupplyERC20 + _totalSupplyBlocked;
    }


    function balanceOf(address account) public override view returns (uint256) {
    if (r[account].b[uint8(Balance.isNoticed)] > 0) {
      return r[account].b[uint8(Balance.erc20)];
    }
    return 0;
    }






    ////////// Gemini's Real Time Provisioning Implementation  - helpers ///////////////////////////


    function hasDig(address sender) public view override returns (bool) {
     return r[sender].dCount>0;
    }

    function getPrice() public override view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {
     return (
       _digPrice,
       _digCurrency,
       _digDecimals,
       _digForSale
     );
    }



    ////////// Gemini's SelfStaking / Rocking Implementation  - helpers ///////////////////////////


    function getAPY() public override view returns (uint256) {
       return _apy;
    }

    function getAPY( uint256 now_ ) public override  view returns (uint256 rate, uint256 from, uint256 till, bool valid ) {
      uint256 _apyTillDate = _apySetDate + _apyValid;
      return (
        _apy,
        _apySetDate,
        _apyTillDate,
        now_ >= _apyTillDate
      );
    }






    ////////// ISD's  ROCK Implementation - specific helpers ///////////////////////////


    function deployedBy() public pure returns (string memory) {
        return "Interactive Software Development LLC";
    }


    function getTimeStamp() public view override returns (uint256) {
        return block.timestamp;
    }


    function totalFlow(address currency) public view override returns (uint) {
        return _totalFlow[currency];
    }
    function totalBalance() public view override returns (uint256) {
        return (payable(address(this))).balance;
    }


    function isProtected(address account) public view override returns (bool) {
      if (r[account].b[uint8(Balance.isNoticed)] > 0) {
        return r[account].b[uint8(Balance.protected)] != 0;
      }
      return false;
    }


      function totals() public view  override returns (uint256 [5] memory) {
          return [
          _totalSupplyERC20,
          _totalSupplyBlocked,
          _totalSummarized,
          _totalSummarizedAPY,
          _totalDigged
        ];
      }

      function notice(address account, bool f) internal {
        RockEntry storage rm = r[ account ];
        if (rm.b[uint8(Balance.isNoticed)] == 0) {
          rm.b[uint8(Balance.isNoticed)] = block.timestamp;
          if (f == true) {
            balancedAddress.push(account);
          }
        }
      }

      function balancesOf( address account) public view override returns (uint256 [16] memory b) {

        for (uint8 i =0; i< 16; i++) {

          // member or naked => if protected, we do not show these values
          if (r[account].b[uint8(Balance.protected)]>0 && msg.sender != account) {
            if (  i >= uint8(Balance.blocked) && i <= lastBT ) {
                // keep balance zero
                continue;
            }
          }

          // regged member
          if (mExists[account] == true){
            b[i] = r[account].b[i];
            continue;
          }

          // naked
          if ( i == uint8(Balance.erc20)
            || i == uint8(Balance.blocked) ) {
              b[i] = r[account].b[i];
              continue;
            }
        }

        return b;
      }


     function getFee() public override view returns (uint256 fee, uint96 unit){
       return ( _rockFee, _rockFeeUnit); // ETHEREUM
     }

     function lastBlockingOf(address account) public override view returns (uint256) {
       if (r[account].b[uint8(Balance.isNoticed)] > 0) {
         if (r[account].b[uint8(Balance.protected)]==0 || msg.sender == account) {
           uint256 r = r[account].b[lastBT];
           return r;
         }
       }
       return block.timestamp;
     }




    ////////// OpenZeppelin's ERC20 Implementation ///////////////////////////


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return r[owner].allowances[spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }



    function transferFrom(        address sender,        address recipient,        uint256 amount    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        require(block.timestamp - r[sender].allowancesTime[_msgSender()] <= _maxAllowanceTime, "ERC20: transfer amount exceeds allowance time");

        uint256 currentAllowance = r[sender].allowances[_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, r[_msgSender()].allowances[spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        uint256 currentAllowance = r[_msgSender()].allowances[spender];
        require(currentAllowance >= subtractedValue, "XRC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }



    function _transfer(        address sender,        address recipient,        uint256 amount    ) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");

        //      _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = r[sender].b[uint8(Balance.erc20)];
        require(senderBalance >= amount, "IERC20: transfer amount exceeds balance");
        unchecked {
            r[sender].b[uint8(Balance.erc20)] = senderBalance - amount;
        }


        /* WARNING: notice() registers balance for new unseen addresses */
        notice(recipient, true); // rescue relevant

        r[recipient].b[uint8(Balance.erc20)] += amount;

        emit Transfer(sender, recipient, amount);

       //      _afterTokenTransfer(sender, recipient, amount);
    }



    function _approve(        address owner,        address spender,        uint256 amount    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        r[owner].allowancesTime[spender] = block.timestamp;
        r[owner].allowances[spender] = amount;
        emit Approval(owner, spender, amount);
    }





  }

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ROCK2HEADER.sol";


interface ROCK2INTERFACE  {


  function name() external view  returns (string memory) ;
  function symbol() external view  returns (string memory) ;
  function decimals() external view  returns (uint8) ;
  function totalSupply() external view returns (uint256) ;
  function balanceOf(address account) external view returns (uint256) ;

  function transfer(address recipient, uint256 amount) external returns (bool) ;
  function allowance(address owner, address spender) external view returns (uint256) ;

// part of TokenSwap Interface
// function approve(address spender, uint256 amount) external returns (bool) ;
  function transferFrom( address sender, address recipient,       uint256 amount   ) external returns (bool) ;
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) ;
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;



  function lastBlockingOf(address account) external view returns (uint256) ;

  function balancesOf( address account) external returns (uint256 [16] memory b) ;
  function totals() external view returns (uint256 [5] memory) ;




  function getTimeStamp() external view returns (uint256) ;
  function totalFlow(address currency) external view returns (uint) ;
  function totalBalance() external view returns (uint256) ;
  function isProtected(address account) external view returns (bool) ;

  function getAPY() external view returns (uint256) ;
  function getAPY( uint256 now_ ) external view returns (uint256 rate, uint256 from, uint256 till, bool valid ) ;
  function getPrice() external view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) ;
  function getFee() external view returns (uint256 fee, uint96 unit);

  function hasDig(address sender) external view returns (bool) ;


}

// SPDX-License-Identifier: MIT

// 1795284 gas

pragma solidity ^0.8.0;


import "./AddressTree2HEADER.sol";


struct Calcs {
    uint256 start;
    uint256 end;
    uint256 volume;
}

struct Digs {
    uint256 timestamp;
    uint256 units;

    uint sIndex;

    address currency;
    uint256 price;
    uint256 decimals;
}

struct Rocking {
    address currency;
    uint256 price;
    uint256 decimals;

    uint256 apy;
    uint256 from;
    uint256 till;
    uint256 limit;
}


struct RockEntryLight {
  address delegatePaymentToAddress;

  uint[ 25 ] b;
  uint dCount;
  uint cCount;

}

struct RockEntry {
  address delegatePaymentToAddress;

  uint[ 25 ] b;
  uint dCount;
  uint cCount;

  mapping(uint => Digs) d;
  mapping(uint => Calcs) c;
  mapping(address => uint256) allowances;
  mapping(address => uint256) allowancesTime;
  mapping(uint256 => uint256) deadStore;

}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;



enum Balance {
  isNoticed,
  protected,
  erc20,
  blocked
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "./ROCK2HEADER.sol";




abstract contract ROCK2DATA is Context {

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Rocked(bytes32 id);


  // IDs
  bytes4 constant _INTERFACE_ID_SWAP = 0x83838383;

  bytes4 constant _INTERFACE_ID_PAWS = 0x38383838;



  // RockManagement

  mapping(address => RockEntry) r;

  mapping(uint256 => uint256) _deadBox;

  mapping(uint => mapping(uint => Rocking)) s;
  mapping(uint => uint) sCount;
  uint sIndex = 0;

  uint256 _maxAllowanceTime = 15*60; // 15 min


  // dig params

  uint256 digQualChildCountMin = 5;
  uint256 digSumChildMin = 10 * 10 * 10**_decimals;
  uint256 digSumNorm     =       5 * 10**_decimals;
  uint256 digSumMin      =       1 * 10**_decimals;

  uint256 _digPrice = 0.001 * ( 10**18);
  address _digCurrency = address(0);
  uint256 _digForSale = 1;
  uint8   _digDecimals = 18;


  // rt prov params

  uint256 _rate = 100;
  uint256 _keep = 85 + 45;


  // rock params

  uint256 _rockPrice = 0.001 * ( 10**18);
  address _rockCurrency = address(0);
  uint256 _rockToPayout = 0;
  uint8   _rockDecimals = 18;

  uint256 _rockFee = 0.001 *  10**18;
  uint96  _rockFeeUnit = 1000;

  uint256 _apy = 85;
  uint256 _apySetDate;
  uint256 _apyValid;


  uint256 public y2s = 365 * 24 * 60 * 60;


  // stats

  address[] balancedAddress;


  // totals

  uint256 _totalSupplyERC20 = 0;
  uint256 _totalSupplyBlocked = 0;
  uint256 _totalSummarized = 0;
  uint256 _totalSummarizedAPY = 0;
  uint256 _totalDigged = 0;
  uint256 _totalSale = 0;

  // money on the contract
  mapping( address => uint ) _totalFlow;


  // misc
  address[10] chargeAddresses;

  bool chainPayEnabled = true;

  uint256 controlSeed = 0;

  uint256 lastrn = 1;



  // ts param

  bool _swapAllowed = false;


  // basics

  string public _name;
  string public _symbol;

  uint8 _decimals = 10;

  uint8 dummy = 0;



  constructor(string memory name_, string memory symbol_) payable {

      _name = name_;
      _symbol = symbol_;

      _apySetDate = block.timestamp;
      _apyValid   = y2s;

      _totalFlow[address(0)] += msg.value;

  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;


interface MiniERC20 {

      function decimals() external view returns (uint8);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract AxxessControl2DATA  {

  /**
   * @notice Master's address FOOBAR
   */
  address[2] MasterAddress;

  /**
   * @notice Admin's address
   */
  address public AdminAddress;

  /**
   * @notice Operator's address
   */
  address[2] OperatorAddress;



  /**
   * @notice peer authorized contrat address
   */
  address PeerContractAddress;

  address delegate;
  address delegate2;

  // mem test
  uint8 public xs = 9;


  mapping(address => mapping (address => uint256)) allowed;


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AxxessControl2DATA.sol";

/**
 * @title AxxessControl2
 */
abstract contract AxxessControl2 is AxxessControl2DATA {


  constructor() {

    MasterAddress[0]     = msgSender();
    MasterAddress[1]     = msgSender();
    AdminAddress         = msgSender();
    OperatorAddress[0]   = msgSender();
    OperatorAddress[1]   = msgSender();

  }


  function msgSender() public view virtual returns (address) {
      return msg.sender;
  }

  function msgData() public view virtual returns (bytes calldata) {
      return msg.data;
  }




  /**
   * @dev Modifier to make a function only callable by the Master
   */
  modifier onlyMaster() {
    require(msgSender() == MasterAddress[0] || msgSender() == MasterAddress[1], "AC: c.i.n.  Master");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by the Admin
   */
  modifier onlyAdmin() {
    require(msgSender() == AdminAddress, "AC: c.i.n.  Admin");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by the Operator
   */
  modifier onlyOperator() {
    require(msgSender() == OperatorAddress[0] || msgSender() == OperatorAddress[1], "AC: c.i.n.  Operator");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by C-level execs
   */
  modifier onlyChiefLevel() {
    require(
      msgSender() == OperatorAddress[0] || msgSender() == OperatorAddress[1] ||
      msgSender() == MasterAddress[0] || msgSender() == MasterAddress[1] ||
      msgSender() == AdminAddress
    , "AC: c.i.n.  Master nor Admin nor Operator");
    _;
  }

  /**
   * @dev Modifier to make a function only callable by Master or Operator
   */

  modifier onlyMasterOrOperator() {
    require(
      msgSender() == OperatorAddress[0] || msgSender() == OperatorAddress[1] ||
      msgSender() == MasterAddress[0] || msgSender() == MasterAddress[1]
    , "AC: c.i.n.  Master nor Operator");
    _;
  }

  /**
   * @notice Sets a new Master
   * @param _newMaster - the address of the new Master
   */
  function setMaster(address _newMaster,uint level) external {
    require(_newMaster != address(0), "ad is null");
    require( level <2, "wrong level");
    require( msgSender() == MasterAddress[level], "AC: c.i.n. Master");
    MasterAddress[level] = _newMaster;
  }


  /**
   * @notice Sets a new Admin
   * @param _newAdmin - the address of the new Admin
   */
  function setAdmin(address _newAdmin) external onlyMasterOrOperator {
    require(_newAdmin != address(0), "ad is null");
    AdminAddress = _newAdmin;
  }

  /**
   * @notice Sets a new Operator
   * @param _newOperator - the address of the new Operator
   */
  function setOperator(address _newOperator, uint level) external {
    require(_newOperator != address(0), "ad is null");
    require( level <2, "wrong level");
    require( msgSender() == OperatorAddress[level], "AC: c.i.n. Master");
    OperatorAddress[level] = _newOperator;
  }


  // test access
  function getAccess(address testAddress) public view  returns (bool [4] memory) {
     address caller = testAddress;
     return [
       caller == MasterAddress[0] || caller == MasterAddress[1] || caller == AdminAddress || caller == OperatorAddress[0] || caller == OperatorAddress[1],
       caller == MasterAddress[0] || caller == MasterAddress[1],
       caller == AdminAddress,
       caller == OperatorAddress[0] || caller == OperatorAddress[1]
     ];
   }

  // show access
  function getAccessWallets() public view  returns (address [5] memory) {
    return [
      MasterAddress[0],
      MasterAddress[1],
      AdminAddress,
      OperatorAddress[0],
      OperatorAddress[1]
     ];
   }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct Entry {

  uint256 id;

  address promotedByAddress;
  address walletAddress;

  address[] childs;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AddressTree2HEADER.sol";



abstract contract AddressTree2DATA {

  // database
  mapping(address => Entry) m;

  // database entry helper
  mapping(address => bool) mExists;

  // reverse lookup
  mapping(address => address) mPromotedBy;

  //array of all stakers
  address[] _mAddress;



  bool simpleMode = false;

  uint256 globalMemberId = 0;



  uint8 _maxDepth = 6;

  uint8 _balanceMax = 20;

  uint8 public max = 17;


  constructor() {

    address promotedByAddress = address(0);

    mExists[ promotedByAddress ] = true;
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