//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract BlinkCash{

    mapping(bytes32 => uint256) balances;

    function deposit(string memory password) external payable {
        bytes32 id = getId(password);
        balances[id] += msg.value;
    }
    function withdraw(bytes32 givenId, string memory password,uint256 amount,address reciever) external{
        bytes32 id = getId(password);
        require(givenId==id,"Wrong ID or password.");
        require(amount<=balances[id],"Cannot withdraw.");
        balances[id] -= amount; 
        (bool success,) = payable(reciever).call{value:amount}("");
        require(success,"Something went wrong.");
    }
    function getBalance(bytes32 id) external view returns(uint256){
        return balances[id];
    }
    function getId(string memory password) public pure returns(bytes32){
        return keccak256(abi.encode(password));
    }
    function balance() external view returns(uint256){
        return address(this).balance;
    }
}