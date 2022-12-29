// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IFrensMetaHelper.sol";
import "./interfaces/IFrensArt.sol";
import "./FrensBase.sol";

contract FrensArt is IFrensArt, FrensBase {

  IFrensPoolShare frensPoolShare;

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
    frensPoolShare = IFrensPoolShare(getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare"))));
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    IStakingPool stakingPool = IStakingPool(payable(getAddress(keccak256(abi.encodePacked("pool.for.id", id)))));
    IFrensMetaHelper metaHelper = IFrensMetaHelper(getAddress(keccak256(abi.encodePacked("contract.address", "FrensMetaHelper"))));
    uint depositForId = getUint(keccak256(abi.encodePacked("deposit.amount", id)));
    string memory depositString = metaHelper.getEthDecimalString(depositForId);
    uint shareForId = stakingPool.getDistributableShare(id);
    string memory shareString = metaHelper.getEthDecimalString(shareForId);
    string memory poolColor = metaHelper.getColor(address(stakingPool));
    address ownerAddress = frensPoolShare.ownerOf(id);
    string memory textColor = metaHelper.getColor(ownerAddress);
    (bool ensExists, string memory ownerEns) = metaHelper.getEns(stakingPool.owner());

    string memory render = string(abi.encodePacked(

      //"frens" lettering stlying
      '<defs><style>@font-face{font-family:"Permanent Marker";src:url(data:application/font-woff;charset=utf-8;base64,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) format("woff"); font-weight:normal;font-style:normal;}</style></defs>'

      '<circle cx="200" cy="200" r="170" fill="#',
        poolColor,
      '"/>,'
      //shaka
      '<g transform="matrix(.707107 -.70710678 .70710678 .707107 16 153)" stroke="none" fill-rule="nonzero"><path d="M196.2512 233.555c8.3009 0 9.8263-6.9913 8.1372-12.24-1.6351-5.0915-6.5388-9.2041-16.1456-13.4342-18.6514-8.1867-44.9124-15.3737-44.9124-17.8813s11.2595-.665 25.952-3.4659c11.1504-2.1342 12.204-6.4434 13.6215-13.9247 1.6891-8.8516-4.0689-15.5493-4.0689-15.5493s9.8988-3.9178 9.8988-16.099-11.4057-17.6453-11.4057-17.6453 4.6668-3.0747 5.866-10.2425c1.4894-8.8319-4.4865-16.6662-12.6045-22.5219-6.8467-4.9352-15.5279-9.3614-21.9741-12.0446-5.5393-2.3102-9.6994-3.936-23.3019-3.7602-10.9517.1372-16.3081-.2153-17.144-3.9951-.6356-2.8202 1.6347-5.7382 3.904-12.8275 2.8157-8.7339 10.0441-31.256-3.0874-51.3503-5.0481-7.7155-18.1245-7.598-20.7756-4.9148-5.0497 5.1108 1.5253 15.3338-1.98 33.645-2.4151 12.6321-5.3214 21.249-17.2164 30.9824-6.8661 5.6207-22.0854 14.963-33.8356 30.6297-4.3587 5.7979-17.9428 4.7004-25.5348 3.5652-3.032-.4507-5.8841 1.7227-6.4831 4.9739-6.0301 32.3922-1.9433 66.2534.0905 79.3165.4911 3.1726 3.1423 5.4245 6.1208 5.1895 6.7737-.5086 18.2526-1.2925 21.8119-.8611 7.1738.8611 21.9389 12.4552 42.1698 18.6239 17.9615 5.4838 43.5155 10.5559 54.9387 11.2413s59.8411 14.5903 67.9588 14.5903z" fill="#ffca28"/><path d="M131.2159 74.786v.3141c6.9566.0192 13.2219 7.0502 12.9677 14.5512-.31 8.7336-11.6234 12.3186-7.3188 24.6756.8706 2.5251 11.4597 6.6976 8.8616 19.2512-2.1244 10.2827-10.0614 9.5562-10.0614 14.7071 0 8.7359 9.4624 14.5704 10.1345 24.5197s-4.0677 11.5345-3.7421 14.9828c.2368 2.5466 1.2729 3.4652 1.2729 2.1941 0-2.5082 11.2594-.6666 25.951-3.4675 11.1514-2.1342 12.2049-6.4434 13.6224-13.9252 1.6891-8.8511-4.0695-15.5488-4.0695-15.5488s9.8995-3.9183 9.8995-16.0979-11.4057-17.6469-11.4057-17.6469 4.6667-3.0743 5.8647-10.242c1.4906-8.8319-4.4856-16.6662-12.6037-22.5221-6.8469-4.9351-15.5274-9.3618-21.9737-12.0429-4.632-1.94-8.3376-3.3884-17.3994-3.7025z" fill="#ffb300"/><path d="M135.3022 150.9304c-.1636-4.1328.091-5.2682 2.1071-5.8173s5.7028.9998 5.7028.9998c14.8553-1.3524 30.8928 2.0552 35.7408 10.9277 0 0-23.609-1.8607-32.4723-1.3523-6.9549.4122-10.8781.4892-11.0784-4.7579zm42.0433-27.6145c-14.5104-5.4647-31.4737-6.4432-36.486-6.4432-7.1193 0-5.7568-11.6727-2.7244-13.8658 2.0889-.9203 4.5581 2.3106 6.5015 3.0748 5.7759 2.2908 30.1841 3.7407 32.7089 17.2342zm.9263 109.5939c-26.6423-5.0914-62.148-15.1978-90.3348-19.1146-20.7393-2.878-32.3452-11.5346-41.0801-16.392-4.9223-2.7417-8.8089-4.9147-12.713-5.9722-10.3344-2.8205-18.2891-1.2347-24.7356-1.489s7.7542-10.0275 26.4972-6.0523c4.758.9998 9.1353 3.7409 14.2568 6.5999 8.8262 4.9161 19.6143 12.241 39.3193 15.7064 11.0417 1.9591 27.8048 3.9566 43.5505 8.2251 12.4227 3.35 46.9653 15.2178 58.9874 16.8051 6.1574.8227 11.587-.9805 11.606-.9805 0 0-1.0361 2.6641-5.2309 4.0149-4.4679 1.45-9.7167.6467-20.1228-1.3508zm-62.0753-158.301c-3.7771.5875-11.986-2.0552-8.5724-10.947 5.8122-15.1194 6.2843-20.3472 6.0476-35.5457-.1812-10.8894-3.3052-18.2322-5.6474-22.6781 0 0 18.8516 13.7094 9.3162 56.5404-1.3982 6.2276-1.144 12.6304-1.144 12.6304zm61.0586 109.1441s-4.2854 2.8393-10.0614 5.0142c-5.7934 2.1727-15.4195 3.9951-19.233 4.0143s-8.355-4.3284-5.0847-5.9542c3.2511-1.6044 34.3791-3.0743 34.3791-3.0743z" fill="#eda600"/></g>',
      //cover part of shaka to have consistent gap from eth logo
      '<polygon points="200,359 80,220 98,195 200,256" fill="#',
        poolColor,
      '"/>',
      //ethlogo (partial)
      '<polygon points="200,359 98,215 200,276" fill="#8c8c8c" />',
      '<polygon points="200,359 302,215 200,276" fill="#3c3c3b" />',
      //frens text
      '<text font-size="122" x="5" y="240" font-family="Permanent Marker"  opacity=".4" fill="#',
        textColor,
      '">FRENS</text>',
      //frens Text outline
      '<text font-size="122" x="5" y="240" font-family="Permanent Marker" fill="none"  stroke-width="2" stroke="#',
        textColor,
      '">FRENS</text>'
      //deposit text
      '<text font-size="50" text-anchor="middle" x="200" y="135" fill="#FF69B4" stroke="#00EDF5" font-weight="Bold" font-family="Sans-Serif" opacity=".8">',
        depositString, ' Eth',
      '</text>',
      //claimable text
      '<text font-size="25" text-anchor="middle" x="200" y="300" fill="#FF69B4" stroke="#00EDF5" font-weight="Bold" font-family="Sans-Serif" >',
        shareString, ' Eth Claimable',
      '</text>'
      //pool owners ENS
      '<text font-size="15" text-anchor="middle" x="200" y="330" fill="#FF69B4" stroke="#00EDF5" font-weight="Bold" font-family="Sans-Serif" >',
        ensExists ? 'Pool created by:' : '',
      '</text>'
      
      '<text font-size="30" text-anchor="middle" x="200" y="360" fill="#FF69B4" stroke="#00EDF5" font-weight="Bold" font-family="Sans-Serif" >',
        ownerEns, 
      '</text>'


      ));

    return render;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IStakingPool{

  function owner() external view returns (address);

  function depositToPool() external payable;

  function addToDeposit(uint _id) external payable;

  function withdraw(uint _id, uint _amount) external;

  function distribute() external;

  function getIdsInThisPool() external view returns(uint[] memory);

  function getShare(uint _id) external view returns(uint);

  function getDistributableShare(uint _id) external view returns(uint);

  function getPubKey() external view returns(bytes memory);

  function setPubKey(bytes memory _publicKey) external;

  function getState() external view returns(string memory);

  function getDepositAmount(uint _id) external view returns(uint);


  function stake(
    bytes calldata pubkey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) external;

    function unstake() external;

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";


interface IFrensPoolShare is IERC721Enumerable{

  function mint(address userAddress, address _pool) external;

  function exists(uint _id) external view returns(bool);

  function getPoolById(uint _id) external view returns(address);

  function tokenURI(uint256 id) external view returns (string memory);

  function renderTokenById(uint256 id) external view returns (string memory);

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensMetaHelper {

  function getColor(address a) external pure returns(string memory);

  function getEthDecimalString(uint amountInWei) external pure returns(string memory);

  function getOperatorsForPool(address poolAddress) external view returns (uint32[] memory, string memory);

  function getEns(address addr) external view returns(bool, string memory);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensArt {
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