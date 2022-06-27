/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract openThaiContract{

    // number of contract stored so far
    uint count;

    constructor() {
        count=0;
    }

    struct Contract{
        uint id;
        address owner;
        address signer;
        string created_at;
        string signed_at;
        string hashed;
        string detail;
        bool isSigned;
    }
    
    // Array to store contract
    Contract[] public contracts;

    // map user to contract's ID
    mapping(address => uint[]) public userToContractID;

    //  number of contract belong to this user
    function numberOfContract() public view returns(uint){
        return userToContractID[msg.sender].length;
    }

    // receive all contract belong to msg.sender
    function retrieveAll() public view returns (Contract[] memory){
        uint length = userToContractID[msg.sender].length;

        Contract[] memory userContract = new Contract[](length);
        for (uint i=0;i<length;i++){
             userContract[i] = contracts[userToContractID[msg.sender][i]];
        }
        return userContract;
    }

    function retrievePending() public view returns (Contract[] memory){
        uint length = userToContractID[msg.sender].length;
        uint j=0;
       for (uint i=0;i<length;i++){
            if (contracts[userToContractID[msg.sender][i]].isSigned==false){
             j++;
            }
        }
        
        if (j==0) {
            return new Contract[](0);
        }
        Contract[] memory userContract = new Contract[](j);
        j =0;
        for (uint i=0;i<length;i++){
            if (contracts[userToContractID[msg.sender][i]].isSigned==false){
          userContract[j] = contracts[userToContractID[msg.sender][i]];
             j++;
            }
        } 
        return userContract;
    }
    function retrieveSigned() public view returns (Contract[] memory){
        uint length = userToContractID[msg.sender].length;
        uint j=0;
       for (uint i=0;i<length;i++){
            if (contracts[userToContractID[msg.sender][i]].isSigned==true){
             j++;
            }
        }
        if (j==0) return new Contract[](0);
        Contract[] memory userContract = new Contract[](j);
        j =0;
        for (uint i=0;i<length;i++){
            if (contracts[userToContractID[msg.sender][i]].isSigned==true){
          userContract[j] = contracts[userToContractID[msg.sender][i]];
             j++;
            }
        } 
        return userContract;
    }

    // delete all contract belong to msg.sender

    function deleteAll() public{
        delete userToContractID[msg.sender];
    }

    // create contract
    function create(address _recipient, string memory _created_at, string memory _signed_at, string memory _hashed, string memory _detail) public{
        if (_recipient != 0x0000000000000000000000000000000000000000){       
            contracts.push(Contract(count,msg.sender,_recipient,_created_at,_signed_at,_hashed,_detail,false));
            userToContractID[msg.sender].push(count);
            userToContractID[_recipient].push(count);
            count++;
        }
        else
        {
            contracts.push(Contract(count,msg.sender,_recipient,_created_at,_signed_at,_hashed,_detail,true));
            userToContractID[msg.sender].push(count);
            count++;
        }
    }

    // sign contract
    function sign(uint _id, string memory _signed_at) public {
        require(contracts[_id].signer==msg.sender,"access denied");
        contracts[_id].signed_at = _signed_at;
        contracts[_id].isSigned = true;

    }
    //test function
    function wave() public pure returns (string memory){
        string memory message= "hi";
        return message;
    }
}