// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*

"I disapprove of what you say, but I will defend to the death your right to say it" - Evelyn Beatrice Hall.  

            .------.
           /  ~ ~   \,------.      ______
         ,'  ~ ~ ~  /  (@)   \   ,'      \
       ,'          /`.    ~ ~ \ /         \
     ,'           | ,'\  ~ ~ ~ X     \  \  \
   ,'  ,'          V--<       (       \  \  \
 ,'  ,'               (vv      \/\  \  \  |  |
(__,'  ,'   /         (vv   ""    \  \  | |  |
  (__,'    /   /       vv   """    \ |  / / /
      \__,'   /  |     vv          / / / / /
          \__/   / |  | \         / /,',','
             \__/\_^  |  \       /,'',','\
                    `-^.__>.____/  ' ,'   \
                            // //---'      |
          ===============(((((((=================
                                     | \ \  \
                                     / |  |  \
                                    / /  / \  \
                                    `.     |   \
                                      `--------'

*/

contract Prrot{

   event postEvent(address indexed senderAddress, uint256 indexed blockNumber, uint64 indexed postOrder, string originalPost, string content);

   mapping(string => string) public getPost;

   function char(bytes1 b) internal pure returns (bytes1 c) {
      // We forgot where we copied this from

      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
   }

   function toAsciiString(address x) internal pure returns (string memory) {
      // We forgot where we copied this from

      bytes memory s = new bytes(40);
      for (uint i = 0; i < 20; i++) {
         bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
         bytes1 hi = bytes1(uint8(b) / 16);
         bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
         s[2*i] = char(hi);
         s[2*i+1] = char(lo);            
      }
      return string(s);
   }

   function toString(uint256 value) internal pure returns (string memory) {
      // Copied from OpenZeppelin's Strings contract
      // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/98c3a79b5765d58ef27856b8211c70a4907c63be/contracts/utils/Strings.sol#L16-L36

      // Inspired by OraclizeAPI's implementation - MIT licence
      // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

      if (value == 0) {
         return "0";
      }
      uint256 temp = value;
      uint256 digits;
      while (temp != 0) {
         digits++;
         temp /= 10;
      }
      bytes memory buffer = new bytes(digits);
      while (value != 0) {
         digits -= 1;
         buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
         value /= 10;
      }
      return string(buffer);
    }

   function newPost(string memory originalPost, uint64 postOrder, string memory content) public returns (string memory) {
      require(bytes(content).length < 280);
      string memory packedPost = string(abi.encodePacked("1_", toAsciiString(msg.sender), "_", toString(block.number), "_", toString(postOrder)));
      require(bytes(getPost[packedPost]).length == 0);
      getPost[packedPost] = content;
      emit postEvent(msg.sender, block.number, postOrder, originalPost, content);
      return packedPost;
   }

   function newPostEvent(string memory originalPost, uint64 postOrder, string memory content) public {
      require(bytes(content).length < 280);
      emit postEvent(msg.sender, block.number, postOrder, originalPost, content);
   }

}