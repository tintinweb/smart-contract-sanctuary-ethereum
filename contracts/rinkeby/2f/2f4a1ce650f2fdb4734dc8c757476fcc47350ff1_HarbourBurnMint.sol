/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string memory _tokenURI
  ) external returns (bool);

  function burn(uint256 tokenId) external;
}

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

abstract contract AdminRole {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _admins.add(msg.sender);
    emit AdminAdded(msg.sender);
  }

  modifier onlyAdmin() {
    require(
      _admins.has(msg.sender),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function addAdmin(address account) public onlyAdmin {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function renounceAdmin() public onlyAdmin {
    _admins.remove(msg.sender);
    emit AdminRemoved(msg.sender);
  }
}

abstract contract CreatorWithdraw is AdminRole {
  address payable private _creator;

  constructor() {
    _creator = payable(msg.sender);
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {
    // thank you
  }

  function withdraw(address erc20, uint256 amount) public onlyAdmin {
    if (erc20 == address(0)) {
      _creator.transfer(amount);
    } else if (erc20 != address(this)) {
      IERC20(erc20).transfer(_creator, amount);
    }
  }

  function withdrawToken(address erc721, uint256 tokenId) public onlyAdmin {
    IERC721(erc721).transferFrom(address(this), _creator, tokenId);
  }
}

contract HarbourBurnMint is AdminRole, CreatorWithdraw, IERC721Receiver {
  struct DestToken {
    uint256 tokenId;
    address contractAddr;
    uint48 stringId;
  }
  mapping(address => mapping(uint256 => DestToken)) private _tokenMap;
  mapping(uint256 => string) private _stringMap;
  uint48 public redeemCount;

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  event SetRedeem(
    address indexed contractAddr,
    uint256 indexed tokenId,
    address destContract,
    uint256 destTokenId
  );
  event SetRedeemMultiple(
    address indexed contractAddr,
    uint256 indexed tokenId,
    address destContract,
    uint256 destTokenId,
    uint256 count
  );
  event Redeem(
    address indexed contractAddr,
    uint256 indexed tokenId,
    address indexed owner,
    address destContract,
    uint256 newTokenId,
    bytes data
  );

  function setRedeem(
    address contractAddr,
    uint256 tokenId,
    address destContract,
    uint256 destTokenId,
    string memory tokenURI
  ) external onlyAdmin {
    uint48 stringId = redeemCount++;
    _stringMap[stringId] = tokenURI;
    _tokenMap[contractAddr][tokenId] = DestToken(
      destTokenId,
      destContract,
      stringId
    );
    emit SetRedeem(contractAddr, tokenId, destContract, destTokenId);
  }

  function setRedeemMultiple(
    address contractAddr,
    uint256 startTokenId,
    address destContract,
    uint256 startDestTokenId,
    string memory tokenURI,
    uint256 count
  ) external onlyAdmin {
    uint48 stringId = redeemCount++;
    _stringMap[stringId] = tokenURI;

    for (uint256 i = 0; i < count; i++) {
      _tokenMap[contractAddr][startTokenId + i] = DestToken(
        startDestTokenId + i,
        destContract,
        stringId
      );
    }
    emit SetRedeemMultiple(
      contractAddr,
      startTokenId,
      destContract,
      startDestTokenId,
      count
    );
  }

  function getRedeem(address contractAddr, uint256 tokenId)
    external
    view
    returns (
      address destContract,
      uint256 destTokenId,
      string memory tokenURI
    )
  {
    DestToken storage dest = _tokenMap[contractAddr][tokenId];
    return (dest.contractAddr, dest.tokenId, _stringMap[dest.stringId]);
  }

  function redeem(
    address contractAddr,
    uint256 tokenId,
    bytes memory data
  ) external returns (address newContract, uint256 newTokenId) {
    require(IERC721(contractAddr).ownerOf(tokenId) == msg.sender, 'not_owner');
    return _redeem(contractAddr, msg.sender, tokenId, data);
  }

  function _redeem(
    address contractAddr,
    address sender,
    uint256 tokenId,
    bytes memory data
  ) internal returns (address newContract, uint256 newTokenId) {
    DestToken storage dest = _tokenMap[contractAddr][tokenId];
    require(dest.contractAddr != address(0), 'not_valid');
    IERC721(contractAddr).burn(tokenId);

    IERC721(dest.contractAddr).mintWithTokenURI(
      sender,
      dest.tokenId,
      _stringMap[dest.stringId]
    );
    emit Redeem(
      contractAddr,
      tokenId,
      sender,
      dest.contractAddr,
      dest.tokenId,
      data
    );
    return (dest.contractAddr, dest.tokenId);
  }

  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes memory data
  ) external virtual override returns (bytes4) {
    _redeem(msg.sender, from, tokenId, data);
    return this.onERC721Received.selector;
  }
}