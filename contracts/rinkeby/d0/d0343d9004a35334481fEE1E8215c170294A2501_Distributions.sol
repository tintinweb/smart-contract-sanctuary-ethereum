/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./ISubredditPoints.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./Compress.sol";

/*
    Implements logic to mint points every round and tracks points receivers such as shared owners
    (get's cut from all minted points), users rounds and their account IDs
*/

contract Distributions is Initializable, OwnableUpgradeable {

    struct SharedOwner {
        address account;
        uint256 percent; // e.g. 30% percent = 30 * percentPrecision/100
    }

    struct DistributionRound {
        uint256 availablePoints;
        uint256 sharedOwnersAvailablePoints;
        uint256 totalKarma;
    }

    event SharedOwnerUpdated(
        address indexed _from,
        address indexed _to,
        uint256 _percent
    );

    event AdvanceRound(uint256 round, uint256 totalPoints, uint256 sharedOwnersPoints);
    event ClaimPoints(uint256 round, address indexed user, uint256 karma, uint256 points);
    event KarmaSourceUpdated(address karmaSource, address prevKarmaSource);
    event SupplyDecayPercentUpdated(uint256 supplyDecayPercent);
    event RoundsBeforeExpirationUpdated(uint256 roundsBeforeExpiration);
    event AccountRegistered(address indexed user, uint256 indexed accountId);

    enum AirdropBatchType {ACCOUNTS, ADDRESSES, GROUPED_ACCOUNTS, GROUPED_ADDRESSES}

    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using BytesLib for bytes;
    using Compress for bytes;

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    ISubredditPoints public subredditPoints;
    address public karmaSource;
    string public subreddit;
    string internal _subredditLowerCase;
    uint256 public lastRound;
    // maps round number to round data
    mapping(uint256 => DistributionRound) internal _distributionRounds;
    // maps account to next claimable round
    mapping(address => uint256) internal _claimableRounds;

    // when sharing percentage, the least possible share is 1/percentPrecision
    uint256 public constant PERCENT_PRECISION = 1000000;
    uint256 public constant MAX_ROUND_SUPPLY = 10 ** 11 * 10 ** 18; // max is 100 bln, to prevent overflows

    // 1 shared owner ~ 35k gas + 250k gas for other ops in advanceToRound
    // so we limit to (8M - 250k)/35k = 221 maximum shared owners
    uint256 public constant MAX_SHARED_OWNERS = 200;

    uint256 public initialSupply;
    uint256 public roundsBeforeExpiration;
    uint256 public nextSupply;
    uint256 public supplyDecayPercent;

    // those owners if exists will get proportion of minted points according to value in percentage
    SharedOwner[] public sharedOwners;
    uint256 internal _prevRoundSupply;       // supply in a prev round
    uint256 internal _prevClaimed;           // total claimed in a prev round

    // Previous karmaSource signer. Used when rotating karmaSource key to enable
    // previous signer to still be valid for a while.
    address public prevKarmaSource;

    // maps account addresses to account ids
    mapping(uint256 => address) internal _accountAddresses;
    mapping(address => uint256) internal _accountIds;
    uint256 internal _lastAccountId;

    uint256 internal _prevOwnersShare;

    // END OF VARS
    // ------------------------------------------------------------------------------------


    function initialize(
        address owner_,
        address subredditPoints_, // ISubredditPoints + IERC20 token contract address
        address karmaSource_, // Karma source provider address

        uint256 initialSupply_,
        uint256 nextSupply_,
        uint256 initialKarma_,
        uint256 roundsBeforeExpiration_, // how many rounds are passed before claiming is possible
        uint256 supplyDecayPercent_, // defines percentage of next rounds' supply from the current
        address[] calldata sharedOwners_,
        uint256[] calldata sharedOwnersPercs_           // index of percentages must correspond to _sharedOwners array
    ) public initializer {
        require(initialSupply_ <= MAX_ROUND_SUPPLY, "Distributions: initial supply should be <= MAX_ROUND_SUPPLY");
        require(initialKarma_ > 0, "Distributions: initial karma should be more than 0");
        require(nextSupply_ > 0 && nextSupply_ <= MAX_ROUND_SUPPLY, "Distributions: nextSupply should be > 0 and <= MAX_ROUND_SUPPLY");
        require(karmaSource_ != address(0), "Distributions: karma source should not be 0");
        require(owner_ != address(0), "Distributions: owner should not be 0");
        require(sharedOwners_.length == sharedOwnersPercs_.length, "Distributions: shared owners addresses array must be same length as percentages");
        require(subredditPoints_ != address(0), "Distributions: subredditPoints should not be 0");

        OwnableUpgradeable.__Ownable_init();
        if (owner_ != _msgSender()) {
            OwnableUpgradeable.transferOwnership(owner_);
        }
        _updateSupplyDecayPercent(supplyDecayPercent_);
        _updateRoundsBeforeExpiration(roundsBeforeExpiration_);

        subredditPoints = ISubredditPoints(subredditPoints_);
        subreddit = subredditPoints.subreddit();
        karmaSource = karmaSource_;
        prevKarmaSource = karmaSource_;
        _subredditLowerCase = _toLower(subreddit);

        initialSupply = initialSupply_;
        nextSupply = nextSupply_;

        for (uint i = 0; i < sharedOwners_.length; i++) {
            _updateSharedOwner(sharedOwners_[i], sharedOwnersPercs_[i]);
        }

        if (initialSupply > 0) {
            uint256 sharedOwnersPoints = calcSharedOwnersAvailablePoints(initialSupply);
            _distributionRounds[0] = DistributionRound({
            availablePoints : initialSupply,
            sharedOwnersAvailablePoints : sharedOwnersPoints,
            totalKarma : initialKarma_
            });

            emit AdvanceRound(0, initialSupply, sharedOwnersPoints);
        }
    }

    function claim(uint256 round, address account, uint256 karma, bytes calldata signature) virtual external {
        address signedBy = verifySignature(account, round, karma, signature);
        require(signedBy == karmaSource || (prevKarmaSource != address(0) && signedBy == prevKarmaSource), "Distributions: claim is not signed by the karma source");

        _mintRound(round, account, karma);
    }

    /* airdrop input format:

        [ ROUND | BATCH 0 … BATCH X ]
        Round is a compressed number, and the batch is:

        [ BATCH_HEADER | BATCH BODY ]
        Where BATCH_HEADER = N * 4 + BATCH_TYPE encoded as a compressed number, which is an equivalent of bit mask:
            +------------+------------+
            |    X-2     |    1-0     |
            +------------+------------+
            | BATCH_SIZE | BATCH_TYPE |
            +------------+------------+

        N is the amount of airdrop records packed within a body and
        BATCH_TYPE is a number 0-3 and defines a batch body:
            AirdropBatchType.ACCOUNTS (0) = [ ACCOUNT_ID 0 | KARMA 0 ... ACCOUNT_ID N-1 | KARMA N-1 ]
            AirdropBatchType.ADDRESSES (1) = [ ADDRESS 0 | KARMA 0 ... ADDRESS N-1 | KARMA N-1 ]
            AirdropBatchType.GROUPED_ACCOUNTS (2) = [ KARMA | ACCOUNT_ID 0 ... ACCOUNT_ID N-1 ]
            AirdropBatchType.GROUPED_ADDRESSES (3) = [ KARMA | ADDRESS 0 ... ADDRESS N-1 ]

        ACCOUNT_ID, KARMA are compressed numbers and ADDRESS is full 20 bytes address.
        Types 2 and 3 are accounts grouped by KARMA, and within a group they all have the same
        amount of karma within a round.
    */

    function airdrop(bytes calldata input) virtual external {
        require(_msgSender() == karmaSource || (prevKarmaSource != address(0) && _msgSender() == prevKarmaSource), "Distributions: airdrop can be only called by karma source");

        uint256 ptr = 0;
        uint256 round;
        (round, ptr) = input.decompressUint256(ptr);

        require(ptr < input.length, "Distributions: airdrop is empty");

        while (ptr < input.length) {
            uint256 batchHeader;
            (batchHeader, ptr) = input.decompressUint256(ptr);
            AirdropBatchType batchType = AirdropBatchType(uint8(batchHeader) & 0x3);
            uint256 batchSize = batchHeader >> 2;
            require(batchSize > 0, "Distributions: airdrop batch is empty");

            if (batchType == AirdropBatchType.ACCOUNTS) {
                ptr = airdropToAccounts(round, ptr, batchSize, input);
            } else if (batchType == AirdropBatchType.ADDRESSES) {
                ptr = airdropToAddresses(round, ptr, batchSize, input);
            } else if (batchType == AirdropBatchType.GROUPED_ACCOUNTS) {
                ptr = airdropToGroupedAccounts(round, ptr, batchSize, input);
            } else if (batchType == AirdropBatchType.GROUPED_ADDRESSES) {
                ptr = airdropToGroupedAddresses(round, ptr, batchSize, input);
            } else {
                revert("Distributions: unknown airdrop batch type");
                // shouldn't happen
            }
        }
    }

    // format is [ ACCOUNT_ID 0 | KARMA 0 ... ACCOUNT_ID N-1 | KARMA N-1 ]
    function airdropToAccounts(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256) {
        for (uint256 i = 0; i < batchSize; i++) {
            uint256 accountId;
            (accountId, ptr) = input.decompressUint256(ptr);
            address account = addressOf(accountId);
            require(account != address(0), "Distributions: account id not found");

            uint256 karma;
            (karma, ptr) = input.decompressUint256(ptr);

            _mintRound(round, account, karma);
        }
        return ptr;
    }

    // format is [ ADDRESS 0 | KARMA 0 ... ADDRESS N-1 | KARMA N-1 ]
    function airdropToAddresses(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256)  {
        for (uint256 i = 0; i < batchSize; i++) {
            address account = input.toAddress(ptr);
            require(account != address(0), "Distributions: account id not found");
            ptr += 20;
            // size of address

            uint256 karma;
            (karma, ptr) = input.decompressUint256(ptr);

            _mintRound(round, account, karma);
        }
        return ptr;
    }

    // format is [ KARMA | ACCOUNT_ID 0 ... ACCOUNT_ID N-1 ]
    function airdropToGroupedAccounts(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256)  {
        uint256 karma;
        (karma, ptr) = input.decompressUint256(ptr);

        for (uint256 i = 0; i < batchSize; i++) {
            uint256 accountId;
            (accountId, ptr) = input.decompressUint256(ptr);
            address account = addressOf(accountId);
            require(account != address(0), "Distributions: account id not found");
            _mintRound(round, account, karma);
        }
        return ptr;
    }

    // format is [ KARMA | ADDRESS 0 ... ADDRESS N-1 ]
    function airdropToGroupedAddresses(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256)  {
        uint256 karma;
        (karma, ptr) = input.decompressUint256(ptr);

        for (uint256 i = 0; i < batchSize; i++) {
            address account = input.toAddress(ptr);
            require(account != address(0), "Distributions: account id not found");
            ptr += 20;
            // size of address
            _mintRound(round, account, karma);
        }
        return ptr;
    }

    function _mintRound(uint256 round, address account, uint256 karma) internal {
        require(account != address(0), "Distributions: address should not be 0");
        require(karma > 0, "Distributions: karma should be > 0");
        require(_claimableRounds[account] <= round, "Distributions: this rounds points are already claimed");
        require(round <= lastRound, "Distributions: too early to claim this round");
        uint256 earliest = claimableRoundOf(account);
        require(round >= earliest, "Distributions: too late to claim this round");
        require(earliest == 0 || round == earliest || _msgSender() == account || _msgSender() == karmaSource,
            "Distributions: only owner can claim round that's not earliest");

        DistributionRound memory dr = _distributionRounds[round];
        require(dr.availablePoints > 0, "Distributions: no points to claim in this round");
        require(dr.totalKarma > 0, "Distributions: this round has no karma");
        uint256 userPoints = dr.availablePoints
        .sub(dr.sharedOwnersAvailablePoints)
        .mul(karma)
        .div(dr.totalKarma);
        require(userPoints > 0, "Distributions: user karma is too low to claim points");
        _prevClaimed = _prevClaimed.add(userPoints);
        _claimableRounds[account] = round.add(1);
        _registerAccount(account);
        emit ClaimPoints(round, account, karma, userPoints);
        subredditPoints.mint(address(this), account, userPoints, "", "");
    }

    // corresponding _distributionRounds mappings are added with
    //  + every next distribution supply is `previous - decay` and stored in nextSupply
    //  + distributed 50% of burned points in a previous round
    // rounds are removed if they are not claimable anymore
    function advanceToRound(uint256 round, uint256 totalKarma) virtual external {
        require(round == lastRound.add(1), "Distributions: round should be incrementally increasing");
        require(totalKarma > 0, "Distributions: totalKarma should be > 0");
        require(_msgSender() == karmaSource, "Distributions: only karma source can advance rounds");
        uint256 mc = minClaimableRound();

        if (mc > 0) {
            // delete non claimable round data
            delete (_distributionRounds[mc-1]);
        }

        uint256 ts = IERC20Upgradeable(address(subredditPoints)).totalSupply();
        uint256 prevClaimedCopy = _prevClaimed;

        // get round points
        uint256 roundPoints = nextSupply;
        // reintroduce 50 % of previously burned tokens
        uint256 ps = _prevRoundSupply.add(_prevClaimed).add(_prevOwnersShare);
        if (ps > ts) {
            roundPoints = roundPoints.add(ps.sub(ts).div(2));
        }

        // decay next supply
        if (nextSupply > 0 && supplyDecayPercent > 0) {
            nextSupply = nextSupply.sub(nextSupply.mul(supplyDecayPercent).div(PERCENT_PRECISION));
        }

        // set distribution round data for this round
        uint256 sharedOwnersPoints = 0;
        if (roundPoints > 0) {
            sharedOwnersPoints = calcSharedOwnersAvailablePoints(roundPoints);
            _distributionRounds[round] = DistributionRound({
            availablePoints : roundPoints,
            sharedOwnersAvailablePoints : sharedOwnersPoints,
            totalKarma : totalKarma
            });
        }

        emit AdvanceRound(round, roundPoints, sharedOwnersPoints);

        lastRound = round;
        _prevRoundSupply = ts;
        _prevClaimed = 0;
        _prevOwnersShare = 0;

        // distribute shared cut, but no more than it was claimed by users
        // this protects from exceeding total amount by increasing percentage between rounds
        if (sharedOwnersPoints > 0 && prevClaimedCopy > 0) {
            uint256 totalSharedPercent;
            for (uint256 i = 0; i < sharedOwners.length; i++) {
                totalSharedPercent = totalSharedPercent.add(sharedOwners[i].percent);
            }

            uint256 claimedPlusShared = prevClaimedCopy
            .mul(PERCENT_PRECISION)
            .div(PERCENT_PRECISION.sub(totalSharedPercent));

            uint256 sharedLeft = claimedPlusShared.sub(prevClaimedCopy);

            for (uint256 i = 0; i < sharedOwners.length && sharedLeft > 0; i++) {
                uint256 ownerPoints = claimedPlusShared.mul(sharedOwners[i].percent).div(PERCENT_PRECISION);
                if (ownerPoints > 0 && ownerPoints <= sharedLeft) {
                    // keep track of owners points minted for this round
                    _prevOwnersShare = _prevOwnersShare.add(ownerPoints);
                    subredditPoints.mint(address(this), sharedOwners[i].account, ownerPoints, "", "");
                    sharedLeft = sharedLeft.sub(ownerPoints);
                }
            }
        }
    }

    function totalSharedOwners() external view returns (uint256) {
        return sharedOwners.length;
    }

    function updateSupplyDecayPercent(uint256 _supplyDecayPercent) external onlyOwner {
        _updateSupplyDecayPercent(_supplyDecayPercent);
    }

    function _updateSupplyDecayPercent(uint256 _supplyDecayPercent) internal {
        require(_supplyDecayPercent < PERCENT_PRECISION, "Distributions: supplyDecayPercent should be < PERCENT_PRECISION");
        supplyDecayPercent = _supplyDecayPercent;
        emit SupplyDecayPercentUpdated(_supplyDecayPercent);
    }

    function updateRoundsBeforeExpiration(uint256 _roundsBeforeExpiration) external onlyOwner {
        _updateRoundsBeforeExpiration(_roundsBeforeExpiration);
    }

    function _updateRoundsBeforeExpiration(uint256 _roundsBeforeExpiration) internal {
        roundsBeforeExpiration = _roundsBeforeExpiration;
        emit RoundsBeforeExpirationUpdated(_roundsBeforeExpiration);
    }

    function minClaimableRound() public view returns (uint256) {
        if (lastRound >= roundsBeforeExpiration) {
            return lastRound.sub(roundsBeforeExpiration);
        }
        return 0;
    }

    function verifySignature(address account, uint256 round, uint256 karma, bytes memory signature)
    internal view returns (address) {

        bytes32 hash = keccak256(abi.encode(_subredditLowerCase, uint256(round), account, karma));
        bytes32 prefixedHash = ECDSAUpgradeable.toEthSignedMessageHash(hash);
        return ECDSAUpgradeable.recover(prefixedHash, signature);
    }

    function calcSharedOwnersAvailablePoints(uint256 points) internal view returns (uint256) {
        uint256 r;
        for (uint256 i = 0; i < sharedOwners.length; i++) {
            r = r.add(calcSharedPoints(points, sharedOwners[i]));
        }
        return r;
    }

    function calcSharedPoints(uint256 points, SharedOwner memory sharedOwner) internal pure returns (uint256) {
        return points
        .mul(sharedOwner.percent)
        .div(PERCENT_PRECISION);
    }

    function updateKarmaSource(address _karmaSource) external onlyOwner {
        require(_karmaSource != address(0), "Distributions: karma source should not be 0");
        prevKarmaSource = karmaSource;
        karmaSource = _karmaSource;
        emit KarmaSourceUpdated(_karmaSource, prevKarmaSource);
    }

    // shared owners get their points 1 round later within advancement
    // increasing total shared percentage can lead to some of the owners not receiving their cut within a next round
    function updateSharedOwner(address account, uint256 percent) external onlyOwner {
        _updateSharedOwner(account, percent);
    }

    function _updateSharedOwner(address account, uint256 percent) internal {
        require(percent < PERCENT_PRECISION, "Distributions: shared owners percent should be < percentPrecision");
        require(percent > 0 && sharedOwners.length < MAX_SHARED_OWNERS, "Distributions: shared owners limit reached, see MAX_SHARED_OWNERS");

        bool updated = false;

        for (uint256 i = 0; i < sharedOwners.length; i++) {
            SharedOwner memory so = sharedOwners[i];
            if (so.account == account) {
                if (percent == 0) {
                    if (i != (sharedOwners.length - 1)) {// if it's not last element, replace it from the tail
                        sharedOwners[i] = sharedOwners[sharedOwners.length - 1];
                    }
                    // remove tail
                    sharedOwners.pop();
                } else {
                    sharedOwners[i].percent = percent;
                }
                updated = true;
            }
        }

        if (!updated) {
            if (percent == 0) {
                return;
            }
            sharedOwners.push(SharedOwner(account, percent));
        }

        checkSharedPercentage();
        // allow to update sharedOwnersAvailablePoints for a rounds which aren't claimed yet
        DistributionRound storage dr = _distributionRounds[lastRound];
        if (_prevClaimed == 0 && dr.availablePoints > 0) {
            dr.sharedOwnersAvailablePoints = calcSharedOwnersAvailablePoints(dr.availablePoints);
        }
        emit SharedOwnerUpdated(_msgSender(), account, percent);
    }

    function checkSharedPercentage() internal view {
        uint256 total;
        for (uint256 i = 0; i < sharedOwners.length; i++) {
            total = sharedOwners[i].percent.add(total);
        }
        require(total < PERCENT_PRECISION, "Distributions: can't share all 100% of points");
    }

    function percentPrecision() external pure returns (uint256) {
        return PERCENT_PRECISION;
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((int8(bStr[i]) >= 65) && (int8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(int8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function claimableRoundOf(address account) public view returns (uint256) {
        uint256 mc = minClaimableRound();
        if (mc > _claimableRounds[account]) {
            return mc;
        }
        return _claimableRounds[account];
    }

    function addressOf(uint256 accountId) public view returns (address) {
        return _accountAddresses[accountId];
    }

    function accountIdOf(address account) public view returns (uint256) {
        return _accountIds[account];
    }

    function _registerAccount(address account) internal {
        if (_accountIds[account] == 0) {
            _lastAccountId+=1;
            _accountIds[account] = _lastAccountId;
            _accountAddresses[_lastAccountId] = account;
            emit AccountRegistered(account, _lastAccountId);
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface ISubredditPoints {
    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    event DefaultOperatorAdded(address indexed operator);

    event DefaultOperatorRemoved(address indexed operator);

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external; // solium-disable-line indentation

    function burn(
        uint256 amount,
        bytes calldata data
    ) external; // solium-disable-line indentation

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external; // solium-disable-line indentation

    function subreddit() external view returns (string memory);
}

//

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.7.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_start + 2 >= _start, "toUint16_overflow");
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_start + 12 >= _start, "toUint96_overflow");
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_start + 16 >= _start, "toUint128_overflow");
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_start + 32 >= _start, "toUint256_overflow");
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_start + 32 >= _start, "toBytes32_overflow");
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Compress {
    using BytesLib for bytes;

    /*
        Compressed unsigned integer numbers have format:
            [ TYPE | VALUE ]

            Where TYPE is the sequence of highest bits of the first byte.

           1. TYPE = 0 (highest bit), 1 byte
               Lower 7 bits of the byte represents an integer

               examples:
               0 = 0 (min)
               127 = 127 (0x7F, max for 1 byte)

           2. TYPE = 10 (highest bits), 2 bytes
                Lower 6 bits of the byte and the following byte = an integer, total 14 bits.
                To the resulting number offset is added: 0x80 (1 + maximum of TYPE=0)

                examples:
                0x8000 = 128 (0x80, min for type)
                0xBFFF = 16511 (0x407F, max for type)

           3. TYPE = 11 (highest bits), dynamic length

                Next 5 bits of the byte = (length in bytes - 1) of the number following the type.
                If all 5 bits of length = 0, then 1 byte.
                If all bits = 1 (decimal 31) then 32 bytes are following (uint256)

                Lowest 1 bit is also used as the lowest bit of an encoded number.

                0 byte format:
                [ B B L L L L L S ]

                BB - is a constant value of the compression type 11
                LLLLL - is the length in bytes following, 0 means 32 bytes
                S - is used as part of number (highest bit)
                When a full 32 bytes number is encoded, extra bit S is ignored and lost.

        Returned result is encoded number and pointer to next byte
    */
    function decompressUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256, uint256) {
        if (_bytes.length == 0) {
            revert("decompressUint256: out of bounds");
        }
        uint8 first = _bytes.toUint8(_start);

        // TYPE 0
        if (first & 0x80 == 0) {
            uint256 end = _start + 1;
            return (first & 0x7F, 1 + _start);
            validateStartEnd(_bytes, _start, end);
        }

        // TYPE 10
        if (first & 0xC0 == 0x80) {
            uint256 end = _start + 2;
            validateStartEnd(_bytes, _start, end);
            uint256 second = uint256(_bytes.toUint8(_start + 1));
            return (uint256(first & 0x3F) * 0x100 + second + 0x80, end);
        }

        // TYPE 11 (dynamic length)

        // 1-7 bits of first byte = length-1
        uint256 len = ((first & 0x3e) >> 1) + 1;

        uint256 end = _start + len + 1;
        validateStartEnd(_bytes, _start, end);

        uint256 result;
        assembly {
            result := mload(add(add(_bytes, add(len, _start)), 1))
        }

        uint256 mask = (1 << (len * 8 + 1)) - 1;
        return (result & mask, end);
    }

    function validateStartEnd(bytes memory _bytes, uint256 _start, uint256 end) internal pure {
        require(end >= _start, "decompressUint256: overflow");
        require(_bytes.length >= end, "decompressUint256: out of bounds");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./Distributions.sol";

/*
    Distribution that used while importing
*/

contract DistributionsImport is Distributions {
    modifier disabledWhileImporting() {
        revert("DistributionsImport: import is in progress");
        _;
    }

    function importInternals(
        uint256 initialSupply_,
        uint256 nextSupply_,
        uint256 lastRound_,
        uint256 prevRoundSupply_,
        uint256 prevClaimed_,
        uint256 roundsBeforeExpiration_,
        uint256 supplyDecayPercent_,
        uint256[] calldata rdAvailablePoints_,
        uint256[] calldata rdSharedOwnersAvailablePoints_,
        uint256[] calldata rdTotalKarma_
    ) external onlyOwner {
        require(initialSupply_ > 0, "DistributionsImport: initialSupply_ should be > 0");

        require(rdAvailablePoints_.length > 0 &&
            rdAvailablePoints_.length == rdSharedOwnersAvailablePoints_.length &&
            rdAvailablePoints_.length == rdTotalKarma_.length,
            "DistributionsImport: rounds data arrays should have equal length and > 0");

        initialSupply = initialSupply_;
        nextSupply = nextSupply_;
        lastRound = lastRound_;
        roundsBeforeExpiration = roundsBeforeExpiration_;
        supplyDecayPercent = supplyDecayPercent_;

        require(lastRound.sub(minClaimableRound()).add(1) == rdAvailablePoints_.length,
            "DistributionsImport: rounds data arrays doesn't have all available rounds data");

        _prevRoundSupply = prevRoundSupply_;
        _prevClaimed = prevClaimed_;

        uint256 round = minClaimableRound();
        for (uint256 i = 0; i < rdAvailablePoints_.length; i++) {
            _distributionRounds[round] = DistributionRound({
                    availablePoints: rdAvailablePoints_[i],
                    sharedOwnersAvailablePoints: rdSharedOwnersAvailablePoints_[i],
                    totalKarma: rdTotalKarma_[i]
                });
            round += 1;
        }
    }

    function importSharedOwners(
        address[] calldata sharedOwners_,
        uint256[] calldata sharedOwnersPercs_
    ) external onlyOwner {
        require(sharedOwners_.length == sharedOwnersPercs_.length, "DistributionsImport: shared owners addresses array must be same length as percentages");

        for (uint i = 0; i < sharedOwners_.length; i++) {
            if (sharedOwners.length <= i) {
                sharedOwners.push(SharedOwner(sharedOwners_[i], sharedOwnersPercs_[i]));
            } else {
                sharedOwners[i] = SharedOwner(sharedOwners_[i], sharedOwnersPercs_[i]);
            }
            emit SharedOwnerUpdated(_msgSender(), sharedOwners_[i], sharedOwnersPercs_[i]);
        }
    }

    function importClaimableRounds(address[] calldata accounts, uint256[] calldata rounds) onlyOwner external {
        require(initialSupply > 0, "DistributionsImport: import internals first");
        require(accounts.length > 0 && accounts.length == rounds.length,
            "DistributionsImport: accounts should have > 0 elements and be equal to rounds");

        uint256 mc = minClaimableRound();

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            require(account != address(0), "DistributionsImport: account should not be address(0)");

            uint256 cr = rounds[i];
            if (cr > mc) {
                _claimableRounds[account] = rounds[i];
            }
            _registerAccount(account);
        }
    }

    function claim(uint256 round, address account, uint256 karma, bytes calldata signature)
        override disabledWhileImporting external { }

    function airdrop(bytes calldata input)
        override disabledWhileImporting external { }

    function advanceToRound(uint256 round, uint256 totalKarma)
        override external disabledWhileImporting { }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./Distributions.sol";
import "./Frozen.sol";

/*
    Distribution that is frozen (while exporting/migrating)
*/

contract DistributionsFrozen is Distributions, Frozen {
    function claim(uint256 round, address account, uint256 karma, bytes calldata signature)
        override frozen external { }

    function airdrop(bytes calldata input)
        override frozen external { }

    function advanceToRound(uint256 round, uint256 totalKarma)
        override external frozen { }

    // export private data

    function prevRoundSupply() external view returns (uint256) {
        return _prevRoundSupply;
    }

    function prevClaimed() external view returns (uint256) {
        return _prevClaimed;
    }

    function roundAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].availablePoints;
    }

    function roundSharedOwnersAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].sharedOwnersAvailablePoints;
    }

    function roundTotalKarma(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].totalKarma;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface Frozen {
    modifier frozen() {
        revert("Contract is frozen");
        _;
    }
}