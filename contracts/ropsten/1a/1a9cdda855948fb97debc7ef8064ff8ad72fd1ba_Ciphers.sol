/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


contract Ciphers {

     string [59]  words =["accepting", "active",  "added",  "angle",
                        "area", "authors",
                            "besides","box","category","common",
                                "company","compare","complaints","complete","complicate",
                                "concern","concrete","consider","consistency",
                                "continuous","corners","course","crisis","cross","daily",
                                "danger","decide","default","department","depth","detail",
                                "dictionary","disadvantage","dislike","displays","documented",
                                "dream","drive","earth","education","emergency",
                                "enjoy","eraser","evidence","examine","exercise",
                        "exists","expand","expanded","expanding","expands","expansion",
                        "face", "facilities", "facility","fact","factor", "facts",
                        "igloo"];
 
  



  function pigpen_cipher() view public returns (string memory) {
  string [26] memory ipfs=["QmcizbQqy4A9HRUEA34aiBSzbpk6BHJFDjAJWMvrKQRUyA",
    "QmcVC9hK9CDKW9RC5aBNFjF521XyDCfiPR3zzzQ84NZGXy",
    "QmfP33Mde6wLXphucyV6Z3em8HjHhdftEBgJ4PDcfuNzgu",
    "QmPXZXszrGn2c1pcL2UNK3UfqW6DYaLHZsicYo5Gktkj4W",
    "QmWBcdmDzdQNkuNneaVgEWpCmHyacSDyUYGvWWKdWwmY5F",
    "QmVhddtfRsXnJyiuQbXgZcKoGyDVCqnNvcyVEBKZqqLMrR",
    "Qmdvvx2Ld8Hm4t2zKgwygJkSn95MhL1ydz2mJNcbUuJV3X", 
    "QmTKsT2MSFhYNMgF6dKALHHeXvgfM5opdqE1VeWcSDvbad",
    "QmR7StEGgVkURcbiwK2KBEq7kstwzawAQmp7tuAQ37dTBT", 
    "QmeUqUVkDqyHxGbugrc97w7JuyRvbh3C3CYwMPc31C6Sqa",
    "QmamDWzzAr3XvvvHk6DbRk7n7tUVsaXYorHnJJBiVMbtNS",
    "QmPVn2BEyKCBKc1SRK9KicFqyW9Sg7ohAypSBZEPJhMrqu", 
    "QmbqEVE1QWePs9U8wkDs8ciZuZYVjA6fZN64rJq3GFA7oj",
    "QmYZuznL9juXoFs7AiRysPqkaZxb6cskKrd7ze6zReg2tW", 
    "QmPAw8SpwvUQQxf3SfcKAmVvpko6bETBYeRJShCkYxMDef", 
    "QmfTyFLuwRxEYrj2zpu6sMsCCTJV6fh7QJphHCEHpCL5T5", 
    "QmQKp5QCw2TRr9dhyVFPKpGEErjSx7L6KTEhgHs7uYgWgN", 
    "QmapjseB9ZvajzZX39RHGJy3X1ny3t6wVCdruiNLtAcQLg", 
    "QmPyy7kn3TqT5EMJLKaumHxxpuQ7387Cyxvnc79pRcg44R", 
    "QmV1rgTWd8QBW8ZMZhUU26Jz3vfUnT6A2kBqwU2rnJWbUe", 
    "QmPnwDGtzWefzXwFcBV4TXWQ1cvbXsgMYAs1aRpotjy5WD", 
    "Qmf9BzmSqj7UJ9XBv9pKGEa8VHb3J4aJYHmCStopgKEBng", 
    "QmcSw7WNyvKTLuxLzFq4vCisw5u3eJN218K8ioHcGug6yR", 
    "QmYXaP2QMLpVsGpugKdTzYQ1V4JbnULnRDqmHAWMxdyJFy", 
    "Qmd5ZeGU5cJFUasQBWr7VvXbbPUWQcYnWUUQQVYkyk6XT6", 
    "QmWWd8DbkjJmkbD8b6xjr1X4Ped2ufokgatyp2vS92hSV8"

    ];

    bytes memory word=bytes(words[random(words.length,0)]);

    string memory rtn="Find the plaintext for the Pigpen code of: ";

    for (uint256 i=0;i<word.length;i++)
    { 
        uint256 pos=uint8(word[i])-uint8(97);

        rtn=string(abi.encodePacked(rtn,"<img src='https://ipfs.io/ipfs/",ipfs[pos],"' style='height: 50px;'> " ));
      } 
    rtn= string(abi.encodePacked(rtn, "\n\nThe answer is:\n",word));
    return string(rtn); 
 
  }
  


  function morse_code() view public returns (string memory) {

    string [26] memory morse= ["(.-)","(-...)","(-.-.)","(-..)","(.)","(..-.)","(- -.)","(....)",
    "(..)","(.- - -)","(-.-)","(.-..)","(- -)","(-.)","(- - -)","(.- -.)","(- -.-)",
    "(.-.)","(...)","(-)","(..-)","(...-)","(.- -)","(-..-)","(-.- -)","(- -..)"];


    bytes memory word=bytes(words[random(words.length,0)]);

    string memory rtn="Find the plaintext for the Morse code of: ";

    for (uint256 i=0;i<word.length;i++)
    { 
        uint256 pos=uint8(word[i])-uint8(97);
        rtn=string(abi.encodePacked(rtn, (morse[pos])));
      } 
    rtn= string(abi.encodePacked(rtn, "\n\nThe mapping is:\n"));
    rtn=string(abi.encodePacked(rtn, word));
    return string(rtn); 
 
  }
  

  function random(uint number,uint i) view internal returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender,uint(i)))) % number;
  } 

}