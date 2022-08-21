// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

contract Nodes is ERC20, Ownable{
  
  struct Node {
    uint createDate;
    uint lastClaimTime;
    string name;
  }

  bool public isMintable = false;
  bool public isClaimable = false;
  uint public rewardPerSecond = 11574074074074;
  uint public nodePrice = 10000000000000000000;
  uint public totalNodes = 0;

  ERC20 USDC;
  address public wallet;
  mapping(address => Node[]) public nodes;
  
  constructor(string memory name, string memory symbol) ERC20(name, symbol){
    _mint(msg.sender, 1000 * 10**uint(decimals()));
    USDC = ERC20(address(this));
    wallet = msg.sender;
  }

  function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

  function setWallet(address _wallet) external onlyOwner{
    wallet = _wallet;
  }

  function setMintable(bool value) external onlyOwner{
    isMintable = value;
  }

  function setClaimable(bool value) external onlyOwner{
    isClaimable = value;
  }

  function setMinter(address token) external onlyOwner{
    USDC = ERC20(token);
  }

  function setNodePrice(uint price) external onlyOwner{
    nodePrice = price;
  }

  function setRewards(uint rewards) external onlyOwner{
      rewardPerSecond = rewards;
  }

  function createNode(string memory _name, address user) internal{
    require(isMintable == true, "not mintable");
    Node memory newNode;
    newNode.createDate = block.timestamp;
    newNode.lastClaimTime = block.timestamp;
    newNode.name = _name;
    nodes[user].push(newNode);
    totalNodes++;
  }

  function mint(string memory _name) external{
    USDC.transferFrom(msg.sender, wallet, nodePrice);
    createNode(_name, msg.sender);
  }

  function mintAdmin(address user, string memory _name) external onlyOwner{
    createNode(_name, user);
  }

  function mintMultiple(string[] memory names, uint amount) external{
    require(amount >= 1, "Dont try to fuck me");
    USDC.transferFrom(msg.sender, wallet, nodePrice * amount);
    for (uint i = 0; i < amount; i++){
      createNode(names[i], msg.sender);
    }
  }

  function mintMultipleAdmin(string[] memory names, uint amount, address user) external onlyOwner{
    require(amount >= 1, "Dont try to fuck me");
    for (uint i = 0; i < amount; i++){
      createNode(names[i], user);
    }
  }

  function getTotalPendingRewards(address user) public view returns(uint){
    Node[] memory userNodes = nodes[user];
    uint totalRewards = 0;
    for (uint i = 0; i < userNodes.length; i++){
      totalRewards += ((block.timestamp - userNodes[i].lastClaimTime) * rewardPerSecond);
    }
    return totalRewards;
  }

  function getNumberOfNode(address user) public view returns(uint){
    return nodes[user].length;
  }

  function getNodeCreation(address user, uint id) public view returns(uint)
  {
    return (nodes[user][id].createDate);
  }

  function getNodeLastClaim(address user, uint id) public view returns(uint){
    return (nodes[user][id].createDate);
  }

  function getPendingRewards(address user, uint id) public view returns(uint){
    Node memory node = nodes[user][id];
    return ((block.timestamp - node.lastClaimTime) * rewardPerSecond);
  }

  function claim(uint id) external{
    require(isClaimable == true, "not claimable");
    Node storage node = nodes[msg.sender][id];
    uint timeElapsed = block.timestamp - node.lastClaimTime;
    node.lastClaimTime = block.timestamp;
    _mint(msg.sender, timeElapsed * rewardPerSecond); 
  }

   function getPendingRewardsEach(address user) public view returns(string memory){
       string memory result;
       string memory separator = "#";
       Node[] memory userNodes = nodes[user];
       for (uint i = 0; i < userNodes.length; i++)
       {
           uint pending = (block.timestamp - userNodes[i].lastClaimTime) * rewardPerSecond;
           result = string(abi.encodePacked(result, separator, uint2str(pending)));
       }
       return result;
   }

   function getCreationEach(address user) public view returns(string memory){
       string memory result;
       string memory separator = "#";
       Node[] memory userNodes = nodes[user];
       for (uint i = 0; i < userNodes.length; i++)
       {
           uint creation = userNodes[i].createDate;
           result = string(abi.encodePacked(result, separator, uint2str(creation)));
       }
       return result;
   }

   function getNameEach(address user) public view returns(string memory){
       string memory result;
       string memory separator = "#";
       Node[] memory userNodes = nodes[user];
       for (uint i = 0; i < userNodes.length; i++)
       {
           string memory name = userNodes[i].name;
           result = string(abi.encodePacked(result, separator, name));
       }
       return result;
   }
}