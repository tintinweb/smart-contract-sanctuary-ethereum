// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {IOracleTripleSix} from "./interface/IOracle.sol";
import {IDroneToken} from "./interface/IDrone.sol";
import {ITripleSixDrones} from "./interface/IDRONESbyT6.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

error ClaimBefore24Hours(string, uint);

contract TripleStaking is ReentrancyGuard, Ownable, Pausable{
    IDroneToken private _stakingToken;
    IOracleTripleSix private _oracle;
    ITripleSixDrones private _drones;
    uint64 public constant END_TIME = 1950444223;
    uint64 public constant START_TIME = 1650444223;
    uint64 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant PROPELLER_MUL = 250000000000000000;
    uint256 public constant MOTOR_MUL = 2500000000000000000;
    uint256 public constant BASE_MOLTEN = 50;
    uint256 public constant BASE_DIAMOND = 15;
    uint256 public constant BASE_GOLD = 5;
    uint256 public constant BASE_SILVER = 1;

    struct UserInfo {
        uint16[] balances;
        uint256 lastClaimedReward;
    }
    mapping(address => UserInfo) private userInfo;
    mapping (uint256 => address) private tokenOwner;

    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed from, uint256 amount);

    /// @notice            Modifier that updates the claimed time after each withdrawal or staking event
    /// @param _user   address of the user
    modifier updateLastClaimed(address _user){
        _;
        if (END_TIME < block.timestamp){
            userInfo[_user].lastClaimedReward = END_TIME;
        }
        // Update last reward block only if it wasn't updated after or at the end block
        if (block.timestamp < END_TIME) {
            userInfo[_user].lastClaimedReward = block.timestamp + SECONDS_IN_A_DAY;
        }
    }

    ///
    ///  STAKE AND WITHDRAW FUNCTIONS
    ///

    /// @notice            Calculates and claims the rewards for the user
    function claimRewards() external nonReentrant {
        uint lastClaimed = userInfo[msg.sender].lastClaimedReward;
        if(lastClaimed > block.timestamp) revert ClaimBefore24Hours("Time Left:", lastClaimed - block.timestamp);

        uint amount = _getRateForUser(msg.sender);

        if(block.timestamp < START_TIME){
            //Rewards are not active yet
            amount = 0;
        }

        if(lastClaimed > 0 && lastClaimed >= START_TIME){
            userInfo[msg.sender].lastClaimedReward = block.timestamp + SECONDS_IN_A_DAY;
            //Calculates the rate + the amount of tokens pending after the 24h limit has been hit
            uint timeLeft = block.timestamp - lastClaimed;
            uint pending = timeLeft * amount / SECONDS_IN_A_DAY;
            amount = amount + pending;
        }

        if(block.timestamp > END_TIME){
            userInfo[msg.sender].lastClaimedReward = END_TIME;
            //Calculates the rate + the amount of tokens pending after the 24h limit has been hit
            uint timeLeft = END_TIME - lastClaimed;
            if (timeLeft == 0){
                amount = 0;
            } else {
                uint pending = timeLeft * amount / SECONDS_IN_A_DAY;
                amount = amount + pending;
            }
        }

        require(amount > 0, "ZERO_AMOUNT");
        emit Claimed(msg.sender, amount);
        _stakingToken.mint(msg.sender, amount);
    }

    /// @notice             Stakes multiple tokens for the user and claims pending tokens if there is any
    /// @param _tokenIds    target tokens
    function stakeMultiple(uint16[] calldata _tokenIds) external nonReentrant updateLastClaimed(msg.sender){
        require(END_TIME > block.timestamp, "EMISSION_STOPED");

        uint256 balance = userInfo[msg.sender].balances.length;
        if(balance > 0) {
            uint256 amount = _getRateForUser(msg.sender);
            if(amount > 0) {
                _handleClaim(amount);
            }
        }

        emit Staked(msg.sender, _tokenIds.length);
        for(uint i; i < _tokenIds.length;) {
            _stakeNft(_tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice             Withdraws all owned tokens by user and claim tokens for the user
    function withdrawAll() external nonReentrant updateLastClaimed(msg.sender){
        uint16[] memory tokenIds = userInfo[msg.sender].balances;
        require(tokenIds.length > 0, "NO_TOKEN_BALANCE");

        uint length = tokenIds.length;
        uint256 amount = _getRateForUser(msg.sender);
        if(amount > 0) {
            _handleClaim(amount);
        }

        emit Withdraw(msg.sender, length);
        for(uint i; i < length;) {
            _withdrawNft(tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice             Withdraws multiple tokens for the user and claims pending if there is any
    /// @param _tokenIds    target tokens
    function withdrawMultiple(uint16[] calldata _tokenIds) external nonReentrant updateLastClaimed(msg.sender){
        uint256 balance = userInfo[msg.sender].balances.length;
        require(balance > 0, "NO_TOKEN_BALANCE");

        uint256 amount = _getRateForUser(msg.sender);
        if(amount > 0) {
            _handleClaim(amount);
        }

        emit Withdraw(msg.sender, _tokenIds.length);
        for(uint i; i < _tokenIds.length;) {
            _withdrawNft(_tokenIds[i]);

            unchecked {
                ++i;
             }
        }
    }

    /// @notice      Withdraw staked tokens and give up rewards. Only for emergency. It does not update the pool.
    function emergencyWithdraw() external nonReentrant whenPaused {
        uint16[] memory balance = userInfo[msg.sender].balances;
        uint256 length = balance.length;
        require(length > 0, "Withdraw: Amount must be > 0");

        // Reset internal value for user
        userInfo[msg.sender].lastClaimedReward = block.timestamp;

        emit EmergencyWithdraw(msg.sender, length);
        for(uint i; i < length;){
            _withdrawNft(balance[i]);

            unchecked {
                ++i;
            }
        }

    }

    ///
    ///  INTERNAL FUNCTIONS
    ///

    /// @notice             Internal function to stake a single token for the user
    /// @param   tokenId    target token
    function _stakeNft(uint16 tokenId) internal {
        require(_drones.ownerOf(tokenId) == msg.sender, "NOT_TOKEN_OWNER");

        userInfo[msg.sender].balances.push(tokenId);
        _drones.transferFrom(msg.sender, address(this), tokenId);
        tokenOwner[tokenId] = msg.sender;
    }

    /// @notice             Withdraws single token for the user
    /// @param tokenId      target token
    function _withdrawNft(uint16 tokenId) internal {
        require(tokenOwner[tokenId] == msg.sender, "NO_TOKEN_OWNER");

        _removeElement(userInfo[msg.sender].balances, tokenId);
        delete tokenOwner[tokenId];
        _drones.transferFrom(address(this), msg.sender, tokenId);
    }

    /// @notice             Internal function to remove element from the balance array
    /// @param _array       target array
    /// @param _element     target element of the array
    function _removeElement(uint16[] storage _array, uint256 _element) internal {
        uint256 length = _array.length;
        for (uint256 i; i < length;) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice             Internal function to get base rate for single token
    /// @param _tokenId     target tokenId
    function _getRatePerToken(uint16 _tokenId) internal view returns(uint) {
        (uint32 cpu, uint32 battery, uint32 motor, uint32 propellers) = _oracle.getTraitsPerToken(_tokenId);
        uint rewards;
        if(cpu > 0){
           //we assume that the NFT is molten
           uint newCpu = cpu * 2 * BASE_MOLTEN * PRECISION;
           uint newProp = propellers * PROPELLER_MUL + PRECISION;
           uint newMotor = motor * MOTOR_MUL;
           if (newProp == 0) {
                rewards = newCpu + newMotor;
           } else {
                rewards = ((newCpu * newProp) / PRECISION) + newMotor;
           }
           uint newBattery = rewards * battery / 100;

           return rewards + newBattery;
        }

        if(propellers > 0){
            //we assume that the NFT is diamond
            uint newProp = propellers * BASE_DIAMOND * (PROPELLER_MUL + PRECISION);
            uint newMotor = motor * MOTOR_MUL;
            rewards = newProp + newMotor;
            uint newBattery = rewards * battery / 100;

            return rewards + newBattery;
        }

        if(motor > 0){
            //we assume that the NFT is gold
            uint newMotor = motor * MOTOR_MUL * BASE_GOLD;
            uint newBattery = newMotor * battery / 100;

            return newMotor + newBattery;
        }

        if (battery > 0) {
            //we assume that the NFT is silver
            uint newBattery = BASE_SILVER * battery * PRECISION;
            uint percentage = newBattery * battery / 100;

            return newBattery + percentage;
        }

        return rewards;
    }

    /// @notice             Internal function to to get base rate for all owned tokens
    /// @param _user        target user
    function _getRateForUser(address _user) internal view returns(uint) {
        uint16[] memory tokenIds = userInfo[_user].balances;
        uint256 length = tokenIds.length;
        uint totalAmount;
        for(uint i; i < length;) {
            totalAmount += _getRatePerToken(tokenIds[i]);

            unchecked {
                ++i;
            }
        }

        return totalAmount;
    }

    /// @notice             Handles the calculation of pending tokens available to claimed before or after the 24h period
    /// @param  amount      base rate amount for the user
    function _handleClaim(uint amount) internal {
        uint256 lastClaimed = userInfo[msg.sender].lastClaimedReward;
        if(block.timestamp >= lastClaimed) {
            //If this happens it means the user never claimed so we send the full amount + accumulated
            uint timeLeft = block.timestamp - lastClaimed;
            uint pending = timeLeft * amount / SECONDS_IN_A_DAY;
            amount = amount + pending;
            emit Claimed(msg.sender, amount);
            _stakingToken.mint(msg.sender, amount);
        } else {
            //Here means that the user withdrew before the 24h limit. But still gets proportional amount
            uint timeLeft = lastClaimed - block.timestamp;
            uint pending = timeLeft * amount / SECONDS_IN_A_DAY;
            amount = amount - pending;
            emit Claimed(msg.sender, amount);
            _stakingToken.mint(msg.sender, amount);
        }
    }

     /// @notice             Internal function to calculate pending rewards for a user
     /// @param _user        target user
    function _calculateReward(address _user) internal view returns(uint) {
        uint16[] memory balance = userInfo[_user].balances;
        uint256 length = balance.length;
        if(length == 0) return 0;

        if(block.timestamp < START_TIME){
            //Rewards are not active yet
            return 0;
        }

        uint totalRewards = _getRateForUser(_user);
        uint256 lastClaimed = userInfo[msg.sender].lastClaimedReward;
        //If the end time has been surpassed it calculates the rewards with that time instead of block.timestamp
        if (END_TIME < block.timestamp){
            uint timeLeft = END_TIME - lastClaimed;
            //If the timeleft is 0 then we set to 0 since emissions have stoped
            if (timeLeft == 0) {
                totalRewards = 0;
            } else {
                //If not then calcs the remaining available tokens to claim
                uint pending = timeLeft * totalRewards / SECONDS_IN_A_DAY;
                totalRewards = totalRewards + pending;
            }
        }

        //Performs standart -24h or +24h pending rewards
        if (block.timestamp < END_TIME) {
            if(block.timestamp >= lastClaimed) {
                uint timeLeft = block.timestamp - lastClaimed;
                uint pending = timeLeft * totalRewards / SECONDS_IN_A_DAY;
                totalRewards = totalRewards + pending;
            } else {
                uint timeLeft = lastClaimed - block.timestamp;
                uint pending = timeLeft * totalRewards / SECONDS_IN_A_DAY;
                totalRewards = totalRewards - pending;
            }
        }

        return totalRewards;
    }

    ///
    ///  GETTER FUNCTIONS
    ///

    /// @notice             Gets total amount of staked tokens in the contract
    function getTotalStakedTokens() external view returns(uint) {
        return _drones.balanceOf(address(this));
    }

    /// @notice             Gets total amount of staked tokens by the user
    /// @param _user        target user
    function getUserBalance(address _user) external view returns(uint){
        return userInfo[_user].balances.length;
    }

    /// @notice             Gets all tokenIds staked by the user
    /// @param _user        target user
    function getUserStakedTokens(address _user) external view returns(uint16[] memory){
        return userInfo[_user].balances;
    }

    /// @notice             Calculates all pending rewards for a user. More for frontend
    /// @param _user        target user
    function calculatePendingReward(address _user) external view returns(uint) {
        return  _calculateReward(_user);
    }

    ///
    ///  OWNER FUNCTIONS
    ///

    /// @notice             Sets the oracle contract
    /// @param oracle       Target oracle contract
    function setOracleContract(address oracle) external onlyOwner {
        _oracle = IOracleTripleSix(oracle);
    }

    /// @notice             Sets the NFT contract
    /// @param drones       Target NFT contract
    function setTripleSixDronesContract(address drones) external onlyOwner {
        _drones = ITripleSixDrones(drones);
    }

    /// @notice             Sets the ERC20 contract
    /// @param stakingToken Target ERC20 contract
    function setDroneTokenContract(address stakingToken) external onlyOwner {
        _stakingToken = IDroneToken(stakingToken);
    }

    /// @notice             Allows calling emergency withdraw
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice             unpause
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice                      Sets all target contracts.
    ///                              We can use CREATE2 or RLP to precompute the needed addresses
    ///                              for the oracle and ERC20 contract at the constructor lvl
    ///                              For more information https://twitter.com/transmissions11/status/1518507047943245824
    /// @param _stakingTokenContract target ERC20 contract
    /// @param _oracleContract       Target contract set for the oracle
    /// @param _dronesContract       Target NFT contract
    constructor(address _stakingTokenContract, address _oracleContract, address _dronesContract) {
        _stakingToken = IDroneToken(_stakingTokenContract);
        _oracle = IOracleTripleSix(_oracleContract);
        _drones = ITripleSixDrones(_dronesContract);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface ITripleSixDrones {
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApprovalToCurrentOwner();
    error ApproveToCaller();
    error BalanceQueryForZeroAddress();
    error InvalidQueryRange();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function LIQUID_METALS() external view returns (address);

    function addGiveaway(address[] memory addresses) external;

    function addressMintedBalance(address) external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseExtension() external view returns (string memory);

    function burnToken(uint256 tokenId) external;

    function explicitOwnershipOf(uint256 tokenId)
        external
        view
        returns (IERC721A.TokenOwnership memory);

    function explicitOwnershipsOf(uint256[] memory tokenIds)
        external
        view
        returns (IERC721A.TokenOwnership[] memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function getGolds() external view returns (uint256[] memory golds);

    function getMinterInfo(address _minter)
        external
        view
        returns (uint256 minterMetalsHeld, uint256 mintedTokenID);

    function getMinters() external view returns (address[] memory minted);

    function getSilvers() external view returns (uint256[] memory silvers);

    function giveaway(address) external view returns (bool);

    function goldMints(uint256) external view returns (uint256);

    function hasMintedGW(address) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isGiveaway(address _user) external view returns (bool);

    function isWhitelisted(address _user, bytes32[] memory _merkleProof)
        external
        view
        returns (bool);

    function maxSupply() external view returns (uint256);

    function merkleRoot() external view returns (bytes32);

    function mint(bytes32[] memory _merkleProof) external;

    function mintAdmin(uint256 mintAmount) external;

    function mintGiveaway(address _winner) external;

    function name() external view returns (string memory);

    function nftPerAddressLimit() external view returns (uint256);

    function notRevealedUri() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function pause(bool _state) external;

    function pauseBurn(bool _state) external;

    function paused() external view returns (bool);

    function pausedBurn() external view returns (bool);

    function renounceOwnership() external;

    function reveal() external;

    function revealed() external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseExtension(string memory _newBaseExtension) external;

    function setBaseURI(string memory _newBaseURI) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function setNftPerAddressLimit(uint256 _limit) external;

    function setNotRevealedURI(string memory _notRevealedURI) external;

    function silverMints(uint256) external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

interface IERC721A {
    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IDroneToken {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function burn(uint256 _amount) external;

    function decimals() external view returns (uint8);

    function mint(address _to, uint256 _amount) external;

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function renounceOwnership() external;

    function setStakingContract(address _stakingContract) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IOracleTripleSix {
    function addPermissions(address _allowed) external;

    function getTraitsPerToken(uint16 _tokenId)
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32
        );

    function owner() external view returns (address);

    function revokePermissions(address _notAllowed) external;

    function setTraitsForToken(
        uint16 _tokenId,
        OracleTripleSix.Traits memory _traits
    ) external;
}

interface OracleTripleSix {
    struct Traits {
        uint32 CPU;
        uint32 BATTERY;
        uint32 MOTOR;
        uint32 PROPELLERS;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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