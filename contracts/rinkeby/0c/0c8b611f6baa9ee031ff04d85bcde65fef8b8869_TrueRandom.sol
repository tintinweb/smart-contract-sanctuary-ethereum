/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// File: @yv-work/true-random-sol/contracts/ITrueRandom.sol



pragma solidity 0.8.8;

interface ITrueRandom{

    // create
    // create function is used to generate new number
    // more importantly it refreshes state salt
    // create should be used at least once in an hour to prevent any interference from miner or code executor
    // ideally, use create once per solidity computation session
    function create()
    external returns(uint256);
    function create(bytes calldata _b)
    external returns(uint256);
    function create(string calldata _s)
    external returns(uint256);
    function create(address _a)
    external returns(uint256);
    function create(uint _i)
    external returns(uint256);

    // get
    // unlike create, get uses state and user defined salt without any state manipulation
    // this means get set of functions can be called as view and therefore can be used with SDKs
    // use get AFTER initial create call reset state salt
    // roughly 1/6 cheaper than create operations
    function get()
    external view returns(uint256);
    function get(bytes calldata _b)
    external view returns(uint256);
    function get(string calldata _s)
    external view returns(uint256);
    function get(address _a)
    external view returns(uint256);
    function get(uint _i)
    external view returns(uint256);
}
// File: contracts/TrueRandom.sol



pragma solidity 0.8.8;


/**
 * @title TrueRandom 1.1
 * @dev TrueRandom.sol smart contract, deployed on networks defined in ./TrueRandomConst.sol
 */
contract TrueRandom is ITrueRandom {

    uint256 private number;

    // create
    // create function is used to generate new number
    // more importantly it refreshes state salt
    // create should be used at least once in an hour to prevent any interference from miner or code executor
    // ideally, use create once per solidity computation session

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create() override external returns (uint256) {
        uint256 n = uint(keccak256(abi.encode(uint128(number), uint128(block.timestamp))));
        number = n;
        return n;
    }

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create(bytes calldata _b) override external returns (uint256) {
        uint n = uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), bytes16(_b))));
        number = n;
        return n;
    }

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create(string calldata _s) override external returns (uint256) {
        uint n = uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), bytes16(bytes(_s)))));
        number = n;
        return n;
    }

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create(address _a) override external returns (uint256) {
        uint n = uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), bytes16(abi.encode(_a)))));
        number = n;
        return n;
    }

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create(uint _i) override external returns (uint256) {
        uint n = uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), uint128(_i))));
        number = n;
        return n;
    }

    // get
    // unlike create, get uses state and user defined salt without any state manipulation
    // this means get set of functions can be called as view and therefore can be used with SDKs
    // use get AFTER initial create call reset state salt
    // roughly 1/6 cheaper than create operations

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get() override external view returns (uint256) {
        return uint(keccak256(abi.encode(uint128(number), uint128(block.timestamp))));
    }

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get(bytes calldata _b) override external view returns (uint256) {
        return uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), bytes16(_b))));
    }

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get(string calldata _s) override external view returns(uint256) { // gas 33591
        return uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), bytes16(bytes(_s)))));
    }

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get(address _a) override external view returns (uint256) {
        return uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), bytes16(abi.encode(_a)))));
    }

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get(uint _i) override external view returns (uint256) {
        return uint(keccak256(abi.encode(uint64(number), uint64(block.timestamp), uint128(_i))));
    }

}