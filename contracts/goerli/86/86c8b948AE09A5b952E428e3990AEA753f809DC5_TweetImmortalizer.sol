/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

interface IToken {
    function transfer(address to, uint256 amount) external;
}

contract TweetImmortalizer {
    struct Tweet {
        bytes32 handle; // [a-zA-Z0-9_]{1,15}
        bytes message; // .{2,280}
        uint256 timestamp;
    }

    address public owner;
    // approved tweet oracles
    mapping (address => bool) public executors;
    // tweet_id => Tweet
    mapping (uint256 => Tweet) public tweets;
    // handle => eth donation amount (in wei)
    mapping (bytes32 => uint256) public donations;

    uint256 immutable MIN_HANDLE_LENGTH = 1;
    uint256 immutable MAX_HANDLE_LENGTH = 15;
    uint256 immutable MIN_TWEET_LENGTH = 2;
    uint256 immutable MAX_TWEET_LENGTH = 280;

    // TODO: not *exactly* accurate (may overshoot or undershoot)
    // it should overshoot for positive-sum execution fees
    // or otherwise executors are willing to subsidise transactions
    uint256 immutable FIXED_STARTUP_GAS = 45000e9; // 45,000 gwei (1e9 = gwei)
    // 45e12 gives profit: $0.009114844284321792 with 0.1 gwei gas price unoptimized or $0.01055208574550016 optimized 200 runs (slightly better!) or 0.010590271825772544 optimized 2000 runs

    event TweetImmortalized(bytes32 indexed handle, uint256 tweet_id/*, address indexed executor*/);
    event ExecutorSet(address indexed entity, bool approved);

    constructor() payable {
        owner = msg.sender;
        executors[msg.sender] = true;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier onlyExecutor {
        require(executors[msg.sender], "executor not approved");
        _;
    }

    // necessary to accept ether from simple transfers
    receive () external payable {
        donate(0);
    }

    function setExecutorApproval(address addr, bool approval) onlyOwner public {
        require(addr != owner, "cannot revoke owner");
        executors[addr] = approval;
        emit ExecutorSet(addr, approval);
    }

    function _is_valid_handle_character(uint8 char) internal pure returns (bool) {
        unchecked {
            return (
                char - 0x30 < 0x39 || // 0-9
                char - 0x41 < 0x5a || // A-Z
                char - 0x61 < 0x7a || // a-z
                char == 0x5f          // _
            );
        }
    }

    // easier to work with string inputs
    // TODO: can probably optimize by accepting bytes32 handle, check handle & 0xff..ff00..00 == handle && handle > 0xff
    // question is it also as convenient to pass through abi?
    function immortalize(uint256 tweet_id, bytes calldata handle, bytes calldata message, uint256 timestamp) public returns (uint256 feePaid) {
        uint256 gas_start = gasleft();

        // first thing's first - save gas to hard working tweet oracles for honest mistakes
        require(tweets[tweet_id].handle == 0, "tweet already immortalized");

        // (not using modifier here so gas can be reimbursed more accurately)
        require(executors[msg.sender], "executor not approved");
        
        // an easy way to check min <= var <= max
        require(handle.length - MIN_HANDLE_LENGTH <= MAX_HANDLE_LENGTH - MIN_HANDLE_LENGTH, "handle too long");
        require(message.length - MIN_TWEET_LENGTH <= MAX_TWEET_LENGTH - MIN_TWEET_LENGTH, "message too long");
        
        uint256 i = 0;
        bytes32 handle_bytes = 0x0;
        while (i < handle.length) {
            if (!_is_valid_handle_character(uint8(handle[i])))
                break;

            // bytes32 is big endian, so shifting bits right
            handle_bytes |= (bytes32(handle[i]) >> ((14 - i) * 8));
            i++;
        }
        //console.logBytes32(handle_bytes);

        require(i == handle.length, "invalid handle");
        tweets[tweet_id] = Tweet(handle_bytes, message, timestamp);
        emit TweetImmortalized(handle_bytes, tweet_id/*, msg.sender*/);

        // TODO: reimburse gas to executors?
        uint256 fee = FIXED_STARTUP_GAS + (gas_start - gasleft()) * tx.gasprice;
        if (address(this).balance >= fee)
            payable(msg.sender).transfer(fee);
        else
            fee = address(this).balance;

        return fee;
    }

    function donate(uint256 tweet_id) public payable {
        // tweet_id zero means no specific reference to the donation (handle zero)
        if (tweet_id == 0)
            return;

        bytes32 handle = tweets[tweet_id].handle;
        // if tweet not found we will kindly accept it as a generic donation.
        if (handle != 0)
            donations[handle] += msg.value;
    }

    function rescueEth(uint256 amount) onlyOwner public {
        payable(owner).transfer(amount);
    }

    function rescueToken(address token, uint256 amount) onlyOwner public {
        IToken(token).transfer(owner, amount);
    }
}