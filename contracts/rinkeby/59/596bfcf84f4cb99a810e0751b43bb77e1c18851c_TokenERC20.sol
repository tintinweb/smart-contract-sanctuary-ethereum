/**
 *Submitted for verification at Etherscan.io on 2022-06-13
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
    // Public variables - stored in Storage 
    string public name;
    string public symbol;
    uint8 public decimals = 18;  // 18 deciamls is recommended
    uint256 public totalSupply;

    // Mapping - creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // This generates a public event on the blockchain
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed from, uint256 value); // This tells clients the amount of tokens burnt

    constructor(
        uint256 initialSupply, 
        string memory tokenName,
        string memory tokenSymbol   
    ) {
        totalSupply = initialSupply * 10**uint256(decimals);  // 1000_00000000_0000000000 
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    /**
        * Only can be called by the contract
        * Internal Visibility
    */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0x0)); // Prevent transfer to 0x0 address. Use burn() method  
        // if _to != address(0x0) {}
        require(balanceOf[_from] >= _value); // Check if the sender has enough money
        require(balanceOf[_to] + _value >= balanceOf[_to]); // check for overflows 
        
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to]; // Save this for an assertion in the future

        balanceOf[_from] -= _value; // Substract the balance from the sender by the amount he/she sends
        balanceOf[_to] += _value; // Receive the amount

        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); // Never fails
    }

    /**
     * name transfer
     * @param _to - The address of the recipient
     * @param _value - the amount of money that receives
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
      * name transferFrom
      * transfer tokens from other address
      * @param _from The address of the sender
      * @param _to The address of the recipient
      * @param _value the amount to send
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    

    /**
     * Set allowance for other address
     * @param _spender the address authorized to spend
     * @param _value the max amount they can spend
    */
    function approve(address _spender, uint256 _value)  public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     * @param _spender The address authorized to spend
     * @param _value the max amount they can sepnd
     * @param _extraData some extra information to send  to the approved contract
    */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return  true;
        }
    }

    /**
        Destroy tokens

        @param _value the amount of tokens to burn
    */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough tokens
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value; // update totalsupply
        emit Burn(msg.sender, _value);
        return true;
    }


    /**
    * Destroy tokens from other account
    * @param _from the address of the sender
    * @param _value the amount of tokens to burn
    */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }


}