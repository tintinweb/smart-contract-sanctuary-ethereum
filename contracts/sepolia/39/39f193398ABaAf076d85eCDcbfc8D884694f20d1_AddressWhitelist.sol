pragma solidity ^0.8.9;


interface IMemberList {
    event MemberAdded(address indexed account);
    event MemberRemoved(address indexed account);

    function addMember(address account) external;

    function removeMember(address account) external;

    function member(address account) external view returns (bool);
}

interface IAddressWhitelist {
  event AddressWhitelisted(address indexed user, address indexed broker);
  event AddressBlacklisted(address indexed user, address indexed broker);

  function whitelist(address user) external view returns (address);

  function blacklist(address user) external view returns (address);
  
  function whitelistDel(address user) external;

  function whitelistAdd(address user) external;

  function addressWhitelisted(address account) external view returns (bool);
}

contract AddressWhitelist is IAddressWhitelist {
  IMemberList public immutable memberList;
  
  mapping(address => address) public whitelist;
  mapping(address => address) public blacklist;

  constructor(IMemberList _memberList) {
    memberList = _memberList;
  }

  modifier onlyValidMember {
    require(memberList.member(msg.sender), "AddressWhiteList: Only valid member can add/remove whitelist");
    _;
  }

  function whitelistAdd(address user) external onlyValidMember {
    require(whitelist[user] == address(0), "AddressWhiteList: Address is already whitelisted");
    whitelist[user] = msg.sender;
    if (blacklist[user] != address(0)) {
      delete blacklist[user];
    }
    emit AddressWhitelisted(user, msg.sender);
  }

  function whitelistDel(address user) external onlyValidMember {
    address member = whitelist[user];
    require(member!= address(0), "AddressWhiteList: Address is not whitelisted");
    require(member == msg.sender, "AddressWhiteList: Caller does not have permission");
    delete whitelist[user];
    blacklist[user] = msg.sender;
    emit AddressBlacklisted(user, msg.sender);
  }

  function addressWhitelisted(address account) external view virtual override returns (bool) {
    return whitelist[account] != address(0);
  }
}