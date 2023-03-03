/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

pragma solidity 0.8.19;

interface IDA {

    function purchaseTo(address _to, uint256 _projectId)
        external
        payable
        returns (uint256 tokenId);

}

contract Minter {
    IDA DA = IDA(0xb61ABA1c6b4079c976Fb664F27a0D9C47b81a05B);
    address DEAD = 0xD5bb28F5d0Cf0E6A093e418517F990373766eC2a;
    uint256 projectid = 279;

    function purchaseSeveral(uint256 count, uint256 priceInWei) external payable {
        for(uint i; i < count; i++) {
            DA.purchaseTo{value: priceInWei}(DEAD, projectid);
        }
    }
}