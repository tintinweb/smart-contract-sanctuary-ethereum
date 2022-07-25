/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity 0.6.6;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}