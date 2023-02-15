/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.18;

contract protected {
    mapping (address => bool) is_auth;
    mapping (address => bool) is_middleware;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    function middleware(address addy) public view returns(bool) {
        return is_middleware[addy];
    }
    function set_middleware(address addy, bool booly) public onlyAuth {
        is_middleware[addy] = booly;
    }
    modifier onlyMiddleware() { // only middleware or owner
        require( is_middleware[msg.sender] || msg.sender==owner, "not middleware");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StableMaker is protected {
    // SECTION structs & types
    struct ChainPrototype {
        address stablemaker_address;
        address authorized_address;
        bool isEnabled;
        uint fee;
    }

    struct transferPrototype {
        address token;
        address to;
        uint amount;
        uint chainID;
        uint started;
        uint completed;
        bool pending;
        bool reverted;
        bool success;
    }

    // transfers
    mapping (bytes32 => transferPrototype) public transfers;
    bytes32[] public transfer_hashes;
    
    // All the chains and access variables
    mapping (uint => ChainPrototype) public chains;
    mapping (uint => string) public chain_names_by_ids;
    mapping (string => uint) public chain_ids_by_names;

    // Users balances on each chain (identified by chain_id)
    mapping (uint => mapping (address => mapping (address => uint))) public pendingBalances; // id -> user -> token -> balance

    // Accepted tokens
    mapping (address => bool) public accepted_tokens;

    // Global fee
    uint public fee = 10; // 1% or 10/1000
    mapping(address => uint) public feeAccumulatedForToken;

    // Events for tokens
    event Emit(address indexed token, address indexed to, uint amount, uint chainID, bytes32 transferHash);
    event Complete(address indexed token, address indexed to, uint amount, uint chainID, bytes32 transferHash);
    event Revert(address indexed token, address indexed to, uint amount, uint chainID, bytes32 transferHash);
    event Redeem(address indexed token, address indexed to, uint amount, uint chainID, bytes32 transferHash);
    // !SECTION structs & types

    constructor() {
        owner = msg.sender;
        is_auth[msg.sender] = true;
        is_middleware[msg.sender] = true;
        // Enable USDC and USDT
        accepted_tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // USDC
        accepted_tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // USDT
        // FIXME: Only for debug purpose
        accepted_tokens[0x07865c6E87B9F70255377e024ace6630C1Eaa37F] = true; // USDC (Goerli)
    }

    // ANCHOR Public functions

    // NOTE Deposit tokens to the contract to be emitted to another chain
    function deposit(uint chain_id, address receiver, address token, uint amount) public safe {
        require(accepted_tokens[token], "token not accepted");
        require(chains[chain_id].isEnabled, "chain not enabled");

        // Transfer tokens to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        // Calculate the fee
        uint fee_amount = amount * chains[chain_id].fee / 1000;
        // Calculate the amount to be added to the user balance
        uint amount_to_add = amount - fee_amount;
        // Accumulate fees
        feeAccumulatedForToken[token] += fee_amount;
        // Add to user balance
        pendingBalances[chain_id][receiver][token] += amount_to_add;
        // Create the hash
        bytes32 transferHash = keccak256(abi.encodePacked(token, receiver, amount_to_add, chain_id, block.timestamp));
        // Add to transfers
        transfer_hashes.push(transferHash);
        transfers[transferHash] = transferPrototype(token, receiver, amount_to_add, chain_id, block.timestamp, 0, true, false, false);
       // Emit
        emit Emit(token, receiver, amount_to_add, chain_id, transferHash);
    }

    // ANCHOR ADMIN functions

    function setFeePerThousand(uint _fee) public safe onlyOwner {
        fee = _fee;
    }

    function setChainFeePerThousand(uint chain_id, uint _fee) public safe onlyOwner {
        chains[chain_id].fee = _fee;
    }

    function setChainEnabled(uint chain_id, bool _enabled) public safe onlyOwner {
        chains[chain_id].isEnabled = _enabled;
    }

    function setTokenAccepted(address token, bool _accepted) public safe onlyOwner {
        accepted_tokens[token] = _accepted;
    }

    // ANCHOR Middleware functions

    // NOTE This will be called by the middleware to complete the emission once the transfer is confirmed on the other chain
    function completeEmission(bytes32 transferHash) public safe onlyMiddleware {
        require(transfers[transferHash].pending, "transfer not pending");
        // Get the transfer data from the hash
        uint _qty = transfers[transferHash].amount;
        address _token = transfers[transferHash].token;
        address _to = transfers[transferHash].to;
        uint _chainID = transfers[transferHash].chainID;
        // Clear the transfer
        transfers[transferHash].pending = false;
        transfers[transferHash].success = true;
        transfers[transferHash].completed = block.timestamp;
        // Clear the pending balance
        if (pendingBalances[_chainID][_to][_token] < _qty) {
            pendingBalances[_chainID][_to][_token] = 0;
        } else {
            pendingBalances[_chainID][_to][_token] -= _qty;
        }
        // Emit
        emit Complete(_token, _to, _qty, _chainID, transferHash);
    }

    // NOTE This will be called by the middleware to cancel the emission if the transfer is not confirmed on the other chain
    function revertEmission(bytes32 transferHash) public safe onlyMiddleware {
        require(transfers[transferHash].pending, "transfer not pending");
        // Get the transfer data from the hash
        uint _qty = transfers[transferHash].amount;
        address _token = transfers[transferHash].token;
        address _to = transfers[transferHash].to;
        uint _chainID = transfers[transferHash].chainID;
        // Clear the transfer
        transfers[transferHash].pending = false;
        transfers[transferHash].reverted = true;
        transfers[transferHash].completed = block.timestamp;
        // Clear the pending balance
        if (pendingBalances[_chainID][_to][_token] < _qty) {
            pendingBalances[_chainID][_to][_token] = 0;
        } else {
            pendingBalances[_chainID][_to][_token] -= _qty;
        }
        // Return the tokens to the user
        IERC20(_token).transfer(_to, _qty);
        // Emit
        emit Revert(_token, _to, _qty, _chainID, transferHash);
    }

    // NOTE This will be called by the middleware to redeem the tokens from the user
    function redeem(address _user, address _token, uint _amount) public safe onlyMiddleware {
        // Redeem is made simply by transfering the tokens to the user, but it should be done by a middleware
        IERC20(_token).transfer(_user, _amount);
        // Emit
        emit Redeem(_token, _user, _amount, 0, 0x0);
    }

    // FIXME Only for debug purpose

    function emitToken(address _token, address _to, uint _chainId, uint _amount) public safe onlyOwner {
        bytes32 _transferHash = keccak256(abi.encodePacked(_token, _to, _amount, _chainId, block.timestamp));
        emit Emit(_token, _to, _amount, _chainId, _transferHash);
    }
}