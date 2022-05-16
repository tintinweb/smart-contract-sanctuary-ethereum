/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

abstract contract CurvePoolInterface2 {
    function getPoolInformations() virtual public view returns (
        // the number of tokens in the pool, for now we assume it is equal to 2
        uint8 nTokens,
        // the address of each token in the pool, this is expected to be of length nTokens
        address[] memory tokenAddresses,
        // the amount of each token in the pool, this is expected to be of length nTokens
        uint256[] memory balances,
        // the constant invariant
        uint256 k,
        // the amplification factor
        uint256 A
        
    );
}

abstract contract CurvePoolInterface {
    function get_virtual_price() virtual external returns (uint256);
}

interface IStableSwapBUSD {
    function get_virtual_price() external returns (uint256);
}

contract PriceAndSlippageComputerContract {
    address owner;
    string ownerName;
    IStableSwapBUSD public stableSwapBUSD;
    constructor(string memory _name){
        owner=msg.sender;
        ownerName=_name;
    }
    
    function getOwnerName() public view returns(string memory) {
        return ownerName;
    }


    function setCurvePoolContractAddress(address _address) external {
        stableSwapBUSD = IStableSwapBUSD(_address);
    }

    function getCurvePoolContractAddress() public view returns(address) {
        return address(stableSwapBUSD);
    }

    function getPrice() public returns(uint256){
        return stableSwapBUSD.get_virtual_price();
    }

}