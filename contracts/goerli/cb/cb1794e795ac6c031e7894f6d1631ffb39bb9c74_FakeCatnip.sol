/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
interface Tubbies {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(uint256 _count) external payable;
}
contract FakeCatnip {
    Tubbies tc;
    constructor() {
        tc = Tubbies(0xBC09aE03c35590bD77e4FCD45269DD7324D34296);
    }
    function bulkMint(uint rounds, uint minerBribe) public payable {
        if(block.timestamp>1645584991){
            for(uint i=0; i<rounds;i++){
                // mint 5 at 0.1 ea to the tubby contract
                // pay miner via coinbase transfer for each successful batch mint
                try tc.mint{value: 0.5 ether}(5){
                    block.coinbase.transfer(minerBribe);
                }catch{
                    break;
                }
            }
        }else{
            revert("too soon");
        }
    }
    function withdrawLoot(uint[] memory ids) public {
        for(uint i=0;i<ids.length;i++){
            uint id = ids[i];
            tc.safeTransferFrom(address(this), 0x4bE25c8df13d15E08BffB05789E3a1Fc02b0a820, id);
        }
    }
}