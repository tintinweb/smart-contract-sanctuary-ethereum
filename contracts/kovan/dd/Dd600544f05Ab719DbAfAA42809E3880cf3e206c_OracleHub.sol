/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/ORACLE/interfaces/IPriceOracle2.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPriceOracle2 {

  function token0() external view returns (address);
  function token1() external view returns (address);
  function update() external;
  function consult(address token, uint amountIn) external view returns (uint256);
  function consultCurrent(address token, uint amountIn) external view returns (uint);

}


// File contracts/CHAINLINK/AggregatorV3Interface.sol


pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/access/Ownable.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/M0/oracle/OracleHub.sol



pragma solidity ^0.8.6;



contract OracleHub is Ownable {
    struct OracleInfo {
        address addr;
        uint256 oracleType; //0 for uniswap oracle, 1 for chainlink oracle
        address inputToken; //must be set when type is 0
        bool answerAsDenominator; //must be set when type is 1
        bool scaledUp;
        uint256 scale;
    }

    mapping(string => OracleInfo) public Oracles;

    function registerOracleType0(
        string memory _name,
        address _addr,
        address inputToken
    ) public onlyOwner {
        Oracles[_name] = OracleInfo(_addr, 0, inputToken, false, false, 0);
    }

    function registerOracleType1(
        string memory _name,
        address _addr,
        bool _answerAsDenominator,
        bool _scaledUp,
        uint256 _scale
    ) public onlyOwner {
        Oracles[_name] = OracleInfo(_addr, 1, address(0), _answerAsDenominator, _scaledUp, _scale);
    }

    function getPrice(string memory _name, uint256 _inputAmount)
        public
        view
        returns (uint256 markPrice, uint256 currentPrice)
    {   
        if(_inputAmount == 0) return (0,0);
        OracleInfo memory oracle = Oracles[_name];
        require(oracle.addr != address(0), "Oracle Hub: no matching oracle");
        if (oracle.oracleType == 0) {
            //uniswap oracle
            markPrice = IPriceOracle2(oracle.addr).consult(
                oracle.inputToken,
                _inputAmount
            );
            currentPrice = IPriceOracle2(oracle.addr).consultCurrent(
                oracle.inputToken,
                _inputAmount
            );
        } else {
            //chainlink oracle
            require(oracle.oracleType == 1, "Oracle Hub: unknown oracle type");
            (, int256 answer, , , ) = AggregatorV3Interface(oracle.addr).latestRoundData();
            if(oracle.answerAsDenominator){
                if(oracle.scaledUp){
                    markPrice = _inputAmount * 10**oracle.scale / uint256(answer);
                }else{
                    markPrice = _inputAmount / 10**oracle.scale / uint256(answer);
                }
            }else{
                if(oracle.scaledUp){
                    markPrice = _inputAmount * uint256(answer) * 10**oracle.scale;
                }else{
                    markPrice = _inputAmount * uint256(answer) / 10**oracle.scale;
                }
            }
            currentPrice = markPrice;
        }
    }
}