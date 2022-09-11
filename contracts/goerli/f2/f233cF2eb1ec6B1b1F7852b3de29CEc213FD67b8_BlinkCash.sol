//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract BlinkCash{

    mapping(bytes32 => uint256) balances;

    function deposit(string memory password) public payable returns(bytes32){
        bytes32 id = getId(password);
        balances[id] += msg.value;
        return id;
    }
    function withdraw(bytes32 givenId, string memory password,uint256 amount) public{
        bytes32 id = getId(password);
        require(givenId==id,"Wrong ID or password.");
        require(amount<=balances[id],"Cannot withdraw.");
        (bool success,) = payable(msg.sender).call{value:amount}("");
        require(success,"Something went wrong.");
        balances[id] -= amount; 
    }
    function getBalance(bytes32 id) public view returns(uint256){
        return balances[id];
    }
    function getId(string memory password) private pure returns(bytes32){
        return keccak256(abi.encode(password));
    }

}