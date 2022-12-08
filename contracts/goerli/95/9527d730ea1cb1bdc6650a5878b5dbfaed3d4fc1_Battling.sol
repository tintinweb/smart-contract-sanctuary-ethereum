/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// File: contracts/SignerVerifiable.sol


pragma solidity ^0.8.15;

contract SignerVerifiable {

    mapping(address => uint256) private nonces;

    function getMessageHash(
        address _player,
        uint _amount,
        string memory _message,
        string memory _battle_id,
        uint _deadline,
        address _erc20_token
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(nonces[_player], _player, _amount, _message, _battle_id, _deadline, _erc20_token));
    }

    function decodeSignature(
        address _player,
        uint _amount,
        string memory _message,
        string memory _battle_id,
        uint256 _deadline,
        address _erc20_token,
        bytes memory signature
    ) public returns (address) {
        bytes32 messageHash = getMessageHash(_player, _amount, _message, _battle_id, _deadline, _erc20_token);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        address decoded_signer = recoverSigner(ethSignedMessageHash, signature);

        require(block.timestamp < _deadline, "Transaction expired");
        require(decoded_signer != address(0x0), "Error: invalid signer");

        nonces[_player]++;

        return decoded_signer;
    }

    function getWhoSigned(
        bytes32 messageHash,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address decoded_signer = recoverSigner(ethSignedMessageHash, signature);
        require(decoded_signer != address(0x0), "Error: invalid signer");

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

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contracts/BattlingRefOnChain.sol


pragma solidity ^0.8.17;




contract Battling is Ownable, SignerVerifiable {
    struct Battle {
        address player_one;
        address player_two;
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

    uint[] public REFERRAL_TIERS_AMT_REQUIRED = [2_000, 5_000, 10_000, 25_000, 50_000, 100_000, 250_000, 500_000, 1_000_000];
    mapping(address => int) public total_wagered_under_account_code;

    mapping(string => Battle) public battle_contestants;
    mapping(address => bool) public erc20_token_supported;
    mapping(address => address) public token_to_aggregator_address;

    mapping(string => address) public referral_code_owner;
    mapping(address => uint) public num_battles_per_user;

    bool public contract_frozen = false;
    
    // MODIFY THESE WHEN DEPLOYING THE CONTRACT
    address public SIGNER = 0x96d974510864C1f61eB508286F3e47C1824bB8b4;
    // address public SIGNER = 0x499f6d0c92b17f922ed8A0846cEC3A4AFe458c86;
    address public TREASURY = 0xe3309B67227609c26D2DDcD11659070D0eFA00aF;

    uint256 public battle_fee_precent = 5;
    uint256 public reduced_battle_fee_percent = 3;
    
    modifier frozen {
        require(!contract_frozen, "Contract is currently paused");
        _;
    }

    modifier callerVerified(uint256 _amount, string memory _message, string memory _battle_id, uint256 _deadline, address _erc20_token, bytes memory _signature) {
        require(msg.sender == tx.origin, "Smart contracts are not allowed to interact with this contract.");
        require(decodeSignature(msg.sender, _amount, _message, _battle_id, _deadline, _erc20_token, _signature) == SIGNER, "Call is not authorized");
        _;
    }

    constructor () { }

    // AUTHORIZED FUNCTIONS
    function initiateBattleERC20(FuncParams memory fp) external frozen callerVerified(fp._amount, fp._message, fp._battle_id, fp._deadline, fp._erc20_token, fp._signature) {
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
        } else {
            battle_contestants[fp._battle_id].player_two = msg.sender;
        }
    }

    function initiateBattleETH(FuncParams memory fp) external payable frozen callerVerified(msg.value, fp._message, fp._battle_id, fp._deadline, address(0), fp._signature) {
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
        } else {
            battle_contestants[fp._battle_id].player_two = msg.sender;
        }
    }
    
    // TODO : FINISH
    function claimWinnings(FuncParams memory fp) external frozen callerVerified(battle_contestants[fp._battle_id].value, fp._message, fp._battle_id, fp._deadline, battle_contestants[fp._battle_id].token_address, fp._signature) {
        require(!battle_contestants[fp._battle_id].paid, "Rewards already claimed for battle");
        require(!battle_contestants[fp._battle_id].cancelled, "Battle was cancelled, cannot claim winnings");
        require(battle_contestants[fp._battle_id].player_one == msg.sender || battle_contestants[fp._battle_id].player_two == msg.sender, "User is not in this battle");
        
        battle_contestants[fp._battle_id].paid = true;

        // 3% battling fee if num_times_claimed < 5, 5% otherwise
        uint battle_value = 2 * battle_contestants[fp._battle_id].value;

        address ref = fp._player_referral_address;
        if (ref == address(0)) ref = TREASURY;
        
        // Use the reduced fee if the user has done less than 5 battles, otherwise use the normal fee
        uint fee_to_use = (num_battles_per_user[msg.sender] < 5 ? reduced_battle_fee_percent : battle_fee_precent);
        num_battles_per_user[msg.sender]++;

        // ETH wagers
        if (battle_contestants[fp._battle_id].token_address == address(0)) {
            uint amount_owed_to_winner = battle_value * (100 - fee_to_use) / 100;
            uint amount_owed_to_ref = _calculateRefOwedAmount(ref, battle_value * fee_to_use / 100);
            uint amount_owed_to_treasury = battle_value * fee_to_use / 100 - amount_owed_to_ref;

            // transfer winnings to user
            payable(msg.sender).transfer(amount_owed_to_winner);

            // transfer referral designated amount
            if (amount_owed_to_ref > 0) payable(ref).transfer(amount_owed_to_ref);

            // transfer treasury designated amount
            if (amount_owed_to_treasury > 0) payable(TREASURY).transfer(amount_owed_to_treasury);

            // Update referral wager balance
            total_wagered_under_account_code[ref] += int(battle_value * (100 - fee_to_use) / 100) * getLatestPrice(battle_contestants[fp._battle_id].token_address) / _pow(18);

        } else { // ERC20 wagers
            uint amount_owed_to_winner = battle_value * (100 - fee_to_use) / 100;
            uint amount_owed_to_ref = _calculateRefOwedAmount(ref, battle_value * fee_to_use / 100);
            uint amount_owed_to_treasury = battle_value * fee_to_use / 100 - amount_owed_to_ref;

            // transfer winnings to user
            ERC20(battle_contestants[fp._battle_id].token_address).transfer(msg.sender, amount_owed_to_winner);

            // transfer referral designated amount
            if (amount_owed_to_ref > 0) ERC20(battle_contestants[fp._battle_id].token_address).transfer(ref, amount_owed_to_ref);

            // transfer treasury designated amount
            ERC20(battle_contestants[fp._battle_id].token_address).transfer(TREASURY, amount_owed_to_treasury);

            // Update referral wager balance
            total_wagered_under_account_code[ref] += int(battle_value * (100 - fee_to_use) / 100) * getLatestPrice(battle_contestants[fp._battle_id].token_address) / _pow(ERC20(battle_contestants[fp._battle_id].token_address).decimals());
        }
    }

    function cancelBattle(FuncParams memory fp) external frozen callerVerified(battle_contestants[fp._battle_id].value, fp._message, fp._battle_id, fp._deadline, battle_contestants[fp._battle_id].token_address, fp._signature) {
        require(battle_contestants[fp._battle_id].value > 0, "Battle does not exist");
        require(!battle_contestants[fp._battle_id].cancelled, "Battle was already cancelled");
        require(battle_contestants[fp._battle_id].player_one == msg.sender && battle_contestants[fp._battle_id].player_two == address(0), "Cannot cancel this battle");

        battle_contestants[fp._battle_id].cancelled = true;

        if (battle_contestants[fp._battle_id].token_address == address(0)) {
            payable(msg.sender).transfer(battle_contestants[fp._battle_id].value);
        } else {
            ERC20(battle_contestants[fp._battle_id].token_address).transfer(msg.sender, battle_contestants[fp._battle_id].value);
        }
    }


    // END AUTHORIZED FUNCTIONS



    // REFERRAL CODE FUNCTIONS


    function _pow(uint8 _exponent) internal pure returns(int ans) {
        ans = 1;
        for (uint i = 0; i < _exponent; i++) ans *= 10;
    }

    // Get the fee portion owed to the referral address by computing the accumulated wagers under their code
    function _calculateRefOwedAmount(address _ref_address, uint _fee_amount) internal view returns(uint) {
        if (_ref_address == address(0)) return 0;

        uint total_wagered = uint(total_wagered_under_account_code[_ref_address]);
        uint tier_num = REFERRAL_TIERS_AMT_REQUIRED.length + 1;

        for (uint i = 0; i < REFERRAL_TIERS_AMT_REQUIRED.length; i++) {
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

    function setAggregatorAddress(address _token, address _aggregator_address) external onlyOwner {
        token_to_aggregator_address[_token] = _aggregator_address;
    }

    function addSupportedToken(address _token) external onlyOwner {
        erc20_token_supported[_token] = true;
    }

    function removeSupportedToken(address _token) external onlyOwner {
        erc20_token_supported[_token] = false;
    }

    function toggleContractFreeze() external onlyOwner {
        contract_frozen = !contract_frozen;
    }
    
    function setSignerAddress(address _new_signer) external onlyOwner {
        SIGNER = _new_signer;
    }

    function setTreasuryAddress(address _new_wallet) external onlyOwner {
        TREASURY = _new_wallet;
    }

    function setBattleFee(uint256 _new_fee) external onlyOwner {
        require(_new_fee <= 100, "Invalid percentage");
        battle_fee_precent = _new_fee;
    }

    function setReducedBattleFee(uint256 _new_fee) external onlyOwner {
        require(_new_fee <= 100, "Invalid percentage");
        reduced_battle_fee_percent = _new_fee;
    }

    // Emergency withdraw funds to users in case it gets stuck in escrow and battle does not play out
    function emergencyRefundUnfinishedBattle(string memory _battle_id) external onlyOwner {
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
    function emergencyPayOutUnpaidBattle(string memory _battle_id, address _winner) external onlyOwner {
        require(!battle_contestants[_battle_id].paid, "Battle was already paid out");

        battle_contestants[_battle_id].paid = true;

        address player_one = battle_contestants[_battle_id].player_one;
        address player_two = battle_contestants[_battle_id].player_two;

        require(_winner == player_one || _winner == player_two, "Winner was not one of the addresses");

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

interface ERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}