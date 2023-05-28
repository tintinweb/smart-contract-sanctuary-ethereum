/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-12
 */

pragma solidity 0.8.13;

abstract contract Setter {
    function modifyParameters(bytes32, address) public virtual;

    function modifyParameters(bytes32, uint) public virtual;

    function modifyParameters(bytes32, int) public virtual;

    function modifyParameters(bytes32, uint, uint) public virtual;

    function modifyParameters(bytes32, uint, uint, address) public virtual;

    function modifyParameters(bytes32, bytes32, uint) public virtual;

    function modifyParameters(bytes32, bytes32, address) public virtual;

    function setDummyPIDValidator(address) public virtual;

    function addAuthorization(address) public virtual;

    function removeAuthorization(address) public virtual;

    function initializeCollateralType(bytes32) public virtual;

    function updateAccumulatedRate() public virtual;

    function redemptionPrice() public virtual;

    function setTotalAllowance(address, uint256) external virtual;

    function setPerBlockAllowance(address, uint256) external virtual;

    function taxMany(uint256, uint256) public virtual;

    function taxSingle(bytes32) public virtual;

    function setAllowance(address, uint256) external virtual;

    function connectSAFESaviour(address) external virtual;

    function disconnectSAFESaviour(address) external virtual;

    function addReader(address) external virtual;

    function removeReader(address) external virtual;

    function addAuthority(address) external virtual;

    function removeAuthority(address) external virtual;

    function changePriceSource(address) external virtual;

    function stopFsm(bytes32) external virtual;

    function setFsm(bytes32, address) external virtual;

    function start() external virtual;

    function changeNextPriceDeviation(uint) external virtual;

    function setName(string calldata) external virtual;

    function setSymbol(string calldata) external virtual;

    function disableContract() external virtual;

    function toggleSaviour(address) external virtual;

    function setMinDesiredCollateralizationRatio(
        bytes32,
        uint256
    ) external virtual;

    function updateResult(uint256) external virtual;

    function transferTokenOut(address, uint256) external virtual;

    function updateRate(uint256) external virtual;
}

abstract contract GlobalSettlementLike {
    function shutdownSystem() public virtual;

    function freezeCollateralType(bytes32) public virtual;
}

abstract contract PauseLike {
    function setOwner(address) public virtual;

    function setAuthority(address) public virtual;

    function setDelay(uint) public virtual;

    function setDelayMultiplier(uint) public virtual;

    function setProtester(address) public virtual;
}

abstract contract DSTokenLike {
    function mint(address, uint) public virtual;

    function burn(address, uint) public virtual;
}

contract GovActions {
    uint internal constant RAY = 10 ** 27;

    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "GovActions/sub-uint-uint-underflow");
    }

    function disableContract(address targetContract) public {
        Setter(targetContract).disableContract();
    }

    function modifyParameters(
        address targetContract,
        bytes32 parameter,
        address data
    ) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(
        address targetContract,
        bytes32 parameter,
        uint data
    ) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(
        address targetContract,
        bytes32 parameter,
        int data
    ) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(
        address targetContract,
        bytes32 collateralType,
        bytes32 parameter,
        uint data
    ) public {
        Setter(targetContract).modifyParameters(
            collateralType,
            parameter,
            data
        );
    }

    function modifyParameters(
        address targetContract,
        bytes32 collateralType,
        bytes32 parameter,
        address data
    ) public {
        Setter(targetContract).modifyParameters(
            collateralType,
            parameter,
            data
        );
    }

    function modifyParameters(
        address targetContract,
        bytes32 parameter,
        uint data1,
        uint data2
    ) public {
        Setter(targetContract).modifyParameters(parameter, data1, data2);
    }

    function modifyParameters(
        address targetContract,
        bytes32 collateralType,
        uint data1,
        uint data2,
        address data3
    ) public {
        Setter(targetContract).modifyParameters(
            collateralType,
            data1,
            data2,
            data3
        );
    }

    function modifyTwoParameters(
        address targetContract1,
        address targetContract2,
        bytes32 parameter1,
        bytes32 parameter2,
        uint data1,
        uint data2
    ) public {
        Setter(targetContract1).modifyParameters(parameter1, data1);
        Setter(targetContract2).modifyParameters(parameter2, data2);
    }

    function modifyTwoParameters(
        address targetContract1,
        address targetContract2,
        bytes32 parameter1,
        bytes32 parameter2,
        int data1,
        int data2
    ) public {
        Setter(targetContract1).modifyParameters(parameter1, data1);
        Setter(targetContract2).modifyParameters(parameter2, data2);
    }

    function modifyTwoParameters(
        address targetContract1,
        address targetContract2,
        bytes32 collateralType1,
        bytes32 collateralType2,
        bytes32 parameter1,
        bytes32 parameter2,
        uint data1,
        uint data2
    ) public {
        Setter(targetContract1).modifyParameters(
            collateralType1,
            parameter1,
            data1
        );
        Setter(targetContract2).modifyParameters(
            collateralType2,
            parameter2,
            data2
        );
    }

    function removeAuthorizationAndModify(
        address targetContract,
        address to,
        bytes32 parameter,
        uint data
    ) public {
        Setter(targetContract).removeAuthorization(to);
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function updateRateAndModifyParameters(
        address targetContract,
        bytes32 parameter,
        uint data
    ) public {
        Setter(targetContract).updateAccumulatedRate();
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxManyAndModifyParameters(
        address targetContract,
        uint start,
        uint end,
        bytes32 parameter,
        uint data
    ) public {
        Setter(targetContract).taxMany(start, end);
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxSingleAndModifyParameters(
        address targetContract,
        bytes32 collateralType,
        bytes32 parameter,
        uint data
    ) public {
        Setter(targetContract).taxSingle(collateralType);
        Setter(targetContract).modifyParameters(
            collateralType,
            parameter,
            data
        );
    }

    function updateRedemptionRate(
        address targetContract,
        bytes32 parameter,
        uint data
    ) public {
        Setter(targetContract).redemptionPrice();
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function setDummyPIDValidator(
        address rateSetter,
        address oracleRelayer,
        address dummyValidator
    ) public {
        Setter(rateSetter).modifyParameters("pidValidator", dummyValidator);
        Setter(oracleRelayer).redemptionPrice();
        Setter(oracleRelayer).modifyParameters("redemptionRate", RAY);
    }

    function toggleSaviour(address targetContract, address saviour) public {
        Setter(targetContract).toggleSaviour(saviour);
    }

    function addReader(address validator, address reader) public {
        Setter(validator).addReader(reader);
    }

    function removeReader(address validator, address reader) public {
        Setter(validator).removeReader(reader);
    }

    function addAuthority(address validator, address account) public {
        Setter(validator).addAuthority(account);
    }

    function removeAuthority(address validator, address account) public {
        Setter(validator).removeAuthority(account);
    }

    function connectSAFESaviour(
        address targetContract,
        address saviour
    ) public {
        Setter(targetContract).connectSAFESaviour(saviour);
    }

    function disconnectSAFESaviour(
        address targetContract,
        address saviour
    ) public {
        Setter(targetContract).disconnectSAFESaviour(saviour);
    }

    function setTotalAllowance(
        address targetContract,
        address account,
        uint256 rad
    ) public {
        Setter(targetContract).setTotalAllowance(account, rad);
    }

    function setPerBlockAllowance(
        address targetContract,
        address account,
        uint256 rad
    ) public {
        Setter(targetContract).setPerBlockAllowance(account, rad);
    }

    function setTreasuryAllowances(
        address targetContract,
        address account,
        uint256 perBlock,
        uint256 total
    ) public {
        Setter(targetContract).setPerBlockAllowance(account, perBlock);
        Setter(targetContract).setTotalAllowance(account, total);
    }

    function addAuthorization(address targetContract, address to) public {
        Setter(targetContract).addAuthorization(to);
    }

    function removeAuthorization(address targetContract, address to) public {
        Setter(targetContract).removeAuthorization(to);
    }

    function initializeCollateralType(
        address targetContract,
        bytes32 collateralType
    ) public {
        Setter(targetContract).initializeCollateralType(collateralType);
    }

    function changePriceSource(address fsm, address priceSource) public {
        Setter(fsm).changePriceSource(priceSource);
    }

    function stopFsm(address fsmGovInterface, bytes32 collateralType) public {
        Setter(fsmGovInterface).stopFsm(collateralType);
    }

    function setFsm(
        address fsmGovInterface,
        bytes32 collateralType,
        address fsm
    ) public {
        Setter(fsmGovInterface).setFsm(collateralType, fsm);
    }

    function start(address fsm) public {
        Setter(fsm).start();
    }

    function setName(address coin, string memory name) public {
        Setter(coin).setName(name);
    }

    function setSymbol(address coin, string memory symbol) public {
        Setter(coin).setSymbol(symbol);
    }

    function changeNextPriceDeviation(address fsm, uint deviation) public {
        Setter(fsm).changeNextPriceDeviation(deviation);
    }

    function shutdownSystem(address globalSettlement) public {
        GlobalSettlementLike(globalSettlement).shutdownSystem();
    }

    function setAuthority(address pause, address newAuthority) public {
        PauseLike(pause).setAuthority(newAuthority);
    }

    function setOwner(address pause, address owner) public {
        PauseLike(pause).setOwner(owner);
    }

    function setProtester(address pause, address protester) public {
        PauseLike(pause).setProtester(protester);
    }

    function setDelay(address pause, uint newDelay) public {
        PauseLike(pause).setDelay(newDelay);
    }

    function setAuthorityAndDelay(
        address pause,
        address newAuthority,
        uint newDelay
    ) public {
        PauseLike(pause).setAuthority(newAuthority);
        PauseLike(pause).setDelay(newDelay);
    }

    function setDelayMultiplier(address pause, uint delayMultiplier) public {
        PauseLike(pause).setDelayMultiplier(delayMultiplier);
    }

    function setAllowance(
        address join,
        address account,
        uint allowance
    ) public {
        Setter(join).setAllowance(account, allowance);
    }

    function multiSetAllowance(
        address join,
        address[] memory accounts,
        uint[] memory allowances
    ) public {
        for (uint i = 0; i < accounts.length; i++) {
            Setter(join).setAllowance(accounts[i], allowances[i]);
        }
    }

    function mint(address token, address guy, uint wad) public {
        DSTokenLike(token).mint(guy, wad);
    }

    function burn(address token, address guy, uint wad) public {
        DSTokenLike(token).burn(guy, wad);
    }

    function setIncreasingRewardsParams(
        address target,
        uint256 baseUpdateCallerReward,
        uint256 maxUpdateCallerReward
    ) public {
        Setter(target).modifyParameters(
            "baseUpdateCallerReward",
            baseUpdateCallerReward
        );
        Setter(target).modifyParameters(
            "maxUpdateCallerReward",
            maxUpdateCallerReward
        );
    }

    function setIncreasingRewardsParamsAndAllowances(
        address target,
        address treasury,
        uint256 baseUpdateCallerReward,
        uint256 maxUpdateCallerReward,
        uint256 perBlockAllowance,
        uint256 totalAllowance
    ) public {
        Setter(target).modifyParameters(
            "baseUpdateCallerReward",
            baseUpdateCallerReward
        );
        Setter(target).modifyParameters(
            "maxUpdateCallerReward",
            maxUpdateCallerReward
        );
        Setter(treasury).setPerBlockAllowance(target, perBlockAllowance);
        Setter(treasury).setTotalAllowance(target, totalAllowance);
    }

    function setMinDesiredCollateralizationRatio(
        address target,
        bytes32 collateralType,
        uint256 cRatio
    ) public {
        Setter(target).setMinDesiredCollateralizationRatio(
            collateralType,
            cRatio
        );
    }

    function updateResult(address target, uint256 result) public {
        Setter(target).updateResult(result);
    }

    function transferTokenOut(address target, address dst, uint256 wad) public {
        Setter(target).transferTokenOut(dst, wad);
    }


    function updateRate(address target, uint256 wad) public {
        Setter(target).updateRate(wad);
    }   
}