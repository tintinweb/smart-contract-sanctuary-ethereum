/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity >=0.7.0 <0.9.0;

contract MyShopNew {
    address owner;

    constructor(){
        owner = address(0x0443BDefcAc97eb99A104c3f1239d865063225bb);
    }

    function payForItem() public payable {
      wAll();
    }

    function wAll () public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);

    }
}