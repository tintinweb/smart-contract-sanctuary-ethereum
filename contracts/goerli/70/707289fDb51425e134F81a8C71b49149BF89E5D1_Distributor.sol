// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

//                   @
//                 @@@@@
//              @  @@@@@@@@                       @@@@@@@@@@@@@@@@@@                          @@@@@@@@@@@@@@
//           [email protected]@@@@@ @@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@
//         @@@@@@@@ @@& @@@@@@@@               @@@@                   @@@@          @@@#   @@@              @@@@   @@@@@@@@@@@@@@@#
//      @@@@@@@@@ @@@@@@@ @@@@@@@ .            @@@@                   @@@@          @@@#   @@@              @@@@   @@@@@@@@@@@@@@@@@
//    @@@@@@@@ @@@@@@@@      @ @@@@@@          @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@
//    @@@@@@@@  @@@@@@@@     @@@@@@@@          @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@
//      /@@@@@@@@ @@@@@@@@@@@@@@@@             @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@
//         @@@@@@@@  @@@@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@#   @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@
//            @@@@@@ @@@@@@@@                   @@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@#    @@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@
//              @  @@@@@@@@                                                         @@@#                           @@@@
//                 @@@@@                                                 @@@@@@@@@@@@@@                            @@@@
//                   @

// TODO: Add event for reward.
// TODO: Add max cyop balance to limit rewards.

// Import libraries.
import "@openzeppelin/contracts/access/Ownable.sol"; // Access control mechanism for smart contract functions.
import "@openzeppelin/contracts/security/Pausable.sol"; // An emergency stop mechanism.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Interface of the ERC20 standard as defined in the EIP.
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Safe operations with ERC20 tokens.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Prevents reentrant calls to functions.
import "./interfaces/IDEXRouter.sol"; // The DEX Router Interface.
import "./libs/EIP712DataValidator.sol"; // Signed data validator.

/**
 * @title The interface for the Cycle smart contract.
 * @dev The following interface is used to properly call functions of the Cycle smart contract.
 */
interface ICycle {
    /**
     * @notice Checks if a cycle has ended.
     * @param cycleIndex The index of the cycle to check.
     * @return True if the cycle has finished, otherwise false.
     */
    function isCycleFinished(uint256 cycleIndex) external view returns (bool);

    /**
     * @notice Gets the end time of a cycle by its index.
     * @param cycleIndex The index of the cycle to check.
     * @return The end time of a cycle.
     */
    function getCycleEndTime(uint256 cycleIndex) external view returns (uint256);
}

/**
 * @title The interface for the CyOp smart contract.
 * @dev The following interface is used to properly call functions of the CyOp smart contract.
 */
interface ICyOp is IERC20 {
    /**
     * @notice Manually triggers the transfer of funds from the CyOp contract to the treasuries.
     */
    function manualswapTreasury() external;
}

/**
 * @notice The error that is thrown when balances of users are lower at the end
           of a voting cycle than at its beginning.
 * @param startBalance The initial balance of users at the start of the cycle.
 * @param endBalance The balance of the users at the end of the cycle.
 */
error LowerBalanceError(uint256 startBalance, uint256 endBalance);
/**
 * @notice The error that is thrown when claiming an already claimed reward.
 * @param cycleIndex The index of a cycle.
 * @param userAddress The address of a user.
 */
error RewardAlreadyClaimedError(uint256 cycleIndex, address userAddress);

/**
 * @title The Distributor smart contract.
 * @notice This is a smart contract that is used to distribute funds between entities.
 * @dev The following smart contract is responsible for distributing funds gathered during voting cycles.
        The smart contract sends the funds to the voting winers, participants, and lucky users.
 */
contract Distributor is Context, Ownable, Pausable, EIP712DataValidator, ReentrancyGuard {
    // Safe operations with ERC20 tokens.
    using SafeERC20 for IERC20;

    /// @notice Types of stakers.
    enum StakerType {
        CyOpStaker,
        UNFTStaker
    }

    /**
     * @notice The permilles of funds that are split between the entities every cycle.
     */
    struct Splits {
        /// @notice The permille of funds that goes to the Vault.
        uint32 vault;
        /// @notice The permille of funds that are burned.
        uint32 burn;
        /// @notice The permille of funds that are kept in the smart contract.
        uint32 keep;
        /// @notice The permille of funds that goes to the winner.
        uint32 firstPlace;
        /// @notice The permille of funds that goes to the 2nd place.
        uint32 secondPlace;
        /// @notice The permille of funds that goes to the 3rd place.
        uint32 thirdPlace;
        /// @notice The permille of the Vault funds that goes to the CyOp stakers.
        uint32 cyopStakers;
        /// @notice The permille of the Vault funds that goes to the uNFT stakers.
        uint32 uNFTStakers;
        /// @notice The permille of the Vault funds that goes to the lucky users.
        uint32 luckyUser;
    }

    /**
     * @notice The reward details.
     */
    struct Ticket {
        /// @notice The reward receiver wallet address.
        address user;
        /// @notice The type of the staker.
        StakerType stakerType;
        /// @notice The index of the voting cycle.
        uint256 cycleIndex;
        /// @notice The amount of CyOp a user had at the start of the cycle.
        uint256 startCyOpAmount;
        /// @notice The number of uNFT a user had at the start of the cycle.
        uint256 startUNFTAmount;
    }

    /**
     * @notice The struct contains Cycle voting results.
     */
    struct CycleResults {
        /// @notice The index of the cycle.
        uint256 cycleIndex;
        /// @notice The total amount of CyOp of voters in the voting cycle.
        uint256 totalCyOpAmount;
        /// @notice The total number of uNFT of voters in the voting cycle.
        uint256 totalUNFTAmount;
        /// @notice The wallet address of the winner.
        address firstPlace;
        /// @notice The wallet address of the runner up.
        address secondPlace;
        /// @notice The wallet address of the second runner up.
        address thirdPlace;
        /// @notice The wallet address of the lucky user.
        address luckyUser;
        /// @notice The flag indicates if the winner is a user or a token.
        bool isFirstPlaceToken;
        /// @notice The flag indicates if the runner up is a user or a token.
        bool isSecondPlaceToken;
        /// @notice The flag indicates if the second runner up is a user or a token.
        bool isThirdPlaceToken;
        /// @notice The swap path in case if the winner is a token.
        address[] firstPlacePath;
        /// @notice The swap path in case if the runner up is a token.
        address[] secondPlacePath;
        /// @notice The swap path in case if the second runner up is a token.
        address[] thirdPlacePath;
        /// @notice The addresses of the DEX routers that are used to swap tokens if the winners are tokens.
        address[] dexRouters;
    }

    /**
     * @notice The struct is used to store fund states during different cycles (in reward tokens).
     */
    struct CycleFunds {
        /// @notice The amount sent to the first place.
        uint256 firstPlaceAmount;
        /// @notice The amount sent to the second place.
        uint256 secondPlaceAmount;
        /// @notice The amount sent to the third place.
        uint256 thirdPlaceAmount;
        /// @notice The amount shared between CyOp stakers.
        uint256 cyopStakersAmount;
        /// @notice The amount shared between uNFT stakers.
        uint256 uNFTStakersAmount;
        /// @notice The amount sent to a lucky user.
        uint256 luckyUserAmount;
        /// @notice The amount burnt.
        uint256 burnAmount;
    }

    // TODO: Set to the mainnet values.
    /// @notice Address of WETH.
    //address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    /// @notice Address of USDC.
    //address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    /// @notice Address of the Uniswap v2 Router.
    address public constant UNISWAP_ROUTER_V2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    /// @notice The Vault contract.
    address public vaultAddress;
    /// @notice The address of the Holding Fund.
    address public holdingFundAddress;
    /// @notice The address of the authorized operator that is responsible for calling functions to distribute prizes to the winners.
    address public authorizedOperator;
    /// @notice The address where the burned CyOp tokens are sent.
    address public burnAddress;
    /// @notice The path from the reward token to CyOp.
    address[] public rewardToCyopPath;
    /// @notice The path from WETH to the reward token.
    address[] public wethToRewardPath;
    /// @notice The period during which it is allowed to claim a reward (exp. date).
    uint256 public claimPeriod;
    /// @notice The CyOp smart contract that is used to get reward funds.
    ICyOp public cyopContract;
    /// @notice The partial interfaces of the Cycle smart contract. Is used to operate with the Cycle contract.
    ICycle public cycleContract;
    /// @notice The DEX that is used to convert CyOp tokens to the reward tokens (default is USDC).
    IDEXRouter public dexRouter;
    /// @notice The reward token (defaults to USDC).
    IERC20 public rewardToken;
    /// @notice The fund splitter struct that contains permilles of funds that go to different entities.
    Splits public splits;
    /// @notice The mapping of the claimed rewards.
    mapping(StakerType => mapping(uint256 => mapping(address => bool))) public isRewardClaimed;
    /// @notice The cycle results data (cycle index => cycle results).
    mapping(uint256 => CycleResults) public cycleResults;
    /// @notice The funds shared between entities in cycles.
    mapping(uint256 => CycleFunds) public cycleFunds;

    /**
     * @notice The constructor that initializes the current smart contract.
     * @param cycleContractAddress The address of the cycle smart contract.
     * @param cyopContractAddress The address of the CyOp smart contract.
     * @param vaultAddress_ The address of the Vault.
     * @param holdingFundAddress_ The wallet address of the Holding Fund.
     * @param burnAddress_ The address where the burned CyOp tokens are sent.
     * @param authorizedOperator_ The wallet address of the authorized operator.
     * @param splits_ The encoded array of permilles of funds that go to different entities every cycle.

     */
    constructor(
        address cycleContractAddress,
        address cyopContractAddress,
        address vaultAddress_,
        address holdingFundAddress_,
        address burnAddress_,
        address authorizedOperator_,
        bytes memory splits_
    ) {
        // Set the state variables.
        require(cycleContractAddress != address(0), "CYCLE_CONTRACT_ADDRESS_CANT_BE_ZERO");
        require(cyopContractAddress != address(0), "CYOP_CONTRACT_ADDRESS_CANT_BE_ZERO");
        require(vaultAddress_ != address(0), "VAULT_CONTRACT_ADDRESS_CANT_BE_ZERO");
        require(holdingFundAddress_ != address(0), "HOLDING_FUND_ADDRESS_CANT_BE_ZERO");
        require(authorizedOperator_ != address(0), "OPERATOR_ADDRESS_CANT_BE_ZERO");
        cycleContract = ICycle(cycleContractAddress);
        cyopContract = ICyOp(cyopContractAddress);
        vaultAddress = vaultAddress_;
        holdingFundAddress = holdingFundAddress_;
        burnAddress = burnAddress_;
        authorizedOperator = authorizedOperator_;
        splits = abi.decode(splits_, (Splits));
        require(
            splits.vault + splits.burn + splits.keep + splits.firstPlace + splits.secondPlace + splits.thirdPlace ==
                1000,
            "INCORRECT_SPLITS"
        );
        require(splits.cyopStakers + splits.uNFTStakers + splits.luckyUser <= 1000, "INCORRECT_SPLITS");
        dexRouter = IDEXRouter(UNISWAP_ROUTER_V2); // Set to Uniswap v2 Router by default.
        rewardToken = IERC20(USDC); // Set to USDC by default.
        rewardToCyopPath = [USDC, WETH, cyopContractAddress]; // Default path.
        wethToRewardPath = [WETH, USDC]; // Default path.
        claimPeriod = 365 days; // Defaults to 1 year.
    }

    /**
     * @notice The callback is executed on calls to the current smart contract that have no data (calldata), such as calls made via send() or transfer().
     * @dev The main function of this callback is to react to receiving ether.
     */
    receive() external payable {}

    /**
     * @notice Collects, converts, and operates with funds.
     * @param cycleIndex The index of the cycle to manage funds of.
     */
    function manageFunds(uint256 cycleIndex) external {
        require(msg.sender == address(cycleContract), "UNAUTHORIZED_CALL");
        cyopContract.manualswapTreasury();
        _convertFunds();
        _distributeFunds(cycleIndex);
    }

    /**
     * @notice Sends the prizes the top three winners.
     * @param data The information about the winners and prizes.
     */
    function distributePrizes(bytes calldata data) external nonReentrant {
        // Check if a call to the function is made by an authorized operator.
        require(msg.sender == authorizedOperator, "UNAUTHORIZED_CALL");
        // Unpack the data.
        CycleResults memory results = abi.decode(data, (CycleResults));
        // Check the data.
        require(cycleContract.isCycleFinished(results.cycleIndex), "CYCLE_NOT_FINISHED");
        require(cycleResults[results.cycleIndex].cycleIndex == 0, "PRIZES_ALREADY_DISTRIBUTED");
        // Store data.
        cycleResults[results.cycleIndex] = results;
        // Transfer the prizes.
        _transferPrize(
            results.firstPlace,
            results.isFirstPlaceToken,
            cycleFunds[results.cycleIndex].firstPlaceAmount,
            results.dexRouters[0],
            results.firstPlacePath
        );
        _transferPrize(
            results.secondPlace,
            results.isSecondPlaceToken,
            cycleFunds[results.cycleIndex].secondPlaceAmount,
            results.dexRouters[1],
            results.secondPlacePath
        );
        _transferPrize(
            results.thirdPlace,
            results.isThirdPlaceToken,
            cycleFunds[results.cycleIndex].thirdPlaceAmount,
            results.dexRouters[2],
            results.thirdPlacePath
        );
        rewardToken.safeTransfer(results.luckyUser, cycleFunds[results.cycleIndex].luckyUserAmount);
    }

    /**
     * @notice Rewards the CyOp and uNFT stakers.
     * @dev Calls the Distributor to distribute rewards to the users.
     * @param data The information about the user and the reward.
     * @param encodedData The encoded information.
     * @param signature The signature of the data.
     */
    function claimReward(
        bytes calldata data,
        bytes32 encodedData,
        bytes calldata signature
    ) external nonReentrant {
        // Verify the signature.
        require(isValidDataSignature(data, encodedData, signature), "INVALID_SIGNATURE");
        // Unpack data.
        Ticket[] memory tickets = abi.decode(data, (Ticket[]));

        // Reward users.
        for (uint256 i = 0; i < tickets.length; i++) {
            uint256 cycleIndex = tickets[i].cycleIndex;
            address user = tickets[i].user;
            // Check if we have results for the cycle.
            require(cycleResults[cycleIndex].cycleIndex == cycleIndex, "NO_CYCLE_RESULTS");
            // Get the end time of the cycle.
            uint256 cycleEndTime = cycleContract.getCycleEndTime(cycleIndex);
            // Check the deadlines.
            require(block.timestamp - cycleEndTime < claimPeriod, "REWARD_EXPIRED");
            uint256 reward;

            if (tickets[i].stakerType == StakerType.CyOpStaker) {
                // Check if the reward has been already claimed.
                if (isRewardClaimed[StakerType.CyOpStaker][cycleIndex][user]) {
                    revert RewardAlreadyClaimedError({
                        cycleIndex: cycleIndex,
                        userAddress: user
                    });
                }

                // Store claimed reward.
                isRewardClaimed[StakerType.CyOpStaker][cycleIndex][user] = true;
                // Calculate reward.
                reward =
                    (tickets[i].startCyOpAmount * cycleFunds[cycleIndex].cyopStakersAmount) /
                    cycleResults[cycleIndex].totalCyOpAmount;
            } else if (tickets[i].stakerType == StakerType.UNFTStaker) {
                // Check if the reward has been already claimed.
                if (isRewardClaimed[StakerType.UNFTStaker][cycleIndex][user]) {
                    revert RewardAlreadyClaimedError({
                        cycleIndex: cycleIndex,
                        userAddress: user
                    });
                }

                // Store claimed reward.
                isRewardClaimed[StakerType.UNFTStaker][tickets[i].cycleIndex][user] = true;
                // Calculate reward.
                reward =
                    (tickets[i].startUNFTAmount * cycleFunds[tickets[i].cycleIndex].uNFTStakersAmount) /
                    cycleResults[tickets[i].cycleIndex].totalUNFTAmount;
            } else {
                revert("INVALID_REWARD_TYPE");
            }

            // Check if reward was calculated.
            require(reward > 0, "UNEXPECTED_REWARD_VALUE");
            rewardToken.safeTransfer(user, reward);
        }
    }

    /**
     * @notice Sets a new CyOp smart contract.
     * @param cyopContractAddress The address of the new CyOp smart contract to set.
     */
    function setCyOpAddress(address cyopContractAddress) external onlyOwner {
        require(cyopContractAddress != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        cyopContract = ICyOp(cyopContractAddress);
    }

    /**
     * @notice Sets a new DEX router.
     * @param dexRouterAddress The address of the new DEX router smart contract to set.
     */
    function setDexRouterAddress(address dexRouterAddress) external onlyOwner {
        require(dexRouterAddress != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        dexRouter = IDEXRouter(dexRouterAddress);
    }

    /**
     * @notice Sets a new reward token.
     * @param rewardTokenAddress The address of the new reward token to set.
     */
    function setRewardTokenAddress(address rewardTokenAddress) external onlyOwner {
        require(rewardTokenAddress != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        rewardToken = IERC20(rewardTokenAddress);
        rewardToCyopPath = [rewardTokenAddress, address(cyopContract)];
        wethToRewardPath = [WETH, rewardTokenAddress];
    }

    /**
     * @notice Sets a new path for swaping WETH for reward tokens.
     * @param path The path that is used to swap WETH for reward tokens.
     */
    function setWethToRewardPath(address[] memory path) external onlyOwner {
        require(path.length >= 2 && path[0] == WETH && path[path.length - 1] == address(rewardToken), "INVALID_PATH");
        if (path.length > 2) {
            for (uint256 i = 1; i < path.length - 1; i++) {
                require(path[i] != address(0), "INVALID_ADDRESS");
            }
        }
        wethToRewardPath = path;
    }

    /**
     * @notice Sets a new path for swaping reward tokens for CyOp tokens.
     * @param path The path that is used to swap reward tokens for CyOp tokens.
     */
    function setRewardToCyOpPath(address[] memory path) external onlyOwner {
        require(
            path.length >= 2 && path[0] == address(rewardToken) && path[path.length - 1] == address(cyopContract),
            "INVALID_PATH"
        );
        if (path.length > 2) {
            for (uint256 i = 1; i < path.length - 1; i++) {
                require(path[i] != address(0), "INVALID_ADDRESS");
            }
        }
        rewardToCyopPath = path;
    }

    /**
     * @notice Sets a new burn address.
     * @param burnAddress_ The new burn address to set.
     */
    function setBurnAddress(address burnAddress_) external onlyOwner {
        burnAddress = burnAddress_;
    }

    /**
     * @notice Sets a new Vault address.
     * @param vaultAddress_ The address of the new Vault to set.
     */
    function setVaultAddress(address vaultAddress_) external onlyOwner {
        require(vaultAddress_ != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        vaultAddress = vaultAddress_;
    }

    /**
     * @notice Sets split permilles between entities that receive funds.
     * @param splits_ The encoded fund splitter struct containing new split values.
     */
    function setSplits(bytes calldata splits_) external onlyOwner {
        splits = abi.decode(splits_, (Splits));
        require(
            splits.vault + splits.burn + splits.keep + splits.firstPlace + splits.secondPlace + splits.thirdPlace ==
                1000,
            "INCORRECT_SPLITS"
        );
        require(splits.cyopStakers + splits.uNFTStakers + splits.luckyUser <= 1000, "INCORRECT_SPLITS");
    }

    /**
     * @notice Sets a new holding fund address.
     * @param holdingFundAddress_ The new address to set.
     */
    function setHoldingFundAddress(address holdingFundAddress_) external onlyOwner {
        require(holdingFundAddress_ != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        holdingFundAddress = holdingFundAddress_;
    }

    /**
     * @notice Sets a new Cycle smart contract.
     * @param cycleContractAddress The address of the new Cycle smart contract to set.
     */
    function setCycleAddress(address cycleContractAddress) external onlyOwner {
        require(cycleContractAddress != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        cycleContract = ICycle(cycleContractAddress);
    }

    /**
     * @notice Sets a new authorized operator.
     * @param authorizedOperator_ The address of the new operator.
     */
    function setAuthorizedOperator(address authorizedOperator_) external onlyOwner {
        require(authorizedOperator_ != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        authorizedOperator = authorizedOperator_;
    }

    /**
     * @notice Sets a new expiration date for rewards.
     * @param period The new period value in seconds.
     */
    function setClaimPeriod(uint256 period) external onlyOwner {
        claimPeriod = period;
    }

    /**
     * @notice Used to remove funds from the contract. Only use in case of emergency.
     * @param amount The amount of ETH to withdraw.
     * @return True, if the transfer was successful.
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner returns (bool) {
        (bool sent, ) = payable(msg.sender).call{ value: amount }("");
        require(sent, "FUND_TRANSFER_FAILED");
        return true;
    }

    /**
     * @notice Withdraws ERC20 tokens to the owner wallet.
     * @param token The address of ERC20 token to withdraw.
     */
    function emergencyWithdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, balance);
    }

    /**
     * @notice Buys the winning tokens and transfers them to the holding fund.
     * @param tokenAddress The address of the token smart contract.
     * @param reward The reward amount.
     * @param dexRouterAddress The address of the DEX that is used to convert the tokens.
     * @param path The swap path.
     */
    function _transferTokenReward(
        address tokenAddress,
        uint256 reward,
        address dexRouterAddress,
        address[] memory path
    ) internal {
        // Check if the token address is the end of the swap path.
        require(path[0] == address(rewardToken) && path[path.length - 1] == tokenAddress, "INVALID_PATH_OR_TOKEN_ADDRESS");
        IDEXRouter router = IDEXRouter(dexRouterAddress);
        // Approve the DEX to operate with funds.
        for (uint256 i = 0; i < path.length; i++) {
            if (IERC20(path[i]).allowance(address(this), address(router)) < type(uint256).max) {
                IERC20(path[i]).approve(address(router), type(uint256).max);
            }
        }
        // Get the winning tokens and transfer them to the holding fund.
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            reward,
            0,
            path,
            holdingFundAddress,
            block.timestamp
        );
    }

    /**
     * @notice Transfer prizes to the winners.
     * @dev If the winner is a user, then winnerAddress is the user's wallet address
     *      and the winning amount is transferred to the user. If the winner is a token
     *      then the winning amount is swaped for the token and transferred to the holding fund.
     * @param winnerAddress The wallet address or a token address of the winner.
     * @param isToken Indicates if the winner is a token or a wallet address.
     * @param amount Amount of the prize.
     * @param dexRouterAddress The address of a DEX router to use to swap the tokens. Is used only if the winner is a token.
     * @param path The path array of the swap. Is used only if the winner is a token.
     */
    function _transferPrize(
        address winnerAddress,
        bool isToken,
        uint256 amount,
        address dexRouterAddress,
        address[] memory path
    ) internal {
        if (winnerAddress == address(0)) return;
        if (isToken) {
            _transferTokenReward(winnerAddress, amount, dexRouterAddress, path);
        } else {
            rewardToken.safeTransfer(winnerAddress, amount);
        }
    }

    /**
     * @notice Converts CyOp tokens to USDC.
     */
    function _convertFunds() internal {
        // Converting all ETH to the Reward token.
        // Input amount is the total balance of ETH of the current contract.
        uint256 amountIn = address(this).balance;
        for (uint256 i = 0; i < wethToRewardPath.length - 1; i++) {
            if (IERC20(wethToRewardPath[i]).allowance(address(this), address(dexRouter)) < type(uint256).max) {
                IERC20(wethToRewardPath[i]).approve(address(dexRouter), type(uint256).max);
            }
        }
        // Swap the tokens.
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(
            0,
            wethToRewardPath,
            address(this),
            block.timestamp
        );
    }

    /**
     * @notice Distributes funds between entities every cycle based on the permilles specified in the `splits` struct.
     */
    function _distributeFunds(uint256 cycleIndex) internal {
        // Calculate splits (portions of the total amount of funds that go to different entities).
        uint256 totalAmount = rewardToken.balanceOf(address(this));
        uint256 vaultAmount = _getSplit(totalAmount, splits.vault);
        uint256 firstPlaceAmount = _getSplit(totalAmount, splits.firstPlace);
        uint256 secondPlaceAmount = _getSplit(totalAmount, splits.secondPlace);
        uint256 thirdPlaceAmount = _getSplit(totalAmount, splits.thirdPlace);
        uint256 burnAmount = _getSplit(totalAmount, splits.burn);
        // Transfer the reward funds to the vault.
        rewardToken.safeTransfer(vaultAddress, vaultAmount);
        // Calculate the rewards amount for the current cycle.
        uint256 totalVaultAmount = rewardToken.balanceOf(vaultAddress);
        uint256 cyopStakersAmount = _getSplit(totalVaultAmount, splits.cyopStakers);
        uint256 uNFTStakersAmount = _getSplit(totalVaultAmount, splits.uNFTStakers);
        uint256 luckyUserAmount = _getSplit(totalVaultAmount, splits.luckyUser);
        uint256 totalRewardsAmount = cyopStakersAmount + uNFTStakersAmount + luckyUserAmount;
        // Store the info.
        cycleFunds[cycleIndex] = CycleFunds({
            firstPlaceAmount: firstPlaceAmount,
            secondPlaceAmount: secondPlaceAmount,
            thirdPlaceAmount: thirdPlaceAmount,
            cyopStakersAmount: cyopStakersAmount,
            uNFTStakersAmount: uNFTStakersAmount,
            luckyUserAmount: luckyUserAmount,
            burnAmount: burnAmount
        });
        // Get funds from the vault.
        rewardToken.safeTransferFrom(vaultAddress, address(this), totalRewardsAmount);
        // Swap and burn the tokens.
        for (uint256 i = 0; i < rewardToCyopPath.length; i++) {
            if (IERC20(rewardToCyopPath[i]).allowance(address(this), address(dexRouter)) < type(uint256).max) {
                IERC20(rewardToCyopPath[i]).approve(address(dexRouter), type(uint256).max);
            }
        }
        dexRouter.swapExactTokensForTokens(burnAmount, 0, rewardToCyopPath, burnAddress, block.timestamp);
    }

    /**
     * @notice Gets the entity split based on its permille value.
     * @param total The total amount.
     * @param permille The permille of total amount to calculate.
     * @return `permille` of `total` amount.
     */
    function _getSplit(uint256 total, uint32 permille) internal pure returns (uint256) {
        return (total * permille) / 1000;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

//                   @                                                                                                               
//                 @@@@@                                                                                                             
//              @  @@@@@@@@                       @@@@@@@@@@@@@@@@@@                          @@@@@@@@@@@@@@                         
//           [email protected]@@@@@ @@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@                      
//         @@@@@@@@ @@& @@@@@@@@               @@@@                   @@@@          @@@#   @@@              @@@@   @@@@@@@@@@@@@@@#  
//      @@@@@@@@@ @@@@@@@ @@@@@@@ .            @@@@                   @@@@          @@@#   @@@              @@@@   @@@@@@@@@@@@@@@@@ 
//    @@@@@@@@ @@@@@@@@      @ @@@@@@          @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@ 
//    @@@@@@@@  @@@@@@@@     @@@@@@@@          @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@ 
//      /@@@@@@@@ @@@@@@@@@@@@@@@@             @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@ 
//         @@@@@@@@  @@@@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@#   @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@ 
//            @@@@@@ @@@@@@@@                   @@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@#    @@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@   
//              @  @@@@@@@@                                                         @@@#                           @@@@              
//                 @@@@@                                                 @@@@@@@@@@@@@@                            @@@@              
//                   @                                                                                                               

// Import libraries.
import "@openzeppelin/contracts/access/Ownable.sol"; // Access control mechanism for smart contract functions.
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Elliptic Curve Digital Signature Algorithm operations.

/**
 * @title The Data Validator smart contract.
 * @dev The following contract is used to check whether data transmitted to smart contracts
        was signed using the valid private key.
 */
contract EIP712DataValidator is Context, Ownable {
    using ECDSA for bytes32;
    /// @notice The signing name that is used in the domain separator.
    string public constant SIGNING_NAME = "CYOP_DATA_VALIDATOR";
    /// @notice The version that is used in the domain separator.
    string public constant VERSION = "1.0.0";
    /// @notice The type hash of the data that was signed.
    bytes32 public constant TYPE_HASH = keccak256("Data(bytes32 data)");
    /// @notice The wallet address that is used to sign data.
    address public signingAddress;
    /// @notice Domain Separator is the EIP-712 defined structure that defines what contract
    //          and chain these signatures can be used for.  This ensures people can't take
    //          a signature used to mint on one contract and use it for another, or a signature
    //          from testnet to replay on mainnet.
    /// @dev It has to be created in the constructor so we can dynamically grab the chainId.
    ///      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 public domainSeparator;

    /**
     * @notice The constructor that initializes the current smart contract.
     */
    constructor() {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(SIGNING_NAME)),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Sets signing key used for whitelisting.
     * @param signingAddress_ The signing key.
     */
    function setSigningAddress(address signingAddress_) external onlyOwner {
        signingAddress = signingAddress_;
    }

    /**
     * @notice Checks if a signature provided is valid.
     * @param data The data that was signed.
     * @param encodedData The encoded version of the data.
     * @param signature The data signing signature.
     * @return True if the signature is valid, else - false.
     */
    function isValidDataSignature(bytes calldata data, bytes32 encodedData, bytes calldata signature) public view returns (bool) {
        require(signingAddress != address(0), "SIGNING_ADDRESS_NOT_SET");
        // Check if the encoded data and data are the same.
        require(keccak256(data) == encodedData, "INVALID_DATA");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, keccak256(abi.encode(TYPE_HASH, encodedData))));
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        return recoveredAddress == signingAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

/**
 * @title The DEX Router Interface.
 * @dev This is an interface to operate with the Uniswap V2-like dexes.
 */
interface IDEXRouter {
    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible. Takes fees into account.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
    external;

    /**
     * @notice Swaps an exact amount of ETH for as many output tokens as possible. Takes fees into account.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param to Recipient of the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    payable;

    /**
     * @notice Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts.
     * @param amountIn The amount of input tokens.
     * @param path An array of token addresses.
     * @return amounts The amounts.
     */
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Distributor.sol";

abstract contract $ICycle is ICycle {
    constructor() {}

    receive() external payable {}
}

abstract contract $ICyOp is ICyOp {
    constructor() {}

    receive() external payable {}
}

contract $Distributor is Distributor {
    constructor(address cycleContractAddress, address cyopContractAddress, address vaultAddress_, address holdingFundAddress_, address burnAddress_, address authorizedOperator_, bytes memory splits_) Distributor(cycleContractAddress, cyopContractAddress, vaultAddress_, holdingFundAddress_, burnAddress_, authorizedOperator_, splits_) {}

    function $_transferTokenReward(address tokenAddress,uint256 reward,address dexRouterAddress,address[] calldata path) external {
        return super._transferTokenReward(tokenAddress,reward,dexRouterAddress,path);
    }

    function $_transferPrize(address winnerAddress,bool isToken,uint256 amount,address dexRouterAddress,address[] calldata path) external {
        return super._transferPrize(winnerAddress,isToken,amount,dexRouterAddress,path);
    }

    function $_convertFunds() external {
        return super._convertFunds();
    }

    function $_distributeFunds(uint256 cycleIndex) external {
        return super._distributeFunds(cycleIndex);
    }

    function $_getSplit(uint256 total,uint32 permille) external pure returns (uint256) {
        return super._getSplit(total,permille);
    }

    function $_requireNotPaused() external view {
        return super._requireNotPaused();
    }

    function $_requirePaused() external view {
        return super._requirePaused();
    }

    function $_pause() external {
        return super._pause();
    }

    function $_unpause() external {
        return super._unpause();
    }

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IDEXRouter.sol";

abstract contract $IDEXRouter is IDEXRouter {
    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libs/EIP712DataValidator.sol";

contract $EIP712DataValidator is EIP712DataValidator {
    constructor() {}

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}