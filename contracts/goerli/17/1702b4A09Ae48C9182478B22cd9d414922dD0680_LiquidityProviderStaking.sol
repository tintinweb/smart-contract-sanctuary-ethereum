// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";

/// @custom:salt LiquidityProviderStaking
/// @custom:deploy-type deployUpgradeable
contract LiquidityProviderStaking is StakingNFT {
    constructor() StakingNFT() {}

    function initialize() public onlyFactory initializer {
        __stakingNFTInit("ALQSNFT", "ALQS");
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "contracts/libraries/governance/GovernanceMaxLock.sol";
import "contracts/libraries/StakingNFT/StakingNFTStorage.sol";
import "contracts/utils/ImmutableAuth.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicValue.sol";
import "contracts/utils/CircuitBreaker.sol";
import "contracts/utils/AtomicCounter.sol";
import "contracts/interfaces/ICBOpener.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IStakingNFTDescriptor.sol";
import "contracts/libraries/errors/StakingNFTErrors.sol";
import "contracts/libraries/errors/CircuitBreakerErrors.sol";

abstract contract StakingNFT is
    Initializable,
    ERC721EnumerableUpgradeable,
    CircuitBreaker,
    AtomicCounter,
    StakingNFTStorage,
    MagicValue,
    EthSafeTransfer,
    ERC20SafeTransfer,
    GovernanceMaxLock,
    ICBOpener,
    IStakingNFT,
    ImmutableFactory,
    ImmutableValidatorPool,
    ImmutableAToken,
    ImmutableGovernance,
    ImmutableStakingPositionDescriptor
{
    modifier onlyIfTokenExists(uint256 tokenID_) {
        if (!_exists(tokenID_)) {
            revert StakingNFTErrors.InvalidTokenId(tokenID_);
        }
        _;
    }

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableAToken()
        ImmutableGovernance()
        ImmutableValidatorPool()
        ImmutableStakingPositionDescriptor()
    {}

    /// @dev tripCB opens the circuit breaker may only be called by _factory owner
    function tripCB() public override onlyFactory {
        _tripCB();
    }

    /// skimExcessEth will send to the address passed as to_ any amount of Eth
    /// held by this contract that is not tracked by the Accumulator system. This
    /// function allows the Admin role to refund any Eth sent to this contract in
    /// error by a user. This method can not return any funds sent to the contract
    /// via the depositEth method. This function should only be necessary if a
    /// user somehow manages to accidentally selfDestruct a contract with this
    /// contract as the recipient.
    function skimExcessEth(address to_) public onlyFactory returns (uint256 excess) {
        excess = _estimateExcessEth();
        _safeTransferEth(to_, excess);
        return excess;
    }

    /// skimExcessToken will send to the address passed as to_ any amount of
    /// AToken held by this contract that is not tracked by the Accumulator
    /// system. This function allows the Admin role to refund any AToken sent to
    /// this contract in error by a user. This method can not return any funds
    /// sent to the contract via the depositToken method.
    function skimExcessToken(address to_) public onlyFactory returns (uint256 excess) {
        IERC20Transferable aToken;
        (aToken, excess) = _estimateExcessToken();
        _safeTransferERC20(aToken, to_, excess);
        return excess;
    }

    /// lockPosition is called by governance system when a governance
    /// vote is cast. This function will lock the specified Position for up to
    /// _MAX_GOVERNANCE_LOCK. This method may only be called by the governance
    /// contract. This function will fail if the circuit breaker is tripped
    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) public override withCircuitBreaker onlyGovernance returns (uint256) {
        if (caller_ != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockPosition(tokenID_, lockDuration_);
    }

    /// This function will lock an owned Position for up to _MAX_GOVERNANCE_LOCK. This method may
    /// only be called by the owner of the Position. This function will fail if the circuit breaker
    /// is tripped
    function lockOwnPosition(uint256 tokenID_, uint256 lockDuration_)
        public
        withCircuitBreaker
        returns (uint256)
    {
        if (msg.sender != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockPosition(tokenID_, lockDuration_);
    }

    /// This function will lock withdraws on the specified Position for up to
    /// _MAX_GOVERNANCE_LOCK. This function will fail if the circuit breaker is tripped
    function lockWithdraw(uint256 tokenID_, uint256 lockDuration_)
        public
        withCircuitBreaker
        returns (uint256)
    {
        if (msg.sender != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockWithdraw(tokenID_, lockDuration_);
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION AS ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY. depositToken distributes AToken
    /// to all stakers evenly should only be called during a slashing event. Any
    /// AToken sent to this method in error will be lost. This function will
    /// fail if the circuit breaker is tripped. The magic_ parameter is intended
    /// to stop some one from successfully interacting with this method without
    /// first reading the source code and hopefully this comment
    function depositToken(uint8 magic_, uint256 amount_)
        public
        withCircuitBreaker
        checkMagic(magic_)
    {
        // collect tokens
        _safeTransferFromERC20(IERC20Transferable(_aTokenAddress()), msg.sender, amount_);
        // update state
        _tokenState = _deposit(amount_, _tokenState);
        _reserveToken += amount_;
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY depositEth distributes Eth to all
    /// stakers evenly should only be called by BTokens contract any Eth sent to
    /// this method in error will be lost this function will fail if the circuit
    /// breaker is tripped the magic_ parameter is intended to stop some one from
    /// successfully interacting with this method without first reading the
    /// source code and hopefully this comment
    function depositEth(uint8 magic_) public payable withCircuitBreaker checkMagic(magic_) {
        _ethState = _deposit(msg.value, _ethState);
        _reserveEth += msg.value;
    }

    /// mint allows a staking position to be opened. This function
    /// requires the caller to have performed an approve invocation against
    /// AToken into this contract. This function will fail if the circuit
    /// breaker is tripped.
    function mint(uint256 amount_) public virtual withCircuitBreaker returns (uint256 tokenID) {
        return _mintNFT(msg.sender, amount_);
    }

    /// mintTo allows a staking position to be opened in the name of an
    /// account other than the caller. This method also allows a lock to be
    /// placed on the position up to _MAX_MINT_LOCK . This function requires the
    /// caller to have performed an approve invocation against AToken into
    /// this contract. This function will fail if the circuit breaker is
    /// tripped.
    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) public virtual withCircuitBreaker returns (uint256 tokenID) {
        if (lockDuration_ > _MAX_MINT_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanMintLock();
        }
        tokenID = _mintNFT(to_, amount_);
        if (lockDuration_ > 0) {
            _lockPosition(tokenID, lockDuration_);
        }
        return tokenID;
    }

    /// burn exits a staking position such that all accumulated value is
    /// transferred to the owner on burn.
    function burn(uint256 tokenID_)
        public
        virtual
        returns (uint256 payoutEth, uint256 payoutAToken)
    {
        return _burn(msg.sender, msg.sender, tokenID_);
    }

    /// burnTo exits a staking position such that all accumulated value
    /// is transferred to a specified account on burn
    function burnTo(address to_, uint256 tokenID_)
        public
        virtual
        returns (uint256 payoutEth, uint256 payoutAToken)
    {
        return _burn(msg.sender, to_, tokenID_);
    }

    /// collects the ether yield of a given position. The caller of this function
    /// must be the owner of the tokenID.
    function collectEth(uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectEthTo(msg.sender, tokenID_);
    }

    /// collects the ALCa tokens yield of a given position. The caller of
    /// this function must be the owner of the tokenID.
    function collectToken(uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectTokenTo(msg.sender, tokenID_);
    }

    /// collects the ether and ALCa tokens yields of a given position. The caller of
    /// this function must be the owner of the tokenID.
    function collectAllProfits(uint256 tokenID_)
        public
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        payoutToken = _collectTokenTo(msg.sender, tokenID_);
        payoutEth = _collectEthTo(msg.sender, tokenID_);
    }

    /// collects the ether yield of a given position and send to the `to_` address.
    /// The caller of this function must be the owner of the tokenID.
    function collectEthTo(address to_, uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectEthTo(to_, tokenID_);
    }

    /// collects the ALCa tokens yield of a given position and send to the `to_`
    /// address. The caller of this function must be the owner of the tokenID.
    function collectTokenTo(address to_, uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectTokenTo(to_, tokenID_);
    }

    /// collects the ether and ALCa tokens yields of a given position and send to the
    /// `to_` address. The caller of this function must be the owner of the tokenID.
    function collectAllProfitsTo(address to_, uint256 tokenID_)
        public
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        payoutToken = _collectTokenTo(to_, tokenID_);
        payoutEth = _collectEthTo(to_, tokenID_);
    }

    /// gets the total amount of AToken staked in contract
    function getTotalShares() public view returns (uint256) {
        return _shares;
    }

    /// gets the total amount of Ether staked in contract
    function getTotalReserveEth() public view returns (uint256) {
        return _reserveEth;
    }

    /// gets the total amount of AToken staked in contract
    function getTotalReserveAToken() public view returns (uint256) {
        return _reserveToken;
    }

    /// estimateEthCollection returns the amount of eth a tokenID may withdraw
    function estimateEthCollection(uint256 tokenID_)
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (uint256 payout)
    {
        Position memory p = _positions[tokenID_];
        Accumulator memory ethState = _ethState;
        uint256 shares = _shares;
        (, , , payout) = _collect(shares, ethState, p, p.accumulatorEth);
        return payout;
    }

    /// estimateTokenCollection returns the amount of AToken a tokenID may withdraw
    function estimateTokenCollection(uint256 tokenID_)
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (uint256 payout)
    {
        Position memory p = _positions[tokenID_];
        uint256 shares = _shares;
        Accumulator memory tokenState = _tokenState;
        (, , , payout) = _collect(shares, tokenState, p, p.accumulatorToken);
        return payout;
    }

    /// estimateAllProfits returns the amount of AToken a tokenID may withdraw
    function estimateAllProfits(uint256 tokenID_)
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        Position memory p = _positions[tokenID_];
        uint256 shares = _shares;
        (, , , payoutEth) = _collect(shares, _ethState, p, p.accumulatorEth);
        (, , , payoutToken) = _collect(shares, _tokenState, p, p.accumulatorToken);
    }

    /// estimateExcessToken returns the amount of AToken that is held in the
    /// name of this contract. The value returned is the value that would be
    /// returned by a call to skimExcessToken.
    function estimateExcessToken() public view returns (uint256 excess) {
        (, excess) = _estimateExcessToken();
        return excess;
    }

    /// estimateExcessEth returns the amount of Eth that is held in the name of
    /// this contract. The value returned is the value that would be returned by
    /// a call to skimExcessEth.
    function estimateExcessEth() public view returns (uint256 excess) {
        return _estimateExcessEth();
    }

    /// gets the position struct given a tokenID. The tokenId must
    /// exist.
    function getPosition(uint256 tokenID_)
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        )
    {
        Position memory p = _positions[tokenID_];
        shares = uint256(p.shares);
        freeAfter = uint256(p.freeAfter);
        withdrawFreeAfter = uint256(p.withdrawFreeAfter);
        accumulatorEth = p.accumulatorEth;
        accumulatorToken = p.accumulatorToken;
    }

    /// Gets token URI
    function tokenURI(uint256 tokenID_)
        public
        view
        override(ERC721Upgradeable)
        onlyIfTokenExists(tokenID_)
        returns (string memory)
    {
        return IStakingNFTDescriptor(_stakingPositionDescriptorAddress()).tokenURI(this, tokenID_);
    }

    /// gets the current value for the Eth accumulator
    function getEthAccumulator() public view returns (uint256 accumulator, uint256 slush) {
        accumulator = _ethState.accumulator;
        slush = _ethState.slush;
    }

    /// gets the current value for the Token accumulator
    function getTokenAccumulator() public view returns (uint256 accumulator, uint256 slush) {
        accumulator = _tokenState.accumulator;
        slush = _tokenState.slush;
    }

    /// gets the ID of the latest minted position
    function getLatestMintedPositionID() public view returns (uint256) {
        return _getCount();
    }

    /// gets the _ACCUMULATOR_SCALE_FACTOR used to scale the ether and tokens
    /// deposited on this contract to reduce the integer division errors.
    function getAccumulatorScaleFactor() public pure returns (uint256) {
        return _ACCUMULATOR_SCALE_FACTOR;
    }

    /// gets the _MAX_MINT_LOCK value. This value is the maximum duration of blocks that we allow a
    /// position to be locked when minted
    function getMaxMintLock() public pure returns (uint256) {
        return _MAX_MINT_LOCK;
    }

    /// gets the _MAX_MINT_LOCK value. This value is the maximum duration of blocks that we allow a
    /// position to be locked
    function getMaxGovernanceLock() public pure returns (uint256) {
        return _MAX_GOVERNANCE_LOCK;
    }

    function __stakingNFTInit(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init(name_, symbol_);
    }

    // _lockPosition prevents a position from being burned for duration_ number
    // of blocks by setting the freeAfter field on the Position struct returns
    // the number of shares in the locked Position so that governance vote
    // counting may be performed when setting a lock
    //
    // Note well: This function *assumes* that tokenID position exists.
    //            This is because the existance check is performed
    //            at the higher level.
    function _lockPosition(uint256 tokenID_, uint256 duration_)
        internal
        onlyIfTokenExists(tokenID_)
        returns (uint256 shares)
    {
        Position memory p = _positions[tokenID_];
        uint32 freeDur = uint32(block.number) + uint32(duration_);
        p.freeAfter = freeDur > p.freeAfter ? freeDur : p.freeAfter;
        _positions[tokenID_] = p;
        return p.shares;
    }

    // _lockWithdraw prevents a position from being collected and burned for duration_ number of blocks
    // by setting the withdrawFreeAfter field on the Position struct.
    // returns the number of shares in the locked Position so that
    //
    // Note well: This function *assumes* that tokenID position exists.
    //            This is because the existance check is performed
    //            at the higher level.
    function _lockWithdraw(uint256 tokenID_, uint256 duration_)
        internal
        onlyIfTokenExists(tokenID_)
        returns (uint256 shares)
    {
        Position memory p = _positions[tokenID_];
        uint256 freeDur = block.number + duration_;
        p.withdrawFreeAfter = freeDur > p.withdrawFreeAfter ? freeDur : p.withdrawFreeAfter;
        _positions[tokenID_] = p;
        return p.shares;
    }

    // _mintNFT performs the mint operation and invokes the inherited _mint method
    function _mintNFT(address to_, uint256 amount_) internal returns (uint256 tokenID) {
        // this is to allow struct packing and is safe due to AToken having a
        // total distribution of 220M
        if (amount_ == 0) {
            revert StakingNFTErrors.MintAmountZero();
        }
        if (amount_ > 2**224 - 1) {
            revert StakingNFTErrors.MintAmountExceedsMaximumSupply();
        }
        // transfer the number of tokens specified by amount_ into contract
        // from the callers account
        _safeTransferFromERC20(IERC20Transferable(_aTokenAddress()), msg.sender, amount_);

        // get local copy of storage vars to save gas
        uint256 shares = _shares;
        Accumulator memory ethState = _ethState;
        Accumulator memory tokenState = _tokenState;

        // get new tokenID from counter
        tokenID = _increment();

        // Call _slushSkim on Eth and Token accumulator before minting staked position.
        // This ensures that all stakers receive their appropriate rewards.
        if (shares > 0) {
            (ethState.accumulator, ethState.slush) = _slushSkim(
                shares,
                ethState.accumulator,
                ethState.slush
            );
            _ethState = ethState;
            (tokenState.accumulator, tokenState.slush) = _slushSkim(
                shares,
                tokenState.accumulator,
                tokenState.slush
            );
            _tokenState = tokenState;
        }

        // update storage
        shares += amount_;
        _shares = shares;
        _positions[tokenID] = Position(
            uint224(amount_),
            uint32(block.number) + 1,
            uint32(block.number) + 1,
            ethState.accumulator,
            tokenState.accumulator
        );
        _reserveToken += amount_;
        // invoke inherited method and return
        ERC721Upgradeable._mint(to_, tokenID);
        return tokenID;
    }

    // _burn performs the burn operation and invokes the inherited _burn method
    function _burn(
        address from_,
        address to_,
        uint256 tokenID_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        if (from_ != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }

        // collect state
        Position memory p = _positions[tokenID_];
        // enforce freeAfter to prevent burn during lock
        if (p.freeAfter >= block.number || p.withdrawFreeAfter >= block.number) {
            revert StakingNFTErrors.FreeAfterTimeNotReached();
        }

        // get copy of storage to save gas
        uint256 shares = _shares;

        // calc Eth amounts due
        (p, payoutEth) = _collectEth(shares, p);

        // calc token amounts due
        (p, payoutToken) = _collectToken(shares, p);

        // add back to token payout the original stake position
        payoutToken += p.shares;

        // debit global shares counter and delete from mapping
        _shares -= p.shares;
        _reserveToken -= payoutToken;
        _reserveEth -= payoutEth;
        delete _positions[tokenID_];

        // invoke inherited burn method
        ERC721Upgradeable._burn(tokenID_);

        // transfer out all eth and tokens owed
        _safeTransferERC20(IERC20Transferable(_aTokenAddress()), to_, payoutToken);
        _safeTransferEth(to_, payoutEth);
        return (payoutEth, payoutToken);
    }

    /// collectEth returns all due Eth allocations to the to_ address. The caller
    /// of this function must be the owner of the tokenID
    function _collectEthTo(address to_, uint256 tokenID_) internal returns (uint256 payout) {
        Position memory position = _getPositionToCollect(tokenID_);
        // get values and update state
        (_positions[tokenID_], payout) = _collectEth(_shares, position);
        _reserveEth -= payout;
        // perform transfer and return amount paid out
        _safeTransferEth(to_, payout);
        return payout;
    }

    function _collectTokenTo(address to_, uint256 tokenID_) internal returns (uint256 payout) {
        Position memory position = _getPositionToCollect(tokenID_);
        // get values and update state
        (_positions[tokenID_], payout) = _collectToken(_shares, position);
        _reserveToken -= payout;
        // perform transfer and return amount paid out
        _safeTransferERC20(IERC20Transferable(_aTokenAddress()), to_, payout);
        return payout;
    }

    function _collectToken(uint256 shares_, Position memory p_)
        internal
        returns (Position memory p, uint256 payout)
    {
        uint256 acc;
        Accumulator memory tokenState = _tokenState;
        (tokenState, p, acc, payout) = _collect(shares_, tokenState, p_, p_.accumulatorToken);
        _tokenState = tokenState;
        p.accumulatorToken = acc;
        return (p, payout);
    }

    // _collectEth performs call to _collect and updates state during a request
    // for an eth distribution
    function _collectEth(uint256 shares_, Position memory p_)
        internal
        returns (Position memory p, uint256 payout)
    {
        uint256 acc;
        Accumulator memory ethState = _ethState;
        (ethState, p, acc, payout) = _collect(shares_, ethState, p_, p_.accumulatorEth);
        _ethState = ethState;
        p.accumulatorEth = acc;
        return (p, payout);
    }

    // _estimateExcessEth returns the amount of Eth that is held in the name of
    // this contract
    function _estimateExcessEth() internal view returns (uint256 excess) {
        uint256 reserve = _reserveEth;
        uint256 balance = address(this).balance;
        if (balance < reserve) {
            revert StakingNFTErrors.BalanceLessThanReserve(balance, reserve);
        }
        excess = balance - reserve;
    }

    // _estimateExcessToken returns the amount of AToken that is held in the
    // name of this contract
    function _estimateExcessToken()
        internal
        view
        returns (IERC20Transferable aToken, uint256 excess)
    {
        uint256 reserve = _reserveToken;
        aToken = IERC20Transferable(_aTokenAddress());
        uint256 balance = aToken.balanceOf(address(this));
        if (balance < reserve) {
            revert StakingNFTErrors.BalanceLessThanReserve(balance, reserve);
        }
        excess = balance - reserve;
        return (aToken, excess);
    }

    function _getPositionToCollect(uint256 tokenID_)
        internal
        view
        returns (Position memory position)
    {
        address owner = ownerOf(tokenID_);
        if (msg.sender != owner) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        position = _positions[tokenID_];
        if (_positions[tokenID_].withdrawFreeAfter >= block.number) {
            revert StakingNFTErrors.LockDurationWithdrawTimeNotReached();
        }
    }

    // _collect performs calculations necessary to determine any distributions
    // due to an account such that it may be used for both token and eth
    // distributions this prevents the need to keep redundant logic
    function _collect(
        uint256 shares_,
        Accumulator memory state_,
        Position memory p_,
        uint256 positionAccumulatorValue_
    )
        internal
        pure
        returns (
            Accumulator memory,
            Position memory,
            uint256,
            uint256
        )
    {
        (state_.accumulator, state_.slush) = _slushSkim(shares_, state_.accumulator, state_.slush);
        // determine number of accumulator steps this Position needs distributions from
        uint256 accumulatorDelta;
        if (positionAccumulatorValue_ > state_.accumulator) {
            accumulatorDelta = 2**168 - positionAccumulatorValue_;
            accumulatorDelta += state_.accumulator;
            positionAccumulatorValue_ = state_.accumulator;
        } else {
            accumulatorDelta = state_.accumulator - positionAccumulatorValue_;
            // update accumulator value for calling method
            positionAccumulatorValue_ += accumulatorDelta;
        }
        // calculate payout based on shares held in position
        uint256 payout = accumulatorDelta * p_.shares;
        // if there are no shares other than this position, flush the slush fund
        // into the payout and update the in memory state object
        if (shares_ == p_.shares) {
            payout += state_.slush;
            state_.slush = 0;
        }

        uint256 payoutRemainder = payout;
        // reduce payout by scale factor
        payout /= _ACCUMULATOR_SCALE_FACTOR;
        // Computing and saving the numeric error from the floor division in the
        // slush.
        payoutRemainder -= payout * _ACCUMULATOR_SCALE_FACTOR;
        state_.slush += payoutRemainder;

        return (state_, p_, positionAccumulatorValue_, payout);
    }

    // _deposit allows an Accumulator to be updated with new value if there are
    // no currently staked positions, all value is stored in the slush
    function _deposit(uint256 delta_, Accumulator memory state_)
        internal
        pure
        returns (Accumulator memory)
    {
        state_.slush += (delta_ * _ACCUMULATOR_SCALE_FACTOR);

        // Slush should be never be above 2**167 to protect against overflow in
        // the later code.
        if (state_.slush >= 2**167) {
            revert StakingNFTErrors.SlushTooLarge(state_.slush);
        }
        return state_;
    }

    // _slushSkim flushes value from the slush into the accumulator if there are
    // no currently staked positions, all value is stored in the slush
    function _slushSkim(
        uint256 shares_,
        uint256 accumulator_,
        uint256 slush_
    ) internal pure returns (uint256, uint256) {
        if (shares_ > 0) {
            uint256 deltaAccumulator = slush_ / shares_;
            slush_ -= deltaAccumulator * shares_;
            accumulator_ += deltaAccumulator;
            // avoiding accumulator_ overflow.
            if (accumulator_ > type(uint168).max) {
                // The maximum allowed value for the accumulator is 2**168-1.
                // This hard limit was set to not overflow the operation
                // `accumulator * shares` that happens later in the code.
                accumulator_ = accumulator_ % (2**168);
            }
        }
        return (accumulator_, slush_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/ETHSafeTransferErrors.sol";

abstract contract EthSafeTransfer {
    /// @notice _safeTransferEth performs a transfer of Eth using the call
    /// method / this function is resistant to breaking gas price changes and /
    /// performs call in a safe manner by reverting on failure. / this function
    /// will return without performing a call or reverting, / if amount_ is zero
    function _safeTransferEth(address to_, uint256 amount_) internal {
        if (amount_ == 0) {
            return;
        }
        if (to_ == address(0)) {
            revert ETHSafeTransferErrors.CannotTransferToZeroAddress();
        }
        address payable caller = payable(to_);
        (bool success, ) = caller.call{value: amount_}("");
        if (!success) {
            revert ETHSafeTransferErrors.EthTransferFailed(address(this), to_, amount_);
        }
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/interfaces/IAliceNetFactory.sol";

abstract contract ImmutableFactory is DeterministicAddress {
    address private immutable _factory;
    error OnlyFactory(address sender, address expected);

    modifier onlyFactory() {
        if (msg.sender != _factory) {
            revert OnlyFactory(msg.sender, _factory);
        }
        _;
    }

    constructor(address factory_) {
        _factory = factory_;
    }

    function _factoryAddress() internal view returns (address) {
        return _factory;
    }
}

abstract contract ImmutableAToken is ImmutableFactory {
    address private immutable _aToken;
    error OnlyAToken(address sender, address expected);

    modifier onlyAToken() {
        if (msg.sender != _aToken) {
            revert OnlyAToken(msg.sender, _aToken);
        }
        _;
    }

    constructor() {
        _aToken = IAliceNetFactory(_factoryAddress()).lookup(_saltForAToken());
    }

    function _aTokenAddress() internal view returns (address) {
        return _aToken;
    }

    function _saltForAToken() internal pure returns (bytes32) {
        return 0x41546f6b656e0000000000000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableBToken is ImmutableFactory {
    address private immutable _bToken;
    error OnlyBToken(address sender, address expected);

    modifier onlyBToken() {
        if (msg.sender != _bToken) {
            revert OnlyBToken(msg.sender, _bToken);
        }
        _;
    }

    constructor() {
        _bToken = IAliceNetFactory(_factoryAddress()).lookup(_saltForBToken());
    }

    function _bTokenAddress() internal view returns (address) {
        return _bToken;
    }

    function _saltForBToken() internal pure returns (bytes32) {
        return 0x42546f6b656e0000000000000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableATokenBurner is ImmutableFactory {
    address private immutable _aTokenBurner;
    error OnlyATokenBurner(address sender, address expected);

    modifier onlyATokenBurner() {
        if (msg.sender != _aTokenBurner) {
            revert OnlyATokenBurner(msg.sender, _aTokenBurner);
        }
        _;
    }

    constructor() {
        _aTokenBurner = getMetamorphicContractAddress(
            0x41546f6b656e4275726e65720000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _aTokenBurnerAddress() internal view returns (address) {
        return _aTokenBurner;
    }

    function _saltForATokenBurner() internal pure returns (bytes32) {
        return 0x41546f6b656e4275726e65720000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableATokenMinter is ImmutableFactory {
    address private immutable _aTokenMinter;
    error OnlyATokenMinter(address sender, address expected);

    modifier onlyATokenMinter() {
        if (msg.sender != _aTokenMinter) {
            revert OnlyATokenMinter(msg.sender, _aTokenMinter);
        }
        _;
    }

    constructor() {
        _aTokenMinter = getMetamorphicContractAddress(
            0x41546f6b656e4d696e7465720000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _aTokenMinterAddress() internal view returns (address) {
        return _aTokenMinter;
    }

    function _saltForATokenMinter() internal pure returns (bytes32) {
        return 0x41546f6b656e4d696e7465720000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableDistribution is ImmutableFactory {
    address private immutable _distribution;
    error OnlyDistribution(address sender, address expected);

    modifier onlyDistribution() {
        if (msg.sender != _distribution) {
            revert OnlyDistribution(msg.sender, _distribution);
        }
        _;
    }

    constructor() {
        _distribution = getMetamorphicContractAddress(
            0x446973747269627574696f6e0000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _distributionAddress() internal view returns (address) {
        return _distribution;
    }

    function _saltForDistribution() internal pure returns (bytes32) {
        return 0x446973747269627574696f6e0000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableDynamics is ImmutableFactory {
    address private immutable _dynamics;
    error OnlyDynamics(address sender, address expected);

    modifier onlyDynamics() {
        if (msg.sender != _dynamics) {
            revert OnlyDynamics(msg.sender, _dynamics);
        }
        _;
    }

    constructor() {
        _dynamics = getMetamorphicContractAddress(
            0x44796e616d696373000000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _dynamicsAddress() internal view returns (address) {
        return _dynamics;
    }

    function _saltForDynamics() internal pure returns (bytes32) {
        return 0x44796e616d696373000000000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableFoundation is ImmutableFactory {
    address private immutable _foundation;
    error OnlyFoundation(address sender, address expected);

    modifier onlyFoundation() {
        if (msg.sender != _foundation) {
            revert OnlyFoundation(msg.sender, _foundation);
        }
        _;
    }

    constructor() {
        _foundation = getMetamorphicContractAddress(
            0x466f756e646174696f6e00000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _foundationAddress() internal view returns (address) {
        return _foundation;
    }

    function _saltForFoundation() internal pure returns (bytes32) {
        return 0x466f756e646174696f6e00000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableGovernance is ImmutableFactory {
    address private immutable _governance;
    error OnlyGovernance(address sender, address expected);

    modifier onlyGovernance() {
        if (msg.sender != _governance) {
            revert OnlyGovernance(msg.sender, _governance);
        }
        _;
    }

    constructor() {
        _governance = getMetamorphicContractAddress(
            0x476f7665726e616e636500000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _governanceAddress() internal view returns (address) {
        return _governance;
    }

    function _saltForGovernance() internal pure returns (bytes32) {
        return 0x476f7665726e616e636500000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableInvalidTxConsumptionAccusation is ImmutableFactory {
    address private immutable _invalidTxConsumptionAccusation;
    error OnlyInvalidTxConsumptionAccusation(address sender, address expected);

    modifier onlyInvalidTxConsumptionAccusation() {
        if (msg.sender != _invalidTxConsumptionAccusation) {
            revert OnlyInvalidTxConsumptionAccusation(msg.sender, _invalidTxConsumptionAccusation);
        }
        _;
    }

    constructor() {
        _invalidTxConsumptionAccusation = getMetamorphicContractAddress(
            0x92a73f2b6573522d63c8fc84b5d8e5d615fbb685c1b3d7fad2155fe227daf848,
            _factoryAddress()
        );
    }

    function _invalidTxConsumptionAccusationAddress() internal view returns (address) {
        return _invalidTxConsumptionAccusation;
    }

    function _saltForInvalidTxConsumptionAccusation() internal pure returns (bytes32) {
        return 0x92a73f2b6573522d63c8fc84b5d8e5d615fbb685c1b3d7fad2155fe227daf848;
    }
}

abstract contract ImmutableLiquidityProviderStaking is ImmutableFactory {
    address private immutable _liquidityProviderStaking;
    error OnlyLiquidityProviderStaking(address sender, address expected);

    modifier onlyLiquidityProviderStaking() {
        if (msg.sender != _liquidityProviderStaking) {
            revert OnlyLiquidityProviderStaking(msg.sender, _liquidityProviderStaking);
        }
        _;
    }

    constructor() {
        _liquidityProviderStaking = getMetamorphicContractAddress(
            0x4c697175696469747950726f76696465725374616b696e670000000000000000,
            _factoryAddress()
        );
    }

    function _liquidityProviderStakingAddress() internal view returns (address) {
        return _liquidityProviderStaking;
    }

    function _saltForLiquidityProviderStaking() internal pure returns (bytes32) {
        return 0x4c697175696469747950726f76696465725374616b696e670000000000000000;
    }
}

abstract contract ImmutableMultipleProposalAccusation is ImmutableFactory {
    address private immutable _multipleProposalAccusation;
    error OnlyMultipleProposalAccusation(address sender, address expected);

    modifier onlyMultipleProposalAccusation() {
        if (msg.sender != _multipleProposalAccusation) {
            revert OnlyMultipleProposalAccusation(msg.sender, _multipleProposalAccusation);
        }
        _;
    }

    constructor() {
        _multipleProposalAccusation = getMetamorphicContractAddress(
            0xcfdffd500b4a956e03976b2afd69712237ffa06e35093df1e05e533688959fdc,
            _factoryAddress()
        );
    }

    function _multipleProposalAccusationAddress() internal view returns (address) {
        return _multipleProposalAccusation;
    }

    function _saltForMultipleProposalAccusation() internal pure returns (bytes32) {
        return 0xcfdffd500b4a956e03976b2afd69712237ffa06e35093df1e05e533688959fdc;
    }
}

abstract contract ImmutablePublicStaking is ImmutableFactory {
    address private immutable _publicStaking;
    error OnlyPublicStaking(address sender, address expected);

    modifier onlyPublicStaking() {
        if (msg.sender != _publicStaking) {
            revert OnlyPublicStaking(msg.sender, _publicStaking);
        }
        _;
    }

    constructor() {
        _publicStaking = getMetamorphicContractAddress(
            0x5075626c69635374616b696e6700000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _publicStakingAddress() internal view returns (address) {
        return _publicStaking;
    }

    function _saltForPublicStaking() internal pure returns (bytes32) {
        return 0x5075626c69635374616b696e6700000000000000000000000000000000000000;
    }
}

abstract contract ImmutableSnapshots is ImmutableFactory {
    address private immutable _snapshots;
    error OnlySnapshots(address sender, address expected);

    modifier onlySnapshots() {
        if (msg.sender != _snapshots) {
            revert OnlySnapshots(msg.sender, _snapshots);
        }
        _;
    }

    constructor() {
        _snapshots = getMetamorphicContractAddress(
            0x536e617073686f74730000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _snapshotsAddress() internal view returns (address) {
        return _snapshots;
    }

    function _saltForSnapshots() internal pure returns (bytes32) {
        return 0x536e617073686f74730000000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableStakingPositionDescriptor is ImmutableFactory {
    address private immutable _stakingPositionDescriptor;
    error OnlyStakingPositionDescriptor(address sender, address expected);

    modifier onlyStakingPositionDescriptor() {
        if (msg.sender != _stakingPositionDescriptor) {
            revert OnlyStakingPositionDescriptor(msg.sender, _stakingPositionDescriptor);
        }
        _;
    }

    constructor() {
        _stakingPositionDescriptor = getMetamorphicContractAddress(
            0x5374616b696e67506f736974696f6e44657363726970746f7200000000000000,
            _factoryAddress()
        );
    }

    function _stakingPositionDescriptorAddress() internal view returns (address) {
        return _stakingPositionDescriptor;
    }

    function _saltForStakingPositionDescriptor() internal pure returns (bytes32) {
        return 0x5374616b696e67506f736974696f6e44657363726970746f7200000000000000;
    }
}

abstract contract ImmutableValidatorPool is ImmutableFactory {
    address private immutable _validatorPool;
    error OnlyValidatorPool(address sender, address expected);

    modifier onlyValidatorPool() {
        if (msg.sender != _validatorPool) {
            revert OnlyValidatorPool(msg.sender, _validatorPool);
        }
        _;
    }

    constructor() {
        _validatorPool = getMetamorphicContractAddress(
            0x56616c696461746f72506f6f6c00000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _validatorPoolAddress() internal view returns (address) {
        return _validatorPool;
    }

    function _saltForValidatorPool() internal pure returns (bytes32) {
        return 0x56616c696461746f72506f6f6c00000000000000000000000000000000000000;
    }
}

abstract contract ImmutableValidatorStaking is ImmutableFactory {
    address private immutable _validatorStaking;
    error OnlyValidatorStaking(address sender, address expected);

    modifier onlyValidatorStaking() {
        if (msg.sender != _validatorStaking) {
            revert OnlyValidatorStaking(msg.sender, _validatorStaking);
        }
        _;
    }

    constructor() {
        _validatorStaking = getMetamorphicContractAddress(
            0x56616c696461746f725374616b696e6700000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _validatorStakingAddress() internal view returns (address) {
        return _validatorStaking;
    }

    function _saltForValidatorStaking() internal pure returns (bytes32) {
        return 0x56616c696461746f725374616b696e6700000000000000000000000000000000;
    }
}

abstract contract ImmutableETHDKGAccusations is ImmutableFactory {
    address private immutable _ethdkgAccusations;
    error OnlyETHDKGAccusations(address sender, address expected);

    modifier onlyETHDKGAccusations() {
        if (msg.sender != _ethdkgAccusations) {
            revert OnlyETHDKGAccusations(msg.sender, _ethdkgAccusations);
        }
        _;
    }

    constructor() {
        _ethdkgAccusations = getMetamorphicContractAddress(
            0x455448444b4741636375736174696f6e73000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgAccusationsAddress() internal view returns (address) {
        return _ethdkgAccusations;
    }

    function _saltForETHDKGAccusations() internal pure returns (bytes32) {
        return 0x455448444b4741636375736174696f6e73000000000000000000000000000000;
    }
}

abstract contract ImmutableETHDKGPhases is ImmutableFactory {
    address private immutable _ethdkgPhases;
    error OnlyETHDKGPhases(address sender, address expected);

    modifier onlyETHDKGPhases() {
        if (msg.sender != _ethdkgPhases) {
            revert OnlyETHDKGPhases(msg.sender, _ethdkgPhases);
        }
        _;
    }

    constructor() {
        _ethdkgPhases = getMetamorphicContractAddress(
            0x455448444b475068617365730000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgPhasesAddress() internal view returns (address) {
        return _ethdkgPhases;
    }

    function _saltForETHDKGPhases() internal pure returns (bytes32) {
        return 0x455448444b475068617365730000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableETHDKG is ImmutableFactory {
    address private immutable _ethdkg;
    error OnlyETHDKG(address sender, address expected);

    modifier onlyETHDKG() {
        if (msg.sender != _ethdkg) {
            revert OnlyETHDKG(msg.sender, _ethdkg);
        }
        _;
    }

    constructor() {
        _ethdkg = getMetamorphicContractAddress(
            0x455448444b470000000000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgAddress() internal view returns (address) {
        return _ethdkg;
    }

    function _saltForETHDKG() internal pure returns (bytes32) {
        return 0x455448444b470000000000000000000000000000000000000000000000000000;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/libraries/errors/ERC20SafeTransferErrors.sol";

abstract contract ERC20SafeTransfer {
    // _safeTransferFromERC20 performs a transferFrom call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferFromERC20(
        IERC20Transferable contract_,
        address sender_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }

        bool success = contract_.transferFrom(sender_, address(this), amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                sender_,
                address(this),
                amount_
            );
        }
    }

    // _safeTransferERC20 performs a transfer call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferERC20(
        IERC20Transferable contract_,
        address to_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }
        bool success = contract_.transfer(to_, amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                address(this),
                to_,
                amount_
            );
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/MagicValueErrors.sol";

abstract contract MagicValue {
    // _MAGIC_VALUE is a constant that may be used to prevent
    // a user from calling a dangerous method without significant
    // effort or ( hopefully ) reading the code to understand the risk
    uint8 internal constant _MAGIC_VALUE = 42;

    modifier checkMagic(uint8 magic_) {
        if (magic_ != _getMagic()) {
            revert MagicValueErrors.BadMagic(magic_);
        }
        _;
    }

    // _getMagic returns the magic constant
    function _getMagic() internal pure returns (uint8) {
        return _MAGIC_VALUE;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/CircuitBreakerErrors.sol";

abstract contract CircuitBreaker {
    // constants for the cb state
    bool internal constant _CIRCUIT_BREAKER_CLOSED = false;
    bool internal constant _CIRCUIT_BREAKER_OPENED = true;

    // Same as _CIRCUIT_BREAKER_CLOSED
    bool internal _circuitBreaker;

    // withCircuitBreaker is a modifier to enforce the CircuitBreaker must
    // be set for a call to succeed
    modifier withCircuitBreaker() {
        if (_circuitBreaker == _CIRCUIT_BREAKER_OPENED) {
            revert CircuitBreakerErrors.CircuitBreakerOpened();
        }
        _;
    }

    function circuitBreakerState() public view returns (bool) {
        return _circuitBreaker;
    }

    function _tripCB() internal {
        if (_circuitBreaker == _CIRCUIT_BREAKER_OPENED) {
            revert CircuitBreakerErrors.CircuitBreakerOpened();
        }

        _circuitBreaker = _CIRCUIT_BREAKER_OPENED;
    }

    function _resetCB() internal {
        if (_circuitBreaker == _CIRCUIT_BREAKER_CLOSED) {
            revert CircuitBreakerErrors.CircuitBreakerClosed();
        }

        _circuitBreaker = _CIRCUIT_BREAKER_CLOSED;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract AtomicCounter {
    // monotonically increasing counter
    uint256 internal _counter;

    // _newTokenID increments the counter and returns the new value
    function _increment() internal returns (uint256 count) {
        count = _counter;
        count += 1;
        _counter = count;
        return count;
    }

    function _getCount() internal view returns (uint256) {
        return _counter;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingNFT {
    function skimExcessEth(address to_) external returns (uint256 excess);

    function skimExcessToken(address to_) external returns (uint256 excess);

    function depositToken(uint8 magic_, uint256 amount_) external;

    function depositEth(uint8 magic_) external payable;

    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) external returns (uint256);

    function lockOwnPosition(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function lockWithdraw(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function mint(uint256 amount_) external returns (uint256 tokenID);

    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) external returns (uint256 tokenID);

    function burn(uint256 tokenID_) external returns (uint256 payoutEth, uint256 payoutAToken);

    function burnTo(address to_, uint256 tokenID_)
        external
        returns (uint256 payoutEth, uint256 payoutAToken);

    function collectEth(uint256 tokenID_) external returns (uint256 payout);

    function collectToken(uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfits(uint256 tokenID_)
        external
        returns (uint256 payoutToken, uint256 payoutEth);

    function collectEthTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectTokenTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfitsTo(address to_, uint256 tokenID_)
        external
        returns (uint256 payoutToken, uint256 payoutEth);

    function getPosition(uint256 tokenID_)
        external
        view
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        );

    function getTotalShares() external view returns (uint256);

    function getTotalReserveEth() external view returns (uint256);

    function getTotalReserveAToken() external view returns (uint256);

    function estimateEthCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateTokenCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateAllProfits(uint256 tokenID_)
        external
        view
        returns (uint256 payoutEth, uint256 payoutToken);

    function estimateExcessToken() external view returns (uint256 excess);

    function estimateExcessEth() external view returns (uint256 excess);

    function getEthAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getTokenAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getLatestMintedPositionID() external view returns (uint256);

    function getAccumulatorScaleFactor() external pure returns (uint256);

    function getMaxMintLock() external pure returns (uint256);

    function getMaxGovernanceLock() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface ICBOpener {
    function tripCB() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingNFT.sol";

/// @title Describes a staked position NFT tokens via URI
interface IStakingNFTDescriptor {
    /// @notice Produces the URI describing a particular token ID for a staked position
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @param _stakingNFT The stake NFT for which to describe the token
    /// @param tokenId The ID of the token for which to produce a description, which may not be valid
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(IStakingNFT _stakingNFT, uint256 tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract GovernanceMaxLock {
    // _MAX_GOVERNANCE_LOCK describes the maximum interval
    // a position may remained locked due to a
    // governance action
    // this value is approx 30 days worth of blocks
    // prevents double spend of voting weight
    uint256 internal constant _MAX_GOVERNANCE_LOCK = 172800;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract StakingNFTStorage {
    // Position describes a staked position
    struct Position {
        // number of aToken
        uint224 shares;
        // block number after which the position may be burned.
        // prevents double spend of voting weight
        uint32 freeAfter;
        // block number after which the position may be collected or burned.
        uint256 withdrawFreeAfter;
        // the last value of the ethState accumulator this account performed a
        // withdraw at
        uint256 accumulatorEth;
        // the last value of the tokenState accumulator this account performed a
        // withdraw at
        uint256 accumulatorToken;
    }

    // Accumulator is a struct that allows values to be collected such that the
    // remainders of floor division may be cleaned up
    struct Accumulator {
        // accumulator is a sum of all changes always increasing
        uint256 accumulator;
        // slush stores division remainders until they may be distributed evenly
        uint256 slush;
    }

    // _MAX_MINT_LOCK describes the maximum interval a Position may be locked
    // during a call to mintTo
    uint256 internal constant _MAX_MINT_LOCK = 1051200;
    // 10**18
    uint256 internal constant _ACCUMULATOR_SCALE_FACTOR = 1000000000000000000;

    // _shares stores total amount of AToken staked in contract
    uint256 internal _shares;

    // _tokenState tracks distribution of AToken that originate from slashing
    // events
    Accumulator internal _tokenState;

    // _ethState tracks the distribution of Eth that originate from the sale of
    // BTokens
    Accumulator internal _ethState;

    // _positions tracks all staked positions based on tokenID
    mapping(uint256 => Position) internal _positions;

    // state to keep track of the amount of Eth deposited and collected from the
    // contract
    uint256 internal _reserveEth;

    // state to keep track of the amount of ATokens deposited and collected
    // from the contract
    uint256 internal _reserveToken;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library StakingNFTErrors {
    error CallerNotTokenOwner(address caller);
    error LockDurationGreaterThanGovernanceLock();
    error LockDurationGreaterThanMintLock();
    error LockDurationWithdrawTimeNotReached();
    error InvalidTokenId(uint256 tokenId);
    error MintAmountExceedsMaximumSupply();
    error FreeAfterTimeNotReached();
    error BalanceLessThanReserve(uint256 balance, uint256 reserve);
    error SlushTooLarge(uint256 slush);
    error MintAmountZero();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library CircuitBreakerErrors {
    error CircuitBreakerOpened();
    error CircuitBreakerClosed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ETHSafeTransferErrors {
    error CannotTransferToZeroAddress();
    error EthTransferFailed(address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(bytes32 _salt, address _factory)
        public
        pure
        returns (address)
    {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IAliceNetFactory {
    function lookup(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IERC20Transferable {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ERC20SafeTransferErrors {
    error CannotCallContractMethodsOnZeroAddress();
    error Erc20TransferFailed(address erc20Address, address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicValueErrors {
    error BadMagic(uint256 magic);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}