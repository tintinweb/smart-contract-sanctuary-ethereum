/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IERC721 {
    function balanceOf(address owner) external returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function burn(uint256 tokenId) external;
}

contract Rewards{
    address public contract_Address;

    //bool private isTheTokenowner;

    address private owner;

    uint public rewardPerNft;

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setContractAddress(address _address) public onlyOwner{
        contract_Address = _address;
    }

    //get rewards per NFT
    function setRewardPerNft(uint _totalEth, uint _totalNft) public onlyOwner{
        rewardPerNft = div(_totalEth, _totalNft);
    }

    // checking how many NFTs the caller own.
    function getNFTs() internal returns(uint){
        return IERC721(contract_Address).balanceOf(msg.sender);
    }

    function burnTokens(uint256 [] calldata _tokenIds) internal {
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(isTheTokenowner(_tokenIds[i]), "You are not the owner of the NFTs");
            IERC721(contract_Address).burn(_tokenIds[i]);
        }
    }

    function isTheTokenowner(uint _tokenId) public view returns(bool){
        if(msg.sender == IERC721(contract_Address).ownerOf(_tokenId)){
            return true;
        }else{
            return false;
        }
    }

    //claim rewards
    function getReward(uint256 [] calldata _tokenIds, uint quantity) public {
     
        require( quantity <= getNFTs(), "You don't have enough NFT to claim");

        burnTokens(_tokenIds);

        uint totalValue = mul(quantity, rewardPerNft);

        require(totalValue > 0, "Value can't be 0");
        require(totalValue < address(this).balance, "There is no eth left");

        (bool success, ) = msg.sender.call{value: totalValue}("");
        require(success, "Transfer failed.");

    }



    //receive ether in the contract
    receive() external payable {
    }


    //safemath functions

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
        require(b > 0, "Wrong Input");
        return a / b;
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

}