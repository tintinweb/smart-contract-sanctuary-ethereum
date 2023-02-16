// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SignerVerifiable.sol";

contract Battling is SignerVerifiable {
    struct Battle {
        address player_one;
        address player_two;
        address player_one_referral_address;
        address player_two_referral_address;
        address token_address;
        uint value;
        bool cancelled;
        bool paid;
    }

    struct FuncParams {
        bytes _signature;
        uint256 _amount;
        uint256 _deadline;
        string _message;
        string _battle_id;
        address _erc20_token;
        address _player_referral_address;
    }

    mapping(address => int) public total_wagered_under_account_code;

    mapping(string => Battle) public battle_contestants;
    mapping(address => bool) public erc20_token_supported;
    mapping(address => address) public token_to_aggregator_address;

    mapping(address => uint) public partnership_fee_tier;

    bool public contract_frozen = false;
    
    // MODIFY THESE WHEN DEPLOYING THE CONTRACT
    address public SIGNER = 0x950bb768cEda61410E451520aBc138d7700D249B;
    address public TREASURY = 0x064bfB0820e6c4ADCAA34086729995d6fD21823E;

    uint256 public battle_fee_precent = 10;
    uint256 public reduced_battle_fee_percent = 5;

    address public OWNER;

    // MODIFIERS
    
    function _onlyOwner() internal view {
        require(msg.sender == OWNER || msg.sender == SIGNER, "Caller is not the owner");
    }
    
    function _isCallerVerified(uint256 _amount, string calldata _message, string calldata _battle_id, uint256 _deadline, address _erc20_token, address _player_referral_address, bytes calldata _signature) internal {
        require(msg.sender == tx.origin, "No smart contract interactions allowed");
        require(!contract_frozen, "Contract is paused");
        require(decodeSignature(msg.sender, _amount, _message, _battle_id, _deadline, _erc20_token, _player_referral_address, _signature) == SIGNER, "Call is not authorized");
    }

    // END MODIFIERS

    constructor () {
        OWNER = msg.sender;
    }

    // AUTHORIZED FUNCTIONS
    function initiateBattleERC20(FuncParams calldata fp) external {
        _isCallerVerified(fp._amount, fp._message, fp._battle_id, fp._deadline, fp._erc20_token, fp._player_referral_address, fp._signature);
        
        require(battle_contestants[fp._battle_id].player_one == address(0) || battle_contestants[fp._battle_id].player_two == address(0), "Battle is full");
        require(!battle_contestants[fp._battle_id].cancelled, "Battle was cancelled");

        if (battle_contestants[fp._battle_id].value == 0) { // battle creation
            require(fp._amount > 0, "Amount must be greater than 0");
            require(erc20_token_supported[fp._erc20_token], "Token is not supported");
            battle_contestants[fp._battle_id].value = fp._amount;
            battle_contestants[fp._battle_id].token_address = fp._erc20_token;
        } else { // battle joining
            require(battle_contestants[fp._battle_id].player_one != msg.sender, "Cannot join own battle");
            require(battle_contestants[fp._battle_id].value == fp._amount, "Incorrect value sent to battle");
            require(battle_contestants[fp._battle_id].token_address == fp._erc20_token, "Wrong token");
        }

        ERC20(fp._erc20_token).transferFrom(msg.sender, address(this), fp._amount);
        
        if (battle_contestants[fp._battle_id].player_one == address(0)) {
            battle_contestants[fp._battle_id].player_one = msg.sender;
            battle_contestants[fp._battle_id].player_one_referral_address = fp._player_referral_address;
        } else {
            battle_contestants[fp._battle_id].player_two = msg.sender;
            battle_contestants[fp._battle_id].player_two_referral_address = fp._player_referral_address;
        }
    }

    function initiateBattleETH(FuncParams calldata fp) external payable {
        _isCallerVerified(msg.value, fp._message, fp._battle_id, fp._deadline, address(0), fp._player_referral_address, fp._signature);
        require(battle_contestants[fp._battle_id].player_one == address(0x0) || battle_contestants[fp._battle_id].player_two == address(0x0), "Battle is full");
        require(!battle_contestants[fp._battle_id].cancelled, "Battle was cancelled");
        
        if (battle_contestants[fp._battle_id].value == 0) { // battle creation
            require(msg.value > 0, "Amount must be greater than 0");
            battle_contestants[fp._battle_id].value = msg.value;
        } else { // battle joining
            require(battle_contestants[fp._battle_id].player_one != msg.sender, "Cannot join own battle");
            require(battle_contestants[fp._battle_id].value == msg.value, "Incorrect value sent to battle");
        }

        if (battle_contestants[fp._battle_id].player_one == address(0)) {
            battle_contestants[fp._battle_id].player_one = msg.sender;
            battle_contestants[fp._battle_id].player_one_referral_address = fp._player_referral_address;
        } else {
            battle_contestants[fp._battle_id].player_two = msg.sender;
            battle_contestants[fp._battle_id].player_two_referral_address = fp._player_referral_address;
        }
    }
    
    function claimWinnings(FuncParams calldata fp) external {
        unchecked {
            _isCallerVerified(battle_contestants[fp._battle_id].value, fp._message, fp._battle_id, fp._deadline, battle_contestants[fp._battle_id].token_address, fp._player_referral_address, fp._signature);
            require(!battle_contestants[fp._battle_id].paid, "Rewards already claimed for battle");
            require(!battle_contestants[fp._battle_id].cancelled, "Battle was cancelled, cannot claim winnings");
            require(battle_contestants[fp._battle_id].player_one == msg.sender || battle_contestants[fp._battle_id].player_two == msg.sender, "User is not in this battle");
            
            battle_contestants[fp._battle_id].paid = true;

            uint battle_value = 2 * battle_contestants[fp._battle_id].value;

            address ref = fp._player_referral_address;
            
            // Use the reduced fee if there is a referral code present, otherwise use the normal fee
            uint fee_to_use = ref != address(0) ? reduced_battle_fee_percent : battle_fee_precent;
            
            if (ref == address(0)) ref = TREASURY;

            address token_address = battle_contestants[fp._battle_id].token_address;

            // ETH wagers
            if (token_address == address(0)) {
                uint amount_owed_to_winner = battle_value * (100 - fee_to_use) / 100;
                uint amount_owed_to_ref = _calculateRefOwedAmount(ref, battle_value * fee_to_use / 100);
                uint amount_owed_to_treasury = battle_value * fee_to_use / 100 - amount_owed_to_ref;

                // transfer winnings to user
                payable(msg.sender).transfer(amount_owed_to_winner);

                // transfer referral designated amount
                if (amount_owed_to_ref > 0) payable(ref).transfer(amount_owed_to_ref);

                // transfer treasury designated amount
                if (amount_owed_to_treasury > 0) payable(TREASURY).transfer(amount_owed_to_treasury);

                // Update referral wager balance, if the token has a corresponding aggregator address
                if (token_to_aggregator_address[token_address] != address(0)) {
                    int latest_price = getLatestPrice(token_address);
                    total_wagered_under_account_code[battle_contestants[fp._battle_id].player_one_referral_address] += int(battle_value / 2) * latest_price / _pow(18);
                    total_wagered_under_account_code[battle_contestants[fp._battle_id].player_two_referral_address] += int(battle_value / 2) * latest_price / _pow(18);
                }

            } else { // ERC20 wagers
                uint amount_owed_to_winner = battle_value * (100 - fee_to_use) / 100;
                uint amount_owed_to_ref = _calculateRefOwedAmount(ref, battle_value * fee_to_use / 100);
                uint amount_owed_to_treasury = battle_value * fee_to_use / 100 - amount_owed_to_ref;

                // transfer winnings to user
                ERC20(token_address).transfer(msg.sender, amount_owed_to_winner);

                // transfer referral designated amount
                if (amount_owed_to_ref > 0) ERC20(token_address).transfer(ref, amount_owed_to_ref);

                // transfer treasury designated amount
                if (amount_owed_to_ref > 0) ERC20(token_address).transfer(TREASURY, amount_owed_to_treasury);

                // Update referral wager balance, if the token has a corresponding aggregator address
                if (token_to_aggregator_address[token_address] != address(0)) {
                    int latest_price = getLatestPrice(token_address);
                    total_wagered_under_account_code[battle_contestants[fp._battle_id].player_one_referral_address] += int(battle_value / 2) * latest_price / _pow(ERC20(token_address).decimals());
                    total_wagered_under_account_code[battle_contestants[fp._battle_id].player_two_referral_address] += int(battle_value / 2) * latest_price / _pow(ERC20(token_address).decimals());
                }
            }
        }
    }

    function cancelBattle(FuncParams calldata fp) external {
        _isCallerVerified(battle_contestants[fp._battle_id].value, fp._message, fp._battle_id, fp._deadline, battle_contestants[fp._battle_id].token_address, fp._player_referral_address, fp._signature);
        uint value = battle_contestants[fp._battle_id].value;

        require(value > 0, "Battle does not exist");
        require(!battle_contestants[fp._battle_id].cancelled, "Battle was already cancelled");
        require(!battle_contestants[fp._battle_id].paid, "Battle was already paid");
        require(battle_contestants[fp._battle_id].player_one == msg.sender && battle_contestants[fp._battle_id].player_two == address(0), "Cannot cancel this battle");

        battle_contestants[fp._battle_id].cancelled = true;

        address token_address = battle_contestants[fp._battle_id].token_address;

        if (token_address == address(0)) {
            payable(msg.sender).transfer(value);
        } else {
            ERC20(token_address).transfer(msg.sender, value);
        }
    }


    // END AUTHORIZED FUNCTIONS



    // REFERRAL CODE FUNCTIONS


    function _pow(uint8 _exponent) internal pure returns(int) {
        return int(10 ** _exponent);
    }

    // Get the fee portion owed to the referral address by computing the accumulated wagers under their code
    function _calculateRefOwedAmount(address _ref_address, uint _fee_amount) internal view returns(uint) {
        if (_ref_address == address(0) || _ref_address == TREASURY) return 0;
        if (partnership_fee_tier[_ref_address] > 0) {
            return 5 * partnership_fee_tier[_ref_address] * _fee_amount / 100;
        }

        uint[9] memory REFERRAL_TIERS_AMT_REQUIRED = [uint(2_000), uint(5_000), uint(7_500), uint(10_000), uint(20_000), uint(40_000), uint(60_000), uint(80_000), uint(100_000)];
        uint total_wagered = uint(total_wagered_under_account_code[_ref_address]);
        uint tier_num = 10;
        
        for (uint i = 0; i < 9; ++i) {
            if (total_wagered < REFERRAL_TIERS_AMT_REQUIRED[i] * (10 ** 18)) {
                tier_num = i + 1;
                break;
            }
        }

        return 5 * tier_num * _fee_amount / 100;
    }

    // Get latest price of some token through ChainLink price feed
    function getLatestPrice(address _token_address) public view returns (int) {
        address aggregator_address = token_to_aggregator_address[_token_address];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(aggregator_address);
        (,int price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return price * (10 ** 18) / _pow(decimals);
    }


    // END REFERRAL CODE FUNCTIONS

    

    // OWNER FUNCTIONS

    function setAggregatorAddress(address _token, address _aggregator_address) external {
        _onlyOwner();
        token_to_aggregator_address[_token] = _aggregator_address;
    }

    function toggleSupportedToken(address _token) external {
        _onlyOwner();
        erc20_token_supported[_token] = !erc20_token_supported[_token];
    }

    function toggleContractFreeze() external {
        _onlyOwner();
        contract_frozen = !contract_frozen;
    }
    
    function setSignerAddress(address _new_signer) external {
        _onlyOwner();
        SIGNER = _new_signer;
    }

    function setTreasuryAddress(address _new_wallet) external {
        _onlyOwner();
        TREASURY = _new_wallet;
    }

    function setBattleFee(uint256 _new_fee) external {
        _onlyOwner();
        require(_new_fee <= 100, "Invalid percentage");
        battle_fee_precent = _new_fee;
    }

    function setReducedBattleFee(uint256 _new_fee) external {
        _onlyOwner();
        require(_new_fee <= 100, "Invalid percentage");
        reduced_battle_fee_percent = _new_fee;
    }

    function setPartnershipFeeTier(address _partner, uint _fee_tier) external {
        _onlyOwner();
        partnership_fee_tier[_partner] = _fee_tier;
    }

    // Emergency withdraw funds to users in case it gets stuck in escrow and battle does not play out
    function emergencyRefundUnfinishedBattle(string memory _battle_id) external {
        _onlyOwner();

        require(!battle_contestants[_battle_id].paid, "Battle was already paid");
        require(!battle_contestants[_battle_id].cancelled, "Battle was already cancelled");

        battle_contestants[_battle_id].cancelled = true;

        address player_one = battle_contestants[_battle_id].player_one;
        address player_two = battle_contestants[_battle_id].player_two;
        address token_address = battle_contestants[_battle_id].token_address;
        uint amt_to_refund_each = battle_contestants[_battle_id].value;

        if (player_one != address(0)) {
            if (token_address == address(0)) {
                payable(player_one).transfer(amt_to_refund_each);
            } else {
                ERC20(token_address).transfer(player_one, amt_to_refund_each);
            }
        }
        
        if (player_two != address(0)) {
            if (token_address == address(0)) {
                payable(player_two).transfer(amt_to_refund_each);
            } else {
                ERC20(token_address).transfer(player_two, amt_to_refund_each);
            }
        }
    }

    // Emergency payout winner in case the claimWinnings function doesn't work
    function emergencyPayOutUnpaidBattle(string memory _battle_id, address _winner) external {
        _onlyOwner();

        require(!battle_contestants[_battle_id].paid, "Battle was already paid out");
        require(!battle_contestants[_battle_id].cancelled, "Battle was already cancelled");

        battle_contestants[_battle_id].paid = true;

        address player_one = battle_contestants[_battle_id].player_one;
        address player_two = battle_contestants[_battle_id].player_two;

        require(_winner == player_one || _winner == player_two, "Winner was not one of the addresses");
        require(player_one != address(0) && player_two != address(0), "No one actually joined the battle");

        address token_address = battle_contestants[_battle_id].token_address;
        uint amt_to_pay_out = 2 * (100 - reduced_battle_fee_percent) * battle_contestants[_battle_id].value / 100;
        uint amt_to_take_fee = 2 * reduced_battle_fee_percent * battle_contestants[_battle_id].value / 100;

        if (token_address == address(0)) {
            payable(_winner).transfer(amt_to_pay_out);
            payable(TREASURY).transfer(amt_to_take_fee);
        } else {
            ERC20(token_address).transfer(_winner, amt_to_pay_out);
            ERC20(token_address).transfer(TREASURY, amt_to_take_fee);
        }
    }

    // END OWNER FUNCTIONS
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract SignerVerifiable {

    mapping(address => uint256) private nonces;

    function getMessageHash(
        address _player,
        uint _amount,
        string calldata _message,
        string calldata _battle_id,
        uint _deadline,
        address _erc20_token, 
        address _player_referral_address
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(nonces[_player], _player, _amount, _message, _battle_id, _deadline, _erc20_token, _player_referral_address));
    }

    function decodeSignature(
        address _player,
        uint _amount,
        string calldata _message,
        string calldata _battle_id,
        uint256 _deadline,
        address _erc20_token,
        address _player_referral_address,
        bytes calldata signature
    ) internal returns (address) {
        address decoded_signer;
        {
            bytes32 messageHash = getMessageHash(_player, _amount, _message, _battle_id, _deadline, _erc20_token, _player_referral_address);
            bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

            decoded_signer = recoverSigner(ethSignedMessageHash, signature);

            require(block.timestamp < _deadline, "Transaction expired");
            require(decoded_signer != address(0), "Error: invalid signer");
        }

        unchecked {
            ++nonces[_player];
        }

        return decoded_signer;
    }

    // INTERNAL FUNCTIONS

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes calldata _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}