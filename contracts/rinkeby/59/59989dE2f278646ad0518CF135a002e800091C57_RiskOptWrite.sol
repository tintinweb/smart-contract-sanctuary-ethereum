// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

contract RiskOptWrite{

    bytes4 public methodId;

    //0xe9c714f2
    function _acceptAdmin() external{
        methodId = bytes4(keccak256("_acceptAdmin()"));
    }

    //0x6161eb18
    function _burn(address account, uint256 amount) external{
        methodId = bytes4(keccak256("_burn(address,uint256)"));
    }

    //0x0b97309a
    function _reduceReserves(uint reduceAmount) external{
        methodId = bytes4(keccak256("_reduceReserves(uint)"));
    }

    //0x822e1e01
    function _reduceReservesFresh(uint reduceAmount) public{
        methodId = bytes4(keccak256("_reduceReservesFresh(uint)"));
    }

    //0x719df4fc
    function _setCompToken(address _compToken) public{
        methodId = bytes4(keccak256("_setCompToken(address)"));
    }

    //0xfc201122
    function _setOwner(address newOwner) public{
        methodId = bytes4(keccak256("_setOwner(address)"));
    }

    //0xb71d1a0c
    function _setPendingAdmin(address newPendingAdmin) public{
        methodId = bytes4(keccak256("_setPendingAdmin(address)"));
    }

    //0xe992a041
    function _setPendingImplementation(address newPendingImplementation) public{
        methodId = bytes4(keccak256("_setPendingImplementation(address)"));
    }

    //0xfa873f7a
    function _setProtocolSeizeShareFresh(uint newProtocolSeizeShareMantissa) public{
        methodId = bytes4(keccak256("_setProtocolSeizeShareFresh(uint)"));
    }

    //0x784b650b
    function _setReserveFactor(uint newReserveFactorMantissa) external{
        methodId = bytes4(keccak256("_setReserveFactor(uint)"));
    }

    //0xd497404b
    function _setReserveFactorFresh(uint newReserveFactorMantissa) public{
        methodId = bytes4(keccak256("_setReserveFactorFresh(uint)"));
    }

    //0x9a83b63f
    function _setSafetyVault(address _safetyVault) public{
        methodId = bytes4(keccak256("_setSafetyVault(address)"));
    }

    //0x66555b2d
    function _setSafetyVaultRatio(uint _safetyVaultRatio) public{
        methodId = bytes4(keccak256("_setSafetyVaultRatio(uint)"));
    }

    //0x2d70db78
    function _setSeizePaused(bool state) public{
        methodId = bytes4(keccak256("_setSeizePaused(bool)"));
    }

    //0x8ebf6364
    function _setTransferPaused(bool state) public{
        methodId = bytes4(keccak256("_setTransferPaused(bool)"));
    }

    //0x79ba5097
    function acceptOwnership() external{
        methodId = bytes4(keccak256("acceptOwnership()"));
    }

    //0x266f24b7
    function add(uint256 _allocPoint, address _lpToken, address _rewarder, address _helper) external{
        methodId = bytes4(keccak256("add(uint256,address,address,address)"));
    }

    //0x0a498a3b
    function addBadAddress(address _bad) public{
        methodId = bytes4(keccak256("addBadAddress(address)"));
    }

    //0x983b2d56
    function addMinter(address _addMinter) public{
        methodId = bytes4(keccak256("addMinter(address)"));
    }

    //0xcdfaeab6
    function allowEmergency() external{
        methodId = bytes4(keccak256("allowEmergency()"));
    }

    //0x6f80d877
    function authorizeForLock(address _address) external{
        methodId = bytes4(keccak256("authorizeForLock(address)"));
    }

    //0x81c95579
    function authorizeLocker(address _locker) external{
        methodId = bytes4(keccak256("authorizeLocker(address)"));
    }

    //0x42966c68
    function burn(uint256 _amount) external{
        methodId = bytes4(keccak256("burn(uint256)"));
    }

    //0x3b3f0ee6
    function createRewarder(address _lpToken, address mainRewardToken) public{
        methodId = bytes4(keccak256("createRewarder(address,address)"));
    }

    //0x941c4854
    function delBadAddress(address _bad) public{
        methodId = bytes4(keccak256("delBadAddress(address)"));
    }

    //0x23338b88
    function delMinter(address _delMinter) public{
        methodId = bytes4(keccak256("delMinter(address)"));
    }

    //0x7dd38dcc
    function emergencyPtpWithdraw() external{
        methodId = bytes4(keccak256("emergencyPtpWithdraw()"));
    }

    function getMethodId(string memory _methodName) external pure returns (bytes4){
        return bytes4(keccak256(abi.encodePacked(_methodName)));
    }

    //0xdef68a9c
    function inCaseTokensGetStuck(address _token) public{
        methodId = bytes4(keccak256("inCaseTokensGetStuck(address)"));
    }

    //0x40c10f19
    function mint(address _account, uint256 _amount) external{
        methodId = bytes4(keccak256("mint(address,uint256)"));
    }

    //0x8456cb59
    function pause() external{
        methodId = bytes4(keccak256("pause()"));
    }

    //0xb5ed298a
    function proposeOwner(address newOwner) public{
        methodId = bytes4(keccak256("proposeOwner(address)"));
    }

    //0x5b12ff9b
    function proposeStrat(address _implementation) public{
        methodId = bytes4(keccak256("proposeStrat(address)"));
    }

    //0x715018a6
    function renounceOwnership() public{
        methodId = bytes4(keccak256("renounceOwnership()"));
    }

    //0x18f73472
    function renouncePauserRole() external{
        methodId = bytes4(keccak256("renouncePauserRole()"));
    }

    //0x1ab06ee5
    function set(uint256 _pid, uint256 _allocPoint) public{
        methodId = bytes4(keccak256("set(uint256,uint256)"));
    }

    //0x56a2ff68
    function set(address _lp, uint256 _allocPoint, address _rewarder, address _locker, bool overwrite) external{
        methodId = bytes4(keccak256("set(address,uint256,address,address,bool)"));
    }

    //0x1d065803
    function setAutoClaim(uint256 _pid, bool _set) external{
        methodId = bytes4(keccak256("setAutoClaim(uint256,bool)"));
    }

    //0x6427a308
    function setAutoUpdate(uint256 _pid, bool _set) external{
        methodId = bytes4(keccak256("setAutoUpdate(uint256,bool)"));
    }

    //0x58afefcc
    function setEmergency() external{
        methodId = bytes4(keccak256("setEmergency()"));
    }

    //0xf4954387
    function setHalt(bool halt) public{
        methodId = bytes4(keccak256("setHalt(bool)"));
    }

    //0xb5ec5c99
    function setHalvingPeriod(uint256 _block) public{
        methodId = bytes4(keccak256("setHalvingPeriod(uint256)"));
    }

    //0x791ba374
    function setMdxPerBlock(uint256 _newPerBlock) public{
        methodId = bytes4(keccak256("setMdxPerBlock(uint256)"));
    }

    //0x19b69036
    function setMintWhitelist(address _account, bool _enabled) external{
        methodId = bytes4(keccak256("setMintWhitelist(address,bool)"));
    }

    //0x4c69c00f
    function setOracleAddress(address oracle) public{
        methodId = bytes4(keccak256("setOracleAddress(address)"));
    }

    //0xe9e15b4f
    function setPoolAddress(address _poolAddress) public{
        methodId = bytes4(keccak256("setPoolAddress(address)"));
    }

    //0xa2212459
    function setPoolHelper(address _lp, address _helper) external{
        methodId = bytes4(keccak256("setPoolHelper(address,address)"));
    }

    //0x34970706
    function setPoolManagerStatus(address _address, bool _bool) external{
        methodId = bytes4(keccak256("setPoolManagerStatus(address,bool)"));
    }

    //0xca53f6ce
    function setRewardMaxPerBlock(uint256 _pid, uint256 _maxPerBlock) external{
        methodId = bytes4(keccak256("setRewardMaxPerBlock(uint256,uint256)"));
    }

    //0x23b88e61
    function setRewardRestricted(address _hacker, uint256 _rate) external{
        methodId = bytes4(keccak256("setRewardRestricted(address,uint256)"));
    }

    //0x34970706
    function setStargatePerBlock(uint256 _stargatePerBlock) external{
        methodId = bytes4(keccak256("setStargatePerBlock(uint256)"));
    }

    //0xf6c1da1a
    function transferOrigin(address _oldOrigin,address _newOrigin) public{
        methodId = bytes4(keccak256("transferOrigin(address,address)"));
    }

    //0xf2fde38b
    function transferOwnership(address newOwner) public{
        methodId = bytes4(keccak256("transferOwnership(address)"));
    }

    //0xbad383a6
    function transferPauserRole(address newPauser) external{
        methodId = bytes4(keccak256("transferPauserRole(address)"));
    }

    //0x333667dc
    function updateBswPerBlock(uint256 newAmount) public{
        methodId = bytes4(keccak256("updateBswPerBlock(uint256)"));
    }

    //0x0ba84cd2
    function updateEmissionRate(uint256 _protonPerBlock) public{
        methodId = bytes4(keccak256("updateEmissionRate(uint256)"));
    }

    //0x5ffe6146
    function updateMultiplier(uint256 multiplierNumber) external{
        methodId = bytes4(keccak256("updateMultiplier(uint256)"));
    }

    //0xebbda551
    function updateNftPoolFeeBP(uint16 _nftPoolFeeBP) public{
        methodId = bytes4(keccak256("updateNftPoolFeeBP(uint16)"));
    }

    //0x06bcf02f
    function updateStartTime(uint256 _startTime) external{
        methodId = bytes4(keccak256("updateStartTime(uint256)"));
    }

    //0xe6685244
    function upgradeStrat() public{
        methodId = bytes4(keccak256("upgradeStrat()"));
    }

    //0x7b261591
//    function setNewMasterPlatypus(IMasterPlatypusV2 _newMasterPlatypus) external{
//        methodId = bytes4(keccak256("setNewMasterPlatypus(IMasterPlatypusV2)"));
//    }

    //0x88bba42f
//    function set(uint256 _pid, uint256 _baseAllocPoint, IRewarder _rewarder, bool overwrite) public{
//        methodId = bytes4(keccak256("set(uint256,uint256,IRewarder,bool)"));
//    }

    //0x90d9c1c3
//    function setVePtp(IVePtp _newVePtp) external{
//        methodId = bytes4(keccak256("setVePtp(IVePtp)"));
//    }

    //
//    function _setComptroller(ComptrollerInterface newComptroller) public{
//        methodId = bytes4(keccak256("_setComptroller(ComptrollerInterface)"));
//    }

//    function _setInterestRateModel(InterestRateModel newInterestRateModel) public{
//        methodId = bytes4(keccak256("_setInterestRateModel(InterestRateModel)"));
//    }

    //0x3bcf7ec1
//    function _setMintPaused(CToken cToken, bool state) public{
//        methodId = bytes4(keccak256("_setMintPaused(CToken,bool)"));
//    }

    //0x18c882a5
//    function _setBorrowPaused(CToken cToken, bool state) public{
//        methodId = bytes4(keccak256("_setBorrowPaused(CToken,bool)"));
//    }

    //19ab453c
//    function init(IBEP20 dummyToken) external{
//        methodId = bytes4(keccak256("init(IBEP20)"));
//    }

    //
//    function _setComptroller(ComptrollerInterface newComptroller) public{
//        methodId = bytes4(keccak256("_setComptroller(ComptrollerInterface)"));
//    }

//    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) public{
//        methodId = bytes4(keccak256("_setInterestRateModelFresh(InterestRateModel)"));
//    }
}