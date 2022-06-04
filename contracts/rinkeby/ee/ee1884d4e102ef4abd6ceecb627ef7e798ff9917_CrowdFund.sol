/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

//SPDX-License-Identifier:NOLICENSE
pragma solidity 0.8.13;

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

pragma solidity 0.8.13;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity 0.8.13;

interface ICrowdFundERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

pragma solidity 0.8.13;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.13;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.13;

contract CrowdFund is Ownable {
    IERC1155 public CrowdFundERC1155;

    struct DonationInfo {
        address charityAddress;
        uint raisingAmount;
        uint raised;
        uint64 postedOn;
        uint64 closedOn;
    }

    struct Donations {
        uint nft;
        bool isCreated;
    }

    struct DonorInfo {
        mapping(address => uint) totalDonatedAmount;
        uint totalDonors;
        uint totalDonations;
    }

    DonationInfo[] public donationInfo;
    DonorInfo public donorInfo;
    uint public totalCharities;

    mapping(address => mapping(uint => uint)) public donatorInfo;
    mapping(uint => address[]) public donators;
    mapping(address => Donations[]) public charityNFTs;

    event FundRaise(
        address charityAddress,
        uint nftId,
        uint64 timestamp
    );

    event Donates(
        address donator,
        uint nftId,
        uint amount,
        uint64 timestamp
    );

    /*
    * @dev Initializes the contract.
    */
    constructor() {
        DonationInfo memory info;
        donationInfo.push(info);
    }

    /*
    * @dev Only charity address can collect funds
    */
    modifier onlyCharity(uint id) {
        require(
            _msgSender() == donationInfo[id].charityAddress,
            "Only charity address"
        );
        _;
    }

    /*
    * @dev Setting NFT as a donation nft.
    */
    function setNFT(IERC1155 nft) external {
        require(address(nft) != address(0), "nft address must not be zero");
        CrowdFundERC1155 = nft;
    }

    /*
    * @dev Creates new crowdfunding.
    */
    function createDonation(address charityAddress, uint raiseAmount)  external onlyOwner {
        require(charityAddress != address(0), "newCharityAddress must not be zero");
        require(raiseAmount > 0, "raiseAmount should be higher than zero");

        uint nft = donationInfo.length;

        if(charityNFTs[charityAddress].length == 0) {
            totalCharities++;
        }

        donationInfo.push(
            DonationInfo({
                charityAddress : charityAddress,
                raisingAmount : raiseAmount,
                raised : 0,
                postedOn : uint64(block.timestamp),
                closedOn : 0
            })
        );

        charityNFTs[charityAddress].push(
            Donations({
                nft :  nft,
                isCreated : true
            })
        );

        emit FundRaise(
            charityAddress,
            nft,
            uint64(block.timestamp)
        );
    }

    /*
    * @dev donate BNB to the charity
    */
    function donate(uint id) external payable {
        require( donationInfo[id].closedOn == 0, "Funding closed");
        require( donationInfo[id].postedOn != 0, "invalid donate id");
        require(_msgSender() == tx.origin, "Not callable by a contract");
        require(msg.value > 0, "BNB should be higher than zero");
        
        uint amount = msg.value;
        donationInfo[id].raised += amount;

        if(donatorInfo[_msgSender()][id] == 0) {
            donators[id].push(_msgSender());
            if(donorInfo.totalDonatedAmount[_msgSender()] == 0) {
                donorInfo.totalDonors++;
            }
        }

        donatorInfo[_msgSender()][id] += amount;
        donorInfo.totalDonatedAmount[_msgSender()] += amount;
        donorInfo.totalDonations += amount;
        
        ICrowdFundERC1155(address(CrowdFundERC1155)).mint(
            _msgSender(),
            id, 
            1, 
            "0x"
        );

        emit Donates(
            _msgSender(),
            id,
            amount,
            uint64(block.timestamp)
        );
    }

    /*
    * @dev Charity collect fund raised from the crowdfunding
    */
    function collect(uint id) external onlyCharity(id) {
        DonationInfo storage info =  donationInfo[id];
        require(info.closedOn == 0, "Funding closed");
        require(info.raised > 0, "No fund raised");

        info.closedOn = uint64(block.timestamp);

        sendValue(
            payable(_msgSender()),
            info.raised
        );
    }

    /*
    * @dev To get all the NFTs of the charity
    */
    function getCharityNFTs(address charity) external view returns (Donations[] memory) {
        return charityNFTs[charity];
    }

    /*
    * @dev To get length of donators by its id
    */
    function getTotalDonatorById(uint id) external view returns (uint) {
        return donators[id].length; 
    }

    /*
    * @dev To get length of donations
    */
    function getDonationsLength() external view returns (uint) {
        return donationInfo.length; 
    }
    
    /*
    * @dev To get all donators address by its id
    */
    function getAllDonatorAddressById(uint id) external view returns (address[] memory) {
        return donators[id]; 
    }

    /*
    * @dev To get total donated amount by address
    */
    function getTotalDonatedAmount(address donor) external view returns (uint) {
        return donorInfo.totalDonatedAmount[donor];
    }
    
    /*
    * @dev Send BNB to charity address 
    */
    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}