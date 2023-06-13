// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

//errors
error Token_NotEnoughFunds();
error Token_NotAllow();

// Interface, Libraries, Contracts
/**
 * @title A contrat for an ICO
 * @author Gabriel ANDREI
 * @notice This contract is a demo, built during my training process
 */
contract Token {
    //Type declarations
    struct TokenStruct {
        uint256 _tokenId;
        address _from;
        address _to;
        uint256 _totalToken;
        bool _hasToken;
    }
    /*State variable */
    string public s_name;
    string public s_symbol;
    uint8 public constant DECIMALS = 18;
    uint256 public s_totalSupply;
    uint256 public s_userId;
    address public s_ownerOfContract;
    address[] public s_holders;

    mapping(address => TokenStruct) public tokenHolders;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /*Events*/
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /**Constructor */
    constructor(
        uint256 _initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        s_ownerOfContract = msg.sender;
        //s_totalSupply = initialSupply * 10**uint256(DECIMALS); // Update total supply with the decimal amount
        balanceOf[msg.sender] = _initialSupply;
        s_totalSupply = _initialSupply;
        s_name = tokenName; // Set the name for display purposes
        s_symbol = tokenSymbol; // Set the symbol for display purposes
    }

    /** Functions */
    function inc() internal {
        s_userId++;
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert Token_NotEnoughFunds();
        inc();
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        //update tokenHolders
        tokenHolders[_to]._tokenId = s_userId;
        tokenHolders[_to]._to = _to;
        tokenHolders[_to]._from = msg.sender;
        tokenHolders[_to]._totalToken = _value;
        tokenHolders[_to]._hasToken = true;

        s_holders.push(_to);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
        if (_value > allowance[_from][msg.sender]) {
            revert Token_NotAllow();
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /*View Pure functions */

    function getToken(
        address _address
    ) public view returns (uint256, address, address, uint256, bool) {
        return (
            tokenHolders[_address]._tokenId,
            tokenHolders[_address]._to,
            tokenHolders[_address]._from,
            tokenHolders[_address]._totalToken,
            tokenHolders[_address]._hasToken
        );
    }

    function getTokenHolders() public view returns (address[] memory) {
        return s_holders;
    }
}