// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./utils/interfaces/IAmorGuildToken.sol";
import "./utils/interfaces/IFXAMORxGuild.sol";
import "./utils/interfaces/IGuildController.sol";
import "./utils/interfaces/IMetaDaoController.sol";

/// Advanced math functions for bonding curve
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title GuildController contract
/// @author Daoism Systems Team
/// @notice GuildController contract controls the all of the deployed contracts of the guild

contract GuildController is IGuildController, Ownable {
    using SafeERC20 for IERC20;

    int256[] public reportsWeight; // this is an array, which describes the amount of the weight of each report.(So the reports will later receive payments based on this weight)
    mapping(uint256 => mapping(address => int256)) public votes; // votes mapping(uint report => mapping(address voter => int256 vote))
    mapping(uint256 => address[]) public voters; // voters mapping(uint report => address [] voters)
    int256[] public reportsVoting; // results of the vote for the report with spe
    mapping(uint256 => address) public reportsAuthors;
    uint256 public totalReportsWeight; // total Weight of all of reports

    address[] public impactMakers; // list of impactMakers of this DAO

    // user --> token --> amount
    mapping(address => mapping(address => uint256)) public claimableTokens; // amount of tokens each specific address(impactMaker) can claim
    mapping(address => uint256) public weights; // weight of each specific Impact Maker/Builder
    uint256 public totalWeight; // total Weight of all of the impact makers
    uint256 public timeVoting; // deadlines for the votes for reports

    IERC20 private ERC20AMORxGuild;
    IFXAMORxGuild private FXGFXAMORxGuild;
    address public AMOR;
    address public AMORxGuild;
    address public dAMORxGuild;
    address public FXAMORxGuild;
    address public MetaDaoController;

    bool public trigger; // set true for a week if previous week were added >= 10 reports; users can vote only if trigger == true
    uint256[] public reportsQueue;
    mapping(uint256 => address) public queueReportsAuthors;

    uint256 public additionalVotingTime;
    uint256 public constant WEEK = 7 days; // 1 week is the time for the users to vore for the specific report
    uint256 public constant DAY = 1 days;
    uint256 public constant HOUR = 1 hours;
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public percentToConvert; //10% // FEE_DENOMINATOR/100*10

    event Initialized(bool success, address owner, address AMORxGuild);

    bool private _initialized;

    error AlreadyInitialized();
    error Unauthorized();
    error EmptyArray();
    error InvalidParameters();
    error VotingTimeExpired();
    error VotingTimeNotFinished();
    error ReportNotExists();
    error InvalidAmount();
    error VotingNotStarted();
    error NotWhitelistedToken();

    /// Invalid address. Needed address != address(0)
    error AddressZero();

    /// Invalid address to transfer. Needed `to` != msg.sender
    error InvalidSender();

    function init(
        address initOwner,
        address AMOR_,
        address AMORxGuild_,
        address FXAMORxGuild_,
        address MetaDaoController_
    ) external returns (bool) {
        if (_initialized) {
            revert AlreadyInitialized();
        }
        _transferOwnership(initOwner);

        AMOR = AMOR_;
        AMORxGuild = AMORxGuild_;
        ERC20AMORxGuild = IERC20(AMORxGuild_);
        FXGFXAMORxGuild = IFXAMORxGuild(FXAMORxGuild_);
        FXAMORxGuild = FXAMORxGuild_;
        MetaDaoController = MetaDaoController_;

        percentToConvert = 100;
        _initialized = true;
        emit Initialized(_initialized, initOwner, AMORxGuild_);
        return true;
    }

    function setVotingPeriod(uint256 newTime) external onlyOwner {
        if (newTime < 2 days) {
            revert InvalidAmount();
        }
        additionalVotingTime = newTime;
    }

    function setPercentToConvert(uint256 newPercentToConvert) external onlyOwner {
        percentToConvert = newPercentToConvert;
    }

    /// @notice called by donate and gatherDonation, distributes amount of tokens between
    /// all of the impact makers based on their weight.
    /// Afterwards, based on the weights distribution, tokens will be automatically redirected to the impact makers
    function distribute(uint256 amount, address token) internal returns (uint256) {
        // based on the weights distribution, tokens will be automatically marked as claimable for the impact makers
        for (uint256 i = 0; i < impactMakers.length; i++) {
            uint256 amountToSendVoter = (amount * weights[impactMakers[i]]) / totalWeight;
            claimableTokens[impactMakers[i]][token] += amountToSendVoter;
        }

        return amount;
    }

    /// @notice gathers donation from MetaDaoController in specific token
    /// and calles distribute function for the whole amount of gathered tokens
    function gatherDonation(address token) public {
        // check if token in the whitelist of the MetaDaoController
        if (!IMetaDaoController(MetaDaoController).isWhitelisted(token)) {
            revert NotWhitelistedToken();
        }
        uint256 amount = IMetaDaoController(MetaDaoController).guildFunds(address(this), token);
        IMetaDaoController(MetaDaoController).claimToken(token);
        // distribute those tokens
        distribute(amount, token);
    }

    /// @notice allows to donate AMORxGuild tokens to the Guild
    /// @param allAmount The amount to donate
    /// @param token Token in which to donate
    // It automatically distributes tokens between Impact makers.
    // 10% of the tokens in the impact pool are getting staked in the FXAMORxGuild tokens,
    // which are going to be owned by the user.
    // Afterwards, based on the weights distribution, tokens will be automatically redirected to the impact makers.
    // Requires the msg.sender to `approve` amount prior to calling this function
    function donate(uint256 allAmount, address token) external returns (uint256) {
        // check if token in the whitelist of the MetaDaoController
        if (!IMetaDaoController(MetaDaoController).isWhitelisted(token)) {
            revert NotWhitelistedToken();
        }
        // if amount is below 10, most of the calculations will round down to zero, only wasting gas
        if (IERC20(token).balanceOf(msg.sender) < allAmount || allAmount < 10) {
            revert InvalidAmount();
        }

        uint256 amount = (allAmount * percentToConvert) / FEE_DENOMINATOR; // 10% of tokens
        uint256 amorxguildAmount = amount;

        // 10% of the tokens in the impact pool are getting:
        if (token == AMOR) {
            // convert AMOR to AMORxGuild
            // 2.Exchanged from AMOR to AMORxGuild using staking contract( if it’s not AMORxGuild)
            // Must calculate stakedAmor prior to transferFrom()
            uint256 stakedAmor = IERC20(token).balanceOf(address(this));
            // get all tokens
            // Note that if token is AMOR then this transferFrom() is taxed due to AMOR tax
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            // Calculate mint amount and mint this to the address `to`
            // Take AMOR tax into account
            uint256 taxCorrectedAmount = IERC20(token).balanceOf(address(this)) - stakedAmor;

            IERC20(token).approve(AMORxGuild, taxCorrectedAmount);

            amorxguildAmount = IAmorxGuild(AMORxGuild).stakeAmor(address(this), taxCorrectedAmount);
        } else if (token == AMORxGuild) {
            ERC20AMORxGuild.safeTransferFrom(msg.sender, address(this), amorxguildAmount);
        } else {
            // if token != AMORxGuild && token != AMOR
            // recieve tokens
            amount = 0;
            // TODO: allow to mint FXAMOR tokend based on
        }

        if (token == AMORxGuild || token == AMOR) {
            // 3.Staked in the FXAMORxGuild tokens,
            // which are going to be owned by the user.
            ERC20AMORxGuild.approve(FXAMORxGuild, amorxguildAmount);
            FXGFXAMORxGuild.stake(msg.sender, amorxguildAmount); // from address(this)
        }
        uint256 decAmount = allAmount - amount; //decreased amount: other 90%
        uint256 tokenBefore = IERC20(token).balanceOf(address(this));

        IERC20(token).safeTransferFrom(msg.sender, address(this), decAmount);

        uint256 decTaxCorrectedAmount = IERC20(token).balanceOf(address(this)) - tokenBefore;

        distribute(decTaxCorrectedAmount, token); // distribute other 90%

        return amorxguildAmount;
    }

    /// @notice adds another element to the reportsWeight, with weight 0, and starts voting on it.
    /// @dev As soon as the report added, voting on it can start.
    /// @param report Hash of report (timestamp and report header)
    /// param signature Signature of this report (splitted into uint8 v, bytes32 r, bytes32 s)
    function addReport(
        bytes32 report,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // each report is an NFT (maybe hash-id of NFT and sign this NFT-hash)
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, report));

        // ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        address signer = ecrecover(prefixedHashMessage, v, r, s);
        if (signer != msg.sender) {
            revert Unauthorized();
        }

        uint256 newReportId = reportsQueue.length;

        queueReportsAuthors[newReportId] = msg.sender;

        // During the vote reports can be added, but they will be waiting and vote for them won’t start.
        // When the voting for the 10 reports is finished, and there are ≥ 10 reports in the queue,
        // than the vote for the next report set instantly starts.
        // The vote starts for all of the untouched reports in the queue.
        // timeVoting == 0 --> for the first queue when there was no voting yet
        reportsQueue.push(newReportId);
    }

    /// @notice burns the amount of FXTokens, and changes a report weight, based on a sign provided.
    /// It also sets a vote info for a specific voter.
    /// It requires the `amount` to be `approved` prior to being called
    /// @dev As soon as the first vote goes for report, we create a time limit for vote(a week).
    /// @param id ID of report to vote for
    /// @param amount Amount of FXTokens to use for vote and burn
    /// @param sign Boolean value: true (for) or false (against) user is voting
    function voteForReport(
        uint256 id,
        uint256 amount,
        bool sign
    ) public {
        // check if tthe voting for this report has started
        if (trigger == false) {
            revert VotingNotStarted();
        }

        if (amount == 0 && msg.sender != address(this)) {
            revert InvalidAmount();
        }

        // check if report with that id exists
        if (reportsWeight.length < id) {
            revert ReportNotExists();
        }

        //check if the week has passed - can vote only a week from first vote
        if (block.timestamp > (timeVoting + additionalVotingTime)) {
            revert VotingTimeExpired();
        }

        if (IERC20(FXAMORxGuild).balanceOf(msg.sender) < amount) {
            revert InvalidAmount();
        }

        FXGFXAMORxGuild.burn(msg.sender, amount);
        voters[id].push(msg.sender);

        reportsWeight[id] += int256(amount);
        totalReportsWeight += amount;

        if (sign == true) {
            reportsVoting[id] += int256(amount);
            votes[id][msg.sender] += int256(amount);
        } else {
            reportsVoting[id] -= int256(amount);
            votes[id][msg.sender] -= int256(amount);
        }
    }

    /// @notice distributes funds, depending on the report ids, for which votings were conducted
    function finalizeVoting() public {
        // nothing to finalize
        if (trigger == false) {
            revert ReportNotExists();
        }

        if (block.timestamp < (timeVoting + additionalVotingTime)) {
            revert VotingTimeNotFinished();
        }

        for (uint256 id = 0; id < reportsWeight.length; id++) {
            // If report has positive voting weight (positive FX tokens) then report is accepted
            int256 fiftyPercent = (reportsWeight[id] * 50) / 100;
            address[] memory people = voters[id];

            if (reportsVoting[id] > 0) {
                // If report has positive voting weight, then funds go 50-50%,
                // 50% go to the report creater,
                ERC20AMORxGuild.safeTransfer(reportsAuthors[id], uint256(fiftyPercent));

                // and 50% goes to the people who voted positively
                for (uint256 i = 0; i < voters[id].length; i++) {
                    // if voted positively
                    if (votes[id][people[i]] > 0) {
                        // 50% * user weigth / all 100%
                        int256 amountToSendVoter = (int256(fiftyPercent) * votes[id][people[i]]) / reportsWeight[id];
                        ERC20AMORxGuild.safeTransfer(people[i], uint256(amountToSendVoter));
                    }
                    delete votes[id][people[i]];
                }
            } else {
                // If report has negative voting weight, then
                // 50% goes to the people who voted negatively,
                for (uint256 i = 0; i < voters[id].length; i++) {
                    // if voted negatively
                    if (votes[id][people[i]] < 0) {
                        // allAmountToDistribute(50%) * user weigth in % / all 100%
                        int256 absVotes = abs(votes[id][people[i]]);
                        int256 amountToSendVoter = (fiftyPercent * absVotes) / reportsWeight[id];
                        ERC20AMORxGuild.safeTransfer(people[i], uint256(amountToSendVoter));
                    }
                    delete votes[id][people[i]];
                }
                // and 50% gets redistributed between the passed reports based on their weights
                for (uint256 i = 0; i < reportsWeight.length; i++) {
                    // passed reports
                    if (reportsVoting[i] > 0) {
                        // allAmountToDistribute(50%) * report weigth in % / all 100%
                        int256 amountToSendReport = (fiftyPercent * reportsWeight[i]) / int256(totalReportsWeight);
                        ERC20AMORxGuild.safeTransfer(reportsAuthors[i], uint256(amountToSendReport));
                    }
                }
            }

            delete voters[id];
        }

        for (uint256 i = 0; i < reportsWeight.length; i++) {
            delete reportsAuthors[i];
        }

        delete reportsWeight;
        delete reportsVoting;
        totalReportsWeight = 0;
        timeVoting = 0;
        trigger = false;
    }

    /// @notice starts voting and clears reports queue
    function startVoting() external {
        // nothing to finalize
        // startVoting will not start voting if there is another voting in progress
        if (block.timestamp < (timeVoting + additionalVotingTime)) {
            revert VotingTimeNotFinished();
        }

        // check queque lenght. must be >= 10 reports
        if (reportsQueue.length < 10) {
            revert InvalidAmount();
        }

        // if the voting time is over, then startVoting will first call finalizeVoting and then start it's own functional
        // if timeVoting == 0 then skip call finalizeVoting for the first start
        if (block.timestamp >= (timeVoting + additionalVotingTime) && timeVoting != 0) {
            finalizeVoting();
        }

        uint256 endTime = block.timestamp;
        uint256 day = getWeekday(block.timestamp);

        // SUNDAY-CHECK
        if (day == 0) {
            endTime += WEEK;
        } else if (day == 6 || day == 5) {
            // if vote started on Friday/Saturday, then the end will be next week
            // end of the next week
            endTime += WEEK + (DAY * (7 - day));
        } else {
            endTime += WEEK - (DAY * day);
        }
        endTime = (endTime / DAY) * DAY;
        endTime += 12 * HOUR;

        for (uint256 i = 0; i < reportsQueue.length; i++) {
            reportsAuthors[i] = queueReportsAuthors[i];
            reportsWeight.push(0);
            reportsVoting.push(0);
            delete queueReportsAuthors[i];
        }

        timeVoting = endTime;
        trigger = true;
        delete reportsQueue;
    }

    /// @notice removes impact makers, resets mapping and array, and creates new array, mapping, and sets weights
    /// @param arrImpactMakers The array of impact makers
    /// @param arrWeight The array of weights of impact makers
    function setImpactMakers(address[] memory arrImpactMakers, uint256[] memory arrWeight) external onlyOwner {
        delete impactMakers;
        for (uint256 i = 0; i < arrImpactMakers.length; i++) {
            impactMakers.push(arrImpactMakers[i]);
            weights[arrImpactMakers[i]] = arrWeight[i];
            totalWeight += arrWeight[i];
        }
    }

    /// @notice allows to add impactMaker with a specific weight
    /// Only avatar can add one, based on the popular vote
    /// @param impactMaker New impact maker to be added
    /// @param weight Weight of the impact maker
    function addImpactMaker(address impactMaker, uint256 weight) external onlyOwner {
        // check thet ImpactMaker won't be added twice
        if (weights[impactMaker] > 0) {
            revert InvalidParameters();
        }
        impactMakers.push(impactMaker);
        weights[impactMaker] = weight;
        totalWeight += weight;
    }

    /// @notice allows to add change impactMaker weight
    /// @param impactMaker Impact maker to be changed
    /// @param weight Weight of the impact maker
    function changeImpactMaker(address impactMaker, uint256 weight) external onlyOwner {
        if (weight > weights[impactMaker]) {
            totalWeight += weight - weights[impactMaker];
        } else {
            totalWeight -= weights[impactMaker] - weight;
        }
        weights[impactMaker] = weight;
    }

    /// @notice allows to remove impactMaker with specific address
    /// @param impactMaker Impact maker to be removed
    function removeImpactMaker(address impactMaker) external onlyOwner {
        for (uint256 i = 0; i < impactMakers.length; i++) {
            if (impactMakers[i] == impactMaker) {
                impactMakers[i] = impactMakers[impactMakers.length - 1];
                impactMakers.pop();
                break;
            }
        }
        totalWeight -= weights[impactMaker];
        delete weights[impactMaker];
    }

    /// @notice allows to claim tokens for specific ImpactMaker address
    /// @param impact Impact maker to to claim tokens from
    /// @param token Tokens addresess to claim
    function claim(address impact, address[] memory token) external {
        if (impact != msg.sender) {
            revert Unauthorized();
        }

        for (uint256 i = 0; i < token.length; i++) {
            IERC20(token[i]).safeTransfer(impact, claimableTokens[impact][token[i]]);
            claimableTokens[impact][token[i]] = 0;
        }
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY + 4) % 7); // day of week = (floor(T / 86400) + 4) mod 7.
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}

// SPDX-License-Identifier: MIT

/// @title  DoinGud Guild Token Interface
/// @author Daoism Systems Team
/// @notice ERC20 implementation for DoinGudDAO

/**
 *  @dev Implementation of the AMORxGuild token for DoinGud
 *
 *  The contract houses the token logic for AMORxGuild.
 *
 *  It varies from traditional ERC20 implementations by:
 *  1) Allowing the token name to be set with an `init()` function
 *  2) Allowing the token symbol to be set with an `init()` function
 *  3) Enables upgrades through updating the proxy
 */
pragma solidity 0.8.15;

interface IAmorxGuild {
    /// Events
    /// Emitted once token has been initialized
    event Initialized(string name, string symbol, address amorToken);

    /// Proxy Address Change
    event ProxyAddressChange(address indexed newProxyAddress);

    /// @notice Initializes the AMORxGuild contract
    /// @dev    Sets the token details as well as the required addresses for token logic
    /// @param  amorAddress the address of the AMOR token proxy
    /// @param  name the token name (e.g AMORxIMPACT)
    /// @param  symbol the token symbol
    function init(
        string memory name,
        string memory symbol,
        address amorAddress,
        address controller
    ) external;

    /// @notice Allows a user to stake their AMOR and receive AMORxGuild in return
    /// @param  to a parameter just like in doxygen (must be followed by parameter name)
    /// @param  amount uint256 amount of AMOR to be staked
    /// @return uint256 the amount of AMORxGuild received from staking
    function stakeAmor(address to, uint256 amount) external returns (uint256);

    /// @notice Allows the user to unstake their AMOR
    /// @param  amount uint256 amount of AMORxGuild to exchange for AMOR
    /// @return uint256 the amount of AMOR returned from burning AMORxGuild
    function withdrawAmor(uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *  @dev Implementation of the FXAMORxGuild token for DoinGud
 *
 *  The contract houses the token logic for FXAMORxGuild.
 *
 */
pragma solidity 0.8.15;

interface IFXAMORxGuild {
    /// Events
    /// Emitted once token has been initialized
    event Initialized(bool success, address owner, address AMORxGuild);

    /// @notice Initializes the IFXAMORxGuild contract
    /// @dev    Sets the token details as well as the required addresses for token logic
    /// @param  AMORxGuild the address of the AMORxGuild
    /// @param  name the token name (e.g AMORxIMPACT)
    /// @param  symbol the token symbol
    function init(
        string memory name,
        string memory symbol,
        address initOwner,
        address AMORxGuild
    ) external;

    /// @notice Stake AMORxGuild and receive FXAMORxGuild in return
    /// @dev    Front end must still call approve() on AMORxGuild token to allow transferFrom()
    /// @param  to a parameter just like in doxygen (must be followed by parameter name)
    /// @param  amount uint256 amount of AMORxGuild to be staked
    /// @return uint256 the amount of AMORxGuild received from staking
    function stake(address to, uint256 amount) external returns (uint256);

    /// @notice Burns FXAMORxGuild tokens if they are being used for voting
    /// @dev When this tokens are burned, staked AMORxGuild is being transfered
    //       to the controller(contract that has a voting function)
    /// @param  account address from which must burn tokens
    /// @param  amount uint256 representing amount of burning tokens
    function burn(address account, uint256 amount) external;

    /// @notice Allows some external account to vote with your FXAMORxGuild tokens
    /// @param  to address to which delegate users FXAMORxGuild
    /// @param  amount uint256 representing amount of delegating tokens
    function delegate(address to, uint256 amount) external;

    /// @notice Unallows some external account to vote with your delegated FXAMORxGuild tokens
    /// @param  account address from which delegating will be taken away
    /// @param  amount uint256 representing amount of undelegating tokens
    function undelegate(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

/// @title  DoinGud Guild Controller Interface
/// @author Daoism Systems Team

/**
 *  @dev Interface for the DoinGud Guild Controller
 */
pragma solidity 0.8.15;

interface IGuildController {
    function init(
        address initOwner,
        address AMOR_,
        address AMORxGuild_,
        address FXAMORxGuild_,
        address MetaDaoController_
    ) external returns (bool);

    function setVotingPeriod(uint256 newTime) external;

    /// @notice allows to donate AMORxGuild tokens to the Guild
    /// @param amount The amount to donate
    // It automatically distributes tokens between Impact makers.
    // 10% of the tokens in the impact pool are getting staked in the FXAMORxGuild tokens,
    // which are going to be owned by the user.
    // Afterwards, based on the weights distribution, tokens will be automatically redirected to the impact makers.
    function donate(uint256 amount, address token) external returns (uint256);

    /// @notice removes impact makers, resets mapping and array, and creates new array, mapping, and sets weights
    /// @param arrImpactMakers The array of impact makers
    /// @param arrWeight The array of weights of impact makers
    function setImpactMakers(address[] memory arrImpactMakers, uint256[] memory arrWeight) external;

    /// @notice allows to add impactMaker with a specific weight
    /// Only avatar can add one, based on the popular vote
    /// @param impactMaker New impact maker to be added
    /// @param weight Weight of the impact maker
    function addImpactMaker(address impactMaker, uint256 weight) external;

    /// @notice allows to add change impactMaker weight
    /// @param impactMaker Impact maker to be changed
    /// @param weight Weight of the impact maker
    function changeImpactMaker(address impactMaker, uint256 weight) external;

    /// @notice allows to remove impactMaker with specific address
    /// @param impactMaker Impact maker to be removed
    function removeImpactMaker(address impactMaker) external;

    /// @notice allows to claim tokens for specific ImpactMaker address
    /// @param impact Impact maker to to claim tokens from
    /// @param token Tokens addresess to claim
    function claim(address impact, address[] memory token) external;

    function gatherDonation(address token) external;
}

// SPDX-License-Identifier: MIT

/// @title  MetaDAO Controller Interface
/// @author Daoism Systems Team
/// @custom security-contact [email protected]

pragma solidity 0.8.15;

interface IMetaDaoController {
    function init(
        address amor,
        address factory,
        address avatar
    ) external;

    function guildFunds(address guild, address token) external returns (uint256);

    /// @notice Allows a user to donate a whitelisted asset
    /// @dev    `approve` must have been called on the `token` contract
    /// @param  token the address of the token to be donated
    /// @param  amount the amount of tokens to donate
    /// @param  index the index being donated to
    function donate(
        address token,
        uint256 amount,
        uint256 index
    ) external;

    function claimToken(address token) external;

    /// @notice Apportions collected AMOR fees
    function distributeFees() external;

    /// @notice Transfers apportioned tokens from the metadao to the guild
    /// @param  guild target guild
    function claimFees(address guild) external;

    /// @notice use this funtion to create a new guild via the guild factory
    /// @dev only admin can all this funtion
    /// @param guildOwner address that will control the functions of the guild
    /// @param name the name for the guild
    /// @param tokenSymbol the symbol for the Guild's token
    function createGuild(
        address guildOwner,
        string memory name,
        string memory tokenSymbol
    ) external;

    /// @notice adds guild based on the controller address provided
    /// @dev give guild role in access control to the controller for the guild
    /// @param controller the controller address of the guild
    function addExternalGuild(address controller) external;

    /// @notice adds guild based on the controller address provided
    /// @dev give guild role in access control to the controller for the guild
    /// @param _token the controller address of the guild
    function addWhitelist(address _token) external;

    /// @notice removes guild based on id
    /// @param controller the index of the guild in guilds[]
    function removeGuild(address controller) external;

    /// @notice Checks that a token is whitelisted
    /// @param  token address of the ERC20 token being checked
    /// @return bool true if token whitelisted, false if not whitelisted
    function isWhitelisted(address token) external view returns (bool);

    /// @notice Adds a new index to the `Index` array
    /// @dev    Requires an encoded array of SORTED tuples in (address, uint256) format
    /// @param  weights an array containing the weighting indexes for different guilds
    /// @return index of the new index in the `Index` array
    function addIndex(bytes[] calldata weights) external returns (uint256);

    /// @notice Allows DoinGud to update the fee index used
    /// @param  weights an array of the guild weights
    function updateIndex(bytes[] calldata weights, uint256 index) external returns (uint256);
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