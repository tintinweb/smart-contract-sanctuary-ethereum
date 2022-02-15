/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity 0.8.4;

contract FunnyChallenges {
    bytes32 constant magic_hash =0x841261bf11a58fbabcbcb7d4efd531da55121171dea830574030238956ac2eed;
    bool private first_challenge_solved;
    constructor() payable {
      
             
    }
    function func(address _contract,uint256 _param, bytes4 _sel) payable external {
        require(msg.value>=1 ether);
         bytes memory data = abi.encodeWithSelector(_sel, msg.sender, _param);
         (bool success,) = _contract.call{value:msg.value}(data);
         require(success,'call failed');

    }
    function DontGiveUp(string calldata ch1,string calldata ch2) external  {
      
      require(keccak256(abi.encodePacked(ch2))!=keccak256(abi.encodePacked("CTF")), "NO Try again");
      bytes memory ch2_bytes = bytes(ch2);
      require(uint8(ch2_bytes[0])!=84 && uint8(ch2_bytes[0])!=70 && uint8(ch2_bytes[0])!=67,"Nice Try but NOOOO!");
      
      require(ch2_bytes.length<=3,"You think of brute force? not a good idea");
      bytes32 hash1= keccak256(abi.encodePacked("Sherlock","CTF "));
      bytes32 hash2=  keccak256(abi.encodePacked(ch1,ch2));
      if (hash1==hash2){
        
          first_challenge_solved=true;


      }
        
    }

    function transfer(address to, uint magic_number) public  payable {
        require(first_challenge_solved, "you should first solve DontGiveUp");
        require(msg.value==2 ether);
        
        bytes32 hash_magic_number=keccak256(abi.encode(magic_number));
       
        require(msg.sender==address(this) || hash_magic_number== magic_hash,"Please don't brute force :)");
        (bool success,)=to.call{value :address(this).balance }("");
        require(success, 'transfer failed');    
    }    
}