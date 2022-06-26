/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// File: contracts/ITrueRandom.sol



pragma solidity >=0.7.0 <0.9.0;

interface ITrueRandom{

    // create
    // create function is used to generate new number
    // more importantly it refreshes state salt
    // create should be used at least once in an hour to prevent any interference from miner or code executor
    // ideally, use create once per solidity computation session
    function create()
    external returns(uint256);
    function create(bytes memory _b)
    external returns(uint256);
    function create(string memory _s)
    external returns(uint256);
    function create(address _a)
    external returns(uint256);

    // get
    // unlike create, get uses state and user defined salt without any state manipulation
    // this means get set of functions can be called as view and therefore can be used with SDKs
    // use get AFTER initial create call reset state salt
    // roughly 1/6 cheaper than create operations
    function get()
    external view returns(uint256);
    function get(bytes memory _b)
    external view returns(uint256);
    function get(string memory _s)
    external view returns(uint256);
    function get(address _a)
    external view returns(uint256);
}
// File: contracts/TrueRandom.sol



pragma solidity 0.8.8;


/**
 * @title TrueRandom 1.0
 * @dev 
 * @custom:empty 
 */
contract TrueRandom is ITrueRandom {

    uint256 private number;
    uint64 private previous;
    mapping(address => uint) private numbers;

    function generateWithInput(bytes memory _toEncode, uint _number) private view returns (uint256) {
        // downsizing trims higher bytes, changing bytes of timestamp are converted
        // 8B + 8B + 16B = 32B, not necessary
        // trimming functions as precaution layer, also saves gas
        return uint(
            keccak256(
                abi.encode(
                    uint64(_number),
                    uint64(block.timestamp),
                    bytes16(_toEncode)
                )
            )
        );  // converting 32B data into 32B hash into 32B uint
    }

    function generateWOInput(uint _number) private view returns (uint256) {
        // downsizing trims higher bytes, changing bytes of timestamp are safe
        // 16B + 16B = 32B, not necessary, precaution layer
        bytes memory toKeccak = abi.encode(uint128(_number), uint128(block.timestamp));
        return uint(keccak256(toKeccak));  // converting 32B data into 32B hash into 32B uint
    }

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
        uint256 n = generateWOInput(number);
        number = n;
        return n;
    }

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create(bytes memory _bytesInput) override external returns (uint256) {
        uint256 n = generateWithInput(_bytesInput, number);
        number = n;
        return n;
    }

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create(string memory _stringInput) override external returns (uint256) { // gas 33591
        uint256 n = generateWithInput(bytes(_stringInput), number);
        number = n;
        return n;
    }

    /**
     * @dev Generates new random num, should be called from smart contract
     * @return newly generated random number
     */
    function create(address _addressInput) override external returns (uint256) {
        uint256 n = generateWithInput(abi.encode(_addressInput), number);
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
        return generateWOInput(number);
    }

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get(bytes memory _b) override external view returns (uint256) {
        return generateWithInput(_b, number);
    }

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get(string memory _s) override external view returns(uint256) { // gas 33591
        return generateWithInput(bytes(_s), number);
    }

    /**
     * @dev Generates new random num, can be called from SDK
     * @return newly generated random number
     */
    function get(address _a) override external view returns (uint256) {
        return generateWithInput(abi.encode(_a), number);
    }

}