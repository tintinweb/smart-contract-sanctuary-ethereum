// SPDX-License-Identifier: Unlicense

/*

An accesslist/token controlled collection of passages and recordings
that attempt to detail one incarnation of the
decentralized Lootverse.

*/

pragma solidity^0.8.1;

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

contract DivineLibrary {

    address public owner;
    address public writePassContract;
    address[] private _publishers;

    event Record(string indexed title, string author, address indexed authorWallet, string content, string[] tags);
    event Revoke(string indexed title, address indexed authorWallet);

    error NoPublishAccess();

    constructor() {
        owner = msg.sender;
        addPublisher(msg.sender);
        writePassContract = address(0x0);
    }

    function record(string memory title, string memory author, address authorWallet, string memory content, string[] memory tags) 
      public 
      onlyValidPublishAccess()
      {
      // records a topic
      // if a topic is re-recorded it should be treated as an edit or update
      emit Record(title, author, authorWallet, content, tags);
    }

    function revoke(string memory title, address authorWallet) 
      public 
      onlyValidPublishAccess()
      {
      // revokes a topic, should be treated as a delete
      emit Revoke(title, authorWallet);
    }

    function addPublisher(address newPublisher) public {
      // adds a publisher to the list of publishers
      require(msg.sender == owner, "LootLibrarium: not owner");
      _publishers.push(newPublisher);
    }

    function getPublishers() public view returns (address[] memory publishers) {
      // returns the list of publishers
      return _publishers;
    }

    function removePublisher(uint i) public {
      // removes a publisher from the list of publishers
      require(msg.sender == owner, "LootLibrarium: not owner");
      delete _publishers[i];
    }

    function setWritePassContract(address newWritePassContract) public {
      // sets the address of the write pass contract
      require(msg.sender == owner, "LootLibrarium: not owner");
      writePassContract = newWritePassContract;
    }

    modifier onlyValidPublishAccess() {
      if (_hasWritePass() || _isPublisher()) {
        _;
      } else {
        revert NoPublishAccess();
      }
    }

    function _isPublisher() private view returns (bool) {
      // returns true if the given address is a publisher
      for (uint i = 0; i < _publishers.length; i++) {
        if (_publishers[i] == msg.sender) {
          return true;
        }
      }
      return false;
    }

    function _hasWritePass() private view returns (bool) {
      if (writePassContract != address(0x0)) {
        IERC721 writePass = IERC721(writePassContract);
        // checks if the sender owns a write pass contract NFT
        if(writePass.balanceOf(msg.sender) > 0) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
}