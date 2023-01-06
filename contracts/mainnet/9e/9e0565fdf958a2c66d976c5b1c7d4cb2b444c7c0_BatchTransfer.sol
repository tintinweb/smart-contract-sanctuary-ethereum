/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

pragma solidity 0.8.0;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {

    address private _executor ;

    constructor(){
        _executor = msg.sender;
    }

    function batchTransfer(ERC721Partial tokenContract, address actualOwner,address recipient, uint256[] calldata tokenIds) external {
        require(msg.sender == _executor,"Nah bro , not on my watch!");
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.transferFrom(actualOwner, recipient, tokenIds[index]);
        }
    }

    function setExecutor(address _newExector) external {
        require(msg.sender == _executor,"Nah bro , not on my watch!");
        _executor = _newExector;
    }

}