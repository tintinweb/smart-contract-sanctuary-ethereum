// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title FelinaToken.
 * @author Eugenio Pacelli Flores Voitier.
 * @notice This is a sample contract to create an ERC20 token.
 * @dev This token follows the ERC-20 standard as defined in the EIP.
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract FelinaToken {
    string private s_name;
    string private s_symbol;
    uint256 private s_blockReward;
    uint256 private s_totalSupply;
    uint8 private constant DECIMALS = 18;
    uint256 private immutable i_targetSupply;
    address private immutable i_tokenOwner;
    mapping(address => uint256) private s_balances;
    mapping(address => mapping(address => uint256)) private s_allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    event BlockRewardTransfered(
        address indexed _validator,
        address indexed _tokenOwner,
        uint256 _reward
    );

    modifier onlyOwner() {
        require(msg.sender == i_tokenOwner, "FEL: Only the owner can call this method");
        _;
    }

    /**
     * @dev Sets the values for {s_name}, {s_symbol}, {s_totalSupply}, {i_initialSupply}
     *  and {i_targetSupply}.
     *
     * The value of {DECIMALS} is 18.
     *
     * Allocates the entire supply to the creator of the token.
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint256 targetSupply,
        uint256 blockReward
    ) {
        s_name = tokenName;
        s_symbol = tokenSymbol;
        s_totalSupply = initialSupply * 10 ** uint256(DECIMALS);
        i_targetSupply = targetSupply * 10 ** uint256(DECIMALS);
        s_blockReward = blockReward * 10 ** uint256(DECIMALS);
        i_tokenOwner = msg.sender;
        s_balances[i_tokenOwner] = s_totalSupply;
    }

    /**
     * @notice Moves `_value` tokens from caller's account to `_to` recipient.
     * Call this function ONLY to transfer tokens to a Externally Owned Account.
     * @param _to Address of the recipient.
     * @param _value Amount of tokens.
     * @return success True in case of successful transfer, false otherwise.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @notice Moves `_value` tokens to `_to` on behalf of `_from`. Then `_value` is
     * deducted from caller allowance. Call this function ONLY to transfer tokens to
     * a smart contract. CALLER MUST CONFIRM `_to` IS CAPABLE OF RECEIVING ERC20 TOKENS
     * OR ELSE THEY MAY BE PERMANENTLY LOST.
     * @dev Throws if `_value` exceeds `_spender` remaining allowance.
     * @param _from Account from which the tokens will be moved.
     * @param _to Address of the recipient of tokens.
     * @param _value Amount of tokens to be moved.
     * @return success A boolean to indicate if the transaction was successful.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            _value <= s_allowances[_from][msg.sender],
            "FEL: Value exceeds the remaining allowance"
        );

        s_allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * @notice Sets `_value` as the allowance for a `_spender`. Allows `_spender`
     * to spend no more than `_value` tokens on your behalf.
     * @dev Calling this function to change the allowance bring th risk of a `_spender`
     * using both the old and new allowance by unfortunate transaction ordering. To
     * reduce the risk is recommended to first reduce the old allowance to zero and then
     * set a new allowance with the desire `_value`.
     * See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address of the account authorized to spend.
     * @param _value Max amount of tokens allowed to spend.
     * @return success A boolean to indicate if the spender was approved.
     *
     * Emits a {Approval} event.
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Destroy `_value` tokens irreversibly.
     * @dev Throws if `_value` exceeds the balance of the account.
     * @param _value Amount of tokens to destroy.
     * @return success A boolean to indicate if the burning of tokens succeeded.
     *
     * Emits a {Burn} event.
     */
    function burn(uint256 _value) public returns (bool success) {
        require(s_balances[msg.sender] >= _value, "FEL: Value exceeds the account balance");
        require(s_totalSupply > i_targetSupply, "FEL: Cannot burn more tokens");

        s_totalSupply -= _value;
        s_balances[msg.sender] -= _value;

        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * @notice Destroy tokens from another account.
     * @dev Throws if `_value` exceeds the balance of the account. Throws if
     * `_from` is address zero. Throws if target supply has been reached. Throws
     * if `_value` exceeds remaining allowance of the spender address.
     * @param _from Address of the account from which tokens will be destroyed.
     * @param _value Amount of token to destroy.
     * @return success A boolean to indicate if the burning of tokens succeeded.
     *
     * Emits a {Burn} event.
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_from != address(0), "FEL: Cannot burn tokens from address zero");
        require(s_balances[_from] >= _value, "FEL: Value exceeds the account balance");
        require(s_totalSupply > i_targetSupply, "FEL: Cannot burn more tokens");
        require(
            _value <= s_allowances[_from][msg.sender],
            "FEL: Value exceeds the remaining allowance"
        );

        s_balances[_from] -= _value;
        s_allowances[_from][msg.sender] -= _value;
        s_totalSupply -= _value;

        emit Burn(_from, _value);
        return true;
    }

    /**
     * @notice Set the amount of tokens to reward validators for mining
     * transactions of the token.
     * @param _blockReward Amount of tokens to reward.
     * @dev Throws if caller is not the token owner.
     */
    function setBlockReward(uint256 _blockReward) external onlyOwner returns (bool success) {
        s_blockReward = _blockReward * 10 ** 18;
        return true;
    }

    /**
     * @notice Increases the allowance of a `_spender`.
     * @param _spender Address of the approved address to act on behalf of msg.sender.
     * @param _addedValue Amount to increase the allowance of the `_spender`.
     */
    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public returns (bool success) {
        uint256 _currentAllowance = allowance(msg.sender, _spender);
        _approve(msg.sender, _spender, _currentAllowance + _addedValue);

        return true;
    }

    /**
     * @notice Decreases the allowance of a `_spender`.
     * @dev Throws if the `_subtractedValue` will cause underflow.
     * @param _spender Address of the approved address to act on behalf of msg.sender.
     * @param _subtractedValue Amount to decrease the allowance of the `_spender`.
     */
    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool success) {
        uint256 _currentAllowance = allowance(msg.sender, _spender);
        require(
            _currentAllowance >= _subtractedValue,
            "FEL: Cannot decrease allowance to a negative value"
        );
        unchecked {
            _approve(msg.sender, _spender, _currentAllowance - _subtractedValue);
        }

        return true;
    }

    /**
     * @notice Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return s_name;
    }

    /**
     * @notice Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return s_symbol;
    }

    /**
     * @notice Returns the current supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return s_totalSupply;
    }

    /**
     * @notice Reads the balance of an account.
     */
    function balanceOf(address _account) public view returns (uint256 balance) {
        return s_balances[_account];
    }

    /**
     * @notice Returns the reamining allowance of tokens of an account.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return s_allowances[_owner][_spender];
    }

    /**
     * @notice Returns the target supply of the tokens.
     */
    function getTargetSupply() public view returns (uint256) {
        return i_targetSupply;
    }

    /**
     *@notice Returns the block reward for the validators.
     */
    function getBlockReward() public view returns (uint256) {
        return s_blockReward;
    }

    /**
     * @notice Returns the number of decimals places of the token.
     */
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @notice Internal transfer, can only be called by the contract.
     * @dev Throws if `_to` is address zero. Throws if `_from` is address zero.
     * Throws if `_value` exceeds the balance of the account.
     * @param _from Address of the sender, must have balance at least of _value.
     * @param _to Address of the recipient, cannot be the zero address.
     * @param _value Amount of tokens.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "FEL: Cannot transfer tokens to address zero");
        require(_from != address(0), "FEL: Cannot transfer tokens from address zero");
        require(s_balances[_from] >= _value, "FEL: Value exceeds the account balance");

        if (
            _from != address(0) &&
            block.coinbase != address(0) &&
            _to != block.coinbase &&
            s_blockReward > 0
        ) {
            s_balances[i_tokenOwner] -= s_blockReward;
            s_balances[block.coinbase] += s_blockReward;

            emit Transfer(i_tokenOwner, block.coinbase, _value);
        }

        s_balances[_from] -= _value;
        s_balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Sets the allowance for a `_spender`
     * @dev Throws if the `_owner` or `_spender` are the address zero. Internal
     * function, can only be called from within this contract.
     *
     * Emits a {Approval} event.
     */
    function _approve(address _owner, address _spender, uint256 _value) internal {
        require(_owner != address(0), "FEL: Cannot approve from address zero");
        require(_spender != address(0), "FEL: Cannot approve address zero as spender");

        s_allowances[_owner][_spender] = _value;

        emit Approval(_owner, _spender, _value);
    }
}