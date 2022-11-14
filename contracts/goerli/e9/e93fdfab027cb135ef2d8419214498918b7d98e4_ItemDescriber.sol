/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: item-desciption-maker.sol


pragma solidity ^0.8.13;

contract ItemDescriber{
    
    string internal qdm;
    string internal partialDesc;
    string internal powerDesc;
    string public fullDesc;

    function calculateCombatRating(uint256 _qualityRating, uint256 _combatRating, uint256 _itemMaterial)public pure returns (uint256){
        uint256 qB = 0; //Quality Bonus
        uint256 materialBonus = 0;
        uint256 totalCR = 0;
        //Quality Descriptors
        if (_qualityRating > 99){
            qB = 20;
        }
        else if (_qualityRating >= 90){
            qB = 18;
        }
        else if (_qualityRating >= 80){
            qB = 15;
        }
        else if (_qualityRating >= 70){
            qB = 10;
        }
        else if (_qualityRating >= 60){
            qB = 8;
        }
        //Quality Score and Combat Rating Bonuses
        if (_itemMaterial== 1){ //Platinum Bonus
            materialBonus = 20;
        }
        else if (_itemMaterial == 2){ //Gold Bonus
            materialBonus = 10;
        }
        //Calculate Total Combat Rating
        totalCR = materialBonus + qB + _combatRating;
        return (totalCR);
    }
    function describeItem(uint256 _qualityRating, uint256 _combatRating, uint256 _itemType, uint256 _itemMaterial) public returns (string memory){
        
        string memory qD = "A low quality "; //qualityDescriptor
        string memory materialString = "iron ";
        string memory itemString = "necklace ";

        //Material Descriptors for Item Description on Marketplace
        if (_itemType == 2){
            itemString = "helmet ";
        }
        else if (_itemType == 3){
            itemString = "sword ";
        }
        //Item Descriptors
        if (_itemMaterial == 1){
            materialString = "platinum ";
        }
        else if (_itemMaterial == 2){
            materialString = "golden ";
        }
        else if (_itemMaterial == 3){
            materialString = "copper ";
        }
        else if (_itemMaterial == 4){
            materialString = "nickel ";
        }
        //Quality Descriptors
        if (_qualityRating > 99){
            qD = "A supremely flawless ";
        }
        else if (_qualityRating >= 90){
            qD = "A superbly crafted ";
        }
        else if (_qualityRating >= 80){
            qD = "A very high-quality ";
        }
        else if (_qualityRating >= 70){
            qD = "A high-quality ";
        }
        else if (_qualityRating >= 60){
            qD = "A solid and functional ";
        }
        else if (_qualityRating >= 50){
            qD = "A functional ";
        }
        else if (_qualityRating >= 30){
            qD = "A slightly misshapen ";
        }
        else if (_qualityRating >= 15){
            qD = "A low-quality ";
        }
        else if (_qualityRating >= 5){
            qD = "A poorly crafted ";
        }
        else{
            qD = "A tragically warped ";
        }
        
        qdm = string.concat(qD,materialString);
        partialDesc = string.concat(qdm,itemString);
        
        
        if (_combatRating >= 99){
            powerDesc = "of unmatched power.";
        }
        else if (_combatRating >= 90){
            powerDesc = "of legendary strength.";
        }
        else if (_combatRating >= 70){
            powerDesc = "of tremendous effect.";
        }
        else if (_combatRating >= 60){
            powerDesc = "of great effect.";
        }
        else if (_combatRating >= 50){
            powerDesc = "of significant effect.";
        }
        else if (_combatRating >= 30){
            powerDesc = "of decent effect.";
        }
        else if (_combatRating >= 15){
            powerDesc = "of some effect.";
        }
        else{
            powerDesc = "of little effect.";
        }
        fullDesc = string.concat(partialDesc, powerDesc);
        return (fullDesc);
    }

}