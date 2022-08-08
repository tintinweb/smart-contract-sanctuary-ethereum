// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SignerVerifiable.sol";

contract Battling is Ownable, SignerVerifiable {
    struct Battle {
        address player_one;
        address player_two;
        address token_address;
        uint value;
        bool cancelled;
    }

    uint256 public team_balance = 0;
    // mapping(string => bool) public winner_paid;
    // mapping(string => bool) public draw_paid_out;
    mapping(string => Battle) public battle_contestants;
    mapping(address => bool) public erc20_token_supported;

    bool public contract_frozen = false;
    address private SIGNER;
    address public TREASURY;
    
    event BattleJoined(string _battle_id, address _player_one, address _player_two, address token_address, uint value);

    modifier frozen {
        require(!contract_frozen, "Contract is currently paused");
        _;
    }

    modifier callerVerified(uint256 _amount, string memory _message, string memory _battle_id, uint256 _deadline, address _erc20_token, bytes memory _signature) {
        require(decodeSignature(msg.sender, _amount, _message, _battle_id, _deadline, _erc20_token, _signature) == SIGNER, "Call is not authorized");
        _;
    }

    constructor () { }

    // AUTHORIZED FUNCTIONS
    function initiateBattleERC20(uint256 _amount, string memory _message, string memory _battle_id, uint256 _deadline, address _erc20_token, bytes memory _signature) external frozen callerVerified(_amount, _message, _battle_id, _deadline, _erc20_token, _signature) {
        require(battle_contestants[_battle_id].player_one == address(0x0) || battle_contestants[_battle_id].player_two == address(0x0), "Battle is full");
        require(!battle_contestants[_battle_id].cancelled, "Battle was cancelled");

        if (battle_contestants[_battle_id].value == 0) { // battle creation
            require(_amount > 0, "Amount must be greater than 0");
            require(erc20_token_supported[_erc20_token], "Token is not supported");
            battle_contestants[_battle_id].value = _amount;
            battle_contestants[_battle_id].token_address = _erc20_token;
        } else { // battle joining
            require(battle_contestants[_battle_id].value == _amount, "Incorrect value sent to battle");
            require(battle_contestants[_battle_id].token_address == _erc20_token, "Wrong token");
        }

        IERC20(_erc20_token).transferFrom(msg.sender, address(this), _amount);

        if (battle_contestants[_battle_id].player_one == address(0x0)) {
            battle_contestants[_battle_id].player_one = msg.sender;
        } else {
            battle_contestants[_battle_id].player_two = msg.sender;
        }
    }

    function initiateBattleETH(string memory _message, string memory _battle_id, uint256 _deadline, bytes memory _signature) external payable frozen callerVerified(msg.value, _message, _battle_id, _deadline, address(0), _signature) {
        require(battle_contestants[_battle_id].player_one == address(0x0) || battle_contestants[_battle_id].player_two == address(0x0), "Battle is full");
        require(!battle_contestants[_battle_id].cancelled, "Battle was cancelled");
        
        if (battle_contestants[_battle_id].value == 0) { // battle creation
            require(msg.value > 0, "Amount must be greater than 0");
            battle_contestants[_battle_id].value = msg.value;
        } else { // battle joining
            require(battle_contestants[_battle_id].value == msg.value, "Incorrect value sent to battle");
        }

        if (battle_contestants[_battle_id].player_one == address(0x0)) {
            battle_contestants[_battle_id].player_one = msg.sender;
        } else {
            battle_contestants[_battle_id].player_two = msg.sender;
        }
    }
    
    // function claimWinnings(uint256 _amount, string memory _message, string memory _battle_id, uint256 _deadline, bytes memory _signature) external frozen callerVerified(_amount, _message, _battle_id, _deadline, _signature) {
    //     require(!winner_paid[_battle_id], "Rewards already claimed for battle");
    //     require(battle_contestants[_battle_id].player_one == msg.sender || battle_contestants[_battle_id].player_two == msg.sender, "User is not in this battle");
        
    //     winner_paid[_battle_id] = true;
    //     payable(msg.sender).transfer(_amount * 95 / 100);
    //     team_balance += 5 * _amount / 100;
    // }

    // function returnWager(uint256 _amount, string memory _message, string memory _battle_id, uint256 _deadline, bytes memory _signature) external frozen callerVerified(_amount, _message, _battle_id, _deadline, _signature) {
    //     require(!draw_paid_out[_battle_id], "Rewards already claimed for battle");
    //     require(battle_contestants[_battle_id].player_one == msg.sender || battle_contestants[_battle_id].player_two == msg.sender, "User is not in this battle");

    //     draw_paid_out[_battle_id] = true;
    //     payable(battle_contestants[_battle_id].player_one).transfer(_amount);
    //     payable(battle_contestants[_battle_id].player_two).transfer(_amount);
    // }

    function cancelBattle(string memory _message, string memory _battle_id, uint256 _deadline, bytes memory _signature) external frozen callerVerified(battle_contestants[_battle_id].value, _message, _battle_id, _deadline, battle_contestants[_battle_id].token_address, _signature) {
        require(battle_contestants[_battle_id].value > 0, "Battle does not exist");
        require(!battle_contestants[_battle_id].cancelled, "Battle was already cancelled");
        require(battle_contestants[_battle_id].player_one == msg.sender && battle_contestants[_battle_id].player_two == address(0), "Cannot cancel this battle");

        battle_contestants[_battle_id].cancelled = true;

        if (battle_contestants[_battle_id].token_address == address(0)) {
            payable(msg.sender).transfer(battle_contestants[_battle_id].value);
        } else {
            IERC20(battle_contestants[_battle_id].token_address).transfer(msg.sender, battle_contestants[_battle_id].value);
        }
    }


    // END AUTHORIZED FUNCTIONS

    // OWNER FUNCTIONS

    function addSupportedToken(address _token) external onlyOwner {
        erc20_token_supported[_token] = true;
    }

    function removeSupportedToken(address _token) external onlyOwner {
        erc20_token_supported[_token] = false;
    }

    function withdrawTeamBalance() external onlyOwner {
        payable(msg.sender).transfer(team_balance);
        team_balance = 0;
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

    function viewSigner() external view onlyOwner returns(address) {
        return SIGNER;
    }

    // END OWNER FUNCTIONS
    
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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