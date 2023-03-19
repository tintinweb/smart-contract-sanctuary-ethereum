pragma solidity >=0.8.4 <0.9.0;

import {SmallRSolution} from './SmallRSolution.sol';

contract Factory {
    function createSolutionContract(bytes32 _salt) public returns (address _resAddress) {
        SmallRSolution _solution = new SmallRSolution{salt: _salt}();
        _resAddress = address(_solution);
    }
}

pragma solidity >=0.8.4 <0.9.0;

contract SmallRSolution {
    fallback() external {
        assembly {
            mstore(0x00, 0xa8b5a32cf86bc7dde643cdb57ac950666f799f4850b44194d1a2932c91431884)
            mstore(0x20, 27)
            mstore(0x40, 0x00000000000000000000003b78ce563f89a0ed9414f5aa28ad0d96d6795f9c63)
            return(0x00, 0x60)         
        }

    }
}