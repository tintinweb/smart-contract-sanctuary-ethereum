pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

///@title Frens Merkle Prover
///@author 0xWildhare and the Frens team
///@dev this gives the Frens Multisig a way to mark a pool as exiting (and then no longer charge fees) This should be replaced by a decentralized alternative

import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensOracle.sol";
import "./interfaces/IFrensStorage.sol";

contract FrensOracle is IFrensOracle {

    //sets a validator public key (which is associated with a pool) as exiting
    mapping(bytes => bool) public isExiting;

    IFrensStorage frensStorage;

    constructor(IFrensStorage frensStorage_) {
        frensStorage = frensStorage_;
    }

    ///@dev called by the staking pool to check if the validator is exiting
    function checkValidatorState(address poolAddress) external returns(bool) {
        IStakingPool pool = IStakingPool(poolAddress);
        bytes memory pubKey = pool.pubKey();
        if(isExiting[pubKey]){
            pool.exitPool();
        }
        return isExiting[pubKey];
    }

    ///@dev allows multisig (guardian) to set a pool as exiting. 
   function setExiting(bytes memory pubKey, bool _isExiting) external {
        require(msg.sender == frensStorage.getGuardian(), "must be guardian");
        isExiting[pubKey] = _isExiting;
   }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IFrensArt.sol";

interface IStakingPool {

    function pubKey() external view returns(bytes memory);

    function depositForId(uint _id) external view returns (uint);

    function totalDeposits() external view returns(uint);

    function transferLocked() external view returns(bool);

    function locked(uint id) external view returns(bool);

    function artForPool() external view returns (IFrensArt);

    function owner() external view returns (address);

    function depositToPool() external payable;

    function addToDeposit(uint _id) external payable;

    function withdraw(uint _id, uint _amount) external;

    function claim(uint id) external;

    function getIdsInThisPool() external view returns(uint[] memory);

    function getShare(uint _id) external view returns (uint);

    function getDistributableShare(uint _id) external view returns (uint);

    function rageQuitInfo(uint id) external view returns(uint, uint, bool);

    function setPubKey(
        bytes calldata pubKey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external;

    function getState() external view returns (string memory);

    // function getDepositAmount(uint _id) external view returns(uint);

    function stake(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external;

    function stake() external;

    function exitPool() external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


interface IFrensOracle {

   function checkValidatorState(address pool) external returns(bool);

   function setExiting(bytes memory pubKey, bool isExiting) external;

}

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

   
    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;
    function burnKeys() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getBool(bytes32 _key) external view returns (bool);   

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setBool(bytes32 _key, bool _value) external;    

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;    

    // Arithmetic 
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensArt {
  function renderTokenById(uint256 id) external view returns (string memory);
}