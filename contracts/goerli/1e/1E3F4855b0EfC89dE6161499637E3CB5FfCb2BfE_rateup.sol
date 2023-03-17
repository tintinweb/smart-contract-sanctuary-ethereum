/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.8.0;

interface ICDP_MANAGER {
    function cdpi() external view returns (uint256);
    function ilks(uint256 _cdpId) external view returns (bytes32);
}

interface IMCD_VAT {
    function ilks(bytes32 _ilks) external view returns (uint256, uint256, uint256, uint256, uint256);
}

interface IMCD_JUG {
    function drip(bytes32 ilk) external returns (uint256 rate);
}

contract rateup {
    ICDP_MANAGER immutable public CDP_MANAGER;
    IMCD_VAT immutable public MCD_VAT;
    IMCD_JUG immutable public MCD_JUG;
    event UpdateRate(uint256 cpdId);

    constructor(
        address _CDP_MANAGER,
        address _MCD_VAT,
        address _MCD_JUG
    ) {
        CDP_MANAGER = ICDP_MANAGER(_CDP_MANAGER);
        MCD_VAT = IMCD_VAT(_MCD_VAT);
        MCD_JUG = IMCD_JUG(_MCD_JUG);
    }

    function getSum() view external returns(uint256) {
        return CDP_MANAGER.cdpi();
    }

    function updateRate(uint256 start, uint256 end) external {
        uint256 arts;
        bytes32 ilks;
        for( uint i = start; i < end; i++ ) {
            ilks = CDP_MANAGER.ilks(i);
            (arts, , , ,) = MCD_VAT.ilks(ilks);
            if(arts > 10 ** 18){
                MCD_JUG.drip(ilks);
                emit UpdateRate(i);
            }
        }
    }

    function updateRates(uint256[] calldata cpdIds) external {
        for( uint i = 0; i < cpdIds.length; i++ ) {
            bytes32 ilks = CDP_MANAGER.ilks(cpdIds[i]);
            MCD_JUG.drip(ilks);
        }
    }

}