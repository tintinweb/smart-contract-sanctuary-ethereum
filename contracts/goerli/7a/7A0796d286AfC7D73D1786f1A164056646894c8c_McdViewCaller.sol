//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;



interface IMcdView {
    function getPrice(bytes32 ilk) external view returns (uint256) ;
    function getNextPrice(bytes32 ilk) external view returns (uint256) ;

}

contract McdViewCaller {

    address public proxy; 
    uint256 public ethPrice ;
    uint256 public ethNextPrice ;
    bytes32 public constant EthILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    
    constructor(address _proxyAddress){
        proxy = _proxyAddress;
    }

    function fetchData() public{
        ethPrice = IMcdView(proxy).getPrice(EthILK);
        ethNextPrice = IMcdView(proxy).getPrice(EthILK);
    }
}