// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "./Ownable.sol";


contract BlockInfo is Ownable { 
    constructor() {
    }

    function getBlockGasLimit() public view returns(uint256 result) {
        assembly {
            result := gaslimit()
        }
    }

    function getBlockDifficulty() public view returns(uint256 result) {
        assembly {
            result := difficulty()
        }
    }

    function getBlockCoinbase() public view returns(address result) {
        assembly {
            result := coinbase()
        }
    }

    function getBlockBaseFee() public view returns(uint256 result) {
        assembly {
            result := basefee()
        }
    }

    function getGasPrice() public view returns(uint256 result) {
        assembly {
            result := gasprice()
        }
    }

    receive() external payable {}
    fallback() external payable {}
}