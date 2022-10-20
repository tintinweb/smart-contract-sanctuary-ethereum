pragma solidity >=0.5.0 <0.6.0;

import "./ZombieAttack.sol";
import "./ERC721.sol";

//Contract inheritys from both ZombieAttack and ERC721
contract ZombieOwnership is ZombieAttack, ERC721 {

  //Used to track who has been approved to transfer a given zombie (must be called by owner of zombie to be transferred)
  mapping (uint => address) zombieApprovals;

  //Returns the number of zombies owned by the give address
  function balanceOf(address _owner) external view returns (uint256) {
    return ownerZombieCount[_owner];
  }

  //Returns the owner of a given zombie
  function ownerOf(uint256 _tokenId) external view returns (address) {
    return zombieToOwner[_tokenId];
  }

  //Private function used by transferFrom to perform transfer of zombie from one account to another (here _tokenId = zombieId)
  function _transfer(address _from, address _to, uint256 _tokenId) private {

    //Replacing the standard ++ and -- with SafeMath library methods to protect from overflows and underflows
    //ownerZombieCount[_to]++;
    //ownerZombieCount[_from]--;
    ownerZombieCount[_to] = ownerZombieCount[_to].add(1);
    ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].sub(1);

    zombieToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  //External payable function that allows for the transferring of a zombie from one account to another (must be called by token owner or address approved by owner to perform the transfer)
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    require (zombieToOwner[_tokenId] == msg.sender || zombieApprovals[_tokenId] == msg.sender);
    _transfer(_from, _to, _tokenId);
  }

  //Function that can only be called by the owner of a zombie to provide approval for another address to call the transferFrom function to transfer ownership of a given zombie
  function approve(address _approved, uint256 _tokenId) external payable onlyOwnerOf(_tokenId) {
    zombieApprovals[_tokenId] = _approved;
    emit Approval(msg.sender, _approved, _tokenId);
  }
}