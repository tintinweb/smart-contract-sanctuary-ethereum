// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Facet} from '../interfaces/IERC20Facet.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {LibERC20Storage} from '../libraries/LibERC20Storage.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LibERC20} from '../libraries/LibERC20.sol';

contract ERC20Facet is IERC20, IERC20Facet{
   function initialize(
      uint256 _initSupply,
      string memory _name,
      string memory _symbol
   ) external override {
      LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
      LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

      require(bytes(es.name).length == 0 && bytes(es.symbol).length == 0, 'Already Initialized');
      require(bytes(_name).length != 0 && bytes(_symbol).length != 0, 'Invalid params');

      require(msg.sender == ds.contractOwner, 'not Owner');

      LibERC20.mint(msg.sender, _initSupply);

      es.name = _name;
      es.symbol = _symbol;
   }

   modifier protectedCall() {
      require(
         msg.sender == LibDiamond.diamondStorage().contractOwner ||
         msg.sender == address(this), "NOT_ALLOWED"
      );
      _;
   }

   function name() external view override returns (string memory) {
      return LibERC20Storage.erc20Storage().name;
   }

   function setName(string calldata _name) external override protectedCall {
      LibERC20Storage.erc20Storage().name = _name;
   }

   function symbol() external view override returns (string memory) {
      return LibERC20Storage.erc20Storage().symbol;
   }

   function setSymbol(string calldata _symbol) external override protectedCall {
      LibERC20Storage.erc20Storage().symbol = _symbol;
   }

   function decimals() external pure override returns (uint8) {
      return 18;
   }

   function mint(address _receiver, uint256 _amount) external override protectedCall {
      LibERC20.mint(_receiver, _amount);
   }

   function burn(address _from, uint256 _amount) external override protectedCall {
      LibERC20.burn(_from, _amount);
   }

   function approve(address _spender, uint256 _amount)
   external
   override
   returns (bool)
   {
      require(_spender != address(0), "SPENDER_INVALID");
      LibERC20Storage.erc20Storage().allowances[msg.sender][_spender] = _amount;
      emit Approval(msg.sender, _spender, _amount);
      return true;
   }

   function increaseApproval(address _spender, uint256 _amount) external override returns (bool) {
      require(_spender != address(0), "SPENDER_INVALID");
      LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
      es.allowances[msg.sender][_spender] += _amount;
      emit Approval(msg.sender, _spender, es.allowances[msg.sender][_spender]);
      return true;
   }

   function decreaseApproval(address _spender, uint256 _amount) external override returns (bool) {
      require(_spender != address(0), "SPENDER_INVALID");
      LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
      uint256 oldValue = es.allowances[msg.sender][_spender];
      if (_amount > oldValue) {
         es.allowances[msg.sender][_spender] = 0;
      } else {
         es.allowances[msg.sender][_spender] = oldValue - _amount;
      }
      emit Approval(msg.sender, _spender, es.allowances[msg.sender][_spender]);
      return true;
   }

   function transfer(address _to, uint256 _amount)
   external
   override
   returns (bool)
   {
      _transfer(msg.sender, _to, _amount);
      return true;
   }

   function transferFrom(
      address _from,
      address _to,
      uint256 _amount
   ) external override returns (bool) {
      LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
      require(_from != address(0), "FROM_INVALID");

      // Update approval if not set to max uint256
      if (es.allowances[_from][msg.sender] > 0) {
         uint256 newApproval = es.allowances[_from][msg.sender] - _amount;
         es.allowances[_from][msg.sender] = newApproval;
         emit Approval(_from, msg.sender, newApproval);
      }

      _transfer(_from, _to, _amount);
      return true;
   }

   function allowance(address _owner, address _spender)
   external
   view
   override
   returns (uint256)
   {
      return LibERC20Storage.erc20Storage().allowances[_owner][_spender];
   }

   function balanceOf(address _of) external view override returns (uint256) {
      return LibERC20Storage.erc20Storage().balances[_of];
   }

   function totalSupply() external view override returns (uint256) {
      return LibERC20Storage.erc20Storage().totalSupply;
   }

   function _transfer(
      address _from,
      address _to,
      uint256 _amount
   ) internal {
      LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

      es.balances[_from] -= _amount;
      es.balances[_to] += _amount;

      emit Transfer(_from, _to, _amount);
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Facet {

    /**
        @notice Get the token name
        @return The token name
    */
    function name() external view returns (string memory);

    /**
        @notice Get the token symbol
        @return The token symbol
    */
    function symbol() external view returns (string memory);

    /**
        @notice Get the amount of decimals
        @return Amount of decimals
    */
    function decimals() external view returns (uint8);

    /**
        @notice Mints tokens. Can only be called by the contract owner or the contract itself
        @param _receiver Address receiving the tokens
        @param _amount Amount to mint
    */
    function mint(address _receiver, uint256 _amount) external;

    /**
        @notice Burns tokens. Can only be called by the contract owner or the contract itself
        @param _from Address to burn from
        @param _amount Amount to burn
    */
    function burn(address _from, uint256 _amount) external;

    /**
        @notice Sets up the metadata and initial supply. Can be called by the contract owner
        @param _initialSupply Initial supply of the token
        @param _name Name of the token
        @param _symbol Symbol of the token
    */
    function initialize(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) external;

    /**
        @notice Set the token name of the contract. Can only be called by the contract owner or the contract itself
        @param _name New token name
    */
    function setName(string calldata _name) external;

    /**
        @notice Set the token symbol of the contract. Can only be called by the contract owner or the contract itself
        @param _symbol New token symbol
    */
    function setSymbol(string calldata _symbol) external;

    /**
        @notice Increase the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to increase by
    */
    function increaseApproval(address _spender, uint256 _amount) external returns (bool);

    /**
        @notice Decrease the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to decrease by
    */
    function decreaseApproval(address _spender, uint256 _amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC20Storage {
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("ciety.governance.token.storage");

    struct ERC20Storage {
        string name;
        string symbol;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

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
pragma solidity ^0.8.0;

import "./LibERC20Storage.sol";

library LibERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "Invalid address");

        LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

        es.balances[_to] += _amount;
        es.totalSupply += _amount;

        emit Transfer(address(0), _to, _amount);
    }

    function burn(address _from, uint256 _amount) internal {
        LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
        es.balances[_from] -= _amount;
        es.totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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