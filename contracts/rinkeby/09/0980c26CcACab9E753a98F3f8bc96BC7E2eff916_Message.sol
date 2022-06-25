pragma solidity 0.8.7;
contract Message{
    event Post(address sender, string id);
    function post(string memory _data) public{
        //Create ipns website
        //Incrypt this link with your public key
        //emit this link as part of events log
        //Even though there will be a ton of events emitted,
        //we can use the graph to filter by user public address.
        emit Post(msg.sender, _data);
    }
  
}