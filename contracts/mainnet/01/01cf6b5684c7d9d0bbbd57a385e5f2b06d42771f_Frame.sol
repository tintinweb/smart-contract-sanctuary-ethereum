/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface MP {
    function balanceOf(address wallet) external view returns(uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address wallet, address stakingAddress) external view returns(bool);
}

interface Shard {
    function determineYield(uint256 timestamp) external view returns(uint256);
    function mintShards(address wallet, uint256 amount) external;
}

/*
⠀*⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢀⣀⣀⣠⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣄⣀⣀⡀⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⣿⣿⣿⣿⡿⠟⠁⠀⠀⣀⣾⣿⣿⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⣿⣿⡿⠋⠀⠀⠀⣠⣾⣿⡿⠋⠁⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⠟⠉⠀⠀⢀⣴⣾⣿⠿⠋⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⣠⣴⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⣠⣾⣿⡿⠋⠁⠀⠀⠀⠀⠀⣠⣶⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⢸⣿⠿⠋⠀⠀⠀⠀⠀⢀⣠⣾⡿⠟⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠘⠁⠀⠀⠀⠀⠀⢀⣴⣿⡿⠋⣠⣴⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⣠⣾⣿⠟⢁⣠⣾⣿⣿⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⠀⠀⠀⢀⣠⣾⡿⠋⢁⣴⣿⣿⣿⣿⣿⠀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⢸⣿⣀⣀⣀⣈⣉⣉⣀⣀⣉⣉⣉⣉⣉⣉⣉⣀⣿⡇⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⠘⠛⠛⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠛⠛⠃⠀⠀⠀⠀⠀
⠀*⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠛⠛⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *          MIRRORPASS.XYZ
 */
contract Frame is Ownable {
    MP private mp;
    Shard private shards;

    struct LockedUp {
        address owner;
        uint256 until;
        uint256 token;
        bool hasToken;
    }

    bool public stakingAvailable = false;
    bool public lockupAvailable = false;
    bool public claimingAvailable = false;
    uint256 public totalStaked = 0;

    mapping(address => uint256[]) private tokensHeld;
    mapping(address => LockedUp) private lockedup;
    mapping(uint256 => uint256) private tokenYield;
    mapping(uint256 => address) private tokenToOwner;

    event StakedToken(address wallet, uint256[] tokens, uint256 timestamp);
    event WithdrewToken(address wallet, uint256 tokenId, uint256 timestamp);
    event LockedToken(address wallet, uint256 tokenId, uint256 timestamp);
    event FreeToken(address wallet, uint256 tokenId);

    modifier isNotContract() {
        require(tx.origin == msg.sender, "No contracts allowed");
        _;
    }

    modifier isStakingAvailable() {
        require(stakingAvailable, "Staking is currently disabled");
        _;
    }

    modifier isLockupAvailable() {
        require(lockupAvailable, "Lock Up is currently disabled");
        _;
    }

    // this returns the index of the token we're looking for in the deposited wallets
    function findToken(uint256 token, uint256[] memory tokens) private pure returns(uint256) {
        uint256 index = 0;

        while (tokens[index] != token) {
            index++;
        }
        
        return index;
    }

    // this allows the user to start staking their tokens and it keeps track of the
    // tokens that are staked, as well as the timestamp that they were deposited with
    function stake(uint256[] memory tokens) public isStakingAvailable isNotContract {
        require(tokens.length >= 1 && tokens.length <= 5, "Invalid token amount");

        uint256[] storage _deposits = tokensHeld[msg.sender];

        for (uint256 x = 0;x < tokens.length;x++) {
            uint256 _token = tokens[x];

            mp.transferFrom(msg.sender, address(this), _token);

            _deposits.push(_token); 
            tokenYield[_token] = block.timestamp;
            tokenToOwner[_token] = msg.sender;
        }

        totalStaked += tokens.length;
        emit StakedToken(msg.sender, tokens, block.timestamp);
    }

    // this withdraws the staked tokens and claims any shards that weren't claimed
    function withdraw(uint256[] memory tokens) public isNotContract {
        require(tokens.length >= 1 && tokens.length <= 5, "Invalid token amount");

        uint256 shardsGained = 0;
        uint256[] storage _deposits = tokensHeld[msg.sender];

        for (uint256 x = 0;x < tokens.length;x++) {
            uint256 _token = tokens[x];
            address _owner = tokenToOwner[_token];

            require(_owner == msg.sender, "You didn't deposit these");
            mp.transferFrom(address(this), _owner, _token);
            
            uint256 index = findToken(_token, _deposits);
            delete _deposits[index];

            // this accumulates the shards the wallet gained from all the tokens
            if (claimingAvailable) {
                shardsGained += shards.determineYield(tokenYield[_token]);
            }

            emit WithdrewToken(_owner, _token, tokenYield[_token]);

            tokenYield[_token] = 0;
            delete _owner;
        }

        if (claimingAvailable) {
            shards.mintShards(msg.sender, shardsGained);
        }

        totalStaked -= tokens.length;
        delete shardsGained;
    }

    // this allows you to "withdraw" your erc20 tokens from the staked tokens
    function claimShardsFromTokens(uint256[] memory tokens) public isNotContract {
        require(claimingAvailable, "You're not able to withdraw your shards right now");

        uint256 shardsGained = 0;

        for (uint256 x = 0;x < tokens.length;x++) {
            uint256 _token = tokens[x];
            require(tokenToOwner[_token] == msg.sender, "You didn't deposit these");

            shardsGained += shards.determineYield(tokenYield[_token]);
            tokenYield[_token] = block.timestamp;
            delete _token;
        }

        shards.mintShards(msg.sender, shardsGained);
        delete shardsGained;
    }

    // this returns the timestamp of when the token was staked, used for determining
    // the yield each token gives
    function getTimeFromToken(uint256 token) public view returns (uint256) {
        return tokenYield[token];
    }

    // returns the total amount of tokens that are staked, used on the UI & for calculating yield
    function getTokensStaked(address wallet) public view returns (uint256[] memory) {
        return tokensHeld[wallet];
    }

    // this locks in the pass into the staking contract for X amount of time, this will give access
    // to the application until the lock up period is over
    function lockIn(uint256 tokenId, uint256 period) public isLockupAvailable isNotContract {
        LockedUp storage _lockedup = lockedup[msg.sender];

        require(!_lockedup.hasToken, "You need to withdraw your current token first");
        require(period > 0 && period <= 3, "You can only lock in your token for 30 to 90 days!");

        mp.transferFrom(msg.sender, address(this), tokenId);

        _lockedup.owner = msg.sender;
        _lockedup.until = block.timestamp + (30 days * period);
        _lockedup.token = tokenId;
        _lockedup.hasToken = true;
        totalStaked += 1;

        emit LockedToken(msg.sender, tokenId, _lockedup.until);        
    }

    // once the users lock in period is over, they are able to withdraw the token using this
    function withdrawLockedUp() public isNotContract {
        LockedUp storage _lockedup = lockedup[msg.sender];

        require(block.timestamp >= _lockedup.until, "Your lock in period is not over yet");

        mp.transferFrom(address(this), _lockedup.owner, _lockedup.token);

        _lockedup.hasToken = false;
        _lockedup.until = 0;
        totalStaked -= 1;

        emit FreeToken(_lockedup.owner, _lockedup.token);
    }

    // this returns the timestamp of when the locked up period ends
    function getLockedInTime(address wallet) public view returns (uint256) {
        LockedUp storage _lockedup = lockedup[wallet];

        return _lockedup.until;
    }

    // this is more of a emergency case incase anything happens that requires
    // people to withdraw their tokens
    function clearLockedupUntil(address[] memory addresses) public onlyOwner {
        for (uint x = 0;x < addresses.length;x++) {
            LockedUp storage _lockedup = lockedup[addresses[x]];

            _lockedup.until = 0;
        }
    }

    // this is a emergency withdraw for locked in tokens if we need to do this any reason
    function emergencyWithdrawLockedup(address[] memory addresses) public onlyOwner {
        for (uint x = 0;x < addresses.length;x++) {
            LockedUp storage _lockedup = lockedup[addresses[x]];

            if (_lockedup.hasToken) {
                mp.transferFrom(address(this), _lockedup.owner, _lockedup.token);
                
                _lockedup.until = 0;
                _lockedup.hasToken = false;
                totalStaked -= 1;
            }
        }
    }

    // this is used on the dashboard to calculate the pending shards 
    function calculateTotalPendingShards(uint256[] memory tokens) public view returns(uint256) {
        uint256 possibleShards = 0;

        for (uint256 x = 0;x < tokens.length;x++) {
            uint256 _token = tokens[x];
            possibleShards += shards.determineYield(tokenYield[_token]);
            delete _token;
        }

        return possibleShards;
    }

    // this is the erc721 contract that holds the OG  mirror pass
    function setTokenContract(address tokenContract) public onlyOwner {
        mp = MP(tokenContract);
    }
    
    // this is the erc20 token that interacts with the ECOSYSTEM
    function setShardsContract(address shardsContract) public onlyOwner {
        shards = Shard(shardsContract);
    }

    // this enables / dsiables stake
    function setStakingState(bool available) public onlyOwner {
        stakingAvailable = available;
    }

    // this enables / disables lockIn
    function setLockupState(bool available) public onlyOwner {
        lockupAvailable = available;
    }

    // this enables / disable erc20 token minting incase something occurs
    // where we need to disable this
    function setShardMinting(bool available) public onlyOwner {
        claimingAvailable = available;
    }
}