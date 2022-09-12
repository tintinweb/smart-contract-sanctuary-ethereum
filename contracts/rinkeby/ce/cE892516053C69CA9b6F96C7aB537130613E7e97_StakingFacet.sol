// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155TokenReceiver.sol";


contract StakingFacet {
    AppStorage internal s;
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event PoolTokensRate(uint256 _newRate);



    function frens(address _account) public view returns (uint256 frens_) {
        Account storage account = s.accounts[_account];        ///////////////////////////////////////////
        uint256 timePeriod = block.timestamp - account.lastFrensUpdate;
        frens_ = account.frens;
        // 86400 the number of seconds in 1 day        
        frens_ += ((account.poolTokens * s.poolTokensRate) * timePeriod) / 24 hours;        
    }

    function bulkFrens(address[] calldata _accounts) external view returns (uint256[] memory frens_) {
        frens_ = new uint256[](_accounts.length);
        for (uint256 i; i < _accounts.length; i++) {
            frens_[i] = frens(_accounts[i]);
        }
    }

    function updateFrens() internal {        
        Account storage account = s.accounts[tx.origin];
        account.frens = frens(tx.origin);           //////////////////////////////////////
        account.lastFrensUpdate = uint40(block.timestamp);
    }

    function updateAccounts(address[] calldata _accounts) external {
        LibDiamond.enforceIsContractOwner();
        for (uint256 i; i < _accounts.length; i++) {
            address accountAddress = _accounts[i];
            Account storage account = s.accounts[accountAddress];
            account.frens = frens(accountAddress);
            account.lastFrensUpdate = uint40(block.timestamp);
        }
    }

    function updatePoolTokensRate(uint256 _newRate) external {
        LibDiamond.enforceIsContractOwner();
        s.poolTokensRate = _newRate;
        emit PoolTokensRate(_newRate);
    }

    function poolTokensRate() external view returns (uint256) {
        return s.poolTokensRate;
    }
    
    function migrateFrens(address[] calldata _stakers, uint256[] calldata _frens) external {
        LibDiamond.enforceIsContractOwner();
        require(_stakers.length == _frens.length, "StakingFacet: stakers not same length as frens");
        for (uint256 i; i < _stakers.length; i++) {
            Account storage account = s.accounts[_stakers[i]];
            account.frens = uint104(_frens[i]);
            account.lastFrensUpdate = uint40(block.timestamp);
        }
    }

    function switchFrens(address _old, address _new) external {
        LibDiamond.enforceIsContractOwner();
        Account storage oldAccount = s.accounts[_old];
        Account storage newAccount = s.accounts[_new];
        (oldAccount.frens, newAccount.frens) = (newAccount.frens, oldAccount.frens);
        oldAccount.lastFrensUpdate = uint40(block.timestamp);
        newAccount.lastFrensUpdate = uint40(block.timestamp);
    }
    

    function stakePoolTokens(uint256 _poolTokens) external {
        updateFrens();        
        Account storage account = s.accounts[tx.origin];        
        account.poolTokens += _poolTokens;                
        IERC20(s.poolContract).transferFrom(tx.origin, address(this), _poolTokens);
    }



    function staked(address _account)
        external
        view
        returns (
            uint256 poolTokens_
        )
    {
        poolTokens_ = s.accounts[_account].poolTokens;
    }
    

    function withdrawPoolStake(uint256 _poolTokens) external {
        updateFrens();        
        uint256 accountPoolTokens = s.accounts[tx.origin].poolTokens;
        require(accountPoolTokens >= _poolTokens, "Can't withdraw more poolTokens than in account");
        s.accounts[tx.origin].poolTokens = accountPoolTokens - _poolTokens;
        IERC20(s.poolContract).transfer(tx.origin, _poolTokens);
    }
    
    function claimTickets(uint256[] calldata _ids, uint256[] calldata _values) external {
        require(_ids.length == _values.length, "Staking: _ids not the same length as _values");
        updateFrens();    
        uint256 frensBal = s.accounts[tx.origin].frens;
        // gas optimization
        unchecked {            
            for (uint256 i; i < _ids.length; i++) {
                uint256 id = _ids[i];
                uint256 value = _values[i];
                require(id < 6, "Staking: Ticket not found");
                uint256 l_ticketCost = ticketCost(id);
                uint256 cost = l_ticketCost * value;            
                require(frensBal >= cost, "Staking: Not enough frens points");
                frensBal -= cost;
                s.tickets[id].accountBalances[tx.origin] += value;
                s.tickets[id].totalSupply += uint96(value);
            }
        }
        s.accounts[tx.origin].frens = frensBal;
        emit TransferBatch(tx.origin, address(0), tx.origin, _ids, _values);
        uint256 size;
        address sender = tx.origin;
        assembly {
            size := extcodesize(sender)
        }
        if (size > 0) {
            require(
                ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(tx.origin).onERC1155BatchReceived(tx.origin, address(0), _ids, _values, new bytes(0)),
                "Staking: Ticket transfer rejected/failed"
            );
        }
    }

    function ticketCost(uint256 _id) public pure returns (uint256 _frensCost) {
        if (_id == 0) {
            _frensCost = 50e18;
        } else if (_id == 1) {
            _frensCost = 250e18;
        } else if (_id == 2) {
            _frensCost = 500e18;
        } else if (_id == 3) {
            _frensCost = 2_500e18;
        } else if (_id == 4) {
            _frensCost = 10_000e18;
        } else if (_id == 5) {
            _frensCost = 50_000e18;
        } else {
            revert("Staking: _id does not exist");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import "../interfaces/IDiamondCut.sol";

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

struct Account {
    // spender => amount    
    mapping(address => bool) ticketsApproved;    
    uint40 lastFrensUpdate;    
    uint256 poolTokens;
    uint256 frens;    
}



struct AppStorage {
    mapping(address => Account) accounts;
    mapping(uint256 => Ticket) tickets;    
    address poolContract;
    string ticketsBaseUri;    
    uint256 poolTokensRate;
    address marketPlaceDiamond ;
}
struct Ticket {
    // user address => balance
    mapping(address => uint256) accountBalances;
    uint256 totalSupply;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

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