// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IGenesis.sol";
import "./IGame.sol";

contract StakedGenesis {

    IGenesis public Genesis = IGenesis(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5);
    IGame public DW = IGame(0xeBD218aB65a793Ef506AF561093D0E7E9C9224f2);
    IGame public PM = IGame(0xc4bc9B325D7B1fB618BDd31352D19ba46fA58d8E);
    IGame public MF = IGame(0x5E7f86544154E43E07f73798ffA1d057d73dC7d9);
    address public BS = 0x801aaeCAA1059ee87c646cad709e210AE1930e41;
    address public BP = 0x9c215c9Ab78b544345047b9aB604c9c9AC391100;
    address public AR = 0xF84BD9d391c9d4874032809BE3Fd121103de5F60;

    function getStakedDW() public view returns (uint256 stakedCatsCount, uint256 stakedDogsCount, uint256 stakedVetsCount) {
        stakedCatsCount = 0;
        stakedDogsCount = 0;
        stakedVetsCount = 0;
        uint256[] memory stakedInDW = Genesis.walletOfOwner(address(DW));
        uint256 length = stakedInDW.length;
        for(uint i = 0; i < length; i++) {
            uint8 genType = DW.genesisType(uint16(stakedInDW[i]));
            if(genType == 1) {
                stakedCatsCount++;
            } else if(genType == 2) {
                stakedDogsCount++;
            } else if(genType == 3) {
                stakedVetsCount++;
            }
        }
    }

    function getStakedPM() public view returns (uint256 stakedBakerCount, uint256 stakedFoodieCount, uint256 stakedShopOwnerCount) {
        stakedBakerCount = 0;
        stakedFoodieCount = 0;
        stakedShopOwnerCount = 0;
        uint256[] memory stakedInPM = Genesis.walletOfOwner(address(PM));
        uint256 length = stakedInPM.length;
        for(uint i = 0; i < length; i++) {
            uint8 genType = PM.genesisType(uint16(stakedInPM[i]));
            if(genType == 1) {
                stakedBakerCount++;
            } else if(genType == 2) {
                stakedFoodieCount++;
            } else if(genType == 3) {
                stakedShopOwnerCount++;
            }
        }
    }

    function getStakedMF() public view returns (uint256 stakedCadetCount, uint256 stakedAlienCount, uint256 stakedGeneralCount) {
        stakedCadetCount = 0;
        stakedAlienCount = 0;
        stakedGeneralCount = 0;
        uint256[] memory stakedInMF = Genesis.walletOfOwner(address(MF));
        uint256 length = stakedInMF.length;
        for(uint i = 0; i < length; i++) {
            uint8 genType = MF.genesisType(uint16(stakedInMF[i]));
            if(genType == 1) {
                stakedCadetCount++;
            } else if(genType == 2) {
                stakedAlienCount++;
            } else if(genType == 3) {
                stakedGeneralCount++;
            }
        }
    }

    function getStakedBS() public view returns (uint256 stakedRunnerCount, uint256 stakedBullCount, uint256 stakedMatadorCount) {
        uint256[] memory stakedInBS = Genesis.walletOfOwner(BS);
        stakedRunnerCount = stakedInBS.length;
        uint256[] memory stakedInBP = Genesis.walletOfOwner(BP);
        stakedBullCount = stakedInBP.length;
        uint256[] memory stakedInAR = Genesis.walletOfOwner(AR);
        stakedMatadorCount = stakedInAR.length;
    }

    function getAllStaked() external view 
    returns (
        uint256 stakedCatsCount, uint256 stakedDogsCount, uint256 stakedVetsCount,
        uint256 stakedBakerCount, uint256 stakedFoodieCount, uint256 stakedShopOwnerCount,
        uint256 stakedCadetCount, uint256 stakedAlienCount, uint256 stakedGeneralCount,
        uint256 stakedRunnerCount, uint256 stakedBullCount, uint256 stakedMatadorCount,
        uint256 totalStaked
    ) {
        (stakedCatsCount, stakedDogsCount, stakedVetsCount) = getStakedDW();
        (stakedBakerCount, stakedFoodieCount, stakedShopOwnerCount) = getStakedPM();
        (stakedCadetCount, stakedAlienCount, stakedGeneralCount) = getStakedMF();
        (stakedRunnerCount, stakedBullCount, stakedMatadorCount) = getStakedBS();
        
        totalStaked = (
            stakedCatsCount + stakedDogsCount + stakedVetsCount +
            stakedBakerCount + stakedFoodieCount + stakedShopOwnerCount +
            stakedCadetCount + stakedAlienCount + stakedGeneralCount +
            stakedRunnerCount + stakedBullCount + stakedMatadorCount
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGame {
    function genesisType(uint16 nft) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGenesis {
    function walletOfOwner(address owner) external view returns (uint256[] memory);
}