/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// File: contracts/IGame.sol


pragma solidity 0.8.17;

interface IGame {
    function getUnclaimedGenesis(uint16) external view returns (uint256);
}
// File: contracts/calc.sol


pragma solidity 0.8.17;


contract Calculator {
    
    IGame public DOGE = IGame(0xeBD218aB65a793Ef506AF561093D0E7E9C9224f2);
    IGame public PYE = IGame(0xc4bc9B325D7B1fB618BDd31352D19ba46fA58d8E);

    function getUnclaimedDoge(uint16[] calldata _ids) external view returns (uint256 unclaimed) {
        for(uint i = 0; i < _ids.length; i++) {
            unclaimed += DOGE.getUnclaimedGenesis(_ids[i]);
        }
    }

    function getUnclaimedPye(uint16[] calldata _ids) external view returns (uint256 unclaimed) {
        for(uint i = 0; i < _ids.length; i++) {
            unclaimed += PYE.getUnclaimedGenesis(_ids[i]);
        }
    }

}