// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract Multicall {
    // Owner of the contract
    address private theowner;

    // Struct of the calls
    struct Call {
        address target;
        bytes callData;
        uint256 ethtosell;
        uint256 gastouse;
    }

    // Set the owner
    constructor() {
        theowner = msg.sender;
    }

    // onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == theowner);
        _;
    }

    // Multicall function return
    // Return {
    //   blockNumber: number of the block,
    //   returnData: [calls results],
    //   gasUsed: [gas used by each call],
    // }

    // If a call fails return 0x00
    function aggregate(
        Call[] memory calls
    )
        public
        onlyOwner
        returns (
            uint256 blockNumber,
            bytes[] memory returnData,
            uint256[] memory gasUsed
        )
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        gasUsed = new uint256[](calls.length);
        uint256 startGas = gasleft();
        bytes memory ris = hex"00";
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call{
                value: calls[i].ethtosell,
                gas: calls[i].gastouse
            }(calls[i].callData);
            if (!success) {
                ret = ris;
            }
            returnData[i] = ret;
            gasUsed[i] = startGas - gasleft();
            startGas = gasleft();
        }
    }

    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function getBlockHash(
        uint256 blockNumber
    ) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function getCurrentBlockDifficulty()
        public
        view
        returns (uint256 difficulty)
    {
        difficulty = block.prevrandao;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    // To allow the contract to receive funds
    receive() external payable {}

    // Allows the contract creator to withdraw funds
    function rescueBNB(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // Allows the contract creator to withdraw Wfunds
    function withdrawToken(
        address _tokenContract,
        uint256 _amount
    ) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}