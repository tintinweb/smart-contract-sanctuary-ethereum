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
    function isDelegated(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
}

interface IBaseV1GaugeFactory {
    function createGauge(address, address) external returns (address);
}

interface IBaseV1EMGaugeFactory {
    function createEMGauge(address, address, address, uint256, uint256) external returns (address);
}


interface IBaseV1BribeFactory {
    function createBribe() external returns (address);
}

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function left(address token) external view returns (uint);
}

interface IBribe {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
}

// Difference from solidly - removed pools, and all that connected with it
// No whitelist(removed, but may be appeared later)
contract BaseV1Voter {

    address public immutable _ve; // the ve token that governs these contracts
    address internal immutable base;
    address public immutable gaugefactory;
    address public immutable emgaugefactory; // EarnMore GaugeFactory
    address public immutable bribefactory;
    uint internal constant DURATION = 7 days; // rewards are released over 7 days

    uint public totalWeight; // total voting weight
    address public treasury;

    address[] public gaugesList; // all gauges
    mapping(address => address) public gauges; // token => gauge
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => int256) public weights; // gauge => weight
    mapping(uint => mapping(address => int256)) public votes; // nft => gauge => votes
    mapping(uint => address[]) public gaugeVote; // nft => gauges
    mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    mapping(address => bool) public isGauge;

    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed token);
    event Voted(address indexed voter, uint tokenId, int256 weight);
    event Abstained(uint tokenId, int256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);

    constructor(address __ve, address  _gauges, address _emgauges, address _bribes, address _treasury) {
        _ve = __ve;
        base = ve(__ve).token();
        gaugefactory = _gauges;
        emgaugefactory = _emgauges;
        bribefactory = _bribes;
        treasury = _treasury;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function reset(uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId) || ve(_ve).isDelegated(msg.sender, _tokenId));
        _reset(_tokenId);
        ve(_ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _gaugeVote = gaugeVote[_tokenId];
        uint _gaugeVoteCnt = _gaugeVote.length;
        int256 _totalWeight = 0;

        for (uint i = 0; i < _gaugeVoteCnt; i ++) {
            address _gauge = _gaugeVote[i];
            int256 _votes = votes[_tokenId][_gauge];

            if (_votes != 0) {
                _updateFor(_gauge);
                weights[_gauge] -= _votes;
                votes[_tokenId][_gauge] -= _votes;
                if (_votes > 0) {
                    IBribe(bribes[_gauge])._withdraw(uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete gaugeVote[_tokenId];
    }

    function poke(uint _tokenId) external {
        address[] memory _gaugeVote = gaugeVote[_tokenId];
        uint _gaugeCnt = _gaugeVote.length;
        int256[] memory _weights = new int256[](_gaugeCnt);

        for (uint i = 0; i < _gaugeCnt; i ++) {
            _weights[i] = votes[_tokenId][_gaugeVote[i]];
        }

        _vote(_tokenId, _gaugeVote, _weights);
    }

    function _vote(uint _tokenId, address[] memory _gaugeVote, int256[] memory _weights) internal {
        _reset(_tokenId);
        uint _gaugeCnt = _gaugeVote.length;
        int256 _weight = int256(ve(_ve).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint i = 0; i < _gaugeCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }

        for (uint i = 0; i < _gaugeCnt; i++) {
            address _gauge = _gaugeVote[i];

            if (isGauge[_gauge]) {
                int256 _gaugeWeight = _weights[i] * _weight / _totalVoteWeight;
                require(votes[_tokenId][_gauge] == 0);
                require(_gaugeWeight != 0);
                _updateFor(_gauge);

                gaugeVote[_tokenId].push(_gauge);

                weights[_gauge] += _gaugeWeight;
                votes[_tokenId][_gauge] += _gaugeWeight;
                if (_gaugeWeight > 0) {
                    IBribe(bribes[_gauge])._deposit(uint256(_gaugeWeight), _tokenId);
                } else {
                    _gaugeWeight = -_gaugeWeight;
                }
                _usedWeight += _gaugeWeight;
                _totalWeight += _gaugeWeight;
                emit Voted(msg.sender, _tokenId, _gaugeWeight);
            }
        }
        if (_usedWeight > 0) ve(_ve).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);
    }

    function vote(uint tokenId, address[] calldata _gaugeVote, int256[] calldata _weights) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId) || ve(_ve).isDelegated(msg.sender, tokenId));
        require(_gaugeVote.length == _weights.length);
        _vote(tokenId, _gaugeVote, _weights);
    }

    function createGauge(address _token) external returns(address) {
        address _gauge = IBaseV1GaugeFactory(gaugefactory).createGauge(_token, _ve);
        _registerGauge(_token, _gauge);
        return _gauge;
    }

    function createEMGauge(address _token, uint256 _excludePercent, uint256 _earnMorePercent) external returns(address) {
        address _gauge = IBaseV1EMGaugeFactory(emgaugefactory).createEMGauge(_token, _ve, treasury, _excludePercent, _earnMorePercent);
        _registerGauge(_token, _gauge);
        return _gauge; 
    }

    function _registerGauge(address _token, address _gauge) internal {
        require(gauges[_token] == address(0x0), "exists");
        address _bribe = IBaseV1BribeFactory(bribefactory).createBribe();
        erc20(base).approve(_gauge, type(uint).max);
        bribes[_gauge] = _bribe;
        gauges[_token] = _gauge;
        isGauge[_gauge] = true;
        _updateFor(_gauge);
        gaugesList.push(_gauge);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _token);
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
        return gaugesList.length;
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
            _updateFor(gaugesList[i]);
        }
    }

    function updateAll() external {
        updateForRange(0, gaugesList.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        int256 _supplied = weights[_gauge];
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

    // #TODO
    function claimAllRewards() external { 

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
        _updateFor(_gauge);
        uint _claimable = claimable[_gauge];
        if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distro() external {
        distribute(0, gaugesList.length);
    }

    function distribute() external {
        distribute(0, gaugesList.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(gaugesList[x]);
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