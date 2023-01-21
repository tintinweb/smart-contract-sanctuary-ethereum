/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
}

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(

    ) public {
    }

    function checkInt25NegotiveValue(int256 param) public pure returns (uint256, int256) {
        uint256 retValUint;
        int256 retValInt = param;
        retValInt = 0 - retValInt;
        retValUint = uint256(retValInt);
        return (retValUint, retValInt);
    }

    function checkInt25PositiveValue(int256 param) public pure returns (uint256) {
        uint256 retVal;
        retVal = uint256(param);
    }
}