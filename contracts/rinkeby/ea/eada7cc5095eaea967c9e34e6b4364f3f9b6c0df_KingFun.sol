/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

pragma solidity >= 0.8.0 < 0.9.0;

contract KingFun{
    bool alreadyKing = false;
    address payable kingGameAddress = payable(0xc44594f48BA69aEAD04C12BF86A315320968E994);

    function becomeKing() public {
        kingGameAddress.transfer(address(this).balance);
    }
    function deposit() payable public{
    }

    receive() external payable{
        require(!alreadyKing, "King!");
        alreadyKing = true;
    }
}