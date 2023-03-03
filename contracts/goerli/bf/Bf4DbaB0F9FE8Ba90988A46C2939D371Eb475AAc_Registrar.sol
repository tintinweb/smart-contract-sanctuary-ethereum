/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16 <0.8.18;

/*

Auction Hash Registrar ( changed by pepihasenfuss, based on ENS 1.0 Temporary Hash Registrar, a Vickery Auction introduced by Nick Johnson and ENS team )
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

/**
 * @title Deed to hold ether in exchange for ownership of a node
 * @dev The deed can be controlled only by the registrar and can only send ether back to the owner.
 */
contract Deed {
  address public registrar;
  uint    public creationDate;
  address public owner;

  event DeedClosed();

  constructor(address _owner) payable {
    owner        = _owner;
    registrar    = msg.sender;
    creationDate = block.timestamp;
  }
  
  function getValue() public payable returns (uint) {
    return address(this).balance;
  }

  function setBalance(uint newValue) public payable {
    if ((msg.sender != registrar) || (address(this).balance==0) || (getValue() < newValue) || !payable(address(uint160(owner))).send(address(this).balance - newValue)) revert("setBalance err");
  }

  /**
   * @dev Close a deed and refund a specified fraction of the bid value
   * @param receiver    GroupWallet contract to send funds to
   */
  function closeDeed(address receiver) public payable {
    address sendTo = (receiver!=address(0x0)) ? receiver : owner;
    if (msg.sender!=registrar || !payable(address(sendTo)).send(getValue())) revert("closeDeed");
    emit DeedClosed();
  }
}

/**
 * @title Registrar
 * @dev The registrar handles the auction process.
 */
contract Registrar {
    mapping (bytes32 => entry) _entries;
    mapping (address => mapping(bytes32 => Deed)) public sealedBids;
    mapping (address => mapping(bytes32 => uint256)) private biddingValue;

    enum Mode { Open, Auction, Owned, Forbidden, Reveal, empty, Over }

    uint public registryStarted;
    address public RegOwner;

    event AuctionStarted(bytes32 indexed hash, uint registrationDate);
    event NewBid(bytes32 indexed hash, address indexed bidder, uint deposit);
    event BidRevealed(bytes32 indexed hash, address indexed owner, uint value, uint8 status);
    event HashReleased(bytes32 indexed hash, uint value);
    event AuctionFinalized(bytes32 indexed hash, address indexed owner, uint value, uint registrationDate);
    event TestReturn(uint256 v1, uint256 v2, uint256 v3, uint256 v4);
    event Deposit(address from, uint256 value);

    struct entry {
        Deed deed;
        uint registrationDate;
        uint value;
        uint highestBid;
        AbstractGroupWalletProxy groupwallet;
        uint finalized;
        uint32 _revealPeriod;
        uint auctMinPrice;
    }

    // State transitions for names:
    //   Open -> Auction (startAuction)
    //   Auction -> Reveal
    //   Reveal -> Owned
    //   Reveal -> Open (if nobody bid)
    //   Owned -> Open (releaseDeed or invalidateName)
    //   Over  -> Over (auction finalized and done)
    function state(bytes32 _hash) public view returns (Mode) {
        entry storage s_entry = _entries[_hash];
      
        if (s_entry.finalized>0) return Mode.Over;
      
        if(block.timestamp < s_entry.registrationDate) {
            if (block.timestamp < (s_entry.registrationDate - s_entry._revealPeriod)) {
                return Mode.Auction;
            } else {
                return Mode.Reveal;
            }
        } else {
            if(s_entry.highestBid == 0) {
                return Mode.Open;
            } else {
                return Mode.Owned;
            }
        }
    }

    modifier onlyOwnerFinalize(bytes32 _hash) {
        if (((state(_hash) != Mode.Owned)&&(state(_hash) != Mode.Over)) || msg.sender != _entries[_hash].deed.owner()) revert("onlyOwnerFinalize is allowed");
        _;
    }

    modifier onlyOwnerRelease(bytes32 _hash) {
        if ((state(_hash) != Mode.Over) || msg.sender != _entries[_hash].deed.owner()) revert("onlyOwnerRelease is allowed");
        _;
    }

    function entries(bytes32 _hash) public view returns (Mode, address, uint, uint, uint, uint, uint, uint) {
        entry storage h = _entries[_hash];
        return (state(_hash), address(h.deed), h.registrationDate, h.value, h.highestBid, h.finalized, h.auctMinPrice, h._revealPeriod);
    }
    
    function getBiddingValue(address bidder,bytes32 hash) public view returns (uint256) {
      return biddingValue[bidder][hash];
    }

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
      return 5;                                                                 // ethereum mainnet, ganache and goerli: Transaction cost not more than 5% of minBid
    }
    
    /** 
     * @dev Returns available date for hash
     * 
     */
    function getAllowedTime() public view returns (uint timestamp) {
      return registryStarted;
    }
  
    function getGasPrice() private view returns (uint256) {
        uint256 gasPrice;
        assembly { gasPrice := gasprice() }
        return gasPrice;
    }
    
    function calculateMinAuctionPrice() private view returns (uint) {      
      return uint(getGasPrice() * uint(2433123) * (100 / getPercentageOfCost()));
    }
      
    /**
     * @dev Start an auction for an available hash
     *
     * Anyone can start an auction by sending an array of hashes that they want to bid for.
     * Arrays are sent so that someone can open up an auction for X dummy hashes when they
     * are only really interested in bidding for one. This will increase the cost for an
     * attacker to simply bid blindly on all new auctions. Dummy auctions that are
     * open but not bid on are closed after a week.
     *
     * @param _hash The hash to start an auction on
     */
    function startAuction(bytes32 _hash, uint revealP) public payable {
        Mode mode  = state(_hash);
        if(mode == Mode.Auction) return;
        if(mode != Mode.Open) revert("startAuction auction not open error");

        entry storage newAuction = _entries[_hash];
        newAuction.value = 0;
        newAuction.highestBid = 0;

        newAuction._revealPeriod  = uint32(revealP) > 0 ? uint32(revealP) : 1 minutes;

        newAuction.registrationDate = block.timestamp + (newAuction._revealPeriod<<1);
        
        newAuction.auctMinPrice = calculateMinAuctionPrice();                   // transaction cost appr. 5% of min biddingPrice 
        
        newAuction.groupwallet = AbstractGroupWalletProxy(msg.sender);
        newAuction.finalized = 0;
        
        emit AuctionStarted(_hash, newAuction.registrationDate);
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

    /**
     * @dev Submit a new sealed bid on a desired hash in a blind auction
     *
     * Bids are sent by sending a message to the main contract with a hash and an amount. The hash
     * contains information about the bid, including the bidded hash, the bid amount, and a random
     * salt. Bids are not tied to any one auction until they are revealed. The value of the bid
     * itself can be masqueraded by sending more than the value of your actual bid. This is
     * followed by a 48h reveal period. Bids revealed after this period will be burned and the ether unrecoverable.
     * Since this is an auction, it is expected that most public hashes, like known domains and common dictionary
     * words, will have multiple bidders pushing the price up.
     *
     * @param sealedBid A sealedBid, created by the shaBid function
     */
    function newBid(bytes32 sealedBid,bytes32 hash) public payable {
        if (address(sealedBids[msg.sender][sealedBid]) > address(0x0)) revert("newBid sealedBid error");
        
        if (msg.value < _entries[hash].auctMinPrice) revert("newBid underflow error");
        
        Deed l_newBid = (new Deed){value: msg.value}(msg.sender);               // creates a new hash contract with the owner
        sealedBids[msg.sender][sealedBid] = l_newBid;
        biddingValue[msg.sender][hash] = msg.value;
        emit NewBid(sealedBid, msg.sender, msg.value);
    }

    /**
     * @dev Submit the properties of a bid to reveal them
     * @param _hash The node in the sealedBid
     * @param _value The bid amount in the sealedBid
     * @param _salt The sale in the sealedBid
     */
    function unsealBid(bytes32 _hash, uint _value, bytes32 _salt) public {
        bytes32 seal = shaBid(_hash, msg.sender, _value, _salt);
        Deed bid = sealedBids[msg.sender][seal];
        if (address(bid) == address(0x0) ) revert("unsealBid address bid == 0x0 error");
        sealedBids[msg.sender][seal] = Deed(address(0x0));
        entry storage h = _entries[_hash];
        uint value = min(_value, bid.getValue());
        bid.setBalance(value);

        Mode auctionState = state(_hash);
        if(auctionState == Mode.Owned) {
            // Too late! Get's 99.5% back.
            bid.closeDeed(address(0x0));
            emit BidRevealed(_hash, msg.sender, value, 1);
        } else if(auctionState != Mode.Reveal) {
            // Invalid phase
            revert("unsealBid auctionState != Mode.Reveal error");
        } else if (value < h.auctMinPrice || bid.creationDate() > h.registrationDate - h._revealPeriod) {
            // Bid too low or too late, refund 99.5%
            bid.closeDeed(address(0x0));
            emit BidRevealed(_hash, msg.sender, value, 0);
        } else if (value > h.highestBid) {
            // new winner
            // cancel the other bid, refund 99.5%
            if(address(h.deed) != address(0x0)) {
              Deed previousWinner = h.deed;
              biddingValue[previousWinner.owner()][_hash] = 0;
              previousWinner.closeDeed(address(0x0));
            }

            // set new winner
            // per the rules of a vickery auction, the value becomes the previous highestBid
            h.value = h.highestBid;  // will be zero if there's only 1 bidder
            h.highestBid = value;
            h.deed = bid;
            emit BidRevealed(_hash, msg.sender, value, 2);
        } else if (value > h.value) {
            // not winner, but affects second place
            h.value = value;
            bid.closeDeed(address(0x0));
            emit BidRevealed(_hash, msg.sender, value, 3);
        } else {
            // bid doesn't affect auction
            bid.closeDeed(address(0x0));
            emit BidRevealed(_hash, msg.sender, value, 4);
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
      return keccak256(abi.encodePacked(AbstractGroupWalletFactory(GWF).base().baseNode(), keccak256(bytes(splitTLDFromDomain(dname)))));
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
    
    function transferGroupSharesPrices(AbstractGroupWalletProxy gwc, address receiver, uint payment, address deedContract) internal returns (uint) {
      string memory dname = getNameFromGW(gwc);
      
      AbstractTokenProxy ptoken = getPToken(gwc,dname);                         // token contract of group shares
      require(address(ptoken)!=address(0x0),"* ptoken contract");
      require(address(receiver)!=address(0x0),"* receiver");
      require(address(deedContract)!=address(0x0),"* deedContract");
      require(payment>0,"* payment");
      
      bytes32 dHash = dHashFromName(gwc,dname);
      uint bal = ptoken.balanceOf(address(this));
      if (bal > 0) ptoken.transferAdjustPrices(receiver,bal,payment,dHash,deedContract);
      
      return (bal > 0) ? bal : 1;
    }
    
    /**
     * @dev Finalize an auction after the registration date has passed
     * @param _hash The hash of the name of the auction
     */
    function finalizeAuction(bytes32 _hash) public onlyOwnerFinalize(_hash) {
        entry storage h = _entries[_hash];
        
        h.value =  max(h.value, h.auctMinPrice);                                // handles the case when there's only a single bidder (h.value is zero)
        h.deed.setBalance(h.value);

        uint bal = 1;
        
        if (isContract(address(h.groupwallet)) && address(h.groupwallet)!=address(0x0)) {
          bal = transferGroupSharesPrices(h.groupwallet,h.deed.owner(),h.value,address(h.deed));// transfer all token to highest bidder 
          h.deed.closeDeed(address(h.groupwallet));
        }
        
        h.finalized = bal;                                                      // finalized = nb of token sent to new owner and winner of the auction
        biddingValue[msg.sender][_hash] = 0;
        
        emit AuctionFinalized(_hash, h.deed.owner(), h.value, h.registrationDate);
    }

    /**
     * @dev Cancel a bid
     * @param seal The value returned by the shaBid function
     */
    function cancelBid(bytes32 seal, bytes32 hash) public {
        Deed bid = sealedBids[msg.sender][seal];
        entry storage h = _entries[hash];     
      
        if (address(bid) != address(0x0)) {
          if (block.timestamp < bid.creationDate() + (h._revealPeriod*2)) revert("cancelBid auctionLength error"); 
          bid.closeDeed(address(0x0));                                          // Send back the canceller bid.
          sealedBids[msg.sender][seal] = Deed(address(0x0));
        }
        
        biddingValue[msg.sender][hash] = 0;
        emit BidRevealed(seal, msg.sender, 0, 5);
        
        if (isContract(address(h.groupwallet)) && address(h.groupwallet)!=address(0x0)) {
          transferGroupShares(h.groupwallet, address(h.groupwallet));
        }
    }
    
    /**
     * @dev After some time, or if we're no longer the registrar, the owner can release
     *      the name and get their ether back.
     * @param _hash The node to release
     */
    function releaseDeed(bytes32 _hash) public onlyOwnerRelease(_hash) {
        entry storage h = _entries[_hash];
        Deed deedContract = h.deed;
        if (block.timestamp < h.registrationDate) revert("releaseDeed error");

        h.value = 0;
        h.highestBid = 0;
        h.deed = Deed(address(0x0));

        deedContract.closeDeed(address(0x0));
        emit HashReleased(_hash, h.value);        
    }

    function version() public pure returns(uint256 v) {
      return 20010045;
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