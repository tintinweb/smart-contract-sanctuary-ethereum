// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMSERC20 {
    /// @notice Simple return for name
    /// @return name of the currency
    function name() external view returns (string memory);

    /// @notice Simple return for symbol
    /// @return symbol of the currency
    function symbol() external view returns (string memory);

    /// @notice Simple return for decimals
    /// @return decimals the amount of decimals
    function decimals() external view returns (uint8);

    /// @notice Simple return for totalSupply
    /// @return totalSupply of the currency
    function totalSupply() external view returns (uint256);

    /// @notice Returns the balance of an account
    /// @param _owner The owner of the account that of which balance details are being requested
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice Main transfer request, this will simply call the internal function _maketransfer
    /// @param _to the person being paid
    /// @param _value the amount
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice Function used to transfer on someone elses behalf. This emits the AllowanceTransfer event
    /// @param _from the paying account
    /// @param _to the account getting paid
    /// @param _value the amount
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice Function that dictates how much someone else can spend on your behalf.
    /// Value must first be set to 0 to prevent a race condition
    /// @param _spender the person who is spending on anothers behalf
    /// @param _value the approved amount to be spent
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    /// @notice Simple function that returns the current allowance allocated to a person
    /// @param _owner the person who is going to pay
    /// @param _spender the person who has permission to use funds from the others account
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    /// @notice Event that is fired when allowance is changed
    /// @param owner the person who is the account holder
    /// @param spender the person spending on the others behalf
    /// @param value the amount they can spend
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    /// @notice Event fired when a transfer is made
    /// @param from the person paying
    /// @param to the person being paid
    /// @param value the amount being paid
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./IMSERC20.sol";

//This document follows the NatSpec format

/// @title Mutually secure ERC20
/// @author Adir Miller
/// @notice This contract requires to to request payment before its made
/// @dev Hooks may be introduced in a later stage
contract MSERC20 is IMSERC20 {
    /// @notice Struct of the requests
    struct request {
        uint256 amount;
        uint256 endtime;
    }

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => mapping(address => request)) private _requests;
    mapping(address => uint32) private _requestcount;

    string private _name;
    string private _symbol;
    uint256 internal _totalSupply;
    uint16 private _requestLimit;

    /// @notice Constructor of the class, will set the total supply,innitial supply and
    /// set this balance to the owner of the contract
    /// @param name_  The name of the token
    /// @param symbol_  The symbol of the token
    /// @param requestLimit_  The max requests one account can request at a time
    /// @param initial The innitial cap of coins, this will be allocated to the owner
    constructor(
        string memory name_,
        string memory symbol_,
        uint16 requestLimit_,
        uint256 initial
    ) {
        _name = name_;
        _symbol = symbol_;
        _requestLimit = requestLimit_;
        _balances[msg.sender] = initial;
        _totalSupply = initial;
    }

    /// @notice Simple return for name
    /// @return name of the currency
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Simple return for symbol
    /// @return symbol of the currency
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Simple return for totalSupply
    /// @return totalSupply of the currency
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Simple return for decimals
    /// @return decimals which is by default 18, however method can be overridden
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /// @notice Returns the balance of an account
    /// @param account that is being requested balance details of
    /// @return balance of account
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @notice Simple function that a requester can use to get their own balance
    /// @return balance of requester
    function myBalance() public view returns (uint256) {
        return _balances[msg.sender];
    }

    /// @notice Simple function that can be used to get the global request limit
    /// @return balance of requester
    function requestLimit() public view returns (uint16) {
        return _requestLimit;
    }

    /// @notice Helper function that checks if a given request is null
    /// @param inrequest the request being checked
    /// @return requestnotempty which is boolean
    function isNotEmpty(request memory inrequest) internal pure returns (bool) {
        return inrequest.amount != 0 && inrequest.endtime != 0;
    }

    /// @notice Function to get the request expiry of an existing transaction
    /// @param requester of the request
    /// @param recipient of the request
    /// @return requestExpiry of request
    function getRequestExpiry(
        address requester,
        address recipient
    ) public view returns (uint256) {
        require(
            isNotEmpty(_requests[requester][recipient]),
            "MSERC20: No request found"
        );
        return _requests[requester][recipient].endtime;
    }

    /// @notice Function that returns how many requests that you have made
    function getRequestCount() public view returns (uint32) {
        return _requestcount[msg.sender];
    }

    /// @notice Function to get the request amount of an existing transaction
    /// @param requester the person paying
    /// @param recipient the person being paid
    /// @return requestAmount of request
    function getRequestAmount(
        address requester,
        address recipient
    ) public view returns (uint256) {
        require(
            isNotEmpty(_requests[requester][recipient]),
            "MSERC20: No request found"
        );
        return _requests[requester][recipient].amount;
    }

    /// @notice Main transfer request, this will simply call the internal function _maketransfer
    /// @param recipient the person being paid
    /// @param amount the amount
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _maketransfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Function used to transfer on someone elses behalf. This emits the AllowanceTransfer event
    /// @param _from the paying account
    /// @param _to the account getting paid
    /// @param _value the amount
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            _from != msg.sender,
            "MSERC20: Incorrect method for transfer from own account, use `transfer` instead."
        );
        //check if sender is on the allowance list
        require(
            _allowances[_from][msg.sender] > 0,
            "MSERC20: Sender not on the allowanace list, Or approve is still pending"
        );
        require(
            _allowances[_from][msg.sender] > _value,
            "MSERC20: Sender's allowence is not high enough"
        );
        _maketransfer(_from, _to, _value);
        _allowances[_from][msg.sender] -= _value; //decrease their allowance
        emit AllowanceTransfer(_from, msg.sender, _to, _value);
        return true;
    }

    /// @notice Internal function that actually does the transfer logic, this function is not overridable by design. This emits the Transfer event
    /// @param sender the person paying
    /// @param recipient the person being paid
    /// @param amount the amount
    function _maketransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            isNotEmpty(_requests[recipient][sender]),
            "MSERC20: No request found"
        );
        require(
            _requests[recipient][sender].amount == amount,
            "MSERC20: Request amounts do not match"
        );
        require(
            _balances[sender] >= amount,
            "MSERC20: transfer amount exceeds balance"
        );
        assert(amount >= 0); // is an assert since we know the requests cant be 0s
        assert(recipient != sender); // is an assert since we know the requests cant have this issue
        if (_requests[recipient][sender].endtime < block.timestamp) {
            _removeRequest(recipient, sender);
            revert("MSERC20: Request has expired");
        }
        //overflow and underflow impossible
        //do the transfer
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _removeRequest(recipient, sender);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /// @notice Makes a new request from the caller of the contract to the requetee. This emits the NewRequest event
    /// @param requestee the person requesting contract caller is requesting payment from
    /// @param amount amount of the payment
    /// @param time the expiry of the request
    function addNewRequest(
        address requestee,
        uint256 amount,
        uint256 time
    ) public returns (bool) {
        require(
            _requestcount[msg.sender] + 1 <= _requestLimit,
            "MSERC20: Max requests reached"
        );
        require(time > block.timestamp, "MSERC20: Time is in the past");
        require(
            time < block.timestamp + 86400,
            "MSERC20: Time is too far in the future, Cannot be more then 24 hours"
        );
        require(
            time > block.timestamp + 600,
            "MSERC: Time must be at least 10 minutes in the future"
        );
        require(
            !isNotEmpty(_requests[msg.sender][requestee]),
            "MSERC20: Request for this account already exists"
        );
        require(
            requestee != msg.sender,
            "MSERC20: Cannot make a request to yourself"
        );
        require(amount > 0, "MSERC20: Amount cant be 0");
        assert(amount >= 0);
        _requestcount[msg.sender]++;
        _requests[msg.sender][requestee] = request(amount, time);
        emit NewRequest(msg.sender, requestee, amount);
        return true;
    }

    /// @notice Helper function that is used to remove a request from the requests array. This emits the RemoveRequest event
    /// @param requester the person who is requesting payment
    /// @param recipient the person having payment requested from
    function _removeRequest(
        address requester,
        address recipient
    ) internal returns (bool) {
        require(
            isNotEmpty(_requests[requester][recipient]),
            "MSERC20: no requests for recipient"
        );
        assert(requester != address(0));
        delete _requests[requester][recipient];
        _requestcount[requester]--;
        emit RemoveRequest(msg.sender, requester, recipient);
        return true;
    }

    /// @notice Function that is called to remove a request from the pool, this can be either the requester or the recipient.
    /// This will simply return the internal _removeRequest function
    /// @param requester the person who is requesting payment
    /// @param recipient the person having payment requested from
    function removeRequest(
        address requester,
        address recipient
    ) public returns (bool) {
        require(
            requester == msg.sender || recipient == msg.sender,
            "MSERC20: Cannot delete someone elses request"
        );
        _removeRequest(requester, recipient);
        return true;
    }

    /// @notice Function that dictates how much someone else can spend on your behalf.
    /// Value must first be set to 0 to prevent a race condition
    /// @param _spender the person who is spending on anothers behalf
    /// @param _value the approved amount to be spent
    function approve(
        address _spender,
        uint256 _value
    ) public override returns (bool success) {
        require(
            _allowances[msg.sender][_spender] == 0 || _value == 0,
            "MSERC20: Amount must first be set to 0 before changing"
        ); //version of compare and swap, prevents race condition
        require(msg.sender != _spender, "MSERC20: Cannot set own allowance");
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Simple function that returns the current allowance allocated to a person
    /// @param _owner the person who is going to pay
    /// @param _spender the person who has permission to use funds from the others account
    function allowance(
        address _owner,
        address _spender
    ) public view override returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    /// @notice Event that is fired when a new request is made
    /// @param sender the person who is requesting payment
    /// @param recipient the person having payment requested from
    /// @param amount the amount being requested
    event NewRequest(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    /// @notice Event that is fired when a request is removed
    /// @param actualSender the person calling this contract
    /// @param sender the person who is requesting payment
    /// @param recipient the person having payment requested from
    event RemoveRequest(
        address indexed actualSender,
        address indexed sender,
        address indexed recipient
    );

    /// @notice Event that is fired when someone makes a transfer on someone elses behalf
    /// @param accholder the account holder
    /// @param sender the person calling this contract
    /// @param recipient the person who is receiving money
    /// @param amount the amount being transfered
    event AllowanceTransfer(
        address indexed accholder,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );
}