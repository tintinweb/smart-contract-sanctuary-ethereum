pragma solidity ^0.8.0;

contract Empty {


    fallback() external payable {
        
    }
}

contract EmptyFactory {

    function create() public returns (address) {
        Empty empty = new Empty();
        return address(empty);
    }
}