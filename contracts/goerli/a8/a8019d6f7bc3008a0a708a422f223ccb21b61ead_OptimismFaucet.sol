/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// Internal Imports
interface IERC20 {
  /// @notice ERC0 transfer tokens
  function transfer(address recipient, uint256 amount) external returns (bool);
  /// @notice ERC20 balance of address
  function balanceOf(address account) external view returns (uint256);
}

/// Faucet that drips ETH & ERC20 on Optimism
contract OptimismFaucet {

    /// Mutable storage

    /// @notice TOKEN ERC20 token
    IERC20 public TOKEN;
    /// @notice ETH to disperse
    uint256 public ETH_AMOUNT = 1e18;
    /// @notice TOKEN to disperse
    uint256 public TOKEN_AMOUNT = 100e18;
    /// @notice TIME in seconds of a day
    uint256 public ONE_DAY_SECONDS = 86400;
    /// @notice Sting githubids with last claim time
    mapping(string => uint256) public lastClaim;
    /// @notice Addresses of approved operators
    mapping(address => bool) public approvedOperators;
    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    /// Modifiers

    /// @notice Requires sender to be contract super operator
    modifier isSuperOperator() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }

    /// @notice Requires sender to be contract approved operator
    modifier isApprovedOperator() {
        // Ensure sender is in approved operators or is super operator
        require(
            approvedOperators[msg.sender] || superOperators[msg.sender], 
            "Not approved operator"
        );
        _;
    }

    /// Events

    /// @notice Emitted after faucet drips to a recipient
    /// @param recipient address dripped to
    event FaucetDripped(address indexed recipient);

    /// @notice Emitted after faucet drained to a recipient
    /// @param recipient address drained to
    event FaucetDrained(address indexed recipient);

    /// @notice Emitted after operator status is updated
    /// @param operator address being updated
    /// @param status new operator status
    event OperatorUpdated(address indexed operator, bool status);

    /// @notice Emitted after super operator is updated
    /// @param operator address being updated
    /// @param status new operator status
    event SuperOperatorUpdated(address indexed operator, bool status);

    /// Constructor

    /// @notice Creates a new OptimismFaucet contract
    /// @param _TOKEN address of ERC20 contract
    constructor(address _TOKEN) {
        TOKEN = IERC20(_TOKEN);
        superOperators[msg.sender] = true;
    }

    /// Functions

    /// @notice Drips and mints tokens to recipient
    /// @param _recipient to drip tokens to
    function drip(address _recipient, string memory _githubid) external isApprovedOperator {
        // Check if same githubid has claimed past 24hours
        require(canDrip(lastClaim[_githubid]), "Has claimed in the last 24hours");
        // Drip Ether
        (bool sent,) = _recipient.call{value: ETH_AMOUNT}("");
        require(sent, "Failed dripping ETH");
        lastClaim[_githubid] = block.timestamp;
        // Drip TOKEN
        // For now we will only require to drip ETH so in case the token balance
        // is low the faucet will still drip ETH
        TOKEN.transfer(_recipient, TOKEN_AMOUNT);

        emit FaucetDripped(_recipient);
    }

    /// @notice Returns number of available drips by token
    /// @return ethDrips — available Ether drips
    /// @return tokenDrips — available TOKEN drips
    function availableDrips() public view 
        returns (uint256 ethDrips, uint256 tokenDrips) 
    {
        ethDrips = address(this).balance / ETH_AMOUNT;
        tokenDrips = TOKEN.balanceOf(address(this)) / TOKEN_AMOUNT;
    }

    /// @notice Allows super operator to drain contract of tokens
    /// @param _recipient to send drained tokens to
    function drain(address _recipient) external isSuperOperator {
        // Drain all Ether
        (bool sent,) = _recipient.call{value: address(this).balance}("");
        require(sent, "Failed draining ETH");

        // Drain all TOKENS
        uint256 tokenBalance = TOKEN.balanceOf(address(this));
        require(TOKEN.transfer(_recipient, tokenBalance), "Failed draining TOKEN");

        emit FaucetDrained(_recipient);
    }

    /// @notice Allows super operator to update approved drip operator status
    /// @param _operator address to update
    /// @param _status of operator to toggle (true == allowed to drip)
    function updateApprovedOperator(address _operator, bool _status) 
        external 
        isSuperOperator 
    {
        approvedOperators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    /// @notice Allows super operator to update super operator
    /// @param _operator address to update
    /// @param _status of operator to toggle (true === is super operator)
    function updateSuperOperator(address _operator, bool _status) 
        external
        isSuperOperator
    {
        superOperators[_operator] = _status;
        emit SuperOperatorUpdated(_operator, _status);
    }

    /// @notice Allows super operator to update drip amounts
    /// @param _ethAmount ETH to drip
    /// @param _tokenAmount TOKEN to drip
    function updateDripAmounts(
        uint256 _ethAmount,
        uint256 _tokenAmount
    ) external isSuperOperator {
        ETH_AMOUNT = _ethAmount;
        TOKEN_AMOUNT = _tokenAmount;
    }

    /// @notice Allows super operator to update the token to drip
    /// @param _TOKEN address of the new token to start dripping
    function updateTokenDrip(address _TOKEN) external isSuperOperator {
        TOKEN = IERC20(_TOKEN);
    }

    /// @notice Returns true if a _githubid can drip
    /// @param  _lastClaimTime uint256 time thet user last claimed
    /// @return bool has claimed past 24hours
    function canDrip(uint256 _lastClaimTime) internal view returns (bool) {
        // incorrect lastClaimTime, is bigger than current time
        if(_lastClaimTime > block.timestamp)  {
            return false;
        }

        if(_lastClaimTime <= 0) {
            return true;
        }

        return ((block.timestamp - _lastClaimTime) >= ONE_DAY_SECONDS);
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}