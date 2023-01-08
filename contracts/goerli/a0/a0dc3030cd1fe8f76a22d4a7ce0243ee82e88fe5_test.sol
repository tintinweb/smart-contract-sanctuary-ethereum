/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

// File: contracts/mop.sol



pragma solidity >= 0.6.0;

contract test {
    
    uint public salesStartTimestamp = 1673178000;
    bool public publicSale = false;
    address public ownerAddress;
    uint256 constant paying = 0.0000006942 ether;

    constructor(){
        ownerAddress = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == ownerAddress);
        _;
    }

    function isSalesActive() public view returns (bool) {
        return salesStartTimestamp <= block.timestamp;
    }

    function setSaleTime(uint _SalesStartTimeStamp) public {
        salesStartTimestamp = _SalesStartTimeStamp;
    }

    function flipState() public onlyOwner{
        publicSale = !publicSale;
    }

    function publicMint() public {
        require(isSalesActive(), "Public sale not live");
        salesStartTimestamp += 180;
    }

}