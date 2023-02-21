/**
 *Submitted for verification at Etherscan.io on 2023-02-21
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
 * Legion (Future Compatibility): ERC721 
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
    constructor() { 
        owner = msg.sender; 
        emit OwnershipTransferred(address(0), msg.sender);
    }
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

contract GangsterPortal is Controllerable {

    /////////////////////
    ///// Constants /////
    /////////////////////
    address constant public OS_STORE = 0xf4910C763eD4e47A585E2D34baA9A4b611aE448C;

    ////////////////////////////
    ///// Address Registry /////
    ////////////////////////////
    event AddressRegistrationSet(address indexed contract_, bool indexed enabled_);
    event AddressTypeSet(address indexed contract_, uint256 indexed type_);

    mapping(address => bool) public addressToEnabled;
    mapping(address => uint256) public addressToType; // 1 = ERC721, 2 = ERC1155

    function C_setAddressEnabled(address[] calldata contracts_, bool enabled_) 
    external onlyController("REGISTRY") {
        uint256 l = contracts_.length;
        uint256 i; unchecked { do { 
            address _currContract = contracts_[i];
            addressToEnabled[_currContract] = enabled_;
            emit AddressRegistrationSet(_currContract, enabled_);
        } while (++i < l); }
    }

    function C_setAddressType(address[] calldata contracts_, uint256[] calldata types_)
    external onlyController("REGISTRY") {
        uint256 l = contracts_.length;
        uint256 i; unchecked { do {
            address _currContract = contracts_[i];
            uint256 _currType = types_[i];
            require(_currType == 1 || _currType == 2, "Unsupported Type!");
            addressToType[_currContract] = _currType;
            emit AddressTypeSet(_currContract, _currType);
        } while (++i < l); }
    }

    // Possible Contract Types: 1 = ERC721, 2 = ERC1155, 3 = OpenSea Storefront
    function _getContractType(address contract_) internal view returns (uint256) {
        // We compare calldata to contract data and return, this process is cheap, so
        // it is the first condition to check and return.
        if (contract_ == OS_STORE) return 3;

        // Otherwise, we do a SLOAD. The loaded data must be {1} or {2} as they are
        // the only supported types.
        uint256 _contractType = addressToType[contract_];
        require(_contractType == 1 || _contractType == 2, "Unsupported Type!");

        return _contractType;
    }

    //////////////////////////////////
    ///// OS Storefront Registry /////
    //////////////////////////////////
    event OpenSeaTokenSet(bool indexed enabled_, uint256 tokenId_);

    mapping(uint256 => bool) public OSTokenToStakeable;

    function C_setOSTokenStakeable(uint256[] calldata tokenIds_, bool enabled_) 
    external onlyController("REGISTRY") {
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

    function C_setERC1155Unstakeable(address contract_, uint256[] calldata tokenIds_,
    bool disallowed_) external onlyController("REGISTRY") {
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

    // Delegate can only be set when you have no tokens staked
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
        address[] contracts_, uint256[] tokenIds_);
    event TokenUnstaked(address indexed staker_, address indexed delegate_,
        address[] contracts_, uint256[] tokenIds_);
    
    mapping(address => uint256) public stakerToStakedBalance;
    mapping(address => mapping(uint256 => address)) public contractToTokenIdToStaker;

    function _handleTransfer(address contract_, uint256 contractType_, 
    address from_, address to_, uint256 tokenId_) internal {
        // Handler for ERC721
        if (contractType_ == 1) {
            IERC721(contract_)
            .transferFrom(from_, to_, tokenId_);
        }
        // Handler for ERC1155
        else if (contractType_ == 2) {
            // This prevents the staking of explicitly disallowed tokens (non 1/1s)
            require(!ERC1155ToTokenIdToDisallowed[contract_][tokenId_],
                    "ERC1155 Token not supported!");

            IERC1155(contract_)
            .safeTransferFrom(from_, to_, tokenId_, 1, "");
        }
        // Handler for OS Storefront
        else if (contractType_ == 3) {
            // This prevents the staking of anything that is not explicitly labeled
            require(OSTokenToStakeable[tokenId_], 
                    "OS Token not stakeable!");
            
            IERC1155(contract_)
            .safeTransferFrom(from_, to_, tokenId_, 1, "");
        }
        // Sanity check that should never happen (see C_setAddressRegistration)
        else {
            revert("Unsupported contract type!");
        }
    }

    function stakeGangsters(address[] calldata contracts_, 
    uint256[] calldata tokenIds_) external {
        require(contracts_.length == tokenIds_.length, "Array lengths mismatch!");
        uint256 l = contracts_.length;
        
        // If the delegate address is empty, the delegate is the staker.
        address _delegate = addressToDelegate[msg.sender] == address(0) ? 
            msg.sender : addressToDelegate[msg.sender];

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

        // Add staked balance to the user
        // Here, {i} is the amount of items looped over, so we can use the same tracker
        // as the source-of-truth of the amount of staked tokens for the transaction.
        stakerToStakedBalance[msg.sender] += i;

        // Emit the Events associated with the stake
        emit TokenStaked(msg.sender, _delegate, contracts_, tokenIds_);
    }

    function unstakeGangsters(address[] calldata contracts_, 
    uint256[] calldata tokenIds_) external {
        require(contracts_.length == tokenIds_.length, "Array lengths mismatch!");
        uint256 l = contracts_.length;

        // If the delegate address is empty, the delegate is the staker.
        address _delegate = addressToDelegate[msg.sender] == address(0) ? 
            msg.sender : addressToDelegate[msg.sender];

        uint256 i; unchecked { do {     

            address _currContract = contracts_[i];
            uint256 _currTokenId = tokenIds_[i];

            // Lookup the address type
            uint256 _contractType = _getContractType(_currContract);

            // Lookup the staker
            address _staker = contractToTokenIdToStaker[_currContract][_currTokenId];

            // Optional verbose error message of token needing to be staked
            require(_staker != address(0), "Token is not staked!");

            // The unstaker must be the staker
            require(msg.sender == _staker, "You are not the staker!");

            // Delete the staked token
            delete contractToTokenIdToStaker[_currContract][_currTokenId];

            // Transfer the token
            _handleTransfer(_currContract, _contractType,
                address(this), _staker, _currTokenId);

        } while (++i < l); }

        // Remove staked balance to the user
        // Here, {i} is the amount of items looped over, so we can use the same tracker
        // as the source-of-truth of the amount of staked tokens for the transaction.
        stakerToStakedBalance[msg.sender] -= i;

        // Emit the Events associated with the stake
        emit TokenUnstaked(msg.sender, _delegate, contracts_, tokenIds_);
    }
}