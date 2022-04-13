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
 
  

function semaphore_cipher() view public returns (string memory) {
  
  string [26] memory semaphore=["QmStHMPpKeXZWn6ouve4e9j9YAK187WxQWuYPNSjkdyBQh",
    "QmQbkLaggmMJS7XMUtAWMPDuR96hWquUDixeCfUF8zohUH",
    "QmcDf789MEnfd5ndYXDjyVvTbh2mELgf8ZfzpKACt1kRQ4", // c
    "QmP5niwPW7TBVB7XExnMnvdrsgjgPGsLeDL2FifzbLYGaj", //d 
    "QmWNbm68bWyT3KbEbLBeFB8K645UpTH7ykiCZWzv6PU5T3", //e
    "QmVhddtfRsXnJyiuQbXgZcKoGyDVCqnNvcyVEBKZqqLMrR", //f
    "QmTbJYQt2v4fyu68tYh1bZptmcTMXKycqcW5atbefzSaRh", //g
    "QmTVtY8ueK3eAc1VFNFNRz5xhqxTkc5AAn11DHJyt6a1fU", //h
    "QmeTR8smB6JPU6qFcnSdpa2w4AY6ybd1okxeXdr3Bvm5Af",  // i
    "QmPo1ToKsqDf3sYsrkquN9cNqUXH2HKvChzwxV7Nq1yUSK", // j
    "QmWc2XFGG5ckn9emyJq4Csau8KXc257UkLkhXvJ58MSux1", // k
    "QmSxpKWjpBy22Lc9Tdk8X3kms5y3Mjn2sBwQ8xaMdvTXEW", // l
    "QmVcqDEqRp5Z3v3UAW7rq3mpg4CVZ5Hdv4PNscUy1ebVJj", // m
    "QmboxrxXSAftQdYoTvUxm2Lv1RWooSS4VCN1R9vc6raUGp", // n
    "QmVjLKtRPM4dgudn6KhU1fpAMy1SqXGSZvFQaFx1gADeGY", // o
    "Qme7BzQeBxCP4aA3Y6czEWFRxFHJgSnHZ38NRGPMQDSTun", // p
    "QmeaTg6A6CGA4g81JMXDubcTE3nXDWXJeLSXyBfGarsnxb", // q
    "Qmdb9CsfVVvMU2GH1u1afKhcq89FgadD2AWeSYY5thLXWC", // r
    "Qmbs4WSFv9fCNdaDePSYfmsREeQm2GR9HPtc8a7AHzGPm7", // s
    "QmUfbNp7tJu6UmMGhfaF1g75tvh7o3619Kg6c6FwXaUXpu", // t
    "QmNTNC6pqKnimhWKmbhpDmwtB1EoT1An1rQfVJeAXRvUhN", // u
    "QmP2pZEUm1jPhcxLua7n6aJPXtL2k6P1XQYKNCxnhvNced", // v
    "QmWBiBZ1K9D4qjfFfChPCtABCgaHunmovFFA58AKKcpg8L", // w
    "Qmats9t6Xp1HV8PtMemtLKsLjHTF6tJ4D5Y1BPuCVvtFV3", // x
    "QmYWEz6cuiXk4Z6GuD6dda1DbBUfaxCstuwEVcZEHDWjs8", // y
    "QmNdFMc1omMWPToFaFzR4Qe1YUa1NqT5j5Pxy6BuEg3aJC" // z
    ];

    string memory rtn=getChallenge("Semaphore",semaphore);
    return(rtn);
 
  }


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

    string memory rtn=getChallenge("Pigpen",ipfs);
    return(rtn);
 
  }

  function getChallenge(string memory name, string [26] memory ipfs) view internal returns (string memory) {

        bytes memory word=bytes(words[random(words.length,0)]);

    string memory rtn = string(abi.encodePacked("Find the cipher for the ",name," code of: "));

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