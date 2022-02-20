/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

/*
* ███╗░░░███╗███████╗████████╗░█████╗░        ███╗░░██╗░█████╗░███╗░░██╗░█████╗░░██████╗
* ████╗░████║██╔════╝╚══██╔══╝██╔══██╗        ████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
* ██╔████╔██║█████╗░░░░░██║░░░███████║        ██╔██╗██║███████║██╔██╗██║██║░░██║╚█████╗░
* ██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║        ██║╚████║██╔══██║██║╚████║██║░░██║░╚═══██╗
* ██║░╚═╝░██║███████╗░░░██║░░░██║░░██║        ██║░╚███║██║░░██║██║░╚███║╚█████╔╝██████╔╝
* ╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝        ╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚═════╝░
*
*
* META NANOs
* The next level 3D play-to-earn metaverse
*
* Our vision is to create a next level, high quality 3D play-to-earn metaverse where users can buy, train and trade
* their NANOs and let them compete against each other in a universe of different games. Each game can interpret the
* NANOs and its power gems in its own specific way and thus differently. Games can require additional equipment which
* NANOs need to use in order to join the game. Each NANO has its own stats and a power gem that can be used to win within
* the game.
*
* META NANOs is an official HERO ecosystem project (www.herocoin.io)
*
* Official Links:
* https://www.metananos.com
* https://twitter.com/metananos
* https://instagram.com/metananos
*
* */


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// 
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/proxy/Clones.sol

// 
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: contracts/MetaNanoDataI.sol

/*
 * Interface for data storage of the cryptoAgri system.
 *
 * 
 */
pragma solidity ^0.8.0;

interface MetaNanoDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: contracts/AuctionV1DeployI.sol

/*
 * AlphaPass Auction V1 deployment interface
 *
 * 
 */
pragma solidity ^0.8.0;

interface AuctionV1DeployI {

    function initialRegister(address previousAuction) external;

}

// File: contracts/DropV1DeployI.sol

/*
 * Auction V1 deployment interface
 *
 * 
 */
pragma solidity ^0.8.0;

interface DropV1DeployI {

    function initialRegister(address paymentToken, uint256 minBidWei, address auctionPrototypeAddress) external;

}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/ERC721SignedTransferI.sol

/*
 * Interface for ERC721 Signed Transfers.
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface ERC721SignedTransferI is IERC721 {

    /**
     * @dev Emitted when a signed transfer is being executed.
     */
    event SignedTransfer(address operator, address indexed from, address indexed to, uint256 indexed tokenId, uint256 signedTransferNonce);

    /**
     * @dev The signed transfer nonce for an account.
     */
    function signedTransferNonce(address account) external view returns (uint256);

    /**
     * @dev Outward-facing function for signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can called by anyone knowing about the right signature, but can only transfer to the given specific target.
     */
    function signedTransfer(uint256 tokenId, address to, bytes memory signature) external;

    /**
     * @dev Outward-facing function for operator-driven signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can transfer to any target, but only be called by the trusted operator contained in the signature.
     */
    function signedTransferWithOperator(uint256 tokenId, address to, bytes memory signature) external;

}

// File: contracts/ERC721ExistsI.sol

/*
 * Interface for an ERC721 compliant contract with an exists() function.
 *
 * 
 */
pragma solidity ^0.8.0;

/**
 * @dev ERC721 compliant contract with an exists() function.
 */
interface ERC721ExistsI is IERC721 {

    // Returns whether the specified token exists
    function exists(uint256 tokenId) external view returns (bool);

}

// File: contracts/PassType.sol

/*
 * 
 */
pragma solidity ^0.8.0;

uint constant MAX_PASS_TYPE_COUNT = 3;

enum PassType {
    Silver,
    Gold,
    Crystal
}

// File: contracts/AlphaPassTokenI.sol

/*
 * Interface for functions of the AlphaPassToken token that need to be accessed by
 * other contracts.
 *
 * 
 */
pragma solidity ^0.8.0;




interface AlphaPassTokenI is IERC721Enumerable, ERC721ExistsI, ERC721SignedTransferI {

    /**
     * @dev The base URI of the token.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev The passType ID for a specific asset / token ID.
     */
    function passType(uint256 tokenId) external view returns (PassType);

    function createMulti(uint _amount, address _owner, PassType _passType) external;

    function moveMulti(uint256 fromTokenInclusive, uint256 toTokenInclusive, address _destination) external;


}

// File: contracts/DropV1FactoryI.sol

/*
 * Interface for AlphaPass auctions V1 Factory.
 *
 * 
 */
pragma solidity ^0.8.0;

interface DropV1FactoryI {

    /**
     * @dev Emitted when a new auction is created.
     */
    event NewDrop(address dropAddress,address paymentToken );

    function create(address paymentToken, uint256 minBidWei) external;

    /**
     * @dev The data contract used with the tokens.
     */
    function metaNanoData() external view returns (MetaNanoDataI);

    function activeDrop() external view returns (address);

    function upcomingDrop() external view returns (address);

}

// File: contracts/DropV1Factory.sol

/*
 * Factory for AlphaPass auctions V1.
 *
 * 
 */
pragma solidity ^0.8.0;








contract DropV1Factory is DropV1FactoryI {

    MetaNanoDataI public metaNanoData;

    address public auctionPrototypeAddress;
    address public dropPrototypeAddress;

    address[] public deployedDrops;
    uint256 public activeDropIndex;

    mapping(address => bool) public isDrop;

    constructor(address _MetaNanoDataAddress, address _auctionPrototypeAddress, address _dropPrototypeAddress)
    {
        metaNanoData = MetaNanoDataI(_MetaNanoDataAddress);
        require(address(metaNanoData) != address(0x0), "You need to provide an actual MetaNano data contract.");
        auctionPrototypeAddress = _auctionPrototypeAddress;
        dropPrototypeAddress = _dropPrototypeAddress;
        require(auctionPrototypeAddress != address(0x0), "You need to provide an actual prototype address.");
    }

    modifier onlyCreateControl() {
        require(msg.sender == metaNanoData.getAddress("auctionCreateControl"), "Auction createControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == metaNanoData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** Get contracts with their ABI ***/

    function assetToken()
    public view
    returns (AlphaPassTokenI)
    {
        return AlphaPassTokenI(metaNanoData.getAddress("AlphaPassToken"));
    }

    /*** Manage auctions ***/

    // Create a new auction, which can own currency and tokens.

    function create(address _paymentToken, uint256 _minBidWei)
    public
    onlyCreateControl
    {
        address newDropAddress = Clones.clone(dropPrototypeAddress);
        emit NewDrop(newDropAddress, _paymentToken);
        isDrop[newDropAddress] = true;
        deployedDrops.push(newDropAddress);
        DropV1DeployI(newDropAddress).initialRegister(_paymentToken, _minBidWei, auctionPrototypeAddress);
    }

    function collectMoney(address _payingUser, uint256 _amount, IERC20 _paymentToken, address _recipient)
    public
    {
        require(isDrop[msg.sender], "only drops are authorized to collect money");
        _paymentToken.transferFrom(_payingUser, _recipient, _amount);
    }

    function deployedDropsCount()
    public view
    returns (uint256)
    {
        return deployedDrops.length;
    }

    function activeDrop() external view returns (address){
        return deployedDrops[activeDropIndex];
    }

    function upcomingDrop() external view returns (address){
        return deployedDrops[activeDropIndex + 1];
    }

    /*** Make sure currency doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }


}