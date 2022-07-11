/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.4.21;


contract EIP20Interface {
    
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


pragma solidity ^0.4.21;

contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
pragma solidity ^0.4.21;
contract EIP20Factory {
    mapping(address => address[]) public created;
    mapping(address => bool) public isEIP20; //verify without having to do a bytecode check.
    bytes public EIP20ByteCode; // solhint-disable-line var-name-mixedcase

    function EIP20Factory() public {
        //upon creation of the factory, deploy a EIP20 (parameters are meaningless) and store the bytecode provably.
        address verifiedToken = createEIP20(10000, "Verify Token", 3, "VTX");
        EIP20ByteCode = codeAt(verifiedToken);
    }

    //verifies if a contract that has been deployed is a Human Standard Token.
    //NOTE: This is a very expensive function, and should only be used in an eth_call. ~800k gas
    function verifyEIP20(address _tokenContract) public view returns (bool) {
        bytes memory fetchedTokenByteCode = codeAt(_tokenContract);

        if (fetchedTokenByteCode.length != EIP20ByteCode.length) {
            return false; //clear mismatch
        }

      //starting iterating through it if lengths match
        for (uint i = 0; i < fetchedTokenByteCode.length; i++) {
            if (fetchedTokenByteCode[i] != EIP20ByteCode[i]) {
                return false;
            }
        }
        return true;
    }

    function createEIP20(uint256 _initialAmount, string _name, uint8 _decimals, string _symbol)
        public
    returns (address) {

        EIP20 newToken = (new EIP20(_initialAmount, _name, _decimals, _symbol));
        created[msg.sender].push(address(newToken));
        isEIP20[address(newToken)] = true;
        //the factory will own the created tokens. You must transfer them.
        newToken.transfer(msg.sender, _initialAmount);
        return address(newToken);
    }

    //for now, keeping this internal. Ideally there should also be a live version of this that
    // any contract can use, lib-style.
    //retrieves the bytecode at a specific address.
    function codeAt(address _addr) internal view returns (bytes outputCode) {
        assembly { // solhint-disable-line no-inline-assembly
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using outputCode = new bytes(size)
            outputCode := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(outputCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(outputCode, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(outputCode, 0x20), 0, size)
        }
    }
}