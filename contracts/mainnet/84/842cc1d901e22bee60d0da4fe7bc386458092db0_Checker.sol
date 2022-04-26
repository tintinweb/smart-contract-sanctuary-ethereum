/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity ^0.8.0;


interface Claim {
    function alphaClaimed(uint256 tokenid) external returns (bool);
    function betaClaimed(uint256 tokenid) external returns (bool);
}

contract Checker {
    Claim claim = Claim(0x025C6da5BD0e6A5dd1350fda9e3B6a614B205a1F);


    function checkAlpha() external returns (uint256[] memory) {
        uint256[] memory unclaimed = new uint256[](10000);
        uint256 count;
        for (uint i = 0; i < 10000; i++){
            if (!claim.alphaClaimed(i)) {
                unclaimed[count] = i;
                count++;
            }
        }
        return unclaimed;
    }

    function checkBeta() external returns (uint256[] memory) {
        uint256[] memory unclaimed = new uint256[](20000);
        uint256 count;
        for (uint i = 0; i < 20000; i++){
            
            if (!claim.betaClaimed(i)) {
                unclaimed[count] = i;
                count++;
            }
        }
        return unclaimed;
    }

}