//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

/// @title MAERC-20 Fungible Token
/// @author Mad Aekauq @stheg
contract MAERC20 {

    string public name;
    string public symbol;
    uint8 constant public decimals = 2;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    //from => spender => value
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed from, 
        address indexed spender, 
        uint256 value
    );

    constructor(string memory tokenName, string memory tokenSymbol) {
        name = tokenName;
        symbol = tokenSymbol;
    }

    /// @notice Checks if enough tokens exist on the balance
    modifier checkBalance(address addr, uint256 value) {
        require(balanceOf[addr] >= value, "No enough tokens");
        _;
    }

    /// @notice Checks if the specified address isn't the Zero-Address
    modifier verifyAddress(address addr) {
        require(addr != address(0), "The zero-address is not allowed.");
        _;
    }

    /// @notice Allows to get the amount which `spender` is still allowed
    /// to withdraw from `owner`
    /// @return remaining amount which can be spent by `spender`  
    function allowance(address owner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[owner][spender];
    }

    /// @notice Transfers `value` amount of tokens to address `to` 
    /// and emits the `Transfer` event
    /// @param to address of the recipient
    /// @param value amount of tokens
    /// @return success result of the operation 
    function transfer(address to, uint256 value) 
        public
        returns (bool success) 
    {
        _transferOrThrow(msg.sender, to, value);
        return true;
    }

    /// @notice If it's allowed, transfers `value` amount of tokens 
    /// from address `from` to address `to` and emits the `Transfer` event
    /// @param from address of the source
    /// @param to address of the recipient
    /// @param value amount of tokens
    /// @return success result of the operation 
    function transferFrom(address from, address to, uint256 value) 
        public 
        returns (bool success) 
    {
        if (msg.sender != from) {
            require(
                _allowances[from][msg.sender] >= value, 
                "No enough approved amount"
            );
            _allowances[from][msg.sender] -= value;
        }

        _transferOrThrow(from, to, value);
        return true;
    }

    /// @notice Approves `spender` to withdraw and to transfer 
    /// `value` amount of tokens from the sender's balance 
    /// and emits the `Approval` event 
    /// @param spender someone's address who will be approved to withdraw
    /// @param value amount of token available for withdrawing
    /// @return success result of the operation 
    function approve(address spender, uint256 value) 
        public
        verifyAddress(spender) 
        returns (bool success) 
    {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @notice Mints some amount of tokens according to `msg.value`
    /// and adds it to the sender's balance, increasing the total supply
    function mint() public payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
    }

    /// @notice Burns tokens from the sender's balance, 
    /// decreasing the total supply of the token,
    /// and transfers Ethers back to the sender
    /// @param value amount of tokens to burn
    function burn(uint value) public checkBalance(msg.sender, value) {
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        payable(msg.sender).transfer(value);
    }

    /// @dev Makes sure that the balance of `from` is enough to send
    /// `value` tokens, changes balances and emits the `Transfer` event,
    /// otherwise it throws an error 
    function _transferOrThrow(address from, address to, uint256 value)
        private
        verifyAddress(from)
        verifyAddress(to)
        checkBalance(from, value)
    {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}