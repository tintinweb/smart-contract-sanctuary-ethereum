/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @rari-capital/solmate/src/auth/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}


// File srcBuild/Voter.sol


pragma solidity ^0.8.11;

library Math {
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

interface IListingFee {
    function listing_fee() external view returns (uint);
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface ve {
    function token() external view returns (address);
    function balanceOfNFT(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
}

interface GaugeFactory {
    function createGauge(address, address, address) external returns (address);
}

interface BribeFactory {
    function createBribe() external returns (address);
}

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function stopDeposits() external;
    function openDeposits() external;
    function isDepositsOpen() external view returns (bool);
    function getReward(address account, address[] memory tokens) external;
    function left(address token) external view returns (uint);
}

interface IBribe {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
}

interface IMinter {
    function update_period() external returns (uint);
}

contract Voter is Auth {

    address public immutable _ve; // the ve token that governs these contracts
    address internal immutable base;
    address internal listingLP;
    address internal listingFeeAddr;
    address public immutable gaugefactory;
    address public immutable bribefactory;
    uint internal constant DURATION = 7 days; // rewards are released over 7 days
    address public minter;
    bool public openListing;
    uint public totalWeight; // total voting weight

    address[] public assets; // all assets viable for incentives
    mapping(address => address) public gauges; // asset => gauge
    mapping(address => address) public assetForGauge; // gauge => asset
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => int256) public weights; // pool => weight
    mapping(uint => mapping(address => int256)) public votes; // nft => asset => votes
    mapping(uint => address[]) public assetVote; // nft => assets
    mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;

    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
    event Voted(address indexed voter, uint tokenId, int256 weight);
    event Abstained(uint tokenId, int256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);
    event DeListed(address indexed delister, address indexed token);

    constructor(
        address _guardian,
        address _authority,
        address __ve,
        address _gauges,
        address _bribes
    ) Auth(_guardian, Authority(_authority)) {
        _ve = __ve;
        base = ve(__ve).token();
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        openListing = false;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function initialize(address[] memory _tokens, address _minter) external {
        require(msg.sender == minter);
        for (uint i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
        minter = _minter;
    }

    function migrateMinter(address newMinter_) external {
        require(msg.sender == minter);
        minter = newMinter_;
    }

    function setListingFeeAddress(address listingFeeAddress_) external requiresAuth {
        listingFeeAddr = listingFeeAddress_;
    }

    function listing_fee() public view returns (uint) {
        return IListingFee(listingFeeAddr).listing_fee();
    }

    function reset(uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        _reset(_tokenId);
        ve(_ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _assetVote = assetVote[_tokenId];
        uint _assetVoteCnt = _assetVote.length;
        int256 _totalWeight = 0;

        for (uint i = 0; i < _assetVoteCnt; i ++) {
            address _asset = _assetVote[i];
            int256 _votes = votes[_tokenId][_asset];

            if (_votes != 0) {
                _updateFor(gauges[_asset]);
                weights[_asset] -= _votes;
                votes[_tokenId][_asset] -= _votes;
                if (_votes > 0) {
                    IBribe(bribes[gauges[_asset]])._withdraw(uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete assetVote[_tokenId];
    }

    function poke(uint _tokenId) external {
        address[] memory _assetVote = assetVote[_tokenId];
        uint _assetCnt = _assetVote.length;
        int256[] memory _weights = new int256[](_assetCnt);

        for (uint i = 0; i < _assetCnt; i ++) {
            _weights[i] = votes[_tokenId][_assetVote[i]];
        }

        _vote(_tokenId, _assetVote, _weights);
    }

    function _vote(uint _tokenId, address[] memory _assetVote, int256[] memory _weights) internal {
        _reset(_tokenId);
        uint _assetCnt = _assetVote.length;
        int256 _weight = int256(ve(_ve).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint i = 0; i < _assetCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }

        for (uint i = 0; i < _assetCnt; i++) {
            address _asset = _assetVote[i];
            address _gauge = gauges[_asset];

            if (isGauge[_gauge] && IGauge(_gauge).isDepositsOpen()) {
                int256 _assetWeight = _weights[i] * _weight / _totalVoteWeight;
                require(votes[_tokenId][_asset] == 0);
                require(_assetWeight != 0);
                _updateFor(_gauge);

                assetVote[_tokenId].push(_asset);

                weights[_asset] += _assetWeight;
                votes[_tokenId][_asset] += _assetWeight;
                if (_assetWeight > 0) {
                    IBribe(bribes[_gauge])._deposit(uint256(_assetWeight), _tokenId);
                } else {
                    _assetWeight = -_assetWeight;
                }
                _usedWeight += _assetWeight;
                _totalWeight += _assetWeight;
                emit Voted(msg.sender, _tokenId, _assetWeight);
            }
        }
        if (_usedWeight > 0) ve(_ve).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);
    }

    function vote(uint tokenId, address[] calldata _assetVote, int256[] calldata _weights) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId));
        require(_assetVote.length == _weights.length);
        _vote(tokenId, _assetVote, _weights);
    }

    function gaugeStopDeposits(address _gauge) external requiresAuth {
        IGauge(_gauge).stopDeposits();
    }

    function gaugeOpenDeposits(address _gauge) external requiresAuth {
        IGauge(_gauge).openDeposits();
    }

    function whitelist(address _token) external {
        require(openListing, "not open for general listing");

        _safeTransferFrom(listingLP, msg.sender, owner, listing_fee());

        _whitelist(_token);
    }

    function enableOpenListing() external requiresAuth {
        openListing = true;
    }

    function disableOpenListing() external requiresAuth {
        openListing = false;
    }

    function removeListing(address _token) external requiresAuth {
        _removeListing(_token);
    }

    function whitelistAsAuth(address _token) external requiresAuth {
        _whitelist(_token);
    }

    function _removeListing(address _token) internal {
        require(isWhitelisted[_token]);
        isWhitelisted[_token] = false;
        emit DeListed(msg.sender, _token);
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token]);
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function createGauge(address _asset) external returns (address) {
        require(gauges[_asset] == address(0x0), "exists");
        require(isWhitelisted[_asset], "!whitelisted");
        address _bribe = BribeFactory(bribefactory).createBribe();
        address _gauge = GaugeFactory(gaugefactory).createGauge(_asset, _bribe, _ve);
        erc20(base).approve(_gauge, type(uint).max);
        bribes[_gauge] = _bribe;
        gauges[_asset] = _gauge;
        assetForGauge[_gauge] = _asset;
        isGauge[_gauge] = true;
        IGauge(_gauge).openDeposits();
        _updateFor(_gauge);
        assets.push(_asset);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _asset);
        return _gauge;
    }

    function attachTokenToGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) ve(_ve).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) ve(_ve).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint) {
        return assets.length;
    }

    uint internal index;
    mapping(address => uint) internal supplyIndex;
    mapping(address => uint) public claimable;

    function notifyRewardAmount(uint amount) external {
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
        uint256 _ratio = amount * 1e18 / totalWeight; // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, base, amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateForRange(uint start, uint end) public {
        for (uint i = start; i < end; i++) {
            _updateFor(gauges[assets[i]]);
        }
    }

    function updateAll() external {
        updateForRange(0, assets.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        address _asset = assetForGauge[_gauge];
        int256 _supplied = weights[_asset];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            uint _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
                claimable[_gauge] += _share;
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function distribute(address _gauge) public lock {
        IMinter(minter).update_period();
        _updateFor(_gauge);
        uint _claimable = claimable[_gauge];
        if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distro() external {
        distribute(0, assets.length);
    }

    function distribute() external {
        distribute(0, assets.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(gauges[assets[x]]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}