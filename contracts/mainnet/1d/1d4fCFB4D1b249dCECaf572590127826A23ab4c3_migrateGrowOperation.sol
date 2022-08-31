// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

struct Stake {
        uint256 tokenId;
        uint256 value;
        address owner;
}

interface IGROWOPERATION {
    function GrowOperation(uint256) external view returns (Stake memory);
    function totalSupply() external view returns (uint256);
}

interface ISTAC {
    function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

contract migrateGrowOperation {
    constructor() {
		growOperationContract = IGROWOPERATION(0x6c4d98826819746F50C926d0c0Ff41D84C216f37);
        stacContract = ISTAC(0x47b513D33D6E2B6F071b09CFbd7F4eDfF29CE07A);
	}

    IGROWOPERATION growOperationContract;
    ISTAC stacContract;

    function getAmountUserStaked(address _owner) external view returns (uint256) {
        uint256 amountStaked = stacContract.balanceOf(address(growOperationContract));
        uint256 amountUserStaked = 0;
        Stake memory stakedInfo;

        for(uint256 i = 0; i < amountStaked; i++) {
            stakedInfo = growOperationContract.GrowOperation(stacContract.tokenOfOwnerByIndex(address(growOperationContract), i));
            if (stakedInfo.owner == _owner) {
                amountUserStaked += 1;
            } 
        }

        return amountUserStaked;

    }

}