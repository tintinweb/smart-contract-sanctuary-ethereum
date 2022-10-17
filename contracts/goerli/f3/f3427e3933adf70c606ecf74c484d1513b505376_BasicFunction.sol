/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract BasicFunction
{
string coinName = "Epic Coin";
uint mybalance = 100;

struct Coin 
{
    string name;
    string symbol;
    uint supply;
}
mapping(address => Coin) internal myCoins;
//function 
function getName() public view returns(string memory)
{
    return coinName;
}
function multiplyBalance(uint _multiplier) external
{
      mybalance = mybalance * _multiplier;

}
function findCoinIndex(string[] memory _coinsaddressList, string memory _find, uint _findFrom) public pure returns(uint)
{
    for(uint i = _findFrom; i< _coinsaddressList.length; i++ )
    {
        string memory coinaddressStorage = _coinsaddressList[i];
        if(keccak256(abi.encodePacked(coinaddressStorage))  == keccak256(abi.encodePacked(_find)))
        {
            return i;

        }
    }
    return 999;
}
function addCoin(string memory _name, string memory _symbol , uint _supply) external
{
    myCoins[msg.sender] = Coin(_name,_symbol, _supply);

}
function getCoin() public view returns(Coin memory)
{
        return myCoins[msg.sender];

} 




}