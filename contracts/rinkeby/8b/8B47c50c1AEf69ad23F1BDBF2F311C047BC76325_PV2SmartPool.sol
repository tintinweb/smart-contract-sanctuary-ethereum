// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;

pragma solidity ^0.8.9;

import "../interfaces/IPV2SmartPool.sol";
import "../interfaces/IBPool.sol";
import "../PCToken.sol";
import "../ReentryProtection.sol";

import "../libraries/LibSafeApprove.sol";

import {PBasicSmartPoolStorage as PBStorage} from "../storage/PBasicSmartPoolStorage.sol";
import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";
import {PCappedSmartPoolStorage as PCSStorage} from "../storage/PCappedSmartPoolStorage.sol";
import {PV2SmartPoolStorage as P2Storage} from "../storage/PV2SmartPoolStorage.sol";

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

contract PV2SmartPool is PCToken, ReentryProtection {
  using LibSafeApprove for IERC20;

  bool setCutable = true;

  modifier onlyOnce() {
    require(LibDiamond.contractOwner() == address(0) || LibDiamond.contractOwner() == msg.sender, "Diamond not setCutable.");
    _;
  }

  // constructor (address _diamondCutFacet, address _contractOwner) {
  //   LibDiamond.setContractOwner(_contractOwner);
  //   // Add the diamondCut external function from the diamondCutFacet
  //   IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
  //   bytes4[] memory functionSelectors = new bytes4[](1);
  //   functionSelectors[0] = IDiamondCut.diamondCut.selector;
  //   cut[0] = IDiamondCut.FacetCut({
  //       facetAddress: _diamondCutFacet,
  //       action: IDiamondCut.FacetCutAction.Add,
  //       functionSelectors: functionSelectors
  //   });
  //   LibDiamond.diamondCut(cut, address(0), "");
  // }

  function setCut (address _diamondCutFacet, address _contractOwner) public onlyOnce {
    LibDiamond.setContractOwner(_contractOwner);
    // Add the diamondCut external function from the diamondCutFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = IDiamondCut.diamondCut.selector;
    cut[0] = IDiamondCut.FacetCut({
        facetAddress: _diamondCutFacet,
        action: IDiamondCut.FacetCutAction.Add,
        functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");
    setCutable = false;
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    bytes memory bytesArray = new bytes(64);
    for (i = 0; i < bytesArray.length; i++) {

        uint8 _f = uint8(_bytes32[i/2] & 0x0f);
        uint8 _l = uint8(_bytes32[i/2] >> 4);

        bytesArray[i] = toByte(_f);
        i = i + 1;
        bytesArray[i] = toByte(_l);
    }
    return string(bytesArray);
  }

  function toByte(uint8 _uint8) public pure returns (bytes1) {
    if(_uint8 < 10) {
        return bytes1(_uint8 + 48);
    } else {
        return bytes1(_uint8 + 87);
    }
  }

  function append(string memory a, string memory b) internal pure returns (string memory) {

    return string(abi.encodePacked(a, b));

  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    // get diamond storage
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
    string memory converted = bytes32ToString(msg.sig);
    require(facet != address(0), append("Diamond: Function does not exist, sig:", converted));
    // Execute external function from facet using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
        // execute function call using the facet
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
        case 0 {
            revert(0, returndatasize())
        }
        default {
            return(0, returndatasize())
        }
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.9;

import "../interfaces/IERC20.sol";
import {PV2SmartPoolStorage as P2Storage} from "../storage/PV2SmartPoolStorage.sol";

interface IPV2SmartPool is IERC20 {
  /**
    @notice Initialise smart pool. Can only be called once
    @param _bPool Address of the underlying bPool
    @param _name Token name
    @param _symbol Token symbol (ticker)
    @param _initialSupply Initial token supply
  */
  function init(
    address _bPool,
    string memory _name,
    string memory _symbol,
    uint256 _initialSupply
  ) external;

  function setCut(
    address _diamondCutFacet,
    address _contractOwner
  ) external;

  /**
    @notice Set the address that can set public swap enabled or disabled. 
    Can only be called by the controller
    @param _swapSetter Address of the new swapSetter
  */
  function setPublicSwapSetter(address _swapSetter) external;

  /**
    @notice Set the address that can bind, unbind and rebind tokens.
    Can only be called by the controller
    @param _tokenBinder Address of the new token binder
  */
  function setTokenBinder(address _tokenBinder) external;

  /**
    @notice Enable or disable trading on the underlying balancer pool.
    Can only be called by the public swap setter
    @param _public Wether public swap is enabled or not
  */
  function setPublicSwap(bool _public) external;

  /**
    @notice Set the swap fee. Can only be called by the controller
    @param _swapFee The new swap fee. 10**18 == 100%. Max 10%
  */
  function setSwapFee(uint256 _swapFee) external;

  /**
    @notice Set the totalSuppy cap. Can only be called by the controller
    @param _cap New cap
  */
  function setCap(uint256 _cap) external;

  /**
    @notice Set the annual fee. Can only be called by the controller
    @param _newFee new fee 10**18 == 100% per 365 days. Max 10%
  */
  function setAnnualFee(uint256 _newFee) external;

  /**
    @notice Charge the outstanding annual fee
  */
  function chargeOutstandingAnnualFee() external;

  /**
    @notice Set the address that receives the annual fee. Can only be called by the controller
  */
  function setFeeRecipient(address _newRecipient) external;

  /**
    @notice Set the controller address. Can only be called by the current address
    @param _controller Address of the new controller
  */
  function setController(address _controller) external;

  /**
    @notice Set the circuit breaker address. Can only be called by the controller
    @param _newCircuitBreaker Address of the new circuit breaker
  */
  function setCircuitBreaker(address _newCircuitBreaker) external;

  /**
    @notice Enable or disable joining and exiting
    @param _newValue enabled or not
  */
  function setJoinExitEnabled(bool _newValue) external;

  /**
    @notice Trip the circuit breaker which disabled exit, join and swaps
  */
  function tripCircuitBreaker() external;

  /**
    @notice Update the weight of a token. Can only be called by the controller
    @param _token Token to adjust the weight of
    @param _newWeight New denormalized weight
  */
  function updateWeight(address _token, uint256 _newWeight) external;

  /** 
    @notice Gradually adjust the weights of a token. Can only be called by the controller
    @param _newWeights Target weights
    @param _startBlock Block to start weight adjustment
    @param _endBlock Block to finish weight adjustment
  */
  function updateWeightsGradually(
    uint256[] calldata _newWeights,
    uint256 _startBlock,
    uint256 _endBlock
  ) external;

  /**
    @notice Poke the weight adjustment
  */
  function pokeWeights() external;

  /**
    @notice Apply the adding of a token. Can only be called by the controller
  */
  function applyAddToken() external;

  /** 
    @notice Commit a token to be added. Can only be called by the controller
    @param _token Address of the token to add
    @param _balance Amount of token to add
    @param _denormalizedWeight Denormalized weight
  */
  function commitAddToken(
    address _token,
    uint256 _balance,
    uint256 _denormalizedWeight
  ) external;

  /**
    @notice Remove a token from the smart pool. Can only be called by the controller
    @param _token Address of the token to remove
  */
  function removeToken(address _token) external;

  /**
    @notice Approve bPool to pull tokens from smart pool
  */
  function approveTokens() external;

  /** 
    @notice Mint pool tokens, locking underlying assets
    @param _amount Amount of pool tokens
  */
  function joinPool(uint256 _amount) external;

  /**
    @notice Mint pool tokens, locking underlying assets. With front running protection
    @param _amount Amount of pool tokens
    @param _maxAmountsIn Maximum amounts of underlying assets
  */
  function joinPool(uint256 _amount, uint256[] calldata _maxAmountsIn) external;

  /**
    @notice Burn pool tokens and redeem underlying assets
    @param _amount Amount of pool tokens to burn
  */
  function exitPool(uint256 _amount) external;

  /**
    @notice Burn pool tokens and redeem underlying assets. With front running protection
    @param _amount Amount of pool tokens to burn
    @param _minAmountsOut Minimum amounts of underlying assets
  */
  function exitPool(uint256 _amount, uint256[] calldata _minAmountsOut) external;

  /**
    @notice Join with a single asset, given amount of token in
    @param _token Address of the underlying token to deposit
    @param _amountIn Amount of underlying asset to deposit
    @param _minPoolAmountOut Minimum amount of pool tokens to receive
  */
  function joinswapExternAmountIn(
    address _token,
    uint256 _amountIn,
    uint256 _minPoolAmountOut
  ) external returns (uint256);

  /**
    @notice Join with a single asset, given amount pool out
    @param _token Address of the underlying token to deposit
    @param _amountOut Amount of pool token to mint
    @param _maxAmountIn Maximum amount of underlying asset
  */
  function joinswapPoolAmountOut(
    address _token,
    uint256 _amountOut,
    uint256 _maxAmountIn
  ) external returns (uint256 tokenAmountIn);

  /**
    @notice Exit with a single asset, given pool amount in
    @param _token Address of the underlying token to withdraw
    @param _poolAmountIn Amount of pool token to burn
    @param _minAmountOut Minimum amount of underlying asset to withdraw
  */
  function exitswapPoolAmountIn(
    address _token,
    uint256 _poolAmountIn,
    uint256 _minAmountOut
  ) external returns (uint256 tokenAmountOut);

  /**
    @notice Exit with a single asset, given token amount out
    @param _token Address of the underlying token to withdraw
    @param _tokenAmountOut Amount of underlying asset to withdraw
    @param _maxPoolAmountIn Maximimum pool amount to burn
  */
  function exitswapExternAmountOut(
    address _token,
    uint256 _tokenAmountOut,
    uint256 _maxPoolAmountIn
  ) external returns (uint256 poolAmountIn);

  /**
    @notice Exit pool, ignoring some tokens
    @param _amount Amount of pool tokens to burn
    @param _lossTokens Addresses of tokens to ignore
  */
  function exitPoolTakingloss(uint256 _amount, address[] calldata _lossTokens) external;

  /**
    @notice Bind(add) a token to the pool
    @param _token Address of the token to bind
    @param _balance Amount of token to bind
    @param _denorm Denormalised weight
  */
  function bind(
    address _token,
    uint256 _balance,
    uint256 _denorm
  ) external;

  /**
    @notice Rebind(adjust) a token's weight or amount
    @param _token Address of the token to rebind
    @param _balance New token amount
    @param _denorm New denormalised weight
  */
  function rebind(
    address _token,
    uint256 _balance,
    uint256 _denorm
  ) external;

  /**
    @notice Unbind(remove) a token from the smart pool
    @param _token Address of the token to unbind
  */
  function unbind(address _token) external;

  /**
    @notice Get the controller address
    @return Address of the controller
  */
  function getController() external view returns (address);

  /**
    @notice Get the public swap setter address
    @return Address of the public swap setter
  */
  function getPublicSwapSetter() external view returns (address);

  /**
    @notice Get the address of the token binder
    @return Token binder address
  */
  function getTokenBinder() external view returns (address);

  /**
    @notice Get the circuit breaker address
    @return Circuit breaker address
  */
  function getCircuitBreaker() external view returns (address);

  /**
    @notice Get if public trading is enabled or not
    @return Enabled or not
  */
  function isPublicSwap() external view returns (bool);

  /** 
    @notice Get the current tokens in the smart pool
    @return Addresses of the tokens in the smart pool
  */
  function getTokens() external view returns (address[] memory);

  /**
    @notice Get the totalSupply cap
    @return The totalSupply cap
  */
  function getCap() external view returns (uint256);

  /**
    @notice Get the annual fee
    @return the annual fee
  */
  function getAnnualFee() external view returns (uint256);

  /**
    @notice Get the address receiving the fees
    @return Fee recipient address
  */
  function getFeeRecipient() external view returns (address);

  /**
    @notice Get the denormalized weight of a token
    @param _token Address of the token
    @return The denormalised weight of the token
  */
  function getDenormalizedWeight(address _token) external view returns (uint256);

  /**
    @notice Get all denormalized weights
    @return weights Denormalized weights
  */
  function getDenormalizedWeights() external view returns (uint256[] memory weights);

  /**
    @notice Get the target weights
    @return weights Target weights
  */
  function getNewWeights() external view returns (uint256[] memory weights);

  /**
    @notice Get weights at start of weight adjustment
    @return weights Start weights
  */
  function getStartWeights() external view returns (uint256[] memory weights);

  /**
    @notice Get start block of weight adjustment
    @return Start block
  */
  function getStartBlock() external view returns (uint256);

  /**
    @notice Get end block of weight adjustment
    @return End block
  */
  function getEndBlock() external view returns (uint256);

  /**
    @notice Get new token being added
    @return New token
  */
  function getNewToken() external view returns (P2Storage.NewToken memory);

  /**
    @notice Get if joining and exiting is enabled
    @return Enabled or not
  */
  function getJoinExitEnabled() external view returns (bool);

  /**
    @notice Get the underlying Balancer pool address
    @return Address of the underlying Balancer pool
  */
  function getBPool() external view returns (address);

  /**
    @notice Get the swap fee
    @return Swap fee
  */
  function getSwapFee() external view returns (uint256);

  /**
    @notice Calculate the amount of underlying needed to mint a certain amount
    @return tokens Addresses of the underlying tokens
    @return amounts Amounts of the underlying tokens
  */
  function calcTokensForAmount(uint256 _amount)
    external
    view
    returns (address[] memory tokens, uint256[] memory amounts);

  /**
    @notice Calculate the amount of pool tokens out given underlying in
    @param _token Underlying asset to deposit
    @param _amount Amount of underlying asset to deposit
    @return Pool amount out
  */
  function calcPoolOutGivenSingleIn(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  /**
    @notice Calculate underlying deposit amount given pool amount out
    @param _token Underlying token to deposit
    @param _amount Amount of pool out
    @return Underlying asset deposit amount
  */
  function calcSingleInGivenPoolOut(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  /**
    @notice Calculate underlying amount out given pool amount in
    @param _token Address of the underlying token to withdraw
    @param _amount Pool amount to burn
    @return Amount of underlying to withdraw
  */
  function calcSingleOutGivenPoolIn(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  /**
    @notice Calculate pool amount in given underlying input
    @param _token Address of the underlying token to withdraw
    @param _amount Underlying output amount
    @return Pool burn amount
  */
  function calcPoolInGivenSingleOut(address _token, uint256 _amount)
    external
    view
    returns (uint256);
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBPool {
  function isBound(address token) external view returns (bool);

  function getBalance(address token) external view returns (uint256);

  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function setSwapFee(uint256 swapFee) external;

  function setPublicSwap(bool _public) external;

  function bind(
    address token,
    uint256 balance,
    uint256 denorm
  ) payable external;

  function unbind(address token) external;

  function getDenormalizedWeight(address token) external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory);

  function setController(address manager) external;

  function isPublicSwap() external view returns (bool);

  function getSwapFee() external view returns (uint256);

  function gulp(address token) external;

  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) external pure returns (uint256 poolAmountOut);

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);

  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountOut);

  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 poolAmountIn);
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {PCTokenStorage as PCStorage} from "./storage/PCTokenStorage.sol";
import "./libraries/LibPoolToken.sol";
import "./libraries/Math.sol";
import "./interfaces/IERC20.sol";


// Highly opinionated token implementation
// Based on the balancer Implementation

contract PCToken {
  using Math for uint256;

  event Approval(address indexed _src, address indexed _dst, uint256 _amount);
  event Transfer(address indexed _src, address indexed _dst, uint256 _amount);

  uint8 public constant decimals = 18;

  function _mint(uint256 _amount) internal {
    LibPoolToken._mint(address(this), _amount);
  }

  function _burn(uint256 _amount) internal {
    LibPoolToken._burn(address(this), _amount);
  }

  function _move(
    address _src,
    address _dst,
    uint256 _amount
  ) internal {
    PCStorage.StorageStruct storage s = PCStorage.load();
    require(s.balance[_src] >= _amount, "ERR_INSUFFICIENT_BAL");
    s.balance[_src] = s.balance[_src].bsub(_amount);
    s.balance[_dst] = s.balance[_dst].badd(_amount);
    emit Transfer(_src, _dst, _amount);
  }

  function _push(address _to, uint256 _amount) internal {
    _move(address(this), _to, _amount);
  }

  function _pull(address _from, uint256 _amount) internal {
    _move(_from, address(this), _amount);
  }

  function allowance(address _src, address _dst) external view returns (uint256) {
    return PCStorage.load().allowance[_src][_dst];
  }

  function balanceOf(address _whom) external view returns (uint256) {
    return PCStorage.load().balance[_whom];
  }

  function totalSupply() public view returns (uint256) {
    return PCStorage.load().totalSupply;
  }

  function name() external view returns (string memory) {
    return PCStorage.load().name;
  }

  function symbol() external view returns (string memory) {
    return PCStorage.load().symbol;
  }

  function approve(address _dst, uint256 _amount) external returns (bool) {
    PCStorage.load().allowance[msg.sender][_dst] = _amount;
    emit Approval(msg.sender, _dst, _amount);
    return true;
  }

  function increaseApproval(address _dst, uint256 _amount) external returns (bool) {
    PCStorage.StorageStruct storage s = PCStorage.load();
    s.allowance[msg.sender][_dst] = s.allowance[msg.sender][_dst].badd(_amount);
    emit Approval(msg.sender, _dst, s.allowance[msg.sender][_dst]);
    return true;
  }

  function decreaseApproval(address _dst, uint256 _amount) external returns (bool) {
    PCStorage.StorageStruct storage s = PCStorage.load();
    uint256 oldValue = s.allowance[msg.sender][_dst];
    if (_amount > oldValue) {
      s.allowance[msg.sender][_dst] = 0;
    } else {
      s.allowance[msg.sender][_dst] = oldValue.bsub(_amount);
    }
    emit Approval(msg.sender, _dst, s.allowance[msg.sender][_dst]);
    return true;
  }

  function transfer(address _dst, uint256 _amount) external returns (bool) {
    _move(msg.sender, _dst, _amount);
    return true;
  }

  function transferFrom(
    address _src,
    address _dst,
    uint256 _amount
  ) external returns (bool) {
    PCStorage.StorageStruct storage s = PCStorage.load();
    require(
      msg.sender == _src || _amount <= s.allowance[_src][msg.sender],
      "ERR_PCTOKEN_BAD_CALLER"
    );
    _move(_src, _dst, _amount);
    if (msg.sender != _src && s.allowance[_src][msg.sender] != type(uint).max) {
      s.allowance[_src][msg.sender] = s.allowance[_src][msg.sender].bsub(_amount);
      emit Approval(msg.sender, _dst, s.allowance[_src][msg.sender]);
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ReentryProtectionStorage as RPStorage} from "./storage/ReentryProtectionStorage.sol";

contract ReentryProtection {

  modifier noReentry {
    // Use counter to only write to storage once
    RPStorage.StorageStruct storage s = RPStorage.load();
    s.lockCounter++;
    uint256 lockValue = s.lockCounter;
    _;
    require(lockValue == s.lockCounter, "ReentryProtection.noReentry: reentry detected");
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/IERC20.sol";

library LibSafeApprove {
    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal {
        uint256 currentAllowance = _token.allowance(address(this), _spender);

        // Do nothing if allowance is already set to this value
        if(currentAllowance == _amount) {
            return;
        }

        // If approval is not zero reset it to zero first
        if(currentAllowance != 0) {
            _token.approve(_spender, 0);
        }

        // do the actual approval
        _token.approve(_spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/IBPool.sol";

library PBasicSmartPoolStorage {
  bytes32 public constant pbsSlot = keccak256("PBasicSmartPool.storage.location");

  struct StorageStruct {
    IBPool bPool;
    address controller;
    address publicSwapSetter;
    address tokenBinder;
  }

  /**
        @notice Load PBasicPool storage
        @return s Pointer to the storage struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = pbsSlot;
    assembly {
      s.slot := loc
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library PCTokenStorage {
  bytes32 public constant ptSlot = keccak256("PCToken.storage.location");
  struct StorageStruct {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) allowance;
  }

  /**
        @notice Load pool token storage
        @return s Storage pointer to the pool token struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = ptSlot;
    assembly {
      s.slot := loc
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library PCappedSmartPoolStorage {
  bytes32 public constant pcsSlot = keccak256("PCappedSmartPool.storage.location");

  struct StorageStruct {
    uint256 cap;
  }

  /**
        @notice Load PBasicPool storage
        @return s Pointer to the storage struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = pcsSlot;
    assembly {
      s.slot := loc
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library PV2SmartPoolStorage {
  bytes32 public constant pasSlot = keccak256("PV2SmartPoolStorage.storage.location");

  struct StorageStruct {
    uint256 startBlock;
    uint256 endBlock;
    uint256[] startWeights;
    uint256[] newWeights;
    NewToken newToken;
    bool joinExitEnabled;
    uint256 annualFee;
    uint256 lastAnnualFeeClaimed;
    address feeRecipient;
    address circuitBreaker;
  }

  struct NewToken {
    address addr;
    bool isCommitted;
    uint256 balance;
    uint256 denorm;
    uint256 commitBlock;
  }

  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = pasSlot;
    assembly {
      s.slot := loc
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        require(msg.sender == diamondStorage().contractOwner || diamondStorage().contractOwner == address(0), "LibDiamond: Must be contract owner");
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address _whom) external view returns (uint256);

  function allowance(address _src, address _dst) external view returns (uint256);

  function approve(address _dst, uint256 _amount) external returns (bool);

  function transfer(address _dst, uint256 _amount) external returns (bool);

  function transferFrom(
    address _src,
    address _dst,
    uint256 _amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {PCTokenStorage as PCStorage} from "../storage/PCTokenStorage.sol";
import "../libraries/Math.sol";
import "../interfaces/IERC20.sol";

library LibPoolToken {
  using Math for uint256;

  event Transfer(address indexed _src, address indexed _dst, uint256 _amount);

  function _mint(address _to, uint256 _amount) internal {
    PCStorage.StorageStruct storage s = PCStorage.load();
    s.balance[_to] = s.balance[_to].badd(_amount);
    s.totalSupply = s.totalSupply.badd(_amount);
    emit Transfer(address(0), _to, _amount);
  }

  function _burn(address _from, uint256 _amount) internal {
    PCStorage.StorageStruct storage s = PCStorage.load();
    require(s.balance[_from] >= _amount, "ERR_INSUFFICIENT_BAL");
    s.balance[_from] = s.balance[_from].bsub(_amount);
    s.totalSupply = s.totalSupply.bsub(_amount);
    emit Transfer(_from, address(0), _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Math {
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;

  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  // Add two numbers together checking for overflows
  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  // subtract two numbers and return diffecerence when it underflows
  function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  // Subtract two numbers checking for underflows
  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  // Multiply two 18 decimals numbers
  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  // Overflow protected multiplication
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "Math: multiplication overflow");

    return c;
  }

  // Divide two 18 decimals numbers
  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }

  // Overflow protected division
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "Division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  // DSMath.wpow
  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;

    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);

      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
    require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);

    uint256 wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    // term 0:
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;

      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }

    return sum;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library ReentryProtectionStorage {
  bytes32 public constant rpSlot = keccak256("ReentryProtection.storage.location");
  struct StorageStruct {
    uint256 lockCounter;
  }

  /**
        @notice Load pool token storage
        @return s Storage pointer to the pool token struct
    */
  function load() internal pure returns (StorageStruct storage s) {
    bytes32 loc = rpSlot;
    assembly {
      s.slot := loc
    }
  }
}