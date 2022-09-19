pragma solidity ^0.4.24;

/*
*   A smart contract for sale Fax Token with Ether.
*
*   Version: 1.0.0
*   Update Time: 2019/05/06
*
*/
import  './BeagleToken.sol';

contract BeagleTokenSale {
    address public admin;

    BeagleToken public tokenContract;
    address public tokenAdmin;

    // 1 Ether = 1000 Beagle
    uint256 public tokenPrice = 1000000000000000;
    uint256 public tokensSold;

    event Bought(address _buyer, uint256 _amount);

    constructor(BeagleToken _tokenContract, address _tokenAdmin) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenAdmin = _tokenAdmin;

    }

    function TransferOutEther() public {
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }

    function setPrice(uint256 _newPrice) public{
        require(msg.sender==admin);
        tokenPrice = _newPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == (_numberOfTokens * tokenPrice));
        require(tokenContract.allowance(tokenAdmin,this) >= _numberOfTokens);
        tokenContract.transferFrom(tokenAdmin,msg.sender, _numberOfTokens);

        tokensSold += _numberOfTokens;

        emit Bought(msg.sender, _numberOfTokens);
    }


}