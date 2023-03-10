/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18 <0.8.20;

/*

Vickrey Auction Hash Registrar ( by pepihasenfuss, copyright (c) 2023, based on ENS 1.0 Temporary Hash Registrar, a Vickrey Auction introduced by Nick Johnson and ENS team )
A Vickrey auction or sealed-bid second-price auction SBSPA is a type of sealed-bid auction.
========================

//   ENS, ENSRegistryWithFallback, PublicResolver, Resolver, FIFS-Registrar, Registrar, AuctionRegistrar, BaseRegistrar, ReverseRegistrar, DefaultReverseResolver, ETHRegistrarController,
//   PriceOracle, SimplePriceOracle, StablePriceOracle, ENSMigrationSubdomainRegistrar, CustomRegistrar, Root, RegistrarMigration are contracts of "ENS", by Nick Johnson and team.
//
//   Copyright (c) 2018, True Names Limited / ENS Labs Limited
//
//   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

interface AbstractENS {
  function owner(bytes32 node) external view  returns(address);
  function resolver(bytes32 node) external view  returns(address);
  function ttl(bytes32 node) external view  returns(uint64);
  function setOwner(bytes32 node, address ensowner)  external;
  function setSubnodeOwner(bytes32 node, bytes32 label, address ensowner)  external;
  function setResolver(bytes32 node, address ensresolver)  external;
  function setTTL(bytes32 node, uint64 ensttl)  external;

  event NewOwner(bytes32 indexed node, bytes32 indexed label, address ensowner);
  event Transfer(bytes32 indexed node, address ensowner);
  event NewResolver(bytes32 indexed node, address ensresolver);
  event NewTTL(bytes32 indexed node, uint64 ensttl);
}

abstract contract AbstractTokenProxy {
  function balanceOf(address tokenOwner) external virtual view returns (uint thebalance);
  function name() external virtual view returns (string memory);
  function transferFrom_78S(address from, address toReceiver, uint amount) external virtual;
  function tokenAllow(address tokenOwner,address spender) external virtual view returns (uint256 tokens);
  function transfer_G8l(address toReceiver, uint amount) external virtual;
  function transferAdjustPrices(address toReceiver, uint amount, uint payment, bytes32 dhash, address deedContract) external virtual;
}

abstract contract Resolver {
  mapping (bytes32 => string) public name;
}

abstract contract AbstractReverseRegistrar {
  Resolver public defaultResolver;
  function node(address addr) external virtual pure returns (bytes32);
}

abstract contract AbstractResolver {
  mapping(bytes32=>bytes) hashes;

  event AddrChanged(bytes32 indexed node, address a);
  event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
  event NameChanged(bytes32 indexed node, string name);
  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
  event ContenthashChanged(bytes32 indexed node, bytes hash);

  function name(bytes32 node) external virtual view returns (string memory);
  function addr(bytes32 node) external virtual view returns (address payable);

  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external virtual;
  function setAddr(bytes32 node, address r_addr) external virtual;
  function setAddr(bytes32 node, uint coinType, bytes calldata a) external virtual;
  function setName(bytes32 node, string calldata _name) external virtual;
  function setText(bytes32 node, string calldata key, string calldata value) external virtual;
  function setAuthorisation(bytes32 node, address target, bool isAuthorised) external virtual;
}

contract AbstractGWMBaseRegistrar {
  event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
  event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
  event NameRenewed(uint256 indexed id, uint expires);

  bytes32 public baseNode;   // The namehash of the TLD this registrar owns (eg, .eth)
}

abstract contract AbstractETHRegistrarController {
  event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
  event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);

  function rentPrice(string memory name, uint duration) view external virtual returns(uint);
  function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) external virtual payable;
}

abstract contract AbstractGroupWalletProxy {
  function getGWF() external view virtual returns (address);
}

abstract contract AbstractGroupWalletFactory {
  AbstractResolver                public  resolverContract;
  AbstractETHRegistrarController  public  controllerContract;
  AbstractGWMBaseRegistrar        public  base;
  AbstractENS                     public  ens;
  AbstractReverseRegistrar        public  reverseContract;

  function getProxyToken(bytes32 _domainHash) public virtual view returns (address p);
}

abstract contract ABS_Reg {
  function state_pln(bytes32 _hash) public view virtual returns (uint);
  function saveExtDeedCntr_gm9(address _sender,bytes32 _hash,uint _value) public payable virtual;
  function unsealExternalBid_qfG(bytes32 _hash) public payable virtual;
  function finalizeExternalAuction_WmS(bytes32 _hash) public payable virtual;
  function cancelExternalBid_9ig(bytes32 seal, bytes32 hash) public payable virtual;
}

bytes32 constant kkk = 0x4db45745d63e3d3fca02d388bb6d96a256b72fa6a5ca7e7b2c10c90c84130f3b;

// ******************************* DeedProxy CONTRACT **************************


contract IntDeedProxy {
    address internal masterCopy;
    bytes32 public  lhash;
    address public  owner;
    uint64  public  creationDate;
    event DeedCreated(address indexed);
  
    constructor(address _masterCopy,address _owner,bytes32 _lhash) payable { 
      masterCopy   =  _masterCopy;
      owner        =  _owner;
      creationDate =   uint64(block.timestamp);
      lhash        = _lhash;
      emit DeedCreated(address(this));
    }
    
    fallback () external payable
    {   
      // solium-disable-next-line security/no-inline-assembly
      assembly {
          let master := and(sload(0),0xffffffffffffffffffffffffffffffffffffffff)
          if eq(calldataload(0),0xa619486e00000000000000000000000000000000000000000000000000000000) {
            mstore(0, master)
            return(0, 0x20)
          }

          let ptr := mload(0x40)
          calldatacopy(ptr, 0, calldatasize())
          let success := delegatecall(gas(),master,ptr,calldatasize(),0,0)
          returndatacopy(0, 0, returndatasize())
          if eq(success,0) { revert(0,0x204) }
          return(0, returndatasize())
      }
    }
}
// ******************************* DeedProxy CONTRACT **************************

abstract contract ABS_IntDeedMaster {
  address public  masterCopy;
  ABS_Reg public  theRegistrar;
}

// ******************************* DEED MASTER CONTRACT ************************
contract intDeedMaster {
  address internal masterCopy;
  bytes32 public  lhash;
  address public  owner;
  uint64  public  creationDate;
  event DeedCreated(address indexed);
  
  ABS_Reg public  theRegistrar;

  constructor(address _masterCopy) payable
  {
    masterCopy   = _masterCopy;
    owner        = tx.origin;
    theRegistrar = ABS_Reg(msg.sender);
    creationDate = uint64(block.timestamp);
  }
  
  function registrar() public payable returns (ABS_Reg) {
    return ABS_IntDeedMaster(masterCopy).theRegistrar();
  }
  
  function adjustBal_1k3(uint newValue) public payable {                        // 0x0000f6a6
    if (address(this).balance<newValue) return;
    require(msg.sender==address(registrar())&&payable(address(uint160(owner))).send(address(this).balance-newValue),"aBl");
  }

  function closeDeed_igk(address receiver) public payable {                     // 0x00004955
    address l_rcv = owner;
    require(owner!=address(0x0),'owner=0x0');
    
    if (uint160(receiver)>0) l_rcv = receiver;
    require(msg.sender==address(registrar())&&l_rcv!=address(0x0)&&payable(l_rcv).send(address(this).balance),"iclD");
  }
}

// ******************************* EXT DEED MASTER CONTRACT ********************
contract extDeedMaster {
  address internal masterCopy;
  address public  owner;
  uint64  public  creationDate;
  ABS_Reg public  registrar;
  bytes32 public  lhash;
  event DeedCreated(address indexed);

  constructor(address _masterCopy) payable
  {
    masterCopy   = _masterCopy;
    owner        = tx.origin;
    registrar    = ABS_Reg(msg.sender);
    creationDate = uint64(block.timestamp);
  }

  function adjustBal_1k3(uint newValue) public payable {                        // 0x0000f6a6
    if (address(this).balance<=newValue) return;
    require(msg.sender==address(registrar)&&address(this).balance>0&&payable(address(uint160(owner))).send(address(this).balance-newValue),"aSd");
  }

  function closeDeed_igk(address receiver) public payable {                     // 0x00004955
    require(msg.sender==address(registrar)&&payable(address( (receiver!=address(0x0)) ? receiver : owner )).send(address(this).balance),"exD");
  }
  
  receive() external payable {    
    uint lstate = registrar.state_pln(lhash);
    
    if (lstate==1) {                                                            // OPEN for bidding
      require(lhash!=0x0&&msg.value>0&&address(this).balance==msg.value,"e2");
      owner = msg.sender;
      registrar.saveExtDeedCntr_gm9(msg.sender,lhash,msg.value);
    } else
    {
      if (lstate>1) require(lhash!=0x0&&msg.value==0&&owner==msg.sender,"ex");  // only Deed owner

      if (lstate==4) {                                                      
        registrar.unsealExternalBid_qfG(lhash);                                 // REVEAL phase
      } else
      {
        if (lstate==2) {                                                        // FINALIZE phase
          registrar.finalizeExternalAuction_WmS(lhash);
        } else
        {
          if (lstate==6) {                                                      // CANCEL after auction done
            registrar.cancelExternalBid_9ig(keccak256(abi.encode(lhash,owner,address(this).balance,kkk)),lhash);
          } else
          {
            lstate = 0;
            if (msg.value>0) require(!payable(msg.sender).send(msg.value),"FB");// fallback: send back payment to sender
          }
        }
      }
    }
  }
}
// ************************* ExtDeedProxy CONTRACT *****************************


contract ExtDeedProxy {
    address internal masterCopy;
    address public  owner;
    uint64  public  creationDate;
    ABS_Reg public  registrar;
    bytes32 public  lhash;
    event DeedCreated(address indexed);
    
    constructor(address _masterCopy,bytes32 _lhash) payable { 
      masterCopy   = _masterCopy;
      registrar    =  ABS_Reg(msg.sender);
      creationDate =  uint64(block.timestamp);
      lhash        = _lhash;
      emit DeedCreated(address(this));
    }
    
    fallback () external payable
    {   
      // solium-disable-next-line security/no-inline-assembly
      assembly {
          let ptr := mload(0x40)
          calldatacopy(ptr, 0, calldatasize())
          let success := delegatecall(gas(),and(sload(0),0xffffffffffffffffffffffffffffffffffffffff),ptr,calldatasize(),0,0)
          returndatacopy(0, 0, returndatasize())
          if eq(success,0) { revert(0,0x204) }
          return(0, returndatasize())
      }
    }
}
// ************************* ExtDeedProxy CONTRACT *****************************



/**
 * @title Deed to hold ether in exchange for ownership of shares
 * @dev The deed can be controlled only by the registrar and can only send ether back to the owner or forwards payment to GroupWallet.
 */
contract Deed {
  bytes32 public  lhash;
  address public  registrar;
  address public  owner;
  uint64  public  creationDate;

  event DeedCreated(address indexed);

  constructor(address _owner, bytes32 _lhash) payable {
    owner        = _owner;
    registrar    = msg.sender;
    creationDate = uint64(block.timestamp);
    lhash        = _lhash;
    emit DeedCreated(address(this));
  }
  
  function adjustBal_1k3(uint newValue) public payable {                        // 0x0000f6a6
    if (address(this).balance<newValue) return;
    require(msg.sender==registrar&&payable(address(uint160(owner))).send(address(this).balance-newValue),"aBlD");
  }

  /**
   * @dev Close a deed and refund the bid value
   * @param receiver    GroupWallet contract to send funds to
   */
  function closeDeed_igk(address receiver) public payable {                     // 0x00004955
    require(msg.sender==registrar&&payable(address( (receiver!=address(0x0)) ? receiver : owner )).send(address(this).balance),"clD");
  }
}

abstract contract ABS_ExtDeed {
  ABS_Reg public  registrar;
  address public  owner;
}

/**
 * @title extDeed to hold ether in exchange for ownership of shares
 * @dev The deed can be controlled only by the registrar and can only send ether back to the owner or forwards payment to GroupWallet.
 */
contract extDeed {
  bytes32 public  lhash;
  ABS_Reg public  registrar;
  address public  owner;
  uint64  public  creationDate;

  event DeedCreated(address indexed);

  constructor(address _owner, bytes32 _lhash) payable {
    owner        = _owner;
    registrar    =  ABS_Reg(msg.sender);
    creationDate =  uint64(block.timestamp);
    lhash        = _lhash;
    emit DeedCreated(address(this));
  }
  
  function adjustBal_1k3(uint newValue) public payable {                        // 0x0000f6a6
    if (address(this).balance<=newValue) return;
    require(msg.sender==address(registrar)&&address(this).balance>0&&payable(address(uint160(owner))).send(address(this).balance-newValue),"aSd");
  }

  function closeDeed_igk(address receiver) public payable {                     // 0x00004955
    require(msg.sender==address(registrar)&&payable(address( (receiver!=address(0x0)) ? receiver : owner )).send(address(this).balance),"exD");
  }
  
  receive() external payable {    
    uint lstate = registrar.state_pln(lhash);
    
    if (lstate==1) {                                                            // OPEN for bidding
      require(lhash!=0x0&&msg.value>0&&address(this).balance==msg.value,"e2");
      owner = msg.sender;
      registrar.saveExtDeedCntr_gm9(msg.sender,lhash,msg.value);
    } else
    {
      if (lstate>1) require(lhash!=0x0&&msg.value==0&&owner==msg.sender,"ex");  // only Deed owner

      if (lstate==4) {                                                      
        registrar.unsealExternalBid_qfG(lhash);                                 // REVEAL phase
      } else
      {
        if (lstate==2) {                                                        // FINALIZE phase
          registrar.finalizeExternalAuction_WmS(lhash);
        } else
        {
          if (lstate==6) {                                                      // CANCEL after auction done
            registrar.cancelExternalBid_9ig(keccak256(abi.encode(lhash,owner,address(this).balance,kkk)),lhash);
          } else
          {
            lstate = 0;
            if (msg.value>0) require(!payable(msg.sender).send(msg.value),"FB");// fallback: send back payment to sender
          }
        }
      }
    }
  }
}

/**
 * @title Registrar
 * @dev The registrar handles the auction process.
 */
contract Registrar {
    mapping (address => mapping(bytes32 => uint256)) private biddingValue;
    mapping (bytes32 => uint256) entry_B;
    mapping (bytes32 => uint256) entry_A;
    mapping (bytes32 => uint256) entry_C;

    enum Mode { Open, Auction, Owned, Forbidden, Reveal, empty, Over }
    
    uint public registryStarted;
    address public RegOwner;

    event AuctionStarted(bytes32 indexed hash, uint indexed);
    event NewBid(bytes32 indexed hash, address indexed, uint indexed);
    event BidRevealed(bytes32 indexed hash, address indexed, uint indexed, uint8);
    event HashReleased(bytes32 indexed hash, uint indexed);
    event AuctionFinalized(bytes32 indexed hash, address indexed, uint indexed, uint);
    event TestReturn(uint256 v1, uint256 v2, uint256 v3, uint256 v4);
    event Deposit(address indexed, uint256 indexed);
    event ExternalDeedMaster(address indexed);
    event InternalDeedMaster(address indexed);


    uint256 constant k_maskBidVal   = 0x00000000000000000000000000000000000000000000ffffffffffffffffffff;
    uint256 constant k_maskSealBid  = 0xffffffffffffffffffffffffffffffffffffffffffff00000000000000000000; 
    uint256 constant k_addressMask  = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff; 
    uint256 constant k_highBidMask  = 0x0000ffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_regDataMask  = 0x00000000000000007fffffff0000000000000000000000000000000000000000;
    uint256 constant k_regDataMask2 = 0x000000000000000000000000000000000000000000000000000000007fffffff;
    uint256 constant k_regDataMask3 = 0xffffffffffffffff80000000ffffffffffffffffffffffffffffffffffffffff; 
    uint256 constant k_finalizeMask = 0x0000000000000000800000000000000000000000000000000000000000000000;
    uint256 constant k_finFlagMask  = 0xffffffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_minPrcMask   = 0xffffffffffffffff000000000000000000000000000000000000000000000000;
    uint256 constant k_minPrcMask2  = 0x000000000000000000000000000000000000000000000000ffffffffffffffff;
    uint256 constant k_minPrcMask3  = 0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_rvlPerMask   = 0x0000000000000000000000000000000000007fffffff00000000000000000000;
    uint256 constant k_rvlPerMask2  = 0xffffffffffffffffffffffffffffffffffff80000000ffffffffffffffffffff;


    // 0000000000000000000000000000000000000000000000000000000000000000         32 bytes (minPrc:8, final:01, regDate: 4-01, gwp 20) = 32 bytes  entry_A
    // 0000000000000000000000003f6d05530286f455e77b1ea1b120670bc7038669 gwp     20 bytes
    // 00000000000000007fffffff0000000000000000000000000000000000000000 regDate 4 bytes until Jan 2038 0x7fffffff
    // 0000000000000000800000000000000000000000000000000000000000000000 final   1 bit 0x8 
    // ffffffffffffffff000000000000000000000000000000000000000000000000 minPrc  8 bytes * 1000 = 18,444.00 ETH 0xffffffffffffffff
    
    // 0000000000000000000000000000000000000000000000000000000000000000         32 bytes (deed:20, hiBid: 10, notUsed: 2)  entry_B
    // 0000000000000000000000005351248ba7800602be2ccaefba6a8c626e52f803 deed    20 bytes 
    // 0000ffffffffffffffffffff0000000000000000000000000000000000000000 hiBid   10 bytes
    // ffff000000000000000000000000000000000000000000000000000000000000 ???      2 bytes not used
    
    // 0000000000000000000000000000000000000000000000000000000000000000         32 bytes (val:10, rvlPer: 4-01bit, notUsed: 18)  entry_C
    // 00000000000000000000000000000000000000000000ffffffffffffffffffff val     10 bytes  0xffffffffffffffffffff  1208925 ETH
    // 0000000000000000000000000000000000007fffffff00000000000000000000 rvlPer   4 bytes - 1bit
    // 000000000000000000000000000000000000                             ????    18 bytes not used
    
    
    // State transitions for names:
    //   Open -> Auction (startAuction)
    //   Auction -> Reveal
    //   Reveal -> Owned
    //   Reveal -> Open (if nobody bid)
    //   Owned -> Open (releaseDeed or invalidateName)
    //   Over  -> Over (auction finalized and done)
    function state_pln(bytes32 _hash) public view returns (Mode) {              // 0x00006154      
        if (__finalize(_hash)) return Mode.Over;
        uint l_regDate = __regDate(_hash);
        
        if(block.timestamp < l_regDate) {
            if (block.timestamp < (l_regDate - __revealPeriod(_hash))) {
                return Mode.Auction;
            } else {
                return Mode.Reveal;
            }
        } else {
            if(__highestBid(_hash) == 0) {
                return Mode.Open;
            } else {
                return Mode.Owned;
            }
        }
    }
    
    function entries(bytes32 _hash) public view returns (Mode, address, uint, uint, uint, uint, uint, uint) {
      uint l_reveal = __revealPeriod(_hash);
      
      Mode l_state  = state_pln(_hash);
      address l_add = address(__deed(_hash));
      
      uint[5] memory l_a;
      l_a[0]   = __minPrice(_hash);
      l_a[1]   = __finalize(_hash) ? 1 : 0;
      l_a[2]   = __highestBid(_hash);
      l_a[3]   = __deedValue(_hash);
      l_a[4]   = __regDate(_hash);
      
      return (l_state, l_add, l_a[4], l_a[3], l_a[2], uint(l_a[1]), l_a[0], l_reveal);
    }
    
    
    // bitMap methods to access bidValue and sealedBid economically
    
    //function __rawBiddingValue(address bidder,bytes32 hash) public view returns (uint256) {
    //  return biddingValue[bidder][hash];
    //}
    
    function __biddVal(address bidder,bytes32 hash) private view returns (uint) {
      return uint(biddingValue[bidder][hash] & k_maskBidVal);
    }
    
    function __sealedBid(address bidder,bytes32 hash) private view returns (address) {
      return address(uint160(uint256(uint256(uint256(biddingValue[bidder][hash])>>80) & k_addressMask)));
    }

    function saveSealedBid(address bidder,bytes32 seal,address bid) private {
      biddingValue[bidder][seal] = uint256(uint256(uint256(uint160(bid))<<80) & k_maskSealBid) + uint256(biddingValue[bidder][seal] & k_maskBidVal);
    }
    
    function saveBiddVal(address bidder,bytes32 hash,uint val) private {
      biddingValue[bidder][hash] = uint256(biddingValue[bidder][hash] & k_maskSealBid) + uint256(val & k_maskBidVal);
    }
    
    function getBiddingValue(address bidder,bytes32 hash) public view returns (uint256) {
      return uint256(__biddVal(bidder,hash));
    }
    
    function sealedBidContract(address bidder,bytes32 hash) public view returns (address) {
      return __sealedBid(bidder,hash);
    }
    
    //function getSealedBidAddress(address _sender, bytes32 _seal) public view returns (address) {
    //  return __sealedBid(_sender,_seal);
    //}
    
    
    // deed,highestBid ----entry_B----------------------------------------------
    
    function __deed(bytes32 hash) private view returns (address) {
      return address(uint160(uint256(entry_B[hash] & k_addressMask)));
    }
    
    function saveDeed(bytes32 hash,address deed) private {
      entry_B[hash] = uint256(entry_B[hash] & k_highBidMask) + uint256(uint256(uint160(deed)) & k_addressMask);
    }

    function __highestBid(bytes32 hash) private view returns (uint) {
      return uint(uint256(uint256(entry_B[hash] & k_highBidMask)>>160) & k_maskBidVal);
    }
    
    function saveHighestBid(bytes32 hash,uint highBid) private {
      entry_B[hash] = uint256(entry_B[hash] & k_addressMask) + uint256(uint256(uint256(highBid & k_maskBidVal)<<160) & k_highBidMask);
    }
    
    function saveDeedAndHighBid(bytes32 hash,address deed,uint highBid) private {
      entry_B[hash] = uint256(uint256(uint160(deed)) & k_addressMask) + uint256(uint256(uint256(highBid & k_maskBidVal)<<160) & k_highBidMask);
    }


    // gwp,regDate,final,minPrc ----entry_A-------------------------------------

    function __gwpc(bytes32 hash) private view returns (address) {
      return address(uint160(uint256(entry_A[hash] & k_addressMask)));
    }
    
    //function saveGWPC(bytes32 hash,address gw) private {
    //  entry_A[hash] = uint256(entry_A[hash] & k_highBidMask) + uint256(uint256(uint160(gw)) & k_addressMask);
    //}

    function __regDate(bytes32 hash) private view returns (uint) {
      return uint(uint256(uint256(entry_A[hash] & k_regDataMask)>>160) & k_regDataMask2);
    }

    //function saveRegDate(bytes32 hash,uint regDate) private {
    //  entry_A[hash] = uint256(entry_A[hash] & k_regDataMask3) + uint256(uint256(uint256(regDate & k_regDataMask2)<<160) & k_regDataMask);
    //}
  
    function __finalize(bytes32 hash) private view returns (bool) {
      return bool(uint256(uint256(entry_A[hash] & k_finalizeMask))>0);
    }
    
    function saveFinalize(bytes32 hash,bool finalize) private {
      if ( finalize) entry_A[hash] = uint256(entry_A[hash] & k_finFlagMask) + uint256(k_finalizeMask);
      if (!finalize) entry_A[hash] = uint256(entry_A[hash] & k_finFlagMask);
    }

    function __minPrice(bytes32 hash) private view returns (uint) {
      return uint(uint256(uint256(entry_A[hash] & k_minPrcMask)>>176) & k_minPrcMask2);
    }

    //function saveMinPrice(bytes32 hash,uint minPrc) private {
    //  entry_A[hash] = uint256(entry_A[hash] & k_minPrcMask3) + uint256(uint256(uint256(minPrc & k_minPrcMask2)<<176) & k_minPrcMask);
    //}
    
    function saveGWRegDFinaMinPrc(bytes32 hash,address gw,uint regDate,bool finalize,uint minPrc) private {
      uint256 l_finalize = 0;
      if (finalize) l_finalize = uint256(k_finalizeMask);
      entry_A[hash] = uint256(uint256(uint160(gw)) & k_addressMask) + uint256(uint256(uint256(regDate & k_regDataMask2)<<160) & k_regDataMask) + l_finalize + uint256(uint256(uint256(minPrc & k_minPrcMask2)<<176) & k_minPrcMask);
    }

    // -val,rvlPer----entry_C---------------------------------------------------

    function __deedValue(bytes32 hash) private view returns (uint) {
      return uint(uint256(uint256(entry_C[hash] & k_maskBidVal)));
    }
    
    function saveDeedValue(bytes32 hash,uint val) private {
      entry_C[hash] = uint256(entry_C[hash] & k_maskSealBid) + uint256(val & k_maskBidVal);
    }

    function __revealPeriod(bytes32 hash) private view returns (uint) {
      return uint(uint256(uint256(uint256(entry_C[hash] & k_rvlPerMask)>>80) & k_regDataMask2));
    }

    function saveRevealPeriod(bytes32 hash,uint rvlPer) private {
      entry_C[hash] = uint256(entry_C[hash] & k_rvlPerMask2) + uint256(uint256(uint256(rvlPer & k_regDataMask2)<<80) & k_rvlPerMask);
    }
    
    function saveRevealPerValue(bytes32 hash,uint rvlPer,uint val) private {
      entry_C[hash] = uint256(uint256(uint256(rvlPer & k_regDataMask2)<<80) & k_rvlPerMask) + uint256(val & k_maskBidVal);
    }
  
    // -------------------------------------------------------------------------

    /**
     * @dev Constructs a new Registrar, with the provided address as the owner of the root node.
     */
    constructor(uint _startDate) payable {
        RegOwner = msg.sender;
        registryStarted = _startDate > 0 ? _startDate : block.timestamp;
    }

    /**
     * @dev Returns lmax the maximum of two unsigned integers
     * @param a A number to compare
     * @param b A number to compare
     * @return lmax The maximum of two unsigned integers
     */
    function max(uint a, uint b) internal pure returns (uint lmax) {
        if (a > b)
            return a;
        else
            return b;
    }

    /**
     * @dev Returns the minimum of two unsigned integers
     * @param a A number to compare
     * @param b A number to compare
     * @return lmin The minimum of two unsigned integers
     */
    function min(uint a, uint b) internal pure returns (uint lmin) {
        if (a < b)
            return a;
        else
            return b;
    }

    /**
     * @dev Returns the length of a given string
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        // Starting here means the LSB will be the byte we care about
        uint ptr;
        uint end;
        uint len;
        assembly {
            ptr := add(s, 1)
            end := add(mload(s), ptr)
        }
        for (len = 0; ptr < end; len++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
        return len;
    }
    
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        
        if (len==0) return;

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length,"substring!!!");

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            dest := add(ret, 32)
            src  := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }

    function mb32(bytes memory _data) private pure returns(bytes32 a) {
      // solium-disable-next-line security/no-inline-assembly
      assembly {
          a := mload(add(_data, 32))
      }
    }

    function toLowerCaseBytes32(bytes32 _in) internal pure returns (bytes32) {
      return bytes32(uint256(uint256(_in) | 0x2000000000000000000000000000000000000000000000000000000000000000 ));
    }
    
    function bytes32ToStr(bytes32 _b) internal pure returns (string memory) {
      bytes memory bArr = new bytes(32);
      uint256 i;
      
      uint off = 0;
      do { 
        if (_b[i] != 0) bArr[i] = _b[i];
        else off = i;
        i++;
      } while(i<32&&off==0);
      
      
      bytes memory rArr = new bytes(off);
      
      i=0;
      do
       { 
        if (bArr[i] != 0) rArr[i] = bArr[i];
        off--;
        i++;
      } while(i<32&&off>0);
      
      return string(rArr); 
    }
    
    function getChainId() public view returns (uint) {
      return block.chainid;
    }
    
    function tldOfChain() internal view returns (string memory) {
      uint chainId = block.chainid;
      if (chainId==1284)     return ".glmr";
      if (chainId==61)       return ".etc";
      if (chainId==137)      return ".matic";
      if (chainId==11155111) return ".sepeth";
      return ".eth";
    }
    
    function getPercentageOfCost() internal view returns (uint) {
      uint chainId = block.chainid;
      if (chainId==1284)     return 10;                                         // moonbeam auctions allow 10% of minimumBid == transaction fees
      if (chainId==61)       return 10;                                         // classic
      if (chainId==137)      return 80;                                         // make polygon auctions cheaper for testing
      if (chainId==11155111) return 25;                                         // sepolia: It is hard to get SepETH!
      if (chainId==5)        return 25;                                         // goerli
      return 5;                                                                 // ethereum mainnet, ganache: Transaction cost not more than 5% of minBid
    }
    
    /** 
     * @dev Returns available date for hash
     * 
     */
    function getAllowedTime() public view returns (uint timestamp) {
      return registryStarted;
    }
    
    function getAuctionMinBiddingPrice(bytes32 _hash) public view returns (uint) {
      return __minPrice(_hash);
    }
  
    function getGasPrice() private view returns (uint256) {
        uint256 gasPrice;
        assembly { gasPrice := gasprice() }
        return gasPrice;
    }
    
    function calculateMinAuctionPrice() private view returns (uint64) {      
      return uint64(getGasPrice() * uint(2433123) * (100 / getPercentageOfCost()));
    }
      
    /**
     * @dev Start an auction for an available hash
     *
     * @param _hash   The hash to start an auction on
     * @param revealP The reveal period in seconds, length of auction = 2*revealP
     */
    function startAuction_ge0(bytes32 _hash, uint revealP) public payable {     // 0x00004632
        require(state_pln(_hash)==Mode.Open,"startAuction auction not open");
        uint32 l_revealP = uint32(revealP) > 0 ? uint32(revealP) : 1 minutes;

        saveRevealPerValue(_hash,l_revealP,0);
        saveHighestBid(_hash,0);
        saveGWRegDFinaMinPrc(_hash,msg.sender,uint64(block.timestamp)+uint64(l_revealP<<1),false,calculateMinAuctionPrice());

        emit AuctionStarted(_hash, __regDate(_hash));
    }

    /**
     * @dev Hash the values required for a secret bid
     * @param hash The node corresponding to the desired namehash
     * @param value The bid amount
     * @param salt A random value to ensure secrecy of the bid
     * @return sealedBid The hash of the bid values
     */
     function shaBid(bytes32 hash, address owner, uint value, bytes32 salt) public pure returns (bytes32 sealedBid) {
        return keccak256(abi.encode(hash, owner, value, salt));
    }

    function saveExtDeedCntr_gm9(address _sender,bytes32 _hash,uint _value) public payable { // 0x000083bf 
      bytes32 lseal = keccak256(abi.encode(_hash,_sender,_value,kkk));
      require(__sealedBid(_sender,lseal)==address(0x0)&&_value>=__minPrice(_hash),"saveExDeed");
      
      saveSealedBid(_sender,lseal,address(msg.sender));                         // lseal
      saveBiddVal  (_sender,_hash,_value);                                      // _hash
    }
  
    /**
     * @dev Submit a new sealed bid on a desired hash in a blind auction 
     *
     * Bids are sent by sending a message to the main contract with a hash and an amount. The hash
     * contains information about the bid, including the bidded hash, the bid amount, and a random
     * salt. Bids are not tied to any one auction until they are revealed. This is
     * followed by a reveal period. Bids revealed after this period will be paid back and cancelled.
     *
     * @param seal A sealedBid, created by the shaBid function
     */
    function newBid_C45(bytes32 seal,bytes32 hash) public payable {             // 0x0000946a
      require(seal!=0x0&&__sealedBid(msg.sender,seal)==address(0x0)&&msg.value>=__minPrice(hash),"newBid");
      saveSealedBid(msg.sender,seal,address((new Deed){value: msg.value}(msg.sender,hash))); // creates a new deed contract with owner
      saveBiddVal(msg.sender,hash,msg.value);
    }
    
    function newBidProxy_DKJ(bytes32 seal,bytes32 hash,address masterContract) public payable { // 0x0000f5c2
      require(seal!=0x0&&__sealedBid(msg.sender,seal)==address(0x0)&&msg.value>=__minPrice(hash),"newBidProxy");
      saveSealedBid(msg.sender,seal,address((new IntDeedProxy){value: msg.value}(masterContract,msg.sender,hash))); // creates a new deed contract with owner    
      saveBiddVal(msg.sender,hash,msg.value);
    }

    function createBidBucket(bytes32 _hash) public payable returns(address) {
      require(state_pln(_hash)==Mode.Auction&&!__finalize(_hash), "AuctionNOTopen.");
      return address((new extDeed){value: 0}(address(this),_hash));             // creates a temporary deed contract, open for one external investor
    }
    
    function createBidBucketProxy(bytes32 _hash,address masterContract) public payable returns(address) {
      require(state_pln(_hash)==Mode.Auction&&!__finalize(_hash), "AuctionNOTopenProxy");
      return address((new ExtDeedProxy){value: 0}(masterContract,_hash));       // creates a temporary deed contract, open for one external investor
    }

    function deployExtDeedMaster() public payable {
      address lDeedMst = address((new extDeedMaster){value: 0}(address(this)));
      emit ExternalDeedMaster(lDeedMst);
    }
     
    function deployIntDeedMaster() public payable {
      address lDeedMst = address((new intDeedMaster){value: 0}(address(this)));
      emit InternalDeedMaster(lDeedMst);
    }

    /**
     * @dev Submit the properties of a bid to reveal them
     * @param _hash The node in the sealedBid
     * @param _value The bid amount in the sealedBid
     * @param _salt The sale in the sealedBid
     */
    function unsealBid_le$(bytes32 _hash, uint _value, bytes32 _salt) public payable {  // 0x0000bf3a
        bytes32 seal = keccak256(abi.encode(_hash,msg.sender,_value,_salt));    // shaBid(_hash, msg.sender, _value, _salt);
        intDeedMaster bid = intDeedMaster(payable(__sealedBid(msg.sender,seal)));
        
        require(address(bid)!=address(0x0),"bid==0x0");
        saveSealedBid(msg.sender,seal,address(0x0));
        
        uint value = min(_value, address(bid).balance);
        bid.adjustBal_1k3(value);

        Mode auctionState = state_pln(_hash);
        if(auctionState == Mode.Owned) {
            bid.closeDeed_igk(address(0x0));                                    // Too late! Get's 100% back.
            //emit BidRevealed(_hash, msg.sender, value, 1);
        } else if(auctionState != Mode.Reveal) {
            revert("unsealBid auctionState != Mode.Reveal error");              // Invalid phase
        } else if (value < __minPrice(_hash) || bid.creationDate() > __regDate(_hash) - __revealPeriod(_hash)) {
            bid.closeDeed_igk(address(0x0));                                    // Bid too low or too late, refund 100%
            //emit BidRevealed(_hash, msg.sender, value, 0);
        } else if (value > __highestBid(_hash)) {
            if(__deed(_hash) != address(0x0)) {                                 // new winner: cancel the other bid, refund 100%
              Deed previousWinner = Deed(__deed(_hash));
              saveBiddVal(previousWinner.owner(),_hash,0);
              previousWinner.closeDeed_igk(address(0x0));
            }
            // set new winner: per the rules of a vickrey auction, the value becomes the previous highest Bid
            saveDeedValue(_hash,__highestBid(_hash));                           // will be zero if there's only 1 bidder
            saveDeedAndHighBid(_hash,address(bid),value);
            //emit BidRevealed(_hash, msg.sender, value, 2);
        } else if (value > __deedValue(_hash)) {
            saveDeedValue(_hash,value);                                         // not winner, but affects second place
            bid.closeDeed_igk(address(0x0));
            //emit BidRevealed(_hash, msg.sender, value, 3);
        } else {
            bid.closeDeed_igk(address(0x0));                                    // bid doesn't affect auction
            //emit BidRevealed(_hash, msg.sender, value, 4);
        }
    }

    function unsealExternalBid_qfG(bytes32 _hash) public payable {              // 0x0000824d
      require(_hash!=0x0&&address(ABS_ExtDeed(payable(msg.sender)).registrar())==address(this)&&ABS_ExtDeed(payable(msg.sender)).owner()==tx.origin,"extDeed");
      
      address l_sender = tx.origin;
      uint    l_value  = address(msg.sender).balance;
      
      bytes32 seal     = keccak256(abi.encode(_hash,l_sender,l_value,kkk));     // shaBid(_hash,l_sender,l_value,kkk);
      require(__sealedBid(l_sender,seal)==msg.sender,"extSealedBid");
      
      extDeed bid = extDeed(payable(__sealedBid(l_sender,seal)));
      require(address(bid)!=address(0x0),"bid==0x0");
      
      saveSealedBid(l_sender,seal,address(0x0));
      
      if (l_value < __minPrice(_hash) || bid.creationDate() > __regDate(_hash) - __revealPeriod(_hash)) {
          bid.closeDeed_igk(address(0x0));                                      // Bid too low or too late, refund 100%
          //emit BidRevealed(_hash, l_sender, l_value, 0);
      } else if (l_value > __highestBid(_hash)) {
          
          if( __deed(_hash) != address(0x0)) {                                  // new winner: cancel the other bid, refund 100%
            extDeed previousWinner = extDeed(payable(__deed(_hash)));
            saveBiddVal(previousWinner.owner(),_hash,0);
            previousWinner.closeDeed_igk(address(0x0));
          }
          // set new winner: per the rules of a vickery auction, the value becomes the previous highest Bid
          saveDeedValue(_hash,__highestBid(_hash));                             // will be zero if there's only 1 bidder
          saveDeedAndHighBid(_hash,address(bid),l_value);
          //emit BidRevealed(_hash, l_sender, l_value, 2);
      } else if (l_value > __deedValue(_hash)) {
          saveDeedValue(_hash,l_value);                                         // not winner, but affects second place
          bid.closeDeed_igk(address(0x0));
          //emit BidRevealed(_hash, l_sender, l_value, 3);
      } else {
          bid.closeDeed_igk(address(0x0));                                      // bid doesn't affect auction
          //emit BidRevealed(_hash, l_sender, l_value, 4);
      }
    }


    function getNameFromGW(AbstractGroupWalletProxy gw) internal view returns (string memory) {
      return bytes32ToStr(toLowerCaseBytes32(mb32(bytes( getDomainNameString(gw) ))));
    }

    function splitTLDFromDomain(string memory domain) internal view returns (bytes memory) {
      return bytes(substring(bytes(domain), 0, strlen(domain) - strlen(tldOfChain())));
    }
    
    function getRevs(AbstractGroupWalletProxy gw) internal view returns (AbstractReverseRegistrar) {
      address GWF = gw.getGWF();
      require(address(GWF)!=address(0x0),"* reverseContract");
      return AbstractGroupWalletFactory(GWF).reverseContract();
    }
    
    function getDomainNameString(AbstractGroupWalletProxy gw) internal view returns (string memory) {
      AbstractReverseRegistrar reverseR = getRevs(gw);
      require(address(reverseR)!=address(0x0),"* getDomainNameString");
      return reverseR.defaultResolver().name( reverseR.node(address(gw)) );
    }

    function dHashFromName(AbstractGroupWalletProxy gw, string memory dname) internal view returns (bytes32) {
      AbstractGroupWalletFactory GWF = AbstractGroupWalletFactory(gw.getGWF() );
      return keccak256(abi.encodePacked(AbstractGroupWalletFactory(GWF).base().baseNode(), keccak256( bytes(substring(bytes(dname), 0, strlen(dname)-strlen(tldOfChain()))) ))); // splitTLDFromDomain(dname)  
    }

    function getPToken(AbstractGroupWalletProxy gw, string memory dname) internal view returns (AbstractTokenProxy) {
      AbstractGroupWalletFactory GWF = AbstractGroupWalletFactory(gw.getGWF() );
      return AbstractTokenProxy( GWF.getProxyToken(  dHashFromName(gw,dname) ) );
    }
    
    function isContract(address addr) internal view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
    
    function transferGroupShares(AbstractGroupWalletProxy gwc, address receiver) internal returns (uint) {
      AbstractTokenProxy ptoken = getPToken(gwc,getNameFromGW(gwc));            // token contract of group shares
      
      require(address(ptoken)!=address(0x0),"* ptoken contract");
      require(address(receiver)!=address(0x0),"* receiver");
      
      uint bal = ptoken.balanceOf(address(this));
      if (bal > 0) ptoken.transfer_G8l(receiver,bal);                           // send back shares to GroupWallet
      
      return (bal > 0) ? bal : 1;
    }
    
    function transferGroupSharesPrices(AbstractGroupWalletProxy gwc, address receiver, uint payment, address deedContract) internal returns (uint32) {
      string memory dname = getNameFromGW(gwc);
      
      AbstractTokenProxy ptoken = getPToken(gwc,dname);                         // token contract of group shares
      require(address(ptoken)!=address(0x0),"* ptoken contract");
      require(address(receiver)!=address(0x0),"* receiver");
      require(address(deedContract)!=address(0x0),"* deedContract");
      require(payment>0,"* payment");
      
      bytes32 dHash = dHashFromName(gwc,dname);
      uint32  bal   = uint32(ptoken.balanceOf(address(this)));
      if (bal > 0) ptoken.transferAdjustPrices(receiver,bal,payment,dHash,deedContract);
      
      return (bal > 0) ? bal : 1;
    }
    
    /**
     * @dev Finalize an auction after the registration date has passed
     * @param _hash The hash of the name of the auction
     */
    function finalizeAuction_H3D(bytes32 _hash) public payable {                // 0x0000283b
      intDeedMaster l_deed = intDeedMaster(payable(__deed(_hash)));
      require(((state_pln(_hash)==Mode.Owned) || (state_pln(_hash)==Mode.Over)) && (msg.sender==l_deed.owner()),"onlyOwnerFinalize");
      
      uint l_deedVal = __deedValue(_hash);
      
      saveDeedValue(_hash,max(l_deedVal, __minPrice(_hash)));                   // handles the case when there's only a single bidder value is zero)
      l_deed.adjustBal_1k3(l_deedVal);

      uint32 bal = 1;
      address gwp = __gwpc(_hash);
      
      if (gwp!=address(0x0)&&isContract(gwp)) {
        bal = transferGroupSharesPrices(AbstractGroupWalletProxy(gwp),l_deed.owner(),l_deedVal,address(l_deed));// transfer all token to highest bidder 
        l_deed.closeDeed_igk(gwp);
      }
      else
      {
        l_deed.closeDeed_igk(address(this));
      }
      
      saveFinalize(_hash,true);                                                 // finalized flag
      bal = 0;
      
      saveBiddVal(msg.sender,_hash,0);
      
      //emit AuctionFinalized(_hash, l_deed.owner(), l_deedVal, __regDate(_hash));
    }

    function finalizeExternalAuction_WmS(bytes32 _hash) public payable {        // 0x00009204
      extDeed l_deed  = extDeed(payable(__deed(_hash)));
      require(!__finalize(_hash)&&block.timestamp>=__regDate(_hash)&&__highestBid(_hash)>0&&address(ABS_ExtDeed(payable(msg.sender)).registrar())==address(this)&&tx.origin==l_deed.owner()&&ABS_ExtDeed(payable(msg.sender)).owner()==tx.origin,"finalizeExt");
      
      uint l_deedVal = __deedValue(_hash);

      saveDeedValue(_hash,max(l_deedVal, __minPrice(_hash)));                   // handles the case when there's only a single bidder value is zero)
      
      l_deed.adjustBal_1k3(l_deedVal);

      uint32 bal = 1;
      address gwp = __gwpc(_hash);
      
      if (gwp!=address(0x0)&&isContract(gwp)) {
        bal = transferGroupSharesPrices(AbstractGroupWalletProxy(gwp),l_deed.owner(),l_deedVal,address(l_deed));// transfer all token to highest bidder 
        l_deed.closeDeed_igk(gwp);
      }
      else
      {
        l_deed.closeDeed_igk(address(this));
      }
      
      saveFinalize(_hash,true);                                                 // finalized flag
      bal = 0;
      
      saveBiddVal(msg.sender,_hash,0);
      
      //emit AuctionFinalized(_hash, l_deed.owner(), l_deedVal, __regDate(_hash));
    }
    
    /**
     * @dev Cancel a bid
     * @param seal The value returned by the shaBid function
     */
    function cancelBid_k4U(bytes32 seal, bytes32 hash) public payable {         // 0x000046cb
      intDeedMaster bid = intDeedMaster(payable(__sealedBid(msg.sender,seal)));
      
      if (address(bid) != address(0x0)) {
        if (block.timestamp < bid.creationDate() + (__revealPeriod(hash)*2)) revert("cancelBid auctionLength error"); 
        bid.closeDeed_igk(address(0x0));                                        // send back cancelled bid
        saveSealedBid(msg.sender,seal,address(0x0));
      }
      
      saveBiddVal(msg.sender,hash,0);
      address gwp = __gwpc(hash);
      
      if (gwp!=address(0x0)&&isContract(gwp)) {
        transferGroupShares(AbstractGroupWalletProxy(gwp),gwp);
      }
    }
    
    function cancelExternalBid_9ig(bytes32 seal, bytes32 hash) public payable { // 0x00006a26
      require(__finalize(hash)&&(address(ABS_ExtDeed(payable(msg.sender)).registrar())==address(this)),"cancelExt");
      
      address l_sender = tx.origin;
      extDeed bid = extDeed(payable(__sealedBid(l_sender,seal)));
    
      if (address(bid) != address(0x0)) {
        if (block.timestamp < bid.creationDate() + (__revealPeriod(hash)*2)) revert("cancelExBid auctLength"); 
        bid.closeDeed_igk(address(0x0));                                        // Send back the canceller bid.
        saveSealedBid(l_sender,seal,address(0x0));
      }
      
      saveBiddVal(l_sender,hash,0);
      address gwp = __gwpc(hash);
      
      if (gwp!=address(0x0)&&isContract(gwp)) {
        transferGroupShares(AbstractGroupWalletProxy(gwp),gwp);
      }
    }

    /**
     * @dev After some time, or if we're no longer the registrar, the owner can release
     *      the name and get their ether back.
     * @param _hash The node to release
     */
    function releaseDeed(bytes32 _hash) public payable {
      intDeedMaster deed = intDeedMaster(payable(__deed(_hash)));
      require(state_pln(_hash)==Mode.Over&&msg.sender==deed.owner()&&block.timestamp>=__regDate(_hash),"releaseDeed err");

      saveDeedValue(_hash,0);
      saveDeedAndHighBid(_hash,address(0x0),0);
      deed.closeDeed_igk(address(0x0));        
    }
    
    function releaseExternalDeed(bytes32 _hash) public payable {
      extDeed deed = extDeed(payable(__deed(_hash)));
      require(state_pln(_hash)==Mode.Over&&msg.sender==deed.owner()&&block.timestamp>=__regDate(_hash),"extReleaseDeed err");

      saveDeedValue(_hash,0);
      saveDeedAndHighBid(_hash,address(0x0),0);
      deed.closeDeed_igk(address(0x0));        
    }

    function version() public pure returns(uint256 v) {
      return 20010053;
    }
    
    function withdraw() public {
      require(RegOwner==msg.sender,"Only Registrar owner");
      require(payable(address(uint160(msg.sender))).send(address(this).balance),"Withdraw funds from Registrar failed.");
    }
    
    fallback() external {
      require(false,"Registrar fallback!");
    }
    
    receive() external payable { emit Deposit(msg.sender, msg.value); }
}