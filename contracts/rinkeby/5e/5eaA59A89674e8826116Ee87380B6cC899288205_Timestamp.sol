/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

/* 
This is the smart contract for provide a Timestamp function.
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Timestamp{

  address payable internal owner;

  struct DataTS {
    address who;
    string name;
    string dataType;
    string data;
    uint256 timestamp;
    uint256 blockTimestamp;
  }
  
  DataTS[] records;
  mapping(string => uint) private indexNames;

  event entryCreated(address indexed who);
 
 
  constructor () public
  {
    owner = payable(msg.sender);
  }


  // This modifier is used to check if the sender of the function call is the owner.
  modifier onlyOwner()
  {
    require(msg.sender==owner);
    _;
  }


  function destroySmartContract() public onlyOwner {
    selfdestruct(owner);
  }


  function post(string memory _name, string memory _dataType, string memory _data, uint256 _timestamp) public returns (bool)
  {  
    DataTS memory entry = DataTS({
      who : msg.sender,
      name: _name,
      dataType: _dataType,
      data: _data,
      timestamp: _timestamp,
      blockTimestamp: block.timestamp
    });

    records.push(entry);
    indexNames[_name] = records.length -1;

    emit entryCreated(msg.sender);
    return true;
  }


  function get(string memory _name) public view
    returns (address _who, string memory _nameRes, string memory _dataType, string memory _data, uint256 _timestamp, uint256 _blocTimestamp) {

    if (records.length > 0) {
      uint index =  indexNames[_name];
      return (
        records[index].who,
        records[index].name,
        records[index].dataType,
        records[index].data,
        records[index].timestamp,
        records[index].blockTimestamp
      );
    }
  }


  function getVersion() public pure returns (string memory _version) {
    return "1.0";
  }

}