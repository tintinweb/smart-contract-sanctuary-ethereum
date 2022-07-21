/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// File: SaveData.sol



pragma solidity ^0.8.0;

contract SaveData {

    struct Data{
        string from;
        string to;
        uint256 tokenId;
        uint now ;
    }

    event Savedata(
        string from, 
        string to, 
        uint timestamp,
        uint256 tokenId, 
        bytes32 datahash
        );

    mapping (uint256 => Data) private tokenhistory;
    mapping (string => uint256) private balance;
    mapping (uint256 => string) private owners;

    function savedata (  
        string memory from,
        string memory to,
        uint256 tokenId
    )public {

        if (balance[from] == 0){

            bytes32 datahash = keccak256(abi.encodePacked(
            from,
            to,
            block.timestamp,
            tokenId
            ));
        
            tokenhistory[tokenId] = Data(
                from,
                to,
                block.timestamp,
                tokenId
            );

            owners[tokenId] = string(to) ;
            balance[to] += 1;

            emit Savedata(from, to, block.timestamp, tokenId, datahash);

        }else{
            
            bytes32 datahash = keccak256(abi.encodePacked(
            from,
            to,
            block.timestamp,
            tokenId
            ));
        
            tokenhistory[tokenId] = Data(
                from,
                to,
                block.timestamp,
                tokenId
            );

            owners[tokenId] = string(to) ;
            balance[to] += 1;
            balance[from] -= 1;

            emit Savedata(from, to, block.timestamp, tokenId, datahash);
        }
    }
    
    function get_tokenhistory(uint256 tokenId) public view returns(Data memory){
        return tokenhistory[tokenId];
    }

    function get_balance(string memory owner) public view returns (uint256){
        return balance[owner];
    }

    function get_owner(uint256 tokenId)public view returns(string memory owner){
        return owners[tokenId];
    }

}