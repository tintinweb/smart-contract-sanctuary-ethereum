/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

pragma solidity ^0.8.0;

interface Iinterface {
    function balanceOf(address account) external view returns (uint256);
}

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    function getEthBlances(address[] memory addr) public view virtual returns (uint256[] memory) {
        uint256[] memory balances = new uint[](addr.length);
        for (uint i = 0 ; i <= addr.length - 1 ;i++) {          
            balances[i] = addr[i].balance;
        }
        return balances;
    }

    // EIP20
    function getEIP20Balances0(address[] memory addr,address token) public view virtual returns (uint256[] memory) { 
        uint256[] memory balances = new uint[](addr.length);
        for (uint8 i = 0 ; i <= addr.length - 1 ;i++) {          
            balances[i] = Iinterface(token).balanceOf(addr[i]);
        }
        return balances;
    }

    function getEIP20Balances1(address addr,address[] memory token) public view virtual returns (uint256[] memory) { 
        uint256[] memory balances = new uint[](token.length);
        for (uint8 i = 0 ; i <= token.length - 1 ;i++) {          
            balances[i] = Iinterface(token[i]).balanceOf(addr);
        }
        return balances;
    }

    function getEIP20Balances2(address[] memory addr,address[] memory token) public view virtual returns (uint256[] memory) { 
        uint256[] memory balances = new uint[](addr.length);
        require(addr.length == token.length,'Parma err!');
        for (uint8 i = 0 ; i <= token.length - 1 ;i++) {          
            balances[i] = Iinterface(token[i]).balanceOf(addr[i]);
        }
        return balances;
    }

}