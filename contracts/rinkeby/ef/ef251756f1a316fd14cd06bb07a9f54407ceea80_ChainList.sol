/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

pragma solidity ^0.4.23;
contract ChainList  {
    address creator;
    modifier onlyCreator() {
        require(msg.sender == creator); // If it is incorrect here, it reverts.
        _;                              // Otherwise, it continues.
    }
    constructor (){
        creator = msg.sender;
    }
    struct  data  {
      uint   profile;
      string ipfs;
      address  pc;
    }
    mapping (uint => data)  datamatching;
    function storedata (uint _profile, string memory _ipfs, address _pc) public onlyCreator {
        data memory persondata  = datamatching[_profile];
        persondata .profile = _profile;
        persondata. pc  =  _pc;
        persondata.ipfs = _ipfs;
    }
    function getData(uint profile) onlyCreator view returns (uint, string memory, address){
        return (datamatching[profile].profile, datamatching[profile].ipfs, datamatching[profile].pc);
      }
}