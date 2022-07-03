/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

contract TokenERC20 {
    // Public variables of the token
    string public _name;
    string public _symbol;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    uint256 public decimals;

    // This creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        uint256 t_decimals,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        decimals = t_decimals;
        totalSupply = initialSupply * 10**decimals; // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
        _name = tokenName; // Set the name for display purposes
        _symbol = tokenSymbol; // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        _transfer2(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value * 10**decimals);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        balanceOf[msg.sender] -= _value; // Subtract from the sender
        totalSupply -= _value; // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[_from] >= _value); // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        balanceOf[_from] -= _value; // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value; // Subtract from the sender's allowance
        totalSupply -= _value; // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    function getBalanceOf(address user) external view returns (uint256) {
        return balanceOf[user];
    }

    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    mapping(address => uint256) public ammountFreezed;
    mapping(address => uint256) public ammountUnreleased;
 
    struct lock {
        address sender;
        address reciever;
        uint256 ammount;
        bool approved; //to be performed by reciever
        bool completed;
    }
    lock[] private pending_tnx;

    function lock_request(address reciever, uint256 ammount)
        public
        returns (uint256)
    {
        uint256 index = pending_tnx.length;
        pending_tnx[index].sender = msg.sender;
        pending_tnx[index].ammount = ammount * 10**decimals;
        pending_tnx[index].reciever = reciever;
        return index;
    }

    function lock_approve(uint256 index, uint256 ammount) public {
        require(msg.sender == pending_tnx[index].reciever);
        require(ammount == pending_tnx[index].ammount);
        pending_tnx[index].approved = true;
        lock_money(index);
    }

    function lock_money(uint256 index) private returns (bool) {
        uint256 ammount = pending_tnx[index].ammount;
        address reciever = pending_tnx[index].reciever;
        address sender = pending_tnx[index].sender;
        require(balanceOf[sender] >= ammount); //checks underflow
        balanceOf[sender] -= ammount;
        require(balanceOf[reciever] >= ammount / 10); //checks underflow
        balanceOf[reciever] -= (ammount / 10);
        require(ammountFreezed[sender] + ammount > ammountFreezed[sender]); //checks overflow
        ammountFreezed[sender] += ammount;
        require(
            ammountFreezed[reciever] + (ammount / 10) > ammountFreezed[reciever]
        ); //checks overflow
        ammountFreezed[reciever] += ammount / 10;

        return true;
    }

    function release_money(uint256 index) public returns (bool) {
        require(pending_tnx[index].sender == msg.sender);
        require(pending_tnx[index].approved);
        uint256 ammount = pending_tnx[index].ammount;
        address sender = pending_tnx[index].sender;
        address reciever = pending_tnx[index].reciever;
        unchecked {
            ammountFreezed[sender] -= ammount;
            ammountFreezed[reciever] -= (ammount / 10);
        }
        pay(reciever, ammount + (ammount / 10));

        pending_tnx[index].completed = true;
        emit Transfer(sender, reciever, ammount);

        return true;
    }

    function reject_money(uint256 index) public returns (bool) {
        require(pending_tnx[index].reciever == msg.sender);
        require(pending_tnx[index].approved);
        uint256 ammount = pending_tnx[index].ammount;
        address sender = pending_tnx[index].sender;
        address reciever = pending_tnx[index].reciever;
        unchecked {
            ammountFreezed[sender] -= ammount;
            ammountFreezed[reciever] -= (ammount / 10);
        }
        pay(reciever, ammount / 10);
        pay(sender, ammount);

        pending_tnx[index].completed = true;
        return true;
    }

    function releaseAmmount(uint256 value) public {
        require(ammountUnreleased[msg.sender] >= value);
        require(balanceOf[msg.sender] + value > balanceOf[msg.sender]);
        ammountUnreleased[msg.sender] -= value;
        balanceOf[msg.sender] += value;
    }

    function pay(address _to, uint256 _value) private {
        require(_to != address(0x0));

        if (balanceOf[_to] + (_value) > balanceOf[_to]) {
            balanceOf[_to] = balanceOf[_to] + (_value);
        } else {
            if (ammountUnreleased[_to] + (_value) > ammountUnreleased[_to]) {
                ammountUnreleased[_to] += (_value);
            } else {
                unchecked {
                    uint temp = ammountUnreleased[_to] + (_value);
                    totalSupply -= (temp + 1);
                    ammountUnreleased[_to] =
                        ammountUnreleased[_to] +
                        (_value) -
                        (temp + 1);
                }
            }
        }
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function _transfer2(
        address from,
        address to,
        uint256 value
    ) private {
        require(balanceOf[from] >= value);
        balanceOf[from] -= value;
        pay(to, value);
    }
}