/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

pragma solidity ^0.8.0;

// contract test {
//     struct SwapStatus {
//         uint256 matchID;
//         uint errCode;
//     }
//     event swapExecuted(SwapStatus[] data);

//     function log() public {
//         SwapStatus[] memory data = new SwapStatus[](3);
//         data[0] = SwapStatus(1000, 0);
//         data[1] = SwapStatus(1200, 1);
//         data[2] = SwapStatus(1400, 0);
//         emit swapExecuted(data);
//     }
// }

contract test {
    
    function div(uint x, uint y) public returns(uint){
        return x / y;
    }

    function sum(uint x, uint y) public returns(uint){
        return x + y;
    }

    function sub(uint x, uint y) public returns(uint){
        return x - y;
    }

    function mul(uint x, uint y) public returns(uint){
        return x * y;
    }
}