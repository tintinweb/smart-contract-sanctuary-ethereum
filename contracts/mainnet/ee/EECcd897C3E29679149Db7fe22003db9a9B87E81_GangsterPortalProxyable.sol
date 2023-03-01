/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: 0xInuarashi

/**
 * @title Gangster Portal
 * Stake gangster all star characters into the smart contract and 
 * port them over to the Gangster Universe where you can earn
 * bounties and more!
 */

/**
 * Notes: 
 * Gangster Portal handles both ERC721 and ERC1155 and also OpenSea Storefront
 * The contracts are listed as following:
 * 
 * 50 Bosses: ERC721
 * Universe: OpenSea Storefront (ERC1155 modified)
 * Specials: ERC1155 (Supporting only 1/1s)
 * Evolutions: ERC721
 * Society (Future Compatibility): ERC721 
 *
 * Adding a collection into the Gangster Portal is possible through 
 * dynamic addres support
 * The dynamic address support supports the following schemas:
 * ERC721 - Specify Contract Address
 * ERC1155 - Specify Contract Address
 * Keep in mind that ERC1155s should only support 1/1s 
 * and otherwise will have strange behavior due to
 * the off-chain handler handling each token as `unique` instead of `non-unique`
 *
 * For this reason, a `disallowed tokenId list` 
 * is added for each ERC1155 for support of 1/1 of
 * Non-1/1 excluive collections
 */

abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    // @proxy commented out for proxy usage
    // constructor() { 
    //     owner = msg.sender; 
    //     emit OwnershipTransferred(address(0), msg.sender);
    // }

    modifier onlyOwner { 
        require(owner == msg.sender, "onlyOwner not owner!");
        _; 
    }

    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}

abstract contract Controllerable is Ownable {

    event ControllerSet(string indexed controllerType, bytes32 indexed controllerSlot, 
        address indexed controller, bool status);

    mapping(bytes32 => mapping(address => bool)) internal __controllers;

    function isController(string memory type_, address controller_) public 
    view returns (bool) {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        return __controllers[_slot][controller_];
    }

    modifier onlyController(string memory type_) {
        require(isController(type_, msg.sender), "Controllerable: Not Controller!");
        _;
    }

    function setController(string memory type_, address controller_, bool bool_) 
    public onlyOwner {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        __controllers[_slot][controller_] = bool_;
        emit ControllerSet(type_, _slot, controller_, bool_);
    }
}

interface IERC721 {
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}

interface IERC1155 {
    function safeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_,
        bytes memory data_) external;
}

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_,
        uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_,
        uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
        external returns (bytes4);
}

contract GangsterPortalProxyable is Controllerable {

    // Version 1.0.0 @ 2022-02-28

    ////////////////////////////
    ///// Proxy Initialize /////
    ////////////////////////////
    event ContractInitialized(address indexed owner_);

    bool internal initialized;

    /**
     *  @dev this function initializes the contract. it should be called
     *  on proxy creation to initialize the proxy as a replacement for 
     *  constructor functions.
     *  
     *  @param owner_ <address> sets the Ownable owner
     */
    function initialize(address owner_) public {
        require(!initialized, "Contract has already been initialized!");
        initialized = true;
        owner = owner_;
        emit ContractInitialized(owner_);
    }
    
    /**
     *  @dev initialize this contract so that it is uninitializable
     */
    constructor() { initialize(msg.sender); }

    /////////////////////
    ///// Constants /////
    /////////////////////
    address constant public OS_STORE = 0x495f947276749Ce646f68AC8c248420045cb7b5e;

    /////////////////////
    /////  Control  /////
    /////////////////////
    event StakingSet(address indexed operator_, bool indexed enabled_);

    bool public stakingIsEnabled;

    /**
     *  @dev an onlyOwner function that sets the stakingIsEnabled boolean
     *  which is used to enable staking and unstaking functionality.
     */
    function O_setStakingIsEnabled(bool enabled_) external onlyOwner {
        stakingIsEnabled = enabled_;
        emit StakingSet(msg.sender, enabled_);
    }

    ////////////////////////////
    ///// Address Registry /////
    ////////////////////////////
    event AddressRegistrationSet(address indexed contract_, bool indexed enabled_);
    event AddressTypeSet(address indexed contract_, uint256 indexed type_);

    mapping(address => bool) public addressToEnabled;
    mapping(address => uint256) public addressToType; // 1 = ERC721, 2 = ERC1155

    /**
     *  @dev controllerable function that sets a contract address to be 
     *  able to be staked. 
     *  this must be paired with C_setAddressType()
     */
    function C_setAddressEnabled(address[] calldata contracts_, bool enabled_) 
    external onlyController("REGISTRY") {
        uint256 l = contracts_.length;
        uint256 i; unchecked { do { 
            address _currContract = contracts_[i];
            addressToEnabled[_currContract] = enabled_;
            emit AddressRegistrationSet(_currContract, enabled_);
        } while (++i < l); }
    }

    /**
     *  @dev controllerable function that sets the address type to the contract address
     *  used to idenfity the type of contract between ERFC721{1} and ERC1155{2}
     *  this is used in a pair with C_setAddressEnabled()
     */
    function C_setAddressType(address[] calldata contracts_, uint256[] calldata types_)
    external onlyController("REGISTRY") {
        require(contracts_.length == types_.length,
                "Array lengths mistmach!");

        uint256 l = contracts_.length;
        uint256 i; unchecked { do {
            address _currContract = contracts_[i];
            uint256 _currType = types_[i];
            require(_currType == 1 || _currType == 2, "Unsupported Type!");
            addressToType[_currContract] = _currType;
            emit AddressTypeSet(_currContract, _currType);
        } while (++i < l); }
    }

    /**
     *  @dev this internal view function gets the contract type for the contract
     *  which does a SSTORE lookup to the mapping addressToType[x] 
     *  
     *  on uninitialized mapping location, it throws an error.
     *
     *  Possible Contract Types: 1 = ERC721, 2 = ERC1155, 3 = OpenSea Storefront
     */
    function _getContractType(address contract_) internal view returns (uint256) {
        // We compare calldata to contract data and return, this process is cheap, so
        // it is the first condition to check and return.
        if (contract_ == OS_STORE) return 3;

        // Otherwise, we do a SLOAD. The loaded data must be {1} or {2} as they are
        // the only supported types in a mapping SLOAD
        uint256 _contractType = addressToType[contract_];
        require(_contractType == 1 || _contractType == 2, "Unsupported Type!");

        return _contractType;
    }

    //////////////////////////////////
    ///// OS Storefront Registry /////
    //////////////////////////////////
    event OpenSeaTokenSet(bool indexed enabled_, uint256 tokenId_);

    mapping(uint256 => bool) public OSTokenToStakeable;

    /**
     *  @dev a controllerable function that takes in an array of opensea tokenIds
     *  used to enable an opensea token to be staked.
     *  
     *  the cost is 1 SSTORE per storage, which is mildly expensive.
     *  however, for the flexibility as well as robustness of the implementation
     *  (due to the deployer having multiple wallets or multiple opensea collections)
     *  (and also the fact that the collection is unfinished / still minting)
     *  this method is used for maximum compatibility and security.
     *
     *  requires the controllerable role "OPERATOR"
     */
    function C_setOSTokenStakeable(uint256[] calldata tokenIds_, bool enabled_) 
    external onlyController("OPERATOR") {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do { 
            OSTokenToStakeable[tokenIds_[i]] = enabled_;
            emit OpenSeaTokenSet(enabled_, tokenIds_[i]);
        } while (++i < l); }
    }

    ///////////////////////////////////////
    ///// ERC1155 Disallowed Registry /////
    ///////////////////////////////////////
    event ERC1155Disallowed(address indexed contract_, bool indexed disallowed_, 
        uint256 tokenId_);

    mapping(address => mapping(uint256 => bool)) public ERC1155ToTokenIdToDisallowed;

    /**
     *  @dev a controllerable function that sets an ERC1155 contract's tokenId to be
     *  unstakeable. 
     *
     *  this is used for collections where the ERC1155 token acts as a fungible token
     *  e.g. when the supply is > 1. 
     *
     *  for example, in GAS specials, there are 5/5 and 10/10 tokens. these are
     *  unstakeable. instead, we offer a solution to convert the 5/5 or 10/10 tokens
     *  to 1/1 versions of themselves with unique IDs instead.
     *
     *  important: this should be done before enabling a contract for staking
     */
    function C_setERC1155Unstakeable(address contract_, bool disallowed_,
    uint256[] calldata tokenIds_) external onlyController("OPERATOR") {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do { 
            ERC1155ToTokenIdToDisallowed[contract_][tokenIds_[i]] = disallowed_;
            emit ERC1155Disallowed(contract_, disallowed_, tokenIds_[i]);
        } while (++i < l); }
    }

    ////////////////////////////////////
    ///// Delegation Functionality /////
    ////////////////////////////////////
    event DelegateSet(address indexed staker_, address indexed delegate_);

    mapping(address => address) public addressToDelegate;

    /**
     *  @dev a public (external) function that allows users to set their "delegate"
     *  address which acts as the main address for rewards and staked data accumulation
     *  on-chain.
     *  
     *  in order to emit consistent events for robust back-end indexing, users will
     *  only be able to set their delegate when they have no staked balance.
     *
     *  this is so that the emitted events of TokenStaked and TokenUnstaked's "delegate_"
     *  field is always accurate to the current delegate address of the user, or
     *  the staker address assuming that they do not have a delegate address.
     *
     *  this function allows multiple wallet addresses to set a single unified
     *  address to receive rewards and points.
     */
    function setDelegate(address delegate_) external {
        require(stakerToStakedBalance[msg.sender] == 0, 
                "You must not have any staked tokens in order to delegate!");
        
        addressToDelegate[msg.sender] = delegate_;

        emit DelegateSet(msg.sender, delegate_);
    }

    /////////////////////////////////
    ///// Staking Functionality /////
    /////////////////////////////////
    event TokenStaked(address indexed staker_, address indexed delegate_, 
        address[] contracts_, uint256[] tokenIds_, uint256 unixTimestamp_);
    event TokenUnstaked(address indexed staker_, address indexed delegate_,
        address[] contracts_, uint256[] tokenIds_, uint256 unixTimestamp_);
    
    mapping(address => uint256) public stakerToStakedBalance;
    mapping(address => mapping(uint256 => address)) public contractToTokenIdToStaker;

    /**
     *  @dev an internal function that handles the transfers of different contract
     *  types with the necessary checks and calling the correct functions
     *  based on contract type.
     *
     *  contract types: 
     *      - 1: ERC721
     *      - 2: ERC1155
     *      - 3: ERC1155 (OpenSea Shared Storefront)
     */
    function _handleTransfer(address contract_, uint256 contractType_, 
    address from_, address to_, uint256 tokenId_) internal {

        // Handler for ERC721
        if (contractType_ == 1) {
            // For an ERC721, just do a normal transferFrom. This assumes expected
            // behavior of throwing on a failure of transfer.
            IERC721(contract_)
            .transferFrom(from_, to_, tokenId_);
        }

        // Handler for ERC1155
        else if (contractType_ == 2) {
            // This prevents the staking of explicitly disallowed tokens (non 1/1s)
            require(!ERC1155ToTokenIdToDisallowed[contract_][tokenId_],
                    "ERC1155 Token not supported!");

            // For ERC1155, the default method is safeTransferFrom which has a 
            // callback to the receiver which must implement ERC1155Receiver
            // if it is a contract address.
            IERC1155(contract_)
            .safeTransferFrom(from_, to_, tokenId_, 1, "");
        }

        // Handler for OS Storefront
        else if (contractType_ == 3) {
            // This prevents the staking of anything that is not explicitly labeled
            require(OSTokenToStakeable[tokenId_], 
                    "OS Token not stakeable!");

            // For ERC1155, the default method is safeTransferFrom which has a 
            // callback to the receiver which must implement ERC1155Receiver
            // if it is a contract address.
            IERC1155(contract_)
            .safeTransferFrom(from_, to_, tokenId_, 1, "");
        }

        // Sanity check that should never happen (see C_setAddressRegistration)
        else {
            revert("Unsupported contract type!");
        }
    }

    // This snippet of code is required to accept ERC1155 tokens into the contract
    // because safeTransferFrom (ERC1155) uses a forced-style callback for no good reason
    function onERC1155Received(address operator_, address from_, uint256 id_,
    uint256 amount_, bytes calldata data_) external returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address operator_, address from_,
    uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
    external returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    /**
     *  @dev the main staking body of the contract.
     *  @param contracts_ <address[]> for the contracts correspondent of each tokenId
     *  @param tokenIds_ <uint256[]> for the tokenIds correspondent of each contract
     *
     *  the staking should only be possible when `stakingisEnabled == true`
     *
     *  we loop through each contract-tokenId pair
     *  determine the contract type
     *  handle the transfer
     *  then store the token to the staker's address
     *  increase the staked balance of the staker
     *  and finally emit TokenStaked event which gets picked up by the back-end
     *  system which continues the rewards system off-chain
     */
    function stakeGangsters(address[] calldata contracts_, 
    uint256[] calldata tokenIds_) external {
        // OK: cannot stake if staking is not enabled
        require(stakingIsEnabled, "Staking is not enabled!");
        // OK: make sure contracts and tokenids have the same length
        require(contracts_.length == tokenIds_.length, "Array lengths mismatch!");

        // OK: the delegate address is always the msg.sender or the delegate
        // If the delegate address is empty, the delegate is the staker.
        address _delegate = addressToDelegate[msg.sender] == address(0) ? 
            msg.sender : addressToDelegate[msg.sender];

        // OK: loops through the arrays, checks contract eligibility and type,
        //  then does a _handleTransfer above and finally stores the token to the
        //  staker address. handled within a frankenloop.
        uint256 l = contracts_.length;
        uint256 i; unchecked { do {

            address _currContract = contracts_[i];
            uint256 _currTokenId = tokenIds_[i];

            // First, we check that the contract is valid
            // We use SLOADs here (2100|100)
            require(addressToEnabled[_currContract], "Contract Unsupported!");

            // Then, we look at the type of address
            uint256 _contractType = _getContractType(_currContract);

            // Transfer the token
            _handleTransfer(_currContract, _contractType,
                msg.sender, address(this), _currTokenId);

            // Record the staked token to the staker
            contractToTokenIdToStaker[_currContract][_currTokenId] = msg.sender;

        } while (++i < l); }

        // OK: checked and the balance matches the stake amount.
        // Add staked balance to the user
        stakerToStakedBalance[msg.sender] += l;

        // Emit the Events associated with the stake
        emit TokenStaked(msg.sender, _delegate, contracts_, tokenIds_, block.timestamp);
    }

    function unstakeGangsters(address[] calldata contracts_, 
    uint256[] calldata tokenIds_) external {

        // OK: requires staking to be enabled to function
        require(stakingIsEnabled, "Staking is not enabled!");

        // OK: contracts must be same length
        require(contracts_.length == tokenIds_.length, "Array lengths mismatch!");

        // OK: the delegate address is always msg.sender or the SSTORE delegate
        // If the delegate address is empty, the delegate is the staker.
        address _delegate = addressToDelegate[msg.sender] == address(0) ? 
            msg.sender : addressToDelegate[msg.sender];

        // OK: the length for frankenloop
        uint256 l = contracts_.length;

        // OK: CEI pattern and removing balances (effects) before interactions
        // Remove staked balance to the user
        stakerToStakedBalance[msg.sender] -= l;

        // OK: just frankenloop
        uint256 i; unchecked { do {     

            // OK: initialize the local variables to the current looped item
            address _currContract = contracts_[i];
            uint256 _currTokenId = tokenIds_[i];

            // OK: this assumes that the contract is eligible already since it is staked
            // OK: get the contract type associated
            uint256 _contractType = _getContractType(_currContract);

            // OK: do an SLOAD to find the staker's address
            address _staker = contractToTokenIdToStaker[_currContract][_currTokenId];

            // OK: first, the token must be staked (SSTORE initialized)
            // Optional verbose error message of token needing to be staked
            require(_staker != address(0), "Token is not staked!");

            // OK: only the _staker can unstake
            // The unstaker must be the staker
            require(msg.sender == _staker, "You are not the staker!");

            // OK: delete the mapping SSTORE before transfer for good CEI
            // Delete the staked token
            delete contractToTokenIdToStaker[_currContract][_currTokenId];

            // OK: handle the transfer after the mapping is deleted
            // Transfer the token
            _handleTransfer(_currContract, _contractType,
                address(this), _staker, _currTokenId);

        } while (++i < l); }

        // Emit the Events associated with the stake
        emit TokenUnstaked(msg.sender, _delegate, contracts_, tokenIds_, 
            block.timestamp);
    }
}