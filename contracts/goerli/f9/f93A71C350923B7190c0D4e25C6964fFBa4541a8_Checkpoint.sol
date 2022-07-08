pragma solidity >=0.4.21 <0.9.0;

contract Checkpoint {
  address public owner;
  mapping(address => bytes32) public currentMerkleRoot;

  event RootUpdated(
      address sender,
      bytes32 currentRoot,
      bytes32 prevRoot,
      uint timestamp
  );

  event HistoryRolledBack(
      address sender,
      bytes32 currentRoot,
      bytes32 prevRoot,
      uint timestamp
  );

  struct RootData {
      //timestamp of current root
      uint timestamp;
      bytes32 prevRoot;
  }

  //address => root => previous root
  mapping(address => mapping(bytes32 => RootData)) public history;

  constructor() public {
  }
  
  function getPreviousMerkleRoot(address account) public view returns(bytes32){
      return history[account][currentMerkleRoot[account]].prevRoot;
  }

  function getCurrentMerkleRoot(address account) public view returns(bytes32){
      return currentMerkleRoot[account];
  }

  function rollBackCurrentMerkleRoot(bytes32 root) public {
      //check to ensure the root is in the history for this address
      require(history[msg.sender][root].timestamp != 0, 'Provided root does not exist in the history');
      currentMerkleRoot[msg.sender] = root;
      //emit history rolled back event
      emit HistoryRolledBack(msg.sender, root, history[msg.sender][root].prevRoot, block.timestamp);
  }

  function updateCurrentMerkleRoot(bytes32 root) public {
      require(root != currentMerkleRoot[msg.sender], 'Root provided matches current merkle root');
      //get previous root and timestamp (maybe change timestamp to block.root)
      Checkpoint.RootData memory currentRootData = RootData({
          timestamp: block.timestamp,
          prevRoot: currentMerkleRoot[msg.sender]
      });
      //update current merkle root
      currentMerkleRoot[msg.sender] = root;
      history[msg.sender][root] = currentRootData;
      //emit root updated event
      emit RootUpdated(msg.sender, root, currentRootData.prevRoot, currentRootData.timestamp);
  }
}