/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return payable (msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Encryptedata is Context, Ownable {
    struct User {
        string publicKey;
        bool approved;
        bool registered;
    }

    mapping(address=>User) public users;
    mapping (address=> string[]) public messageDetails;
    address[] userAddresses;

    function request(string memory _pubkey) public {
        require(!users[msg.sender].registered, "Already Registered");
        User memory u = User(_pubkey, false, true);
        users[msg.sender] = u;

        userAddresses.push(msg.sender);
    }
    
    function approve(address a, bool approval) public onlyOwner {
        users[a].approved = approval;
    }

    function  viewPublicKe(address reciever) view public returns(string memory ){
        return users[reciever].publicKey;
    }

    function storeData(string memory _message, address reciever) public {
        require(users[reciever].approved, "Receiver not approved.");
        messageDetails[reciever].push(_message);
    }

    function viewMessage(address reciever) view public returns(string[] memory){
        return messageDetails[reciever];
    }

    function viewMessageByIndex(uint _index,address reciever) view public returns (string memory) {
        return messageDetails[reciever][_index];
    }

    function viewUserAddresses() public view returns (address[] memory){
        return userAddresses;
    }
}