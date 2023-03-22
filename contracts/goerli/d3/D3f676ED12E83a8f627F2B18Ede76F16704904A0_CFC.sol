//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./interfaces/IOracle.sol";
import "./interfaces/ICharon.sol";
import "./helpers/MerkleTree.sol";
import "./interfaces/IERC20.sol";

/**
 @title CFC
 @dev charon fee contract for distributing fees and auction proceeds in the charon system
**/
contract CFC is MerkleTree{

    /*Storage*/
    struct FeePeriod{
        uint256 endDate;//end date of a given fee period (e.g. monthly fee payments)
        bytes32 rootHash;//rootHash of CIT token balance tree to allow holder reward distribution
        uint256 totalSupply;//total supply of CIT tokens for calculating payments to holders
        uint256 chdRewardsPerToken;//chd tokens due to each holder of cit tokens
        uint256 baseTokenRewardsPerToken;//base tokens due to each holder of cit tokens
        uint256 feePeriodToDistributeCHD;//amount to distribute left in this round
        uint256 feePeriodToDistributeToken;//amount to distribute left in this round
    }

    address public cit;//CIT address (on mainnet ethereum)
    bool private _lock; //reentrant blocker
    uint256 public citChain; //chain that CIT token is on
    uint256 public toDistributeToken;//amount of baseToken reward to distribute in contract
    uint256 public toDistributeCHD;//amount of chd in contract to distribute as rewards
    uint256 public toHolders;//percent (e.g. 100% = 100e18) going to Holders of the governance token
    uint256 public toLPs;//percent (e.g. 100% = 100e18) going to LP's on this chain
    uint256 public toOracle;//percent (e.g. 100% = 100e18) going to the oracle provider on this chain
    uint256 public totalDistributedToken; //amount of all distributions baseToken
    uint256 public totalDistributedCHD;//amount of all distributions CHD
    uint256 public toUsers;//percent (e.g. 100% = 100e18) going to subsidize users (pay to mint CHD)
    uint256[] public feePeriods;//a list of block numbers corresponding to fee periods
    mapping(uint256 => FeePeriod) public feePeriodByTimestamp; //gov token balance
    mapping(uint256 => mapping(address => bool)) public didClaim;//shows if a user already claimed reward
    ICharon public charon;//instance of charon on this chain
    IERC20 public token;//ERC20 base token instance
    IERC20 public chd;//chd token instance
    IOracle public oracle;//oracle for reading cross-chain Balances


    /*Events*/
    event FeeAdded(uint256 _amount, bool _isCHD);
    event FeeRoundEnded(uint256 _endDate, uint256 _baseTokenrRewardsPerToken, uint256 _chdRewardsPerToken);
    event RewardClaimed(address _account,uint256 _baseTokenRewards,uint256 _chdRewards);

    /*Functions*/
    /**
     * @dev Constructor to initialize token
     * @param _charon address of charon on this chain
     * @param _oracle address of oracle for rootHash/supply
     * @param _toOracle percentage (100% = 100e18) given to oraclePayment address
     * @param _toLPs percentage (100% = 100e18) given to LPs
     * @param _toHolders percentage (100% = 100e18) given to CIT token holders
     * @param _toUsers percentage (100% = 100e18) given to chd minters (users)
     */
    constructor(address _charon, address _oracle, uint256 _toOracle, uint256 _toLPs, uint256 _toHolders, uint256 _toUsers){
        require(_toOracle + _toLPs + _toHolders + _toUsers == 100 ether, "should be 100%");
        charon = ICharon(_charon);
        oracle = IOracle(_oracle);
        toOracle = _toOracle;
        toLPs = _toLPs;
        toHolders = _toHolders;
        toUsers = _toUsers;
        uint256 _endDate = block.timestamp + 30 days;
        feePeriods.push(_endDate);
        feePeriodByTimestamp[_endDate].endDate = _endDate;
        token = charon.token();
    }

    /**
     * @dev allows fees to be added to the CFC for distribution
     * @param _amount amount of tokens being sent to contract
     * @param _isCHD bool whether the token is CHD (base token if false)
     */
    function addFees(uint256 _amount, bool _isCHD) public{
        //send LP and User rewards over now
        uint256 _toLPs = _amount * toLPs / 100e18;
        uint256 _toUsers = _amount * toUsers / 100e18;
        uint256 _toOracle = _amount * toOracle / 100e18;
        if(_isCHD){
            if(!_lock){require(chd.transferFrom(msg.sender,address(this), _amount), "should transfer amount");}
            chd.approve(address(charon),_toUsers + _toLPs + _toOracle);
            toDistributeCHD += _amount;
            charon.addRewards(_toUsers,_toLPs,_toOracle,true);
        }
        else{
            if(!_lock){require(token.transferFrom(msg.sender,address(this), _amount), "should transfer amount");}
            token.approve(address(charon),_toUsers + _toLPs + _toOracle);
            toDistributeToken += _amount;
            charon.addRewards(_toUsers,_toLPs,_toOracle,false);
        }
        emit FeeAdded(_amount , _isCHD);
    }

    /**
     * @dev enables CIT token holders to claim rewards for a given fee period
     * @param _timestamp uint256 input of fee period end date
     * @param _account _address to pay out
     * @param _balance uint256 amount of CIT tokens the _account holds
     * @param _hashes bytes32 hashes in the balance to prove balance
     * @param _right bool array of if the corresponding hash is rightmost
     */
    function claimRewards(uint256 _timestamp, address _account, uint256 _balance, bytes32[] calldata _hashes, bool[] calldata _right) external{
        FeePeriod storage _f = feePeriodByTimestamp[_timestamp];
        if(feePeriods.length >= 5){
            require(feePeriods[feePeriods.length - 5] < _timestamp, "too late too claim");
        }
        require(!didClaim[_timestamp][_account], "can only claim once");
        didClaim[_timestamp][_account] = true;
        bytes32 _myHash = keccak256(abi.encode(_account,_balance));
        if (_hashes.length == 1) {
            require(_hashes[0] == _myHash);
        } else {
            require(_hashes[0] == _myHash || _hashes[1] == _myHash || _hashes[2] == _myHash);
        }
        require(_inTree(_f.rootHash, _hashes, _right));//checks if your balance/account is in the merkleTree
        uint256 _baseTokenRewards = _f.baseTokenRewardsPerToken * _balance / 1e18;
        uint256 _chdRewards =  _f.chdRewardsPerToken * _balance /1e18;
        _f.feePeriodToDistributeCHD -= _chdRewards;
        _f.feePeriodToDistributeToken -= _baseTokenRewards;
        if(_baseTokenRewards > 0){
            require(token.transfer(_account, _baseTokenRewards));
        }
        if(_chdRewards > 0){
            require(chd.transfer(_account, _chdRewards));  
        }
        emit RewardClaimed(_account,_baseTokenRewards,_chdRewards);
    }

    /**
     * @dev function called to end a given fee round and distribute payment to oracle and holders
     */
    function endFeeRound() external{
        FeePeriod storage _f = feePeriodByTimestamp[feePeriods[feePeriods.length - 1]];
        require(block.timestamp > _f.endDate + 12 hours, "round should be over and time for tellor");
        bytes memory _val = oracle.getRootHashAndSupply(_f.endDate,citChain,cit);
        (bytes32 _rootHash, uint256 _totalSupply) = abi.decode(_val,(bytes32,uint256));
        _f.rootHash = _rootHash;
        _f.totalSupply = _totalSupply;
        uint256 _endDate = block.timestamp + 30 days;
        feePeriods.push(_endDate);
        feePeriodByTimestamp[_endDate].endDate = _endDate;
        _f.baseTokenRewardsPerToken = toDistributeToken * toHolders / (_totalSupply * 100);
        _f.chdRewardsPerToken = toDistributeCHD * toHolders  / (_totalSupply * 100);
        _f.feePeriodToDistributeCHD = toDistributeCHD * toHolders / 100e18;
        _f.feePeriodToDistributeToken = toDistributeToken * toHolders / 100e18;
        toDistributeToken = 0;
        toDistributeCHD = 0;
        if(feePeriods.length >= 5){
            _lock = true;
            addFees(feePeriodByTimestamp[feePeriods[feePeriods.length - 5]].feePeriodToDistributeToken,false);
            addFees(feePeriodByTimestamp[feePeriods[feePeriods.length - 5]].feePeriodToDistributeCHD,true);
            _lock = false;
        }
        emit FeeRoundEnded(_f.endDate, _f.baseTokenRewardsPerToken, _f.chdRewardsPerToken);
    }

    /** 
     * @dev getter to show all fee period end dates
     * @param _cit address variable of the CIT token on mainchain
     * @param _chainId chainID of the main chain
     * @param _chd chd token address on this chain
     */
    function setCit(address _cit, uint256 _chainId, address _chd) external{
        require(cit == address(0), "cit already set");
        citChain = _chainId;
        cit = _cit;
        chd = IERC20(_chd);
    }

    //Getters
    /** 
     * @dev getter to show all fee period end dates
     * @return returns uint array of all fee period end dates
     */
    function getFeePeriods() external view returns(uint256[] memory){
        return feePeriods;
    }
    /** 
     * @dev getter to show fee period variables for given endDate
     * @param _timestamp uint256 input of fee period end date
     * @return returns the FeePeriod variables (endDate, rootHash, totalSupply, chdRewardsPerToken, baseRewardsPerToken)
     */
    function getFeePeriodByTimestamp(uint256 _timestamp) external view returns(FeePeriod memory){
        return feePeriodByTimestamp[_timestamp];
    }

        /** 
     * @dev getter to show whether a fee has been claimed
     * @param _timestamp uint256 input of fee period end date
     * @param _account account your inquiring about
     * @return returns bool of if claimed
     */
    function getDidClaim(uint256 _timestamp, address _account) external view returns(bool){
        return didClaim[_timestamp][_account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 @title MerleTree
 @dev contract for verifying inclusion in a given a merkleTree
**/
contract MerkleTree {

    /*Functions*/
    /**
     * @dev Gets roothash of a given tree
     * @param _inputs bytes32[] of merkle tree inputs
     */
    function getRootHash(bytes32[] memory _inputs) public pure returns (bytes32) {
        uint256 _len = _inputs.length;
        if (_len == 1) {
            return _inputs[0];
        }
        bytes32[] memory _currentTree = new bytes32[](_len/2 + (_len) % 2);
        uint256 _index = 0;
        uint256 _maxIndex = _len - 1;
        bool _readInputs = true;
        bytes32 _newHash;
        bytes32 _hash1;
        while (true) {
            if (_readInputs) {
                _hash1 = _inputs[_index];
                if (_index + 1 > _maxIndex){
                    _newHash = keccak256(abi.encodePacked(_hash1,_hash1));
                }
                else {
                    _newHash = keccak256(abi.encodePacked(_hash1,_inputs[_index+1]));
                }
            }
            else {
                _hash1 = _currentTree[_index];
                if (_index + 1 > _maxIndex){
                    _newHash = keccak256(abi.encodePacked(_hash1,_hash1));
                }
                else {
                    _newHash = keccak256(abi.encodePacked(_hash1,_currentTree[_index+1]));
                }             
            }
            _currentTree[_index/2] = _newHash;
            _index += 2;
            if (_index > _maxIndex) {
                _maxIndex = (_index - 2) / 2;
                if (_maxIndex == 0) {
                    break;
                }
                _index = 0;
                _readInputs = false;
            }
        }
        return _currentTree[0];
    }  

    /** @dev Function to return true if a TargetHash was part of a tree
      * @param _rootHash the root hash of the tree
      * @param _hashTree The array of the hash items. The first is hashed with the second, the second with the third, etc.
      * @param _right bool array of if the corresponding hash is rightmost
      * @return A boolean wether `TargetHash` is part of the Merkle Tree with root hash `RootHash`. True if it is part of this tree, false if not. 
      */
    function _inTree(bytes32 _rootHash, bytes32[] memory _hashTree, bool[] memory _right) internal pure returns (bool) {
        bytes32 _cHash = _hashTree[0];
        for (uint256 _i=1;_i < _hashTree.length; _i++) {
            if (_right[_i]) {
                _cHash = keccak256(abi.encodePacked(_cHash, _hashTree[_i]));
            } else {
                _cHash = keccak256(abi.encodePacked(_hashTree[_i], _cHash));
            }
        }
        return (_cHash == _rootHash);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import "./IERC20.sol";
/**
 * @dev Interface of the charonAMM contracts used by the CFC
 */
interface ICharon {
    function addRewards(uint256 _toUsers, uint256 _toLPs, uint256 _toOracle,bool _isCHD) external;
    function token() external view returns(IERC20);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 @title IOracle
 @dev oracle interface for the CFC contract
**/
interface IOracle {
    function getRootHashAndSupply(uint256 _timestamp,uint256 _chainID, address _address) external view returns(bytes memory _value);
}