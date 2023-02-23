pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "./interfaces/IFrensClaim.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./FrensBase.sol";

contract FrensClaim is IFrensClaim, FrensBase {

    IFrensPoolShare frensPoolShare;

    constructor(IFrensStorage frensStorage_) FrensBase(frensStorage_){
        address frensPoolShareAddress = getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare")));
        frensPoolShare = IFrensPoolShare(frensPoolShareAddress); //this hardcodes the nft contract to this contract
        version = 0;
    }

    function distribute(uint[] calldata ids) external payable onlyStakingPool(msg.sender) returns(bool) {
        for(uint i=0; i<ids.length; i++) {
            uint id = ids[i];
            uint share = _getShare(id, msg.value);
            address claimant = frensPoolShare.ownerOf(id);
            addUint(keccak256(abi.encodePacked("claimable.amount", address(this), claimant)), share);
        }
        return true;
    }

    function getShare(uint _id) external view returns(uint) {
        address pool = getAddress(keccak256(abi.encodePacked("pool.for.id", _id)));
        uint contractBalance = pool.balance;
        return _getShare(_id, contractBalance);
    }

    function _getShare(uint _id, uint _contractBalance) internal view returns(uint) {
        address pool = getAddress(keccak256(abi.encodePacked("pool.for.id", _id)));
        uint depAmt = getUint(keccak256(abi.encodePacked("deposit.amount", pool, _id)));
        uint totDeps = getUint(keccak256(abi.encodePacked("total.deposits", pool)));
        if(depAmt == 0) return 0;
            uint calcedShare =  _contractBalance * depAmt / totDeps;
        if(calcedShare > 1){
            return(calcedShare - 1); //steal 1 wei to avoid rounding errors drawing balance negative
        }else return 0;
    }

    function claim(address claimant) override public {
        uint amount = getUint(keccak256(abi.encodePacked("claimable.amount", address(this), claimant)));
        setUint(keccak256(abi.encodePacked("claimable.amount", address(this), claimant)), 0);
        payable(claimant).transfer(amount);
    }

    function claim() override external {
        claim(msg.sender);
    }

    // to support receiving ETH by default
    receive() external payable {}

    fallback() external payable {}
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensClaim {
    
    function distribute(uint[] calldata ids) external payable  returns(bool);

    function getShare(uint _id) external view returns(uint);

    function claim() external;

    function claim(address claimant) external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";


interface IFrensPoolShare is IERC721Enumerable{

  function mint(address userAddress) external;

  function burn(uint tokenId) external;

  function exists(uint _id) external view returns(bool);

  function getPoolById(uint _id) external view returns(address);

  function tokenURI(uint256 id) external view returns (string memory);

  function renderTokenById(uint256 id) external view returns (string memory);

}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/IFrensStorage.sol";

/// @title Base settings / modifiers for each contract in Frens Pool
/// @author modified 04-Dec-2022 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// this code is modified from the Rocket Pool RocketBase contract all "Rocket" replaced with "Frens"

abstract contract FrensBase {

    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    IFrensStorage frensStorage;


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Frens Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    //removed  0xWildhare
    /*
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }
    */
    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    //removed  0xWildhare
    /*
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }
    */

    /**
    * @dev Throws if called by any sender that isn't a registered Frens StakingPool
    */
    modifier onlyStakingPool(address _stakingPoolAddress) {
        require(getBool(keccak256(abi.encodePacked("pool.exists", _stakingPoolAddress))), "Invalid Pool");
        _;
    }


    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == frensStorage.getGuardian(), "Account is not a temporary guardian");
        _;
    }


    





    /*** Methods **********************************************************/

    /// @dev Set the main Frens Storage address
    constructor(IFrensStorage _frensStorage) {
        // Update the contract address
        frensStorage = IFrensStorage(_frensStorage);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the address of a network contract by name (returns address(0x0) instead of reverting if contract does not exist)
    function getContractAddressUnsafe(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Frens Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return frensStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return frensStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return frensStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return frensStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return frensStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return frensStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return frensStorage.getBytes32(_key); }
    function getArray(bytes32 _key) internal view returns (uint[] memory) { return frensStorage.getArray(_key); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { frensStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { frensStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { frensStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { frensStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { frensStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { frensStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { frensStorage.setBytes32(_key, _value); }
    function setArray(bytes32 _key, uint[] memory _value) internal { frensStorage.setArray(_key, _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { frensStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { frensStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { frensStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { frensStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { frensStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { frensStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { frensStorage.deleteBytes32(_key); }
    function deleteArray(bytes32 _key) internal { frensStorage.deleteArray(_key); }

    /// @dev Storage arithmetic methods - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) internal { frensStorage.addUint(_key, _amount); }
    function subUint(bytes32 _key, uint256 _amount) internal { frensStorage.subUint(_key, _amount); }
    function pushUint(bytes32 _key, uint256 _amount) internal { frensStorage.pushUint(_key, _amount); }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
interface IERC165 {
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

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);
    function getArray(bytes32 _key) external view returns (uint[] memory);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;
    function setArray(bytes32 _key, uint[] calldata _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
    function deleteArray(bytes32 _key) external;

    // Arithmetic (and stuff) - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    function pushUint(bytes32 _key, uint256 _amount) external;

    // Protected storage removed ~ 0xWildhare
    /*
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
    */
}