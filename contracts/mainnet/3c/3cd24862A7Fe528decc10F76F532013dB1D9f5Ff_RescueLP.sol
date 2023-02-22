/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
 
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(address to) external returns (uint amount0, uint amount1);
}
 
contract RescueLP {
 
    IERC20 constant pair = IERC20(0xc36d3F7FbDa3b1157456B23DF090C79AAEe43C24);
    IERC20 constant token = IERC20(0x2685f19f04e46E9084db76B960515276744DD13F);
 
    uint256 amount = 894570330000000;
 
    address immutable owner;
 
    error NotOwner();
 
    address[38] wallets = [0x775E78148Cd0B02FBCDe9Ef5Fc441CaDc2A73126, 0x8Cf6B1a47924f006beaE71B044264582833106aF, 0xaFd73c1797530c9587750b3Fde633E20D2BC2B4D, 0xe3565a6eE986E23AE300F1CE614d128E0DBd2cc7, 0xC31b8136753E7E071829276AEC1548bb17143D77, 0xf2F26af5A1A11aD435b5E4dc6849dEAd201E15E1, 0x151e005c47E0Fdc146731e83139D1963E3774661, 0x8b3Ef8a78f387460e3856434324FA48DC80D4D48, 0xfD875F5E05937194E85382c44638D8A0F270F774, 0x2C7FD5cE05a79b26628809365aB02C34a919fC30, 0x9bEb509b4f5805508DE8d912B985d04a13e814b5, 0x28f8E53e409888ccB748dE64C6f11E5A3dC2EFfd, 0x4B613e144FB89eED5cf032F82FacfD77931795f9, 0x906a5490401A0C3ca2c8236782483b256e7fDfB1, 0x4d15d03c366aB89bEb8BB2b8aD8658fB79f441a6, 0xB6645A85f779744436344Fa247300582F29f396a, 0xb47Ab2c6093A01757B15d7D91A53faE1874e5476, 0x7D30a9bc5D3D6801d8216Cf64ad4F5828B10F878, 0x0A21000b8635ACF2E8ada749324dc7B4E33BD7bE, 0xf2a08AC409d082D843de292BeC28a3C38B6E197f, 0x1ff3EFB385fB3FDbCC1cb994Fe603E26534c22F2, 0x978d7EDf9d73FBE154105C69e64f126678B56C0c, 0x9cA900026F17153b6d5a8320c5Cf8aEaBb3140e3, 0x520f99754bBE7A223aBb837398BAaB90c3D17C62, 0x08080dBbd7e460E43CEA18F99fDae7f66B48C685, 0x0778354b4fCB90CC7de05b9c56077706288E683e, 0xA74af0C9B41947e21F9C22F3DC1D0C6588b1Ce0d, 0x542323DB8673B021299A73E13bCD7459A6Fc51F7, 0x421727B15594C1A8ab6D3407BAD39bF54BACA816, 0x5e6da92A5874B0b3B6B2822216d77eEf7a0a582E, 0xE99f8a15ed30404a07Ba3d094999F6Ac1cA7D446, 0x2A52C4f7Dc8C2e73B2b1304ba281294882fF64Dd, 0xc5F03771511DC1aE469BeD9F104Cf14350a68AE6, 0x16A17B6dbf4CC5CD448399CC524062Dfaac6B1a7, 0xA819724Fe35412b66e5F60Bbd3b137DDFa19FCDd, 0x9E193e8aE368039FDC63a5e5B07C88Ea0Bf78e0F, 0xeaB9E5bf0274DdB16DC67343326419aABa7DE124, 0x763155Ad13410E44007b0B9f0B7cA731fbe94665];
 
    constructor() {
        owner = msg.sender;
    }
 
    function rescue() external {
        if(owner != msg.sender) revert NotOwner();
        address[38] memory _wallets = wallets;
        for(uint256 i; i < 39;){
            uint256 j;
            while(j < 2){
                pair.transfer(address(pair), amount);
                (uint256 tokenAmount, ) = pair.burn(address(this));
                token.transfer(_wallets[i], tokenAmount);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }
 
    function rescueTokens(address tokenAddress, uint256 tokenAmt) external{
        IERC20(tokenAddress).transfer(owner, tokenAmt);
    }
 
    function rescueETH() external {
        payable(owner).transfer(address(this).balance);
    }
 
    function setAmount(uint256 _amount) external{
        require(owner == msg.sender);
        amount = _amount;
    }
 
    receive() external payable{}
}