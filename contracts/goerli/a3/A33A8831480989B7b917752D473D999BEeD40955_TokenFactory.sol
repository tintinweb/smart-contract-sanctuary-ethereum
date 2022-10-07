// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './Token.sol';
import './TokenLockup.sol';

contract TokenFactory is Ownable {
  // state vars
  //   uint256 private s_requiredDeposit; // 1 ETH
  uint256 private s_contractId;
  mapping(uint256 => address) public s_deployedContracts; // contractId -> deployed contract address; should it be private?
  mapping(uint256 => address) public _s_tokenLockups; // contractId -> deployed contract address; should it be private?
  // mapping(address => uint256) s_whitelist; // deployer address -> is allowed to deploy? // not needed for MVP
  //   mapping(address => uint256) s_deposit; // deployer address -> deposit amount // not needed for MVP

  event ContractDeployed(
    uint256 indexed contractId,
    address msgSender,
    address contractAddress,
    string indexed name,
    string indexed contactType
  );

  // we can set it to our company wallet address as the owner
  constructor() {
    // default ownership
    // s_requiredDeposit = requiredDeposit_; // not needed for MVP
  }

  function deployToken(
    string memory _erc20Name,
    string memory _erc20Symbol,
    uint256 _decimals,
    uint256 _cap,
    address[] memory _mintAddresses,
    uint256[] memory _mintAmounts
  ) external {
    Token _tokenAddr = new Token(
      _erc20Name,
      _erc20Symbol,
      uint8(_decimals),
      _cap,
      _mintAddresses,
      _mintAmounts
    );

    s_deployedContracts[s_contractId] = address(_tokenAddr);

    emit ContractDeployed(
      s_contractId,
      msg.sender,
      address(_tokenAddr),
      _erc20Name,
      'Token'
    );

    s_contractId++;
  }

  function deployTokenLockup(
    address token_,
    string memory name_,
    string memory symbol_,
    uint256 _minTimelockAmount,
    uint256 _maxReleaseDelay
  ) public {
    TokenLockup _tokenLockupAddr = new TokenLockup(
      token_,
      name_,
      symbol_,
      _minTimelockAmount,
      _maxReleaseDelay
    );

    s_deployedContracts[s_contractId] = address(_tokenLockupAddr);

    emit ContractDeployed(
      s_contractId,
      msg.sender,
      address(_tokenLockupAddr),
      name_,
      'TokenLockup'
    );

    s_contractId++;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract Token is ERC20Capped {
    uint8 private immutable customDecimals;

    constructor(
        string memory _erc20Name,
        string memory _erc20Symbol,
        uint8 _decimals,
        uint256 _cap,
        address[] memory _mintAddresses,
        uint256[] memory _mintAmounts
    ) ERC20(_erc20Name, _erc20Symbol) ERC20Capped(_cap) {
        // set temp var for _mintAddresses.length bc it gets re-used
        require(
            _mintAddresses.length == _mintAmounts.length,
            "must have same number of mint addresses and amounts"
        );

        customDecimals = _decimals;

        for (uint i; i < _mintAddresses.length; i++) {
            // always: more gas efficient to use temp var for length so it isn't calculating on every iteration
            require(
                _mintAddresses[i] != address(0),
                "cannot have a non-address as reserve"
            ); // emit error instead of require. Refunds gas, ends tx
            ERC20._mint(_mintAddresses[i], _mintAmounts[i]);
        }

        require(
            _cap >= totalSupply(),
            "total supply of tokens cannot exceed the cap"
        );
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function decimals() public view override returns (uint8) {
        return customDecimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
    @title A smart contract for unlocking tokens based on a release schedule
    @author By CoMakery, Inc., Upside, Republic
    @dev When deployed the contract is as a proxy for a single token that it creates release schedules for
        it implements the ERC20 token interface to integrate with wallets but it is not an independent token.
        The token must implement a burn function.
        Unit test can be found here: https://github.com/CoMakery/upside-evm/tree/main/test/token-lockup
*/
contract TokenLockup is ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable token;
    string private _name;
    string private _symbol;

    struct ReleaseSchedule {
        uint256 releaseCount;
        uint256 delayUntilFirstReleaseInSeconds;
        uint256 initialReleasePortionInBips;
        uint256 periodBetweenReleasesInSeconds;
    }

    struct Timelock {
        uint256 scheduleId;
        uint256 commencementTimestamp;
        uint256 tokensTransferred;
        uint256 totalAmount;
        address[] cancelableBy; // not cancelable unless set at the time of funding
    }

    ReleaseSchedule[] public releaseSchedules;
    uint256 public immutable minTimelockAmount;
    uint256 public immutable maxReleaseDelay;
    uint256 private constant BIPS_PRECISION = 10_000;
    uint256 private constant MAX_TIMELOCKS = 10_000;

    mapping(address => Timelock[]) public timelocks;
    mapping(address => mapping(address => uint256)) internal _allowances;

    event Approval(
        address indexed from,
        address indexed spender,
        uint256 amount
    );
    event ScheduleCreated(address indexed from, uint256 indexed scheduleId);

    event ScheduleFunded(
        address indexed from,
        address indexed to,
        uint256 indexed scheduleId,
        uint256 amount,
        uint256 commencementTimestamp,
        uint256 timelockId,
        address[] cancelableBy
    );

    event TimelockCanceled(
        address indexed canceledBy,
        address indexed target,
        uint256 indexed timelockIndex,
        address relaimTokenTo,
        uint256 canceledAmount,
        uint256 paidAmount
    );

    /**
        @dev Configure deployment for a specific token with release schedule security parameters
        @param _token The address of the token that will be released on the lockup schedule
        @param name_ TokenLockup ERC20 interface name. Should be Distinct from token. Example: "Token Name Lockup"
        @param symbol_ TokenLockup ERC20 interface symbol. Should be distinct from token symbol. Example: "TKN LOCKUP"
        @dev The symbol should end with " Unlock" & be less than 11 characters for MetaMask "custom token" compatibility
    */
    constructor(
        address _token,
        string memory name_,
        string memory symbol_,
        uint256 _minTimelockAmount,
        uint256 _maxReleaseDelay
    ) ReentrancyGuard() {
        require(_token != address(0), "Zero token address");

        _name = name_;
        _symbol = symbol_;
        token = IERC20Metadata(_token);

        // Setup minimal fund payment for timelock
        if (_minTimelockAmount == 0) {
            _minTimelockAmount = 100 * (10**IERC20Metadata(_token).decimals()); // 100 tokens
        }

        minTimelockAmount = _minTimelockAmount;

        maxReleaseDelay = _maxReleaseDelay;
    }

    /**
        @notice Create a release schedule template that can be used to generate many token timelocks
        @param releaseCount Total number of releases including any initial "cliff'
        @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
        @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
        @param periodBetweenReleasesInSeconds After the delay and initial release
            the remaining tokens will be distributed evenly across the remaining number of releases (releaseCount - 1)
        @return unlockScheduleId The id used to refer to the release schedule at the time of funding the schedule
    */
    function createReleaseSchedule(
        uint256 releaseCount,
        uint256 delayUntilFirstReleaseInSeconds,
        uint256 initialReleasePortionInBips,
        uint256 periodBetweenReleasesInSeconds
    ) external returns (uint256 unlockScheduleId) {
        require(
            delayUntilFirstReleaseInSeconds <= maxReleaseDelay,
            "first release > max"
        );
        require(releaseCount >= 1, "< 1 release");
        require(
            initialReleasePortionInBips <= BIPS_PRECISION,
            "release > 100%"
        );

        if (releaseCount > 1) {
            require(periodBetweenReleasesInSeconds > 0, "period = 0");
        } else if (releaseCount == 1) {
            require(
                initialReleasePortionInBips == BIPS_PRECISION,
                "released < 100%"
            );
        }

        releaseSchedules.push(
            ReleaseSchedule(
                releaseCount,
                delayUntilFirstReleaseInSeconds,
                initialReleasePortionInBips,
                periodBetweenReleasesInSeconds
            )
        );

        unlockScheduleId = releaseSchedules.length - 1;
        emit ScheduleCreated(msg.sender, unlockScheduleId);

        return unlockScheduleId;
    }

    /**
        @notice Fund the programmatic release of tokens to a recipient.
            WARNING: this function IS CANCELABLE by cancelableBy.
            If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
            and unlocked tokens will be transferred to the recipient.
        @param to recipient address that will have tokens unlocked on a release schedule
        @param amount of tokens to transfer in base units (the smallest unit without the decimal point)
        @param commencementTimestamp the time the release schedule will start
        @param scheduleId the id of the release schedule that will be used to release the tokens
        @param cancelableBy array of canceler addresses
        @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
    */
    function fundReleaseSchedule(
        address to,
        uint256 amount,
        uint256 commencementTimestamp, // unix timestamp
        uint256 scheduleId,
        address[] memory cancelableBy
    ) public nonReentrant returns (bool success) {
        require(cancelableBy.length <= 10, "max 10 cancelableBy addressees");

        uint256 timelockId = _fund(
            to,
            amount,
            commencementTimestamp,
            scheduleId
        );

        if (cancelableBy.length > 0) {
            timelocks[to][timelockId].cancelableBy = cancelableBy;
        }

        emit ScheduleFunded(
            msg.sender,
            to,
            scheduleId,
            amount,
            commencementTimestamp,
            timelockId,
            cancelableBy
        );
        return true;
    }

    function _fund(
        address to,
        uint256 amount,
        uint256 commencementTimestamp, // unix timestamp
        uint256 scheduleId
    ) internal returns (uint256) {
        require(
            timelocks[to].length <= MAX_TIMELOCKS,
            "Max timelocks exceeded"
        );
        require(amount >= minTimelockAmount, "amount < min funding");
        require(to != address(0), "to 0 address");
        require(scheduleId < releaseSchedules.length, "bad scheduleId");
        require(
            amount >= releaseSchedules[scheduleId].releaseCount,
            "< 1 token per release"
        );

        uint256 tokensBalance = token.balanceOf(address(this));
        // It will revert via ERC20 implementation if there's no allowance
        token.safeTransferFrom(msg.sender, address(this), amount);
        // deflation token check
        require(
            token.balanceOf(address(this)) - tokensBalance == amount,
            "deflation token declined"
        );

        require(
            commencementTimestamp +
                releaseSchedules[scheduleId].delayUntilFirstReleaseInSeconds <=
                block.timestamp + maxReleaseDelay,
            "initial release out of range"
        );

        Timelock memory timelock;
        timelock.scheduleId = scheduleId;
        timelock.commencementTimestamp = commencementTimestamp;
        timelock.totalAmount = amount;

        timelocks[to].push(timelock);
        return timelockCountOf(to) - 1;
    }

    /**
        @notice Cancel a cancelable timelock created by the fundReleaseSchedule function.
            WARNING: this function cannot cancel a release schedule created by fundReleaseSchedule
            If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
            and unlocked tokens will be transferred to the recipient.
        @param target The address that would receive the tokens when released from the timelock.
        @param timelockIndex timelock index
        @param target The address that would receive the tokens when released from the timelock
        @param scheduleId require it matches expected
        @param commencementTimestamp require it matches expected
        @param totalAmount require it matches expected
        @param reclaimTokenTo reclaim token to
        @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
    */
    function cancelTimelock(
        address target,
        uint256 timelockIndex,
        uint256 scheduleId,
        uint256 commencementTimestamp,
        uint256 totalAmount,
        address reclaimTokenTo
    ) external nonReentrant returns (bool success) {
        require(timelockCountOf(target) > timelockIndex, "invalid timelock");
        require(reclaimTokenTo != address(0), "Invalid reclaimTokenTo");

        Timelock storage timelock = timelocks[target][timelockIndex];

        require(
            _canBeCanceled(timelock),
            "You are not allowed to cancel this timelock"
        );
        require(
            timelock.scheduleId == scheduleId,
            "Expected scheduleId does not match"
        );
        require(
            timelock.commencementTimestamp == commencementTimestamp,
            "Expected commencementTimestamp does not match"
        );
        require(
            timelock.totalAmount == totalAmount,
            "Expected totalAmount does not match"
        );

        uint256 canceledAmount = lockedBalanceOfTimelock(target, timelockIndex);

        require(canceledAmount > 0, "Timelock has no value left");

        uint256 paidAmount = unlockedBalanceOfTimelock(target, timelockIndex);

        token.safeTransfer(reclaimTokenTo, canceledAmount);
        token.safeTransfer(target, paidAmount);

        emit TimelockCanceled(
            msg.sender,
            target,
            timelockIndex,
            reclaimTokenTo,
            canceledAmount,
            paidAmount
        );

        timelock.tokensTransferred = timelock.totalAmount;
        return true;
    }

    /**
     *  @notice Check if timelock can be cancelable by msg.sender
     */
    function _canBeCanceled(Timelock storage timelock)
        private
        view
        returns (bool)
    {
        uint256 len = timelock.cancelableBy.length;
        for (uint256 i = 0; i < len; i++) {
            if (msg.sender == timelock.cancelableBy[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @notice Batch version of fund cancelable release schedule
     *  @param to An array of recipient address that will have tokens unlocked on a release schedule
     *  @param amounts An array of amount of tokens to transfer in base units (the smallest unit without the decimal point)
     *  @param commencementTimestamps An array of the time the release schedule will start
     *  @param scheduleIds An array of the id of the release schedule that will be used to release the tokens
     *  @param cancelableBy An array of cancelables
     *  @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
     */
    function batchFundReleaseSchedule(
        address[] calldata to,
        uint[] calldata amounts,
        uint[] calldata commencementTimestamps,
        uint[] calldata scheduleIds,
        address[] calldata cancelableBy
    ) external returns (bool success) {
        require(to.length == amounts.length, "mismatched array length");
        require(
            to.length == commencementTimestamps.length,
            "mismatched array length"
        );
        require(to.length == scheduleIds.length, "mismatched array length");

        for (uint256 i = 0; i < to.length; i++) {
            require(
                fundReleaseSchedule(
                    to[i],
                    amounts[i],
                    commencementTimestamps[i],
                    scheduleIds[i],
                    cancelableBy
                ),
                "Can not release schedule"
            );
        }

        return true;
    }

    /**
        @notice Get The total locked balance of an address for all timelocks
        @param who Address to calculate
        @return amount The total locked amount of tokens for all of the who address's timelocks
    */
    function lockedBalanceOf(address who) public view returns (uint256 amount) {
        for (uint256 i = 0; i < timelockCountOf(who); i++) {
            amount += lockedBalanceOfTimelock(who, i);
        }
        return amount;
    }

    /**
        @notice Get The total unlocked balance of an address for all timelocks
        @param who Address to calculate
        @return amount The total unlocked amount of tokens for all of the who address's timelocks
    */
    function unlockedBalanceOf(address who)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < timelockCountOf(who); i++) {
            amount += unlockedBalanceOfTimelock(who, i);
        }
        return amount;
    }

    /**
        @notice Get The locked balance for a specific address and specific timelock
        @param who The address to check
        @param timelockIndex Specific timelock belonging to the who address
        @return locked Balance of the timelock
    */
    function lockedBalanceOfTimelock(address who, uint256 timelockIndex)
        public
        view
        returns (uint256 locked)
    {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return
                timelock.totalAmount -
                totalUnlockedToDateOfTimelock(who, timelockIndex);
        }
    }

    /**
        @notice Get the unlocked balance for a specific address and specific timelock
        @param who the address to check
        @param timelockIndex for a specific timelock belonging to the who address
        @return unlocked balance of the timelock
    */
    function unlockedBalanceOfTimelock(address who, uint256 timelockIndex)
        public
        view
        returns (uint256 unlocked)
    {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return
                totalUnlockedToDateOfTimelock(who, timelockIndex) -
                timelock.tokensTransferred;
        }
    }

    /**
        @notice Check the total remaining balance of a timelock including the locked and unlocked portions
        @param who the address to check
        @param timelockIndex  Specific timelock belonging to the who address
        @return total remaining balance of a timelock
     */
    function balanceOfTimelock(address who, uint256 timelockIndex)
        external
        view
        returns (uint256)
    {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return timelock.totalAmount - timelock.tokensTransferred;
        }
    }

    /**
        @notice Gets the total locked and unlocked balance of a specific address's timelocks
        @param who The address to check
        @param timelockIndex The index of the timelock for the who address
        @return total Locked and unlocked amount for the specified timelock
    */
    function totalUnlockedToDateOfTimelock(address who, uint256 timelockIndex)
        public
        view
        returns (uint256 total)
    {
        Timelock memory _timelock = timelockOf(who, timelockIndex);

        return
            calculateUnlocked(
                _timelock.commencementTimestamp,
                block.timestamp,
                _timelock.totalAmount,
                _timelock.scheduleId
            );
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
    */
    function balanceOf(address who) external view returns (uint256) {
        return unlockedBalanceOf(who) + lockedBalanceOf(who);
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
    */
    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(_allowances[from][msg.sender] >= value, "value > allowance");
        _allowances[from][msg.sender] -= value;
        emit Approval(from, msg.sender, _allowances[from][msg.sender]);
        return _transfer(from, to, value);
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
        @notice ERC20 standard interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
        @dev Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "decrease > allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
        @notice ERC20 details interface function
            TokenLockup is a Proxy to an ERC20 token and not an independend token.
            this functionality is provided as a convenience function
            for interacting with the contract using the ERC20 token wallets interface.
         @dev this function returns the decimals of the token contract that the TokenLockup proxies
    */
    function decimals() external view returns (uint8) {
        return token.decimals();
    }

    /// @notice ERC20 standard interfaces function
    /// @return The name of the TokenLockup contract.
    ///     WARNING: this is different than the underlying token that the TokenLockup is a proxy for.
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice ERC20 standard interfaces function
    /// @return The symbol of the TokenLockup contract.
    ///     WARNING: this is different than the underlying token that the TokenLockup is a proxy for.
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @notice ERC20 standard interface function.
    /// @return Total of tokens for all timelocks and all addresses held by the TokenLockup smart contract.
    function totalSupply() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal nonReentrant returns (bool) {
        require(unlockedBalanceOf(from) >= value, "amount > unlocked");

        uint256 remainingTransfer = value;

        // transfer from unlocked tokens
        for (uint256 i = 0; i < timelockCountOf(from); i++) {
            // if the timelock has no value left
            if (
                timelocks[from][i].tokensTransferred ==
                timelocks[from][i].totalAmount
            ) {
                continue;
            } else if (remainingTransfer > unlockedBalanceOfTimelock(from, i)) {
                // if the remainingTransfer is more than the unlocked balance use it all
                remainingTransfer -= unlockedBalanceOfTimelock(from, i);
                timelocks[from][i]
                    .tokensTransferred += unlockedBalanceOfTimelock(from, i);
            } else {
                // if the remainingTransfer is less than or equal to the unlocked balance
                // use part or all and exit the loop
                timelocks[from][i].tokensTransferred += remainingTransfer;
                remainingTransfer = 0;
                break;
            }
        }

        // should never have a remainingTransfer amount at this point
        require(remainingTransfer == 0, "bad transfer");

        token.safeTransfer(to, value);
        return true;
    }

    /**
        @notice transfers the unlocked token from an address's specific timelock
            It is typically more convenient to call transfer. But if the account has many timelocks the cost of gas
            for calling transfer may be too high. Calling transferTimelock from a specific timelock limits the transfer cost.
        @param to the address that the tokens will be transferred to
        @param value the number of token base units to me transferred to the to address
        @param timelockId the specific timelock of the function caller to transfer unlocked tokens from
        @return bool always true when completed
    */

    function transferTimelock(
        address to,
        uint256 value,
        uint256 timelockId
    ) external nonReentrant returns (bool) {
        require(
            unlockedBalanceOfTimelock(msg.sender, timelockId) >= value,
            "amount > unlocked"
        );
        timelocks[msg.sender][timelockId].tokensTransferred += value;
        token.safeTransfer(to, value);
        return true;
    }

    /**
        @notice calculates how many tokens would be released at a specified time for a scheduleId.
            This is independent of any specific address or address's timelock.
        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param scheduleId the schedule id used to calculate the unlocked amount
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        uint256 scheduleId
    ) public view returns (uint256 unlocked) {
        return
            calculateUnlocked(
                commencedTimestamp,
                currentTimestamp,
                amount,
                releaseSchedules[scheduleId]
            );
    }

    // Code from OpenZeppelin's contract/token/ERC20/ERC20.sol, modified
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "owner is 0 address");
        require(spender != address(0), "spender is 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // @notice the total number of schedules that have been created
    function scheduleCount() external view returns (uint256 count) {
        return releaseSchedules.length;
    }

    /**
        @notice Get the struct details for an address's specific timelock
        @param who Address to check
        @param index The index of the timelock for the who address
        @return timelock Struct with the attributes of the timelock
    */
    function timelockOf(address who, uint256 index)
        public
        view
        returns (Timelock memory timelock)
    {
        return timelocks[who][index];
    }

    // @notice returns the total count of timelocks for a specific address
    function timelockCountOf(address who) public view returns (uint256) {
        return timelocks[who].length;
    }

    /**
        @notice calculates how many tokens would be released at a specified time for a ReleaseSchedule struct.
            This is independent of any specific address or address's timelock.
        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param releaseSchedule a ReleaseSchedule struct used to calculate the unlocked amount
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        ReleaseSchedule memory releaseSchedule
    ) public pure returns (uint256 unlocked) {
        return
            calculateUnlocked(
                commencedTimestamp,
                currentTimestamp,
                amount,
                releaseSchedule.releaseCount,
                releaseSchedule.delayUntilFirstReleaseInSeconds,
                releaseSchedule.initialReleasePortionInBips,
                releaseSchedule.periodBetweenReleasesInSeconds
            );
    }

    /**
        @notice The same functionality as above function with spread format of `releaseSchedule` arg
        @param commencedTimestamp the commencement time to use in the calculation for the scheduled
        @param currentTimestamp the timestamp to calculate unlocked tokens for
        @param amount the amount of tokens
        @param releaseCount Total number of releases including any initial "cliff'
        @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
        @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
        @param periodBetweenReleasesInSeconds After the delay and initial release
        @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        uint256 releaseCount,
        uint256 delayUntilFirstReleaseInSeconds,
        uint256 initialReleasePortionInBips,
        uint256 periodBetweenReleasesInSeconds
    ) public pure returns (uint256 unlocked) {
        if (commencedTimestamp > currentTimestamp) {
            return 0;
        }
        uint256 secondsElapsed = currentTimestamp - commencedTimestamp;

        // return the full amount if the total lockup period has expired
        // unlocked amounts in each period are truncated and round down remainders smaller than the smallest unit
        // unlocking the full amount unlocks any remainder amounts in the final unlock period
        // this is done first to reduce computation
        if (
            secondsElapsed >=
            delayUntilFirstReleaseInSeconds +
                (periodBetweenReleasesInSeconds * (releaseCount - 1))
        ) {
            return amount;
        }

        // unlock the initial release if the delay has elapsed
        if (secondsElapsed >= delayUntilFirstReleaseInSeconds) {
            unlocked = (amount * initialReleasePortionInBips) / BIPS_PRECISION;

            // if at least one period after the delay has passed
            if (
                secondsElapsed - delayUntilFirstReleaseInSeconds >=
                periodBetweenReleasesInSeconds
            ) {
                // calculate the number of additional periods that have passed (not including the initial release)
                // this discards any remainders (ie it truncates / rounds down)
                uint256 additionalUnlockedPeriods = (secondsElapsed -
                    delayUntilFirstReleaseInSeconds) /
                    periodBetweenReleasesInSeconds;

                // calculate the amount of unlocked tokens for the additionalUnlockedPeriods
                // multiplication is applied before division to delay truncating to the smallest unit
                // this distributes unlocked tokens more evenly across unlock periods
                // than truncated division followed by multiplication
                unlocked +=
                    ((amount - unlocked) * additionalUnlockedPeriods) /
                    (releaseCount - 1);
            }
        }

        return unlocked;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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