// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import 'interfaces/IGreeter.sol';

contract Greeter is IGreeter {
    // Empty string for revert checks
    /// @dev result of doing keccak256(bytes(''))
    bytes32 internal constant _EMPTY_STRING = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @inheritdoc IGreeter
    address public immutable OWNER;

    /// @inheritdoc IGreeter
    string public greeting;

    /// @inheritdoc IGreeter
    IERC20 public token;

    /**
     * @notice Defines the owner to the msg.sender and sets the
     * initial greeting
     *
     * @param _greeting Initial greeting
     * @param _token Initial token
     */
    constructor(string memory _greeting, IERC20 _token) {
        OWNER = msg.sender;
        token = _token;
        setGreeting(_greeting);
    }

    /// @inheritdoc IGreeter
    function setGreeting(string memory _greeting) public onlyOwner {
        if (keccak256(bytes(_greeting)) == _EMPTY_STRING) {
            revert Greeter_InvalidGreeting();
        }

        greeting = _greeting;
        emit GreetingSet(_greeting);
    }

    /// @inheritdoc IGreeter
    function greet() external view returns (string memory _greeting, uint256 _balance) {
        _greeting = greeting;
        _balance = token.balanceOf(msg.sender);
    }

    /**
     * @notice Reverts in case the function was not called by
     * the owner of the contract
     */
    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert Greeter_OnlyOwner();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import 'isolmate/interfaces/tokens/IERC20.sol';

/**
 * @title Greeter Contract
 * @author Wonderland
 * @notice This is a basic contract created in order to portray some
 * best practices and foundry functionality.
 */
interface IGreeter {
    ///////////////////////////////////////////////////////// EVENTS
    /**
     * @notice Greeting has changed
     * @param _greeting The new greeting
     */
    event GreetingSet(string _greeting);

    ///////////////////////////////////////////////////////// ERRORS
    /**
     * @notice Throws if the function was called by someone else than the owner
     */
    error Greeter_OnlyOwner();

    /**
     * @notice Throws if the greeting set is invalid
     * @dev Empty string is an invalid greeting
     */
    error Greeter_InvalidGreeting();

    ////////////////////////////////////////////////////// VARIABLES
    /**
     * @notice Returns the owner of the contract
     * @dev The owner will always be the deployer of the contract
     * @return The owner of the contract
     */
    function OWNER() external view returns (address);

    /**
     * @notice Returns the greeting
     * @return The greeting
     */
    function greeting() external view returns (string memory);

    /**
     * @notice Returns the token used to greet callers
     * @return The address of the token
     */
    function token() external view returns (IERC20);

    /**
     * @notice Returns set previously set greeting
     *
     * @return _greeting The greeting
     * @return _balance  Current token balance of the caller
     */
    function greet() external view returns (string memory _greeting, uint256 _balance);

    ////////////////////////////////////////////////////////// LOGIC
    /**
     * @notice Sets a new greeting
     * @dev Only callable by the owner
     * @param _newGreeting The new greeting to be set
     */
    function setGreeting(string memory _newGreeting) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20 {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                              VARIABLES
  //////////////////////////////////////////////////////////////*/
  function name() external view returns (string memory _name);

  function symbol() external view returns (string memory _symbol);

  function decimals() external view returns (uint8 _decimals);

  function totalSupply() external view returns (uint256 _totalSupply);

  function balanceOf(address _account) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function nonces(address _account) external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                                LOGIC
  //////////////////////////////////////////////////////////////*/
  function approve(address spender, uint256 amount) external returns (bool);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}