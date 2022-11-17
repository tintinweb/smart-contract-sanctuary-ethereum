// // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IMatchPrediction.sol";
import "./Match.sol";

contract MatchPrediction is Initializable, IMatchPrediction,Match { 
    IERC20Upgradeable public daiToken;

    /** NOTE {isMatchPrediction} set inside the initialize to {true} */
    bool public override isMatchPrediction;
    uint public override DaiMultiplier;
    mapping(uint256=>uint256) public override matchTotal;
    mapping(address => mapping (uint256 => uint256)) public override activeMatchPrediction;
    mapping(address => mapping( bytes32 => MatchPredictionData )) public override predictions;
    mapping(uint256 => uint256) public override matchRegularTimeWinAPrediction;
    mapping(uint256 => uint256) public override matchRegularTimeDrawPrediction;
    mapping(uint256 => uint256) public override matchRegularTimeWinBPrediction;
    mapping(uint256 => uint256) public override matchExtraTimeWinAPrediction;
    mapping(uint256 => uint256) public override matchExtraTimeDrawPrediction;
    mapping(uint256 => uint256) public override matchExtraTimeWinBPrediction;
    mapping(uint256 => uint256) public override matchPenaltyWinAPrediction;
    mapping(uint256 => uint256) public override matchPenaltyWinBPrediction;
    mapping(uint256 => mapping(int8 => uint256)) public override matchRegularTimeGoalDifference;
    mapping(uint256 => mapping(int8 => uint256)) public override matchExtraTimeGoalDifference;
    mapping(uint256 => mapping(int8 => uint256)) public override matchPenaltyGoalDifference;
    mapping(uint256 => mapping(int32 => uint256)) public override matchRegularTimeExact;
    mapping(uint256 => mapping(int32 => uint256)) public override matchExtraTimeExact;
    mapping(uint256 => mapping(int32 => uint256)) public override matchPenaltyExact;

    /** NOTE modifier for check valid address */
    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }
    /// @inheritdoc IMatchPrediction
    function initialize(address _accessRestrictionAddress, address _teamContractAddress)
        external
        override
        initializer
    {
        _initializeMatch(_accessRestrictionAddress, _teamContractAddress);
        isMatchPrediction = true;
    }
    /// @inheritdoc IMatchPrediction
    function setDaiTokenAddress(address _address,uint256 _daiMultiplier)
        external
        override
        onlyAdmin
        validAddress(_address)
    {
        require(_daiMultiplier>0,"invalid DAI multiplier");
        IERC20Upgradeable candidateContract = IERC20Upgradeable(_address);
        daiToken = candidateContract;
        DaiMultiplier=_daiMultiplier;
    }
    function _normalizePredict(bool isPlayOff, uint48 _predict)
    internal
    pure
    returns(uint48)
    {
        if(isPlayOff){
            uint8[] memory goals = new uint8[](6);
            uint48 x=_predict;
            for (uint256 i = 0; i < 6; i++){
                goals[i] = uint8(x & 255);
                x >>= 8;
            }
            if(goals[0]!=goals[1]){
                return _predict&uint48(type(uint16).max);
            }
            else if(goals[2]!=goals[3]){
                return _predict&uint48(type(uint32).max);
            }
            else{
                return _predict;
            }
        }
        else{
            return _predict&uint48(type(uint16).max);
        }

    }

    /// @inheritdoc IMatchPrediction
    function addPrediction(uint256 _matchId, uint48 _predict, uint256 _amount)
        external
        override
    {
        require(_predict<type(uint48).max,"invalid Prediciton");
        require((matches[_matchId].status >1 && matches[_matchId].status!=8 && (matches[_matchId].startDate+50*60*1000)>=block.timestamp),"match is not valid");
        require(activeMatchPrediction[msg.sender][_matchId]+_amount<1000,"max amount of match is 1000$");
        uint totalAmount=DaiMultiplier*_amount;
        require(
            daiToken.balanceOf(msg.sender) >= totalAmount,
            "Insufficient balance"
        );
        bool success = daiToken.transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        require(success, "Unsuccessful transfer");
        matchTotal[_matchId]+=(15*_amount*DaiMultiplier)/16;
        int8[] memory goals = new int8[](6);
        uint48 truePredict=_normalizePredict(matches[_matchId].isPlayOff,_predict);
        uint48 x=truePredict;
        uint8 z;
        for (uint256 i = 0; i < 6; i++){
            z= uint8(x & 255);
            goals[i] =int8(z) ;
            x >>= 8;
        }
        uint256  multiplirPrediction=10;
        if (matches[_matchId].startDate<block.timestamp){
            multiplirPrediction=7;
        }
        activeMatchPrediction[msg.sender][_matchId]+=_amount;
        if(goals[1]==goals[0]){
            matchRegularTimeDrawPrediction[_matchId]+=multiplirPrediction*_amount;
        }
        else if(goals[0]>goals[1]){
            matchRegularTimeWinAPrediction[_matchId]+=multiplirPrediction*_amount;

        }else{
            matchRegularTimeWinBPrediction[_matchId]+=multiplirPrediction*_amount;

        }
        matchRegularTimeGoalDifference[_matchId][int8(goals[0])-int8(goals[1])]+=multiplirPrediction*_amount;
        matchRegularTimeExact[_matchId][int32(goals[1])*256+goals[0]]+=multiplirPrediction*_amount;
        bytes32 resHash=keccak256(
                            abi.encodePacked(
                                _matchId,
                                truePredict

                            )
                        );
        predictions[msg.sender][resHash].amount+=uint128(multiplirPrediction*_amount);
        if(matches[_matchId].isPlayOff==true && goals[0]==goals[1]){
            matchExtraTimeExact[_matchId][int32(goals[3])*256+goals[2]]+=multiplirPrediction*_amount;
            matchExtraTimeDrawPrediction[_matchId]+=multiplirPrediction*_amount;

            if( goals[2]==goals[3]){
                matchExtraTimeDrawPrediction[_matchId]+=multiplirPrediction*_amount;
                if(goals[4]>goals[5]){
                    matchPenaltyWinAPrediction[_matchId]+=multiplirPrediction*_amount;
                }
                else{
                    matchPenaltyWinBPrediction[_matchId]+=multiplirPrediction*_amount;
                }
                matchPenaltyGoalDifference[_matchId][int8(goals[4])-int8(goals[5])]+=multiplirPrediction*_amount;
                matchPenaltyExact[_matchId][int32(goals[5])*256+goals[4]]+=multiplirPrediction*_amount;
            }
            else if(goals[2]>goals[3]){
                    matchExtraTimeWinAPrediction[_matchId]+=multiplirPrediction*_amount;
            }
            else{
                matchExtraTimeWinBPrediction[_matchId]+=multiplirPrediction*_amount;
            }
        }
        emit PredictionAdded(msg.sender,_matchId,_predict,_amount);
    }
    /// @inheritdoc IMatchPrediction
    function getReward(MatchPredictionList[] memory _matchList )
    external
    override
    {
        require (_matchList.length<51,"data overflow");
        uint matchI;
        uint48 predictI;
        bool rewarded;
        uint totalReward=0;
        bytes32 resHashI;
        for(uint i=0; i<_matchList.length; i++){
            matchI=_matchList[i].matchId;
            predictI=_normalizePredict(matches[matchI].isPlayOff, _matchList[i].predict);
            resHashI=keccak256(
                            abi.encodePacked(
                                matchI,
                                predictI

                            )
                        );
            rewarded=predictions[msg.sender][resHashI].isRewarded;
            if (matches[matchI].status==4 && rewarded==false){
                totalReward+=_calcSingleReward(matchI,predictI,predictions[msg.sender][resHashI].amount);
                predictions[msg.sender][resHashI].isRewarded=true;
            }
        }
        if (totalReward>0){
            bool success=daiToken.transfer(msg.sender,totalReward);
            require(success, "Unsuccessful transfer");
        }
        emit RewardSent(_matchList, msg.sender, totalReward);
    }
    function _calcSingleReward(uint _matchId,uint48 _predict, uint128 _amount)
    private
    view
    returns(uint)
    {   bool _isPlayOff=matches[_matchId].isPlayOff;
        uint48 _result=matches[_matchId].result;
        uint rwd=0;
        uint8 z;
        int8[] memory res = new int8[](6);
        int8[] memory prd = new int8[](6);
        for (uint256 i = 0; i < 6; i++){
            z=uint8(_predict & 255);
            prd[i] = int8(z);
            _predict >>= 8;
            z=uint8(_result & 255);
            res[i] = int8(z);
            _result >>= 8;
        }
        uint256 totalPredictions=_calcTotalMatchReward(_matchId);
        int8 x=res[0]-res[1];
        int8 y=prd[0]-prd[1];
        if (x==0 && y==0){
            rwd=7;
            if (res[0]==prd[0]){
                rwd=10;
            }
            if (_isPlayOff==true)
            {
                x=res[2]-res[3];
                y=prd[2]-prd[3];
                if(x==0 && y==0){
                    rwd=17;
                    if (res[2]==prd[2]){
                        rwd=20;
                    }
                    x=res[4]-res[5];
                    y=prd[4]-prd[5];
                    if(int16(x)*int16(y)>0){
                        rwd=26;
                        if (x==y){
                            rwd=28;
                            if(res[4]==prd[4]){
                                rwd=30;
                            }
                        }
                    }
                }
                else if(int16(x)*int16(y)>0){
                    rwd=16;
                    if (x==y){
                        rwd=18;
                        if(res[4]==prd[4]){
                            rwd=20;
                        }
                    }
                }
            }
        }
        else if(int16(x)*int16(y)>0){
            rwd=6;
            if (x==y){
                rwd=8;
                if(res[4]==prd[4]){
                    rwd=10;
                }
            }
        }
        return (rwd*uint256(_amount)*matchTotal[_matchId])/totalPredictions;

    }

    function _calcTotalMatchReward(uint _matchId)
    private
    view
    returns(uint){
        uint48 _result=matches[_matchId].result;
        uint rwd=0;
        int8[] memory res = new int8[](6);
        uint8 z;
        for (uint256 i = 0; i < 6; i++){
            z=uint8(_result & 255);
            res[i] = int8(z);
            _result >>= 8;
        }
        int8 x=int8(res[0]-res[1]);
        if(x==0){
            rwd+=7*matchRegularTimeDrawPrediction[_matchId];
            rwd+=3*matchRegularTimeExact[_matchId][int32(res[1])*256+res[0]];
            if(matches[_matchId].isPlayOff){
                x=res[2]-res[3];
                if(x==0){
                    rwd+=7*matchExtraTimeDrawPrediction[_matchId];
                    rwd+=3*matchExtraTimeExact[_matchId][int32(res[3])*256+res[2]];
                    x=res[4]-res[5];
                    rwd+=2*matchPenaltyGoalDifference[_matchId][x];
                    rwd+=2*matchPenaltyExact[_matchId][int32(res[5])*256+res[4]];
                    if(x>0){
                        rwd+=6*matchPenaltyWinAPrediction[_matchId];
                    }
                    else{
                        rwd+=6*matchPenaltyWinBPrediction[_matchId];
                    }
                }
                else {
                    rwd+=2*matchExtraTimeGoalDifference[_matchId][x];
                    rwd+=2*matchExtraTimeExact[_matchId][int32(res[3])*256+res[2]];
                    if(x>0){
                        rwd+=6*matchExtraTimeWinAPrediction[_matchId];
                    }
                    else{
                        rwd+=6*matchExtraTimeWinBPrediction[_matchId];
                    }

                }

            }
        }
        else{
            rwd+=2*matchRegularTimeGoalDifference[_matchId][x];
            rwd+=2*matchRegularTimeExact[_matchId][int32(res[1])*256+res[0]];
            if(x>0){
                rwd+=6*matchRegularTimeWinAPrediction[_matchId];
            }
            else{
                rwd+=6*matchRegularTimeWinBPrediction[_matchId];
            }
        }
        return rwd;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./IMatch.sol";

interface IMatchPrediction is IMatch {
    struct MatchPredictionData{
        uint128 amount;
        bool isRewarded;
    }
    struct MatchPredictionList{
        uint256 matchId;
        uint48 predict;
    }
   /**
     * @dev emitted when dai token address set
     * @param daiToken address of DAI token in network
     * @param decimal number of digits after decimal point
     */

    event DaiTokenSet(
        address daiToken,
        uint256 decimal
    );

    /**
     * @dev emitted when a prediction added
     * @param predictor predictor address
     * @param matchId id of match predicted
     * @param predict the predict value
     * @param amount weight of predict in DAI
     */

    event PredictionAdded(
        address predictor,
        uint256 matchId,
        uint48 predict,
        uint256 amount
    );

    /**
     * @dev emitted when team updated
     * @param matchList list of matches to get reward from
     * @param predictor rewarded predictor address 
     * @param reward reward amount in DAI
     */

    event RewardSent(
        MatchPredictionList[] matchList,
        address predictor,
        uint256 reward
    );


        /**
     * @dev set dai token address on network
     * NOTE emit an {DaiTokenSet} event
     * @param _address address of DAI token contract
     * @param _daiMultiplier multiplier of Dai Amount
     */
    function setDaiTokenAddress(address _address,uint256 _daiMultiplier) external;

    /**
     * @dev add a prediction
     * NOTE emit an {PredictionAdded} event
     * @param _matchId Id of match predicted
     * @param _predict predict value
     * @param _amount weight of prediction
     */
    function addPrediction(uint256 _matchId, uint48 _predict, uint256 _amount) external;

    /**
     * @dev get reward of batch of predictions
     * NOTE emit an {reward} event
     * @param _matchList list of match predictions
     */
    function getReward(MatchPredictionList[] memory _matchList ) external;

     /**
     * @dev initialize and set true for isMatchPrediction
     * @param _accessRestrictionAddress address of AccessRestiction contract
     * @param _teamContractAddress address of Team contract
     */
    function initialize(address _accessRestrictionAddress, address _teamContractAddress) external;

    /**
     * @return true if MatchPrediction contract have been initialized
     */
    function isMatchPrediction() external view returns (bool);

    /**
     * @return uint256 amount of DaiMultipLier
     */
    function DaiMultiplier() external view returns (uint256);

    /**
     * @dev return total collected Amount in DAI
     * @param _matchId id of team to get data
     * @return totalAmount
     */
    function matchTotal(uint256 _matchId)
        external
        view
        returns (
            uint256
    );

    /**
     * @dev return amount a predictor predicted for a match
     * @param _predictor address of predictor
     * @param _matchId id of match
     * @return amount  amount of predictor investment for a match
     */
    function activeMatchPrediction(address _predictor,uint256 _matchId)
        external
        view
        returns(
            uint256
        );
    /**
     * @dev returns amount and status of  a single prediction
     * @param _predictor address of predictor
     * @param _predictionHash hash of matchId and prediction value
     * @return amount amount invested in prediction
     * @return isRewarded is reward has been tooked for the  prediction
     */
    function predictions(address _predictor,bytes32 _predictionHash)
        external
        view
        returns (
            uint128,
            bool
        );

     /**
     * @dev returns the total prediction of win A in regulartime
     * @param _matchId Id of match
     * @return amount amount invested in win A in regular time
      */
    function matchRegularTimeWinAPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of draw in regulartime
     * @param _matchId Id of match
     * @return amount amount invested in draw in regular time
    */
    function matchRegularTimeDrawPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of win B in regulartime
     * @param _matchId Id of match
     * @return amount amount invested in win B in regular time
    */
    function matchRegularTimeWinBPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of win A in extra time
     * @param _matchId Id of match
     * @return amount amount invested in win A in extra time
    */
    function matchExtraTimeWinAPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of win A in extra time
     * @param _matchId Id of match
     * @return amount amount invested in win A in extra time
    */
    function matchExtraTimeDrawPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of win B in extra time
     * @param _matchId Id of match
     * @return amount amount invested in win B in extra time
    */
    function matchExtraTimeWinBPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );
    /**
     * @dev returns the total prediction of win A in Penalty
     * @param _matchId Id of match
     * @return amount amount invested in win A in Penalty
    */
    function matchPenaltyWinAPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of win B in Penalty
     * @param _matchId Id of match
     * @return amount amount invested in win B in Penalty
    */
    function matchPenaltyWinBPrediction(uint256 _matchId)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of goal Difference in regular time
     * @param _matchId Id of match
     * @param _goalDifference goal difference A-B
     * @return amount amount invested in goal Difference in regular time
    */
    function matchRegularTimeGoalDifference(uint256 _matchId,int8 _goalDifference)
        external
        view
        returns (
            uint256
        );
    /**
     * @dev returns the total prediction of goal Difference in extra time
     * @param _matchId Id of match
     * @param _goalDifference goal difference A-B
     * @return amount amount invested in goal Difference in extra time
    */
    function matchExtraTimeGoalDifference(uint256 _matchId,int8 _goalDifference)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of goal Difference in extra time
     * @param _matchId Id of match
     * @param _goalDifference goal difference A-B
     * @return amount amount invested in goal Difference in extra time
    */
    function matchPenaltyGoalDifference(uint256 _matchId,int8 _goalDifference)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of exact result in regularTime
     * @param _matchId Id of match
     * @param _exact exact result of regular time
     * @return amount amount invested in  exact result in regularTime
    */
    function matchRegularTimeExact(uint256 _matchId,int32 _exact)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of exact result in extraTime
     * @param _matchId Id of match
     * @param _exact exact result of extra time
     * @return amount amount invested in  exact result in extraTime
    */
    function matchExtraTimeExact(uint256 _matchId,int32 _exact)
        external
        view
        returns (
            uint256
        );

    /**
     * @dev returns the total prediction of exact result in Penalty
     * @param _matchId Id of match
     * @param _exact exact result of Penalty
     * @return amount amount invested in  exact result in Penalty
    */
    function matchPenaltyExact(uint256 _matchId,int32 _exact)
        external
        view
        returns (
            uint256
        );

}

// // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../access/IAccessRestriction.sol";
import "../team/ITeam.sol";
import "./IMatch.sol";

contract Match is Initializable, IMatch { 
    using CountersUpgradeable for CountersUpgradeable.Counter;
    struct MatchData {
        bool isPlayOff;
        uint32 teamA;
        uint32 teamB;
        uint32 group;//1:A,2:B,3:C,4:D,5:E,6:F,7:G,8:H,9:1/8,10:1/4,11:semi final,12:final games
        uint32 status;
        uint48 result;
        uint64 startDate;
    }

    IAccessRestriction public accessRestriction;
    ITeam public teamContract;

    CountersUpgradeable.Counter private _matchCounter;


    /** NOTE {isMatch} set inside the initialize to {true} */
    bool public override isMatch;

    /** NOTE mapping of teamId to TeamData Struct */
    mapping(uint256 => MatchData) public override matches;



    /** NOTE modifier to check msg.sender has data manager role */
    modifier onlyDataManager() {
        accessRestriction.ifDataManager(msg.sender);
        _;
    }
    /** NOTE modifier to check msg.sender has data manager role */
    modifier onlyAdmin() {
        accessRestriction.ifAdmin(msg.sender);
        _;
    }

    
    function _initializeMatch(address _accessRestrictionAddress, address _teamContractAddress)
    internal
    {
        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        ITeam candid=ITeam(_teamContractAddress);

        require(candidateContract.isAccessRestriction());
        require(candid.isTeam());
        isMatch= true;
        _matchCounter.increment();
        accessRestriction = candidateContract;
        teamContract=candid;
    }

    /// @inheritdoc IMatch
    function addMatch( uint32 _teamA,
        uint32 _teamB,
        uint32 _group,
        bool _isPlayOff,
        uint64 _startDate)
        external
        override
        onlyDataManager
    {
        require(teamContract.teamsExist(_teamA,_teamB),"Teams are not valid");
        require(_startDate>block.timestamp,"The match is expired");
        matches[_matchCounter.current()]=MatchData(_isPlayOff,_teamA,_teamB,_group,1,0,_startDate);
        emit MatchAdded(_matchCounter.current(), _teamA, _teamB, _group, _isPlayOff, _startDate);
        _matchCounter.increment();
    }
    /// @inheritdoc IMatch
    function verifyMatch( uint256 _matchId )
    external
    override
    onlyAdmin
    {
        require(matches[_matchId].startDate>block.timestamp,"The match is expired");
        matches[_matchId].status=2;
        emit MatchVerified(_matchId);
    }
    /// @inheritdoc IMatch
    function updateMatch(uint256 _matchId, uint64 _startDate, uint32 _status)
    external
    override
    onlyAdmin
    {
        require(_startDate>block.timestamp,"The match is expired");
        require(_status>2 && matches[_matchId].status<9,"invalid state");
        require(matches[_matchId].status>1 && matches[_matchId].status<8,"match cannot be updated");
        matches[_matchId].status=_status;
        matches[_matchId].startDate=_startDate;
        emit MatchUpdated(_matchId, _startDate, _status);
    }


    /// @inheritdoc IMatch
    function addMatchResult(uint256 _matchId, uint48 _result)
        external
        override
        onlyDataManager
    {
        require(matches[_matchId].status>1 && matches[_matchId].status<8,"match cannot be updated");
        require(matches[_matchId].startDate+6300*1000<block.timestamp,"match is not finished yet");
        matches[_matchId].result=_result;
        matches[_matchId].status=3;
        emit MatchResultAdded(_matchId, _result);
    }

    /// @inheritdoc IMatch
    function verifyMatchResult(uint256 _matchId)
        external
        override
        onlyAdmin
    {
        require(matches[_matchId].status==3,"match cannot be updated");
        matches[_matchId].status==4;
        emit MatchResultVerified(_matchId);
    }
    function getLastMatch()
    external
    view
    returns(uint)
    {
        return _matchCounter.current();
    }




}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IMatch {
    /**
     * @dev emitted when match added
     * @param id matchId
     * @param teamA teamAId
     * @param teamB teamBId
     * @param group group or level the match exists at
     * @param isplayOff if playOff true else false
     * @param startDate match startDate
     */

    event MatchAdded(
        uint256 id,
        uint32 teamA,
        uint32 teamB,
        uint32 group,
        bool isplayOff,
        uint64 startDate

    );
     /**
     * @dev emitted when match verified
     * @param id matchId
     */

    event MatchVerified(
        uint256 id
    );

    /**
     * @dev emitted when match updated
     * @param id matchId
     * @param startDate start date of match
     * @param status status of match {1:added,2:verified,3:resultAdded, 4:resultVerified, 5:delayedtoMax1Week,6:delayedtoKnownTime,7:delayedToUnknownDate,  8:canceled}
     */

    event MatchUpdated(
        uint256 id,
        uint64 startDate,
        uint32 status
    );

    /**
     * @dev emitted when match result added
     * @param id matchId
     * @param result result of match
     */

    event MatchResultAdded(
        uint256 id,
        uint64 result
    );

    /**
     * @dev emitted when Match Result Verified
     * @param id matchId
     */

    event MatchResultVerified(
        uint256 id
    );
    
    /**
     * @dev return last matchId
     * @return id last matchId
     */
    function getLastMatch() external view returns(uint);

    /**
     * @dev add a match
     * NOTE emit an {MatchAdded} event
     * @param _teamA teamA ID
     * @param _teamB teamB ID
     * @param _group group or level the match exists at
     * @param _isPlayOff  if playOff
     * @param _startDate start date of match
     */
    function addMatch(
        uint32 _teamA,
        uint32 _teamB,
        uint32 _group,
        bool _isPlayOff,
        uint64 _startDate
    ) external;

    /**
     * @dev verify a match
     * NOTE emit an {matchVerified} event
     * @param _matchId match id
     */
    function verifyMatch(
        uint256 _matchId
    ) external;



    /**
     * @dev update a match
     * NOTE emit an {matchUpdated} event
     * @param _matchId match id
     * @param _startDate start date of match
     * @param _status new status of match
     */
    function updateMatch(
        uint256 _matchId,
        uint64 _startDate,
        uint32 _status
    ) external;

    /**
     * @dev add the match result
     * NOTE emit an {MatchResultAdded} event
     * @param _matchId match id
     * @param _result result of match
     */
    function addMatchResult(
        uint256 _matchId,
        uint48 _result
    ) external;

        /**
     * @dev verify the match result
     * NOTE emit an {MatchResultVerified} event
     * @param _matchId match id
     */
    function verifyMatchResult(
        uint256 _matchId
    ) external;


    //  /**
    //  * @dev initialize AccessRestriction contract and set true for isMatch
    //  * @param _accessRestrictionAddress set to the address of AccessRestriction contract
    //  * @param _teamContractAddress set to the address of team contract
    //  */
    // function initializeMatch(address _accessRestrictionAddress, address _teamContractAddress) external;

    /**
     * @return true if Team contract have been initialized
     */
    function isMatch() external view returns (bool);


    /**
     * @dev return symbol data
     * @param _matchId id of team to get data
     * @return isPlayOff
     * @return teamA
     * @return teamB
     * @return group
     * @return status
     * @return result
     * @return startDate
     */
    function matches(uint256 _matchId)
        external
        view
        returns ( bool,uint32,uint32,uint32,uint32,uint48,uint64 );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/** @title AccessRestriction interface*/

interface IAccessRestriction is IAccessControlUpgradeable {

    function initialize(address _deployer) external;

    /** @return true if AccessRestriction contract has been initialized  */
    function isAccessRestriction() external view returns (bool);



   /**
     * @dev check if given address is admin
     * @param _address input address
     */
    function ifAdmin(address _address) external view;

    /**
     * @dev check if given address has admin role
     * @param _address input address
     * @return if given address has admin role
     */
    function isAdmin(address _address) external view returns (bool);

    /**
     * @dev check if given address is Wolrdcup contract
     * @param _address input address
     */
    function ifWolrdcupContract(address _address) external view;

    /**
     * @dev check if given address has Wolrdcup contract role
     * @param _address input address
     * @return if given address has Wolrdcup contract role
     */
    function isWolrdcupContract(address _address) external view returns (bool);

    /**
     * @dev check if given address is data manager
     * @param _address input address
     */
    function ifDataManager(address _address) external view;

    /**
     * @dev check if given address has data manager role
     * @param _address input address
     * @return if given address has data manager role
     */
    function isDataManager(address _address) external view returns (bool);

    /**
     * @dev check if given address is verifier
     * @param _address input address
     */
    function ifVerifier(address _address) external view;

    /**
     * @dev check if given address has verifier role
     * @param _address input address
     * @return if given address has verifier role
     */
    function isVerifier(address _address) external view returns (bool);

    /**
     * @dev check if given address is script
     * @param _address input address
     */
    function ifScript(address _address) external view;

    /**
     * @dev check if given address has script role
     * @param _address input address
     * @return if given address has script role
     */
    function isScript(address _address) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface ITeam {
    /**
     * @dev emitted when team added
     * @param id teamId
     * @param country country name
     */

    event TeamAdded(
        uint32 id,
        bytes32 country
    );

        /**
     * @dev emitted when team updated
     * @param id teamId
     * @param country country name
     */

    event TeamUpdated(
        uint32 id,
        bytes32 country
    );



    /**
     * @dev add a team
     * NOTE emit an {TeamAdded} event
     * @param _countryName name of country
     */
    function addTeam(
        bytes32 _countryName
    ) external;

    /**
     * @dev update a team
     * NOTE emit an {TeamUpdated} event
     * @param _id id of team
     * @param _countryName name of country
     */
    function updateTeam(
        uint32 _id,
        bytes32 _countryName
    ) external;
     /**
     * @dev initialize AccessRestriction contract and set true for isMatch
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     */
    function initialize(address _accessRestrictionAddress) external;

    /**
     * @return true if Team contract have been initialized
     */
    function isTeam() external view returns (bool);


    /**
     * @dev return symbol data
     * @param _teamId id of team to get data
     * @return countryName
     */
    function teams(uint32 _teamId)
        external
        view
        returns (
            bytes32
        );
    /**
     * @dev return symbol data
     * @param _countryName name of country
     * @return exists
     */
    function countryNames(bytes32 _countryName)
        external
        view
        returns (
            bool
        );

    /**
     * @dev return symbol data
     * @param _teamA teamA id
     * @param _teamB teamB id
     * @return exists
     */
    function teamsExist(uint32 _teamA,uint32 _teamB)
        external
        view
        returns (
            bool
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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