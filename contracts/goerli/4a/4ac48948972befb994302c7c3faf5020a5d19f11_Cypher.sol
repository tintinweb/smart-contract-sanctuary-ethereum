/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

//
// Don't hate me, Trinity. I'm just a messenger.
//

pragma solidity ^0.8.0;

contract Cypher {
  uint8   public constant decimals    = 18;
  uint    public constant MAX_INT     = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint    public totalSupply          = 0;
  uint    public totalStore           = 0;
  uint    public fee                  = 1e16;

  address public owner                = 0xf0b699A8559A3fFAf72f1525aBe14CebcD1De5Ed;

  string  public name                 = "Trust Cypher";
  string  public symbol               = "TC";

  struct Post { 
    uint ups;
    uint dwns;
    uint repto;
    address sndr;
    string str;
  }

  event   Send(address indexed src, string str);
  event   Upvote(address indexed src, address indexed sndr);
  event   Downvote(address indexed src, address indexed sndr);

  event   Approval(address indexed src, address indexed guy, uint wad);
  event   Transfer(address indexed src, address indexed dst, uint wad);

  event   Levelup(address indexed usr, uint level);
  event   AddMinter(address indexed src, address indexed usr);
  event   RemoveMinter(address indexed src, address indexed usr);

  mapping (uint => Post)                            public  cyphers;
  mapping (uint => uint[])                          public  threads;
  mapping (address => uint[])                       public  profiles;

  mapping (address => bool)                         public  minters;
  mapping (address => uint)                         public  ranks;

  mapping (address => uint)                         public  balanceOf;
  mapping (address => mapping (address => uint))    public  allowance;

  function levelup() public {
    uint cost = 1e18 * (ranks[msg.sender] + 1);

    require(balanceOf[msg.sender] >= cost);
    burnFrom(msg.sender, cost);
    ranks[msg.sender] += 1;

    emit Levelup(msg.sender, ranks[msg.sender]);
  }

  function payload(string memory str, uint repto) public payable {
    require(strlen(str) <= 280, "Too long");

    uint gas = tx.gasprice * 1e8;
    require(msg.value >= (fee / 1e18), "Too poor");

    balanceOf[msg.sender] += gas;
    balanceOf[owner] += gas;
    totalSupply += (2 * gas);

    if (repto > 0) {
      threads[repto].push(totalStore);
    }

    cyphers[totalStore] = Post(0,0,repto,msg.sender,str);
    profiles[msg.sender].push(totalStore);
    totalStore += 1;

    emit Send(msg.sender, str);
    emit Transfer(address(0), msg.sender, gas);
  }

  function trustload(string memory str, uint repto) public {
    require(strlen(str) <= 280, "Too long");
    require(ranks[msg.sender] >= 1, "Too low");

    uint tip = fee;
    require(balanceOf[msg.sender] >= tip, "Too poor");

    balanceOf[msg.sender] -= tip;
    balanceOf[owner] += tip;

    if (repto > 0) {
      threads[repto].push(totalStore);
    }

    cyphers[totalStore] = Post(0,0,repto,msg.sender,str);
    profiles[msg.sender].push(totalStore);
    totalStore += 1;

    emit Send(msg.sender, str);
    emit Transfer(msg.sender, owner, tip);
  }

  function upvote(uint idx) public {
    require(cyphers[idx].sndr != address(0), "Not exists");

    uint tip = fee / 1e2;
    cyphers[idx].ups += 1;

    balanceOf[msg.sender] -= tip;
    balanceOf[cyphers[idx].sndr] += tip;

    emit Upvote(msg.sender,cyphers[idx].sndr);
    emit Transfer(msg.sender, owner, tip);
  }

  function downvote(uint idx) public {
    require(cyphers[idx].sndr != address(0), "Not exists");

    uint tip = fee / 1e2;
    cyphers[idx].dwns += 1;

    balanceOf[msg.sender] -= tip;
    balanceOf[owner] += tip;

    emit Downvote(msg.sender,cyphers[idx].sndr);
    emit Transfer(msg.sender, owner, tip);
  }

  function unload() public {
    address payable _owner = payable(owner);
    (bool sent, bytes memory data) = _owner.call{value: address(this).balance}("");
  }

  function mint(address usr, uint wad) public {
    require(minters[msg.sender] == true);

    totalSupply += wad;
    balanceOf[usr] += wad;
    
    emit Transfer(address(0), usr, wad);
  }

  function burn(uint wad) public {
    burnFrom(msg.sender, wad);
  }

  function burnFrom(address src, uint wad) public {
    require(minters[msg.sender] == true);
    require(balanceOf[src] >= wad, "No balance");

    if (src != msg.sender && allowance[src][msg.sender] != MAX_INT) {
      require(allowance[src][msg.sender] >= wad, "No allowance");
      allowance[src][msg.sender] -= wad;
    }

    totalSupply -= wad;
    balanceOf[src] -= wad;
    
    emit Transfer(src, address(0), wad);
  }
  
  function approve(address guy, uint wad) public returns (bool) {
    allowance[msg.sender][guy] = wad;
    emit Approval(msg.sender, guy, wad);
    return true;
  }

  function transfer(address dst, uint wad) public returns (bool) {
    return transferFrom(msg.sender, dst, wad);
  }

  function transferFrom(address src, address dst, uint wad) public returns (bool)
  {
    require(balanceOf[src] >= wad);

    if (src != msg.sender && allowance[src][msg.sender] != MAX_INT) {
        require(allowance[src][msg.sender] >= wad);
        allowance[src][msg.sender] -= wad;
    }

    balanceOf[src] -= wad;
    balanceOf[dst] += wad;

    emit Transfer(src, dst, wad);
    return true;
  }

  function _lowerFee() public {
    require(owner == msg.sender, "Not owner");
    fee /= 10;
  }

  function _addMinter(address usr) public {
    require(owner == msg.sender, "Not owner");

    minters[usr] = true;

    emit AddMinter(msg.sender, usr);
  }

  function _removeMinter(address usr) public {
    require(owner == msg.sender, "Not owner");

    minters[usr] = false;

    emit RemoveMinter(msg.sender, usr);
  }

  function _removeOwner() public {
    require(owner == msg.sender, "Not owner");
    owner = address(0);
  }

  function init() public payable {
    require(msg.value > 0, "No value");
  }

  receive() external payable {
    init();
  }

  fallback() external payable {
    init();
  }

  function strlen(string memory s) internal pure returns (uint) {
    uint len;
    uint i = 0;
    uint bytelength = bytes(s).length;
    for(len = 0; i < bytelength; len++) {
      bytes1 b = bytes(s)[i];
      if(b < 0x80) {
        i += 1;
      } else if (b < 0xE0) {
        i += 2;
      } else if (b < 0xF0) {
        i += 3;
      } else if (b < 0xF8) {
        i += 4;
      } else if (b < 0xFC) {
        i += 5;
      } else {
        i += 6;
      }
    }
    return len;
  }
}

//
// SPDX-License-Identifier: NONE
// (C) 2022 Trendering.com
//