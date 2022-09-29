/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
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

interface IBaseV1Factory {
    function isPair(address) external view returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IBaseV1Core {
    function tokens() external returns (address, address);
}

interface IBaseV1GaugeFactory {
    function createGauge(address, address, address) external returns (address);
}

interface IBaseV1BribeFactory {
    function createBribe() external returns (address);
}

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function left(address token) external view returns (uint);
    function unload(address token, address minter) external;
}

interface IBribe {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
}

interface IMinter {
    function update_period() external returns (uint);
    function active_period() external view returns (uint);
}

contract BaseV1Voter {

    address public immutable _ve; // the ve token that governs these contracts
    address public immutable factory; // the BaseV1Factory
    address internal immutable base;
    address public immutable gaugefactory;
    address public immutable bribefactory;
    uint internal constant DURATION = 7 days; // rewards are released over 7 days
    address public minter;

    uint public totalWeight; // total voting weight
    uint public listingFee; // listing fee bp

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => int256) public weights; // pool => weight
    mapping(uint => mapping(address => int256)) public votes; // nft => pool => votes
    mapping(uint => address[]) public poolVote; // nft => pools
    mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    mapping(address => mapping(address => uint)) public tokenIdForGauge; // gauge => staker => attached NFT
    mapping(uint => address[]) public gaugeForTokenId; // tokenId => attached Gauge
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted; // token
    
    mapping(uint => uint) public lastVotePeriod; // nft => period
    mapping(address => bool) public isBlacklisted; // gauge

    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
    event Voted(address indexed voter, uint tokenId, int256 weight);
    event Abstained(uint tokenId, int256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed emergencyDAO, address indexed token);
    event ListingFeeSet(address indexed emergencyDAO, uint listingFee);
    event Blacklisted(address indexed emergencyDAO, address indexed gauge);
    event RemoveBlacklisted(address indexed emergencyDAO, address indexed gauge);

    constructor(address __ve, address _factory, address  _gauges, address _bribes) {
        _ve = __ve;
        factory = _factory;
        base = ve(__ve).token();
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        listingFee = 1000;
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

    function setListingFee(uint _listingFee) external {
        require(msg.sender == ve(_ve).ownerOf(1), "Emergency DAO privilege: setListingFee");
        require(_listingFee >= 100 && _listingFee <= 10000);
        listingFee = _listingFee;
        emit ListingFeeSet(msg.sender, _listingFee);
    }

    function listing_fee(address _token) public view returns (uint) {
        return erc20(_token).totalSupply() / listingFee;
    }

    function reset(uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == _ve);
        _reset(_tokenId);
        ve(_ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        int256 _totalWeight = 0;

        for (uint i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            int256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updateFor(gauges[_pool]);
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    IBribe(bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function poke(uint _tokenId) external {
        address[] memory _poolVote = poolVote[_tokenId];
        uint _poolCnt = _poolVote.length;
        int256[] memory _weights = new int256[](_poolCnt);

        for (uint i = 0; i < _poolCnt; i ++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }

        _vote(_tokenId, _poolVote, _weights);
    }

    function _vote(uint _tokenId, address[] memory _poolVote, int256[] memory _weights) internal {
        _reset(_tokenId);
        uint _poolCnt = _poolVote.length;
        int256 _weight = int256(ve(_ve).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }

        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                int256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0);
                require(_poolWeight != 0);
                _updateFor(_gauge);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                if (_poolWeight > 0) {
                    IBribe(bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
                } else {
                    _poolWeight = -_poolWeight;
                }
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                lastVotePeriod[_tokenId] = IMinter(minter).active_period();
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) ve(_ve).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);
    }

    function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId));
        require(_poolVote.length == _weights.length);
        require(votable(tokenId) == true, "Token already voted this epoch");
        _vote(tokenId, _poolVote, _weights);
    }

    function votable(uint _tokenId) public view returns (bool) {
        if(_tokenId == 1 || lastVotePeriod[_tokenId] < IMinter(minter).active_period()) {
            return true;
        } else {
            return false;
        }
    }

    function whitelist(address _token, address _pool, uint _tokenId) public {
        require(!isWhitelisted[_token]);

        if (_tokenId == 1) {
            require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
            _whitelist(_token);
        }
        else {
            uint paid = listing_fee(_token);
            //require(erc20(_token).balanceOf(msg.sender) >= paid);
            _safeTransferFrom(_token, msg.sender, address(this), paid);
            _whitelist(_token);
            address gauge = createGauge(_pool);
            address bribe = bribes[gauge];
            
            erc20(_token).approve(bribe, paid);
            IBribe(bribe).notifyRewardAmount(_token, paid);
        }
    }

    function _whitelist(address _token) internal {
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function blacklist(address _gauge) public {
        require(isGauge[_gauge], "Not a gauge");
        require(!isBlacklisted[_gauge], "Gauge already blacklisted");
        require(msg.sender == ve(_ve).ownerOf(1), "Emergency DAO privilege: blacklist");
        isBlacklisted[_gauge] = true;
        IGauge(_gauge).unload(base, minter);
        emit Blacklisted(msg.sender, _gauge);
    }

    function removeFromBlacklist(address _gauge) public {
        require(isGauge[_gauge], "Not a gauge");
        require(isBlacklisted[_gauge], "Gauge is not blacklisted");
        require(msg.sender == ve(_ve).ownerOf(1), "Emergency DAO privilege: removeFromBlacklist");
        isBlacklisted[_gauge] = false;
        emit RemoveBlacklisted(msg.sender, _gauge);
    } 

    function createGauge(address _pool) public returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        require(IBaseV1Factory(factory).isPair(_pool), "!_pool");
        (address tokenA, address tokenB) = IBaseV1Core(_pool).tokens();
        require(isWhitelisted[tokenA] && isWhitelisted[tokenB], "!whitelisted");
        address _bribe = IBaseV1BribeFactory(bribefactory).createBribe();
        address _gauge = IBaseV1GaugeFactory(gaugefactory).createGauge(_pool, _bribe, _ve);
        erc20(base).approve(_gauge, type(uint).max);
        bribes[_gauge] = _bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
        return _gauge;
    }

    function attachTokenToGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        tokenIdForGauge[msg.sender][account] = tokenId;
        gaugeForTokenId[tokenId].push(msg.sender);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender]);
        if (tokenId > 0) {
            tokenIdForGauge[msg.sender][account] = 0;
            address[] memory attachedGauges = gaugeForTokenId[tokenId];
            uint l = attachedGauges.length;
            for (uint i = 0; i < l; i++) {
                if(attachedGauges[i] == msg.sender) {
                    gaugeForTokenId[tokenId][i] = attachedGauges[l - 1]; // gas: use gaugeForTokenId instead of attachedGauges?
                    gaugeForTokenId[tokenId].pop();
                    break;
                }
            }
        }
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromAllGauges(uint tokenId, address account) external {
        require(msg.sender == _ve);
        address[] memory attachedGauges = gaugeForTokenId[tokenId];
        uint l = attachedGauges.length;
        if(l > 0) {
            for(uint i; i < l; i++) {
                address attachedGauge = attachedGauges[i];
                tokenIdForGauge[attachedGauge][account] = 0;
                emit Detach(account, attachedGauge, tokenId);
            }
            delete gaugeForTokenId[tokenId];
        }
    }

    function getAttachedToken(address gauge, address account) external view returns(uint tokenId) {
        return tokenIdForGauge[gauge][account];
    }
    
    function length() external view returns (uint) {
        return pools.length;
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
            _updateFor(gauges[pools[i]]);
        }
    }

    function updateAll() external {
        updateForRange(0, pools.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        int256 _supplied = weights[_pool];
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
        if (isBlacklisted[_gauge]) {
            claimable[_gauge] = 0;
            _safeTransfer(base, minter, _claimable);
        }
        else if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distro() external {
        distribute(0, pools.length);
    }

    function distribute() external {
        distribute(0, pools.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(gauges[pools[x]]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}