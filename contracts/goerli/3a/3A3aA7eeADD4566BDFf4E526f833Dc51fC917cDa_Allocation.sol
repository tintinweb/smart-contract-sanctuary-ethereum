/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// 3 categories
// Common - 870 (87%)   

// Rare - 80 (8%)
    // Orange - 5 (0.5%)
    // Purple - 10 (1%)
    // Violet - 25 (2.5%)
    // Yellow - 40 (4%)

// Unique - 51 (5%)
    // One Above The All - 1 (OATA)
    // Legendary -5 NFT (0.5%)
    // Golden - 10 (1%)
    // Diamond - 20 (2%)
    // Silver - 15 (1.5%)

// 20% of 950 NFTs (870 COMMON + 80 RARE)- 190 NFTs
// COMMON - 174
// RARE - 16
//     ORANGE - 1/5
//     PURPLE - 2/10
//     VIOLET - 5/25
//     YELLOW - 8/40 
// UNIQUE-10
//     LEGENDARY - 1
//     GOLDEN - 2
//     DIAMOND - 4
//     SILVER -3
//TOTAL: 174 + 16 + 10 = 200


pragma solidity ^0.8.0;

contract Allocation{

    uint256 public supplyCap = 1000;
    uint256 nonce = 0;
    uint[] public giveAwayArray;

    enum Category{
        COMMON,
        RAREORANGE,
        RAREPURPLE,
        RAREVIOLET,
        RAREYELLOW,
        UNIQUELEGENDARY,
        UNIQUEGOLDEN,
        UNIQUEDIAMOND,
        UNIQUESILVER
    }


    //supply caps of different token categories
    //categorySupplyCap will give how many can be minted
    mapping (Category => uint256) public categorySupplyCap;

    //categorySupply will give you how many NFTs in a particular category are minted
    // total supplies of different token categories
    mapping (Category => uint256) public categorySupply;
    mapping(uint256 => bool) checkNftInArray;


    function calcCategorySupply() public {
        categorySupplyCap[Category.COMMON]     =  (supplyCap * 87)/ 100;
        categorySupplyCap[Category.RAREORANGE] =  (supplyCap * 5)/ 1000;
        categorySupplyCap[Category.RAREPURPLE] =  (supplyCap * 1)/ 100;
        categorySupplyCap[Category.RAREVIOLET] =  (supplyCap * 25)/ 1000;
        categorySupplyCap[Category.RAREYELLOW] =  (supplyCap * 4)/ 100;     
     }

    function distributeNFT(
        Category category,
        uint256 lowerRange,
        uint256 upperRange
        ) public {
        uint256 NumberOfNft = (categorySupplyCap[category] * 20)/100;
        uint256 i = 0;             
        while (i < NumberOfNft) {
            uint256 randNFT = randModules(lowerRange, upperRange);
            if (category == Category.COMMON && checkNftInArray[randNFT] == false) {
            // NumberOfNft for Common = 174                               
                giveAwayArray.push(randNFT);
                checkNftInArray[randNFT] = true;
                i++;
            }
        

            if (category == Category.RAREORANGE && checkNftInArray[randNFT] == false) {
                // NumberOfNft for RAREORANGE = 1 
                    giveAwayArray.push(randNFT);
                    checkNftInArray[randNFT] = true;
                    i++;
                }
            

            if (category == Category.RAREPURPLE && checkNftInArray[randNFT] == false) {
                // NumberOfNft for RAREPURPLE = 2 
                    giveAwayArray.push(randNFT);
                    checkNftInArray[randNFT] = true;
                    i++;
                }
            

            if (category == Category.RAREVIOLET && checkNftInArray[randNFT] == false) {
                // NumberOfNft for RAREVIOLET = 5 
                    giveAwayArray.push(randNFT);
                    checkNftInArray[randNFT] = true;
                    i++;
                }
            

            if (category == Category.RAREYELLOW && checkNftInArray[randNFT] == false) {
                // NumberOfNft for RAREYELLOW = 10                 
                    giveAwayArray.push(randNFT);
                    checkNftInArray[randNFT] = true;
                    i++;
                }
            }
        }
    

        function randModules(uint256 lowerRange, uint256 upperRange)
                public
                returns (uint256)
            {
                nonce++;
                uint256 randomNumber = uint256(
                    keccak256(
                        abi.encodePacked(
                            nonce,
                            block.timestamp,
                            block.difficulty,
                            msg.sender
                        )
                    )
                );
                return (randomNumber % (upperRange - lowerRange)) + lowerRange;
        }

    function getGiveAwayArray() public view returns(uint[] memory){
        return giveAwayArray;
    }    
}