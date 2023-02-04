// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "Pausable.sol";

contract FoodToken is ERC20, ERC20Burnable, Ownable, Pausable  {
    using SafeMath for uint256;

     // FOOD total supply
    uint256 private immutable max_supply;

    // Fighting Hunger wallet
    address public fighting_hungrt_wallet;

     // developing wallet
    address public developing_wallet;

    // pause controller: after presale, it will change to 0x0000000000000000000000000000000000000000
    address public pause_controller;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event SetFightingHungerWallet(address indexed user, address indexed newAddress);
    event SetDevelopingWallet(address indexed user, address indexed newAddress);


    constructor(uint256 _max_supply, address _fighting_hungrt_wallet, address _developing_wallet) ERC20("Metafarmer", "FOOD") {
        
        require(_max_supply > 0, "ERC20Capped: cap is 0");
        require(_fighting_hungrt_wallet != address(0));
        require(_developing_wallet != address(0));

        max_supply = _max_supply;
        fighting_hungrt_wallet = _fighting_hungrt_wallet;
        developing_wallet = _developing_wallet;
        pause_controller = msg.sender; 
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);        
    }

    /**
     * @dev Returns the cap on the token's max supply.
     */
    function maxSupply() public view virtual returns (uint256) {
        return max_supply;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= maxSupply(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }


    function pause() public {
        require(pause_controller == msg.sender, "You are not the pause controller");
        super._pause();  
    }

    function unpause() public onlyOwner {
        super._unpause();  
    }

    /// @dev overrides transfer function to meet tokenomics of FOOD
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(!paused() , "FOOD: the transfer has been paused during the pre-sale!");
        if (recipient == BURN_ADDRESS) {
            super._transfer(sender, recipient, amount);
        } else {

            // 1% of every transfer allocated to fighting and eradicating hunger.
            uint256 fightingAmount = amount.mul(1).div(100);

            // 1.5% of every transfer allocated to developing Metafarmer and producing new games.
            uint256 developingAmount = (amount.mul(1).div(100)).add((amount.mul(1).div(100)).div(2));

            // 2.5% of every transfer burnt
            uint256 burnAmount = (amount.mul(2).div(100)).add((amount.mul(1).div(100)).div(2));

            // 95% of transfer sent to recipient
            uint256 sendAmount = amount.sub(amount.mul(5).div(100));
            require(amount == sendAmount + fightingAmount + developingAmount + burnAmount, "FOOD::transfer: value invalid");

            super._transfer(sender, fighting_hungrt_wallet, fightingAmount);            
            super._transfer(sender, developing_wallet, developingAmount);            
            super._transfer(sender, BURN_ADDRESS, burnAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                block.chainid,
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "FOOD::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "FOOD::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "FOOD::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "FOOD::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying FOODs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "FOOD::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    // Update fighting hunger wallet.
    function setFightingHungerWallet(address _fighting_hunger_wallet) public onlyOwner {
        fighting_hungrt_wallet = _fighting_hunger_wallet;
        emit SetFightingHungerWallet(msg.sender, _fighting_hunger_wallet);
    }

    // Update developing wallet.
    function setDevelopingWallet(address _developing_wallet) public onlyOwner {
        developing_wallet = _developing_wallet;
        emit SetDevelopingWallet(msg.sender, _developing_wallet);
    }  

    // Update developing wallet.
    function pauseControllerDismiss() public onlyOwner {
        pause_controller= 0x0000000000000000000000000000000000000000;
    }    

}