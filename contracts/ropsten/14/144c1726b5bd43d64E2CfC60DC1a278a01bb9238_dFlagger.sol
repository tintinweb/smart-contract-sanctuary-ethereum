/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity >=0.4.22 <0.9.0;

contract dFlagger {

    mapping(uint256 => bytes32) Hash_list;
    mapping(uint256 => string) Identity_list;
    mapping(uint256 => string) Flag_list;

    event TokensSent(string Flag_state);

    function Register(string memory identity) payable public{
        require(msg.value == 13370000000000, "Wrong amount paid");
        Hash_list[uint256(uint160(msg.sender))] = blockhash(block.number - 1);
        Identity_list[uint256(uint160(msg.sender))] = identity;
    } 

    function ObtainFlag(bytes32 payload, uint256 balance) public{
        bytes32 block_hash = Hash_list[uint256(uint160(msg.sender))];
        require(payload == block_hash ^ bytes32(uint256(uint160(msg.sender))), "Wrong payload");
        require(address(this).balance == balance, "Wrong balance");
        Flag_list[uint256(uint160(msg.sender))] = "flag is obtained";
    } 

    function Verify(address user_addr, string memory identity) payable public{
        require(keccak256(bytes(Identity_list[uint256(uint160(user_addr))])) == keccak256(bytes(identity)), "Wrong identity");
        string memory Flag_state = Flag_list[uint256(uint160(user_addr))];
        require(keccak256(bytes(Flag_state)) == keccak256(bytes("flag is obtained")), "No flag");
        emit TokensSent(Flag_state);
    }


}