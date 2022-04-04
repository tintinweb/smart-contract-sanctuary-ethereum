/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



// Part: Deploy

abstract contract Deploy  {
    function premint(uint256 quantity)  external payable {}
    function getPrice() public  pure returns (uint256) {}
}

// Part: mintSingle

contract mintSingle {
    uint price ;
    Deploy dc;
    constructor(address token)  payable {
        dc = Deploy(token);
        price = dc.getPrice();
    }

    function getPrice() public view returns (uint256 result) {
        return dc.getPrice();
    }

    function mint(uint256 _val) external payable  {
        dc.premint{value:price}(_val);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public  returns (bytes4) {
        return 0x150b7a02;
    }

}

// File: mintfactory.sol

contract mintFactory  {
    uint number = 0;
    mapping(uint => address) mintcontracts;
    address  token = 0x956d8Ca6511B59d3AC8A3156A9168f49a6aba938;
    function createContract(uint amount) public payable {
        for(uint  i=0;i<amount;i++)
        {
            mintcontracts[number] = address (new mintSingle{value: msg.value/amount}(token));
            number++;
        }
    }
    function getAddr(uint num)public view returns(address){
        return mintcontracts[num];
    }

//    function multiMint(uint amount) public {
//        for(uint  i=0;i<=amount;i++)
//        {
//
//            mintSingle(getAddr(i)).mint
//        }
//    }
    function pricetag() public view returns (uint256 result) {
        return mintSingle(getAddr(0)).getPrice();
    }


}