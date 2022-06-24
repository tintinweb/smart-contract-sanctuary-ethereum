/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity 0.8.15;  
    
contract news{  
        
    struct newsfeed{  
        address publisher;  
        string newsdesc;  
    }  
    mapping(uint => newsfeed) public newsfeeds;  
    uint public newsCount;  
    
    function addnews(string memory newsdesc) public {  
        newsCount++;  
        newsfeeds[newsCount].publisher = msg.sender;  
        newsfeeds[newsCount].newsdesc = newsdesc;  
    
    }  
}