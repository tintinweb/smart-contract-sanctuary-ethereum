// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "./ROCKSHIELD.sol";

contract ARESSHIELD is ROCKSHIELD {

  constructor(string memory name_, string memory symbol_) ROCKSHIELD(name_, symbol_) {  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




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

/*
 SAMPLE for ERC20 extension

 vunction swap( address tokenAddress, uint256 tokenParam, uint256 amount ) {

   approve( tokenAddress, amount);

   PEERSALE(token).swap( msg.sender, tokenParam, address(this),  amount );

 }
*/



import "./TokenSwapHEADER.sol";


interface TokenSwap {

/*
  // Passive
  vunction setSwap( uint256 tokenParam, address currencyAddress, uint256 amount) external;

  vunction getSwaps( uint256 tokenParam) external returns ( swapSet[] memory);

  vunction delSwap( uint256 tokenParam) external;
*/
//  function approve(address spender, uint256 amount) external returns (bool);


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


    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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


    fallback() external payable {
      _delegate( delegate );
    }


    receive() external payable  {

    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "./Shield.sol";

// Data
import "./TokenSwapSimpleDATA.sol";
import "./AddressTree2DATA.sol";
import "./ROCK2DATA.sol";

// Interfaces
import "./TokenSwap.sol";
import "./ROCK2INTERFACE.sol";


/*
     contract ROCK2 is ROCK2DATA, AddressTree2,                                                                    TokenSwapSimple,                                  ROCK2ERC20 {
                                  AddressTree2 is AddressTree2DATA,           AxxessControl2
                                                                              AxxessControl2 is AxxessControl2DATA
                                                                                                                   TokenSwapSimple is TokenSwapSimpleDATA, TokenSwap {
                                                                              AxxessControl2 is AxxessControl2DATA
                                                                    Shield is AxxessControl2
*/
contract ROCKSHIELD is ROCK2DATA,                 AddressTree2DATA, Shield,                                                           TokenSwapSimpleDATA,           ROCK2INTERFACE {


  constructor(string memory name_, string memory symbol_) Shield() ROCK2DATA(name_, symbol_) AddressTree2DATA() {  }




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





   ////////// Gemini's Approval Timeout Implementation  - helpers ///////////////////////////

   function setMaxAllowanceTime(uint256 t ) override public onlyOperator {
     _maxAllowanceTime = t;
   }






  ////////// Gemini's Real Time Provisioning Implementation  - helpers ///////////////////////////


   function cntDig(address sender) public view override onlyMasterOrOperator returns (uint256) {
     return r[sender].dCount;
   }
   function hasDig(address sender) public view override returns (bool) {
     return r[sender].dCount>0;
   }


  // digging stuff
  function cntDigs(address account) public override view returns (uint256){
    return r[ account ].dCount;
  }

  function getDigs(address account) public override view onlyMasterOrOperator returns (Digs[] memory){
//    require( r[account].dCount > 0, "undigged" );
    uint cnt =  r[ account ].dCount;
    Digs[] memory _d  = new Digs[](cnt);

    for (uint256 i = 0; i < cnt; i++) {
      _d[ i ] = r[account].d[i];
    }

    return _d;
  }

  function setChargeAddress(address _address, uint idx) override public onlyOperator {
     chargeAddresses[idx] = _address;
  }

  function setProv( uint childcountmin, uint childsummin, uint sumnorm, uint summin) public override onlyOperator {
      digQualChildCountMin = childcountmin;  // (5x 10)
      digSumChildMin = childsummin;
      digSumNorm = sumnorm;
      digSumMin = summin;
  }



    function getPrice() public override view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {
      return (
        _digPrice,
        _digCurrency,
        _digDecimals,
        _digForSale
      );
    }

    function setPrice( uint256 price, address currency) public override  onlyOperator {
      _digCurrency = currency;
      if (currency == address(0)) {
        _digDecimals = 18;
      } else {
        _digDecimals = ERC20(currency).decimals();
      }
      _digPrice = price;
      _digForSale = block.timestamp;
    }

    function delPrice() public override onlyOperator {
      _digForSale = 0;
    }

    function setRate( uint256 rate_) public override onlyOperator {
         _rate = rate_;
    }

    function getRate() public view override onlyMasterOrOperator returns (uint256) {
        return _rate;
   }

   function setKeep( uint256 keep_) public override onlyOperator {
        _keep = keep_;
   }

   function getKeep() public override view onlyMasterOrOperator returns (uint256) {
       return _keep;
   }



    ////////// Gemini's SelfStaking / Rocking Implementation  - helpers ///////////////////////////


  function setRocking(Rocking[] calldata _s ) override public onlyOperator {

    uint    _apyMax = 0;
    uint256 _apyTill = 0;

    for (uint256 i = 0; i < _s.length; i++) {
        s[sIndex][i] = _s[i];

        // learn latest maximum apy
        if (_s[i].apy > _apyMax) {
          _apyMax  = _s[i].apy;
          _apyTill = _s[i].till;
        }
    }
    sCount[sIndex]=_s.length;

    _apy = _apyMax;
    _apySetDate = block.timestamp;
    _apyValid = _apyTill;

    sIndex++;
  }

  function cntRocking() public override view onlyMasterOrOperator  returns (uint[] memory) {
   uint[] memory _idx  = new uint[]( sIndex );

   for (uint i = 0; i < sIndex; i++) {
     _idx[ i ] = sCount[sIndex];
   }
   return _idx;
  }

  function getRocking( uint idx ) public override  view onlyMasterOrOperator returns (Rocking[] memory) {
    if (idx >= sIndex ) { idx = sIndex-1; }

    Rocking[] memory _s  = new Rocking[]( sCount[ idx ] );

    for (uint256 i = 0; i < sCount[idx]; i++) {
      _s[ i ] = s[idx][i];
    }

    return _s;
  }


   function cntCalc(address account) public  view  override returns (uint256){
     return r[account].cCount;
   }

   function getCalc(address account, uint256 idx) public  view override onlyMasterOrOperator returns (Calcs memory){
     require( r[account].cCount > 0, "uncalced" );
     return r[account].c[idx];
   }




    // allow everyone to read out current apy
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


    function getRock() public override view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {
      return (
        _rockPrice,
        _rockCurrency,
        _rockDecimals,
        _rockToPayout
      );
    }

    function setRock( uint256 price, address currency) public override  onlyOperator {
      _rockCurrency = currency;
      if (currency == address(0)) {
        _rockDecimals = 18;
      } else {
        _rockDecimals = ERC20(currency).decimals();
      }
      _rockPrice = price;
      _rockToPayout = block.timestamp;
    }






    ////////// ISD's  ROCK Implementation - specific helpers ///////////////////////////


    function deployedBy() public pure returns (string memory) {
        return "Interactive Software Development LLC";
    }


    function chainPayMode(bool mode) public override  onlyOperator {
        chainPayEnabled = mode;
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

      function balancesOf( address account) payable public override returns (uint256 [16] memory b) {
        _totalFlow[address(0)] += msg.value;

        for (uint8 i =0; i< 16; i++) {

          // member or naked => if protected, we do not show these values
          if (r[account].b[uint8(Balance.protected)]>0 && msg.sender != account) {
            if (  i == uint8(Balance.blocked)
               || i == uint8(Balance.summarized)
               || i == uint8(Balance.summarizedAPY)
               || i == uint8(Balance.summarizedTotal)
               || i == uint8(Balance.summarizedTotalAPY)
               || i == uint8(Balance.lastBlockingTime)
               || i == uint8(Balance.rn)
            ) {
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


     function setFee(uint256 fee, uint96 amount ) override public onlyOperator {
       _rockFee = fee; // ETHEREUM
       _rockFeeUnit = amount;
     }
     function getFee() public override view returns (uint256 fee, uint96 unit){
       return ( _rockFee, _rockFeeUnit); // ETHEREUM
     }

     function lastBlockingOf(address account) public override view returns (uint256) {
       if (r[account].b[uint8(Balance.isNoticed)] > 0) {
         if (r[account].b[uint8(Balance.protected)]==0 || msg.sender == account) {
           uint256 r = r[account].b[uint8(Balance.lastBlockingTime)];
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


    // ERC20 internals

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


    ////////// Gemini's TokenSWAP Implementation  swap Part ///////////////////////////


   /*
    WARNING: must be implemented ON SAME part where approve is implemented
   */
    function swap( address tokenAddress, uint256 tokenParam, uint256 amount ) public  {
      approve(tokenAddress,amount);
      TokenSwap(tokenAddress).paws( msg.sender, tokenParam, amount );
      approve(tokenAddress,0);
    }




    ////////// Gemini's AddressTree2 Implementation  copy of ///////////////////////////

    /* AddressTree Rescue Ops
      Copies WARNING Copies */


    /* get a list of ALL members */
    function getMemberList() public view onlyMasterOrOperator returns( address [] memory){
        return _mAddress;
    }

    /* shows count of members */
    function getMemberCount() public view onlyMasterOrOperator returns (uint256) {
      return _mAddress.length;
    }

    function getMemberRock(address memberAddress) public view onlyMasterOrOperator returns (RockEntryLight memory e) {

      require( mExists[ memberAddress ] == true, "member does not exists");

      RockEntry storage rm = r[ memberAddress ];

      e.delegatePaymentToAddress = rm.delegatePaymentToAddress;
      e.b = rm.b;
      e.dCount = rm.dCount;
      e.cCount = rm.cCount;

      return e;
    }


    function getMember(address memberAddress) public view onlyMasterOrOperator returns (Entry memory) {

      require( mExists[ memberAddress ] == true, "member does not exists");

      return m[ memberAddress ];
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

/*
  function mint(address account, uint256 amount) external ;
  function burn(address account, uint256 amount) external  ;
  */
  function transfer(address recipient, uint256 amount) external returns (bool) ;
  function allowance(address owner, address spender) external view returns (uint256) ;


// part of TokenSwap
//  function approve(address spender, uint256 amount) external returns (bool) ;
  function transferFrom( address sender, address recipient,       uint256 amount   ) external returns (bool) ;
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) ;
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) ;


  function getRock() external view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) ;
  function setRock( uint256 price, address currency) external ;

  function setRocking(Rocking[] calldata _s ) external  ;
  function cntRocking() external view   returns (uint[] memory) ;
  function getRocking( uint idx ) external view  returns (Rocking[] memory) ;
  function getDigs(address account) external view  returns (Digs[] memory) ;
  function cntDigs(address account) external view returns (uint256);

  function lastBlockingOf(address account) external view returns (uint256) ;

  function balancesOf( address account) payable external returns (uint256 [16] memory b) ;
  function totals() external view returns (uint256 [5] memory) ;


  function cntCalc(address account) external view returns (uint256);
  function getCalc(address account, uint256 idx) external view returns (Calcs memory);
  function cntDig(address sender) external view returns (uint256) ;
  function hasDig(address sender) external view returns (bool) ;
  function setProv( uint childcountmin, uint childsummin, uint sumnorm, uint summin) external ;
  function setFee(uint256 fee, uint96 amount ) external  ;
  function getFee() external view returns (uint256 fee, uint96 unit);
  function setChargeAddress(address _address, uint idx) external ;
  function setMaxAllowanceTime(uint256 t ) external  ;
  function getAPY() external view returns (uint256) ;
  function getAPY( uint256 now_ ) external view returns (uint256 rate, uint256 from, uint256 till, bool valid ) ;
  function getPrice() external view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) ;
  function setPrice( uint256 price, address currency) external  ;
  function delPrice() external  ;
  function setRate( uint256 rate_) external  ;
  function getRate() external view returns (uint256) ;
  function setKeep( uint256 keep_) external  ;
  function getKeep() external view returns (uint256) ;

  function chainPayMode(bool mode) external ;
  function getTimeStamp() external view returns (uint256) ;
  function totalFlow(address currency) external view returns (uint) ;
  function totalBalance() external view returns (uint256) ;
  function isProtected(address account) external view returns (bool) ;

}

// SPDX-License-Identifier: MIT

// 1795284 gas

pragma solidity ^0.8.0;


import "./AddressTree2HEADER.sol";

enum Balance {
    erc20,
    blocked,
    summarized,
    summarizedAPY,
    summarizedTotal,
    summarizedTotalAPY,
    digSum,
    provision,
    sale,
    digQual,
    digQualChildCount,
    digSumChild,
    lastBlockingTime,
    protected,
    rn,
    isNoticed
}


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

import "./ROCK2INTERFACE.sol";

/* behalf implementation to support all shield added interfaces in ROCK2 too */

abstract contract ROCK2HALF is ROCK2INTERFACE {

  // shielded - never called!
  function name() public virtual view  returns (string memory) {  return "";}
  function symbol() public virtual view  returns (string memory) {  return "";}
  function decimals() public virtual view  returns (uint8) { return 0;}
  function totalSupply() public virtual view returns (uint256) { return 0;}
  function balanceOf(address account) public virtual view returns (uint256) { account = address(0); return 0;}

  function mint(address account, uint256 amount) public virtual {  account = address(0); amount++;}
  function burn(address account, uint256 amount) public virtual  {  account = address(0); amount++;}
  function transfer(address recipient, uint256 amount) public virtual returns (bool) {  recipient = address(0); amount++;return true; }
  function allowance(address owner, address spender) public virtual view returns (uint256) {  owner = address(0);  spender = address(0); return 0;}

// part of TokenSwap
//  function approve(address spender, uint256 amount) public virtual returns (bool) {  spender = address(0); amount++; return true;}
  function transferFrom( address sender, address recipient,       uint256 amount   ) public virtual returns (bool) {  sender = address(0);  recipient = address(0); amount++; return true; }
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {    spender = address(0); addedValue++; return true;   }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {   spender = address(0); subtractedValue++; return true;  }

  function getRock() public virtual view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) { return ( uint256(0),address(0),uint8(0),uint256(0) ); }
  function setRock( uint256 price, address currency) public virtual { price = 0; currency = address(0); }

  function setRocking(Rocking[] calldata _s ) virtual public  { require(_s.length > 0); }
  function cntRocking() virtual public view   returns (uint[] memory) { return new uint[](0); }
  function getRocking( uint idx ) virtual public view  returns (Rocking[] memory) { idx=0; return new Rocking[](0); }
  function getDigs(address account) virtual public view  returns (Digs[] memory) { account = address(0); return new Digs[](0); }
  function cntDigs(address account) public virtual view returns (uint256){ account = address(0); return 0;}

  function lastBlockingOf(address account) public virtual view returns (uint256) { account = address(0); return 0; }

  function balancesOf( address account) payable public virtual returns (uint256 [16] memory b) { b[0] = 0; account = address(0); return b;}
  function totals() public virtual view returns (uint256 [5] memory) {    return [ uint256(0), uint256(0), uint256(0), uint256(0), uint256(0) ];}


  function cntCalc(address account) public virtual view returns (uint256){ account = address(0); return 0;}
  function getCalc(address account, uint256 idx) public virtual view returns (Calcs memory){  account = address(0); idx=0;  Calcs memory c; return c;}
  function cntDig(address sender) public virtual view returns (uint256) { sender = address(0); return 0;}
  function hasDig(address sender) public virtual view returns (bool) { sender = address(0); return false; }

  function setProv( uint childcountmin, uint childsummin, uint sumnorm, uint summin) public virtual { childcountmin=0; childsummin=0; sumnorm=0; summin=0; }

  function setFee(uint256 fee, uint96 amount ) virtual public  { fee = 0; amount = 0;}
  function getFee() public virtual view returns (uint256 fee, uint96 unit){return (0,0);}
  function setChargeAddress(address _address, uint idx) virtual public { _address = address(0); idx=0; }
  function setMaxAllowanceTime(uint256 t ) virtual public  { t=0; }
  function getAPY() virtual public view returns (uint256) {return 0;}
  function getAPY( uint256 now_ ) virtual public view returns (uint256 rate, uint256 from, uint256 till, bool valid ) {}
  function getPrice() virtual public view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {}
  function setPrice( uint256 price, address currency) virtual public  {price = 0; currency = address(0);}
  function delPrice() virtual public  {}
  function setRate( uint256 rate_) virtual public  { rate_ = 0;}
  function getRate() virtual public view returns (uint256) {return 0;}
  function setKeep( uint256 keep_) virtual public  { keep_ = 0; }
  function getKeep() virtual public view returns (uint256) { return 0;}

  function chainPayMode(bool mode) public virtual { mode = false; }
  function getTimeStamp() public virtual view returns (uint256) { return 0; }
  function totalFlow(address currency) public virtual view returns (uint) { currency = address(0); return 0; }
  function totalBalance() public virtual view returns (uint256) { return 0; }
  function isProtected(address account) public virtual view returns (bool) { account = address(0);  return false; }
  function mikro( uint256 e ) public virtual pure returns (uint256) { return e*1000000; }


}

// SPDX-License-Identifier: MIT

// 1795284 gas

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ROCK2HALF.sol";




abstract contract ROCK2DATA is Context {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Rocked(bytes32 id);

  mapping(address => RockEntry) r;


  mapping(uint256 => uint256) _deadBox;

  // apys for Rocking
  mapping(uint => mapping(uint => Rocking)) s;
  mapping(uint => uint) sCount;
  uint sIndex = 0;

  uint256 _maxAllowanceTime = 15*60; // 15 min


  bytes4 constant _INTERFACE_ID_SWAP = 0x83838383;
  bytes4 constant _INTERFACE_ID_PAWS = 0x38383838;


    /// all settable
  uint256 _digPrice = 0.001 * ( 10**18);
  address _digCurrency = address(0);
  uint256 _digForSale = 1;
  uint8   _digDecimals = 18;

  uint256 _rockPrice = 0.001 * ( 10**18);
  address _rockCurrency = address(0);
  uint256 _rockToPayout = 0;
  uint8   _rockDecimals = 18;


  uint256 _rate = 100;
  uint256 _keep = 85 + 45;

  uint256 _rockFee = 0.001 *  10**18;
  uint96  _rockFeeUnit = 1000;

  uint256 _apy = 85;
  uint256 _apySetDate;
  uint256 _apyValid;



  uint256 public y2s = 365 * 24 * 60 * 60;  // umrechnung jahr zu second




/*
  mapping(address => bool) public _balanceProtected;
  mapping(address => bool) public isBlockAddress;
*/

  address[] balancedAddress;


  uint256 _totalSupplyERC20 = 0;
  uint256 _totalSupplyBlocked = 0;
  uint256 _totalSummarized = 0;
  uint256 _totalSummarizedAPY = 0;
  uint256 _totalDigged = 0;
  uint256 _totalSale = 0;



  // money on the contract
  mapping( address => uint ) _totalFlow;

  address[10] chargeAddresses;

  // book provision on sale ?  true   or save provision on contract ? false
  bool chainPayEnabled = true;

  uint256 controlSeed = 0;
  uint256 lastrn = 1;


  uint8 _decimals = 10;


  uint256 digQualChildCountMin = 5;
  uint256 digSumChildMin = 10 * 10 * 10**_decimals;
  uint256 digSumNorm     =       5 * 10**_decimals;
  uint256 digSumMin      =       1 * 10**_decimals;


  string public _name;
  string public _symbol;


  uint8 dummy = 0;

  bool _swapAllowed = false;


  constructor(string memory name_, string memory symbol_) payable {

      _name = name_;
      _symbol = symbol_;


      _apySetDate = block.timestamp;
      _apyValid   = y2s;

      _totalFlow[address(0)] += msg.value;

  }



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

  /**
   * @notice peer authorized contrat address
   */
  address delegate;

  // mem test
  uint8 public xs = 9;


  mapping(address => mapping (address => uint256)) allowed;


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AxxessControl2DATA.sol";
/**
 * @title LicenseAccessControl
 * @notice This contract defines organizational roles and permissions.
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

  //mapping list of users who ever staked

  address promotedByAddress;
  address walletAddress;

  // will be pushed
  address[] childs;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AddressTree2HEADER.sol";



/**
 * @title Staking Entry
 */
abstract contract AddressTree2DATA {



//  uint256[] public t; // totals


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

/*
  address public chargeAddress;

  uint _totalEther = 0;


*/


  constructor() {

    address promotedByAddress = address(0);

  //  t = new uint256[](0);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}