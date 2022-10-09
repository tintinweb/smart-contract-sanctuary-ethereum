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

  address public owner                = 0xf0b699A8559A3fFAf72f1525aBe14CebcD1De5Ed;

  string  public name                 = "Trust Cypher";
  string  public symbol               = "TC";

  struct Post { 
    uint ups;
    uint dwns;
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

  function payload(string memory str) public payable returns (bool) {
    require(strlen(str) <= 280, "Too long");
    require(msg.value >= 0.001 ether, "Too poor");

    uint gas = tx.gasprice * 1e8;

    balanceOf[msg.sender] += gas;
    balanceOf[owner] += gas;
    totalSupply += (2 * gas);

    cyphers[totalStore] = Post(0,0,msg.sender,str);
    totalStore += 1;

    emit Send(msg.sender, str);
    return true;
  }

  function trustload(string memory str) public returns (bool) {
    require(strlen(str) <= 280, "Too long");
    require(ranks[msg.sender] >= 1, "Too low");
    require(balanceOf[msg.sender] >= 1e16, "Too poor");

    balanceOf[msg.sender] -= 1e16;
    balanceOf[owner] += 1e16;

    cyphers[totalStore] = Post(0,0,msg.sender,str);
    totalStore += 1;

    emit Send(msg.sender, str);
    return true;
  }

  function upvote(uint idx) public returns (bool) {
    if (cyphers[idx].sndr == address(0)) return false;

    cyphers[idx].ups += 1;
    balanceOf[msg.sender] -= 1e14;
    balanceOf[cyphers[idx].sndr] += 1e14;

    emit Upvote(msg.sender,cyphers[idx].sndr);
    return true;
  }

  function downvote(uint idx) public returns (bool) {
    if (cyphers[idx].sndr == address(0)) return false;

    cyphers[idx].dwns += 1;
    balanceOf[msg.sender] -= 1e14;
    balanceOf[owner] += 1e14;

    emit Downvote(msg.sender,cyphers[idx].sndr);
    return true;
  }

  function unload() public {
    address payable _owner = payable(owner);
    (bool sent, bytes memory data) = _owner.call{value: address(this).balance}("");
  }

  function xunown() public {
    require(owner == msg.sender, "Not owner");
    owner = address(0);
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

  function addMinter(address usr) public {
      require(owner == msg.sender, "Not owner");

      minters[usr] = true;

      emit AddMinter(msg.sender, usr);
  }

  function removeMinter(address usr) public {
      require(owner == msg.sender, "Not owner");

      minters[usr] = false;

      emit RemoveMinter(msg.sender, usr);
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