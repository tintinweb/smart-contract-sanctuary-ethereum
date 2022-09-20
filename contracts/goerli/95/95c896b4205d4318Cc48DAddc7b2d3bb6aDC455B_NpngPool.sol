//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title No Pool No Game : Pool Contract
/// @author Perrin GRANDNE
/// @notice
/// @dev
/// @custom:experimental This is an experimental contract.

import {NpngGame} from "./NpngGame.sol";

/// @notice Only the ERC-20 functions we need
interface IERC20 {
    /// @notice Get the balance of aUSDC in No Pool No Game
    /// @notice and balance of USDC from the Player
    function balanceOf(address acount) external view returns (uint);

    /// @notice Approve the deposit of USDC from No Pool No Game to Aave
    function approve(address spender, uint amount) external returns (bool);

    /// @notice Confirm the allowed amount before deposit
    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    /// @notice Withdraw USDC from No Pool No Game
    function transfer(address recipient, uint amount) external returns (bool);

    /// @notice Transfer USDC from User to No Pool No Game
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function mint(address sender, uint amount) external;

    function burn(address sender, uint amount) external;
}

/// Only the PoolAave functions we need
interface PoolAave {
    /// Deposit USDC to Aave Pool
    function supply(
        address asset,
        uint amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /// Withdraw USDC from Aave Pool
    function withdraw(
        address asset,
        uint amount,
        address to
    ) external;
}

contract NpngPool is NpngGame {
    mapping(address => uint) private balanceOfUser;
    mapping(address => uint) private idContestOfDeposit;
    IERC20 private usdcToken;
    IERC20 private aUsdcToken;
    IERC20 private npngToken;
    PoolAave private poolAave;

    constructor() {
        usdcToken = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
        aUsdcToken = IERC20(0x1Ee669290939f8a8864497Af3BC83728715265FF);
        poolAave = PoolAave(0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6);
        npngToken = IERC20(0x0CEA29EB3A96f90f2de68e5Ea7CDe2330829cAdf);
    }

    /// WRITE FUNCTIONS
    function changeNpngTokenAddress(address _newAddress) public onlyOwner {
        npngToken = IERC20(_newAddress);
    }

    function depositOnAave(uint _amount) public {
        require(_amount < usdcToken.balanceOf(msg.sender));
        require(
            _amount < usdcToken.allowance(msg.sender, address(this)),
            "Insufficient allowed USDC"
        );
        usdcToken.transferFrom(msg.sender, address(this), _amount);
        usdcToken.approve(address(poolAave), _amount);
        poolAave.supply(address(usdcToken), _amount, address(this), 0);
        balanceOfUser[msg.sender] = balanceOfUser[msg.sender] + _amount;
        balanceOfUser[address(this)] = balanceOfUser[address(this)] + _amount;
        npngToken.mint(msg.sender, _amount);
        NpngGame.updateIdContest();
        idContestOfDeposit[msg.sender] = NpngGame.getCurrentIdContest();
    }

    function withdraw(uint _amount) public {
        require(balanceOfUser[msg.sender] >= _amount, "Insufficient balance");
        require(
            idContestOfDeposit[msg.sender] <= getCurrentIdContest() + 2,
            "Please wait 2 contests after your deposit to witdraw"
        );
        poolAave.withdraw(address(usdcToken), _amount, address(this));
        usdcToken.transfer(msg.sender, _amount);
        balanceOfUser[msg.sender] = balanceOfUser[msg.sender] - _amount;
        balanceOfUser[address(this)] = balanceOfUser[address(this)] - _amount;
        npngToken.burn(msg.sender, _amount);
    }

    // function claimRewards(uint _idContest) public {
    //     require (calculateRewards(_idContest, msg.sender) > 0,"No reward to claim");
    // }

    /// READ FUNCTIONS
    function getMyBalance(address _account) public view returns (uint) {
        return (balanceOfUser[_account]);
    }

    function interestEarned() public view returns (uint) {
        return (aUsdcToken.balanceOf(address(this)) -
            balanceOfUser[address(this)]);
    }

    function getTotalAmountTopPlayers(uint _idContest)
        public
        view
        returns (uint)
    {
        uint totalAmountTopPlayers = 0;
        ContestsResult[10] memory topPlayers = NpngGame.getTopPlayers(
            _idContest
        );
        for (uint i = 0; i < 10; i++) {
            totalAmountTopPlayers = totalAmountTopPlayers + topPlayers[i].score;
        }
        return (totalAmountTopPlayers);
    }

    function calculateRewards(uint _idContest, address _player)
        public
        view
        returns (uint)
    {
        uint playerRank = NpngGame.checkPlayerRank(_idContest, _player);
        uint playerDeposit = balanceOfUser[_player];
        uint totalAmountTopPlayers = getTotalAmountTopPlayers(_idContest);
        uint playerReward = (playerDeposit / totalAmountTopPlayers) *
            139 *
            (1 - playerRank / 100)**5;
        return (playerReward);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NpngGame is Ownable {
    struct ContestsResult {
        uint idContest;
        address player;
        uint score;
    }

    ContestsResult[] public contestsResult;
    mapping(uint => uint) public numberOfPlayersPerContest;
    uint private contestInit;
    uint private gameFrequence;
    uint private currentIdContest;
    uint private startContestTimestamp;
    uint private lastContestTimestamp;

    constructor() {
        startContestTimestamp = block.timestamp;
        lastContestTimestamp = startContestTimestamp;
        currentIdContest = 1;
        //1 semaine 604800s ; 1 jour = 86400s ; 5 minutes = 300s
        gameFrequence = 86400;
    }

    /// WRITE FUNCTIONS

    function updateIdContest() public {
        uint currentTimestamp = block.timestamp;
        uint numberNewContest = (currentTimestamp - lastContestTimestamp) /
            gameFrequence;
        if (numberNewContest > 0) {
            currentIdContest += numberNewContest;
            lastContestTimestamp = currentTimestamp;
        }
    }

    function changeGameFrequence(uint _newFrequence) public onlyOwner {
        gameFrequence = _newFrequence;
    }

    function saveScore(address player, uint score) public onlyOwner {
        updateIdContest();
        contestsResult.push(ContestsResult(currentIdContest, player, score));
        numberOfPlayersPerContest[currentIdContest] =
            numberOfPlayersPerContest[currentIdContest] +
            1;
    }

    /// READ FUNCTIONS

    function getCurrentIdContest() public view returns (uint) {
        return (currentIdContest);
    }

    function getGameFrequence() public view returns (uint) {
        return (gameFrequence);
    }

    function getScore() public view returns (ContestsResult[] memory) {
        return (contestsResult);
    }

    function getTopPlayers(uint _idContest)
        public
        view
        returns (ContestsResult[10] memory)
    {
        ContestsResult[10] memory topContest;
        for (uint i = 0; i < 10; i++) {
            topContest[i] = ContestsResult(
                _idContest,
                0x000000000000000000000000000000000000dEaD,
                0
            );
        }
        for (uint i = 0; i < 10; i++) {
            ContestsResult memory tempResult = topContest[9];
            for (uint j = 0; j < contestsResult.length; j++) {
                if (
                    contestsResult[j].idContest == _idContest &&
                    contestsResult[j].player != topContest[0].player &&
                    contestsResult[j].player != topContest[1].player &&
                    contestsResult[j].player != topContest[2].player &&
                    contestsResult[j].player != topContest[3].player &&
                    contestsResult[j].player != topContest[4].player &&
                    contestsResult[j].player != topContest[5].player &&
                    contestsResult[j].player != topContest[6].player &&
                    contestsResult[j].player != topContest[7].player &&
                    contestsResult[j].player != topContest[8].player &&
                    contestsResult[j].score > tempResult.score
                ) {
                    tempResult = contestsResult[j];
                }
            }
            topContest[i] = tempResult;
        }
        return (topContest);
    }

    function checkPlayerRank(uint _idContest, address _player)
        public
        view
        returns (uint)
    {
        ContestsResult[10] memory listTopPlayers = getTopPlayers(_idContest);
        uint playerRank = 0;
        for (uint i = 0; i < 10; i++) {
            if (_player == listTopPlayers[i].player) {
                playerRank = i + 1;
                break;
            }
        }
        return (playerRank);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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